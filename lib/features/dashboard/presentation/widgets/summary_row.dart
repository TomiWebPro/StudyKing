import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SummaryRow extends StatelessWidget {
  final OverallStats? overallStats;

  const SummaryRow({super.key, this.overallStats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = overallStats ?? const OverallStats();
    final accuracy = stats.accuracy;
    final totalHours = stats.totalStudyTimeHours;
    final weeklyActivity = stats.weeklyActivity;
    final topicsStudied = stats.topicsStudied;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.check_circle,
                value: '$accuracy%',
                label: l10n.accuracy,
                accent: AppTheme.progressColor(accuracy / 100.0, context),
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.timer,
                value: '${totalHours}h',
                label: l10n.studyTime,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.trending_up,
                value: '$weeklyActivity',
                label: l10n.weeklyActivity,
                accent: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
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
