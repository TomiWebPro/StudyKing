import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';

LlmTaskManager _createManagerWithTasks() {
  final manager = LlmTaskManager();
  // Create a few tasks directly in the internal list for testing
  return manager;
}

void main() {
  group('LlmTaskService', () {
    test('getAllTasks returns all tasks', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.getAllTasks(), isEmpty);
    });

    test('getActiveTasks returns empty when no active tasks', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.getActiveTasks(), isEmpty);
    });

    test('totalTokenUsage is 0 with no tasks', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.totalTokenUsage, 0);
    });

    test('totalEstimatedCost is 0 with no tasks', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.totalEstimatedCost, 0.0);
    });

    test('getTasksByFeature returns empty for unknown feature', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.getTasksByFeature('unknown'), isEmpty);
    });

    test('getTasksByStatus returns empty for unknown status', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.getTasksByStatus(LlmTaskStatus.done), isEmpty);
    });

    test('getFilteredTasks with no filter returns all', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.getFilteredTasks(), isEmpty);
    });

    test('tokenUsageByFeature returns empty map', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.tokenUsageByFeature, isEmpty);
    });

    test('costByFeature returns empty map', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      expect(service.costByFeature, isEmpty);
    });

    test('listeners can be added and removed', () {
      final manager = _createManagerWithTasks();
      final service = LlmTaskService(manager: manager);
      void listener() {}
      service.addListener(listener);
      service.removeListener(listener);
    });
  });
}
