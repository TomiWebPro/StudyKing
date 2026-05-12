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
  });
}
