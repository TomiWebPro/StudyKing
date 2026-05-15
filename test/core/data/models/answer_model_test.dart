import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';

void main() {
  group('QuestionChoice', () {
    group('constructor', () {
      test('creates with required fields', () {
        final choice = QuestionChoice(
          id: 'choice-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
        );
        expect(choice.id, 'choice-1');
        expect(choice.questionId, 'question-1');
        expect(choice.text, 'Paris');
        expect(choice.isCorrect, isTrue);
        expect(choice.explanation, '');
        expect(choice.variantIds, isEmpty);
        expect(choice.confidenceScore, 0.0);
      });

      test('creates with all fields', () {
        final choice = QuestionChoice(
          id: 'choice-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital of France',
          variantIds: ['variant-1'],
          confidenceScore: 0.95,
        );
        expect(choice.explanation, 'Capital of France');
        expect(choice.variantIds, ['variant-1']);
        expect(choice.confidenceScore, 0.95);
      });

      test('creates with incorrect answer', () {
        final choice = QuestionChoice(
          id: 'choice-2',
          questionId: 'question-1',
          text: 'London',
          isCorrect: false,
        );
        expect(choice.isCorrect, isFalse);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final choice = QuestionChoice(
          id: 'choice-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital',
          variantIds: ['v1'],
          confidenceScore: 0.9,
        );
        final json = choice.toJson();
        expect(json['id'], 'choice-1');
        expect(json['questionId'], 'question-1');
        expect(json['text'], 'Paris');
        expect(json['isCorrect'], isTrue);
        expect(json['explanation'], 'Capital');
        expect(json['variantIds'], ['v1']);
        expect(json['confidenceScore'], 0.9);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'choice-1',
          'questionId': 'question-1',
          'text': 'Paris',
          'isCorrect': true,
          'explanation': 'Capital',
          'variantIds': ['v1'],
          'confidenceScore': 0.9,
        };
        final choice = QuestionChoice.fromJson(json);
        expect(choice.id, 'choice-1');
        expect(choice.isCorrect, isTrue);
        expect(choice.variantIds, ['v1']);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'choice-1',
          'questionId': 'question-1',
          'text': 'Paris',
          'isCorrect': false,
        };
        final choice = QuestionChoice.fromJson(json);
        expect(choice.explanation, '');
        expect(choice.variantIds, isEmpty);
        expect(choice.confidenceScore, 0.0);
      });

      test('handles null variantIds defaults to empty list', () {
        final json = {
          'id': 'a1', 'questionId': 'q1', 'text': 'T', 'isCorrect': true,
          'variantIds': null,
        };
        final choice = QuestionChoice.fromJson(json);
        expect(choice.variantIds, isEmpty);
      });

      test('handles null confidenceScore defaults to 0.0', () {
        final json = {
          'id': 'a1', 'questionId': 'q1', 'text': 'T', 'isCorrect': true,
          'confidenceScore': null,
        };
        final choice = QuestionChoice.fromJson(json);
        expect(choice.confidenceScore, 0.0);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = QuestionChoice(
          id: 'choice-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital of France',
          variantIds: ['v1'],
          confidenceScore: 0.85,
        );
        final json = original.toJson();
        final restored = QuestionChoice.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.questionId, original.questionId);
        expect(restored.text, original.text);
        expect(restored.isCorrect, original.isCorrect);
        expect(restored.explanation, original.explanation);
        expect(restored.confidenceScore, original.confidenceScore);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        final b = QuestionChoice(id: 'a2', questionId: 'q2', text: 'London', isCorrect: false);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        expect(obj.toString(), contains('QuestionChoice'));
      });
    });
  });
}
