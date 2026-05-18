import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/loading_screen.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_lessons_tab.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_practice_tab.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_history_tab.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_stats_tab.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final SubjectDetailArgs args;
  final SessionRepository? sessionRepository;

  const SubjectDetailScreen({
    super.key,
    required this.args,
    this.sessionRepository,
  });

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _sourceCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSourceCount();
  }

  Future<void> _loadSourceCount() async {
    try {
      final repo = SourceRepository();
      await repo.init();
      final sources = await repo.getBySubject(widget.args.subjectId);
      if (mounted) setState(() => _sourceCount = sources.length);
    } catch (e) {
      const Logger('SubjectDetailScreen').e('Failed to load source count: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ColorUtils.stringToColor(widget.args.subjectColor);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: (MediaQuery.sizeOf(context).height * 0.25).clamp(100.0, 200.0),
            floating: false,
            pinned: true,
            backgroundColor: color.withValues(alpha: 0.1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                                    widget.args.subjectName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color.withValues(alpha: 0.4),
                    ],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: ResponsiveUtils.screenPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.colorScheme.surface,
                                  child: Text(
                                    widget.args.subjectName.isNotEmpty ? widget.args.subjectName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                widget.args.subjectName,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.args.subjectCode != null)
                                        Text(
                                          widget.args.subjectCode!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: l10n.settings,
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    color: theme.colorScheme.onPrimary,
                                    tooltip: l10n.moreOptions,
                                    onPressed: () => _showMoreOptions(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: color,
              tabs: [
                Tab(icon: const Icon(Icons.book), text: l10n.lessonsTab),
                Tab(icon: const Icon(Icons.play_arrow), text: l10n.practiceTab),
                Tab(icon: const Icon(Icons.source), text: l10n.sources),
                Tab(icon: const Icon(Icons.history), text: l10n.historyTab),
                Tab(icon: const Icon(Icons.bar_chart), text: l10n.statsTab),
              ],
            ),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: ResponsiveUtils.screenPadding(context),
              child: TabBarView(
                controller: _tabController,
                children: [
                  SubjectLessonsTab(subjectId: widget.args.subjectId),
                  SubjectPracticeTab(
                    onStartPractice: () => _startPractice(isSpacedRepetition: false),
                    onStartSpacedRepetition: () => _startPractice(isSpacedRepetition: true),
                  ),
                  _SubjectSourcesTab(subjectId: widget.args.subjectId, subjectName: widget.args.subjectName),
                  SubjectHistoryTab(
                    subjectId: widget.args.subjectId,
                    onSessionTap: (session) => _showSessionDetails(session),
                    sessionRepository: widget.sessionRepository,
                  ),
                  SubjectStatsTab(subjectId: widget.args.subjectId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startPractice({required bool isSpacedRepetition}) {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(
        subjectId: widget.args.subjectId,
        isSpacedRepetition: isSpacedRepetition,
      ),
    );
  }

  void _showMoreOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: l10n.editSubject,
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.editSubject),
                onTap: () {
                  Navigator.pop(context);
                  _editSubject();
                },
              ),
            ),
            Semantics(
              label: l10n.uploadContent,
              child: ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: Text(l10n.uploadContent),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.upload,
                    arguments: widget.args.subjectId,
                  );
                },
              ),
            ),
            if (_sourceCount > 0)
              Semantics(
                label: l10n.viewSources,
                child: ListTile(
                  leading: const Icon(Icons.source),
                  title: Text(l10n.sourcesCountLabel(_sourceCount)),
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(2);
                  },
                ),
              ),
            Semantics(
              label: l10n.dashboard,
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                title: Text(l10n.dashboard),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.dashboard,
                    arguments: DashboardArgs(
                      studentId: StudentIdService().getStudentId(),
                    ),
                  );
                },
              ),
            ),
            Semantics(
              label: l10n.deleteSubject,
              child: ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.deleteSubject, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSubject() async {
    if (!mounted) return;
    try {
      final repo = await ref.read(subjectsRepositoryProvider.future);
      final subjectResult = await repo.get(widget.args.subjectId);
      final subject = subjectResult.data;
      if (subject == null || !mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.subjectSelection,
        arguments: subject,
      );
    } catch (e) {
      const Logger('SubjectDetailScreen').e('Failed to edit subject: $e');
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSubject),
        content: Text(l10n.deleteSubjectConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final repo = await ref.read(subjectsRepositoryProvider.future);
      await repo.delete(widget.args.subjectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteSubject)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
      );
    }
  }

  void _showSessionDetails(Session session) {
    final questions = session.questionsAnswered;
    final correct = session.correctAnswers;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sessionDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(l10n.date, formatDateFromContext(context, session.startTime)),
            _detailRow(l10n.duration, formatDurationFromContext(context, session.actualDuration)),
            _detailRow(l10n.questions, formatDecimal(questions.toDouble(), l10n.localeName)),
            if (correct > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.correctOf(correct, questions)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SubjectSourcesTab extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;

  const _SubjectSourcesTab({required this.subjectId, required this.subjectName});

  @override
  ConsumerState<_SubjectSourcesTab> createState() => _SubjectSourcesTabState();
}

class _SubjectSourcesTabState extends ConsumerState<_SubjectSourcesTab> {
  final _sourceRepo = SourceRepository();
  List<_SourceItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _sourceRepo.init();
      final sources = await _sourceRepo.getBySubject(widget.subjectId);
      if (mounted) {
        setState(() {
          _items = sources.map((s) => _SourceItem(
            id: s.id,
            title: s.title,
            type: s.type,
            status: s.statusEnum,
            questionCount: s.generatedQuestionIds.length,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      const Logger('SubjectDetailScreen').e('Failed to load sources', e);
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) return const LoadingScreen();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.somethingWentWrong, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(l10n.noSourcesForSubject, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: Text(l10n.uploadMaterials),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.upload, arguments: widget.subjectId),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            l10n.sourcesCount(_items.length),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              final cs = theme.colorScheme;
              final statusColor = item.status == ProcessingStatus.completed
                  ? cs.primary
                  : item.status == ProcessingStatus.failed
                      ? cs.error
                      : cs.tertiary;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(_typeIcon(item.type), color: theme.colorScheme.primary, size: 20),
                ),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _statusLabel(item.status, l10n),
                        style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (item.questionCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(l10n.questionsCount(item.questionCount), style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.sourceDetail, arguments: item.id),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _typeIcon(SourceType type) {
    switch (type) {
      case SourceType.pdf: return Icons.picture_as_pdf;
      case SourceType.syllabus: return Icons.menu_book;
      case SourceType.textbook: return Icons.book;
      case SourceType.video: return Icons.video_library;
      case SourceType.lectureNotes: return Icons.note;
      case SourceType.externalResource: return Icons.article;
      case SourceType.image: return Icons.image;
      case SourceType.webPage: return Icons.language;
      case SourceType.audio: return Icons.headphones;
      case SourceType.document: return Icons.description;
    }
  }
}

String _statusLabel(ProcessingStatus status, AppLocalizations l10n) {
  switch (status) {
    case ProcessingStatus.pending:
      return l10n.pending;
    case ProcessingStatus.extracting:
      return l10n.extracting;
    case ProcessingStatus.classifying:
      return l10n.processing;
    case ProcessingStatus.generatingQuestions:
      return l10n.generatingQuestions;
    case ProcessingStatus.validating:
      return l10n.validating;
    case ProcessingStatus.completed:
      return l10n.completed;
    case ProcessingStatus.failed:
      return l10n.failed;
  }
}

class _SourceItem {
  final String id;
  final String title;
  final SourceType type;
  final ProcessingStatus status;
  final int questionCount;

  const _SourceItem({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.questionCount,
  });
}
