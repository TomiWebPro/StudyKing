import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/practice_data.dart';

void main() {
  group('practice_data barrel', () {
    test('MasteryState can be constructed with required fields', () {
      final now = DateTime.now();
      final state = MasteryState(
        studentId: 's1',
        topicId: 't1',
        lastAttempt: now,
        lastUpdated: now,
      );
      expect(state.studentId, 's1');
      expect(state.topicId, 't1');
      expect(state.accuracy, 0.0);
      expect(state.totalAttempts, 0);
    });

    test('QuestionMasteryState can be constructed with required fields', () {
      final state = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        lastAttempt: DateTime.now(),
      );
      expect(state.studentId, 's1');
      expect(state.questionId, 'q1');
      expect(state.correctCount, 0);
      expect(state.incorrectCount, 0);
    });

    test('StudentAttempt can be constructed with required fields', () {
      final attempt = StudentAttempt(
        id: 'a1',
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        timestamp: DateTime(2026, 5, 19),
      );
      expect(attempt.id, 'a1');
      expect(attempt.studentId, 's1');
      expect(attempt.questionId, 'q1');
      expect(attempt.isCorrect, false);
    });

    test('StudentAttempt defaults fields correctly', () {
      final attempt = StudentAttempt(
        id: 'a2',
        studentId: 's1',
        questionId: 'q2',
        subjectId: 'sub1',
        timestamp: DateTime(2026, 5, 19),
      );
      expect(attempt.timeSpentMs, 0);
      expect(attempt.confidence, 3);
    });
  });
}
