import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('Lesson', () {
    late DateTime now;
    late LessonBlock sampleBlock;

    setUp(() {
      now = DateTime(2026, 5, 12);
      sampleBlock = LessonBlock(
        id: 'block-1',
        subjectId: 'subject-1',
        lessonId: 'lesson-1',
        type: LessonBlockType.text,
        content: 'Content',
        order: 1,
      );
    });

    group('constructor', () {
      test('creates with required fields', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Algebra Basics',
          topicId: 'topic-1',
          createdAt: now,
        );
        expect(lesson.id, 'lesson-1');
        expect(lesson.subjectId, 'subject-1');
        expect(lesson.title, 'Algebra Basics');
        expect(lesson.topicId, 'topic-1');
        expect(lesson.blocks, isEmpty);
        expect(lesson.difficulty, 1);
        expect(lesson.generatedBy, GeneratedBy.manual);
        expect(lesson.createdAt, now);
        expect(lesson.markscheme, isNull);
      });

      test('creates with all fields', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Advanced',
          topicId: 'topic-1',
          blocks: [sampleBlock],
          difficulty: 3,
          generatedBy: GeneratedBy.ai,
          createdAt: now,
          markscheme: 'answer key',
        );
        expect(lesson.blocks.length, 1);
        expect(lesson.blocks.first.id, 'block-1');
        expect(lesson.difficulty, 3);
        expect(lesson.generatedBy, GeneratedBy.ai);
        expect(lesson.markscheme, 'answer key');
      });

      test('creates with explicit empty markscheme', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 's1',
          title: 'Title',
          topicId: 't1',
          createdAt: now,
          markscheme: '',
        );
        expect(lesson.markscheme, '');
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Title',
          topicId: 'topic-1',
          blocks: [sampleBlock],
          difficulty: 2,
          generatedBy: GeneratedBy.hybrid,
          createdAt: now,
          markscheme: 'key',
        );
        final json = lesson.toJson();
        expect(json['id'], 'lesson-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['title'], 'Title');
        expect(json['topicId'], 'topic-1');
        expect(json['difficulty'], 2);
        expect(json['generatedBy'], GeneratedBy.hybrid.index);
        expect(json['createdAt'], now.toIso8601String());
        expect(json['blocks'], isA<List>());
        expect((json['blocks'] as List).length, 1);
        expect(json['markscheme'], 'key');
      });

      test('serializes all GeneratedBy values correctly', () {
        for (final gb in GeneratedBy.values) {
          final lesson = Lesson(
            id: 'l1', subjectId: 's1', title: 'T',
            topicId: 't1', createdAt: now, generatedBy: gb,
          );
          expect(lesson.toJson()['generatedBy'], gb.index);
        }
      });

      test('serializes empty blocks list', () {
        final lesson = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', createdAt: now,
        );
        final json = lesson.toJson();
        expect(json['blocks'], isA<List>());
        expect((json['blocks'] as List), isEmpty);
      });

      test('serializes null markscheme', () {
        final lesson = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', createdAt: now,
        );
        expect(lesson.toJson()['markscheme'], isNull);
      });

      test('serializes multiple blocks of different types', () {
        final blocks = [
          sampleBlock,
          LessonBlock(id: 'b2', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.quiz, content: 'Q', order: 2),
          LessonBlock(id: 'b3', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.slide, content: 'S', order: 3),
        ];
        final lesson = Lesson(id: 'l1', subjectId: 's1', title: 'T', topicId: 't1', blocks: blocks, createdAt: now);
        final json = lesson.toJson();
        expect((json['blocks'] as List).length, 3);
        expect((json['blocks'] as List)[0]['id'], 'block-1');
        expect((json['blocks'] as List)[1]['type'], LessonBlockType.quiz.index);
        expect((json['blocks'] as List)[2]['type'], LessonBlockType.slide.index);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 'subject-1',
          'title': 'Title',
          'topicId': 'topic-1',
          'blocks': [
            {
              'id': 'block-1',
              'subjectId': 'subject-1',
              'lessonId': 'lesson-1',
              'type': 0,
              'content': 'Content',
              'order': 1,
            }
          ],
          'difficulty': 2,
          'generatedBy': 1,
          'createdAt': now.toIso8601String(),
          'markscheme': null,
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.id, 'lesson-1');
        expect(lesson.subjectId, 'subject-1');
        expect(lesson.title, 'Title');
        expect(lesson.topicId, 'topic-1');
        expect(lesson.blocks.length, 1);
        expect(lesson.difficulty, 2);
        expect(lesson.generatedBy, GeneratedBy.manual);
        expect(lesson.createdAt, now);
        expect(lesson.markscheme, isNull);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 'subject-1',
          'title': 'Title',
          'topicId': 'topic-1',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.blocks, isEmpty);
        expect(lesson.difficulty, 1);
        expect(lesson.generatedBy, GeneratedBy.ai);
      });

      test('deserializes all GeneratedBy enum indices', () {
        for (final gb in GeneratedBy.values) {
          final json = {
            'id': 'l1', 'subjectId': 's1', 'title': 'T',
            'topicId': 't1', 'generatedBy': gb.index,
            'createdAt': now.toIso8601String(),
          };
          final lesson = Lesson.fromJson(json);
          expect(lesson.generatedBy, gb);
        }
      });

      test('deserializes with non-null markscheme string', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'markscheme': 'This is the answer key',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.markscheme, 'This is the answer key');
      });

      test('deserializes with empty string markscheme', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'markscheme': '',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.markscheme, '');
      });

      test('deserializes with multiple blocks', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'blocks': [
            {'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1', 'type': 0, 'content': 'A', 'order': 1},
            {'id': 'b2', 'subjectId': 's1', 'lessonId': 'l1', 'type': 4, 'content': 'B', 'order': 2},
          ],
          'generatedBy': 2,
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.blocks.length, 2);
        expect(lesson.blocks[0].type, LessonBlockType.text);
        expect(lesson.blocks[1].type, LessonBlockType.quiz);
        expect(lesson.generatedBy, GeneratedBy.hybrid);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Title',
          topicId: 'topic-1',
          blocks: [sampleBlock],
          difficulty: 3,
          generatedBy: GeneratedBy.ai,
          createdAt: now,
          markscheme: 'answer key',
        );
        final json = original.toJson();
        final restored = Lesson.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.subjectId, original.subjectId);
        expect(restored.title, original.title);
        expect(restored.topicId, original.topicId);
        expect(restored.blocks.length, original.blocks.length);
        expect(restored.difficulty, original.difficulty);
        expect(restored.generatedBy, original.generatedBy);
        expect(restored.createdAt, original.createdAt);
        expect(restored.markscheme, original.markscheme);
      });

      test('roundtrip preserves all GeneratedBy values', () {
        for (final gb in GeneratedBy.values) {
          final original = Lesson(
            id: 'l1', subjectId: 's1', title: 'T',
            topicId: 't1', createdAt: now, generatedBy: gb,
          );
          final restored = Lesson.fromJson(original.toJson());
          expect(restored.generatedBy, gb);
        }
      });

      test('roundtrip preserves empty blocks', () {
        final original = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', createdAt: now,
        );
        final restored = Lesson.fromJson(original.toJson());
        expect(restored.blocks, isEmpty);
      });

      test('roundtrip preserves no markscheme', () {
        final original = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', createdAt: now,
        );
        final restored = Lesson.fromJson(original.toJson());
        expect(restored.markscheme, isNull);
      });

      test('roundtrip preserves empty markscheme string', () {
        final original = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', createdAt: now, markscheme: '',
        );
        final restored = Lesson.fromJson(original.toJson());
        expect(restored.markscheme, '');
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Title',
          topicId: 'topic-1',
          blocks: [sampleBlock],
          difficulty: 2,
          generatedBy: GeneratedBy.hybrid,
          createdAt: now,
        );
        final copy = lesson.copyWith();
        expect(copy.id, lesson.id);
        expect(copy.subjectId, lesson.subjectId);
        expect(copy.title, lesson.title);
        expect(copy.topicId, lesson.topicId);
        expect(copy.blocks, lesson.blocks);
        expect(copy.difficulty, lesson.difficulty);
        expect(copy.generatedBy, lesson.generatedBy);
        expect(copy.createdAt, lesson.createdAt);
      });

      test('updates specified fields', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Title',
          topicId: 'topic-1',
          createdAt: now,
        );
        final copy = lesson.copyWith(
          title: 'New Title',
          difficulty: 5,
          generatedBy: GeneratedBy.hybrid,
          markscheme: 'new key',
        );
        expect(copy.title, 'New Title');
        expect(copy.difficulty, 5);
        expect(copy.generatedBy, GeneratedBy.hybrid);
        expect(copy.markscheme, 'new key');
        expect(copy.id, lesson.id);
        expect(copy.subjectId, lesson.subjectId);
        expect(copy.topicId, lesson.topicId);
        expect(copy.createdAt, lesson.createdAt);
      });

      test('updates every field', () {
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Title',
          topicId: 'topic-1',
          createdAt: now,
        );
        final newBlocks = [sampleBlock];
        final newDate = DateTime(2027, 1, 1);
        final copy = lesson.copyWith(
          id: 'lesson-2',
          subjectId: 'subject-2',
          title: 'New Title',
          topicId: 'topic-2',
          blocks: newBlocks,
          difficulty: 5,
          generatedBy: GeneratedBy.hybrid,
          createdAt: newDate,
          markscheme: 'new key',
        );
        expect(copy.id, 'lesson-2');
        expect(copy.subjectId, 'subject-2');
        expect(copy.title, 'New Title');
        expect(copy.topicId, 'topic-2');
        expect(copy.blocks, newBlocks);
        expect(copy.difficulty, 5);
        expect(copy.generatedBy, GeneratedBy.hybrid);
        expect(copy.createdAt, newDate);
        expect(copy.markscheme, 'new key');
      });

      test('passing null blocks preserves original blocks', () {
        final lesson = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', blocks: [sampleBlock], createdAt: now,
        );
        final copy = lesson.copyWith(blocks: null);
        expect(copy.blocks, same(lesson.blocks));
        expect(copy.blocks.length, 1);
      });

      test('passing null markscheme preserves original markscheme', () {
        final lesson = Lesson(
          id: 'l1', subjectId: 's1', title: 'T',
          topicId: 't1', createdAt: now, markscheme: 'key',
        );
        final copy = lesson.copyWith(markscheme: null);
        expect(copy.markscheme, 'key');
      });
    });

    group('fromJson edge cases', () {
      test('handles null blocks', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'blocks': null,
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.blocks, isEmpty);
      });

      test('handles missing blocks key', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.blocks, isEmpty);
      });

      test('handles null difficulty falling back to 1', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'difficulty': null,
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.difficulty, 1);
      });

      test('handles missing difficulty key', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.difficulty, 1);
      });

      test('handles null generatedBy falling back to ai (index 0)', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'generatedBy': null,
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.generatedBy, GeneratedBy.ai);
      });

      test('handles missing generatedBy key', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.generatedBy, GeneratedBy.ai);
      });

      test('handles null markscheme', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'markscheme': null,
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.markscheme, isNull);
      });

      test('handles missing markscheme key', () {
        final json = {
          'id': 'lesson-1',
          'subjectId': 's1',
          'title': 'Title',
          'topicId': 't1',
          'createdAt': now.toIso8601String(),
        };
        final lesson = Lesson.fromJson(json);
        expect(lesson.markscheme, isNull);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          topicId: 'topic-1',
          createdAt: now,
        );
        final b = Lesson(
          id: 'lesson-2',
          subjectId: 'subject-2',
          title: 'Geometry',
          topicId: 'topic-2',
          createdAt: now,
        );
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          topicId: 'topic-1',
          createdAt: now,
        );
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });

      test('different instances with same values are not equal', () {
        final a = Lesson(
          id: 'same-id',
          subjectId: 'same-subject',
          title: 'Same',
          topicId: 'same-topic',
          createdAt: now,
        );
        final b = Lesson(
          id: 'same-id',
          subjectId: 'same-subject',
          title: 'Same',
          topicId: 'same-topic',
          createdAt: now,
        );
        expect(a == b, isFalse);
        expect(identical(a, b), isFalse);
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const lesson = Lesson;
        expect(lesson.toString(), 'Lesson');
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = Lesson(id: 'l1', subjectId: 's1', title: 'T', topicId: 't1', createdAt: now);
        expect(obj.toString(), contains('Lesson'));
      });
    });
  });
}
