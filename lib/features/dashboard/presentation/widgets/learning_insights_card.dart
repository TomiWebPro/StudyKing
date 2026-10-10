import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class LearningInsightsCard extends StatelessWidget {
  final Map<String, dynamic>? insights;

  const LearningInsightsCard({super.key, this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights == null || !(insights!['hasData'] as bool? ?? false)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final preferredBlock = insights!['preferredBlockType'] as String? ?? 'exercise';
    final optimalMinutes = insights!['optimalSessionMinutes'] as int? ?? 25;
    final prefersVisual = insights!['prefersVisual'] as bool? ?? false;
    final srEffectiveness = insights!['srEffectiveness'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(l10n.learningStyleInsightsTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _buildInsightRow(
              context,
              Icons.view_module,
              l10n.preferredContentLabel,
              preferredBlock.toUpperCase(),
            ),
            const SizedBox(height: 8),
            _buildInsightRow(
              context,
              Icons.timer,
              l10n.optimalSessionLabel,
              l10n.minutesValue(optimalMinutes),
            ),
            const SizedBox(height: 8),
            _buildInsightRow(
              context,
              Icons.visibility,
              l10n.visualLearnerLabel,
              prefersVisual ? l10n.yesLabel : l10n.noLabel,
            ),
            if (srEffectiveness > 0.5) ...[
              const SizedBox(height: 8),
              _buildInsightRow(
                context,
                Icons.repeat,
                l10n.spacedRepetition,
                l10n.highlyEffectiveLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }
}
