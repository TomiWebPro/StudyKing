import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/constants/app_api_config.dart';

void main() {
  group('LlmService provider wiring', () {
    test('default llmServiceProvider uses openRouter provider and default baseUrl', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final llm = container.read(llmServiceProvider);
      expect(llm.config.provider, equals(LlmProvider.openRouter));
      expect(llm.config.apiKey, isEmpty);
      expect(llm.config.baseUrl, equals(ApiConfig.openRouterBaseUrlString));
    });

    test('llmServiceProvider reflects provider change to ollama', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(llmProviderProvider.notifier).state = LlmProvider.ollama;
      container.read(apiBaseUrlProvider.notifier).state = 'http://localhost:11434';

      final llm = container.read(llmServiceProvider);
      expect(llm.config.provider, equals(LlmProvider.ollama));
      expect(llm.config.baseUrl, equals('http://localhost:11434'));
    });

    test('llmServiceProvider reflects provider change to openAI', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(llmProviderProvider.notifier).state = LlmProvider.openAI;
      container.read(apiBaseUrlProvider.notifier).state = 'https://api.openai.com/v1';
      container.read(apiKeyProvider.notifier).state = 'sk-test-key';

      final llm = container.read(llmServiceProvider);
      expect(llm.config.provider, equals(LlmProvider.openAI));
      expect(llm.config.baseUrl, equals('https://api.openai.com/v1'));
      expect(llm.config.apiKey, equals('sk-test-key'));
    });

    test('llmServiceProvider updates when apiBaseUrlProvider changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(apiBaseUrlProvider.notifier).state = 'https://custom.url/v1';
      container.read(apiKeyProvider.notifier).state = 'custom-key';

      final llm = container.read(llmServiceProvider);
      expect(llm.config.provider, equals(LlmProvider.openRouter));
      expect(llm.config.baseUrl, equals('https://custom.url/v1'));
      expect(llm.config.apiKey, equals('custom-key'));
    });

    test('llmServiceProvider with provider override constructs correct LlmConfiguration', () {
      final container = ProviderContainer(
        overrides: [
          llmProviderProvider.overrideWith((ref) => LlmProvider.ollama),
          apiBaseUrlProvider.overrideWith((ref) => 'http://localhost:11434'),
          apiKeyProvider.overrideWith((ref) => 'ollama-key'),
        ],
      );
      addTearDown(container.dispose);

      final llm = container.read(llmServiceProvider);
      expect(llm.config.provider, equals(LlmProvider.ollama));
      expect(llm.config.baseUrl, equals('http://localhost:11434'));
      expect(llm.config.apiKey, equals('ollama-key'));
    });

    test('defaultModelForProvider returns correct defaults per provider', () {
      expect(defaultModelForProvider(LlmProvider.openRouter), equals('gemini-2.0-flash'));
      expect(defaultModelForProvider(LlmProvider.ollama), equals('llama3'));
      expect(defaultModelForProvider(LlmProvider.openAI), equals('gpt-4o-mini'));
    });
  });
}
