import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/mentor/services/tools/create_plan_tool.dart';

class FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  String? capturedCourse;
  int? capturedDaysValue;
  int? capturedHoursValue;

  FakePlannerService();

  void setPlan(PersonalLearningPlan? plan) => _plan = plan;

  @override
  Future<Result<PersonalLearningPlan?>> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
  }) async {
    capturedCourse = course;
    capturedDaysValue = daysValue;
    capturedHoursValue = hoursValue;
    return Result.success(_plan);
  }
}

PersonalLearningPlan _createPlan({String studentId = 'student-1', int totalDays = 0}) {
  return PersonalLearningPlan(
    studentId: studentId,
    generatedAt: DateTime.now(),
    dailyPlans: List.generate(totalDays, (i) => DailyPlan(
      date: DateTime.now().add(Duration(days: i)),
      dayNumber: i + 1,
      priorityTopics: [],
      reviewQuestionIds: [],
      stretchGoalQuestionIds: [],
      targetQuestions: 5,
      targetMinutes: 30,
    )),
    summary: PlanSummary(
      totalQuestions: 0,
      totalMinutes: 0,
      newTopics: 0,
      reviewTopics: 0,
      estimatedCoverage: 0.0,
      focusAreas: [],
    ),
    recommendations: [],
    planDurationDays: totalDays,
    targetMinutesPerDay: 60,
    targetQuestionsPerDay: 10,
  );
}

void main() {
  group('CreatePlanTool', () {
    late FakePlannerService fakePlanner;
    late CreatePlanTool tool;

    setUp(() {
      fakePlanner = FakePlannerService();
      tool = CreatePlanTool(plannerService: fakePlanner);
    });

    test('name returns create_plan', () {
      expect(tool.name, 'create_plan');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      final properties = params['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll(['course', 'daysValue', 'hoursValue']));
      expect(properties['course']['type'], 'string');
      expect(properties['daysValue']['type'], 'integer');
      expect(properties['hoursValue']['type'], 'integer');
      expect(properties['hoursValue']['default'], 2);
      expect(params['required'], ['course', 'daysValue']);
    });

    test('execute returns success with plan data when plan is generated', () async {
      fakePlanner.setPlan(_createPlan(studentId: 'stu-42', totalDays: 5));

      final result = await tool.execute({
        'course': 'Mathematics',
        'daysValue': 5,
      });

      expect(result['success'], true);
      expect(result['planId'], 'stu-42');
      expect(result['totalDays'], 5);
      expect(result['message'], 'Plan created for Mathematics over 5 days');
    });

    test('execute returns success=false when plan is null', () async {
      fakePlanner.setPlan(null);

      final result = await tool.execute({
        'course': 'Mathematics',
        'daysValue': 5,
      });

      expect(result['success'], false);
      expect(result['planId'], '');
      expect(result['totalDays'], 0);
      expect(result['message'], 'Failed to create plan');
    });

    test('execute uses default hoursValue when omitted', () async {
      fakePlanner.setPlan(null);

      await tool.execute({
        'course': 'Physics',
        'daysValue': 10,
      });

      expect(fakePlanner.capturedHoursValue, 2);
    });

    test('execute accepts custom hoursValue', () async {
      await tool.execute({
        'course': 'Physics',
        'daysValue': 10,
        'hoursValue': 3,
      });

      expect(fakePlanner.capturedHoursValue, 3);
    });

    test('execute handles plan with zero daily plans', () async {
      fakePlanner.setPlan(_createPlan(totalDays: 0));

      final result = await tool.execute({
        'course': 'Chemistry',
        'daysValue': 0,
      });

      expect(result['success'], true);
      expect(result['totalDays'], 0);
    });
  });
}
