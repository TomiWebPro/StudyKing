import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show selectedModelProvider;
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SourceDetailScreen extends ConsumerStatefulWidget {
  final String sourceId;

  const SourceDetailScreen({super.key, required this.sourceId});

  @override
  ConsumerState<SourceDetailScreen> createState() => _SourceDetailScreenState();
}

class _SourceDetailScreenState extends ConsumerState<SourceDetailScreen> {
  final _sourceRepo = SourceRepository();
  final _subjectRepo = SubjectRepository();
  final _topicRepo = TopicRepository();
  final _questionRepo = QuestionRepository();

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
        if (mounted) setState(() { _isLoading = false; _error = 'Source not found'; });
        return;
      }

      Subject? subject;
      if (source.subjectId.isNotEmpty) {
        final subjectResult = await _subjectRepo.get(source.subjectId);
        subject = subjectResult.data;
      }

      List<Topic> topics = [];
      if (source.subjectId.isNotEmpty) {
        topics = await _topicRepo.getBySubject(source.subjectId);
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
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _reprocess() async {
    final l10n = AppLocalizations.of(context)!;
    final source = _source;
    if (source == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprocess Source'),
        content: const Text('Reprocessing will replace existing generated questions. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Continue')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isReprocessing = true;
      _reprocessingStage = 'Reprocessing...';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reprocess failed: $e')),
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
    } catch (_) {} finally {
      if (mounted) setState(() => _isReprocessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _source == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Source Detail')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Source not found', style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
            ],
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
              tooltip: 'Reprocess',
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
              const PopupMenuItem(value: 'reprocess', child: Text('Reprocess')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
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
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_reprocessingStage),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: ResponsiveUtils.screenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Status', value: status.name),
                  if (subjectName.isNotEmpty)
                    _InfoRow(label: 'Subject', value: subjectName),
                  _InfoRow(label: 'Type', value: source.type.name),
                  _InfoRow(label: 'ID', value: source.id),
                  if (source.createdAt != null)
                    _InfoRow(label: 'Uploaded', value: formatDateFromContext(context, source.createdAt!)),

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
                          Expanded(child: Text('Processing failed', style: TextStyle(color: theme.colorScheme.error))),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(l10n.retry),
                            onPressed: _reprocess,
                          ),
                        ],
                      ),
                    ),

                  _SectionHeader(title: 'Topic Classification'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: topic != null
                                ? Text(topic.title)
                                : Text('Not yet classified', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          ),
                          if (_topics.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showTopicPicker(),
                            ),
                          if (topic == null && _topics.isNotEmpty)
                            TextButton(
                              onPressed: _classifyNow,
                              child: const Text('Classify Now'),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Summary'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        source.summary.isNotEmpty ? source.summary : 'No summary available',
                        style: TextStyle(
                          color: source.summary.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Extracted Text (${source.extractedText.length} chars)'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search in text',
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
                                child: source.extractedText.isNotEmpty
                                    ? Text(source.extractedText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))
                                    : Text(
                                        'No extracted text available',
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
                  _SectionHeader(title: 'Generated Questions (${_questions.length})'),
                  if (_questions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('No questions from this source', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    )
                  else
                    ...List.generate(_questions.length, (i) {
                      final q = _questions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                          ),
                          title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${q.type.name}  •  ${q.difficultyText ?? "Difficulty ${q.difficulty}"}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/question-bank');
                          },
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _reprocess,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reprocess'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(),
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      label: const Text('Delete'),
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
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Select Topic', style: Theme.of(ctx).textTheme.titleMedium),
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
        title: const Text('Delete Source'),
        content: const Text('Are you sure you want to delete this source?'),
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
          content: const Text('Source deleted'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
