import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class TopicBreakdownCard extends StatelessWidget {
  final List<MasteryState> allMastery;
  final String Function(String) resolveTopicName;

  const TopicBreakdownCard({
    super.key,
    required this.allMastery,
    required this.resolveTopicName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (allMastery.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              l10n.noTopicDataYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final sorted = List<MasteryState>.from(allMastery)
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.topicPerformance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            ...sorted.take(10).map((state) => _buildTopicRow(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(BuildContext context, MasteryState state) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getProgressColor(context, state.accuracy);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  resolveTopicName(state.topicId),
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(state.accuracy * 100).round()}%',
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.accuracy,
              minHeight: 4,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Row(
            children: [
              Text(
                l10n.attemptsCount(state.totalAttempts),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _masteryLabel(context, state.masteryLevel),
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _masteryLabel(BuildContext context, MasteryLevel level) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return level.name;
    switch (level) {
      case MasteryLevel.novice: return l10n.masteryLevelNovice;
      case MasteryLevel.browsing: return l10n.masteryLevelBrowsing;
      case MasteryLevel.developing: return l10n.masteryLevelDeveloping;
      case MasteryLevel.proficient: return l10n.masteryLevelProficient;
      case MasteryLevel.expert: return l10n.masteryLevelExpert;
    }
  }

  Color _getProgressColor(BuildContext context, double value) {
    final cs = Theme.of(context).colorScheme;
    if (value >= 0.8) return cs.primary;
    if (value >= 0.6) return cs.tertiary;
    return cs.error;
  }
}
