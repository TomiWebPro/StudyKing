import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/presentation/focus_timer_screen.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeFocusSessionRepository extends FocusSessionRepository {
  @override
  Future<void> init() async {}
}

class FakeFocusSessionService extends FocusSessionService {
  FakeFocusSessionService()
      : super(repository: FakeFocusSessionRepository());

  bool _hasActiveSession = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  FocusSession? _fakeCurrentSession;
  final List<void Function(FocusSession)> _sessionCompleteCallbacks = [];

  @override
  bool get hasActiveSession => _hasActiveSession;

  @override
  bool get isPaused => _isPaused;

  @override
  int get elapsedSeconds => _elapsedSeconds;

  @override
  FocusSession? get currentSession => _fakeCurrentSession;

  @override
  void addOnSessionComplete(void Function(FocusSession) callback) {
    _sessionCompleteCallbacks.add(callback);
  }

  @override
  void removeOnSessionComplete(void Function(FocusSession) callback) {
    _sessionCompleteCallbacks.remove(callback);
  }

  @override
  Future<bool> isDailyCapReached(int additionalMinutes) async => false;

  @override
  Future<int> getDailyCapMinutes() async => 0;

  @override
  Future<Map<String, dynamic>> getTodayStats() async => {
    'totalSeconds': 0,
    'completedSessions': 0,
    'totalSessions': 0,
    'plannedMinutes': 0,
    'hours': '0.0',
  };

  @override
  Future<int> getWeeklyFocusSeconds() async => 0;

  @override
  Future<List<FocusSession>> getRecentSessions({int limit = 10}) async => [];

  @override
  Future<FocusSession> startSession({
    required int plannedDurationMinutes,
    String? subjectId,
    String? topicId,
  }) async {
    _hasActiveSession = true;
    _isPaused = false;
    _elapsedSeconds = 0;
    _fakeCurrentSession = FocusSession(
      id: 'test_session',
      startTime: DateTime.now(),
      plannedDurationMinutes: plannedDurationMinutes,
    );
    return _fakeCurrentSession!;
  }

  @override
  void pauseSession() {
    _isPaused = true;
  }

  @override
  void resumeSession() {
    _isPaused = false;
  }

  @override
  Future<FocusSession> completeSession() async {
    _hasActiveSession = false;
    _isPaused = false;
    _fakeCurrentSession = null;
    final session = FocusSession(
      id: 'test_session',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      plannedDurationMinutes: 25,
      actualDurationSeconds: 1500,
      completed: true,
    );
    for (final cb in _sessionCompleteCallbacks) {
      cb(session);
    }
    return session;
  }

  @override
  Future<FocusSession> cancelSession() async {
    _hasActiveSession = false;
    _isPaused = false;
    _fakeCurrentSession = null;
    return FocusSession(
      id: 'test_session',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      plannedDurationMinutes: 25,
      actualDurationSeconds: 0,
      completed: false,
    );
  }

  @override
  Future<void> dispose() async {}
}

Widget _buildTestApp(Widget widget) {
  return ProviderScope(
    overrides: [
      focusSessionRepositoryProvider.overrideWithValue(FakeFocusSessionRepository()),
      focusSessionServiceProvider.overrideWithValue(FakeFocusSessionService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
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
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('shows duration preset chips', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('60m'), findsOneWidget);
    });

    testWidgets('shows focus button with default duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Focus for 25 minutes'), findsOneWidget);
    });

    testWidgets('changes selected duration when chip is tapped', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('45m'));
      await tester.pump();

      expect(find.text('Focus for 45 minutes'), findsOneWidget);
    });

    testWidgets('shows SessionSummaryCard', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('shows refresh button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('accepts preselectedSubjectId parameter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(preselectedSubjectId: 'subj-1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('accepts preselectedTopicId parameter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(preselectedTopicId: 'topic-1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('accepts defaultDurationMinutes parameter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(defaultDurationMinutes: 45),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('25min chip is selected by default', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('25m'),
          matching: find.byType(ChoiceChip),
        ).first,
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('non-default chips are not selected', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chip5 = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('5m'),
          matching: find.byType(ChoiceChip),
        ).first,
      );
      expect(chip5.selected, isFalse);
    });

    testWidgets('setup to active session flow renders correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('pauses and resumes session correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Focus for 25 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FocusTimerWidget), findsOneWidget);

      await tester.tap(find.text('Mark Complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Break Time!'), findsOneWidget);
    });
  });
}
