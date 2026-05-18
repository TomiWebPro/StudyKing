import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/core/errors/result.dart';

class _FakeTutorSessionBox implements Box<TutorSession> {
  final Map<dynamic, TutorSession> _storage = {};

  @override
  Iterable<TutorSession> get values => _storage.values;

  @override
  int get length => _storage.length;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isOpen => true;

  @override
  String get name => 'tutor_sessions';

  @override
  TutorSession? get(dynamic key, {TutorSession? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, TutorSession value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final key in keys) {
      _storage.remove(key);
    }
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key);

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  Map<dynamic, TutorSession> toMap() => Map.from(_storage);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ErrorFakeTutorSessionBox implements Box<TutorSession> {
  final Map<dynamic, TutorSession> _storage = {};
  bool throwOnPut = false;
  bool throwOnGet = false;
  bool throwOnDelete = false;
  bool throwOnValues = false;
  bool throwOnClear = false;

  @override
  Iterable<TutorSession> get values {
    if (throwOnValues) throw Exception('values error');
    return _storage.values;
  }

  @override
  int get length => _storage.length;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isOpen => true;

  @override
  String get name => 'tutor_sessions_error';

  @override
  TutorSession? get(dynamic key, {TutorSession? defaultValue}) {
    if (throwOnGet) throw Exception('get error');
    return _storage[key] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, TutorSession value) async {
    if (throwOnPut) throw Exception('put error');
    _storage[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    if (throwOnDelete) throw Exception('delete error');
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final key in keys) {
      _storage.remove(key);
    }
  }

  @override
  Future<int> clear() async {
    if (throwOnClear) throw Exception('clear error');
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key);

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  Map<dynamic, TutorSession> toMap() => Map.from(_storage);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThrowingGetStudentSessionsRepo extends TutorSessionRepository {
  bool throwOnGetStudentSessions = false;

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(String studentId) async {
    if (throwOnGetStudentSessions) {
      return Result.failure('simulated failure from getStudentSessions');
    }
    return super.getStudentSessions(studentId);
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
  DateTime? endTime,
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
    endTime: endTime,
    questionsAsked: questionsAsked,
    questionsCorrect: questionsCorrect,
  );
}

void main() {
  group('TutorSessionRepository (attached to fake box)', () {
    late _FakeTutorSessionBox fakeBox;
    late TutorSessionRepository repository;

    setUp(() {
      fakeBox = _FakeTutorSessionBox();
      repository = TutorSessionRepository();
      repository.attachBox(fakeBox);
    });

    group('create', () {
      test('stores a session via create alias', () async {
        final session = createSession();
        final result = await repository.create(session);
        expect(result.isSuccess, true);
        expect((await repository.getSession('session-1')).data?.topicTitle, 'Algebra');
      });

      test('create is equivalent to saveSession', () async {
        final session = createSession();
        final createResult = await repository.create(session);
        final saveResult = await repository.saveSession(createSession(id: 'session-2'));
        expect(createResult.isSuccess, true);
        expect(saveResult.isSuccess, true);
      });
    });

    group('saveSession', () {
      test('stores a session', () async {
        final session = createSession();
        final result = await repository.saveSession(session);
        expect(result.isSuccess, true);
        expect((await repository.getSession('session-1')).data?.topicTitle, 'Algebra');
      });

      test('overwrites existing session with same id', () async {
        final session1 = createSession(topicTitle: 'Algebra');
        final session2 = createSession(topicTitle: 'Calculus');
        await repository.saveSession(session1);
        await repository.saveSession(session2);
        expect((await repository.getSession('session-1')).data?.topicTitle, 'Calculus');
      });

      test('returns Result<void> type', () async {
        final session = createSession();
        final result = await repository.saveSession(session);
        expect(result, isA<SuccessResult<void>>());
      });
    });

    group('getSession', () {
      test('returns Result with null data for non-existent session', () async {
        final result = await repository.getSession('none');
        expect(result, isA<SuccessResult<TutorSession?>>());
        expect(result.data, isNull);
      });

      test('returns stored session', () async {
        await repository.saveSession(createSession());
        final result = await repository.getSession('session-1');
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.id, 'session-1');
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
        final allResult = await repository.getAllSessions();
        expect(allResult.isSuccess, true);
        final all = allResult.data!;
        expect(all.length, 3);
        expect(all[0].id, 's2');
        expect(all[1].id, 's3');
        expect(all[2].id, 's1');
      });

      test('returns empty when no sessions', () async {
        expect((await repository.getAllSessions()).data, isEmpty);
      });

      test('returns single session', () async {
        await repository.saveSession(createSession(id: 's1'));
        final allResult = await repository.getAllSessions();
        expect(allResult.isSuccess, true);
        final all = allResult.data!;
        expect(all.length, 1);
        expect(all[0].id, 's1');
      });

      test('returns Result type wrapping list', () async {
        final result = await repository.getAllSessions();
        expect(result, isA<SuccessResult<List<TutorSession>>>());
      });
    });

    group('getStudentSessions', () {
      test('filters by studentId', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1'));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu1'));
        await repository.saveSession(createSession(id: 's3', studentId: 'stu2'));
        final sessionsResult = await repository.getStudentSessions('stu1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 2);
      });

      test('returns empty for student with no sessions', () async {
        expect((await repository.getStudentSessions('none')).data, isEmpty);
      });

      test('sorts by startTime descending', () async {
        await repository.saveSession(createSession(
          id: 's1', studentId: 'stu1',
          startTime: DateTime(2025, 1, 10),
        ));
        await repository.saveSession(createSession(
          id: 's2', studentId: 'stu1',
          startTime: DateTime(2025, 1, 15),
        ));
        await repository.saveSession(createSession(
          id: 's3', studentId: 'stu1',
          startTime: DateTime(2025, 1, 12),
        ));
        final sessionsResult = await repository.getStudentSessions('stu1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 3);
        expect(sessions[0].id, 's2');
        expect(sessions[1].id, 's3');
        expect(sessions[2].id, 's1');
      });
    });

    group('getSubjectSessions', () {
      test('filters by studentId and subjectId', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1', subjectId: 'sub1'));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu1', subjectId: 'sub1'));
        await repository.saveSession(createSession(id: 's3', studentId: 'stu1', subjectId: 'sub2'));
        await repository.saveSession(createSession(id: 's4', studentId: 'stu2', subjectId: 'sub1'));
        final sessionsResult = await repository.getSubjectSessions('stu1', 'sub1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 2);
      });

      test('returns empty when no match', () async {
        expect((await repository.getSubjectSessions('stu1', 'sub1')).data, isEmpty);
      });

      test('only includes sessions matching both student and subject', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1', subjectId: 'sub1'));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu2', subjectId: 'sub1'));
        final sessionsResult = await repository.getSubjectSessions('stu1', 'sub1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 1);
        expect(sessions[0].id, 's1');
      });
    });

    group('getActiveSessions', () {
      test('returns only in-progress sessions', () async {
        await repository.saveSession(createSession(id: 's1', status: SessionStatus.inProgress));
        await repository.saveSession(createSession(id: 's2', status: SessionStatus.planned));
        await repository.saveSession(createSession(id: 's3', status: SessionStatus.completed));
        await repository.saveSession(createSession(id: 's4', status: SessionStatus.inProgress));
        final activeResult = await repository.getActiveSessions();
        expect(activeResult.isSuccess, true);
        final active = activeResult.data!;
        expect(active.length, 2);
        expect(active.every((s) => s.status == SessionStatus.inProgress), isTrue);
      });

      test('returns empty when no active sessions', () async {
        await repository.saveSession(createSession(id: 's1', status: SessionStatus.completed));
        expect((await repository.getActiveSessions()).data, isEmpty);
      });

      test('works when box has no sessions', () async {
        expect((await repository.getActiveSessions()).data, isEmpty);
      });
    });

    group('getCompletedSessions', () {
      test('returns completed sessions for a student', () async {
        await repository.saveSession(createSession(id: 's1', studentId: 'stu1', status: SessionStatus.completed));
        await repository.saveSession(createSession(id: 's2', studentId: 'stu1', status: SessionStatus.completed));
        await repository.saveSession(createSession(id: 's3', studentId: 'stu1', status: SessionStatus.inProgress));
        await repository.saveSession(createSession(id: 's4', studentId: 'stu2', status: SessionStatus.completed));
        final completedResult = await repository.getCompletedSessions('stu1');
        expect(completedResult.isSuccess, true);
        final completed = completedResult.data!;
        expect(completed.length, 2);
        expect(completed.every((s) => s.status == SessionStatus.completed), isTrue);
      });

      test('returns empty when no completed sessions', () async {
        expect((await repository.getCompletedSessions('stu1')).data, isEmpty);
      });

      test('returns completed sessions in filter order', () async {
        await repository.saveSession(createSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.completed,
          startTime: DateTime(2025, 1, 10),
        ));
        await repository.saveSession(createSession(
          id: 's2', studentId: 'stu1', status: SessionStatus.completed,
          startTime: DateTime(2025, 1, 15),
        ));
        final completedResult = await repository.getCompletedSessions('stu1');
        expect(completedResult.isSuccess, true);
        final completed = completedResult.data!;
        expect(completed.length, 2);
        expect(completed.every((s) => s.status == SessionStatus.completed), isTrue);
      });
    });

    group('deleteSession', () {
      test('removes a session', () async {
        final session = createSession();
        await repository.saveSession(session);
        final result = await repository.deleteSession('session-1');
        expect(result.isSuccess, true);
        expect((await repository.getSession('session-1')).data, isNull);
      });

      test('does nothing for non-existent session', () async {
        final result = await repository.deleteSession('none');
        expect(result.isSuccess, true);
      });

      test('returns Result<void> type', () async {
        final result = await repository.deleteSession('none');
        expect(result, isA<SuccessResult<void>>());
      });
    });

    group('clearAll', () {
      test('removes all sessions', () async {
        await repository.saveSession(createSession(id: 's1'));
        await repository.saveSession(createSession(id: 's2'));
        final result = await repository.clearAll();
        expect(result.isSuccess, true);
        expect((await repository.getAllSessions()).data, isEmpty);
      });

      test('works on empty repository', () async {
        final result = await repository.clearAll();
        expect(result.isSuccess, true);
        expect((await repository.getAllSessions()).data, isEmpty);
      });
    });

    group('getSessionStats', () {
      test('returns zeros when no sessions', () async {
        final statsResult = await repository.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
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
          startTime: DateTime(2025, 1, 15, 9, 0, 0),
        ));
        await repository.saveSession(createSession(
          id: 's2', studentId: 'stu1', status: SessionStatus.completed,
          questionsAsked: 5, questionsCorrect: 3,
          startTime: DateTime(2025, 1, 15, 8, 0, 0),
        ));
        await repository.saveSession(createSession(
          id: 's3', studentId: 'stu1', status: SessionStatus.inProgress,
          questionsAsked: 2, questionsCorrect: 1,
        ));

        final statsResult = await repository.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
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
        final statsResult = await repository.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
        expect(stats['totalSessions'], 1);
      });

      test('averageAccuracy is 0 when no completed sessions', () async {
        await repository.saveSession(createSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.inProgress,
        ));
        final statsResult = await repository.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
        expect(stats['averageAccuracy'], 0.0);
      });

      test('totalHours is computed from elapsed time for completed sessions', () async {
        final start = DateTime.now().subtract(const Duration(hours: 2));
        await repository.saveSession(createSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.completed,
          startTime: start,
        ));
        final statsResult = await repository.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
        expect(stats['totalSessions'], 1);
        expect(stats['completedSessions'], 1);
        expect(stats['totalHours'], greaterThan(0.0));
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
        final saveResult = await hiveRepo.saveSession(session);
        expect(saveResult.isSuccess, true);
        final retrieved = await hiveRepo.getSession('session-1');
        expect(retrieved, isNotNull);
        expect(retrieved.data!.topicTitle, 'Algebra');
        expect(retrieved.data!.studentId, 'student-1');
      });

      test('getSession returns Result with null data for non-existent', () async {
        final result = await hiveRepo.getSession('none');
        expect(result, isA<SuccessResult<TutorSession?>>());
        expect(result.data, isNull);
      });

      test('saveSession overwrites existing session with same id', () async {
        final s1 = hiveSession(topicTitle: 'Algebra');
        final s2 = hiveSession(topicTitle: 'Calculus');
        await hiveRepo.saveSession(s1);
        await hiveRepo.saveSession(s2);
        expect((await hiveRepo.getSession('session-1')).data?.topicTitle, 'Calculus');
      });

      test('create alias stores a session', () async {
        final session = hiveSession(id: 'create-session');
        final result = await hiveRepo.create(session);
        expect(result.isSuccess, true);
        expect((await hiveRepo.getSession('create-session')).data?.topicTitle, 'Algebra');
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
        final allResult = await hiveRepo.getAllSessions();
        expect(allResult.isSuccess, true);
        final all = allResult.data!;
        expect(all.length, 3);
        expect(all[0].id, 's2');
        expect(all[1].id, 's3');
        expect(all[2].id, 's1');
      });

      test('returns empty when no sessions', () async {
        expect((await hiveRepo.getAllSessions()).data, isEmpty);
      });

      test('returns single session', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1'));
        final allResult = await hiveRepo.getAllSessions();
        expect(allResult.isSuccess, true);
        final all = allResult.data!;
        expect(all.length, 1);
        expect(all[0].id, 's1');
      });
    });

    group('getStudentSessions', () {
      test('filters by studentId', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', studentId: 'stu1'));
        await hiveRepo.saveSession(hiveSession(id: 's2', studentId: 'stu1'));
        await hiveRepo.saveSession(hiveSession(id: 's3', studentId: 'stu2'));
        final sessionsResult = await hiveRepo.getStudentSessions('stu1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 2);
      });

      test('returns empty for student with no sessions', () async {
        expect((await hiveRepo.getStudentSessions('none')).data, isEmpty);
      });

      test('sorts by startTime descending', () async {
        await hiveRepo.saveSession(hiveSession(
          id: 's1', studentId: 'stu1',
          startTime: DateTime(2025, 1, 10),
        ));
        await hiveRepo.saveSession(hiveSession(
          id: 's2', studentId: 'stu1',
          startTime: DateTime(2025, 1, 15),
        ));
        final sessionsResult = await hiveRepo.getStudentSessions('stu1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 2);
        expect(sessions[0].id, 's2');
        expect(sessions[1].id, 's1');
      });
    });

    group('getSubjectSessions', () {
      test('filters by studentId and subjectId', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', studentId: 'stu1', subjectId: 'sub1'));
        await hiveRepo.saveSession(hiveSession(id: 's2', studentId: 'stu1', subjectId: 'sub1'));
        await hiveRepo.saveSession(hiveSession(id: 's3', studentId: 'stu1', subjectId: 'sub2'));
        await hiveRepo.saveSession(hiveSession(id: 's4', studentId: 'stu2', subjectId: 'sub1'));
        final sessionsResult = await hiveRepo.getSubjectSessions('stu1', 'sub1');
        expect(sessionsResult.isSuccess, true);
        final sessions = sessionsResult.data!;
        expect(sessions.length, 2);
      });

      test('returns empty when no match', () async {
        expect((await hiveRepo.getSubjectSessions('stu1', 'sub1')).data, isEmpty);
      });
    });

    group('getActiveSessions', () {
      test('returns only in-progress sessions', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', status: SessionStatus.inProgress));
        await hiveRepo.saveSession(hiveSession(id: 's2', status: SessionStatus.planned));
        await hiveRepo.saveSession(hiveSession(id: 's3', status: SessionStatus.completed));
        await hiveRepo.saveSession(hiveSession(id: 's4', status: SessionStatus.inProgress));
        final activeResult = await hiveRepo.getActiveSessions();
        expect(activeResult.isSuccess, true);
        final active = activeResult.data!;
        expect(active.length, 2);
        expect(active.every((s) => s.status == SessionStatus.inProgress), isTrue);
      });

      test('returns empty when no active sessions', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', status: SessionStatus.completed));
        expect((await hiveRepo.getActiveSessions()).data, isEmpty);
      });
    });

    group('getCompletedSessions', () {
      test('returns completed sessions for a student', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1', studentId: 'stu1', status: SessionStatus.completed));
        await hiveRepo.saveSession(hiveSession(id: 's2', studentId: 'stu1', status: SessionStatus.completed));
        await hiveRepo.saveSession(hiveSession(id: 's3', studentId: 'stu1', status: SessionStatus.inProgress));
        await hiveRepo.saveSession(hiveSession(id: 's4', studentId: 'stu2', status: SessionStatus.completed));
        final completedResult = await hiveRepo.getCompletedSessions('stu1');
        expect(completedResult.isSuccess, true);
        final completed = completedResult.data!;
        expect(completed.length, 2);
        expect(completed.every((s) => s.status == SessionStatus.completed), isTrue);
      });

      test('returns empty when no completed sessions', () async {
        expect((await hiveRepo.getCompletedSessions('stu1')).data, isEmpty);
      });
    });

    group('deleteSession', () {
      test('removes a session', () async {
        await hiveRepo.saveSession(hiveSession());
        final result = await hiveRepo.deleteSession('session-1');
        expect(result.isSuccess, true);
        expect((await hiveRepo.getSession('session-1')).data, isNull);
      });

      test('does nothing for non-existent session', () async {
        final result = await hiveRepo.deleteSession('none');
        expect(result.isSuccess, true);
      });
    });

    group('clearAll', () {
      test('removes all sessions', () async {
        await hiveRepo.saveSession(hiveSession(id: 's1'));
        await hiveRepo.saveSession(hiveSession(id: 's2'));
        final result = await hiveRepo.clearAll();
        expect(result.isSuccess, true);
        expect((await hiveRepo.getAllSessions()).data, isEmpty);
      });

      test('works on empty repository', () async {
        final result = await hiveRepo.clearAll();
        expect(result.isSuccess, true);
        expect((await hiveRepo.getAllSessions()).data, isEmpty);
      });
    });

    group('getSessionStats', () {
      test('returns zeros when no sessions', () async {
        final statsResult = await hiveRepo.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
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

        final statsResult = await hiveRepo.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
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
        final statsResult = await hiveRepo.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
        expect(stats['totalSessions'], 1);
      });

      test('averageAccuracy is 0 when no completed sessions', () async {
        await hiveRepo.saveSession(hiveSession(
          id: 's1', studentId: 'stu1', status: SessionStatus.inProgress,
        ));
        final statsResult = await hiveRepo.getSessionStats('stu1');
        expect(statsResult.isSuccess, true);
        final stats = statsResult.data!;
        expect(stats['averageAccuracy'], 0.0);
      });
    });
  });

  group('TutorSessionRepository error handling', () {
    group('with throwing fake box', () {
      late _ErrorFakeTutorSessionBox errorBox;
      late TutorSessionRepository repository;

      setUp(() {
        errorBox = _ErrorFakeTutorSessionBox();
        repository = TutorSessionRepository();
        repository.attachBox(errorBox);
      });

      group('saveSession', () {
        test('returns failure when box.put throws', () async {
          errorBox.throwOnPut = true;
          final session = createSession();
          final result = await repository.saveSession(session);
          expect(result.isFailure, true);
          expect(result.error, contains('Failed to put'));
        });
      });

      group('create', () {
        test('returns failure when box.put throws', () async {
          errorBox.throwOnPut = true;
          final session = createSession();
          final result = await repository.create(session);
          expect(result.isFailure, true);
          expect(result.error, contains('Failed to put'));
        });
      });

      group('getSession', () {
        test('returns failure when box.get throws', () async {
          errorBox.throwOnGet = true;
          final result = await repository.getSession('any');
          expect(result.isFailure, true);
          expect(result.error, contains('Failed to get'));
        });
      });

      group('getAllSessions', () {
        test('handles box error gracefully (returns empty)', () async {
          errorBox.throwOnValues = true;
          final result = await repository.getAllSessions();
          expect(result.isSuccess, true);
          expect(result.data, isEmpty);
        });
      });

      group('getStudentSessions', () {
        test('returns failure when box.values throws', () async {
          errorBox.throwOnValues = true;
          final result = await repository.getStudentSessions('stu1');
          expect(result.isFailure, true);
        });
      });

      group('getSubjectSessions', () {
        test('returns failure when box.values throws', () async {
          errorBox.throwOnValues = true;
          final result = await repository.getSubjectSessions('stu1', 'sub1');
          expect(result.isFailure, true);
        });
      });

      group('getActiveSessions', () {
        test('returns failure when box.values throws', () async {
          errorBox.throwOnValues = true;
          final result = await repository.getActiveSessions();
          expect(result.isFailure, true);
        });
      });

      group('getCompletedSessions', () {
        test('returns failure when box.values throws', () async {
          errorBox.throwOnValues = true;
          final result = await repository.getCompletedSessions('stu1');
          expect(result.isFailure, true);
        });
      });

      group('deleteSession', () {
        test('returns failure when box.delete throws', () async {
          errorBox.throwOnDelete = true;
          final result = await repository.deleteSession('any');
          expect(result.isFailure, true);
          expect(result.error, contains('Failed to delete'));
        });
      });

      group('clearAll', () {
        test('returns failure when box.clear throws', () async {
          errorBox.throwOnClear = true;
          final result = await repository.clearAll();
          expect(result.isFailure, true);
        });
      });

      group('getSessionStats', () {
        test('returns failure when getStudentSessions fails', () async {
          errorBox.throwOnValues = true;
          final result = await repository.getSessionStats('stu1');
          expect(result.isFailure, true);
        });
      });
    });

    group('getSessionStats failure propagation', () {
      test('propagates failure from getStudentSessions via subclass', () async {
        final repo = _FakeThrowingGetStudentSessionsRepo();
        repo.throwOnGetStudentSessions = true;
        final errorBox = _ErrorFakeTutorSessionBox();
        repo.attachBox(errorBox);

        final result = await repo.getSessionStats('stu1');
        expect(result.isFailure, true);
        expect(result.error, 'simulated failure from getStudentSessions');
      });
    });
  });
}
