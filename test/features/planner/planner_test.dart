import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/planner.dart';

void main() {
  group('planner barrel', () {
    test('exports PersonalLearningPlan', () => expect(PersonalLearningPlan, isNotNull));
    test('exports PlanAdherenceMetric', () => expect(PlanAdherenceMetric, isNotNull));
    test('exports EngagementNudgeRepository', () => expect(EngagementNudgeRepository, isNotNull));
    test('exports PendingActionRepository', () => expect(PendingActionRepository, isNotNull));
    test('exports PlanAdherenceRepository', () => expect(PlanAdherenceRepository, isNotNull));
    test('exports PlanRepository', () => expect(PlanRepository, isNotNull));
    test('exports RoadmapRepository', () => expect(RoadmapRepository, isNotNull));
    test('exports StudentAvailabilityRepository', () => expect(StudentAvailabilityRepository, isNotNull));
    test('exports PlannerScreen', () => expect(PlannerScreen, isNotNull));
    test('exports PlannerService', () => expect(PlannerService, isNotNull));
    test('exports ActionExecutor', () => expect(ActionExecutor, isNotNull));
    test('exports SyllabusResolver', () => expect(SyllabusResolver, isNotNull));
    test('exports PlannerNotifier', () => expect(PlannerNotifier, isNotNull));
    test('exports PlanSummaryCard', () => expect(PlanSummaryCard, isNotNull));
    test('exports DailyPlanCard', () => expect(DailyPlanCard, isNotNull));
    test('exports RoadmapCard', () => expect(RoadmapCard, isNotNull));
    test('exports MilestoneTimeline', () => expect(MilestoneTimeline, isNotNull));
    test('exports PendingActionCard', () => expect(PendingActionCard, isNotNull));
    test('exports LessonBookingSheet', () => expect(LessonBookingSheet, isNotNull));
    test('exports ProgressOverlayWidget', () => expect(ProgressOverlayWidget, isNotNull));
    test('exports CalendarViewWidget', () => expect(CalendarViewWidget, isNotNull));

    test('PersonalLearningPlan stores properties', () {
      final plan = PersonalLearningPlan(
        studentId: 'student_1',
        generatedAt: DateTime(2025, 1, 15),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 50,
          totalMinutes: 300,
          newTopics: 3,
          reviewTopics: 2,
          estimatedCoverage: 0.8,
          focusAreas: ['Algebra', 'Geometry'],
        ),
        recommendations: [],
        planDurationDays: 14,
        targetMinutesPerDay: 45.0,
        targetQuestionsPerDay: 20,
      );
      expect(plan.studentId, 'student_1');
      expect(plan.planDurationDays, 14);
      expect(plan.targetMinutesPerDay, 45.0);
      expect(plan.targetQuestionsPerDay, 20);
    });

    test('PlanAdherenceMetric stores values', () {
      final metric = PlanAdherenceMetric(
        date: DateTime(2025, 1, 15),
        studentId: 'student_1',
        plannedQuestions: 20,
        actualQuestions: 15,
        plannedMinutes: 60,
        actualMinutes: 45,
        adherenceScore: 0.75,
      );
      expect(metric.date, DateTime(2025, 1, 15));
      expect(metric.plannedQuestions, 20);
      expect(metric.actualQuestions, 15);
      expect(metric.adherenceScore, 0.75);
    });

    test('PlanSummary stores values', () {
      final summary = PlanSummary(
        totalQuestions: 100,
        totalMinutes: 600,
        newTopics: 5,
        reviewTopics: 3,
        estimatedCoverage: 0.9,
        focusAreas: ['Math', 'Science'],
      );
      expect(summary.totalQuestions, 100);
      expect(summary.totalMinutes, 600);
      expect(summary.newTopics, 5);
      expect(summary.estimatedCoverage, 0.9);
      expect(summary.focusAreas, ['Math', 'Science']);
    });

    test('PlannedTopic stores values', () {
      final topic = PlannedTopic(
        topicId: 'topic_1',
        topicTitle: 'Quadratic Equations',
        priority: 0.9,
        reason: 'Weak area',
        readinessScore: 0.3,
        reviewUrgency: 0.8,
        estimatedQuestions: 10,
        estimatedMinutes: 30,
        reasons: ['low accuracy', 'prerequisite gap'],
      );
      expect(topic.topicId, 'topic_1');
      expect(topic.topicTitle, 'Quadratic Equations');
      expect(topic.priority, 0.9);
      expect(topic.reviewUrgency, 0.8);
    });

    test('DailyPlan stores values', () {
      final plan = DailyPlan(
        date: DateTime(2025, 1, 15),
        dayNumber: 1,
        priorityTopics: [],
        reviewQuestionIds: ['q1', 'q2'],
        stretchGoalQuestionIds: ['q3'],
        targetQuestions: 15,
        targetMinutes: 45,
        focus: 'Algebra review',
      );
      expect(plan.date, DateTime(2025, 1, 15));
      expect(plan.dayNumber, 1);
      expect(plan.targetQuestions, 15);
      expect(plan.targetMinutes, 45);
      expect(plan.focus, 'Algebra review');
    });

    test('PlanRecommendation stores values', () {
      final rec = PlanRecommendation(
        topicId: 'topic_1',
        reason: 'Needs practice',
        recommendationType: 'review',
        priority: 0.8,
        explanations: ['Low accuracy on derivatives'],
      );
      expect(rec.topicId, 'topic_1');
      expect(rec.recommendationType, 'review');
      expect(rec.priority, 0.8);
    });

    test('SyllabusGoal stores values', () {
      final goal = SyllabusGoal(
        subjectId: 'subj_1',
        subjectTitle: 'Mathematics',
        syllabusCode: 'MATH101',
        targetDays: 60,
        targetHoursPerDay: 2,
      );
      expect(goal.subjectId, 'subj_1');
      expect(goal.subjectTitle, 'Mathematics');
      expect(goal.syllabusCode, 'MATH101');
      expect(goal.targetDays, 60);
      expect(goal.targetHoursPerDay, 2);
    });
  });
}
