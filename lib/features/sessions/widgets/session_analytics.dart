import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/study_session_model.dart';

/// Session Analytics Widget - Analytics and progress visualization
class SessionAnalyticsWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Calculate session counts by day of week
    final dayOfWeekCounts = _getSessionCountByDayOfWeek();
    
    // Calculate average time per session
    final avgTimePerSession = sessions.isNotEmpty 
        ? totalStudyTime ~/ sessions.length 
        : Duration.zero;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Study Time Distribution
        _buildSectionHeader('Study Activity (Last 7 Days)', Icons.calendar_month),
        const SizedBox(height: 12),
        _buildDayOfWeekChart(dayOfWeekCounts, theme),
        
        const SizedBox(height: 24),
        
        // Performance Metrics
        _buildSectionHeader('Performance Metrics', Icons.show_chart),
        const SizedBox(height: 12),
        _buildMetricCards(
          [
            MetricCardData(
              label: 'Avg Session',
              value: _formatDuration(avgTimePerSession),
              icon: Icons.timer,
              color: Colors.blue,
            ),
            MetricCardData(
              label: 'Total Sessions',
              value: sessions.length.toString(),
              icon: Icons.history,
              color: Colors.green,
            ),
            MetricCardData(
              label: 'Best Streak',
              value: '${_getBestStreak()} days',
              icon: Icons.emoji_events,
              color: Colors.orange,
            ),
            MetricCardData(
              label: 'Total Time',
              value: _formatDuration(totalStudyTime),
              icon: Icons.access_time,
              color: Colors.purple,
            ),
          ],
          theme,
        ),
      ],
    );
  }

  Map<String, int> _getSessionCountByDayOfWeek() {
    final today = DateTime.now();
    final counts = <String, int>{};
    
    for (var i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dayName = _getDayName(date);
      final dayStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      counts[dayName] = sessions
          .where((s) => s.startTime.toString().startsWith(dayStr))
          .length;
    }
    
    return counts;
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday % 7];
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDayOfWeekChart(Map<String, int> counts, ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxCount = counts.values.isNotEmpty ? counts.values.reduce((a, b) => a > b ? a : b) : 1;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final count = counts[day] ?? 0;
          final height = 40 + (count / maxCount * 80);
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: count > 0
                      ? theme.primaryColor.withOpacity(0.7 + (count / maxCount * 0.3))
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? theme.primaryColor : Colors.grey[400],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCards(List<MetricCardData> metrics, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: metrics.map((metric) => _buildMetricCard(metric, theme)).toList(),
    );
  }

  Widget _buildMetricCard(MetricCardData metric, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            metric.color.withOpacity(isDark ? 0.3 : 0.2),
            metric.color.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: metric.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            metric.icon,
            color: metric.color,
            size: 28,
          ),
          const Spacer(),
          Text(
            metric.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: metric.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
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

  int _getBestStreak() {
    // Simple best streak calculation (would be more complex in production)
    return currentStreak;
  }
}

class MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
