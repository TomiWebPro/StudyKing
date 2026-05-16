import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('apiKeyValueProvider mirrors apiKeyProvider default', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(apiKeyValueProvider), equals(container.read(apiKeyProvider)));
    });
  });

  group('llmServiceProvider wiring', () {
    test('uses default config from dependency providers', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final service = container.read(llmServiceProvider);
      expect(service.config.apiKey, isEmpty);
      expect(service.config.provider, equals(LlmProvider.openRouter));
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

    test('reads apiKeyValueProvider overrides', () {
      final container = ProviderContainer(
        overrides: [
          apiKeyProvider.overrideWith((ref) => 'overridden-key'),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(apiKeyValueProvider), equals('overridden-key'));
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

      expect(container1.read(apiKeyValueProvider), equals('container1-key'));
      expect(container2.read(apiKeyValueProvider), isEmpty);
    });
  });
}
