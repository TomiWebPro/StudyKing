import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import '../data/hive_box_names.dart';
import '../theme/llm_task_status.dart';
import '../utils/logger.dart';
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
  final String? description;
  final Completer<void>? cancelCompleter;

  /// Coarse task category for filtering/categorisation in the LLM task manager
  /// portal (e.g. `mentor`, `tutor`, `background`, `pdf_ingestion`). See
  /// [LlmUsageRecord.taskType] and Vision Next-Term §4.2.
  final String? taskType;

  /// Identifier of the teaching session (`TutorSession.id`) this task belongs
  /// to, or `null` when not attributable to a specific lesson. Lets the student
  /// filter the task list to a single lesson's token spend
  /// (Vision Next-Term §0 steerability / §4.4).
  final String? sessionId;

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
    this.description,
    this.cancelCompleter,
    this.taskType,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'feature': feature,
    'modelId': modelId,
    'status': status.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'tokensUsed': tokensUsed,
    'estimatedCost': estimatedCost,
    'error': error,
    'description': description,
    'taskType': taskType,
    'sessionId': sessionId,
  };

  factory LlmTask.fromJson(Map<String, dynamic> json) => LlmTask(
    id: json['id'] as String,
    feature: json['feature'] as String,
    modelId: json['modelId'] as String,
    status: LlmTaskStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => LlmTaskStatus.queued,
    ),
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    tokensUsed: (json['tokensUsed'] as num?)?.toInt() ?? 0,
    estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
    error: json['error'] as String?,
    description: json['description'] as String?,
    taskType: json['taskType'] as String?,
    sessionId: json['sessionId'] as String?,
  );

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
    String? description,
    Completer<void>? cancelCompleter,
    String? taskType,
    String? sessionId,
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
      description: description ?? this.description,
      cancelCompleter: cancelCompleter ?? this.cancelCompleter,
      taskType: taskType ?? this.taskType,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class LlmTaskManager {
  static final Logger _logger = const Logger('LlmTaskManager');

  final List<LlmTask> _tasks = [];
  int _counter = 0;
  Box? _box;
  // Trailing save future: serializes box writes so overlapping
  // mutations cannot interleave their clear/put sequences.
  Future<void> _saveChain = Future<void>.value();

  List<LlmTask> get tasks => List.unmodifiable(_tasks);

  List<LlmTask> get activeTasks =>
      _tasks.where((t) => t.status == LlmTaskStatus.running || t.status == LlmTaskStatus.queued).toList();

  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxNames.llmTasks);
    _loadFromBox();
  }

  void _loadFromBox() {
    final box = _box;
    if (box == null || !box.isOpen) return;
    _tasks.clear();
    for (final entry in box.values) {
      if (entry is Map) {
        _tasks.add(LlmTask.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    if (_tasks.isNotEmpty) {
      final maxId = _tasks.map((t) {
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
      // The clear must fully complete before the puts start. Firing
      // both unawaited lets Hive's async keystore updates interleave,
      // which nondeterministically either drops the just-written
      // tasks or leaves stale ones behind for the next init().
      await box.clear();
      for (final task in _tasks) {
        await box.put(task.id, task.toJson());
      }
    } catch (e) {
      _logger.w('Failed to persist LLM tasks to box', e);
    }
  }

  /// Schedules an ordered box save. Saves run one after another, each
  /// writing the full current state, so rapid successive mutations
  /// coalesce without ever interleaving their writes.
  void _persist() {
    _saveChain = _saveChain.then((_) => _saveToBox());
  }

  /// Completes once every save scheduled so far has finished.
  @visibleForTesting
  Future<void> get persistenceComplete => _saveChain;

  String createTask({
    required String feature,
    required String modelId,
    String? description,
    String? taskType,
    String? sessionId,
  }) {
    final id = 'task_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
    _tasks.add(LlmTask(
      id: id,
      feature: feature,
      modelId: modelId,
      startTime: DateTime.now(),
      description: description,
      taskType: taskType,
      sessionId: sessionId,
    ));
    if (_tasks.length > 1000) {
      _tasks.removeRange(0, _tasks.length - 1000);
    }
    _persist();
    _notify();
    return id;
  }

  void startTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: LlmTaskStatus.running,
    );
    _persist();
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
    _persist();
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
    _persist();
    _notify();
    onTaskFailed?.call(_tasks[idx].feature, error);
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
      _persist();
      _notify();
    }
  }

  Completer<void>? registerCancelCompleter(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return null;
    final completer = Completer<void>();
    _tasks[idx] = _tasks[idx].copyWith(cancelCompleter: completer);
    return completer;
  }

  String retryTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return '';
    final oldTask = _tasks[idx];
    return createTask(
      feature: oldTask.feature,
      modelId: oldTask.modelId,
      description: oldTask.description,
      taskType: oldTask.taskType,
      sessionId: oldTask.sessionId,
    );
  }

  void Function(String feature, String error)? onTaskFailed;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
