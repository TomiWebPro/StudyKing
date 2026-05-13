import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/services/answer_validator.dart';

void main() {
  group('AnswerValidationService (feature layer)', () {
    group('validateWithMarkschemeInstance', () {
      test('returns correct for exact typed answer match', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Paris');
        final result = service.validateWithMarkschemeInstance('Paris', QuestionType.typedAnswer, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for null markscheme', () {
        final service = AnswerValidationService();
        final result = service.validateWithMarkschemeInstance('answer', QuestionType.typedAnswer, null);
        expect(result.isCorrect, isFalse);
      });

      test('returns correct for acceptable answer via instance method', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(
          questionId: 'q1',
          correctAnswer: 'Paris',
          acceptableAnswers: ['paris', 'PARIS'],
        );
        final result = service.validateWithMarkschemeInstance('paris', QuestionType.typedAnswer, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for wrong typed answer', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Paris');
        final result = service.validateWithMarkschemeInstance('London', QuestionType.typedAnswer, markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('validates single choice through instance method', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Option A');
        final result = service.validateWithMarkschemeInstance('Option A', QuestionType.singleChoice, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for canvas type via instance (empty canvas)', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final result = service.validateWithMarkschemeInstance('drawing', QuestionType.canvas, markscheme);
        expect(result.isCorrect, isFalse);
      });
    });

    group('validateMCQAnswerWithMarkscheme (static)', () {
      test('validates correct single choice answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Option A');
        final result = AnswerValidationService.validateMCQAnswerWithMarkscheme('Option A', QuestionType.singleChoice, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates incorrect single choice answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Option A');
        final result = AnswerValidationService.validateMCQAnswerWithMarkscheme('Option B', QuestionType.singleChoice, markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('validates correct multi choice answer with exact set', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'A,B');
        final result = AnswerValidationService.validateMCQAnswerWithMarkscheme('A,B', QuestionType.multiChoice, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates correct multi choice answer with different order', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'A,B');
        final result = AnswerValidationService.validateMCQAnswerWithMarkscheme('B,A', QuestionType.multiChoice, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates incorrect multi choice answer with missing answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'A,B');
        final result = AnswerValidationService.validateMCQAnswerWithMarkscheme('A', QuestionType.multiChoice, markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for null markscheme in MCQ', () {
        final result = AnswerValidationService.validateMCQAnswerWithMarkscheme('A', QuestionType.singleChoice, null);
        expect(result.isCorrect, isFalse);
      });
    });

    group('validateMathExpressionWithMarkscheme (static)', () {
      test('validates exact math expression', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x=2');
        final result = AnswerValidationService.validateMathExpressionWithMarkscheme('x=2', markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates math expression with whitespace normalization', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x=2');
        final result = AnswerValidationService.validateMathExpressionWithMarkscheme('x = 2', markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates math expression with case normalization', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'X=2');
        final result = AnswerValidationService.validateMathExpressionWithMarkscheme('x=2', markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for wrong math expression', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x=2');
        final result = AnswerValidationService.validateMathExpressionWithMarkscheme('x=3', markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for null markscheme', () {
        final result = AnswerValidationService.validateMathExpressionWithMarkscheme('x=2', null);
        expect(result.isCorrect, isFalse);
      });
    });

    group('validateCanvasDrawingWithMarkscheme (static)', () {
      test('validates canvas drawing with non-empty stroke data', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final canvasData = <Map<String, dynamic>>[{'type': 'stroke', 'points': [1.0, 2.0, 3.0]}];
        final result = AnswerValidationService.validateCanvasDrawingWithMarkscheme(canvasData, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates canvas drawing with multiple strokes', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final canvasData = <Map<String, dynamic>>[
          {'type': 'stroke', 'points': [0.0, 0.0, 10.0, 10.0]},
          {'type': 'stroke', 'points': [5.0, 5.0, 15.0, 15.0]},
        ];
        final result = AnswerValidationService.validateCanvasDrawingWithMarkscheme(canvasData, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for empty canvas data', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final result = AnswerValidationService.validateCanvasDrawingWithMarkscheme([], markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for empty point map', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final canvasData = <Map<String, dynamic>>[<String, dynamic>{}];
        final result = AnswerValidationService.validateCanvasDrawingWithMarkscheme(canvasData, markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns correct for non-empty canvas even with null markscheme', () {
        final canvasData = <Map<String, dynamic>>[{'type': 'stroke'}];
        final result = AnswerValidationService.validateCanvasDrawingWithMarkscheme(canvasData, null);
        expect(result.isCorrect, isTrue);
      });
    });

    group('validateAnswer (instance method)', () {
      test('validates answer via instance wrapper returning correct', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'correct');
        final result = service.validateAnswer('correct', QuestionType.typedAnswer, 'q1', markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('uses cached validator on repeated call', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q-cache', correctAnswer: 'answer');
        final result1 = service.validateAnswer('answer', QuestionType.typedAnswer, 'q-cache', markscheme);
        final result2 = service.validateAnswer('answer', QuestionType.typedAnswer, 'q-cache', markscheme);
        expect(result1.isCorrect, isTrue);
        expect(result2.isCorrect, isTrue);
      });

      test('invalidates cache when markscheme changes', () {
        final service = AnswerValidationService();
        final ms1 = Markscheme(questionId: 'q-change', correctAnswer: 'old');
        final ms2 = Markscheme(questionId: 'q-change', correctAnswer: 'new');
        expect(service.validateAnswer('old', QuestionType.typedAnswer, 'q-change', ms1).isCorrect, isTrue);
        expect(service.validateAnswer('new', QuestionType.typedAnswer, 'q-change', ms2).isCorrect, isTrue);
      });
    });

    group('validateWithMarkscheme (static)', () {
      test('returns correct for exact match', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Berlin');
        final result = AnswerValidationService.validateWithMarkscheme('Berlin', QuestionType.typedAnswer, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for null markscheme', () {
        final result = AnswerValidationService.validateWithMarkscheme('answer', QuestionType.typedAnswer, null);
        expect(result.isCorrect, isFalse);
      });

      test('returns correct for acceptable answer via static method', () {
        final markscheme = Markscheme(
          questionId: 'q1',
          correctAnswer: 'Berlin',
          acceptableAnswers: ['berlin', 'germany capital'],
        );
        final result = AnswerValidationService.validateWithMarkscheme('berlin', QuestionType.typedAnswer, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for wrong answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Berlin');
        final result = AnswerValidationService.validateWithMarkscheme('London', QuestionType.typedAnswer, markscheme);
        expect(result.isCorrect, isFalse);
      });
    });

    group('validateTypedAnswerWithMarkscheme (static)', () {
      test('validates correct typed answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Answer');
        final result = AnswerValidationService.validateTypedAnswerWithMarkscheme('Answer', markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('validates incorrect typed answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Answer');
        final result = AnswerValidationService.validateTypedAnswerWithMarkscheme('Wrong', markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for empty answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Answer');
        final result = AnswerValidationService.validateTypedAnswerWithMarkscheme('', markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for null markscheme', () {
        final result = AnswerValidationService.validateTypedAnswerWithMarkscheme('Answer', null);
        expect(result.isCorrect, isFalse);
      });
    });

    group('validateEssayAnswerWithMarkscheme (static)', () {
      test('returns correct for long essay answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
        final result = AnswerValidationService.validateEssayAnswerWithMarkscheme('A' * 60, markscheme);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for short essay answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
        final result = AnswerValidationService.validateEssayAnswerWithMarkscheme('Short', markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for empty essay', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
        final result = AnswerValidationService.validateEssayAnswerWithMarkscheme('', markscheme);
        expect(result.isCorrect, isFalse);
      });

      test('returns correct for essay exactly at threshold', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
        final result = AnswerValidationService.validateEssayAnswerWithMarkscheme('A' * 51, markscheme);
        expect(result.isCorrect, isTrue);
      });
    });

    group('validateStepByStepWithMarkscheme (static)', () {
      test('returns correct when all required steps are present', () {
        final markscheme = Markscheme(
          questionId: 'q1',
          correctAnswer: 'answer',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
            MarkSchemeStep(stepNumber: '2', requiredAnswer: 'step2', points: 1.0),
          ],
        );
        final result = AnswerValidationService.validateStepByStepWithMarkscheme(
          'First I did step1 and then step2', markscheme,
        );
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect when some steps are missing', () {
        final markscheme = Markscheme(
          questionId: 'q1',
          correctAnswer: 'answer',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
            MarkSchemeStep(stepNumber: '2', requiredAnswer: 'step2', points: 1.0),
          ],
        );
        final result = AnswerValidationService.validateStepByStepWithMarkscheme(
          'Only step1 here', markscheme,
        );
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for null markscheme', () {
        final result = AnswerValidationService.validateStepByStepWithMarkscheme('answer', null);
        expect(result.isCorrect, isFalse);
      });
    });

    group('ValidationResult model', () {
      test('stores all fields correctly', () {
        final result = ValidationResult(
          isCorrect: true,
          explanation: 'Well done',
          score: 1.0,
          feedback: 'Perfect answer',
        );
        expect(result.isCorrect, isTrue);
        expect(result.explanation, 'Well done');
        expect(result.score, 1.0);
        expect(result.feedback, 'Perfect answer');
      });

      test('allows null score and feedback', () {
        final result = ValidationResult(
          isCorrect: false,
          explanation: 'Wrong',
        );
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Wrong');
        expect(result.score, isNull);
        expect(result.feedback, isNull);
      });
    });
  });
}
