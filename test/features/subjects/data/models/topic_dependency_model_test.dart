import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';

void main() {
  group('TopicDependency', () {
    const topicId = 't1';
    const prereqId = 't0';

    group('constructor', () {
      test('creates instance with required fields', () {
        final dep = TopicDependency(topicId: topicId);
        expect(dep.topicId, topicId);
        expect(dep.prerequisites, []);
        expect(dep.downstreamTopics, []);
        expect(dep.syllabusWeight, 1.0);
        expect(dep.dependencyWeights, {});
        expect(dep.estimatedQuestions, 10);
        expect(dep.estimatedMinutes, 30);
        expect(dep.masteryThreshold, 0.8);
        expect(dep.isRequired, isTrue);
        expect(dep.parentTopicId, isNull);
        expect(dep.sortOrder, 0);
      });

      test('accepts all optional fields', () {
        final dep = TopicDependency(
          topicId: topicId,
          prerequisites: [prereqId],
          downstreamTopics: ['t2'],
          syllabusWeight: 2.0,
          dependencyWeights: {prereqId: 0.5},
          estimatedQuestions: 20,
          estimatedMinutes: 60,
          masteryThreshold: 0.9,
          isRequired: false,
          parentTopicId: 'parent-1',
          sortOrder: 3,
        );
        expect(dep.prerequisites, [prereqId]);
        expect(dep.downstreamTopics, ['t2']);
        expect(dep.syllabusWeight, 2.0);
        expect(dep.dependencyWeights, {prereqId: 0.5});
        expect(dep.estimatedQuestions, 20);
        expect(dep.estimatedMinutes, 60);
        expect(dep.masteryThreshold, 0.9);
        expect(dep.isRequired, isFalse);
        expect(dep.parentTopicId, 'parent-1');
        expect(dep.sortOrder, 3);
      });
    });

    group('isReady', () {
      test('returns true when no prerequisites', () {
        final dep = TopicDependency(topicId: topicId);
        expect(dep.isReady([], null), isTrue);
      });

      test('returns true when prerequisites met', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
        );
        expect(dep.isReady([prereqId], null), isTrue);
      });

      test('returns false when prerequisites not met', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
        );
        expect(dep.isReady([], null), isFalse);
      });

      test('returns false when readiness below threshold', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          masteryThreshold: 0.8,
        );
        expect(dep.isReady([prereqId], 0.5), isFalse);
      });

      test('returns true when readiness meets threshold', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          masteryThreshold: 0.8,
        );
        expect(dep.isReady([prereqId], 0.8), isTrue);
      });
    });

    group('calculatePriority', () {
      test('returns base weight when mastery meets threshold', () {
        final dep = TopicDependency(topicId: topicId, masteryThreshold: 0.8);
        final priority = dep.calculatePriority(
          masteryState: 0.9, isPrerequisite: false, downstreamCount: 0,
        );
        expect(priority, 1.0);
      });

      test('increases for low mastery', () {
        final dep = TopicDependency(topicId: topicId, masteryThreshold: 0.8);
        final priority = dep.calculatePriority(
          masteryState: 0.3, isPrerequisite: false, downstreamCount: 0,
        );
        expect(priority, closeTo(1.5, 0.01));
      });

      test('increases for prerequisites', () {
        final dep = TopicDependency(topicId: topicId);
        final priority = dep.calculatePriority(
          masteryState: 0.9, isPrerequisite: true, downstreamCount: 0,
        );
        expect(priority, closeTo(1.5, 0.01));
      });

      test('increases with downstream count', () {
        final dep = TopicDependency(topicId: topicId);
        final priority = dep.calculatePriority(
          masteryState: 0.9, isPrerequisite: false, downstreamCount: 5,
        );
        expect(priority, closeTo(1.5, 0.01));
      });

      test('clamps to 10.0', () {
        final dep = TopicDependency(topicId: topicId, syllabusWeight: 10.0);
        final priority = dep.calculatePriority(
          masteryState: 0.0, isPrerequisite: true, downstreamCount: 10,
        );
        expect(priority, 10.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          downstreamTopics: ['t2'], syllabusWeight: 1.5,
          dependencyWeights: {prereqId: 0.3},
          estimatedQuestions: 15, estimatedMinutes: 45,
          masteryThreshold: 0.85, isRequired: false,
          parentTopicId: 'p1', sortOrder: 2,
        );
        final json = dep.toJson();
        expect(json['topicId'], topicId);
        expect(json['prerequisites'], [prereqId]);
        expect(json['syllabusWeight'], 1.5);
        expect(json['masteryThreshold'], 0.85);
        expect(json['isRequired'], isFalse);
        expect(json['sortOrder'], 2);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'topicId': topicId,
          'prerequisites': [prereqId],
          'downstreamTopics': ['t2'],
          'syllabusWeight': 2.0,
          'dependencyWeights': {prereqId: 0.5},
          'estimatedQuestions': 20,
          'estimatedMinutes': 60,
          'masteryThreshold': 0.9,
          'isRequired': false,
          'parentTopicId': 'p1',
          'sortOrder': 5,
        };
        final dep = TopicDependency.fromJson(json);
        expect(dep.prerequisites, [prereqId]);
        expect(dep.syllabusWeight, 2.0);
        expect(dep.masteryThreshold, 0.9);
        expect(dep.isRequired, isFalse);
        expect(dep.sortOrder, 5);
      });

      test('handles missing optional fields', () {
        final json = {'topicId': topicId};
        final dep = TopicDependency.fromJson(json);
        expect(dep.prerequisites, []);
        expect(dep.downstreamTopics, []);
        expect(dep.syllabusWeight, 1.0);
        expect(dep.dependencyWeights, {});
        expect(dep.estimatedQuestions, 10);
        expect(dep.estimatedMinutes, 30);
        expect(dep.masteryThreshold, 0.8);
        expect(dep.isRequired, isTrue);
        expect(dep.parentTopicId, isNull);
        expect(dep.sortOrder, 0);
      });

      test('handles null dependencyWeights', () {
        final json = {
          'topicId': topicId,
          'dependencyWeights': null,
        };
        final dep = TopicDependency.fromJson(json);
        expect(dep.dependencyWeights, {});
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          downstreamTopics: ['t2'], syllabusWeight: 1.5,
          masteryThreshold: 0.85, sortOrder: 3,
        );
        final restored = TopicDependency.fromJson(original.toJson());
        expect(restored.topicId, original.topicId);
        expect(restored.prerequisites, original.prerequisites);
        expect(restored.syllabusWeight, original.syllabusWeight);
        expect(restored.sortOrder, original.sortOrder);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final dep = TopicDependency(topicId: topicId);
        final copy = dep.copyWith();
        expect(copy.topicId, dep.topicId);
      });

      test('updates specified fields', () {
        final dep = TopicDependency(topicId: topicId);
        final copy = dep.copyWith(
          isRequired: false, sortOrder: 10, masteryThreshold: 0.95,
        );
        expect(copy.isRequired, isFalse);
        expect(copy.sortOrder, 10);
        expect(copy.masteryThreshold, 0.95);
        expect(copy.topicId, topicId);
      });
    });

    group('fromTopic', () {
      test('creates from topic with child topic IDs', () {
        final dep = TopicDependency.fromTopic(
          topicId: topicId,
          childTopicIds: ['t2', 't3'],
          parentId: 'p1',
          sortOrder: 1,
        );
        expect(dep.topicId, topicId);
        expect(dep.downstreamTopics, ['t2', 't3']);
        expect(dep.parentTopicId, 'p1');
        expect(dep.sortOrder, 1);
      });

      test('uses defaults for optional params', () {
        final dep = TopicDependency.fromTopic(
          topicId: topicId,
          childTopicIds: [],
        );
        expect(dep.parentTopicId, isNull);
        expect(dep.sortOrder, 0);
      });
    });
  });
}
