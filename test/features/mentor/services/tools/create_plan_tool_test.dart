import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:studyking/features/mentor/services/tools/create_plan_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'test_helpers.dart';

void main() {
  group('CreatePlanTool', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('returns success with plan metadata when a plan is generated',
        () async {
      // Persisted plans get a fresh UUID planId distinct from studentId
      // (PlannerService._persistGeneratedPlan), so the tool must report
      // the plan's own id, not the student's.
      final plan = sampleLearningPlan().copyWith(planId: 'plan-uuid-1');
      final planner = FakePlannerService(plan);
      final tool = CreatePlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'course': 'Mathematics',
        'daysValue': 7,
        'hoursValue': 2,
      });

      expect(result['success'], isTrue);
      expect(result['planId'], equals(plan.planId));
      expect(result['planId'], isNot(equals(plan.studentId)));
      expect(result['totalDays'], equals(2));
      expect(result['message'], isA<String>());
      expect(result['message'], isNotEmpty);
    });

    test('reports failure when the planner returns no plan', () async {
      final planner = FakePlannerService(null);
      final tool = CreatePlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'course': 'Mathematics',
        'daysValue': 7,
        'hoursValue': 2,
      });

      expect(result['success'], isFalse);
      expect(result['planId'], equals(''));
      expect(result['message'], equals(l10n.toolCreatePlanFail));
    });

    test('parses stringified numeric arguments without throwing',
        () async {
      final plan = sampleLearningPlan().copyWith(planId: 'plan-uuid-1');
      final planner = FakePlannerService(plan);
      final tool = CreatePlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'course': 'Mathematics',
        'daysValue': '7',
        'hoursValue': '3',
      });

      // The LLM emitted numbers as strings; the parsed values
      // must reach the planner service.
      expect(result['success'], isTrue);
      expect(planner.lastGenerateDaysValue, equals(7));
      expect(planner.lastGenerateHoursValue, equals(3));
    });

    test('reports a validation failure when daysValue is unparseable',
        () async {
      final planner = FakePlannerService(sampleLearningPlan());
      final tool = CreatePlanTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'course': 'Mathematics',
        'daysValue': 'not-a-number',
      });

      // Previously this threw a TypeError; now it degrades to a
      // structured failure.
      expect(result['success'], isFalse);
      expect(result['error'], contains('daysValue'));
      expect(planner.lastGenerateDaysValue, isNull);
    });
  });
}
