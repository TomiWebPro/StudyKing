import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PlanAdherenceCard extends StatelessWidget {
  final Map<String, dynamic>? instrumentationData;

  const PlanAdherenceCard({super.key, this.instrumentationData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adherence = instrumentationData?['planAdherence'] as Map<String, dynamic>?;
    final avgAdherence = adherence?['averageAdherence'] as double? ?? 0.0;
    final weeklyAvg = adherence?['weeklyAdherenceAvg'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.planAdherence,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildAdherenceMetric(context, l10n.overall, '${(avgAdherence * 100).round()}%', avgAdherence)),
                Expanded(child: _buildAdherenceMetric(context, l10n.thisWeek, '${(weeklyAvg * 100).round()}%', weeklyAvg)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceMetric(BuildContext context, String label, String value, double score) {
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
