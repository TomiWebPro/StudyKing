import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/dashboard.dart';

void main() {
  group('Dashboard barrel', () {
    test('exports DashboardScreen', () {
      expect(DashboardScreen, isNotNull);
    });

    test('exports BadgesCard', () => expect(BadgesCard, isNotNull));
    test('exports DashboardHeader', () => expect(DashboardHeader, isNotNull));
    test('exports ExportSection', () => expect(ExportSection, isNotNull));
    test('exports MasteryProgressCard', () => expect(MasteryProgressCard, isNotNull));
    test('exports PlanAdherenceCard', () => expect(PlanAdherenceCard, isNotNull));
    test('exports SummaryRow', () => expect(SummaryRow, isNotNull));
    test('exports TopicBreakdownCard', () => expect(TopicBreakdownCard, isNotNull));
    test('exports WeakAreasCard', () => expect(WeakAreasCard, isNotNull));
    test('exports WeeklyChart', () => expect(WeeklyChart, isNotNull));
  });
}
