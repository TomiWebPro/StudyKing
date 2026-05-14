import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/features/sessions/presentation/session_tracker_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeStudySessionRepository extends StudySessionRepository {
  _FakeStudySessionRepository({List<StudySession>? seed, this.throwOnInit = false, this.throwOnCreate = false})
      : _sessions = List<StudySession>.from(seed ?? []);

  final List<StudySession> _sessions;
  final bool throwOnInit;
  final bool throwOnCreate;

  @override
  Future<void> init() async {
    if (throwOnInit) throw Exception('init failed');
  }

  @override
  Future<List<StudySession>> getAll() async => List<StudySession>.from(_sessions);

  @override
  Future<void> create(StudySession session) async {
    if (throwOnCreate) {
      throw Exception('save failed');
    }
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(session);
  }
}

Widget _buildTestAppWithRoutes(_FakeStudySessionRepository repository, {String? historyRoute}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: SessionTrackerScreen(sessionRepository: repository),
    routes: {
      '/session-history': (_) => Scaffold(
        body: Center(child: Text(historyRoute ?? 'Session History')),
      ),
    },
  );
}

Widget _buildTestApp(_FakeStudySessionRepository repository) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SessionTrackerScreen(sessionRepository: repository),
  );
}

void main() {
  group('SessionTrackerScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state after repository load', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Study Session Tracker'), findsOneWidget);
      expect(find.text('No Active Session'), findsOneWidget);
      expect(find.text('Tap start to begin tracking'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('loads sessions and shows recent entries', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 'a',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now.subtract(const Duration(hours: 2)),
          timeSpentMs: 1800000,
        ),
        StudySession(
          id: 'b',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now.subtract(const Duration(hours: 1)),
          timeSpentMs: 3600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
    });

    testWidgets('renders analytics and actions in default state', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0s'), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('Recent Sessions'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
      expect(find.text('Start your first session!'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('start button begins tracking session', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      expect(find.text('Current Session'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'End'), findsOneWidget);
    });

    testWidgets('end button shows session complete dialog', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      expect(find.text('Session Complete'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Questions Answered'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Correct Answers'), findsOneWidget);
    });

    testWidgets('start and end session saves entered stats', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Current Session'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'End'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      expect(find.text('Session Complete'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Questions Answered'), '12');
      await tester.enterText(find.widgetWithText(TextField, 'Correct Answers'), '9');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo._sessions.length, 1);
      expect(repo._sessions.single.questionsAnswered, 12);
      expect(repo._sessions.single.correctAnswers, 9);
      expect(find.text('No Active Session'), findsOneWidget);
    });

    testWidgets('shows snackbar when save fails', (tester) async {
      final repo = _FakeStudySessionRepository(throwOnCreate: true);
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to save session'), findsOneWidget);
    });

    testWidgets('view all navigates to history screen', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SessionTrackerScreen(sessionRepository: repo),
        routes: {
          '/session-history': (_) => const Scaffold(body: Center(child: Text('Session History'))),
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'View All'));
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
    });
  });

  group('SessionTrackerScreen - Streak calculation', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('calculates streak for consecutive days', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 'a', studentId: 'u1', subjectId: 'math',
          startTime: now, timeSpentMs: 600000,
        ),
        StudySession(
          id: 'b', studentId: 'u1', subjectId: 'science',
          startTime: now.subtract(const Duration(days: 1)), timeSpentMs: 600000,
        ),
        StudySession(
          id: 'c', studentId: 'u1', subjectId: 'math',
          startTime: now.subtract(const Duration(days: 2)), timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('3 days'), findsOneWidget);
    });

    testWidgets('calculates streak of 1 when only today has sessions', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 'a', studentId: 'u1', subjectId: 'math',
          startTime: now, timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('1 day'), findsOneWidget);
    });

    testWidgets('calculates streak of 0 when no sessions exist', (tester) async {
      final repo = _FakeStudySessionRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0 days'), findsOneWidget);
    });

    testWidgets('breaks streak when a day is skipped', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 'a', studentId: 'u1', subjectId: 'math',
          startTime: now, timeSpentMs: 600000,
        ),
        StudySession(
          id: 'b', studentId: 'u1', subjectId: 'science',
          startTime: now.subtract(const Duration(days: 2)), timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('1 day'), findsOneWidget);
    });
  });

  group('SessionTrackerScreen - Loading error', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('handles init error gracefully', (tester) async {
      final repo = _FakeStudySessionRepository(throwOnInit: true);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Study Session Tracker'), findsOneWidget);
    });
  });

  group('SessionTrackerScreen - End session skip', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('skip creates session with zero stats', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(repo._sessions.length, 1);
      expect(repo._sessions.single.questionsAnswered, 0);
      expect(repo._sessions.single.correctAnswers, 0);
      expect(find.text('No Active Session'), findsOneWidget);
    });
  });

  group('SessionTrackerScreen - Timer display', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows current session after start', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      expect(find.text('Current Session'), findsOneWidget);
      expect(find.text('No Active Session'), findsNothing);
    });
  });

  group('SessionTrackerScreen - Dispose', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('disposes without error', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes without error while tracking session', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('SessionTrackerScreen - Session end with plan errors', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('end session does not crash when plan/mastery services unavailable', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo._sessions.length, 1);
      expect(find.text('No Active Session'), findsOneWidget);
    });
  });
}