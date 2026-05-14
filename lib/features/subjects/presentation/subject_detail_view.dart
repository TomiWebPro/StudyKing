import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Subject Detail Screen - Shows all content for a subject
class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? subjectDescription;
  final String? subjectSyllabus;
  final String? subjectCode;
  final String? subjectTeacher;
  final String subjectColor;
  final String? subjectExamDate;
  final List<String> topicIds;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.subjectDescription,
    this.subjectSyllabus,
    this.subjectCode,
    this.subjectTeacher,
    required this.subjectColor,
    this.subjectExamDate,
    required this.topicIds,
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
    final color = ColorUtils.stringToColor(widget.subjectColor);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).height * 0.25,
            floating: false,
            pinned: true,
            backgroundColor: color.withValues(alpha: 0.1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.subjectName,
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
                                    widget.subjectName[0].toUpperCase(),
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
                                        widget.subjectName,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.subjectCode != null)
                                        Text(
                                          widget.subjectCode!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: l10n.editSubject,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.white,
                                    onPressed: () {
                                      // Navigate to edit screen
                                    },
                                  ),
                                ),
                                Semantics(
                                  label: l10n.settings,
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    color: Colors.white,
                                    onPressed: _showMoreOptions,
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

          // Tab content
          SliverFillRemaining(
            child: Padding(
              padding: ResponsiveUtils.screenPadding(context),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Lessons Tab
                  _buildLessonsTab(),

                  // Practice Tab
                  _buildPracticeTab(),

                  // History Tab
                  _buildHistoryTab(),

                  // Stats Tab
                  _buildStatsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Consumer(builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context)!;
      final lessonRepo = LessonRepository();
      
      Future<List<Lesson>> loadLessons() async {
        try {
          final lessons = await lessonRepo.getAll();
          return lessons.where((l) => l.subjectId == widget.subjectId).toList();
        } catch (e) {
          return [];
        }
      }

      return FutureBuilder<List<Lesson>>(
        future: loadLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjectLessons = snapshot.data ?? [];
          
          if (subjectLessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noLessonsYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.startLearningByCreatingTopics,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addTopic),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: subjectLessons.length,
            itemBuilder: (context, index) {
              final lesson = subjectLessons[index];
              return Card(
                margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(Icons.book, color: Theme.of(context).primaryColor),
                  ),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    l10n.blocksCount(lesson.blocks.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildPracticeTab() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: ResponsiveUtils.screenPadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            l10n.practiceMode,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.practiceModes,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Semantics(
            label: l10n.startPractice,
            child: FilledButton.icon(
              onPressed: () => _startPractice(isSpacedRepetition: false),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startPractice),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: l10n.practiceMode,
            child: OutlinedButton.icon(
              onPressed: () => _startPractice(isSpacedRepetition: true),
              icon: const Icon(Icons.repeat),
              label: Text(l10n.practiceMode),
            ),
          ),
        ],
      ),
    );
  }

  void _startPractice({required bool isSpacedRepetition}) {
    Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(
        subjectId: widget.subjectId,
        isSpacedRepetition: isSpacedRepetition,
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context)!;
      final sessionRepo = StudySessionRepository();
      
      Future<List<StudySession>> loadSessions() async {
        try {
          final sessions = await sessionRepo.getAll();
          return sessions.where((s) => s.subjectId == widget.subjectId).toList();
        } catch (e) {
          return [];
        }
      }

      return FutureBuilder<List<StudySession>>(
        future: loadSessions(),
        builder: (context, snapshot) {
          final subjectSessions = snapshot.data ?? [];
          
          if (subjectSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSessionsYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.startStudyingToTrack,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: subjectSessions.length,
            itemBuilder: (context, index) {
              final session = subjectSessions[index];
              final score = session.questionsAnswered > 0
                  ? (session.correctAnswers / session.questionsAnswered) * 100
                  : 0.0;

              return Card(
                margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _scoreColor(score).withValues(alpha: 0.2),
                    child: Icon(
                      score >= 80
                          ? Icons.check_circle
                          : Icons.sticky_note_2,
                      color: _scoreColor(score),
                    ),
                  ),
                  title: Text(l10n.sessionNumber(index + 1)),
                  subtitle: Text(
                    '${formatDateFromContext(context, session.startTime)} • ${formatDurationFromContext(context, Duration(milliseconds: session.timeSpentMs))}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(score),
                        ),
                      ),
                      if (session.questionsAnswered > 0)
                        Text(
                          '${session.correctAnswers}/${session.questionsAnswered}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  onTap: () => _showSessionDetails(session),
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildStatsTab() {
    return Consumer(builder: (context, ref, child) {
      final l10n = AppLocalizations.of(context)!;
      final sessionRepo = StudySessionRepository();
      
      Future<List<StudySession>> loadSessions() async {
        try {
          final sessions = await sessionRepo.getAll();
          return sessions.where((s) => s.subjectId == widget.subjectId).toList();
        } catch (e) {
          return [];
        }
      }

      return FutureBuilder<List<StudySession>>(
        future: loadSessions(),
        builder: (context, snapshot) {
          final subjectSessions = snapshot.data ?? [];
          
          final totalSessions = subjectSessions.length;
          final totalQuestions = subjectSessions.fold<int>(0, (sum, s) => sum + s.questionsAnswered);
          final totalCorrect = subjectSessions.fold<int>(0, (sum, s) => sum + s.correctAnswers);
          final totalTime = subjectSessions.fold<int>(0, (sum, s) => sum + s.timeSpentMs);
          final avgScore = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;

          return Column(
            children: [
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      l10n.sessionsLabel,
                      totalSessions.toString(),
                      Icons.how_to_vote,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.accuracy,
                      '${avgScore.toStringAsFixed(1)}%',
                      Icons.star,
                      _scoreColor(avgScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      l10n.questionsLabel,
                      totalQuestions.toString(),
                      Icons.question_answer,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.time,
                      formatDurationFromContext(context, Duration(milliseconds: totalTime)),
                      Icons.access_time,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Practice Progress
              _buildSectionHeader(l10n.practiceProgress),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: ResponsiveUtils.cardPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.overallScore),
                          Text(
                            '${avgScore.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(avgScore),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: avgScore / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _scoreColor(avgScore),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.keepPracticing,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return MetricCard(
      label: label,
      value: value,
      icon: icon,
      accent: color,
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
                  // Navigate to edit screen
                },
              ),
            ),
            Semantics(
              label: l10n.settings,
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.settings),
                onTap: () {
                  Navigator.pop(context);
                  // Add settings
                },
              ),
            ),
            Semantics(
              label: 'Upload Content',
              child: ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Upload Content'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.upload,
                    arguments: widget.subjectId,
                  );
                },
              ),
            ),
            Semantics(
              label: 'Dashboard',
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
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
              // Delete subject logic
              Navigator.pop(context);
              if (mounted) Navigator.pop(context);
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

  Color _scoreColor(double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 80) return cs.primary;
    if (score >= 50) return cs.tertiary;
    return cs.error;
  }

}
