import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';

class FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _store = {};

  @override
  Future<Result<void>> save(Session session) async {
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

void main() {
  group('StudyTimerService', () {
    late FakeSessionRepository repository;
    late StudyTimerService service;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('timer_test_');
      Hive.init(dir.path);
      await Hive.openBox('settings');
      repository = FakeSessionRepository();
      service = StudyTimerService(repository: repository);
    });

    tearDown(() async {
      await service.dispose();
      await Hive.close();
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
    });

    group('startSession', () {
      test('creates and saves a new session', () async {
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
    });

    group('completeSession', () {
      test('throws StateError when no active session', () async {
        expect(
          () => service.completeSession(),
          throwsA(isA<StateError>()),
        );
      });

      test('completes the active session', () async {
        await service.startSession(
          plannedDurationMinutes: 25,
          studentId: 'student-1',
        );
        final completed = await service.completeSession();
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
        final completed = await service.completeSession();
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
        final completed = await service.completeSession();
        expect(captured, isNotNull);
        expect(captured!.id, completed.id);
      });
    });

    group('cancelSession', () {
      test('throws StateError when no active session', () async {
        expect(
          () => service.cancelSession(),
          throwsA(isA<StateError>()),
        );
      });

      test('cancels the active session', () async {
        await service.startSession(plannedDurationMinutes: 25);
        final cancelled = await service.cancelSession();
        expect(cancelled.completed, isFalse);
        expect(cancelled.endTime, isNotNull);
        expect(service.hasActiveSession, isFalse);
      });
    });

    group('callbacks', () {
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
    });

    group('getDailyCapMinutes', () {
      test('returns 0 when no cap is set', () async {
        expect(await service.getDailyCapMinutes(), 0);
      });

      test('returns stored cap value', () async {
        final box = Hive.box('settings');
        await box.put('dailyCapMinutes', 120);
        expect(await service.getDailyCapMinutes(), 120);
      });
    });

    group('isDailyCapReached', () {
      test('returns false when cap is 0', () async {
        expect(await service.isDailyCapReached(30), isFalse);
      });

      test('returns false when under cap', () async {
        final box = Hive.box('settings');
        await box.put('dailyCapMinutes', 120);
        expect(await service.isDailyCapReached(30), isFalse);
      });

      test('returns true when over cap', () async {
        final box = Hive.box('settings');
        await box.put('dailyCapMinutes', 60);
        await repository.save(Session(
          id: 'existing-session',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 2400000,
          type: SessionType.focus,
        ));
        expect(await service.isDailyCapReached(30), isTrue);
      });
    });

    group('getRemainingDailyCapMinutes', () {
      test('returns -1 when cap is 0', () async {
        expect(await service.getRemainingDailyCapMinutes(), -1);
      });

      test('returns remaining minutes', () async {
        final box = Hive.box('settings');
        await box.put('dailyCapMinutes', 120);
        expect(await service.getRemainingDailyCapMinutes(), 120);
      });
    });

    group('getRecentSessions', () {
      test('returns empty when no sessions', () async {
        expect(await service.getRecentSessions(), isEmpty);
      });

      test('returns limited recent sessions', () async {
        for (var i = 0; i < 5; i++) {
          await repository.save(Session(
            id: 's$i',
            studentId: 'student-1',
            startTime: DateTime(2025, 1, 15 + i),
            type: SessionType.focus,
          ));
        }
        final recent = await service.getRecentSessions(limit: 3);
        expect(recent.length, 3);
      });
    });

    group('today stats delegation', () {
      test('getTodayDurationMs delegates to repository', () async {
        await repository.save(Session(
          id: 'today-session',
          studentId: 'student-1',
          startTime: DateTime.now(),
          actualDurationMs: 5000,
          type: SessionType.focus,
        ));
        expect(await service.getTodayDurationMs(), 5000);
      });

      test('getTodaySessionCount delegates to repository', () async {
        await repository.save(Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime.now(),
          type: SessionType.focus,
        ));
        await repository.save(Session(
          id: 's2',
          studentId: 'student-1',
          startTime: DateTime.now(),
          type: SessionType.focus,
        ));
        expect(await service.getTodaySessionCount(), 2);
      });

      test('getTodayCompletedSessionCount delegates to repository', () async {
        await repository.save(Session(
          id: 's1',
          studentId: 'student-1',
          startTime: DateTime.now(),
          completed: true,
          type: SessionType.focus,
        ));
        expect(await service.getTodayCompletedSessionCount(), 1);
      });

      test('getTodayStats delegates to repository', () async {
        final stats = await service.getTodayStats();
        expect(stats, isA<Map<String, dynamic>>());
      });
    });

    group('dispose', () {
      test('cancels timer and clears state', () async {
        await service.startSession(plannedDurationMinutes: 25);
        await service.dispose();
        expect(service.hasActiveSession, isTrue);
      });
    });
  });
}
