import 'package:flutter/material.dart';

class LearningInsightsCard extends StatelessWidget {
  final Map<String, dynamic>? insights;

  const LearningInsightsCard({super.key, this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights == null || !(insights!['hasData'] as bool? ?? false)) {
      return const SizedBox.shrink();
    }

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
                Text('Learning Style Insights', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _buildInsightRow(
              context,
              Icons.view_module,
              'Preferred Content',
              preferredBlock.toUpperCase(),
            ),
            const SizedBox(height: 8),
            _buildInsightRow(
              context,
              Icons.timer,
              'Optimal Session',
              '$optimalMinutes minutes',
            ),
            const SizedBox(height: 8),
            _buildInsightRow(
              context,
              Icons.visibility,
              'Visual Learner',
              prefersVisual ? 'Yes' : 'No',
            ),
            if (srEffectiveness > 0.5) ...[
              const SizedBox(height: 8),
              _buildInsightRow(
                context,
                Icons.repeat,
                'Spaced Repetition',
                'Highly effective',
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
