import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('LlmService', () {
    group('LlmConfiguration', () {
      test('creates configuration with required fields', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test_key',
        );

        expect(config.provider, equals(LlmProvider.openRouter));
        expect(config.apiKey, equals('test_key'));
      });

      test('creates configuration with custom baseUrl', () {
        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'test_key',
          baseUrl: 'http://localhost:11434',
        );

        expect(config.baseUrl, equals('http://localhost:11434'));
      });

      test('default baseUrl is empty', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test_key',
        );

        expect(config.baseUrl, equals(''));
      });
    });

    group('LlmProvider', () {
      test('has openRouter value', () {
        expect(LlmProvider.openRouter, isA<LlmProvider>());
      });

      test('has ollama value', () {
        expect(LlmProvider.ollama, isA<LlmProvider>());
      });
    });
  });
}