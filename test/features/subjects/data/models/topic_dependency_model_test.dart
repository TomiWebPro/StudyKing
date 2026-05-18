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

      test('returns true when readiness exceeds threshold', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          masteryThreshold: 0.8,
        );
        expect(dep.isReady([prereqId], 0.95), isTrue);
      });

      test('returns false when only some prerequisites met', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId, 't2'],
        );
        expect(dep.isReady([prereqId], null), isFalse);
      });

      test('returns true when all multiple prerequisites met', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId, 't2'],
        );
        expect(dep.isReady([prereqId, 't2'], null), isTrue);
      });

      test('returns true with no prerequisites and null readinessScore', () {
        final dep = TopicDependency(topicId: topicId);
        expect(dep.isReady([], null), isTrue);
      });

      test('returns true with no prerequisites and any readinessScore', () {
        final dep = TopicDependency(topicId: topicId);
        expect(dep.isReady([], 0.0), isTrue);
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

      test('applies all factors combined', () {
        final dep = TopicDependency(
          topicId: topicId, syllabusWeight: 2.0, masteryThreshold: 0.8,
        );
        final priority = dep.calculatePriority(
          masteryState: 0.5, isPrerequisite: true, downstreamCount: 3,
        );
        // base 2.0 * (1 + (0.8-0.5)) = 2.0 * 1.3 = 2.6
        // * 1.5 (prereq) = 3.9
        // * (1 + 3*0.1) = 3.9 * 1.3 = 5.07
        expect(priority, closeTo(5.07, 0.01));
      });

      test('masteryState at threshold does not increase priority', () {
        final dep = TopicDependency(
          topicId: topicId, syllabusWeight: 2.0, masteryThreshold: 0.8,
        );
        final priority = dep.calculatePriority(
          masteryState: 0.8, isPrerequisite: false, downstreamCount: 0,
        );
        expect(priority, 2.0);
      });

      test('masteryState of 0.0 applies full threshold gap', () {
        final dep = TopicDependency(
          topicId: topicId, masteryThreshold: 0.8,
        );
        final priority = dep.calculatePriority(
          masteryState: 0.0, isPrerequisite: false, downstreamCount: 0,
        );
        // 1.0 * (1 + 0.8) = 1.8
        expect(priority, closeTo(1.8, 0.01));
      });

      test('clamps to 0.0 when priority is negative', () {
        final dep = TopicDependency(
          topicId: topicId, syllabusWeight: -5.0, masteryThreshold: 0.8,
        );
        final priority = dep.calculatePriority(
          masteryState: 0.0, isPrerequisite: true, downstreamCount: 5,
        );
        expect(priority, 0.0);
      });

      test('downstreamCount of 0 adds no multiplier', () {
        final dep = TopicDependency(
          topicId: topicId, syllabusWeight: 1.0, masteryThreshold: 0.8,
        );
        final priority = dep.calculatePriority(
          masteryState: 0.0, isPrerequisite: true, downstreamCount: 0,
        );
        // 1.0 * (1 + 0.8) = 1.8 * 1.5 = 2.7
        expect(priority, closeTo(2.7, 0.01));
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
        expect(json['downstreamTopics'], ['t2']);
        expect(json['syllabusWeight'], 1.5);
        expect(json['dependencyWeights'], {prereqId: 0.3});
        expect(json['estimatedQuestions'], 15);
        expect(json['estimatedMinutes'], 45);
        expect(json['masteryThreshold'], 0.85);
        expect(json['isRequired'], isFalse);
        expect(json['parentTopicId'], 'p1');
        expect(json['sortOrder'], 2);
      });

      test('serializes null parentTopicId', () {
        final dep = TopicDependency(topicId: topicId);
        final json = dep.toJson();
        expect(json['parentTopicId'], isNull);
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
        expect(dep.topicId, topicId);
        expect(dep.prerequisites, [prereqId]);
        expect(dep.downstreamTopics, ['t2']);
        expect(dep.syllabusWeight, 2.0);
        expect(dep.dependencyWeights, {prereqId: 0.5});
        expect(dep.estimatedQuestions, 20);
        expect(dep.estimatedMinutes, 60);
        expect(dep.masteryThreshold, 0.9);
        expect(dep.isRequired, isFalse);
        expect(dep.parentTopicId, 'p1');
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

      test('handles null parentTopicId', () {
        final json = {
          'topicId': topicId,
          'parentTopicId': null,
        };
        final dep = TopicDependency.fromJson(json);
        expect(dep.parentTopicId, isNull);
      });

      test('handles integer values for double fields', () {
        final json = {
          'topicId': topicId,
          'syllabusWeight': 2,
          'masteryThreshold': 1,
        };
        final dep = TopicDependency.fromJson(json);
        expect(dep.syllabusWeight, 2.0);
        expect(dep.masteryThreshold, 1.0);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          downstreamTopics: ['t2'], syllabusWeight: 1.5,
          dependencyWeights: {prereqId: 0.3},
          estimatedQuestions: 15, estimatedMinutes: 45,
          masteryThreshold: 0.85, isRequired: false,
          parentTopicId: 'p1', sortOrder: 3,
        );
        final restored = TopicDependency.fromJson(original.toJson());
        expect(restored.topicId, original.topicId);
        expect(restored.prerequisites, original.prerequisites);
        expect(restored.downstreamTopics, original.downstreamTopics);
        expect(restored.syllabusWeight, original.syllabusWeight);
        expect(restored.dependencyWeights, original.dependencyWeights);
        expect(restored.estimatedQuestions, original.estimatedQuestions);
        expect(restored.estimatedMinutes, original.estimatedMinutes);
        expect(restored.masteryThreshold, original.masteryThreshold);
        expect(restored.isRequired, original.isRequired);
        expect(restored.parentTopicId, original.parentTopicId);
        expect(restored.sortOrder, original.sortOrder);
      });

      test('preserves null parentTopicId through roundtrip', () {
        final original = TopicDependency(topicId: topicId);
        final restored = TopicDependency.fromJson(original.toJson());
        expect(restored.parentTopicId, isNull);
      });

      test('preserves defaults through roundtrip', () {
        final original = TopicDependency(topicId: topicId);
        final restored = TopicDependency.fromJson(original.toJson());
        expect(restored.prerequisites, []);
        expect(restored.syllabusWeight, 1.0);
        expect(restored.sortOrder, 0);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final dep = TopicDependency(topicId: topicId);
        final copy = dep.copyWith();
        expect(copy.topicId, dep.topicId);
        expect(copy.prerequisites, dep.prerequisites);
        expect(copy.sortOrder, dep.sortOrder);
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

      test('updates all fields at once', () {
        final dep = TopicDependency(topicId: topicId);
        final copy = dep.copyWith(
          topicId: 't2',
          prerequisites: ['p1'],
          downstreamTopics: ['d1'],
          syllabusWeight: 3.0,
          dependencyWeights: {'p1': 0.7},
          estimatedQuestions: 25,
          estimatedMinutes: 50,
          masteryThreshold: 0.75,
          isRequired: false,
          parentTopicId: 'parent-2',
          sortOrder: 7,
        );
        expect(copy.topicId, 't2');
        expect(copy.prerequisites, ['p1']);
        expect(copy.downstreamTopics, ['d1']);
        expect(copy.syllabusWeight, 3.0);
        expect(copy.dependencyWeights, {'p1': 0.7});
        expect(copy.estimatedQuestions, 25);
        expect(copy.estimatedMinutes, 50);
        expect(copy.masteryThreshold, 0.75);
        expect(copy.isRequired, isFalse);
        expect(copy.parentTopicId, 'parent-2');
        expect(copy.sortOrder, 7);
      });

      test('original is not mutated by copyWith', () {
        final dep = TopicDependency(
          topicId: topicId, isRequired: true, sortOrder: 0,
        );
        dep.copyWith(isRequired: false, sortOrder: 99);
        expect(dep.isRequired, isTrue);
        expect(dep.sortOrder, 0);
      });

      test('preserves fields not specified in copyWith', () {
        final dep = TopicDependency(
          topicId: topicId, prerequisites: [prereqId],
          sortOrder: 5, masteryThreshold: 0.9,
        );
        final copy = dep.copyWith(isRequired: false);
        expect(copy.prerequisites, [prereqId]);
        expect(copy.sortOrder, 5);
        expect(copy.masteryThreshold, 0.9);
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

      test('creates with empty childTopicIds', () {
        final dep = TopicDependency.fromTopic(
          topicId: topicId,
          childTopicIds: [],
          parentId: 'root',
        );
        expect(dep.downstreamTopics, []);
        expect(dep.parentTopicId, 'root');
      });

      test('defaults other fields to constructor defaults', () {
        final dep = TopicDependency.fromTopic(
          topicId: topicId,
          childTopicIds: ['t2'],
        );
        expect(dep.prerequisites, []);
        expect(dep.syllabusWeight, 1.0);
        expect(dep.masteryThreshold, 0.8);
        expect(dep.isRequired, isTrue);
        expect(dep.estimatedQuestions, 10);
        expect(dep.estimatedMinutes, 30);
        expect(dep.dependencyWeights, {});
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = TopicDependency(topicId: topicId);
        expect(a == a, isTrue);
      });

      test('different instances are not equal by default (identity)', () {
        final a = TopicDependency(topicId: 't1');
        final b = TopicDependency(topicId: 't2');
        expect(a == b, isFalse);
      });

      test('same values but different instances are not equal', () {
        final a = TopicDependency(topicId: topicId);
        final b = TopicDependency(topicId: topicId);
        expect(a == b, isFalse);
      });

      test('hashCode is consistent across calls', () {
        final a = TopicDependency(topicId: topicId);
        expect(a.hashCode, a.hashCode);
      });

      test('different objects likely have different hashCodes', () {
        final a = TopicDependency(topicId: 't1');
        final b = TopicDependency(topicId: 't2');
        expect(a.hashCode == b.hashCode, isFalse);
      });
    });

    group('edge cases', () {
      group('isReady', () {
        test('returns true with empty prerequisites even if completedTopicIds is empty', () {
          final dep = TopicDependency(topicId: topicId, prerequisites: []);
          expect(dep.isReady([], null), isTrue);
        });

        test('returns true when prereqs met even with extra completed IDs', () {
          final dep = TopicDependency(
            topicId: topicId, prerequisites: [prereqId],
          );
          expect(dep.isReady([prereqId, 't2', 't3'], null), isTrue);
        });
      });

      group('calculatePriority', () {
        test('returns 0 with syllabusWeight of 0', () {
          final dep = TopicDependency(
            topicId: topicId, syllabusWeight: 0.0,
          );
          final priority = dep.calculatePriority(
            masteryState: 0.9, isPrerequisite: false, downstreamCount: 0,
          );
          expect(priority, 0.0);
        });

        test('very large downstreamCount is clamped to 10.0', () {
          final dep = TopicDependency(
            topicId: topicId, syllabusWeight: 1.0, masteryThreshold: 0.8,
          );
          final priority = dep.calculatePriority(
            masteryState: 0.0, isPrerequisite: true, downstreamCount: 100,
          );
          // would be huge, but clamped to 10.0
          expect(priority, 10.0);
        });

        test('combines low mastery, isPrerequisite, and downstreamCount', () {
          final dep = TopicDependency(
            topicId: topicId, syllabusWeight: 1.0, masteryThreshold: 0.8,
          );
          final priority = dep.calculatePriority(
            masteryState: 0.0, isPrerequisite: true, downstreamCount: 10,
          );
          // 1.0 * (1 + 0.8) = 1.8 (*1.5 prereq) = 2.7 (* (1+10*0.1)) = 5.4
          expect(priority, closeTo(5.4, 0.01));
        });
      });

      group('fromJson', () {
        test('handles empty prerequisites list', () {
          final json = {
            'topicId': topicId,
            'prerequisites': <String>[],
          };
          final dep = TopicDependency.fromJson(json);
          expect(dep.prerequisites, []);
        });

        test('handles empty downstreamTopics list', () {
          final json = {
            'topicId': topicId,
            'downstreamTopics': <String>[],
          };
          final dep = TopicDependency.fromJson(json);
          expect(dep.downstreamTopics, []);
        });

        test('handles empty dependencyWeights map', () {
          final json = {
            'topicId': topicId,
            'dependencyWeights': <String, double>{},
          };
          final dep = TopicDependency.fromJson(json);
          expect(dep.dependencyWeights, {});
        });

        test('handles empty string topicId', () {
          final json = {'topicId': ''};
          final dep = TopicDependency.fromJson(json);
          expect(dep.topicId, '');
        });
      });

      group('copyWith', () {
        test('can replace prerequisites with empty list', () {
          final dep = TopicDependency(
            topicId: topicId, prerequisites: [prereqId],
          );
          final copy = dep.copyWith(prerequisites: []);
          expect(copy.prerequisites, []);
        });

        test('can replace downstreamTopics with empty list', () {
          final dep = TopicDependency(
            topicId: topicId, downstreamTopics: ['t2'],
          );
          final copy = dep.copyWith(downstreamTopics: []);
          expect(copy.downstreamTopics, []);
        });

        test('can replace dependencyWeights with empty map', () {
          final dep = TopicDependency(
            topicId: topicId,
            dependencyWeights: {prereqId: 0.5},
          );
          final copy = dep.copyWith(dependencyWeights: {});
          expect(copy.dependencyWeights, {});
        });

        test('passing null for parentTopicId preserves original value', () {
          final dep = TopicDependency(
            topicId: topicId, parentTopicId: 'p1',
          );
          final copy = dep.copyWith(parentTopicId: null);
          // copyWith uses `??` so null keeps the original
          expect(copy.parentTopicId, 'p1');
        });
      });
    });
  });
}
