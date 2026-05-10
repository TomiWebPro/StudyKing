import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/utils/time_utils.dart';

class SessionAnalyticsWidget extends StatelessWidget {
  final List<StudySession> sessions;
  final int currentStreak;
  final int daysToShow;
  final DateTime? asOf;

  const SessionAnalyticsWidget({
    super.key,
    required this.sessions,
    required this.currentStreak,
    this.daysToShow = 7,
    this.asOf,
  });

  Duration get _totalStudyTime => sessions.fold(
    Duration.zero,
    (sum, s) => sum + Duration(milliseconds: s.timeSpentMs),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = asOf ?? DateTime.now();
    final dayOfWeekCounts = _getSessionCountByDayOfWeek(now);
    final avgTimePerSession = sessions.isNotEmpty
        ? _totalStudyTime ~/ sessions.length
        : Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Sessions by Day of Week', Icons.calendar_month, theme),
        const SizedBox(height: 12),
        _buildDayOfWeekChart(dayOfWeekCounts, theme),
        const SizedBox(height: 24),
        _buildSectionHeader('Performance Metrics', Icons.show_chart, theme),
        const SizedBox(height: 12),
        _buildMetricCards(theme, avgTimePerSession),
      ],
    );
  }

  Map<String, int> _getSessionCountByDayOfWeek(DateTime now) {
    final counts = <String, int>{};

    for (var i = 0; i < daysToShow; i++) {
      final date = now.subtract(Duration(days: i));
      final dayName = DateFormat('E').format(date);

      counts[dayName] = sessions
          .where((s) => s.startTime.isSameDay(date))
          .length;
    }

    return counts;
  }

  Color _bodySmallColor(ThemeData theme) =>
      theme.textTheme.bodySmall?.color ?? Colors.grey;

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: _bodySmallColor(theme)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  static const _cardBorderRadius = BorderRadius.all(Radius.circular(12));
  static const _barBorderRadius = BorderRadius.all(Radius.circular(6));
  static const _chartPadding = EdgeInsets.all(16);
  static const _cardPadding = EdgeInsets.all(16);
  static const _chartMinBarHeight = 40.0;
  static const _chartMaxBarHeight = 120.0;

  Widget _buildDayOfWeekChart(Map<String, int> counts, ThemeData theme) {
    final rawMax = counts.values.isNotEmpty
        ? counts.values.reduce((a, b) => a > b ? a : b)
        : 0;
    final maxCount = rawMax > 0 ? rawMax : 1;

    return Container(
      padding: _chartPadding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: _cardBorderRadius,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: counts.keys.map((day) {
          final count = counts[day] ?? 0;
          final height = _chartMinBarHeight + (count / maxCount * (_chartMaxBarHeight - _chartMinBarHeight));

          return Column(
            key: ValueKey('bar_$day'),
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: height),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    width: 32,
                    height: value,
                    decoration: BoxDecoration(
                      color: count > 0
                          ? theme.primaryColor.withValues(alpha: 0.7 + (count / maxCount * 0.3))
                          : theme.disabledColor.withValues(alpha: 0.2),
                      borderRadius: _barBorderRadius,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  color: _bodySmallColor(theme),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? theme.primaryColor : _bodySmallColor(theme),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCards(ThemeData theme, Duration avgTimePerSession) {
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Session',
                avgTimePerSession > Duration.zero ? formatDuration(avgTimePerSession) : '\u2014',
                Icons.timer,
                scheme.primary,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Sessions',
                sessions.length.toString(),
                Icons.history,
                scheme.secondary,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Current Streak',
                '$currentStreak days',
                Icons.emoji_events,
                scheme.tertiary,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Time',
                _totalStudyTime > Duration.zero ? formatDuration(_totalStudyTime) : '0s',
                Icons.access_time,
                scheme.error,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, ThemeData theme, {VoidCallback? onTap}) {
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      key: ValueKey('metric_card_$label'),
      padding: _cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.3 : 0.2),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: _cardBorderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _bodySmallColor(theme),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: _cardBorderRadius,
        child: InkWell(
          borderRadius: _cardBorderRadius,
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}
