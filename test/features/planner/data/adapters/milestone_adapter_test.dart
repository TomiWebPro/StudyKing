import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/adapters/milestone_adapter.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('milestone_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(MilestoneModelAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('MilestoneModelAdapter', () {
    test('typeId is 25', () => expect(MilestoneModelAdapter().typeId, 25));

    test('hashCode and equality', () {
      expect(MilestoneModelAdapter().hashCode, MilestoneModelAdapter().hashCode);
      expect(MilestoneModelAdapter() == MilestoneModelAdapter(), isTrue);
      expect(MilestoneModelAdapter() == Object(), isFalse);
    });

    test('write then read round-trip', () async {
      final box = await Hive.openBox<MilestoneModel>('milestones_rt');
      final deadline = DateTime(2026, 9, 1);
      final milestone = MilestoneModel(
        id: 'm1',
        title: 'Master basics',
        description: 'Core concepts',
        deadline: deadline,
        topicsCovered: ['t1', 't2'],
        assessmentCriteria: ['quiz', 'project'],
        isCompleted: true,
        progress: 0.8,
        order: 3,
      );
      await box.put('m1', milestone);
      final restored = box.get('m1')!;
      expect(restored.id, 'm1');
      expect(restored.title, 'Master basics');
      expect(restored.description, 'Core concepts');
      expect(restored.deadline, deadline);
      expect(restored.topicsCovered, ['t1', 't2']);
      expect(restored.assessmentCriteria, ['quiz', 'project']);
      expect(restored.isCompleted, isTrue);
      expect(restored.progress, 0.8);
      expect(restored.order, 3);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<MilestoneModel>('milestones_def');
      final deadline = DateTime(2026, 9, 1);
      final milestone = MilestoneModel(id: 'm2', title: 'Intro', deadline: deadline);
      await box.put('m2', milestone);
      final restored = box.get('m2')!;
      expect(restored.title, 'Intro');
      expect(restored.description, '');
      expect(restored.isCompleted, isFalse);
      expect(restored.progress, 0.0);
      expect(restored.topicsCovered, isEmpty);
      await box.close();
    });
  });
}
