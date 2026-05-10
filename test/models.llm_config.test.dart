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
  });

  group('LLM usage models', () {
    test('LLMUsageRecord json round-trip and totals', () {
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

    test('LLMUsageSummary computes safe derived values', () {
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
  });
}
