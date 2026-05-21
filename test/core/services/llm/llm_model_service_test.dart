import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/services/llm/llm_chat_service.dart' show LlmProvider;
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

    group('fromOllama', () {
      test('parses model name correctly', () {
        final data = {'name': 'llama3.2:latest'};
        final model = AiModel.fromOllama(data);
        expect(model.id, 'llama3.2:latest');
        expect(model.name, 'llama3.2 latest');
        expect(model.provider, 'Ollama');
        expect(model.contextLength, isNull);
        expect(model.pricing, isNull);
      });

      test('handles missing name field', () {
        final data = <String, dynamic>{};
        final model = AiModel.fromOllama(data);
        expect(model.id, 'unknown');
        expect(model.name, 'unknown');
        expect(model.provider, 'Ollama');
      });

      test('strips colons and hyphens from name', () {
        final data = {'name': 'mistral-7b:instruct-q4'};
        final model = AiModel.fromOllama(data);
        expect(model.name, 'mistral 7b instruct q4');
        expect(model.provider, 'Ollama');
      });
    });

    group('fromOpenAI', () {
      test('parses model with id', () {
        final data = {'id': 'gpt-4o'};
        final model = AiModel.fromOpenAI(data);
        expect(model.id, 'gpt-4o');
        expect(model.name, 'gpt 4o');
        expect(model.provider, 'OpenAI');
        expect(model.contextLength, isNull);
        expect(model.pricing, isNull);
      });

      test('handles underscores in id', () {
        final data = {'id': 'text_embedding_3_large'};
        final model = AiModel.fromOpenAI(data);
        expect(model.name, 'text embedding 3 large');
      });

      test('handles missing id field', () {
        final data = <String, dynamic>{};
        final model = AiModel.fromOpenAI(data);
        expect(model.id, 'unknown');
        expect(model.name, 'unknown');
        expect(model.provider, 'OpenAI');
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
        expect(model.name, equals('providermodel v2.0'));
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
        final result = await service.fetchAvailableModels();
        expect(result.data!.length, 2);
        expect(result.data![0].id, 'model-a');
        expect(result.data![1].id, 'model-b');
      });

      test('returns empty list on API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Not Found', 404);

        final service = ModelListingService(apiKey: 'key', httpClient: client);
        final result = await service.fetchAvailableModels();
        expect(result.data, isEmpty);
      });

      test('returns empty list on network error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Connection failed');

        final service = ModelListingService(apiKey: 'key', httpClient: client);
        final result = await service.fetchAvailableModels();
        expect(result.data, isEmpty);
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

    group('fetchAvailableModels with Ollama provider', () {
      test('returns Ollama models on success', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.path, '/api/tags');
          expect(request.headers.containsKey('Authorization'), isFalse);
          return http.Response(
            jsonEncode({
              'models': [
                {'name': 'llama3.2'},
                {'name': 'mistral:7b'},
              ],
            }),
            200,
          );
        };

        final service = ModelListingService(
          apiKey: 'key',
          httpClient: client,
          provider: LlmProvider.ollama,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data!.length, 2);
        expect(result.data![0].id, 'llama3.2');
        expect(result.data![0].provider, 'Ollama');
        expect(result.data![1].id, 'mistral:7b');
        expect(result.data![1].provider, 'Ollama');
      });

      test('returns empty list on Ollama API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Error', 500);

        final service = ModelListingService(
          apiKey: 'key',
          httpClient: client,
          provider: LlmProvider.ollama,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data, isEmpty);
      });
    });

    group('fetchAvailableModels with OpenAI provider', () {
      test('returns OpenAI models on success', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.path, '/v1/models');
          expect(request.headers['Authorization'], 'Bearer test_key');
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'gpt-4o'},
                {'id': 'gpt-4o-mini'},
              ],
            }),
            200,
          );
        };

        final service = ModelListingService(
          apiKey: 'test_key',
          httpClient: client,
          provider: LlmProvider.openAI,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data!.length, 2);
        expect(result.data![0].id, 'gpt-4o');
        expect(result.data![0].provider, 'OpenAI');
        expect(result.data![1].id, 'gpt-4o-mini');
        expect(result.data![1].provider, 'OpenAI');
      });

      test('returns empty list on OpenAI API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Unauthorized', 401);

        final service = ModelListingService(
          apiKey: 'key',
          httpClient: client,
          provider: LlmProvider.openAI,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data, isEmpty);
      });
    });

    group('fetchAvailableModels with explicit provider parameter', () {
      test('uses provider parameter over constructor provider', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.path, '/api/tags');
          return http.Response(
            jsonEncode({'models': [{'name': 'model'}]}),
            200,
          );
        };

        final service = ModelListingService(
          apiKey: 'key',
          httpClient: client,
          provider: LlmProvider.ollama,
        );
        final result = await service.fetchAvailableModels(provider: LlmProvider.ollama);
        expect(result.data!.length, 1);
      });
    });

    group('_effectiveBaseUrl behavior', () {
      test('uses custom baseUrl for Ollama when provided', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'custom.openrouter.local');
          expect(request.url.path, '/api/tags');
          return http.Response(
            jsonEncode({'models': [{'name': 'm'}]}),
            200,
          );
        };

        final service = ModelListingService(
          apiKey: 'key',
          baseUrl: 'https://custom.openrouter.local',
          httpClient: client,
          provider: LlmProvider.ollama,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data!.length, 1);
      });

      test('uses Ollama default baseUrl with Ollama provider', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'localhost');
          expect(request.url.port, 11434);
          return http.Response(
            jsonEncode({'models': [{'name': 'm'}]}),
            200,
          );
        };

        final service = ModelListingService(
          apiKey: 'key',
          httpClient: client,
          provider: LlmProvider.ollama,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data!.length, 1);
      });

      test('uses OpenAI default baseUrl with OpenAI provider', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'api.openai.com');
          return http.Response(
            jsonEncode({'data': [{'id': 'gpt-4'}]}),
            200,
          );
        };

        final service = ModelListingService(
          apiKey: 'key',
          httpClient: client,
          provider: LlmProvider.openAI,
        );
        final result = await service.fetchAvailableModels();
        expect(result.data!.length, 1);
      });
    });
  });
}
