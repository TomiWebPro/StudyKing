import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'lesson_booking_sheet.dart';

class ScheduledLessonsSection extends ConsumerWidget {
  const ScheduledLessonsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);
    final lessons = state.scheduledLessons;

    if (lessons.isEmpty) return const SizedBox.shrink();

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.scheduledLessons,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...lessons.take(3).map((lesson) {
            final time = DateFormat.jm(l10n.localeName).format(lesson.startTime);
            final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '';
            final isCompleted = lesson.status == SessionStatus.completed || lesson.completed;
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: Icon(
                  isCompleted ? Icons.check_circle : Icons.menu_book,
                  size: 20,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    )),
                subtitle: Text(
                  l10n.lessonTimeStatus(lesson.topicId ?? '', time, isCompleted ? ', ${l10n.completed}' : ''),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompleted)
                      Semantics(
                        button: true,
                        label: l10n.startTutoring,
                        child: IconButton(
                          icon: Icon(Icons.play_circle_filled, size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          tooltip: l10n.startTutoring,
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.tutor,
                            arguments: TutorArgs(
                              topicId: lesson.topicId ?? '',
                              topicTitle: title,
                              subjectId: lesson.subjectId ?? '',
                              durationMinutes: lesson.plannedDurationMinutes ?? 45,
                              scheduledSessionId: lesson.id,
                            ),
                          ),
                        ),
                      ),
                    if (!isCompleted)
                      IconButton(
                        icon: Icon(Icons.refresh, size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        tooltip: l10n.rescheduleLesson,
                        onPressed: () => _openRescheduleLesson(context, ref, lesson, l10n),
                      ),
                    if (!isCompleted)
                      IconButton(
                        icon: Icon(Icons.cancel_outlined, size: 18,
                            color: Theme.of(context).colorScheme.error),
                        tooltip: l10n.cancel,
                        onPressed: () => _confirmCancelLesson(context, ref, lesson, l10n),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (lessons.length > 3)
            TextButton(
              onPressed: () {
                final first = lessons.first;
                if (first.topicId == null || first.topicId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noTopicsAvailable)),
                  );
                  return;
                }
                Navigator.pushNamed(context, AppRoutes.lessonList,
                    arguments: LessonListArgs(
                      topicId: first.topicId!,
                      topicTitle: l10n.scheduledLessons,
                      subjectId: first.subjectId,
                    ));
              },
              child: Text(l10n.moreLessonsCount(lessons.length - 3)),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelLesson(BuildContext context, WidgetRef ref, Session lesson, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel),
        content: Text(l10n.cancelLessonConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.noThanks),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppTheme.destructiveButtonStyle(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(plannerProvider.notifier).cancelLesson(lesson.id, l10n);
    }
  }

  Future<void> _openRescheduleLesson(BuildContext context, WidgetRef ref, Session lesson, AppLocalizations l10n) async {
    final plannerService = ref.read(plannerServiceProvider);
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LessonBookingSheet(
        topicId: lesson.topicId ?? '',
        topicTitle: lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '',
        subjectId: lesson.subjectId ?? '',
        plannerService: plannerService,
        initialDate: lesson.startTime,
        initialDuration: lesson.plannedDurationMinutes ?? 30,
        excludeSessionId: lesson.id,
        onSchedule: (scheduledTime, durationMinutes) async {
          await ref.read(plannerProvider.notifier).rescheduleLesson(
                sessionId: lesson.id,
                newStartTime: scheduledTime,
                durationMinutes: durationMinutes,
                l10n: l10n,
              );
        },
      ),
    );
  }
}
