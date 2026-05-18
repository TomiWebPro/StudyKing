import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:studyking/core/services/llm_task_manager.dart';

class LlmTaskService {
  final LlmTaskManager _manager;

  LlmTaskService({required LlmTaskManager manager}) : _manager = manager;

  List<LlmTask> getAllTasks() => _manager.tasks;

  List<LlmTask> getActiveTasks() => _manager.activeTasks;

  List<LlmTask> getTasksByFeature(String feature) {
    return _manager.tasks.where((t) => t.feature == feature).toList();
  }

  List<LlmTask> getTasksByStatus(LlmTaskStatus status) {
    return _manager.tasks.where((t) => t.status == status).toList();
  }

  List<LlmTask> getFilteredTasks({String? feature, LlmTaskStatus? status}) {
    var tasks = _manager.tasks;
    if (feature != null) {
      tasks = tasks.where((t) => t.feature == feature).toList();
    }
    if (status != null) {
      tasks = tasks.where((t) => t.status == status).toList();
    }
    return tasks;
  }

  int get totalTokenUsage =>
      _manager.tasks.fold(0, (sum, t) => sum + t.tokensUsed);

  double get totalEstimatedCost =>
      _manager.tasks.fold(0.0, (sum, t) => sum + t.estimatedCost);

  Map<String, int> get tokenUsageByFeature {
    final usage = <String, int>{};
    for (final task in _manager.tasks) {
      usage[task.feature] = (usage[task.feature] ?? 0) + task.tokensUsed;
    }
    return usage;
  }

  Map<String, double> get costByFeature {
    const cost = <String, double>{};
    for (final task in _manager.tasks) {
      cost[task.feature] = (cost[task.feature] ?? 0) + task.estimatedCost;
    }
    return cost;
  }

  String createTask({required String feature, required String modelId}) {
    return _manager.createTask(feature: feature, modelId: modelId);
  }

  void startTask(String taskId) => _manager.startTask(taskId);

  void completeTask(String taskId, {int tokensUsed = 0, double estimatedCost = 0.0}) {
    _manager.completeTask(taskId, tokensUsed: tokensUsed, estimatedCost: estimatedCost);
  }

  void failTask(String taskId, String error) => _manager.failTask(taskId, error);

  void cancelTask(String taskId) => _manager.cancelTask(taskId);

  String retryTask(String taskId) => _manager.retryTask(taskId);

  void addListener(VoidCallback listener) => _manager.addListener(listener);

  void removeListener(VoidCallback listener) => _manager.removeListener(listener);
}
