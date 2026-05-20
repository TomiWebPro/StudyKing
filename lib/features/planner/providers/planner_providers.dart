import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/shared_providers.dart' show localeProvider;
import 'package:studyking/features/lessons/providers/lesson_providers.dart' show lessonAgentServiceProvider;
import '../../../core/services/plan_adherence_orchestrator.dart';
import '../../../core/utils/study_utils.dart';
import '../services/planner_service.dart';
import 'package:studyking/core/utils/time_utils.dart';

final plannerServiceProvider = Provider<PlannerService>((ref) {
  final locale = ref.watch(localeProvider);
  return PlannerService(
    lessonAgentService: ref.watch(lessonAgentServiceProvider),
    localeName: locale.languageCode,
  );
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
  final planResult = await service.loadExistingPlan();
  final plan = planResult.data;
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

  final metricsResult = await service.getAdherenceMetrics();
  final metrics = metricsResult.data ?? <String, int>{};
  final actualMinutesToday = metrics['actualMinutesToday'] as int;
  final actualQuestionsToday = metrics['actualQuestionsToday'] as int;

  final todayProgress = plannedMinutesToday > 0
      ? (actualMinutesToday / plannedMinutesToday).clamp(0.0, 1.5)
      : 0.0;

  final adherenceRecordsResult = await service.getAdherenceRecords();
  final adherenceRecords = adherenceRecordsResult.data ?? [];

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
  final List<Session> missedLessons;
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
    this.missedLessons = const [],
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
    List<Session>? missedLessons,
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
      missedLessons: missedLessons ?? this.missedLessons,
      adherenceDeviation: adherenceDeviation ?? this.adherenceDeviation,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  PlannerState clearMessages() {
    return copyWith(error: null, successMessage: null);
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  static final Logger _logger = const Logger('PlannerNotifier');
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
    await loadMissedLessons();
    await checkAdherence();
  }

  Future<void> loadMissedLessons() async {
    try {
      final missedResult = await _service.getMissedLessons();
      state = state.copyWith(missedLessons: missedResult.data ?? []);
    } catch (e) {
      _logger.w('Failed to load missed lessons', e);
    }
  }

  Future<void> loadExistingPlan() async {
    try {
      final planResult = await _service.loadExistingPlan();
      final plan = planResult.data;
      if (plan != null) {
        final recordsResult = await _service.getAdherenceRecords();
        final records = recordsResult.data ?? [];
        final annotatedPlans = plan.dailyPlans.map((day) {
          final record = records.where((r) => r.date.dateOnly == day.date.dateOnly).firstOrNull;
          final isCompleted = record != null && record.adherenceScore >= 0.5;
          return day.copyWith(isCompleted: isCompleted);
        }).toList();
        state = state.copyWith(plan: plan.copyWith(dailyPlans: annotatedPlans));
      }
    } catch (e) {
      _logger.w('Failed to load existing plan', e);
      state = state.copyWith(error: 'failedToLoadPlan');
    }
  }

  Future<void> loadRoadmaps() async {
    state = state.copyWith(isLoadingRoadmaps: true);

    try {
      final roadmapsResult = await _service.loadRoadmaps();
      state = state.copyWith(
        roadmaps: roadmapsResult.data ?? [],
        isLoadingRoadmaps: false,
      );
    } catch (e) {
      _logger.w('Failed to load roadmaps', e);
      state = state.copyWith(
        isLoadingRoadmaps: false,
        error: 'failedToLoadRoadmaps',
      );
    }
  }

  Future<void> loadPendingActions() async {
    try {
      final actionsResult = await _service.loadPendingActions();
      state = state.copyWith(pendingActions: actionsResult.data ?? []);
    } catch (e) {
      _logger.w('Failed to load pending actions', e);
    }
  }

  Future<void> loadScheduledLessons() async {
    try {
      final lessonsResult = await _service.getScheduledLessons();
      state = state.copyWith(scheduledLessons: lessonsResult.data ?? []);
    } catch (e) {
      _logger.w('Failed to load scheduled lessons', e);
    }
  }

  Future<List<Session>> getMissedLessons() async {
    try {
      final result = await _service.getMissedLessons();
      return result.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> dismissAllMissed(AppLocalizations l10n) async {
    try {
      await _service.dismissAllMissed();
      state = state.copyWith(successMessage: l10n.missedDismissed);
    } catch (e) {
      state = state.copyWith(error: l10n.failedToDismissMissed);
    }
  }

  Future<void> checkAdherence() async {
    try {
      final deviationResult = await _service.planOrchestrator.checkAdherence(_service.studentId);
      state = state.copyWith(adherenceDeviation: deviationResult.data);
    } catch (e) {
      _logger.w('Failed to check adherence', e);
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
      final planResult = await _service.generatePlan(
        course: course,
        daysValue: daysValue,
        hoursValue: hoursValue,
      );
      final plan = planResult.data;
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
      _logger.w('Generate plan failed', e);
      state = state.copyWith(
        isGenerating: false,
        error: l10n.somethingWentWrong,
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
      final planResult = await _service.generatePlanFromSyllabus(
        syllabusGoals: syllabusGoals,
        daysValue: daysValue,
        hoursValue: hoursValue,
      );
      final plan = planResult.data;
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
      _logger.w('Generate plan from syllabus failed', e);
      state = state.copyWith(
        isGenerating: false,
        error: l10n.somethingWentWrong,
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
      final roadmapResult = await _service.createRoadmap(
        goal: goal,
        days: days,
        l10n: l10n,
        subjectId: subjectId,
      );
      await loadRoadmaps();
      final roadmap = roadmapResult.data;
      if (roadmap != null) {
        state = state.copyWith(successMessage: l10n.roadmapCreated(roadmap.goal));
      }
    } catch (e) {
      _logger.w('Failed to create roadmap', e);
      state = state.copyWith(error: l10n.failedToCreateRoadmap);
    }
  }

  Future<void> updateRoadmap({
    required String roadmapId,
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    try {
      await _service.updateRoadmap(
        roadmapId: roadmapId,
        goal: goal,
        days: days,
        l10n: l10n,
        subjectId: subjectId,
      );
      await loadRoadmaps();
      state = state.copyWith(successMessage: l10n.roadmapUpdated);
    } catch (e) {
      _logger.w('Failed to update roadmap', e);
      state = state.copyWith(error: l10n.failedToCreateRoadmap);
    }
  }

  Future<void> deleteRoadmap(String roadmapId, AppLocalizations l10n) async {
    try {
      await _service.roadmapRepo.deleteRoadmap(roadmapId);
      await loadRoadmaps();
      state = state.copyWith(successMessage: l10n.roadmapDeleted);
    } catch (e) {
      _logger.w('Failed to delete roadmap', e);
      state = state.copyWith(error: l10n.failedToCreateRoadmap);
    }
  }

  Future<void> toggleMilestoneCompletion({
    required String roadmapId,
    required String milestoneId,
    required bool isCompleted,
    required AppLocalizations l10n,
  }) async {
    try {
      final updatedResult = await _service.toggleMilestoneCompletion(
        roadmapId: roadmapId,
        milestoneId: milestoneId,
        isCompleted: isCompleted,
      );
      final updated = updatedResult.data;
      if (updated != null) {
        final idx = state.roadmaps.indexWhere((r) => r.id == roadmapId);
        if (idx >= 0) {
          final roadmaps = [...state.roadmaps];
          roadmaps[idx] = updated;
          state = state.copyWith(
            roadmaps: roadmaps,
            successMessage: l10n.milestoneUpdated,
          );
        }
      }
    } catch (e) {
      _logger.w('Failed to toggle milestone completion', e);
      await loadRoadmaps();
      state = state.copyWith(error: l10n.failedToUpdateMilestone);
    }
  }

  Future<void> acceptPendingAction(String actionId, AppLocalizations l10n) async {
    try {
      final successResult = await _service.acceptPendingAction(actionId);
      await loadPendingActions();
      if (successResult.data ?? false) {
        state = state.copyWith(successMessage: l10n.actionAccepted);
      } else {
        state = state.copyWith(error: l10n.failedToExecuteAction);
      }
    } catch (e) {
      _logger.w('Failed to accept pending action', e);
      state = state.copyWith(error: l10n.failedToAcceptAction);
    }
  }

  Future<void> dismissPendingAction(String actionId, AppLocalizations l10n) async {
    try {
      await _service.dismissPendingAction(actionId);
      await loadPendingActions();
    } catch (e) {
      _logger.w('Failed to dismiss pending action', e);
      state = state.copyWith(error: l10n.failedToDismissAction);
    }
  }

  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    required AppLocalizations l10n,
    int durationMinutes = defaultSessionDurationMinutes,
  }) async {
    try {
      final successResult = await _service.scheduleLesson(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      final success = successResult.data ?? false;
      if (success) {
        await loadScheduledLessons();
        state = state.copyWith(successMessage: l10n.lessonScheduled);
      }
      return success;
    } catch (e) {
      _logger.w('Failed to schedule lesson', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<void> regenerateFromAdherence(AppLocalizations l10n) async {
    state = state.copyWith(isGenerating: true);
    try {
      final planResult = await _service.planOrchestrator.suggestRegeneration(studentId: _service.studentId);
      final plan = planResult.data;
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
      _logger.w('Regenerate plan from adherence failed', e);
      state = state.copyWith(isGenerating: false, error: l10n.somethingWentWrong);
    }
  }

  Future<bool> scheduleLessonWithConflictCheck({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    required AppLocalizations l10n,
    int durationMinutes = defaultSessionDurationMinutes,
  }) async {
    try {
      final hasConflictResult = await _service.hasSchedulingConflict(
        startTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      if (hasConflictResult.data ?? false) {
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
      _logger.w('Failed to schedule lesson with conflict check', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<bool> cancelLesson(String sessionId, AppLocalizations l10n) async {
    try {
      final successResult = await _service.cancelLesson(sessionId);
      final success = successResult.data ?? false;
      if (success) {
        await loadScheduledLessons();
        state = state.copyWith(successMessage: l10n.sessionDeleted);
      }
      return success;
    } catch (e) {
      _logger.w('Failed to cancel lesson', e);
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
    try {
      final successResult = await _service.rescheduleLesson(
        sessionId: sessionId,
        newStartTime: newStartTime,
        durationMinutes: durationMinutes,
      );
      final success = successResult.data ?? false;
      if (success) {
        await loadScheduledLessons();
        state = state.copyWith(successMessage: l10n.lessonScheduled);
      }
      return success;
    } catch (e) {
      _logger.w('Failed to reschedule lesson', e);
      state = state.copyWith(error: l10n.failedToScheduleLesson);
      return false;
    }
  }

  Future<void> redistributeWorkload(int missedMinutes, AppLocalizations l10n, {String strategy = 'days:3'}) async {
    try {
      await _service.planService.redistributeMissedWorkloadForStudent(_service.studentId, missedMinutes, strategy: strategy);
      await loadExistingPlan();
      state = state.copyWith(
        successMessage: l10n.missedWorkloadRedistributed,
      );
    } catch (e) {
      _logger.w('Failed to redistribute workload', e);
      state = state.copyWith(error: l10n.failedToRedistributeWorkload);
    }
  }

  Future<void> extendPlan(int extraDays, AppLocalizations l10n) async {
    final result = await _service.planService.extendPlan(_service.studentId, extraDays);
    if (result.isFailure) {
      _logger.w('Failed to extend plan: ${result.error}');
      state = state.copyWith(error: l10n.failedToExtendPlan);
      return;
    }
    await loadExistingPlan();
    state = state.copyWith(successMessage: l10n.planExtended(extraDays));
  }

  Future<void> catchUpWithStrategy(String strategy, int missedDays, AppLocalizations l10n) async {
    Result<void>? result;
    if (strategy == 'extend') {
      result = await _service.planService.extendPlan(_service.studentId, missedDays);
    } else if (strategy.startsWith('redistribute:')) {
      final redistributeStrategy = strategy.split(':').last;
      final plan = state.plan;
      if (plan != null) {
        final missedMinutes = plan.targetMinutesPerDay.toInt() * missedDays;
        result = await _service.planService.redistributeMissedWorkloadForStudent(_service.studentId, missedMinutes, strategy: 'days:$redistributeStrategy');
      }
    } else if (strategy == 'regenerate') {
      await regenerateFromAdherence(l10n);
    }
    if (result != null && result.isFailure) {
      _logger.w('Failed to catch up: ${result.error}');
      state = state.copyWith(error: l10n.failedToCatchUp);
      return;
    }
    await loadExistingPlan();
  }

  Future<void> adjustPace(double newTargetMinutesPerDay, AppLocalizations l10n) async {
    try {
      await _service.adjustPace(newTargetMinutesPerDay);
      await loadExistingPlan();
      state = state.copyWith(successMessage: l10n.planAdjusted);
    } catch (e) {
      state = state.copyWith(error: l10n.failedToAdjustPlan);
    }
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  final service = ref.watch(plannerServiceProvider);
  return PlannerNotifier(service);
});
