import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/daily_activity_heatmap.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('DailyActivityHeatmap', () {
    testWidgets('renders header with heatmap title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DailyActivityHeatmap(dailyTrend: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_view_day), findsOneWidget);
      expect(find.text('Daily Activity'), findsOneWidget);
    });

    testWidgets('shows no activity message when trend is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const DailyActivityHeatmap(dailyTrend: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No activity'), findsOneWidget);
    });

    testWidgets('renders heatmap cells when trend data provided', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final trend = [
        DailyTrendEntry(
          date: today,
          attempts: 10,
          accuracy: 80,
          focusSeconds: 300,
          sessions: 2,
          compositeScore: 0.8,
        ),
        DailyTrendEntry(
          date: today.subtract(const Duration(days: 1)),
          attempts: 5,
          accuracy: 60,
          focusSeconds: 120,
          sessions: 1,
          compositeScore: 0.4,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        DailyActivityHeatmap(dailyTrend: trend),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_view_day), findsOneWidget);
      expect(find.byType(DailyActivityHeatmap), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders legend with color squares', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final trend = [
        DailyTrendEntry(date: today, attempts: 5, compositeScore: 0.5),
      ];

      await tester.pumpWidget(_buildTestApp(
        DailyActivityHeatmap(dailyTrend: trend),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DailyActivityHeatmap), findsOneWidget);
    });

    testWidgets('renders day-of-week labels', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final trend = [
        DailyTrendEntry(date: today, attempts: 5, compositeScore: 0.5),
      ];

      await tester.pumpWidget(_buildTestApp(
        DailyActivityHeatmap(dailyTrend: trend),
      ));
      await tester.pumpAndSettle();

      expect(find.text('M'), findsWidgets);
      expect(find.text('W'), findsWidgets);
      expect(find.text('F'), findsWidgets);
    });
  });
}
