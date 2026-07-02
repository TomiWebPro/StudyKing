import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';

class _FakeClock implements Clock {
  final DateTime fixed;
  _FakeClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class InMemorySessionRepository extends SessionRepository {
  final Map<String, Session> _store = {};
  final Clock _clock;
  bool _failNextOperations = false;

  InMemorySessionRepository({super.clock})
      : _clock = clock ?? _FakeClock(DateTime(2024, 6, 15, 12, 0));

  void setFailNextOperations(bool fail) {
    _failNextOperations = fail;
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Session item) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    _store[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String key) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    return Result.success(_store[key]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final sessions = _store.values.toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return Result.success(sessions);
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(hours: 24));
    final filtered = _store.values.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Session>>> getByType(SessionType type) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    return Result.success(
      _store.values.where((s) => s.type == type).toList(),
    );
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    return Result.success(
      _store.values.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<Session>>> getBySubject(String subjectId) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    return Result.success(
      _store.values.where((s) => s.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<Result<List<Session>>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    return Result.success(
      _store.values
          .where((s) => s.studentId == studentId && s.subjectId == subjectId)
          .toList(),
    );
  }

  @override
  Future<Result<List<Session>>> getRecentSessionsForSubject(
    String subjectId, {
    int limit = 10,
  }) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final filtered = _store.values.where((s) => s.subjectId == subjectId).toList();
    filtered.sort((a, b) =>
        b.startTime.millisecondsSinceEpoch
            .compareTo(a.startTime.millisecondsSinceEpoch));
    return Result.success(filtered.take(limit).toList());
  }

  @override
  Future<Result<int>> getTotalStudyTimeForSubject(String subjectId) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final total = _store.values
        .where((s) => s.subjectId == subjectId)
        .fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    return Result.success(total);
  }

  @override
  Future<Result<List<Session>>> getActive() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    return Result.success(
      _store.values.where((s) => s.isActive).toList(),
    );
  }

  @override
  Future<Result<int>> getTodayDurationMs() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final now = _clock.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(hours: 24));
    final today = _store.values.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
    return Result.success(today.fold<int>(0, (sum, s) => sum + s.actualDurationMs));
  }

  @override
  Future<Result<bool>> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    final proposedEnd = startTime.add(Duration(minutes: durationMinutes));
    for (final s in _store.values) {
      if (excludeSessionId != null && s.id == excludeSessionId) continue;
      final sEnd = s.endTime ??
          (s.plannedDurationMinutes != null
              ? s.startTime.add(Duration(minutes: s.plannedDurationMinutes!))
              : null);
      if (sEnd == null) continue;
      if (s.startTime.isBefore(proposedEnd) && sEnd.isAfter(startTime)) {
        return Result.success(true);
      }
    }
    return Result.success(false);
  }

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success(_store.values.where((s) => s.status == SessionStatus.planned).toList());
  }

  @override
  Future<Result<int>> getTodaySessionCount() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final now = _clock.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(hours: 24));
    final today = _store.values.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
    return Result.success(today.length);
  }

  @override
  Future<Result<int>> getTodayCompletedSessionCount() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final now = _clock.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(hours: 24));
    final today = _store.values.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end) && s.completed).toList();
    return Result.success(today.length);
  }

  @override
  Future<Result<int>> getWeeklyDurationMs() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final now = _clock.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final total = _store.values
        .where((s) => s.startTime.isAfter(weekAgo))
        .fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    return Result.success(total);
  }

  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final now = _clock.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(hours: 24));
    final sessions = _store.values.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
    final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    final completed = sessions.where((s) => s.completed).length;
    final plannedMinutes = sessions.fold<int>(0, (sum, s) =>
        sum + (s.plannedDurationMinutes ?? 0));
    return Result.success({
      'totalMs': totalMs,
      'totalSeconds': totalMs ~/ 1000,
      'completedSessions': completed,
      'totalSessions': sessions.length,
      'plannedMinutes': plannedMinutes,
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final sessions = _store.values.where((s) => s.subjectId == subjectId).toList();
    final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    final totalQuestions = sessions.fold<int>(0, (sum, s) => sum + s.questionsAnswered);
    final totalCorrect = sessions.fold<int>(0, (sum, s) => sum + s.correctAnswers);
    return Result.success({
      'totalSessions': sessions.length,
      'totalDurationMs': totalMs,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'avgScore': totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0,
    });
  }

  @override
  Future<Result<List<Session>>> getStaleOrphaned() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    final now = _clock.now();
    return Result.success(
      _store.values
          .where((s) =>
              s.endTime == null &&
              !s.completed &&
              s.startTime.isBefore(now.subtract(const Duration(hours: 1))))
          .toList(),
    );
  }

  @override
  Future<Result<void>> clearAll() async {
    if (_failNextOperations) return Result.failure('Simulated failure');
    _store.clear();
    return Result.success(null);
  }
}

Session createSession({
  String id = 's1',
  String studentId = 'stu1',
  String? subjectId = 'sub1',
  String? topicId,
  SessionType type = SessionType.practice,
  DateTime? startTime,
  DateTime? endTime,
  int? plannedDurationMinutes,
  int actualDurationMs = 0,
  int questionsAnswered = 0,
  int correctAnswers = 0,
  bool completed = false,
  SessionStatus status = SessionStatus.planned,
}) {
  return Session(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    topicId: topicId,
    type: type,
    startTime: startTime ?? DateTime(2024, 1, 1, 10, 0),
    endTime: endTime,
    plannedDurationMinutes: plannedDurationMinutes,
    actualDurationMs: actualDurationMs,
    questionsAnswered: questionsAnswered,
    correctAnswers: correctAnswers,
    completed: completed,
    status: status,
  );
}

void main() {
  group('InMemorySessionRepository', () {
    late _FakeClock clock;
    late InMemorySessionRepository repo;

    setUp(() {
      clock = _FakeClock(DateTime(2024, 6, 15, 12, 0));
      repo = InMemorySessionRepository(clock: clock);
    });

    group('save and get', () {
      test('stores and retrieves a session', () async {
        final session = createSession(id: 's1');
        await repo.save('s1', session);
        final result = await repo.get('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.id, 's1');
      });

      test('returns null for non-existent', () async {
        final result = await repo.get('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('overwrites existing session', () async {
        await repo.save('s1', createSession(id: 's1', actualDurationMs: 100));
        await repo.save('s1', createSession(id: 's1', actualDurationMs: 200));
        final result = await repo.get('s1');
        expect(result.data?.actualDurationMs, 200);
      });
    });

    group('getAll', () {
      test('returns empty when store is empty', () async {
        final result = await repo.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns all sessions sorted by startTime desc', () async {
        await repo.save('s1', createSession(id: 's1', startTime: DateTime(2024, 1, 1, 10, 0)));
        await repo.save('s2', createSession(id: 's2', startTime: DateTime(2024, 1, 2, 10, 0)));
        await repo.save('s3', createSession(id: 's3', startTime: DateTime(2024, 1, 3, 10, 0)));
        final result = await repo.getAll();
        expect(result.data?.length, 3);
        expect(result.data![0].id, 's3');
        expect(result.data![2].id, 's1');
      });
    });

    group('getByDate', () {
      final day = DateTime(2024, 1, 15);

      test('returns sessions for given date', () async {
        await repo.save('s1', createSession(id: 's1', startTime: DateTime(2024, 1, 15, 10, 0)));
        await repo.save('s2', createSession(id: 's2', startTime: DateTime(2024, 1, 15, 14, 0)));
        await repo.save('s3', createSession(id: 's3', startTime: DateTime(2024, 1, 16, 10, 0)));
        final result = await repo.getByDate(day);
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
      });

      test('returns empty when no sessions match date', () async {
        await repo.save('s1', createSession(id: 's1', startTime: DateTime(2024, 1, 10)));
        final result = await repo.getByDate(day);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('handles date boundaries correctly', () async {
        await repo.save('s1', createSession(id: 's1', startTime: DateTime(2024, 1, 15, 0, 0, 0)));
        await repo.save('s2', createSession(id: 's2', startTime: DateTime(2024, 1, 15, 23, 59, 59)));
        final result = await repo.getByDate(day);
        expect(result.data?.length, 2);
      });
    });

    group('getByType', () {
      test('filters by session type', () async {
        await repo.save('s1', createSession(id: 's1', type: SessionType.practice));
        await repo.save('s2', createSession(id: 's2', type: SessionType.tutoring));
        await repo.save('s3', createSession(id: 's3', type: SessionType.practice));
        final result = await repo.getByType(SessionType.practice);
        expect(result.data?.length, 2);
      });
    });

    group('getByStudent', () {
      test('filters by student', () async {
        await repo.save('s1', createSession(id: 's1', studentId: 'stu1'));
        await repo.save('s2', createSession(id: 's2', studentId: 'stu2'));
        final result = await repo.getByStudent('stu1');
        expect(result.data?.length, 1);
      });
    });

    group('getBySubject', () {
      test('filters by subject', () async {
        await repo.save('s1', createSession(id: 's1', subjectId: 'math'));
        await repo.save('s2', createSession(id: 's2', subjectId: 'physics'));
        final result = await repo.getBySubject('math');
        expect(result.data?.length, 1);
      });
    });

    group('getByStudentAndSubject', () {
      test('filters by both student and subject', () async {
        await repo.save('s1', createSession(id: 's1', studentId: 'stu1', subjectId: 'math'));
        await repo.save('s2', createSession(id: 's2', studentId: 'stu1', subjectId: 'physics'));
        await repo.save('s3', createSession(id: 's3', studentId: 'stu2', subjectId: 'math'));
        final result = await repo.getByStudentAndSubject('stu1', 'math');
        expect(result.data?.length, 1);
      });
    });

    group('getRecentSessionsForSubject', () {
      test('returns most recent sessions within limit', () async {
        await repo.save('s1', createSession(id: 's1', subjectId: 'math', startTime: DateTime(2024, 1, 1)));
        await repo.save('s2', createSession(id: 's2', subjectId: 'math', startTime: DateTime(2024, 1, 2)));
        await repo.save('s3', createSession(id: 's3', subjectId: 'math', startTime: DateTime(2024, 1, 3)));
        final result = await repo.getRecentSessionsForSubject('math', limit: 2);
        expect(result.data?.length, 2);
        expect(result.data![0].id, 's3');
      });
    });

    group('getActive', () {
      test('returns active sessions', () async {
        await repo.save('s1', createSession(id: 's1', endTime: DateTime(2024, 1, 1), completed: true));
        await repo.save('s2', createSession(id: 's2', endTime: null, completed: false));
        final result = await repo.getActive();
        expect(result.data?.length, 1);
        expect(result.data![0].id, 's2');
      });
    });

    group('getTodayDurationMs', () {
      test('returns total duration for today', () async {
        final today = clock.now();
        await repo.save('s1', createSession(id: 's1', startTime: today, actualDurationMs: 5000));
        await repo.save('s2', createSession(id: 's2', startTime: today, actualDurationMs: 3000));
        final result = await repo.getTodayDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 8000);
      });

      test('returns 0 when no sessions today', () async {
        final result = await repo.getTodayDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });
    });

    group('hasSchedulingConflict', () {
      test('returns false when no overlap', () async {
        await repo.save('s1', createSession(
          id: 's1', startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 11, 0),
        ));
        final conflict = await repo.hasSchedulingConflict(
          startTime: DateTime(2024, 1, 1, 11, 30),
          durationMinutes: 30,
        );
        expect(conflict.data, isFalse);
      });

      test('returns true when overlapping', () async {
        await repo.save('s1', createSession(
          id: 's1', startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 11, 0),
        ));
        final conflict = await repo.hasSchedulingConflict(
          startTime: DateTime(2024, 1, 1, 10, 30),
          durationMinutes: 30,
        );
        expect(conflict.data, isTrue);
      });

      test('excludes session by id', () async {
        await repo.save('s1', createSession(
          id: 's1', startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 11, 0),
        ));
        final conflict = await repo.hasSchedulingConflict(
          startTime: DateTime(2024, 1, 1, 10, 30),
          durationMinutes: 30,
          excludeSessionId: 's1',
        );
        expect(conflict.data, isFalse);
      });
    });

    group('getTodaySessionCount', () {
      test('returns count of today sessions', () async {
        final today = clock.now();
        await repo.save('s1', createSession(id: 's1', startTime: today));
        await repo.save('s2', createSession(id: 's2', startTime: today));
        final result = await repo.getTodaySessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 2);
      });

      test('returns 0 when no sessions today', () async {
        final result = await repo.getTodaySessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });
    });

    group('getTodayCompletedSessionCount', () {
      test('returns count of completed today sessions', () async {
        final today = clock.now();
        await repo.save('s1', createSession(id: 's1', startTime: today, completed: true));
        await repo.save('s2', createSession(id: 's2', startTime: today, completed: false));
        final result = await repo.getTodayCompletedSessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });

      test('returns 0 when no completed sessions today', () async {
        final today = clock.now();
        await repo.save('s1', createSession(id: 's1', startTime: today, completed: false));
        final result = await repo.getTodayCompletedSessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });
    });

    group('getWeeklyDurationMs', () {
      test('sums weekly session durations', () async {
        final today = clock.now();
        await repo.save('s1', createSession(id: 's1', startTime: today, actualDurationMs: 1000));
        await repo.save('s2', createSession(id: 's2', startTime: today.subtract(const Duration(days: 3)), actualDurationMs: 2000));
        final result = await repo.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 3000);
      });

      test('excludes sessions older than 7 days', () async {
        final today = clock.now();
        await repo.save('s1', createSession(id: 's1', startTime: today, actualDurationMs: 1000));
        await repo.save('s2', createSession(id: 's2', startTime: today.subtract(const Duration(days: 10)), actualDurationMs: 5000));
        final result = await repo.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 1000);
      });

      test('returns 0 when no sessions this week', () async {
        final result = await repo.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });
    });

    group('getScheduledLessons', () {
      test('returns only planned sessions', () async {
        await repo.save('s1', createSession(id: 's1', status: SessionStatus.planned));
        await repo.save('s2', createSession(id: 's2', status: SessionStatus.inProgress));
        await repo.save('s3', createSession(id: 's3', status: SessionStatus.completed));
        final lessons = await repo.getScheduledLessons();
        expect(lessons.data!.length, 1);
        expect(lessons.data!.first.id, 's1');
      });

      test('returns empty when no planned sessions', () async {
        await repo.save('s1', createSession(id: 's1', status: SessionStatus.completed));
        final lessons = await repo.getScheduledLessons();
        expect(lessons.data, isEmpty);
      });
    });

    group('getStaleOrphaned', () {
      test('returns sessions with no endTime and older than 1 hour', () async {
        final oldStart = clock.now().subtract(const Duration(hours: 2));
        await repo.save('s1', createSession(id: 's1', startTime: oldStart, completed: false));
        await repo.save('s2', createSession(id: 's2', startTime: clock.now(), completed: false));
        final result = await repo.getStaleOrphaned();
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data![0].id, 's1');
      });

      test('excludes completed sessions', () async {
        final oldStart = clock.now().subtract(const Duration(hours: 2));
        await repo.save('s1', createSession(id: 's1', startTime: oldStart, completed: true));
        final result = await repo.getStaleOrphaned();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('excludes sessions with endTime set', () async {
        final oldStart = clock.now().subtract(const Duration(hours: 2));
        await repo.save('s1', createSession(id: 's1', startTime: oldStart, endTime: oldStart.add(const Duration(hours: 1)), completed: false));
        final result = await repo.getStaleOrphaned();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getTodayStats', () {
      test('returns correct stats', () async {
        final today = clock.now();
        await repo.save('s1', createSession(
          id: 's1', startTime: today, actualDurationMs: 5000,
          completed: true, plannedDurationMinutes: 30,
        ));
        final result = await repo.getTodayStats();
        expect(result.isSuccess, isTrue);
        expect(result.data!['totalMs'], 5000);
        expect(result.data!['completedSessions'], 1);
        expect(result.data!['totalSessions'], 1);
      });
    });

    group('getSubjectStats', () {
      test('returns correct subject stats', () async {
        await repo.save('s1', createSession(
          id: 's1', subjectId: 'math', actualDurationMs: 5000,
          questionsAnswered: 10, correctAnswers: 7,
        ));
        final result = await repo.getSubjectStats('math');
        expect(result.isSuccess, isTrue);
        expect(result.data!['totalSessions'], 1);
        expect(result.data!['totalDurationMs'], 5000);
        expect(result.data!['avgScore'], 70.0);
      });
    });

    group('delete and clear', () {
      test('removes a session', () async {
        await repo.save('s1', createSession(id: 's1'));
        await repo.delete('s1');
        expect((await repo.get('s1')).data, isNull);
      });

      test('clearAll removes all sessions', () async {
        await repo.save('s1', createSession(id: 's1'));
        await repo.save('s2', createSession(id: 's2'));
        await repo.clearAll();
        final result = await repo.getAll();
        expect(result.data, isEmpty);
      });
    });

    group('error-state: edge cases', () {
      test('get returns null for missing key', () async {
        expect((await repo.get('missing')).data, isNull);
      });

      test('delete on missing key does not throw', () async {
        await repo.delete('nonexistent');
      });

      test('getAll on empty returns empty list', () async {
        final result = await repo.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('getByType with no matches returns empty', () async {
        final result = await repo.getByType(SessionType.tutoring);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('getTodayDurationMs with no sessions returns 0', () async {
        final result = await repo.getTodayDurationMs();
        expect(result.data, 0);
      });
    });

    group('error-state: store failure propagation', () {
      setUp(() {
        repo.setFailNextOperations(true);
      });

      test('getAll returns failure', () async {
        final result = await repo.getAll();
        expect(result.isFailure, isTrue);
      });

      test('get returns failure', () async {
        final result = await repo.get('s1');
        expect(result.isFailure, isTrue);
      });

      test('save returns failure', () async {
        final result = await repo.save('s1', createSession());
        expect(result.isFailure, isTrue);
      });

      test('delete returns failure', () async {
        final result = await repo.delete('s1');
        expect(result.isFailure, isTrue);
      });

      test('getByDate returns failure', () async {
        final result = await repo.getByDate(DateTime(2024, 1, 15));
        expect(result.isFailure, isTrue);
      });

      test('getByType returns failure', () async {
        final result = await repo.getByType(SessionType.practice);
        expect(result.isFailure, isTrue);
      });

      test('getByStudent returns failure', () async {
        final result = await repo.getByStudent('stu1');
        expect(result.isFailure, isTrue);
      });

      test('getBySubject returns failure', () async {
        final result = await repo.getBySubject('sub1');
        expect(result.isFailure, isTrue);
      });

      test('getByStudentAndSubject returns failure', () async {
        final result = await repo.getByStudentAndSubject('stu1', 'sub1');
        expect(result.isFailure, isTrue);
      });

      test('getRecentSessionsForSubject returns failure', () async {
        final result = await repo.getRecentSessionsForSubject('sub1');
        expect(result.isFailure, isTrue);
      });

      test('getTotalStudyTimeForSubject returns failure', () async {
        final result = await repo.getTotalStudyTimeForSubject('sub1');
        expect(result.isFailure, isTrue);
      });

      test('getActive returns failure', () async {
        final result = await repo.getActive();
        expect(result.isFailure, isTrue);
      });

      test('getTodayDurationMs returns failure', () async {
        final result = await repo.getTodayDurationMs();
        expect(result.isFailure, isTrue);
      });

      test('getTodaySessionCount returns failure', () async {
        final result = await repo.getTodaySessionCount();
        expect(result.isFailure, isTrue);
      });

      test('getTodayCompletedSessionCount returns failure', () async {
        final result = await repo.getTodayCompletedSessionCount();
        expect(result.isFailure, isTrue);
      });

      test('getWeeklyDurationMs returns failure', () async {
        final result = await repo.getWeeklyDurationMs();
        expect(result.isFailure, isTrue);
      });

      test('getTodayStats returns failure', () async {
        final result = await repo.getTodayStats();
        expect(result.isFailure, isTrue);
      });

      test('getSubjectStats returns failure', () async {
        final result = await repo.getSubjectStats('sub1');
        expect(result.isFailure, isTrue);
      });

      test('clearAll returns failure', () async {
        final result = await repo.clearAll();
        expect(result.isFailure, isTrue);
      });

      test('getStaleOrphaned returns failure', () async {
        final result = await repo.getStaleOrphaned();
        expect(result.isFailure, isTrue);
      });
    });
  });
}
