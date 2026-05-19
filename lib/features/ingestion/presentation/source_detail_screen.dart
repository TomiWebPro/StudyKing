import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show selectedModelProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/core/utils/label_helpers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SourceDetailScreen extends ConsumerStatefulWidget {
  final String sourceId;
  final SourceRepository? sourceRepo;
  final SubjectRepository? subjectRepo;
  final TopicRepository? topicRepo;
  final QuestionRepository? questionRepo;

  const SourceDetailScreen({
    super.key,
    required this.sourceId,
    this.sourceRepo,
    this.subjectRepo,
    this.topicRepo,
    this.questionRepo,
  });

  @override
  ConsumerState<SourceDetailScreen> createState() => _SourceDetailScreenState();
}

class _SourceDetailScreenState extends ConsumerState<SourceDetailScreen> {
  final _logger = const Logger('SourceDetailScreen');
  late final SourceRepository _sourceRepo = widget.sourceRepo ?? SourceRepository();
  late final SubjectRepository _subjectRepo = widget.subjectRepo ?? SubjectRepository();
  late final TopicRepository _topicRepo = widget.topicRepo ?? TopicRepository();
  late final QuestionRepository _questionRepo = widget.questionRepo ?? QuestionRepository();

  Source? _source;
  Subject? _subject;
  List<Topic> _topics = [];
  List<Question> _questions = [];
  bool _isLoading = true;
  String? _error;
  bool _isReprocessing = false;
  String _reprocessingStage = '';

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _sourceRepo.init();
      await _subjectRepo.init();
      await _topicRepo.init();
      await _questionRepo.init();

      final sourceResult = await _sourceRepo.get(widget.sourceId);
      final source = sourceResult.data;
      if (source == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() { _isLoading = false; _error = l10n?.sourceNotFound ?? 'Source not found'; });
        }
        return;
      }

      Subject? subject;
      if (source.subjectId.isNotEmpty) {
        final subjectResult = await _subjectRepo.get(source.subjectId);
        subject = subjectResult.data;
      }

      List<Topic> topics = [];
      if (source.subjectId.isNotEmpty) {
        final topicsResult = await _topicRepo.getBySubject(source.subjectId);
        topics = topicsResult.data ?? [];
      }

      List<Question> questions = [];
      if (source.generatedQuestionIds.isNotEmpty) {
        final allQuestionsResult = await _questionRepo.getAll();
        final allQuestions = allQuestionsResult.data ?? [];
        questions = allQuestions.where((q) => source.generatedQuestionIds.contains(q.id)).toList();
      }

      if (mounted) {
        setState(() {
          _source = source;
          _subject = subject;
          _topics = topics;
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('_load failed', e);
      if (mounted) setState(() { _error = AppLocalizations.of(context)!.somethingWentWrong; _isLoading = false; });
    }
  }

  Future<void> _reprocess() async {
    final l10n = AppLocalizations.of(context)!;
    final source = _source;
    if (source == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reprocessSource),
        content: Text(l10n.reprocessingWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.continueAnyway)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isReprocessing = true;
      _reprocessingStage = l10n.reprocessing;
    });

    try {
      final pipeline = ref.read(contentPipelineProvider);
      final modelId = ref.read(selectedModelProvider);
      if (modelId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.modelNotConfigured)),
          );
        }
        return;
      }
      final result = await pipeline.reprocessSource(
        source,
        modelId: modelId,
        generateQuestions: source.generatedQuestionIds.isNotEmpty,
        onProgress: (status, description) {
          if (mounted) setState(() { _reprocessingStage = description; });
        },
      );

      if (result.isSuccess && mounted) {
        final newSource = result.data!;
        final reprocessed = source.copyWith(
          processingStatus: newSource.processingStatus,
          extractedText: newSource.extractedText.isNotEmpty ? newSource.extractedText : source.extractedText,
          summary: newSource.summary.isNotEmpty ? newSource.summary : source.summary,
          generatedQuestionIds: newSource.generatedQuestionIds.isNotEmpty ? newSource.generatedQuestionIds : source.generatedQuestionIds,
          topicId: newSource.topicId.isNotEmpty ? newSource.topicId : source.topicId,
        );
        await _sourceRepo.save(widget.sourceId, reprocessed);
        if (newSource.id != widget.sourceId) {
          await _sourceRepo.delete(newSource.id);
        }
        await _load();
      }
    } catch (e) {
      if (mounted) {
        _logger.e('Reprocess failed', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.somethingWentWrong)),
        );
      }
    } finally {
      if (mounted) setState(() { _isReprocessing = false; _reprocessingStage = ''; });
    }
  }

  Future<void> _updateTopic(String? topicId) async {
    final source = _source;
    if (source == null || topicId == null) return;
    final updated = source.copyWith(topicId: topicId);
    await _sourceRepo.save(widget.sourceId, updated);
    if (mounted) setState(() => _source = updated);
  }

  Future<void> _classifyNow() async {
    final source = _source;
    if (source == null || _topics.isEmpty) return;

    final pipeline = ref.read(contentPipelineProvider);
    final topicTitles = _topics.map((t) => t.title).toList();
    final modelId = ref.read(selectedModelProvider);

    if (modelId.isEmpty) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.modelNotConfigured)));
      }
      return;
    }

    setState(() => _isReprocessing = true);

    try {
      await pipeline.reprocessSource(
        source,
        modelId: modelId,
        possibleTopics: topicTitles,
        generateQuestions: false,
        onProgress: (status, description) {
          if (mounted) setState(() { _reprocessingStage = description; });
        },
      );
      await _load();
    } catch (e) {
      _logger.w('Reprocess failed', e);
    } finally {
      if (mounted) setState(() => _isReprocessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const LoadingScreen());
    }
    if (_error != null || _source == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sourceDetail)),
        body: Center(
          child: ErrorRetryWidget(
            message: _error ?? l10n.sourceNotFound,
            onRetry: _load,
          ),
        ),
      );
    }

    final source = _source!;
    final subjectName = _subject?.name ?? '';
    final status = source.statusEnum;
    final topic = _topics.where((t) => t.id == source.topicId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(source.title),
        actions: [
          if (status == ProcessingStatus.failed)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.reprocess,
              onPressed: _reprocess,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reprocess':
                  _reprocess();
                case 'delete':
                  _confirmDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'reprocess', child: Text(l10n.reprocess)),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.delete, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        ],
      ),
      body: _isReprocessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(_reprocessingStage),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: ResponsiveUtils.screenPadding(context),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: l10n.status, value: processingStatusLabel(status, l10n)),
                  if (subjectName.isNotEmpty)
                    _InfoRow(label: l10n.subject, value: subjectName),
                  _InfoRow(label: l10n.type, value: sourceTypeLabel(source.type, l10n)),
                  _InfoRow(label: l10n.id, value: source.id),
                  if (source.createdAt != null)
                    _InfoRow(label: l10n.uploaded, value: formatDateFromContext(context, source.createdAt!)),

                  const SizedBox(height: 16),
                  if (status == ProcessingStatus.failed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.processingFailed, style: TextStyle(color: theme.colorScheme.error))),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(l10n.retry),
                            onPressed: _reprocess,
                          ),
                        ],
                      ),
                    ),

                  _SectionHeader(title: l10n.topicClassification),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: topic != null
                                ? Text(topic.title)
                                : Text(l10n.notYetClassified, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          ),
                          if (_topics.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: l10n.edit,
                              onPressed: () => _showTopicPicker(),
                            ),
                          if (topic == null && _topics.isNotEmpty)
                            TextButton(
                              onPressed: _classifyNow,
                              child: Text(l10n.classifyNow),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _SectionHeader(title: l10n.summarySection),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        source.summary.isNotEmpty ? source.summary : l10n.noSummaryAvailable,
                        style: TextStyle(
                          color: source.summary.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _SectionHeader(title: l10n.extractedTextCount(source.extractedText.length)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l10n.searchInText,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                            child: Scrollbar(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: source.extractedText.isNotEmpty
                                    ? Text(source.extractedText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))
                                    : Text(
                                        l10n.noExtractedText,
                                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _SectionHeader(title: l10n.generatedQuestionsCount(_questions.length)),
                  if (_questions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l10n.noQuestionsFromSource, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    )
                  else
                    ...List.generate(_questions.length, (i) {
                      final q = _questions[i];
                      return Semantics(
                        button: true,
                        label: q.text,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                            ),
                            title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(l10n.questionSubtitle(questionTypeLabel(q.type, l10n), q.difficultyText ?? l10n.difficultyLabel(q.difficulty.toString()))),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.questionBank, arguments: q.id);
                            },
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _reprocess,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.reprocess),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(),
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      label: Text(l10n.delete),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.error)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showTopicPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.selectTopic, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          ..._topics.map((t) => ListTile(
                title: Text(t.title),
                trailing: t.id == _source?.topicId ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateTopic(t.id);
                },
              )),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSourceTitle),
        content: Text(l10n.deleteSourceBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final source = _source;
    if (source == null) return;
    final result = await _sourceRepo.delete(widget.sourceId);
    if (result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sourceDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () async {
              await _sourceRepo.create(source);
            },
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            )),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}


