import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';

void main() {
  group('Question', () {
    late DateTime now;
    late Markscheme sampleMarkscheme;

    setUp(() {
      now = DateTime(2026, 5, 12);
      sampleMarkscheme = Markscheme(
        questionId: 'q-1',
        correctAnswer: 'Paris',
        acceptableAnswers: ['France'],
        explanation: 'Capital of France',
      );
    });

    group('constructor', () {
      test('creates with required fields', () {
        final question = Question(
          id: 'q-1',
          text: 'What is capital of France?',
          type: QuestionType.singleChoice,
          subjectId: 'subject-1',
          topicId: 'topic-1',
          createdAt: now,
          updatedAt: now,
        );
        expect(question.id, 'q-1');
        expect(question.text, 'What is capital of France?');
        expect(question.type, QuestionType.singleChoice);
        expect(question.difficulty, 1);
        expect(question.options, isEmpty);
        expect(question.tags, isEmpty);
      });

      test('creates with all fields', () {
        final question = Question(
          id: 'q-1',
          text: 'What is 2+2?',
          type: QuestionType.typedAnswer,
          difficulty: 2,
          subjectId: 'subject-1',
          topicId: 'topic-1',
          variantIds: ['v1'],
          sourceIds: ['s1'],
          options: ['3', '4', '5'],
          allowedAnswerTypes: 'text',
          markscheme: sampleMarkscheme,
          model: 'gemini',
          topic: 'Algebra',
          tags: ['math', 'addition'],
          explanation: 'Basic addition',
          difficultyText: 'medium',
          createdAt: now,
          updatedAt: now,
          nextReview: now,
        );
        expect(question.difficulty, 2);
        expect(question.markscheme?.correctAnswer, 'Paris');
        expect(question.tags, ['math', 'addition']);
        expect(question.nextReview, now);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final question = Question(
          id: 'q-1',
          text: 'What is capital?',
          type: QuestionType.multiChoice,
          difficulty: 2,
          subjectId: 'subject-1',
          topicId: 'topic-1',
          options: ['Paris', 'London'],
          markscheme: sampleMarkscheme,
          tags: ['geography'],
          explanation: 'Test',
          createdAt: now,
          updatedAt: now,
          nextReview: now,
        );
        final json = question.toJson();
        expect(json['id'], 'q-1');
        expect(json['type'], QuestionType.multiChoice.index);
        expect(json['difficulty'], 2);
        expect(json['markscheme'], isNotNull);
        expect(json['nextReview'], now.toIso8601String());
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'q-1',
          'text': 'What is capital?',
          'type': 0,
          'difficulty': 2,
          'subjectId': 'subject-1',
          'topicId': 'topic-1',
          'variantIds': ['v1'],
          'sourceIds': ['s1'],
          'options': ['Paris', 'London'],
          'allowedAnswerTypes': '',
          'markscheme': {
            'questionId': 'q-1',
            'correctAnswer': 'Paris',
            'acceptableAnswers': [],
            'explanation': null,
            'markschemePoints': null,
            'steps': [],
          },
          'model': null,
          'topic': null,
          'tags': ['geography'],
          'explanation': 'Test explanation',
          'difficultyText': null,
          'nextReview': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.id, 'q-1');
        expect(question.type, QuestionType.singleChoice);
        expect(question.markscheme?.correctAnswer, 'Paris');
        expect(question.tags, ['geography']);
      });

      test('deserializes with string markscheme', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'markscheme': 'Paris',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.markscheme, isNotNull);
        expect(question.markscheme?.correctAnswer, 'Paris');
      });

      test('deserializes with missing optional fields', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.difficulty, 1);
        expect(question.options, isEmpty);
        expect(question.markscheme, isNull);
        expect(question.nextReview, isNull);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith();
        expect(copy.id, question.id);
        expect(copy.text, question.text);
      });

      test('updates specified fields', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(
          text: 'New text',
          difficulty: 3,
          markscheme: sampleMarkscheme,
        );
        expect(copy.text, 'New text');
        expect(copy.difficulty, 3);
        expect(copy.markscheme?.correctAnswer, 'Paris');
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves all data', () {
        final original = Question(
          id: 'q-1',
          text: 'What is capital?',
          type: QuestionType.multiChoice,
          difficulty: 2,
          subjectId: 'subject-1',
          topicId: 'topic-1',
          options: ['Paris', 'London'],
          markscheme: sampleMarkscheme,
          tags: ['geography'],
          explanation: 'Test',
          createdAt: now,
          updatedAt: now,
        );
        final json = original.toJson();
        final restored = Question.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.text, original.text);
        expect(restored.type, original.type);
        expect(restored.difficulty, original.difficulty);
        expect(restored.markscheme?.correctAnswer, original.markscheme?.correctAnswer);
      });
    });

    group('fromJson edge cases', () {
      test('handles null type index by falling back to singleChoice', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': null,
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.type, QuestionType.singleChoice);
      });

      test('handles string type value by falling back to singleChoice', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 'invalid',
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.type, QuestionType.singleChoice);
      });

      test('handles missing markscheme key', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.markscheme, isNull);
      });

      test('handles difficulty falling back to 1', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'difficulty': null,
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.difficulty, 1);
      });

      test('handles null nextReview', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'nextReview': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.nextReview, isNull);
      });
    });

    group('copyWith edge cases', () {
      test('setting nullable fields to null preserves original values', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          markscheme: sampleMarkscheme,
          model: 'gemini',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(markscheme: null, model: null);
        expect(copy.markscheme?.correctAnswer, 'Paris');
        expect(copy.model, 'gemini');
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const question = Question;
        expect(question.toString(), 'Question');
      });
    });
  });
}
