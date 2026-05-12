import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';
import 'package:studyking/features/practice/services/answer_validation_service.dart';

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

      final result = service.validateAnswer(question, 'any answer');
      expect(result.isCorrect, isFalse);
      expect(result.explanation, contains('No markscheme'));
    });

    test('validates correct typed answer', () {
      final question = _question(
        id: 'q1',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
      );

      final result = service.validateAnswer(question, 'Paris');
      expect(result.isCorrect, isTrue);
    });

    test('validates incorrect typed answer', () {
      final question = _question(
        id: 'q2',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
      );

      final result = service.validateAnswer(question, 'London');
      expect(result.isCorrect, isFalse);
    });

    test('caches validator for same question', () {
      final question = _question(
        id: 'q-cache',
        type: QuestionType.typedAnswer,
        correctAnswer: '42',
      );

      final result1 = service.validateAnswer(question, '42');
      final result2 = service.validateAnswer(question, '42');
      expect(result1.isCorrect, isTrue);
      expect(result2.isCorrect, isTrue);
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

      final result1 = service.validateAnswer(question1, 'old');
      expect(result1.isCorrect, isTrue);

      final result2 = service.validateAnswer(question2, 'new');
      expect(result2.isCorrect, isTrue);
    });

    test('validates single choice answer', () {
      final question = _question(
        id: 'q-sc',
        type: QuestionType.singleChoice,
        correctAnswer: 'Option A',
      );

      final result = service.validateAnswer(question, 'Option A');
      expect(result.isCorrect, isTrue);
    });

    test('validates multi choice answer', () {
      final question = _question(
        id: 'q-mc',
        type: QuestionType.multiChoice,
        correctAnswer: 'A,B',
      );

      final result = service.validateAnswer(question, 'A,B');
      expect(result.isCorrect, isTrue);
    });

    test('validates canvas drawing answer', () {
      final question = _question(
        id: 'q-canvas',
        type: QuestionType.canvas,
        correctAnswer: 'Drawing submitted',
      );

      final result = service.validateAnswer(question, 'Drawing submitted');
      expect(result.isCorrect, isTrue);
    });

    test('validates essay answer', () {
      final question = _question(
        id: 'q-essay',
        type: QuestionType.essay,
        correctAnswer: '',
      );

      final result = service.validateAnswer(question, 'Long essay text');
      expect(result.isCorrect, isTrue);
    });

    test('accepts answers from acceptable answers list', () {
      final question = _question(
        id: 'q-accept',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'PARIS', 'city of light'],
      );

      final result = service.validateAnswer(question, 'paris');
      expect(result.isCorrect, isTrue);
    });

    test('validates math expression answer', () {
      final question = _question(
        id: 'q-math',
        type: QuestionType.mathExpression,
        correctAnswer: 'x=2',
      );

      final result = service.validateAnswer(question, 'x=2');
      expect(result.isCorrect, isTrue);
    });
  });
}
