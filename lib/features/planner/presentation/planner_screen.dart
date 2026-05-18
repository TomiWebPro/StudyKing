import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/data/models/session_model.dart';
import '../data/models/personal_learning_plan_model.dart';
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

class _SyllabusEntry {
  final TextEditingController subjectController;
  final TextEditingController daysController;
  final TextEditingController hoursController;

  _SyllabusEntry()
      : subjectController = TextEditingController(),
        daysController = TextEditingController(),
        hoursController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    daysController.dispose();
    hoursController.dispose();
  }
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final List<_SyllabusEntry> _syllabusEntries = [];
  bool _useMultiSyllabus = false;

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
    for (final entry in _syllabusEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId,
      {int durationMinutes = 45, String? scheduledSessionId}) {
    if (topicId.isEmpty) return;
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        durationMinutes: durationMinutes,
        scheduledSessionId: scheduledSessionId,
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
    final l10nGen = AppLocalizations.of(context)!;

    if (_useMultiSyllabus) {
      final validEntries = _syllabusEntries.where((e) =>
          e.subjectController.text.trim().isNotEmpty &&
          int.tryParse(e.daysController.text) != null &&
          int.tryParse(e.hoursController.text) != null &&
          int.parse(e.daysController.text) > 0 &&
          int.parse(e.hoursController.text) > 0).toList();

      if (validEntries.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10nGen.fillAllFieldsCorrectly)),
        );
        return;
      }

      final syllabusGoals = validEntries.map((e) => SyllabusGoal(
        subjectId: '',
        subjectTitle: e.subjectController.text.trim(),
        targetDays: int.parse(e.daysController.text),
        targetHoursPerDay: int.parse(e.hoursController.text),
      )).toList();

      final overallDays = syllabusGoals.fold<int>(0, (sum, g) => sum + g.targetDays) ~/ syllabusGoals.length;
      final overallHours = syllabusGoals.fold<int>(0, (sum, g) => sum + g.targetHoursPerDay);

      await ref.read(plannerProvider.notifier).generatePlanFromSyllabus(
        syllabusGoals: syllabusGoals,
        daysValue: overallDays.clamp(1, 365),
        hoursValue: overallHours.clamp(1, 24),
        l10n: l10nGen,
      );
      return;
    }

    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty ||
        daysValue == null ||
        hoursValue == null ||
        daysValue <= 0 ||
        hoursValue <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nGen.fillAllFieldsCorrectly)),
      );
      return;
    }

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
        semanticLabel: l10n.createRoadmap,
        title: Text(l10n.createRoadmap),
        content: SingleChildScrollView(
          child: Column(
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
                  labelText: l10n.subjectOptional,
                  hintText: l10n.subjectIdHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => selectedSubjectId = v.trim(),
              ),
            ],
          ),
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

    goalController.dispose();
    daysController.dispose();

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
            Semantics(label: l10n.studyPlanner, child: Tab(text: l10n.studyPlanner)),
            Semantics(label: l10n.calendar, child: Tab(text: l10n.calendar)),
            Semantics(label: l10n.roadmaps, child: Tab(text: l10n.roadmaps)),
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
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.adherenceDeviation != null &&
                state.adherenceDeviation!.requiresRegeneration) ...[
              _buildAdherenceBanner(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.plan != null) ...[
              _buildProgressOverlay(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.scheduledLessons.isNotEmpty) ...[
              _buildScheduledLessonsSection(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(l10n.createStudyPlan,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                TextButton.icon(
                  icon: Icon(_useMultiSyllabus ? Icons.subject : Icons.menu_book),
                  label: Text(_useMultiSyllabus ? l10n.courseSubject : l10n.subjects),
                  onPressed: () => setState(() => _useMultiSyllabus = !_useMultiSyllabus),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            if (_useMultiSyllabus)
              _buildMultiSyllabusInput(l10n)
            else ...[
              TextField(
                controller: _courseController,
                decoration: InputDecoration(
                  labelText: l10n.courseSubject,
                  hintText: l10n.courseHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
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
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
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
                      SizedBox(width: ResponsiveUtils.horizontalSpacing(context)),
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
            ],
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            Semantics(
              button: true,
              label: state.isGenerating ? l10n.generating : l10n.generatePlan,
              child: ElevatedButton.icon(
                onPressed: state.isGenerating ? null : _generatePlan,
                icon: state.isGenerating
                    ? ResponsiveUtils.loaderInTouchTarget(size: 20)
                    : const Icon(Icons.calendar_today),
                label: Text(state.isGenerating
                    ? l10n.generating
                    : l10n.generatePlan),
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            if (state.error != null && _tabController.index == 0)
              Container(
                padding: ResponsiveUtils.cardPadding(context),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            if (state.plan != null) ...[
              if (state.plan!.syllabusGoals.isNotEmpty)
                _buildSubjectProgressTabs(l10n, state)
              else ...[
                PlanSummaryCard(summary: state.plan!.summary),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              ],
              _buildDailyPlans(state, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSyllabusInput(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._syllabusEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: e.subjectController,
                          decoration: InputDecoration(
                            labelText: '${l10n.courseSubject} ${index + 1}',
                            hintText: l10n.courseHint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                        tooltip: l10n.delete,
                        onPressed: _syllabusEntries.length > 1
                            ? () {
                                setState(() {
                                  e.dispose();
                                  _syllabusEntries.removeAt(index);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: e.daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: e.hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.hoursPerDay,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCourseSubject),
          onPressed: () => setState(() => _syllabusEntries.add(_SyllabusEntry())),
        ),
      ],
    );
  }

  Widget _buildSubjectProgressTabs(AppLocalizations l10n, PlannerState state) {
    final goals = state.plan!.syllabusGoals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(l10n.subjectProgress,
            style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
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
                  Text(l10n.hoursPerDayAbbrev(formatDecimal(goal.targetHoursPerDay.toDouble(), l10n.localeName)),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        PlanSummaryCard(summary: state.plan!.summary),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
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
          final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '';
          final isCompleted = lesson.status == SessionStatus.completed || lesson.completed;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: Icon(
                isCompleted ? Icons.check_circle : Icons.menu_book,
                size: 20,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  )),
              subtitle: Text(
                l10n.lessonTimeStatus(lesson.topicId ?? '', time, isCompleted ? ' · ${l10n.completed}' : ''),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted)
                    Semantics(
                      button: true,
                      label: l10n.startTutoring,
                      child: IconButton(
                        icon: Icon(Icons.play_circle_filled, size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        tooltip: l10n.startTutoring,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.tutor,
                          arguments: TutorArgs(
                            topicId: lesson.topicId ?? '',
                            topicTitle: title,
                            subjectId: lesson.subjectId ?? '',
                            durationMinutes: lesson.plannedDurationMinutes ?? 45,
                            scheduledSessionId: lesson.id,
                          ),
                        ),
                      ),
                    ),
                  if (!isCompleted)
                    IconButton(
                      icon: Icon(Icons.refresh, size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      tooltip: l10n.rescheduleLesson,
                      onPressed: () => _openRescheduleLesson(lesson, l10n),
                    ),
                  if (!isCompleted)
                    IconButton(
                      icon: Icon(Icons.cancel_outlined, size: 18,
                          color: Theme.of(context).colorScheme.error),
                      tooltip: l10n.cancel,
                      onPressed: () => _confirmCancelLesson(lesson, l10n),
                    ),
                ],
              ),
            ),
          );
        }),
        if (state.scheduledLessons.length > 3)
          TextButton(
            onPressed: () {
              final first = state.scheduledLessons.first;
              Navigator.pushNamed(context, AppRoutes.lessonList,
                  arguments: LessonListArgs(
                    topicId: first.topicId ?? '',
                    topicTitle: l10n.scheduledLessons,
                    subjectId: first.subjectId ?? '',
                  ));
            },
            child: Text(l10n.moreLessonsCount(
                state.scheduledLessons.length - 3)),
          ),
      ],
    ),
    );
  }

  Future<void> _confirmCancelLesson(Session lesson, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel),
        content: Text(l10n.cancelLessonConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.noThanks),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(plannerProvider.notifier).cancelLesson(lesson.id, l10n);
    }
  }

  Future<void> _openRescheduleLesson(Session lesson, AppLocalizations l10n) async {
    if (!mounted) return;
    final plannerService = ref.read(plannerServiceProvider);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LessonBookingSheet(
        topicId: lesson.topicId ?? '',
        topicTitle: lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '',
        subjectId: lesson.subjectId ?? '',
        plannerService: plannerService,
        initialDate: lesson.startTime,
        initialDuration: lesson.plannedDurationMinutes ?? 30,
        onSchedule: (scheduledTime, durationMinutes) async {
          await ref.read(plannerProvider.notifier).rescheduleLesson(
                sessionId: lesson.id,
                newStartTime: scheduledTime,
                durationMinutes: durationMinutes,
                l10n: l10n,
              );
        },
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
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
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
                size: ResponsiveUtils.emptyStateIconSize(context),
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
            padding: ResponsiveUtils.screenPadding(context),
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
                        size: ResponsiveUtils.emptyStateIconSize(context),
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
                padding: ResponsiveUtils.screenPadding(context),
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
