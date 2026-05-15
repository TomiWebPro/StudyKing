import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

void main() {
  group('RoadmapModel', () {
    late DateTime now;
    late MilestoneModel milestone;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
      milestone = MilestoneModel(
        id: 'ms-1',
        title: 'Complete Chapter 1',
        description: 'Finish all exercises',
        deadline: now.add(const Duration(days: 7)),
        topicsCovered: ['topic-1'],
        assessmentCriteria: ['criterion-1'],
        isCompleted: false,
        progress: 0.5,
        order: 1,
      );
    });

    group('constructor', () {
      test('creates with required fields', () {
        final roadmap = RoadmapModel(
          id: 'roadmap-1',
          studentId: 'student-1',
          goal: 'Master Algebra',
          createdAt: now,
        );
        expect(roadmap.id, 'roadmap-1');
        expect(roadmap.studentId, 'student-1');
        expect(roadmap.goal, 'Master Algebra');
        expect(roadmap.createdAt, now);
        expect(roadmap.targetCompletionDate, isNull);
        expect(roadmap.milestones, isEmpty);
        expect(roadmap.completionPercentage, 0.0);
        expect(roadmap.status, 'active');
        expect(roadmap.subjectId, isNull);
        expect(roadmap.plannedVsActual, isNull);
      });

      test('creates with all fields', () {
        final roadmap = RoadmapModel(
          id: 'roadmap-2',
          studentId: 'student-1',
          goal: 'Master Calculus',
          createdAt: now,
          targetCompletionDate: now.add(const Duration(days: 90)),
          milestones: [milestone],
          completionPercentage: 25.0,
          status: 'in_progress',
          subjectId: 'subject-1',
          plannedVsActual: {'week1': 80.0},
        );
        expect(roadmap.targetCompletionDate, now.add(const Duration(days: 90)));
        expect(roadmap.milestones, [milestone]);
        expect(roadmap.completionPercentage, 25.0);
        expect(roadmap.status, 'in_progress');
        expect(roadmap.subjectId, 'subject-1');
        expect(roadmap.plannedVsActual, {'week1': 80.0});
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final roadmap = RoadmapModel(
          id: 'r1',
          studentId: 's1',
          goal: 'G',
          createdAt: now,
          targetCompletionDate: now.add(const Duration(days: 30)),
          milestones: [milestone],
          completionPercentage: 50.0,
          status: 'active',
          subjectId: 'sub-1',
          plannedVsActual: {'w1': 60.0},
        );
        final copy = roadmap.copyWith();
        expect(copy.id, roadmap.id);
        expect(copy.studentId, roadmap.studentId);
        expect(copy.goal, roadmap.goal);
        expect(copy.createdAt, roadmap.createdAt);
        expect(copy.targetCompletionDate, roadmap.targetCompletionDate);
        expect(copy.milestones, roadmap.milestones);
        expect(copy.completionPercentage, roadmap.completionPercentage);
        expect(copy.status, roadmap.status);
        expect(copy.subjectId, roadmap.subjectId);
        expect(copy.plannedVsActual, roadmap.plannedVsActual);
      });

      test('updates specified fields', () {
        final roadmap = RoadmapModel(
          id: 'r1',
          studentId: 's1',
          goal: 'G',
          createdAt: now,
        );
        final copy = roadmap.copyWith(
          goal: 'New Goal',
          completionPercentage: 100.0,
          status: 'completed',
        );
        expect(copy.goal, 'New Goal');
        expect(copy.completionPercentage, 100.0);
        expect(copy.status, 'completed');
      });

      test('updates milestones', () {
        final roadmap = RoadmapModel(
          id: 'r1',
          studentId: 's1',
          goal: 'G',
          createdAt: now,
        );
        final copy = roadmap.copyWith(milestones: [milestone]);
        expect(copy.milestones, [milestone]);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final roadmap = RoadmapModel(
          id: 'r1',
          studentId: 's1',
          goal: 'Goal',
          createdAt: now,
          targetCompletionDate: now.add(const Duration(days: 30)),
          milestones: [milestone],
          completionPercentage: 50.0,
          status: 'active',
          subjectId: 'sub-1',
          plannedVsActual: {'w1': 60.0},
        );
        final json = roadmap.toJson();
        expect(json['id'], 'r1');
        expect(json['studentId'], 's1');
        expect(json['goal'], 'Goal');
        expect(json['createdAt'], now.toIso8601String());
        expect(json['targetCompletionDate'], now.add(const Duration(days: 30)).toIso8601String());
        expect(json['milestones'], isA<List>());
        expect((json['milestones'] as List).length, 1);
        expect(json['completionPercentage'], 50.0);
        expect(json['status'], 'active');
        expect(json['subjectId'], 'sub-1');
        expect(json['plannedVsActual'], {'w1': 60.0});
      });

      test('serializes with null optionals', () {
        final roadmap = RoadmapModel(
          id: 'r1',
          studentId: 's1',
          goal: 'Goal',
          createdAt: now,
        );
        final json = roadmap.toJson();
        expect(json['targetCompletionDate'], isNull);
        expect(json['milestones'], isEmpty);
        expect(json['subjectId'], isNull);
        expect(json['plannedVsActual'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'r1',
          'studentId': 's1',
          'goal': 'Goal',
          'createdAt': now.toIso8601String(),
          'targetCompletionDate': now.add(const Duration(days: 30)).toIso8601String(),
          'milestones': [
            {
              'id': 'ms-1',
              'title': 'Milestone 1',
              'description': 'Desc',
              'deadline': now.add(const Duration(days: 7)).toIso8601String(),
              'topicsCovered': ['t1'],
              'assessmentCriteria': ['c1'],
              'isCompleted': false,
              'progress': 0.5,
              'order': 1,
            }
          ],
          'completionPercentage': 50.0,
          'status': 'active',
          'subjectId': 'sub-1',
          'plannedVsActual': {'w1': 60.0},
        };
        final roadmap = RoadmapModel.fromJson(json);
        expect(roadmap.id, 'r1');
        expect(roadmap.goal, 'Goal');
        expect(roadmap.milestones.length, 1);
        expect(roadmap.milestones.first.title, 'Milestone 1');
        expect(roadmap.completionPercentage, 50.0);
        expect(roadmap.status, 'active');
        expect(roadmap.subjectId, 'sub-1');
        expect(roadmap.plannedVsActual, {'w1': 60.0});
      });

      test('deserializes with missing optional fields', () {
        final json = {
          'id': 'r1',
          'studentId': 's1',
          'goal': 'Goal',
          'createdAt': now.toIso8601String(),
        };
        final roadmap = RoadmapModel.fromJson(json);
        expect(roadmap.targetCompletionDate, isNull);
        expect(roadmap.milestones, isEmpty);
        expect(roadmap.completionPercentage, 0.0);
        expect(roadmap.status, 'active');
        expect(roadmap.subjectId, isNull);
        expect(roadmap.plannedVsActual, isNull);
      });

      test('handles null milestones', () {
        final json = {
          'id': 'r1',
          'studentId': 's1',
          'goal': 'Goal',
          'createdAt': now.toIso8601String(),
          'milestones': null,
        };
        final roadmap = RoadmapModel.fromJson(json);
        expect(roadmap.milestones, isEmpty);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = RoadmapModel(
          id: 'r1',
          studentId: 's1',
          goal: 'Goal',
          createdAt: now,
          targetCompletionDate: now.add(const Duration(days: 30)),
          milestones: [milestone],
          completionPercentage: 50.0,
          status: 'active',
          subjectId: 'sub-1',
          plannedVsActual: {'w1': 60.0},
        );
        final json = original.toJson();
        final restored = RoadmapModel.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.goal, original.goal);
        expect(restored.milestones.length, original.milestones.length);
        expect(restored.completionPercentage, original.completionPercentage);
        expect(restored.plannedVsActual, original.plannedVsActual);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = RoadmapModel(id: 'r1', studentId: 's1', goal: 'G', createdAt: now);
        final b = RoadmapModel(id: 'r1', studentId: 's1', goal: 'G', createdAt: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = RoadmapModel(id: 'r1', studentId: 's1', goal: 'G', createdAt: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = RoadmapModel(id: 'r1', studentId: 's1', goal: 'G', createdAt: now);
        expect(obj.toString(), contains('RoadmapModel'));
      });
    });
  });

  group('MilestoneModel', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final ms = MilestoneModel(
          id: 'ms-1',
          title: 'Complete Chapter 1',
          deadline: now,
        );
        expect(ms.id, 'ms-1');
        expect(ms.title, 'Complete Chapter 1');
        expect(ms.description, '');
        expect(ms.deadline, now);
        expect(ms.topicsCovered, isEmpty);
        expect(ms.assessmentCriteria, isEmpty);
        expect(ms.isCompleted, isFalse);
        expect(ms.progress, 0.0);
        expect(ms.order, 0);
      });

      test('creates with all fields', () {
        final ms = MilestoneModel(
          id: 'ms-2',
          title: 'Master Algebra',
          description: 'All exercises done',
          deadline: now,
          topicsCovered: ['topic-1', 'topic-2'],
          assessmentCriteria: ['80% accuracy'],
          isCompleted: true,
          progress: 1.0,
          order: 2,
        );
        expect(ms.description, 'All exercises done');
        expect(ms.topicsCovered, ['topic-1', 'topic-2']);
        expect(ms.assessmentCriteria, ['80% accuracy']);
        expect(ms.isCompleted, isTrue);
        expect(ms.progress, 1.0);
        expect(ms.order, 2);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final ms = MilestoneModel(
          id: 'ms-1',
          title: 'Title',
          description: 'Desc',
          deadline: now,
          topicsCovered: ['t1'],
          assessmentCriteria: ['c1'],
          isCompleted: true,
          progress: 0.8,
          order: 1,
        );
        final copy = ms.copyWith();
        expect(copy.id, ms.id);
        expect(copy.title, ms.title);
        expect(copy.description, ms.description);
        expect(copy.deadline, ms.deadline);
        expect(copy.topicsCovered, ms.topicsCovered);
        expect(copy.assessmentCriteria, ms.assessmentCriteria);
        expect(copy.isCompleted, ms.isCompleted);
        expect(copy.progress, ms.progress);
        expect(copy.order, ms.order);
      });

      test('updates specified fields', () {
        final ms = MilestoneModel(id: 'ms-1', title: 'Title', deadline: now);
        final copy = ms.copyWith(
          title: 'New Title',
          isCompleted: true,
          progress: 1.0,
        );
        expect(copy.title, 'New Title');
        expect(copy.isCompleted, isTrue);
        expect(copy.progress, 1.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final ms = MilestoneModel(
          id: 'ms-1',
          title: 'Title',
          description: 'Desc',
          deadline: now,
          topicsCovered: ['t1'],
          assessmentCriteria: ['c1'],
          isCompleted: true,
          progress: 0.8,
          order: 1,
        );
        final json = ms.toJson();
        expect(json['id'], 'ms-1');
        expect(json['title'], 'Title');
        expect(json['description'], 'Desc');
        expect(json['deadline'], now.toIso8601String());
        expect(json['topicsCovered'], ['t1']);
        expect(json['assessmentCriteria'], ['c1']);
        expect(json['isCompleted'], isTrue);
        expect(json['progress'], 0.8);
        expect(json['order'], 1);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'ms-1',
          'title': 'Title',
          'description': 'Desc',
          'deadline': now.toIso8601String(),
          'topicsCovered': ['t1'],
          'assessmentCriteria': ['c1'],
          'isCompleted': true,
          'progress': 0.8,
          'order': 1,
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.id, 'ms-1');
        expect(ms.title, 'Title');
        expect(ms.description, 'Desc');
        expect(ms.deadline, now);
        expect(ms.topicsCovered, ['t1']);
        expect(ms.assessmentCriteria, ['c1']);
        expect(ms.isCompleted, isTrue);
        expect(ms.progress, 0.8);
        expect(ms.order, 1);
      });

      test('deserializes with missing optional fields', () {
        final json = {
          'id': 'ms-1',
          'title': 'Title',
          'deadline': now.toIso8601String(),
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.description, '');
        expect(ms.topicsCovered, isEmpty);
        expect(ms.assessmentCriteria, isEmpty);
        expect(ms.isCompleted, isFalse);
        expect(ms.progress, 0.0);
        expect(ms.order, 0);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = MilestoneModel(
          id: 'ms-1',
          title: 'Title',
          description: 'Desc',
          deadline: now,
          topicsCovered: ['t1'],
          assessmentCriteria: ['c1'],
          isCompleted: true,
          progress: 0.8,
          order: 1,
        );
        final json = original.toJson();
        final restored = MilestoneModel.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.deadline, original.deadline);
        expect(restored.isCompleted, original.isCompleted);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = MilestoneModel(id: 'ms-1', title: 'T', deadline: now);
        final b = MilestoneModel(id: 'ms-1', title: 'T', deadline: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = MilestoneModel(id: 'ms-1', title: 'T', deadline: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = MilestoneModel(id: 'ms-1', title: 'T', deadline: now);
        expect(obj.toString(), contains('MilestoneModel'));
      });
    });

    group('fromJson edge cases', () {
      test('handles null progress', () {
        final json = {
          'id': 'ms-1',
          'title': 'Title',
          'deadline': now.toIso8601String(),
          'progress': null,
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.progress, 0.0);
      });

      test('handles null order', () {
        final json = {
          'id': 'ms-1',
          'title': 'Title',
          'deadline': now.toIso8601String(),
          'order': null,
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.order, 0);
      });

      test('handles null isCompleted', () {
        final json = {
          'id': 'ms-1',
          'title': 'Title',
          'deadline': now.toIso8601String(),
          'isCompleted': null,
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.isCompleted, isFalse);
      });

      test('handles null description', () {
        final json = {
          'id': 'ms-1',
          'title': 'Title',
          'deadline': now.toIso8601String(),
          'description': null,
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.description, '');
      });
    });
  });
}
