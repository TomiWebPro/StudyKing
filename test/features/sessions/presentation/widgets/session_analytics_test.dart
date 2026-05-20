import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/data/models/session_model.dart';
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

  Session buildSession({
    required String id,
    required DateTime start,
    int timeSpentMs = 0,
  }) {
    return Session(
      id: id,
      studentId: 'student-1',
      subjectId: 'math',
      type: SessionType.practice,
      startTime: start,
      actualDurationMs: timeSpentMs,
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
        final day = DateFormat('E', 'en').format(asOf.subtract(Duration(days: i)));
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

      expect(find.byType(AnimatedBarChart), findsOneWidget);
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

    testWidgets('bar chart shows bars for all days even without sessions', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      expect(find.byType(AnimatedBarChart), findsOneWidget);
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
        final day = DateFormat('E', 'en').format(customAsOf.subtract(Duration(days: i)));
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
        final day = DateFormat('E', 'en').format(asOf.subtract(Duration(days: i)));
        expect(find.byKey(ValueKey('bar_$day')), findsOneWidget);
      }
    });
  });

  group('SessionAnalyticsWidget - reduceMotion', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('uses Container bars when reduceMotion is true', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
          reduceMotion: true,
        ),
      ));
      await tester.pump();

      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    });

    testWidgets('sessions outside daysToShow window are excluded from counts', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf.subtract(const Duration(days: 10))),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          daysToShow: 7,
          asOf: asOf,
        ),
      ));
      await tester.pump();

      for (var i = 0; i < 7; i++) {
        final day = DateFormat('E', 'en').format(asOf.subtract(Duration(days: i)));
        expect(find.byKey(ValueKey('bar_$day')), findsOneWidget);
      }
    });

    testWidgets('renders chart data correctly with reduceMotion and sessions', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
        buildSession(id: '2', start: asOf.subtract(const Duration(days: 1)), timeSpentMs: 1800000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 2,
          asOf: asOf,
          reduceMotion: true,
        ),
      ));
      await tester.pump();

      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(find.byType(SessionAnalyticsWidget), findsOneWidget);
    });
  });

  group('SessionAnalyticsWidget - Localization', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders day names in Spanish with es locale', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: SizedBox(
            height: 1200,
            child: SessionAnalyticsWidget(
              sessions: [],
              currentStreak: 0,
              asOf: asOf,
            ),
          ),
        ),
      ));

      for (var i = 0; i < 7; i++) {
        final day = DateFormat('E', 'es').format(asOf.subtract(Duration(days: i)));
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('renders metric card labels in Spanish', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
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

      expect(find.text('Sesión Prom.'), findsOneWidget);
      expect(find.text('Sesiones Totales'), findsOneWidget);
      expect(find.text('Racha Actual'), findsOneWidget);
      expect(find.text('Tiempo Total'), findsOneWidget);
    });
  });

  group('SessionAnalyticsWidget - daysToShow window boundaries', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders single day with daysToShow=1', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 1,
          daysToShow: 1,
          asOf: asOf,
        ),
      ));

      final day = DateFormat('E', 'en').format(asOf);
      expect(find.byKey(ValueKey('bar_$day')), findsOneWidget);
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders large window with daysToShow=30', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 3600000),
        buildSession(id: '2', start: asOf.subtract(const Duration(days: 15)), timeSpentMs: 1800000),
        buildSession(id: '3', start: asOf.subtract(const Duration(days: 29)), timeSpentMs: 900000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 3,
          daysToShow: 30,
          asOf: asOf,
        ),
      ));

      for (var i = 0; i < 30; i++) {
        final day = DateFormat('E', 'en').format(asOf.subtract(Duration(days: i)));
        expect(find.byKey(ValueKey('bar_$day')), findsOneWidget);
      }
    });

    testWidgets('handles daysToShow=1 with no sessions', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
          daysToShow: 1,
        ),
      ));

      expect(find.byType(AnimatedBarChart), findsOneWidget);
    });
  });

  group('SessionAnalyticsWidget - Zero duration edge cases', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('handles sessions with zero actualDurationMs', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 0),
        buildSession(id: '2', start: asOf, timeSpentMs: 0),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 0,
          asOf: asOf,
        ),
      ));

      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('0s'), findsAtLeastNWidgets(1));
    });
  });

  group('SessionAnalyticsWidget - bodySmallColor fallback', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('falls back to grey when bodySmall color is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light().copyWith(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
            bodySmall: TextStyle(),
            titleLarge: TextStyle(color: Colors.black),
            titleSmall: TextStyle(color: Colors.black),
            displayLarge: TextStyle(color: Colors.black),
            labelSmall: TextStyle(color: Colors.black),
          ),
        ),
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

      final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_month));
      expect(icon.color, Colors.grey);
    });

    testWidgets('uses bodySmall color when available', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light().copyWith(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
            bodySmall: TextStyle(color: Colors.deepPurple),
            titleLarge: TextStyle(color: Colors.black),
            titleSmall: TextStyle(color: Colors.black),
            displayLarge: TextStyle(color: Colors.black),
            labelSmall: TextStyle(color: Colors.black),
          ),
        ),
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

      final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_month));
      expect(icon.color, Colors.deepPurple);
    });
  });

  group('SessionAnalyticsWidget - MetricCard properties', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('four MetricCards with correct labels and values', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      final cards = tester.widgetList<MetricCard>(find.byType(MetricCard)).toList();
      expect(cards.length, 4);
      expect(cards[0].label, 'Avg Session');
      expect(cards[0].value, '\u2014');
      expect(cards[1].label, 'Total Sessions');
      expect(cards[1].value, '0');
      expect(cards[2].label, 'Current Streak');
      expect(cards[2].value, '0 days');
      expect(cards[3].label, 'Total Time');
      expect(cards[3].value, '0s');
    });

    testWidgets('correct MetricCard values with session data', (tester) async {
      final sessions = [
        buildSession(id: '1', start: asOf, timeSpentMs: 7200000),
        buildSession(id: '2', start: asOf, timeSpentMs: 3600000),
      ];

      await tester.pumpWidget(buildTestApp(
        SessionAnalyticsWidget(
          sessions: sessions,
          currentStreak: 5,
          asOf: asOf,
        ),
      ));

      final cards = tester.widgetList<MetricCard>(find.byType(MetricCard)).toList();
      expect(cards[0].value, '1h 30m 0s');
      expect(cards[1].value, '2');
      expect(cards[2].value, '5 days');
      expect(cards[3].value, '3h 0m 0s');
    });

    testWidgets('MetricCards receive distinct non-transparent accent colors', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SessionAnalyticsWidget(
          sessions: [],
          currentStreak: 0,
        ),
      ));

      final cards = tester.widgetList<MetricCard>(find.byType(MetricCard)).toList();
      expect(cards.length, 4);
      for (final card in cards) {
        expect(card.accent, isNot(equals(Colors.transparent)));
      }
      expect(cards[0].accent, isNot(equals(cards[1].accent)));
      expect(cards[1].accent, isNot(equals(cards[2].accent)));
      expect(cards[2].accent, isNot(equals(cards[3].accent)));
    });
  });
}
