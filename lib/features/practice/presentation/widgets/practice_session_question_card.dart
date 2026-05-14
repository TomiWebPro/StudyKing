import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/ui/widgets/single_answer_widget.dart';
import 'package:studyking/features/questions/ui/widgets/canvas_drawing_widget.dart';
import 'package:studyking/features/questions/ui/widgets/math_expression_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
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
    return TextField(
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.yourAnswer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      onChanged: onAnswerSelected,
    );
  }

  Widget _buildEssayWidget(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.yourAnswerCharacters(currentAnswer?.length ?? 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      onChanged: onAnswerSelected,
    );
  }

  Widget _buildFallbackWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(l10n.unsupportedQuestionType(question.type.localizedLabel(l10n)));
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
          const SizedBox(height: 12),
          Text(
            question.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuestionWidget(context, ref),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(BuildContext context, WidgetRef ref) {
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        final correctAnswer = question.markscheme?.correctAnswer ?? '';
        final l10n = AppLocalizations.of(context)!;
        final fallbackOptions = [1, 2, 3, 4].map((i) => l10n.fallbackOption(i)).toList();
        final options = question.type == QuestionType.singleChoice
            ? question.options.isEmpty ? fallbackOptions : question.options
            : question.options.isEmpty ? fallbackOptions : question.options;
        return SingleAnswerWidget(
          options: options,
          correctAnswer: correctAnswer,
          selectedAnswer: currentAnswer,
          isSubmitted: isSubmitted,
          isFeedbackVisible: isFeedbackVisible,
          onAnswerSelected: onAnswerSelected,
          reduceMotion: ref.watch(settingsProvider).reduceMotion,
        );

      case QuestionType.mathExpression:
        return MathExpressionWidget(expression: question.text, isSolution: false);

      case QuestionType.canvas:
        return CanvasDrawingWidget(
          instruction: question.text,
          onDrawingComplete: (data) => onAnswerSelected(AppLocalizations.of(context)!.drawingSubmitted),
          initialDrawing: null,
          largeTouchTargets: ref.watch(settingsProvider).largeTouchTargets,
        );

      case QuestionType.typedAnswer:
        return _buildTypedAnswerWidget(context);

      case QuestionType.essay:
        return _buildEssayWidget(context);

      default:
        return _buildFallbackWidget(context);
    }
  }
}
