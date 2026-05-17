import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/presentation/widgets/progress_overlay_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
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
      expect(find.textContaining('15/30'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('displays chart icon', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(),
        ),
      ));

      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('renders LinearProgressIndicator for today', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 0.75),
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays primary color for 100% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 1.0),
        ),
      ));
      final cs = Theme.of(tester.element(find.byType(ProgressOverlayWidget))).colorScheme;

      final textWidget = tester.widget<Text>(find.text('100%'));
      expect(textWidget.style?.color, cs.primary);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.valueColor, isA<Animation<Color?>>());
    });

    testWidgets('displays error color for below 80% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 0.5),
        ),
      ));
      final cs = Theme.of(tester.element(find.byType(ProgressOverlayWidget))).colorScheme;

      final textWidget = tester.widget<Text>(find.text('50%'));
      expect(textWidget.style?.color, cs.error);
    });

    testWidgets('displays tertiary color for 70% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 0.7),
        ),
      ));
      final cs = Theme.of(tester.element(find.byType(ProgressOverlayWidget))).colorScheme;

      final textWidget = tester.widget<Text>(find.text('70%'));
      expect(textWidget.style?.color, cs.tertiary);
    });

    testWidgets('displays error color for below 50% progress', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(todayProgress: 0.3),
        ),
      ));
      final cs = Theme.of(tester.element(find.byType(ProgressOverlayWidget))).colorScheme;

      final textWidget = tester.widget<Text>(find.text('30%'));
      expect(textWidget.style?.color, cs.error);
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
    });

    testWidgets('non-empty weeklyProgress shows weekly section',
        (tester) async {
      await tester.pumpWidget(buildApp(
        SizedBox(
          height: 500,
          child: ProgressOverlayWidget(
            data: PlanProgressData(
              weeklyProgress: [
                DailyProgress(
                  date: DateTime.now(),
                  plannedMinutes: 15,
                  actualMinutes: 2,
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
    });

    testWidgets('shows day labels in weekly chart', (tester) async {
      final monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      await tester.pumpWidget(buildApp(
        SizedBox(
          height: 500,
          child: ProgressOverlayWidget(
            data: PlanProgressData(
              weeklyProgress: [
                DailyProgress(date: monday, plannedMinutes: 15, actualMinutes: 2),
                DailyProgress(date: monday.add(const Duration(days: 1)), plannedMinutes: 20, actualMinutes: 3),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('renders weekly chart legend', (tester) async {
      await tester.pumpWidget(buildApp(
        SizedBox(
          height: 500,
          child: ProgressOverlayWidget(
            data: PlanProgressData(
              weeklyProgress: [
                DailyProgress(date: DateTime.now(), plannedMinutes: 15, actualMinutes: 2),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
    });

    testWidgets('renders containers in weekly chart', (tester) async {
      await tester.pumpWidget(buildApp(
        SizedBox(
          height: 500,
          child: ProgressOverlayWidget(
            data: PlanProgressData(
              weeklyProgress: [
                DailyProgress(date: DateTime.now(), plannedMinutes: 20, actualMinutes: 3),
              ],
            ),
          ),
        ),
      ));

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders cumulative progress with trending up icon', (tester) async {
      await tester.pumpWidget(buildApp(
        ProgressOverlayWidget(
          data: const PlanProgressData(
            completedDays: 10,
            totalPlanDays: 40,
            cumulativeProgress: 0.25,
          ),
        ),
      ));

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.textContaining('10/40 Days'), findsOneWidget);
      expect(find.textContaining('25%'), findsOneWidget);
    });

  });
}
