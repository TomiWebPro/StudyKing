import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';

void main() {
  group('TopicProgress', () {
    final lastUpdated = DateTime(2026, 5, 16);

    group('constructor', () {
      test('creates instance with required fields', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(progress.topicId, 't1');
        expect(progress.lastUpdated, lastUpdated);
        expect(progress.questionsAnswered, 0);
        expect(progress.correctAnswers, 0);
        expect(progress.averageTimeMs, 0.0);
      });

      test('accepts all optional fields', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 20, correctAnswers: 15,
          averageTimeMs: 45000.0,
        );
        expect(progress.questionsAnswered, 20);
        expect(progress.correctAnswers, 15);
        expect(progress.averageTimeMs, 45000.0);
      });
    });

    group('accuracy', () {
      test('computes accuracy correctly', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 10, correctAnswers: 7,
        );
        expect(progress.accuracy, 0.7);
      });

      test('returns 0 when no questions answered', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(progress.accuracy, 0.0);
      });

      test('returns 1.0 for perfect score', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 5, correctAnswers: 5,
        );
        expect(progress.accuracy, 1.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 10, correctAnswers: 8,
          averageTimeMs: 30000.0,
        );
        final json = progress.toJson();
        expect(json['topicId'], 't1');
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 8);
        expect(json['averageTimeMs'], 30000.0);
        expect(json['lastUpdated'], lastUpdated.toIso8601String());
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'topicId': 't1',
          'questionsAnswered': 15,
          'correctAnswers': 12,
          'averageTimeMs': 40000.0,
          'lastUpdated': lastUpdated.toIso8601String(),
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.topicId, 't1');
        expect(progress.questionsAnswered, 15);
        expect(progress.correctAnswers, 12);
        expect(progress.averageTimeMs, 40000.0);
        expect(progress.lastUpdated, lastUpdated);
      });

      test('handles missing optional fields', () {
        final json = {
          'topicId': 't1',
          'lastUpdated': lastUpdated.toIso8601String(),
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.questionsAnswered, 0);
        expect(progress.correctAnswers, 0);
        expect(progress.averageTimeMs, 0.0);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 10, correctAnswers: 9,
          averageTimeMs: 25000.0,
        );
        final restored = TopicProgress.fromJson(original.toJson());
        expect(restored.topicId, original.topicId);
        expect(restored.questionsAnswered, original.questionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
        expect(restored.averageTimeMs, original.averageTimeMs);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final copy = progress.copyWith();
        expect(copy.topicId, progress.topicId);
      });

      test('updates specified fields', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final later = DateTime(2026, 5, 17);
        final copy = progress.copyWith(
          questionsAnswered: 5, correctAnswers: 4, lastUpdated: later,
        );
        expect(copy.questionsAnswered, 5);
        expect(copy.correctAnswers, 4);
        expect(copy.lastUpdated, later);
        expect(copy.topicId, 't1');
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final b = TopicProgress(
          topicId: 't2', lastUpdated: lastUpdated,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(a.hashCode, a.hashCode);
      });
    });
  });
}
