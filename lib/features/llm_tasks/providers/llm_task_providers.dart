import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';

final llmTaskServiceProvider = Provider<LlmTaskService>((ref) {
  final manager = ref.watch(llmTaskManagerProvider);
  return LlmTaskService(manager: manager);
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
