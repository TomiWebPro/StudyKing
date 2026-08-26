import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'test_helpers.dart';

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
  });
}
