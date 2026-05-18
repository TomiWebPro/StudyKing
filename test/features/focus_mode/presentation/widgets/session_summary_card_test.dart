import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

TestNavigatorObserver? testNavigatorObserver;

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: testNavigatorObserver != null ? [testNavigatorObserver!] : [],
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
    setUp(() {
      testNavigatorObserver = TestNavigatorObserver();
    });

    tearDown(() {
      testNavigatorObserver = null;
    });
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

      expect(find.text('1h 0m 0s'), findsOneWidget);
    });

    testWidgets('renders today duration in minutes when < 1 hour', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalMs': 1500000},
        ),
      ));

      expect(find.text('25m 0s'), findsOneWidget);
    });

    testWidgets('renders weekly duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          weeklyMs: 7200000,
        ),
      ));

      expect(find.text('2h 0m 0s'), findsOneWidget);
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

      expect(find.text('0s'), findsAtLeast(1));
    });

    testWidgets('renders default values when stats map is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(todayStats: {}),
      ));

      expect(find.text('0s'), findsAtLeast(1));
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
      expect(find.text('25m 0s / 25m 0s'), findsOneWidget);
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

      expect(find.text('10m 0s / 25m 0s'), findsOneWidget);
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

      expect(find.text('1h 0m 0s'), findsOneWidget);
      expect(find.text('2h 0m 0s'), findsOneWidget);
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

      expect(find.text('1h 30m 0s / 1h 30m 0s'), findsOneWidget);
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

    testWidgets('renders today stat with seconds format', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalMs': 45000},
        ),
      ));

      expect(find.text('45s'), findsOneWidget);
    });

    testWidgets('falls back to totalSeconds when totalMs absent', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {'totalSeconds': 3600},
        ),
      ));

      expect(find.text('1h 0m 0s'), findsOneWidget);
    });

    testWidgets('totalMs takes precedence over totalSeconds', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SessionSummaryCard(
          todayStats: {
            'totalMs': 1800000,
            'totalSeconds': 3600,
          },
        ),
      ));

      expect(find.text('30m 0s'), findsOneWidget);
    });

    testWidgets('session with null plannedDurationMinutes', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        Session(
          id: 's1',
          studentId: 'student-1',
          startTime: now,
          actualDurationMs: 1500000,
          completed: true,
          type: SessionType.focus,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.text('25m 0s / 0s'), findsOneWidget);
    });

    testWidgets('narrow layout adjusts MetricCard widths', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(350, 600)),
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

      expect(find.text('1h 0m 0s'), findsOneWidget);
      expect(find.text('2h 0m 0s'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('session with null planned and short duration', (tester) async {
      final now = DateTime(2026, 5, 14, 10, 30);
      final sessions = [
        Session(
          id: 's1',
          studentId: 'student-1',
          startTime: now,
          actualDurationMs: 30000,
          completed: false,
          type: SessionType.focus,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        SessionSummaryCard(recentSessions: sessions),
      ));

      expect(find.text('30s / 0s'), findsOneWidget);
    });
  });
}
