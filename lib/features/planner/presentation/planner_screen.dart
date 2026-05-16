import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive.dart';
import '../providers/planner_providers.dart';
import 'widgets/plan_summary_card.dart';
import 'widgets/daily_plan_card.dart';
import 'widgets/roadmap_card.dart';
import 'widgets/pending_action_card.dart';
import 'widgets/lesson_booking_sheet.dart';
import 'widgets/progress_overlay_widget.dart';
import 'widgets/calendar_view_widget.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  final String? fixedStudentId;

  const PlannerScreen({super.key, this.fixedStudentId});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plannerProvider.notifier).loadInitialData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plannerProvider.notifier).loadAdditionalData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId) {
    if (topicId.isEmpty) return;
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
      ),
    );
  }

  Future<void> _openLessonBooking(
      String topicId, String topicTitle, String subjectId) async {
    if (!mounted) return;
    final l10nCtx = AppLocalizations.of(context)!;
    final plannerService = ref.read(plannerServiceProvider);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LessonBookingSheet(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        plannerService: plannerService,
        onSchedule: (scheduledTime, durationMinutes) async {
          await ref.read(plannerProvider.notifier).scheduleLesson(
                topicId: topicId,
                topicTitle: topicTitle,
                subjectId: subjectId,
                scheduledTime: scheduledTime,
                l10n: l10nCtx,
                durationMinutes: durationMinutes,
              );
        },
      ),
    );
  }

  Future<void> _generatePlan() async {
    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty ||
        daysValue == null ||
        hoursValue == null ||
        daysValue <= 0 ||
        hoursValue <= 0) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFieldsCorrectly)),
      );
      return;
    }

    final l10nGen = AppLocalizations.of(context)!;
    await ref.read(plannerProvider.notifier).generatePlan(
          course: course,
          daysValue: daysValue,
          hoursValue: hoursValue,
          l10n: l10nGen,
        );
  }

  Future<void> _showCreateRoadmapDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final goalController = TextEditingController();
    final daysController = TextEditingController();
    var selectedSubjectId = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createRoadmap),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalController,
              decoration: InputDecoration(
                labelText: l10n.roadmapGoal,
                hintText: l10n.roadmapGoalHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.days,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: l10n.studentIdOptional,
                hintText: l10n.subjectIdHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => selectedSubjectId = v.trim(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'goal': goalController.text.trim(),
              'days': daysController.text.trim(),
              'subjectId': selectedSubjectId,
            }),
            child: Text(l10n.generateRoadmap),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      goalController.dispose();
      daysController.dispose();
    });

    if (result == null || result['goal']!.isEmpty) return;

    final goal = result['goal']!;
    final days = int.tryParse(result['days'] ?? '') ?? 30;
    final subjectId = result['subjectId']?.isNotEmpty == true ? result['subjectId'] : null;

    if (!mounted) return;
    await ref.read(plannerProvider.notifier).createRoadmap(
          goal: goal,
          days: days,
          l10n: AppLocalizations.of(context)!,
          subjectId: subjectId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);

    ref.listen<PlannerState>(plannerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(plannerProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(plannerProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studyPlanner),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.studyPlanner),
            Tab(text: l10n.calendar),
            Tab(text: l10n.roadmaps),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyPlanTab(l10n, state),
          _buildCalendarTab(l10n, state),
          _buildRoadmapsTab(l10n, state),
        ],
      ),
    );
  }

  Widget _buildStudyPlanTab(AppLocalizations l10n, PlannerState state) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.screenPadding(context),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.pendingActions.isNotEmpty) ...[
              _buildPendingActionsSection(l10n, state),
              const SizedBox(height: 16),
            ],
            if (state.adherenceDeviation != null &&
                state.adherenceDeviation!.requiresRegeneration) ...[
              _buildAdherenceBanner(l10n, state),
              const SizedBox(height: 16),
            ],
            if (state.plan != null) ...[
              _buildProgressOverlay(),
              const SizedBox(height: 16),
            ],
            if (state.scheduledLessons.isNotEmpty) ...[
              _buildScheduledLessonsSection(l10n, state),
              const SizedBox(height: 16),
            ],
            Text(l10n.createStudyPlan,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _courseController,
              decoration: InputDecoration(
                labelText: l10n.courseSubject,
                hintText: l10n.courseHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = ResponsiveUtils.breakpointOf(context).isMobile;
                if (narrow) {
                  return Column(
                    children: [
                      TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.days,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.hoursPerDay,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.days,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.hoursPerDay,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: state.isGenerating ? l10n.generating : l10n.generatePlan,
              child: ElevatedButton.icon(
                onPressed: state.isGenerating ? null : _generatePlan,
                icon: state.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calendar_today),
                label: Text(state.isGenerating
                    ? l10n.generating
                    : l10n.generatePlan),
              ),
            ),
            const SizedBox(height: 16),
            if (state.error != null && _tabController.index == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            if (state.plan != null) ...[
              if (state.plan!.syllabusGoals.isNotEmpty)
                _buildSubjectProgressTabs(l10n, state)
              else ...[
                PlanSummaryCard(summary: state.plan!.summary),
                const SizedBox(height: 16),
              ],
              _buildDailyPlans(state, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectProgressTabs(AppLocalizations l10n, PlannerState state) {
    final goals = state.plan!.syllabusGoals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(l10n.subjectProgress,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...goals.map((goal) {
          final subjectPlans = state.plan!.subjectPlans;
          final topicCount = subjectPlans[goal.subjectId]?.length ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(goal.subjectTitle.isNotEmpty
                    ? goal.subjectTitle[0]
                    : 'S'),
              ),
              title: Text(goal.subjectTitle.isNotEmpty
                  ? goal.subjectTitle
                  : goal.subjectId),
              subtitle: Text(
                  '${goal.targetDays} ${l10n.days} ${l10n.planSummary} · $topicCount ${l10n.topics}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${goal.targetHoursPerDay}h/${l10n.days}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        PlanSummaryCard(summary: state.plan!.summary),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPendingActionsSection(
      AppLocalizations l10n, PlannerState state) {
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_active,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.pendingActions,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...state.pendingActions.map((action) => PendingActionCard(
              action: action,
              onAccept: () => ref
                  .read(plannerProvider.notifier)
                  .acceptPendingAction(action.id, l10n),
              onDismiss: () => ref
                  .read(plannerProvider.notifier)
                  .dismissPendingAction(action.id, l10n),
            )),
      ],
    ),
    );
  }

  Widget _buildAdherenceBanner(AppLocalizations l10n, PlannerState state) {
    final deviation = state.adherenceDeviation!;
    final missedMinutes = state.plan?.targetMinutesPerDay.toInt() ?? 60;
    return FocusTraversalGroup(
      child: Container(
      padding: const EdgeInsets.all(12),
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
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildScheduledLessonsSection(
      AppLocalizations l10n, PlannerState state) {
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.scheduledLessons,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...state.scheduledLessons.take(3).map((lesson) {
          final time = DateFormat.Hm(l10n.localeName).format(lesson.startTime);
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.menu_book, size: 20),
              title: Text(lesson.topicTitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(lesson.topicId),
              trailing: Text(time,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          );
        }),
        if (state.scheduledLessons.length > 3)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.lessonList,
                  arguments: LessonListArgs(
                    topicId: state.scheduledLessons.first.topicId,
                    topicTitle: l10n.scheduledLessons,
                    subjectId: state.scheduledLessons.first.subjectId,
                  ));
            },
            child: Text(l10n.moreLessonsCount(
                state.scheduledLessons.length - 3)),
          ),
      ],
    ),
    );
  }

  Widget _buildDailyPlans(PlannerState state, AppLocalizations l10n) {
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.yourStudySchedule,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...state.plan!.dailyPlans.map(
          (day) => DailyPlanCard(
            day: day,
            onStartTutoring: _openTutorMode,
            onScheduleLesson: _openLessonBooking,
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildProgressOverlay() {
    final progressAsync = ref.watch(planProgressProvider);
    return progressAsync.when(
      data: (data) {
        if (data.totalPlanDays == 0) return const SizedBox.shrink();
        return ProgressOverlayWidget(data: data);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCalendarTab(AppLocalizations l10n, PlannerState state) {
    if (state.plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(l10n.noStudyPlanYet, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return CalendarViewWidget(
      plan: state.plan!,
      onDayTap: (topicId, topicTitle, subjectId) {
        _openTutorMode(topicId, topicTitle, subjectId);
      },
    );
  }

  Widget _buildRoadmapsTab(AppLocalizations l10n, PlannerState state) {
    return FocusTraversalGroup(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateRoadmapDialog,
                icon: const Icon(Icons.add_road),
                label: Text(l10n.createRoadmap),
              ),
            ),
          ),
          if (state.isLoadingRoadmaps)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.roadmaps.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(l10n.noRoadmapsYet,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l10n.roadmapGoalHint,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.roadmaps.length,
                itemBuilder: (context, index) {
                  return RoadmapCard(
                    roadmap: state.roadmaps[index],
                    onToggleMilestone: (roadmapId, milestoneId, isCompleted) {
                      ref
                          .read(plannerProvider.notifier)
                          .toggleMilestoneCompletion(
                            roadmapId: roadmapId,
                            milestoneId: milestoneId,
                            isCompleted: isCompleted,
                            l10n: l10n,
                          );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
