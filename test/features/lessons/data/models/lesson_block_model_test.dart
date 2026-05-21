import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

      test('creates with non-default answerKey', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.quiz,
          content: 'Question?',
          order: 1,
          answerKey: 'The answer is 42',
        );
        expect(block.answerKey, 'The answer is 42');
      });

      test('creates with empty answerKey default', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.text,
          content: 'Content',
        );
        expect(block.answerKey, '');
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

      test('serializes answerKey', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.quiz, content: 'Q',
          answerKey: 'Answer key',
        );
        final json = block.toJson();
        expect(json['answerKey'], 'Answer key');
      });

      test('serializes empty answerKey default', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: 'C',
        );
        final json = block.toJson();
        expect(json['answerKey'], '');
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

      test('deserializes with answerKey', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 4, 'content': 'Question?',
          'order': 2, 'answerKey': 'Correct answer',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.answerKey, 'Correct answer');
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

      test('roundtrip preserves answerKey', () {
        final original = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.quiz, content: 'Q',
          order: 2, answerKey: 'secret answer',
        );
        final restored = LessonBlock.fromJson(original.toJson());
        expect(restored.answerKey, 'secret answer');
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
          order: 7, answerKey: 'orig key',
        );
        final copy = block.copyWith(
          id: null, subjectId: null, lessonId: null,
          type: null, content: null, order: null, answerKey: null,
        );
        expect(copy.id, 'b1');
        expect(copy.subjectId, 's1');
        expect(copy.lessonId, 'l1');
        expect(copy.type, LessonBlockType.summary);
        expect(copy.content, 'original');
        expect(copy.order, 7);
        expect(copy.answerKey, 'orig key');
      });

      test('updates answerKey', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.quiz, content: 'Q',
        );
        final copy = block.copyWith(answerKey: 'new key');
        expect(copy.answerKey, 'new key');
        expect(copy.id, block.id);
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

      test('handles null answerKey falling back to empty string', () {
        final json = {
          'id': 'block-1',
          'subjectId': 's1',
          'lessonId': 'l1',
          'type': 0,
          'content': 'Content',
          'answerKey': null,
        };
        final block = LessonBlock.fromJson(json);
        expect(block.answerKey, '');
      });

      test('handles missing answerKey key', () {
        final json = {
          'id': 'block-1',
          'subjectId': 's1',
          'lessonId': 'l1',
          'type': 0,
          'content': 'Content',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.answerKey, '');
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

    group('copyWith edge cases', () {
      test('changes answerKey from empty string to non-empty', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.quiz, content: 'Q',
        );
        final copy = block.copyWith(answerKey: 'new key');
        expect(copy.answerKey, 'new key');
        expect(block.answerKey, '');
      });

      test('changes answerKey from non-empty to empty string', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.quiz, content: 'Q',
          answerKey: 'old key',
        );
        final copy = block.copyWith(answerKey: '');
        expect(copy.answerKey, '');
      });

      test('preserves answerKey when passing null', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.quiz, content: 'Q',
          answerKey: 'existing key',
        );
        final copy = block.copyWith(answerKey: null);
        expect(copy.answerKey, 'existing key');
      });

      test('chains multiple copyWith calls', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: 'Start',
          order: 0,
        );
        final step1 = block.copyWith(content: 'Step 1', order: 1);
        final step2 = step1.copyWith(content: 'Step 2', type: LessonBlockType.quiz);
        expect(step2.content, 'Step 2');
        expect(step2.order, 1);
        expect(step2.type, LessonBlockType.quiz);
        expect(step2.id, 'b1');
        expect(step2.subjectId, 's1');
        expect(step2.lessonId, 'l1');
      });
    });

    group('LessonBlock numeric edge cases', () {
      test('creates with negative order', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: 'C',
          order: -5,
        );
        expect(block.order, -5);
        final json = block.toJson();
        expect(json['order'], -5);
        final restored = LessonBlock.fromJson(json);
        expect(restored.order, -5);
      });

      test('creates with very large order', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: 'C',
          order: 2147483647,
        );
        expect(block.order, 2147483647);
        final restored = LessonBlock.fromJson(block.toJson());
        expect(restored.order, 2147483647);
      });
    });

    group('LessonBlock very long content', () {
      test('handles very long content string', () {
        final longContent = 'A' * 10000;
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: longContent,
        );
        expect(block.content.length, 10000);
        final json = block.toJson();
        expect(json['content'], longContent);
        final restored = LessonBlock.fromJson(json);
        expect(restored.content, longContent);
      });

      test('handles content with only whitespace', () {
        final block = LessonBlock(
          id: 'b1', subjectId: 's1', lessonId: 'l1',
          type: LessonBlockType.text, content: '   ',
        );
        expect(block.content, '   ');
        final restored = LessonBlock.fromJson(block.toJson());
        expect(restored.content, '   ');
      });
    });

    group('LessonBlock fromJson with varied answerKey', () {
      test('deserializes answerKey as empty string when key is empty string', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 4, 'content': 'Q', 'answerKey': '',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.answerKey, '');
      });

      test('deserializes answerKey as empty string when key is absent and type is quiz', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 4, 'content': 'Q',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.answerKey, '');
      });

      test('deserializes answerKey with special characters', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 4, 'content': 'Q',
          'answerKey': 'Answer: 42\nExplanation: Life\tuniverse',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.answerKey, 'Answer: 42\nExplanation: Life\tuniverse');
      });
    });

    group('LessonBlock identity and mutability', () {
      test('two blocks with same data are not identical', () {
        final a = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C');
        final b = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C');
        expect(identical(a, b), isFalse);
      });

      test('copyWith returns different instance', () {
        final a = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C');
        final b = a.copyWith();
        expect(identical(a, b), isFalse);
      });
    });

    group('LessonBlock JSON with unexpected types', () {
      test('fromJson handles content as non-string by crashing gracefully', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 0, 'content': 123,
        };
        expect(() => LessonBlock.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('fromJson throws when type index is out of range', () {
        final json = {
          'id': 'b1', 'subjectId': 's1', 'lessonId': 'l1',
          'type': 999, 'content': 'C',
        };
        expect(() => LessonBlock.fromJson(json), throwsA(isA<RangeError>()));
      });
    });

    group('LessonBlock Hive extension', () {
      test('is a HiveObject', () {
        final block = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C');
        expect(block, isA<HiveObject>());
      });
    });
  });
}
