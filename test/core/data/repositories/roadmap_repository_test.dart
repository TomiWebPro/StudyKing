import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/models/roadmap_model.dart';

class _MockRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    _storage[roadmap.id] = roadmap;
  }

  @override
  Future<RoadmapModel?> loadRoadmap(String id) async {
    return _storage[id];
  }

  @override
  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    return _storage.values.where((r) => r.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<RoadmapModel>> getAllRoadmaps() async {
    return _storage.values.toList();
  }

  @override
  Future<void> deleteRoadmap(String id) async {
    _storage.remove(id);
  }

  @override
  Future<bool> hasRoadmap(String id) async {
    return _storage.containsKey(id);
  }
}

RoadmapModel createTestRoadmap({
  String id = 'roadmap-1',
  String studentId = 'student-1',
  String goal = 'Master Algebra',
  DateTime? createdAt,
}) {
  return RoadmapModel(
    id: id,
    studentId: studentId,
    goal: goal,
    createdAt: createdAt ?? DateTime(2026, 5, 12),
  );
}

void main() {
  group('RoadmapRepository', () {
    late _MockRoadmapRepository repository;

    setUp(() {
      repository = _MockRoadmapRepository();
    });

    group('init', () {
      test('completes successfully', () async {
        await repository.init();
      });
    });

    group('saveRoadmap', () {
      test('stores a roadmap', () async {
        final roadmap = createTestRoadmap();
        await repository.saveRoadmap(roadmap);
        final stored = await repository.loadRoadmap('roadmap-1');
        expect(stored?.goal, 'Master Algebra');
      });

      test('overwrites existing roadmap with same id', () async {
        final r1 = createTestRoadmap(goal: 'Goal A');
        final r2 = createTestRoadmap(goal: 'Goal B');
        await repository.saveRoadmap(r1);
        await repository.saveRoadmap(r2);
        expect((await repository.loadRoadmap('roadmap-1'))?.goal, 'Goal B');
      });
    });

    group('loadRoadmap', () {
      test('returns null for non-existent', () async {
        expect(await repository.loadRoadmap('none'), isNull);
      });

      test('returns stored roadmap', () async {
        await repository.saveRoadmap(createTestRoadmap());
        expect(await repository.loadRoadmap('roadmap-1'), isNotNull);
      });
    });

    group('getRoadmapsByStudent', () {
      test('returns roadmaps for student sorted by createdAt descending', () async {
        await repository.saveRoadmap(createTestRoadmap(
          id: 'r1', studentId: 's1',
          createdAt: DateTime(2026, 5, 10),
        ));
        await repository.saveRoadmap(createTestRoadmap(
          id: 'r2', studentId: 's1',
          createdAt: DateTime(2026, 5, 12),
        ));
        await repository.saveRoadmap(createTestRoadmap(
          id: 'r3', studentId: 's2',
        ));
        final result = await repository.getRoadmapsByStudent('s1');
        expect(result.length, 2);
        expect(result[0].id, 'r2');
        expect(result[1].id, 'r1');
      });

      test('returns empty for student with no roadmaps', () async {
        expect(await repository.getRoadmapsByStudent('none'), isEmpty);
      });
    });

    group('getAllRoadmaps', () {
      test('returns all roadmaps', () async {
        await repository.saveRoadmap(createTestRoadmap(id: 'r1'));
        await repository.saveRoadmap(createTestRoadmap(id: 'r2'));
        expect((await repository.getAllRoadmaps()).length, 2);
      });

      test('returns empty when no roadmaps', () async {
        expect(await repository.getAllRoadmaps(), isEmpty);
      });
    });

    group('deleteRoadmap', () {
      test('removes a roadmap', () async {
        await repository.saveRoadmap(createTestRoadmap());
        await repository.deleteRoadmap('roadmap-1');
        expect(await repository.loadRoadmap('roadmap-1'), isNull);
      });

      test('does nothing for non-existent', () async {
        await repository.deleteRoadmap('none');
      });
    });

    group('hasRoadmap', () {
      test('returns false when no roadmap exists', () async {
        expect(await repository.hasRoadmap('roadmap-1'), isFalse);
      });

      test('returns true when roadmap exists', () async {
        await repository.saveRoadmap(createTestRoadmap());
        expect(await repository.hasRoadmap('roadmap-1'), isTrue);
      });
    });
  });
}
