import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/planner_data.dart';

void main() {
  group('planner_data barrel', () {
    test('exports PersonalLearningPlan', () {
      expect(PersonalLearningPlan, isNotNull);
    });

    test('exports registerPlannerAdapters', () {
      expect(registerPlannerAdapters, isNotNull);
      expect(registerPlannerAdapters, isA<Function>());
    });

    test('PersonalLearningPlan stores plan properties', () {
      final summary = PlanSummary(
        totalQuestions: 30,
        totalMinutes: 180,
        newTopics: 2,
        reviewTopics: 1,
        estimatedCoverage: 0.7,
        focusAreas: ['Physics'],
      );
      final plan = PersonalLearningPlan(
        studentId: 'student_1',
        generatedAt: DateTime(2025, 2, 1),
        dailyPlans: [],
        summary: summary,
        recommendations: [],
        planDurationDays: 7,
      );
      expect(plan.studentId, 'student_1');
      expect(plan.planDurationDays, 7);
      expect(plan.summary.totalQuestions, 30);
    });

    test('PlanSummary estimatedCoverage is between 0 and 1', () {
      final summary = PlanSummary(
        totalQuestions: 30,
        totalMinutes: 180,
        newTopics: 2,
        reviewTopics: 1,
        estimatedCoverage: 0.7,
        focusAreas: ['Physics'],
      );
      expect(summary.estimatedCoverage, greaterThanOrEqualTo(0));
      expect(summary.estimatedCoverage, lessThanOrEqualTo(1));
    });
  });
}
