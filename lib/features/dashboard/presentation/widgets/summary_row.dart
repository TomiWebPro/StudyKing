import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SummaryRow extends StatelessWidget {
  final OverallStats? overallStats;

  const SummaryRow({super.key, this.overallStats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = overallStats ?? const OverallStats();
    final accuracy = stats.accuracy;
    final totalHours = stats.totalStudyTimeHours.toDouble();
    final weeklyActivity = stats.weeklyActivity;
    final topicsStudied = stats.topicsStudied;
    final bp = ResponsiveUtils.breakpointOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = {
          ScreenBreakpoint.xs: 2,
          ScreenBreakpoint.sm: 3,
          ScreenBreakpoint.md: 4,
          ScreenBreakpoint.lg: 4,
        }[bp] ?? 4;
        final gap = 12.0;
        final totalGap = gap * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalGap) / crossAxisCount;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                icon: Icons.check_circle,
                value: formatPercent(accuracy.toDouble(), l10n.localeName),
                label: l10n.accuracy,
                accent: AppTheme.progressColor(accuracy / 100.0, context),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                icon: Icons.timer,
                value: l10n.hoursAbbreviation(formatDecimal(totalHours, l10n.localeName, minFractionDigits: 1, maxFractionDigits: 1)),
                label: l10n.studyTime,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                icon: Icons.trending_up,
                value: '$weeklyActivity',
                label: l10n.weeklyActivity,
                accent: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                icon: Icons.book,
                value: '$topicsStudied',
                label: l10n.topics,
                accent: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
