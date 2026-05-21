import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'plan_summary_card.dart';
import 'syllabus_progress_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class SubjectProgressTabs extends ConsumerWidget {
  final String? fixedStudentId;

  const SubjectProgressTabs({super.key, this.fixedStudentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);
    if (state.plan == null) return const SizedBox.shrink();

    final goals = state.plan!.syllabusGoals;
    if (goals.isEmpty) return const SizedBox.shrink();

    final studentId = fixedStudentId ?? ref.read(studentIdServiceProvider).getStudentId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.subjectProgress,
            style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        ...goals.map((goal) {
          final subjectPlans = state.plan!.subjectPlans;
          final plansForSubject = subjectPlans[goal.subjectId] ?? [];
          final uniqueTopicCount = plansForSubject
              .expand((plan) => plan.priorityTopics)
              .map((t) => t.topicId)
              .toSet()
              .length;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(goal.subjectTitle.isNotEmpty
                          ? goal.subjectTitle[0]
                          : 'S'),
                    ),
                    title: Text(goal.subjectTitle.isNotEmpty
                        ? goal.subjectTitle
                        : l10n.unknown),
                    subtitle: Text(
                        '${goal.targetDays} ${l10n.days}, $uniqueTopicCount ${l10n.topics}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.hoursPerDayAbbrev(formatDecimal(goal.targetHoursPerDay.toDouble(), l10n.localeName)),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  SyllabusProgressCard(
                    studentId: studentId,
                    goal: goal,
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        PlanSummaryCard(
          summary: state.plan!.summary,
          syllabusGoals: goals,
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
      ],
    );
  }
}
