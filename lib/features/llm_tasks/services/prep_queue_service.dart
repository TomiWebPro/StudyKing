import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:studyking/core/services/llm_agent/idle_executor.dart';

/// Read/write bridge between the off-period prep queue ([IdleExecutor]) and the
/// LLM task-manager portal.
///
/// Vision Next-Term §4.2: "All prep jobs are visible tasks
/// (queued → running → done/failed, retry/cancel) — the existing task-manager
/// portal is the UI." Before this bridge, [IdleExecutor] only created an
/// `LlmTask` once a job actually started, so a job deferred by quiet hours,
/// device pressure, a paused syllabus, or an exhausted prep budget was
/// invisible: the portal looked idle while work was merely paused.
///
/// The service aggregates the waiting tasks of every supplied executor (the
/// app shares one queue, but tests and future owners may hold several), and
/// exposes cancel / try-now actions that act on the queue itself rather than on
/// [LlmTask]s, because deferred work has no [LlmTask] yet.
class PrepQueueService extends ChangeNotifier {
  PrepQueueService({required List<IdleExecutor> executors})
      : _executors = List.unmodifiable(executors) {
    for (final executor in _executors) {
      executor.addListener(_onQueueChanged);
    }
  }

  final List<IdleExecutor> _executors;

  void _onQueueChanged() => notifyListeners();

  /// Waiting tasks across all executors, oldest first, deduplicated by object
  /// identity so a queue shared by several owners is never rendered twice.
  /// (Ids are only unique per executor, so two distinct queues can legitimately
  /// mint the same id - identity is the safe dedupe key.)
  ///
  /// Each task carries a non-null [IdleTask.deferredReason] once a gate has
  /// paused it; `null` means the task is queued and about to run.
  List<IdleTask> get queuedTasks {
    final seen = Set<IdleTask>.identity();
    final tasks = <IdleTask>[];
    for (final executor in _executors) {
      for (final task in executor.queuedTasks) {
        if (seen.add(task)) tasks.add(task);
      }
    }
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(tasks);
  }

  /// Removes a waiting prep job from its queue (student pressed cancel).
  /// Returns false when no executor owns an id that is still waiting - e.g. the
  /// job already started running and can no longer be cancelled here.
  bool cancel(String taskId) {
    for (final executor in _executors) {
      if (executor.cancelQueuedTask(taskId)) return true;
    }
    return false;
  }

  /// Tries to start waiting prep now instead of waiting for quiet hours to end
  /// or the polling timer to fire (student pressed "try now"). Gates still
  /// apply: under CPU pressure or an exhausted budget the job stays queued.
  Future<void> retryNow() async {
    for (final executor in _executors) {
      await executor.retryDeferredNow();
    }
  }

  @override
  void dispose() {
    for (final executor in _executors) {
      executor.removeListener(_onQueueChanged);
    }
    super.dispose();
  }
}
