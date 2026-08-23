import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/adapters/task_adapter.dart';
import 'package:studyking/features/planner/data/models/task_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('task_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(TaskModelAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('TaskModelAdapter', () {
    test('typeId is 9', () => expect(TaskModelAdapter().typeId, 9));

    test('hashCode and equality', () {
      expect(TaskModelAdapter().hashCode, TaskModelAdapter().hashCode);
      expect(TaskModelAdapter() == TaskModelAdapter(), isTrue);
      expect(TaskModelAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<TaskModel>('tasks_rt');
      final due = DateTime(2026, 8, 1);
      final created = DateTime(2026, 7, 23);
      final updated = DateTime(2026, 7, 24);
      final task = TaskModel(
        id: 'tk1',
        title: 'Read chapter',
        description: 'Pages 1-10',
        status: 'in_progress',
        assignee: 'student1',
        priority: 'high',
        dueDate: due,
        createdAt: created,
        updatedAt: updated,
      );
      await box.put('tk1', task);
      final restored = box.get('tk1')!;
      expect(restored.id, 'tk1');
      expect(restored.title, 'Read chapter');
      expect(restored.status, 'in_progress');
      expect(restored.priority, 'high');
      expect(restored.dueDate, due);
      expect(restored.createdAt, created);
      expect(restored.updatedAt, updated);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<TaskModel>('tasks_def');
      final task = TaskModel(id: 'tk2', title: 'Do homework', description: 'math');
      await box.put('tk2', task);
      final restored = box.get('tk2')!;
      expect(restored.status, 'todo');
      expect(restored.priority, 'medium');
      expect(restored.dueDate, isNull);
      await box.close();
    });
  });
}
