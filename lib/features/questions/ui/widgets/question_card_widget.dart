import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/data/enums.dart';
import '../../../../core/data/models/question_model.dart';
import 'single_answer_widget.dart';
import 'canvas_drawing_widget.dart';


/// Question Card - Main UI component for displaying questions
class QuestionCardWidget extends StatefulWidget {
  final Question question;
  final String? currentAnswer;
  final bool isSubmitted;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSubmitted;
  final ValueChanged<String?>? onAnswerChanged;
  final VoidCallback? onNext;

  const QuestionCardWidget({
    super.key,
    required this.question,
    this.currentAnswer,
    this.isSubmitted = false,
    this.isFeedbackVisible = false,
    required this.onAnswerSubmitted,
    this.onAnswerChanged,
    this.onNext,
  });

  @override
  State<QuestionCardWidget> createState() => _QuestionCardWidgetState();
}

class _QuestionCardWidgetState extends State<QuestionCardWidget> {
  late final TextEditingController _textController;
  late final TextEditingController _essayController;
  String? _localAnswer;
  final Set<String> _multiSelected = <String>{};

  @override
  void initState() {
    super.initState();
    _localAnswer = widget.currentAnswer;
    _textController = TextEditingController(text: widget.currentAnswer ?? '');
    _essayController = TextEditingController(text: widget.currentAnswer ?? '');
    if (widget.question.type == QuestionType.multiChoice &&
        widget.currentAnswer != null &&
        widget.currentAnswer!.isNotEmpty) {
      _multiSelected
        ..clear()
        ..addAll(widget.currentAnswer!.split('||').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
  }

  @override
  void didUpdateWidget(covariant QuestionCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAnswer != widget.currentAnswer) {
      _localAnswer = widget.currentAnswer;
      _textController.text = widget.currentAnswer ?? '';
      _essayController.text = widget.currentAnswer ?? '';
      if (widget.question.type == QuestionType.multiChoice) {
        _multiSelected
          ..clear()
          ..addAll((widget.currentAnswer ?? '')
              .split('||')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty));
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _essayController.dispose();
    super.dispose();
  }

  void _updateAnswer(String? value) {
    setState(() {
      _localAnswer = value;
    });
    widget.onAnswerChanged?.call(value);
  }

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
                  label: Text('Difficulty: ${_difficultyLabel(widget.question.difficulty)}'),
                  backgroundColor: _getDifficultyColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                if (widget.isSubmitted)
                  Chip(
                    label: Text(_isCurrentAnswerCorrect() ? 'Correct' : 'Incorrect'),
                    backgroundColor: _isCurrentAnswerCorrect()
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
                widget.question.text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),

            // Question type specific content
            _buildQuestionContent(context),

            const SizedBox(height: 16),

            // Submit button
            if (!widget.isSubmitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit
                      ? () {
                          widget.onAnswerSubmitted(_localAnswer);
                        }
                      : null,
                  child: const Text('Submit Answer'),
                ),
              ),
            if (!widget.isSubmitted && !_canSubmit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add an answer before submitting.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),

            if (widget.isSubmitted && widget.onNext != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onNext,
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
    switch (widget.question.type) {
      case QuestionType.singleChoice:
        return _buildMCQContent(context);
      case QuestionType.multiChoice:
        return _buildMultiChoiceContent(context);

      case QuestionType.typedAnswer:
      case QuestionType.mathExpression:
        return _buildTextAnswerContent(context);

      case QuestionType.essay:
        return _buildEssayContent(context);

      case QuestionType.canvas:
      case QuestionType.graphDrawing:
        return _buildCanvasContent(context);

      default:
        return Row(
          children: const [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Expanded(child: Text('This question type is not yet supported in this view.')),
          ],
        );
    }
  }

  Widget _buildMCQContent(BuildContext context) {
    final options = widget.question.options.isNotEmpty
        ? widget.question.options
        : ['Option 1', 'Option 2', 'Option 3', 'Option 4'];

    return SingleAnswerWidget(
      options: options,
      correctAnswer: _getCorrectAnswer(),
      selectedAnswer: _localAnswer,
      isSubmitted: widget.isSubmitted,
      isFeedbackVisible: widget.isFeedbackVisible,
      onAnswerSelected: (answer) {
        _updateAnswer(answer);
      },
    );
  }

  Widget _buildMultiChoiceContent(BuildContext context) {
    final options = widget.question.options.isNotEmpty
        ? widget.question.options
        : ['Option 1', 'Option 2', 'Option 3', 'Option 4'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((option) {
          final selected = _multiSelected.contains(option);
          return CheckboxListTile(
            value: selected,
            onChanged: widget.isSubmitted
                ? null
                : (value) {
                    setState(() {
                      if (value ?? false) {
                        _multiSelected.add(option);
                      } else {
                        _multiSelected.remove(option);
                      }
                      _localAnswer = _multiSelected.join('||');
                    });
                    widget.onAnswerChanged?.call(_localAnswer);
                  },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(option),
          );
        }),
      ],
    );
  }

  Widget _buildTextAnswerContent(BuildContext context) {
    return TextField(
      controller: _textController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) {
        _updateAnswer(value.trim().isEmpty ? null : value);
      },
    );
  }

  Widget _buildEssayContent(BuildContext context) {
    return TextField(
      controller: _essayController,
      maxLines: 10,
      decoration: InputDecoration(
        hintText: 'Write your essay answer...',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) {
        _updateAnswer(value.trim().isEmpty ? null : value);
      },
    );
  }

  Widget _buildCanvasContent(BuildContext context) {
    return CanvasDrawingWidget(
      onDrawingComplete: (data) {
        _updateAnswer(base64Encode(data));
      },
    );
  }

  String? _getCorrectAnswer() {
    return widget.question.correctAnswer ?? widget.question.markscheme;
  }

  bool _isCurrentAnswerCorrect() {
    final correct = _getCorrectAnswer();
    if (correct == null || _localAnswer == null) return false;
    if (widget.question.type == QuestionType.multiChoice) {
      final selected = _localAnswer!
          .split('||')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
      final expected = correct
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
      return selected.length == expected.length && selected.containsAll(expected);
    }
    return _localAnswer!.trim().toLowerCase() == correct.trim().toLowerCase();
  }

  bool get _canSubmit {
    final answer = _localAnswer;
    if (answer == null) return false;
    return answer.trim().isNotEmpty;
  }

  String _getTypeLabel() {
    switch (widget.question.type) {
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
    switch (widget.question.type) {
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
    switch (widget.question.difficulty) {
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

  String _difficultyLabel(int value) {
    switch (value) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return value.toString();
    }
  }
}
