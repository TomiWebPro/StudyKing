import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';

import 'dart:io';

class FakeFocusSessionRepository extends FocusSessionRepository {
  final Map<String, String> _store = {};
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<void> save(FocusSession session) async {
    _store[session.id] = session.toJson().toString();
  }

  @override
  Future<FocusSession?> get(String id) async {
    final raw = _store[id];
    if (raw == null) return null;
    return FocusSession(
      id: id,
      startTime: DateTime.now(),
      plannedDurationMinutes: 25,
    );
  }

  @override
  Future<List<FocusSession>> getAll() async {
    return _store.keys.map((id) => FocusSession(
      id: id,
      startTime: DateTime.now(),
      plannedDurationMinutes: 25,
    )).toList();
  }

  @override
  Future<List<FocusSession>> getByDate(DateTime date) async {
    return _store.keys.map((id) => FocusSession(
      id: id,
      startTime: DateTime.now(),
      plannedDurationMinutes: 25,
      actualDurationSeconds: 1500,
      completed: id.contains('completed'),
    )).toList();
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

void main() {
  late FocusSessionService service;
  late FakeFocusSessionRepository fakeRepo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);

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

      test('onTick callback fires when timer ticks', () async {
        await service.startSession(plannedDurationMinutes: 1);
        int? captured;
        service.addOnTick((elapsed) => captured = elapsed);

        await Future.delayed(const Duration(milliseconds: 1500));
        service.dispose();

        expect(captured, greaterThan(0));
      });

      test('removeOnTick removes callback', () async {
        await service.startSession(plannedDurationMinutes: 1);
        int? captured;
        void callback(int e) => captured = e;
        service.addOnTick(callback);
        service.removeOnTick(callback);

        await Future.delayed(const Duration(milliseconds: 1500));
        service.dispose();

        expect(captured, isNull);
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

    group('stats', () {
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

      test('getTodayStats returns map with zero values', () async {
        final stats = await service.getTodayStats();

        expect(stats['totalSeconds'], 0);
        expect(stats['completedSessions'], 0);
        expect(stats['totalSessions'], 0);
        expect(stats['plannedMinutes'], 0);
        expect(stats['hours'], '0.0');
      });

      test('getRecentSessions returns empty list', () async {
        final recent = await service.getRecentSessions();
        expect(recent, isEmpty);
      });
    });
  });
}
