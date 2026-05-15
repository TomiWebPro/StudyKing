import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
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
      await Hive.openBox<String>('sessions');
      repository = SessionRepository();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    group('save', () {
      test('stores a session', () async {
        final session = createSession(startTime: DateTime(2025, 1, 15, 10, 0));
        await repository.save(session);
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

      test('returns stored session', () async {
        final session = createSession(startTime: DateTime(2025, 1, 15, 10, 0));
        await repository.save(session);
        final storedResult = await repository.get(session.id);
        expect(storedResult.isSuccess, isTrue);
        final stored = storedResult.data;
        expect(stored, isNotNull);
        expect(stored!.id, session.id);
        expect(stored.studentId, session.studentId);
      });

      test('returns null for corrupt JSON', () async {
        final box = Hive.box<String>('sessions');
        await box.put('corrupt', 'not-json');
        final result = await repository.get('corrupt');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
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

      test('skips corrupt entries', () async {
        final box = Hive.box<String>('sessions');
        await box.put('good1', jsonEncode(createSession(
          id: 'good1', startTime: DateTime(2025, 1, 15, 10, 0),
        ).toJson()));
        await box.put('bad1', 'not-json');
        await box.put('good2', jsonEncode(createSession(
          id: 'good2', startTime: DateTime(2025, 1, 16, 10, 0),
        ).toJson()));
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
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
    });

    group('getByType', () {
      test('filters by session type', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15), type: SessionType.tutoring,
        ));
        await repository.save(createSession(
          id: 's2', startTime: DateTime(2025, 1, 15), type: SessionType.focus,
        ));
        final tutoringResult = await repository.getByType(SessionType.tutoring);
        expect(tutoringResult.isSuccess, isTrue);
        final tutoring = tutoringResult.data!;
        expect(tutoring.length, 1);
        expect(tutoring.first.id, 's1');
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
        final results = await repository.getByStudent('stu-1');
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 1);
        expect(results.data!.first.id, 's1');
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
    });

    group('getRecentSessionsForSubject', () {
      test('returns recent sessions limited by count', () async {
        for (var i = 0; i < 5; i++) {
          await repository.save(createSession(
            id: 's$i', subjectId: 'sub-1',
            startTime: DateTime(2025, 1, 15 + i),
          ));
        }
        final results = await repository.getRecentSessionsForSubject('sub-1', limit: 3);
        expect(results.isSuccess, isTrue);
        expect(results.data!.length, 3);
        expect(results.data![0].id, 's4');
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
      });
    });

    group('delete', () {
      test('removes a session', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime(2025, 1, 15),
        ));
        await repository.delete('s1');
        final result = await repository.get('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
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
        await repository.clearAll();
        final result = await repository.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
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
    });

    group('getTodayStats', () {
      test('returns empty stats when no sessions', () async {
        final statsResult = await repository.getTodayStats();
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalMs'], 0);
        expect(stats['totalSessions'], 0);
        expect(stats['completedSessions'], 0);
      });

      test('returns computed stats for today', () async {
        await repository.save(createSession(
          id: 's1', startTime: DateTime.now(), completed: true,
          actualDurationMs: 3600000, plannedDurationMinutes: 60,
        ));
        final statsResult = await repository.getTodayStats();
        expect(statsResult.isSuccess, isTrue);
        final stats = statsResult.data!;
        expect(stats['totalMs'], 3600000);
        expect(stats['totalSessions'], 1);
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
      });
    });
  });
}
