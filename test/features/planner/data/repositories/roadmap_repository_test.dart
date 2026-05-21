import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

class _FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _storage = {};

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveRoadmap(RoadmapModel roadmap) async {
    _storage[roadmap.id] = roadmap;
    return Result.success(null);
  }

  @override
  Future<Result<RoadmapModel?>> loadRoadmap(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<RoadmapModel>>> getRoadmapsByStudent(String studentId) async {
    return Result.success(
      _storage.values.where((r) => r.studentId == studentId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<Result<List<RoadmapModel>>> getAllRoadmaps() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> deleteRoadmap(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }

  @override
  Future<Result<bool>> hasRoadmap(String id) async {
    return Result.success(_storage.containsKey(id));
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
    late _FakeRoadmapRepository repository;

    setUp(() {
      repository = _FakeRoadmapRepository();
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
        expect(stored.data?.goal, 'Master Algebra');
      });

      test('overwrites existing roadmap with same id', () async {
        final r1 = createTestRoadmap(goal: 'Goal A');
        final r2 = createTestRoadmap(goal: 'Goal B');
        await repository.saveRoadmap(r1);
        await repository.saveRoadmap(r2);
        expect((await repository.loadRoadmap('roadmap-1')).data?.goal, 'Goal B');
      });
    });

    group('loadRoadmap', () {
      test('returns null for non-existent', () async {
        expect((await repository.loadRoadmap('none')).data, isNull);
      });

      test('returns stored roadmap', () async {
        await repository.saveRoadmap(createTestRoadmap());
        expect((await repository.loadRoadmap('roadmap-1')).data, isNotNull);
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
        expect(result.data!.length, 2);
        expect(result.data![0].id, 'r2');
        expect(result.data![1].id, 'r1');
      });

      test('returns empty for student with no roadmaps', () async {
        expect((await repository.getRoadmapsByStudent('none')).data, isEmpty);
      });
    });

    group('getAllRoadmaps', () {
      test('returns all roadmaps', () async {
        await repository.saveRoadmap(createTestRoadmap(id: 'r1'));
        await repository.saveRoadmap(createTestRoadmap(id: 'r2'));
        expect((await repository.getAllRoadmaps()).data!.length, 2);
      });

      test('returns empty when no roadmaps', () async {
        expect((await repository.getAllRoadmaps()).data, isEmpty);
      });
    });

    group('deleteRoadmap', () {
      test('removes a roadmap', () async {
        await repository.saveRoadmap(createTestRoadmap());
        await repository.deleteRoadmap('roadmap-1');
        expect((await repository.loadRoadmap('roadmap-1')).data, isNull);
      });

      test('does nothing for non-existent', () async {
        await repository.deleteRoadmap('none');
      });
    });

    group('hasRoadmap', () {
      test('returns false when no roadmap exists', () async {
        expect((await repository.hasRoadmap('roadmap-1')).data, isFalse);
      });

      test('returns true when roadmap exists', () async {
        await repository.saveRoadmap(createTestRoadmap());
        expect((await repository.hasRoadmap('roadmap-1')).data, isTrue);
      });
    });
  });

  group('error handling', () {
    test('getRoadmapsByStudent returns failure when box throws', () async {
      final repo = RoadmapRepository();
      repo.attachBox(_ThrowingRoadmapBox());
      final result = await repo.getRoadmapsByStudent('test');
      expect(result.isFailure, isTrue);
    });

    test('hasRoadmap returns failure when box throws', () async {
      final repo = RoadmapRepository();
      repo.attachBox(_ThrowingRoadmapBox());
      final result = await repo.hasRoadmap('any');
      expect(result.isFailure, isTrue);
    });

    test('saveRoadmap returns failure when box throws', () async {
      final repo = RoadmapRepository();
      repo.attachBox(_ThrowingRoadmapBox());
      final roadmap = createTestRoadmap();
      final result = await repo.saveRoadmap(roadmap);
      expect(result.isFailure, isTrue);
    });
  });

  group('RoadmapRepository (init with real Hive)', () {
    late RoadmapRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestMilestoneAdapter());
      Hive.registerAdapter(_TestRoadmapAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('roadmap_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = RoadmapRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('roadmaps');
    });

    test('init opens box and supports CRUD', () async {
      final roadmap = createTestRoadmap(id: 'hive-1', goal: 'Hive Test');
      await repository.saveRoadmap(roadmap);
      final stored = await repository.loadRoadmap('hive-1');
      expect(stored.data, isNotNull);
      expect(stored.data!.goal, 'Hive Test');
    });

    test('getRoadmapsByStudent works after init', () async {
      await repository.saveRoadmap(createTestRoadmap(id: 'r1', studentId: 's1'));
      await repository.saveRoadmap(createTestRoadmap(id: 'r2', studentId: 's1'));
      await repository.saveRoadmap(createTestRoadmap(id: 'r3', studentId: 's2'));
      expect((await repository.getRoadmapsByStudent('s1')).data, hasLength(2));
    });

    test('deleteRoadmap works after init', () async {
      await repository.saveRoadmap(createTestRoadmap(id: 'd1'));
      await repository.deleteRoadmap('d1');
      expect((await repository.loadRoadmap('d1')).data, isNull);
    });
  });
}

class _ThrowingRoadmapBox implements Box<RoadmapModel> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw Exception('Simulated Hive error');
  }
}

class _TestMilestoneAdapter extends TypeAdapter<MilestoneModel> {
  @override
  final int typeId = 25;

  @override
  MilestoneModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilestoneModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      deadline: fields[3] as DateTime,
      topicsCovered: (fields[4] as List?)?.cast<String>() ?? [],
      assessmentCriteria: (fields[5] as List?)?.cast<String>() ?? [],
      isCompleted: fields[6] as bool? ?? false,
      progress: (fields[7] as num?)?.toDouble() ?? 0.0,
      order: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, MilestoneModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.topicsCovered)
      ..writeByte(5)
      ..write(obj.assessmentCriteria)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.order);
  }
}

class _TestRoadmapAdapter extends TypeAdapter<RoadmapModel> {
  @override
  final int typeId = 29;

  @override
  RoadmapModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoadmapModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      goal: fields[2] as String,
      createdAt: fields[3] as DateTime,
      targetCompletionDate: fields[4] as DateTime?,
      milestones: (fields[5] as List?)?.cast<MilestoneModel>() ?? [],
      completionPercentage: (fields[6] as num?)?.toDouble() ?? 0.0,
      status: fields[7] as String? ?? 'active',
      subjectId: fields[8] as String?,
      plannedVsActual: fields[9] != null ? Map<String, double>.from(fields[9] as Map) : null,
    );
  }

  @override
  void write(BinaryWriter writer, RoadmapModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.goal)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.targetCompletionDate)
      ..writeByte(5)
      ..write(obj.milestones)
      ..writeByte(6)
      ..write(obj.completionPercentage)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.subjectId)
      ..writeByte(9)
      ..write(obj.plannedVsActual);
  }
}
