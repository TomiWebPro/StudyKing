import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/teaching/data/adapters/lesson_feedback_adapter.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import '../../../../helpers/hive_test_utils.dart';

void main() {
  group('LessonFeedbackAdapter', () {
    test('has correct typeId', () {
      expect(LessonFeedbackAdapter().typeId, 44);
    });

    test('is a TypeAdapter<LessonFeedbackModel>', () {
      expect(LessonFeedbackAdapter(),
          isA<TypeAdapter<LessonFeedbackModel>>());
    });

    test('read and write round-trips a fully populated model', () {
      final adapter = LessonFeedbackAdapter();
      final createdAt = DateTime.utc(2026, 3, 14, 9, 30);
      final model = LessonFeedbackModel(
        id: 'fb-1',
        studentId: 'student-1',
        targetType: 'explanation',
        lessonId: 'lesson-1',
        messageId: 'msg-1',
        sentiment: 'positive',
        starRating: 4,
        comment: 'Clear explanation',
        reportedIncorrect: true,
        createdAt: createdAt,
      );

      final cache = <int, dynamic>{};
      adapter.write(TestBinaryWriter(cache), model);

      final restored = adapter.read(TestBinaryReader(cache));
      expect(restored.id, model.id);
      expect(restored.studentId, model.studentId);
      expect(restored.targetType, model.targetType);
      expect(restored.lessonId, model.lessonId);
      expect(restored.messageId, model.messageId);
      expect(restored.sentiment, model.sentiment);
      expect(restored.starRating, model.starRating);
      expect(restored.comment, model.comment);
      expect(restored.reportedIncorrect, model.reportedIncorrect);
      expect(restored.createdAt, model.createdAt);
    });

    test('read and write round-trips with null and default fields', () {
      final adapter = LessonFeedbackAdapter();
      final model = LessonFeedbackModel(
        id: 'fb-2',
        studentId: 'student-2',
        targetType: 'lesson',
      );

      final cache = <int, dynamic>{};
      adapter.write(TestBinaryWriter(cache), model);

      final restored = adapter.read(TestBinaryReader(cache));
      expect(restored.id, model.id);
      expect(restored.lessonId, isNull);
      expect(restored.messageId, isNull);
      expect(restored.sentiment, 'none');
      expect(restored.starRating, 0);
      expect(restored.comment, isNull);
      expect(restored.reportedIncorrect, isFalse);
      expect(restored.createdAt, isA<DateTime>());
    });
  });
}
