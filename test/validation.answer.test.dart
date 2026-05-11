import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/services/answer_validation_service.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';

void main() {
  group('AnswerValidationService', () {
    late AnswerValidationService service;
    final now = DateTime.utc(2024, 1, 1);

    setUp(() {
      service = AnswerValidationService();
    });

    Question buildQuestion({
      required String id,
      required QuestionType type,
      String? markschemeText,
      List<String> options = const [],
      String? explanation,
    }) {
      return Question(
        id: id,
        text: 'Question $id',
        type: type,
        subjectId: 'sub-1',
        topicId: 'topic-1',
        markscheme: markschemeText != null ? Markscheme(questionId: id, correctAnswer: markschemeText) : null,
        options: options,
        explanation: explanation,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('signature generation (_signatureFor)', () {
      test('generates unique signature for different correct answers', () {
        final service1 = AnswerValidationService();
        final service2 = AnswerValidationService();

        final q1 = buildQuestion(id: 'q1', type: QuestionType.typedAnswer, markschemeText: 'Answer A');
        final q2 = buildQuestion(id: 'q2', type: QuestionType.typedAnswer, markschemeText: 'Answer B');

        final r1 = service1.validateAnswer(q1, 'Answer A');
        final r2 = service2.validateAnswer(q2, 'Answer B');

        expect(r1.isCorrect, isTrue);
        expect(r2.isCorrect, isTrue);
      });

      test('generates different signature for different acceptable answers', () {
        final q1 = buildQuestion(id: 'q1', type: QuestionType.typedAnswer, markschemeText: 'Correct', options: ['alt1']);
        final q2 = buildQuestion(id: 'q2', type: QuestionType.typedAnswer, markschemeText: 'Correct', options: ['alt2']);

        final r1 = service.validateAnswer(q1, 'alt1');
        final r2 = service.validateAnswer(q2, 'alt2');

        expect(r1.isCorrect, isTrue);
        expect(r2.isCorrect, isTrue);
      });

      test('generates different signature for different explanations', () {
        final q1 = buildQuestion(id: 'q1', type: QuestionType.typedAnswer, markschemeText: 'Answer', explanation: 'Explanation 1');
        final q2 = buildQuestion(id: 'q2', type: QuestionType.typedAnswer, markschemeText: 'Answer', explanation: 'Explanation 2');

        final r1 = service.validateAnswer(q1, 'answer');
        final r2 = service.validateAnswer(q2, 'answer');

        expect(r1.isCorrect, isTrue);
        expect(r2.isCorrect, isTrue);
      });
    });

    group('caching behavior (_getValidator)', () {
      test('reuses validator for same question ID with same signature', () {
        final question = buildQuestion(
          id: 'cache-test-1',
          type: QuestionType.typedAnswer,
          markschemeText: 'Paris',
        );

        final result1 = service.validateAnswer(question, 'Paris');
        final result2 = service.validateAnswer(question, 'paris');

        expect(result1.isCorrect, isTrue);
        expect(result2.isCorrect, isTrue);
      });

      test('creates new validator when question ID is different', () {
        final q1 = buildQuestion(id: 'id-1', type: QuestionType.typedAnswer, markschemeText: 'Answer');
        final q2 = buildQuestion(id: 'id-2', type: QuestionType.typedAnswer, markschemeText: 'Answer');

        final r1 = service.validateAnswer(q1, 'answer');
        final r2 = service.validateAnswer(q2, 'Answer');

        expect(r1.isCorrect, isTrue);
        expect(r2.isCorrect, isTrue);
      });

      test('cache key is based on question ID only', () {
        final q1 = buildQuestion(id: 'same-id', type: QuestionType.typedAnswer, markschemeText: 'First');
        final q2 = buildQuestion(id: 'same-id', type: QuestionType.typedAnswer, markschemeText: 'Second');

        final r1 = service.validateAnswer(q1, 'first');
        final r2 = service.validateAnswer(q2, 'second');
        final r3 = service.validateAnswer(q2, 'first');

        expect(r1.isCorrect, isTrue);
        expect(r2.isCorrect, isTrue);
        expect(r3.isCorrect, isFalse);
      });

      test('cache updates when markscheme signature changes', () {
        final q1 = buildQuestion(id: 'update-cache', type: QuestionType.typedAnswer, markschemeText: 'Original');
        final q2 = buildQuestion(id: 'update-cache', type: QuestionType.typedAnswer, markschemeText: 'Updated');

        final firstValidation = service.validateAnswer(q1, 'original');
        final afterUpdate = service.validateAnswer(q2, 'updated');

        expect(firstValidation.isCorrect, isTrue);
        expect(afterUpdate.isCorrect, isTrue);
        expect(service.validateAnswer(q2, 'original').isCorrect, isFalse);
      });

      test('multiple different questions maintain separate cache entries', () {
        final q1 = buildQuestion(id: 'multi-1', type: QuestionType.typedAnswer, markschemeText: 'ans1');
        final q2 = buildQuestion(id: 'multi-2', type: QuestionType.typedAnswer, markschemeText: 'ans2');
        final q3 = buildQuestion(id: 'multi-3', type: QuestionType.typedAnswer, markschemeText: 'ans3');

        expect(service.validateAnswer(q1, 'ans1').isCorrect, isTrue);
        expect(service.validateAnswer(q2, 'ans2').isCorrect, isTrue);
        expect(service.validateAnswer(q3, 'ans3').isCorrect, isTrue);
        expect(service.validateAnswer(q1, 'wrong').isCorrect, isFalse);
        expect(service.validateAnswer(q2, 'wrong').isCorrect, isFalse);
        expect(service.validateAnswer(q3, 'wrong').isCorrect, isFalse);
      });
    });

    group('validateAnswer with question properties', () {
      test('passes options as acceptableAnswers', () {
        final question = buildQuestion(
          id: 'options-test',
          type: QuestionType.typedAnswer,
          markschemeText: 'correct',
          options: ['alt1', 'alt2', 'alt3'],
        );

        expect(service.validateAnswer(question, 'alt1').isCorrect, isTrue);
        expect(service.validateAnswer(question, 'alt2').isCorrect, isTrue);
        expect(service.validateAnswer(question, 'alt3').isCorrect, isTrue);
        expect(service.validateAnswer(question, 'wrong').isCorrect, isFalse);
      });

      test('passes explanation from question to validator', () {
        final question = buildQuestion(
          id: 'explanation-test',
          type: QuestionType.typedAnswer,
          markschemeText: 'Answer',
          explanation: 'This is the detailed explanation',
        );

        final result = service.validateAnswer(question, 'wrong');
        expect(result.explanation, 'This is the detailed explanation');
      });

      test('uses default explanation when question explanation is null', () {
        final question = buildQuestion(
          id: 'no-explanation',
          type: QuestionType.typedAnswer,
          markschemeText: 'Answer',
        );

        final correctResult = service.validateAnswer(question, 'answer');
        final wrongResult = service.validateAnswer(question, 'wrong');

        expect(correctResult.explanation, 'Correct!');
        expect(wrongResult.explanation, 'Incorrect');
      });

      test('handles empty options list', () {
        final question = buildQuestion(
          id: 'empty-options',
          type: QuestionType.typedAnswer,
          markschemeText: 'Correct',
          options: [],
        );

        expect(service.validateAnswer(question, 'Correct').isCorrect, isTrue);
        expect(service.validateAnswer(question, 'wrong').isCorrect, isFalse);
      });
    });

    group('validateAnswer with different question types', () {
      test('mathExpression type uses math validation', () {
        final question = buildQuestion(
          id: 'math-type',
          type: QuestionType.mathExpression,
          markschemeText: '2 + 2 = 4',
        );

        expect(service.validateAnswer(question, '2+2=4').isCorrect, isTrue);
        expect(service.validateAnswer(question, '2 + 2 = 4').isCorrect, isTrue);
      });

      test('essay type uses essay validation', () {
        final question = buildQuestion(
          id: 'essay-type',
          type: QuestionType.essay,
          markschemeText: '',
        );

        final shortAnswer = service.validateAnswer(question, 'Short');
        final longAnswer = service.validateAnswer(
          question,
          'This is a very long answer that contains enough characters to pass the minimum length requirement for essay validation.',
        );

        expect(shortAnswer.isCorrect, isFalse);
        expect(longAnswer.isCorrect, isTrue);
      });

      test('stepByStep type validates required steps', () {
        final question = buildQuestion(
          id: 'step-type',
          type: QuestionType.stepByStep,
          markschemeText: 'Solution',
        );

        final resultWithSteps = service.validateAnswer(question, 'First do step one, then step two');
        expect(resultWithSteps.isCorrect, isTrue);
      });

      test('canvas type validates canvas data', () {
        final question = buildQuestion(
          id: 'canvas-type',
          type: QuestionType.canvas,
          markschemeText: '',
        );

        final result = service.validateAnswer(question, '');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, contains('canvas'));
      });
    });

    group('edge cases', () {
      test('handles null markscheme in question', () {
        final question = buildQuestion(
          id: 'null-markscheme',
          type: QuestionType.typedAnswer,
          markschemeText: null,
        );

        final result = service.validateAnswer(question, 'anything');
        expect(result.isCorrect, isFalse);
      });

      test('handles empty string markscheme', () {
        final question = buildQuestion(
          id: 'empty-markscheme',
          type: QuestionType.typedAnswer,
          markschemeText: '',
        );

        final result = service.validateAnswer(question, 'answer');
        expect(result.isCorrect, isFalse);
      });

      test('handles whitespace-only answer', () {
        final question = buildQuestion(
          id: 'whitespace-answer',
          type: QuestionType.typedAnswer,
          markschemeText: 'correct',
        );

        final result = service.validateAnswer(question, '   ');
        expect(result.isCorrect, isFalse);
      });

      test('handles very long answer', () {
        final question = buildQuestion(
          id: 'long-answer',
          type: QuestionType.typedAnswer,
          markschemeText: 'answer',
        );

        final longAnswer = 'a' * 1000;
        final result = service.validateAnswer(question, longAnswer);
        expect(result.isCorrect, isFalse);
      });

      test('handles special characters in markscheme', () {
        final question = buildQuestion(
          id: 'special-chars',
          type: QuestionType.typedAnswer,
          markschemeText: 'Test <>&"\'123',
        );

        expect(service.validateAnswer(question, 'test <>&"\'123').isCorrect, isTrue);
      });
    });

    group('validateAnswer integration', () {
      test('validates multiple questions in sequence correctly', () {
        final questions = [
          buildQuestion(id: 'seq-1', type: QuestionType.typedAnswer, markschemeText: 'Answer 1'),
          buildQuestion(id: 'seq-2', type: QuestionType.singleChoice, markschemeText: 'A', options: ['A', 'B']),
          buildQuestion(id: 'seq-3', type: QuestionType.multiChoice, markschemeText: 'A,B', options: ['A', 'B', 'C']),
        ];

        expect(service.validateAnswer(questions[0], 'answer 1').isCorrect, isTrue);
        expect(service.validateAnswer(questions[1], 'A').isCorrect, isTrue);
        expect(service.validateAnswer(questions[2], 'B,A').isCorrect, isTrue);
      });

      test('validation result contains explanation', () {
        final question = buildQuestion(
          id: 'result-info',
          type: QuestionType.typedAnswer,
          markschemeText: 'Correct',
          explanation: 'Detailed explanation here',
        );

        final result = service.validateAnswer(question, 'wrong');
        expect(result.explanation, isNotEmpty);
      });
    });
  });

  group('AnswerValidationService.validateAnswer', () {
    final service = AnswerValidationService();
    final now = DateTime.utc(2024, 1, 1);

    Question buildQuestion({
      required String id,
      required QuestionType type,
      String? markschemeText,
      List<String> options = const [],
    }) {
      return Question(
        id: id,
        text: 'Question $id',
        type: type,
        subjectId: 'sub-1',
        topicId: 'topic-1',
        markscheme: markschemeText != null ? Markscheme(questionId: id, correctAnswer: markschemeText) : null,
        options: options,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('typed answer is correct with markscheme match and wrong without markscheme', () {
      final withMarkscheme = buildQuestion(
        id: 'typed-1',
        type: QuestionType.typedAnswer,
        markschemeText: 'Paris',
      );
      final withoutMarkscheme = buildQuestion(
        id: 'typed-2',
        type: QuestionType.typedAnswer,
        markschemeText: null,
      );

      final correctResult = service.validateAnswer(withMarkscheme, 'paris');
      final missingResult = service.validateAnswer(withoutMarkscheme, 'anything');

      expect(correctResult.isCorrect, isTrue);
      expect(missingResult.isCorrect, isFalse);
    });

    test('single-choice uses exact answer validation', () {
      final question = buildQuestion(
        id: 'single-1',
        type: QuestionType.singleChoice,
        markschemeText: 'B',
        options: const ['A', 'B', 'C'],
      );

      expect(service.validateAnswer(question, 'B').isCorrect, isTrue);
      expect(service.validateAnswer(question, 'A').isCorrect, isFalse);
    });

    test('multi-choice accepts equal sets and rejects partial answers', () {
      final question = buildQuestion(
        id: 'multi-1',
        type: QuestionType.multiChoice,
        markschemeText: 'A,C',
        options: const ['A', 'B', 'C', 'D'],
      );

      expect(service.validateAnswer(question, 'C, A').isCorrect, isTrue);
      expect(service.validateAnswer(question, 'A').isCorrect, isFalse);
    });

    test('cache refreshes validator when same question id markscheme changes', () {
      final original = buildQuestion(
        id: 'cache-1',
        type: QuestionType.singleChoice,
        markschemeText: 'A',
        options: const ['A', 'B'],
      );
      final updated = buildQuestion(
        id: 'cache-1',
        type: QuestionType.singleChoice,
        markschemeText: 'B',
        options: const ['A', 'B'],
      );

      final first = service.validateAnswer(original, 'A');
      final second = service.validateAnswer(updated, 'B');
      final staleCheck = service.validateAnswer(updated, 'A');

      expect(first.isCorrect, isTrue);
      expect(second.isCorrect, isTrue);
      expect(staleCheck.isCorrect, isFalse);
    });
  });
}
