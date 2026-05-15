import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import '../../../core/services/plan_adapter.dart';
import '../services/planner_service.dart';
import '../services/action_executor.dart';

final plannerServiceProvider = Provider<PlannerService>((ref) {
  return PlannerService();
});

final actionExecutorProvider = Provider<ActionExecutor>((ref) {
  final plannerService = ref.watch(plannerServiceProvider);
  return ActionExecutor(plannerService: plannerService);
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
  final todayStart = DateTime(now.year, now.month, now.day);

  int plannedMinutesToday = 0;
  int plannedQuestionsToday = 0;
  for (final day in plan.dailyPlans) {
    final dDay = DateTime(day.date.year, day.date.month, day.date.day);
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

  await service.adherenceRepo.init();
  final adherenceRecords = await service.adherenceRepo.getByStudent(service.studentId);

  final weeklyProgress = <DailyProgress>[];
  for (var i = 6; i >= 0; i--) {
    final day = todayStart.subtract(Duration(days: i));
    var pMin = 0;
    var aMin = 0;
    for (final dp in plan.dailyPlans) {
      final dDay = DateTime(dp.date.year, dp.date.month, dp.date.day);
      if (dDay == day) {
        pMin = dp.targetMinutes;
        break;
      }
    }
    for (final r in adherenceRecords) {
      final rDay = DateTime(r.date.year, r.date.month, r.date.day);
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
      final rDay = DateTime(r.date.year, r.date.month, r.date.day);
      final dDay = DateTime(d.date.year, d.date.month, d.date.day);
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
  final List<TutorSession> scheduledLessons;
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
    List<TutorSession>? scheduledLessons,
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
    try {
      final plan = await _service.loadExistingPlan();
      if (plan != null) {
        state = state.copyWith(plan: plan);
      }
    } catch (_) {}
  }

  Future<void> loadRoadmaps() async {
    state = state.copyWith(isLoadingRoadmaps: true);
    try {
      final roadmaps = await _service.loadRoadmaps();
      state = state.copyWith(
        roadmaps: roadmaps,
        isLoadingRoadmaps: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingRoadmaps: false);
    }
  }

  Future<void> loadPendingActions() async {
    try {
      final actions = await _service.loadPendingActions();
      state = state.copyWith(pendingActions: actions);
    } catch (_) {}
  }

  Future<void> loadScheduledLessons() async {
    try {
      final lessons = await _service.getScheduledLessons();
      state = state.copyWith(scheduledLessons: lessons);
    } catch (_) {}
  }

  Future<void> checkAdherence() async {
    try {
      final deviation = await _service.checkAdherence();
      state = state.copyWith(adherenceDeviation: deviation);
    } catch (_) {}
  }

  Future<void> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
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
          successMessage: 'Plan generated successfully',
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: 'Failed to generate plan',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Error: $e',
      );
    }
  }

  Future<void> generatePlanFromSyllabus({
    required List<SyllabusGoal> syllabusGoals,
    required int daysValue,
    required int hoursValue,
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
          successMessage: 'Syllabus-based plan generated successfully',
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: 'Failed to generate syllabus plan',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Error: $e',
      );
    }
  }

  Future<void> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    try {
      await _service.createRoadmap(
        goal: goal,
        days: days,
        l10n: l10n,
        subjectId: subjectId,
      );
      await loadRoadmaps();
      state = state.copyWith(successMessage: l10n.roadmapGoal);
    } catch (_) {
      state = state.copyWith(error: 'Failed to create roadmap');
    }
  }

  Future<void> toggleMilestoneCompletion({
    required String roadmapId,
    required String milestoneId,
    required bool isCompleted,
  }) async {
    try {
      await _service.toggleMilestoneCompletion(
        roadmapId: roadmapId,
        milestoneId: milestoneId,
        isCompleted: isCompleted,
      );
      await loadRoadmaps();
    } catch (_) {
      state = state.copyWith(error: 'Failed to update milestone');
    }
  }

  Future<void> acceptPendingAction(String actionId) async {
    try {
      final success = await _service.acceptPendingAction(actionId);
      await loadPendingActions();
      if (success) {
        state = state.copyWith(successMessage: 'Action accepted');
      } else {
        state = state.copyWith(error: 'Failed to execute action — missing parameters');
      }
    } catch (_) {
      state = state.copyWith(error: 'Failed to accept action');
    }
  }

  Future<void> dismissPendingAction(String actionId) async {
    try {
      await _service.dismissPendingAction(actionId);
      await loadPendingActions();
    } catch (_) {
      state = state.copyWith(error: 'Failed to dismiss action');
    }
  }

  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
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
        state = state.copyWith(successMessage: 'Lesson scheduled');
      }
      return success;
    } catch (_) {
      state = state.copyWith(error: 'Failed to schedule lesson');
      return false;
    }
  }

  Future<void> regenerateFromAdherence() async {
    state = state.copyWith(isGenerating: true);
    try {
      final plan = await _service.regeneratePlanFromAdherence();
      if (plan != null) {
        state = state.copyWith(
          plan: plan,
          isGenerating: false,
          successMessage: 'Plan regenerated based on your adherence',
        );
      } else {
        state = state.copyWith(isGenerating: false, error: 'Failed to regenerate');
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Error: $e');
    }
  }

  Future<bool> scheduleLessonWithConflictCheck({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    AppLocalizations? l10n,
    int durationMinutes = 30,
  }) async {
    try {
      final hasConflict = await _service.hasSchedulingConflict(
        startTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      if (hasConflict) {
        state = state.copyWith(error: l10n?.timeConflict ?? 'Time conflict with existing scheduled lesson');
        return false;
      }
      return await scheduleLesson(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to schedule lesson');
      return false;
    }
  }

  Future<void> redistributeWorkload(int missedMinutes) async {
    try {
      await _service.redistributeWorkload(missedMinutes);
      await loadExistingPlan();
      state = state.copyWith(
        successMessage: 'Missed workload redistributed over next 3 days',
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to redistribute workload');
    }
  }

  Future<void> linkDailyPlanToRoadmap(List<String> completedTopicIds) async {
    try {
      await _service.linkDailyPlanToRoadmap(completedTopicIds);
      await loadRoadmaps();
    } catch (_) {}
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  final service = ref.watch(plannerServiceProvider);
  return PlannerNotifier(service);
});
