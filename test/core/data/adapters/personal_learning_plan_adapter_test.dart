import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/core/data/adapters/personal_learning_plan_adapter.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';

TypeRegistryImpl _registry() {
  return TypeRegistryImpl()
    ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
    ..registerAdapter(PersonalLearningPlanAdapter())
    ..registerAdapter(DailyPlanAdapter())
    ..registerAdapter(PlannedTopicAdapter())
    ..registerAdapter(PlanSummaryAdapter())
    ..registerAdapter(PlanRecommendationAdapter());
}

void main() {
  group('PersonalLearningPlanAdapter', () {
    test('typeId is 19', () {
      expect(PersonalLearningPlanAdapter().typeId, 19);
    });

    test('hashCode and equality', () {
      expect(PersonalLearningPlanAdapter().hashCode, PersonalLearningPlanAdapter().hashCode);
      expect(PersonalLearningPlanAdapter() == PersonalLearningPlanAdapter(), isTrue);
    });

    test('write/read round-trip', () {
      final registry = _registry();
      final adapter = PersonalLearningPlanAdapter();
      final now = DateTime.now();
      final source = PersonalLearningPlan(
        studentId: 's1',
        generatedAt: now,
        dailyPlans: [
          DailyPlan(
            date: now, dayNumber: 1,
            priorityTopics: [
              PlannedTopic(
                topicId: 't1', topicTitle: 'Algebra', priority: 1.0,
                reason: 'Weak', readinessScore: 0.5, reviewUrgency: 0.8,
                estimatedQuestions: 10, estimatedMinutes: 30, reasons: ['weak'],
              ),
            ],
            reviewQuestionIds: ['q1'], stretchGoalQuestionIds: [],
            targetQuestions: 10, targetMinutes: 30, focus: 'Algebra',
            isRestDay: false,
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 10, totalMinutes: 30, newTopics: 1, reviewTopics: 2,
          estimatedCoverage: 0.5, focusAreas: ['Algebra'],
        ),
        recommendations: [
          PlanRecommendation(
            topicId: 't2', reason: 'Prerequisite', recommendationType: 'study',
            priority: 0.9, explanations: ['Needs improvement'],
          ),
        ],
        planDurationDays: 30,
        targetMinutesPerDay: 45.0,
        targetQuestionsPerDay: 20,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 's1');
      expect(restored.dailyPlans.length, 1);
      expect(restored.dailyPlans[0].dayNumber, 1);
      expect(restored.dailyPlans[0].priorityTopics.length, 1);
      expect(restored.summary.totalQuestions, 10);
      expect(restored.recommendations.length, 1);
      expect(restored.planDurationDays, 30);
      expect(restored.targetMinutesPerDay, 45.0);
    });

    test('write/read with minimal fields', () {
      final registry = _registry();
      final adapter = PersonalLearningPlanAdapter();
      final now = DateTime.now();
      final source = PersonalLearningPlan(
        studentId: 's1', generatedAt: now,
        dailyPlans: [],
        summary: PlanSummary(totalQuestions: 0, totalMinutes: 0, newTopics: 0, reviewTopics: 0, estimatedCoverage: 0.0, focusAreas: []),
        recommendations: [],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.planDurationDays, 7);
      expect(restored.targetMinutesPerDay, 30.0);
      expect(restored.targetQuestionsPerDay, 15);
    });
  });

  group('DailyPlanAdapter', () {
    test('typeId is 20', () {
      expect(DailyPlanAdapter().typeId, 20);
    });

    test('write/read round-trip', () {
      final registry = _registry();
      final adapter = DailyPlanAdapter();
      final now = DateTime.now();
      final source = DailyPlan(
        date: now, dayNumber: 2, priorityTopics: [],
        reviewQuestionIds: ['q1'], stretchGoalQuestionIds: [],
        targetQuestions: 15, targetMinutes: 45, focus: 'Review',
        isRestDay: false,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.dayNumber, 2);
      expect(restored.targetQuestions, 15);
      expect(restored.isRestDay, isFalse);
    });
  });

  group('PlannedTopicAdapter', () {
    test('typeId is 21', () {
      expect(PlannedTopicAdapter().typeId, 21);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(PlannedTopicAdapter());
      final adapter = PlannedTopicAdapter();
      final source = PlannedTopic(
        topicId: 't1', topicTitle: 'Algebra', priority: 0.8,
        reason: 'Weak', readinessScore: 0.4, reviewUrgency: 0.9,
        estimatedQuestions: 5, estimatedMinutes: 15, reasons: ['low score'],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.topicId, 't1');
      expect(restored.priority, 0.8);
      expect(restored.estimatedQuestions, 5);
      expect(restored.reasons, ['low score']);
    });
  });

  group('PlanSummaryAdapter', () {
    test('typeId is 22', () {
      expect(PlanSummaryAdapter().typeId, 22);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(PlanSummaryAdapter());
      final adapter = PlanSummaryAdapter();
      final source = PlanSummary(
        totalQuestions: 50, totalMinutes: 120, newTopics: 3, reviewTopics: 0,
        estimatedCoverage: 0.6, focusAreas: ['Math'],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.totalQuestions, 50);
      expect(restored.totalMinutes, 120);
      expect(restored.estimatedCoverage, 0.6);
      expect(restored.focusAreas, ['Math']);
    });
  });

  group('PlanRecommendationAdapter', () {
    test('typeId is 23', () {
      expect(PlanRecommendationAdapter().typeId, 23);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(PlanRecommendationAdapter());
      final adapter = PlanRecommendationAdapter();
      final source = PlanRecommendation(
        topicId: 't1', reason: 'Prerequisite', recommendationType: 'study',
        priority: 0.95, explanations: ['Must learn first'],
        prerequisiteReason: 'Required for calculus',
        weaknessReason: 'Score low',
        reviewReason: 'Overdue',
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.topicId, 't1');
      expect(restored.recommendationType, 'study');
      expect(restored.priority, 0.95);
      expect(restored.explanations, ['Must learn first']);
      expect(restored.prerequisiteReason, 'Required for calculus');
    });
  });
}
