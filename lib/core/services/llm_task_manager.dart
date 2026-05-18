import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_box_names.dart';
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
  late Box _box;

  List<LlmTask> get tasks => List.unmodifiable(_tasks);

  List<LlmTask> get activeTasks =>
      _tasks.where((t) => t.status == LlmTaskStatus.running || t.status == LlmTaskStatus.queued).toList();

  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxNames.llmTasks);
    _loadFromBox();
  }

  void _loadFromBox() {
    _tasks.clear();
    for (final entry in _box.values) {
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

  void _saveToBox() {
    _box.clear();
    for (final task in _tasks) {
      _box.put(task.id, task.toJson());
    }
  }

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
    if (_tasks.length > 1000) {
      _tasks.removeRange(0, _tasks.length - 1000);
    }
    _saveToBox();
    _notify();
    return id;
  }

  void startTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: LlmTaskStatus.running,
    );
    _saveToBox();
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
    _saveToBox();
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
    _saveToBox();
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
      _saveToBox();
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
