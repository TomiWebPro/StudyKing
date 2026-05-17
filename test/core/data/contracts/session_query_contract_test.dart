import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/contracts/session_query_contract.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';

class _TestSessionQueryContract implements SessionQueryContract {
  final Map<String, Session> _store = {};

  @override
  Future<void> init() async {}

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
    return Result.success(_store.values.toList());
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(
      _store.values.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    return Result.success(
      _store.values.where((s) =>
        s.startTime.year == date.year &&
        s.startTime.month == date.month &&
        s.startTime.day == date.day,
      ).toList(),
    );
  }

  @override
  Future<Result<int>> getTodayDurationMs() async {
    final total = _store.values.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    return Result.success(total);
  }

  @override
  Future<bool> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    return _store.values.any((s) =>
      s.id != excludeSessionId &&
      s.startTime.isBefore(startTime.add(Duration(minutes: durationMinutes))) &&
      startTime.isBefore(s.startTime.add(Duration(milliseconds: s.actualDurationMs))),
    );
  }

  @override
  Future<List<Session>> getScheduledLessons() async {
    return _store.values.where((s) => s.type == SessionType.tutoring).toList();
  }
}

Session _createSession({
  String id = 's1',
  String studentId = 'stu1',
  DateTime? startTime,
  int durationMs = 3600000,
  SessionType type = SessionType.practice,
}) {
  final start = startTime ?? DateTime(2025, 1, 15, 10, 0);
  return Session(
    id: id,
    studentId: studentId,
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
    actualDurationMs: durationMs,
    type: type,
  );
}

void main() {
  group('SessionQueryContract', () {
    late _TestSessionQueryContract contract;

    setUp(() {
      contract = _TestSessionQueryContract();
    });

    group('save and get', () {
      test('saves and retrieves a session', () async {
        final session = _createSession(id: 's1');
        await contract.save(session);
        final result = await contract.get('s1');
        expect(result.data, isNotNull);
        expect(result.data!.id, 's1');
      });

      test('returns null for missing session', () async {
        final result = await contract.get('nonexistent');
        expect(result.data, isNull);
      });
    });

    group('getAll', () {
      test('returns empty list when no sessions', () async {
        final result = await contract.getAll();
        expect(result.data, isEmpty);
      });

      test('returns all saved sessions', () async {
        await contract.save(_createSession(id: 's1'));
        await contract.save(_createSession(id: 's2'));
        final result = await contract.getAll();
        expect(result.data!.length, 2);
      });
    });

    group('getByStudent', () {
      test('returns sessions for specific student', () async {
        await contract.save(_createSession(id: 's1', studentId: 'stu1'));
        await contract.save(_createSession(id: 's2', studentId: 'stu2'));
        final result = await contract.getByStudent('stu1');
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 's1');
      });
    });

    group('getByDate', () {
      test('returns sessions for specific date', () async {
        final date = DateTime(2025, 1, 15);
        await contract.save(_createSession(id: 's1', startTime: date));
        await contract.save(_createSession(id: 's2', startTime: DateTime(2025, 1, 16)));
        final result = await contract.getByDate(date);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 's1');
      });
    });

    group('getTodayDurationMs', () {
      test('returns total duration for today', () async {
        final now = DateTime.now();
        await contract.save(_createSession(id: 's1', startTime: now, durationMs: 1800000));
        await contract.save(_createSession(id: 's2', startTime: now, durationMs: 1800000));
        final result = await contract.getTodayDurationMs();
        expect(result.data, 3600000);
      });
    });

    group('hasSchedulingConflict', () {
      test('returns false when no conflict', () async {
        final start = DateTime(2025, 1, 15, 10, 0);
        await contract.save(_createSession(id: 's1', startTime: start));
        final conflict = await contract.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 14, 0),
          durationMinutes: 60,
        );
        expect(conflict, isFalse);
      });

      test('returns true when conflict exists', () async {
        final start = DateTime(2025, 1, 15, 10, 0);
        await contract.save(_createSession(id: 's1', startTime: start));
        final conflict = await contract.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 60,
        );
        expect(conflict, isTrue);
      });
    });

    group('getScheduledLessons', () {
      test('returns only tutoring sessions', () async {
        await contract.save(_createSession(id: 's1', type: SessionType.tutoring));
        await contract.save(_createSession(id: 's2', type: SessionType.practice));
        final lessons = await contract.getScheduledLessons();
        expect(lessons.length, 1);
        expect(lessons.first.id, 's1');
      });
    });
  });
}
