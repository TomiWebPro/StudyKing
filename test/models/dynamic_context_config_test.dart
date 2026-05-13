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

    test('constructor creates immutable config', () {
      const config = DynamicContextConfig(
        modelId: 'test-model',
        contextWindow: 32000,
        actualContextUsed: 1024,
        autoFetched: true,
        batchSize: 20,
        batchInterval: Duration(seconds: 3),
      );

      expect(config.modelId, 'test-model');
      expect(config.contextWindow, 32000);
      expect(config.actualContextUsed, 1024);
      expect(config.autoFetched, isTrue);
      expect(config.batchSize, 20);
      expect(config.batchInterval, const Duration(seconds: 3));
    });

    test('fromModel recognizes all known models', () {
      final knownModels = [
        ('anthropic/claude-3-5-sonnet', 200000),
        ('meta/llama-3-1-405b-instruct', 128000),
        ('google/gemini-2.0-flash', 1000000),
        ('google/gemini-1.5-pro', 200000),
        ('mistralai/mistral-large', 32000),
        ('meta/llama-3.2-90b-vision-instruct', 128000),
        ('meta/llama-3.1-70b-instruct', 128000),
        ('meta/llama-3-70b-instruct', 8192),
        ('mistralai/mistral-7b-instruct', 32768),
        ('openai/gpt-4o', 128000),
      ];

      for (final (modelId, expectedWindow) in knownModels) {
        final config = DynamicContextConfig.fromModel(modelId);
        expect(config.contextWindow, expectedWindow,
            reason: 'Model $modelId should have context window $expectedWindow');
        expect(config.modelId, modelId);
      }
    });

    test('toJson produces correct structure', () {
      const config = DynamicContextConfig(
        modelId: 'test-model',
        contextWindow: 32000,
        actualContextUsed: 2048,
        autoFetched: true,
        batchSize: 15,
        batchInterval: Duration(seconds: 5),
      );

      final json = config.toJson();

      expect(json['modelId'], 'test-model');
      expect(json['contextWindow'], 32000);
      expect(json['actualContextUsed'], 2048);
      expect(json['batchSize'], 15);
      expect(json['batchIntervalMs'], 5000);
    });

    test('fromJson handles partial data', () {
      final config = DynamicContextConfig.fromJson({
        'modelId': 'partial-model',
        'contextWindow': 16000,
      });

      expect(config.modelId, 'partial-model');
      expect(config.contextWindow, 16000);
      expect(config.actualContextUsed, 0);
      expect(config.autoFetched, isFalse);
      expect(config.batchSize, 10);
    });

    test('fromJson handles null modelId', () {
      final config = DynamicContextConfig.fromJson({
        'modelId': null,
        'contextWindow': 16000,
      });

      expect(config.modelId, 'unknown');
      expect(config.contextWindow, 16000);
    });

    test('equality compares all fields', () {
      const config1 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        actualContextUsed: 500,
        autoFetched: false,
        batchSize: 10,
        batchInterval: Duration(seconds: 2),
      );

      const config2 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        actualContextUsed: 500,
        autoFetched: false,
        batchSize: 10,
        batchInterval: Duration(seconds: 2),
      );

      expect(config1, equals(config2));
    });

    test('inequality for different actualContextUsed', () {
      const config1 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        actualContextUsed: 500,
      );

      const config2 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        actualContextUsed: 600,
      );

      expect(config1, isNot(equals(config2)));
    });

    test('inequality for different autoFetched', () {
      const config1 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        autoFetched: false,
      );

      const config2 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        autoFetched: true,
      );

      expect(config1, isNot(equals(config2)));
    });

    test('inequality for different batchSize', () {
      const config1 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        batchSize: 10,
      );

      const config2 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        batchSize: 20,
      );

      expect(config1, isNot(equals(config2)));
    });

    test('hashCode depends on all fields', () {
      const config1 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        actualContextUsed: 500,
        autoFetched: false,
        batchSize: 10,
        batchInterval: Duration(seconds: 2),
      );

      const config2 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        actualContextUsed: 500,
        autoFetched: false,
        batchSize: 10,
        batchInterval: Duration(seconds: 2),
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('hashCode differs for different fields', () {
      const config1 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        batchSize: 10,
      );

      const config2 = DynamicContextConfig(
        modelId: 'test',
        contextWindow: 10000,
        batchSize: 20,
      );

      expect(config1.hashCode, isNot(equals(config2.hashCode)));
    });

    test('toString includes all relevant information', () {
      const config = DynamicContextConfig(
        modelId: 'claude-3.5-sonnet',
        contextWindow: 200000,
        actualContextUsed: 50000,
        autoFetched: true,
        batchSize: 15,
        batchInterval: Duration(seconds: 3),
      );

      final str = config.toString();

      expect(str, contains('claude-3.5-sonnet'));
      expect(str, contains('200000'));
      expect(str, contains('50000'));
      expect(str, contains('15'));
      expect(str, contains('true'));
    });

    test('fromModel uses default batch configuration', () {
      final config = DynamicContextConfig.fromModel('anthropic/claude-3-5-sonnet');

      expect(config.batchSize, 10);
      expect(config.batchInterval, const Duration(seconds: 2));
    });
  });
}
