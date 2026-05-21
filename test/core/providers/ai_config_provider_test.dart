import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/ai_config_provider.dart';

void main() {
  group('aiConfigProvider', () {
    test('aiConfigReadyProvider is not completed initially', () {
      expect(isAiConfigReady, isFalse);
    });

    test('markAiConfigReady completes the future', () async {
      markAiConfigReady();
      expect(isAiConfigReady, isTrue);
    });

    test('aiConfigReadyProvider resolves after markAiConfigReady', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      markAiConfigReady();
      await container.read(aiConfigReadyProvider.future);
    });

    test('double-complete is idempotent', () {
      markAiConfigReady();
      expect(isAiConfigReady, isTrue);
      markAiConfigReady();
      expect(isAiConfigReady, isTrue);
    });
  });
}
