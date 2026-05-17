import 'package:flutter/material.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class WorkloadCard extends StatelessWidget {
  final SubjectWorkload? workload;
  final String Function(String) resolveTopicName;

  const WorkloadCard({
    super.key,
    required this.workload,
    required this.resolveTopicName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (workload == null || workload!.totalQuestions == 0) {
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

    final totalLessons = workload!.estimatedLessonsRemaining;
    final totalLessonsStr = formatDecimal(totalLessons, l10n.localeName, minFractionDigits: 0);
    final topicsNeedingAttention = workload!.topicWorkloads
        .where((t) => t.estimatedLessonsRemaining > 0)
        .toList();

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
            '${topicsNeedingAttention.length} topics need attention',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (topicsNeedingAttention.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...topicsNeedingAttention.take(5).map((topic) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolveTopicName(topic.topicId),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _masteryLabel(topic.masteryLevel, l10n),
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

  String _masteryLabel(double masteryLevel, AppLocalizations l10n) {
    if (masteryLevel >= 0.9) return l10n.masteryLevelExpert;
    if (masteryLevel >= 0.7) return l10n.masteryLevelProficient;
    if (masteryLevel >= 0.5) return l10n.masteryLevelDeveloping;
    if (masteryLevel >= 0.3) return l10n.masteryLevelBrowsing;
    return l10n.masteryLevelNovice;
  }
}
