import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';

void main() {
  group('PersonalLearningPlan', () {
    late DateTime now;
    late DailyPlan dailyPlan;
    late PlanSummary summary;
    late PlanRecommendation recommendation;

    setUp(() {
      now = DateTime(2026, 5, 12);
      dailyPlan = DailyPlan(
        date: now,
        dayNumber: 1,
        priorityTopics: [
          PlannedTopic(
            topicId: 'topic-1',
            topicTitle: 'Algebra',
            priority: 0.8,
            reason: 'Weak area',
            readinessScore: 0.4,
            reviewUrgency: 0.7,
            estimatedQuestions: 10,
            estimatedMinutes: 30,
            reasons: ['Low score'],
          ),
        ],
        reviewQuestionIds: ['q1', 'q2'],
        stretchGoalQuestionIds: ['q3'],
        targetQuestions: 15,
        targetMinutes: 45,
        focus: 'Algebra basics',
        isRestDay: false,
      );
      summary = PlanSummary(
        totalQuestions: 50,
        totalMinutes: 300,
        newTopics: 2,
        reviewTopics: 3,
        estimatedCoverage: 0.75,
        focusAreas: ['Algebra', 'Geometry'],
        workloadDistribution: {'mon': 30, 'tue': 45},
      );
      recommendation = PlanRecommendation(
        topicId: 'topic-1',
        reason: 'Weak area',
        recommendationType: 'review',
        priority: 0.9,
        explanations: ['Score too low'],
        prerequisiteReason: null,
        weaknessReason: 'Below threshold',
        reviewReason: null,
      );
    });

    group('PersonalLearningPlan', () {
      test('creates with all fields', () {
        final plan = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [dailyPlan],
          summary: summary,
          recommendations: [recommendation],
        );
        expect(plan.studentId, 's1');
        expect(plan.dailyPlans.length, 1);
        expect(plan.recommendations.length, 1);
        expect(plan.planDurationDays, 7);
        expect(plan.targetMinutesPerDay, 30.0);
        expect(plan.targetQuestionsPerDay, 15);
      });

      test('creates with custom settings', () {
        final plan = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [],
          summary: summary,
          recommendations: [],
          planDurationDays: 14,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 30,
          metadata: {'version': '1.0'},
        );
        expect(plan.planDurationDays, 14);
        expect(plan.targetMinutesPerDay, 60.0);
        expect(plan.targetQuestionsPerDay, 30);
        expect(plan.metadata?['version'], '1.0');
      });

      test('toJson / fromJson roundtrip', () {
        final original = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [dailyPlan],
          summary: summary,
          recommendations: [recommendation],
        );
        final json = original.toJson();
        final restored = PersonalLearningPlan.fromJson(json);
        expect(restored.studentId, original.studentId);
        expect(restored.dailyPlans.length, original.dailyPlans.length);
        expect(restored.summary.totalQuestions, original.summary.totalQuestions);
        expect(restored.recommendations.length, original.recommendations.length);
      });
    });

    group('DailyPlan', () {
      test('creates with all fields', () {
        expect(dailyPlan.date, now);
        expect(dailyPlan.dayNumber, 1);
        expect(dailyPlan.priorityTopics.length, 1);
        expect(dailyPlan.reviewQuestionIds, ['q1', 'q2']);
        expect(dailyPlan.targetQuestions, 15);
        expect(dailyPlan.isRestDay, isFalse);
      });

      test('creates as rest day', () {
        final rest = DailyPlan(
          date: now,
          dayNumber: 7,
          priorityTopics: [],
          reviewQuestionIds: [],
          stretchGoalQuestionIds: [],
          targetQuestions: 0,
          targetMinutes: 0,
          isRestDay: true,
        );
        expect(rest.isRestDay, isTrue);
      });

      test('toJson / fromJson roundtrip', () {
        final json = dailyPlan.toJson();
        final restored = DailyPlan.fromJson(json);
        expect(restored.date, dailyPlan.date);
        expect(restored.dayNumber, dailyPlan.dayNumber);
        expect(restored.targetQuestions, dailyPlan.targetQuestions);
        expect(restored.isRestDay, dailyPlan.isRestDay);
      });
    });

    group('PlannedTopic', () {
      test('creates with all fields', () {
        final topic = dailyPlan.priorityTopics.first;
        expect(topic.topicId, 'topic-1');
        expect(topic.topicTitle, 'Algebra');
        expect(topic.priority, 0.8);
        expect(topic.readinessScore, 0.4);
        expect(topic.estimatedQuestions, 10);
        expect(topic.reasons, ['Low score']);
      });

      test('toJson / fromJson roundtrip', () {
        final topic = dailyPlan.priorityTopics.first;
        final json = topic.toJson();
        final restored = PlannedTopic.fromJson(json);
        expect(restored.topicId, topic.topicId);
        expect(restored.topicTitle, topic.topicTitle);
        expect(restored.priority, topic.priority);
      });
    });

    group('PlanSummary', () {
      test('creates with all fields', () {
        expect(summary.totalQuestions, 50);
        expect(summary.totalMinutes, 300);
        expect(summary.newTopics, 2);
        expect(summary.reviewTopics, 3);
        expect(summary.estimatedCoverage, 0.75);
        expect(summary.focusAreas, ['Algebra', 'Geometry']);
      });

      test('toJson / fromJson roundtrip', () {
        final json = summary.toJson();
        final restored = PlanSummary.fromJson(json);
        expect(restored.totalQuestions, summary.totalQuestions);
        expect(restored.totalMinutes, summary.totalMinutes);
        expect(restored.estimatedCoverage, summary.estimatedCoverage);
      });
    });

    group('PlanRecommendation', () {
      test('creates with all fields', () {
        expect(recommendation.topicId, 'topic-1');
        expect(recommendation.reason, 'Weak area');
        expect(recommendation.recommendationType, 'review');
        expect(recommendation.priority, 0.9);
      });

      test('toJson / fromJson roundtrip', () {
        final json = recommendation.toJson();
        final restored = PlanRecommendation.fromJson(json);
        expect(restored.topicId, recommendation.topicId);
        expect(restored.reason, recommendation.reason);
        expect(restored.priority, recommendation.priority);
      });
    });
  });
}
