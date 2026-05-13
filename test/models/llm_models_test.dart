import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/llm_models.dart';

void main() {
  group('ModelPrice', () {
    test('parses model price json with fallback defaults', () {
      final parsed = ModelPrice.fromJson({
        'modelId': 'm1',
        'inputPrice': '0.5',
        'outputPrice': 1.5,
        'cacheReadPrice': null,
      });

      expect(parsed.modelId, 'm1');
      expect(parsed.inputPrice, 0.5);
      expect(parsed.outputPrice, 1.5);
      expect(parsed.cacheReadPrice, 0.0);
      expect(parsed.contextWindow, 4096);
    });

    test('toJson produces correct output', () {
      final price = ModelPrice(
        modelId: 'test-model',
        inputPrice: 1.0,
        outputPrice: 2.0,
        cacheReadPrice: 0.5,
        contextWindow: 8192,
      );

      final json = price.toJson();
      expect(json['modelId'], 'test-model');
      expect(json['inputPrice'], 1.0);
      expect(json['outputPrice'], 2.0);
      expect(json['cacheReadPrice'], 0.5);
      expect(json['contextWindow'], 8192);
    });

    test('handles null/undefined values in json', () {
      final parsed = ModelPrice.fromJson({
        'modelId': 'test-model',
        'inputPrice': '0.5',
        'outputPrice': 1.5,
        'cacheReadPrice': null,
      });

      expect(parsed.modelId, 'test-model');
      expect(parsed.inputPrice, 0.5);
      expect(parsed.outputPrice, 1.5);
      expect(parsed.cacheReadPrice, 0.0);
      expect(parsed.contextWindow, 4096);
    });

    test('handles invalid string values in json', () {
      final parsed = ModelPrice.fromJson({
        'modelId': 'test',
        'inputPrice': 'invalid',
        'outputPrice': 'not-a-number',
        'cacheReadPrice': 'also-invalid',
      });

      expect(parsed.inputPrice, 0.0);
      expect(parsed.outputPrice, 0.0);
      expect(parsed.cacheReadPrice, 0.0);
    });

    test('handles numeric values in json', () {
      final parsed = ModelPrice.fromJson({
        'modelId': 'test',
        'inputPrice': 0.5,
        'outputPrice': 1.5,
        'cacheReadPrice': 0.1,
        'contextWindow': 10000,
      });

      expect(parsed.inputPrice, 0.5);
      expect(parsed.outputPrice, 1.5);
      expect(parsed.cacheReadPrice, 0.1);
      expect(parsed.contextWindow, 10000);
    });
  });

  group('DynamicModel', () {
    test('getBestPrice and calculateCost handle empty and non-empty prices', () {
      final empty = DynamicModel(
        provider: 'openrouter',
        modelName: 'm-empty',
        providerDisplayName: 'Empty',
      );

      final priced = DynamicModel(
        provider: 'openrouter',
        modelName: 'm-priced',
        providerDisplayName: 'Priced',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 0.8, outputPrice: 0.9, cacheReadPrice: 0.0, contextWindow: 1000),
          ModelPrice(modelId: 'p2', inputPrice: 0.4, outputPrice: 0.4, cacheReadPrice: 0.0, contextWindow: 2000),
        ],
      );

      expect(empty.getBestPrice().modelId, 'm-empty');
      expect(empty.calculateCost(1000, 1000), 0.0);

      final best = priced.getBestPrice();
      expect(best.modelId, 'p2');
      expect(priced.calculateCost(500000, 500000), closeTo(0.4, 1e-10));
      expect(priced.toString(), contains('fetched:false'));
    });

    test('DynamicModel equality based on provider and modelName', () {
      final model1 = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test Model',
      );

      final model2 = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Different Display Name',
      );

      final model3 = DynamicModel(
        provider: 'openrouter',
        modelName: 'different-model',
        providerDisplayName: 'Test Model',
      );

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });

    test('DynamicModel supports metadata', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        metadata: {'key': 'value', 'version': 1},
      );

      expect(model.metadata['key'], 'value');
      expect(model.metadata['version'], 1);
    });

    test('DynamicModel with custom prices list', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 1.0, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096),
        ],
      );

      expect(model.prices.length, 1);
      expect(model.pricesFetched, isFalse);
    });

    test('getBestPrice returns first price when all have same total', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 1.0, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096),
          ModelPrice(modelId: 'p2', inputPrice: 1.0, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096),
        ],
      );

      final best = model.getBestPrice();
      expect(best.modelId, 'p1');
    });

    test('calculateCost with zero tokens', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 1.0, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096),
        ],
      );

      expect(model.calculateCost(0, 0), 0.0);
    });

    test('calculateCost with large tokens', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 3.0, outputPrice: 15.0, cacheReadPrice: 0.0, contextWindow: 200000),
        ],
      );

      final cost = model.calculateCost(1000000, 500000);
      expect(cost, greaterThan(0));
    });

    test('toString includes modelName and pricesFetched', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        pricesFetched: true,
      );

      final str = model.toString();
      expect(str, contains('test-model'));
      expect(str, contains('fetched:true'));
    });
  });

  group('OpenRouterRequest', () {
    test('serializes optional fields correctly', () {
      const full = OpenRouterRequest(
        model: 'm1',
        messages: [
          {'role': 'user', 'content': 'Hello'}
        ],
        temperature: 0.4,
        maxTokens: 256,
        topP: 0.9,
        stream: true,
      );
      const minimal = OpenRouterRequest(
        model: 'm2',
        messages: [],
      );

      final fullJson = full.toJson();
      final minimalJson = minimal.toJson();

      expect(fullJson['max_tokens'], 256);
      expect(fullJson['top_p'], 0.9);
      expect(fullJson['stream'], isTrue);
      expect(fullJson['temperature'], 0.4);

      expect(minimalJson.containsKey('max_tokens'), isFalse);
      expect(minimalJson.containsKey('top_p'), isFalse);
      expect(minimalJson['temperature'], 0.7);
      expect(minimal.toString(), contains('messages: 0'));
    });

    test('includes apiKey in header (via extraHeaderKey)', () {
      const request = OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'test'}],
        apiKey: 'secret-key',
        extraHeaderKey: 'x-api-key',
      );

      expect(request.apiKey, 'secret-key');
      expect(request.extraHeaderKey, 'x-api-key');
    });

    test('toJson with all optional parameters null', () {
      const request = OpenRouterRequest(
        model: 'test',
        messages: [],
        temperature: null,
        maxTokens: null,
        topP: null,
        stream: null,
      );

      final json = request.toJson();
      expect(json['temperature'], 0.7);
      expect(json.containsKey('max_tokens'), isFalse);
      expect(json.containsKey('top_p'), isFalse);
    });

    test('toString includes model and message count', () {
      const request = OpenRouterRequest(
        model: 'claude-3',
        messages: [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi'},
        ],
      );

      final str = request.toString();
      expect(str, contains('claude-3'));
      expect(str, contains('messages: 2'));
    });
  });

  group('OpenRouterResponse', () {
    test('fromJson parses response correctly', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r1',
        'choices': [
          {'role': 'assistant', 'content': 'Answer'}
        ],
      });

      expect(response.object, 'chat.completion');
      expect(response.created, 0);
      expect(response.getAssistantResponse()?.content, 'Answer');
      expect(response.toString(), contains('choices: 1'));
    });

    test('fromJson handles empty response', () {
      final empty = OpenRouterResponse.fromJson({'id': 'r2'});
      expect(empty.choices, isEmpty);
      expect(empty.getAssistantResponse(), isNull);
    });

    test('fromJson with full usage data', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r3',
        'choices': [
          {'role': 'assistant', 'content': 'Full response'}
        ],
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 50,
          'total_tokens': 150,
        },
        'effective_duration_ms': 1234,
        'prompt_tokens_details': {'cached_tokens': 20},
      });

      expect(response.usage['prompt_tokens'], 100);
      expect(response.effectiveDurationMs, 1234);
      expect(response.promptTokensDetails['cached_tokens'], 20);
    });

    test('getAssistantResponse returns null for empty choices', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r4',
        'choices': [],
      });

      expect(response.getAssistantResponse(), isNull);
    });

    test('toString includes id and choices count', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'test-id-123',
        'choices': [
          {'role': 'assistant', 'content': 'A'},
          {'role': 'assistant', 'content': 'B'},
        ],
      });

      final str = response.toString();
      expect(str, contains('choices: 2'));
      expect(str, contains('test-id-123'));
    });
  });

  group('Message', () {
    test('fromJson parses message correctly', () {
      final message = Message.fromJson({
        'role': 'user',
        'content': 'Hello, world!',
        'reasoning': {'thinking': 'I should respond politely'},
        'tool': {'name': 'calculator', 'input': {}},
        'index': {'position': 0},
        'finish': {'reason': 'stop'},
      });

      expect(message.role, 'user');
      expect(message.content, 'Hello, world!');
      expect(message.reasoning, isNotNull);
      expect(message.tool, isNotNull);
      expect(message.index, isNotNull);
      expect(message.finish, isNotNull);
    });

    test('fromJson handles empty json with defaults', () {
      final message = Message.fromJson({});

      expect(message.role, 'unknown');
      expect(message.content, '');
      expect(message.reasoning, isNull);
      expect(message.tool, isNull);
      expect(message.index, isNull);
      expect(message.finish, isNull);
      expect(message.toString(), contains('0 chars'));
    });

    test('default constructor creates empty message', () {
      const message = Message();

      expect(message.role, '');
      expect(message.content, '');
      expect(message.reasoning, isNull);
    });

    test('toString includes role and content length', () {
      const message = Message(role: 'assistant', content: 'Test content');

      final str = message.toString();
      expect(str, contains('assistant'));
      expect(str, matches(RegExp(r'\d+ chars')));
    });
  });
}
