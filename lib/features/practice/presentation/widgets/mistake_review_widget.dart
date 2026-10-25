import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';

class MistakeReviewWidget extends StatelessWidget {
  final List<MistakeEntry> mistakes;
  final VoidCallback? onRedo;
  final VoidCallback? onDismiss;

  /// Per-mistake remediation: invoked when the student taps "Try Variant" on
  /// a card whose question has already-generated variants. The exact question
  /// is passed so the caller can start a re-test with a fresh variant value
  /// (Vision: questions "expanded through generated variants" drive adaptive
  /// revision). Omitted when no action is available — the button is hidden.
  final void Function(MistakeEntry mistake)? onTryVariant;

  /// Per-mistake remediation: invoked when the student taps "Schedule Lesson"
  /// on a card (e.g. to route them to the mentor to book a remedial lesson on
  /// the weak concept). Omitted when no action is available — the button is
  /// hidden.
  final void Function(MistakeEntry mistake)? onScheduleLesson;

  const MistakeReviewWidget({
    super.key,
    required this.mistakes,
    this.onRedo,
    this.onDismiss,
    this.onTryVariant,
    this.onScheduleLesson,
  });

  static void show(
    BuildContext context, {
    required List<MistakeEntry> mistakes,
    VoidCallback? onRedo,
    VoidCallback? onDismiss,
    void Function(MistakeEntry mistake)? onTryVariant,
    void Function(MistakeEntry mistake)? onScheduleLesson,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppTheme.bottomSheetShape,
      builder: (context) => MistakeReviewWidget(
        mistakes: mistakes,
        onRedo: onRedo,
        onDismiss: onDismiss,
        onTryVariant: onTryVariant,
        onScheduleLesson: onScheduleLesson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            Row(
              children: [
                Icon(Icons.refresh, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  l10n.reviewMistakes,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            Text(
              l10n.reviewMistakesDescription(mistakes.length),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            if (mistakes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: ResponsiveUtils.emptyStateIconSize(context), color: Theme.of(context).colorScheme.primary),
                      SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                      Text(l10n.noMistakesToReview, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: mistakes.length,
                  separatorBuilder: (_, __) => SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                  itemBuilder: (context, index) {
                    final mistake = mistakes[index];
                    return _MistakeCard(
                      mistake: mistake,
                      index: index,
                      onTryVariant: onTryVariant,
                      onScheduleLesson: onScheduleLesson,
                    );
                  },
                ),
              ),
            if (mistakes.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRedo,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.redoIncorrectQuestions),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (onDismiss != null)
                    OutlinedButton(
                      onPressed: onDismiss,
                      child: Text(l10n.dismiss),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final MistakeEntry mistake;
  final int index;
  final void Function(MistakeEntry mistake)? onTryVariant;
  final void Function(MistakeEntry mistake)? onScheduleLesson;

  const _MistakeCard({
    required this.mistake,
    required this.index,
    this.onTryVariant,
    this.onScheduleLesson,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mistake.question.text,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            // Concept tag — surface which concept the student missed so the
            // review is a remediation step, not just a replay (vision:
            // questions "linked to topics/syllabi" + "identify weak areas").
            if (mistake.conceptLabel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sell_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mistake.conceptLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            _buildAnswerRow(
              context,
              l10n.yourAnswer,
              mistake.attempt?.userAnswer.isNotEmpty == true
                  ? mistake.attempt!.userAnswer
                  : l10n.noAnswerProvided,
              isIncorrect: true,
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            _buildAnswerRow(
              context,
              l10n.correctAnswer,
              mistake.correctAnswer,
              isCorrect: true,
            ),
            if (mistake.explanation != null && mistake.explanation!.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              _buildExplanationRow(context, l10n, mistake.explanation!),
            ],
            // Variant availability — tells the student a re-test with fresh
            // values already exists (vision: "expanded through generated
            // variants ... drive adaptive revision").
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.copy_all,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.variantCount(mistake.variantCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (onTryVariant != null || onScheduleLesson != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onTryVariant != null && mistake.variantCount > 0) ...[
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onTryVariant!(mistake),
                        icon: const Icon(Icons.copy_all, size: 18),
                        label: Text(l10n.tryVariant),
                      ),
                    ),
                    if (onScheduleLesson != null) const SizedBox(width: 12),
                  ],
                  if (onScheduleLesson != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onScheduleLesson!(mistake),
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(l10n.scheduleLesson),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerRow(
    BuildContext context,
    String label,
    String value, {
    bool isCorrect = false,
    bool isIncorrect = false,
  }) {
    final color = isCorrect
        ? Theme.of(context).colorScheme.primary
        : isIncorrect
            ? Theme.of(context).colorScheme.error
            : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicWidth(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: color != null ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationRow(BuildContext context, AppLocalizations l10n, String explanation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            size: 16,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              explanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
