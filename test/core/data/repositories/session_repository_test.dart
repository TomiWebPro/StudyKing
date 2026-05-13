import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/models/study_session_model.dart';

class _MockSessionRepository extends SessionRepository {
  final Map<String, StudySession> _storage = {};

  @override
  Future<void> init() async {
  }

  @override
  Future<void> create(StudySession session) async {
    _storage[session.id] = session;
  }

  @override
  Future<StudySession?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<StudySession>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<void> endSession(String id) async {
    final session = _storage[id];
    if (session != null) {
      _storage[id] = session.copyWith(endTime: DateTime.now());
    }
  }
}

void main() {
  group('SessionRepository', () {
    late _MockSessionRepository repository;

    setUp(() {
      repository = _MockSessionRepository();
    });

    group('create', () {
      test('stores a session', () async {
        final session = StudySession(
          id: 's1',
          studentId: 'student-1',
          subjectId: 'sub-1',
          startTime: DateTime(2026, 5, 12),
        );
        await repository.create(session);
        final stored = await repository.get('s1');
        expect(stored?.id, 's1');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });
    });

    group('getAll', () {
      test('returns all sessions', () async {
        await repository.create(StudySession(id: 's1', studentId: 's1', subjectId: 'sub1', startTime: DateTime(2026, 5, 12)));
        await repository.create(StudySession(id: 's2', studentId: 's1', subjectId: 'sub1', startTime: DateTime(2026, 5, 12)));
        expect((await repository.getAll()).length, 2);
      });
    });

    group('endSession', () {
      test('sets end time on existing session', () async {
        final session = StudySession(id: 's1', studentId: 's1', subjectId: 'sub1', startTime: DateTime(2026, 5, 12));
        await repository.create(session);
        await repository.endSession('s1');
        final stored = await repository.get('s1');
        expect(stored?.endTime, isNotNull);
      });

      test('does nothing for non-existent session', () async {
        await repository.endSession('none');
      });
    });
  });
}
