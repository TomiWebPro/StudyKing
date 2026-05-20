import 'package:flutter/material.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ReviewAnswersScreen extends StatelessWidget {
  final List<Question> questions;
  final List<PracticeAnswerRecord> answerRecords;

  const ReviewAnswersScreen({
    super.key,
    required this.questions,
    required this.answerRecords,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewMistakes)),
      body: ListView.builder(
        padding: ResponsiveUtils.listPadding(context),
        itemCount: answerRecords.length,
        itemBuilder: (context, index) {
          final record = answerRecords[index];
          final question = questions.where((q) => q.id == record.questionId).firstOrNull;
          if (question == null) return const SizedBox.shrink();
          return _buildAnswerCard(context, theme, l10n, question, record, index + 1);
        },
      ),
    );
  }

  Widget _buildAnswerCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Question question,
    PracticeAnswerRecord record,
    int index,
  ) {
    final correctAnswer = question.markscheme?.correctAnswer ?? '';
    final isCorrect = record.isCorrect;
    return Semantics(
      label: '$index: ${question.text}',
      child: Card(
        margin: AppSpacing.onlyB8,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: AppSpacing.symH8V4,
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      borderRadius: AppRadius.circularSm,
                    ),
                    child: Text(
                      '$index',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCorrect
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(
                      question.text,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              _buildDetailRow(
                context,
                l10n.yourAnswer,
                record.userAnswer,
                isCorrect ? null : theme.colorScheme.error,
              ),
              if (correctAnswer.isNotEmpty) ...[
                AppSpacing.gapSm,
                _buildDetailRow(
                  context,
                  l10n.correctAnswer,
                  correctAnswer,
                  theme.colorScheme.primary,
                ),
              ],
              if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                AppSpacing.gapSm,
                _buildDetailRow(
                  context,
                  l10n.explanation,
                  question.explanation!,
                  theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color? color,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
