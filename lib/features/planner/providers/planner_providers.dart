import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../core/data/models/roadmap_model.dart';
import '../../../core/data/models/pending_action_model.dart';
import '../../../core/data/models/tutor_session_model.dart';
import '../../../core/services/plan_adapter.dart';
import '../services/planner_service.dart';

final plannerServiceProvider = Provider<PlannerService>((ref) {
  return PlannerService();
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
      await _service.acceptPendingAction(actionId);
      await loadPendingActions();
      state = state.copyWith(successMessage: 'Action accepted');
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
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  final service = ref.watch(plannerServiceProvider);
  return PlannerNotifier(service);
});
