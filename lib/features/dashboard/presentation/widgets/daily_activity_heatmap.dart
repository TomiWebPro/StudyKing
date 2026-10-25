import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Whole calendar days from [a] to [b] (`b - a`). Both arguments
/// are local calendar midnights; the computation is done on
/// UTC-normalized dates so a DST transition (a 23h or 25h
/// calendar day) cannot shift the result the way elapsed-time
/// `difference().inDays` does.
int _calendarDaysBetween(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcB.difference(utcA).inDays;
}

class DailyActivityHeatmap extends StatelessWidget {
  final List<DailyTrendEntry> dailyTrend;

  /// Current time; overridable in tests. Defaults to [DateTime.now].
  final DateTime? now;

  const DailyActivityHeatmap({super.key, required this.dailyTrend, this.now});

  static const double _cellSize = 12.0;
  static const double _cellGap = 2.0;

  Color _colorForScore(BuildContext context, double score) {
    final scheme = Theme.of(context).colorScheme;
    if (score <= 0.0) return scheme.surfaceContainerHighest;
    if (score <= 0.25) return const Color(0xFF9BE9A8);
    if (score <= 0.50) return const Color(0xFF40C463);
    if (score <= 0.75) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (dailyTrend.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n, theme),
          const SizedBox(height: 12),
          Text(
            l10n.heatmapNoActivity,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final sorted = List<DailyTrendEntry>.from(dailyTrend)
      ..sort((a, b) => a.date.compareTo(b.date));

    final dateMap = <DateTime, DailyTrendEntry>{};
    for (final entry in sorted) {
      dateMap[entry.date.dateOnly] = entry;
    }

    final today = (now ?? DateTime.now()).dateOnly;
    final endDate = today;
    // Align the grid to the start of the week (Monday) containing the
    // first activity so the fixed row labels (row 0 = Monday) match the
    // actual weekday of every row, GitHub-style. Cells before the first
    // activity have no entry and render empty.
    final firstActivity = sorted.first.date.dateOnly;
    // Calendar-day arithmetic, not 24h Duration arithmetic: across a
    // DST transition a local midnight is 23h/25h from the next one, so
    // subtract/add(Duration(days: ...)) lands an hour off midnight and
    // difference().inDays truncates a day — which drops the transition
    // day's cell and shortens the grid. Constructing the date directly
    // (the local DateTime constructor normalizes day overflow) and
    // differencing UTC-normalized midnights keeps every cell on the
    // correct calendar day in every timezone.
    final startDate = DateTime(firstActivity.year, firstActivity.month,
        firstActivity.day - (firstActivity.weekday - DateTime.monday));

    final totalDays = _calendarDaysBetween(startDate, endDate) + 1;
    final weeksCount = (totalDays / 7).ceil();

    final columns = <List<DailyTrendEntry?>>[];
    for (var w = 0; w < weeksCount; w++) {
      final column = <DailyTrendEntry?>[];
      for (var d = 0; d < 7; d++) {
        final dayOffset = w * 7 + d;
        final date = DateTime(
            startDate.year, startDate.month, startDate.day + dayOffset);
        if (date.isAfter(endDate)) {
          column.add(null);
        } else {
          column.add(dateMap[date.dateOnly]);
        }
      }
      columns.add(column);
    }

    final dayLabels = [
      l10n.localeName == 'es' ? 'L' : 'M',
      '',
      l10n.localeName == 'es' ? 'X' : 'W',
      '',
      l10n.localeName == 'es' ? 'V' : 'F',
      '',
      '',
    ];

    final monthLabels = _computeMonthLabels(columns, startDate, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(l10n, theme),
        const SizedBox(height: 12),
        _buildMonthLabels(monthLabels, theme),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: List.generate(7, (rowIndex) {
                return SizedBox(
                  height: _cellSize,
                  width: 14,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      dayLabels[rowIndex],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns.map((column) {
                    return Padding(
                      padding: const EdgeInsets.only(right: _cellGap),
                      child: Column(
                        children: List.generate(7, (rowIndex) {
                          final entry = rowIndex < column.length
                              ? column[rowIndex]
                              : null;
                          if (entry == null) {
                            return SizedBox(
                              width: _cellSize,
                              height: _cellSize,
                            );
                          }
                          final color =
                              _colorForScore(context, entry.compositeScore);
                          return Tooltip(
                            message: _tooltipText(entry, l10n),
                            child: Semantics(
                              label: _semanticLabel(entry, l10n),
                              child: Container(
                                width: _cellSize,
                                height: _cellSize,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(l10n, theme),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.calendar_view_day, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Semantics(
            headingLevel: 3,
            child: Text(
              l10n.heatmapTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthLabels(List<_MonthLabel> labels, ThemeData theme) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 14,
      child: Stack(
        children: labels.map((label) {
          return Positioned(
            left: label.offset * (_cellSize + _cellGap) + 18,
            child: Text(
              label.text,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(AppLocalizations l10n, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n.heatmapNoActivity,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 8,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _legendColor(i),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _legendColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF9BE9A8);
      case 1:
        return const Color(0xFF40C463);
      case 2:
        return const Color(0xFF30A14E);
      case 3:
        return const Color(0xFF216E39);
      default:
        return const Color(0xFF9BE9A8);
    }
  }

  String _tooltipText(DailyTrendEntry entry, AppLocalizations l10n) {
    final dateStr = DateFormat.yMMMd(l10n.localeName).format(entry.date);
    final focusMinutes = entry.focusSeconds ~/ 60;
    final focusStr = focusMinutes > 0 ? '${focusMinutes}m' : '0m';
    return l10n.heatmapTooltip(
      dateStr,
      entry.attempts,
      entry.accuracy.round(),
      focusStr,
      entry.sessions,
    );
  }

  String _semanticLabel(DailyTrendEntry entry, AppLocalizations l10n) {
    final dateStr = DateFormat.yMMMd(l10n.localeName).format(entry.date);
    if (entry.attempts == 0) {
      return '$dateStr: ${l10n.heatmapNoActivity}';
    }
    return '$dateStr: ${entry.attempts} ${l10n.sessionsLabel}, ${entry.accuracy.round()}%';
  }

  List<_MonthLabel> _computeMonthLabels(
    List<List<DailyTrendEntry?>> columns,
    DateTime startDate,
    AppLocalizations l10n,
  ) {
    final labels = <_MonthLabel>[];
    final monthFormat = DateFormat.MMM(l10n.localeName);
    DateTime? lastMonth;

    for (var i = 0; i < columns.length; i++) {
      final firstDayOfWeek = DateTime(
          startDate.year, startDate.month, startDate.day + i * 7);
      final month = DateTime(firstDayOfWeek.year, firstDayOfWeek.month);
      if (lastMonth == null || month != lastMonth) {
        labels.add(_MonthLabel(
          text: monthFormat.format(firstDayOfWeek),
          offset: i,
        ));
        lastMonth = month;
      }
    }
    return labels;
  }
}

class _MonthLabel {
  final String text;
  final int offset;

  const _MonthLabel({required this.text, required this.offset});
}
