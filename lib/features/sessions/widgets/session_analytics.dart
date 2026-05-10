import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';

const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const double _minBarHeight = 40;
const double _maxBarHeight = 120;

class SessionAnalyticsWidget extends StatelessWidget {
  final List<StudySession> sessions;
  final Duration totalStudyTime;
  final int currentStreak;

  const SessionAnalyticsWidget({
    super.key,
    required this.sessions,
    required this.totalStudyTime,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayOfWeekCounts = _getSessionCountByDayOfWeek();
    final avgTimePerSession = sessions.isNotEmpty
        ? totalStudyTime ~/ sessions.length
        : Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Study Activity (Last 7 Days)', Icons.calendar_month, theme),
        const SizedBox(height: 12),
        _buildDayOfWeekChart(dayOfWeekCounts, theme),
        const SizedBox(height: 24),
        _buildSectionHeader('Performance Metrics', Icons.show_chart, theme),
        const SizedBox(height: 12),
        _buildMetricCards(theme, avgTimePerSession),
      ],
    );
  }

  Map<String, int> _getSessionCountByDayOfWeek() {
    final today = DateTime.now();
    final counts = <String, int>{};

    for (var i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dayName = _getDayName(date);

      counts[dayName] = sessions
          .where((s) =>
              s.startTime.year == date.year &&
              s.startTime.month == date.month &&
              s.startTime.day == date.day)
          .length;
    }

    return counts;
  }

  String _getDayName(DateTime date) {
    return _dayNames[date.weekday - 1];
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.textTheme.bodySmall?.color ?? Colors.grey),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDayOfWeekChart(Map<String, int> counts, ThemeData theme) {
    final maxCount = counts.values.isNotEmpty
        ? counts.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _dayNames.map((day) {
          final count = counts[day] ?? 0;
          final height = _minBarHeight + (count / maxCount * (_maxBarHeight - _minBarHeight));

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: count > 0
                      ? theme.primaryColor.withValues(alpha: 0.7 + (count / maxCount * 0.3))
                      : theme.disabledColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? theme.primaryColor : (theme.textTheme.bodySmall?.color ?? Colors.grey),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCards(ThemeData theme, Duration avgTimePerSession) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard('Avg Session', _formatDuration(avgTimePerSession), Icons.timer, Colors.blue, theme),
        _buildMetricCard('Total Sessions', sessions.length.toString(), Icons.history, Colors.green, theme),
        _buildMetricCard('Best Streak', '$currentStreak days', Icons.emoji_events, Colors.orange, theme),
        _buildMetricCard('Total Time', _formatDuration(totalStudyTime), Icons.access_time, Colors.purple, theme),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.3 : 0.2),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
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
              color: theme.textTheme.bodySmall?.color ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
