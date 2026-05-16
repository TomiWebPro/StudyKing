import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PlanAdherenceCard extends StatelessWidget {
  final double averageAdherence;
  final double weeklyAdherence;

  const PlanAdherenceCard({
    super.key,
    required this.averageAdherence,
    required this.weeklyAdherence,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_note,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Semantics(
              headingLevel: 3,
              child: Text(
                l10n.planAdherence,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAdherenceMetric(
                context,
                l10n.overall,
                formatPercent(averageAdherence * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                averageAdherence,
              ),
            ),
            Expanded(
              child: _buildAdherenceMetric(
                context,
                l10n.thisWeek,
                formatPercent(weeklyAdherence * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                weeklyAdherence,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdherenceMetric(
      BuildContext context, String label, String value, double score) {
    final color = score >= 0.7
        ? Theme.of(context).colorScheme.primary
        : score >= 0.4
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
