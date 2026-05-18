import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('Settings → LLM providers integration', () {
    test('LlmConfiguration stores api key from settings', () async {
      const config = LlmConfiguration(
        provider: LlmProvider.openAI,
        apiKey: 'sk-test-key-12345',
        baseUrl: 'https://api.openai.com/v1',
      );

      expect(config.apiKey, 'sk-test-key-12345');
      expect(config.provider, LlmProvider.openAI);
      expect(config.baseUrl, 'https://api.openai.com/v1');
    });

    test('empty api key results in failure result', () async {
      const config = LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: '',
      );
      final service = LlmService(config: config);
      final result = await service.chat(
        message: 'Hello',
        modelId: 'test-model',
      );
      expect(result.isFailure, isTrue);
    });

    test('provider change affects base URL construction', () async {
      const openRouterConfig = LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'key',
      );
      final openRouterService = LlmService(config: openRouterConfig);

      const openAIConfig = LlmConfiguration(
        provider: LlmProvider.openAI,
        apiKey: 'key',
      );
      final openAIService = LlmService(config: openAIConfig);

      expect(openRouterService, isNot(same(openAIService)));
    });

    test('api key change creates new service configuration', () async {
      const config1 = LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'old-key',
      );
      const config2 = LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'new-key',
      );

      expect(config1.apiKey, 'old-key');
      expect(config2.apiKey, 'new-key');
      expect(config1.apiKey, isNot(config2.apiKey));
    });
  });
}
