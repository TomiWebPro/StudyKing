import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';

void main() {
  group('StudySession', () {
    late DateTime baseStartTime;
    late DateTime baseEndTime;

    setUp(() {
      baseStartTime = DateTime(2026, 1, 15, 10, 0, 0);
      baseEndTime = DateTime(2026, 1, 15, 11, 30, 0);
    });

    group('constructor', () {
      test('creates session with required fields only', () {
        final session = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        expect(session.id, 'test-id');
        expect(session.studentId, 'student-1');
        expect(session.subjectId, 'math');
        expect(session.startTime, baseStartTime);
        expect(session.endTime, isNull);
        expect(session.lessonId, '');
        expect(session.questionsAnswered, 0);
        expect(session.correctAnswers, 0);
        expect(session.timeSpentMs, 0);
      });

      test('creates session with all fields', () {
        final session = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          lessonId: 'lesson-1',
          startTime: baseStartTime,
          endTime: baseEndTime,
          questionsAnswered: 10,
          correctAnswers: 8,
          timeSpentMs: 5400000,
        );

        expect(session.id, 'test-id');
        expect(session.studentId, 'student-1');
        expect(session.subjectId, 'math');
        expect(session.lessonId, 'lesson-1');
        expect(session.startTime, baseStartTime);
        expect(session.endTime, baseEndTime);
        expect(session.questionsAnswered, 10);
        expect(session.correctAnswers, 8);
        expect(session.timeSpentMs, 5400000);
      });
    });

    group('toJson', () {
      test('serializes session with all fields to JSON', () {
        final session = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          lessonId: 'lesson-1',
          startTime: baseStartTime,
          endTime: baseEndTime,
          questionsAnswered: 10,
          correctAnswers: 8,
          timeSpentMs: 5400000,
        );

        final json = session.toJson();

        expect(json['id'], 'test-id');
        expect(json['studentId'], 'student-1');
        expect(json['subjectId'], 'math');
        expect(json['lessonId'], 'lesson-1');
        expect(json['startTime'], baseStartTime.toIso8601String());
        expect(json['endTime'], baseEndTime.toIso8601String());
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 8);
        expect(json['timeSpentMs'], 5400000);
      });

      test('serializes session with null endTime', () {
        final session = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final json = session.toJson();

        expect(json['endTime'], isNull);
      });

      test('serializes session with empty lessonId', () {
        final session = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final json = session.toJson();

        expect(json['lessonId'], '');
      });
    });

    group('fromJson', () {
      test('deserializes session from JSON with all fields', () {
        final json = {
          'id': 'test-id',
          'studentId': 'student-1',
          'subjectId': 'math',
          'lessonId': 'lesson-1',
          'startTime': baseStartTime.toIso8601String(),
          'endTime': baseEndTime.toIso8601String(),
          'questionsAnswered': 10,
          'correctAnswers': 8,
          'timeSpentMs': 5400000,
        };

        final session = StudySession.fromJson(json);

        expect(session.id, 'test-id');
        expect(session.studentId, 'student-1');
        expect(session.subjectId, 'math');
        expect(session.lessonId, 'lesson-1');
        expect(session.startTime, baseStartTime);
        expect(session.endTime, baseEndTime);
        expect(session.questionsAnswered, 10);
        expect(session.correctAnswers, 8);
        expect(session.timeSpentMs, 5400000);
      });

      test('deserializes session from JSON with missing optional fields', () {
        final json = {
          'id': 'test-id',
          'studentId': 'student-1',
          'subjectId': 'math',
          'startTime': baseStartTime.toIso8601String(),
        };

        final session = StudySession.fromJson(json);

        expect(session.id, 'test-id');
        expect(session.lessonId, '');
        expect(session.endTime, isNull);
        expect(session.questionsAnswered, 0);
        expect(session.correctAnswers, 0);
        expect(session.timeSpentMs, 0);
      });

      test('deserializes session from JSON with null endTime', () {
        final json = {
          'id': 'test-id',
          'studentId': 'student-1',
          'subjectId': 'math',
          'startTime': baseStartTime.toIso8601String(),
          'endTime': null,
          'questionsAnswered': 0,
          'correctAnswers': 0,
          'timeSpentMs': 0,
        };

        final session = StudySession.fromJson(json);

        expect(session.endTime, isNull);
      });

      test('deserializes session from JSON with null lessonId', () {
        final json = {
          'id': 'test-id',
          'studentId': 'student-1',
          'subjectId': 'math',
          'lessonId': null,
          'startTime': baseStartTime.toIso8601String(),
        };

        final session = StudySession.fromJson(json);

        expect(session.lessonId, '');
      });
    });

    group('copyWith', () {
      test('copies session with all fields unchanged when no parameters provided', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          lessonId: 'lesson-1',
          startTime: baseStartTime,
          endTime: baseEndTime,
          questionsAnswered: 10,
          correctAnswers: 8,
          timeSpentMs: 5400000,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.studentId, original.studentId);
        expect(copy.subjectId, original.subjectId);
        expect(copy.lessonId, original.lessonId);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.questionsAnswered, original.questionsAnswered);
        expect(copy.correctAnswers, original.correctAnswers);
        expect(copy.timeSpentMs, original.timeSpentMs);
      });

      test('copies session with id changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final copy = original.copyWith(id: 'new-id');

        expect(copy.id, 'new-id');
        expect(copy.studentId, original.studentId);
        expect(copy.subjectId, original.subjectId);
      });

      test('copies session with studentId changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final copy = original.copyWith(studentId: 'student-2');

        expect(copy.id, original.id);
        expect(copy.studentId, 'student-2');
        expect(copy.subjectId, original.subjectId);
      });

      test('copies session with subjectId changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final copy = original.copyWith(subjectId: 'science');

        expect(copy.subjectId, 'science');
        expect(copy.id, original.id);
      });

      test('copies session with lessonId changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final copy = original.copyWith(lessonId: 'lesson-2');

        expect(copy.lessonId, 'lesson-2');
      });

      test('copies session with startTime changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final newStartTime = DateTime(2026, 2, 1, 9, 0, 0);
        final copy = original.copyWith(startTime: newStartTime);

        expect(copy.startTime, newStartTime);
        expect(copy.id, original.id);
      });

      test('copies session with endTime changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final newEndTime = DateTime(2026, 1, 20, 14, 0, 0);
        final copy = original.copyWith(endTime: newEndTime);

        expect(copy.endTime, newEndTime);
      });

      test('copies session with questionsAnswered changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
          questionsAnswered: 10,
        );

        final copy = original.copyWith(questionsAnswered: 20);

        expect(copy.questionsAnswered, 20);
        expect(copy.correctAnswers, original.correctAnswers);
      });

      test('copies session with correctAnswers changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
          correctAnswers: 8,
        );

        final copy = original.copyWith(correctAnswers: 15);

        expect(copy.correctAnswers, 15);
      });

      test('copies session with timeSpentMs changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
          timeSpentMs: 3600000,
        );

        final copy = original.copyWith(timeSpentMs: 7200000);

        expect(copy.timeSpentMs, 7200000);
      });

      test('copies session with multiple fields changed', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
          questionsAnswered: 10,
          correctAnswers: 8,
        );

        final newEndTime = DateTime(2026, 1, 15, 12, 0, 0);
        final copy = original.copyWith(
          subjectId: 'science',
          endTime: newEndTime,
          questionsAnswered: 15,
          correctAnswers: 12,
        );

        expect(copy.id, original.id);
        expect(copy.studentId, original.studentId);
        expect(copy.subjectId, 'science');
        expect(copy.endTime, newEndTime);
        expect(copy.questionsAnswered, 15);
        expect(copy.correctAnswers, 12);
      });
    });

    group('roundtrip serialization', () {
      test('toJson then fromJson preserves all data', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          lessonId: 'lesson-1',
          startTime: baseStartTime,
          endTime: baseEndTime,
          questionsAnswered: 10,
          correctAnswers: 8,
          timeSpentMs: 5400000,
        );

        final json = original.toJson();
        final restored = StudySession.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.subjectId, original.subjectId);
        expect(restored.lessonId, original.lessonId);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.questionsAnswered, original.questionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
        expect(restored.timeSpentMs, original.timeSpentMs);
      });

      test('toJson then fromJson with partial data', () {
        final original = StudySession(
          id: 'test-id',
          studentId: 'student-1',
          subjectId: 'math',
          startTime: baseStartTime,
        );

        final json = original.toJson();
        final restored = StudySession.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.lessonId, '');
        expect(restored.endTime, isNull);
      });
    });
  });
}
