import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart' show LlmUsageMeter;
import 'package:studyking/core/services/prep_budget.dart' show PrepBudgetService, PrepCategory;
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/core/utils/logger.dart';

/// Rebuilds the executable closure for an [IdleTask] that was restored from
/// persistence without one.
///
/// Closures cannot be serialized to Hive (Vision Next-Term §4.1: "the task
/// closure must be reconstructed from taskType/feature, not serialized
/// directly"). Services that own a class of prep task register a
/// [TaskReconstructor] with the [IdleExecutor]; at execution time the executor
/// consults it to (re)attach a fresh closure for any restored task that carries
/// a `feature`/`jobId` it recognises. Returns `null` when the task cannot be
/// resumed in this process (e.g. it belonged to a service that has no
/// registered reconstructor).
typedef TaskReconstructor = Future<void> Function()? Function(IdleTask task);

/// Why a queued [IdleTask] has not started yet.
///
/// Vision Next-Term §4.2 requires prep jobs to be visible as
/// `queued → running → done/failed` in the task-manager portal. A job that a
/// gate defers used to leave no trace anywhere a student could see (only a
/// debug log), so the portal looked idle while prep was merely paused.
/// Recording the reason on the task lets the portal say *why* the work is
/// waiting and offer cancel / try-now affordances.
enum PrepDeferralReason {
  /// Inside the student's quiet-hours window.
  quietHours,

  /// Device under CPU/battery pressure (§4.3).
  systemLoad,

  /// The student paused prep for this syllabus (§4.2 per-subject opt-in).
  subjectDisabled,

  /// The category's preparation token budget is exhausted (§4.2/§4.4).
  budgetExhausted,
}

PrepDeferralReason? _parseDeferralReason(Object? name) {
  if (name is! String) return null;
  for (final reason in PrepDeferralReason.values) {
    if (reason.name == name) return reason;
  }
  return null;
}

class IdleTask {
  final String id;
  final String description;
  final DateTime createdAt;

  /// Executable closure. NOT persisted: functions cannot be serialised to
  /// Hive. Restored tasks carry `null` here and are re-attached via the
  /// [IdleExecutor]'s [TaskReconstructor] at execution time. Mutable so the
  /// reconstructor can set it after construction.
  Future<void> Function()? taskFn;

  final bool requiresHeavy;
  final String? taskType;
  final String? feature;

  /// Subject this prep task belongs to, for per-subject opt-in enforcement
  /// (Vision Next-Term §4.2 "per-syllabus opt-in"). When non-null and the
  /// subject has been disabled by the student, the [IdleExecutor] defers the
  /// task so no tokens are spent on a syllabus the student paused.
  final String? subjectId;

  /// Optional opaque identifier linking this idle task to the durable entity
  /// that owns it (e.g. a `BulkIngestionJob.id`). The owning service's
  /// [TaskReconstructor] uses it to look up the config needed to rebuild the
  /// executable closure after a restart.
  final String? jobId;

  /// Optional serialisable payload blob carrying whatever extra context a
  /// [TaskReconstructor] needs to rebuild the closure (Vision Next-Term §4.1
  /// PrepTool registry - the taskType/feature key, plus a payload). Stored as
  /// a raw string so future tools can evolve their own encoding without a new
  /// adapter.
  final String? payload;

  bool isRunning;
  bool isCompleted;
  String? error;

  /// Reason this task is currently waiting, or `null` when no gate is
  /// deferring it (e.g. it is about to run, or it already ran).
  ///
  /// Mutated by [IdleExecutor] on every deferral and cleared when execution
  /// starts, so the task-manager portal can render
  /// `queued (deferred: quiet hours / device load / subject paused / budget)`
  /// instead of hiding paused prep work (Vision Next-Term §4.2).
  PrepDeferralReason? deferredReason;

  /// Pre-run token estimate supplied by the enqueuing [PrepTool] so the
  /// [IdleExecutor] budget gate can consult
  /// [PrepBudgetService.canSpend] *before* creating the parent
  /// [LlmTask] on [LlmTaskManager]. When both are zero (the default)
  /// the gate is skipped - tasks that carry no estimate are assumed to
  /// be non-prep background work.
  final int estimatedInputTokens;
  final int estimatedOutputTokens;

  IdleTask({
    required this.id,
    required this.description,
    required this.createdAt,
    this.taskFn,
    this.requiresHeavy = false,
    this.taskType,
    this.feature,
    this.subjectId,
    this.jobId,
    this.payload,
    this.isRunning = false,
    this.isCompleted = false,
    this.error,
    this.deferredReason,
    this.estimatedInputTokens = 0,
    this.estimatedOutputTokens = 0,
  });

  /// Serialisable snapshot used for Hive persistence. The `taskFn` closure is
  /// intentionally excluded - it is reconstructed at load time via the
  /// [TaskReconstructor].
  Map<String, dynamic> toPersistJson() => {
        'id': id,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'requiresHeavy': requiresHeavy,
        'taskType': taskType,
        'feature': feature,
        'subjectId': subjectId,
        'jobId': jobId,
        'payload': payload,
        'isRunning': isRunning,
        'isCompleted': isCompleted,
        'error': error,
        'deferredReason': deferredReason?.name,
        'estimatedInputTokens': estimatedInputTokens,
        'estimatedOutputTokens': estimatedOutputTokens,
      };

  factory IdleTask.fromPersistJson(Map<String, dynamic> json) => IdleTask(
        id: json['id'] as String,
        description: json['description'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        requiresHeavy: json['requiresHeavy'] as bool? ?? false,
        taskType: json['taskType'] as String?,
        feature: json['feature'] as String?,
        subjectId: json['subjectId'] as String?,
        jobId: json['jobId'] as String?,
        payload: json['payload'] as String?,
        // A task that was `isRunning` at termination never reached completion;
        // reset it so the next poll retries it instead of skipping it.
        isRunning: false,
        isCompleted: json['isCompleted'] as bool? ?? false,
        error: json['error'] as String?,
        // A persisted deferral reason is only informational; the executor
        // re-evaluates every gate on the next poll and overwrites it then.
        deferredReason: _parseDeferralReason(json['deferredReason']),
        estimatedInputTokens: (json['estimatedInputTokens'] as num?)?.toInt() ?? 0,
        estimatedOutputTokens: (json['estimatedOutputTokens'] as num?)?.toInt() ?? 0,
      );
}

class IdleExecutor {
  static final Logger _logger = const Logger('IdleExecutor');
  final LlmTaskManager? _llmTaskManager;
  final SystemMonitorService? _systemMonitor;

  /// Bridges aggregate prep spend to the [LlmUsageMeter] so that
  /// [PrepBudgetService.spendingByCategory] attributes off-period work to the
  /// correct prep category (Vision Next-Term §4.2/§4.4). Without this bridge,
  /// individual LLM calls inside a prep pipeline record on the meter under
  /// sub-feature task types (e.g. `classification`), and the parent task's
  /// `feature`/`taskType` (e.g. `pdf_ingestion`) is invisible to the budget
  /// layer - spendByCategory reads zero for the category the student configured.
  final LlmUsageMeter? _usageMeter;

  /// Optional callback consulted before running a task. When it returns true
  /// the task is left in the queue and retried on the next poll, implementing
  /// vision Next-Term §4.2 quiet-hours: heavy prep defers so the student is
  /// not disturbed at night. Inject in tests with a stubbed [DateTime] for a
  /// deterministic fake-clock (e.g. 2am within a 22-8 window).
  final bool Function(DateTime now)? _shouldDeferForQuietHours;

  /// Optional callback consulted before running a task that carries a
  /// [IdleTask.subjectId]. When it returns false the task is left in the queue
  /// (deferred) and no tokens are spent, realising vision Next-Term §4.2
  /// "per-syllabus opt-in": a student who toggles a subject off gets no prep
  /// for that syllabus while away. Inject in tests with a predicate mirroring a
  /// `PrepBudget` whose `disabledSubjects` contains the subject.
  final bool Function(String subjectId)? _isPrepEnabledForSubject;

  /// Vision Next-Term §4.2 prep-budget gate. When present,
  /// [_tryExecuteNext] consults [PrepBudgetService.canSpend] *before*
  /// creating the parent [LlmTask] on [LlmTaskManager], so that an
  /// exhausted category cap defers the task (task stays `queued`) instead
  /// of starting the task and only failing at the [PrepTool.execute] level.
  /// Inject in tests with a fake whose `canSpend` can be toggled.
  final PrepBudgetService? _prepBudgetService;

  /// Optional closure reconstructor consulted lazily by [_tryExecuteNext] for
  /// tasks restored from persistence with no executable [IdleTask.taskFn]
  /// (Vision Next-Term §4.1: the closure must be rebuilt from taskType/feature,
  /// never serialised). Set post-construction by owning services via
  /// [setTaskReconstructor] so they can build on top of the IdleExecutor once
  /// their own state has been restored.
  TaskReconstructor? _taskReconstructor;

  final List<IdleTask> _queue = [];
  int _counter = 0;
  Timer? _idleCheckTimer;
  bool _isExecuting = false;

  // --- Hive persistence (Vision Next-Term §4.2: queue survives termination) ---
  Box? _box;
  // In-flight init future: lets tests await the fire-and-forget init() that
  // owning providers/factories invoke. Null until the first init() call.
  Future<void>? _initFuture;
  // Trailing save future: serialises box writes so overlapping mutations
  // cannot interleave their clear/put sequences (mirrors LlmTaskManager).
  Future<void> _saveChain = Future<void>.value();

  /// Completes once every box save scheduled so far has finished.
  @visibleForTesting
  Future<void> get persistenceComplete => _saveChain;

  /// Completes once the in-flight [init()] (box open + queue restore) has
  /// finished. Lets tests deterministically await the fire-and-forget init()
  /// that [AgentFactory.create] invokes, so they can prove the box is opened by
  /// production code rather than by an explicit test-side init() call.
  /// Resolves immediately (as a completed future) if init() was never called.
  @visibleForTesting
  Future<void> get initComplete => _initFuture ?? Future.value();

  /// Whether the background polling timer spawned by [startIdleMonitoring] is
  /// currently live. True between [startIdleMonitoring] and [stopIdleMonitoring];
  /// false otherwise (including before monitoring starts and after disposal).
  /// Used by provider tests to assert the timer is cancelled on scope teardown
  /// (Vision Next-Term §4.3/§4.4).
  @visibleForTesting
  bool get isMonitoring => _idleCheckTimer?.isActive == true;

  IdleExecutor({
    LlmTaskManager? llmTaskManager,
    String studentId = 'default',
    SystemMonitorService? systemMonitor,
    bool Function(DateTime now)? shouldDeferForQuietHours,
    bool Function(String subjectId)? isPrepEnabledForSubject,
    LlmUsageMeter? usageMeter,
    PrepBudgetService? prepBudgetService,
    TaskReconstructor? taskReconstructor,
  })  : _llmTaskManager = llmTaskManager,
        _systemMonitor = systemMonitor,
        _shouldDeferForQuietHours = shouldDeferForQuietHours,
        _isPrepEnabledForSubject = isPrepEnabledForSubject,
        _usageMeter = usageMeter,
        _prepBudgetService = prepBudgetService,
        _taskReconstructor = taskReconstructor;

  /// Opens the idle-tasks box and restores any queued/running tasks left over
  /// from a previous process. Restored tasks carry no executable closure; they
  /// are re-attached lazily by [_tryExecuteNext] via [_taskReconstructor].
  ///
  /// This is invoked fire-and-forget by owning providers/factories (mirroring
  /// `ingestion_providers.dart:179`), so it must never throw: an unawaited
  /// failure here would surface as an unhandled async error and crash the app.
  /// When the box cannot be opened (e.g. Hive is not initialised, or a test
  /// runs without Hive), the failure is logged and persistence is disabled for
  /// this instance rather than propagating. Idempotent: concurrent/retry calls
  /// share the same in-flight future (see [initComplete]).
  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      _box = await Hive.openBox(HiveBoxNames.idleTasks);
      _loadFromBox();
    } catch (e) {
      _logger.w(
        'IdleExecutor.init could not open the idle-tasks box; '
        'persistence disabled for this instance',
        e,
      );
    }
  }

  /// Registers (or replaces) the closure reconstructor consulted by
  /// [_tryExecuteNext] for tasks restored without an executable
  /// [IdleTask.taskFn]. Owning services call this from their own `init()`
  /// after they have restored the durable state the reconstructor needs to
  /// look up.
  void setTaskReconstructor(TaskReconstructor? reconstructor) {
    _taskReconstructor = reconstructor;
  }

  void _loadFromBox() {
    final box = _box;
    if (box == null || !box.isOpen) return;
    _queue.clear();
    for (final entry in box.values) {
      if (entry is Map) {
        try {
          _queue.add(IdleTask.fromPersistJson(Map<String, dynamic>.from(entry)));
        } catch (e) {
          _logger.w('Failed to restore an idle task from box', e);
        }
      }
    }
    if (_queue.isNotEmpty) {
      _logger.d('Restored ${_queue.length} idle task(s) from persistence');
    }
    // Restore the monotonic counter from the highest stored id so newly
    // generated ids never collide with restored ones across a restart
    // (mirrors LlmTaskManager._loadFromBox).
    if (_queue.isNotEmpty) {
      final maxId = _queue.map((t) {
        final parts = t.id.split('_');
        return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      }).fold(0, (a, b) => a > b ? a : b);
      _counter = maxId;
    }
  }

  Future<void> _saveToBox() async {
    final box = _box;
    if (box == null || !box.isOpen) return;
    try {
      // The clear must fully complete before the puts start. Firing both
      // unawaited lets Hive's async keystore updates interleave, which
      // nondeterministically drops just-written tasks or leaves stale ones
      // behind for the next init() (mirrors LlmTaskManager._saveToBox).
      await box.clear();
      for (final task in _queue) {
        await box.put(task.id, task.toPersistJson());
      }
    } catch (e) {
      _logger.w('Failed to persist idle tasks to box', e);
    }
  }

  /// Schedules an ordered box save. Saves run one after another, each writing
  /// the full current state, so rapid successive mutations coalesce without
  /// ever interleaving their writes. No-op when no box is open (e.g. tests).
  void _persist() {
    _saveChain = _saveChain.then((_) => _saveToBox());
  }

  /// Evicts queued/persisted tasks matching [test] and persists the removal.
  /// Used by owning services (e.g. [BulkIngestionService]) to drop stale tasks
  /// they re-own before re-enqueuing fresh ones after a restart.
  void removeTasksWhere(bool Function(IdleTask task) test) {
    _queue.removeWhere(test);
    _persist();
    _notify();
  }

  List<IdleTask> get queue => List.unmodifiable(_queue);
  bool get hasPendingTasks => _queue.any((t) => !t.isCompleted && !t.isRunning);

  /// Tasks that are waiting to run (neither running nor completed), including
  /// ones a gate is currently deferring. This is the executor's contribution to
  /// the task-manager portal's "queued" section (Vision Next-Term §4.2): pair it
  /// with [IdleTask.deferredReason] to explain *why* prep is waiting.
  List<IdleTask> get queuedTasks =>
      List.unmodifiable(_queue.where((t) => !t.isCompleted && !t.isRunning));

  /// Removes a waiting task from the queue, e.g. when the student cancels it
  /// from the task portal. Running tasks cannot be cancelled this way (their
  /// [IdleTask.taskFn] is already executing and has no cancellation channel);
  /// returns `false` for a running or unknown id.
  bool cancelQueuedTask(String taskId) {
    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index == -1 || _queue[index].isRunning) return false;
    _queue.removeAt(index);
    _persist();
    _notify();
    return true;
  }

  /// Runs the next queued task immediately if every gate now allows it - the
  /// portal's "try now" action for a student who wants to resume deferred prep
  /// instead of waiting for quiet hours to end or the polling timer to fire.
  /// No-op while another task is executing (the poll will pick it up).
  Future<void> retryDeferredNow() => _tryExecuteNext();

  /// Records that [task] is deferred and why, notifying portal listeners only
  /// when the reason actually changes (the poll re-runs gates every 30s).
  void _markDeferred(IdleTask task, PrepDeferralReason reason) {
    if (task.deferredReason == reason) return;
    task.deferredReason = reason;
    _persist();
    _notify();
  }

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
    String? jobId,
    String? payload,
  }) async {
    final id = 'idle_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
    _queue.add(IdleTask(
      id: id,
      description: description,
      createdAt: DateTime.now(),
      taskFn: task,
      requiresHeavy: requiresHeavy,
      jobId: jobId,
      payload: payload,
    ));
    if (_queue.length > 50) {
      _queue.removeAt(0);
    }
    _persist();
    _tryExecuteNext();
  }

  Future<void> enqueuePrepTool(
    String description,
    Future<Map<String, dynamic>> Function() task, {
    required bool requiresHeavy,
    required String feature,
    required String taskType,
    String? subjectId,
    int estimatedInputTokens = 0,
    int estimatedOutputTokens = 0,
    String? jobId,
    String? payload,
  }) async {
    final id = 'idle_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
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
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
      jobId: jobId,
      payload: payload,
    ));
    if (_queue.length > 50) {
      _queue.removeAt(0);
    }
    _persist();
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
    // during sleep hours - not just heavy tasks (a light task at 2am is still
    // disruptive). The check is delegated to the injected callback so tests
    // can supply a fake clock deterministically.
    if (_shouldDeferForQuietHours != null &&
        _shouldDeferForQuietHours(DateTime.now())) {
      _logger.d(
        'Deferring task "${next.description}" - within quiet hours',
      );
      _markDeferred(next, PrepDeferralReason.quietHours);
      return;
    }

    // Vision Next-Term §4.3: heavy off-period prep must defer when the device
    // is stressed (CPU > 80%, battery < 20%, battery-saver on). The task is
    // left in the queue and retried on the next poll / enqueue.
    if (next.requiresHeavy && _systemMonitor != null && !_systemMonitor.canRunHeavyPrepNow) {
      _logger.w(
        'Deferring heavy prep task "${next.description}" - system under load',
      );
      _markDeferred(next, PrepDeferralReason.systemLoad);
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
        'Deferring task "${next.description}" - subject "$subjectId" prep disabled by student',
      );
      _markDeferred(next, PrepDeferralReason.subjectDisabled);
      return;
    }

    // Vision Next-Term §4.2/§4.4: prep-budget gate. Before creating the parent
    // [LlmTask] on [LlmTaskManager], consult [PrepBudgetService.canSpend] with
    // the task's pre-run token estimate. When the category cap is exhausted the
    // task is left in the queue (status `queued`, never `running`/`failed`) and
    // retried on the next poll - so the student sees a deferred task that
    // resumes when the budget window resets, rather than a failure that
    // requires manual retry. Only applies when the task's [IdleTask.taskType]
    // maps to a recognised [PrepCategory]; non-prep background tasks skip this
    // gate entirely (they carry `taskType: 'background'` which maps to
    // [PrepCategory.background], so they are still covered by the cap).
    if (_prepBudgetService != null && next.taskType != null) {
      final category = PrepCategory.values.firstWhere(
        (c) => c.taskTypeKey == next.taskType,
        orElse: () => PrepCategory.background,
      );
      final estimatedTokens = next.estimatedInputTokens + next.estimatedOutputTokens;
      if (estimatedTokens > 0 &&
          !_prepBudgetService.canSpend(category, estimatedTokens)) {
        _logger.d(
          'Deferring task "${next.description}" - ${category.taskTypeKey} budget exhausted '
          '(${_prepBudgetService.remainingFor(category)} tokens remaining; '
          'estimated $estimatedTokens needed, will retry on next poll)',
        );
        _markDeferred(next, PrepDeferralReason.budgetExhausted);
        return;
      }
    }

    // Vision Next-Term §4.1: the executable closure cannot be serialised to
    // Hive, so tasks restored from persistence arrive here with `taskFn == null`.
    // Consult the optional [TaskReconstructor] to rebuild the closure from the
    // task's taskType/feature (+ jobId/payload). When no reconstructor can
    // reattach a closure the task is drained as a no-op (logged at `d`) so it
    // does not clog the queue; an owning service that can reconstruct the
    // closure keeps the task runnable across restarts.
    if (next.taskFn == null) {
      final closure = _taskReconstructor?.call(next);
      if (closure == null) {
        _logger.d(
          'Idle task "${next.description}" has no reconstructable closure '
          '(feature=${next.feature}, taskType=${next.taskType}, '
          'jobId=${next.jobId}); draining as no-op',
        );
        next.isCompleted = true;
        _persist();
        _notify();
        return;
      }
      // The reconstructor returns the closure directly (a pure lookup); attach
      // it so the normal execution path below runs the restored task.
      next.taskFn = closure;
    }

    _isExecuting = true;
    next.isRunning = true;
    // Every gate passed: the task is no longer deferred, so the portal must
    // stop showing a pause reason for it (Vision Next-Term §4.2).
    next.deferredReason = null;
    _persist();

    final manager = _llmTaskManager;
    final taskId = manager?.createTask(
          feature: next.feature ?? 'idle_executor',
          modelId: 'background',
          taskType: next.taskType ?? LlmTaskType.background.name,
          // Propagate the human-readable IdleTask.description onto the parent
          // LlmTask (Vision Next-Term §0 token principle / §4.2 visibility):
          // the task-manager portal needs it to tell students WHAT the off-period
          // prep is doing, not just that a "background/background" job is running.
          description: next.description,
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
      // per-task token spend instead of 0 (vision Next-Term §4.2 token
      // transparency).
      var totalTokens = 0;
      var totalCost = 0.0;
      // Track whether any per-call LlmTask already recorded on the meter under
      // a PrepCategory key. If so, those tokens are already attributed on the
      // meter and the aggregate bridge must NOT re-record them - that would
      // double-count the same physical tokens on the shared LlmUsageMeter,
      // inflating totalPrepTokens() and burning per-category caps at 2x the
      // real rate (Issue: idle-executor-aggregate-double-counts-meter).
      var perCallHasPrepCategory = false;
      if (manager != null) {
        for (final t in manager.tasks) {
          if (preRunTaskIds.contains(t.id) || t.id == taskId) continue;
          totalTokens += t.tokensUsed;
          totalCost += t.estimatedCost;
          if (t.taskType != null &&
              PrepCategory.values.any((c) => c.taskTypeKey == t.taskType)) {
            perCallHasPrepCategory = true;
          }
        }
      }
      if (taskId.isNotEmpty) {
        manager?.completeTask(
          taskId,
          tokensUsed: totalTokens,
          estimatedCost: totalCost,
        );
        // Bridge the parent task's feature/taskType onto the LlmUsageMeter so
        // PrepBudgetService can attribute the spend under the correct prep
        // category (Vision Next-Term §4.2). This is ONLY needed when per-call
        // recordings did NOT already cover the tokens under a PrepCategory key
        // - e.g. pipeline internal calls using non-prep features that resolve
        // to classification/generation/summarization. When per-call recordings
        // already used a PrepCategory key (e.g. 'pdf_ingestion' via the
        // taskType override in chat()), re-recording would double-count the
        // same physical tokens. Only recorded when tokens were actually
        // consumed AND the aggregate is not redundant.
        if (_usageMeter != null &&
            totalTokens > 0 &&
            !perCallHasPrepCategory) {
          final inputTokens = totalTokens ~/ 2;
          _usageMeter.recordUsage(
            id: '${taskId}_aggregate_${DateTime.now().millisecondsSinceEpoch}',
            feature: next.feature ?? 'idle_executor',
            modelId: 'background',
            inputTokens: inputTokens,
            outputTokens: totalTokens - inputTokens,
            taskType: next.taskType ?? LlmTaskType.background.name,
          );
        }
      }
      _persist();
    } catch (e) {
      next.error = e.toString();
      if (taskId.isNotEmpty) manager?.failTask(taskId, e.toString());
      _logger.w('Idle task failed: ${next.description}', e);
      _persist();
    } finally {
      next.isRunning = false;
      _isExecuting = false;
      _notify();
      _persist();
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
    // Flush the in-memory queue to disk so queued/pending tasks survive the
    // process termination (Vision Next-Term §4.2). Best-effort: when no box is
    // open (e.g. tests) this is a no-op. Schedules on the ordered save chain
    // mirroring LlmTaskManager (which persists on each mutation).
    _persist();
    stopIdleMonitoring();
    _listeners.clear();
  }
}
