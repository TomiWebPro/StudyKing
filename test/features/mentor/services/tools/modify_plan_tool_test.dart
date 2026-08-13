import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';

class FakePlannerService extends PlannerService {
  double? capturedAdjustPaceMinutes;
  bool adjustPaceSuccess = true;
  PersonalLearningPlan? _plan;

  int? capturedExtendDays;
  bool extendSuccess = true;

  int? capturedRedistributeMinutes;
  String? capturedRedistributeStrategy;
  bool redistributeSuccess = true;

  FakePlannerService({PersonalLearningPlan? plan}) : _plan = plan;

  void setPlan(PersonalLearningPlan? plan) => _plan = plan;

  @override
  String get studentId => 'test-student';

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(_plan);
  }

  @override
  Future<Result<void>> adjustPace(double newTargetMinutesPerDay,
      {bool recalculateDuration = false}) async {
    capturedAdjustPaceMinutes = newTargetMinutesPerDay;
    if (!adjustPaceSuccess) return Result.failure('adjustPace failed');
    return Result.success(null);
  }

  @override
  Future<Result<void>> extendPlan(int extraDays) async {
    capturedExtendDays = extraDays;
    if (!extendSuccess) return Result.failure('extendPlan failed');
    return Result.success(null);
  }

  @override
  Future<Result<void>> redistributeMissedWorkload(
    int missedMinutes, {
    String strategy = 'days:3',
  }) async {
    capturedRedistributeMinutes = missedMinutes;
    capturedRedistributeStrategy = strategy;
    if (!redistributeSuccess) return Result.failure('redistribute failed');
    return Result.success(null);
  }
}

PersonalLearningPlan _createPlan({
  String studentId = 'test-student',
  int totalDays = 5,
  double targetMinutesPerDay = 60,
  int targetQuestionsPerDay = 10,
}) {
  return PersonalLearningPlan(
    studentId: studentId,
    generatedAt: DateTime.now(),
    dailyPlans: List.generate(
      totalDays,
      (i) => DailyPlan(
        date: DateTime.now().add(Duration(days: i)),
        dayNumber: i + 1,
        priorityTopics: [],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: targetQuestionsPerDay,
        targetMinutes: targetMinutesPerDay.round(),
      ),
    ),
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
    targetMinutesPerDay: targetMinutesPerDay,
    targetQuestionsPerDay: targetQuestionsPerDay,
  );
}

void main() {
  group('ModifyPlanTool', () {
    late FakePlannerService fakePlanner;
    late ModifyPlanTool tool;

    setUp(() {
      fakePlanner = FakePlannerService(plan: _createPlan());
      tool = ModifyPlanTool(plannerService: fakePlanner, localeName: 'en');
    });

    test('name returns modify_plan', () {
      expect(tool.name, 'modify_plan');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      final properties = params['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll([
        'action',
        'planId',
        'newTargetMinutesPerDay',
        'extendDays',
        'missedMinutes',
        'redistributionStrategy',
        'newDailyQuestions',
        'newDailyMinutes',
      ]));
      expect(properties['action']['type'], 'string');
      expect(properties['action']['enum'], [
        'adjust_pace',
        'extend',
        'redistribute',
        'change_targets',
      ]);
      expect(params['required'], ['action']);
    });

    test('returns error for invalid action', () async {
      final result = await tool.execute({'action': 'invalid_action'});
      expect(result['success'], false);
      expect(result['message'], contains('Invalid modification action'));
    });

    group('adjust_pace', () {
      test('returns error when newTargetMinutesPerDay is missing', () async {
        final result = await tool.execute({'action': 'adjust_pace'});
        expect(result['success'], false);
        expect(result['message'], contains('Missing required parameter'));
      });

      test('returns error when newTargetMinutesPerDay is zero', () async {
        final result = await tool.execute({
          'action': 'adjust_pace',
          'newTargetMinutesPerDay': 0,
        });
        expect(result['success'], false);
      });

      test('calls adjustPace with correct value', () async {
        final result = await tool.execute({
          'action': 'adjust_pace',
          'newTargetMinutesPerDay': 45,
        });

        expect(fakePlanner.capturedAdjustPaceMinutes, 45.0);
        expect(result['success'], true);
        expect(result['newTargetMinutesPerDay'], 45);
        expect(result['message'], contains('45'));
      });

      test('returns error when adjustPace fails', () async {
        fakePlanner.adjustPaceSuccess = false;

        final result = await tool.execute({
          'action': 'adjust_pace',
          'newTargetMinutesPerDay': 45,
        });

        expect(result['success'], false);
        expect(result['message'], contains('Failed'));
      });
    });

    group('extend', () {
      test('returns error when extendDays is missing', () async {
        final result = await tool.execute({'action': 'extend'});
        expect(result['success'], false);
        expect(result['message'], contains('Missing required parameter'));
      });

      test('returns error when extendDays is zero', () async {
        final result = await tool.execute({
          'action': 'extend',
          'extendDays': 0,
        });
        expect(result['success'], false);
      });

      test('returns error when no plan exists', () async {
        fakePlanner.setPlan(null);

        final result = await tool.execute({
          'action': 'extend',
          'extendDays': 7,
        });

        expect(result['success'], false);
        expect(result['message'], contains('No active plan'));
      });

      test('calls extendPlan with correct values', () async {
        fakePlanner.setPlan(_createPlan(totalDays: 5));

        final result = await tool.execute({
          'action': 'extend',
          'extendDays': 7,
        });

        expect(result['success'], true);
        expect(result['addedDays'], 7);
        expect(result['newTotalDays'], 12);
        expect(result['message'], contains('7'));
      });
    });

    group('redistribute', () {
      test('returns error when missedMinutes is missing', () async {
        final result = await tool.execute({'action': 'redistribute'});
        expect(result['success'], false);
        expect(result['message'], contains('Missing required parameter'));
      });

      test('returns error when missedMinutes is zero', () async {
        final result = await tool.execute({
          'action': 'redistribute',
          'missedMinutes': 0,
        });
        expect(result['success'], false);
      });

      test('calls redistribute with default strategy', () async {
        final result = await tool.execute({
          'action': 'redistribute',
          'missedMinutes': 120,
        });

        expect(result['success'], true);
        expect(result['missedMinutes'], 120);
        expect(result['strategy'], 'next_3_days');
        expect(result['message'], contains('120'));
      });

      test('uses all_remaining strategy when specified', () async {
        final result = await tool.execute({
          'action': 'redistribute',
          'missedMinutes': 60,
          'redistributionStrategy': 'all_remaining',
        });

        expect(result['success'], true);
        expect(result['strategy'], 'all_remaining');
      });
    });

    group('change_targets', () {
      test('returns error when neither target is provided', () async {
        final result = await tool.execute({'action': 'change_targets'});
        expect(result['success'], false);
        expect(result['message'], contains('Missing required parameter'));
      });

      test('calls adjustPace when newDailyMinutes is provided', () async {
        final result = await tool.execute({
          'action': 'change_targets',
          'newDailyMinutes': 30,
        });

        expect(fakePlanner.capturedAdjustPaceMinutes, 30.0);
        expect(result['success'], true);
        expect(result['message'], contains('updated'));
      });

      test('returns success when only newDailyQuestions is provided', () async {
        final result = await tool.execute({
          'action': 'change_targets',
          'newDailyQuestions': 20,
        });

        expect(fakePlanner.capturedAdjustPaceMinutes, isNull);
        expect(result['success'], true);
      });
    });
  });
}
