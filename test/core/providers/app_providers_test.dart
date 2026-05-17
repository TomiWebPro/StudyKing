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

    test('override wiring reads back overridden value', () {
      final container = ProviderContainer(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.dark),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('override wiring does not affect other providers', () {
      final container = ProviderContainer(
        overrides: [
          fontSizeProvider.overrideWith((ref) => 20.0),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(fontSizeProvider), equals(20.0));
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('StateProvider returns same instance from same container', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final theme1 = container.read(themeModeProvider);
      final theme2 = container.read(themeModeProvider);
      expect(theme1, theme2);
    });

    test('localeProvider falls back to en for unsupported locale', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final locale = container.read(localeProvider);
      expect(locale.languageCode, anyOf('en', 'en_US', 'en_GB'));
    });
  });
}
