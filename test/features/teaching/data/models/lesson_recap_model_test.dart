import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';

void main() {
  group('LessonRecapModel', () {
    final base = LessonRecapModel(
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
      generatedAt: DateTime(2026, 1, 2, 3, 4, 5),
      providerName: 'openRouter',
    );

    test('accuracyPercent clamps and scales 0-100', () {
      expect(base.accuracyPercent, 75.0);
      expect(LessonRecapModel(
        id: 'x',
        sessionId: 's',
        studentId: 'st',
        subjectId: 'su',
        topicId: 't',
        topicTitle: 'T',
        accuracy: 1.5,
        generatedAt: DateTime.now(),
      ).accuracyPercent, 100.0);
    });

    test('toJson/fromJson round-trips all fields', () {
      final json = base.toJson();
      final restored = LessonRecapModel.fromJson(json);
      expect(restored.id, base.id);
      expect(restored.sessionId, base.sessionId);
      expect(restored.lessonId, base.lessonId);
      expect(restored.studentId, base.studentId);
      expect(restored.subjectId, base.subjectId);
      expect(restored.topicId, base.topicId);
      expect(restored.topicTitle, base.topicTitle);
      expect(restored.topicsCovered, base.topicsCovered);
      expect(restored.struggles, base.struggles);
      expect(restored.homework, base.homework);
      expect(restored.summary, base.summary);
      expect(restored.accuracy, base.accuracy);
      expect(restored.questionCount, base.questionCount);
      expect(restored.correctCount, base.correctCount);
      expect(restored.confidenceRating, base.confidenceRating);
      expect(restored.participationMessages, base.participationMessages);
      expect(restored.generatedAt, base.generatedAt);
      expect(restored.providerName, base.providerName);
    });

    test('fromJson tolerates missing optional lists', () {
      final restored = LessonRecapModel.fromJson({
        'id': 'r2',
        'sessionId': 's2',
        'studentId': 'st',
        'subjectId': 'su',
        'topicId': 't',
        'topicTitle': 'T',
        'generatedAt': DateTime.now().toIso8601String(),
      });
      expect(restored.topicsCovered, isEmpty);
      expect(restored.struggles, isEmpty);
      expect(restored.homework, isEmpty);
      expect(restored.accuracy, 0.0);
    });

    test('copyWith overrides and clears lessonId', () {
      final updated = base.copyWith(
        summary: 'new summary',
        clearLessonId: true,
      );
      expect(updated.summary, 'new summary');
      expect(updated.lessonId, isNull);
      expect(updated.sessionId, base.sessionId);

      final restored = updated.copyWith(lessonId: 'L9');
      expect(restored.lessonId, 'L9');
    });
  });
}
