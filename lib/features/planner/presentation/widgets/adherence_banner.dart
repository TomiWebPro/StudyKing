import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class AdherenceBanner extends ConsumerWidget {
  const AdherenceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);
    final deviation = state.adherenceDeviation;
    if (deviation == null) return const SizedBox.shrink();

    final missedMinutes = state.plan?.targetMinutesPerDay.toInt() ?? 60;
    final isAbsence = deviation is AbsenceDeviation;

    return FocusTraversalGroup(
      child: Container(
        padding: ResponsiveUtils.cardPadding(context),
        decoration: BoxDecoration(
          color: deviation.requiresEscalation
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              deviation.requiresEscalation
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline,
              color: deviation.requiresEscalation
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviation.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isAbsence) ...[
                        TextButton.icon(
                          onPressed: () => _showCatchUpSheet(context, ref, l10n, state),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: Text(l10n.catchUp),
                        ),
                      ] else ...[
                        TextButton.icon(
                          onPressed: () => ref
                              .read(plannerProvider.notifier)
                              .redistributeWorkload(missedMinutes, l10n),
                          icon: const Icon(Icons.replay, size: 16),
                          label: Text(l10n.redistribute),
                        ),
                        const SizedBox(width: 8),
                        if (deviation.requiresRegeneration)
                          TextButton.icon(
                            onPressed: () => ref
                                .read(plannerProvider.notifier)
                                .regenerateFromAdherence(l10n),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(l10n.regeneratePlan),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatchUpSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n, PlannerState state) {
    final daysAway = state.adherenceDeviation is AbsenceDeviation
        ? (state.adherenceDeviation as AbsenceDeviation).daysSinceLastActivity
        : 3;
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
