import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/llm_defaults.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('defaultModelForProvider', () {
    test('returns gemini-2.0-flash for OpenRouter', () {
      expect(defaultModelForProvider(LlmProvider.openRouter), equals('gemini-2.0-flash'));
    });

    test('returns llama3 for Ollama', () {
      expect(defaultModelForProvider(LlmProvider.ollama), equals('llama3'));
    });

    test('returns gpt-4o-mini for OpenAI', () {
      expect(defaultModelForProvider(LlmProvider.openAI), equals('gpt-4o-mini'));
    });

    test('each provider gets a non-empty model', () {
      final models = LlmProvider.values.map(defaultModelForProvider).toSet();
      expect(models, isNotEmpty);
      for (final provider in LlmProvider.values) {
        expect(defaultModelForProvider(provider), isNotEmpty);
      }
    });

    test('openRouter, ollama and openAI get distinct models', () {
      final baseProviders = [
        LlmProvider.openRouter,
        LlmProvider.ollama,
        LlmProvider.openAI,
      ];
      final models = baseProviders.map(defaultModelForProvider).toSet();
      expect(models.length, baseProviders.length);
    });

    test('returns non-empty string for every provider', () {
      for (final provider in LlmProvider.values) {
        expect(defaultModelForProvider(provider), isNotEmpty);
      }
    });
  });
}
