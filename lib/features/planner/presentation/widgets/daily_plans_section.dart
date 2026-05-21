import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'daily_plan_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class DailyPlansSection extends ConsumerWidget {
  final void Function(String topicId, String topicTitle, String subjectId) onStartTutoring;
  final void Function(String topicId, String topicTitle, String subjectId) onScheduleLesson;

  const DailyPlansSection({
    super.key,
    required this.onStartTutoring,
    required this.onScheduleLesson,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);

    if (state.plan == null) return const SizedBox.shrink();

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.yourStudySchedule,
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
          ...state.plan!.dailyPlans.map(
            (day) => DailyPlanCard(
              day: day,
              onStartTutoring: (topicId, topicTitle, subjectId) {
                onStartTutoring(
                  topicId, topicTitle, subjectId,
                );
              },
              onScheduleLesson: onScheduleLesson,
              onCatchUp: !day.isCompleted && day.date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                  ? () => _showCatchUpSheet(context, ref, l10n, state)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showCatchUpSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n, PlannerState state) {
    final daysAway = 3;
    final notifier = ref.read(plannerProvider.notifier);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.catchUpTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.catchUpDescription(daysAway),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.catchUpWithStrategy('redistribute:all', daysAway, l10n);
                },
                icon: const Icon(Icons.replay),
                label: Text(l10n.catchUpRedistribute),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.catchUpWithStrategy('extend', daysAway, l10n);
                },
                icon: const Icon(Icons.date_range),
                label: Text(l10n.catchUpExtend(daysAway)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.catchUpWithStrategy('regenerate', daysAway, l10n);
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.regeneratePlan),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
