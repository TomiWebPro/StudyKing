import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: widget,
    ),
  );
}

void main() {
  group('SessionSummaryCard', () {
    testWidgets('renders Focus Time title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(),
      ));

      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('renders today duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalSeconds': 3600},
        ),
      ));

      expect(find.text('1h 0m'), findsOneWidget);
    });

    testWidgets('renders today duration in minutes when < 1 hour', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalSeconds': 1500},
        ),
      ));

      expect(find.text('25m'), findsOneWidget);
    });

    testWidgets('renders weekly duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          weeklySeconds: 7200,
        ),
      ));

      expect(find.text('2h 0m'), findsOneWidget);
    });

    testWidgets('renders session counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {
            'totalSeconds': 3600,
            'completedSessions': 3,
            'totalSessions': 5,
          },
        ),
      ));

      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('renders default values when stats is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(),
      ));

      expect(find.text('0m'), findsAtLeast(1));
    });

    testWidgets('renders default values when stats map is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(todayStats: {}),
      ));

      expect(find.text('0m'), findsAtLeast(1));
      expect(find.text('0/0'), findsOneWidget);
    });

    testWidgets('shows recent sessions', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        FocusSession(
          id: 's1',
          startTime: now,
          endTime: now.add(const Duration(minutes: 25)),
          plannedDurationMinutes: 25,
          actualDurationSeconds: 1500,
          completed: true,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.text('Recent Sessions'), findsOneWidget);
      expect(find.text('25m / 25m'), findsOneWidget);
    });

    testWidgets('shows incomplete session in recent list', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        FocusSession(
          id: 's1',
          startTime: now,
          endTime: now.add(const Duration(minutes: 10)),
          plannedDurationMinutes: 25,
          actualDurationSeconds: 600,
          completed: false,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.text('10m / 25m'), findsOneWidget);
    });

    testWidgets('limits recent sessions to 3', (tester) async {
      final now = DateTime(2026, 5, 14);
      final sessions = List.generate(
        5,
        (i) => FocusSession(
          id: 's$i',
          startTime: now,
          plannedDurationMinutes: 25,
          actualDurationSeconds: 1500,
          completed: true,
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    });

    testWidgets('hides recent sessions section when empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(),
      ));

      expect(find.text('Recent Sessions'), findsNothing);
    });
  });
}
