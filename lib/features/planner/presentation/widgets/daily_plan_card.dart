import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class DailyPlanCard extends StatelessWidget {
  final DailyPlan day;
  final void Function(String topicId, String topicTitle, String subjectId)
      onStartTutoring;
  final void Function(String topicId, String topicTitle, String subjectId)?
      onScheduleLesson;
  final VoidCallback? onCatchUp;

  const DailyPlanCard({
    super.key,
    required this.day,
    required this.onStartTutoring,
    this.onScheduleLesson,
    this.onCatchUp,
  });

  bool get _isPast {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return day.date.isBefore(todayStart);
  }

  bool get _isToday {
    final now = DateTime.now();
    final dayStart = DateTime(day.date.year, day.date.month, day.date.day);
    final todayStart = DateTime(now.year, now.month, now.day);
    return dayStart == todayStart;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isPast = _isPast;
    final isToday = _isToday;
    final opacity = isPast && day.isCompleted ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: day.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer,
                    child: day.isCompleted
                        ? Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary)
                        : Text('${day.dayNumber}',
                            style: theme.textTheme.bodySmall),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day.focus ?? l10n.studyDay,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: day.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (isToday && !day.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.today,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                    ),
                  if (isPast && !day.isCompleted && !day.isRestDay)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.missedLessonLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          )),
                    ),
                  if (day.isRestDay)
                    Chip(
                      label: Text(l10n.rest, style: theme.textTheme.labelSmall),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (!day.isRestDay)
                    Text(
                      l10n.questionsAndMinutes(
                          day.targetQuestions, day.targetMinutes),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              if (!day.isRestDay && day.priorityTopics.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...day.priorityTopics.map((topic) => SizedBox(
                      height: 48,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.school,
                            size: 18,
                            color: theme.colorScheme.primary),
                        title: Text(topic.topicTitle,
                            style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                          l10n.topicQuestionsAndMinutes(
                              topic.estimatedQuestions, topic.estimatedMinutes),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: topic.topicId.isNotEmpty && !isPast
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onScheduleLesson != null)
                                    Semantics(
                                      button: true,
                                      label: l10n.scheduleLesson,
                                      child: IconButton(
                                        icon: const Icon(Icons.event, size: 20),
                                        tooltip: l10n.scheduleLesson,
                                        onPressed: () => onScheduleLesson!(
                                            topic.topicId,
                                            topic.topicTitle,
                                            topic.subjectId),
                                      ),
                                    ),
                                  Semantics(
                                    button: true,
                                    label: l10n.startTutoring,
                                    child: IconButton(
                                      icon: const Icon(Icons.smart_toy_outlined, size: 20),
                                      tooltip: l10n.startTutoring,
                                      onPressed: () => onStartTutoring(
                                          topic.topicId, topic.topicTitle, topic.subjectId),
                                    ),
                                  ),
                                ],
                              )
                            : (isPast && !day.isCompleted && onCatchUp != null
                                ? TextButton.icon(
                                    onPressed: onCatchUp,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text(l10n.catchUp),
                                  )
                                : null),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
