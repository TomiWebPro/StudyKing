import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/services/llm_task_manager.dart';

class IdleTask {
  final String id;
  final String description;
  final DateTime createdAt;
  final Future<void> Function()? taskFn;
  bool isRunning;
  bool isCompleted;
  String? error;

  IdleTask({
    required this.id,
    required this.description,
    required this.createdAt,
    this.taskFn,
    this.isRunning = false,
    this.isCompleted = false,
    this.error,
  });
}

class IdleExecutor {
  static final Logger _logger = const Logger('IdleExecutor');
  final LlmTaskManager? _llmTaskManager;
  final List<IdleTask> _queue = [];
  Timer? _idleCheckTimer;
  bool _isExecuting = false;

  IdleExecutor({
    LlmTaskManager? llmTaskManager,
    String studentId = 'default',
  }) : _llmTaskManager = llmTaskManager;

  List<IdleTask> get queue => List.unmodifiable(_queue);
  bool get hasPendingTasks => _queue.any((t) => !t.isCompleted && !t.isRunning);

  Future<void> startIdleMonitoring({Duration interval = const Duration(seconds: 30)}) async {
    _idleCheckTimer?.cancel();
    _idleCheckTimer = Timer.periodic(interval, (_) => _tryExecuteNext());
  }

  void stopIdleMonitoring() {
    _idleCheckTimer?.cancel();
    _idleCheckTimer = null;
  }

  Future<void> enqueue(String description, Future<void> Function() task) async {
    final id = 'idle_${DateTime.now().millisecondsSinceEpoch}';
    _queue.add(IdleTask(id: id, description: description, createdAt: DateTime.now(), taskFn: task));
    if (_queue.length > 50) {
      _queue.removeAt(0);
    }
    _tryExecuteNext();
  }

  Future<void> _tryExecuteNext() async {
    if (_isExecuting) return;
    final next = _queue.where((t) => !t.isCompleted && !t.isRunning).firstOrNull;
    if (next == null) return;

    _isExecuting = true;
    next.isRunning = true;

    final taskId = _llmTaskManager?.createTask(
      feature: 'idle_executor',
      modelId: 'background',
    );
    if (taskId != null) _llmTaskManager?.startTask(taskId);

    try {
      await _executeTask(next);
      next.isCompleted = true;
      if (taskId != null) _llmTaskManager?.completeTask(taskId);
    } catch (e) {
      next.error = e.toString();
      if (taskId != null) _llmTaskManager?.failTask(taskId, e.toString());
      _logger.w('Idle task failed: ${next.description}', e);
    } finally {
      next.isRunning = false;
      _isExecuting = false;
      _notify();
    }
  }

  Future<void> _executeTask(IdleTask task) async {
    _logger.d('Executing idle task: ${task.description}');
    if (task.taskFn != null) {
      await task.taskFn!();
    }
  }

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    stopIdleMonitoring();
    _listeners.clear();
  }
}
