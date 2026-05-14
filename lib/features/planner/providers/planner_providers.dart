import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../core/data/models/roadmap_model.dart';
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

  const PlannerState({
    this.plan,
    this.roadmaps = const [],
    this.isGenerating = false,
    this.isLoadingRoadmaps = false,
    this.error,
    this.successMessage,
  });

  PlannerState copyWith({
    PersonalLearningPlan? plan,
    List<RoadmapModel>? roadmaps,
    bool? isGenerating,
    bool? isLoadingRoadmaps,
    String? error,
    String? successMessage,
  }) {
    return PlannerState(
      plan: plan ?? this.plan,
      roadmaps: roadmaps ?? this.roadmaps,
      isGenerating: isGenerating ?? this.isGenerating,
      isLoadingRoadmaps: isLoadingRoadmaps ?? this.isLoadingRoadmaps,
      error: error,
      successMessage: successMessage,
    );
  }

  PlannerState clearMessages() {
    return copyWith(error: null, successMessage: null);
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  final PlannerService _service;

  PlannerNotifier(this._service) : super(const PlannerState());

  void clearMessages() {
    state = state.clearMessages();
  }

  Future<void> loadInitialData() async {
    await loadExistingPlan();
    await loadRoadmaps();
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

  Future<void> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
  }) async {
    try {
      await _service.createRoadmap(goal: goal, days: days, l10n: l10n);
      await loadRoadmaps();
      state = state.copyWith(successMessage: l10n.roadmapGoal);
    } catch (_) {
      state = state.copyWith(error: 'Failed to create roadmap');
    }
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  final service = ref.watch(plannerServiceProvider);
  return PlannerNotifier(service);
});
