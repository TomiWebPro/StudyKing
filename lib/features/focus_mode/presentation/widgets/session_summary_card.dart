import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/core/widgets/practice_performance_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SessionSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? todayStats;
  final int weeklyMs;
  final List<Session> recentSessions;
  final FocusSession? lastPracticeSession;

  const SessionSummaryCard({
    super.key,
    this.todayStats,
    this.weeklyMs = 0,
    this.recentSessions = const [],
    this.lastPracticeSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final stats = todayStats ?? {};
    final completed = stats['completedSessions'] as int? ?? 0;
    final total = stats['totalSessions'] as int? ?? 0;
    final todayMs = stats['totalMs'] as int? ?? (stats['totalSeconds'] as int? ?? 0) * msPerSecond;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.focusTime,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 400;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: narrow ? (constraints.maxWidth - 12) / 2 : 140),
                      child: MetricCard(
                        icon: Icons.access_time,
                        value: formatDurationFromContext(context, Duration(milliseconds: todayMs)),
                        label: l10n.today,
                        accent: cs.primary,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: narrow ? (constraints.maxWidth - 12) / 2 : 140),
                      child: MetricCard(
                        icon: Icons.date_range,
                        value: formatDurationFromContext(context, Duration(milliseconds: weeklyMs)),
                        label: l10n.thisWeek,
                        accent: cs.tertiary,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: narrow ? (constraints.maxWidth - 12) / 2 : 140),
                      child: MetricCard(
                        icon: Icons.check_circle,
                        value: '$completed/$total',
                        label: l10n.sessionsLabel,
                        accent: cs.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (lastPracticeSession != null && lastPracticeSession!.questionsAnswered > 0) ...[
              const SizedBox(height: 16),
              _buildPracticePerformance(context, theme, cs, l10n),
            ],
            if (recentSessions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.recentSessions,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...recentSessions.take(3).map((s) {
                final durStr = formatDurationFromContext(context, Duration(milliseconds: s.actualDurationMs));
                final plannedStr = formatDurationFromContext(context, Duration(minutes: s.plannedDurationMinutes ?? 0));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: MergeSemantics(
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            s.completed ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: s.completed ? cs.primary : cs.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$durStr / $plannedStr',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          DateFormat.Hm(l10n.localeName).format(s.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPracticePerformance(BuildContext context, ThemeData theme, ColorScheme cs, AppLocalizations l10n) {
    return PracticePerformanceCard(session: lastPracticeSession!);
  }
}
