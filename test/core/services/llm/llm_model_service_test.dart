import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/services/llm/llm_model_service.dart';

class _FakeHttpClient extends http.BaseClient {
  Future<http.Response> Function(http.Request)? handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request is http.Request
        ? request
        : http.Request(request.method, request.url)
          ..headers.addAll(request.headers);
    final response = await handler!(req);
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode(response.body)]),
      response.statusCode,
      contentLength: response.contentLength,
      headers: response.headers,
    );
  }
}

void main() {
  group('AiModel', () {
    group('constructor', () {
      test('creates with required fields', () {
        final model = AiModel(id: 'test-model', name: 'Test Model', provider: 'TestProvider');
        expect(model.id, 'test-model');
        expect(model.name, 'Test Model');
        expect(model.provider, 'TestProvider');
        expect(model.contextLength, isNull);
        expect(model.pricing, isNull);
      });

      test('creates with optional fields', () {
        final model = AiModel(
          id: 'test',
          name: 'Test',
          provider: 'P',
          contextLength: '8192',
          pricing: '0.01',
        );
        expect(model.contextLength, '8192');
        expect(model.pricing, '0.01');
      });
    });

    group('fromOpenRouter', () {
      test('parses complete data with all fields', () {
        final data = {
          'id': 'openrouter/test-model',
          'name': 'Test Model',
          'context_length': 8192,
          'pricing': {'prompt': '0.01'},
        };
        final model = AiModel.fromOpenRouter(data);
        expect(model.id, 'openrouter/test-model');
        expect(model.name, 'Test Model');
        expect(model.contextLength, '8192');
        expect(model.pricing, '0.01');
      });

      test('derives name from id when name is null', () {
        final data = {'id': 'openrouter/gpt-4'};
        final model = AiModel.fromOpenRouter(data);
        expect(model.name, 'gpt 4');
      });

      test('derives name from id with colons and hyphens', () {
        final data = {'id': 'openrouter/claude-3:opus'};
        final model = AiModel.fromOpenRouter(data);
        expect(model.name, 'claude 3opus');
      });

      test('uses Unknown provider when no provider data', () {
        final data = {'id': 'test-model', 'name': 'Test'};
        final model = AiModel.fromOpenRouter(data);
        expect(model.provider, 'Unknown');
      });

      test('extracts provider from providers map', () {
        final data = {
          'id': 'test-id',
          'name': 'Test',
          'providers': {
            'some-key': {'id': 'CustomProvider'},
          },
        };
        final model = AiModel.fromOpenRouter(data);
        expect(model.provider, 'CustomProvider');
      });

      test('uses Unknown when providers map is empty', () {
        final data = {'id': 'test-id', 'name': 'Test', 'providers': <String, dynamic>{}};
        final model = AiModel.fromOpenRouter(data);
        expect(model.provider, 'Unknown');
      });

      test('handles null providers key in map', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
          'providers': null,
        };
        final model = AiModel.fromOpenRouter(data);
        expect(model.provider, equals('Unknown'));
      });

      test('handles empty provider map type', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
          'providers': <String, String>{},
        };
        final model = AiModel.fromOpenRouter(data);
        expect(model.provider, equals('Unknown'));
      });

      test('sets default id to unknown when id is null', () {
        final data = <String, dynamic>{};
        final model = AiModel.fromOpenRouter(data);
        expect(model.id, 'unknown');
      });

      test('handles null context_length and pricing', () {
        final data = {'id': 'm', 'name': 'M'};
        final model = AiModel.fromOpenRouter(data);
        expect(model.contextLength, isNull);
        expect(model.pricing, isNull);
      });
    });

    group('fromId', () {
      test('creates from simple id', () {
        final model = AiModel.fromId('gpt-4');
        expect(model.id, 'gpt-4');
        expect(model.name, 'gpt 4');
        expect(model.provider, 'Unknown');
      });

      test('creates from provider/id format', () {
        final model = AiModel.fromId('openrouter/gpt-4-turbo');
        expect(model.id, 'openrouter/gpt-4-turbo');
        expect(model.name, 'gpt 4 turbo');
      });

      test('handles id with special characters', () {
        final model = AiModel.fromId('provider:model-v2.0');
        expect(model.name, equals('provider model v2 0'));
      });
    });

    group('equality', () {
      test('equal models are equal', () {
        final a = AiModel(id: 'm1', name: 'M1', provider: 'P');
        final b = AiModel(id: 'm1', name: 'M1', provider: 'P');
        expect(a, equals(b));
      });

      test('different models are not equal', () {
        final a = AiModel(id: 'm1', name: 'M1', provider: 'P');
        final b = AiModel(id: 'm2', name: 'M2', provider: 'P');
        expect(a, isNot(equals(b)));
      });

      test('hashCode consistent with equality', () {
        final a = AiModel(id: 'm1', name: 'M1', provider: 'P');
        final b = AiModel(id: 'm1', name: 'M1', provider: 'P');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        final model = AiModel(id: 'test-id', name: 'Test Name', provider: 'TestProv');
        expect(model.toString(), 'AiModel(id: test-id, name: Test Name, provider: TestProv)');
      });
    });
  });

  group('ModelListingService', () {
    group('fetchAvailableModels', () {
      test('returns list of models on success', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'GET');
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'model-a', 'name': 'Model A'},
                {'id': 'model-b', 'name': 'Model B'},
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final service = ModelListingService(apiKey: 'test_key', httpClient: client);
        final models = await service.fetchAvailableModels();
        expect(models.length, 2);
        expect(models[0].id, 'model-a');
        expect(models[1].id, 'model-b');
      });

      test('returns empty list on API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Not Found', 404);

        final service = ModelListingService(apiKey: 'key', httpClient: client);
        final models = await service.fetchAvailableModels();
        expect(models, isEmpty);
      });

      test('returns empty list on network error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Connection failed');

        final service = ModelListingService(apiKey: 'key', httpClient: client);
        final models = await service.fetchAvailableModels();
        expect(models, isEmpty);
      });
    });

    group('getModelById', () {
      test('finds model by id in list', () {
        final models = [
          AiModel(id: 'model-1', name: 'Model 1', provider: 'P'),
          AiModel(id: 'model-2', name: 'Model 2', provider: 'P'),
        ];
        final service = ModelListingService(apiKey: 'key');
        final result = service.getModelById('model-1', models);
        expect(result?.id, 'model-1');
        expect(result?.name, 'Model 1');
      });

      test('returns fallback AiModel when id not found', () {
        final models = [AiModel(id: 'model-1', name: 'Model 1', provider: 'P')];
        final service = ModelListingService(apiKey: 'key');
        final result = service.getModelById('unknown-model', models);
        expect(result?.id, 'unknown-model');
        expect(result?.name, 'unknown model');
      });

      test('handles empty list', () {
        final service = ModelListingService(apiKey: 'key');
        final result = service.getModelById('model1', []);
        expect(result, isNotNull);
        expect(result!.id, equals('model1'));
      });

      test('returns first match when duplicate ids', () {
        final models = [
          AiModel(id: 'model1', name: 'Model 1', provider: 'Provider A'),
          AiModel(id: 'model1', name: 'Model 1 Duplicate', provider: 'Provider B'),
        ];
        final service = ModelListingService(apiKey: 'key');
        final result = service.getModelById('model1', models);
        expect(result, isNotNull);
      });
    });
  });
}
