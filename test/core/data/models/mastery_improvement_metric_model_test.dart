import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_improvement_metric_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('MasteryImprovementMetric', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 'student-1',
          topicId: 'topic-1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 0.3,
          currentMasteryLevel: 0.7,
          previousLevel: MasteryLevel.novice,
          currentLevel: MasteryLevel.developing,
        );
        expect(metric.date, now);
        expect(metric.studentId, 'student-1');
        expect(metric.topicId, 'topic-1');
        expect(metric.previousAccuracy, 0.5);
        expect(metric.currentAccuracy, 0.8);
        expect(metric.accuracyDelta, 0.3);
        expect(metric.previousMasteryLevel, 0.3);
        expect(metric.currentMasteryLevel, 0.7);
        expect(metric.previousLevel, MasteryLevel.novice);
        expect(metric.currentLevel, MasteryLevel.developing);
        expect(metric.metadata, isNull);
      });

      test('creates with metadata', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.0,
          currentAccuracy: 1.0,
          accuracyDelta: 1.0,
          previousMasteryLevel: 0.0,
          currentMasteryLevel: 1.0,
          previousLevel: MasteryLevel.novice,
          currentLevel: MasteryLevel.expert,
          metadata: {'source': 'quiz'},
        );
        expect(metric.metadata, {'source': 'quiz'});
      });
    });

    group('leveledUp', () {
      test('returns true when current level index is higher', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 0.3,
          currentMasteryLevel: 0.7,
          previousLevel: MasteryLevel.novice,
          currentLevel: MasteryLevel.developing,
        );
        expect(metric.leveledUp, isTrue);
      });

      test('returns false when current level index is same', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 0.3,
          currentMasteryLevel: 0.7,
          previousLevel: MasteryLevel.novice,
          currentLevel: MasteryLevel.novice,
        );
        expect(metric.leveledUp, isFalse);
      });

      test('returns false when current level index is lower', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 0.3,
          currentMasteryLevel: 0.7,
          previousLevel: MasteryLevel.developing,
          currentLevel: MasteryLevel.novice,
        );
        expect(metric.leveledUp, isFalse);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.5,
          currentAccuracy: 0.8,
          accuracyDelta: 0.3,
          previousMasteryLevel: 0.3,
          currentMasteryLevel: 0.7,
          previousLevel: MasteryLevel.novice,
          currentLevel: MasteryLevel.developing,
          metadata: {'key': 'val'},
        );
        final json = metric.toJson();
        expect(json['date'], now.toIso8601String());
        expect(json['studentId'], 's1');
        expect(json['topicId'], 't1');
        expect(json['previousAccuracy'], 0.5);
        expect(json['currentAccuracy'], 0.8);
        expect(json['accuracyDelta'], 0.3);
        expect(json['previousMasteryLevel'], 0.3);
        expect(json['currentMasteryLevel'], 0.7);
        expect(json['previousLevel'], MasteryLevel.novice.index);
        expect(json['currentLevel'], MasteryLevel.developing.index);
        expect(json['leveledUp'], isTrue);
        expect(json['metadata'], {'key': 'val'});
      });

      test('serializes with null metadata', () {
        final metric = MasteryImprovementMetric(
          date: now,
          studentId: 's1',
          topicId: 't1',
          previousAccuracy: 0.0,
          currentAccuracy: 0.0,
          accuracyDelta: 0.0,
          previousMasteryLevel: 0.0,
          currentMasteryLevel: 0.0,
          previousLevel: MasteryLevel.novice,
          currentLevel: MasteryLevel.novice,
        );
        final json = metric.toJson();
        expect(json['leveledUp'], isFalse);
        expect(json['metadata'], isNull);
      });
    });
  });
}
