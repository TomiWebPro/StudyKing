import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../theme/llm_task_status.dart';
export '../theme/llm_task_status.dart';

class LlmTask {
  final String id;
  final String feature;
  final String modelId;
  final LlmTaskStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int tokensUsed;
  final double estimatedCost;
  final String? error;
  final Completer<void>? cancelCompleter;

  LlmTask({
    required this.id,
    required this.feature,
    required this.modelId,
    this.status = LlmTaskStatus.queued,
    required this.startTime,
    this.endTime,
    this.tokensUsed = 0,
    this.estimatedCost = 0.0,
    this.error,
    this.cancelCompleter,
  });

  LlmTask copyWith({
    String? id,
    String? feature,
    String? modelId,
    LlmTaskStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? tokensUsed,
    double? estimatedCost,
    String? error,
  }) {
    return LlmTask(
      id: id ?? this.id,
      feature: feature ?? this.feature,
      modelId: modelId ?? this.modelId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      error: error ?? this.error,
      cancelCompleter: cancelCompleter,
    );
  }
}

class LlmTaskManager {
  final List<LlmTask> _tasks = [];
  int _counter = 0;

  List<LlmTask> get tasks => List.unmodifiable(_tasks);

  List<LlmTask> get activeTasks =>
      _tasks.where((t) => t.status == LlmTaskStatus.running || t.status == LlmTaskStatus.queued).toList();

  String createTask({
    required String feature,
    required String modelId,
  }) {
    final id = 'task_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
    _tasks.add(LlmTask(
      id: id,
      feature: feature,
      modelId: modelId,
      startTime: DateTime.now(),
    ));
    _notify();
    return id;
  }

  void startTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: LlmTaskStatus.running,
    );
    _notify();
  }

  void completeTask(String taskId, {int tokensUsed = 0, double estimatedCost = 0.0}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: LlmTaskStatus.done,
      endTime: DateTime.now(),
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
    );
    _notify();
  }

  void failTask(String taskId, String error) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: LlmTaskStatus.failed,
      endTime: DateTime.now(),
      error: error,
    );
    _notify();
  }

  void cancelTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];
    if (task.status == LlmTaskStatus.running || task.status == LlmTaskStatus.queued) {
      task.cancelCompleter?.complete();
      _tasks[idx] = task.copyWith(
        status: LlmTaskStatus.cancelled,
        endTime: DateTime.now(),
      );
      _notify();
    }
  }

  Completer<void>? registerCancelCompleter(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return null;
    final completer = Completer<void>();
    _tasks[idx] = LlmTask(
      id: _tasks[idx].id,
      feature: _tasks[idx].feature,
      modelId: _tasks[idx].modelId,
      status: _tasks[idx].status,
      startTime: _tasks[idx].startTime,
      cancelCompleter: completer,
    );
    return completer;
  }

  String retryTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return '';
    final oldTask = _tasks[idx];
    return createTask(feature: oldTask.feature, modelId: oldTask.modelId);
  }

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
