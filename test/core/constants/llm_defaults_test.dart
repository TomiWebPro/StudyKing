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

    test('each provider gets a distinct model', () {
      final models = LlmProvider.values.map(defaultModelForProvider).toSet();
      expect(models.length, LlmProvider.values.length);
    });

    test('returns non-empty string for every provider', () {
      for (final provider in LlmProvider.values) {
        expect(defaultModelForProvider(provider), isNotEmpty);
      }
    });
  });
}
