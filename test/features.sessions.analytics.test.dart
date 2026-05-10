import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('renders day labels for all 7 days', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
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
      final today = DateTime.now();
      final sessions = [
        StudySession(
          id: '1',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: today,
          timeSpentMs: 3600000,
        ),
        StudySession(
          id: '2',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: today,
          timeSpentMs: 1800000,
        ),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 3,
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
      final today = DateTime.now();
      final sessions = [
        StudySession(
          id: '1',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: today,
          timeSpentMs: 3600000,
        ),
        StudySession(
          id: '2',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: today.subtract(const Duration(days: 1)),
          timeSpentMs: 1800000,
        ),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 5,
        ),
      ));

      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('5 days'), findsOneWidget);
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
      final today = DateTime.now();
      final sessions = [
        StudySession(id: '1', studentId: 's1', subjectId: 'math', startTime: today),
        StudySession(id: '2', studentId: 's1', subjectId: 'math', startTime: today.subtract(const Duration(days: 1))),
        StudySession(id: '3', studentId: 's1', subjectId: 'math', startTime: today.subtract(const Duration(days: 2))),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 3,
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
      final today = DateTime.now();
      final sessions = [
        StudySession(
          id: '1',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: today,
          timeSpentMs: 3600000,
        ),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 0,
        ),
      ));

      expect(find.text('Avg Session'), findsOneWidget);
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
      final today = DateTime.now();
      final sessions = [
        StudySession(id: '1', studentId: 's1', subjectId: 'math', startTime: today),
        StudySession(id: '2', studentId: 's1', subjectId: 'math', startTime: today),
        StudySession(id: '3', studentId: 's1', subjectId: 'math', startTime: today),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
        ),
      ));

      expect(find.text('3'), findsAtLeastNWidgets(1));
    });
  });
}
