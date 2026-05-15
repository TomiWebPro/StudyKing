import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/presentation/models/practice_models.dart';

void main() {
  group('PracticeAnswerRecord', () {
    test('stores all fields correctly', () {
      final record = PracticeAnswerRecord(
        questionId: 'q-1',
        questionType: QuestionType.typedAnswer,
        isCorrect: true,
        timeSpent: const Duration(seconds: 30),
        userAnswer: '42',
      );

      expect(record.questionId, 'q-1');
      expect(record.questionType, QuestionType.typedAnswer);
      expect(record.isCorrect, isTrue);
      expect(record.timeSpent, const Duration(seconds: 30));
      expect(record.userAnswer, '42');
    });

    test('stores incorrect answer record', () {
      final record = PracticeAnswerRecord(
        questionId: 'q-2',
        questionType: QuestionType.multiChoice,
        isCorrect: false,
        timeSpent: const Duration(seconds: 15),
        userAnswer: 'A,C',
      );

      expect(record.isCorrect, isFalse);
      expect(record.userAnswer, 'A,C');
    });

    test('stores singleChoice question type', () {
      final record = PracticeAnswerRecord(
        questionId: 'q-3',
        questionType: QuestionType.singleChoice,
        isCorrect: true,
        timeSpent: Duration.zero,
        userAnswer: 'B',
      );

      expect(record.questionType, QuestionType.singleChoice);
    });
  });

  group('PracticeSessionResult', () {
    test('stores questions answered and correct answers', () {
      final result = PracticeSessionResult(
        questionsAnswered: 10,
        correctAnswers: 7,
      );

      expect(result.questionsAnswered, 10);
      expect(result.correctAnswers, 7);
    });

    test('stores zero values', () {
      final result = PracticeSessionResult(
        questionsAnswered: 0,
        correctAnswers: 0,
      );

      expect(result.questionsAnswered, 0);
      expect(result.correctAnswers, 0);
    });

    test('stores all correct result', () {
      final result = PracticeSessionResult(
        questionsAnswered: 5,
        correctAnswers: 5,
      );

      expect(result.questionsAnswered, 5);
      expect(result.correctAnswers, 5);
    });
  });
}
