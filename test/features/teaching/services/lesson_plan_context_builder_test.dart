import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/teaching/services/lesson_plan_context_builder.dart';

void main() {
  group('LessonPlanContextBuilder', () {
    final builder = LessonPlanContextBuilder();

    LessonBlock block({
      required String id,
      required LessonBlockType type,
      required String content,
      String? sectionTitle,
      String? chapterTitle,
    }) =>
        LessonBlock(
          id: id,
          subjectId: 'math',
          lessonId: 'lesson-1',
          type: type,
          content: content,
          order: 0,
          sectionTitle: sectionTitle,
          chapterTitle: chapterTitle,
        );

    test('returns null when blocks are empty', () {
      expect(builder.build(blocks: []), isNull);
    });

    test('includes the Current lesson plan heading', () {
      final context = builder.build(blocks: [
        block(id: 'b1', type: LessonBlockType.example, content: 'A worked example'),
      ]);

      expect(context, isNotNull);
      expect(context, contains('Current lesson plan'));
    });

    test('serialises the block type label', () {
      final context = builder.build(blocks: [
        block(id: 'b1', type: LessonBlockType.example, content: 'pizza analogy'),
        block(id: 'b2', type: LessonBlockType.exercise, content: 'solve x'),
        block(id: 'b3', type: LessonBlockType.analogy, content: 'atoms are like...'),
      ]);

      expect(context, contains('Type: example'));
      expect(context, contains('Type: exercise'));
      expect(context, contains('Type: analogy'));
    });

    test('serialises the section title when present', () {
      final context = builder.build(blocks: [
        block(
          id: 'b1',
          type: LessonBlockType.example,
          content: 'content',
          sectionTitle: 'Worked Example',
        ),
      ]);

      expect(context, contains('Section: Worked Example'));
    });

    test('falls back to chapterTitle when sectionTitle is absent', () {
      final context = builder.build(blocks: [
        block(
          id: 'b1',
          type: LessonBlockType.exercise,
          content: 'content',
          chapterTitle: 'Chapter 4',
        ),
      ]);

      expect(context, contains('Section: Chapter 4'));
    });

    test('includes a short content snippet', () {
      final context = builder.build(blocks: [
        block(id: 'b1', type: LessonBlockType.example, content: 'A short snippet'),
      ]);

      expect(context, contains('Content: A short snippet'));
    });

    test('omits the Section line when neither title is present', () {
      final context = builder.build(blocks: [
        block(id: 'b1', type: LessonBlockType.text, content: 'no titles here'),
      ]);

      expect(context, isNotNull);
      expect(context, isNot(contains('Section:')));
      expect(context, contains('Type: text'));
      expect(context, contains('Content: no titles here'));
    });

    test('truncates overly long content snippets', () {
      final long = 'x' * 500;
      final context = builder.build(blocks: [
        block(id: 'b1', type: LessonBlockType.text, content: long),
      ]);

      expect(context, isNotNull);
      // Snippet is bounded by maxContentChars (200) plus the ellipsis.
      expect(context, contains('…'));
      expect(context!.length, lessThan(400));
    });

    test('caps the number of blocks to maxBlocks', () {
      final blocks = List.generate(
        8,
        (i) => block(
          id: 'b$i',
          type: LessonBlockType.example,
          content: 'content-$i',
        ),
      );

      final context = builder.build(blocks: blocks);

      expect(context, isNotNull);
      // Only the first maxBlocks entries surface their content.
      expect(context, contains('content-0'));
      expect(context, contains('content-4'));
      // Beyond the cap, individual content is not echoed verbatim.
      expect(context, isNot(contains('content-5')));
      // A trailer notes that more blocks exist.
      expect(context, contains('... and 3 more blocks'));
    });
  });
}
