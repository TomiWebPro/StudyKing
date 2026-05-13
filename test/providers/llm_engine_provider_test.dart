import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/llm_config.dart';
import 'package:studyking/core/data/models/llm_models.dart';
import 'package:studyking/providers/llm_engine_provider.dart';
import 'package:studyking/services/llm_api_service.dart';

class MockOpenRouterClient extends OpenRouterClient {
  String? apiKey;
  List<Map<String, dynamic>> availableModels = [];
  Map<String, List<ModelPrice>> modelPrices = {};
  OpenRouterResponse? chatResponse;
  bool shouldThrowOnChat = false;
  bool shouldThrowOnPrices = false;

  MockOpenRouterClient() : super();

  @override
  void setApiKey(String key) {
    apiKey = key;
  }

  @override
  void clearApiKey() {
    apiKey = null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableModels() async {
    return availableModels;
  }

  @override
  Future<List<ModelPrice>> fetchModelPrices(String modelId) async {
    if (shouldThrowOnPrices) {
      throw Exception('Price fetch failed');
    }
    return modelPrices[modelId] ?? [];
  }

  @override
  Future<OpenRouterResponse> chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
    bool? stream,
  }) async {
    if (shouldThrowOnChat) {
      throw Exception('Chat failed');
    }
    return chatResponse!;
  }
}

void main() {
  late MockOpenRouterClient mockClient;
  late LLMAIEngineProvider provider;

  setUp(() {
    mockClient = MockOpenRouterClient();
    provider = LLMAIEngineProvider(client: mockClient);
  });

  group('initial state', () {
    test('isLoading is false initially', () {
      expect(provider.isLoading, isFalse);
    });

    test('apiKeyConfigured is false initially', () {
      expect(provider.apiKeyConfigured, isFalse);
    });

    test('selectedModel is null initially', () {
      expect(provider.selectedModel, isNull);
    });

    test('usageSummary is empty initially', () {
      final summary = provider.usageSummary;
      expect(summary.totalRequests, 0);
      expect(summary.totalTokens, 0);
      expect(summary.totalInputTokens, 0);
      expect(summary.totalOutputTokens, 0);
      expect(summary.totalCost, 0.0);
    });

    test('getUsageHistory returns empty list initially', () {
      expect(provider.getUsageHistory(), isEmpty);
    });
  });

  group('API key management', () {
    test('setApiKey sets the key and notifies', () async {
      await provider.setApiKey('test-key-123');
      expect(provider.apiKeyConfigured, isTrue);
      expect(provider.apiKey, 'test-key-123');
    });

    test('setApiKey returns the key', () async {
      final result = await provider.setApiKey('return-key');
      expect(result, 'return-key');
    });

    test('clearApiKey clears the key', () async {
      await provider.setApiKey('some-key');
      expect(provider.apiKeyConfigured, isTrue);

      provider.clearApiKey();
      expect(provider.apiKeyConfigured, isFalse);
      expect(provider.apiKey, isEmpty);
    });

    test('configureEndpoint delegates to setApiKey', () async {
      await provider.configureEndpoint('endpoint-key');
      expect(provider.apiKeyConfigured, isTrue);
      expect(provider.apiKey, 'endpoint-key');
    });

    test('resetConfiguration clears key and selected model', () async {
      await provider.setApiKey('key-to-reset');
      provider.setSelectedModel(
        const LLMModelConfig(
          provider: 'openrouter',
          modelName: 'test/model',
          providerDisplayName: 'Test Model',
          inputPricePerMillionTokens: 1.0,
          outputPricePerMillionTokens: 2.0,
          contextWindow: 4096,
        ),
      );
      expect(provider.apiKeyConfigured, isTrue);
      expect(provider.selectedModel, isNotNull);

      await provider.resetConfiguration();
      expect(provider.apiKeyConfigured, isFalse);
      expect(provider.selectedModel, isNull);
    });
  });

  group('model selection', () {
    test('setSelectedModel updates selected model', () {
      final model = const LLMModelConfig(
        provider: 'openrouter',
        modelName: 'anthropic/claude-3.5-sonnet',
        providerDisplayName: 'Claude 3.5 Sonnet',
        inputPricePerMillionTokens: 3.0,
        outputPricePerMillionTokens: 15.0,
        contextWindow: 200000,
      );

      provider.setSelectedModel(model);
      expect(provider.selectedModel, model);
      expect(provider.selectedModel!.modelName, 'anthropic/claude-3.5-sonnet');
    });

    test('setSelectedModel replaces previous selection', () {
      provider.setSelectedModel(
        const LLMModelConfig(
          provider: 'openrouter',
          modelName: 'model-a',
          providerDisplayName: 'A',
          inputPricePerMillionTokens: 1.0,
          outputPricePerMillionTokens: 2.0,
          contextWindow: 4096,
        ),
      );
      provider.setSelectedModel(
        const LLMModelConfig(
          provider: 'openrouter',
          modelName: 'model-b',
          providerDisplayName: 'B',
          inputPricePerMillionTokens: 3.0,
          outputPricePerMillionTokens: 6.0,
          contextWindow: 8192,
        ),
      );

      expect(provider.selectedModel!.modelName, 'model-b');
    });
  });

  group('usage tracking', () {
    test('addUsageRecord adds to history', () {
      final now = DateTime.now();
      provider.addUsageRecord(
        LLMUsageRecord(
          timestamp: now,
          provider: 'openrouter',
          model: 'test-model',
          inputTokens: 100,
          outputTokens: 50,
          totalCost: 0.001,
        ),
      );

      final history = provider.getUsageHistory();
      expect(history.length, 1);
      expect(history[0].inputTokens, 100);
      expect(history[0].outputTokens, 50);
      expect(history[0].totalCost, 0.001);
    });

    test('addUsageRecord prepends to history', () {
      final now = DateTime.now();
      provider.addUsageRecord(
        LLMUsageRecord(
          timestamp: now, provider: 'p1', model: 'm1',
          inputTokens: 10, outputTokens: 5, totalCost: 0.001,
        ),
      );
      provider.addUsageRecord(
        LLMUsageRecord(
          timestamp: now, provider: 'p2', model: 'm2',
          inputTokens: 100, outputTokens: 50, totalCost: 0.01,
        ),
      );

      final history = provider.getUsageHistory();
      expect(history.length, 2);
      expect(history[0].provider, 'p2');
      expect(history[1].provider, 'p1');
    });

    test('usageSummary reflects accumulated usage', () {
      final now = DateTime.now();
      provider.addUsageRecord(
        LLMUsageRecord(
          timestamp: now, provider: 'p1', model: 'm1',
          inputTokens: 100, outputTokens: 50, totalCost: 0.005,
        ),
      );
      provider.addUsageRecord(
        LLMUsageRecord(
          timestamp: now, provider: 'p2', model: 'm2',
          inputTokens: 200, outputTokens: 100, totalCost: 0.015,
        ),
      );

      final summary = provider.usageSummary;
      expect(summary.totalRequests, 2);
      expect(summary.totalTokens, 450);
      expect(summary.totalInputTokens, 300);
      expect(summary.totalOutputTokens, 150);
      expect(summary.totalCost, 0.02);
    });

    test('clearUsageHistory resets all tracking', () {
      final now = DateTime.now();
      provider.addUsageRecord(
        LLMUsageRecord(
          timestamp: now, provider: 'p1', model: 'm1',
          inputTokens: 10, outputTokens: 5, totalCost: 0.001,
        ),
      );
      expect(provider.getUsageHistory(), isNotEmpty);

      provider.clearUsageHistory();
      expect(provider.getUsageHistory(), isEmpty);
      expect(provider.usageSummary.totalRequests, 0);
    });
  });

  group('getTimestamp', () {
    test('returns ISO8601 formatted string', () {
      final ts = provider.getTimestamp();
      expect(ts, isA<String>());
      expect(() => DateTime.parse(ts), returnsNormally);
    });
  });

  group('getAllModels', () {
    test('returns empty list when no models available', () async {
      final models = await provider.getAllModels();
      expect(models, isEmpty);
    });

    test('maps models from OpenRouter format', () async {
      provider = LLMAIEngineProvider(client: mockClient);
      mockClient.availableModels = [
        {'modelId': 'model-a', 'name': 'Model A', 'contextLength': 4096},
        {'modelId': 'model-b', 'name': null, 'contextLength': null},
      ];

      final models = await provider.getAllModels();
      expect(models.length, 2);
      expect(models[0].modelId, 'model-a');
      expect(models[0].modelName, 'Model A');
      expect(models[1].modelId, 'model-b');
      expect(models[1].modelName, 'model-b');
      expect(models[1].contextLength, 4096);
    });
  });

  group('OpenRouterModelModel', () {
    test('toJson produces correct map', () {
      final model = OpenRouterModelModel(
        modelId: 'test-id',
        provider: 'openrouter',
        modelName: 'Test Model',
        contextLength: 8192,
      );

      final json = model.toJson();
      expect(json['modelId'], 'test-id');
      expect(json['provider'], 'openrouter');
      expect(json['modelName'], 'Test Model');
      expect(json['contextLength'], 8192);
    });

    test('toJson includes metadata', () {
      final model = OpenRouterModelModel(
        modelId: 'id',
        provider: 'p',
        modelName: 'n',
        contextLength: 4096,
        metadata: {'extra': 'value'},
      );

      final json = model.toJson();
      expect(json['extra'], 'value');
    });

    test('fromMap parses with all fields', () {
      final model = OpenRouterModelModel.fromMap({
        'modelId': 'm1',
        'provider': 'openrouter',
        'modelName': 'My Model',
        'contextLength': 16384,
      });

      expect(model.modelId, 'm1');
      expect(model.provider, 'openrouter');
      expect(model.modelName, 'My Model');
      expect(model.contextLength, 16384);
    });

    test('fromMap fills defaults for missing fields', () {
      final model = OpenRouterModelModel.fromMap({});

      expect(model.modelId, '');
      expect(model.provider, '');
      expect(model.modelName, '');
      expect(model.contextLength, 4096);
    });

    test('toString truncates long model IDs', () {
      final model = OpenRouterModelModel(
        modelId: 'a' * 50,
        provider: 'p',
        modelName: 'n',
        contextLength: 4096,
      );

      expect(model.toString().length, lessThan(40));
    });
  });

  group('fetchModelPrice', () {
    test('does nothing when API key is not set', () async {
      await provider.fetchModelPrice('any-model');
      expect(provider.isLoading, isFalse);
    });

    test('handles fetch errors gracefully', () async {
      await provider.setApiKey('test-key');
      mockClient.shouldThrowOnPrices = true;

      await provider.fetchModelPrice('failing-model');
      expect(provider.isLoading, isFalse);
    });
  });

  group('calculateModelCost', () {
    test('returns zero for unknown model', () {
      expect(provider.calculateModelCost('unknown-model'), 0.0);
    });
  });
}
