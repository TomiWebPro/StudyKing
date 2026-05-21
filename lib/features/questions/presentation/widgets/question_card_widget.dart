import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../core/data/enums.dart';
import '../../../../core/data/models/question_model.dart';
import '../../../../core/utils/responsive.dart';
import 'package:studyking/core/utils/answer_comparator.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'single_answer_widget.dart';
import 'canvas_drawing_widget.dart';
import 'graph_drawing_widget.dart';
import 'file_upload_widget.dart';
import 'audio_recording_widget.dart';

class QuestionCardWidget extends StatefulWidget {
  final Question question;
  final String? currentAnswer;
  final bool isSubmitted;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSubmitted;
  final ValueChanged<String?>? onAnswerChanged;
  final VoidCallback? onNext;
  final bool reduceMotion;
  final bool largeTouchTargets;

  const QuestionCardWidget({
    super.key,
    required this.question,
    this.currentAnswer,
    this.isSubmitted = false,
    this.isFeedbackVisible = false,
    required this.onAnswerSubmitted,
    this.onAnswerChanged,
    this.onNext,
    this.reduceMotion = false,
    this.largeTouchTargets = false,
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

  void _updateAnswer(String? value) {
    setState(() {
      _localAnswer = value;
    });
    widget.onAnswerChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: '${_getTypeLabel(l10n)}: ${widget.question.text}',
      child: Card(
        margin: ResponsiveUtils.screenPadding(context),
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(_getTypeLabel(l10n), overflow: TextOverflow.ellipsis),
                    backgroundColor: _getTypeColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Chip(
                      label: Text(l10n.difficultyLabel(_difficultyLabel(widget.question.difficulty, l10n)), overflow: TextOverflow.ellipsis),
                      backgroundColor: _getDifficultyColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.isSubmitted)
                    Chip(
                      label: Text(_isCurrentAnswerCorrect() ? l10n.correctFeedback : l10n.incorrectFeedback, overflow: TextOverflow.ellipsis),
                      backgroundColor: _isCurrentAnswerCorrect()
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

                Text(
                  widget.question.text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 16),

              _buildQuestionContent(context),

              const SizedBox(height: 16),

              if (!widget.isSubmitted)
                Semantics(
                  label: l10n.submitAnswer,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit
                          ? () {
                              widget.onAnswerSubmitted(_localAnswer);
                            }
                          : null,
                      child: Text(l10n.submitAnswer),
                    ),
                  ),
                ),
              if (!widget.isSubmitted && !_canSubmit)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.addAnswerBeforeSubmitting,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),

              if (widget.isSubmitted && widget.onNext != null)
                Semantics(
                  label: l10n.nextQuestion,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(l10n.nextQuestion),
                    ),
                  ),
                ),
            ],
          ),
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
        return _buildCanvasContent(context);
      case QuestionType.graphDrawing:
        return _buildGraphContent(context);

      case QuestionType.stepByStep:
        return _buildTextAnswerContent(context);

      case QuestionType.fileUpload:
        return _buildFileUploadContent(context);

      case QuestionType.audioRecording:
        return _buildAudioRecordingContent(context);
    }
  }

  Widget _buildMCQContent(BuildContext context) {
    if (widget.question.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(AppLocalizations.of(context)!.noOptionsAvailable),
      );
    }

    return SingleAnswerWidget(
      options: widget.question.options,
      correctAnswer: _getCorrectAnswer(),
      selectedAnswer: _localAnswer,
      isSubmitted: widget.isSubmitted,
      isFeedbackVisible: widget.isFeedbackVisible,
      onAnswerSelected: (answer) {
        _updateAnswer(answer);
      },
      reduceMotion: widget.reduceMotion,
    );
  }

  Widget _buildMultiChoiceContent(BuildContext context) {
    if (widget.question.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(AppLocalizations.of(context)!.noOptionsAvailable),
      );
    }

    final options = widget.question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((option) {
          final selected = _multiSelected.contains(option);
          return Semantics(
            label: option,
            selected: selected,
            child: CheckboxListTile(
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
              title: Text(option, overflow: TextOverflow.ellipsis),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextAnswerContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      hint: l10n.typeYourAnswerHere,
      child: TextField(
        controller: _textController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: l10n.typeYourAnswerHere,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onChanged: (value) {
          _updateAnswer(value.trim().isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _buildEssayContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      hint: l10n.writeYourEssayAnswer,
      child: TextField(
        controller: _essayController,
        maxLines: 10,
        decoration: InputDecoration(
          hintText: l10n.writeYourEssayAnswer,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onChanged: (value) {
          _updateAnswer(value.trim().isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _buildCanvasContent(BuildContext context) {
    return CanvasDrawingWidget(
      onDrawingComplete: (data) {
        _updateAnswer(base64Encode(data));
      },
      largeTouchTargets: widget.largeTouchTargets,
    );
  }

  Widget _buildGraphContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GraphDrawingWidget(
      instruction: l10n.drawYourGraphHere,
      onDrawingComplete: (data) {
        _updateAnswer(base64Encode(data));
      },
      largeTouchTargets: widget.largeTouchTargets,
    );
  }

  Widget _buildFileUploadContent(BuildContext context) {
    return FileUploadWidget(
      currentAnswer: _localAnswer,
      isSubmitted: widget.isSubmitted,
      onAnswerChanged: _updateAnswer,
    );
  }

  Widget _buildAudioRecordingContent(BuildContext context) {
    return AudioRecordingWidget(
      currentAnswer: _localAnswer,
      isSubmitted: widget.isSubmitted,
      onAnswerChanged: _updateAnswer,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _essayController.dispose();
    super.dispose();
  }

  String? _getCorrectAnswer() {
    return widget.question.markscheme?.correctAnswer;
  }

  bool _isCurrentAnswerCorrect() {
    final correct = _getCorrectAnswer();
    if (correct == null || _localAnswer == null) return false;
    if (widget.question.type == QuestionType.multiChoice) {
      final selected = _localAnswer!
          .split('||')
          .map((e) => e.normalized)
          .where((e) => e.isNotEmpty)
          .toSet();
      final expected = correct
          .split(',')
          .map((e) => e.normalized)
          .where((e) => e.isNotEmpty)
          .toSet();
      return selected.length == expected.length && selected.containsAll(expected);
    }
    return AnswerComparator.areEquivalent(_localAnswer!, correct);
  }

  bool get _canSubmit {
    final answer = _localAnswer;
    if (answer == null) return false;
    return answer.trim().isNotEmpty;
  }

  String _getTypeLabel(AppLocalizations l10n) {
    switch (widget.question.type) {
      case QuestionType.singleChoice:
        return l10n.multipleChoice;
      case QuestionType.multiChoice:
        return l10n.multipleSelect;
      case QuestionType.typedAnswer:
        return l10n.textAnswer;
      case QuestionType.mathExpression:
        return l10n.math;
      case QuestionType.essay:
        return l10n.essay;
      case QuestionType.canvas:
        return l10n.diagram;
      case QuestionType.graphDrawing:
        return l10n.graphQuestion;
      case QuestionType.stepByStep:
        return l10n.stepByStep;
      default:
        return l10n.questionTypeDefault;
    }
  }

  Color _getTypeColor() {
    final cs = Theme.of(context).colorScheme;
    switch (widget.question.type) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return cs.primaryContainer;
      case QuestionType.typedAnswer:
      case QuestionType.mathExpression:
        return cs.secondaryContainer;
      case QuestionType.essay:
        return cs.tertiaryContainer;
      case QuestionType.canvas:
      case QuestionType.graphDrawing:
        return cs.primaryContainer;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  Color _getDifficultyColor() {
    final cs = Theme.of(context).colorScheme;
    switch (widget.question.difficulty) {
      case 1:
        return cs.primaryContainer;
      case 2:
        return cs.tertiaryContainer;
      case 3:
        return cs.errorContainer;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  String _difficultyLabel(int value, AppLocalizations l10n) {
    switch (value) {
      case 1:
        return l10n.easy;
      case 2:
        return l10n.difficultyMedium;
      case 3:
        return l10n.hard;
      default:
        return value.toString();
    }
  }
}
