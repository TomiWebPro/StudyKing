import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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

    testWidgets('semantic label announces rounded accuracy, not raw double',
        (tester) async {
      await initializeDateFormatting();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final trend = [
        DailyTrendEntry(
          date: today,
          attempts: 10,
          accuracy: 85.0,
          focusSeconds: 300,
          sessions: 2,
          compositeScore: 0.8,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(DailyActivityHeatmap(dailyTrend: trend)));
      await tester.pumpAndSettle();

      final dateStr = DateFormat.yMMMd('en').format(today);
      // The spoken label must use the rounded percent (85%), matching the
      // tooltip — never the raw double (85.0%).
      expect(
        find.bySemanticsLabel('$dateStr: 10 Sessions, 85%'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'85\.0%')), findsNothing);
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

    group('weekday row alignment', () {
      setUpAll(() async {
        await initializeDateFormatting();
      });

      DateTime lastWeekdayBefore(int weekday) {
        final now = DateTime.now();
        var date = DateTime(now.year, now.month, now.day);
        while (date.weekday != weekday) {
          date = date.subtract(const Duration(days: 1));
        }
        // Keep the first activity strictly in the past so the grid
        // spans a full week even when today is that weekday.
        if (!date.isBefore(DateTime(now.year, now.month, now.day))) {
          date = date.subtract(const Duration(days: 7));
        }
        return date;
      }

      Future<void> pumpWithFirstActivity(
        WidgetTester tester,
        DateTime firstActivity,
      ) async {
        await tester.pumpWidget(_buildTestApp(
          DailyActivityHeatmap(
            dailyTrend: [
              DailyTrendEntry(
                date: firstActivity,
                attempts: 5,
                accuracy: 80,
                focusSeconds: 300,
                sessions: 1,
                compositeScore: 0.5,
              ),
            ],
          ),
        ));
        await tester.pumpAndSettle();
      }

      /// Top offset of the heatmap cell grid (the row of week columns)
      /// relative to the top of the rendered grid area.
      double gridTop(WidgetTester tester) {
        final weekRow = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Row),
        );
        expect(weekRow, findsOneWidget);
        return tester.getTopLeft(weekRow).dy;
      }

      testWidgets('places first activity on a Thursday in the Thursday row',
          (tester) async {
        final thursday = lastWeekdayBefore(DateTime.thursday);
        await pumpWithFirstActivity(tester, thursday);

        // The entry must render with its date in the semantics label.
        final dateStr = DateFormat.yMMMd('en').format(thursday);
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(dateStr)}')),
          findsOneWidget,
        );

        // Thursday is row 3 (Monday = row 0); each cell is 12px tall
        // with no gaps between rows in a column.
        final cell = find.byType(Tooltip);
        expect(cell, findsOneWidget);
        expect(tester.getTopLeft(cell).dy - gridTop(tester), 3 * 12.0);
      });

      testWidgets('places first activity on a Monday in the Monday row',
          (tester) async {
        final monday = lastWeekdayBefore(DateTime.monday);
        await pumpWithFirstActivity(tester, monday);

        final cell = find.byType(Tooltip);
        expect(cell, findsOneWidget);
        expect(tester.getTopLeft(cell).dy - gridTop(tester), 0.0);
      });
    });
  });
}
