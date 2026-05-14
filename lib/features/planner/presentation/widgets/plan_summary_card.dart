import 'package:flutter/material.dart';
import '../../../../../core/data/models/personal_learning_plan_model.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class PlanSummaryCard extends StatelessWidget {
  final PlanSummary summary;

  const PlanSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildSummaryChip(String value, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.planSummary,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                buildSummaryChip('${summary.totalQuestions}Q', l10n.total),
                buildSummaryChip(
                    '${summary.totalMinutes}min', l10n.totalTime),
                buildSummaryChip(
                    '${summary.newTopics} ${l10n.newTopics}', l10n.topics),
                buildSummaryChip(
                    '${summary.reviewTopics} ${l10n.reviewTopics}',
                    l10n.reviewTopics),
                buildSummaryChip(
                    '${(summary.estimatedCoverage * 100).round()}%',
                    l10n.coverage),
              ],
            ),
            if (summary.focusAreas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.focusLabel(summary.focusAreas.join(', ')),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
