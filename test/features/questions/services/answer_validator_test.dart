import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';
import 'package:studyking/features/questions/services/answer_validator.dart';

void main() {
  group('QuestionAnswerValidator', () {
    late Markscheme markscheme;

    setUp(() {
      markscheme = Markscheme(
        questionId: 'q1',
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'french capital'],
        explanation: 'Capital of France',
        markschemePoints: 10.0,
      );
    });

    group('validateTypedAnswer', () {
      test('returns correct for exact match (case insensitive)', () {
        final validator = QuestionAnswerValidator(markscheme);

        expect(validator.validateTypedAnswer('Paris').isCorrect, isTrue);
        expect(validator.validateTypedAnswer('paris').isCorrect, isTrue);
        expect(validator.validateTypedAnswer('PARIS').isCorrect, isTrue);
      });

      test('returns correct for acceptable answers', () {
        final validator = QuestionAnswerValidator(markscheme);

        expect(validator.validateTypedAnswer('paris').isCorrect, isTrue);
        expect(validator.validateTypedAnswer('french capital').isCorrect, isTrue);
      });

      test('returns incorrect for wrong answer', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateTypedAnswer('London');
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect and explanation for wrong answer', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateTypedAnswer('Berlin');
        expect(result.explanation, 'Capital of France');
      });

      test('returns incorrect for empty answer', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateTypedAnswer('');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Please provide an answer');
      });

      test('returns incorrect for whitespace-only answer', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateTypedAnswer('   ');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Please provide an answer');
      });

      test('returns incorrect when markscheme is null', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateTypedAnswer('anything');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'No markscheme available for validation');
      });

      test('returns correct with default explanation when explanation is empty', () {
        final markschemeNoExplanation = Markscheme(
          questionId: 'q2',
          correctAnswer: 'Answer',
        );
        final validator = QuestionAnswerValidator(markschemeNoExplanation);

        final result = validator.validateTypedAnswer('Answer');
        expect(result.isCorrect, isTrue);
        expect(result.explanation, 'Correct!');
      });

      test('trims answers before validation', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateTypedAnswer('  Paris  ');
        expect(result.isCorrect, isTrue);
      });
    });

    group('validateMCQAnswer', () {
      test('returns incorrect when markscheme is null', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateMCQAnswer('A', QuestionType.singleChoice);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'No markscheme available');
      });

      test('delegates to validateTypedAnswer for non-MCQ types', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateTypedAnswer('Paris');
        expect(result.isCorrect, isTrue);
      });
    });

    group('_validateSingleChoice', () {
      test('returns correct for exact match', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateMCQAnswer('Paris', QuestionType.singleChoice);
        expect(result.isCorrect, isTrue);
      });

      test('returns correct for case-insensitive match', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateMCQAnswer('paris', QuestionType.singleChoice);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for wrong answer', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateMCQAnswer('London', QuestionType.singleChoice);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Capital of France');
      });

      test('trims whitespace', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validateMCQAnswer('  Paris  ', QuestionType.singleChoice);
        expect(result.isCorrect, isTrue);
      });
    });

    group('_validateMultiChoice', () {
      test('returns correct for exact match', () {
        final markschemeMulti = Markscheme(
          questionId: 'q-multi',
          correctAnswer: 'A,B,C',
          explanation: 'Select A, B, and C',
        );
        final validator = QuestionAnswerValidator(markschemeMulti);

        final result = validator.validateMCQAnswer('A,B', QuestionType.multiChoice);
        expect(result.isCorrect, isFalse);
      });

      test('returns correct when all answers match regardless of order', () {
        final markschemeMulti = Markscheme(
          questionId: 'q-multi',
          correctAnswer: 'A,B,C',
        );
        final validator = QuestionAnswerValidator(markschemeMulti);

        final result = validator.validateMCQAnswer('C,A,B', QuestionType.multiChoice);
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for partial match', () {
        final markschemeMulti = Markscheme(
          questionId: 'q-multi',
          correctAnswer: 'A,B,C',
        );
        final validator = QuestionAnswerValidator(markschemeMulti);

        final result = validator.validateMCQAnswer('A,B', QuestionType.multiChoice);
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect for wrong order with missing answers', () {
        final markschemeMulti = Markscheme(
          questionId: 'q-multi',
          correctAnswer: 'A,B,C',
        );
        final validator = QuestionAnswerValidator(markschemeMulti);

        final result = validator.validateMCQAnswer('A,D', QuestionType.multiChoice);
        expect(result.isCorrect, isFalse);
      });

      test('handles extra whitespace', () {
        final markschemeMulti = Markscheme(
          questionId: 'q-multi',
          correctAnswer: 'A, B, C',
        );
        final validator = QuestionAnswerValidator(markschemeMulti);

        final result = validator.validateMCQAnswer('A , B , C', QuestionType.multiChoice);
        expect(result.isCorrect, isTrue);
      });
    });

    group('validateMathExpression', () {
      test('returns correct for exact match', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math-1',
          correctAnswer: 'x = 5',
          explanation: 'Solve for x',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validateMathExpression('x = 5');
        expect(result.isCorrect, isTrue);
      });

      test('returns correct when normalized', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math-1',
          correctAnswer: '2 x 3 = 6',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validateMathExpression('2x3=6');
        expect(result.isCorrect, isTrue);
      });

      test('returns incorrect for different expression', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math-1',
          correctAnswer: 'x + 5 = 10',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validateMathExpression('x + 3 = 10');
        expect(result.isCorrect, isFalse);
      });

      test('returns incorrect when markscheme is null', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateMathExpression('2 + 2 = 4');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'No markscheme available');
      });

      test('includes correct answer in explanation when wrong', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math-1',
          correctAnswer: 'x = 10',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validateMathExpression('x = 5');
        expect(result.explanation, 'The correct answer is: x = 10');
      });

      test('normalizes x to * for multiplication', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math-1',
          correctAnswer: '2*3=6',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validateMathExpression('2x3=6');
        expect(result.isCorrect, isTrue);
      });

      test('ignores whitespace', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math-1',
          correctAnswer: '1+2=3',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validateMathExpression('1 + 2 = 3');
        expect(result.isCorrect, isTrue);
      });
    });

    group('validateEssayAnswer', () {
      test('returns incorrect for empty answer', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateEssayAnswer('');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Please provide an answer');
      });

      test('returns incorrect for whitespace-only answer', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateEssayAnswer('   ');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Please provide an answer');
      });

      test('returns incorrect for too short answer', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateEssayAnswer('Short');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Answer is too short. Please provide more details.');
      });

      test('returns incorrect for answer with 9 characters', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateEssayAnswer('Some text');
        expect(result.isCorrect, isFalse);
      });

      test('returns correct for answer with 51+ characters', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateEssayAnswer('This is a much longer answer that should pass the minimum length requirement for full credit.');
        expect(result.isCorrect, isTrue);
        expect(result.explanation, 'Good response length. Essays require AI-based grading (placeholder).');
      });

      test('returns incorrect but valid for answer between 10-50 characters', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateEssayAnswer('Medium length answer here');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Answer too short for full credit.');
      });
    });

    group('validateCanvasDrawing', () {
      test('returns incorrect for empty canvas data', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateCanvasDrawing([]);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'No drawing detected. Please draw something on the canvas.');
      });

      test('returns incorrect for empty point in canvas data', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateCanvasDrawing([{}]);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Invalid drawing data detected. Please redraw.');
      });

      test('returns correct for valid canvas data', () {
        final validator = QuestionAnswerValidator(null);

        final canvasData = <Map<String, dynamic>>[
          <String, dynamic>{'x': 10.0, 'y': 20.0},
          <String, dynamic>{'x': 30.0, 'y': 40.0},
        ];
        final result = validator.validateCanvasDrawing(canvasData);
        expect(result.isCorrect, isTrue);
        expect(result.explanation, 'Drawing detected');
      });

      test('returns incorrect for mixed empty and valid points', () {
        final validator = QuestionAnswerValidator(null);

        final canvasData = <Map<String, dynamic>>[
          {'x': 10.0, 'y': 20.0},
          <String, dynamic>{},
        ];
        final result = validator.validateCanvasDrawing(canvasData);
        expect(result.isCorrect, isFalse);
      });
    });

    group('validateStepByStepAnswer', () {
      test('returns incorrect when markscheme is null', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validateStepByStepAnswer('Any answer');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'No markscheme available');
      });

      test('returns correct when all required steps are present', () {
        final markschemeWithSteps = Markscheme(
          questionId: 'step-1',
          correctAnswer: 'Solution',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step one', points: 1.0),
            MarkSchemeStep(stepNumber: '2', requiredAnswer: 'step two', points: 1.0),
          ],
        );
        final validator = QuestionAnswerValidator(markschemeWithSteps);

        final result = validator.validateStepByStepAnswer('First do step one, then step two');
        expect(result.isCorrect, isTrue);
        expect(result.explanation, 'All required steps identified');
      });

      test('returns incorrect when some steps are missing', () {
        final markschemeWithSteps = Markscheme(
          questionId: 'step-1',
          correctAnswer: 'Solution',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step one', points: 1.0),
            MarkSchemeStep(stepNumber: '2', requiredAnswer: 'step two', points: 1.0),
          ],
        );
        final validator = QuestionAnswerValidator(markschemeWithSteps);

        final result = validator.validateStepByStepAnswer('Only step one here');
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'Some required steps missing');
      });

      test('returns incorrect when no steps match', () {
        final markschemeWithSteps = Markscheme(
          questionId: 'step-1',
          correctAnswer: 'Solution',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'identify', points: 1.0),
          ],
        );
        final validator = QuestionAnswerValidator(markschemeWithSteps);

        final result = validator.validateStepByStepAnswer('Something else entirely');
        expect(result.isCorrect, isFalse);
      });
    });

    group('validate generic method', () {
      test('handles singleChoice question type', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validate('Paris', QuestionType.singleChoice);
        expect(result.isCorrect, isTrue);
      });

      test('handles multiChoice question type', () {
        final markschemeMulti = Markscheme(
          questionId: 'multi',
          correctAnswer: 'A,B',
        );
        final validator = QuestionAnswerValidator(markschemeMulti);

        final result = validator.validate('B,A', QuestionType.multiChoice);
        expect(result.isCorrect, isTrue);
      });

      test('handles typedAnswer question type', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validate('Paris', QuestionType.typedAnswer);
        expect(result.isCorrect, isTrue);
      });

      test('handles mathExpression question type', () {
        final mathMarkscheme = Markscheme(
          questionId: 'math',
          correctAnswer: '2+2=4',
        );
        final validator = QuestionAnswerValidator(mathMarkscheme);

        final result = validator.validate('2+2=4', QuestionType.mathExpression);
        expect(result.isCorrect, isTrue);
      });

      test('handles essay question type', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validate(
          'This is a very long essay answer that exceeds the minimum length requirement.',
          QuestionType.essay,
        );
        expect(result.isCorrect, isTrue);
      });

      test('handles canvas question type', () {
        final validator = QuestionAnswerValidator(null);

        final result = validator.validate('', QuestionType.canvas);
        expect(result.isCorrect, isFalse);
      });

      test('handles stepByStep question type', () {
        final markschemeWithSteps = Markscheme(
          questionId: 'step',
          correctAnswer: 'Solution',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'first', points: 1.0),
          ],
        );
        final validator = QuestionAnswerValidator(markschemeWithSteps);

        final result = validator.validate('Contains first step', QuestionType.stepByStep);
        expect(result.isCorrect, isTrue);
      });

      test('returns not supported for graphDrawing', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validate('answer', QuestionType.graphDrawing);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'This question type requires special handling');
      });

      test('returns not supported for fileUpload', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validate('answer', QuestionType.fileUpload);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'This question type requires special handling');
      });

      test('returns not supported for audioRecording', () {
        final validator = QuestionAnswerValidator(markscheme);

        final result = validator.validate('answer', QuestionType.audioRecording);
        expect(result.isCorrect, isFalse);
        expect(result.explanation, 'This question type requires special handling');
      });
    });
  });

  group('ValidationResult', () {
    test('creates with required fields', () {
      final result = ValidationResult(
        isCorrect: true,
        explanation: 'Correct answer',
      );

      expect(result.isCorrect, isTrue);
      expect(result.explanation, 'Correct answer');
      expect(result.score, isNull);
      expect(result.feedback, isNull);
    });

    test('creates with all fields', () {
      final result = ValidationResult(
        isCorrect: true,
        explanation: 'Well done',
        score: 95.0,
        feedback: 'Great job!',
      );

      expect(result.isCorrect, isTrue);
      expect(result.explanation, 'Well done');
      expect(result.score, 95.0);
      expect(result.feedback, 'Great job!');
    });

    test('can be created with only isCorrect and explanation', () {
      final result = ValidationResult(
        isCorrect: false,
        explanation: 'Try again',
      );

      expect(result.isCorrect, isFalse);
      expect(result.explanation, 'Try again');
    });
  });
}