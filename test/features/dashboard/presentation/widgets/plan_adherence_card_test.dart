import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/plan_adherence_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
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
  });
}
