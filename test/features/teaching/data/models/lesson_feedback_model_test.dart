import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';

void main() {
  group('LessonFeedbackModel', () {
    final createdAt = DateTime.utc(2026, 3, 14, 9, 30);

    final base = LessonFeedbackModel(
      id: 'fb-1',
      studentId: 'student-1',
      targetType: 'explanation',
      lessonId: 'lesson-1',
      messageId: 'msg-1',
      sentiment: 'positive',
      starRating: 4,
      comment: 'Clear explanation',
      reportedIncorrect: false,
      createdAt: createdAt,
    );

    test('applies defaults for optional fields', () {
      final minimal = LessonFeedbackModel(
        id: 'fb-2',
        studentId: 'student-2',
        targetType: 'lesson',
      );
      expect(minimal.sentiment, 'none');
      expect(minimal.starRating, 0);
      expect(minimal.comment, isNull);
      expect(minimal.reportedIncorrect, isFalse);
      expect(minimal.lessonId, isNull);
      expect(minimal.messageId, isNull);
      expect(minimal.createdAt, isA<DateTime>());
    });

    test('targetTypeEnum maps names and falls back to explanation', () {
      expect(base.targetTypeEnum, FeedbackTargetType.explanation);
      expect(
        LessonFeedbackModel(
          id: 'a',
          studentId: 's',
          targetType: 'lesson',
        ).targetTypeEnum,
        FeedbackTargetType.lesson,
      );
      expect(
        LessonFeedbackModel(
          id: 'a',
          studentId: 's',
          targetType: 'bogus',
        ).targetTypeEnum,
        FeedbackTargetType.explanation,
      );
    });

    test('sentimentEnum maps names and falls back to none', () {
      expect(base.sentimentEnum, FeedbackSentiment.positive);
      expect(
        LessonFeedbackModel(
          id: 'a',
          studentId: 's',
          targetType: 'lesson',
          sentiment: 'negative',
        ).sentimentEnum,
        FeedbackSentiment.negative,
      );
      expect(
        LessonFeedbackModel(
          id: 'a',
          studentId: 's',
          targetType: 'lesson',
          sentiment: 'weird',
        ).sentimentEnum,
        FeedbackSentiment.none,
      );
    });

    test('toJson serializes all fields', () {
      final json = base.toJson();
      expect(json['id'], 'fb-1');
      expect(json['studentId'], 'student-1');
      expect(json['targetType'], 'explanation');
      expect(json['lessonId'], 'lesson-1');
      expect(json['messageId'], 'msg-1');
      expect(json['sentiment'], 'positive');
      expect(json['starRating'], 4);
      expect(json['comment'], 'Clear explanation');
      expect(json['reportedIncorrect'], isFalse);
      expect(json['createdAt'], createdAt.toIso8601String());
    });

    test('fromJson round-trips all fields', () {
      final restored = LessonFeedbackModel.fromJson(base.toJson());
      expect(restored.id, base.id);
      expect(restored.studentId, base.studentId);
      expect(restored.targetType, base.targetType);
      expect(restored.lessonId, base.lessonId);
      expect(restored.messageId, base.messageId);
      expect(restored.sentiment, base.sentiment);
      expect(restored.starRating, base.starRating);
      expect(restored.comment, base.comment);
      expect(restored.reportedIncorrect, base.reportedIncorrect);
      expect(restored.createdAt, base.createdAt);
    });

    test('fromJson tolerates missing optional fields', () {
      final restored = LessonFeedbackModel.fromJson({
        'id': 'fb-3',
        'studentId': 'student-3',
        'targetType': 'content',
      });
      expect(restored.lessonId, isNull);
      expect(restored.messageId, isNull);
      expect(restored.sentiment, 'none');
      expect(restored.starRating, 0);
      expect(restored.comment, isNull);
      expect(restored.reportedIncorrect, isFalse);
      expect(restored.createdAt, isA<DateTime>());
    });

    test('copyWith overrides selected fields and preserves others', () {
      final updated = base.copyWith(
        sentiment: 'negative',
        starRating: 1,
        reportedIncorrect: true,
      );
      expect(updated.sentiment, 'negative');
      expect(updated.starRating, 1);
      expect(updated.reportedIncorrect, isTrue);
      expect(updated.id, base.id);
      expect(updated.comment, base.comment);
      expect(updated.createdAt, base.createdAt);
    });

    test('logical field equality after round-trip', () {
      final restored = LessonFeedbackModel.fromJson(base.toJson());
      expect(restored.id, base.id);
      expect(restored.toJson(), base.toJson());
    });
  });
}
