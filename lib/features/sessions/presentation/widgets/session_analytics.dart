import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SessionAnalyticsWidget extends StatelessWidget {
  final List<Session> sessions;
  final int currentStreak;
  final int daysToShow;
  final DateTime? asOf;
  final bool reduceMotion;

  const SessionAnalyticsWidget({
    super.key,
    required this.sessions,
    required this.currentStreak,
    this.daysToShow = 7,
    this.asOf,
    this.reduceMotion = false,
  });

  Duration get _totalStudyTime => sessions.fold(
    Duration.zero,
    (sum, s) => sum + s.actualDuration,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final now = asOf ?? DateTime.now();
    final dayOfWeekCounts = _getSessionCountByDayOfWeek(now, l10n.localeName);
    final avgTimePerSession = sessions.isNotEmpty
        ? _totalStudyTime ~/ sessions.length
        : Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.sessionsByDayOfWeek, Icons.calendar_month, theme),
        const SizedBox(height: 12),
        AnimatedBarChart(
          data: dayOfWeekCounts,
          accentColor: theme.primaryColor,
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(l10n.performanceMetrics, Icons.show_chart, theme),
        const SizedBox(height: 12),
        _buildMetricCards(context, l10n, avgTimePerSession),
      ],
    );
  }

  Map<String, int> _getSessionCountByDayOfWeek(DateTime now, String localeName) {
    final counts = <String, int>{};

    for (var i = 0; i < daysToShow; i++) {
      final date = now.subtract(Duration(days: i));
      final dayName = DateFormat.E(localeName).format(date);

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

  Widget _buildMetricCards(BuildContext context, AppLocalizations l10n, Duration avgTimePerSession) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: l10n.avgSession,
                value: avgTimePerSession > Duration.zero
                    ? formatDurationFromContext(context, avgTimePerSession)
                    : '\u2014',
                icon: Icons.timer,
                accent: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: l10n.totalSessionsLabel,
                value: sessions.length.toString(),
                icon: Icons.history,
                accent: scheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: l10n.currentStreakLabel,
                value: l10n.daysCount(currentStreak),
                icon: Icons.emoji_events,
                accent: scheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: l10n.totalTime,
                value: formatDurationFromContext(context, _totalStudyTime),
                icon: Icons.access_time,
                accent: scheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
