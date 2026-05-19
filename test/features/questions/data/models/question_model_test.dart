import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';

void main() {
  group('Question', () {
    group('constructor', () {
      test('creates with required fields', () {
        final q = Question(
          id: 'q1',
          text: 'Test?',
          type: QuestionType.singleChoice,
          subjectId: 'sub1',
          topicId: 'topic1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(q.id, 'q1');
        expect(q.text, 'Test?');
        expect(q.type, QuestionType.singleChoice);
        expect(q.subjectId, 'sub1');
        expect(q.topicId, 'topic1');
        expect(q.model, isNull);
        expect(q.sourceIds, isEmpty);
      });

      test('stores model field when AI-generated', () {
        final q = Question(
          id: 'q1',
          text: 'Test?',
          type: QuestionType.singleChoice,
          subjectId: '',
          topicId: '',
          model: 'gpt-4',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(q.model, 'gpt-4');
      });

      test('stores sourceIds for filtering', () {
        final q = Question(
          id: 'q3',
          text: 'Source question?',
          type: QuestionType.multiChoice,
          subjectId: '',
          topicId: '',
          sourceIds: ['src1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(q.sourceIds, contains('src1'));
      });

      test('without sourceIds has empty list', () {
        final q = Question(
          id: 'q4',
          text: 'No source?',
          type: QuestionType.essay,
          subjectId: '',
          topicId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(q.sourceIds, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final q = Question(
          id: 'q1',
          text: 'Test?',
          type: QuestionType.singleChoice,
          subjectId: 'sub1',
          topicId: 'topic1',
          options: ['A', 'B'],
          markscheme: Markscheme(correctAnswer: 'A'),
          model: 'gpt-4',
          sourceIds: ['src1'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
        );
        final json = q.toJson();
        expect(json['id'], 'q1');
        expect(json['text'], 'Test?');
        expect(json['type'], 0);
        expect(json['subjectId'], 'sub1');
        expect(json['topicId'], 'topic1');
        expect(json['options'], ['A', 'B']);
        expect(json['markscheme']['correctAnswer'], 'A');
        expect(json['model'], 'gpt-4');
        expect(json['sourceIds'], ['src1']);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'q1',
          'text': 'Test question?',
          'type': 'singleChoice',
          'subjectId': 'sub1',
          'topicId': 'topic1',
          'options': ['Option A', 'Option B'],
          'correctAnswer': 'Option A',
          'model': 'claude-3',
          'sourceIds': ['src1'],
          'createdAt': '2025-01-01T00:00:00.000',
          'updatedAt': '2025-01-02T00:00:00.000',
        };
        final q = Question.fromJson(json);
        expect(q.id, 'q1');
        expect(q.text, 'Test question?');
        expect(q.type, QuestionType.singleChoice);
        expect(q.subjectId, 'sub1');
        expect(q.options, ['Option A', 'Option B']);
        expect(q.model, 'claude-3');
        expect(q.sourceIds, ['src1']);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'q1',
          'text': 'Test?',
          'type': 'typedAnswer',
          'subjectId': 'sub1',
          'topicId': 'topic1',
          'createdAt': '2025-01-01T00:00:00.000',
          'updatedAt': '2025-01-01T00:00:00.000',
        };
        final q = Question.fromJson(json);
        expect(q.options, isEmpty);
        expect(q.markscheme, isNull);
        expect(q.model, isNull);
        expect(q.sourceIds, isEmpty);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = Question(
          id: 'q1',
          text: 'Test?',
          type: QuestionType.multiChoice,
          subjectId: 'sub1',
          topicId: 'topic1',
          options: ['A', 'B', 'C'],
          markscheme: Markscheme(correctAnswer: 'A'),
          model: 'gpt-4',
          sourceIds: ['src1'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
        );
        final restored = Question.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.text, original.text);
        expect(restored.type, original.type);
        expect(restored.options, original.options);
        expect(restored.model, original.model);
        expect(restored.sourceIds, original.sourceIds);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final q = Question(
          id: 'q1', text: 'Test?', type: QuestionType.singleChoice,
          subjectId: 'sub1', topicId: 'topic1',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        );
        final copy = q.copyWith();
        expect(copy.id, q.id);
        expect(copy.text, q.text);
      });

      test('updates specified fields', () {
        final q = Question(
          id: 'q1', text: 'Old?', type: QuestionType.singleChoice,
          subjectId: 'sub1', topicId: 'topic1',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        );
        final copy = q.copyWith(text: 'New?', model: 'gpt-4');
        expect(copy.text, 'New?');
        expect(copy.model, 'gpt-4');
      });
    });
  });
}
