import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/llm_defaults.dart' show defaultModelForProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm/llm_response_cache.dart';
import 'package:studyking/core/services/llm/model_router.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/providers/app_providers.dart';

final llmTaskManagerProvider = Provider<LlmTaskManager>((ref) {
  final manager = LlmTaskManager();
  manager.init();
  return manager;
});

final llmUsageMeterProvider = Provider<LlmUsageMeter>((ref) {
  final meter = LlmUsageMeter();
  meter.init();
  return meter;
});

final llmResponseCacheProvider = Provider<LlmResponseCache>((ref) {
  final cache = LlmResponseCache();
  cache.init();
  return cache;
});

final backupLlmProviderProvider = StateProvider<LlmProvider>((ref) => LlmProvider.openRouter);

final backupApiKeyProvider = StateProvider<String>((ref) => '');

final backupBaseUrlProvider = StateProvider<String>((ref) => '');

final backupModelProvider = StateProvider<String>((ref) => '');

/// Per-task model configuration. UI in Settings can override individual
/// task model IDs; empty values fall back to the router's sensible defaults.
final taskModelConfigProvider = StateProvider<TaskModelConfig>(
  (ref) => const TaskModelConfig(),
);

/// Routes each [LlmTaskType] to a concrete model ID, applying capability-based
/// fallback when a configured model lacks the required capability.
final modelRouterProvider = Provider<ModelRouter>((ref) {
  final config = ref.watch(taskModelConfigProvider);
  final provider = ref.watch(llmProviderProvider);
  final selected = ref.watch(selectedModelProvider);
  final fallback = selected.isNotEmpty ? selected : defaultModelForProvider(provider);
  return ModelRouter(
    config: config,
    fallbackModelId: fallback,
    provider: provider,
  );
});

final llmServiceProvider = Provider<LlmService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  final apiBaseUrl = ref.watch(apiBaseUrlProvider);
  final llmProvider = ref.watch(llmProviderProvider);
  final taskManager = ref.watch(llmTaskManagerProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
  final cache = ref.watch(llmResponseCacheProvider);
  final backupProvider = ref.watch(backupLlmProviderProvider);
  final backupApiKey = ref.watch(backupApiKeyProvider);
  final backupBaseUrl = ref.watch(backupBaseUrlProvider);
  final backupModel = ref.watch(backupModelProvider);
  return LlmService(
    config: LlmConfiguration(
      provider: llmProvider,
      apiKey: apiKey,
      baseUrl: apiBaseUrl,
      backupProvider: backupProvider,
      backupApiKey: backupApiKey,
      backupBaseUrl: backupBaseUrl,
      backupModel: backupModel,
    ),
    taskManager: taskManager,
    usageMeter: usageMeter,
    cache: cache,
  );
});

