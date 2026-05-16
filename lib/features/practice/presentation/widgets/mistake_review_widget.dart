import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';

class MistakeReviewWidget extends StatelessWidget {
  final List<MistakeEntry> mistakes;
  final VoidCallback? onRedo;
  final VoidCallback? onDismiss;

  const MistakeReviewWidget({
    super.key,
    required this.mistakes,
    this.onRedo,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required List<MistakeEntry> mistakes,
    VoidCallback? onRedo,
    VoidCallback? onDismiss,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MistakeReviewWidget(
        mistakes: mistakes,
        onRedo: onRedo,
        onDismiss: onDismiss,
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Text(
              l10n.reviewMistakesDescription(mistakes.length),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (mistakes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final mistake = mistakes[index];
                    return _MistakeCard(mistake: mistake, index: index);
                  },
                ),
              ),
            if (mistakes.isNotEmpty) ...[
              const SizedBox(height: 16),
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

  const _MistakeCard({required this.mistake, required this.index});

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
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
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
            const SizedBox(height: 12),
            _buildAnswerRow(
              context,
              l10n.yourAnswer,
              mistake.attempt?.userAnswer.isNotEmpty == true
                  ? mistake.attempt!.userAnswer
                  : l10n.noAnswerProvided,
              isIncorrect: true,
            ),
            const SizedBox(height: 8),
            _buildAnswerRow(
              context,
              l10n.correctAnswer,
              mistake.correctAnswer,
              isCorrect: true,
            ),
            if (mistake.explanation != null && mistake.explanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildExplanationRow(context, l10n, mistake.explanation!),
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
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
