import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
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
        expect(json['title'], 'Title');
        expect(json['difficulty'], 2);
        expect(json['generatedBy'], GeneratedBy.hybrid.index);
        expect(json['createdAt'], now.toIso8601String());
        expect(json['blocks'], isA<List>());
        expect((json['blocks'] as List).length, 1);
        expect(json['markscheme'], 'key');
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
        expect(lesson.blocks.length, 1);
        expect(lesson.difficulty, 2);
        expect(lesson.generatedBy, GeneratedBy.manual);
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
        expect(lesson.generatedBy, GeneratedBy.ai); // Default index 0
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
        expect(restored.title, original.title);
        expect(restored.blocks.length, original.blocks.length);
        expect(restored.difficulty, original.difficulty);
        expect(restored.generatedBy, original.generatedBy);
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
        expect(copy.title, lesson.title);
        expect(copy.blocks.length, lesson.blocks.length);
        expect(copy.difficulty, lesson.difficulty);
        expect(copy.generatedBy, lesson.generatedBy);
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
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const lesson = Lesson;
        expect(lesson.toString(), 'Lesson');
      });
    });
  });
}
