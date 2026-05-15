import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/teaching/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';

class _MockTutorSessionRepository extends TutorSessionRepository {
  final Map<String, TutorSession> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(TutorSession session) async {
    _storage[session.id] = session;
  }

  @override
  Future<TutorSession?> getSession(String id) async {
    return _storage[id];
  }

  @override
  Future<List<TutorSession>> getAllSessions() async {
    final all = _storage.values.toList();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    return all;
  }

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    final sessions = _storage.values
        .where((s) => s.studentId == studentId)
        .toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  @override
  Future<List<TutorSession>> getSubjectSessions(
    String studentId,
    String subjectId,
  ) async {
    return _storage.values
        .where((s) => s.studentId == studentId && s.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<TutorSession>> getActiveSessions() async {
    return _storage.values
        .where((s) => s.status == SessionStatus.inProgress)
        .toList();
  }

  @override
  Future<List<TutorSession>> getCompletedSessions(String studentId) async {
    return _storage.values
        .where((s) =>
            s.studentId == studentId && s.status == SessionStatus.completed)
        .toList();
  }

  @override
  Future<void> deleteSession(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, dynamic>> getSessionStats(String studentId) async {
    final sessions = _storage.values
        .where((s) => s.studentId == studentId)
        .toList();
    final completed =
        sessions.where((s) => s.status == SessionStatus.completed);

    return {
      'totalSessions': sessions.length,
      'completedSessions': completed.length,
      'totalHours': completed.fold<double>(
          0, (sum, s) => sum + (s.elapsedMinutes / 60.0)),
      'totalQuestions': completed.fold<int>(
          0, (sum, s) => sum + s.questionsAsked),
      'averageAccuracy': completed.isEmpty
          ? 0.0
          : completed.fold<double>(0, (sum, s) => sum + s.accuracy) /
              completed.length,
    };
  }
}

TutorSession createSession({
  String id = 'session-1',
  String studentId = 'student-1',
  String subjectId = 'subject-1',
  String topicId = 'topic-1',
  String topicTitle = 'Algebra',
  SessionStatus status = SessionStatus.planned,
  DateTime? startTime,
  int questionsAsked = 0,
  int questionsCorrect = 0,
}) {
  return TutorSession(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    topicId: topicId,
    topicTitle: topicTitle,
    status: status,
    startTime: startTime ?? DateTime(2025, 1, 15, 10, 0, 0),
    questionsAsked: questionsAsked,
    questionsCorrect: questionsCorrect,
  );
}

void main() {
  group('TutorSessionRepository', () {
    late _MockTutorSessionRepository repository;

    setUp(() {
      repository = _MockTutorSessionRepository();
    });

    group('saveSession', () {
      test('stores a session', () async {
        final session = createSession();
        await repository.saveSession(session);
        final stored = await repository.getSession('session-1');
        expect(stored?.topicTitle, 'Algebra');
      });

      test('overwrites existing session with same id', () async {
        final session1 = createSession(topicTitle: 'Algebra');
        final session2 = createSession(topicTitle: 'Calculus');
        await repository.saveSession(session1);
        await repository.saveSession(session2);
        final stored = await repository.getSession('session-1');
        expect(stored?.topicTitle, 'Calculus');
      });
    });

    group('getSession', () {
      test('returns null for non-existent session', () async {
        expect(await repository.getSession('none'), isNull);
      });

      test('returns stored session', () async {
        await repository.saveSession(createSession());
        expect(await repository.getSession('session-1'), isNotNull);
      });
    });

    group('getAllSessions', () {
      test('returns all sessions sorted by startTime descending', () async {
        final s1 = createSession(id: 's1', startTime: DateTime(2025, 1, 10));
        final s2 = createSession(id: 's2', startTime: DateTime(2025, 1, 15));
        final s3 = createSession(id: 's3', startTime: DateTime(2025, 1, 12));
        await repository.saveSession(s1);
        await repository.saveSession(s2);
        await repository.saveSession(s3);
        final all = await repository.getAllSessions();
        expect(all.length, 3);
        expect(all[0].id, 's2');
        expect(all[1].id, 's3');
        expect(all[2].id, 's1');
      });

      test('returns empty when no sessions', () async {
        expect(await repository.getAllSessions(), isEmpty);
      });
    });

    group('getStudentSessions', () {
      test('filters by studentId', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1'));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu1'));
        await repository.saveSession(createSession(id: 's3', studentId: 'stu2'));
        final sessions = await repository.getStudentSessions('stu1');
        expect(sessions.length, 2);
      });

      test('returns empty for student with no sessions', () async {
        expect(await repository.getStudentSessions('none'), isEmpty);
      });
    });

    group('getSubjectSessions', () {
      test('filters by studentId and subjectId', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1', subjectId: 'sub1'));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu1', subjectId: 'sub1'));
        await repository.saveSession(createSession(id: 's3', studentId: 'stu1', subjectId: 'sub2'));
        await repository.saveSession(createSession(id: 's4', studentId: 'stu2', subjectId: 'sub1'));
        final sessions = await repository.getSubjectSessions('stu1', 'sub1');
        expect(sessions.length, 2);
      });

      test('returns empty when no match', () async {
        expect(await repository.getSubjectSessions('stu1', 'sub1'), isEmpty);
      });
    });

    group('getActiveSessions', () {
      test('returns only in-progress sessions', () async {
        await repository.saveSession(createSession(id: 's1', status: SessionStatus.inProgress));
        await repository.saveSession(createSession(id: 's2', status: SessionStatus.planned));
        await repository.saveSession(createSession(id: 's3', status: SessionStatus.completed));
        await repository.saveSession(createSession(id: 's4', status: SessionStatus.inProgress));
        final active = await repository.getActiveSessions();
        expect(active.length, 2);
        expect(active.every((s) => s.status == SessionStatus.inProgress), isTrue);
      });

      test('returns empty when no active sessions', () async {
        await repository.saveSession(createSession(id: 's1', status: SessionStatus.completed));
        expect(await repository.getActiveSessions(), isEmpty);
      });
    });

    group('getCompletedSessions', () {
      test('returns completed sessions for a student', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1', status: SessionStatus.completed));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu1', status: SessionStatus.completed));
        await repository.saveSession(createSession(id: 's3', studentId: 'stu1', status: SessionStatus.inProgress));
        await repository.saveSession(createSession(id: 's4', studentId: 'stu2', status: SessionStatus.completed));
        final completed = await repository.getCompletedSessions('stu1');
        expect(completed.length, 2);
        expect(completed.every((s) => s.status == SessionStatus.completed), isTrue);
      });

      test('returns empty when no completed sessions', () async {
        expect(await repository.getCompletedSessions('stu1'), isEmpty);
      });
    });

    group('deleteSession', () {
      test('removes a session', () async {
        final session = createSession();
        await repository.saveSession(session);
        await repository.deleteSession('session-1');
        expect(await repository.getSession('session-1'), isNull);
      });

      test('does nothing for non-existent session', () async {
        await repository.deleteSession('none');
      });
    });

    group('clearAll', () {
      test('removes all sessions', () async {
        await repository.saveSession(createSession(id: 's1'));
        await repository.saveSession(createSession(id: 's2'));
        await repository.clearAll();
        expect(await repository.getAllSessions(), isEmpty);
      });
    });

    group('getSessionStats', () {
      test('returns zeros when no sessions', () async {
        final stats = await repository.getSessionStats('stu1');
        expect(stats['totalSessions'], 0);
        expect(stats['completedSessions'], 0);
        expect(stats['totalHours'], 0.0);
        expect(stats['totalQuestions'], 0);
        expect(stats['averageAccuracy'], 0.0);
      });

      test('returns correct stats for student', () async {
        await repository.saveSession(createSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.completed,
          questionsAsked: 10, questionsCorrect: 8,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
        ));
        await repository.saveSession(createSession(
          id: 's2', studentId: 'stu1', status: SessionStatus.completed,
          questionsAsked: 5, questionsCorrect: 3,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
        ));
        await repository.saveSession(createSession(
          id: 's3', studentId: 'stu1', status: SessionStatus.inProgress,
          questionsAsked: 2, questionsCorrect: 1,
        ));

        final stats = await repository.getSessionStats('stu1');
        expect(stats['totalSessions'], 3);
        expect(stats['completedSessions'], 2);
        expect(stats['totalQuestions'], 15);
        expect(stats['averageAccuracy'], (0.8 + 0.6) / 2);
      });

      test('stats exclude other students', () async {
        await repository.saveSession(createSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.completed,
        ));
        await repository.saveSession(createSession(
          id: 's2', studentId: 'stu2', status: SessionStatus.completed,
        ));
        final stats = await repository.getSessionStats('stu1');
        expect(stats['totalSessions'], 1);
      });
    });
  });

  group('TutorSessionRepository Hive integration', () {
    late TutorSessionRepository hiveRepo;
    late String hivePath;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_tutor_session_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(28)) {
        Hive.registerAdapter(TutorSessionAdapter());
      }
      hiveRepo = TutorSessionRepository();
      await hiveRepo.init();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    TutorSession hiveSession({
      String id = 'session-1',
      String studentId = 'student-1',
      String subjectId = 'subject-1',
      String topicId = 'topic-1',
      String topicTitle = 'Algebra',
      SessionStatus status = SessionStatus.planned,
      DateTime? startTime,
      int questionsAsked = 0,
      int questionsCorrect = 0,
    }) {
      return TutorSession(
        id: id,
        studentId: studentId,
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        status: status,
        startTime: startTime ?? DateTime(2025, 1, 15, 10, 0, 0),
        questionsAsked: questionsAsked,
        questionsCorrect: questionsCorrect,
      );
    }

    test('init initializes successfully', () async {
      final repo = TutorSessionRepository();
      await repo.init();
    });

    test('init can be called multiple times without error', () async {
      await hiveRepo.init();
      await hiveRepo.init();
    });

    group('CRUD operations', () {
      test('saves and retrieves a session', () async {
        final session = hiveSession();
        await hiveRepo.saveSession(session);
        final retrieved = await hiveRepo.getSession('session-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.topicTitle, 'Algebra');
        expect(retrieved.studentId, 'student-1');
      });

      test('getSession returns null for non-existent', () async {
        expect(await hiveRepo.getSession('none'), isNull);
      });

      test('saveSession overwrites existing session with same id', () async {
        final s1 = hiveSession(topicTitle: 'Algebra');
        final s2 = hiveSession(topicTitle: 'Calculus');
        await hiveRepo.saveSession(s1);
        await hiveRepo.saveSession(s2);
        final stored = await hiveRepo.getSession('session-1');
        expect(stored?.topicTitle, 'Calculus');
      });
    });

    group('getAllSessions', () {
      test('returns all sessions sorted by startTime desc', () async {
        final s1 = hiveSession(id: 's1', startTime: DateTime(2025, 1, 10));
        final s2 = hiveSession(id: 's2', startTime: DateTime(2025, 1, 15));
        final s3 = hiveSession(id: 's3', startTime: DateTime(2025, 1, 12));
        await hiveRepo.saveSession(s1);
        await hiveRepo.saveSession(s2);
        await hiveRepo.saveSession(s3);
        final all = await hiveRepo.getAllSessions();
        expect(all.length, 3);
        expect(all[0].id, 's2');
        expect(all[1].id, 's3');
        expect(all[2].id, 's1');
      });

      test('returns empty when no sessions', () async {
        expect(await hiveRepo.getAllSessions(), isEmpty);
      });
    });

    group('getStudentSessions', () {
      test('filters by studentId', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', studentId: 'stu1'));
        await hiveRepo.saveSession(hiveSession(id: 's2', studentId: 'stu1'));
        await hiveRepo.saveSession(hiveSession(id: 's3', studentId: 'stu2'));
        final sessions = await hiveRepo.getStudentSessions('stu1');
        expect(sessions.length, 2);
      });

      test('returns empty for student with no sessions', () async {
        expect(await hiveRepo.getStudentSessions('none'), isEmpty);
      });
    });

    group('getSubjectSessions', () {
      test('filters by studentId and subjectId', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', studentId: 'stu1', subjectId: 'sub1'));
        await hiveRepo.saveSession(hiveSession(id: 's2', studentId: 'stu1', subjectId: 'sub1'));
        await hiveRepo.saveSession(hiveSession(id: 's3', studentId: 'stu1', subjectId: 'sub2'));
        await hiveRepo.saveSession(hiveSession(id: 's4', studentId: 'stu2', subjectId: 'sub1'));
        final sessions = await hiveRepo.getSubjectSessions('stu1', 'sub1');
        expect(sessions.length, 2);
      });

      test('returns empty when no match', () async {
        expect(await hiveRepo.getSubjectSessions('stu1', 'sub1'), isEmpty);
      });
    });

    group('getActiveSessions', () {
      test('returns only in-progress sessions', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', status: SessionStatus.inProgress));
        await hiveRepo.saveSession(hiveSession(id: 's2', status: SessionStatus.planned));
        await hiveRepo.saveSession(hiveSession(id: 's3', status: SessionStatus.completed));
        await hiveRepo.saveSession(hiveSession(id: 's4', status: SessionStatus.inProgress));
        final active = await hiveRepo.getActiveSessions();
        expect(active.length, 2);
        expect(active.every((s) => s.status == SessionStatus.inProgress), isTrue);
      });

      test('returns empty when no active sessions', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', status: SessionStatus.completed));
        expect(await hiveRepo.getActiveSessions(), isEmpty);
      });
    });

    group('getCompletedSessions', () {
      test('returns completed sessions for a student', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', studentId: 'stu1', status: SessionStatus.completed));
        await hiveRepo.saveSession(hiveSession(id: 's2', studentId: 'stu1', status: SessionStatus.completed));
        await hiveRepo.saveSession(hiveSession(id: 's3', studentId: 'stu1', status: SessionStatus.inProgress));
        await hiveRepo.saveSession(hiveSession(id: 's4', studentId: 'stu2', status: SessionStatus.completed));
        final completed = await hiveRepo.getCompletedSessions('stu1');
        expect(completed.length, 2);
        expect(completed.every((s) => s.status == SessionStatus.completed), isTrue);
      });

      test('returns empty when no completed sessions', () async {
        expect(await hiveRepo.getCompletedSessions('stu1'), isEmpty);
      });
    });

    group('deleteSession', () {
      test('removes a session', () async {
        await hiveRepo.saveSession(hiveSession());
        await hiveRepo.deleteSession('session-1');
        expect(await hiveRepo.getSession('session-1'), isNull);
      });

      test('does nothing for non-existent session', () async {
        await hiveRepo.deleteSession('none');
      });
    });

    group('clearAll', () {
      test('removes all sessions', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1'));
        await hiveRepo.saveSession(hiveSession(id: 's2'));
        await hiveRepo.clearAll();
        expect(await hiveRepo.getAllSessions(), isEmpty);
      });
    });

    group('getSessionStats', () {
      test('returns zeros when no sessions', () async {
        final stats = await hiveRepo.getSessionStats('stu1');
        expect(stats['totalSessions'], 0);
        expect(stats['completedSessions'], 0);
        expect(stats['totalHours'], 0.0);
        expect(stats['totalQuestions'], 0);
        expect(stats['averageAccuracy'], 0.0);
      });

      test('returns correct stats for student', () async {
        await hiveRepo.saveSession(hiveSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.completed,
          questionsAsked: 10, questionsCorrect: 8,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
        ));
        await hiveRepo.saveSession(hiveSession(
          id: 's2', studentId: 'stu1', status: SessionStatus.completed,
          questionsAsked: 5, questionsCorrect: 3,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
        ));
        await hiveRepo.saveSession(hiveSession(
          id: 's3', studentId: 'stu1', status: SessionStatus.inProgress,
          questionsAsked: 2, questionsCorrect: 1,
        ));

        final stats = await hiveRepo.getSessionStats('stu1');
        expect(stats['totalSessions'], 3);
        expect(stats['completedSessions'], 2);
        expect(stats['totalQuestions'], 15);
        expect(stats['averageAccuracy'], (0.8 + 0.6) / 2);
      });

      test('stats exclude other students', () async {
        await hiveRepo.saveSession(hiveSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.completed,
        ));
        await hiveRepo.saveSession(hiveSession(
          id: 's2', studentId: 'stu2', status: SessionStatus.completed,
        ));
        final stats = await hiveRepo.getSessionStats('stu1');
        expect(stats['totalSessions'], 1);
      });
    });
  });
}
