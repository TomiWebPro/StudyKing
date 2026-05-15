import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';

class _MockPlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> savePlan(PersonalLearningPlan plan) async {
    _storage[plan.studentId] = plan;
  }

  @override
  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    return _storage[studentId];
  }

  @override
  Future<void> deletePlan(String studentId) async {
    _storage.remove(studentId);
  }

  @override
  Future<bool> hasPlan(String studentId) async {
    return _storage.containsKey(studentId);
  }

  @override
  Future<List<PersonalLearningPlan>> getAllPlans() async {
    return _storage.values.toList();
  }
}

PersonalLearningPlan createPlan({
  String studentId = 'student-1',
  int planDurationDays = 7,
}) {
  final now = DateTime(2025, 1, 15);
  return PersonalLearningPlan(
    studentId: studentId,
    generatedAt: now,
    dailyPlans: [
      DailyPlan(
        date: now,
        dayNumber: 1,
        priorityTopics: [
          PlannedTopic(
            topicId: 't1', topicTitle: 'Algebra',
            priority: 0.9, reason: 'Weak area',
            readinessScore: 0.3, reviewUrgency: 0.8,
            estimatedQuestions: 10, estimatedMinutes: 30,
            reasons: ['needs practice'],
          ),
        ],
        reviewQuestionIds: ['q1', 'q2'],
        stretchGoalQuestionIds: ['q3'],
        targetQuestions: 10,
        targetMinutes: 30,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: 10,
      totalMinutes: 30,
      newTopics: 2,
      reviewTopics: 3,
      estimatedCoverage: 0.75,
      focusAreas: ['algebra'],
    ),
    recommendations: [
      PlanRecommendation(
        topicId: 't1', reason: 'Weak', recommendationType: 'practice',
        priority: 0.9, explanations: ['needs work'],
      ),
    ],
    planDurationDays: planDurationDays,
  );
}

void main() {
  group('PlanRepository', () {
    late _MockPlanRepository repository;

    setUp(() {
      repository = _MockPlanRepository();
    });

    group('savePlan', () {
      test('stores a plan', () async {
        final plan = createPlan();
        await repository.savePlan(plan);
        final stored = await repository.loadPlan('student-1');
        expect(stored?.studentId, 'student-1');
      });

      test('overwrites existing plan for same student', () async {
        final plan1 = createPlan(planDurationDays: 7);
        final plan2 = createPlan(planDurationDays: 14);
        await repository.savePlan(plan1);
        await repository.savePlan(plan2);
        final stored = await repository.loadPlan('student-1');
        expect(stored?.planDurationDays, 14);
      });
    });

    group('loadPlan', () {
      test('returns null for non-existent student', () async {
        expect(await repository.loadPlan('none'), isNull);
      });

      test('returns stored plan', () async {
        final plan = createPlan();
        await repository.savePlan(plan);
        expect(await repository.loadPlan('student-1'), isNotNull);
      });
    });

    group('deletePlan', () {
      test('removes a plan', () async {
        final plan = createPlan();
        await repository.savePlan(plan);
        await repository.deletePlan('student-1');
        expect(await repository.loadPlan('student-1'), isNull);
      });

      test('does nothing for non-existent plan', () async {
        await repository.deletePlan('none');
      });
    });

    group('hasPlan', () {
      test('returns false when no plan exists', () async {
        expect(await repository.hasPlan('student-1'), isFalse);
      });

      test('returns true when plan exists', () async {
        await repository.savePlan(createPlan());
        expect(await repository.hasPlan('student-1'), isTrue);
      });
    });

    group('getAllPlans', () {
      test('returns all stored plans', () async {
        await repository.savePlan(createPlan(studentId: 's1'));
        await repository.savePlan(createPlan(studentId: 's2'));
        await repository.savePlan(createPlan(studentId: 's3'));
        expect((await repository.getAllPlans()).length, 3);
      });

      test('returns empty when no plans', () async {
        expect(await repository.getAllPlans(), isEmpty);
      });
    });
  });
}
