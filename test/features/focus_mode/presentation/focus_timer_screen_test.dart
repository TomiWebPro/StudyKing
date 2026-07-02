import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/focus_mode/presentation/focus_timer_screen.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart' show focusSessionRepositoryProvider, studyTimerServiceProvider;
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show badgeServiceProvider;
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

final _today = DateTime.now();

class _FakeSubjectRepo extends SubjectRepository {
  @override
  Future<Result<List<Subject>>> getAll() async => Result.success([]);
}

class _TestSubjectsNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _TestSubjectsNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async {
    state = AsyncValue.data(repo);
    return repo;
  }
}
final _todayStart = DateTime(_today.year, _today.month, _today.day);

class FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions = [];

  @override
  Future<Result<void>> save(String key, Session session) async {
    _sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(List.from(_sessions));

  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async => Result.success({
    'totalMs': 0,
    'totalSeconds': 0,
    'completedSessions': 0,
    'totalSessions': 0,
    'plannedMinutes': 0,
    'hours': '0.0',
  });
}

class FakeStudyTimerService extends StudyTimerService {
  bool _hasActiveSession = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Session? _fakeCurrentSession;
  final List<void Function(Session)> _sessionCompleteCallbacks = [];

  FakeStudyTimerService() : super(repository: FakeSessionRepository());

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
  Future<Result<bool>> isDailyCapReached(int additionalMinutes) async => Result.success(false);

  @override
  Future<Result<int>> getDailyCapMinutes() async => Result.success(0);

  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async => Result.success({
    'totalMs': 0,
    'totalSeconds': 0,
    'completedSessions': 0,
    'totalSessions': 0,
    'plannedMinutes': 0,
    'hours': '0.0',
  });

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(0);

  @override
  Future<Result<List<Session>>> getRecentSessions({int limit = 10}) async => Result.success([]);

  @override
  Future<Result<Session>> startSession({
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
    return Result.success(_fakeCurrentSession!);
  }

  @override
  Result<void> pauseSession() {
    _isPaused = true;
    return Result.success(null);
  }

  @override
  Result<void> resumeSession() {
    _isPaused = false;
    return Result.success(null);
  }

  @override
  Future<Result<Session>> completeSession() async {
    _hasActiveSession = false;
    _isPaused = false;
    _fakeCurrentSession = null;
    final session = Session(
      id: 'test_session',
      studentId: '',
      type: SessionType.focus,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      plannedDurationMinutes: 25,
      actualDurationMs: 1500000,
      completed: true,
    );
    for (final cb in _sessionCompleteCallbacks) {
      cb(session);
    }
    return Result.success(session);
  }

  @override
  Future<Result<Session>> cancelSession() async {
    _hasActiveSession = false;
    _isPaused = false;
    _fakeCurrentSession = null;
    return Result.success(Session(
      id: 'test_session',
      studentId: '',
      type: SessionType.focus,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      plannedDurationMinutes: 25,
      actualDurationMs: 0,
      completed: false,
    ));
  }

  @override
  Future<Result<void>> dispose() async => Result.success(null);
}

class _FakeCapReachedService extends FakeStudyTimerService {
  @override
  Future<Result<bool>> isDailyCapReached(int additionalMinutes) async => Result.success(true);
}

class _FakeStartErrorService extends FakeStudyTimerService {
  @override
  Future<Result<Session>> startSession({
    required int plannedDurationMinutes,
    SessionType type = SessionType.focus,
    String? studentId,
    String? subjectId,
    String? topicId,
  }) async {
    return Result.failure('Start failed');
  }
}

class _FakeStatsService extends FakeStudyTimerService {
  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    return Result.success({
      'totalMs': 3600000,
      'totalSeconds': 3600,
      'completedSessions': 2,
      'totalSessions': 3,
      'plannedMinutes': 75,
      'hours': '1.0',
    });
  }

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(7200000);

  @override
  Future<Result<List<Session>>> getRecentSessions({int limit = 10}) async {
    return Result.success([
      Session(
        id: 's1',
        studentId: '',
        subjectId: null,
        type: SessionType.focus,
        startTime: _todayStart.add(const Duration(hours: 9)),
        endTime: _todayStart.add(const Duration(hours: 9, minutes: 25)),
        plannedDurationMinutes: 25,
        actualDurationMs: 1500000,
        completed: true,
        questionsAnswered: 0,
        correctAnswers: 0,
      ),
      Session(
        id: 's2',
        studentId: '',
        subjectId: null,
        type: SessionType.focus,
        startTime: _todayStart.add(const Duration(hours: 11)),
        endTime: _todayStart.add(const Duration(hours: 11, minutes: 20)),
        plannedDurationMinutes: 30,
        actualDurationMs: 1200000,
        completed: true,
        questionsAnswered: 0,
        correctAnswers: 0,
      ),
      Session(
        id: 's3',
        studentId: '',
        subjectId: null,
        type: SessionType.focus,
        startTime: _todayStart.add(const Duration(hours: 14)),
        endTime: _todayStart.add(const Duration(hours: 14, minutes: 5)),
        plannedDurationMinutes: 25,
        actualDurationMs: 300000,
        completed: false,
        questionsAnswered: 0,
        correctAnswers: 0,
      ),
    ]);
  }
}

class _FakeBadgeService extends BadgeService {
  _FakeBadgeService() : super();

  @override
  Future<Result<List<BadgeModel>>> checkAndUnlockBadges(String studentId) async {
    return Result.success([]);
  }
}

class _FakeFocusSessionRepo extends FocusSessionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<FocusSession?>> getLatest() async => Result.success(null);

  @override
  Future<Result<void>> save(FocusSession session) async {
    return Result.success(null);
  }
}

Widget _wrapApp(Widget widget, {StudyTimerService? serviceOverride, TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      if (serviceOverride != null)
        studyTimerServiceProvider.overrideWithValue(serviceOverride)
      else
        studyTimerServiceProvider.overrideWithValue(FakeStudyTimerService()),
      subjectsRepositoryProvider.overrideWith(() => _TestSubjectsNotifier(_FakeSubjectRepo())),
      focusSessionRepositoryProvider.overrideWithValue(_FakeFocusSessionRepo()),
      badgeServiceProvider.overrideWithValue(_FakeBadgeService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: widget,
    ),
  );
}

Widget _buildTestApp(Widget widget, {TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      studyTimerServiceProvider.overrideWithValue(FakeStudyTimerService()),
      subjectsRepositoryProvider.overrideWith(() => _TestSubjectsNotifier(_FakeSubjectRepo())),
      focusSessionRepositoryProvider.overrideWithValue(_FakeFocusSessionRepo()),
      badgeServiceProvider.overrideWithValue(_FakeBadgeService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: widget,
    ),
  );
}

Future<void> _pumpAndSwitchToTimer(WidgetTester tester, Widget widget, {TestNavigatorObserver? navigatorObserver}) async {
  await tester.pumpWidget(_buildTestApp(widget, navigatorObserver: navigatorObserver));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  // The screen defaults to study hub mode; switch to timer mode
  await tester.tap(find.byType(Switch));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('FocusTimerScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Focus Mode'), findsOneWidget);
    });

    testWidgets('shows setup view after initialization', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('shows duration preset chips', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.text('5m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('60m'), findsOneWidget);
    });

    testWidgets('shows focus button with default duration', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.text('Focus for 25 minutes'), findsOneWidget);
    });

    testWidgets('changes selected duration when chip is tapped', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('45m'));
      await tester.pump();

      expect(find.text('Focus for 45 minutes'), findsOneWidget);
    });

    testWidgets('shows SessionSummaryCard', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('shows refresh button in app bar', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('accepts preselectedSubjectId parameter', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen(preselectedSubjectId: 'subj-1'));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('accepts preselectedTopicId parameter', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen(preselectedTopicId: 'topic-1'));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('accepts defaultDurationMinutes parameter', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen(defaultDurationMinutes: 45));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('25min chip is selected by default', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('25m'),
          matching: find.byType(ChoiceChip),
        ).first,
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('non-default chips are not selected', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      final chip5 = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('5m'),
          matching: find.byType(ChoiceChip),
        ).first,
      );
      expect(chip5.selected, isFalse);
    });

    testWidgets('setup to active session flow renders correctly', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.text('New Focus Session'), findsOneWidget);

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('pauses and resumes session correctly', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Pause'));
      await tester.pump();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();

      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets('completes session and shows break view', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FocusTimerWidget), findsOneWidget);

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Break Time!'), findsOneWidget);
    });

    testWidgets('break view shows icons and session info', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();

      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      expect(find.text('Break Time!'), findsOneWidget);
      expect(find.text('Session completed: 25m'), findsOneWidget);
    });

    testWidgets('break timer countdown updates after each tick', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();

      final timerFinder = find.byWidgetPredicate(
        (w) => w is Text && w.data?.contains(':') == true && w.data!.length == 5,
      );
      expect(timerFinder, findsOneWidget);

      final before = tester.widget<Text>(timerFinder).data!;
      await tester.pump(const Duration(seconds: 5));
      final after = tester.widget<Text>(timerFinder).data!;
      expect(after, isNot(equals(before)));
    });

    testWidgets('break ends and returns to setup after timer expires', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();

      expect(find.text('Break Time!'), findsOneWidget);

      for (int i = 0; i < 305; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();

      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.text('Break Time!'), findsNothing);
    });

    testWidgets('shows exit confirmation dialog when back is pressed during active session', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pause'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('End focus session?'), findsOneWidget);
      expect(find.text('You have an active focus session. Ending it early will save your progress so far.'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);
    });

    testWidgets('stay button keeps session active', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Stay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets('end session button cancels session and returns to setup', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('End Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.byType(FocusTimerWidget), findsNothing);
    });

    testWidgets('cancel session returns to setup view', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.text('End'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.byType(FocusTimerWidget), findsNothing);
    });

    testWidgets('shows daily cap dialog when cap reached', (tester) async {
      final capService = _FakeCapReachedService();
      await tester.pumpWidget(_wrapApp(
        const FocusTimerScreen(),
        serviceOverride: capService,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Daily Limit Reached'), findsOneWidget);
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Daily Limit Reached'), findsNothing);
    });

    testWidgets('shows error snackbar when start fails', (tester) async {
      final errorService = _FakeStartErrorService();
      await tester.pumpWidget(_wrapApp(
        const FocusTimerScreen(),
        serviceOverride: errorService,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('shows slider on tablet width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 800)),
          child: _buildTestApp(const FocusTimerScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('hides slider on mobile width', (tester) async {
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen());

      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('displays stats from service with data', (tester) async {
      final statsService = _FakeStatsService();
      await tester.pumpWidget(_wrapApp(
        const FocusTimerScreen(),
        serviceOverride: statsService,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1h 0m'), findsOneWidget);
      expect(find.text('2h 0m'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('Recent Sessions'), findsOneWidget);
    });

    testWidgets('navigator observes no pops initially', (tester) async {
      final observer = TestNavigatorObserver();
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen(), navigatorObserver: observer);

      expect(observer.poppedRoutes, isEmpty);
    });

    testWidgets('navigator pops via system back', (tester) async {
      final observer = TestNavigatorObserver();
      await _pumpAndSwitchToTimer(tester, const FocusTimerScreen(), navigatorObserver: observer);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, hasLength(1));
    });
  });
}
