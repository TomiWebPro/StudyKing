import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class WorkloadCard extends StatelessWidget {
  final List<MasteryState> allMastery;
  final String Function(String) resolveTopicName;

  const WorkloadCard({
    super.key,
    required this.allMastery,
    required this.resolveTopicName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final belowThreshold = allMastery.where((s) => s.masteryLevel.index < MasteryLevel.developing.index).toList();
    final totalLessons = _estimateLessonsRemaining(belowThreshold);

    if (allMastery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.noTopicsYetAddSome,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalLessonsStr = formatDecimal(totalLessons.toDouble(), l10n.localeName, minFractionDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Remaining Workload',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    TextSpan(text: '~$totalLessonsStr'),
                    WidgetSpan(
                      child: Text(
                        ' lessons',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${belowThreshold.length} topics need attention',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (belowThreshold.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...belowThreshold.take(5).map((state) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolveTopicName(state.topicId),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _masteryLabel(state.masteryLevel, l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  int _estimateLessonsRemaining(List<MasteryState> belowThreshold) {
    int total = 0;
    for (final state in belowThreshold) {
      final level = state.masteryLevel;
      switch (level) {
        case MasteryLevel.novice:
          total += 3;
        case MasteryLevel.browsing:
          total += 2;
        case MasteryLevel.developing:
        case MasteryLevel.proficient:
        case MasteryLevel.expert:
          break;
      }
    }
    return total;
  }

  String _masteryLabel(MasteryLevel level, AppLocalizations l10n) {
    switch (level) {
      case MasteryLevel.novice:
        return l10n.masteryLevelNovice;
      case MasteryLevel.browsing:
        return l10n.masteryLevelBrowsing;
      case MasteryLevel.developing:
        return l10n.masteryLevelDeveloping;
      case MasteryLevel.proficient:
        return l10n.masteryLevelProficient;
      case MasteryLevel.expert:
        return l10n.masteryLevelExpert;
    }
  }
}
