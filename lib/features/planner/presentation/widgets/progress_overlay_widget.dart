import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/planner_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ProgressOverlayWidget extends StatelessWidget {
  final PlanProgressData data;

  const ProgressOverlayWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(l10n.progressOverview,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildTodayProgress(theme, l10n),
            const SizedBox(height: 16),
            _buildWeeklyChart(theme, l10n),
            const SizedBox(height: 16),
            _buildCumulativeProgress(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgress(ThemeData theme, AppLocalizations l10n) {
    final progressColor = data.todayProgress >= 1.0
        ? Colors.green
        : data.todayProgress >= 0.5
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.todaysProgress,
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.planned}: ${data.plannedMinutesToday} min',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${l10n.actual}: ${data.actualMinutesToday} min',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${(data.todayProgress * 100).round()}%',
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: data.todayProgress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, AppLocalizations l10n) {
    if (data.weeklyProgress.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.weekly,
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.weeklyProgress.map((day) {
              final maxVal = data.weeklyProgress
                  .fold<int>(0, (m, d) => m > d.plannedMinutes ? m : d.plannedMinutes);
              final plannedH = maxVal > 0
                  ? (day.plannedMinutes / maxVal * 60).clamp(4.0, 60.0)
                  : 4.0;
              final actualH = maxVal > 0
                  ? (day.actualMinutes / maxVal * 60).clamp(0.0, 60.0)
                  : 0.0;
              final dayLabel = DateFormat.E(l10n.localeName)
                  .format(day.date)
                  .substring(0, 1);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 12,
                        height: actualH,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 12,
                        height: plannedH,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dayLabel,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 8, height: 8, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(l10n.actual, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
            const SizedBox(width: 12),
            Container(width: 8, height: 8, color: theme.colorScheme.primaryContainer),
            const SizedBox(width: 4),
            Text(l10n.planned, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _buildCumulativeProgress(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Icon(Icons.trending_up, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${data.completedDays}/${data.totalPlanDays} ${l10n.days} — ${(data.cumulativeProgress * 100).round()}%',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
