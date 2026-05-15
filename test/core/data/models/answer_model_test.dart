import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';

void main() {
  group('Answer', () {
    group('constructor', () {
      test('creates with required fields', () {
        final answer = Answer(
          id: 'answer-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
        );
        expect(answer.id, 'answer-1');
        expect(answer.questionId, 'question-1');
        expect(answer.text, 'Paris');
        expect(answer.isCorrect, isTrue);
        expect(answer.explanation, '');
        expect(answer.variantIds, isEmpty);
        expect(answer.confidenceScore, 0.0);
      });

      test('creates with all fields', () {
        final answer = Answer(
          id: 'answer-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital of France',
          variantIds: ['variant-1'],
          confidenceScore: 0.95,
        );
        expect(answer.explanation, 'Capital of France');
        expect(answer.variantIds, ['variant-1']);
        expect(answer.confidenceScore, 0.95);
      });

      test('creates with incorrect answer', () {
        final answer = Answer(
          id: 'answer-2',
          questionId: 'question-1',
          text: 'London',
          isCorrect: false,
        );
        expect(answer.isCorrect, isFalse);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final answer = Answer(
          id: 'answer-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital',
          variantIds: ['v1'],
          confidenceScore: 0.9,
        );
        final json = answer.toJson();
        expect(json['id'], 'answer-1');
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
          'id': 'answer-1',
          'questionId': 'question-1',
          'text': 'Paris',
          'isCorrect': true,
          'explanation': 'Capital',
          'variantIds': ['v1'],
          'confidenceScore': 0.9,
        };
        final answer = Answer.fromJson(json);
        expect(answer.id, 'answer-1');
        expect(answer.isCorrect, isTrue);
        expect(answer.variantIds, ['v1']);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'answer-1',
          'questionId': 'question-1',
          'text': 'Paris',
          'isCorrect': false,
        };
        final answer = Answer.fromJson(json);
        expect(answer.explanation, '');
        expect(answer.variantIds, isEmpty);
        expect(answer.confidenceScore, 0.0);
      });

      test('handles null variantIds defaults to empty list', () {
        final json = {
          'id': 'a1', 'questionId': 'q1', 'text': 'T', 'isCorrect': true,
          'variantIds': null,
        };
        final answer = Answer.fromJson(json);
        expect(answer.variantIds, isEmpty);
      });

      test('handles null confidenceScore defaults to 0.0', () {
        final json = {
          'id': 'a1', 'questionId': 'q1', 'text': 'T', 'isCorrect': true,
          'confidenceScore': null,
        };
        final answer = Answer.fromJson(json);
        expect(answer.confidenceScore, 0.0);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = Answer(
          id: 'answer-1',
          questionId: 'question-1',
          text: 'Paris',
          isCorrect: true,
          explanation: 'Capital of France',
          variantIds: ['v1'],
          confidenceScore: 0.85,
        );
        final json = original.toJson();
        final restored = Answer.fromJson(json);
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
        final a = Answer(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        final b = Answer(id: 'a2', questionId: 'q2', text: 'London', isCorrect: false);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = Answer(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = Answer(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        expect(obj.toString(), contains('Answer'));
      });
    });
  });
}
