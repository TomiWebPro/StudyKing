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
  });
}
