import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectStatsTab extends StatefulWidget {
  final String subjectId;
  final SessionRepository? sessionRepository;

  const SubjectStatsTab({
    super.key,
    required this.subjectId,
    this.sessionRepository,
  });

  @override
  State<SubjectStatsTab> createState() => _SubjectStatsTabState();
}

class _SubjectStatsTabState extends State<SubjectStatsTab> {
  late Future<List<Session>> _sessionsFuture;
  late Future<_SyllabusProgressData> _syllabusProgressFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
    _syllabusProgressFuture = _loadSyllabusProgress();
  }

  Future<List<Session>> _loadSessions() async {
    final sessionRepo = widget.sessionRepository ?? SessionRepository();
    final result = await sessionRepo.getAll();
    final sessions = result.data ?? [];
    return sessions.where((s) => s.subjectId == widget.subjectId).toList();
  }

  Future<_SyllabusProgressData> _loadSyllabusProgress() async {
    try {
      final topicRepo = TopicRepository();
      await topicRepo.init();
      final topicsResult = await topicRepo.getBySubject(widget.subjectId);
      final allTopics = topicsResult.data ?? [];

      if (allTopics.isEmpty) return const _SyllabusProgressData(totalTopics: 0, masteredCount: 0);

      final studentIdService = StudentIdService();
      await studentIdService.init();
      final studentId = studentIdService.getStudentId();
      if (studentId.isEmpty) return _SyllabusProgressData(totalTopics: allTopics.length, masteredCount: 0);

      final masteryRepo = MasteryStateRepository();
      await masteryRepo.init();
      final masteryResult = await masteryRepo.getAllMasteryStates(studentId);
      final states = masteryResult.data ?? [];

      final subjectMasteryStates = states.where((s) => s.topicId.isNotEmpty).toList();
      final masteredCount = subjectMasteryStates
          .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
          .length;

      return _SyllabusProgressData(totalTopics: allTopics.length, masteredCount: masteredCount);
    } catch (_) {
      return const _SyllabusProgressData(totalTopics: 0, masteredCount: 0);
    }
  }

  void _retry() {
    setState(() {
      _sessionsFuture = _loadSessions();
      _syllabusProgressFuture = _loadSyllabusProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<Session>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return Semantics(
            label: l10n.errorOccurred,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 12),
                    Text(l10n.errorOccurred, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final subjectSessions = snapshot.data ?? [];

        final totalSessions = subjectSessions.length;
        final totalQuestions = subjectSessions.fold<int>(
          0,
          (sum, s) => sum + s.questionsAnswered,
        );
        final totalCorrect = subjectSessions.fold<int>(
          0,
          (sum, s) => sum + s.correctAnswers,
        );
        final totalTime = subjectSessions.fold<int>(
          0,
          (sum, s) => sum + s.actualDurationMs,
        );
        final avgScore = totalQuestions > 0
            ? (totalCorrect / totalQuestions * 100)
            : 0.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.sessionsLabel,
                      formatDecimal(totalSessions.toDouble(), l10n.localeName),
                      Icons.how_to_vote,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.accuracy,
                      formatPercent(avgScore, l10n.localeName),
                      Icons.star,
                      _scoreColor(context, avgScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.questionsLabel,
                      formatDecimal(totalQuestions.toDouble(), l10n.localeName),
                      Icons.question_answer,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.time,
                      formatDurationFromContext(
                        context,
                        Duration(milliseconds: totalTime),
                      ),
                      Icons.access_time,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, l10n.practiceProgress),
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
                            formatPercent(avgScore, l10n.localeName),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(context, avgScore),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: avgScore.isNaN || !avgScore.isFinite ? 0.0 : avgScore / 100,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _scoreColor(context, avgScore),
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
              const SizedBox(height: 24),
              _buildSyllabusProgress(context, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSyllabusProgress(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<_SyllabusProgressData>(
      future: _syllabusProgressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        final data = snapshot.data;
        if (data == null || data.totalTopics == 0) {
          return const SizedBox.shrink();
        }

        final progress = data.masteredCount / data.totalTopics;
        final cs = Theme.of(context).colorScheme;
        final barColor = progress >= 0.8
            ? cs.primary
            : progress >= 0.5
                ? cs.tertiary
                : cs.error;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, l10n.syllabusLabel),
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
                        Text('${l10n.mastered} ${data.masteredCount} / ${data.totalTopics}'),
                        Text(
                          formatPercent(progress * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return MetricCard(label: label, value: value, icon: icon, accent: color);
  }

  Color _scoreColor(BuildContext context, double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 80) return cs.primary;
    if (score >= 50) return cs.tertiary;
    return cs.error;
  }
}

class _SyllabusProgressData {
  final int totalTopics;
  final int masteredCount;

  const _SyllabusProgressData({required this.totalTopics, required this.masteredCount});
}
