import 'package:flutter/material.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SessionSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? todayStats;
  final int weeklySeconds;
  final List<FocusSession> recentSessions;

  const SessionSummaryCard({
    super.key,
    this.todayStats,
    this.weeklySeconds = 0,
    this.recentSessions = const [],
  });

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final stats = todayStats ?? {};
    final todaySeconds = stats['totalSeconds'] as int? ?? 0;
    final completed = stats['completedSessions'] as int? ?? 0;
    final total = stats['totalSessions'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    SizedBox(
                      width: narrow ? (constraints.maxWidth - 12) / 2 : 140,
                      child: MetricCard(
                        icon: Icons.access_time,
                        value: _formatDuration(todaySeconds),
                        label: l10n.today,
                        accent: cs.primary,
                      ),
                    ),
                    SizedBox(
                      width: narrow ? (constraints.maxWidth - 12) / 2 : 140,
                      child: MetricCard(
                        icon: Icons.date_range,
                        value: _formatDuration(weeklySeconds),
                        label: l10n.thisWeek,
                        accent: cs.tertiary,
                      ),
                    ),
                    SizedBox(
                      width: narrow ? (constraints.maxWidth - 12) / 2 : 140,
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
                final dur = s.actualDurationSeconds;
                final durStr = _formatDuration(dur);
                final plannedStr = '${s.plannedDurationMinutes}m';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        s.completed ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: s.completed ? cs.primary : cs.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$durStr / $plannedStr',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
