import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/teaching/data/adapters/lesson_recap_adapter.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';
import '../../../../helpers/hive_test_utils.dart';

void main() {
  group('LessonRecapAdapter', () {
    test('has correct typeId', () {
      expect(LessonRecapAdapter().typeId, 30);
    });

    test('is a TypeAdapter<LessonRecapModel>', () {
      expect(LessonRecapAdapter(), isA<TypeAdapter<LessonRecapModel>>());
    });

    test('read and write round-trips a fully populated model', () {
      final adapter = LessonRecapAdapter();
      final generatedAt = DateTime(2026, 1, 2, 3, 4, 5);
      final model = LessonRecapModel(
        id: 'r1',
        sessionId: 's1',
        lessonId: 'L1',
        studentId: 'student-1',
        subjectId: 'subj-1',
        topicId: 'topic-1',
        topicTitle: 'Photosynthesis',
        topicsCovered: ['light reactions', 'calvin cycle'],
        struggles: ['stomata function'],
        homework: ['read chapter 4'],
        summary: 'We covered photosynthesis step by step.',
        accuracy: 0.75,
        questionCount: 4,
        correctCount: 3,
        confidenceRating: 4,
        participationMessages: 12,
        generatedAt: generatedAt,
        providerName: 'openRouter',
      );

      final cache = <int, dynamic>{};
      adapter.write(TestBinaryWriter(cache), model);

      final restored = adapter.read(TestBinaryReader(cache));
      expect(restored.id, model.id);
      expect(restored.sessionId, model.sessionId);
      expect(restored.lessonId, model.lessonId);
      expect(restored.studentId, model.studentId);
      expect(restored.subjectId, model.subjectId);
      expect(restored.topicId, model.topicId);
      expect(restored.topicTitle, model.topicTitle);
      expect(restored.topicsCovered, model.topicsCovered);
      expect(restored.struggles, model.struggles);
      expect(restored.homework, model.homework);
      expect(restored.summary, model.summary);
      expect(restored.accuracy, model.accuracy);
      expect(restored.questionCount, model.questionCount);
      expect(restored.correctCount, model.correctCount);
      expect(restored.confidenceRating, model.confidenceRating);
      expect(restored.participationMessages, model.participationMessages);
      expect(restored.generatedAt, model.generatedAt);
      expect(restored.providerName, model.providerName);
    });

    test('read and write round-trips with null and empty fields', () {
      final adapter = LessonRecapAdapter();
      final model = LessonRecapModel(
        id: 'r2',
        sessionId: 's2',
        studentId: 'student-2',
        subjectId: 'subj-2',
        topicId: 'topic-2',
        topicTitle: 'Cell Division',
        generatedAt: DateTime(2026, 5, 6, 7, 8, 9),
      );

      final cache = <int, dynamic>{};
      adapter.write(TestBinaryWriter(cache), model);

      final restored = adapter.read(TestBinaryReader(cache));
      expect(restored.id, model.id);
      expect(restored.lessonId, isNull);
      expect(restored.topicsCovered, isEmpty);
      expect(restored.struggles, isEmpty);
      expect(restored.homework, isEmpty);
      expect(restored.summary, '');
      expect(restored.accuracy, 0.0);
      expect(restored.questionCount, 0);
      expect(restored.correctCount, 0);
      expect(restored.confidenceRating, 0);
      expect(restored.participationMessages, 0);
      expect(restored.providerName, isNull);
      expect(restored.generatedAt, model.generatedAt);
    });
  });
}
