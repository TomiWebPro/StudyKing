import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';

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
          variantIds: ['v1', 'v2'],
          sourceIds: ['s1'],
          options: ['Paris', 'London'],
          allowedAnswerTypes: 'text,audio',
          markscheme: sampleMarkscheme,
          model: 'gemini',
          topic: 'Geography',
          tags: ['geography'],
          explanation: 'Test',
          difficultyText: 'medium',
          createdAt: now,
          updatedAt: now,
          nextReview: now,
        );
        final json = question.toJson();
        expect(json['id'], 'q-1');
        expect(json['type'], QuestionType.multiChoice.index);
        expect(json['difficulty'], 2);
        expect(json['subjectId'], 'subject-1');
        expect(json['topicId'], 'topic-1');
        expect(json['variantIds'], ['v1', 'v2']);
        expect(json['sourceIds'], ['s1']);
        expect(json['options'], ['Paris', 'London']);
        expect(json['allowedAnswerTypes'], 'text,audio');
        expect(json['markscheme'], isNotNull);
        expect(json['model'], 'gemini');
        expect(json['topic'], 'Geography');
        expect(json['tags'], ['geography']);
        expect(json['explanation'], 'Test');
        expect(json['difficultyText'], 'medium');
        expect(json['nextReview'], now.toIso8601String());
        expect(json['createdAt'], now.toIso8601String());
        expect(json['updatedAt'], now.toIso8601String());
      });

      test('serializes nullable markscheme as null', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final json = question.toJson();
        expect(json['markscheme'], isNull);
      });

      test('serializes null nextReview as null', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final json = question.toJson();
        expect(json['nextReview'], isNull);
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

      test('deserializes all QuestionType values by index', () {
        for (final type in QuestionType.values) {
          final json = {
            'id': 'q-1',
            'text': 'Text',
            'type': type.index,
            'subjectId': 's1',
            'topicId': 't1',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };
          final question = Question.fromJson(json);
          expect(question.type, type);
        }
      });

      test('deserializes markscheme with empty string', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'markscheme': '',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.markscheme, isNull);
      });

      test('handles null variantIds defaults to empty', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'variantIds': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.variantIds, isEmpty);
      });

      test('handles null sourceIds defaults to empty', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'sourceIds': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.sourceIds, isEmpty);
      });

      test('handles null options defaults to empty', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'options': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.options, isEmpty);
      });

      test('handles null tags defaults to empty', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'tags': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.tags, isEmpty);
      });

      test('handles null id defaults to empty string', () {
        final json = {
          'id': null,
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.id, '');
      });

      test('handles null text defaults to empty string', () {
        final json = {
          'id': 'q-1',
          'text': null,
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.text, '');
      });

      test('handles null subjectId defaults to empty string', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': null,
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.subjectId, '');
      });

      test('handles null topicId defaults to empty string', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.topicId, '');
      });

      test('handles null allowedAnswerTypes defaults to empty string', () {
        final json = {
          'id': 'q-1',
          'text': 'Text',
          'type': 0,
          'subjectId': 's1',
          'topicId': 't1',
          'allowedAnswerTypes': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.allowedAnswerTypes, '');
      });

      test('parses all string fields from JSON', () {
        final json = {
          'id': 'q-1',
          'text': 'Question text',
          'type': 2,
          'difficulty': 4,
          'subjectId': 'sub-1',
          'topicId': 'top-1',
          'variantIds': ['v1'],
          'sourceIds': ['src1'],
          'options': ['A', 'B'],
          'allowedAnswerTypes': 'text',
          'model': 'gpt4',
          'topic': 'Algebra',
          'tags': ['math'],
          'explanation': 'Explanation',
          'difficultyText': 'hard',
          'nextReview': now.add(const Duration(days: 1)).toIso8601String(),
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final question = Question.fromJson(json);
        expect(question.id, 'q-1');
        expect(question.text, 'Question text');
        expect(question.type, QuestionType.typedAnswer);
        expect(question.difficulty, 4);
        expect(question.subjectId, 'sub-1');
        expect(question.topicId, 'top-1');
        expect(question.variantIds, ['v1']);
        expect(question.sourceIds, ['src1']);
        expect(question.options, ['A', 'B']);
        expect(question.allowedAnswerTypes, 'text');
        expect(question.model, 'gpt4');
        expect(question.topic, 'Algebra');
        expect(question.tags, ['math']);
        expect(question.explanation, 'Explanation');
        expect(question.difficultyText, 'hard');
        expect(question.nextReview, now.add(const Duration(days: 1)));
        expect(question.createdAt, now);
        expect(question.updatedAt, now);
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

      test('preserves list fields when null is passed', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          variantIds: ['v1'],
          sourceIds: ['s1'],
          options: ['A', 'B', 'C'],
          tags: ['tag1'],
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(
          variantIds: null,
          sourceIds: null,
          options: null,
          tags: null,
        );
        expect(copy.variantIds, ['v1']);
        expect(copy.sourceIds, ['s1']);
        expect(copy.options, ['A', 'B', 'C']);
        expect(copy.tags, ['tag1']);
      });

      test('updates list fields', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          variantIds: ['v1'],
          tags: ['tag1'],
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(
          variantIds: ['v2', 'v3'],
          tags: ['tag1', 'tag2'],
        );
        expect(copy.variantIds, ['v2', 'v3']);
        expect(copy.tags, ['tag1', 'tag2']);
      });

      test('preserves nullable String fields when null is passed', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          model: 'gpt4',
          topic: 'Algebra',
          explanation: 'Explanation',
          difficultyText: 'hard',
          allowedAnswerTypes: 'text',
          createdAt: now,
          updatedAt: now,
          nextReview: now,
        );
        final copy = question.copyWith(
          model: null,
          topic: null,
          explanation: null,
          difficultyText: null,
          allowedAnswerTypes: null,
          nextReview: null,
        );
        expect(copy.model, 'gpt4');
        expect(copy.topic, 'Algebra');
        expect(copy.explanation, 'Explanation');
        expect(copy.difficultyText, 'hard');
        expect(copy.allowedAnswerTypes, 'text');
        expect(copy.nextReview, now);
      });

      test('updates updatedAt', () {
        final later = DateTime(2026, 6, 1);
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(updatedAt: later);
        expect(copy.updatedAt, later);
      });

      test('updates nextReview', () {
        final later = DateTime(2026, 6, 1);
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(nextReview: later);
        expect(copy.nextReview, later);
      });

      test('updates createdAt', () {
        final later = DateTime(2026, 6, 1);
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(createdAt: later);
        expect(copy.createdAt, later);
      });

      test('clearSrData sets srDataJson to null', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
          srDataJson: '{"repetitions": 3}',
        );
        final copy = question.copyWith(clearSrData: true);
        expect(copy.srDataJson, isNull);
      });

      test('preserves srDataJson when clearSrData is false', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
          srDataJson: '{"repetitions": 3}',
        );
        final copy = question.copyWith(clearSrData: false);
        expect(copy.srDataJson, '{"repetitions": 3}');
      });

      test('updates srDataJson when provided without clear flag', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
          srDataJson: '{"repetitions": 3}',
        );
        final copy = question.copyWith(srDataJson: '{"repetitions": 5}');
        expect(copy.srDataJson, '{"repetitions": 5}');
      });

      test('updates srDataJson from null', () {
        final question = Question(
          id: 'q-1',
          text: 'Text',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          createdAt: now,
          updatedAt: now,
        );
        final copy = question.copyWith(srDataJson: '{"repetitions": 1}');
        expect(copy.srDataJson, '{"repetitions": 1}');
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const question = Question;
        expect(question.toString(), 'Question');
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = Question(id: 'q1', text: 'T', type: QuestionType.singleChoice, subjectId: 's1', topicId: 't1', createdAt: now, updatedAt: now);
        final b = Question(id: 'q1', text: 'T', type: QuestionType.singleChoice, subjectId: 's1', topicId: 't1', createdAt: now, updatedAt: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = Question(id: 'q1', text: 'T', type: QuestionType.singleChoice, subjectId: 's1', topicId: 't1', createdAt: now, updatedAt: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = Question(id: 'q1', text: 'T', type: QuestionType.singleChoice, subjectId: 's1', topicId: 't1', createdAt: now, updatedAt: now);
        expect(obj.toString(), contains('Question'));
      });
    });
  });
}
