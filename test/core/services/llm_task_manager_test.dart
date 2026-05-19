import 'dart:async';

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

    test('toJson/fromJson round-trip preserves all fields', () {
      final original = LlmTask(
        id: 'rt-1',
        feature: 'chat',
        modelId: 'gpt-4',
        status: LlmTaskStatus.running,
        startTime: DateTime(2026, 5, 19, 10, 0, 0),
        endTime: DateTime(2026, 5, 19, 10, 0, 30),
        tokensUsed: 500,
        estimatedCost: 0.01,
        error: null,
      );
      final json = original.toJson();
      final restored = LlmTask.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.feature, original.feature);
      expect(restored.modelId, original.modelId);
      expect(restored.status, original.status);
      expect(restored.startTime, original.startTime);
      expect(restored.endTime, original.endTime);
      expect(restored.tokensUsed, original.tokensUsed);
      expect(restored.estimatedCost, original.estimatedCost);
      expect(restored.error, original.error);
    });

    test('toJson/fromJson round-trip with null endTime and error', () {
      final original = LlmTask(
        id: 'rt-2',
        feature: 'ingestion',
        modelId: 'claude-3',
        status: LlmTaskStatus.failed,
        startTime: DateTime(2026, 1, 1),
        tokensUsed: 0,
        estimatedCost: 0.0,
        error: 'Connection timeout',
      );
      final json = original.toJson();
      final restored = LlmTask.fromJson(json);
      expect(restored.endTime, isNull);
      expect(restored.error, 'Connection timeout');
      expect(restored.status, LlmTaskStatus.failed);
    });

    test('toJson/fromJson round-trip for cancelled status', () {
      final original = LlmTask(
        id: 'rt-3',
        feature: 'tutor',
        modelId: 'gpt-4',
        status: LlmTaskStatus.cancelled,
        startTime: DateTime(2026, 3, 15),
        endTime: DateTime(2026, 3, 15, 0, 0, 5),
      );
      final json = original.toJson();
      final restored = LlmTask.fromJson(json);
      expect(restored.status, LlmTaskStatus.cancelled);
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

    test('startTask does nothing for non-existent task', () {
      manager.startTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('completeTask does nothing for non-existent task', () {
      manager.completeTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('failTask does nothing for non-existent task', () {
      manager.failTask('nonexistent', 'error');
      expect(manager.tasks, isEmpty);
    });

    test('cancelTask does nothing for non-existent task', () {
      manager.cancelTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('cancelTask on a done task does not change status', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(taskId);
      manager.cancelTask(taskId);

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.done);
    });

    test('registerCancelCompleter returns a completer for existing task', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final completer = manager.registerCancelCompleter(taskId);
      expect(completer, isNotNull);
      expect(completer, isA<Completer<void>>());
    });

    test('registerCancelCompleter returns null for non-existent task', () {
      final completer = manager.registerCancelCompleter('nonexistent');
      expect(completer, isNull);
    });

    test('cancelTask triggers the registered cancelCompleter', () async {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(taskId);
      final completer = manager.registerCancelCompleter(taskId);

      manager.cancelTask(taskId);

      expect(completer!.isCompleted, isTrue);
      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.cancelled);
    });

    test('addListener is notified when task is created', () {
      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(notificationCount, greaterThan(0));
    });

    test('addListener is notified on startTask', () {
      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final initialCount = notificationCount;
      manager.startTask(taskId);

      expect(notificationCount, greaterThan(initialCount));
    });

    test('addListener is notified on completeTask', () {
      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final initialCount = notificationCount;
      manager.completeTask(taskId);

      expect(notificationCount, greaterThan(initialCount));
    });

    test('addListener is notified on failTask', () {
      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final initialCount = notificationCount;
      manager.failTask(taskId, 'error');

      expect(notificationCount, greaterThan(initialCount));
    });

    test('addListener is notified on cancelTask', () {
      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final initialCount = notificationCount;
      manager.cancelTask(taskId);

      expect(notificationCount, greaterThan(initialCount));
    });

    test('removeListener stops notifications', () {
      int notificationCount = 0;
      void listener() {
        notificationCount++;
      }
      manager.addListener(listener);
      manager.removeListener(listener);

      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(notificationCount, equals(0));
    });

    test('activeTasks returns empty when all tasks are done', () {
      final taskId = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(taskId);
      expect(manager.activeTasks, isEmpty);
    });
  });
}
