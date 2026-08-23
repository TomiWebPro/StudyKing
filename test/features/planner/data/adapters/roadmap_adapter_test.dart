import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/adapters/milestone_adapter.dart';
import 'package:studyking/features/planner/data/adapters/roadmap_adapter.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('roadmap_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(RoadmapModelAdapter());
    Hive.registerAdapter(MilestoneModelAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('RoadmapModelAdapter', () {
    test('typeId is 29', () => expect(RoadmapModelAdapter().typeId, 29));

    test('hashCode and equality', () {
      expect(RoadmapModelAdapter().hashCode, RoadmapModelAdapter().hashCode);
      expect(RoadmapModelAdapter() == RoadmapModelAdapter(), isTrue);
      expect(RoadmapModelAdapter() == Object(), isFalse);
    });

    test('write/read round-trip with milestones', () async {
      final box = await Hive.openBox<RoadmapModel>('roadmaps_rt');
      final created = DateTime(2026, 7, 23);
      final target = DateTime(2026, 12, 31);
      final deadline = DateTime(2026, 9, 1);
      final roadmap = RoadmapModel(
        id: 'rm1',
        studentId: 'stu1',
        goal: 'Learn chemistry',
        createdAt: created,
        targetCompletionDate: target,
        milestones: [
          MilestoneModel(id: 'm1', title: 'Basics', deadline: deadline),
        ],
        completionPercentage: 25.0,
        status: 'active',
        subjectId: 'sub1',
        plannedVsActual: {'week1': 5.0, 'week2': 3.5},
      );
      await box.put('rm1', roadmap);
      final restored = box.get('rm1')!;
      expect(restored.id, 'rm1');
      expect(restored.goal, 'Learn chemistry');
      expect(restored.completionPercentage, 25.0);
      expect(restored.status, 'active');
      expect(restored.milestones.length, 1);
      expect(restored.milestones.first.title, 'Basics');
      expect(restored.plannedVsActual!['week1'], 5.0);
      expect(restored.plannedVsActual!['week2'], 3.5);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<RoadmapModel>('roadmaps_def');
      final created = DateTime(2026, 7, 23);
      final roadmap = RoadmapModel(
        id: 'rm2',
        studentId: 'stu1',
        goal: 'Learn physics',
        createdAt: created,
      );
      await box.put('rm2', roadmap);
      final restored = box.get('rm2')!;
      expect(restored.goal, 'Learn physics');
      expect(restored.completionPercentage, 0.0);
      expect(restored.status, 'active');
      expect(restored.milestones, isEmpty);
      expect(restored.plannedVsActual, isNull);
      await box.close();
    });
  });
}
