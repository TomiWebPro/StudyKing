import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

void main() {
  group('RoadmapModel', () {
    final now = DateTime(2026, 5, 16);
    const id = 'roadmap-1';
    const studentId = 'student-1';
    const goal = 'Master IB Physics';
    final targetDate = DateTime(2026, 12, 31);

    group('constructor', () {
      test('creates instance with required fields', () {
        final roadmap = RoadmapModel(
          id: id, studentId: studentId, goal: goal, createdAt: now,
        );
        expect(roadmap.id, id);
        expect(roadmap.studentId, studentId);
        expect(roadmap.goal, goal);
        expect(roadmap.createdAt, now);
        expect(roadmap.targetCompletionDate, isNull);
        expect(roadmap.milestones, []);
        expect(roadmap.completionPercentage, 0.0);
        expect(roadmap.status, 'active');
        expect(roadmap.subjectId, isNull);
        expect(roadmap.plannedVsActual, isNull);
      });

      test('accepts all optional fields', () {
        final milestone = MilestoneModel(
          id: 'm1', title: 'Finish Kinematics', deadline: now,
        );
        final roadmap = RoadmapModel(
          id: id, studentId: studentId, goal: goal, createdAt: now,
          targetCompletionDate: targetDate,
          milestones: [milestone],
          completionPercentage: 25.0,
          status: 'in_progress',
          subjectId: 'subject-1',
          plannedVsActual: {'planned': 10.0, 'actual': 8.0},
        );
        expect(roadmap.targetCompletionDate, targetDate);
        expect(roadmap.milestones.length, 1);
        expect(roadmap.completionPercentage, 25.0);
        expect(roadmap.status, 'in_progress');
        expect(roadmap.subjectId, 'subject-1');
        expect(roadmap.plannedVsActual, {'planned': 10.0, 'actual': 8.0});
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final milestone = MilestoneModel(
          id: 'm1', title: 'Milestone 1', deadline: now, description: 'Desc',
          topicsCovered: ['t1'], assessmentCriteria: ['c1'],
          isCompleted: true, progress: 100.0, order: 1,
        );
        final roadmap = RoadmapModel(
          id: id, studentId: studentId, goal: goal, createdAt: now,
          targetCompletionDate: targetDate,
          milestones: [milestone],
          completionPercentage: 50.0,
          status: 'active',
          subjectId: 'sub-1',
          plannedVsActual: {'p': 20.0},
        );
        final json = roadmap.toJson();
        expect(json['id'], id);
        expect(json['studentId'], studentId);
        expect(json['goal'], goal);
        expect(json['createdAt'], now.toIso8601String());
        expect(json['targetCompletionDate'], targetDate.toIso8601String());
        expect(json['milestones'], isA<List>());
        expect((json['milestones'] as List).length, 1);
        expect(json['completionPercentage'], 50.0);
        expect(json['status'], 'active');
        expect(json['subjectId'], 'sub-1');
        expect(json['plannedVsActual'], {'p': 20.0});
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'goal': goal,
          'createdAt': now.toIso8601String(),
          'targetCompletionDate': targetDate.toIso8601String(),
          'milestones': [
            {
              'id': 'm1', 'title': 'M1', 'description': 'Desc',
              'deadline': now.toIso8601String(),
              'topicsCovered': ['t1'], 'assessmentCriteria': ['c1'],
              'isCompleted': false, 'progress': 0.0, 'order': 0,
            }
          ],
          'completionPercentage': 10.0,
          'status': 'active',
          'subjectId': 'sub-1',
          'plannedVsActual': {'p': 5.0},
        };
        final roadmap = RoadmapModel.fromJson(json);
        expect(roadmap.id, id);
        expect(roadmap.milestones.length, 1);
        expect(roadmap.completionPercentage, 10.0);
        expect(roadmap.status, 'active');
        expect(roadmap.subjectId, 'sub-1');
        expect(roadmap.plannedVsActual, {'p': 5.0});
      });

      test('handles missing optional fields', () {
        final json = {
          'id': id, 'studentId': studentId, 'goal': goal,
          'createdAt': now.toIso8601String(),
        };
        final roadmap = RoadmapModel.fromJson(json);
        expect(roadmap.targetCompletionDate, isNull);
        expect(roadmap.milestones, []);
        expect(roadmap.completionPercentage, 0.0);
        expect(roadmap.status, 'active');
        expect(roadmap.subjectId, isNull);
        expect(roadmap.plannedVsActual, isNull);
      });

      test('handles null milestones', () {
        final json = {
          'id': id, 'studentId': studentId, 'goal': goal,
          'createdAt': now.toIso8601String(),
          'milestones': null,
        };
        final roadmap = RoadmapModel.fromJson(json);
        expect(roadmap.milestones, []);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final milestone = MilestoneModel(
          id: 'm1', title: 'M1', deadline: now,
        );
        final original = RoadmapModel(
          id: id, studentId: studentId, goal: goal, createdAt: now,
          milestones: [milestone], completionPercentage: 75.0,
        );
        final restored = RoadmapModel.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.completionPercentage, original.completionPercentage);
        expect(restored.milestones.length, original.milestones.length);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final r = RoadmapModel(id: id, studentId: studentId, goal: goal, createdAt: now);
        final copy = r.copyWith();
        expect(copy.id, r.id);
        expect(copy.goal, r.goal);
      });

      test('updates specified fields', () {
        final r = RoadmapModel(id: id, studentId: studentId, goal: goal, createdAt: now);
        final copy = r.copyWith(status: 'completed', completionPercentage: 100.0);
        expect(copy.status, 'completed');
        expect(copy.completionPercentage, 100.0);
        expect(copy.goal, goal);
      });
    });
  });

  group('MilestoneModel', () {
    final now = DateTime(2026, 6, 1);
    const id = 'ms-1';
    const title = 'Midterm Review';

    group('constructor', () {
      test('creates with required fields', () {
        final ms = MilestoneModel(id: id, title: title, deadline: now);
        expect(ms.id, id);
        expect(ms.title, title);
        expect(ms.deadline, now);
        expect(ms.description, '');
        expect(ms.topicsCovered, []);
        expect(ms.assessmentCriteria, []);
        expect(ms.isCompleted, isFalse);
        expect(ms.progress, 0.0);
        expect(ms.order, 0);
      });

      test('accepts all optional fields', () {
        final ms = MilestoneModel(
          id: id, title: title, deadline: now,
          description: 'Desc', topicsCovered: ['t1'],
          assessmentCriteria: ['c1'], isCompleted: true,
          progress: 100.0, order: 2,
        );
        expect(ms.description, 'Desc');
        expect(ms.topicsCovered, ['t1']);
        expect(ms.assessmentCriteria, ['c1']);
        expect(ms.isCompleted, isTrue);
        expect(ms.progress, 100.0);
        expect(ms.order, 2);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final ms = MilestoneModel(
          id: id, title: title, deadline: now, description: 'Desc',
          topicsCovered: ['t1'], assessmentCriteria: ['c1'],
          isCompleted: true, progress: 50.0, order: 1,
        );
        final json = ms.toJson();
        expect(json['id'], id);
        expect(json['title'], title);
        expect(json['deadline'], now.toIso8601String());
        expect(json['description'], 'Desc');
        expect(json['topicsCovered'], ['t1']);
        expect(json['assessmentCriteria'], ['c1']);
        expect(json['isCompleted'], isTrue);
        expect(json['progress'], 50.0);
        expect(json['order'], 1);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': id, 'title': title, 'deadline': now.toIso8601String(),
          'description': 'Desc', 'topicsCovered': ['t1'],
          'assessmentCriteria': ['c1'], 'isCompleted': true,
          'progress': 75.0, 'order': 3,
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.id, id);
        expect(ms.description, 'Desc');
        expect(ms.isCompleted, isTrue);
        expect(ms.progress, 75.0);
        expect(ms.order, 3);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': id, 'title': title, 'deadline': now.toIso8601String(),
        };
        final ms = MilestoneModel.fromJson(json);
        expect(ms.description, '');
        expect(ms.topicsCovered, []);
        expect(ms.assessmentCriteria, []);
        expect(ms.isCompleted, isFalse);
        expect(ms.progress, 0.0);
        expect(ms.order, 0);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = MilestoneModel(
          id: id, title: title, deadline: now, progress: 80.0,
        );
        final restored = MilestoneModel.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.progress, original.progress);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final ms = MilestoneModel(id: id, title: title, deadline: now);
        final copy = ms.copyWith();
        expect(copy.id, ms.id);
        expect(copy.title, ms.title);
      });

      test('updates specified fields', () {
        final ms = MilestoneModel(id: id, title: title, deadline: now);
        final copy = ms.copyWith(isCompleted: true, progress: 100.0);
        expect(copy.isCompleted, isTrue);
        expect(copy.progress, 100.0);
        expect(copy.title, title);
      });
    });
  });
}
