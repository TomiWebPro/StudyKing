import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('defaultModelForProvider', () {
    test('returns correct default models', () {
      expect(defaultModelForProvider(LlmProvider.openRouter), equals('gemini-2.0-flash'));
      expect(defaultModelForProvider(LlmProvider.ollama), equals('llama3'));
      expect(defaultModelForProvider(LlmProvider.openAI), equals('gpt-4o-mini'));
    });
  });

  group('app providers', () {
    test('settingsLoadingProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(settingsLoadingProvider), isFalse);
    });

    test('themeModeProvider defaults to light', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('fontSizeProvider defaults to 16', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(fontSizeProvider), equals(16.0));
    });

    test('apiKeyProvider defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(apiKeyProvider), equals(''));
    });

    test('selectedModelProvider defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(selectedModelProvider), equals(''));
    });

    test('llmProviderProvider defaults to openRouter', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(llmProviderProvider), equals(LlmProvider.openRouter));
    });

    test('apiBaseUrlProvider defaults to openRouter base URL', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(apiBaseUrlProvider), isNotEmpty);
    });
  });
}
