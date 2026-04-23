import 'package:flutter/material.dart';

/// Single Answer Widget (Multiple Choice)
class SingleAnswerWidget extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final String? correctAnswer;
  final String? selectedAnswer;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSelected;
  final bool isSubmitted;

  const SingleAnswerWidget({
    super.key,
    required this.questionText,
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
        // Question text
        Text(
          questionText,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // Options list
        ...options.asMap().entries.map((entry) {
          final option = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: !isSubmitted ? () => onAnswerSelected(option) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getOptionColor(option),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedAnswer == option
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio button
                    Radio<String>(
                      value: option,
                      groupValue: selectedAnswer,
                      onChanged: isSubmitted
                          ? null
                          : (value) => onAnswerSelected(value ?? ''),
                    ),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
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
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedAnswer == correctAnswer
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: selectedAnswer == correctAnswer
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedAnswer == correctAnswer
                        ? 'Correct!'
                        : 'Incorrect',
                    style: TextStyle(
                      color: selectedAnswer == correctAnswer
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getOptionColor(String option) {
    if (isSubmitted && correctAnswer != null) {
      if (option == correctAnswer) {
        return Colors.green.withOpacity(0.2);
      }
      if (option == selectedAnswer) {
        return Colors.red.withOpacity(0.2);
      }
    }
    return Colors.transparent;
  }
}
