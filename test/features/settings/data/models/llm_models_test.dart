import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/llm_models.dart';

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

    test('missing contextWindow defaults to 4096', () {
      final parsed = ModelPrice.fromJson({
        'modelId': 'test',
        'inputPrice': 0.5,
        'outputPrice': 1.0,
      });

      expect(parsed.contextWindow, 4096);
    });

    group('equality', () {
      test('equal when all fields match', () {
        const a = ModelPrice(modelId: 'm1', inputPrice: 0.5, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096);
        const b = ModelPrice(modelId: 'm1', inputPrice: 0.5, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096);
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when modelId differs', () {
        const a = ModelPrice(modelId: 'm1', inputPrice: 0.5, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096);
        const b = ModelPrice(modelId: 'm2', inputPrice: 0.5, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096);
        expect(a == b, isFalse);
      });

      test('identical to itself', () {
        const price = ModelPrice(modelId: 'm1', inputPrice: 0.5, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096);
        expect(price == price, isTrue);
      });
    });

    test('toString includes modelId', () {
      const price = ModelPrice(modelId: 'test-model', inputPrice: 0.5, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096);
      expect(price.toString(), contains('ModelPrice'));
    });

    test('serialization roundtrip', () {
      const original = ModelPrice(modelId: 'm1', inputPrice: 0.5, outputPrice: 1.5, cacheReadPrice: 0.1, contextWindow: 8192);
      final json = original.toJson();
      final restored = ModelPrice.fromJson(json);
      expect(restored.modelId, original.modelId);
      expect(restored.inputPrice, original.inputPrice);
      expect(restored.outputPrice, original.outputPrice);
      expect(restored.cacheReadPrice, original.cacheReadPrice);
      expect(restored.contextWindow, original.contextWindow);
    });
  });

  group('DynamicModel', () {
    test('constructor defaults', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test Model',
      );

      expect(model.provider, 'openrouter');
      expect(model.modelName, 'test-model');
      expect(model.providerDisplayName, 'Test Model');
      expect(model.pricesFetched, isFalse);
      expect(model.prices, isEmpty);
      expect(model.metadata, isEmpty);
    });

    test('getBestPrice with empty prices returns fallback', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
      );

      final best = model.getBestPrice();
      expect(best.modelId, 'test-model');
      expect(best.inputPrice, 0.0);
      expect(best.contextWindow, 4096);
    });

    test('getBestPrice returns cheapest price', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 0.8, outputPrice: 0.9, cacheReadPrice: 0.0, contextWindow: 1000),
          ModelPrice(modelId: 'p2', inputPrice: 0.4, outputPrice: 0.4, cacheReadPrice: 0.0, contextWindow: 2000),
        ],
      );

      final best = model.getBestPrice();
      expect(best.modelId, 'p2');
    });

    test('getBestPrice returns first when all same total', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 1.0, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096),
          ModelPrice(modelId: 'p2', inputPrice: 1.0, outputPrice: 1.0, cacheReadPrice: 0.0, contextWindow: 4096),
        ],
      );

      expect(model.getBestPrice().modelId, 'p1');
    });

    test('calculateCost with empty prices returns 0', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
      );

      expect(model.calculateCost(1000, 1000), 0.0);
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

    test('calculateCost computes correctly', () {
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

    test('equality based on provider and modelName', () {
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

    test('supports metadata', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        metadata: {'key': 'value', 'version': 1},
      );

      expect(model.metadata['key'], 'value');
      expect(model.metadata['version'], 1);
    });

    test('toString includes modelName and pricesFetched', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        pricesFetched: true,
      );

      expect(model.toString(), contains('test-model'));
      expect(model.toString(), contains('fetched:true'));
    });

    test('copyWith behavior', () {
      final model = DynamicModel(
        provider: 'openrouter',
        modelName: 'test-model',
        providerDisplayName: 'Test',
      );

      expect(model.provider, 'openrouter');
      expect(model.modelName, 'test-model');
    });
  });

  group('OpenRouterRequest', () {
    test('constructor with required fields', () {
      const request = OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'Hello'}],
      );

      expect(request.model, 'test-model');
      expect(request.messages.length, 1);
      expect(request.temperature, isNull);
      expect(request.maxTokens, isNull);
      expect(request.topP, isNull);
      expect(request.stream, isFalse);
    });

    test('constructor with all fields', () {
      const request = OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'Hello'}],
        temperature: 0.4,
        maxTokens: 256,
        topP: 0.9,
        stream: true,
        apiKey: 'secret-key',
        extraHeaderKey: 'x-api-key',
      );

      expect(request.model, 'test-model');
      expect(request.temperature, 0.4);
      expect(request.maxTokens, 256);
      expect(request.topP, 0.9);
      expect(request.stream, isTrue);
      expect(request.apiKey, 'secret-key');
      expect(request.extraHeaderKey, 'x-api-key');
    });

    test('toJson serializes all optional fields', () {
      const request = OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'Hello'}],
        temperature: 0.4,
        maxTokens: 256,
        topP: 0.9,
        stream: true,
      );

      final json = request.toJson();
      expect(json['model'], 'test-model');
      expect(json['messages'], [{'role': 'user', 'content': 'Hello'}]);
      expect(json['temperature'], 0.4);
      expect(json['max_tokens'], 256);
      expect(json['top_p'], 0.9);
      expect(json['stream'], isTrue);
    });

    test('toJson omits null optional fields', () {
      const request = OpenRouterRequest(
        model: 'test-model',
        messages: [],
      );

      final json = request.toJson();
      expect(json['temperature'], 0.7);
      expect(json.containsKey('max_tokens'), isFalse);
      expect(json.containsKey('top_p'), isFalse);
      expect(json['stream'], isFalse);
    });

    test('toString includes model and message count', () {
      const request = OpenRouterRequest(
        model: 'claude-3',
        messages: [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi'},
        ],
      );

      expect(request.toString(), contains('claude-3'));
      expect(request.toString(), contains('messages: 2'));
    });
  });

  group('OpenRouterResponse', () {
    test('fromJson parses full response correctly', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r1',
        'object': 'chat.completion',
        'created': 123456,
        'choices': [
          {'role': 'assistant', 'content': 'Answer'}
        ],
        'usage': {'prompt_tokens': 100, 'completion_tokens': 50, 'total_tokens': 150},
        'effective_duration_ms': 1234,
        'prompt_tokens_details': {'cached_tokens': 20},
      });

      expect(response.id, 'r1');
      expect(response.object, 'chat.completion');
      expect(response.created, 123456);
      expect(response.usage['prompt_tokens'], 100);
      expect(response.effectiveDurationMs, 1234);
      expect(response.promptTokensDetails['cached_tokens'], 20);
      expect(response.choices.length, 1);
    });

    test('fromJson handles minimal response with defaults', () {
      final response = OpenRouterResponse.fromJson({'id': 'r2'});

      expect(response.id, 'r2');
      expect(response.object, 'chat.completion');
      expect(response.created, 0);
      expect(response.choices, isEmpty);
      expect(response.usage, {});
      expect(response.effectiveDurationMs, 0);
      expect(response.promptTokensDetails, {});
    });

    test('fromJson handles null choices', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r3',
        'choices': null,
      });

      expect(response.choices, isEmpty);
      expect(response.getAssistantResponse(), isNull);
    });

    test('getAssistantResponse returns first choice', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r4',
        'choices': [
          {'role': 'assistant', 'content': 'First response'},
          {'role': 'assistant', 'content': 'Second response'},
        ],
      });

      final assistant = response.getAssistantResponse();
      expect(assistant, isNotNull);
      expect(assistant!.content, 'First response');
    });

    test('getAssistantResponse returns null for empty choices', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r5',
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

      expect(response.toString(), contains('choices: 2'));
      expect(response.toString(), contains('test-id-123'));
    });
  });

  group('Message', () {
    test('default constructor creates empty message', () {
      const message = Message();

      expect(message.role, '');
      expect(message.content, '');
      expect(message.reasoning, isNull);
      expect(message.tool, isNull);
      expect(message.index, isNull);
      expect(message.finish, isNull);
    });

    test('fromJson parses message with all fields', () {
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
    });

    test('fromJson handles null fields', () {
      final message = Message.fromJson({
        'role': null,
        'content': null,
        'reasoning': null,
        'tool': null,
        'index': null,
        'finish': null,
      });

      expect(message.role, 'unknown');
      expect(message.content, '');
      expect(message.reasoning, isNull);
    });

    test('toString includes role and content length', () {
      const message = Message(role: 'assistant', content: 'Test content');

      expect(message.toString(), contains('assistant'));
      expect(message.toString(), matches(RegExp(r'\d+ chars')));
    });
  });
}
