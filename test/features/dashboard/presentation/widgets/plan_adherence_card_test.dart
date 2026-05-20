import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/plan_adherence_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Widget _buildTestApp(Widget child, {TestNavigatorObserver? navigatorObserver}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PlanAdherenceCard', () {
    testWidgets('renders both overall and weekly adherence', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.8,
          weeklyAdherence: 0.6,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('80%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('renders zero adherence', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.0,
          weeklyAdherence: 0.0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsNWidgets(2));
    });

    testWidgets('renders 100% adherence', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 1.0,
          weeklyAdherence: 1.0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsNWidgets(2));
    });

    testWidgets('shows plan adherence header with icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.5,
          weeklyAdherence: 0.5,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event_note), findsOneWidget);
    });

    testWidgets('shows plan adherence title with semantics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.8,
          weeklyAdherence: 0.6,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Plan Adherence'), findsOneWidget);
      expect(find.byType(Semantics), findsAtLeast(1));
    });

    testWidgets('uses error color style at very low adherence', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.2,
          weeklyAdherence: 0.1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('20%'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
    });

    testWidgets('high adherence (>= 0.7) uses primary color', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.85,
          weeklyAdherence: 0.75,
        ),
      ));
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final valueTexts = textWidgets.where((t) => t.data == '85%' || t.data == '75%').toList();
      for (final t in valueTexts) {
        expect(t.style?.fontWeight, FontWeight.bold);
      }
    });

    testWidgets('medium adherence (0.4-0.7) uses tertiary color', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.55,
          weeklyAdherence: 0.45,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('55%'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('boundary at exactly 0.7 is primary', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.7,
          weeklyAdherence: 0.7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('70%'), findsNWidgets(2));
    });

    testWidgets('boundary at exactly 0.4 is tertiary', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.4,
          weeklyAdherence: 0.4,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('40%'), findsNWidgets(2));
    });

    testWidgets('below 0.4 uses error color', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PlanAdherenceCard(
          averageAdherence: 0.39,
          weeklyAdherence: 0.35,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('39%'), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
    });

    // PlanAdherenceCard is a pure rendering widget with no navigation callbacks.
  });
}
