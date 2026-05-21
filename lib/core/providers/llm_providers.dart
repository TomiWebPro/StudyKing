import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
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

final backupLlmProviderProvider = StateProvider<LlmProvider>((ref) => LlmProvider.openRouter);

final backupApiKeyProvider = StateProvider<String>((ref) => '');

final backupBaseUrlProvider = StateProvider<String>((ref) => '');

final backupModelProvider = StateProvider<String>((ref) => '');

final llmServiceProvider = Provider<LlmService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  final apiBaseUrl = ref.watch(apiBaseUrlProvider);
  final llmProvider = ref.watch(llmProviderProvider);
  final taskManager = ref.watch(llmTaskManagerProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
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
  );
});

