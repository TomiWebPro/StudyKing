import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/summary_row.dart';
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
  group('SummaryRow', () {
    testWidgets('renders with null stats gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SummaryRow(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('0.0h'), findsOneWidget);
      expect(find.text('0'), findsAtLeast(1));
    });

    testWidgets('renders with empty stats', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SummaryRow(overallStats: OverallStats()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0.0%'), findsOneWidget);
    });

    testWidgets('displays accuracy percentage', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SummaryRow(overallStats: OverallStats(accuracy: 85)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('85.0%'), findsOneWidget);
    });

    testWidgets('displays study time hours', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SummaryRow(overallStats: OverallStats(totalStudyTimeHours: 12.5)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('12.5h'), findsOneWidget);
    });

    testWidgets('displays weekly activity count', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SummaryRow(overallStats: OverallStats(weeklyActivity: 15)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('15'), findsAtLeast(1));
    });

    testWidgets('displays topics studied count', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SummaryRow(overallStats: OverallStats(topicsStudied: 7)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsAtLeast(1));
    });

    testWidgets('renders MetricCard widgets for each stat', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SummaryRow(overallStats: OverallStats(
          accuracy: 80,
          totalStudyTimeHours: 10,
          weeklyActivity: 20,
          topicsStudied: 5,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
    });
  });
}
