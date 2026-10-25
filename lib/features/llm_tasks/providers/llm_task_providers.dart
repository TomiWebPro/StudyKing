import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/idle_executor_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart' show IdleTask;
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';
import 'package:studyking/features/llm_tasks/services/prep_queue_service.dart';

final llmTaskServiceProvider = Provider<LlmTaskService>((ref) {
  final manager = ref.watch(llmTaskManagerProvider);
  return LlmTaskService(manager: manager);
});

/// Bridge between the shared off-period prep queue and the task portal
/// (Vision Next-Term §4.2: deferred prep must appear as `queued` so the student
/// can see and steer it). The screen watches this to render the "queued
/// preparation" section with cancel / try-now actions.
///
/// Watches [idleExecutorProvider] so the portal and the mentor agent/bulk
/// ingestion observe the SAME queue.
final prepQueueServiceProvider = ChangeNotifierProvider<PrepQueueService>((ref) {
  return PrepQueueService(executors: [ref.watch(idleExecutorProvider)]);
});

/// Waiting prep tasks (oldest first) for the portal's queued section.
final queuedPrepTasksProvider = Provider<List<IdleTask>>((ref) {
  return ref.watch(prepQueueServiceProvider).queuedTasks;
});

final allTasksProvider = Provider<List<LlmTask>>((ref) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.getAllTasks();
});

final activeTasksProvider = Provider<List<LlmTask>>((ref) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.getActiveTasks();
});

final filteredTasksProvider = Provider.family<List<LlmTask>, LlmTaskFilter>((ref, filter) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.getFilteredTasks(feature: filter.feature, status: filter.status);
});

final taskTokenUsageProvider = Provider<Map<String, int>>((ref) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.tokenUsageByFeature;
});

final taskCostProvider = Provider<Map<String, double>>((ref) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.costByFeature;
});

final totalTaskTokensProvider = Provider<int>((ref) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.totalTokenUsage;
});

final totalTaskCostProvider = Provider<double>((ref) {
  final service = ref.watch(llmTaskServiceProvider);
  return service.totalEstimatedCost;
});

class LlmTaskFilter {
  final String? feature;
  final LlmTaskStatus? status;

  const LlmTaskFilter({this.feature, this.status});
}
