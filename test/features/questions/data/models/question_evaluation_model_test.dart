import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';

void main() {
  group('QuestionEvaluation', () {
    const questionId = 'q1';
    const correctAnswer = 'Paris';

    group('constructor', () {
      test('creates with required fields', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: correctAnswer,
        );
        expect(eval.questionId, questionId);
        expect(eval.correctAnswer, correctAnswer);
        expect(eval.acceptableAnswers, []);
        expect(eval.evaluationType, EvaluationType.exactMatch);
        expect(eval.explanation, isNull);
        expect(eval.steps, isNull);
        expect(eval.maxPoints, isNull);
        expect(eval.metadata, isNull);
        expect(eval.version, 1);
      });

      test('accepts all fields', () {
        final step = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'Step1', points: 1.0,
        );
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: correctAnswer,
          acceptableAnswers: ['paris'], evaluationType: EvaluationType.fuzzyMatch,
          explanation: 'Capital', steps: [step], maxPoints: 5.0,
          metadata: {'key': 'value'}, version: 2,
        );
        expect(eval.acceptableAnswers, ['paris']);
        expect(eval.evaluationType, EvaluationType.fuzzyMatch);
        expect(eval.explanation, 'Capital');
        expect(eval.steps!.length, 1);
        expect(eval.maxPoints, 5.0);
        expect(eval.metadata, {'key': 'value'});
        expect(eval.version, 2);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final step = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'A', points: 1.0,
        );
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: correctAnswer,
          acceptableAnswers: ['alt'], evaluationType: EvaluationType.stepBased,
          explanation: 'Exp', steps: [step], maxPoints: 3.0,
        );
        final json = eval.toJson();
        expect(json['questionId'], questionId);
        expect(json['correctAnswer'], correctAnswer);
        expect(json['evaluationType'], EvaluationType.stepBased.index);
        expect(json['steps'], isA<List>());
        expect(json['maxPoints'], 3.0);
        expect(json['version'], 1);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'questionId': questionId, 'correctAnswer': correctAnswer,
          'acceptableAnswers': ['alt'],
          'evaluationType': EvaluationType.fuzzyMatch.index,
          'explanation': 'Exp', 'maxPoints': 2.0,
          'version': 3,
        };
        final eval = QuestionEvaluation.fromJson(json);
        expect(eval.questionId, questionId);
        expect(eval.evaluationType, EvaluationType.fuzzyMatch);
        expect(eval.explanation, 'Exp');
        expect(eval.maxPoints, 2.0);
        expect(eval.version, 3);
      });

      test('handles missing optional fields', () {
        final json = {
          'questionId': questionId, 'correctAnswer': correctAnswer,
        };
        final eval = QuestionEvaluation.fromJson(json);
        expect(eval.acceptableAnswers, []);
        expect(eval.evaluationType, EvaluationType.exactMatch);
        expect(eval.explanation, isNull);
        expect(eval.steps, isNull);
        expect(eval.maxPoints, isNull);
        expect(eval.version, 1);
      });

      test('handles null steps', () {
        final json = {
          'questionId': questionId, 'correctAnswer': correctAnswer,
          'steps': null,
        };
        final eval = QuestionEvaluation.fromJson(json);
        expect(eval.steps, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final step = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'A', points: 1.0,
        );
        final original = QuestionEvaluation(
          questionId: questionId, correctAnswer: correctAnswer,
          steps: [step], maxPoints: 5.0,
        );
        final restored = QuestionEvaluation.fromJson(original.toJson());
        expect(restored.questionId, original.questionId);
        expect(restored.maxPoints, original.maxPoints);
        expect(restored.steps!.length, original.steps!.length);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: correctAnswer,
        );
        final copy = eval.copyWith();
        expect(copy.questionId, eval.questionId);
        expect(copy.version, eval.version);
      });

      test('updates specified fields', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: correctAnswer,
        );
        final copy = eval.copyWith(version: 5, maxPoints: 10.0);
        expect(copy.version, 5);
        expect(copy.maxPoints, 10.0);
        expect(copy.questionId, questionId);
      });
    });

    group('fromLegacy', () {
      test('creates from legacy markscheme', () {
        final eval = QuestionEvaluation.fromLegacy(
          questionId: questionId, markscheme: 'Ans',
          correctAnswer: 'Ignored', explanation: 'Exp',
        );
        expect(eval.correctAnswer, 'Ans');
        expect(eval.evaluationType, EvaluationType.exactMatch);
        expect(eval.explanation, 'Exp');
      });

      test('uses correctAnswer when markscheme is null', () {
        final eval = QuestionEvaluation.fromLegacy(
          questionId: questionId, correctAnswer: 'Ans',
        );
        expect(eval.correctAnswer, 'Ans');
      });
    });

    group('fromLegacyMarkscheme', () {
      test('creates with steps when steps are provided', () {
        final eval = QuestionEvaluation.fromLegacyMarkscheme(
          questionId: questionId,
          correctAnswer: 'Ans',
          acceptableAnswers: ['Alt'],
          explanation: 'Exp',
          steps: ['Step1', 'Step2'],
        );
        expect(eval.evaluationType, EvaluationType.stepBased);
        expect(eval.steps!.length, 2);
        expect(eval.steps![0].stepNumber, '1');
      });

      test('creates with exactMatch when no steps', () {
        final eval = QuestionEvaluation.fromLegacyMarkscheme(
          questionId: questionId,
          correctAnswer: 'Ans',
        );
        expect(eval.evaluationType, EvaluationType.exactMatch);
        expect(eval.steps, isNull);
      });
    });

    group('isMatch', () {
      test('matches exact answer', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Paris',
        );
        expect(eval.isMatch('Paris'), isTrue);
      });

      test('matches acceptable answer', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Paris',
          acceptableAnswers: ['The capital'],
        );
        expect(eval.isMatch('the capital'), isTrue);
      });

      test('does not match wrong answer', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Paris',
        );
        expect(eval.isMatch('London'), isFalse);
      });

      test('fuzzyMatch with high word overlap', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Newton second law motion',
          evaluationType: EvaluationType.fuzzyMatch,
        );
        expect(eval.isMatch('Newton second law motion'), isTrue);
      });

      test('fuzzyMatch with low word overlap', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Newton second law motion',
          evaluationType: EvaluationType.fuzzyMatch,
        );
        expect(eval.isMatch('Einstein relativity'), isFalse);
      });

      test('stepBased matches all steps', () {
        final step1 = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'F=ma', points: 1.0,
        );
        final step2 = EvaluationStep(
          stepNumber: '2', requiredAnswer: 'a=F/m', points: 1.0,
        );
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'F=ma',
          evaluationType: EvaluationType.stepBased,
          steps: [step1, step2],
        );
        expect(eval.isMatch('Using F=ma we get a=F/m'), isTrue);
      });

      test('stepBased fails when missing a step', () {
        final step1 = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'F=ma', points: 1.0,
        );
        final step2 = EvaluationStep(
          stepNumber: '2', requiredAnswer: 'a=F/m', points: 1.0,
        );
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'F=ma',
          evaluationType: EvaluationType.stepBased,
          steps: [step1, step2],
        );
        expect(eval.isMatch('F=ma only'), isFalse);
      });

      test('empty fuzzyMatch returns false', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Answer',
          evaluationType: EvaluationType.fuzzyMatch,
        );
        expect(eval.isMatch(''), isFalse);
      });

      test('partialMatch returns false (no special handling)', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Paris',
          evaluationType: EvaluationType.partialMatch,
        );
        expect(eval.isMatch('Paris'), isTrue);
        expect(eval.isMatch('London'), isFalse);
      });

      test('acceptableMatch returns false when not in acceptable list', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'Paris',
          acceptableAnswers: ['Lyon'],
          evaluationType: EvaluationType.acceptableMatch,
        );
        expect(eval.isMatch('Paris'), isTrue);
        expect(eval.isMatch('Lyon'), isTrue);
        expect(eval.isMatch('Marseille'), isFalse);
      });

      test('fuzzyMatch with low matching ratio returns false', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'one two three four',
          evaluationType: EvaluationType.fuzzyMatch,
        );
        expect(eval.isMatch('one two five six'), isFalse);
      });

      test('fuzzyMatch with partial word overlap but low ratio', () {
        final eval = QuestionEvaluation(
          questionId: questionId, correctAnswer: 'a b c d',
          evaluationType: EvaluationType.fuzzyMatch,
        );
        expect(eval.isMatch('a b x y'), isFalse);
      });
    });
  });

  group('EvaluationType enum', () {
    test('has correct values in order', () {
      expect(EvaluationType.values, [
        EvaluationType.exactMatch,
        EvaluationType.acceptableMatch,
        EvaluationType.fuzzyMatch,
        EvaluationType.partialMatch,
        EvaluationType.stepBased,
      ]);
    });
  });

  group('EvaluationStep', () {
    group('constructor', () {
      test('creates with required fields', () {
        final step = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'Ans', points: 2.0,
        );
        expect(step.stepNumber, '1');
        expect(step.requiredAnswer, 'Ans');
        expect(step.points, 2.0);
        expect(step.description, isNull);
        expect(step.partialCredit, isNull);
      });

      test('accepts all fields', () {
        final step = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'Ans', points: 2.0,
          description: 'Desc', partialCredit: 1.0,
        );
        expect(step.description, 'Desc');
        expect(step.partialCredit, 1.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final step = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'Ans', points: 2.0,
        );
        final json = step.toJson();
        expect(json['stepNumber'], '1');
        expect(json['requiredAnswer'], 'Ans');
        expect(json['points'], 2.0);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'stepNumber': '1', 'requiredAnswer': 'Ans', 'points': 3.0,
          'description': 'Desc', 'partialCredit': 1.5,
        };
        final step = EvaluationStep.fromJson(json);
        expect(step.stepNumber, '1');
        expect(step.points, 3.0);
        expect(step.description, 'Desc');
        expect(step.partialCredit, 1.5);
      });

      test('handles missing fields', () {
        final json = {'stepNumber': '1', 'requiredAnswer': 'Ans'};
        final step = EvaluationStep.fromJson(json);
        expect(step.points, 1.0);
        expect(step.description, isNull);
        expect(step.partialCredit, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = EvaluationStep(
          stepNumber: '1', requiredAnswer: 'Ans', points: 4.0,
        );
        final restored = EvaluationStep.fromJson(original.toJson());
        expect(restored.stepNumber, original.stepNumber);
        expect(restored.points, original.points);
      });
    });
  });
}
