import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';

class _MockStudySessionRepository extends StudySessionRepository {
  _MockStudySessionRepository({List<StudySession>? seed}) {
    _sessions.clear();
    if (seed != null) {
      for (final session in seed) {
        _sessions[session.id] = session;
      }
    }
  }

  final Map<String, StudySession> _sessions = {};
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<StudySession?> get(String id) async {
    return _sessions[id];
  }

  @override
  Future<List<StudySession>> getAll() async {
    return _sessions.values.toList();
  }

  @override
  Future<void> create(StudySession session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<void> delete(String id) async {
    _sessions.remove(id);
  }

  @override
  Future<void> updateQuestionCount(String id, int count) async {
    final session = _sessions[id];
    if (session != null) {
      _sessions[id] = session.copyWith(questionsAnswered: count);
    }
  }

  @override
  Future<List<StudySession>> getByStudent(String studentId) async {
    return _sessions.values.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<List<StudySession>> getBySubject(String subjectId) async {
    return _sessions.values.where((s) => s.subjectId == subjectId).toList();
  }

  @override
  Future<List<StudySession>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    return _sessions.values
        .where(
            (s) => s.studentId == studentId && s.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<StudySession>> getRecentSessionsForSubject(String subjectId,
      {int limit = 10}) async {
    final sessions =
        _sessions.values.where((s) => s.subjectId == subjectId).toList();
    sessions.sort((a, b) =>
        b.startTime.millisecondsSinceEpoch
            .compareTo(a.startTime.millisecondsSinceEpoch));
    return sessions.take(limit).toList();
  }

  @override
  Future<int> getTotalStudyTimeForSubject(String subjectId) async {
    final sessions =
        _sessions.values.where((s) => s.subjectId == subjectId).toList();
    return sessions.fold<int>(0, (sum, s) => sum + s.timeSpentMs);
  }
}

void main() {
  late DateTime baseTime;

  setUp(() {
    baseTime = DateTime(2026, 1, 15, 10, 0, 0);
  });

  StudySession makeSession({
    required String id,
    String studentId = 'student-1',
    String subjectId = 'math',
    DateTime? startTime,
    int timeSpentMs = 3600000,
  }) {
    return StudySession(
      id: id,
      studentId: studentId,
      subjectId: subjectId,
      startTime: startTime ?? baseTime,
      timeSpentMs: timeSpentMs,
    );
  }

  group('StudySessionRepository', () {
    group('init', () {
      test('init marks repository as initialized', () async {
        final repo = _MockStudySessionRepository();
        await repo.init();
        expect(repo.initCalled, isTrue);
      });
    });

    group('create', () {
      test('create adds session to repository', () async {
        final repo = _MockStudySessionRepository();
        final session = makeSession(id: 's1');

        await repo.create(session);

        final retrieved = await repo.get('s1');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 's1');
      });

      test('create replaces existing session with same id', () async {
        final repo = _MockStudySessionRepository();
        final session1 = makeSession(id: 's1', subjectId: 'math');
        final session2 = makeSession(id: 's1', subjectId: 'science');

        await repo.create(session1);
        await repo.create(session2);

        final retrieved = await repo.get('s1');
        expect(retrieved!.subjectId, 'science');
      });
    });

    group('get', () {
      test('get returns session by id', () async {
        final repo = _MockStudySessionRepository();
        final session = makeSession(id: 's1');
        await repo.create(session);

        final retrieved = await repo.get('s1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 's1');
      });

      test('get returns null for non-existent id', () async {
        final repo = _MockStudySessionRepository();

        final retrieved = await repo.get('non-existent');

        expect(retrieved, isNull);
      });
    });

    group('getAll', () {
      test('getAll returns all sessions', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1'));
        await repo.create(makeSession(id: 's2'));
        await repo.create(makeSession(id: 's3'));

        final all = await repo.getAll();

        expect(all.length, 3);
      });

      test('getAll returns empty list when no sessions', () async {
        final repo = _MockStudySessionRepository();

        final all = await repo.getAll();

        expect(all, isEmpty);
      });
    });

    group('delete', () {
      test('delete removes session by id', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1'));

        await repo.delete('s1');

        final retrieved = await repo.get('s1');
        expect(retrieved, isNull);
      });

      test('delete does nothing for non-existent id', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1'));

        await repo.delete('non-existent');

        final all = await repo.getAll();
        expect(all.length, 1);
      });
    });

    group('updateQuestionCount', () {
      test('updateQuestionCount updates session questions', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1'));

        await repo.updateQuestionCount('s1', 15);

        final retrieved = await repo.get('s1');
        expect(retrieved!.questionsAnswered, 15);
      });

      test('updateQuestionCount does nothing for non-existent id', () async {
        final repo = _MockStudySessionRepository();

        await repo.updateQuestionCount('non-existent', 15);

        final all = await repo.getAll();
        expect(all, isEmpty);
      });
    });

    group('getByStudent', () {
      test('getByStudent returns sessions for student', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1', studentId: 'student-1'));
        await repo.create(makeSession(id: 's2', studentId: 'student-1'));
        await repo.create(makeSession(id: 's3', studentId: 'student-2'));

        final sessions = await repo.getByStudent('student-1');

        expect(sessions.length, 2);
      });

      test('getByStudent returns empty list when no matches', () async {
        final repo = _MockStudySessionRepository();

        final sessions = await repo.getByStudent('non-existent');

        expect(sessions, isEmpty);
      });
    });

    group('getBySubject', () {
      test('getBySubject returns sessions for subject', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1', subjectId: 'math'));
        await repo.create(makeSession(id: 's2', subjectId: 'math'));
        await repo.create(makeSession(id: 's3', subjectId: 'science'));

        final sessions = await repo.getBySubject('math');

        expect(sessions.length, 2);
      });

      test('getBySubject returns empty list when no matches', () async {
        final repo = _MockStudySessionRepository();

        final sessions = await repo.getBySubject('non-existent');

        expect(sessions, isEmpty);
      });
    });

    group('getByStudentAndSubject', () {
      test('returns sessions matching both student and subject', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(
            makeSession(id: 's1', studentId: 's1', subjectId: 'math'));
        await repo.create(
            makeSession(id: 's2', studentId: 's1', subjectId: 'science'));
        await repo.create(
            makeSession(id: 's3', studentId: 's2', subjectId: 'math'));

        final sessions =
            await repo.getByStudentAndSubject('s1', 'math');

        expect(sessions.length, 1);
        expect(sessions.first.id, 's1');
      });

      test('returns empty list when no matches', () async {
        final repo = _MockStudySessionRepository();

        final sessions =
            await repo.getByStudentAndSubject('non-student', 'non-subject');

        expect(sessions, isEmpty);
      });
    });

    group('getRecentSessionsForSubject', () {
      test('returns recent sessions sorted by startTime descending', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(
          id: 's1',
          subjectId: 'math',
          startTime: baseTime.subtract(const Duration(days: 2)),
        ));
        await repo.create(makeSession(
          id: 's2',
          subjectId: 'math',
          startTime: baseTime,
        ));
        await repo.create(makeSession(
          id: 's3',
          subjectId: 'math',
          startTime: baseTime.subtract(const Duration(days: 1)),
        ));

        final sessions = await repo.getRecentSessionsForSubject('math');

        expect(sessions.length, 3);
        expect(sessions[0].id, 's2');
        expect(sessions[1].id, 's3');
        expect(sessions[2].id, 's1');
      });

      test('respects limit parameter', () async {
        final repo = _MockStudySessionRepository();
        for (int i = 0; i < 5; i++) {
          await repo.create(makeSession(
            id: 's$i',
            subjectId: 'math',
            startTime: baseTime.subtract(Duration(days: i)),
          ));
        }

        final sessions = await repo.getRecentSessionsForSubject('math', limit: 3);

        expect(sessions.length, 3);
        expect(sessions[0].id, 's0');
      });

      test('returns empty list for non-existent subject', () async {
        final repo = _MockStudySessionRepository();

        final sessions = await repo.getRecentSessionsForSubject('non-existent');

        expect(sessions, isEmpty);
      });
    });

    group('getTotalStudyTimeForSubject', () {
      test('returns total study time for subject', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1', subjectId: 'math', timeSpentMs: 3600000));
        await repo.create(makeSession(id: 's2', subjectId: 'math', timeSpentMs: 7200000));

        final total = await repo.getTotalStudyTimeForSubject('math');

        expect(total, 10800000);
      });

      test('returns zero for non-existent subject', () async {
        final repo = _MockStudySessionRepository();

        final total = await repo.getTotalStudyTimeForSubject('non-existent');

        expect(total, 0);
      });

      test('returns zero when no sessions for subject', () async {
        final repo = _MockStudySessionRepository();
        await repo.create(makeSession(id: 's1', subjectId: 'science'));

        final total = await repo.getTotalStudyTimeForSubject('math');

        expect(total, 0);
      });
    });
  });
}