import 'package:flutter/material.dart';

/// Single Answer Widget (Multiple Choice)
class SingleAnswerWidget extends StatelessWidget {
  final List<String> options;
  final String? correctAnswer;
  final String? selectedAnswer;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSelected;
  final bool isSubmitted;

  const SingleAnswerWidget({
    super.key,
    required this.options,
    this.correctAnswer,
    this.selectedAnswer,
    this.isFeedbackVisible = false,
    required this.isSubmitted,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((option) {
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              selected: selectedAnswer == option,
              button: true,
              label: option,
              child: InkWell(
                onTap: !isSubmitted ? () => onAnswerSelected(option) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getOptionColor(context, option),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedAnswer == option
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
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
                            : Colors.grey,
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
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isSubmitted ? 1.0 : 0.0,
            child: Container(
              margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
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
                        ? 'Correct!'
                        : 'Incorrect',
                      style: TextStyle(
                        color: selectedAnswer == correctAnswer
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      selectedAnswer == correctAnswer ? 'Selected right option' : 'Try again',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ),
      ],
    );
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
