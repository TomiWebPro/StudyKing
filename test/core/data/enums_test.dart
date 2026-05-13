import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('QuestionType', () {
    test('has all expected values', () {
      expect(QuestionType.values.length, 10);
      expect(QuestionType.singleChoice.index, 0);
      expect(QuestionType.multiChoice.index, 1);
      expect(QuestionType.typedAnswer.index, 2);
      expect(QuestionType.canvas.index, 3);
      expect(QuestionType.essay.index, 4);
      expect(QuestionType.stepByStep.index, 5);
      expect(QuestionType.mathExpression.index, 6);
      expect(QuestionType.graphDrawing.index, 7);
      expect(QuestionType.fileUpload.index, 8);
      expect(QuestionType.audioRecording.index, 9);
    });
  });

  group('SourceType', () {
    test('has all expected values', () {
      expect(SourceType.values.length, 6);
      expect(SourceType.pdf.index, 0);
      expect(SourceType.syllabus.index, 1);
      expect(SourceType.textbook.index, 2);
      expect(SourceType.video.index, 3);
      expect(SourceType.lectureNotes.index, 4);
      expect(SourceType.externalResource.index, 5);
    });
  });

  group('LessonBlockType', () {
    test('has all expected values', () {
      expect(LessonBlockType.values.length, 6);
      expect(LessonBlockType.text.index, 0);
      expect(LessonBlockType.example.index, 1);
      expect(LessonBlockType.exercise.index, 2);
      expect(LessonBlockType.slide.index, 3);
      expect(LessonBlockType.quiz.index, 4);
      expect(LessonBlockType.summary.index, 5);
    });
  });

  group('GeneratedBy', () {
    test('has all expected values', () {
      expect(GeneratedBy.values.length, 3);
      expect(GeneratedBy.ai.index, 0);
      expect(GeneratedBy.manual.index, 1);
      expect(GeneratedBy.hybrid.index, 2);
    });
  });
}
