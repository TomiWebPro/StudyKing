import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';

class FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _store = {};

  @override
  Future<Result<void>> save(String key, Session session) async {
    _store[session.id] = session;
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    return Result.success(_store[id]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return Result.success(list);
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final list = _store.values.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
    return Result.success(list);
  }

  @override
  Future<Result<int>> getTodayDurationMs() async {
    final todayResult = await getByDate(DateTime.now());
    final today = todayResult.data!;
    return Result.success(today.fold<int>(0, (sum, s) => sum + s.actualDurationMs));
  }

  @override
  Future<Result<int>> getTodaySessionCount() async {
    final todayResult = await getByDate(DateTime.now());
    final today = todayResult.data!;
    return Result.success(today.length);
  }

  @override
  Future<Result<int>> getTodayCompletedSessionCount() async {
    final todayResult = await getByDate(DateTime.now());
    final today = todayResult.data!;
    return Result.success(today.where((s) => s.completed).length);
  }

  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    final now = DateTime.now();
    final sessionsResult = await getByDate(now);
    final sessions = sessionsResult.data!;
    final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    final completed = sessions.where((s) => s.completed).length;
    return Result.success({
      'totalMs': totalMs,
      'totalSessions': sessions.length,
      'completedSessions': completed,
    });
  }
}

class TestableStudyTimerService extends StudyTimerService {
  int _dailyCapMinutes = 0;

  TestableStudyTimerService({required super.repository});

  void setDailyCapMinutes(int value) => _dailyCapMinutes = value;

  @override
  Future<int> getDailyCapMinutes() async => _dailyCapMinutes;
}

void main() {
  group('StudyTimerService', () {
    late FakeSessionRepository repository;
    late TestableStudyTimerService service;

    setUp(() async {
      repository = FakeSessionRepository();
      service = TestableStudyTimerService(repository: repository);
    });

    tearDown(() async {
      await service.dispose();
    });

    group('initial state', () {
      test('has no active session', () {
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
        expect(service.elapsedMs, 0);
        expect(service.isPaused, isFalse);
      });

      test('repository getter returns injected repository', () {
        expect(service.repository, repository);
      });

      test('elapsedSeconds is 0 initially', () {
        expect(service.elapsedSeconds, 0);
      });
    });

    group('startSession', () {
      test('creates and saves a new session of type focus', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 25,
          type: SessionType.focus,
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
        );
        expect(session.type, SessionType.focus);
        expect(session.studentId, 'student-1');
        expect(session.subjectId, 'subject-1');
        expect(session.topicId, 'topic-1');
        expect(session.plannedDurationMinutes, 25);
        expect(session.startTime, isNotNull);
        expect(session.isActive, isTrue);
        expect(service.hasActiveSession, isTrue);
        expect(service.currentSession!.id, session.id);
      });

      test('creates and saves a new session of type practice', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 30,
          type: SessionType.practice,
          studentId: 'student-1',
        );
        expect(session.type, SessionType.practice);
        expect(service.currentSession!.type, SessionType.practice);
        expect(service.currentSession!.id, session.id);
      });

      test('creates and saves a new session of type tutoring', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 45,
          type: SessionType.tutoring,
          studentId: 'student-1',
        );
        expect(session.type, SessionType.tutoring);
        expect(service.currentSession!.type, SessionType.tutoring);
      });

      test('creates and saves a new session of type manual', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 10,
          type: SessionType.manual,
          studentId: 'student-1',
        );
        expect(session.type, SessionType.manual);
        expect(service.currentSession!.type, SessionType.manual);
      });

      test('cancels previous session when starting new one', () async {
        final first = await service.startSession(
          plannedDurationMinutes: 25,
        );
        final second = await service.startSession(
          plannedDurationMinutes: 30,
        );
        expect(service.currentSession!.id, second.id);
        final storedFirstResult = await repository.get(first.id);
        expect(storedFirstResult.data!.completed, isFalse);
      });

      test('sets elapsedMs to 0 on start', () async {
        await service.startSession(plannedDurationMinutes: 25);
        expect(service.elapsedMs, 0);
      });

      test('uses empty string for studentId when not provided', () async {
        final session = await service.startSession(
          plannedDurationMinutes: 25,
        );
        expect(session.studentId, '');
      });
    });

    group('pause and resume', () {
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

      test('pauseSession does not clear elapsedMs', () async {
        await service.startSession(plannedDurationMinutes: 25);
        service.pauseSession();
        expect(service.elapsedMs, 0);
      });
    });

    group('completeSession', () {
      test('returns failure when no active session', () async {
        final result = await service.completeSession();
        expect(result.isFailure, isTrue);
        expect(result.error, 'No_active_session');
      });

      test('completes the active session', () async {
        await service.startSession(
          plannedDurationMinutes: 25,
          studentId: 'student-1',
        );
        final result = await service.completeSession();
        expect(result.isSuccess, true);
        final completed = result.data!;
        expect(completed.completed, isTrue);
        expect(completed.endTime, isNotNull);
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
      });

      test('saves completed session to repository', () async {
        await service.startSession(
          plannedDurationMinutes: 25,
          studentId: 'student-1',
        );
        final result = await service.completeSession();
        expect(result.isSuccess, true);
        final completed = result.data!;
        final storedResult = await repository.get(completed.id);
        expect(storedResult.data, isNotNull);
        expect(storedResult.data!.completed, isTrue);
      });

      test('fires onSessionComplete callback', () async {
        Session? captured;
        service.addOnSessionComplete((session) {
          captured = session;
        });
        await service.startSession(plannedDurationMinutes: 25);
        final result = await service.completeSession();
        expect(result.isSuccess, true);
        final completed = result.data!;
        expect(captured, isNotNull);
        expect(captured!.id, completed.id);
      });

      test('completes with zero elapsedMs', () async {
        await service.startSession(plannedDurationMinutes: 25);
        final result = await service.completeSession();
        expect(result.isSuccess, true);
        final completed = result.data!;
        expect(completed.actualDurationMs, 0);
        expect(completed.completed, isTrue);
      });

      test('resets state after completion', () async {
        await service.startSession(plannedDurationMinutes: 25);
        await service.completeSession();
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
        expect(service.elapsedMs, 0);
        expect(service.isPaused, isFalse);
      });
    });

    group('cancelSession', () {
      test('returns failure when no active session', () async {
        final result = await service.cancelSession();
        expect(result.isFailure, isTrue);
        expect(result.error, 'No_active_session');
      });

      test('cancels the active session', () async {
        await service.startSession(plannedDurationMinutes: 25);
        final result = await service.cancelSession();
        expect(result.isSuccess, true);
        final cancelled = result.data!;
        expect(cancelled.completed, isFalse);
        expect(cancelled.endTime, isNotNull);
        expect(service.hasActiveSession, isFalse);
      });

      test('cancels with zero elapsedMs', () async {
        await service.startSession(plannedDurationMinutes: 25);
        final result = await service.cancelSession();
        expect(result.isSuccess, true);
        expect(result.data!.actualDurationMs, 0);
      });

      test('resets state after cancellation', () async {
        await service.startSession(plannedDurationMinutes: 25);
        await service.cancelSession();
        expect(service.hasActiveSession, isFalse);
        expect(service.currentSession, isNull);
        expect(service.elapsedMs, 0);
        expect(service.isPaused, isFalse);
      });
    });

    group('reconcileElapsedMs', () {
      test('does nothing when no active session', () async {
        service.reconcileElapsedMs(5000);
        expect(service.elapsedMs, 0);
      });

      test('does nothing when session is paused', () async {
        await service.startSession(plannedDurationMinutes: 25);
        service.pauseSession();
        service.reconcileElapsedMs(5000);
        expect(service.elapsedMs, 0);
      });

      test('increments elapsedMs when active and not paused', () async {
        await service.startSession(plannedDurationMinutes: 25);
        service.reconcileElapsedMs(5000);
        expect(service.elapsedMs, 5000);
      });

      test('auto-completes session when elapsed exceeds planned duration', () async {
        await service.startSession(
          plannedDurationMinutes: 1,
          studentId: 'student-1',
        );
        final sessionId = service.currentSession!.id;
        expect(service.hasActiveSession, isTrue);
        service.reconcileElapsedMs(120000);
        await Future<void>.delayed(Duration.zero);
        final storedResult = await repository.get(sessionId);
        expect(storedResult.data!.completed, isTrue);
      });
    });

    group('daily cap - isDailyCapExceededMidSession', () {
      test('returns false when cap is 0', () async {
        expect(await service.isDailyCapExceededMidSession(), isFalse);
      });

      test('returns false when under cap', () async {
        service.setDailyCapMinutes(120);
        expect(await service.isDailyCapExceededMidSession(), isFalse);
      });

      test('returns true when over cap without current session', () async {
        service.setDailyCapMinutes(10);
        final existing = Session(
          id: 'existing',
          studentId: 'student-1',
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          actualDurationMs: 600000,
          completed: true,
          type: SessionType.focus,
        );
        await repository.save(existing.id, existing);
        expect(await service.isDailyCapExceededMidSession(), isTrue);
      });

      test('returns false when over cap but current session keeps total under', () async {
        service.setDailyCapMinutes(15);
        await service.startSession(plannedDurationMinutes: 10);
        service.reconcileElapsedMs(120000);
        final existing = Session(
          id: 'existing',
          studentId: 'student-1',
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          actualDurationMs: 600000,
          completed: true,
          type: SessionType.focus,
        );
        await repository.save(existing.id, existing);
        expect(await service.isDailyCapExceededMidSession(), isFalse);
      });
    });

    group('getRemainingDailyCapMinutes', () {
      test('returns -1 when cap is 0', () async {
        expect(await service.getRemainingDailyCapMinutes(), -1);
      });

      test('returns cap value when no sessions', () async {
        service.setDailyCapMinutes(120);
        expect(await service.getRemainingDailyCapMinutes(), 120);
      });

      test('returns reduced remaining after sessions', () async {
        service.setDailyCapMinutes(60);
        final existing = Session(
          id: 'existing',
          studentId: 'student-1',
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          actualDurationMs: 1800000,
          completed: true,
          type: SessionType.focus,
        );
        await repository.save(existing.id, existing);
        final remaining = await service.getRemainingDailyCapMinutes();
        expect(remaining, 30);
      });

      test('can go to 0 remaining', () async {
        service.setDailyCapMinutes(60);
        final existing = Session(
          id: 'existing',
          studentId: 'student-1',
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          actualDurationMs: 3600000,
          completed: true,
          type: SessionType.focus,
        );
        await repository.save(existing.id, existing);
        expect(await service.getRemainingDailyCapMinutes(), 0);
      });
    });

    group('getRecentSessions', () {
      test('returns empty when no sessions', () async {
        expect(await service.getRecentSessions(), isEmpty);
      });

      test('returns limited recent sessions', () async {
        for (var i = 0; i < 5; i++) {
          final sess1 = Session(
            id: 's$i',
            studentId: 'student-1',
            startTime: DateTime(2025, 1, 15 + i),
            type: SessionType.focus,
          );
          await repository.save(sess1.id, sess1);
        }
        final recent = await service.getRecentSessions(limit: 3);
        expect(recent.length, 3);
      });

      test('returns all sessions when fewer than limit', () async {
        final s1 = Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime(2025, 1, 15),
          type: SessionType.focus,
        );
        await repository.save(s1.id, s1);
        final recent = await service.getRecentSessions(limit: 10);
        expect(recent.length, 1);
      });

      test('defaults to limit of 10', () async {
        for (var i = 0; i < 15; i++) {
          final s = Session(
            id: 's$i',
            studentId: 'student-1',
            startTime: DateTime(2025, 1, 15 + i),
            type: SessionType.focus,
          );
          await repository.save(s.id, s);
        }
        final recent = await service.getRecentSessions();
        expect(recent.length, 10);
      });
    });

    group('onTick callbacks', () {
      test('addOnTick registers callback', () {
        final calls = <int>[];
        service.addOnTick((elapsed) => calls.add(elapsed));
        expect(service.hasActiveSession, isFalse);
      });

      test('removeOnTick unregisters callback', () {
        final calls = <int>[];
        void cb(int elapsed) => calls.add(elapsed);
        service.addOnTick(cb);
        service.removeOnTick(cb);
      });

      test('addOnTick and removeOnTick are idempotent', () {
        void cb(int elapsed) {}
        service.addOnTick(cb);
        service.addOnTick(cb);
        service.removeOnTick(cb);
        service.removeOnTick(cb);
      });
    });

    group('onSessionComplete callbacks', () {
      test('addOnSessionComplete registers callback', () async {
        final calls = <Session>[];
        service.addOnSessionComplete((s) => calls.add(s));
        await service.startSession(plannedDurationMinutes: 25);
        await service.completeSession();
        expect(calls.length, 1);
      });

      test('removeOnSessionComplete unregisters callback', () async {
        final calls = <Session>[];
        void cb(Session s) => calls.add(s);
        service.addOnSessionComplete(cb);
        service.removeOnSessionComplete(cb);
        await service.startSession(plannedDurationMinutes: 25);
        await service.completeSession();
        expect(calls, isEmpty);
      });

      test('multiple callbacks all fire', () async {
        final calls = <String>[];
        service.addOnSessionComplete((_) => calls.add('a'));
        service.addOnSessionComplete((_) => calls.add('b'));
        await service.startSession(plannedDurationMinutes: 25);
        await service.completeSession();
        expect(calls.length, 2);
        expect(calls, contains('a'));
        expect(calls, contains('b'));
      });
    });

    group('getDailyCapMinutes', () {
      test('returns 0 when no cap is set', () async {
        expect(await service.getDailyCapMinutes(), 0);
      });

      test('returns stored cap value', () async {
        service.setDailyCapMinutes(120);
        expect(await service.getDailyCapMinutes(), 120);
      });
    });

    group('isDailyCapReached', () {
      test('returns false when cap is 0', () async {
        expect(await service.isDailyCapReached(30), isFalse);
      });

      test('returns false when under cap', () async {
        service.setDailyCapMinutes(120);
        expect(await service.isDailyCapReached(30), isFalse);
      });

      test('returns true when over cap', () async {
        service.setDailyCapMinutes(60);
        final sess0 = Session(
          id: 'existing-session',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 2400000,
          type: SessionType.focus,
        );
        await repository.save(sess0.id, sess0);
        expect(await service.isDailyCapReached(30), isTrue);
      });

      test('returns false when exactly at cap boundary', () async {
        service.setDailyCapMinutes(60);
        final existing = Session(
          id: 'existing-session',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 1800000,
          type: SessionType.focus,
        );
        await repository.save(existing.id, existing);
        expect(await service.isDailyCapReached(30), isFalse);
      });
    });

    group('today stats delegation', () {
      test('getTodayDurationMs returns 0 when no sessions', () async {
        expect(await service.getTodayDurationMs(), 0);
      });

      test('getTodayDurationMs delegates to repository', () async {
        final sess2 = Session(
          id: 'today-session',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 5000,
          type: SessionType.focus,
        );
        await repository.save(sess2.id, sess2);
        expect(await service.getTodayDurationMs(), 5000);
      });

      test('getTodaySessionCount delegates to repository', () async {
        final sess3 = Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime.now(),
          type: SessionType.focus,
        );
        await repository.save(sess3.id, sess3);
        final sess4 = Session(
          id: 's2',
          studentId: 'student-1',
          startTime: DateTime.now(),
          type: SessionType.focus,
        );
        await repository.save(sess4.id, sess4);
        expect(await service.getTodaySessionCount(), 2);
      });

      test('getTodayCompletedSessionCount delegates to repository', () async {
        final sess5 = Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime.now(),
          completed: true,
          type: SessionType.focus,
        );
        await repository.save(sess5.id, sess5);
        expect(await service.getTodayCompletedSessionCount(), 1);
      });

      test('getTodayCompletedSessionCount returns 0 when no completed sessions', () async {
        final sess = Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime.now(),
          completed: false,
          type: SessionType.focus,
        );
        await repository.save(sess.id, sess);
        expect(await service.getTodayCompletedSessionCount(), 0);
      });

      test('getTodayStats returns empty map when no sessions', () async {
        final stats = await service.getTodayStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['totalMs'], 0);
        expect(stats['totalSessions'], 0);
      });

      test('getTodayStats returns accumulated stats', () async {
        final s1 = Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 10000,
          completed: true,
          type: SessionType.focus,
        );
        final s2 = Session(
          id: 's2',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 20000,
          completed: false,
          type: SessionType.focus,
        );
        await repository.save(s1.id, s1);
        await repository.save(s2.id, s2);
        final stats = await service.getTodayStats();
        expect(stats['totalMs'], 30000);
        expect(stats['totalSessions'], 2);
        expect(stats['completedSessions'], 1);
      });
    });

    group('dispose', () {
      test('cancels timer', () async {
        await service.startSession(plannedDurationMinutes: 25);
        await service.dispose();
        expect(service.hasActiveSession, isTrue);
      });

      test('can be called when no active session', () async {
        await service.dispose();
        expect(service.currentSession, isNull);
      });

      test('can be called multiple times', () async {
        await service.dispose();
        await service.dispose();
      });
    });
  });
}
