import 'package:flutter/material.dart';
import '../../../../../core/data/models/personal_learning_plan_model.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class DailyPlanCard extends StatelessWidget {
  final DailyPlan day;
  final void Function(String topicId, String topicTitle, String subjectId)
      onStartTutoring;

  const DailyPlanCard({
    super.key,
    required this.day,
    required this.onStartTutoring,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.focus ?? l10n.studyDay,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (day.isRestDay)
                  Chip(
                    label:
                        Text(l10n.rest, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (!day.isRestDay)
                  Text(
                    l10n.questionsAndMinutes(
                        day.targetQuestions, day.targetMinutes),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            if (!day.isRestDay && day.priorityTopics.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...day.priorityTopics.map((topic) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.school,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(topic.topicTitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text(
                      l10n.topicQuestionsAndMinutes(
                          topic.estimatedQuestions, topic.estimatedMinutes),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: topic.topicId.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.smart_toy_outlined,
                                size: 20),
                            tooltip: l10n.startTutoring,
                            onPressed: () => onStartTutoring(
                                topic.topicId, topic.topicTitle, ''),
                          )
                        : null,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
