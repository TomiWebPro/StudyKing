import 'package:flutter/material.dart';
import '../../providers/planner_providers.dart';

class ProgressOverlayWidget extends StatelessWidget {
  final PlanProgressData data;

  const ProgressOverlayWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Text('Progress Overview',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildTodayProgress(theme),
            const SizedBox(height: 16),
            _buildWeeklyChart(theme),
            const SizedBox(height: 16),
            _buildCumulativeProgress(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgress(ThemeData theme) {
    final progressColor = data.todayProgress >= 1.0
        ? Colors.green
        : data.todayProgress >= 0.5
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Progress',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planned: ${data.plannedMinutesToday} min',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Actual: ${data.actualMinutesToday} min',
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

  Widget _buildWeeklyChart(ThemeData theme) {
    if (data.weeklyProgress.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
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
              final dayLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.date.weekday - 1];

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
            Text('Actual', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
            const SizedBox(width: 12),
            Container(width: 8, height: 8, color: theme.colorScheme.primaryContainer),
            const SizedBox(width: 4),
            Text('Planned', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _buildCumulativeProgress(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.trending_up, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${data.completedDays}/${data.totalPlanDays} days — ${(data.cumulativeProgress * 100).round()}% of plan',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
