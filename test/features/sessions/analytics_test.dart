import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/features/sessions/widgets/session_analytics.dart';

Widget buildTestApp(SessionAnalyticsWidget widget) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 1200,
        child: widget,
      ),
    ),
  );
}

void main() {
  final asOf = DateTime(2026, 1, 7, 10, 0); // Wed

  StudySession buildSession({
    required String id,
    required DateTime start,
    int timeSpentMs = 0,
  }) {
    return StudySession(
      id: id,
      studentId: 'student-1',
      subjectId: 'math',
      startTime: start,
      timeSpentMs: timeSpentMs,
    );
  }

  group('SessionAnalyticsWidget', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders section headers', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('Sessions by Day of Week'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
    });

    testWidgets('renders day labels for all days in default window', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
          asOf: asOf,
        ),
      ));

      for (var i = 0; i < 7; i++) {
        final day = DateFormat('E').format(asOf.subtract(Duration(days: i)));
        expect(find.text(day), findsOneWidget);
        expect(find.byKey(ValueKey('bar_$day')), findsOneWidget);
      }
    });

    testWidgets('shows zero counts for all days with no sessions', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('0'), findsAtLeastNWidgets(7));
    });

    testWidgets('displays session count on bar chart for days with sessions', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
        buildSession(id: '2', start: asOf, timeSpentMs: 1800000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 3,
          asOf: asOf,
        ),
      ));

      expect(find.text('2'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays metric cards with correct labels', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('Avg Session'), findsOneWidget);
      expect(find.text('Total Sessions'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Total Time'), findsOneWidget);
    });

    testWidgets('metric cards show correct data with sessions', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
        buildSession(
          id: '2',
          start: asOf.subtract(const Duration(days: 1)),
          timeSpentMs: 1800000,
        ),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 5,
          asOf: asOf,
        ),
      ));

      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('1h 30m 0s'), findsOneWidget);
      expect(find.text('45m 0s'), findsOneWidget);
    });

    testWidgets('handles dark theme brightness', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: SizedBox(
            height: 1200,
            child: const SessionAnalyticsWidget(
              sessions: [],
              currentStreak: 0,
            ),
          ),
        ),
      ));

      expect(find.text('Sessions by Day of Week'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
    });

    testWidgets('section header icons are rendered', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('metric card icons are rendered', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('sessions on different days update bar counts', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf),
        buildSession(id: '2', start: asOf.subtract(const Duration(days: 1))),
        buildSession(id: '3', start: asOf.subtract(const Duration(days: 2))),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 3,
          asOf: asOf,
        ),
      ));

      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('total time metric shows zero when empty', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('0s'), findsAtLeastNWidgets(1));
    });

    testWidgets('avg session text is shown with data', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 0,
          asOf: asOf,
        ),
      ));

      expect(find.text('Avg Session'), findsOneWidget);
      expect(find.text('1h 0m 0s'), findsAtLeastNWidgets(1));
    });

    testWidgets('bar chart containers render with correct structure', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays total sessions count in metric card', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf),
        buildSession(id: '2', start: asOf),
        buildSession(id: '3', start: asOf),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: asOf,
        ),
      ));

      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('supports custom daysToShow window', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: const [],
          currentStreak: 0,
          daysToShow: 3,
          asOf: asOf,
        ),
      ));

      for (var i = 0; i < 3; i++) {
        final day = DateFormat('E').format(asOf.subtract(Duration(days: i)));
        expect(find.byKey(ValueKey('bar_$day')), findsOneWidget);
      }
    });

  });
}
