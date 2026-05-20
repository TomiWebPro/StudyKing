import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class MasteryProgressCard extends StatelessWidget {
  final MasterySnapshot? snapshot;

  const MasteryProgressCard({super.key, this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = snapshot ?? const MasterySnapshot();
    final totalTopics = data.totalTopics;
    final masteredTopics = data.masteredTopics;
    final weakTopics = data.weakTopics;
    final avgAccuracy = data.averageAccuracy;
    final avgReadiness = data.avgReadiness;
    final masteryPercent = totalTopics > 0 ? masteredTopics / totalTopics : 0.0;

    final lastUpdated = data.lastUpdated;
    final daysSinceUpdate = lastUpdated != null
        ? DateTime.now().difference(lastUpdated).inDays
        : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Semantics(
              headingLevel: 3,
              child: Text(
                l10n.masteryOverview,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        if (daysSinceUpdate >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: daysSinceUpdate >= 7
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    daysSinceUpdate >= 7 ? Icons.warning_amber_rounded : Icons.info_outline,
                    size: 14,
                    color: daysSinceUpdate >= 7
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last updated $daysSinceUpdate days ago',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: daysSinceUpdate >= 7
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statColumn(context, '$totalTopics', l10n.totalTopics, Theme.of(context).colorScheme.primary)),
            Expanded(child: _statColumn(context, '$masteredTopics', l10n.mastered, Theme.of(context).colorScheme.primary)),
            Expanded(child: _statColumn(context, '${totalTopics - masteredTopics - weakTopics}', l10n.inProgress, Theme.of(context).colorScheme.tertiary)),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: masteryPercent,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(context, masteryPercent)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat(context, l10n.accuracy, formatPercent(avgAccuracy * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0), AppTheme.progressColor(avgAccuracy, context)),
            _miniStat(context, l10n.readiness, formatPercent(avgReadiness * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0), Theme.of(context).colorScheme.tertiary),
            _miniStat(context, l10n.weakAreas, '$weakTopics', Theme.of(context).colorScheme.error),
          ],
        ),
      ],
    );
  }

  Widget _statColumn(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold, color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ],
    );
  }

  Widget _miniStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11,
        )),
      ],
    );
  }

  Color _getProgressColor(BuildContext context, double value) {
    return AppTheme.progressColor(value, context);
  }
}
