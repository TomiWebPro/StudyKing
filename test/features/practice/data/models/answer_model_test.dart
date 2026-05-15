import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';

void main() {
  group('QuestionChoice', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final choice = QuestionChoice(
          id: 'c1',
          questionId: 'q1',
          text: 'Paris',
          isCorrect: true,
        );

        expect(choice.id, 'c1');
        expect(choice.questionId, 'q1');
        expect(choice.text, 'Paris');
        expect(choice.isCorrect, isTrue);
      });

      test('uses default values for optional fields', () {
        final choice = QuestionChoice(
          id: 'c1',
          questionId: 'q1',
          text: 'Paris',
          isCorrect: true,
        );

        expect(choice.explanation, '');
        expect(choice.variantIds, []);
        expect(choice.confidenceScore, 0.0);
      });

      test('accepts custom values for optional fields', () {
        final choice = QuestionChoice(
          id: 'c2',
          questionId: 'q2',
          text: 'London',
          isCorrect: false,
          explanation: 'Not the capital of France',
          variantIds: ['v1', 'v2'],
          confidenceScore: 0.8,
        );

        expect(choice.explanation, 'Not the capital of France');
        expect(choice.variantIds, ['v1', 'v2']);
        expect(choice.confidenceScore, 0.8);
      });
    });

    group('toJson', () {
      test('returns correct map', () {
        final choice = QuestionChoice(
          id: 'c1',
          questionId: 'q1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'The capital of France',
          variantIds: ['v1'],
          confidenceScore: 0.9,
        );

        final json = choice.toJson();
        expect(json['id'], 'c1');
        expect(json['questionId'], 'q1');
        expect(json['text'], 'Paris');
        expect(json['isCorrect'], isTrue);
        expect(json['explanation'], 'The capital of France');
        expect(json['variantIds'], ['v1']);
        expect(json['confidenceScore'], 0.9);
      });
    });

    group('fromJson', () {
      test('creates instance from map', () {
        final json = {
          'id': 'c1',
          'questionId': 'q1',
          'text': 'Paris',
          'isCorrect': true,
          'explanation': 'The capital of France',
          'variantIds': ['v1'],
          'confidenceScore': 0.9,
        };

        final choice = QuestionChoice.fromJson(json);
        expect(choice.id, 'c1');
        expect(choice.questionId, 'q1');
        expect(choice.text, 'Paris');
        expect(choice.isCorrect, isTrue);
        expect(choice.explanation, 'The capital of France');
        expect(choice.variantIds, ['v1']);
        expect(choice.confidenceScore, 0.9);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'c1',
          'questionId': 'q1',
          'text': 'Paris',
          'isCorrect': true,
        };

        final choice = QuestionChoice.fromJson(json);
        expect(choice.explanation, '');
        expect(choice.variantIds, []);
        expect(choice.confidenceScore, 0.0);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'c1',
          'questionId': 'q1',
          'text': 'Paris',
          'isCorrect': true,
          'explanation': null,
          'variantIds': null,
          'confidenceScore': null,
        };

        final choice = QuestionChoice.fromJson(json);
        expect(choice.explanation, '');
        expect(choice.variantIds, []);
        expect(choice.confidenceScore, 0.0);
      });
    });

    group('json round-trip', () {
      test('preserves all fields', () {
        final original = QuestionChoice(
          id: 'c1',
          questionId: 'q1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital of France',
          variantIds: ['v1', 'v2'],
          confidenceScore: 0.95,
        );

        final restored = QuestionChoice.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.questionId, original.questionId);
        expect(restored.text, original.text);
        expect(restored.isCorrect, original.isCorrect);
        expect(restored.explanation, original.explanation);
        expect(restored.variantIds, original.variantIds);
        expect(restored.confidenceScore, original.confidenceScore);
      });
    });
  });
}
