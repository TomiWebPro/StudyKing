import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

final Logger _logger = const Logger('LessonsNeedingReviewCard');

final lessonsNeedingReviewProvider =
    FutureProvider.autoDispose.family<List<LessonFeedbackModel>, String>(
        (ref, studentId) {
  final repo = ref.watch(lessonFeedbackRepositoryProvider);
  return repo.getAll().then((result) => result.fold(
        (data) => data.where((f) => f.studentId == studentId).toList(),
        (error) {
          _logger.w('Failed to load lessons needing review: $error');
          return <LessonFeedbackModel>[];
        },
      ));
});

class LessonsNeedingReviewCard extends ConsumerWidget {
  final String studentId;

  const LessonsNeedingReviewCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncItems = ref.watch(lessonsNeedingReviewProvider(studentId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncItems.when(
          loading: () => const LinearProgressIndicator(minHeight: 4),
          error: (_, __) => Text(l10n.errorOccurred),
          data: (items) {
            final flagged = items.where(_needsReview).toList();
            if (flagged.isEmpty) {
              return Text(
                l10n.lessonsNeedingReviewEmpty,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.lessonsNeedingReviewTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...flagged.map(
                  (f) => _ReviewRow(
                    feedback: f,
                    l10n: l10n,
                    theme: theme,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _needsReview(LessonFeedbackModel f) =>
      f.reportedIncorrect || (f.starRating > 0 && f.starRating <= 2);
}

class _ReviewRow extends StatelessWidget {
  final LessonFeedbackModel feedback;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ReviewRow({
    required this.feedback,
    required this.l10n,
    required this.theme,
  });

  String _targetLabel() {
    switch (feedback.targetTypeEnum) {
      case FeedbackTargetType.lesson:
        return l10n.feedbackTargetLesson;
      case FeedbackTargetType.content:
        return l10n.feedbackTargetContent;
      case FeedbackTargetType.explanation:
        return l10n.feedbackTargetExplanation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowRated = feedback.starRating > 0 && feedback.starRating <= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLowRated)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            ),
          if (isLowRated) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _targetLabel(),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (feedback.reportedIncorrect) ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(l10n.feedbackReportedBadge),
                        avatar: const Icon(Icons.flag_outlined, size: 14),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
                if (feedback.comment != null && feedback.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      feedback.comment!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
