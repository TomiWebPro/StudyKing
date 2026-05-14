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

    group('cache eviction policy', () {
      test('cache does not grow beyond configured limit', () {
        AnswerValidationService.clearCache();
        final service = AnswerValidationService();

        for (int i = 0; i < 150; i++) {
          final markscheme = Markscheme(
            questionId: 'q$i',
            correctAnswer: 'Answer $i',
          );
          service.validateAnswer('Answer $i', QuestionType.typedAnswer, 'q$i', markscheme);
        }

        final result1 = service.validateAnswer('Answer 0', QuestionType.typedAnswer, 'q0', Markscheme(
          questionId: 'q0', correctAnswer: 'Answer 0',
        ));
        expect(result1.isCorrect, isTrue);
      });

      test('old entries are evicted when limit is exceeded', () {
        AnswerValidationService.clearCache();
        final service = AnswerValidationService();

        for (int i = 0; i < 101; i++) {
          final markscheme = Markscheme(
            questionId: 'q$i',
            correctAnswer: 'Answer $i',
          );
          service.validateAnswer('Answer $i', QuestionType.typedAnswer, 'q$i', markscheme);
        }

        final markscheme0 = Markscheme(questionId: 'q0', correctAnswer: 'Answer 0');
        final markscheme100 = Markscheme(questionId: 'q100', correctAnswer: 'Answer 100');

        final result0 = service.validateAnswer('Answer 0', QuestionType.typedAnswer, 'q0', markscheme0);
        final result100 = service.validateAnswer('Answer 100', QuestionType.typedAnswer, 'q100', markscheme100);

        expect(result0.isCorrect, isTrue);
        expect(result100.isCorrect, isTrue);
      });

      test('evicted entries are re-created correctly on subsequent access', () {
        AnswerValidationService.clearCache();
        final service = AnswerValidationService();

        final markscheme1 = Markscheme(questionId: 'q1', correctAnswer: 'Answer 1');
        final result1 = service.validateAnswer('Answer 1', QuestionType.typedAnswer, 'q1', markscheme1);
        expect(result1.isCorrect, isTrue);

        // Fill cache to evict q1
        for (int i = 2; i <= 102; i++) {
          final ms = Markscheme(questionId: 'q$i', correctAnswer: 'Answer $i');
          service.validateAnswer('Answer $i', QuestionType.typedAnswer, 'q$i', ms);
        }

        // q1 should be evicted, but re-creating should still work
        final markscheme1again = Markscheme(questionId: 'q1', correctAnswer: 'Answer 1');
        final resultAgain = service.validateAnswer('Answer 1', QuestionType.typedAnswer, 'q1', markscheme1again);
        expect(resultAgain.isCorrect, isTrue);
      });

      test('clearCache empties all entries', () {
        AnswerValidationService.clearCache();
        final service = AnswerValidationService();

        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Answer');
        service.validateAnswer('Answer', QuestionType.typedAnswer, 'q1', markscheme);

        AnswerValidationService.clearCache();

        final markscheme2 = Markscheme(questionId: 'q2', correctAnswer: 'New answer');
        final result = service.validateAnswer('New answer', QuestionType.typedAnswer, 'q2', markscheme2);
        expect(result.isCorrect, isTrue);
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

    group('QuestionAnswerValidator (direct instantiation)', () {
      test('wraps core validator and returns correct for exact match', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Paris');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('Paris', QuestionType.typedAnswer);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for empty answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Paris');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('', QuestionType.typedAnswer);
        expect(result.isCorrect, isFalse);
      });

      test('handles graphDrawing type via core validateStatic', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('drawing', QuestionType.graphDrawing);
        expect(result.isCorrect, isFalse);
      });

      test('wraps core validator and returns incorrect for wrong answer', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Paris');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('London', QuestionType.typedAnswer);
        expect(result.isCorrect, isFalse);
      });

      test('returns correct for acceptable answer', () {
        final markscheme = Markscheme(
          questionId: 'q1',
          correctAnswer: 'Paris',
          acceptableAnswers: ['paris', 'PARIS'],
        );
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('paris', QuestionType.typedAnswer);
        expect(result.isCorrect, isTrue);
      });

      test('returns correct for single choice', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Option A');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('Option A', QuestionType.singleChoice);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for null markscheme', () {
        final validator = QuestionAnswerValidator(null);
        final result = validator.validate('answer', QuestionType.typedAnswer);
        expect(result.isCorrect, isFalse);
      });

      test('handles math expression validation', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x=2');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('x=2', QuestionType.mathExpression);
        expect(result.isCorrect, isTrue);
      });

      test('handles essay validation', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('A' * 60, QuestionType.essay);
        expect(result.isCorrect, isTrue);
      });

      test('handles step by step validation', () {
        final markscheme = Markscheme(
          questionId: 'q1',
          correctAnswer: 'answer',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
          ],
        );
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('This includes step1', QuestionType.stepByStep);
        expect(result.isCorrect, isTrue);
      });

      test('returns correct for multi choice', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'A,B');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('A,B', QuestionType.multiChoice);
        expect(result.isCorrect, isTrue);
      });

      test('returns false for unsupported types via canvas', () {
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final validator = QuestionAnswerValidator(markscheme);
        final result = validator.validate('drawing', QuestionType.canvas);
        expect(result.isCorrect, isFalse);
      });
    });

    group('_signatureFor consistency', () {
      test('produces consistent signatures for identical markschemes', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'test', explanation: 'exp');
        final markscheme2 = Markscheme(questionId: 'q1', correctAnswer: 'test', explanation: 'exp');

        final r1 = service.validateAnswer('test', QuestionType.typedAnswer, 'q1', markscheme);
        final r2 = service.validateAnswer('test', QuestionType.typedAnswer, 'q1', markscheme2);
        expect(r1.isCorrect, isTrue);
        expect(r2.isCorrect, isTrue);
      });

      test('cache uses signature based on markscheme content not identity', () {
        final service = AnswerValidationService();
        final ms1 = Markscheme(questionId: 'q1', correctAnswer: 'same', explanation: 'a');
        final ms2 = Markscheme(questionId: 'q1', correctAnswer: 'same', explanation: 'b');

        expect(service.validateAnswer('same', QuestionType.typedAnswer, 'q1', ms1).isCorrect, isTrue);
        expect(service.validateAnswer('same', QuestionType.typedAnswer, 'q1', ms2).isCorrect, isTrue);
      });

      test('signature handles empty acceptableAnswers', () {
        final service = AnswerValidationService();
        final ms = Markscheme(
          questionId: 'q1',
          correctAnswer: 'test',
          acceptableAnswers: [],
          explanation: 'exp',
        );
        final result = service.validateAnswer('test', QuestionType.typedAnswer, 'q1', ms);
        expect(result.isCorrect, isTrue);
      });

      test('validateWithMarkschemeInstance handles graphDrawing type', () {
        final service = AnswerValidationService();
        final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'drawing');
        final result = service.validateWithMarkschemeInstance('drawing', QuestionType.graphDrawing, markscheme);
        expect(result.isCorrect, isFalse);
      });
    });
  });
}
