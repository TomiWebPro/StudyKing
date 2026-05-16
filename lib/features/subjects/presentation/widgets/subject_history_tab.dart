import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectHistoryTab extends StatelessWidget {
  final String subjectId;
  final void Function(Session session) onSessionTap;
  final SessionRepository? sessionRepository;

  const SubjectHistoryTab({
    super.key,
    required this.subjectId,
    required this.onSessionTap,
    this.sessionRepository,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionRepo = sessionRepository ?? SessionRepository();

    Future<List<Session>> loadSessions() async {
      try {
        final result = await sessionRepo.getAll();
        final sessions = result.data ?? [];
        return sessions.where((s) => s.subjectId == subjectId).toList();
      } catch (e) {
        return [];
      }
    }

    return FutureBuilder<List<Session>>(
      future: loadSessions(),
      builder: (context, snapshot) {
        final subjectSessions = snapshot.data ?? [];

        if (subjectSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
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
            final icon = _sessionIcon(session.type);
            final color = _sessionColor(session.type, context);

            return Card(
              margin: EdgeInsets.only(
                bottom: ResponsiveUtils.verticalSpacing(context) * 0.75,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _scoreColor(
                    context,
                    score,
                  ).withValues(alpha: 0.2),
                  child: Icon(icon, color: color),
                ),
                title: Row(
                  children: [
                    Text(l10n.sessionNumber(index + 1)),
                    const SizedBox(width: 8),
                    Icon(icon, size: 14, color: color),
                  ],
                ),
                subtitle: Text(
                  '${formatDateFromContext(context, session.startTime)} \u2022 ${formatDurationFromContext(context, session.actualDuration)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPercent(
                        score,
                        l10n.localeName,
                        minFractionDigits: 0,
                        maxFractionDigits: 0,
                      ),
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

  IconData _sessionIcon(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return Icons.timer;
      case SessionType.practice:
        return Icons.play_arrow;
      case SessionType.tutoring:
        return Icons.school;
      case SessionType.manual:
        return Icons.edit_note;
    }
  }

  Color _sessionColor(SessionType type, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case SessionType.focus:
        return cs.tertiary;
      case SessionType.practice:
        return cs.primary;
      case SessionType.tutoring:
        return cs.secondary;
      case SessionType.manual:
        return cs.onSurfaceVariant;
    }
  }

  Color _scoreColor(BuildContext context, double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 80) return cs.primary;
    if (score >= 50) return cs.tertiary;
    return cs.error;
  }
}
