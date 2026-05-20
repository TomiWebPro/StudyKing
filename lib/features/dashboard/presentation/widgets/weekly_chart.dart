import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/widgets/animated_bar_chart.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class WeeklyChart extends ConsumerWidget {
  final List<WeeklyTrendEntry> weeklyTrend;

  const WeeklyChart({super.key, required this.weeklyTrend});

  Map<String, int> _fallbackDayLabels(String localeName) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return {
      for (var i = 0; i < 7; i++)
        DateFormat.E(localeName).format(startOfWeek.add(Duration(days: i))): 0,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trend = weeklyTrend.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Semantics(
                headingLevel: 3,
                child: Text(
                  l10n.weeklyActivity,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        if (trend.isEmpty)
          AnimatedBarChart(
            data: _fallbackDayLabels(l10n.localeName),
            accentColor: theme.colorScheme.primary,
            reduceMotion: ref.watch(settingsProvider).reduceMotion,
            semanticsLabelBuilder: (day, count) =>
                '$day: $count ${l10n.sessionsLabel}',
          )
        else
          _buildChart(trend, l10n, theme, ref),
      ],
    );
  }

  Widget _buildChart(
    List<WeeklyTrendEntry> trend,
    AppLocalizations l10n,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final chartData = <String, int>{};
    final gapWeeks = <String>{};
    for (var i = 0; i < trend.length; i++) {
      final item = trend[i];
      final weeksAgo = trend.length - 1 - i;
      final weekLabel = weeksAgo == 0
          ? l10n.thisWeek
          : l10n.weekNumber(weeksAgo);
      chartData[weekLabel] = item.attempts;
      if (item.isGap) {
        gapWeeks.add(weekLabel);
      }
    }

    return Column(
      children: [
        AnimatedBarChart(
          data: chartData,
          accentColor: theme.colorScheme.primary,
          reduceMotion: ref.watch(settingsProvider).reduceMotion,
          gapWeeks: gapWeeks,
          semanticsLabelBuilder: (day, count) => gapWeeks.contains(day)
              ? l10n.noActivity
              : '$day: $count ${l10n.sessionsLabel}',
        ),
        if (gapWeeks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(l10n.noActivity,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
      ],
    );
  }
}
