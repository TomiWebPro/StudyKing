import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/llm_models.dart';

void main() {
  group('DynamicModel.getBestPrice', () {
    test('returns zero-price model when prices list is empty', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [],
      );
      final best = model.getBestPrice();
      expect(best.inputPrice, 0.0);
      expect(best.outputPrice, 0.0);
      expect(best.cacheReadPrice, 0.0);
      expect(best.contextWindow, 4096);
    });

    test('returns the only price when single price exists', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [
          const ModelPrice(
            modelId: 'only',
            inputPrice: 2.0,
            outputPrice: 3.0,
            cacheReadPrice: 0.1,
            contextWindow: 4096,
          ),
        ],
      );
      final best = model.getBestPrice();
      expect(best.inputPrice, 2.0);
      expect(best.outputPrice, 3.0);
    });

    test('returns cheapest price from multiple', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [
          const ModelPrice(
            modelId: 'expensive',
            inputPrice: 5.0,
            outputPrice: 10.0,
            cacheReadPrice: 0.5,
            contextWindow: 4096,
          ),
          const ModelPrice(
            modelId: 'cheap',
            inputPrice: 1.0,
            outputPrice: 2.0,
            cacheReadPrice: 0.1,
            contextWindow: 4096,
          ),
          const ModelPrice(
            modelId: 'mid',
            inputPrice: 3.0,
            outputPrice: 4.0,
            cacheReadPrice: 0.2,
            contextWindow: 4096,
          ),
        ],
      );
      final best = model.getBestPrice();
      expect(best.modelId, 'cheap');
    });

    test('returns first price when all have same total', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [
          const ModelPrice(
            modelId: 'first',
            inputPrice: 1.0,
            outputPrice: 2.0,
            cacheReadPrice: 0.1,
            contextWindow: 4096,
          ),
          const ModelPrice(
            modelId: 'second',
            inputPrice: 1.0,
            outputPrice: 2.0,
            cacheReadPrice: 0.2,
            contextWindow: 4096,
          ),
        ],
      );
      final best = model.getBestPrice();
      expect(best.modelId, 'first');
    });
  });

  group('DynamicModel.calculateCost', () {
    test('returns 0 for zero tokens', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [
          const ModelPrice(
            modelId: 'm',
            inputPrice: 2.0,
            outputPrice: 3.0,
            cacheReadPrice: 0.1,
            contextWindow: 4096,
          ),
        ],
      );
      expect(model.calculateCost(0, 0), 0.0);
    });

    test('returns 0 when prices list is empty', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [],
      );
      expect(model.calculateCost(1000, 500), 0.0);
    });

    test('calculates cost correctly for non-zero tokens', () {
      final model = DynamicModel(
        provider: 'test',
        modelName: 'test-model',
        providerDisplayName: 'Test',
        prices: [
          const ModelPrice(
            modelId: 'm',
            inputPrice: 1.0,
            outputPrice: 2.0,
            cacheReadPrice: 0.0,
            contextWindow: 4096,
          ),
        ],
      );
      final cost = model.calculateCost(1000, 500);
      expect(cost, ((1000 * 1.0) + (500 * 2.0)) / 1000000);
    });
  });

  group('OpenRouterRequest.toJson', () {
    test('includes temperature default when null', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
      );
      final json = request.toJson();
      expect(json['temperature'], 0.7);
      expect(json['stream'], false);
    });

    test('includes maxTokens when not null', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
        maxTokens: 2048,
      );
      final json = request.toJson();
      expect(json['max_tokens'], 2048);
    });

    test('omits maxTokens when null', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
      );
      final json = request.toJson();
      expect(json.containsKey('max_tokens'), isFalse);
    });

    test('includes topP when not null', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
        topP: 0.9,
      );
      final json = request.toJson();
      expect(json['top_p'], 0.9);
    });

    test('omits topP when null', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
      );
      final json = request.toJson();
      expect(json.containsKey('top_p'), isFalse);
    });

    test('omits maxTokens and topP when both null', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
      );
      final json = request.toJson();
      expect(json.containsKey('max_tokens'), isFalse);
      expect(json.containsKey('top_p'), isFalse);
    });

    test('uses custom temperature', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
        temperature: 1.5,
      );
      final json = request.toJson();
      expect(json['temperature'], 1.5);
    });

    test('toString returns readable format', () {
      final request = const OpenRouterRequest(
        model: 'test-model',
        messages: [{'role': 'user', 'content': 'hello'}],
      );
      expect(request.toString(), contains('test-model'));
      expect(request.toString(), contains('messages: 1'));
    });
  });
}
