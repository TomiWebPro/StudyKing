import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_lessons_tab.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_practice_tab.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_history_tab.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_stats_tab.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final SubjectDetailArgs args;
  final StudySessionRepository? sessionRepository;

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
            expandedHeight: MediaQuery.sizeOf(context).height * 0.25,
            floating: false,
            pinned: true,
            backgroundColor: color.withValues(alpha: 0.1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                                    widget.args.subjectName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
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
                                  backgroundColor: Colors.white,
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
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.args.subjectCode != null)
                                        Text(
                                          widget.args.subjectCode!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: l10n.settings,
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    color: Colors.white,
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
                    arguments: {
                      'studentId': StudentIdService().getStudentId(),
                    },
                  );
                },
              ),
            ),
            Semantics(
              label: l10n.deleteSubject,
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.deleteSubject, style: const TextStyle(color: Colors.red)),
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

  void _confirmDelete() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSubject),
        content: Text(l10n.deleteSubjectConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(StudySession session) {
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
            _detailRow(l10n.duration, formatDurationFromContext(context, Duration(milliseconds: session.timeSpentMs))),
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
