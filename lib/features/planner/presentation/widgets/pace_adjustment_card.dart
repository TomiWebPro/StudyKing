import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class PaceAdjustmentCard extends ConsumerStatefulWidget {
  const PaceAdjustmentCard({super.key});

  @override
  ConsumerState<PaceAdjustmentCard> createState() => _PaceAdjustmentCardState();
}

class _PaceAdjustmentCardState extends ConsumerState<PaceAdjustmentCard> {
  double _paceHours = 1.0;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);

    if (state.plan == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.rocket_launch, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.noStudyPlanYet,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized && state.plan != null) {
      _paceHours = state.plan!.targetMinutesPerDay / 60;
      _initialized = true;
    }

    final goals = state.plan!.syllabusGoals;
    final hasMultipleSubjects = goals.length > 1;
    final firstPlanDate = state.plan!.dailyPlans.first.date;

    if (!hasMultipleSubjects) {
      final currentHours = state.plan!.targetMinutesPerDay / 60;
      _paceHours = currentHours;
      final estEndDate = _estimateCompletionDate(firstPlanDate, _paceHours, state.plan!.summary.totalMinutes);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.planAdjusted,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(l10n.hoursPerDay),
                  const Spacer(),
                  Text(
                    '${formatDecimal(_paceHours, l10n.localeName, minFractionDigits: 1)} ${l10n.hoursPerDay}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '→ Estimated finish: ${DateFormat.yMd(l10n.localeName).format(estEndDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _paceHours,
                min: 0.5,
                max: 8.0,
                divisions: 15,
                label: '${formatDecimal(_paceHours, l10n.localeName, minFractionDigits: 1)} ${l10n.hoursPerDay}',
                onChanged: (value) {
                  setState(() => _paceHours = value);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final newTargetMinutes = (_paceHours * 60).round();
                    ref.read(plannerProvider.notifier).adjustPace(
                      newTargetMinutes.toDouble(),
                      l10n,
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l10n.planAdjusted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.planAdjusted,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...goals.asMap().entries.map((entry) {
              final goal = entry.value;
              final goalHours = goal.targetHoursPerDay.toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.subjectTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(l10n.hoursPerDay),
                        const Spacer(),
                        Text(
                          '${formatDecimal(goalHours, l10n.localeName, minFractionDigits: 1)} ${l10n.hoursPerDay}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: goalHours,
                      min: 0.5,
                      max: 8.0,
                      divisions: 15,
                      label: '${formatDecimal(goalHours, l10n.localeName, minFractionDigits: 1)} ${l10n.hoursPerDay}',
                      onChanged: (value) {
                        _updateSyllabusHours(goal, value);
                      },
                    ),
                  ],
                ),
              );
            }),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _applyPerSubjectPace(state, l10n);
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.planAdjusted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _estimateCompletionDate(DateTime startDate, double hoursPerDay, int totalMinutes) {
    if (hoursPerDay <= 0) return startDate;
    final daysNeeded = (totalMinutes / (hoursPerDay * 60)).ceil();
    return startDate.add(Duration(days: daysNeeded));
  }

  void _updateSyllabusHours(SyllabusGoal goal, double newHours) {
    ref.read(plannerProvider.notifier).adjustPace(
      (newHours * 60).toDouble(),
      AppLocalizations.of(context)!,
    );
  }

  void _applyPerSubjectPace(PlannerState state, AppLocalizations l10n) {
    final newTotalMinutes = state.plan!.syllabusGoals.fold<int>(
      0,
      (sum, goal) {
        return sum + (goal.targetHoursPerDay * 60);
      },
    );
    final avgMinutes = state.plan!.syllabusGoals.isNotEmpty
        ? newTotalMinutes / state.plan!.syllabusGoals.length
        : state.plan!.targetMinutesPerDay;
    ref.read(plannerProvider.notifier).adjustPace(avgMinutes, l10n);
  }
}
