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
  String? sourceId,
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
    sourceId: sourceId,
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
        final saveResult = await repository.save(session.id, session);
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
        await repository.save(session1.id, session1);
        await repository.save(session2.id, session2);
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
          sourceId: 'source-main',
          sourceIds: ['src-1', 'src-2'],
          lessonIds: ['lesson-1'],
          tags: ['math', 'algebra'],
          tutorSessionId: 'tut-1',
          status: SessionStatus.completed,
          tutorMetadata: tutorMeta,
        );
        await repository.save(session.id, session);
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
        expect(stored.sourceId, 'source-main');
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
        final sess0 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15, 10, 0),
                  
        );
        await repository.save(sess0.id, sess0);
        final sess1 = createSession(
          
                    id: 's2', startTime: DateTime(2025, 1, 16, 10, 0),
                  
        );
        await repository.save(sess1.id, sess1);
        final sess2 = createSession(
          
                    id: 's3', startTime: DateTime(2025, 1, 14, 10, 0),
                  
        );
        await repository.save(sess2.id, sess2);
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        final all = result.data!;
        expect(all.length, 3);
        expect(all[0].id, 's2');
        expect(all[1].id, 's1');
        expect(all[2].id, 's3');
      });

      test('returns sessions when there is only one', () async {
        final sess3 = createSession(
          
                    id: 'only', startTime: DateTime(2025, 1, 15, 10, 0),
                  
        );
        await repository.save(sess3.id, sess3);
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'only');
      });
    });

    group('getByDate', () {
      test('returns sessions for given date', () async {
        final sess4 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15, 10, 0),
                  
        );
        await repository.save(sess4.id, sess4);
        final sess5 = createSession(
          
                    id: 's2', startTime: DateTime(2025, 1, 15, 14, 0),
                  
        );
        await repository.save(sess5.id, sess5);
        final sess6 = createSession(
          
                    id: 's3', startTime: DateTime(2025, 1, 16, 10, 0),
                  
        );
        await repository.save(sess6.id, sess6);
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
        final sess7 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15, 0, 0, 0),
                  
        );
        await repository.save(sess7.id, sess7);
        final sess8 = createSession(
          
                    id: 's2', startTime: DateTime(2025, 1, 15, 23, 59, 59),
                  
        );
        await repository.save(sess8.id, sess8);
        final sess9 = createSession(
          
                    id: 's3', startTime: DateTime(2025, 1, 14, 23, 59, 59),
                  
        );
        await repository.save(sess9.id, sess9);
        final results = await repository.getByDate(DateTime(2025, 1, 15));
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 2);
        expect(results.data!.map((s) => s.id), containsAll(['s1', 's2']));
      });
    });

    group('getByType', () {
      test('filters by session type', () async {
        final sess10 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15), type: SessionType.tutoring,
                  
        );
        await repository.save(sess10.id, sess10);
        final sess11 = createSession(
          
                    id: 's2', startTime: DateTime(2025, 1, 15), type: SessionType.focus,
                  
        );
        await repository.save(sess11.id, sess11);
        final sess12 = createSession(
          
                    id: 's3', startTime: DateTime(2025, 1, 15), type: SessionType.practice,
                  
        );
        await repository.save(sess12.id, sess12);
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
        final sess13 = createSession(
          
                    id: 's1', studentId: 'stu-1', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess13.id, sess13);
        final sess14 = createSession(
          
                    id: 's2', studentId: 'stu-2', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess14.id, sess14);
        final sess15 = createSession(
          
                    id: 's3', studentId: 'stu-1', startTime: DateTime(2025, 1, 16),
                  
        );
        await repository.save(sess15.id, sess15);
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
        final sess16 = createSession(
          
                    id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess16.id, sess16);
        final sess17 = createSession(
          
                    id: 's2', subjectId: 'sub-2', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess17.id, sess17);
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
        final sess18 = createSession(
          
                    id: 's1', studentId: 'stu-1', subjectId: 'sub-1',
                    startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess18.id, sess18);
        final sess19 = createSession(
          
                    id: 's2', studentId: 'stu-1', subjectId: 'sub-2',
                    startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess19.id, sess19);
        final sess20 = createSession(
          
                    id: 's3', studentId: 'stu-2', subjectId: 'sub-1',
                    startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess20.id, sess20);
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
          final sess21 = createSession(
            
                        id: 's$i', subjectId: 'sub-1',
                        startTime: DateTime(2025, 1, 15 + i),
                      
          );
          await repository.save(sess21.id, sess21);
        }
        final results = await repository.getRecentSessionsForSubject('sub-1',
            limit: 3);
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 3);
        expect(results.data![0].id, 's4');
      });

      test('returns all sessions when fewer than limit', () async {
        final sess22 = createSession(
          
                    id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess22.id, sess22);
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
        final sess23 = createSession(
          
                    id: 'old', subjectId: 'sub-1',
                    startTime: DateTime(2025, 1, 10),
                  
        );
        await repository.save(sess23.id, sess23);
        final sess24 = createSession(
          
                    id: 'new', subjectId: 'sub-1',
                    startTime: DateTime(2025, 1, 20),
                  
        );
        await repository.save(sess24.id, sess24);
        final sess25 = createSession(
          
                    id: 'mid', subjectId: 'sub-1',
                    startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess25.id, sess25);
        final results = await repository.getRecentSessionsForSubject('sub-1');
        expect(results.data!.map((s) => s.id),
            equals(['new', 'mid', 'old']));
      });
    });

    group('getTotalStudyTimeForSubject', () {
      test('sums actualDurationMs for subject', () async {
        final sess26 = createSession(
          
                    id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
                    actualDurationMs: 1000,
                  
        );
        await repository.save(sess26.id, sess26);
        final sess27 = createSession(
          
                    id: 's2', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
                    actualDurationMs: 2000,
                  
        );
        await repository.save(sess27.id, sess27);
        final sess28 = createSession(
          
                    id: 's3', subjectId: 'sub-2', startTime: DateTime(2025, 1, 15),
                    actualDurationMs: 3000,
                  
        );
        await repository.save(sess28.id, sess28);
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
        final sess29 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15), completed: false,
                  
        );
        await repository.save(sess29.id, sess29);
        final sess30 = createSession(
          
                    id: 's2', startTime: DateTime(2025, 1, 15), completed: true,
                  
        );
        await repository.save(sess30.id, sess30);
        final sess31 = createSession(
          
                    id: 's3', startTime: DateTime(2025, 1, 15), completed: false,
                  
        );
        await repository.save(sess31.id, sess31);
        final active = await repository.getActive();
        expect(active.isSuccess, isTrue);
        expect(active.data!.length, 2);
        expect(active.data!.map((s) => s.id), containsAll(['s1', 's3']));
      });

      test('returns empty when no active sessions', () async {
        final sess32 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15), completed: true,
                  
        );
        await repository.save(sess32.id, sess32);
        final active = await repository.getActive();
        expect(active.isSuccess, isTrue);
        expect(active.data, isEmpty);
      });

      test('considers session with endTime set as not active', () async {
        final sess33 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15),
                    endTime: DateTime(2025, 1, 15, 11, 0), completed: false,
                  
        );
        await repository.save(sess33.id, sess33);
        final active = await repository.getActive();
        expect(active.isSuccess, isTrue);
        expect(active.data, isEmpty);
      });
    });

    group('delete', () {
      test('removes a session', () async {
        final sess34 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess34.id, sess34);
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
        final sess35 = createSession(
          
                    id: 's1', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess35.id, sess35);
        final sess36 = createSession(
          
                    id: 's2', startTime: DateTime(2025, 1, 15),
                  
        );
        await repository.save(sess36.id, sess36);
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
        final sess37 = createSession(
          
                    id: 's1', startTime: DateTime.now(), actualDurationMs: 5000,
                  
        );
        await repository.save(sess37.id, sess37);
        final sess38 = createSession(
          
                    id: 's2', startTime: DateTime.now(), actualDurationMs: 3000,
                  
        );
        await repository.save(sess38.id, sess38);
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
        final sess39 = createSession(
          
                    id: 's1', startTime: DateTime.now(),
                  
        );
        await repository.save(sess39.id, sess39);
        final sess40 = createSession(
          
                    id: 's2', startTime: DateTime.now(),
                  
        );
        await repository.save(sess40.id, sess40);
        final result = await repository.getTodaySessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 2);
      });
    });

    group('getTodayCompletedSessionCount', () {
      test('returns 0 when no completed sessions today', () async {
        final sess41 = createSession(
          
                    id: 's1', startTime: DateTime.now(), completed: false,
                  
        );
        await repository.save(sess41.id, sess41);
        final result = await repository.getTodayCompletedSessionCount();
        expect(result.isSuccess, isTrue);
        expect(result.data, 0);
      });

      test('counts completed sessions today', () async {
        final sess42 = createSession(
          
                    id: 's1', startTime: DateTime.now(), completed: true,
                  
        );
        await repository.save(sess42.id, sess42);
        final sess43 = createSession(
          
                    id: 's2', startTime: DateTime.now(), completed: false,
                  
        );
        await repository.save(sess43.id, sess43);
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
        final sess44 = createSession(
          
                    id: 's1', startTime: DateTime.now(), actualDurationMs: 1000,
                  
        );
        await repository.save(sess44.id, sess44);
        final sess45 = createSession(
          
                    id: 's2',
                    startTime: DateTime.now().subtract(const Duration(days: 3)),
                    actualDurationMs: 2000,
                  
        );
        await repository.save(sess45.id, sess45);
        final result = await repository.getWeeklyDurationMs();
        expect(result.isSuccess, isTrue);
        expect(result.data, 3000);
      });

      test('excludes sessions older than 7 days', () async {
        final sess46 = createSession(
          
                    id: 'recent', startTime: DateTime.now(), actualDurationMs: 1000,
                  
        );
        await repository.save(sess46.id, sess46);
        final sess47 = createSession(
          
                    id: 'old',
                    startTime: DateTime.now().subtract(const Duration(days: 10)),
                    actualDurationMs: 5000,
                  
        );
        await repository.save(sess47.id, sess47);
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
        final sess48 = createSession(
          
                    id: 's1', startTime: DateTime.now(), completed: true,
                    actualDurationMs: 3600000, plannedDurationMinutes: 60,
                  
        );
        await repository.save(sess48.id, sess48);
        final sess49 = createSession(
          
                    id: 's2', startTime: DateTime.now(), completed: false,
                    actualDurationMs: 1800000, plannedDurationMinutes: null,
                  
        );
        await repository.save(sess49.id, sess49);
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
        final sess50 = createSession(
          
                    id: 's1', subjectId: 'sub-1', startTime: DateTime(2025, 1, 15),
                    actualDurationMs: 1000, questionsAnswered: 10, correctAnswers: 8,
                  
        );
        await repository.save(sess50.id, sess50);
        final sess51 = createSession(
          
                    id: 's2', subjectId: 'sub-1', startTime: DateTime(2025, 1, 16),
                    actualDurationMs: 2000, questionsAnswered: 5, correctAnswers: 4,
                  
        );
        await repository.save(sess51.id, sess51);
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
        final sess52 = createSession(
          
                    id: 's1', subjectId: 'sub-zero', startTime: DateTime(2025, 1, 15),
                    actualDurationMs: 500, questionsAnswered: 0, correctAnswers: 0,
                  
        );
        await repository.save(sess52.id, sess52);
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
        await repository.save(session.id, session);
        final stored = (await repository.get('active')).data!;
        expect(stored.isActive, isTrue);
      });

      test('isActive returns false when completed', () async {
        final session = createSession(
          id: 'done', startTime: DateTime.now(),
          completed: true,
        );
        await repository.save(session.id, session);
        final stored = (await repository.get('done')).data!;
        expect(stored.isActive, isFalse);
      });

      test('isActive returns false when endTime is set', () async {
        final session = createSession(
          id: 'ended', startTime: DateTime.now(),
          endTime: DateTime.now(), completed: false,
        );
        await repository.save(session.id, session);
        final stored = (await repository.get('ended')).data!;
        expect(stored.isActive, isFalse);
      });

      test('actualDuration returns Duration from ms', () async {
        final session = createSession(
          id: 'dur', startTime: DateTime.now(),
          actualDurationMs: 5000,
        );
        await repository.save(session.id, session);
        final stored = (await repository.get('dur')).data!;
        expect(stored.actualDuration, const Duration(seconds: 5));
      });

      test('plannedDuration returns Duration from minutes', () async {
        final session = createSession(
          id: 'plan', startTime: DateTime.now(),
          plannedDurationMinutes: 30,
        );
        await repository.save(session.id, session);
        final stored = (await repository.get('plan')).data!;
        expect(stored.plannedDuration, const Duration(minutes: 30));
      });

      test('plannedDuration returns null when plannedDurationMinutes is null',
          () async {
        final session = createSession(
          id: 'noplan', startTime: DateTime.now(),
          plannedDurationMinutes: null,
        );
        await repository.save(session.id, session);
        final stored = (await repository.get('noplan')).data!;
        expect(stored.plannedDuration, isNull);
      });
    });

    group('error handling', () {
      setUp(() async {
        final session = createSession(startTime: DateTime.now());
        await repository.save(session.id, session);
        await Hive.close();
      });

      test('getAll returns failure when box is closed', () async {
        final result = await repository.getAll();
        expect(result.isFailure, isTrue);
      });

      test('getByDate returns failure when box is closed', () async {
        final result = await repository.getByDate(DateTime.now());
        expect(result.isFailure, isTrue);
      });

      test('getByType returns failure when box is closed', () async {
        final result = await repository.getByType(SessionType.focus);
        expect(result.isFailure, isTrue);
      });

      test('getByStudent returns failure when box is closed', () async {
        final result = await repository.getByStudent('student-1');
        expect(result.isFailure, isTrue);
      });

      test('getBySubject returns failure when box is closed', () async {
        final result = await repository.getBySubject('subject-1');
        expect(result.isFailure, isTrue);
      });

      test('getByStudentAndSubject returns failure when box is closed', () async {
        final result =
            await repository.getByStudentAndSubject('stu-1', 'sub-1');
        expect(result.isFailure, isTrue);
      });

      test('getRecentSessionsForSubject returns failure when box is closed',
          () async {
        final result =
            await repository.getRecentSessionsForSubject('sub-1');
        expect(result.isFailure, isTrue);
      });

      test('getTotalStudyTimeForSubject returns failure when box is closed',
          () async {
        final result =
            await repository.getTotalStudyTimeForSubject('sub-1');
        expect(result.isFailure, isTrue);
      });

      test('getActive returns failure when box is closed', () async {
        final result = await repository.getActive();
        expect(result.isFailure, isTrue);
      });

      test('getTodayDurationMs returns failure when box is closed', () async {
        final result = await repository.getTodayDurationMs();
        expect(result.isFailure, isTrue);
      });

      test('getTodaySessionCount returns failure when box is closed', () async {
        final result = await repository.getTodaySessionCount();
        expect(result.isFailure, isTrue);
      });

      test('getTodayCompletedSessionCount returns failure when box is closed',
          () async {
        final result = await repository.getTodayCompletedSessionCount();
        expect(result.isFailure, isTrue);
      });

      test('getWeeklyDurationMs returns failure when box is closed', () async {
        final result = await repository.getWeeklyDurationMs();
        expect(result.isFailure, isTrue);
      });

      test('getTodayStats returns failure when box is closed', () async {
        final result = await repository.getTodayStats();
        expect(result.isFailure, isTrue);
      });

      test('getSubjectStats returns failure when box is closed', () async {
        final result = await repository.getSubjectStats('sub-1');
        expect(result.isFailure, isTrue);
      });

      test('clearAll returns failure when box is closed', () async {
        final result = await repository.clearAll();
        expect(result.isFailure, isTrue);
      });

      test('save returns failure when box is closed', () async {
        final session = createSession(startTime: DateTime.now());
        final result = await repository.save(session.id, session);
        expect(result.isFailure, isTrue);
      });

      test('get returns failure when box is closed', () async {
        final result = await repository.get('any-key');
        expect(result.isFailure, isTrue);
      });

      test('delete returns failure when box is closed', () async {
        final result = await repository.delete('any-key');
        expect(result.isFailure, isTrue);
      });
    });

    group('attachBox', () {
      test('uses a pre-opened Hive box', () async {
        final box = await Hive.openBox<Session>('test_attach_box');
        final repo = SessionRepository();
        repo.attachBox(box);
        expect(repo.box, isNotNull);
        expect(repo.box.name, 'test_attach_box');
        await box.close();
      });
    });

    group('multiple sessions edge cases', () {
      test('getByType distinguishes all session types', () async {
        for (final type in SessionType.values) {
          final sess = createSession(
            id: 'type-${type.name}', startTime: DateTime(2025, 1, 15),
            type: type,
          );
          await repository.save(sess.id, sess);
        }
        for (final type in SessionType.values) {
          final results = await repository.getByType(type);
          expect(results.isSuccess, isTrue);
          expect(results.data!.length, 1);
          expect(results.data!.first.id, 'type-${type.name}');
        }
      });

      test('getTodayStats handles sessions without plannedDurationMinutes', () async {
        final noPlan = createSession(
          id: 'noplan', startTime: DateTime.now(), completed: true,
          actualDurationMs: 1000, plannedDurationMinutes: null,
        );
        await repository.save(noPlan.id, noPlan);
        final hasPlan = createSession(
          id: 'hasplan', startTime: DateTime.now(), completed: false,
          actualDurationMs: 2000, plannedDurationMinutes: 30,
        );
        await repository.save(hasPlan.id, hasPlan);
        final statsResult = await repository.getTodayStats();
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalMs'], 3000);
        expect(stats['totalSessions'], 2);
        expect(stats['completedSessions'], 1);
        expect(stats['plannedMinutes'], 30);
      });

      test('getSubjectStats computes perfect score', () async {
        final sess = createSession(
          id: 'perfect', subjectId: 'sub-perfect', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 1000, questionsAnswered: 10, correctAnswers: 10,
        );
        await repository.save(sess.id, sess);
        final statsResult = await repository.getSubjectStats('sub-perfect');
        expect(statsResult.isSuccess, isTrue);
        expect(statsResult.data!['avgScore'], 100.0);
      });

      test('getSubjectStats computes zero score', () async {
        final sess = createSession(
          id: 'zero', subjectId: 'sub-zero-score', startTime: DateTime(2025, 1, 15),
          actualDurationMs: 1000, questionsAnswered: 10, correctAnswers: 0,
        );
        await repository.save(sess.id, sess);
        final statsResult = await repository.getSubjectStats('sub-zero-score');
        expect(statsResult.isSuccess, isTrue);
        expect(statsResult.data!['avgScore'], 0.0);
      });

      test('getByStudentAndSubject returns empty for nonexistent student', () async {
        final sess = createSession(
          id: 's1', studentId: 'stu-1', subjectId: 'sub-1',
          startTime: DateTime(2025, 1, 15),
        );
        await repository.save(sess.id, sess);
        final results = await repository.getByStudentAndSubject('stu-99', 'sub-1');
        expect(results.isSuccess, isTrue);
        expect(results.data, isEmpty);
      });

      test('getRecentSessionsForSubject respects default limit of 10', () async {
        for (var i = 0; i < 15; i++) {
          final sess = createSession(
            id: 's$i', subjectId: 'sub-limit',
            startTime: DateTime(2025, 1, 15 + i),
          );
          await repository.save(sess.id, sess);
        }
        final results = await repository.getRecentSessionsForSubject('sub-limit');
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 10);
      });
    });

    group('hasSchedulingConflict', () {
      test('returns false when no sessions exist', () async {
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 0),
          durationMinutes: 60,
        );
        expect(conflict, isFalse);
      });

      test('returns false when no overlap exists', () async {
        final sess = createSession(
          id: 'existing',
          startTime: DateTime(2025, 1, 15, 10, 0),
          plannedDurationMinutes: 60,
          status: SessionStatus.planned,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 14, 0),
          durationMinutes: 60,
        );
        expect(conflict, isFalse);
      });

      test('returns true when sessions overlap', () async {
        final sess = createSession(
          id: 'existing',
          startTime: DateTime(2025, 1, 15, 10, 0),
          plannedDurationMinutes: 60,
          status: SessionStatus.planned,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 60,
        );
        expect(conflict, isTrue);
      });

      test('returns true when proposed is fully contained', () async {
        final sess = createSession(
          id: 'existing',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 12, 0),
          status: SessionStatus.inProgress,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 11, 0),
          durationMinutes: 30,
        );
        expect(conflict, isTrue);
      });

      test('skips excluded session', () async {
        final sess = createSession(
          id: 'to-exclude',
          startTime: DateTime(2025, 1, 15, 10, 0),
          plannedDurationMinutes: 120,
          status: SessionStatus.planned,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 60,
          excludeSessionId: 'to-exclude',
        );
        expect(conflict, isFalse);
      });

      test('skips session with no endTime and no plannedDurationMinutes',
          () async {
        final sess = createSession(
          id: 'no-duration',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: null,
          plannedDurationMinutes: null,
          status: SessionStatus.planned,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 60,
        );
        expect(conflict, isFalse);
      });

      test('detects conflict using endTime when available', () async {
        final sess = createSession(
          id: 'with-endtime',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 11, 0),
          plannedDurationMinutes: null,
          status: SessionStatus.completed,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 60,
        );
        expect(conflict, isTrue);
      });

      test('detects conflict using plannedDurationMinutes when no endTime',
          () async {
        final sess = createSession(
          id: 'planned-only',
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: null,
          plannedDurationMinutes: 60,
          status: SessionStatus.planned,
        );
        await repository.save(sess.id, sess);
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 30,
        );
        expect(conflict, isTrue);
      });

      test('returns false when box is closed', () async {
        final sess = createSession(
          id: 'close-test',
          startTime: DateTime(2025, 1, 15, 10, 0),
          plannedDurationMinutes: 60,
        );
        await repository.save(sess.id, sess);
        await Hive.close();
        final conflict = await repository.hasSchedulingConflict(
          startTime: DateTime(2025, 1, 15, 10, 30),
          durationMinutes: 60,
        );
        expect(conflict, isFalse);
      });
    });

    group('getScheduledLessons', () {
      test('returns empty when no sessions exist', () async {
        final lessons = await repository.getScheduledLessons();
        expect(lessons, isEmpty);
      });

      test('returns only planned sessions', () async {
        final planned = createSession(
          id: 'planned-1',
          startTime: DateTime(2025, 1, 15, 10, 0),
          status: SessionStatus.planned,
        );
        await repository.save(planned.id, planned);
        final inProgress = createSession(
          id: 'inprogress-1',
          startTime: DateTime(2025, 1, 15, 11, 0),
          status: SessionStatus.inProgress,
        );
        await repository.save(inProgress.id, inProgress);
        final completed = createSession(
          id: 'completed-1',
          startTime: DateTime(2025, 1, 15, 12, 0),
          status: SessionStatus.completed,
        );
        await repository.save(completed.id, completed);
        final cancelled = createSession(
          id: 'cancelled-1',
          startTime: DateTime(2025, 1, 15, 13, 0),
          status: SessionStatus.cancelled,
        );
        await repository.save(cancelled.id, cancelled);
        final lessons = await repository.getScheduledLessons();
        expect(lessons.length, 1);
        expect(lessons.first.id, 'planned-1');
        expect(lessons.first.status, SessionStatus.planned);
      });

      test('returns multiple planned sessions', () async {
        for (var i = 0; i < 3; i++) {
          final sess = createSession(
            id: 'planned-$i',
            startTime: DateTime(2025, 1, 15, 10 + i, 0),
            status: SessionStatus.planned,
          );
          await repository.save(sess.id, sess);
        }
        final lessons = await repository.getScheduledLessons();
        expect(lessons.length, 3);
      });

      test('returns empty when box is closed', () async {
        final sess = createSession(
          id: 's1',
          startTime: DateTime(2025, 1, 15, 10, 0),
          status: SessionStatus.planned,
        );
        await repository.save(sess.id, sess);
        await Hive.close();
        final lessons = await repository.getScheduledLessons();
        expect(lessons, isEmpty);
      });
    });
  });
}
