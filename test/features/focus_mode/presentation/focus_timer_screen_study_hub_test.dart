import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, notificationServiceProvider, planAdapterProvider, SettingsController;
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/core/services/student_id_service.dart' show studentIdValueProvider;
import 'package:studyking/features/focus_mode/presentation/focus_timer_screen.dart';
import 'package:studyking/core/routes/app_router.dart' show AppRoutes;
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider, spacedRepetitionRepositoryProvider, questionRepositoryProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../../../helpers/navigator_observer_helper.dart';

// ── Fake SubjectRepository ──────────────────────────────────────────────

class _FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects;

  _FakeSubjectRepository(this._subjects);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(List.from(_subjects));
}

// ── Override Notifier for subjectsRepositoryProvider ───────────────────

class _TestSubjectsNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _TestSubjectsNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async {
    state = AsyncValue.data(repo);
    return repo;
  }
}

// ── Fake SpacedRepetitionRepository ────────────────────────────────────

class _FakeSpacedRepetitionRepo extends SpacedRepetitionRepository {
  final List<Question> _dueQuestions;
  _FakeSpacedRepetitionRepo(this._dueQuestions);

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success(List.from(_dueQuestions));
  }
}

// ── Fake MasteryGraphService ───────────────────────────────────────────

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> _weakTopics;
  _FakeMasteryGraphService(this._weakTopics);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(List.from(_weakTopics));
  }
}

// ── Fake QuestionRepository ────────────────────────────────────────────

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(List.from(_questions));
}

// ── Fake PlanAdapter ───────────────────────────────────────────────────

class _FakePlanAdapter extends PlanAdapter {
  bool recordFromFocusSessionCalled = false;

  _FakePlanAdapter() : super();

  @override
  Future<void> recordFromFocusSession({
    required String studentId,
    required int actualMinutes,
    String? planId,
  }) async {
    recordFromFocusSessionCalled = true;
  }
}

// ── Fake SessionRepository ─────────────────────────────────────────────

class _FakeSessionRepo extends SessionRepository {
  @override
  Future<Result<void>> save(String key, Session session) async => Result.success(null);
  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);
  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async => Result.success({
    'totalMs': 0, 'totalSeconds': 0, 'completedSessions': 0, 'totalSessions': 0,
  });
}

// ── Fake StudyTimerService with daily cap support ──────────────────────

class _FakeStudyTimerService extends StudyTimerService {
  bool _hasActiveSession = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Session? _fakeCurrentSession;
  final List<void Function(Session)> _sessionCompleteCallbacks = [];
  final int _dailyCapMin;
  final int _remainingCap;

  _FakeStudyTimerService({
    int dailyCapMinutes = 0,
    int remainingCapMinutes = 0,
  }) : _dailyCapMin = dailyCapMinutes,
       _remainingCap = remainingCapMinutes,
       super(repository: _FakeSessionRepo());

  @override
  bool get hasActiveSession => _hasActiveSession;
  @override
  bool get isPaused => _isPaused;
  @override
  int get elapsedSeconds => _elapsedSeconds;
  @override
  Session? get currentSession => _fakeCurrentSession;

  @override
  void addOnSessionComplete(void Function(Session) callback) {
    _sessionCompleteCallbacks.add(callback);
  }

  @override
  void removeOnSessionComplete(void Function(Session) callback) {
    _sessionCompleteCallbacks.remove(callback);
  }

  @override
  Future<int> getDailyCapMinutes() async => _dailyCapMin;

  @override
  Future<int> getRemainingDailyCapMinutes() async => _remainingCap;

  @override
  Future<Map<String, dynamic>> getTodayStats() async => {
    'totalMs': 0, 'totalSeconds': 0, 'completedSessions': 0, 'totalSessions': 0,
  };

  @override
  Future<int> getTodayDurationMs() async => 0;

  @override
  Future<List<Session>> getRecentSessions({int limit = 10}) async => [];

  @override
  Future<Session> startSession({
    required int plannedDurationMinutes,
    SessionType type = SessionType.focus,
    String? studentId,
    String? subjectId,
    String? topicId,
  }) async {
    _hasActiveSession = true;
    _isPaused = false;
    _elapsedSeconds = 0;
    _fakeCurrentSession = Session(
      id: 'test_session',
      studentId: studentId ?? '',
      subjectId: subjectId,
      topicId: topicId,
      type: type,
      startTime: DateTime.now(),
      plannedDurationMinutes: plannedDurationMinutes,
    );
    return _fakeCurrentSession!;
  }

  @override
  void pauseSession() { _isPaused = true; }

  @override
  void resumeSession() { _isPaused = false; }

  @override
  Future<Result<Session>> completeSession() async {
    _hasActiveSession = false;
    _isPaused = false;
    _fakeCurrentSession = null;
    final session = Session(
      id: 'test_session', studentId: '', type: SessionType.focus,
      startTime: DateTime.now(), endTime: DateTime.now(),
      plannedDurationMinutes: 25, actualDurationMs: 1500000, completed: true,
    );
    for (final cb in _sessionCompleteCallbacks) { cb(session); }
    return Result.success(session);
  }

  @override
  Future<Result<Session>> cancelSession() async {
    _hasActiveSession = false;
    _isPaused = false;
    _fakeCurrentSession = null;
    return Result.success(Session(
      id: 'test_session', studentId: '', type: SessionType.focus,
      startTime: DateTime.now(), endTime: DateTime.now(),
      plannedDurationMinutes: 25, actualDurationMs: 0, completed: false,
    ));
  }

  @override
  Future<void> dispose() async {}
}

// ── Fake SettingsRepository ────────────────────────────────────────────

class _FakeSettingsRepo extends SettingsRepository {
  final SettingsBox _settings;
  _FakeSettingsRepo(this._settings);

  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

  @override
  Future<Result<void>> updateSettings({
    String? apiKey, String? apiBaseUrl, String? selectedModel,
    ThemeMode? themeMode, double? fontSize, bool? studyRemindersEnabled,
    int? requestTimeoutSeconds, int? sessionDurationMinutes,
    bool? highContrastEnabled, bool? largeTouchTargets, bool? reduceMotion,
    bool? revisionRemindersEnabled, bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled, bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds, int? dailyReminderHour, int? dailyReminderMinute,
    bool? firstFocusVisit, bool? dailyReminderEnabled,
  }) async => Result.success(null);
}

// ── Factories ──────────────────────────────────────────────────────────

final _now = DateTime.now();

Question _makeQuestion({required String id, required String subjectId, required String topicId}) {
  return Question(
    id: id, text: 'Question $id', type: QuestionType.singleChoice,
    subjectId: subjectId, topicId: topicId, createdAt: _now, updatedAt: _now,
  );
}

MasteryState _makeWeakState({required String topicId}) {
  return MasteryState(
    studentId: 'test-student', topicId: topicId,
    lastAttempt: _now, lastUpdated: _now,
  );
}

Widget _buildApp({
  required Widget child,
  required SubjectRepository subjectRepo,
  SpacedRepetitionRepository? srRepo,
  MasteryGraphService? masteryGraphService,
  QuestionRepository? questionRepo,
  PlanAdapter? planAdapter,
  StudyTimerService? timerService,
  SettingsBox? settings,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(_FakeSessionRepo()),
      studyTimerServiceProvider.overrideWithValue(timerService ?? _FakeStudyTimerService()),
      subjectsRepositoryProvider.overrideWith(() => _TestSubjectsNotifier(subjectRepo)),
      spacedRepetitionRepositoryProvider.overrideWithValue(srRepo ?? _FakeSpacedRepetitionRepo([])),
      questionRepositoryProvider.overrideWithValue(questionRepo ?? _FakeQuestionRepository([])),
      studentIdValueProvider.overrideWithValue('test-student'),
      planAdapterProvider.overrideWithValue(planAdapter ?? _FakePlanAdapter()),
      settingsProvider.overrideWith((ref) => SettingsController(_FakeSettingsRepo(settings ?? SettingsBox()))),
      notificationServiceProvider.overrideWithValue(NotificationService()),
      if (masteryGraphService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryGraphService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.subjectSelection || settings.name == AppRoutes.practiceSession) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Routed')),
            settings: settings,
          );
        }
        return null;
      },
      home: child,
    ),
  );
}

Future<void> pumpScreen(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(app);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async => '/tmp/test';
}

void main() {
  setUp(() async {
    _now;
    PathProviderPlatform.instance = _FakePathProvider();
    Hive.init('/tmp/test_hive');
  });

  tearDown(() async {
    Hive.close();
  });

  group('FocusTimerScreen - Study Hub & Mode Toggle', () {
    testWidgets('shows study hub mode by default with mode toggle', (tester) async {
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
      ));

      expect(find.text('Practice'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('displays no subjects state in study hub', (tester) async {
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
      ));

      expect(find.text('No subjects yet'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
    });

    testWidgets('add subject button navigates to subject selection', (tester) async {
      final observer = TestNavigatorObserver();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
        navigatorObserver: observer,
      ));

      await tester.tap(find.text('Add Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('mode toggle switches to focus timer mode', (tester) async {
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('mode toggle switches back to study hub', (tester) async {
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('New Focus Session'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No subjects yet'), findsOneWidget);
    });

    testWidgets('mode toggle is disabled during active session', (tester) async {
      final timerService = _FakeStudyTimerService();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
        timerService: timerService,
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('mode toggle is disabled during break', (tester) async {
      final timerService = _FakeStudyTimerService();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
        timerService: timerService,
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('shows subject cards when subjects are loaded', (tester) async {
      final subjects = [
        Subject(id: 's1', name: 'Mathematics'),
        Subject(id: 's2', name: 'Physics'),
      ];
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
      ));

      expect(find.text('Your Subjects'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('shows due question count total', (tester) async {
      final subjects = [Subject(id: 's1', name: 'Math')];
      final srRepo = _FakeSpacedRepetitionRepo([
        _makeQuestion(id: 'q1', subjectId: 's1', topicId: 't1'),
      ]);
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
        srRepo: srRepo,
      ));

      expect(find.text('Due for Review'), findsOneWidget);
    });

    testWidgets('stat items show subject count', (tester) async {
      final subjects = [
        Subject(id: 's1', name: 'Math'),
        Subject(id: 's2', name: 'Physics'),
      ];
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
      ));

      expect(find.text('2'), findsAtLeast(1));
    });

    testWidgets('spaced repetition button is disabled when no subjects or due questions', (tester) async {
      final subjects = [Subject(id: 's1', name: 'Math')];
      final srRepo = _FakeSpacedRepetitionRepo([]);
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
        srRepo: srRepo,
      ));

      final srButton = find.text('Spaced Repetition');
      expect(srButton, findsOneWidget);

      final outlinedButton = find.ancestor(
        of: srButton,
        matching: find.byType(OutlinedButton),
      ).first;
      final button = tester.widget<OutlinedButton>(outlinedButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('weak areas button shows no areas snackbar when empty', (tester) async {
      final subjects = [Subject(id: 's1', name: 'Math')];
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
        masteryGraphService: _FakeMasteryGraphService([]),
      ));

      await tester.tap(find.text('Weak Areas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No weak areas found. Keep up the great work!'), findsOneWidget);
    });

    testWidgets('weak areas shows no questions snackbar when weak topics have no questions', (tester) async {
      final subjects = [Subject(id: 's1', name: 'Math')];
      final masteryGraph = _FakeMasteryGraphService([
        _makeWeakState(topicId: 't1'),
      ]);
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
        masteryGraphService: masteryGraph,
      ));

      await tester.tap(find.text('Weak Areas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No questions available for your weak areas.'), findsOneWidget);
    });

    testWidgets('weak areas button navigates when weak questions found', (tester) async {
      final subjects = [Subject(id: 's1', name: 'Math')];
      final masteryGraph = _FakeMasteryGraphService([
        _makeWeakState(topicId: 't1'),
      ]);
      final questionRepo = _FakeQuestionRepository([
        _makeQuestion(id: 'q1', subjectId: 's1', topicId: 't1'),
      ]);
      final observer = TestNavigatorObserver();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
        masteryGraphService: masteryGraph,
        questionRepo: questionRepo,
        navigatorObserver: observer,
      ));

      await tester.tap(find.text('Weak Areas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('quick practice navigates to practice session', (tester) async {
      final subjects = [Subject(id: 's1', name: 'Math')];
      final observer = TestNavigatorObserver();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
        navigatorObserver: observer,
      ));

      await tester.tap(find.text('Math'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(2));
    });
  });

  group('FocusTimerScreen - Daily Cap', () {
    testWidgets('shows daily cap warning with cancel and continue', (tester) async {
      final timerService = _FakeStudyTimerService(
        dailyCapMinutes: 120,
        remainingCapMinutes: 10,
      );
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
        timerService: timerService,
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Daily Cap Warning'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Continue Anyway'), findsOneWidget);

      // Cancel stays on setup
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Focus for 25 minutes'), findsOneWidget);
      expect(timerService.hasActiveSession, isFalse);
    });

    testWidgets('daily cap continue anyway starts session', (tester) async {
      final timerService = _FakeStudyTimerService(
        dailyCapMinutes: 120,
        remainingCapMinutes: 10,
      );
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
        timerService: timerService,
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Continue Anyway'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FocusTimerWidget), findsOneWidget);
      expect(timerService.hasActiveSession, isTrue);
    });
  });

  group('FocusTimerScreen - Subject Picker', () {
    testWidgets('shows subject picker dropdown when subjects loaded', (tester) async {
      final subjects = [
        Subject(id: 's1', name: 'Math'),
        Subject(id: 's2', name: 'Physics'),
      ];
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository(subjects),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Select Subject'), findsOneWidget);
    });

    testWidgets('shows hint text when no subjects', (tester) async {
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add subjects in Settings to track focus by subject.'), findsOneWidget);
    });
  });

  group('FocusTimerScreen - Preselected Parameters', () {
    testWidgets('preselectedSubjectId is passed to session start', (tester) async {
      final timerService = _FakeStudyTimerService();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(preselectedSubjectId: 'subj-1'),
        subjectRepo: _FakeSubjectRepository([]),
        timerService: timerService,
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(timerService.currentSession?.subjectId, 'subj-1');
    });
  });

  group('FocusTimerScreen - Break View', () {
    testWidgets('break view appears after session complete', (tester) async {
      final timerService = _FakeStudyTimerService();
      await pumpScreen(tester, _buildApp(
        child: const FocusTimerScreen(),
        subjectRepo: _FakeSubjectRepository([]),
        timerService: timerService,
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Break Time!'), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    });
  });
}
