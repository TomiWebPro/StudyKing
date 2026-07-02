import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/models/question_model.dart';
class QuestionReviewData {
  final Question question;
  final String? userAnswer;
  final String? correctAnswer;
  final bool isCorrect;

  const QuestionReviewData({
    required this.question,
    this.userAnswer,
    this.correctAnswer,
    required this.isCorrect,
  });

  bool get isManual => question.model == null;
}

class PracticeResultsScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final VoidCallback onPracticeAgain;
  final Map<String, double> topicBreakdown;
  final List<QuestionReviewData>? reviewQuestions;

  const PracticeResultsScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.onPracticeAgain,
    this.topicBreakdown = const {},
    this.reviewQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = totalQuestions == 0
        ? 0.0
        : (correctAnswers / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionResults),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.share,
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
          padding: ResponsiveUtils.screenPadding(context),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.practiceComplete,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              MergeSemantics(
                child: _buildStatRow(context, l10n.totalQuestions, formatDecimal(totalQuestions.toDouble(), l10n.localeName)),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              MergeSemantics(
                child: _buildStatRow(context, l10n.correctAnswers, l10n.correctOf(correctAnswers, totalQuestions)),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              MergeSemantics(
                child: _buildStatRow(context, l10n.accuracy, formatPercent(accuracy, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)),
              ),
              if (topicBreakdown.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                Text(
                  l10n.topicBreakdown,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                ...topicBreakdown.entries.map((e) => _buildStatRow(
                  context,
                  e.key,
                  formatPercent(e.value * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                )),
              ],
              if (reviewQuestions != null && reviewQuestions!.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                _buildManualAiBreakdown(context),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              ],
              if (reviewQuestions != null && reviewQuestions!.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                Center(
                  child: Semantics(
                    label: l10n.reviewMistakes,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(context),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(l10n.reviewMistakes),
                    ),
                  ),
                ),
              ],
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              Center(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: Semantics(
                    label: l10n.practiceAgain,
                    child: ElevatedButton.icon(
                      onPressed: onPracticeAgain,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.practiceAgain),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        semanticLabel: l10n.reviewMistakes,
        title: Text(l10n.reviewMistakes),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reviewQuestions!.length,
            itemBuilder: (ctx, i) {
              final item = reviewQuestions![i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.isCorrect ? Icons.check_circle : Icons.cancel,
                            color: item.isCorrect
                                ? Theme.of(ctx).colorScheme.primary
                                : Theme.of(ctx).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l10n.correctAnswers} ${i + 1}',
                              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.question.text,
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      if (item.userAnswer != null && item.userAnswer!.isNotEmpty)
                        Text(
                          '${l10n.yourAnswer}: ${item.userAnswer}',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: item.isCorrect
                                ? Theme.of(ctx).colorScheme.primary
                                : Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      if (!item.isCorrect && item.correctAnswer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${l10n.correctAnswer}: ${item.correctAnswer}',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildManualAiBreakdown(BuildContext context) {
    if (reviewQuestions == null || reviewQuestions!.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final manualQs = reviewQuestions!.where((r) => r.isManual).toList();
    final aiQs = reviewQuestions!.where((r) => !r.isManual).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.topicBreakdown,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        if (manualQs.isNotEmpty) ...[
          _buildStatRow(context, l10n.manual, '${manualQs.where((r) => r.isCorrect).length}/${manualQs.length} (${formatPercent(manualQs.where((r) => r.isCorrect).length / manualQs.length * 100, l10n.localeName, minFractionDigits: 0)})'),
        ],
        if (aiQs.isNotEmpty) ...[
          SizedBox(height: 4),
          _buildStatRow(context, l10n.aiGenerated, '${aiQs.where((r) => r.isCorrect).length}/${aiQs.length} (${formatPercent(aiQs.where((r) => r.isCorrect).length / aiQs.length * 100, l10n.localeName, minFractionDigits: 0)})'),
        ],
      ],
    );
  }

  Future<void> _shareResults(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = totalQuestions == 0 ? 0.0 : (correctAnswers / totalQuestions) * 100;
    final buffer = StringBuffer();
    buffer.writeln(l10n.sessionResults);
    buffer.writeln('${l10n.totalQuestions}: $totalQuestions');
    buffer.writeln('${l10n.correctAnswers}: ${l10n.correctOf(correctAnswers, totalQuestions)}');
    buffer.writeln('${l10n.accuracy}: ${formatPercent(accuracy, l10n.localeName, minFractionDigits: 0)}');
    if (reviewQuestions != null && reviewQuestions!.isNotEmpty) {
      final manualQs = reviewQuestions!.where((r) => r.isManual).toList();
      final aiQs = reviewQuestions!.where((r) => !r.isManual).toList();
      if (manualQs.isNotEmpty) {
        buffer.writeln('${l10n.manual}: ${manualQs.where((r) => r.isCorrect).length}/${manualQs.length}');
      }
      if (aiQs.isNotEmpty) {
        buffer.writeln('${l10n.aiGenerated}: ${aiQs.where((r) => r.isCorrect).length}/${aiQs.length}');
      }
    }
    await Share.share(buffer.toString(), subject: l10n.sessionResults);
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
