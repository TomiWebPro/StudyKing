import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'test_helpers.dart';

class _ThrowingPlannerService extends FakePlannerService {
  _ThrowingPlannerService(super.plan);

  @override
  Future<Result<void>> adjustPace(double newTargetMinutesPerDay,
          {bool recalculateDuration = false}) async =>
      throw Exception('forced failure');
}

void main() {
  group('ModifyPlanTool', () {
    late FakePlannerService planner;

    setUpAll(() async {
      await AppLocalizations.delegate.load(const Locale('en'));
    });

    setUp(() => planner = FakePlannerService(sampleLearningPlan()));

    test('adjust_pace returns success with updated targets', () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'action': 'adjust_pace',
        'newTargetMinutesPerDay': 40,
      });

      expect(result['success'], isTrue);
      expect(result['newTargetMinutesPerDay'], equals(40));
      expect(result['planId'], equals('student-1'));
      expect(result['totalDays'], equals(2));
    });

    test('extend returns previous and new totals', () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'action': 'extend',
        'extendDays': 3,
      });

      expect(result['success'], isTrue);
      expect(result['previousDays'], equals(2));
      expect(result['addedDays'], equals(3));
      expect(result['newTotalDays'], equals(5));
    });

    test('redistribute reports success', () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'action': 'redistribute',
        'missedMinutes': 120,
        'redistributionStrategy': 'all_remaining',
      });

      expect(result['success'], isTrue);
      expect(result['missedMinutes'], equals(120));
      expect(result['strategy'], equals('all_remaining'));
    });

    test('change_targets updates daily targets', () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'action': 'change_targets',
        'newDailyMinutes': 45,
        'newDailyQuestions': 8,
      });

      expect(result['success'], isTrue);
      expect(result['newDailyMinutes'], equals(45));
      expect(result['newDailyQuestions'], equals(8));
    });

    test('reports the plan\'s own planId (not studentId) for every action',
        () async {
      // A persisted plan carries a planId (UUID) distinct from its
      // studentId; the tool must echo the plan's own id, never the
      // student's.
      final plan = sampleLearningPlan().copyWith(planId: 'plan-uuid-42');
      final planner = FakePlannerService(plan);
      final tool = ModifyPlanTool(plannerService: planner, localeName: 'en');

      final paceResult = await tool.execute({
        'action': 'adjust_pace',
        'newTargetMinutesPerDay': 40,
      });
      expect(paceResult['success'], isTrue);
      expect(paceResult['planId'], equals('plan-uuid-42'));
      expect(paceResult['planId'], isNot(equals(plan.studentId)));

      final extendResult = await tool.execute({
        'action': 'extend',
        'extendDays': 3,
      });
      expect(extendResult['success'], isTrue);
      expect(extendResult['planId'], equals('plan-uuid-42'));
      expect(extendResult['planId'], isNot(equals(plan.studentId)));

      final targetsResult = await tool.execute({
        'action': 'change_targets',
        'newDailyMinutes': 45,
      });
      expect(targetsResult['success'], isTrue);
      expect(targetsResult['planId'], equals('plan-uuid-42'));
      expect(targetsResult['planId'], isNot(equals(plan.studentId)));
    });

    test('reports failure for an invalid action', () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({'action': 'nonsense'});
      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
    });

    test('reports failure when required params are missing', () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'action': 'adjust_pace',
      });
      expect(result['success'], isFalse);
    });

    test('parses stringified numeric arguments for every action',
        () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final paceResult = await tool.execute({
        'action': 'adjust_pace',
        'newTargetMinutesPerDay': '45',
      });
      expect(paceResult['success'], isTrue);
      expect(paceResult['newTargetMinutesPerDay'], equals(45));

      final extendResult = await tool.execute({
        'action': 'extend',
        'extendDays': '3',
      });
      expect(extendResult['success'], isTrue);
      expect(extendResult['addedDays'], equals(3));
      expect(extendResult['newTotalDays'], equals(5));

      final redistributeResult = await tool.execute({
        'action': 'redistribute',
        'missedMinutes': '120',
      });
      expect(redistributeResult['success'], isTrue);
      expect(redistributeResult['missedMinutes'], equals(120));

      final targetsResult = await tool.execute({
        'action': 'change_targets',
        'newDailyMinutes': '45',
        'newDailyQuestions': '8',
      });
      expect(targetsResult['success'], isTrue);
      expect(targetsResult['newDailyMinutes'], equals(45));
      expect(targetsResult['newDailyQuestions'], equals(8));
    });

    test('reports a missing-param failure for unparseable numeric args',
        () async {
      final tool = ModifyPlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      // 'abc' cannot be parsed, so the tool must treat the
      // parameter as absent instead of throwing a TypeError.
      final result = await tool.execute({
        'action': 'adjust_pace',
        'newTargetMinutesPerDay': 'abc',
      });
      expect(result['success'], isFalse);
    });

    test('logs warning and preserves user-facing message on exception', () async {
      final throwingPlanner = _ThrowingPlannerService(sampleLearningPlan());
      final tool = ModifyPlanTool(
        plannerService: throwingPlanner,
        localeName: 'en',
      );

      final records = <String>[];
      final originalPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => records.add(message ?? '');

      final result = await tool.execute({
        'action': 'adjust_pace',
        'newTargetMinutesPerDay': 40,
      });

      debugPrint = originalPrint;

      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
      expect(result['message'], contains('Failed to modify'));
      expect(
        records.any((r) => r.contains('modify_plan_tool failed')),
        isTrue,
        reason: 'expected _logger.w to be called with modify_plan_tool failed',
      );
      expect(
        records.any((r) => r.contains('forced failure')),
        isTrue,
        reason: 'expected logged output to include underlying exception',
      );
    });
  });
}
