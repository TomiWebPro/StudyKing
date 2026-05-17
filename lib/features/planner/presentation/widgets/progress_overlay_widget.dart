import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_format_utils.dart';
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
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            _buildTodayProgress(context, theme, l10n),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            _buildWeeklyChart(context, theme, l10n),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            _buildCumulativeProgress(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgress(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final progressColor = AppTheme.progressColor(data.todayProgress, context);

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
                formatPercent(data.todayProgress * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
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

  Widget _buildWeeklyChart(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    if (data.weeklyProgress.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.weekly,
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: ResponsiveUtils.verticalSpacing(context) * 8,
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
                      Semantics(
                        label: '${l10n.actual} ${day.actualMinutes} min',
                        child: Container(
                          width: 12,
                          height: actualH,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Semantics(
                        label: '${l10n.planned} ${day.plannedMinutes} min',
                        child: Container(
                          width: 12,
                          height: plannedH,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dayLabel,
                          style: theme.textTheme.labelSmall),
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
            Text(l10n.actual, style: theme.textTheme.labelSmall),
            const SizedBox(width: 12),
            Container(width: 8, height: 8, color: theme.colorScheme.primaryContainer),
            const SizedBox(width: 4),
            Text(l10n.planned, style: theme.textTheme.labelSmall),
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
            '${data.completedDays}/${data.totalPlanDays} ${l10n.days} — ${formatPercent(data.cumulativeProgress * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
