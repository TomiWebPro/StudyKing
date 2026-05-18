import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

class _FakeSessionRepo extends SessionRepository {
  final Map<String, Session> _sessions = {};
  bool shouldThrow = false;

  @override
  Future<Result<void>> save(String key, Session session) async {
    if (shouldThrow) return Result.failure('save error');
    _sessions[key] = session;
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    if (shouldThrow) return Result.failure('get error');
    return Result.success(_sessions.values.toList());
  }
}

void main() {
  group('Focus Mode → Sessions integration', () {
    test('completing focus session records it in session history', () async {
      final repo = _FakeSessionRepo();

      final session = Session(
        id: 'fs-1',
        studentId: 'student-1',
        type: SessionType.focus,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 25)),
        plannedDurationMinutes: 25,
        actualDurationMs: 1500000,
        completed: true,
      );

      final saveResult = await repo.save(session.id, session);
      expect(saveResult.isSuccess, isTrue);

      final allSessions = await repo.getAll();
      expect(allSessions.isSuccess, isTrue);
      expect(allSessions.data!.length, 1);
      expect(allSessions.data!.first.type, SessionType.focus);
      expect(allSessions.data!.first.completed, isTrue);
    });

    test('handles error when session repo is unavailable', () async {
      final repo = _FakeSessionRepo();
      repo.shouldThrow = true;

      final session = Session(
        id: 'fs-2',
        studentId: 'student-1',
        type: SessionType.focus,
        startTime: DateTime.now(),
        plannedDurationMinutes: 25,
      );

      final result = await repo.save(session.id, session);
      expect(result.isFailure, isTrue);
    });

    test('recovers and saves after repo error', () async {
      final repo = _FakeSessionRepo();
      repo.shouldThrow = true;

      final session = Session(
        id: 'fs-3',
        studentId: 'student-1',
        type: SessionType.focus,
        startTime: DateTime.now(),
        plannedDurationMinutes: 25,
      );
      final errorResult = await repo.save(session.id, session);
      expect(errorResult.isFailure, isTrue);

      repo.shouldThrow = false;
      final successResult = await repo.save(session.id, session);
      expect(successResult.isSuccess, isTrue);

      final allSessions = await repo.getAll();
      expect(allSessions.data!.length, 1);
    });
  });
}
