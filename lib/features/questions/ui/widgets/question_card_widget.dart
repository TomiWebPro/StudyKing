import 'package:flutter/material.dart';
import '../../../../core/data/enums.dart';
import '../../../../core/data/models/question_model.dart';
import 'single_answer_widget.dart';
import 'canvas_drawing_widget.dart';


/// Question Card - Main UI component for displaying questions
class QuestionCardWidget extends StatelessWidget {
  final Question question;
  final String? currentAnswer;
  final bool isSubmitted;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSubmitted;
  final VoidCallback? onNext;

  const QuestionCardWidget({
    super.key,
    required this.question,
    this.currentAnswer,
    this.isSubmitted = false,
    this.isFeedbackVisible = false,
    required this.onAnswerSubmitted,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Chip(
                  label: Text(_getTypeLabel()),
                  backgroundColor: _getTypeColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('Difficulty: ${question.difficulty}'),
                  backgroundColor: _getDifficultyColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                if (isSubmitted)
                  Chip(
                    label: Text(currentAnswer == question.markscheme ? 'Correct' : 'Incorrect'),
                    backgroundColor: currentAnswer == question.markscheme
                        ? Colors.green
                        : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            Text(
              question.text,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Question type specific content
            _buildQuestionContent(context),

            const SizedBox(height: 16),

            // Submit button
            if (!isSubmitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onAnswerSubmitted(currentAnswer);
                  },
                  child: const Text('Submit Answer'),
                ),
              ),

            if (isSubmitted && onNext != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Question'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return _buildMCQContent(context);

      case QuestionType.typedAnswer:
      case QuestionType.mathExpression:
        return _buildTextAnswerContent(context);

      case QuestionType.essay:
        return _buildEssayContent(context);

      case QuestionType.canvas:
      case QuestionType.graphDrawing:
        return _buildCanvasContent(context);

      default:
        return Text('Question type not supported');
    }
  }

  Widget _buildMCQContent(BuildContext context) {
    final options = question.markscheme != null 
        ? (question.markscheme!.isEmpty 
            ? ['Option 1', 'Option 2', 'Option 3', 'Option 4'] 
            : question.markscheme!.split(','))
        : ['Option 1', 'Option 2', 'Option 3', 'Option 4'];

    return SingleAnswerWidget(
      questionText: question.text,
      options: options.take(4).toList(),
      correctAnswer: question.markscheme,
      selectedAnswer: currentAnswer,
      isSubmitted: isSubmitted,
      isFeedbackVisible: isFeedbackVisible,
      onAnswerSelected: (answer) {
        // Store selected answer
      },
    );
  }

  Widget _buildTextAnswerContent(BuildContext context) {
    return TextField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) {
        // Handle text answer
      },
    );
  }

  Widget _buildEssayContent(BuildContext context) {
    return TextField(
      maxLines: 10,
      decoration: InputDecoration(
        hintText: 'Write your essay answer...',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildCanvasContent(BuildContext context) {
    return CanvasDrawingWidget(
      onDrawingComplete: (data) {
        // Handle canvas drawing completion
      },
    );
  }

  String _getTypeLabel() {
    switch (question.type) {
      case QuestionType.singleChoice:
        return 'Multiple Choice';
      case QuestionType.multiChoice:
        return 'Multiple Select';
      case QuestionType.typedAnswer:
        return 'Text Answer';
      case QuestionType.mathExpression:
        return 'Math';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.canvas:
        return 'Diagram';
      case QuestionType.graphDrawing:
        return 'Graph';
      case QuestionType.stepByStep:
        return 'Step-by-Step';
      default:
        return 'Question';
    }
  }

  Color _getTypeColor() {
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return Colors.blue.shade100;
      case QuestionType.typedAnswer:
      case QuestionType.mathExpression:
        return Colors.green.shade100;
      case QuestionType.essay:
        return Colors.orange.shade100;
      case QuestionType.canvas:
      case QuestionType.graphDrawing:
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getDifficultyColor() {
    switch (question.difficulty) {
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.orange.shade100;
      case 3:
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
