import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticeResultsScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final VoidCallback onPracticeAgain;

  const PracticeResultsScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.onPracticeAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = totalQuestions == 0
        ? 0.0
        : (correctAnswers / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionResults)),
      body: FocusTraversalGroup(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.practiceComplete,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              MergeSemantics(
                child: _buildStatRow(context, l10n.totalQuestions, totalQuestions.toString()),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              MergeSemantics(
                child: _buildStatRow(context, l10n.correctAnswers, '$correctAnswers/$totalQuestions'),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              MergeSemantics(
                child: _buildStatRow(context, l10n.accuracy, formatPercent(accuracy, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)),
              ),
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
      ),
    );
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
