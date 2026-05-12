import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_progress_model.dart';

void main() {
  group('TopicProgress', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          lastUpdated: now,
        );
        expect(progress.topicId, 'topic-1');
        expect(progress.lastUpdated, now);
        expect(progress.questionsAnswered, 0);
        expect(progress.correctAnswers, 0);
        expect(progress.averageTimeMs, 0.0);
      });

      test('creates with all fields', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 10,
          correctAnswers: 7,
          averageTimeMs: 5000.0,
          lastUpdated: now,
        );
        expect(progress.questionsAnswered, 10);
        expect(progress.correctAnswers, 7);
        expect(progress.averageTimeMs, 5000.0);
      });
    });

    group('accuracy', () {
      test('returns 0.0 when no questions answered', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          lastUpdated: now,
        );
        expect(progress.accuracy, 0.0);
      });

      test('returns correct ratio', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 10,
          correctAnswers: 7,
          lastUpdated: now,
        );
        expect(progress.accuracy, 0.7);
      });

      test('returns 1.0 when all correct', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 5,
          correctAnswers: 5,
          lastUpdated: now,
        );
        expect(progress.accuracy, 1.0);
      });

      test('returns 0.0 when none correct', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 3,
          correctAnswers: 0,
          lastUpdated: now,
        );
        expect(progress.accuracy, 0.0);
      });
    });
  });
}
