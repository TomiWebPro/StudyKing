import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';

void main() {
  group('Markscheme', () {
    group('constructor', () {
      test('creates with required fields', () {
        final ms = Markscheme(correctAnswer: 'Paris');
        expect(ms.questionId, '');
        expect(ms.correctAnswer, 'Paris');
        expect(ms.acceptableAnswers, []);
        expect(ms.explanation, isNull);
        expect(ms.markschemePoints, isNull);
        expect(ms.steps, []);
      });

      test('accepts all fields', () {
        final step = MarkSchemeStep(
          stepNumber: '1', requiredAnswer: 'F=ma', points: 2.0,
          description: 'State Newton\'s second law',
        );
        final ms = Markscheme(
          questionId: 'q1', correctAnswer: 'F=ma',
          acceptableAnswers: ['F = m * a', 'Force equals mass times acceleration'],
          explanation: 'Newton\'s second law', markschemePoints: 5.0,
          steps: [step],
        );
        expect(ms.questionId, 'q1');
        expect(ms.acceptableAnswers.length, 2);
        expect(ms.explanation, 'Newton\'s second law');
        expect(ms.markschemePoints, 5.0);
        expect(ms.steps.length, 1);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final step = MarkSchemeStep(
          stepNumber: '1', requiredAnswer: 'Answer', points: 1.0,
        );
        final ms = Markscheme(
          questionId: 'q1', correctAnswer: 'Correct',
          acceptableAnswers: ['Alt1'], explanation: 'Exp',
          markschemePoints: 3.0, steps: [step],
        );
        final json = ms.toJson();
        expect(json['questionId'], 'q1');
        expect(json['correctAnswer'], 'Correct');
        expect(json['acceptableAnswers'], ['Alt1']);
        expect(json['explanation'], 'Exp');
        expect(json['markschemePoints'], 3.0);
        expect(json['steps'], isA<List>());
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'questionId': 'q1', 'correctAnswer': 'Paris',
          'acceptableAnswers': ['paris'], 'explanation': 'Capital',
          'markschemePoints': 2.0,
          'steps': [
            {'stepNumber': '1', 'requiredAnswer': 'Step1', 'points': 1.0},
          ],
        };
        final ms = Markscheme.fromJson(json);
        expect(ms.questionId, 'q1');
        expect(ms.correctAnswer, 'Paris');
        expect(ms.acceptableAnswers, ['paris']);
        expect(ms.explanation, 'Capital');
        expect(ms.markschemePoints, 2.0);
        expect(ms.steps.length, 1);
      });

      test('handles missing optional fields', () {
        final json = {'correctAnswer': 'Ans'};
        final ms = Markscheme.fromJson(json);
        expect(ms.questionId, '');
        expect(ms.acceptableAnswers, []);
        expect(ms.explanation, isNull);
        expect(ms.markschemePoints, isNull);
        expect(ms.steps, []);
      });

      test('handles null steps', () {
        final json = {'correctAnswer': 'Ans', 'steps': null};
        final ms = Markscheme.fromJson(json);
        expect(ms.steps, []);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final step = MarkSchemeStep(
          stepNumber: '1', requiredAnswer: 'A', points: 1.0,
        );
        final original = Markscheme(
          questionId: 'q1', correctAnswer: 'Ans',
          acceptableAnswers: ['Alt'], steps: [step],
        );
        final restored = Markscheme.fromJson(original.toJson());
        expect(restored.questionId, original.questionId);
        expect(restored.correctAnswer, original.correctAnswer);
        expect(restored.steps.length, original.steps.length);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final ms = Markscheme(correctAnswer: 'Ans');
        final copy = ms.copyWith();
        expect(copy.correctAnswer, ms.correctAnswer);
      });

      test('updates specified fields', () {
        final ms = Markscheme(correctAnswer: 'Old');
        final copy = ms.copyWith(correctAnswer: 'New', explanation: 'Exp');
        expect(copy.correctAnswer, 'New');
        expect(copy.explanation, 'Exp');
      });
    });

    group('isMatch', () {
      test('matches exact answer', () {
        final ms = Markscheme(correctAnswer: 'Paris');
        expect(ms.isMatch('Paris'), isTrue);
      });

      test('matches case-insensitive', () {
        final ms = Markscheme(correctAnswer: 'Paris');
        expect(ms.isMatch('paris'), isTrue);
      });

      test('matches trimmed', () {
        final ms = Markscheme(correctAnswer: 'Paris');
        expect(ms.isMatch('  Paris  '), isTrue);
      });

      test('matches acceptable answer', () {
        final ms = Markscheme(
          correctAnswer: 'Paris',
          acceptableAnswers: ['The capital of France'],
        );
        expect(ms.isMatch('the capital of france'), isTrue);
      });

      test('does not match wrong answer', () {
        final ms = Markscheme(correctAnswer: 'Paris');
        expect(ms.isMatch('London'), isFalse);
      });
    });
  });

  group('MarkSchemeStep', () {
    group('constructor', () {
      test('creates with required fields', () {
        final step = MarkSchemeStep(
          stepNumber: '1', requiredAnswer: 'F=ma', points: 2.0,
        );
        expect(step.stepNumber, '1');
        expect(step.requiredAnswer, 'F=ma');
        expect(step.points, 2.0);
        expect(step.description, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final step = MarkSchemeStep(
          stepNumber: '1', requiredAnswer: 'A', points: 1.0,
          description: 'Desc',
        );
        final json = step.toJson();
        expect(json['stepNumber'], '1');
        expect(json['requiredAnswer'], 'A');
        expect(json['points'], 1.0);
        expect(json['description'], 'Desc');
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'stepNumber': '1', 'requiredAnswer': 'A', 'points': 2.0,
        };
        final step = MarkSchemeStep.fromJson(json);
        expect(step.stepNumber, '1');
        expect(step.requiredAnswer, 'A');
        expect(step.points, 2.0);
      });

      test('handles missing points', () {
        final json = {
          'stepNumber': '1', 'requiredAnswer': 'A',
        };
        final step = MarkSchemeStep.fromJson(json);
        expect(step.points, 1.0);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = MarkSchemeStep(
          stepNumber: '1', requiredAnswer: 'A', points: 3.0,
        );
        final restored = MarkSchemeStep.fromJson(original.toJson());
        expect(restored.stepNumber, original.stepNumber);
        expect(restored.points, original.points);
      });
    });
  });
}
