import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/service_providers.dart' show studentIdServiceProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/sessions/presentation/session_tracker_screen.dart';
import 'package:studyking/features/sessions/presentation/widgets/session_analytics.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository({List<Session>? seed, this.throwOnSave = false})
      : sessions = List<Session>.from(seed ?? []);

  final List<Session> sessions;
  final bool throwOnSave;

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List<Session>.from(sessions));
  }

  @override
  Future<Result<void>> save(String key, Session session) async {
    if (throwOnSave) {
      throw Exception('save failed');
    }
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }
}

class _FakeSubjectRepository extends SubjectRepository {
  _FakeSubjectRepository({List<Subject>? subjects}) : _subjects = subjects ?? [];

  final List<Subject> _subjects;

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(List<Subject>.from(_subjects));

  @override
  Future<Result<void>> save(String key, Subject subject) async {
    _subjects.add(subject);
    return Result.success(null);
  }

  @override
  Future<Result<Subject?>> get(String id) async =>
      Result.success(_subjects.where((s) => s.id == id).firstOrNull);

  @override
  Future<Result<void>> delete(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    return Result.success(null);
  }

  Future<Result<void>> clearAll() async {
    _subjects.clear();
    return Result.success(null);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student';

  @override
  Future<void> init() async {}
}

class _FakeSettingsRepository extends SettingsRepository {
  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(SettingsBox());

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async => Result.success(null);

  @override
  Future<Result<SettingsBox>> updateStats({int? sessionCount, int? studyTimeMs, int? questions}) async =>
      Result.success(SettingsBox());

  @override
  Future<Result<void>> saveApiKey({required String service, required String key}) async =>
      Result.success(null);
}

Widget _buildTestApp(_FakeSessionRepository repository, {TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsController(_FakeSettingsRepository())),
      subjectRepositoryProvider.overrideWithValue(_FakeSubjectRepository()),
      studentIdServiceProvider.overrideWithValue(_FakeStudentIdService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: SessionTrackerScreen(sessionRepository: repository, fixedStudentId: 'test-student'),
      routes: {
        '/session-history': (_) => const Scaffold(body: Center(child: Text('Session History'))),
      },
    ),
  );
}

void main() {
  late String hivePath;

  setUpAll(() async {
    hivePath = (await Directory.systemTemp.createTemp('tracker_test_')).path;
    Hive.init(hivePath);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  group('SessionTrackerScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state after repository load', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Study Session Tracker'), findsOneWidget);
      expect(find.text('No Active Session'), findsOneWidget);
      expect(find.text('Tap start to begin tracking'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('loads sessions and shows recent entries', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 'a',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now.subtract(const Duration(hours: 2)),
          actualDurationMs: 1800000,
        ),
        Session(
          id: 'b',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now.subtract(const Duration(hours: 1)),
          actualDurationMs: 3600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
    });

    testWidgets('renders analytics and actions in default state', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0s'), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('Recent Sessions'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
      expect(find.text('Start your first session!'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('start button begins tracking session', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      expect(find.text('Current Session'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'End'), findsOneWidget);
    });

    testWidgets('end button shows session complete dialog', (tester) async {
      final repo = _FakeSessionRepository();
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
      final repo = _FakeSessionRepository();
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

      expect(repo.sessions.length, 1);
      expect(repo.sessions.single.questionsAnswered, 12);
      expect(repo.sessions.single.correctAnswers, 9);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SessionAnalyticsWidget), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
    });

    testWidgets('shows snackbar when save fails', (tester) async {
      final repo = _FakeSessionRepository(throwOnSave: true);
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
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsController(_FakeSettingsRepository())),
          subjectRepositoryProvider.overrideWithValue(_FakeSubjectRepository()),
          studentIdServiceProvider.overrideWithValue(_FakeStudentIdService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: SessionTrackerScreen(sessionRepository: repo, fixedStudentId: 'test-student'),
          routes: {
            '/session-history': (_) => const Scaffold(body: Center(child: Text('Session History'))),
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'View All'));
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('navigator pushes session history on view all tap', (tester) async {
      final observer = TestNavigatorObserver();
      final repo = _FakeSessionRepository();

      await tester.pumpWidget(_buildTestApp(repo, navigatorObserver: observer));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'View All'));
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.any((r) => r.settings.name == '/session-history'),
        isTrue,
      );
    });

    testWidgets('navigator pops history on system back', (tester) async {
      final observer = TestNavigatorObserver();
      final repo = _FakeSessionRepository();

      await tester.pumpWidget(_buildTestApp(repo, navigatorObserver: observer));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'View All'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, hasLength(1));
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
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 'a', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
        ),
        Session(
          id: 'b', studentId: 'u1', subjectId: 'science',
          startTime: now.subtract(const Duration(days: 1)), actualDurationMs: 600000,
        ),
        Session(
          id: 'c', studentId: 'u1', subjectId: 'math',
          startTime: now.subtract(const Duration(days: 2)), actualDurationMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('3 days'), findsOneWidget);
    });

    testWidgets('calculates streak of 1 when only today has sessions', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 'a', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('1 day'), findsOneWidget);
    });

    testWidgets('calculates streak of 0 when no sessions exist', (tester) async {
      final repo = _FakeSessionRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0 days'), findsOneWidget);
    });

    testWidgets('breaks streak when a day is skipped', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 'a', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
        ),
        Session(
          id: 'b', studentId: 'u1', subjectId: 'science',
          startTime: now.subtract(const Duration(days: 2)), actualDurationMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('1 day'), findsOneWidget);
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
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(repo.sessions.length, 1);
      expect(repo.sessions.single.questionsAnswered, 0);
      expect(repo.sessions.single.correctAnswers, 0);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
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
      final repo = _FakeSessionRepository();
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
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes without error while tracking session', (tester) async {
      final repo = _FakeSessionRepository();
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
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo.sessions.length, 1);
      await tester.pump();
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
    });
  });

  group('SessionTrackerScreen - Invalid dialog input', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows validation error for non-numeric input', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Questions Answered'), 'abc');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo.sessions.length, 0);
      expect(find.text('Session Complete'), findsOneWidget);
    });

    testWidgets('valid input saves session correctly', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Questions Answered'), '5');
      await tester.enterText(find.widgetWithText(TextField, 'Correct Answers'), '3');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo.sessions.length, 1);
      expect(repo.sessions.single.questionsAnswered, 5);
      expect(repo.sessions.single.correctAnswers, 3);
      await tester.pump();
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
    });
  });

  group('Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup for keyboard navigation', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('all interactive elements are reachable', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'View All'), findsOneWidget);
      expect(find.byType(SessionAnalyticsWidget), findsOneWidget);
    });
  });
}
