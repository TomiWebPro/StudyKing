import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/planner_data.dart';

void main() {
  group('planner_data barrel', () {
    test('exports PersonalLearningPlan', () {
      expect(PersonalLearningPlan, isNotNull);
    });

    test('exports registerPlannerAdapters', () {
      expect(registerPlannerAdapters, isNotNull);
    });
  });
}
