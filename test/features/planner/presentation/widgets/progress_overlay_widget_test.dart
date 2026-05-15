import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/presentation/widgets/progress_overlay_widget.dart';

Widget buildApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(body: widget),
  );
}

void main() {
  group('ProgressOverlayWidget', () {
    testWidgets('renders today progress with planned and actual minutes',
        (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(
            plannedMinutesToday: 60,
            actualMinutesToday: 45,
            todayProgress: 0.75,
            totalPlanDays: 30,
            completedDays: 15,
            cumulativeProgress: 0.5,
          ),
        ),
      ));

      expect(find.text('Progress Overview'), findsOneWidget);
      expect(find.text('Planned: 60 min'), findsOneWidget);
      expect(find.text('Actual: 45 min'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.textContaining('15/30 days'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('displays green color for 100% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 1.0),
        ),
      ));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('displays orange color for 50-99% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 0.5),
        ),
      ));

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('displays red color for below 50% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 0.3),
        ),
      ));

      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('empty weeklyProgress hides weekly section', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(
            weeklyProgress: [],
          ),
        ),
      ));

      expect(find.text('Weekly'), findsNothing);
      expect(find.text('Actual'), findsNothing);
      expect(find.text('Planned'), findsNothing);
    });

    testWidgets('non-empty weeklyProgress shows weekly section',
        (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: PlanProgressData(
            weeklyProgress: [
              DailyProgress(
                date: DateTime.now(),
                plannedMinutes: 30,
                actualMinutes: 20,
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
    });

    testWidgets('renders cumulative progress bar', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(
            completedDays: 10,
            totalPlanDays: 40,
            cumulativeProgress: 0.25,
          ),
        ),
      ));

      expect(find.text('10/40 days — 25% of plan'), findsOneWidget);
    });
  });
}
