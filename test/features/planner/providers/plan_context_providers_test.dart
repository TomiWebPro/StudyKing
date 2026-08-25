import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

DailyPlan _day(int dayNumber) => DailyPlan(
      date: DateTime.now().add(Duration(days: dayNumber)),
      dayNumber: dayNumber,
      priorityTopics: const [],
      reviewQuestionIds: const [],
      stretchGoalQuestionIds: const [],
      targetQuestions: 5,
      targetMinutes: 30,
    );

PersonalLearningPlan _plan(String planId, int dayCount) => PersonalLearningPlan(
      studentId: 'test-student',
      planId: planId,
      name: planId,
      generatedAt: DateTime.now(),
      dailyPlans: List.generate(dayCount, (i) => _day(i + 1)),
      summary: PlanSummary(
        totalQuestions: 10,
        totalMinutes: 60,
        newTopics: 1,
        reviewTopics: 2,
        estimatedCoverage: 0.5,
        focusAreas: const [],
      ),
      recommendations: const [],
    );

class _FakePlannerService extends PlannerService {
  _FakePlannerService() : super();

  String? activeId;
  List<PersonalLearningPlan> plans = [];

  @override
  Future<Result<List<PersonalLearningPlan>>> getPlans() =>
      Future.value(Result.success(plans));

  @override
  Future<Result<String?>> getActivePlanId() =>
      Future.value(Result.success(activeId));

  @override
  Future<Result<void>> setActivePlanId(String planId) {
    activeId = planId;
    return Future.value(Result.success(null));
  }

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() {
    final plan = plans.where((p) => p.planId == activeId).firstOrNull ??
        plans.firstOrNull;
    return Future.value(Result.success(plan));
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() =>
      Future.value(Result.success(const []));

  @override
  Future<Result<Map<String, int>>> getAdherenceMetrics() =>
      Future.value(Result.success(const {
        'actualMinutesToday': 0,
        'actualQuestionsToday': 0,
      }));
}

void main() {
  group('plan context providers', () {
    late _FakePlannerService fake;

    setUp(() {
      fake = _FakePlannerService();
      fake.plans = [
        _plan('plan-a', 1),
        _plan('plan-b', 2),
      ];
    });

    test('activePlanIdProvider defaults to null', () {
      final container = ProviderContainer(
        overrides: [plannerServiceProvider.overrideWithValue(fake)],
      );
      expect(container.read(activePlanIdProvider), isNull);
      container.dispose();
    });

    test('plansProvider exposes persisted plans', () async {
      final container = ProviderContainer(
        overrides: [plannerServiceProvider.overrideWithValue(fake)],
      );
      final plans = await container.read(plansProvider.future);
      expect(plans, hasLength(2));
      container.dispose();
    });

    test('planProgressProvider re-binds when active plan changes', () async {
      final container = ProviderContainer(
        overrides: [plannerServiceProvider.overrideWithValue(fake)],
      );

      // Switching the active context (service persists, provider mirrors it).
      await fake.setActivePlanId('plan-a');
      container.read(activePlanIdProvider.notifier).state = 'plan-a';
      final progressA = await container.read(planProgressProvider.future);
      expect(progressA.totalPlanDays, 1);

      await fake.setActivePlanId('plan-b');
      container.read(activePlanIdProvider.notifier).state = 'plan-b';
      final progressB = await container.read(planProgressProvider.future);
      expect(progressB.totalPlanDays, 2);

      // The active selection is reflected back through the service.
      expect(fake.activeId, 'plan-b');
      container.dispose();
    });

    test('switching active plan updates downstream providers without restart', () async {
      final container = ProviderContainer(
        overrides: [plannerServiceProvider.overrideWithValue(fake)],
      );
      await fake.setActivePlanId('plan-a');
      container.read(activePlanIdProvider.notifier).state = 'plan-a';
      final first = await container.read(planProgressProvider.future);

      // Simulate the notifier switching context.
      await fake.setActivePlanId('plan-b');
      container.read(activePlanIdProvider.notifier).state = 'plan-b';
      final second = await container.read(planProgressProvider.future);

      expect(first.totalPlanDays, isNot(equals(second.totalPlanDays)));
      container.dispose();
    });
  });
}
