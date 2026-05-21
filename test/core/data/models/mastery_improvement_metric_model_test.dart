import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_improvement_metric_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('MasteryImprovementMetric', () {
    final baseDate = DateTime(2025, 1, 15);

    test('creates metric with all fields', () {
      final metric = MasteryImprovementMetric(
        date: baseDate,
        studentId: 'stu1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.8,
        accuracyDelta: 0.3,
        previousMasteryLevel: 0.4,
        currentMasteryLevel: 0.7,
        previousLevel: MasteryLevel.browsing,
        currentLevel: MasteryLevel.developing,
      );

      expect(metric.date, baseDate);
      expect(metric.studentId, 'stu1');
      expect(metric.topicId, 'topic1');
      expect(metric.previousAccuracy, 0.5);
      expect(metric.currentAccuracy, 0.8);
      expect(metric.accuracyDelta, 0.3);
    });

    test('leveledUp returns true when level increased', () {
      final metric = MasteryImprovementMetric(
        date: baseDate,
        studentId: 'stu1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.8,
        accuracyDelta: 0.3,
        previousMasteryLevel: 0.4,
        currentMasteryLevel: 0.7,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.proficient,
      );

      expect(metric.leveledUp, isTrue);
    });

    test('leveledUp returns false when level decreased', () {
      final metric = MasteryImprovementMetric(
        date: baseDate,
        studentId: 'stu1',
        topicId: 'topic1',
        previousAccuracy: 0.8,
        currentAccuracy: 0.5,
        accuracyDelta: -0.3,
        previousMasteryLevel: 0.7,
        currentMasteryLevel: 0.4,
        previousLevel: MasteryLevel.proficient,
        currentLevel: MasteryLevel.novice,
      );

      expect(metric.leveledUp, isFalse);
    });

    test('leveledUp returns false when same level', () {
      final metric = MasteryImprovementMetric(
        date: baseDate,
        studentId: 'stu1',
        topicId: 'topic1',
        previousAccuracy: 0.6,
        currentAccuracy: 0.7,
        accuracyDelta: 0.1,
        previousMasteryLevel: 0.5,
        currentMasteryLevel: 0.6,
        previousLevel: MasteryLevel.developing,
        currentLevel: MasteryLevel.developing,
      );

      expect(metric.leveledUp, isFalse);
    });

    test('toJson produces correct map', () {
      final metric = MasteryImprovementMetric(
        date: baseDate,
        studentId: 'stu1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.8,
        accuracyDelta: 0.3,
        previousMasteryLevel: 0.4,
        currentMasteryLevel: 0.7,
        previousLevel: MasteryLevel.browsing,
        currentLevel: MasteryLevel.developing,
        metadata: {'source': 'mock'},
      );

      final json = metric.toJson();

      expect(json['date'], baseDate.toIso8601String());
      expect(json['studentId'], 'stu1');
      expect(json['topicId'], 'topic1');
      expect(json['previousAccuracy'], 0.5);
      expect(json['currentAccuracy'], 0.8);
      expect(json['accuracyDelta'], 0.3);
      expect(json['previousMasteryLevel'], 0.4);
      expect(json['currentMasteryLevel'], 0.7);
      expect(json['previousLevel'], MasteryLevel.browsing.index);
      expect(json['currentLevel'], MasteryLevel.developing.index);
      expect(json['leveledUp'], isTrue);
      expect(json['metadata'], {'source': 'mock'});
    });

    test('toJson omits metadata when null', () {
      final metric = MasteryImprovementMetric(
        date: baseDate,
        studentId: 'stu1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.5,
        accuracyDelta: 0.0,
        previousMasteryLevel: 0.4,
        currentMasteryLevel: 0.4,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.novice,
      );

      final json = metric.toJson();
      expect(json['metadata'], isNull);
      expect(json['leveledUp'], isFalse);
    });
  });
}
