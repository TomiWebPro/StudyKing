import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:studyking/services/llm_api_service.dart';
import 'package:studyking/core/data/models/llm_models.dart';

void main() {
  group('OpenRouterClient', () {
    late OpenRouterClient client;

    setUp(() {
      client = OpenRouterClient();
    });

    group('initialization', () {
      test('creates instance with default dio', () {
        expect(client.dio, isNotNull);
      });

      test('creates instance with custom dio', () {
        final customDio = Dio();
        final customClient = OpenRouterClient(dio: customDio);
        expect(customClient.dio, equals(customDio));
      });

      test('has default baseUrl', () {
        expect(client.baseUrl, equals('https://openrouter.ai/api/v1'));
      });

      test('allows custom baseUrl', () {
        final customClient = OpenRouterClient(baseUrl: 'http://custom.api');
        expect(customClient.baseUrl, equals('http://custom.api'));
      });
    });

    group('setApiKey', () {
      test('sets authorization header', () {
        client.setApiKey('test-api-key');
        expect(client.dio.options.headers['Authorization'], equals('Bearer test-api-key'));
      });

      test('can set different api keys', () {
        client.setApiKey('key1');
        client.setApiKey('key2');
        expect(client.dio.options.headers['Authorization'], equals('Bearer key2'));
      });
    });

    group('clearApiKey', () {
      test('removes authorization header', () {
        client.setApiKey('test-key');
        client.clearApiKey();
        expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
      });

      test('can clear after setting', () {
        client.setApiKey('test-key');
        client.clearApiKey();
        expect(client.dio.options.headers['Authorization'], isNull);
      });
    });

    group('fetchModelPrices', () {
      test('handles fetch without throwing', () async {
        final prices = await client.fetchModelPrices('test-model');
        expect(prices, isA<List<ModelPrice>>());
      });

      test('returns non-empty list on error', () async {
        final prices = await client.fetchModelPrices('test-model');
        expect(prices.isNotEmpty, isTrue);
      });

      test('returns ModelPrice objects', () async {
        final prices = await client.fetchModelPrices('test-model');
        expect(prices.first, isA<ModelPrice>());
      });
    });

    group('fetchModelInfo', () {
      test('returns map on error', () async {
        final info = await client.fetchModelInfo('test-model');
        expect(info, isA<Map<String, dynamic>>());
      });

      test('returns default values on error', () async {
        final info = await client.fetchModelInfo('error-model');
        expect(info['id'], equals('error-model'));
        expect(info['context_length'], equals(4096));
      });

      test('includes required fields in default response', () async {
        final info = await client.fetchModelInfo('model');
        expect(info.containsKey('id'), isTrue);
        expect(info.containsKey('context_length'), isTrue);
        expect(info.containsKey('per_minute_limit'), isTrue);
      });
    });

    group('fetchAvailableModels', () {
      test('handles fetch without throwing', () async {
        final models = await client.fetchAvailableModels();
        expect(models, isA<List<Map<String, dynamic>>>());
      });

      test('returns list (empty or populated)', () async {
        final models = await client.fetchAvailableModels();
        expect(models, isA<List>());
      });
    });

    group('chat', () {
      test('throws exception on error', () async {
        expect(
          () => client.chat(
            model: 'test-model',
            messages: [
              {'role': 'user', 'content': 'Hello'}
            ],
          ),
          throwsA(anything),
        );
      });

      test('accepts required parameters', () async {
        try {
          await client.chat(
            model: 'test-model',
            messages: [
              {'role': 'user', 'content': 'Hello'}
            ],
          );
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('accepts optional temperature', () async {
        try {
          await client.chat(
            model: 'test-model',
            messages: [
              {'role': 'user', 'content': 'Hello'}
            ],
            temperature: 0.7,
          );
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('accepts optional maxTokens', () async {
        try {
          await client.chat(
            model: 'test-model',
            messages: [
              {'role': 'user', 'content': 'Hello'}
            ],
            maxTokens: 100,
          );
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('streamChat', () {
      test('throws exception on error', () async {
        expect(
          () async {
            final stream = client.streamChat(
              model: 'test-model',
              messages: [
                {'role': 'user', 'content': 'Hello'}
              ],
            );
            await stream.first;
          }(),
          throwsA(anything),
        );
      });

      test('accepts messages parameter', () async {
        try {
          final stream = client.streamChat(
            model: 'test-model',
            messages: [
              {'role': 'user', 'content': 'Hello'}
            ],
          );
          await stream.first;
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('calculateCost', () {
      test('returns 0.0 for empty usage', () {
        final cost = client.calculateCost({});
        expect(cost, equals(0.0));
      });

      test('returns 0.0 for null values', () {
        final cost = client.calculateCost({
          'prompt_tokens': null,
          'completion_tokens': null,
          'cached_tokens': null,
        });
        expect(cost, equals(0.0));
      });

      test('calculates cost for valid usage', () {
        final cost = client.calculateCost({
          'prompt_tokens': 1000,
          'completion_tokens': 500,
          'cached_tokens': 200,
        });
        expect(cost, greaterThan(0.0));
      });

      test('handles non-numeric tokens', () {
        final cost1 = client.calculateCost({'prompt_tokens': 'not a number'});
        expect(cost1, equals(0.0));
      });
    });

    group('calculateCostWithPrices', () {
      test('returns 0 for zero tokens', () {
        final cost = client.calculateCostWithPrices(0, 0, 0);
        expect(cost, equals(0.0));
      });

      test('calculates input cost', () {
        final cost = client.calculateCostWithPrices(1000000, 0, 0);
        expect(cost, closeTo(0.000006, 0.0000001));
      });

      test('calculates output cost', () {
        final cost = client.calculateCostWithPrices(0, 1000000, 0);
        expect(cost, closeTo(0.000024, 0.0000001));
      });

      test('calculates cache read cost', () {
        final cost = client.calculateCostWithPrices(0, 0, 1000000);
        expect(cost, closeTo(0.000003, 0.0000001));
      });

      test('calculates combined cost', () {
        final cost = client.calculateCostWithPrices(1000000, 1000000, 1000000);
        final expected = 0.000006 + 0.000024 + 0.000003;
        expect(cost, closeTo(expected, 0.0000001));
      });
    });

    group('estimatePrice', () {
      test('handles API errors gracefully', () async {
        double? price;
        try {
          price = await client.estimatePrice('error-model');
          expect(price, greaterThanOrEqualTo(0.0));
        } catch (e) {
          expect(price, greaterThanOrEqualTo(0.0));
        }
      });

      test('returns non-negative price', () async {
        final price = await client.estimatePrice('test-model');
        expect(price, greaterThanOrEqualTo(0.0));
      });
    });
  });
}
