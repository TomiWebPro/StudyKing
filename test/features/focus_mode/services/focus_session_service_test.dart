import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';

class FakeFocusSessionRepository extends FocusSessionRepository {
  final Map<String, FocusSession> _store = {};
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<void> save(FocusSession session) async {
    _store[session.id] = session;
  }

  @override
  Future<FocusSession?> get(String id) async {
    return _store[id];
  }

  @override
  Future<List<FocusSession>> getAll() async {
    final sessions = _store.values.toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  @override
  Future<List<FocusSession>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final all = await getAll();
    return all.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }
}

FocusSession _session({
  required String id,
  required DateTime startTime,
  int plannedDurationMinutes = 25,
  int actualDurationSeconds = 0,
  bool completed = false,
  String? subjectId,
  String? topicId,
}) {
  return FocusSession(
    id: id,
    startTime: startTime,
    plannedDurationMinutes: plannedDurationMinutes,
    actualDurationSeconds: actualDurationSeconds,
    completed: completed,
    subjectId: subjectId,
    topicId: topicId,
    endTime: completed ? startTime.add(Duration(seconds: actualDurationSeconds)) : null,
  );
}

void main() {
  late FocusSessionService service;
  late FakeFocusSessionRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeFocusSessionRepository();
    service = FocusSessionService(repository: fakeRepo);
  });

  tearDown(() {
    service.dispose();
  });

  group('FocusSessionService', () {
    group('initial state', () {
      test('has no active session initially', () {
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
        expect(service.elapsedSeconds, 0);
        expect(service.isPaused, isFalse);
      });
    });

    group('startSession', () {
      test('starts a new session', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 25,
        );

        expect(session.id, contains('focus_'));
        expect(session.plannedDurationMinutes, 25);
        expect(service.hasActiveSession, isTrue);
        expect(service.currentSession, isNotNull);
        expect(service.currentSession!.id, session.id);
        expect(service.elapsedSeconds, 0);
        expect(service.isPaused, isFalse);
      });

      test('cancels previous session if one is active', () async {
        await service.startSession(plannedDurationMinutes: 25);

        final session2 = await service.startSession(plannedDurationMinutes: 30);

        expect(service.currentSession!.id, session2.id);
        expect(service.currentSession!.plannedDurationMinutes, 30);
      });

      test('accepts subjectId and topicId', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 25,
          subjectId: 'subj-1',
          topicId: 'topic-1',
        );

        expect(session.subjectId, 'subj-1');
        expect(session.topicId, 'topic-1');
      });
    });

    group('pause/resume', () {
      test('pauseSession sets isPaused to true', () async {
        await service.startSession(plannedDurationMinutes: 25);
        service.pauseSession();

        expect(service.isPaused, isTrue);
      });

      test('pauseSession does nothing when no active session', () {
        service.pauseSession();

        expect(service.isPaused, isFalse);
      });

      test('resumeSession sets isPaused to false', () async {
        await service.startSession(plannedDurationMinutes: 25);
        service.pauseSession();
        service.resumeSession();

        expect(service.isPaused, isFalse);
      });

      test('resumeSession does nothing when no active session', () {
        service.resumeSession();

        expect(service.isPaused, isFalse);
      });
    });

    group('completeSession', () {
      test('completes active session', () async {
        await service.startSession(plannedDurationMinutes: 25);
        final completed = await service.completeSession();

        expect(completed.completed, isTrue);
        expect(completed.endTime, isNotNull);
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
      });

      test('throws StateError when no active session', () async {
        expect(
          () => service.completeSession(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('cancelSession', () {
      test('cancels active session', () async {
        await service.startSession(plannedDurationMinutes: 25);
        final cancelled = await service.cancelSession();

        expect(cancelled.completed, isFalse);
        expect(cancelled.endTime, isNotNull);
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
      });

      test('throws StateError when no active session', () async {
        expect(
          () => service.cancelSession(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('callbacks', () {
      test('addOnSessionComplete callback fires on completion', () async {
        await service.startSession(plannedDurationMinutes: 25);
        FocusSession? captured;
        service.addOnSessionComplete((s) => captured = s);

        await service.completeSession();

        expect(captured, isNotNull);
        expect(captured!.completed, isTrue);
      });

      test('removeOnSessionComplete removes callback', () async {
        await service.startSession(plannedDurationMinutes: 25);
        FocusSession? captured;
        void callback(FocusSession s) => captured = s;
        service.addOnSessionComplete(callback);
        service.removeOnSessionComplete(callback);

        await service.completeSession();

        expect(captured, isNull);
      });

      test('onTick callback fires when timer ticks', () {
        fakeAsync((async) {
          service.startSession(plannedDurationMinutes: 1);
          int? captured;
          service.addOnTick((elapsed) => captured = elapsed);

          async.elapse(const Duration(seconds: 1));

          expect(captured, greaterThan(0));
        });
      });

      test('removeOnTick removes callback', () {
        fakeAsync((async) {
          service.startSession(plannedDurationMinutes: 1);
          int? captured;
          void callback(int e) => captured = e;
          service.addOnTick(callback);
          service.removeOnTick(callback);

          async.elapse(const Duration(seconds: 1));

          expect(captured, isNull);
        });
      });
    });

    group('daily cap', () {
      test('getDailyCapMinutes returns 0 when settings box unavailable', () async {
        final cap = await service.getDailyCapMinutes();
        expect(cap, 0);
      });

      test('isDailyCapReached returns false when cap is 0', () async {
        final reached = await service.isDailyCapReached(25);
        expect(reached, isFalse);
      });

      test('getRemainingDailyCapMinutes returns -1 when cap is 0', () async {
        final remaining = await service.getRemainingDailyCapMinutes();
        expect(remaining, -1);
      });
    });

    group('stats with real data', () {
      setUp(() async {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);

        await fakeRepo.save(_session(
          id: 's1',
          startTime: todayStart.add(const Duration(hours: 10)),
          actualDurationSeconds: 1200,
          completed: true,
        ));
        await fakeRepo.save(_session(
          id: 's2',
          startTime: todayStart.add(const Duration(hours: 14)),
          actualDurationSeconds: 1800,
          completed: true,
        ));
        await fakeRepo.save(_session(
          id: 's3',
          startTime: todayStart.add(const Duration(hours: 16)),
          actualDurationSeconds: 600,
          completed: false,
        ));
      });

      test('getTodayFocusSeconds returns sum of today durations', () async {
        final seconds = await service.getTodayFocusSeconds();
        expect(seconds, 3600);
      });

      test('getTodaySessionCount returns correct count', () async {
        final count = await service.getTodaySessionCount();
        expect(count, 3);
      });

      test('getTodayCompletedSessionCount returns only completed', () async {
        final count = await service.getTodayCompletedSessionCount();
        expect(count, 2);
      });

      test('getTodayStats returns map with correct values', () async {
        final stats = await service.getTodayStats();

        expect(stats['totalSeconds'], 3600);
        expect(stats['completedSessions'], 2);
        expect(stats['totalSessions'], 3);
        expect(stats['hours'], '1.0');
      });

      test('getRecentSessions returns saved sessions sorted by time', () async {
        final recent = await service.getRecentSessions();
        expect(recent.length, 3);
      });
    });

    group('weekly stats', () {
      setUp(() async {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        await fakeRepo.save(_session(
          id: 'today_session',
          startTime: todayStart.add(const Duration(hours: 12)),
          actualDurationSeconds: 900,
          completed: true,
        ));
        await fakeRepo.save(_session(
          id: 'yesterday_session',
          startTime: todayStart.subtract(const Duration(days: 1)).add(const Duration(hours: 10)),
          actualDurationSeconds: 600,
          completed: true,
        ));
        await fakeRepo.save(_session(
          id: 'last_week_session',
          startTime: todayStart.subtract(const Duration(days: 10)),
          actualDurationSeconds: 300,
          completed: false,
        ));
      });

      test('getWeeklyFocusSeconds sums last 7 days', () async {
        final seconds = await service.getWeeklyFocusSeconds();
        expect(seconds, 1500);
      });
    });

    group('stats edge cases', () {
      test('getTodayFocusSeconds returns 0 with no sessions', () async {
        final seconds = await service.getTodayFocusSeconds();
        expect(seconds, 0);
      });

      test('getTodaySessionCount returns 0 with no sessions', () async {
        final count = await service.getTodaySessionCount();
        expect(count, 0);
      });

      test('getTodayCompletedSessionCount returns 0 with no sessions', () async {
        final count = await service.getTodayCompletedSessionCount();
        expect(count, 0);
      });

      test('getWeeklyFocusSeconds returns 0 with no sessions', () async {
        final seconds = await service.getWeeklyFocusSeconds();
        expect(seconds, 0);
      });

      test('getTodayStats returns map with zeros when no sessions', () async {
        final stats = await service.getTodayStats();

        expect(stats['totalSeconds'], 0);
        expect(stats['completedSessions'], 0);
        expect(stats['totalSessions'], 0);
        expect(stats['plannedMinutes'], 0);
        expect(stats['hours'], '0.0');
      });

      test('getRecentSessions returns empty list when no sessions', () async {
        final recent = await service.getRecentSessions();
        expect(recent, isEmpty);
      });
    });
  });
}
