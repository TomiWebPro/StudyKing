import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/models/dynamic_context_config.dart';

void main() {
  group('DynamicContextConfig', () {
    test('fromModel uses known and fallback context windows', () {
      final known = DynamicContextConfig.fromModel('google/gemini-1.5-pro');
      final fallback = DynamicContextConfig.fromModel('unknown/model');

      expect(known.contextWindow, 200000);
      expect(known.autoFetched, isFalse);
      expect(known.batchSize, 10);
      expect(known.batchInterval, const Duration(seconds: 2));

      expect(fallback.contextWindow, 8192);
      expect(fallback.modelId, 'unknown/model');
    });

    test('toJson and fromJson round-trip with all fields', () {
      const source = DynamicContextConfig(
        modelId: 'openai/gpt-4o',
        contextWindow: 128000,
        actualContextUsed: 4096,
        autoFetched: true,
        batchSize: 12,
        batchInterval: Duration(milliseconds: 1500),
      );

      final restored = DynamicContextConfig.fromJson(source.toJson());

      expect(restored.modelId, source.modelId);
      expect(restored.contextWindow, source.contextWindow);
      expect(restored.actualContextUsed, source.actualContextUsed);
      expect(restored.batchSize, source.batchSize);
      expect(restored.batchInterval, source.batchInterval);
      expect(restored.autoFetched, isFalse);
      expect(restored.toString(), contains('openai/gpt-4o'));
    });

    test('fromJson applies default values for missing data', () {
      final restored = DynamicContextConfig.fromJson({});

      expect(restored.modelId, 'unknown');
      expect(restored.contextWindow, 4096);
      expect(restored.actualContextUsed, 0);
      expect(restored.autoFetched, isFalse);
      expect(restored.batchSize, 10);
      expect(restored.batchInterval, const Duration(milliseconds: 2000));
    });
  });
}
