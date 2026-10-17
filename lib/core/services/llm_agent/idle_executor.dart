import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/core/utils/logger.dart';

class IdleTask {
  final String id;
  final String description;
  final DateTime createdAt;
  final Future<void> Function()? taskFn;
  final bool requiresHeavy;
  final String? taskType;
  final String? feature;

  /// Subject this prep task belongs to, for per-subject opt-in enforcement
  /// (Vision Next-Term §4.2 "per-syllabus opt-in"). When non-null and the
  /// subject has been disabled by the student, the [IdleExecutor] defers the
  /// task so no tokens are spent on a syllabus the student paused.
  final String? subjectId;

  bool isRunning;
  bool isCompleted;
  String? error;

  IdleTask({
    required this.id,
    required this.description,
    required this.createdAt,
    this.taskFn,
    this.requiresHeavy = false,
    this.taskType,
    this.feature,
    this.subjectId,
    this.isRunning = false,
    this.isCompleted = false,
    this.error,
  });
}

class IdleExecutor {
  static final Logger _logger = const Logger('IdleExecutor');
  final LlmTaskManager? _llmTaskManager;
  final SystemMonitorService? _systemMonitor;

  /// Optional callback consulted before running a task. When it returns true
  /// the task is left in the queue and retried on the next poll, implementing
  /// vision §4.2 quiet-hours: heavy prep defers so the student is not
  /// disturbed at night. Inject in tests with a stubbed [DateTime] for a
  /// deterministic fake-clock (e.g. 2am within a 22–8 window).
  final bool Function(DateTime now)? _shouldDeferForQuietHours;

  /// Optional callback consulted before running a task that carries a
  /// [IdleTask.subjectId]. When it returns false the task is left in the queue
  /// (deferred) and no tokens are spent, realising vision §4.2 "per-syllabus
  /// opt-in": a student who toggles a subject off gets no prep for that
  /// syllabus while away. Inject in tests with a predicate mirroring a
  /// `PrepBudget` whose `disabledSubjects` contains the subject.
  final bool Function(String subjectId)? _isPrepEnabledForSubject;

  final List<IdleTask> _queue = [];
  Timer? _idleCheckTimer;
  bool _isExecuting = false;

  IdleExecutor({
    LlmTaskManager? llmTaskManager,
    String studentId = 'default',
    SystemMonitorService? systemMonitor,
    bool Function(DateTime now)? shouldDeferForQuietHours,
    bool Function(String subjectId)? isPrepEnabledForSubject,
  })  : _llmTaskManager = llmTaskManager,
        _systemMonitor = systemMonitor,
        _shouldDeferForQuietHours = shouldDeferForQuietHours,
        _isPrepEnabledForSubject = isPrepEnabledForSubject;

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

  Future<void> enqueue(
    String description,
    Future<void> Function() task, {
    bool requiresHeavy = false,
  }) async {
    final id = 'idle_${DateTime.now().millisecondsSinceEpoch}';
    _queue.add(IdleTask(
      id: id,
      description: description,
      createdAt: DateTime.now(),
      taskFn: task,
      requiresHeavy: requiresHeavy,
    ));
    if (_queue.length > 50) {
      _queue.removeAt(0);
    }
    _tryExecuteNext();
  }

   Future<void> enqueuePrepTool(
    String description,
    Future<Map<String, dynamic>> Function() task, {
    required bool requiresHeavy,
    required String feature,
    required String taskType,
    String? subjectId,
  }) async {
    final id = 'idle_${DateTime.now().millisecondsSinceEpoch}';
    _queue.add(IdleTask(
      id: id,
      description: description,
      createdAt: DateTime.now(),
      taskFn: () async {
        final result = await task();
        final success = result['success'] as bool? ?? false;
        if (!success) {
          throw Exception(result['error'] ?? 'Prep tool returned failure');
        }
      },
      requiresHeavy: requiresHeavy,
      feature: feature,
      taskType: taskType,
      subjectId: subjectId,
    ));
    if (_queue.length > 50) {
      _queue.removeAt(0);
    }
    _tryExecuteNext();
  }

  /// Visible so tests can advance deferred tasks without waiting on the
  /// 30s polling timer.
  @visibleForTesting
  Future<void> processNext() => _tryExecuteNext();

  Future<void> _tryExecuteNext() async {
    if (_isExecuting) return;
    final next = _queue.where((t) => !t.isCompleted && !t.isRunning).firstOrNull;
    if (next == null) return;

    // Vision Next-Term §4.2 quiet-hours: defer ALL off-period prep tasks when
    // the student has configured a quiet-hours window and the current time is
    // within it. This prevents notifications, network traffic, and CPU use
    // during sleep hours — not just heavy tasks (a light task at 2am is still
    // disruptive). The check is delegated to the injected callback so tests
    // can supply a fake clock deterministically.
    if (_shouldDeferForQuietHours != null &&
        _shouldDeferForQuietHours(DateTime.now())) {
      _logger.d(
        'Deferring task "${next.description}" — within quiet hours',
      );
      return;
    }

    // Vision Next-Term §4.3: heavy off-period prep must defer when the device
    // is stressed (CPU > 80%, battery < 20%, battery-saver on). The task is
    // left in the queue and retried on the next poll / enqueue.
    if (next.requiresHeavy && _systemMonitor != null && !_systemMonitor.canRunHeavyPrepNow) {
      _logger.w(
        'Deferring heavy prep task "${next.description}" — system under load',
      );
      return;
    }

    // Vision Next-Term §4.2: per-subject opt-in. A student may disable prep for
    // a specific syllabus in Settings; such tasks are deferred (never executed,
    // no tokens spent) and logged so they surface as "subject disabled by
    // student" instead of silently burning budget. The check happens before the
    // task is registered on [LlmTaskManager], so a disabled-subject task never
    // appears as a running/failed prep job. Mirrors the quiet-hours predicate
    // pattern: inject `isPrepEnabledForSubject` in tests with a stub.
    final subjectId = next.subjectId;
    if (subjectId != null &&
        _isPrepEnabledForSubject != null &&
        !_isPrepEnabledForSubject(subjectId)) {
      _logger.d(
        'Deferring task "${next.description}" — subject "$subjectId" prep disabled by student',
      );
      return;
    }

    _isExecuting = true;
    next.isRunning = true;

    final manager = _llmTaskManager;
    final taskId = manager?.createTask(
          feature: next.feature ?? 'idle_executor',
          modelId: 'background',
          taskType: next.taskType ?? LlmTaskType.background.name,
        ) ??
        '';
    if (taskId.isNotEmpty) manager?.startTask(taskId);

    // Snapshot task IDs that already existed so we can aggregate token counts
    // from per-call LLM tasks created during execution onto the parent idle
    // task (mirrors agent_loop.dart:57-59 and agent_loop.dart:150-167).
    final preRunTaskIds = manager != null
        ? Set<String>.from(manager.tasks.map((t) => t.id))
        : const <String>{};

    try {
      await _executeTask(next);
      next.isCompleted = true;
      // Aggregate tokens from per-call LLM tasks created during execution that
      // were not in the pre-snapshot, so the task-manager portal surfaces real
      // per-task token spend instead of 0 (vision §4.2 token transparency).
      var totalTokens = 0;
      var totalCost = 0.0;
      if (manager != null) {
        for (final t in manager.tasks) {
          if (preRunTaskIds.contains(t.id) || t.id == taskId) continue;
          totalTokens += t.tokensUsed;
          totalCost += t.estimatedCost;
        }
      }
      if (taskId.isNotEmpty) {
        manager?.completeTask(
          taskId,
          tokensUsed: totalTokens,
          estimatedCost: totalCost,
        );
      }
    } catch (e) {
      next.error = e.toString();
      if (taskId.isNotEmpty) manager?.failTask(taskId, e.toString());
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
