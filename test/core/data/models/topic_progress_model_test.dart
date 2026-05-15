import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';

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

    group('toJson', () {
      test('serializes all fields', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 10,
          correctAnswers: 7,
          averageTimeMs: 5000.0,
          lastUpdated: now,
        );
        final json = progress.toJson();
        expect(json['topicId'], 'topic-1');
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 7);
        expect(json['averageTimeMs'], 5000.0);
        expect(json['lastUpdated'], now.toIso8601String());
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'topicId': 'topic-1',
          'questionsAnswered': 10,
          'correctAnswers': 7,
          'averageTimeMs': 5000.0,
          'lastUpdated': now.toIso8601String(),
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.topicId, 'topic-1');
        expect(progress.questionsAnswered, 10);
        expect(progress.correctAnswers, 7);
        expect(progress.averageTimeMs, 5000.0);
        expect(progress.lastUpdated, now);
      });

      test('applies defaults for missing fields', () {
        final json = {
          'topicId': 'topic-1',
          'lastUpdated': now.toIso8601String(),
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.questionsAnswered, 0);
        expect(progress.correctAnswers, 0);
        expect(progress.averageTimeMs, 0.0);
      });

      test('handles null numeric fields', () {
        final json = {
          'topicId': 't1',
          'lastUpdated': now.toIso8601String(),
          'questionsAnswered': null,
          'correctAnswers': null,
          'averageTimeMs': null,
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.questionsAnswered, 0);
        expect(progress.correctAnswers, 0);
        expect(progress.averageTimeMs, 0.0);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 10,
          correctAnswers: 7,
          averageTimeMs: 5000.0,
          lastUpdated: now,
        );
        final json = original.toJson();
        final restored = TopicProgress.fromJson(json);
        expect(restored.topicId, original.topicId);
        expect(restored.questionsAnswered, original.questionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
        expect(restored.averageTimeMs, original.averageTimeMs);
        expect(restored.lastUpdated, original.lastUpdated);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          questionsAnswered: 10,
          correctAnswers: 7,
          averageTimeMs: 5000.0,
          lastUpdated: now,
        );
        final copy = progress.copyWith();
        expect(copy.topicId, progress.topicId);
        expect(copy.questionsAnswered, progress.questionsAnswered);
        expect(copy.lastUpdated, progress.lastUpdated);
      });

      test('updates specified fields', () {
        final progress = TopicProgress(
          topicId: 'topic-1',
          lastUpdated: now,
        );
        final copy = progress.copyWith(
          questionsAnswered: 15,
          correctAnswers: 12,
          averageTimeMs: 3000.0,
        );
        expect(copy.questionsAnswered, 15);
        expect(copy.correctAnswers, 12);
        expect(copy.averageTimeMs, 3000.0);
        expect(copy.topicId, progress.topicId);
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const progress = TopicProgress;
        expect(progress.toString(), 'TopicProgress');
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = TopicProgress(topicId: 't1', lastUpdated: now);
        final b = TopicProgress(topicId: 't1', lastUpdated: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = TopicProgress(topicId: 't1', lastUpdated: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = TopicProgress(topicId: 't1', lastUpdated: now);
        expect(obj.toString(), contains('TopicProgress'));
      });
    });
  });
}
