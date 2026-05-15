import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/widgets/animated_bar_chart.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weekly_chart.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('WeeklyChart', () {
    testWidgets('renders with empty trend data', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const WeeklyChart(weeklyTrend: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.show_chart), findsOneWidget);
      expect(find.byType(AnimatedBarChart), findsOneWidget);
    });

    testWidgets('renders with trend data', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeeklyChart(weeklyTrend: [
          WeeklyTrendEntry(attempts: 5),
          WeeklyTrendEntry(attempts: 10),
          WeeklyTrendEntry(attempts: 3),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedBarChart), findsOneWidget);
      expect(find.text('W3'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
    });

    testWidgets('limits to 7 data points', (tester) async {
      final trend = List.generate(
        10,
        (i) => WeeklyTrendEntry(attempts: i),
      );
      await tester.pumpWidget(_buildTestApp(
        WeeklyChart(weeklyTrend: trend),
      ));
      await tester.pumpAndSettle();

      expect(find.text('W7'), findsOneWidget);
      expect(find.text('W10'), findsNothing);
    });
  });
}
