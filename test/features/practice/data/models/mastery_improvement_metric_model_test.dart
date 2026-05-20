import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_improvement_metric_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('MasteryImprovementMetric', () {
    group('constructor', () {
      test('creates instance with all fields', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 2.0,
          currentMasteryLevel: 3.5,
          previousLevel: MasteryLevel.developing,
          currentLevel: MasteryLevel.proficient,
          metadata: {'source': 'practice'},
        );

        expect(metric.date, now);
        expect(metric.studentId, 's1');
        expect(metric.topicId, 't1');
        expect(metric.previousAccuracy, 0.5);
        expect(metric.currentAccuracy, 0.8);
        expect(metric.accuracyDelta, 0.3);
        expect(metric.previousMasteryLevel, 2.0);
        expect(metric.currentMasteryLevel, 3.5);
        expect(metric.previousLevel, MasteryLevel.developing);
        expect(metric.currentLevel, MasteryLevel.proficient);
        expect(metric.metadata, {'source': 'practice'});
      });

      test('allows null metadata', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 2.0,
          currentMasteryLevel: 3.5,
          previousLevel: MasteryLevel.developing,
          currentLevel: MasteryLevel.proficient,
        );

        expect(metric.metadata, isNull);
      });
    });

    group('leveledUp', () {
      test('returns true when level increased', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 2.0,
          currentMasteryLevel: 3.5,
          previousLevel: MasteryLevel.developing,
          currentLevel: MasteryLevel.proficient,
        );

        expect(metric.leveledUp, isTrue);
      });

      test('returns false when level decreased', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.8,
          currentAccuracy: 0.5,
          accuracyDelta: -0.3,
          previousMasteryLevel: 3.5,
          currentMasteryLevel: 2.0,
          previousLevel: MasteryLevel.proficient,
          currentLevel: MasteryLevel.developing,
        );

        expect(metric.leveledUp, isFalse);
      });

      test('returns false when level unchanged', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.6,
          accuracyDelta: 0.1,
          previousMasteryLevel: 2.0,
          currentMasteryLevel: 2.5,
          previousLevel: MasteryLevel.developing,
          currentLevel: MasteryLevel.developing,
        );

        expect(metric.leveledUp, isFalse);
      });

      test('returns false when level jumps down multiple steps', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.9,
          currentAccuracy: 0.3,
          accuracyDelta: -0.6,
          previousMasteryLevel: 4.0,
          currentMasteryLevel: 1.0,
          previousLevel: MasteryLevel.expert,
          currentLevel: MasteryLevel.browsing,
        );

        expect(metric.leveledUp, isFalse);
      });
    });

    group('toJson', () {
      test('returns correct map with leveledUp true', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 2.0,
          currentMasteryLevel: 3.5,
          previousLevel: MasteryLevel.developing,
          currentLevel: MasteryLevel.proficient,
          metadata: {'source': 'practice'},
        );

        final json = metric.toJson();
        expect(json['date'], now.toIso8601String());
        expect(json['studentId'], 's1');
        expect(json['topicId'], 't1');
        expect(json['previousAccuracy'], 0.5);
        expect(json['currentAccuracy'], 0.8);
        expect(json['accuracyDelta'], 0.3);
        expect(json['previousMasteryLevel'], 2.0);
        expect(json['currentMasteryLevel'], 3.5);
        expect(json['previousLevel'], MasteryLevel.developing.index);
        expect(json['currentLevel'], MasteryLevel.proficient.index);
        expect(json['leveledUp'], isTrue);
        expect(json['metadata'], {'source': 'practice'});
      });

      test('returns correct map with leveledUp false', () {
        final now = DateTime(2026, 5, 12);
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.8,
          currentAccuracy: 0.7,
          accuracyDelta: -0.1,
          previousMasteryLevel: 3.5,
          currentMasteryLevel: 3.0,
          previousLevel: MasteryLevel.proficient,
          currentLevel: MasteryLevel.developing,
        );

        final json = metric.toJson();
        expect(json['leveledUp'], isFalse);
        expect(json['metadata'], isNull);
      });
    });
  });
}
