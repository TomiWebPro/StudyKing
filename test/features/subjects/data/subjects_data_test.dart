import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/subjects_data.dart';

void main() {
  group('subjects_data barrel', () {
    test('TopicDependency can be constructed with required fields', () {
      final dep = TopicDependency(topicId: 't1');
      expect(dep.topicId, 't1');
      expect(dep.prerequisites, isEmpty);
      expect(dep.downstreamTopics, isEmpty);
      expect(dep.isRequired, isTrue);
      expect(dep.sortOrder, 0);
    });

    test('TopicDependency.isReady returns true when no prerequisites', () {
      final dep = TopicDependency(topicId: 't1');
      expect(dep.isReady([], null), isTrue);
      expect(dep.isReady(['t2'], 0.9), isTrue);
    });

    test('TopicDependency.isReady returns false when prerequisites not met', () {
      final dep = TopicDependency(
        topicId: 't1',
        prerequisites: ['p1', 'p2'],
      );
      expect(dep.isReady([], null), isFalse);
      expect(dep.isReady(['p1'], null), isFalse);
    });

    test('TopicDependency.isReady returns true when all prerequisites met', () {
      final dep = TopicDependency(
        topicId: 't1',
        prerequisites: ['p1', 'p2'],
      );
      expect(dep.isReady(['p1', 'p2'], null), isTrue);
    });

    test('TopicDependency.calculatePriority returns positive value', () {
      final dep = TopicDependency(
        topicId: 't1',
        syllabusWeight: 1.0,
        masteryThreshold: 0.8,
      );
      final priority = dep.calculatePriority(
        masteryState: 0.5,
        isPrerequisite: false,
        downstreamCount: 0,
      );
      expect(priority, greaterThan(0));
    });

    test('registerSubjectsAdapters can be called without throwing', () {
      expect(() => registerSubjectsAdapters(), returnsNormally);
    });

    test('TopicDependency supports toJson/fromJson round-trip', () {
      final dep = TopicDependency(
        topicId: 't1',
        prerequisites: ['p1'],
        downstreamTopics: ['d1'],
        syllabusWeight: 2.0,
        estimatedQuestions: 15,
        isRequired: false,
        sortOrder: 1,
      );
      final json = dep.toJson();
      final restored = TopicDependency.fromJson(json);
      expect(restored.topicId, 't1');
      expect(restored.prerequisites, ['p1']);
      expect(restored.downstreamTopics, ['d1']);
      expect(restored.syllabusWeight, 2.0);
      expect(restored.estimatedQuestions, 15);
      expect(restored.isRequired, isFalse);
      expect(restored.sortOrder, 1);
    });

    test('TopicDependency supports copyWith', () {
      final dep = TopicDependency(topicId: 't1');
      final copied = dep.copyWith(topicId: 't2', isRequired: false);
      expect(copied.topicId, 't2');
      expect(copied.isRequired, isFalse);
      expect(copied.sortOrder, dep.sortOrder);
    });
  });
}
