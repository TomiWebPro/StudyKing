import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/adapters/personal_learning_plan_adapter.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';

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
  group('PlanRepository with real Hive', () {
    late String hivePath;
    late PlanRepository repository;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('plan_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(PersonalLearningPlanAdapter());
      }
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(DailyPlanAdapter());
      }
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(PlannedTopicAdapter());
      }
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(PlanSummaryAdapter());
      }
      if (!Hive.isAdapterRegistered(23)) {
        Hive.registerAdapter(PlanRecommendationAdapter());
      }
      repository = PlanRepository();
      await repository.init();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('init opens the box and readies the repository', () {
      expect(repository, isNotNull);
    });

    group('savePlan', () {
      test('stores a plan', () async {
        final plan = createPlan();
        await repository.savePlan(plan);
        final stored = await repository.loadPlan('student-1');
        expect(stored, isNotNull);
        expect(stored!.studentId, 'student-1');
      });

      test('stores a plan retrievable by studentId', () async {
        final plan = createPlan(studentId: 'custom-student');
        await repository.savePlan(plan);
        final stored = await repository.loadPlan('custom-student');
        expect(stored, isNotNull);
      });

      test('overwrites existing plan for same student', () async {
        final plan1 = createPlan(planDurationDays: 7);
        final plan2 = createPlan(planDurationDays: 14);
        await repository.savePlan(plan1);
        await repository.savePlan(plan2);
        final stored = await repository.loadPlan('student-1');
        expect(stored?.planDurationDays, 14);
      });

      test('preserves all fields', () async {
        final plan = createPlan();
        await repository.savePlan(plan);
        final stored = await repository.loadPlan('student-1');
        expect(stored!.generatedAt, plan.generatedAt);
        expect(stored.summary.totalQuestions, 10);
        expect(stored.recommendations.length, 1);
        expect(stored.dailyPlans.length, 1);
        expect(stored.dailyPlans[0].dayNumber, 1);
      });
    });

    group('loadPlan', () {
      test('returns null for non-existent student', () async {
        expect(await repository.loadPlan('nonexistent'), isNull);
      });

      test('returns stored plan', () async {
        final plan = createPlan();
        await repository.savePlan(plan);
        final stored = await repository.loadPlan('student-1');
        expect(stored, isNotNull);
        expect(stored!.studentId, 'student-1');
      });

      test('returns different plans for different students', () async {
        await repository.savePlan(createPlan(studentId: 's1', planDurationDays: 7));
        await repository.savePlan(createPlan(studentId: 's2', planDurationDays: 14));
        final s1 = await repository.loadPlan('s1');
        final s2 = await repository.loadPlan('s2');
        expect(s1!.planDurationDays, 7);
        expect(s2!.planDurationDays, 14);
      });
    });

    group('deletePlan', () {
      test('removes a plan', () async {
        await repository.savePlan(createPlan());
        await repository.deletePlan('student-1');
        expect(await repository.loadPlan('student-1'), isNull);
      });

      test('does not affect other students', () async {
        await repository.savePlan(createPlan(studentId: 's1'));
        await repository.savePlan(createPlan(studentId: 's2'));
        await repository.deletePlan('s1');
        expect(await repository.loadPlan('s1'), isNull);
        expect(await repository.loadPlan('s2'), isNotNull);
      });

      test('does nothing for non-existent plan', () async {
        await repository.deletePlan('nonexistent');
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

      test('returns false after plan is deleted', () async {
        await repository.savePlan(createPlan());
        await repository.deletePlan('student-1');
        expect(await repository.hasPlan('student-1'), isFalse);
      });
    });

    group('getAllPlans', () {
      test('returns all stored plans', () async {
        await repository.savePlan(createPlan(studentId: 's1'));
        await repository.savePlan(createPlan(studentId: 's2'));
        await repository.savePlan(createPlan(studentId: 's3'));
        final plans = await repository.getAllPlans();
        expect(plans.length, 3);
      });

      test('returns empty when no plans', () async {
        expect(await repository.getAllPlans(), isEmpty);
      });

      test('returns updated list after deletion', () async {
        await repository.savePlan(createPlan(studentId: 's1'));
        await repository.savePlan(createPlan(studentId: 's2'));
        await repository.deletePlan('s1');
        final plans = await repository.getAllPlans();
        expect(plans.length, 1);
        expect(plans.first.studentId, 's2');
      });
    });
  });
}
