import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'planner_service_test_helpers.dart';

PersonalLearningPlan _samplePlan({
  required String studentId,
  required String planId,
  String name = '',
}) {
  return PersonalLearningPlan(
    studentId: studentId,
    planId: planId,
    name: name,
    generatedAt: DateTime.now(),
    dailyPlans: const [],
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
}

class FakeGenerationPlanService extends PersonalLearningPlanService {
  FakeGenerationPlanService()
      : super(
          masteryService: MasteryGraphService(),
          repository: FakeMasteryGraphRepository(),
          topicRepository: FakeTopicRepository(),
          planRepository: FakePlanRepository(),
          adherenceRepository: FakeAdherenceRepo(),
          roadmapRepository: FakeRoadmapRepository(),
          questionRepository: QuestionRepository(),
        );

  @override
  Future<Result<PersonalLearningPlan>> generatePlan(
    String studentId, {
    String courseName = '',
  }) async {
    return Result.success(_samplePlan(
      studentId: studentId,
      planId: 'generated-$courseName',
      name: courseName,
    ));
  }

  @override
  Future<Result<PersonalLearningPlan>> generatePlanFromSyllabus({
    required String studentId,
    required List<SyllabusGoal> syllabusGoals,
  }) async {
    return Result.success(_samplePlan(
      studentId: studentId,
      planId: 'generated-syllabus',
      name: 'Syllabus plan',
    ));
  }
}

void main() {
  group('PlannerService multi-plan support', () {
    late FakePlanRepository planRepo;
    late FakePlanContextRepository contextRepo;
    late PlannerService service;

    setUp(() {
      planRepo = FakePlanRepository();
      contextRepo = FakePlanContextRepository();
      service = createPlannerService(
        planRepo: planRepo,
        planContextRepo: contextRepo,
        planService: FakeGenerationPlanService(),
        roadmapRepo: FakeRoadmapRepository(),
        sessionRepo: FakeSessionRepository(),
        pendingActionRepo: FakePendingActionRepository(),
        adherenceRepo: FakeAdherenceRepo(),
        planOrchestrator: FakePlanAdherenceOrchestrator(),
      );
    });

    test('getPlans returns all plans for the student', () async {
      await planRepo.savePlan(_samplePlan(
        studentId: 'test-student',
        planId: 'plan-a',
        name: 'Plan A',
      ));
      await planRepo.savePlan(_samplePlan(
        studentId: 'test-student',
        planId: 'plan-b',
        name: 'Plan B',
      ));

      final result = await service.getPlans();
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
    });

    test('generating a plan persists it and sets it active', () async {
      final result = await service.generatePlan(
        course: 'Math',
        daysValue: 30,
        hoursValue: 2,
      );
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      final plan = result.data!;
      expect(plan.planId, isNot(equals('test-student')));

      final activeResult = await service.getActivePlanId();
      expect(activeResult.data, equals(plan.planId));

      final plans = await service.getPlans();
      expect(plans.data, hasLength(1));
    });

    test('generating multiple plans creates independent plans', () async {
      final first = await service.generatePlan(
        course: 'Math',
        daysValue: 30,
        hoursValue: 2,
      );
      final second = await service.generatePlan(
        course: 'Physics',
        daysValue: 20,
        hoursValue: 1,
      );
      expect(first.data!.planId, isNot(equals(second.data!.planId)));

      final plans = await service.getPlans();
      expect(plans.data, hasLength(2));

      final active = await service.getActivePlanId();
      expect(active.data, equals(second.data!.planId));
    });

    test('loadExistingPlan returns the active plan', () async {
      final planA = _samplePlan(studentId: 'test-student', planId: 'plan-a', name: 'A');
      final planB = _samplePlan(studentId: 'test-student', planId: 'plan-b', name: 'B');
      await planRepo.savePlan(planA);
      await planRepo.savePlan(planB);
      await contextRepo.setActivePlanId('test-student', 'plan-a');

      final result = await service.loadExistingPlan();
      expect(result.data?.planId, equals('plan-a'));
    });

    test('loadExistingPlan falls back to legacy single plan when no active id', () async {
      final legacy = _samplePlan(studentId: 'test-student', planId: 'test-student', name: 'Legacy');
      await planRepo.savePlan(legacy);

      final result = await service.loadExistingPlan();
      expect(result.data?.planId, equals('test-student'));
    });

    test('setActivePlanId rejects a plan that does not belong to the student', () async {
      final result = await service.setActivePlanId('foreign-plan');
      expect(result.isFailure, isTrue);
    });

    test('deletePlan removes the plan and clears the active selection', () async {
      final plan = _samplePlan(studentId: 'test-student', planId: 'plan-a', name: 'A');
      await planRepo.savePlan(plan);
      await contextRepo.setActivePlanId('test-student', 'plan-a');

      final deleteResult = await service.deletePlan('plan-a');
      expect(deleteResult.isSuccess, isTrue);

      final plans = await service.getPlans();
      expect(plans.data, isEmpty);

      final active = await service.getActivePlanId();
      expect(active.data, isNull);
    });

    test('switching the active plan changes loadExistingPlan result', () async {
      final planA = _samplePlan(studentId: 'test-student', planId: 'plan-a', name: 'A');
      final planB = _samplePlan(studentId: 'test-student', planId: 'plan-b', name: 'B');
      await planRepo.savePlan(planA);
      await planRepo.savePlan(planB);

      await service.setActivePlanId('plan-a');
      expect((await service.loadExistingPlan()).data?.planId, equals('plan-a'));

      await service.setActivePlanId('plan-b');
      expect((await service.loadExistingPlan()).data?.planId, equals('plan-b'));
    });
  });
}
