import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

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

      test('copyWith returns identical copy with no args', () {
        final plan = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [dailyPlan],
          summary: summary,
          recommendations: [recommendation],
          planDurationDays: 14,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 30,
          metadata: {'version': '1.0'},
        );
        final copy = plan.copyWith();
        expect(copy.studentId, 's1');
        expect(copy.dailyPlans.length, 1);
        expect(copy.planDurationDays, 14);
        expect(copy.metadata?['version'], '1.0');
      });

      test('copyWith updates specific fields', () {
        final plan = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [dailyPlan],
          summary: summary,
          recommendations: [recommendation],
        );
        expect(plan.copyWith(studentId: 's2').studentId, 's2');
        expect(plan.copyWith(planDurationDays: 30).planDurationDays, 30);
        expect(plan.copyWith(targetMinutesPerDay: 90.0).targetMinutesPerDay, 90.0);
        expect(plan.copyWith(targetQuestionsPerDay: 50).targetQuestionsPerDay, 50);
      });

      test('copyWith null fields keep original values', () {
        final plan = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [dailyPlan],
          summary: summary,
          recommendations: [recommendation],
          planDurationDays: 14,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 30,
          metadata: {'k': 'v'},
        );
        final copy = plan.copyWith(
          studentId: null,
          generatedAt: null,
          dailyPlans: null,
          summary: null,
          recommendations: null,
          planDurationDays: null,
          targetMinutesPerDay: null,
          targetQuestionsPerDay: null,
          metadata: null,
        );
        expect(copy.studentId, 's1');
        expect(copy.planDurationDays, 14);
        expect(copy.targetMinutesPerDay, 60.0);
        expect(copy.metadata?['k'], 'v');
      });

      test('copyWith does not mutate original', () {
        final plan = PersonalLearningPlan(
          studentId: 's1',
          generatedAt: now,
          dailyPlans: [dailyPlan],
          summary: summary,
          recommendations: [recommendation],
        );
        plan.copyWith(studentId: 's2');
        expect(plan.studentId, 's1');
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

      test('copyWith returns identical copy with no args', () {
        final copy = dailyPlan.copyWith();
        expect(copy.date, dailyPlan.date);
        expect(copy.dayNumber, dailyPlan.dayNumber);
        expect(copy.targetQuestions, dailyPlan.targetQuestions);
        expect(copy.isRestDay, dailyPlan.isRestDay);
        expect(copy.focus, dailyPlan.focus);
      });

      test('copyWith updates specific fields', () {
        expect(dailyPlan.copyWith(dayNumber: 5).dayNumber, 5);
        expect(dailyPlan.copyWith(targetQuestions: 99).targetQuestions, 99);
        expect(dailyPlan.copyWith(isRestDay: true).isRestDay, isTrue);
        expect(dailyPlan.copyWith(focus: 'New focus').focus, 'New focus');
      });

      test('copyWith null fields keep original values', () {
        final copy = dailyPlan.copyWith(
          date: null,
          dayNumber: null,
          priorityTopics: null,
          reviewQuestionIds: null,
          stretchGoalQuestionIds: null,
          targetQuestions: null,
          targetMinutes: null,
          focus: null,
          isRestDay: null,
        );
        expect(copy.date, dailyPlan.date);
        expect(copy.dayNumber, dailyPlan.dayNumber);
        expect(copy.focus, dailyPlan.focus);
      });

      test('copyWith does not mutate original', () {
        dailyPlan.copyWith(dayNumber: 99);
        expect(dailyPlan.dayNumber, 1);
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

    group('fromJson edge cases', () {
      test('PersonalLearningPlan handles null planDurationDays', () {
        final json = {
          'studentId': 's1',
          'generatedAt': now.toIso8601String(),
          'dailyPlans': [dailyPlan.toJson()],
          'summary': summary.toJson(),
          'recommendations': [recommendation.toJson()],
          'planDurationDays': null,
        };
        final plan = PersonalLearningPlan.fromJson(json);
        expect(plan.planDurationDays, 7);
      });

      test('PersonalLearningPlan handles null metadata', () {
        final json = {
          'studentId': 's1',
          'generatedAt': now.toIso8601String(),
          'dailyPlans': [dailyPlan.toJson()],
          'summary': summary.toJson(),
          'recommendations': [recommendation.toJson()],
          'metadata': null,
        };
        final plan = PersonalLearningPlan.fromJson(json);
        expect(plan.metadata, isNull);
      });
    });

    group('equality', () {
      test('uses identity-based equality for PersonalLearningPlan', () {
        final plan = PersonalLearningPlan(
          studentId: 's1', generatedAt: now, dailyPlans: [], summary: summary,
          recommendations: [], planDurationDays: 7,
        );
        expect(plan == plan, isTrue);
      });

      test('hashCode is consistent for DailyPlan', () {
        final obj = dailyPlan;
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });

      test('uses identity-based equality for PlanSummary', () {
        final a = PlanSummary(totalQuestions: 10, totalMinutes: 60, newTopics: 1, reviewTopics: 2, estimatedCoverage: 0.5, focusAreas: ['math']);
        final b = PlanSummary(totalQuestions: 10, totalMinutes: 60, newTopics: 1, reviewTopics: 2, estimatedCoverage: 0.5, focusAreas: ['math']);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('uses identity-based equality for PlanRecommendation', () {
        final a = PlanRecommendation(topicId: 't1', reason: 'R', recommendationType: 'review', priority: 0.5, explanations: []);
        final b = PlanRecommendation(topicId: 't1', reason: 'R', recommendationType: 'review', priority: 0.5, explanations: []);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });
    });

    group('toString', () {
      test('PersonalLearningPlan includes class name', () {
        final plan = PersonalLearningPlan(
          studentId: 's1', generatedAt: now, dailyPlans: [], summary: summary,
          recommendations: [], planDurationDays: 7,
        );
        expect(plan.toString(), contains('PersonalLearningPlan'));
      });

      test('PlannedTopic includes class name', () {
        expect(dailyPlan.priorityTopics.first.toString(), contains('PlannedTopic'));
      });

      test('DailyPlan includes class name', () {
        expect(dailyPlan.toString(), contains('DailyPlan'));
      });

      test('PlanSummary includes class name', () {
        expect(summary.toString(), contains('PlanSummary'));
      });

      test('PlanRecommendation includes class name', () {
        expect(recommendation.toString(), contains('PlanRecommendation'));
      });
    });
  });
}
