import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import '../../../../l10n/generated/app_localizations.dart';

class CalendarViewWidget extends StatefulWidget {
  final PersonalLearningPlan plan;
  final void Function(String topicId, String topicTitle, String subjectId)?
      onDayTap;

  const CalendarViewWidget({
    super.key,
    required this.plan,
    this.onDayTap,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        _buildMonthHeader(theme, l10n),
        const SizedBox(height: 8),
        _buildDayHeaders(theme, l10n),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: _aspectRatio(context),
            ),
            itemCount: startWeekday + lastDay.day,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox.shrink();
              }
              final day = index - startWeekday + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              return _buildDayCell(context, theme, l10n, date, day);
            },
          ),
        ),
      ],
    );
  }

  double _aspectRatio(BuildContext context) {
    final bp = ResponsiveUtils.breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return 0.85;
      case ScreenBreakpoint.sm:
        return 1.0;
      case ScreenBreakpoint.md:
        return 1.0;
      case ScreenBreakpoint.lg:
        return 1.0;
    }
  }

  Widget _buildMonthHeader(ThemeData theme, AppLocalizations l10n) {
    final monthLabel = DateFormat.yMMM(l10n.localeName).format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: l10n.previous,
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.previous,
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
          ),
        ),
        Semantics(
          header: true,
          label: monthLabel,
          child: Text(
            monthLabel,
            style: theme.textTheme.titleMedium,
          ),
        ),
        Semantics(
          button: true,
          label: l10n.next,
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.next,
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(ThemeData theme, AppLocalizations l10n) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      return DateFormat.EEEE(l10n.localeName).format(date);
    });
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayCell(
      BuildContext context, ThemeData theme, AppLocalizations l10n, DateTime date, int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    final dailyPlan = widget.plan.dailyPlans.where((p) {
      final d = DateTime(p.date.year, p.date.month, p.date.day);
      return d == date;
    }).firstOrNull;

    final isRestDay = dailyPlan?.isRestDay ?? false;
    final hasTopics = (dailyPlan?.priorityTopics.length ?? 0) > 0;
    final isTappable = dailyPlan != null && dailyPlan.priorityTopics.isNotEmpty && widget.onDayTap != null;
    final dayLabel = '${DateFormat.MMMMd(l10n.localeName).format(date)}${isToday ? ', ${l10n.today}' : ''}';

    return Semantics(
      button: isTappable,
      label: dayLabel,
      child: InkWell(
        onTap: isTappable
            ? () {
                final first = dailyPlan.priorityTopics.first;
                widget.onDayTap!(first.topicId, first.topicTitle, first.subjectId);
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday
                ? theme.colorScheme.primaryContainer
                : isRestDay
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : hasTopics
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : null,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isRestDay
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                if (dailyPlan != null && !dailyPlan.isRestDay)
                  Text(
                    l10n.minutesCountMetric(dailyPlan.targetMinutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
