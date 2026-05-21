import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class MissedLessonsSection extends ConsumerWidget {
  const MissedLessonsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);
    final missedLessons = state.missedLessons;

    if (missedLessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.allCaughtUp,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber,
                  size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(l10n.missedLessonsCount(missedLessons.length),
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...missedLessons.take(3).map((lesson) {
            final time = DateFormat.jm(l10n.localeName).format(lesson.startTime);
            final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.cancel_outlined,
                    size: 20, color: Theme.of(context).colorScheme.error),
                title: Text(title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                    )),
                subtitle: Text(
                  '${l10n.missedLessonLabel}, $time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          }),
          if (missedLessons.length > 3)
            TextButton(
              onPressed: () {
                ref.read(plannerProvider.notifier).dismissAllMissed(l10n);
              },
              child: Text(l10n.dismissAllMissed),
            ),
        ],
      ),
    );
  }
}
