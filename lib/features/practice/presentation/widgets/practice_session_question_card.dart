import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/presentation/widgets/single_answer_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/canvas_drawing_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/graph_drawing_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/math_expression_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/file_upload_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/audio_recording_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/providers/service_providers.dart' show visionInterpretationServiceProvider;
import 'package:studyking/features/practice/services/question_type_localizer.dart';

class PracticeSessionQuestionCard extends ConsumerWidget {
  final Question question;
  final String? currentAnswer;
  final bool isSubmitted;
  final bool isFeedbackVisible;
  final ValueChanged<String?> onAnswerSelected;

  const PracticeSessionQuestionCard({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.isSubmitted,
    required this.isFeedbackVisible,
    required this.onAnswerSelected,
  });

  Widget _buildTypedAnswerWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: l10n.yourAnswer,
      child: TextField(
        decoration: InputDecoration(
          labelText: l10n.yourAnswer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        minLines: 3,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        onChanged: onAnswerSelected,
      ),
    );
  }

  Widget _buildEssayWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: '${l10n.yourAnswer}, ${currentAnswer?.length ?? 0}',
      child: TextField(
        decoration: InputDecoration(
          labelText: l10n.yourAnswerCharacters(currentAnswer?.length ?? 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        minLines: 3,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
        onChanged: onAnswerSelected,
      ),
    );
  }

  Widget _buildMultiChoiceContent(BuildContext context) {
    final options = question.options;
    if (options.isEmpty) {
      return Text(AppLocalizations.of(context)!.noOptionsAvailable);
    }

    final selected = <String>{};
    if (currentAnswer != null && currentAnswer!.isNotEmpty) {
      selected.addAll(currentAnswer!.split('||').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
      ),
      child: ListView(
        shrinkWrap: true,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          return Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: isSelected,
              onChanged: isSubmitted
                  ? null
                  : (value) {
                      final updated = Set<String>.from(selected);
                      if (value ?? false) {
                        updated.add(option);
                      } else {
                        updated.remove(option);
                      }
                      onAnswerSelected(updated.isEmpty ? null : updated.join('||'));
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(option),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.type.localizedLabel(l10n),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
          Text(
            question.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
          _buildQuestionWidget(context, ref),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(BuildContext context, WidgetRef ref) {
    switch (question.type) {
      case QuestionType.singleChoice:
        final correctAnswer = question.markscheme?.correctAnswer ?? '';
        if (question.options.isEmpty) {
          return Text(AppLocalizations.of(context)!.noOptionsAvailable);
        }
        return SingleAnswerWidget(
          options: question.options,
          correctAnswer: correctAnswer,
          selectedAnswer: currentAnswer,
          isSubmitted: isSubmitted,
          isFeedbackVisible: isFeedbackVisible,
          onAnswerSelected: onAnswerSelected,
          reduceMotion: ref.watch(settingsProvider).reduceMotion,
        );

      case QuestionType.multiChoice:
        return _buildMultiChoiceContent(context);

      case QuestionType.mathExpression:
        return MathExpressionWidget(expression: question.text, isSolution: false);

      case QuestionType.canvas:
        return _buildCanvasAnswer(context, ref);
      case QuestionType.graphDrawing:
        return GraphDrawingWidget(
          instruction: question.text,
          onDrawingComplete: (data) => onAnswerSelected(base64Encode(data)),
          largeTouchTargets: ref.watch(settingsProvider).largeTouchTargets,
        );

      case QuestionType.typedAnswer:
      case QuestionType.stepByStep:
        return _buildTypedAnswerWidget(context);

      case QuestionType.essay:
        return _buildEssayWidget(context);

      case QuestionType.fileUpload:
        return FileUploadWidget(
          currentAnswer: currentAnswer,
          isSubmitted: isSubmitted,
          onAnswerChanged: onAnswerSelected,
        );
      case QuestionType.audioRecording:
        return AudioRecordingWidget(
          currentAnswer: currentAnswer,
          isSubmitted: isSubmitted,
          onAnswerChanged: onAnswerSelected,
        );
    }
  }

  Widget _buildCanvasAnswer(BuildContext context, WidgetRef ref) {
    return _CanvasAnswerWithVision(
      instruction: question.text,
      currentAnswer: currentAnswer,
      isSubmitted: isSubmitted,
      largeTouchTargets: ref.watch(settingsProvider).largeTouchTargets,
      onAnswerSelected: onAnswerSelected,
    );
  }
}

class _CanvasAnswerWithVision extends ConsumerStatefulWidget {
  final String? instruction;
  final String? currentAnswer;
  final bool isSubmitted;
  final bool largeTouchTargets;
  final ValueChanged<String?> onAnswerSelected;

  const _CanvasAnswerWithVision({
    this.instruction,
    this.currentAnswer,
    this.isSubmitted = false,
    this.largeTouchTargets = false,
    required this.onAnswerSelected,
  });

  @override
  ConsumerState<_CanvasAnswerWithVision> createState() => _CanvasAnswerWithVisionState();
}

class _CanvasAnswerWithVisionState extends ConsumerState<_CanvasAnswerWithVision> {
  static final Logger _logger = const Logger('CanvasAnswerWithVision');
  bool _isInterpreting = false;
  String? _recognizedPreview;
  String? _visionError;

  Future<void> _pickAndInterpretImage() async {
    if (widget.isSubmitted || _isInterpreting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isInterpreting = true;
      _visionError = null;
    });
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final bytes = picked?.files.first.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _isInterpreting = false);
        return;
      }
      final result = await ref.read(visionInterpretationServiceProvider).interpretImage(bytes);
      if (result.isSuccess) {
        final text = result.data!;
        setState(() {
          _recognizedPreview = text;
          _isInterpreting = false;
        });
        widget.onAnswerSelected(text);
      } else {
        setState(() {
          _visionError = l10n.visionInterpretationFailed;
          _isInterpreting = false;
        });
      }
    } catch (e) {
      _logger.w('Image vision interpretation failed', e);
      if (mounted) {
        setState(() {
          _visionError = AppLocalizations.of(context)!.visionInterpretationFailed;
          _isInterpreting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CanvasDrawingWidget(
          instruction: widget.instruction,
          onDrawingComplete: (data) => widget.onAnswerSelected(base64Encode(data)),
          onTextRecognized: (text) => widget.onAnswerSelected(text),
          showInputModeSelector: true,
          initialDrawing: null,
          largeTouchTargets: widget.largeTouchTargets,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: (widget.isSubmitted || _isInterpreting) ? null : _pickAndInterpretImage,
          icon: _isInterpreting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_camera),
          label: Text(_isInterpreting ? l10n.interpretingImage : l10n.uploadPhotoOfWork),
        ),
        if (_recognizedPreview != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.recognizedFromImage(_recognizedPreview!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_visionError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _visionError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
