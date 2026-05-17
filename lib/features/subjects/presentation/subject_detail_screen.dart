import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                                    widget.args.subjectName[0].toUpperCase(),
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
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: color,
              tabs: [
                Tab(icon: const Icon(Icons.book), text: l10n.lessonsTab),
                Tab(icon: const Icon(Icons.play_arrow), text: l10n.practiceTab),
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
      final subject = await repo.get(widget.args.subjectId);
      if (subject == null || !mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.subjectSelection,
        arguments: subject,
      );
    } catch (_) {}
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
            _detailRow(l10n.questions, questions.toString()),
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
