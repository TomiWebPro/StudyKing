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

  /// Fallback labels used when [weeklyTrend] is empty.
  /// Uses locale-aware short day names via DateFormat.E (invariant, OK for chart labels).
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
    final trend = weeklyTrend.take(7).toList();
    final chartData = <String, int>{};
    for (var i = 0; i < trend.length; i++) {
      final item = trend[i];
      final weekLabel = 'W${trend.length - i}';
      chartData[weekLabel] = item.attempts;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Semantics(
                headingLevel: 3,
                child: Text(
                  l10n.weeklyActivity,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        AnimatedBarChart(
          data: chartData.isNotEmpty
              ? chartData
              : _fallbackDayLabels(l10n.localeName),
          accentColor: Theme.of(context).colorScheme.primary,
          reduceMotion: ref.watch(settingsProvider).reduceMotion,
          semanticsLabelBuilder: (day, count) =>
              '$day: $count ${l10n.sessionsLabel.toLowerCase()}',
        ),
      ],
    );
  }
}
