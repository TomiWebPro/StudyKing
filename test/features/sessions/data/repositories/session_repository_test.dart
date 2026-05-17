import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/session_adapter.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

Session createSession({
  String id = 'session-1',
  String studentId = 'student-1',
  String? subjectId = 'subject-1',
  String? topicId = 'topic-1',
  SessionType type = SessionType.tutoring,
  required DateTime startTime,
  DateTime? endTime,
  int? plannedDurationMinutes = 45,
  int actualDurationMs = 0,
  int questionsAnswered = 0,
  int correctAnswers = 0,
  bool completed = false,
  List<String> sourceIds = const [],
  List<String> lessonIds = const [],
  List<String> tags = const [],
  DateTime? createdAt,
  String? tutorSessionId,
  SessionStatus status = SessionStatus.planned,
  TutorMetadata? tutorMetadata,
}) {
  return Session(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    topicId: topicId,
    type: type,
    startTime: startTime,
    endTime: endTime,
    plannedDurationMinutes: plannedDurationMinutes,
    actualDurationMs: actualDurationMs,
    questionsAnswered: questionsAnswered,
    correctAnswers: correctAnswers,
    completed: completed,
    sourceIds: sourceIds,
    lessonIds: lessonIds,
    tags: tags,
    createdAt: createdAt,
    tutorSessionId: tutorSessionId,
    status: status,
    tutorMetadata: tutorMetadata,
  );
}

void main() {
  group('SessionRepository', () {
    late String hivePath;
    late SessionRepository repository;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('session_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(36)) {
        Hive.registerAdapter(SessionAdapter());
      }
      await Hive.openBox<Session>('sessions_typed');
      repository = SessionRepository();
      await repository.init();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    group('init', () {
      test('initializes the box', () async {
        final repo = SessionRepository();
        await repo.init();
        expect(repo.box, isNotNull);
        expect(repo.box.name, 'sessions_typed');
      });
    });

    group('box getter', () {
      test('returns the underlying Hive box', () async {
        expect(repository.box, isA<Box<Session>>());
        expect(repository.box.name, 'sessions_typed');
      });
    });

    group('save', () {
      test('stores a session', () async {
        final session = createSession(startTime: DateTime(2025, 1, 15, 10, 0));
        final saveResult = await repository.save(session);
        expect(saveResult.isSuccess, isTrue);
        final storedResult = await repository.get(session.id);
        expect(storedResult.isSuccess, isTrue);
        final stored = storedResult.data;
        expect(stored, isNotNull);
        expect(stored!.id, session.id);
      });

      test('overwrites existing session with same id', () async {
        final session1 = createSession(
          id: 's1',
          startTime: DateTime(2025, 1, 15, 10, 0),
          actualDurationMs: 1000,
        );
        final session2 = createSession(
          id: 's1',
          startTime: DateTime(2025, 1, 15, 10, 0),
          actualDurationMs: 2000,
        );
        await repository.save(session1);
        await repository.save(session2);
        final storedResult = await repository.get('s1');
        expect(storedResult.isSuccess, isTrue);
        expect(storedResult.data!.actualDurationMs, 2000);
      });
    });

    group('get', () {
      test('returns null for non-existent session', () async {
        final result = await repository.get('nonexistent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('returns stored session with all fields', () async {
        final tutorMeta = TutorMetadata(
          topicTitle: 'Algebra',
          confidenceRating: 4,
          totalMessages: 10,
          totalTokensUsed: 500,
        );
        final session = createSession(
          id: 'detailed',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 11, 0),
          actualDurationMs: 3600000,
          questionsAnswered: 20,
          correctAnswers: 18,
          completed: true,
          sourceIds: ['src-1', 'src-2'],
          lessonIds: ['lesson-1'],
          tags: ['math', 'algebra'],
          tutorSessionId: 'tut-1',
          status: SessionStatus.completed,
          tutorMetadata: tutorMeta,
        );
        await repository.save(session);
        final storedResult = await repository.get(session.id);
        expect(storedResult.isSuccess, isTrue);
        final stored = storedResult.data!;
        expect(stored.id, session.id);
        expect(stored.studentId, session.studentId);
        expect(stored.subjectId, session.subjectId);
        expect(stored.topicId, session.topicId);
        expect(stored.type, session.type);
        expect(stored.startTime, session.startTime);
        expect(stored.endTime, session.endTime);
        expect(stored.actualDurationMs, 3600000);
        expect(stored.questionsAnswered, 20);
        expect(stored.correctAnswers, 18);
        expect(stored.completed, isTrue);
        expect(stored.sourceIds, ['src-1', 'src-2']);
        expect(stored.lessonIds, ['lesson-1']);
        expect(stored.tags, ['math', 'algebra']);
        expect(stored.tutorSessionId, 'tut-1');
        expect(stored.status, SessionStatus.completed);
        expect(stored.tutorMetadata, isNotNull);
        expect(stored.tutorMetadata!.topicTitle, 'Algebra');
        expect(stored.tutorMetadata!.totalMessages, 10);
      });
    });

    group('getAll', () {
      test('returns empty when no sessions', () async {
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns all stored sessions sorted by startTime desc', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15, 10, 0),
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 16, 10, 0),
        ));
        await repository.save(createSession(
          id: 's3', startTime: DateTime(2025, 1, 14, 10, 0),
        ));
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        final all = result.data!;
        expect(all.length, 3);
        expect(all[0].id, 's2');
        expect(all[1].id, 's1');
        expect(all[2].id, 's3');
      });

      test('returns sessions when there is only one', () async {
        await repository.save(createSession(
          id: 'only', startTime: DateTime(2025, 1, 15, 10, 0),
        ));
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'only');
      });
    });

    group('getByDate', () {
      test('returns sessions for given date', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15, 10, 0),
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 15, 14, 0),
        ));
        await repository.save(createSession(
          id: 's3', startTime: DateTime(2025, 1, 16, 10, 0),
        ));
        final results = await repository.getByDate(DateTime(2025, 1, 15));
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 2);
      });

      test('returns empty for date with no sessions', () async {
        final results = await repository.getByDate(DateTime(2025, 1, 15));
        expect(results.isSuccess, isTrue);
        expect(results.data, isEmpty);
      });

      test('returns only sessions on specified date boundary (start of day)',
          () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15, 0, 0, 0),
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 15, 23, 59, 59),
        ));
        await repository.save(createSession(
          id: 's3', startTime: DateTime(2025, 1, 14, 23, 59, 59),
        ));
        final results = await repository.getByDate(DateTime(2025, 1, 15));
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 2);
        expect(results.data!.map((s) => s.id), containsAll(['s1', 's2']));
      });
    });

    group('getByType', () {
      test('filters by session type', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15), type: SessionType.tutoring,
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 15), type: SessionType.focus,
        ));
        await repository.save(createSession(
          id: 's3', startTime: DateTime(2025, 1, 15), type: SessionType.practice,
        ));
        final tutoringResult = await repository.getByType(SessionType.tutoring);
        expect(tutoringResult.isSuccess, isTrue);
        expect(tutoringResult.data!.length, 1);
        expect(tutoringResult.data!.first.id, 's1');

        final focusResult = await repository.getByType(SessionType.focus);
        expect(focusResult.data!.length, 1);
        expect(focusResult.data!.first.id, 's2');
      });

      test('returns empty when no sessions match type', () async {
        final result = await repository.getByType(SessionType.manual);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getByStudent', () {
      test('filters by student id', () async {
        await repository.save(createSession(
          id: 's1', studentId: 'stu-1', startTime: DateTime(2025, 1, 15),
        ));
        await repository.save(createSession(
          id: 's2', studentId: 'stu-2', startTime: DateTime(2025, 1, 15),
        ));
        await repository.save(createSession(
          id: 's3', studentId: 'stu-1', startTime: DateTime(2025, 1, 16),
        ));
        final results = await repository.getByStudent('stu-1');
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 2);
        expect(results.data!.map((s) => s.id), containsAll(['s1', 's3']));
      });

      test('returns empty when student has no sessions', () async {
        final result = await repository.getByStudent('nonexistent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getBySubject', () {
      test('filters by subject id', () async {
        await repository.save(createSession(
          id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
        ));
        await repository.save(createSession(
          id: 's2', subjectId: 'sub-2', startTime: DateTime(2025, 1, 15),
        ));
        final results = await repository.getBySubject('sub-1');
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 1);
        expect(results.data!.first.id, 's1');
      });

      test('returns empty when subject has no sessions', () async {
        final result = await repository.getBySubject('nonexistent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getByStudentAndSubject', () {
      test('filters by both student and subject', () async {
        await repository.save(createSession(
          id: 's1', studentId: 'stu-1', subjectId: 'sub-1',
          startTime: DateTime(2025, 1, 15),
        ));
        await repository.save(createSession(
          id: 's2', studentId: 'stu-1', subjectId: 'sub-2',
          startTime: DateTime(2025, 1, 15),
        ));
        await repository.save(createSession(
          id: 's3', studentId: 'stu-2', subjectId: 'sub-1',
          startTime: DateTime(2025, 1, 15),
        ));
        final results = await repository.getByStudentAndSubject('stu-1', 'sub-1');
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 1);
        expect(results.data!.first.id, 's1');
      });

      test('returns empty for non-matching combination', () async {
        final result = await repository.getByStudentAndSubject('stu-1', 'sub-99');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getRecentSessionsForSubject', () {
      test('returns recent sessions limited by count', () async {
        for (var i = 0; i < 5; i++) {
          await repository.save(createSession(
            id: 's$i', subjectId: 'sub-1',
            startTime: DateTime(2025, 1, 15 + i),
          ));
        }
        final results = await repository.getRecentSessionsForSubject('sub-1',
            limit: 3);
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 3);
        expect(results.data![0].id, 's4');
      });

      test('returns all sessions when fewer than limit', () async {
        await repository.save(createSession(
          id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
        ));
        final results = await repository.getRecentSessionsForSubject('sub-1',
            limit: 10);
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 1);
      });

      test('returns empty for subject with no sessions', () async {
        final results = await repository.getRecentSessionsForSubject('sub-empty');
        expect(results.isSuccess, isTrue);
        expect(results.data, isEmpty);
      });

      test('returns sessions sorted by most recent first', () async {
        await repository.save(createSession(
          id: 'old', subjectId: 'sub-1',
          startTime: DateTime(2025, 1, 10),
        ));
        await repository.save(createSession(
          id: 'new', subjectId: 'sub-1',
          startTime: DateTime(2025, 1, 20),
        ));
        await repository.save(createSession(
          id: 'mid', subjectId: 'sub-1',
          startTime: DateTime(2025, 1, 15),
        ));
        final results = await repository.getRecentSessionsForSubject('sub-1');
        expect(results.data!.map((s) => s.id),
            equals(['new', 'mid', 'old']));
      });
    });

    group('getTotalStudyTimeForSubject', () {
      test('sums actualDurationMs for subject', () async {
        await repository.save(createSession(
          id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 1000,
        ));
        await repository.save(createSession(
          id: 's2', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 2000,
        ));
        await repository.save(createSession(
          id: 's3', subjectId: 'sub-2', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 3000,
        ));
        final result = await repository.getTotalStudyTimeForSubject('sub-1');
        expect(result.isSuccess, isTrue);
        expect(result.data, 3000);
      });

      test('returns 0 for subject with no sessions', () async {
        final result = await repository.getTotalStudyTimeForSubject('sub-empty');
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });
    });

    group('getActive', () {
      test('returns sessions that are active', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15), completed: false,
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 15), completed: true,
        ));
        await repository.save(createSession(
          id: 's3', startTime: DateTime(2025, 1, 15), completed: false,
        ));
        final active = await repository.getActive();
        expect(active.isSuccess, isTrue);
        expect(active.data!.length, 2);
        expect(active.data!.map((s) => s.id), containsAll(['s1', 's3']));
      });

      test('returns empty when no active sessions', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15), completed: true,
        ));
        final active = await repository.getActive();
        expect(active.isSuccess, isTrue);
        expect(active.data, isEmpty);
      });

      test('considers session with endTime set as not active', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15),
          endTime: DateTime(2025, 1, 15, 11, 0), completed: false,
        ));
        final active = await repository.getActive();
        expect(active.isSuccess, isTrue);
        expect(active.data, isEmpty);
      });
    });

    group('delete', () {
      test('removes a session', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15),
        ));
        final deleteResult = await repository.delete('s1');
        expect(deleteResult.isSuccess, isTrue);
        final result = await repository.get('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('succeeds when deleting non-existent session', () async {
        final result = await repository.delete('nonexistent');
        expect(result.isSuccess, isTrue);
      });
    });

    group('clearAll', () {
      test('removes all sessions', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15),
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 15),
        ));
        final clearResult = await repository.clearAll();
        expect(clearResult.isSuccess, isTrue);
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('succeeds when already empty', () async {
        final result = await repository.clearAll();
        expect(result.isSuccess, isTrue);
      });
    });

    group('getTodayDurationMs', () {
      test('returns 0 when no sessions today', () async {
        final result = await repository.getTodayDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });

      test('sums today session durations', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(), actualDurationMs: 5000,
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime.now(), actualDurationMs: 3000,
        ));
        final result = await repository.getTodayDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 8000);
      });
    });

    group('getTodaySessionCount', () {
      test('returns 0 when no sessions today', () async {
        final result = await repository.getTodaySessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });

      test('counts today sessions', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(),
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime.now(),
        ));
        final result = await repository.getTodaySessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 2);
      });
    });

    group('getTodayCompletedSessionCount', () {
      test('returns 0 when no completed sessions today', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(), completed: false,
        ));
        final result = await repository.getTodayCompletedSessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });

      test('counts completed sessions today', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(), completed: true,
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime.now(), completed: false,
        ));
        final result = await repository.getTodayCompletedSessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });
    });

    group('getWeeklyDurationMs', () {
      test('returns 0 when no sessions this week', () async {
        final result = await repository.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });

      test('sums weekly session durations', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(), actualDurationMs: 1000,
        ));
        await repository.save(createSession(
          id: 's2',
          startTime: DateTime.now().subtract(const Duration(days: 3)),
          actualDurationMs: 2000,
        ));
        final result = await repository.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 3000);
      });

      test('excludes sessions older than 7 days', () async {
        await repository.save(createSession(
          id: 'recent', startTime: DateTime.now(), actualDurationMs: 1000,
        ));
        await repository.save(createSession(
          id: 'old',
          startTime: DateTime.now().subtract(const Duration(days: 10)),
          actualDurationMs: 5000,
        ));
        final result = await repository.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 1000);
      });
    });

    group('getTodayStats', () {
      test('returns empty stats when no sessions', () async {
        final statsResult = await repository.getTodayStats();
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalMs'], 0);
        expect(stats['totalSeconds'], 0);
        expect(stats['totalSessions'], 0);
        expect(stats['completedSessions'], 0);
        expect(stats['plannedMinutes'], 0);
      });

      test('returns computed stats for today', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(), completed: true,
          actualDurationMs: 3600000, plannedDurationMinutes: 60,
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime.now(), completed: false,
          actualDurationMs: 1800000, plannedDurationMinutes: null,
        ));
        final statsResult = await repository.getTodayStats();
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalMs'], 5400000);
        expect(stats['totalSeconds'], 5400);
        expect(stats['totalSessions'], 2);
        expect(stats['completedSessions'], 1);
        expect(stats['plannedMinutes'], 60);
      });
    });

    group('getSubjectStats', () {
      test('returns empty stats for unknown subject', () async {
        final statsResult = await repository.getSubjectStats('unknown');
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalSessions'], 0);
        expect(stats['totalDurationMs'], 0);
        expect(stats['totalQuestions'], 0);
        expect(stats['totalCorrect'], 0);
        expect(stats['avgScore'], 0.0);
      });

      test('returns computed stats for subject', () async {
        await repository.save(createSession(
          id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 1000, questionsAnswered: 10, correctAnswers: 8,
        ));
        await repository.save(createSession(
          id: 's2', subjectId: 'sub-1', startTime: DateTime(2025, 1, 16),
          actualDurationMs: 2000, questionsAnswered: 5, correctAnswers: 4,
        ));
        final statsResult = await repository.getSubjectStats('sub-1');
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalSessions'], 2);
        expect(stats['totalDurationMs'], 3000);
        expect(stats['totalQuestions'], 15);
        expect(stats['totalCorrect'], 12);
        expect(stats['avgScore'], 80.0);
      });

      test('handles zero questions gracefully', () async {
        await repository.save(createSession(
          id: 's1', subjectId: 'sub-zero', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 500, questionsAnswered: 0, correctAnswers: 0,
        ));
        final statsResult = await repository.getSubjectStats('sub-zero');
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalSessions'], 1);
        expect(stats['totalQuestions'], 0);
        expect(stats['avgScore'], 0.0);
      });
    });

    group('computed fields', () {
      test('isActive returns true when not completed and no endTime', () async {
        final session = createSession(
          id: 'active', startTime: DateTime.now(),
          completed: false,
        );
        await repository.save(session);
        final stored = (await repository.get('active')).data!;
        expect(stored.isActive, isTrue);
      });

      test('isActive returns false when completed', () async {
        final session = createSession(
          id: 'done', startTime: DateTime.now(),
          completed: true,
        );
        await repository.save(session);
        final stored = (await repository.get('done')).data!;
        expect(stored.isActive, isFalse);
      });

      test('isActive returns false when endTime is set', () async {
        final session = createSession(
          id: 'ended', startTime: DateTime.now(),
          endTime: DateTime.now(), completed: false,
        );
        await repository.save(session);
        final stored = (await repository.get('ended')).data!;
        expect(stored.isActive, isFalse);
      });

      test('actualDuration returns Duration from ms', () async {
        final session = createSession(
          id: 'dur', startTime: DateTime.now(),
          actualDurationMs: 5000,
        );
        await repository.save(session);
        final stored = (await repository.get('dur')).data!;
        expect(stored.actualDuration, const Duration(seconds: 5));
      });

      test('plannedDuration returns Duration from minutes', () async {
        final session = createSession(
          id: 'plan', startTime: DateTime.now(),
          plannedDurationMinutes: 30,
        );
        await repository.save(session);
        final stored = (await repository.get('plan')).data!;
        expect(stored.plannedDuration, const Duration(minutes: 30));
      });

      test('plannedDuration returns null when plannedDurationMinutes is null',
          () async {
        final session = createSession(
          id: 'noplan', startTime: DateTime.now(),
          plannedDurationMinutes: null,
        );
        await repository.save(session);
        final stored = (await repository.get('noplan')).data!;
        expect(stored.plannedDuration, isNull);
      });
    });
  });
}
