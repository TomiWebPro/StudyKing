import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/adapters.dart';
import 'package:studyking/features/planner/data/adapters/engagement_nudge_adapter.dart';
import 'package:studyking/features/planner/data/adapters/personal_learning_plan_adapter.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_adapter.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_model_adapter.dart';
import 'package:studyking/features/planner/data/adapters/plan_advisor_suggestion_adapter.dart';
import 'package:studyking/features/planner/data/adapters/student_availability_adapter.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_metric_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/plan_advisor_suggestion_model.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';

void main() {
  group('registerPlannerAdapters', () {
    test('registers all adapters when not already registered', () {
      registerPlannerAdapters();
      expect(Hive.isAdapterRegistered(19), isTrue);
      expect(Hive.isAdapterRegistered(20), isTrue);
      expect(Hive.isAdapterRegistered(21), isTrue);
      expect(Hive.isAdapterRegistered(22), isTrue);
      expect(Hive.isAdapterRegistered(23), isTrue);
      expect(Hive.isAdapterRegistered(30), isTrue);
      expect(Hive.isAdapterRegistered(32), isTrue);
      expect(Hive.isAdapterRegistered(33), isTrue);
      expect(Hive.isAdapterRegistered(35), isTrue);
      expect(Hive.isAdapterRegistered(37), isTrue);
    });

    test('is idempotent when called multiple times', () {
      expect(() => registerPlannerAdapters(), returnsNormally);
      expect(() => registerPlannerAdapters(), returnsNormally);
      expect(Hive.isAdapterRegistered(19), isTrue);
      expect(Hive.isAdapterRegistered(20), isTrue);
      expect(Hive.isAdapterRegistered(21), isTrue);
      expect(Hive.isAdapterRegistered(22), isTrue);
      expect(Hive.isAdapterRegistered(23), isTrue);
      expect(Hive.isAdapterRegistered(30), isTrue);
      expect(Hive.isAdapterRegistered(32), isTrue);
      expect(Hive.isAdapterRegistered(33), isTrue);
      expect(Hive.isAdapterRegistered(35), isTrue);
      expect(Hive.isAdapterRegistered(37), isTrue);
    });
  });

  group('round-trip adapter tests', () {
    TypeRegistryImpl fullRegistry() {
      return TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PersonalLearningPlanAdapter())
        ..registerAdapter(DailyPlanAdapter())
        ..registerAdapter(PlannedTopicAdapter())
        ..registerAdapter(PlanSummaryAdapter())
        ..registerAdapter(PlanRecommendationAdapter())
        ..registerAdapter(PlanAdherenceMetricAdapter())
        ..registerAdapter(PlanAdherenceModelAdapter())
        ..registerAdapter(EngagementNudgeModelAdapter())
        ..registerAdapter(StudentAvailabilityModelAdapter())
        ..registerAdapter(PlanAdvisorSuggestionAdapter());
    }

    test('PersonalLearningPlanAdapter round-trip', () {
      final registry = fullRegistry();
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

    test('DailyPlanAdapter round-trip', () {
      final registry = fullRegistry();
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

    test('PlannedTopicAdapter round-trip', () {
      final registry = fullRegistry();
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

    test('PlanSummaryAdapter round-trip', () {
      final registry = fullRegistry();
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

    test('PlanRecommendationAdapter round-trip', () {
      final registry = fullRegistry();
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

    test('PlanAdherenceMetricAdapter round-trip', () {
      final registry = fullRegistry();
      final adapter = PlanAdherenceMetricAdapter();
      final now = DateTime.now();
      final source = PlanAdherenceMetric(
        date: now,
        studentId: 'student1',
        plannedQuestions: 10,
        actualQuestions: 8,
        plannedMinutes: 60,
        actualMinutes: 45,
        adherenceScore: 0.75,
        metadata: {'source': 'daily_tracker', 'version': 2},
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.studentId, 'student1');
      expect(restored.plannedQuestions, 10);
      expect(restored.actualQuestions, 8);
      expect(restored.plannedMinutes, 60);
      expect(restored.actualMinutes, 45);
      expect(restored.adherenceScore, 0.75);
      expect(restored.metadata!['source'], 'daily_tracker');
      expect(restored.metadata!['version'], 2);
    });

    test('PlanAdherenceModelAdapter round-trip', () {
      final registry = fullRegistry();
      final adapter = PlanAdherenceModelAdapter();
      final now = DateTime.now();
      final source = PlanAdherenceModel(
        id: 'adh-001',
        studentId: 'student-1',
        date: now,
        plannedQuestions: 20,
        actualQuestions: 18,
        plannedMinutes: 120,
        actualMinutes: 110,
        adherenceScore: 0.9,
        planId: 'plan-abc',
        metadata: {'source': 'manual'},
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'adh-001');
      expect(restored.studentId, 'student-1');
      expect(restored.plannedQuestions, 20);
      expect(restored.actualQuestions, 18);
      expect(restored.plannedMinutes, 120);
      expect(restored.actualMinutes, 110);
      expect(restored.adherenceScore, 0.9);
      expect(restored.planId, 'plan-abc');
      expect(restored.metadata!['source'], 'manual');
    });

    test('EngagementNudgeModelAdapter round-trip', () {
      final registry = fullRegistry();
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime.now();
      final source = EngagementNudgeModel(
        id: 'nudge-rt',
        studentId: 'student-1',
        nudgeType: 'overwork',
        message: 'Take a break!',
        severity: 'high',
        topicId: 'topic-1',
        sentAt: now,
        wasActedUpon: true,
        actedUponAt: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'nudge-rt');
      expect(restored.studentId, 'student-1');
      expect(restored.nudgeType, 'overwork');
      expect(restored.message, 'Take a break!');
      expect(restored.severity, 'high');
      expect(restored.topicId, 'topic-1');
      expect(restored.wasActedUpon, isTrue);
    });

    test('EngagementNudgeModelAdapter round-trip with defaults', () {
      final registry = fullRegistry();
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime.now();
      final source = EngagementNudgeModel(
        id: 'nudge-rt2',
        studentId: 'student-2',
        nudgeType: 'revision',
        message: 'Review time',
        sentAt: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.severity, 'medium');
      expect(restored.topicId, isNull);
      expect(restored.wasActedUpon, isFalse);
      expect(restored.actedUponAt, isNull);
    });

    test('StudentAvailabilityModelAdapter round-trip', () {
      final registry = fullRegistry();
      final adapter = StudentAvailabilityModelAdapter();
      final blackout1 = DateTime(2025, 12, 25);
      final blackout2 = DateTime(2026, 1, 1);
      final source = StudentAvailabilityModel(
        studentId: 's-rt',
        preferredStudyDays: [1, 3, 5],
        preferredStartHour: 8,
        preferredEndHour: 22,
        maxSessionsPerDay: 4,
        defaultSessionDurationMinutes: 45,
        blackoutDates: [blackout1, blackout2],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 's-rt');
      expect(restored.preferredStudyDays, [1, 3, 5]);
      expect(restored.preferredStartHour, 8);
      expect(restored.preferredEndHour, 22);
      expect(restored.maxSessionsPerDay, 4);
      expect(restored.defaultSessionDurationMinutes, 45);
      expect(restored.blackoutDates.length, 2);
    });

    test('StudentAvailabilityModelAdapter round-trip with defaults', () {
      final registry = fullRegistry();
      final adapter = StudentAvailabilityModelAdapter();
      final source = StudentAvailabilityModel(studentId: 's-rt2');

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.preferredStudyDays, [1, 2, 3, 4, 5, 6, 7]);
      expect(restored.preferredStartHour, 9);
      expect(restored.preferredEndHour, 21);
      expect(restored.maxSessionsPerDay, 3);
      expect(restored.defaultSessionDurationMinutes, 30);
      expect(restored.blackoutDates, isEmpty);
    });

    test('PlanAdvisorSuggestionAdapter round-trip with all fields', () {
      final registry = fullRegistry();
      final adapter = PlanAdvisorSuggestionAdapter();
      final now = DateTime(2025, 6, 15);
      final source = PlanAdvisorSuggestionModel(
        id: 'suggestion-rt',
        studentId: 'student-1',
        generatedAt: now,
        suggestionType: 'plan_adjustment',
        workloadEstimate: '~1.5h/day',
        pathwaySuggestion: 'Review chapter 3 first',
        motivationalReasoning: 'You are 80% through the syllabus',
        metadata: {'confidence': 0.9},
        applied: false,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'suggestion-rt');
      expect(restored.studentId, 'student-1');
      expect(restored.generatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.suggestionType, 'plan_adjustment');
      expect(restored.workloadEstimate, '~1.5h/day');
      expect(restored.pathwaySuggestion, 'Review chapter 3 first');
      expect(restored.motivationalReasoning, 'You are 80% through the syllabus');
      expect(restored.metadata['confidence'], 0.9);
      expect(restored.applied, isFalse);
    });

    test('PlanAdvisorSuggestionAdapter round-trip with defaults', () {
      final registry = fullRegistry();
      final adapter = PlanAdvisorSuggestionAdapter();
      final now = DateTime(2025, 6, 15);
      final source = PlanAdvisorSuggestionModel(
        id: 'suggestion-rt2',
        studentId: 'student-2',
        generatedAt: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.suggestionType, 'plan_generation');
      expect(restored.workloadEstimate, isNull);
      expect(restored.pathwaySuggestion, isNull);
      expect(restored.motivationalReasoning, isNull);
      expect(restored.metadata, {});
      expect(restored.applied, isFalse);
    });

    test('reading from empty binary throws', () {
      final registry = fullRegistry();
      final adapter = PersonalLearningPlanAdapter();
      final reader = BinaryReaderImpl(Uint8List(0), registry);
      expect(() => adapter.read(reader), throwsA(isA<RangeError>()));
    });
  });
}
