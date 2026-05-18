import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import '../../../core/services/plan_adapter.dart';
import '../services/planner_service.dart';
import '../services/action_executor.dart';
import 'package:studyking/core/utils/time_utils.dart';

final plannerServiceProvider = Provider<PlannerService>((ref) {
  return PlannerService();
});

final actionExecutorProvider = Provider<ActionExecutor>((ref) {
  final plannerService = ref.watch(plannerServiceProvider);
  return ActionExecutor(actionPlanner: plannerService);
});

class PlanProgressData {
  final int plannedMinutesToday;
  final int actualMinutesToday;
  final int plannedQuestionsToday;
  final int actualQuestionsToday;
  final double todayProgress;
  final int totalPlanDays;
  final int completedDays;
  final double cumulativeProgress;
  final List<DailyProgress> weeklyProgress;

  const PlanProgressData({
    this.plannedMinutesToday = 0,
    this.actualMinutesToday = 0,
    this.plannedQuestionsToday = 0,
    this.actualQuestionsToday = 0,
    this.todayProgress = 0.0,
    this.totalPlanDays = 0,
    this.completedDays = 0,
    this.cumulativeProgress = 0.0,
    this.weeklyProgress = const [],
  });
}

class DailyProgress {
  final DateTime date;
  final int plannedMinutes;
  final int actualMinutes;

  const DailyProgress({
    required this.date,
    this.plannedMinutes = 0,
    this.actualMinutes = 0,
  });
}

final planProgressProvider = FutureProvider<PlanProgressData>((ref) async {
  final service = ref.watch(plannerServiceProvider);
  final plan = await service.loadExistingPlan();
  if (plan == null) return const PlanProgressData();

  final now = DateTime.now();
  final todayStart = now.dateOnly;

  int plannedMinutesToday = 0;
  int plannedQuestionsToday = 0;
  for (final day in plan.dailyPlans) {
    final dDay = day.date.dateOnly;
    if (dDay == todayStart) {
      plannedMinutesToday = day.targetMinutes;
      plannedQuestionsToday = day.targetQuestions;
      break;
    }
  }

  final metrics = await service.getAdherenceMetrics();
  final actualMinutesToday = metrics['actualMinutesToday'] as int;
  final actualQuestionsToday = metrics['actualQuestionsToday'] as int;

  final todayProgress = plannedMinutesToday > 0
      ? (actualMinutesToday / plannedMinutesToday).clamp(0.0, 1.5)
      : 0.0;

  final adherenceRecords = await service.getAdherenceRecords();

  final weeklyProgress = <DailyProgress>[];
  for (var i = 6; i >= 0; i--) {
    final day = todayStart.subtract(Duration(days: i));
    var pMin = 0;
    var aMin = 0;
    for (final dp in plan.dailyPlans) {
      final dDay = dp.date.dateOnly;
      if (dDay == day) {
        pMin = dp.targetMinutes;
        break;
      }
    }
    for (final r in adherenceRecords) {
      final rDay = r.date.dateOnly;
      if (rDay == day) {
        aMin += r.actualMinutes;
      }
    }
    weeklyProgress.add(DailyProgress(
      date: day,
      plannedMinutes: pMin,
      actualMinutes: aMin,
    ));
  }

  final completedDays = plan.dailyPlans.where((d) {
    if (d.isRestDay) return true;
    for (final r in adherenceRecords) {
      final rDay = r.date.dateOnly;
      final dDay = d.date.dateOnly;
      if (rDay == dDay && r.adherenceScore >= 0.5) return true;
    }
    return false;
  }).length;

  final totalPlanDays = plan.dailyPlans.length;
  final cumulativeProgress = totalPlanDays > 0 ? completedDays / totalPlanDays : 0.0;

  return PlanProgressData(
    plannedMinutesToday: plannedMinutesToday,
    actualMinutesToday: actualMinutesToday,
    plannedQuestionsToday: plannedQuestionsToday,
    actualQuestionsToday: actualQuestionsToday,
    todayProgress: todayProgress,
    totalPlanDays: totalPlanDays,
    completedDays: completedDays,
    cumulativeProgress: cumulativeProgress,
    weeklyProgress: weeklyProgress,
  );
});

class PlannerState {
  final PersonalLearningPlan? plan;
  final List<RoadmapModel> roadmaps;
  final bool isGenerating;
  final bool isLoadingRoadmaps;
  final String? error;
  final String? successMessage;
  final List<PendingActionModel> pendingActions;
  final List<Session> scheduledLessons;
  final AdherenceDeviation? adherenceDeviation;
  final int activeTab;

  const PlannerState({
    this.plan,
    this.roadmaps = const [],
    this.isGenerating = false,
    this.isLoadingRoadmaps = false,
    this.error,
    this.successMessage,
    this.pendingActions = const [],
    this.scheduledLessons = const [],
    this.adherenceDeviation,
    this.activeTab = 0,
  });

  PlannerState copyWith({
    PersonalLearningPlan? plan,
    List<RoadmapModel>? roadmaps,
    bool? isGenerating,
    bool? isLoadingRoadmaps,
    String? error,
    String? successMessage,
    List<PendingActionModel>? pendingActions,
    List<Session>? scheduledLessons,
    AdherenceDeviation? adherenceDeviation,
    int? activeTab,
  }) {
    return PlannerState(
      plan: plan ?? this.plan,
      roadmaps: roadmaps ?? this.roadmaps,
      isGenerating: isGenerating ?? this.isGenerating,
      isLoadingRoadmaps: isLoadingRoadmaps ?? this.isLoadingRoadmaps,
      error: error,
      successMessage: successMessage,
      pendingActions: pendingActions ?? this.pendingActions,
      scheduledLessons: scheduledLessons ?? this.scheduledLessons,
      adherenceDeviation: adherenceDeviation ?? this.adherenceDeviation,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  PlannerState clearMessages() {
    return copyWith(error: null, successMessage: null);
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  final PlannerService _service;

  PlannerNotifier(this._service) : super(const PlannerState());

  PlannerState get currentState => state;
  set currentState(PlannerState newState) => state = newState;

  void setActiveTab(int index) {
    state = state.copyWith(activeTab: index);
  }

  void clearMessages() {
    state = state.clearMessages();
  }

  Future<void> loadInitialData() async {
    await loadExistingPlan();
    await loadRoadmaps();
  }

  Future<void> loadAdditionalData() async {
    await loadPendingActions();
    await loadScheduledLessons();
    await checkAdherence();
  }

  Future<void> loadExistingPlan() async {
    final logger = const Logger('PlannerNotifier.loadExistingPlan');
    try {
      final plan = await _service.loadExistingPlan();
      if (plan != null) {
        state = state.copyWith(plan: plan);
      }
    } catch (e) {
      logger.e('Failed to load existing plan', e);
      state = state.copyWith(error: 'Failed_to_load_plan: $e');
    }
  }

  Future<void> loadRoadmaps() async {
    final logger = const Logger('PlannerNotifier.loadRoadmaps');



    try {
      final roadmaps = await _service.loadRoadmaps();
      state = state.copyWith(
        roadmaps: roadmaps,
        isLoadingRoadmaps: false,
      );
    } catch (e) {
      logger.e('Failed to load roadmaps', e);
      state = state.copyWith(isLoadingRoadmaps: false);
    }
  }

  Future<void> loadPendingActions() async {
    final logger = const Logger('PlannerNotifier.loadPendingActions');
    try {
      final actions = await _service.loadPendingActions();
      state = state.copyWith(pendingActions: actions);
    } catch (e) {
      logger.e('Failed to load pending actions', e);
    }
  }

  Future<void> loadScheduledLessons() async {
    final logger = const Logger('PlannerNotifier.loadScheduledLessons');
    try {
      final lessons = await _service.getScheduledLessons();
      state = state.copyWith(scheduledLessons: lessons);
    } catch (e) {
      logger.e('Failed to load scheduled lessons', e);
    }
  }

  Future<void> checkAdherence() async {
    final logger = const Logger('PlannerNotifier.checkAdherence');
    try {
      final deviation = await _service.checkAdherence();
      state = state.copyWith(adherenceDeviation: deviation);
    } catch (e) {
      logger.e('Failed to check adherence', e);
    }
  }

  Future<void> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
    required AppLocalizations l10n,
  }) async {
    state = state.copyWith(isGenerating: true, error: null, successMessage: null);

    try {
      final plan = await _service.generatePlan(
        course: course,
        daysValue: daysValue,
        hoursValue: hoursValue,
      );
      if (plan != null) {
        state = state.copyWith(
          plan: plan,
          isGenerating: false,
          successMessage: l10n.planGeneratedSuccessfully,
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: l10n.failedToGeneratePlan,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: l10n.errorWithMessage(e.toString()),
      );
    }
  }

  Future<void> generatePlanFromSyllabus({
    required List<SyllabusGoal> syllabusGoals,
    required int daysValue,
    required int hoursValue,
    required AppLocalizations l10n,
  }) async {
    state = state.copyWith(isGenerating: true, error: null, successMessage: null);

    try {
      final plan = await _service.generatePlanFromSyllabus(
        syllabusGoals: syllabusGoals,
        daysValue: daysValue,
        hoursValue: hoursValue,
      );
      if (plan != null) {
        state = state.copyWith(
          plan: plan,
          isGenerating: false,
          successMessage: l10n.syllabusPlanGenerated,
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: l10n.failedToGenerateSyllabusPlan,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: l10n.errorWithMessage(e.toString()),
      );
    }
  }

  Future<void> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    final logger = const Logger('PlannerNotifier.createRoadmap');
    try {
      await _service.createRoadmap(
        goal: goal,
        days: days,
        l10n: l10n,
        subjectId: subjectId,
      );
      await loadRoadmaps();
      state = state.copyWith(successMessage: l10n.roadmapGoal);
    } catch (e) {
      logger.e('Failed to create roadmap', e);
      state = state.copyWith(error: l10n.failedToCreateRoadmap);
    }
  }

  Future<void> toggleMilestoneCompletion({
    required String roadmapId,
    required String milestoneId,
    required bool isCompleted,
    required AppLocalizations l10n,
  }) async {
    final logger = const Logger('PlannerNotifier.toggleMilestoneCompletion');
    try {
      await _service.toggleMilestoneCompletion(
        roadmapId: roadmapId,
        milestoneId: milestoneId,
        isCompleted: isCompleted,
      );
      await loadRoadmaps();
    } catch (e) {
      logger.e('Failed to toggle milestone completion', e);
      state = state.copyWith(error: l10n.failedToUpdateMilestone);
    }
  }

  Future<void> acceptPendingAction(String actionId, AppLocalizations l10n) async {
    final logger = const Logger('PlannerNotifier.acceptPendingAction');
    try {
      final success = await _service.acceptPendingAction(actionId);
      await loadPendingActions();
      if (success) {
        state = state.copyWith(successMessage: l10n.actionAccepted);
      } else {
        state = state.copyWith(error: l10n.failedToExecuteAction);
      }
    } catch (e) {
      logger.e('Failed to accept pending action', e);
      state = state.copyWith(error: l10n.failedToAcceptAction);
    }
  }

  Future<void> dismissPendingAction(String actionId, AppLocalizations l10n) async {
    final logger = const Logger('PlannerNotifier.dismissPendingAction');
    try {
      await _service.dismissPendingAction(actionId);
      await loadPendingActions();
    } catch (e) {
      logger.e('Failed to dismiss pending action', e);
      state = state.copyWith(error: l10n.failedToDismissAction);
    }
  }

  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    required AppLocalizations l10n,
    int durationMinutes = 30,
  }) async {
    final logger = const Logger('PlannerNotifier.scheduleLesson');
    try {
      final success = await _service.scheduleLesson(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      if (success) {
        await loadScheduledLessons();
        state = state.copyWith(successMessage: l10n.lessonScheduled);
      }
      return success;
    } catch (e) {
      logger.e('Failed to schedule lesson', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<void> regenerateFromAdherence(AppLocalizations l10n) async {
    state = state.copyWith(isGenerating: true);
    try {
      final plan = await _service.regeneratePlanFromAdherence();
      if (plan != null) {
        state = state.copyWith(
          plan: plan,
          isGenerating: false,
          successMessage: l10n.planRegeneratedFromAdherence,
        );
      } else {
        state = state.copyWith(isGenerating: false, error: l10n.failedToRegeneratePlan);
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: l10n.errorWithMessage(e.toString()));
    }
  }

  Future<bool> scheduleLessonWithConflictCheck({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    required AppLocalizations l10n,
    int durationMinutes = 30,
  }) async {
    final logger = const Logger('PlannerNotifier.scheduleLessonWithConflictCheck');
    try {
      final hasConflict = await _service.hasSchedulingConflict(
        startTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      if (hasConflict) {
        state = state.copyWith(error: l10n.timeConflict);
        return false;
      }
      return await scheduleLesson(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        scheduledTime: scheduledTime,
        l10n: l10n,
        durationMinutes: durationMinutes,
      );
    } catch (e) {
      logger.e('Failed to schedule lesson with conflict check', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<bool> cancelLesson(String sessionId, AppLocalizations l10n) async {
    final logger = const Logger('PlannerNotifier.cancelLesson');
    try {
      final success = await _service.cancelLesson(sessionId);
      if (success) {
        await loadScheduledLessons();
        state = state.copyWith(successMessage: l10n.sessionDeleted);
      }
      return success;
    } catch (e) {
      logger.e('Failed to cancel lesson', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<bool> rescheduleLesson({
    required String sessionId,
    required DateTime newStartTime,
    required int durationMinutes,
    required AppLocalizations l10n,
  }) async {
    final logger = const Logger('PlannerNotifier.rescheduleLesson');
    try {
      final success = await _service.rescheduleLesson(
        sessionId: sessionId,
        newStartTime: newStartTime,
        durationMinutes: durationMinutes,
      );
      if (success) {
        await loadScheduledLessons();
        state = state.copyWith(successMessage: l10n.lessonScheduled);
      }
      return success;
    } catch (e) {
      logger.e('Failed to reschedule lesson', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<void> redistributeWorkload(int missedMinutes, AppLocalizations l10n) async {
    final logger = const Logger('PlannerNotifier.redistributeWorkload');
    try {
      await _service.redistributeWorkload(missedMinutes);
      await loadExistingPlan();
      state = state.copyWith(
        successMessage: l10n.missedWorkloadRedistributed,
      );
    } catch (e) {
      logger.e('Failed to redistribute workload', e);
      state = state.copyWith(error: l10n.failedToRedistributeWorkload);
    }
  }

  Future<void> linkDailyPlanToRoadmap(List<String> completedTopicIds) async {
    final logger = const Logger('PlannerNotifier.linkDailyPlanToRoadmap');
    try {
      await _service.linkDailyPlanToRoadmap(completedTopicIds);
      await loadRoadmaps();
    } catch (e) {
      logger.e('Failed to link daily plan to roadmap', e);
    }
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  final service = ref.watch(plannerServiceProvider);
  return PlannerNotifier(service);
});
