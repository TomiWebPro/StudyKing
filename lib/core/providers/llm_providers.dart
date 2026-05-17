import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/providers/app_providers.dart';

final llmTaskManagerProvider = Provider<LlmTaskManager>((ref) {
  return LlmTaskManager();
});

final llmUsageMeterProvider = Provider<LlmUsageMeter>((ref) {
  return LlmUsageMeter();
});

final llmServiceProvider = Provider<LlmService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  final apiBaseUrl = ref.watch(apiBaseUrlProvider);
  final llmProvider = ref.watch(llmProviderProvider);
  final taskManager = ref.watch(llmTaskManagerProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
  return LlmService(
    config: LlmConfiguration(
      provider: llmProvider,
      apiKey: apiKey,
      baseUrl: apiBaseUrl,
    ),
    taskManager: taskManager,
    usageMeter: usageMeter,
  );
});

