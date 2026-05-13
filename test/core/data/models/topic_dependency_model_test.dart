import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';

void main() {
  group('TopicDependency', () {
    group('constructor', () {
      test('creates with required fields', () {
        final dep = TopicDependency(topicId: 'topic-1');
        expect(dep.topicId, 'topic-1');
        expect(dep.prerequisites, isEmpty);
        expect(dep.downstreamTopics, isEmpty);
        expect(dep.syllabusWeight, 1.0);
        expect(dep.estimatedQuestions, 10);
        expect(dep.masteryThreshold, 0.8);
        expect(dep.isRequired, isTrue);
      });

      test('creates with all fields', () {
        final dep = TopicDependency(
          topicId: 'topic-1',
          prerequisites: ['topic-0'],
          downstreamTopics: ['topic-2', 'topic-3'],
          syllabusWeight: 2.0,
          dependencyWeights: {'topic-0': 0.5},
          estimatedQuestions: 20,
          estimatedMinutes: 60,
          masteryThreshold: 0.7,
          isRequired: false,
          parentTopicId: 'parent-1',
          sortOrder: 3,
        );
        expect(dep.prerequisites, ['topic-0']);
        expect(dep.downstreamTopics, ['topic-2', 'topic-3']);
        expect(dep.syllabusWeight, 2.0);
        expect(dep.isRequired, isFalse);
        expect(dep.sortOrder, 3);
      });
    });

    group('isReady', () {
      test('returns true when no prerequisites', () {
        final dep = TopicDependency(topicId: 'topic-1');
        expect(dep.isReady([], null), isTrue);
        expect(dep.isReady([], 0.5), isTrue);
      });

      test('returns true when all prerequisites met', () {
        final dep = TopicDependency(
          topicId: 'topic-1',
          prerequisites: ['topic-0'],
          masteryThreshold: 0.8,
        );
        expect(dep.isReady(['topic-0'], 0.9), isTrue);
      });

      test('returns false when prerequisite not completed', () {
        final dep = TopicDependency(
          topicId: 'topic-1',
          prerequisites: ['topic-0'],
        );
        expect(dep.isReady([], null), isFalse);
      });

      test('returns false when readiness below threshold', () {
        final dep = TopicDependency(
          topicId: 'topic-1',
          prerequisites: ['topic-0'],
          masteryThreshold: 0.8,
        );
        expect(dep.isReady(['topic-0'], 0.5), isFalse);
      });

      test('handles multiple prerequisites', () {
        final dep = TopicDependency(
          topicId: 'topic-3',
          prerequisites: ['topic-1', 'topic-2'],
        );
        expect(dep.isReady(['topic-1', 'topic-2'], null), isTrue);
        expect(dep.isReady(['topic-1'], null), isFalse);
      });
    });

    group('calculatePriority', () {
      test('returns base priority when all conditions default', () {
        final dep = TopicDependency(topicId: 'topic-1');
        final priority = dep.calculatePriority(
          masteryState: 0.9,
          isPrerequisite: false,
          downstreamCount: 0,
        );
        expect(priority, 1.0);
      });

      test('increases priority when mastery below threshold', () {
        final dep = TopicDependency(topicId: 'topic-1', masteryThreshold: 0.8);
        final priority = dep.calculatePriority(
          masteryState: 0.5,
          isPrerequisite: false,
          downstreamCount: 0,
        );
        expect(priority, greaterThan(1.0));
      });

      test('increases priority for prerequisites', () {
        final dep = TopicDependency(topicId: 'topic-1');
        final priority = dep.calculatePriority(
          masteryState: 0.9,
          isPrerequisite: true,
          downstreamCount: 0,
        );
        expect(priority, 1.5);
      });

      test('increases priority with downstream topics', () {
        final dep = TopicDependency(topicId: 'topic-1');
        final priority = dep.calculatePriority(
          masteryState: 0.9,
          isPrerequisite: false,
          downstreamCount: 5,
        );
        expect(priority, 1.5);
      });

      test('clamps to max 10.0', () {
        final dep = TopicDependency(
          topicId: 'topic-1',
          syllabusWeight: 5.0,
          masteryThreshold: 0.8,
        );
        final priority = dep.calculatePriority(
          masteryState: 0.0,
          isPrerequisite: true,
          downstreamCount: 20,
        );
        expect(priority, 10.0);
      });
    });

    group('fromTopic', () {
      test('creates dependency from topic data', () {
        final dep = TopicDependency.fromTopic(
          topicId: 'topic-1',
          childTopicIds: ['topic-2', 'topic-3'],
          parentId: 'parent-1',
          sortOrder: 2,
        );
        expect(dep.topicId, 'topic-1');
        expect(dep.downstreamTopics, ['topic-2', 'topic-3']);
        expect(dep.parentTopicId, 'parent-1');
        expect(dep.sortOrder, 2);
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip', () {
        final original = TopicDependency(
          topicId: 'topic-1',
          prerequisites: ['topic-0'],
          downstreamTopics: ['topic-2'],
          syllabusWeight: 1.5,
          masteryThreshold: 0.75,
          isRequired: true,
          sortOrder: 1,
        );
        final json = original.toJson();
        final restored = TopicDependency.fromJson(json);
        expect(restored.topicId, original.topicId);
        expect(restored.prerequisites, original.prerequisites);
        expect(restored.syllabusWeight, original.syllabusWeight);
        expect(restored.masteryThreshold, original.masteryThreshold);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final dep = TopicDependency(topicId: 'topic-1');
        final copy = dep.copyWith(
          prerequisites: ['topic-0'],
          masteryThreshold: 0.9,
        );
        expect(copy.prerequisites, ['topic-0']);
        expect(copy.masteryThreshold, 0.9);
        expect(copy.topicId, 'topic-1');
      });
    });
  });
}
