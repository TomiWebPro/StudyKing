import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';

void main() {
  group('LlmTaskService', () {
    test('getAllTasks returns all tasks', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.getAllTasks(), isEmpty);
    });

    test('getActiveTasks returns empty when no active tasks', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.getActiveTasks(), isEmpty);
    });

    test('totalTokenUsage is 0 with no tasks', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.totalTokenUsage, 0);
    });

    test('totalEstimatedCost is 0 with no tasks', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.totalEstimatedCost, 0.0);
    });

    test('getTasksByFeature returns empty for unknown feature', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.getTasksByFeature('unknown'), isEmpty);
    });

    test('getTasksByStatus returns empty for unknown status', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.getTasksByStatus(LlmTaskStatus.done), isEmpty);
    });

    test('getFilteredTasks with no filter returns all', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.getFilteredTasks(), isEmpty);
    });

    test('tokenUsageByFeature returns empty map', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.tokenUsageByFeature, isEmpty);
    });

    test('costByFeature returns empty map', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      expect(service.costByFeature, isEmpty);
    });

    test('listeners can be added and removed', () {
      final manager = LlmTaskManager();
      final service = LlmTaskService(manager: manager);
      void listener() {}
      service.addListener(listener);
      service.removeListener(listener);
    });

    group('task lifecycle', () {
      test('creates a task and returns its id', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'chat', modelId: 'gpt-4');
        expect(taskId, isNotEmpty);
        expect(service.getAllTasks(), hasLength(1));
        expect(service.getTasksByFeature('chat'), hasLength(1));
      });

      test('starts a created task', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'chat', modelId: 'gpt-4');

        service.startTask(taskId);
        final active = service.getActiveTasks();
        expect(active, hasLength(1));
        expect(active.first.status, LlmTaskStatus.running);
      });

      test('completes a started task with token usage', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'chat', modelId: 'gpt-4');
        service.startTask(taskId);
        service.completeTask(taskId, tokensUsed: 100, estimatedCost: 0.002);

        final tasks = service.getAllTasks();
        expect(tasks.first.status, LlmTaskStatus.done);
        expect(tasks.first.tokensUsed, 100);
        expect(tasks.first.estimatedCost, 0.002);
        expect(tasks.first.endTime, isNotNull);
      });

      test('fails a running task with error message', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'practice', modelId: 'gpt-4');
        service.startTask(taskId);
        service.failTask(taskId, 'API timeout');

        final tasks = service.getAllTasks();
        expect(tasks.first.status, LlmTaskStatus.failed);
        expect(tasks.first.error, 'API timeout');
        expect(tasks.first.endTime, isNotNull);
      });

      test('cancels a queued task', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'teaching', modelId: 'gpt-4');
        service.cancelTask(taskId);

        final all = service.getAllTasks();
        expect(all.first.status, LlmTaskStatus.cancelled);
        expect(service.getActiveTasks(), isEmpty);
      });

      test('retryTask creates a new task from a failed one', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'chat', modelId: 'gpt-4');
        service.failTask(taskId, 'error');

        final retryId = service.retryTask(taskId);
        expect(retryId, isNotEmpty);
        expect(retryId, isNot(taskId));

        final all = service.getAllTasks();
        expect(all, hasLength(2));
        expect(all.where((t) => t.status == LlmTaskStatus.failed), hasLength(1));
        expect(all.where((t) => t.status == LlmTaskStatus.queued), hasLength(1));
      });

      test('does not start a non-existent task', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        service.startTask('nonexistent');
        expect(service.getAllTasks(), isEmpty);
      });

      test('does not cancel a done task', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        final taskId = service.createTask(feature: 'chat', modelId: 'gpt-4');
        service.startTask(taskId);
        service.completeTask(taskId);
        service.cancelTask(taskId);

        final tasks = service.getAllTasks();
        expect(tasks.first.status, LlmTaskStatus.done);
      });
    });

    group('aggregation queries', () {
      test('totalTokenUsage sums across all tasks', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);
        service.completeTask(t1, tokensUsed: 100, estimatedCost: 0.002);

        final t2 = service.createTask(feature: 'teaching', modelId: 'm2');
        service.startTask(t2);
        service.completeTask(t2, tokensUsed: 200, estimatedCost: 0.004);

        expect(service.totalTokenUsage, 300);
        expect(service.totalEstimatedCost, closeTo(0.006, 0.0001));
      });

      test('tokenUsageByFeature groups correctly', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);
        service.completeTask(t1, tokensUsed: 100);

        final t2 = service.createTask(feature: 'chat', modelId: 'm2');
        service.startTask(t2);
        service.completeTask(t2, tokensUsed: 200);

        final t3 = service.createTask(feature: 'teaching', modelId: 'm3');
        service.startTask(t3);
        service.completeTask(t3, tokensUsed: 500);

        expect(service.tokenUsageByFeature['chat'], 300);
        expect(service.tokenUsageByFeature['teaching'], 500);
      });

      test('costByFeature groups correctly', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);
        service.completeTask(t1, estimatedCost: 0.002);

        final t2 = service.createTask(feature: 'practice', modelId: 'm2');
        service.startTask(t2);
        service.completeTask(t2, estimatedCost: 0.005);

        expect(service.costByFeature['chat'], closeTo(0.002, 0.0001));
        expect(service.costByFeature['practice'], closeTo(0.005, 0.0001));
      });
    });

    group('filtered queries', () {
      test('getTasksByFeature filters correctly', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        service.createTask(feature: 'chat', modelId: 'm1');
        service.createTask(feature: 'teaching', modelId: 'm2');
        service.createTask(feature: 'chat', modelId: 'm3');

        expect(service.getTasksByFeature('chat'), hasLength(2));
        expect(service.getTasksByFeature('teaching'), hasLength(1));
        expect(service.getTasksByFeature('unknown'), isEmpty);
      });

      test('getTasksByStatus filters correctly', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);
        service.completeTask(t1);

        final t2 = service.createTask(feature: 'chat', modelId: 'm2');
        service.startTask(t2);

        expect(service.getTasksByStatus(LlmTaskStatus.done), hasLength(1));
        expect(service.getTasksByStatus(LlmTaskStatus.running), hasLength(1));
        expect(service.getTasksByStatus(LlmTaskStatus.queued), hasLength(1));
      });

      test('getFilteredTasks combines feature and status filters', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);
        service.completeTask(t1);

        service.createTask(feature: 'chat', modelId: 'm2');

        final t3 = service.createTask(feature: 'teaching', modelId: 'm3');
        service.startTask(t3);
        service.completeTask(t3);

        final chatQueued = service.getFilteredTasks(
          feature: 'chat',
          status: LlmTaskStatus.queued,
        );
        expect(chatQueued, hasLength(1));

        final chatDone = service.getFilteredTasks(
          feature: 'chat',
          status: LlmTaskStatus.done,
        );
        expect(chatDone, hasLength(1));

        final teachingDone = service.getFilteredTasks(
          feature: 'teaching',
          status: LlmTaskStatus.done,
        );
        expect(teachingDone, hasLength(1));

        final allChat = service.getFilteredTasks(feature: 'chat');
        expect(allChat, hasLength(2));
      });
    });

    group('listener notification', () {
      test('listener is called when task is created', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        int callCount = 0;
        void listener() => callCount++;

        service.addListener(listener);
        service.createTask(feature: 'chat', modelId: 'm1');
        expect(callCount, 1);
        service.removeListener(listener);
      });

      test('listener is called on task state change', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        int callCount = 0;
        void listener() => callCount++;

        final taskId = service.createTask(feature: 'chat', modelId: 'm1');
        service.addListener(listener);
        service.startTask(taskId);
        expect(callCount, 1);

        service.completeTask(taskId);
        expect(callCount, 2);

        service.removeListener(listener);
      });

      test('removed listener is no longer called', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        int callCount = 0;
        void listener() => callCount++;

        service.addListener(listener);
        service.removeListener(listener);
        service.createTask(feature: 'chat', modelId: 'm1');
        expect(callCount, 0);
      });
    });

    group('active tasks', () {
      test('getActiveTasks returns running and queued tasks', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);

        service.createTask(feature: 'teaching', modelId: 'm2');

        final t3 = service.createTask(feature: 'practice', modelId: 'm3');
        service.startTask(t3);
        service.completeTask(t3);

        final active = service.getActiveTasks();
        expect(active, hasLength(2));
        expect(active.where((t) => t.status == LlmTaskStatus.running), hasLength(1));
        expect(active.where((t) => t.status == LlmTaskStatus.queued), hasLength(1));
      });

      test('no active tasks when all are done or failed', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        final t1 = service.createTask(feature: 'chat', modelId: 'm1');
        service.startTask(t1);
        service.completeTask(t1);

        final t2 = service.createTask(feature: 'chat', modelId: 'm2');
        service.startTask(t2);
        service.failTask(t2, 'error');

        expect(service.getActiveTasks(), isEmpty);
      });
    });

    group('edge cases', () {
      test('retry on non-existent task returns empty string', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        expect(service.retryTask('nonexistent'), '');
      });

      test('completeTask on non-existent task does nothing', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        service.completeTask('nonexistent', tokensUsed: 100);
        expect(service.getAllTasks(), isEmpty);
      });

      test('failTask on non-existent task does nothing', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        service.failTask('nonexistent', 'error');
        expect(service.getAllTasks(), isEmpty);
      });

      test('cancelTask on non-existent task does nothing', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);
        service.cancelTask('nonexistent');
        expect(service.getAllTasks(), isEmpty);
      });

      test('handles many tasks without performance issues', () {
        final manager = LlmTaskManager();
        final service = LlmTaskService(manager: manager);

        for (var i = 0; i < 50; i++) {
          final id = service.createTask(feature: 'f$i', modelId: 'm');
          service.startTask(id);
          service.completeTask(id, tokensUsed: i * 10);
        }

        expect(service.getAllTasks(), hasLength(50));
        expect(service.totalTokenUsage, 12250);
      });
    });
  });
}
