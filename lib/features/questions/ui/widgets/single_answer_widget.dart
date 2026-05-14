import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Single Answer Widget (Multiple Choice)
class SingleAnswerWidget extends StatelessWidget {
  final List<String> options;
  final String? correctAnswer;
  final String? selectedAnswer;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSelected;
  final bool isSubmitted;
  final bool reduceMotion;

  const SingleAnswerWidget({
    super.key,
    required this.options,
    this.correctAnswer,
    this.selectedAnswer,
    this.isFeedbackVisible = false,
    required this.isSubmitted,
    required this.onAnswerSelected,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((option) {

          return Padding(
            padding: EdgeInsets.only(bottom: ResponsiveUtils
                .verticalSpacing(context) * 0.75),
            child: Semantics(
              selected: selectedAnswer == option,
              button: true,
              label: _optionSemanticsLabel(option, l10n),
              hint: isSubmitted ? null : l10n.selectAsAnswer,
              child: InkWell(
                onTap: !isSubmitted ? () => onAnswerSelected(option) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: ResponsiveUtils.cardPadding(context),
                  decoration: BoxDecoration(
                    color: _getOptionColor(context, option),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedAnswer == option
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedAnswer == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedAnswer == option
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // Feedback
        if (isFeedbackVisible && correctAnswer != null)
          Semantics(
            liveRegion: true,
            child: reduceMotion
                ? _buildFeedbackContent(context, l10n)
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _buildFeedbackContent(context, l10n),
                  ),
          ),
      ],
    );
  }

  Widget _buildFeedbackContent(BuildContext context, AppLocalizations l10n) {
    return Container(
      key: ValueKey('feedback_${selectedAnswer}_$correctAnswer'),
      margin: EdgeInsets.only(top: ResponsiveUtils.verticalSpacing(context) * 1.5),
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: selectedAnswer == correctAnswer
          ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            selectedAnswer == correctAnswer
              ? Icons.check_circle
              : Icons.error_outline,
            color: selectedAnswer == correctAnswer
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            selectedAnswer == correctAnswer
              ? l10n.correctFeedback
              : l10n.incorrectFeedback,
            style: TextStyle(
              color: selectedAnswer == correctAnswer
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            selectedAnswer == correctAnswer ? l10n.selectedRightOption : l10n.tryAgain,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _optionSemanticsLabel(String option, AppLocalizations l10n) {
    if (!isSubmitted || correctAnswer == null) return option;
    final buf = StringBuffer(option);
    if (option == correctAnswer) {
      buf.write(', ${l10n.correctFeedback}');
    }
    if (option == selectedAnswer && option != correctAnswer) {
      buf.write(', ${l10n.incorrectFeedback}');
    }
    return buf.toString();
  }

  Color _getOptionColor(BuildContext context, String option) {
    if (isSubmitted && correctAnswer != null) {
      if (option == correctAnswer) {
        return Theme.of(context).colorScheme.tertiaryContainer;
      }
      if (option == selectedAnswer) {
        return Theme.of(context).colorScheme.errorContainer;
      }
    }
    return Colors.transparent;
  }
}
