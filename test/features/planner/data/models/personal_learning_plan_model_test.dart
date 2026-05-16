import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

void main() {
  group('PersonalLearningPlan', () {
    final now = DateTime(2026, 5, 16);
    const studentId = 'student-1';

    final defaultSummary = PlanSummary(
      totalQuestions: 100, totalMinutes: 300,
      newTopics: 5, reviewTopics: 3,
      estimatedCoverage: 0.8, focusAreas: ['Kinematics'],
    );

    final defaultDailyPlan = DailyPlan(
      date: now, dayNumber: 1,
      priorityTopics: [], reviewQuestionIds: [],
      stretchGoalQuestionIds: [], targetQuestions: 15, targetMinutes: 30,
    );

    group('constructor', () {
      test('creates instance with required fields', () {
        final plan = PersonalLearningPlan(
          studentId: studentId, generatedAt: now,
          dailyPlans: [defaultDailyPlan], summary: defaultSummary,
          recommendations: [],
        );
        expect(plan.studentId, studentId);
        expect(plan.generatedAt, now);
        expect(plan.dailyPlans.length, 1);
        expect(plan.planDurationDays, 7);
        expect(plan.targetMinutesPerDay, 30.0);
        expect(plan.targetQuestionsPerDay, 15);
        expect(plan.metadata, isNull);
      });

      test('accepts all optional fields', () {
        final plan = PersonalLearningPlan(
          studentId: studentId, generatedAt: now,
          dailyPlans: [defaultDailyPlan], summary: defaultSummary,
          recommendations: [],
          planDurationDays: 30, targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 20,
          metadata: {'key': 'value'},
        );
        expect(plan.planDurationDays, 30);
        expect(plan.targetMinutesPerDay, 60.0);
        expect(plan.targetQuestionsPerDay, 20);
        expect(plan.metadata, {'key': 'value'});
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final plan = PersonalLearningPlan(
          studentId: studentId, generatedAt: now,
          dailyPlans: [defaultDailyPlan], summary: defaultSummary,
          recommendations: [],
        );
        final json = plan.toJson();
        expect(json['studentId'], studentId);
        expect(json['generatedAt'], now.toIso8601String());
        expect(json['dailyPlans'], isA<List>());
        expect(json['summary'], isA<Map>());
        expect(json['recommendations'], []);
        expect(json['planDurationDays'], 7);
        expect(json['targetMinutesPerDay'], 30.0);
        expect(json['targetQuestionsPerDay'], 15);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'studentId': studentId,
          'generatedAt': now.toIso8601String(),
          'dailyPlans': [
            {
              'date': now.toIso8601String(),
              'dayNumber': 1,
              'priorityTopics': [],
              'reviewQuestionIds': [],
              'stretchGoalQuestionIds': [],
              'targetQuestions': 15,
              'targetMinutes': 30,
              'focus': null,
              'isRestDay': false,
            }
          ],
          'summary': {
            'totalQuestions': 100, 'totalMinutes': 300,
            'newTopics': 5, 'reviewTopics': 3,
            'estimatedCoverage': 0.8, 'focusAreas': ['Kinematics'],
          },
          'recommendations': [],
          'planDurationDays': 14,
          'targetMinutesPerDay': 45.0,
          'targetQuestionsPerDay': 20,
        };
        final plan = PersonalLearningPlan.fromJson(json);
        expect(plan.studentId, studentId);
        expect(plan.dailyPlans.length, 1);
        expect(plan.planDurationDays, 14);
        expect(plan.targetMinutesPerDay, 45.0);
        expect(plan.targetQuestionsPerDay, 20);
      });

      test('handles missing optional fields', () {
        final json = {
          'studentId': studentId,
          'generatedAt': now.toIso8601String(),
          'dailyPlans': [
            {
              'date': now.toIso8601String(),
              'dayNumber': 1,
              'priorityTopics': [],
              'reviewQuestionIds': [],
              'stretchGoalQuestionIds': [],
              'targetQuestions': 10,
              'targetMinutes': 30,
            }
          ],
          'summary': {
            'totalQuestions': 50, 'totalMinutes': 150,
            'newTopics': 2, 'reviewTopics': 1,
            'estimatedCoverage': 0.5, 'focusAreas': [],
          },
          'recommendations': [],
        };
        final plan = PersonalLearningPlan.fromJson(json);
        expect(plan.planDurationDays, 7);
        expect(plan.targetMinutesPerDay, 30.0);
        expect(plan.targetQuestionsPerDay, 15);
        expect(plan.metadata, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = PersonalLearningPlan(
          studentId: studentId, generatedAt: now,
          dailyPlans: [defaultDailyPlan], summary: defaultSummary,
          recommendations: [],
          planDurationDays: 30,
        );
        final restored = PersonalLearningPlan.fromJson(original.toJson());
        expect(restored.studentId, original.studentId);
        expect(restored.planDurationDays, original.planDurationDays);
        expect(restored.dailyPlans.length, original.dailyPlans.length);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final plan = PersonalLearningPlan(
          studentId: studentId, generatedAt: now,
          dailyPlans: [defaultDailyPlan], summary: defaultSummary,
          recommendations: [],
        );
        final copy = plan.copyWith();
        expect(copy.studentId, plan.studentId);
        expect(copy.planDurationDays, plan.planDurationDays);
      });

      test('updates specified fields', () {
        final plan = PersonalLearningPlan(
          studentId: studentId, generatedAt: now,
          dailyPlans: [defaultDailyPlan], summary: defaultSummary,
          recommendations: [],
        );
        final copy = plan.copyWith(planDurationDays: 60, targetMinutesPerDay: 90.0);
        expect(copy.planDurationDays, 60);
        expect(copy.targetMinutesPerDay, 90.0);
        expect(copy.studentId, studentId);
      });
    });
  });

  group('DailyPlan', () {
    final now = DateTime(2026, 5, 16);

    group('constructor', () {
      test('creates with required fields', () {
        final plan = DailyPlan(
          date: now, dayNumber: 1,
          priorityTopics: [], reviewQuestionIds: [],
          stretchGoalQuestionIds: [], targetQuestions: 10, targetMinutes: 30,
        );
        expect(plan.date, now);
        expect(plan.dayNumber, 1);
        expect(plan.targetQuestions, 10);
        expect(plan.targetMinutes, 30);
        expect(plan.focus, isNull);
        expect(plan.isRestDay, isFalse);
      });

      test('accepts all fields', () {
        final plan = DailyPlan(
          date: now, dayNumber: 2,
          priorityTopics: [], reviewQuestionIds: ['q1'],
          stretchGoalQuestionIds: ['q2'], targetQuestions: 20,
          targetMinutes: 60, focus: 'Algebra', isRestDay: true,
        );
        expect(plan.reviewQuestionIds, ['q1']);
        expect(plan.stretchGoalQuestionIds, ['q2']);
        expect(plan.focus, 'Algebra');
        expect(plan.isRestDay, isTrue);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final plan = DailyPlan(
          date: now, dayNumber: 1, priorityTopics: [],
          reviewQuestionIds: ['r1'], stretchGoalQuestionIds: ['s1'],
          targetQuestions: 15, targetMinutes: 45, focus: 'Review',
        );
        final json = plan.toJson();
        expect(json['date'], now.toIso8601String());
        expect(json['dayNumber'], 1);
        expect(json['targetQuestions'], 15);
        expect(json['targetMinutes'], 45);
        expect(json['focus'], 'Review');
        expect(json['isRestDay'], isFalse);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'date': now.toIso8601String(),
          'dayNumber': 1,
          'priorityTopics': [],
          'reviewQuestionIds': ['r1'],
          'stretchGoalQuestionIds': ['s1'],
          'targetQuestions': 15,
          'targetMinutes': 30,
          'focus': 'Algebra',
          'isRestDay': true,
        };
        final plan = DailyPlan.fromJson(json);
        expect(plan.date, now);
        expect(plan.dayNumber, 1);
        expect(plan.reviewQuestionIds, ['r1']);
        expect(plan.focus, 'Algebra');
        expect(plan.isRestDay, isTrue);
      });

      test('handles missing optional fields', () {
        final json = {
          'date': now.toIso8601String(),
          'dayNumber': 1,
          'priorityTopics': [],
          'reviewQuestionIds': null,
          'stretchGoalQuestionIds': null,
          'targetQuestions': 10,
          'targetMinutes': 30,
        };
        final plan = DailyPlan.fromJson(json);
        expect(plan.reviewQuestionIds, []);
        expect(plan.stretchGoalQuestionIds, []);
        expect(plan.focus, isNull);
        expect(plan.isRestDay, isFalse);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = DailyPlan(
          date: now, dayNumber: 1, priorityTopics: [],
          reviewQuestionIds: ['r1'], stretchGoalQuestionIds: ['s1'],
          targetQuestions: 20, targetMinutes: 60, focus: 'Kinematics',
        );
        final restored = DailyPlan.fromJson(original.toJson());
        expect(restored.date, original.date);
        expect(restored.targetQuestions, original.targetQuestions);
        expect(restored.focus, original.focus);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final plan = DailyPlan(
          date: now, dayNumber: 1, priorityTopics: [],
          reviewQuestionIds: [], stretchGoalQuestionIds: [],
          targetQuestions: 10, targetMinutes: 30,
        );
        final copy = plan.copyWith(targetQuestions: 25, isRestDay: true);
        expect(copy.targetQuestions, 25);
        expect(copy.isRestDay, isTrue);
        expect(copy.date, now);
      });
    });
  });

  group('PlannedTopic', () {
    group('constructor', () {
      test('creates with required fields', () {
        final topic = PlannedTopic(
          topicId: 't1', topicTitle: 'Kinematics',
          priority: 0.9, reason: 'Weak area',
          readinessScore: 0.4, reviewUrgency: 0.8,
          estimatedQuestions: 10, estimatedMinutes: 30,
          reasons: ['needs review'],
        );
        expect(topic.topicId, 't1');
        expect(topic.topicTitle, 'Kinematics');
        expect(topic.priority, 0.9);
        expect(topic.subjectId, '');
      });

      test('accepts subjectId', () {
        final topic = PlannedTopic(
          topicId: 't1', topicTitle: 'Kinematics',
          priority: 1.0, reason: 'New topic',
          readinessScore: 0.0, reviewUrgency: 0.0,
          estimatedQuestions: 5, estimatedMinutes: 15,
          reasons: [], subjectId: 'sub-1',
        );
        expect(topic.subjectId, 'sub-1');
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final topic = PlannedTopic(
          topicId: 't1', topicTitle: 'Kinematics',
          priority: 0.8, reason: 'Review',
          readinessScore: 0.6, reviewUrgency: 0.3,
          estimatedQuestions: 10, estimatedMinutes: 30,
          reasons: ['weak'], subjectId: 'sub-1',
        );
        final json = topic.toJson();
        expect(json['topicId'], 't1');
        expect(json['topicTitle'], 'Kinematics');
        expect(json['priority'], 0.8);
        expect(json['subjectId'], 'sub-1');
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'topicId': 't1', 'topicTitle': 'Kinematics',
          'priority': 0.9, 'reason': 'Weak',
          'readinessScore': 0.4, 'reviewUrgency': 0.8,
          'estimatedQuestions': 10, 'estimatedMinutes': 30,
          'reasons': ['needs practice'],
        };
        final topic = PlannedTopic.fromJson(json);
        expect(topic.topicId, 't1');
        expect(topic.priority, 0.9);
        expect(topic.reasons, ['needs practice']);
        expect(topic.subjectId, '');
      });

      test('handles missing optional fields', () {
        final json = {
          'topicId': 't1', 'topicTitle': 'Kinematics',
          'priority': null, 'reason': 'Weak area',
          'readinessScore': null, 'reviewUrgency': null,
          'estimatedQuestions': null, 'estimatedMinutes': null,
          'reasons': null,
        };
        final topic = PlannedTopic.fromJson(json);
        expect(topic.priority, 0.0);
        expect(topic.readinessScore, 0.0);
        expect(topic.reviewUrgency, 0.0);
        expect(topic.estimatedQuestions, 0);
        expect(topic.estimatedMinutes, 0);
        expect(topic.reasons, []);
        expect(topic.subjectId, '');
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = PlannedTopic(
          topicId: 't1', topicTitle: 'Kinematics',
          priority: 0.9, reason: 'Review',
          readinessScore: 0.5, reviewUrgency: 0.7,
          estimatedQuestions: 15, estimatedMinutes: 45,
          reasons: ['weak', 'due'], subjectId: 'sub-1',
        );
        final restored = PlannedTopic.fromJson(original.toJson());
        expect(restored.topicId, original.topicId);
        expect(restored.priority, original.priority);
        expect(restored.subjectId, original.subjectId);
      });
    });
  });

  group('PlanSummary', () {
    group('constructor', () {
      test('creates with required fields', () {
        final summary = PlanSummary(
          totalQuestions: 100, totalMinutes: 300,
          newTopics: 5, reviewTopics: 3,
          estimatedCoverage: 0.8, focusAreas: ['Kinematics', 'Dynamics'],
        );
        expect(summary.totalQuestions, 100);
        expect(summary.totalMinutes, 300);
        expect(summary.newTopics, 5);
        expect(summary.reviewTopics, 3);
        expect(summary.estimatedCoverage, 0.8);
        expect(summary.focusAreas, ['Kinematics', 'Dynamics']);
        expect(summary.workloadDistribution, isNull);
      });

      test('accepts workloadDistribution', () {
        final summary = PlanSummary(
          totalQuestions: 50, totalMinutes: 150,
          newTopics: 2, reviewTopics: 1,
          estimatedCoverage: 0.6, focusAreas: [],
          workloadDistribution: {'monday': 30},
        );
        expect(summary.workloadDistribution, {'monday': 30});
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip preserves data', () {
        final original = PlanSummary(
          totalQuestions: 100, totalMinutes: 300,
          newTopics: 5, reviewTopics: 3,
          estimatedCoverage: 0.8, focusAreas: ['Kinematics'],
          workloadDistribution: {'week1': 60.0},
        );
        final json = original.toJson();
        final restored = PlanSummary.fromJson(json);
        expect(restored.totalQuestions, original.totalQuestions);
        expect(restored.focusAreas, original.focusAreas);
        expect(restored.workloadDistribution, original.workloadDistribution);
      });

      test('handles missing optional fields', () {
        final json = {
          'totalQuestions': 50, 'totalMinutes': 150,
          'newTopics': null, 'reviewTopics': null,
          'estimatedCoverage': null, 'focusAreas': null,
        };
        final summary = PlanSummary.fromJson(json);
        expect(summary.newTopics, 0);
        expect(summary.reviewTopics, 0);
        expect(summary.estimatedCoverage, 0.0);
        expect(summary.focusAreas, []);
        expect(summary.workloadDistribution, isNull);
      });
    });
  });

  group('PlanRecommendation', () {
    group('constructor', () {
      test('creates with required fields', () {
        final rec = PlanRecommendation(
          topicId: 't1', reason: 'Weak area',
          recommendationType: 'review', priority: 0.8,
          explanations: ['Needs more practice'],
        );
        expect(rec.topicId, 't1');
        expect(rec.reason, 'Weak area');
        expect(rec.recommendationType, 'review');
        expect(rec.priority, 0.8);
        expect(rec.explanations, ['Needs more practice']);
        expect(rec.prerequisiteReason, isNull);
        expect(rec.weaknessReason, isNull);
        expect(rec.reviewReason, isNull);
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip preserves data', () {
        final original = PlanRecommendation(
          topicId: 't1', reason: 'Review', recommendationType: 'weakness',
          priority: 0.9, explanations: ['Low score'],
          prerequisiteReason: 'prereq', weaknessReason: 'weak',
          reviewReason: 'overdue',
        );
        final json = original.toJson();
        final restored = PlanRecommendation.fromJson(json);
        expect(restored.topicId, original.topicId);
        expect(restored.prerequisiteReason, original.prerequisiteReason);
        expect(restored.weaknessReason, original.weaknessReason);
        expect(restored.reviewReason, original.reviewReason);
      });

      test('handles missing optional fields', () {
        final json = {
          'topicId': 't1', 'reason': 'Reason',
          'recommendationType': 'type', 'priority': null,
          'explanations': null,
        };
        final rec = PlanRecommendation.fromJson(json);
        expect(rec.priority, 0.0);
        expect(rec.explanations, []);
        expect(rec.prerequisiteReason, isNull);
      });
    });
  });

  group('SyllabusGoal', () {
    group('constructor', () {
      test('creates with required fields', () {
        final goal = const SyllabusGoal(
          subjectId: 'sub-1', subjectTitle: 'IB Physics',
        );
        expect(goal.subjectId, 'sub-1');
        expect(goal.subjectTitle, 'IB Physics');
        expect(goal.syllabusCode, '');
        expect(goal.targetDays, 30);
        expect(goal.targetHoursPerDay, 1);
      });

      test('accepts all fields', () {
        final goal = const SyllabusGoal(
          subjectId: 'sub-1', subjectTitle: 'IB Physics',
          syllabusCode: 'IB-PHYS', targetDays: 90, targetHoursPerDay: 2,
        );
        expect(goal.syllabusCode, 'IB-PHYS');
        expect(goal.targetDays, 90);
        expect(goal.targetHoursPerDay, 2);
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip preserves data', () {
        final original = const SyllabusGoal(
          subjectId: 'sub-1', subjectTitle: 'IB Physics',
          syllabusCode: 'IB-PHYS', targetDays: 60, targetHoursPerDay: 2,
        );
        final json = original.toJson();
        final restored = SyllabusGoal.fromJson(json);
        expect(restored.subjectId, original.subjectId);
        expect(restored.syllabusCode, original.syllabusCode);
        expect(restored.targetDays, original.targetDays);
      });

      test('handles missing optional fields', () {
        final json = {
          'subjectId': 'sub-1',
        };
        final goal = SyllabusGoal.fromJson(json);
        expect(goal.subjectTitle, '');
        expect(goal.syllabusCode, '');
        expect(goal.targetDays, 30);
        expect(goal.targetHoursPerDay, 1);
      });
    });
  });
}
