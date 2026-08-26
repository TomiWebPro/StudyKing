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
      final planner = FakePlannerService(sampleLearningPlan());
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
      expect(result['planId'], equals('student-1'));
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
