import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectStatsTab extends StatelessWidget {
  final String subjectId;

  const SubjectStatsTab({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionRepo = StudySessionRepository();

    Future<List<StudySession>> loadSessions() async {
      try {
        final sessions = await sessionRepo.getAll();
        return sessions.where((s) => s.subjectId == subjectId).toList();
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
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    l10n.sessionsLabel,
                    totalSessions.toString(),
                    Icons.how_to_vote,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    l10n.accuracy,
                    '${avgScore.toStringAsFixed(1)}%',
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
                    totalQuestions.toString(),
                    Icons.question_answer,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    l10n.time,
                    formatDurationFromContext(context, Duration(milliseconds: totalTime)),
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
                          '${avgScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(context, avgScore),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: avgScore / 100,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return MetricCard(
      label: label,
      value: value,
      icon: icon,
      accent: color,
    );
  }

  Color _scoreColor(BuildContext context, double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 80) return cs.primary;
    if (score >= 50) return cs.tertiary;
    return cs.error;
  }
}
