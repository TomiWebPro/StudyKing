import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_evaluation_model.dart';

void main() {
  group('QuestionEvaluation', () {
    group('constructor', () {
      test('creates with required fields', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        expect(eval.questionId, 'q-1');
        expect(eval.correctAnswer, 'Paris');
        expect(eval.acceptableAnswers, isEmpty);
        expect(eval.evaluationType, EvaluationType.exactMatch);
        expect(eval.version, 1);
      });

      test('creates with all fields', () {
        final step = EvaluationStep(stepNumber: '1', requiredAnswer: 'x=5', points: 1.0);
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'x=5',
          acceptableAnswers: ['5'],
          evaluationType: EvaluationType.stepBased,
          explanation: 'Solve for x',
          steps: [step],
          maxPoints: 5.0,
          metadata: {'source': 'test'},
          version: 2,
        );
        expect(eval.steps?.length, 1);
        expect(eval.maxPoints, 5.0);
        expect(eval.metadata?['source'], 'test');
        expect(eval.version, 2);
      });
    });

    group('isMatch', () {
      test('exact match returns true', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        expect(eval.isMatch('Paris'), isTrue);
      });

      test('case insensitive match', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        expect(eval.isMatch('paris'), isTrue);
        expect(eval.isMatch('PARIS'), isTrue);
      });

      test('trimmed match', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        expect(eval.isMatch('  Paris  '), isTrue);
      });

      test('acceptable answers match', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
          acceptableAnswers: ['France'],
        );
        expect(eval.isMatch('France'), isTrue);
      });

      test('non-match returns false', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        expect(eval.isMatch('London'), isFalse);
      });

      group('fuzzyMatch', () {
        test('similar answer with enough matching words returns true', () {
          final eval = QuestionEvaluation(
            questionId: 'q-1',
            correctAnswer: 'mitosis cell division',
            evaluationType: EvaluationType.fuzzyMatch,
          );
          expect(eval.isMatch('mitosis cell division process'), isTrue);
        });

        test('dissimilar answer returns false', () {
          final eval = QuestionEvaluation(
            questionId: 'q-1',
            correctAnswer: 'mitosis cell division process',
            evaluationType: EvaluationType.fuzzyMatch,
          );
          expect(eval.isMatch('meiosis reproduction'), isFalse);
        });

        test('empty answer returns false', () {
          final eval = QuestionEvaluation(
            questionId: 'q-1',
            correctAnswer: 'Paris',
            evaluationType: EvaluationType.fuzzyMatch,
          );
          expect(eval.isMatch(''), isFalse);
        });
      });

      group('stepBased', () {
        test('all steps present returns true', () {
          final eval = QuestionEvaluation(
            questionId: 'q-1',
            correctAnswer: 'x=5',
            evaluationType: EvaluationType.stepBased,
            steps: [
              EvaluationStep(stepNumber: '1', requiredAnswer: '2x', points: 1.0),
              EvaluationStep(stepNumber: '2', requiredAnswer: 'x=5', points: 1.0),
            ],
          );
          expect(eval.isMatch('First 2x then x=5'), isTrue);
        });

        test('missing steps returns false', () {
          final eval = QuestionEvaluation(
            questionId: 'q-1',
            correctAnswer: 'x=5',
            evaluationType: EvaluationType.stepBased,
            steps: [
              EvaluationStep(stepNumber: '1', requiredAnswer: '2x', points: 1.0),
              EvaluationStep(stepNumber: '2', requiredAnswer: 'x=5', points: 1.0),
            ],
          );
          expect(eval.isMatch('just x=5'), isFalse);
        });
      });
    });

    group('fromLegacy', () {
      test('creates from legacy fields', () {
        final eval = QuestionEvaluation.fromLegacy(
          questionId: 'q-1',
          markscheme: 'correct answer',
          options: ['alt1', 'alt2'],
          explanation: 'explanation',
        );
        expect(eval.correctAnswer, 'correct answer');
        expect(eval.acceptableAnswers, ['alt1', 'alt2']);
        expect(eval.explanation, 'explanation');
        expect(eval.evaluationType, EvaluationType.exactMatch);
      });
    });

    group('fromLegacyMarkscheme', () {
      test('creates from legacy markscheme with steps', () {
        final eval = QuestionEvaluation.fromLegacyMarkscheme(
          questionId: 'q-1',
          correctAnswer: 'x=5',
          steps: ['Step 1', 'Step 2'],
        );
        expect(eval.evaluationType, EvaluationType.stepBased);
        expect(eval.steps?.length, 2);
        expect(eval.steps?[0].requiredAnswer, 'Step 1');
      });

      test('creates from legacy markscheme without steps', () {
        final eval = QuestionEvaluation.fromLegacyMarkscheme(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        expect(eval.evaluationType, EvaluationType.exactMatch);
        expect(eval.steps, isNull);
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip preserves data', () {
        final original = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
          acceptableAnswers: ['France'],
          evaluationType: EvaluationType.exactMatch,
          explanation: 'Capital',
          maxPoints: 1.0,
          version: 2,
        );
        final json = original.toJson();
        final restored = QuestionEvaluation.fromJson(json);
        expect(restored.questionId, original.questionId);
        expect(restored.correctAnswer, original.correctAnswer);
        expect(restored.evaluationType, original.evaluationType);
        expect(restored.version, original.version);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final eval = QuestionEvaluation(
          questionId: 'q-1',
          correctAnswer: 'Paris',
        );
        final copy = eval.copyWith(correctAnswer: 'London', version: 2);
        expect(copy.correctAnswer, 'London');
        expect(copy.version, 2);
        expect(copy.questionId, 'q-1');
      });
    });
  });

  group('EvaluationStep', () {
    test('creates with required fields', () {
      final step = EvaluationStep(
        stepNumber: '1',
        requiredAnswer: 'x=5',
        points: 2.0,
      );
      expect(step.stepNumber, '1');
      expect(step.requiredAnswer, 'x=5');
      expect(step.points, 2.0);
      expect(step.description, isNull);
      expect(step.partialCredit, isNull);
    });

    test('creates with all fields', () {
      final step = EvaluationStep(
        stepNumber: '1',
        requiredAnswer: 'x=5',
        points: 2.0,
        description: 'Solve for x',
        partialCredit: 1.0,
      );
      expect(step.description, 'Solve for x');
      expect(step.partialCredit, 1.0);
    });

    test('toJson / fromJson roundtrip', () {
      final original = EvaluationStep(
        stepNumber: '1',
        requiredAnswer: 'x=5',
        points: 2.0,
        description: 'Solve',
        partialCredit: 1.0,
      );
      final json = original.toJson();
      final restored = EvaluationStep.fromJson(json);
      expect(restored.stepNumber, original.stepNumber);
      expect(restored.requiredAnswer, original.requiredAnswer);
      expect(restored.points, original.points);
      expect(restored.description, original.description);
    });
  });
}
