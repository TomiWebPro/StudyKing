import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_task_manager.dart';

void main() {
  group('LlmTask', () {
    test('creates task with default status queued', () {
      final task = LlmTask(
        id: 'task_1',
        feature: 'chat',
        modelId: 'gpt-4',
        startTime: DateTime(2024, 1, 1),
      );

      expect(task.status, LlmTaskStatus.queued);
      expect(task.tokensUsed, 0);
      expect(task.estimatedCost, 0.0);
      expect(task.error, isNull);
    });

    test('copyWith overrides specified fields', () {
      final task = LlmTask(
        id: 'task_1',
        feature: 'chat',
        modelId: 'gpt-4',
        startTime: DateTime(2024, 1, 1),
      );

      final updated = task.copyWith(
        status: LlmTaskStatus.running,
        tokensUsed: 100,
      );

      expect(updated.status, LlmTaskStatus.running);
      expect(updated.tokensUsed, 100);
      expect(updated.feature, 'chat');
      expect(updated.id, 'task_1');
    });
  });

  group('LlmTaskManager', () {
    late LlmTaskManager manager;

    setUp(() {
      manager = LlmTaskManager();
    });

    test('starts with empty task list', () {
      expect(manager.tasks, isEmpty);
      expect(manager.activeTasks, isEmpty);
    });

    test('creates a task and adds to list', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(taskId, startsWith('task_'));
      expect(manager.tasks.length, 1);
      expect(manager.tasks.first.status, LlmTaskStatus.queued);
    });

    test('startTask updates status to running', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(taskId);

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.running);
    });

    test('completeTask updates status to done with token info', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(taskId);
      manager.completeTask(taskId, tokensUsed: 500, estimatedCost: 0.01);

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.done);
      expect(task.tokensUsed, 500);
      expect(task.estimatedCost, 0.01);
      expect(task.endTime, isNotNull);
    });

    test('activeTasks returns only queued and running tasks', () {
      final task1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final task2 = manager.createTask(feature: 'embed', modelId: 'text-embedding');

      manager.startTask(task1);
      manager.completeTask(task1, tokensUsed: 100);

      expect(manager.activeTasks.length, 1);
      expect(manager.activeTasks.first.id, task2);
    });

    test('cancelTask updates status to cancelled', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.cancelTask(taskId);

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.cancelled);
      expect(task.endTime, isNotNull);
    });

    test('failTask updates status to failed with error', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(taskId, 'Connection timeout');

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.failed);
      expect(task.error, 'Connection timeout');
    });

    test('createTask returns unique ids', () {
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final id2 = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(id1, isNot(id2));
    });
  });
}
