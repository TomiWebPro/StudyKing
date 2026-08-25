import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ReportedFeedbackPanel extends ConsumerWidget {
  const ReportedFeedbackPanel({super.key});

  String _targetLabel(AppLocalizations l10n, String targetType) {
    switch (targetType) {
      case 'lesson':
        return l10n.feedbackTargetLesson;
      case 'content':
        return l10n.feedbackTargetContent;
      case 'explanation':
      default:
        return l10n.feedbackTargetExplanation;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reportedAsync = ref.watch(reportedLessonFeedbackProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
                    l10n.mentorReportedFeedbackHeading,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mentorReportedFeedbackSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            reportedAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 4),
              error: (_, __) => Text(
                l10n.errorOccurred,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      l10n.mentorReportedFeedbackNone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((item) => _ReportedFeedbackTile(
                            item: item,
                            targetLabel: _targetLabel(l10n, item.targetType),
                            l10n: l10n,
                            theme: theme,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportedFeedbackTile extends StatelessWidget {
  final LessonFeedbackModel item;
  final String targetLabel;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ReportedFeedbackTile({
    required this.item,
    required this.targetLabel,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final sentimentIcon = item.sentimentEnum == FeedbackSentiment.positive
        ? Icons.thumb_up_outlined
        : item.sentimentEnum == FeedbackSentiment.negative
            ? Icons.thumb_down_outlined
            : Icons.remove_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(sentimentIcon, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(targetLabel),
                      avatar: const Icon(Icons.flag_outlined, size: 14),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (item.starRating > 0) ...[
                      const SizedBox(width: 4),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < item.starRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: i < item.starRating
                                ? Colors.amber
                                : theme.colorScheme.onSurfaceVariant,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
                if (item.comment != null && item.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.comment!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (item.lessonId != null || item.messageId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.lessonId != null
                          ? '${l10n.feedbackTargetLesson}: ${item.lessonId}'
                          : '${l10n.feedbackTargetExplanation}: ${item.messageId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
