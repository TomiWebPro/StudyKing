import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/evaluation_adapter_service.dart';
import 'package:studyking/core/data/models/question_evaluation_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart' as legacy;
import 'package:studyking/core/data/enums.dart';

void main() {
  group('EvaluationAdapterService', () {
    late EvaluationAdapterService service;

    setUp(() {
      service = EvaluationAdapterService();
    });

    group('convertFromQuestion', () {
      test('converts question to evaluation', () {
        final question = Question(
          id: 'q1',
          text: 'What is 2+2?',
          type: QuestionType.singleChoice,
          difficulty: 1,
          subjectId: 'math',
          topicId: 'topic1',
          variantIds: [],
          sourceIds: [],
          allowedAnswerTypes: '',
          markscheme: '4',
          correctAnswer: '4',
          options: ['2', '3', '4', '5'],
          explanation: 'Simple addition',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final evaluation = service.convertFromQuestion(question);

        expect(evaluation.questionId, equals('q1'));
        expect(evaluation.correctAnswer, equals('4'));
      });

      test('handles question with empty markscheme', () {
        final question = Question(
          id: 'q1',
          text: 'What is 2+2?',
          type: QuestionType.singleChoice,
          difficulty: 1,
          subjectId: 'math',
          topicId: 'topic1',
          variantIds: [],
          sourceIds: [],
          allowedAnswerTypes: '',
          markscheme: '',
          correctAnswer: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final evaluation = service.convertFromQuestion(question);

        expect(evaluation.questionId, equals('q1'));
      });
    });

    group('convertFromLegacyMarkscheme', () {
      test('converts legacy markscheme with steps', () {
        final markscheme = legacy.Markscheme(
          correctAnswer: 'x = 5',
          acceptableAnswers: [],
          explanation: 'Solve for x',
          steps: ['Step 1: Subtract 3', 'Step 2: Divide by 2'],
        );

        final evaluation = service.convertFromLegacyMarkscheme('q1', markscheme);

        expect(evaluation.questionId, equals('q1'));
        expect(evaluation.correctAnswer, equals('x = 5'));
        expect(evaluation.evaluationType, equals(EvaluationType.stepBased));
        expect(evaluation.steps, isNotNull);
        expect(evaluation.steps!.length, equals(2));
      });

      test('converts legacy markscheme without steps', () {
        final markscheme = legacy.Markscheme(
          correctAnswer: '42',
          acceptableAnswers: [],
          explanation: 'The answer is 42',
          steps: [],
        );

        final evaluation = service.convertFromLegacyMarkscheme('q1', markscheme);

        expect(evaluation.evaluationType, equals(EvaluationType.exactMatch));
        expect(evaluation.steps, isNull);
      });

      test('handles empty steps list', () {
        final markscheme = legacy.Markscheme(
          correctAnswer: '42',
          acceptableAnswers: [],
          explanation: 'The answer is 42',
          steps: [],
        );

        final evaluation = service.convertFromLegacyMarkscheme('q1', markscheme);

        expect(evaluation.steps, isNull);
      });
    });

    group('convertFromMarkschemeModel', () {
      test('converts with steps', () {
        final evaluation = service.convertFromMarkschemeModel(
          'q1',
          'x = 5',
          acceptableAnswers: ['x=5', '5'],
          explanation: 'Solve for x',
          steps: ['Step 1', 'Step 2'],
        );

        expect(evaluation.questionId, equals('q1'));
        expect(evaluation.correctAnswer, equals('x = 5'));
        expect(evaluation.evaluationType, equals(EvaluationType.stepBased));
        expect(evaluation.steps!.length, equals(2));
      });

      test('converts without steps', () {
        final evaluation = service.convertFromMarkschemeModel(
          'q1',
          '42',
          explanation: 'The answer',
        );

        expect(evaluation.evaluationType, equals(EvaluationType.exactMatch));
        expect(evaluation.steps, isNull);
      });

      test('handles null acceptable answers', () {
        final evaluation = service.convertFromMarkschemeModel(
          'q1',
          '42',
        );

        expect(evaluation.acceptableAnswers, isEmpty);
      });
    });

    group('validateWithEvaluation', () {
      test('validates correct answer', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          evaluationType: EvaluationType.exactMatch,
          explanation: 'The answer is 42',
        );

        final result = service.validateWithEvaluation(evaluation, '42');

        expect(result.isCorrect, isTrue);
        expect(result.score, equals(1.0));
        expect(result.feedback, equals('The answer is 42'));
      });

      test('validates incorrect answer', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          evaluationType: EvaluationType.exactMatch,
          explanation: 'The answer is 42',
        );

        final result = service.validateWithEvaluation(evaluation, 'wrong');

        expect(result.isCorrect, isFalse);
        expect(result.score, equals(0.0));
        expect(result.feedback, contains('Incorrect'));
      });

      test('validates with acceptable answers', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          acceptableAnswers: ['42', 'forty-two'],
          evaluationType: EvaluationType.exactMatch,
        );

        final result = service.validateWithEvaluation(evaluation, 'forty-two');

        expect(result.isCorrect, isTrue);
      });

      test('validates step-based evaluation with all steps matched', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'x = 5',
          evaluationType: EvaluationType.stepBased,
          steps: [
            EvaluationStep(stepNumber: '1', requiredAnswer: 'subtract 3', points: 1.0),
            EvaluationStep(stepNumber: '2', requiredAnswer: 'divide by 2', points: 1.0),
          ],
        );

        final result = service.validateWithEvaluation(evaluation, 'First subtract 3 then divide by 2');

        expect(result.isCorrect, isTrue);
        expect(result.score, greaterThan(0.0));
      });

      test('validates step-based evaluation with partial steps', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'x = 5',
          evaluationType: EvaluationType.stepBased,
          steps: [
            EvaluationStep(stepNumber: '1', requiredAnswer: 'subtract 3', points: 1.0),
            EvaluationStep(stepNumber: '2', requiredAnswer: 'divide by 2', points: 1.0),
          ],
        );

        final result = service.validateWithEvaluation(evaluation, 'First subtract 3');

        expect(result.isCorrect, isFalse);
        expect(result.score, lessThan(1.0));
        expect(result.feedback, contains('Missing'));
      });

      test('validates step-based evaluation with no steps matched', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'x = 5',
          evaluationType: EvaluationType.stepBased,
          steps: [
            EvaluationStep(stepNumber: '1', requiredAnswer: 'subtract 3', points: 1.0),
            EvaluationStep(stepNumber: '2', requiredAnswer: 'divide by 2', points: 1.0),
          ],
        );

        final result = service.validateWithEvaluation(evaluation, 'wrong answer');

        expect(result.isCorrect, isFalse);
        expect(result.score, equals(0.0));
        expect(result.feedback, contains('No required steps found'));
      });

      test('handles case insensitive matching', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          evaluationType: EvaluationType.exactMatch,
        );

        final result = service.validateWithEvaluation(evaluation, '42');

        expect(result.isCorrect, isTrue);
      });
    });

    group('toLegacyFormat', () {
      test('converts evaluation to legacy format', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          acceptableAnswers: ['42'],
          evaluationType: EvaluationType.exactMatch,
          explanation: 'The answer',
          maxPoints: 1.0,
        );

        final legacy = service.toLegacyFormat(evaluation);

        expect(legacy['questionId'], equals('q1'));
        expect(legacy['correctAnswer'], equals('42'));
        expect(legacy['explanation'], equals('The answer'));
        expect(legacy['markschemePoints'], equals(1.0));
      });

      test('handles evaluation with steps', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: 'x = 5',
          evaluationType: EvaluationType.stepBased,
          steps: [
            EvaluationStep(stepNumber: '1', requiredAnswer: 'subtract 3', points: 1.0),
          ],
        );

        final legacy = service.toLegacyFormat(evaluation);

        expect(legacy['steps'], isA<List>());
      });

      test('handles null explanation', () {
        final evaluation = QuestionEvaluation(
          questionId: 'q1',
          correctAnswer: '42',
          evaluationType: EvaluationType.exactMatch,
        );

        final legacy = service.toLegacyFormat(evaluation);

        expect(legacy['explanation'], isNull);
      });
    });
  });

  group('EvaluationResult', () {
    test('creates result with all fields', () {
      final result = EvaluationResult(
        isCorrect: true,
        score: 1.0,
        feedback: 'Correct!',
        explanation: 'Well done',
      );

      expect(result.isCorrect, isTrue);
      expect(result.score, equals(1.0));
      expect(result.feedback, equals('Correct!'));
      expect(result.explanation, equals('Well done'));
    });

    test('creates result without explanation', () {
      final result = EvaluationResult(
        isCorrect: false,
        score: 0.0,
        feedback: 'Incorrect',
      );

      expect(result.explanation, isNull);
    });
  });
}