import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('LessonBlock', () {
    group('constructor', () {
      test('creates with required fields', () {
        final block = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'Content here',
        );
        expect(block.id, 'block-1');
        expect(block.subjectId, 'subject-1');
        expect(block.lessonId, 'lesson-1');
        expect(block.type, LessonBlockType.text);
        expect(block.content, 'Content here');
        expect(block.order, 0);
      });

      test('creates with all fields', () {
        final block = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.quiz,
          content: 'Quiz content',
          order: 3,
        );
        expect(block.type, LessonBlockType.quiz);
        expect(block.order, 3);
      });

      test('creates with empty content string', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.text,
          content: '',
        );
        expect(block.content, '');
        expect(block.order, 0);
      });

      test('creates with special characters in content', () {
        final content = 'Line 1\nLine 2\tTabbed\nSpecial: ñ á é €';
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.text,
          content: content,
        );
        expect(block.content, content);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final block = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.example,
          content: 'Example',
          order: 2,
        );
        final json = block.toJson();
        expect(json['id'], 'block-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['lessonId'], 'lesson-1');
        expect(json['type'], LessonBlockType.example.index);
        expect(json['content'], 'Example');
        expect(json['order'], 2);
      });

      test('serializes all LessonBlockType values correctly', () {
        for (final type in LessonBlockType.values) {
          final block = LessonBlock(
            id: 'b1', subjectId: 's1', lessonId: 'l1',
            type: type, content: 'c',
          );
          expect(block.toJson()['type'], type.index);
        }
      });

      test('serializes empty content string', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: '',
        );
        final json = block.toJson();
        expect(json['content'], '');
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'block-1',
          'subjectId': 'subject-1',
          'lessonId': 'lesson-1',
          'type': 3,
          'content': 'Slide content',
          'order': 1,
        };
        final block = LessonBlock.fromJson(json);
        expect(block.id, 'block-1');
        expect(block.type, LessonBlockType.slide);
        expect(block.order, 1);
      });

      test('deserializes with missing order', () {
        final json = {
          'id': 'block-1',
          'subjectId': 'subject-1',
          'lessonId': 'lesson-1',
          'type': 0,
          'content': 'Text',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.type, LessonBlockType.text);
        expect(block.order, 0);
      });

      test('deserializes all LessonBlockType enum indices', () {
        for (final type in LessonBlockType.values) {
          final json = {
            'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
            'type': type.index, 'content': 'c',
          };
          final block = LessonBlock.fromJson(json);
          expect(block.type, type);
        }
      });

      test('deserializes empty content string', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 0, 'content': '',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.content, '');
      });

      test('deserializes content with special characters', () {
        final content = 'Multi-line\nwith\ttabs\nand ñ é €';
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 1, 'content': content,
        };
        final block = LessonBlock.fromJson(json);
        expect(block.content, content);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.summary,
          content: 'Summary',
          order: 5,
        );
        final json = original.toJson();
        final restored = LessonBlock.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.type, original.type);
        expect(restored.order, original.order);
        expect(restored.content, original.content);
        expect(restored.subjectId, original.subjectId);
        expect(restored.lessonId, original.lessonId);
      });

      test('roundtrip preserves all LessonBlockType values', () {
        for (final type in LessonBlockType.values) {
          final original = LessonBlock(
            id: 'b1', subjectId: 's1', lessonId: 'l1',
            type: type, content: 'c', order: 1,
          );
          final restored = LessonBlock.fromJson(original.toJson());
          expect(restored.type, type);
        }
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final block = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'Content',
          order: 2,
        );
        final copy = block.copyWith();
        expect(copy.id, block.id);
        expect(copy.subjectId, block.subjectId);
        expect(copy.lessonId, block.lessonId);
        expect(copy.type, block.type);
        expect(copy.content, block.content);
        expect(copy.order, block.order);
      });

      test('updates specified fields', () {
        final block = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'Content',
          order: 0,
        );
        final copy = block.copyWith(
          type: LessonBlockType.quiz,
          content: 'New content',
          order: 5,
        );
        expect(copy.type, LessonBlockType.quiz);
        expect(copy.content, 'New content');
        expect(copy.order, 5);
        expect(copy.id, block.id);
        expect(copy.subjectId, block.subjectId);
        expect(copy.lessonId, block.lessonId);
      });

      test('updates every field', () {
        final block = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'Content',
          order: 0,
        );
        final copy = block.copyWith(
          id: 'block-2',
          subjectId: 'subject-2',
          lessonId: 'lesson-2',
          type: LessonBlockType.quiz,
          content: 'Updated',
          order: 10,
        );
        expect(copy.id, 'block-2');
        expect(copy.subjectId, 'subject-2');
        expect(copy.lessonId, 'lesson-2');
        expect(copy.type, LessonBlockType.quiz);
        expect(copy.content, 'Updated');
        expect(copy.order, 10);
      });

      test('passing null parameters preserves originals', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.summary, content: 'original',
          order: 7,
        );
        final copy = block.copyWith(
          id: null, subjectId: null, lessonId: null,
          type: null, content: null, order: null,
        );
        expect(copy.id, 'b1');
        expect(copy.subjectId, 's1');
        expect(copy.lessonId, 'l1');
        expect(copy.type, LessonBlockType.summary);
        expect(copy.content, 'original');
        expect(copy.order, 7);
      });
    });

    group('fromJson edge cases', () {
      test('handles null order falling back to 0', () {
        final json = {
          'id': 'block-1',
          'subjectId': 's1',
          'lessonId': 'l1',
          'type': 0,
          'content': 'Content',
          'order': null,
        };
        final block = LessonBlock.fromJson(json);
        expect(block.order, 0);
      });

      test('handles missing order key', () {
        final json = {
          'id': 'block-1',
          'subjectId': 's1',
          'lessonId': 'l1',
          'type': 0,
          'content': 'Content',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.order, 0);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'Content',
        );
        final b = LessonBlock(
          id: 'block-2',
          subjectId: 'subject-2',
          lessonId: 'lesson-2',
          type: LessonBlockType.quiz,
          content: 'Other',
        );
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = LessonBlock(
          id: 'block-1',
          subjectId: 'subject-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'Content',
        );
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });

      test('different instances with same values are not equal', () {
        final a = LessonBlock(
          id: 'same-id',
          subjectId: 'same-subject',
          lessonId: 'same-lesson',
          type: LessonBlockType.text,
          content: 'same',
          order: 1,
        );
        final b = LessonBlock(
          id: 'same-id',
          subjectId: 'same-subject',
          lessonId: 'same-lesson',
          type: LessonBlockType.text,
          content: 'same',
          order: 1,
        );
        expect(a == b, isFalse);
        expect(identical(a, b), isFalse);
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const block = LessonBlock;
        expect(block.toString(), 'LessonBlock');
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C', order: 1);
        expect(obj.toString(), contains('LessonBlock'));
      });
    });
  });
}
