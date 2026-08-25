import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/planner/services/mastery_remaining_lessons_estimator.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Surfaces the relative "lessons remaining to mastery" indicator on the
/// dashboard so a student can gauge how close they are to mastery without
/// needing a fully planned-out schedule.
class MasteryRemainingLessonsCard extends StatelessWidget {
  final RemainingLessonsEstimate estimate;

  const MasteryRemainingLessonsCard({
    super.key,
    required this.estimate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = l10n.localeName;

    final progressPercent =
        formatPercent(estimate.masteryProgress * 100, localeName);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.lessonsToMasteryTitle,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            l10n.remainingLessonsToMastery(estimate.lessonsRemaining),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: estimate.masteryProgress.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.masteryProgress}: $progressPercent',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Semantics(
            value:
                '${l10n.remainingLessonsToMastery(estimate.lessonsRemaining)}, '
                '${l10n.masteryProgress}: $progressPercent',
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
