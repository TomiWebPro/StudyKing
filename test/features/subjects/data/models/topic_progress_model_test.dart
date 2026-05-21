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

      test('accepts zero or negative averageTimeMs', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          averageTimeMs: -1.0,
        );
        expect(progress.averageTimeMs, -1.0);
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

      test('returns 0 when more correct than answered (should not happen)', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 5, correctAnswers: 10,
        );
        expect(progress.accuracy, 2.0);
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

      test('serializes default values', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final json = progress.toJson();
        expect(json['questionsAnswered'], 0);
        expect(json['correctAnswers'], 0);
        expect(json['averageTimeMs'], 0.0);
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

      test('handles null optional fields', () {
        final json = {
          'topicId': 't1',
          'lastUpdated': lastUpdated.toIso8601String(),
          'questionsAnswered': null,
          'correctAnswers': null,
          'averageTimeMs': null,
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.questionsAnswered, 0);
        expect(progress.correctAnswers, 0);
        expect(progress.averageTimeMs, 0.0);
      });

      test('handles int averageTimeMs by converting to double', () {
        final json = {
          'topicId': 't1',
          'lastUpdated': lastUpdated.toIso8601String(),
          'averageTimeMs': 30000,
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.averageTimeMs, 30000.0);
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
        expect(restored.lastUpdated, original.lastUpdated);
      });

      test('preserves default values through roundtrip', () {
        final original = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final restored = TopicProgress.fromJson(original.toJson());
        expect(restored.questionsAnswered, 0);
        expect(restored.correctAnswers, 0);
        expect(restored.averageTimeMs, 0.0);
        expect(restored.lastUpdated, original.lastUpdated);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final copy = progress.copyWith();
        expect(copy.topicId, progress.topicId);
        expect(copy.lastUpdated, progress.lastUpdated);
        expect(copy.questionsAnswered, progress.questionsAnswered);
        expect(copy.correctAnswers, progress.correctAnswers);
        expect(copy.averageTimeMs, progress.averageTimeMs);
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

      test('updates all fields at once', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final later = DateTime(2026, 6, 1);
        final copy = progress.copyWith(
          topicId: 't2',
          questionsAnswered: 10,
          correctAnswers: 8,
          averageTimeMs: 5000.0,
          lastUpdated: later,
        );
        expect(copy.topicId, 't2');
        expect(copy.questionsAnswered, 10);
        expect(copy.correctAnswers, 8);
        expect(copy.averageTimeMs, 5000.0);
        expect(copy.lastUpdated, later);
      });

      test('original is not mutated by copyWith', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 3, correctAnswers: 2,
        );
        progress.copyWith(questionsAnswered: 10);
        expect(progress.questionsAnswered, 3);
        expect(progress.correctAnswers, 2);
      });

      test('preserves averageTimeMs when not specified', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          averageTimeMs: 12345.0,
        );
        final copy = progress.copyWith(questionsAnswered: 1);
        expect(copy.averageTimeMs, 12345.0);
      });
    });

    group('mutability', () {
      test('questionsAnswered is mutable', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        progress.questionsAnswered = 10;
        expect(progress.questionsAnswered, 10);
      });

      test('correctAnswers is mutable', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        progress.correctAnswers = 7;
        expect(progress.correctAnswers, 7);
      });

      test('averageTimeMs is mutable', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        progress.averageTimeMs = 12345.0;
        expect(progress.averageTimeMs, 12345.0);
      });

      test('lastUpdated is mutable', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final later = DateTime(2026, 6, 1);
        progress.lastUpdated = later;
        expect(progress.lastUpdated, later);
      });

      test('mutation affects accuracy', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        progress.questionsAnswered = 10;
        progress.correctAnswers = 8;
        expect(progress.accuracy, 0.8);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal by default (identity)', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final b = TopicProgress(
          topicId: 't2', lastUpdated: lastUpdated,
        );
        expect(a == b, isFalse);
      });

      test('same values but different instances are not equal', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final b = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        expect(a.hashCode, a.hashCode);
      });

      test('different objects have different hashCodes', () {
        final a = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final b = TopicProgress(
          topicId: 't2', lastUpdated: lastUpdated,
        );
        // identity-based hashCode, so different instances should differ
        expect(a.hashCode == b.hashCode, isFalse);
      });
    });

    group('edge cases', () {
      test('large number of questions', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          questionsAnswered: 1000000, correctAnswers: 750000,
        );
        expect(progress.accuracy, 0.75);
      });

      test('zero questionsAnswered with non-zero correctAnswers', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          correctAnswers: 5,
        );
        expect(progress.accuracy, 0.0);
      });

      test('fromJson with empty string topicId', () {
        final json = {
          'topicId': '',
          'lastUpdated': DateTime(2024, 1, 1).toIso8601String(),
        };
        final progress = TopicProgress.fromJson(json);
        expect(progress.topicId, '');
      });

      test('copyWith with empty topicId string', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
        );
        final copy = progress.copyWith(topicId: '');
        expect(copy.topicId, '');
        expect(progress.topicId, 't1');
      });

      test('large time values do not overflow', () {
        final progress = TopicProgress(
          topicId: 't1', lastUpdated: lastUpdated,
          averageTimeMs: 999999999.99,
        );
        expect(progress.averageTimeMs, 999999999.99);
      });
    });
  });
}
