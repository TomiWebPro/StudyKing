import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
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

Session _session({
  required String id,
  required DateTime startTime,
  int plannedDurationMinutes = 25,
  int actualDurationMs = 1500000,
  bool completed = true,
}) {
  return Session(
    id: id,
    studentId: 'student-1',
    startTime: startTime,
    endTime: completed ? startTime.add(Duration(milliseconds: actualDurationMs)) : null,
    plannedDurationMinutes: plannedDurationMinutes,
    actualDurationMs: actualDurationMs,
    completed: completed,
    type: SessionType.focus,
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
          todayStats: {'totalMs': 3600000},
        ),
      ));

      expect(find.text('1h 0m'), findsOneWidget);
    });

    testWidgets('renders today duration in minutes when < 1 hour', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalMs': 1500000},
        ),
      ));

      expect(find.text('25m'), findsOneWidget);
    });

    testWidgets('renders weekly duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          weeklyMs: 7200000,
        ),
      ));

      expect(find.text('2h 0m'), findsOneWidget);
    });

    testWidgets('renders session counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {
            'totalMs': 3600000,
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
        _session(
          id: 's1',
          startTime: now,
          plannedDurationMinutes: 25,
          actualDurationMs: 1500000,
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
        _session(
          id: 's1',
          startTime: now,
          plannedDurationMinutes: 25,
          actualDurationMs: 600000,
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
        (i) => _session(
          id: 's$i',
          startTime: now,
          plannedDurationMinutes: 25,
          actualDurationMs: 1500000,
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

    testWidgets('renders narrow layout with MetricCards wrapping', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(300, 600)),
          child: _buildTestApp(
            const SessionSummaryCard(
              todayStats: {
                'totalMs': 3600000,
                'completedSessions': 2,
                'totalSessions': 3,
              },
              weeklyMs: 7200000,
            ),
          ),
        ),
      );

      expect(find.text('1h 0m'), findsOneWidget);
      expect(find.text('2h 0m'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('shows session time with hours in recent list', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        _session(
          id: 's1',
          startTime: now,
          plannedDurationMinutes: 90,
          actualDurationMs: 5400000,
          completed: true,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.text('1h 30m / 90m'), findsOneWidget);
    });

    testWidgets('shows session start time correctly', (tester) async {
      final now = DateTime(2026, 5, 14, 8, 5);
      final sessions = [
        _session(
          id: 's1',
          startTime: now,
          plannedDurationMinutes: 25,
          actualDurationMs: 1500000,
          completed: true,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.text('08:05'), findsOneWidget);
    });

    testWidgets('shows correct icon for completed session', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        _session(
          id: 's1',
          startTime: now,
          actualDurationMs: 1500000,
          completed: true,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.byIcon(Icons.check_circle), findsAtLeast(1));
    });

    testWidgets('shows correct icon for incomplete session', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        _session(
          id: 's1',
          startTime: now,
          actualDurationMs: 600000,
          completed: false,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders today stat with minutes only format', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalMs': 45000},
        ),
      ));

      expect(find.text('0m'), findsAtLeast(1));
    });
  });
}
