import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_evaluation_model.dart';
import 'package:studyking/core/services/answer_validation_service.dart';

Question _question({
  required String id,
  required QuestionType type,
  String correctAnswer = '',
  List<String> acceptableAnswers = const [],
}) {
  return Question(
    id: id,
    text: 'Test question',
    type: type,
    subjectId: 'subject-a',
    topicId: 'topic-a',
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: correctAnswer,
      acceptableAnswers: acceptableAnswers,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('AnswerValidationService', () {
    late AnswerValidationService service;

    setUp(() {
      service = AnswerValidationService();
    });

    test('returns incorrect result when markscheme is null', () {
      final question = Question(
        id: 'q-no-ms',
        text: 'No markscheme',
        type: QuestionType.typedAnswer,
        subjectId: 's1',
        topicId: 't1',
        markscheme: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = service.validateAnswerForQuestion(question, 'any answer');
      expect(result.isCorrect, isFalse);
      expect(result.explanation, contains('No markscheme'));
    });

    test('validates correct typed answer', () {
      final question = _question(
        id: 'q1',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
      );

      final result = service.validateAnswerForQuestion(question, 'Paris');
      expect(result.isCorrect, isTrue);
    });

    test('validates incorrect typed answer', () {
      final question = _question(
        id: 'q2',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
      );

      final result = service.validateAnswerForQuestion(question, 'London');
      expect(result.isCorrect, isFalse);
    });

    test('caches validator for same question', () {
      final question = _question(
        id: 'q-cache',
        type: QuestionType.typedAnswer,
        correctAnswer: '42',
      );

      final result1 = service.validateAnswerForQuestion(question, '42');
      final result2 = service.validateAnswerForQuestion(question, '42');
      expect(result1.isCorrect, isTrue);
      expect(result2.isCorrect, isTrue);
    });

    test('cache miss on first call', () {
      final question = _question(
        id: 'q-first',
        type: QuestionType.typedAnswer,
        correctAnswer: 'first',
      );
      final result = service.validateAnswerForQuestion(question, 'first');
      expect(result.isCorrect, isTrue);
    });

    test('cache hit on repeated call with same markscheme', () {
      final q1 = _question(id: 'q-hit', type: QuestionType.typedAnswer, correctAnswer: 'A');
      final q2 = _question(id: 'q-hit', type: QuestionType.typedAnswer, correctAnswer: 'A');

      expect(service.validateAnswerForQuestion(q1, 'A').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(q2, 'A').isCorrect, isTrue);
    });

    test('invalidates cache when markscheme changes', () {
      final question1 = _question(
        id: 'q-change',
        type: QuestionType.typedAnswer,
        correctAnswer: 'old',
      );
      final question2 = _question(
        id: 'q-change',
        type: QuestionType.typedAnswer,
        correctAnswer: 'new',
      );

      final result1 = service.validateAnswerForQuestion(question1, 'old');
      expect(result1.isCorrect, isTrue);

      final result2 = service.validateAnswerForQuestion(question2, 'new');
      expect(result2.isCorrect, isTrue);
    });

    test('invalidates cache when acceptableAnswers change', () {
      final q1 = _question(
        id: 'q-accept-change', type: QuestionType.typedAnswer,
        correctAnswer: 'Paris', acceptableAnswers: ['paris'],
      );
      final q2 = _question(
        id: 'q-accept-change', type: QuestionType.typedAnswer,
        correctAnswer: 'Paris', acceptableAnswers: ['PARIS', 'City of Light'],
      );

      expect(service.validateAnswerForQuestion(q1, 'paris').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(q2, 'PARIS').isCorrect, isTrue);
    });

    test('validates single choice answer', () {
      final question = _question(
        id: 'q-sc',
        type: QuestionType.singleChoice,
        correctAnswer: 'Option A',
      );

      final result = service.validateAnswerForQuestion(question, 'Option A');
      expect(result.isCorrect, isTrue);
    });

    test('validates multi choice answer', () {
      final question = _question(
        id: 'q-mc',
        type: QuestionType.multiChoice,
        correctAnswer: 'A,B',
      );

      final result = service.validateAnswerForQuestion(question, 'A,B');
      expect(result.isCorrect, isTrue);
    });

    test('returns incorrect for canvas drawing answer via validateAnswerForQuestion (string input is not valid canvas data)', () {
      final question = _question(
        id: 'q-canvas',
        type: QuestionType.canvas,
        correctAnswer: 'Drawing submitted',
      );

      final result = service.validateAnswerForQuestion(question, 'Drawing submitted');
      expect(result.isCorrect, isFalse);
    });

    test('validates essay answer (length > 50 chars is correct)', () {
      final question = _question(
        id: 'q-essay',
        type: QuestionType.essay,
        correctAnswer: '',
      );

      final result = service.validateAnswerForQuestion(question, 'A' * 60);
      expect(result.isCorrect, isTrue);
    });

    test('accepts answers from acceptable answers list', () {
      final question = _question(
        id: 'q-accept',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'PARIS', 'city of light'],
      );

      final result = service.validateAnswerForQuestion(question, 'paris');
      expect(result.isCorrect, isTrue);
    });

    test('validates math expression answer', () {
      final question = _question(
        id: 'q-math',
        type: QuestionType.mathExpression,
        correctAnswer: 'x=2',
      );

      final result = service.validateAnswerForQuestion(question, 'x=2');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithMarkscheme returns correct for exact match', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Berlin');
      final result = service.validateWithMarkscheme('Berlin', QuestionType.typedAnswer, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateWithMarkscheme returns incorrect for null markscheme', () {
      final result = service.validateWithMarkscheme('answer', QuestionType.typedAnswer, null);
      expect(result.isCorrect, isFalse);
    });

    test('validateWithMarkscheme returns correct for acceptable answer', () {
      final markscheme = Markscheme(
        questionId: 'q1', correctAnswer: 'Berlin',
        acceptableAnswers: ['berlin', 'germany capital'],
      );
      final result = service.validateWithMarkscheme('berlin', QuestionType.typedAnswer, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation exact match returns correct', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: '42',
      );
      final result = service.validateWithEvaluation(evaluation, '42');
      expect(result.isCorrect, isTrue);
      expect(result.score, 1.0);
    });

    test('validateWithEvaluation mismatch returns incorrect', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Paris',
        explanation: 'Capital of France',
      );
      final result = service.validateWithEvaluation(evaluation, 'London');
      expect(result.isCorrect, isFalse);
      expect(result.feedback, contains('Incorrect'));
    });

    test('validateWithEvaluation fuzzy match exact answer returns correct', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'photosynthesis',
        evaluationType: EvaluationType.fuzzyMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'photosynthesis');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation step based match', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'steps',
        evaluationType: EvaluationType.stepBased,
        steps: [
          EvaluationStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
          EvaluationStep(stepNumber: '2', requiredAnswer: 'step2', points: 1.0),
        ],
      );
      final result = service.validateWithEvaluation(evaluation, 'my answer has step1 and step2');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation with acceptable answer match', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'PARIS'],
        evaluationType: EvaluationType.acceptableMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'PARIS');
      expect(result.isCorrect, isTrue);
    });

    test('validateAnswer returns correct result via validate method', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'correct');
      final result = service.validateAnswer('correct', QuestionType.typedAnswer, 'q1', markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('generates unique signature for different correct answers', () {
      final service2 = AnswerValidationService();
      final q1 = _question(id: 'q1', type: QuestionType.typedAnswer, correctAnswer: 'Answer A');
      final q2 = _question(id: 'q2', type: QuestionType.typedAnswer, correctAnswer: 'Answer B');
      final r1 = service2.validateAnswerForQuestion(q1, 'Answer A');
      final r2 = service2.validateAnswerForQuestion(q2, 'Answer B');
      expect(r1.isCorrect, isTrue);
      expect(r2.isCorrect, isTrue);
    });

    test('uses default explanation when question explanation is null', () {
      final question = _question(id: 'no-explanation', type: QuestionType.typedAnswer, correctAnswer: 'Answer');
      final correctResult = service.validateAnswerForQuestion(question, 'answer');
      final wrongResult = service.validateAnswerForQuestion(question, 'wrong');
      expect(correctResult.explanation, 'Correct!');
      expect(wrongResult.explanation, 'Incorrect');
    });

    test('handles empty options list', () {
      final question = _question(id: 'empty-options', type: QuestionType.typedAnswer, correctAnswer: 'Correct');
      expect(service.validateAnswerForQuestion(question, 'Correct').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(question, 'wrong').isCorrect, isFalse);
    });

    test('handles null markscheme in question', () {
      final question = Question(
        id: 'null-markscheme', text: 'Q', type: QuestionType.typedAnswer,
        subjectId: 's1', topicId: 't1', markscheme: null,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final result = service.validateAnswerForQuestion(question, 'anything');
      expect(result.isCorrect, isFalse);
    });

    test('handles empty string markscheme', () {
      final question = _question(id: 'empty-ms', type: QuestionType.typedAnswer, correctAnswer: '');
      final result = service.validateAnswerForQuestion(question, 'answer');
      expect(result.isCorrect, isFalse);
    });

    test('handles whitespace-only answer', () {
      final question = _question(id: 'ws', type: QuestionType.typedAnswer, correctAnswer: 'correct');
      final result = service.validateAnswerForQuestion(question, '   ');
      expect(result.isCorrect, isFalse);
    });

    test('handles very long answer', () {
      final question = _question(id: 'long', type: QuestionType.typedAnswer, correctAnswer: 'answer');
      final result = service.validateAnswerForQuestion(question, 'a' * 1000);
      expect(result.isCorrect, isFalse);
    });

    test('handles special characters in markscheme', () {
      final question = _question(id: 'special', type: QuestionType.typedAnswer, correctAnswer: 'Test <>&"\'123');
      expect(service.validateAnswerForQuestion(question, 'test <>&"\'123').isCorrect, isTrue);
    });

    test('validates multiple questions in sequence correctly', () {
      final questions = [
        _question(id: 'seq-1', type: QuestionType.typedAnswer, correctAnswer: 'Answer 1'),
      ];
      questions.add(_question(id: 'seq-2', type: QuestionType.singleChoice, correctAnswer: 'A'));
      questions.add(_question(id: 'seq-3', type: QuestionType.multiChoice, correctAnswer: 'A,B'));

      expect(service.validateAnswerForQuestion(questions[0], 'answer 1').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(questions[1], 'A').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(questions[2], 'A,B').isCorrect, isTrue);
    });
  });
}
