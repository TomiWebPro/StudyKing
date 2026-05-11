import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/models/llm_config.dart';

void main() {
  group('LLMModelConfig', () {
    const config = LLMModelConfig(
      provider: 'openrouter',
      modelName: 'anthropic/claude-3-haiku',
      providerDisplayName: 'Claude',
      inputPricePerMillionTokens: 0.25,
      outputPricePerMillionTokens: 1.25,
      contextWindow: 200000,
    );

    test('calculates token cost and formats pricing', () {
      final cost = config.calculateCost(400000, 100000);

      expect(cost, closeTo(0.225, 1e-10));
      expect(config.formatPricing(), '0.25/\$M input, 1.25/\$M output');
      expect(config.toString(), contains('LLMConfig(openrouter, anthropic/claude-3-haiku'));
    });

    test('uses provider and model in equality', () {
      const same = LLMModelConfig(
        provider: 'openrouter',
        modelName: 'anthropic/claude-3-haiku',
        providerDisplayName: 'Different Display',
        inputPricePerMillionTokens: 4,
        outputPricePerMillionTokens: 5,
        contextWindow: 1,
      );

      expect(config, same);
      expect(config.hashCode, same.hashCode);
    });

    test('different provider/model results in inequality', () {
      const different = LLMModelConfig(
        provider: 'openai',
        modelName: 'gpt-4',
        providerDisplayName: 'GPT-4',
        inputPricePerMillionTokens: 0.25,
        outputPricePerMillionTokens: 1.25,
        contextWindow: 200000,
      );

      expect(config, isNot(equals(different)));
    });

    test('hashCode depends on provider and modelName only', () {
      const config1 = LLMModelConfig(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Display 1',
        inputPricePerMillionTokens: 1.0,
        outputPricePerMillionTokens: 2.0,
        contextWindow: 1000,
      );

      const config2 = LLMModelConfig(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Display 2',
        inputPricePerMillionTokens: 9.0,
        outputPricePerMillionTokens: 8.0,
        contextWindow: 9999,
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('calculateCost with zero tokens', () {
      final cost = config.calculateCost(0, 0);
      expect(cost, 0.0);
    });

    test('calculateCost with large token counts', () {
      final cost = config.calculateCost(1000000, 1000000);
      expect(cost, greaterThan(0));
    });

    test('formatPricing returns correct format', () {
      const testConfig = LLMModelConfig(
        provider: 'test',
        modelName: 'model',
        providerDisplayName: 'Test Model',
        inputPricePerMillionTokens: 3.0,
        outputPricePerMillionTokens: 15.0,
        contextWindow: 100000,
      );

      expect(testConfig.formatPricing(), '3.0/\$M input, 15.0/\$M output');
    });

    test('toString includes pricing information', () {
      const testConfig = LLMModelConfig(
        provider: 'test',
        modelName: 'model',
        providerDisplayName: 'Test',
        inputPricePerMillionTokens: 1.0,
        outputPricePerMillionTokens: 2.0,
        contextWindow: 4096,
      );

      final str = testConfig.toString();
      expect(str, contains('LLMConfig'));
      expect(str, contains('test'));
      expect(str, contains('model'));
    });
  });

  group('APIEndpointConfig', () {
    test('normalizes empty api key and maps openrouter provider', () {
      final endpoint = APIEndpointConfig(
        provider: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: '',
        modelName: 'model-x',
        contextWindow: 32000,
      );

      final modelConfig = endpoint.toModelConfig();
      expect(endpoint.apiKey, '');
      expect(modelConfig.provider, 'openrouter');
      expect(modelConfig.inputPricePerMillionTokens, 0.5);
      expect(modelConfig.outputPricePerMillionTokens, 10.0);
      expect(modelConfig.contextWindow, 32000);
    });

    test('maps unknown provider to custom model config', () {
      final endpoint = APIEndpointConfig(
        provider: 'my-provider',
        baseUrl: 'https://custom',
        apiKey: 'token',
        modelName: 'model-z',
      );

      final modelConfig = endpoint.toModelConfig();
      expect(modelConfig.provider, 'custom');
      expect(modelConfig.providerDisplayName, 'my-provider');
      expect(modelConfig.inputPricePerMillionTokens, 0);
      expect(modelConfig.outputPricePerMillionTokens, 0);
    });

    test('non-empty api key is preserved', () {
      final endpoint = APIEndpointConfig(
        provider: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: 'sk-or-v1-test-key',
        modelName: 'claude-3',
      );

      expect(endpoint.apiKey, 'sk-or-v1-test-key');
    });

    test('default context window when not specified', () {
      final endpoint = APIEndpointConfig(
        provider: 'openrouter',
        baseUrl: 'https://test.com',
        apiKey: 'key',
      );

      expect(endpoint.contextWindow, 4096);
    });

    test('equality based on provider and baseUrl', () {
      final endpoint1 = APIEndpointConfig(
        provider: 'openrouter',
        baseUrl: 'https://test.com',
        apiKey: 'key1',
        modelName: 'model-a',
      );

      final endpoint2 = APIEndpointConfig(
        provider: 'openrouter',
        baseUrl: 'https://test.com',
        apiKey: 'key2',
        modelName: 'model-b',
      );

      expect(endpoint1, equals(endpoint2));
      expect(endpoint1.hashCode, equals(endpoint2.hashCode));
    });

    test('different baseUrl results in inequality', () {
      final endpoint1 = APIEndpointConfig(
        provider: 'openrouter',
        baseUrl: 'https://test1.com',
        apiKey: 'key',
      );

      final endpoint2 = APIEndpointConfig(
        provider: 'openrouter',
        baseUrl: 'https://test2.com',
        apiKey: 'key',
      );

      expect(endpoint1, isNot(equals(endpoint2)));
    });

    test('toModelConfig uses case-insensitive provider matching', () {
      final endpoint = APIEndpointConfig(
        provider: 'OPENROUTER',
        baseUrl: 'https://test.com',
        apiKey: 'key',
        modelName: 'test-model',
      );

      final modelConfig = endpoint.toModelConfig();
      expect(modelConfig.provider, 'openrouter');
    });
  });

  group('LLMUsageRecord', () {
    test('json round-trip and totals', () {
      final now = DateTime.now();
      final record = LLMUsageRecord(
        timestamp: now,
        provider: 'openrouter',
        model: 'm1',
        inputTokens: 123,
        outputTokens: 45,
        totalCost: 0.017,
      );

      final restored = LLMUsageRecord.fromJson(record.toJson());
      expect(restored.totalTokens, 168);
      expect(restored.provider, 'openrouter');
      expect(restored.model, 'm1');
    });

    test('totalTokens calculation', () {
      final record = LLMUsageRecord(
        timestamp: DateTime.now(),
        provider: 'openrouter',
        model: 'test',
        inputTokens: 1000,
        outputTokens: 500,
        totalCost: 0.05,
      );

      expect(record.totalTokens, 1500);
    });

    test('fromJson parses timestamp correctly', () {
      final json = {
        'timestamp': '2026-05-11T10:30:00.000Z',
        'provider': 'openrouter',
        'model': 'claude-3',
        'inputTokens': 100,
        'outputTokens': 50,
        'totalCost': 0.01,
      };

      final record = LLMUsageRecord.fromJson(json);
      expect(record.timestamp.year, 2026);
      expect(record.timestamp.month, 5);
      expect(record.timestamp.day, 11);
    });

    test('toJson includes all fields', () {
      final timestamp = DateTime(2026, 5, 11, 12, 0, 0);
      final record = LLMUsageRecord(
        timestamp: timestamp,
        provider: 'test-provider',
        model: 'test-model',
        inputTokens: 200,
        outputTokens: 100,
        totalCost: 0.025,
      );

      final json = record.toJson();
      expect(json['timestamp'], '2026-05-11T12:00:00.000');
      expect(json['provider'], 'test-provider');
      expect(json['model'], 'test-model');
      expect(json['inputTokens'], 200);
      expect(json['outputTokens'], 100);
      expect(json['totalCost'], 0.025);
    });
  });

  group('LLMUsageSummary', () {
    test('computes safe derived values', () {
      const empty = LLMUsageSummary(
        totalRequests: 0,
        totalTokens: 0,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalCost: 0,
      );
      const used = LLMUsageSummary(
        totalRequests: 10,
        totalTokens: 1000,
        totalInputTokens: 700,
        totalOutputTokens: 300,
        totalCost: 5,
      );

      expect(empty.costPerToken, 0);
      expect(empty.monthlyProjection, 0);
      expect(used.costPerToken, 0.005);
      expect(used.monthlyProjection, 15);
      expect(used.toString(), contains('10 reqs'));
    });

    test('costPerToken handles edge cases', () {
      const noTokens = LLMUsageSummary(
        totalRequests: 1,
        totalTokens: 0,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalCost: 1.0,
      );

      expect(noTokens.costPerToken, 0);
    });

    test('monthlyProjection handles edge cases', () {
      const noRequests = LLMUsageSummary(
        totalRequests: 0,
        totalTokens: 1000,
        totalInputTokens: 700,
        totalOutputTokens: 300,
        totalCost: 5.0,
      );

      expect(noRequests.monthlyProjection, 0);
    });

    test('costPerToken calculates correctly', () {
      const summary = LLMUsageSummary(
        totalRequests: 100,
        totalTokens: 10000,
        totalInputTokens: 7000,
        totalOutputTokens: 3000,
        totalCost: 10.0,
      );

      expect(summary.costPerToken, 0.001);
    });

    test('toString formats correctly', () {
      const summary = LLMUsageSummary(
        totalRequests: 50,
        totalTokens: 5000,
        totalInputTokens: 3500,
        totalOutputTokens: 1500,
        totalCost: 2.50,
      );

      final str = summary.toString();
      expect(str, contains('50 reqs'));
      expect(str, contains('5000 tokens'));
      expect(str, contains('2.5000'));
    });
  });

  group('AvailableModels', () {
    test('returns provider models and handles unknown provider', () {
      final openrouter = AvailableModels.getModelsByProvider('OpenRouter');
      final unknown = AvailableModels.getModelsByProvider('unknown');

      expect(openrouter, isNotEmpty);
      expect(openrouter.first.provider, 'openrouter');
      expect(openrouter.any((m) => m.modelName == AvailableModels.defaultOpenRouterModel), isTrue);
      expect(unknown, isEmpty);
    });

    test('getModelsByProvider is case-insensitive', () {
      final upper = AvailableModels.getModelsByProvider('OPENROUTER');
      final lower = AvailableModels.getModelsByProvider('openrouter');
      final mixed = AvailableModels.getModelsByProvider('OpenRouter');

      expect(upper.length, equals(lower.length));
      expect(upper.length, equals(mixed.length));
    });

    test('contains multiple model categories', () {
      final models = AvailableModels.getModelsByProvider('openrouter');
      final modelNames = models.map((m) => m.modelName).toList();

      expect(modelNames.any((n) => n.contains('anthropic')), isTrue);
      expect(modelNames.any((n) => n.contains('google')), isTrue);
      expect(modelNames.any((n) => n.contains('meta')), isTrue);
      expect(modelNames.any((n) => n.contains('mistral')), isTrue);
    });

    test('defaultOpenRouterModel exists in openrouterModels', () {
      final models = AvailableModels.openrouterModels;
      expect(models.any((m) => m.modelName == AvailableModels.defaultOpenRouterModel), isTrue);
    });

    test('all models have valid context windows', () {
      final models = AvailableModels.openrouterModels;

      for (final model in models) {
        expect(model.contextWindow, greaterThan(0));
      }
    });

    test('all models have valid pricing', () {
      final models = AvailableModels.openrouterModels;

      for (final model in models) {
        expect(model.inputPricePerMillionTokens, greaterThanOrEqualTo(0));
        expect(model.outputPricePerMillionTokens, greaterThanOrEqualTo(0));
        expect(model.provider, isNotEmpty);
        expect(model.modelName, isNotEmpty);
        expect(model.providerDisplayName, isNotEmpty);
      }
    });

    test('openrouterModels has expected number of models', () {
      expect(AvailableModels.openrouterModels.length, greaterThanOrEqualTo(8));
    });
  });
}
