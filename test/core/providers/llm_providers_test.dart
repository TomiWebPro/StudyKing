import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('llm providers - default values', () {
    test('llmTaskManagerProvider creates provider', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final taskManager = container.read(llmTaskManagerProvider);
      expect(taskManager, isNotNull);
    });

    test('llmUsageMeterProvider creates provider', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final meter = container.read(llmUsageMeterProvider);
      expect(meter, isNotNull);
    });

    test('apiKeyProvider mirrors apiKeyProvider default', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(apiKeyProvider), equals(container.read(apiKeyProvider)));
    });
  });

  group('llmServiceProvider wiring', () {
    test('uses default config from dependency providers', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final service = container.read(llmServiceProvider);
      expect(service.config.apiKey, isEmpty);
      expect(service.config.provider, equals(LlmProvider.openRouter));
      expect(service.config.baseUrl, equals(ApiConfig.openRouterBaseUrlString));
    });

    test('reflects overridden apiKey', () {
      final container = ProviderContainer(
        overrides: [
          apiKeyProvider.overrideWith((ref) => 'test-api-key'),
        ],
      );
      addTearDown(() => container.dispose());
      final service = container.read(llmServiceProvider);
      expect(service.config.apiKey, equals('test-api-key'));
    });

    test('reflects overridden apiBaseUrl', () {
      final container = ProviderContainer(
        overrides: [
          apiBaseUrlProvider.overrideWith((ref) => 'https://custom.url'),
        ],
      );
      addTearDown(() => container.dispose());
      final service = container.read(llmServiceProvider);
      expect(service.config.baseUrl, equals('https://custom.url'));
    });

    test('reflects overridden llmProvider', () {
      final container = ProviderContainer(
        overrides: [
          llmProviderProvider.overrideWith((ref) => LlmProvider.ollama),
        ],
      );
      addTearDown(() => container.dispose());
      final service = container.read(llmServiceProvider);
      expect(service.config.provider, equals(LlmProvider.ollama));
    });

    test('reads apiKeyProvider overrides', () {
      final container = ProviderContainer(
        overrides: [
          apiKeyProvider.overrideWith((ref) => 'overridden-key'),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(apiKeyProvider), equals('overridden-key'));
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
  });

  group('defaultModelForProvider', () {
    test('returns correct defaults per provider', () {
      expect(defaultModelForProvider(LlmProvider.openRouter), equals('gemini-2.0-flash'));
      expect(defaultModelForProvider(LlmProvider.ollama), equals('llama3'));
      expect(defaultModelForProvider(LlmProvider.openAI), equals('gpt-4o-mini'));
    });
  });

  group('provider isolation', () {
    test('different containers have different provider instances', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(() => container1.dispose());
      addTearDown(() => container2.dispose());

      final service1 = container1.read(llmServiceProvider);
      final service2 = container2.read(llmServiceProvider);
      expect(identical(service1, service2), isFalse);
    });

    test('overrides in one container do not affect another', () {
      final container1 = ProviderContainer(
        overrides: [
          apiKeyProvider.overrideWith((ref) => 'container1-key'),
        ],
      );
      final container2 = ProviderContainer();
      addTearDown(() => container1.dispose());
      addTearDown(() => container2.dispose());

      expect(container1.read(apiKeyProvider), equals('container1-key'));
      expect(container2.read(apiKeyProvider), isEmpty);
    });
  });
}
