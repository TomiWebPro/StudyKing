import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticeFeedbackWidget extends StatelessWidget {
  final bool isCorrect;
  final String? explanation;

  const PracticeFeedbackWidget({
    super.key,
    required this.isCorrect,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      label: isCorrect ? l10n.correctFeedback : l10n.incorrectFeedback,
      child: Container(
        padding: ResponsiveUtils.cardPadding(context),
        decoration: BoxDecoration(
          color: isCorrect
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.error_outline,
                  color: isCorrect ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? l10n.correctFeedback : l10n.incorrectFeedback,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (explanation != null && explanation!.isNotEmpty)
              Text(
                explanation!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
