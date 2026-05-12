import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
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
      });
    });
  });
}
