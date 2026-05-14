import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectHistoryTab extends StatelessWidget {
  final String subjectId;
  final void Function(StudySession session) onSessionTap;

  const SubjectHistoryTab({
    super.key,
    required this.subjectId,
    required this.onSessionTap,
  });

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

        if (subjectSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
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
                  backgroundColor: _scoreColor(context, score).withValues(alpha: 0.2),
                  child: Icon(
                    score >= 80
                        ? Icons.check_circle
                        : Icons.sticky_note_2,
                    color: _scoreColor(context, score),
                  ),
                ),
                title: Text(l10n.sessionNumber(index + 1)),
                subtitle: Text(
                  '${formatDateFromContext(context, session.startTime)} \u2022 ${formatDurationFromContext(context, Duration(milliseconds: session.timeSpentMs))}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _scoreColor(context, score),
                      ),
                    ),
                    if (session.questionsAnswered > 0)
                      Text(
                        '${session.correctAnswers}/${session.questionsAnswered}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                onTap: () => onSessionTap(session),
              ),
            );
          },
        );
      },
    );
  }

  Color _scoreColor(BuildContext context, double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 80) return cs.primary;
    if (score >= 50) return cs.tertiary;
    return cs.error;
  }
}
