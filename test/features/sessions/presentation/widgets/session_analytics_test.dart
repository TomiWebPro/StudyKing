import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/features/sessions/presentation/widgets/session_analytics.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildTestApp(SessionAnalyticsWidget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        height: 1200,
        child: widget,
      ),
    ),
  );
}

void main() {
  final asOf = DateTime(2026, 1, 7, 10, 0);

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

  group('SessionAnalyticsWidget - Basic rendering', () {
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
  });

  group('SessionAnalyticsWidget - Chart', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
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

    testWidgets('bar height varies based on session count', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf),
        buildSession(id: '2', start: asOf),
        buildSession(id: '3', start: asOf),
        buildSession(id: '4', start: asOf),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: asOf,
        ),
      ));

      expect(find.text('4'), findsAtLeastNWidgets(1));
    });

    testWidgets('handles single session correctly', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: asOf,
        ),
      ));

      expect(find.text('1'), findsAtLeastNWidgets(1));
      expect(find.text('1h 0m 0s'), findsAtLeastNWidgets(1));
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

    testWidgets('TweenAnimationBuilder animates bar height', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: asOf,
        ),
      ));

      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);
    });

    testWidgets('bar chart shows empty state bars with low opacity', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      final zeroCountBars = find.text('0');
      expect(zeroCountBars, findsAtLeastNWidgets(7));
    });
  });

  group('SessionAnalyticsWidget - Metric cards', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
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

    testWidgets('shows dash for avg session when no sessions', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('shows zero seconds for total time when empty', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.text('0s'), findsOneWidget);
    });

    testWidgets('calculates correct total time with multiple sessions', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
        buildSession(id: '2', start: asOf, timeSpentMs: 1800000),
        buildSession(id: '3', start: asOf, timeSpentMs: 900000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 0,
          asOf: asOf,
        ),
      ));

      expect(find.text('1h 45m 0s'), findsOneWidget);
    });

    testWidgets('calculates correct avg time per session', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
        buildSession(id: '2', start: asOf, timeSpentMs: 1800000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 0,
          asOf: asOf,
        ),
      ));

      expect(find.text('45m 0s'), findsOneWidget);
    });

    testWidgets('displays streak with days suffix', (tester) async {
      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: const [],
          currentStreak: 10,
        ),
      ));

      expect(find.text('10 days'), findsOneWidget);
    });

    testWidgets('metric card contains Icon widget', (tester) async {
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

    testWidgets('metric card uses GradientContainer decoration', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.byType(GradientContainer), findsWidgets);
    });
  });

  group('SessionAnalyticsWidget - Theme variations', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders with light theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: Brightness.light),
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
    });

    testWidgets('renders with dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    });

    testWidgets('renders with custom primary color', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(primaryColor: Colors.purple),
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
    });
  });

  group('SessionAnalyticsWidget - Edge cases', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('handles very long session times', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 720000000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: asOf,
        ),
      ));

      expect(find.byType(SessionAnalyticsWidget), findsOneWidget);
    });

    testWidgets('handles many sessions', (tester) async {
      final sessions = List.generate(
        100,
        (i) => buildSession(id: '$i', start: asOf, timeSpentMs: 3600000),
      );

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: asOf,
        ),
      ));

      expect(find.text('100'), findsAtLeastNWidgets(1));
    });
  });

  group('SessionAnalyticsWidget - asOf parameter', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('uses asOf for chart calculations when provided', (tester) async {
      final customAsOf = DateTime(2026, 3, 15);
      final sessions = [
        buildSession(id: '1', start: customAsOf),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          asOf: customAsOf,
        ),
      ));

      for (var i = 0; i < 7; i++) {
        final day = DateFormat('E').format(customAsOf.subtract(Duration(days: i)));
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('defaults to DateTime.now() when asOf not provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.byType(SessionAnalyticsWidget), findsOneWidget);
    });
  });

  group('SessionAnalyticsWidget - Supports custom daysToShow window', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders correct number of days', (tester) async {
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
