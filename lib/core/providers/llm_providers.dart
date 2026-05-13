import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/providers/app_providers.dart';

final llmServiceProvider = Provider<LlmService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return LlmService(
    config: LlmConfiguration(
      provider: LlmProvider.openRouter,
      apiKey: apiKey,
    ),
  );
});

final apiKeyValueProvider = Provider<String>((ref) {
  return ref.watch(apiKeyProvider);
});
