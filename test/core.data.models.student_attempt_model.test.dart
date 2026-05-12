import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';

void main() {
  group('StudentAttempt', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final attempt = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
        );
        expect(attempt.id, 'attempt-1');
        expect(attempt.studentId, 'student-1');
        expect(attempt.questionId, 'question-1');
        expect(attempt.subjectId, 'subject-1');
        expect(attempt.timestamp, now);
        expect(attempt.isCorrect, isFalse);
        expect(attempt.timeSpentMs, 0);
        expect(attempt.confidence, 3);
        expect(attempt.userAnswer, '');
        expect(attempt.markschemeMatch, isNull);
        expect(attempt.lastDueDate, isNull);
      });

      test('creates with all fields', () {
        final attempt = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
          isCorrect: true,
          timeSpentMs: 30000,
          confidence: 5,
          userAnswer: 'Paris',
          markschemeMatch: 'exact',
          lastDueDate: now,
        );
        expect(attempt.isCorrect, isTrue);
        expect(attempt.timeSpentMs, 30000);
        expect(attempt.confidence, 5);
        expect(attempt.userAnswer, 'Paris');
        expect(attempt.markschemeMatch, 'exact');
        expect(attempt.lastDueDate, now);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final attempt = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
          isCorrect: true,
          timeSpentMs: 30000,
          confidence: 5,
          userAnswer: 'Paris',
          markschemeMatch: 'exact',
          lastDueDate: now,
        );
        final json = attempt.toJson();
        expect(json['id'], 'attempt-1');
        expect(json['studentId'], 'student-1');
        expect(json['questionId'], 'question-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['isCorrect'], isTrue);
        expect(json['timeSpentMs'], 30000);
        expect(json['confidence'], 5);
        expect(json['timestamp'], now.toIso8601String());
        expect(json['userAnswer'], 'Paris');
        expect(json['markschemeMatch'], 'exact');
        expect(json['lastDueDate'], now.toIso8601String());
      });

      test('serializes with null optional fields', () {
        final attempt = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
        );
        final json = attempt.toJson();
        expect(json['isCorrect'], isFalse);
        expect(json['timeSpentMs'], 0);
        expect(json['confidence'], 3);
        expect(json['userAnswer'], '');
        expect(json['markschemeMatch'], isNull);
        expect(json['lastDueDate'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'attempt-1',
          'studentId': 'student-1',
          'questionId': 'question-1',
          'subjectId': 'subject-1',
          'isCorrect': true,
          'timeSpentMs': 30000,
          'confidence': 5,
          'timestamp': now.toIso8601String(),
          'userAnswer': 'Paris',
          'markschemeMatch': 'exact',
          'lastDueDate': now.toIso8601String(),
        };
        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.id, 'attempt-1');
        expect(attempt.isCorrect, isTrue);
        expect(attempt.timeSpentMs, 30000);
        expect(attempt.confidence, 5);
        expect(attempt.userAnswer, 'Paris');
        expect(attempt.markschemeMatch, 'exact');
        expect(attempt.lastDueDate, now);
      });

      test('applies defaults for missing fields', () {
        final json = {
          'id': 'attempt-1',
          'studentId': 'student-1',
          'questionId': 'question-1',
          'subjectId': 'subject-1',
          'timestamp': now.toIso8601String(),
        };
        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.isCorrect, isFalse);
        expect(attempt.timeSpentMs, 0);
        expect(attempt.confidence, 3);
        expect(attempt.userAnswer, '');
        expect(attempt.markschemeMatch, isNull);
        expect(attempt.lastDueDate, isNull);
      });

      test('handles null lastDueDate', () {
        final json = {
          'id': 'attempt-1',
          'studentId': 'student-1',
          'questionId': 'question-1',
          'subjectId': 'subject-1',
          'timestamp': now.toIso8601String(),
          'lastDueDate': null,
        };
        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.lastDueDate, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
          isCorrect: true,
          timeSpentMs: 30000,
          confidence: 5,
          userAnswer: 'Paris',
          markschemeMatch: 'exact',
          lastDueDate: now,
        );
        final json = original.toJson();
        final restored = StudentAttempt.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.isCorrect, original.isCorrect);
        expect(restored.timeSpentMs, original.timeSpentMs);
        expect(restored.confidence, original.confidence);
        expect(restored.userAnswer, original.userAnswer);
        expect(restored.markschemeMatch, original.markschemeMatch);
        expect(restored.lastDueDate, original.lastDueDate);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final attempt = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
        );
        final copy = attempt.copyWith();
        expect(copy.id, attempt.id);
        expect(copy.isCorrect, attempt.isCorrect);
        expect(copy.confidence, attempt.confidence);
      });

      test('updates specified fields', () {
        final attempt = StudentAttempt(
          id: 'attempt-1',
          studentId: 'student-1',
          questionId: 'question-1',
          subjectId: 'subject-1',
          timestamp: now,
        );
        final copy = attempt.copyWith(
          isCorrect: true,
          timeSpentMs: 50000,
          confidence: 4,
          userAnswer: 'Berlin',
        );
        expect(copy.isCorrect, isTrue);
        expect(copy.timeSpentMs, 50000);
        expect(copy.confidence, 4);
        expect(copy.userAnswer, 'Berlin');
        expect(copy.id, attempt.id);
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const attempt = StudentAttempt;
        expect(attempt.toString(), 'StudentAttempt');
      });
    });
  });
}
