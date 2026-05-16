import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart' show LlmProvider;
import 'package:studyking/core/services/llm/llm_embeddings_service.dart';

void main() {
  group('EmbeddingService', () {
    group('constructor', () {
      test('stores apiKey', () {
        final service = EmbeddingService(apiKey: 'test-key');
        expect(service.apiKey, 'test-key');
      });
    });

    group('embed', () {
      test('returns embedding on successful response', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/embeddings');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'text-embedding-3-small');
          expect(body['input'], 'Hello world');
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': [0.1, 0.2, 0.3, 0.4, 0.5]}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: 'test-key',
          httpClient: mockClient,
        );
        final result = await service.embed(
          text: 'Hello world',
          modelId: 'text-embedding-3-small',
        );
        expect(result, [0.1, 0.2, 0.3, 0.4, 0.5]);
      });

      test('throws on API error', () async {
        final mockClient = MockClient((_) async {
          return http.Response('Server Error', 500);
        });

        final service = EmbeddingService(
          apiKey: 'key',
          httpClient: mockClient,
        );
        expect(
          () => service.embed(text: 'Hi', modelId: 'm'),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty embedding', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': []}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: 'key',
          httpClient: mockClient,
        );
        final result = await service.embed(text: 'Hi', modelId: 'm');
        expect(result, isEmpty);
      });
    });

    group('Ollama provider', () {
      test('sends request to localhost Ollama', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'localhost');
          expect(request.url.port, 11434);
          expect(request.url.path, '/api/embeddings');
          expect(request.headers.containsKey('Authorization'), isFalse);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'nomic-embed-text');
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': [1.0, 2.0, 3.0]}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: '',
          provider: LlmProvider.ollama,
          httpClient: mockClient,
        );
        final result = await service.embed(text: 'Test', modelId: 'nomic-embed-text');
        expect(result, [1.0, 2.0, 3.0]);
      });

      test('uses custom baseUrl for Ollama', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'my-ollama.local');
          expect(request.url.path, '/api/embeddings');
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': [0.5]}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: '',
          provider: LlmProvider.ollama,
          baseUrl: 'http://my-ollama.local',
          httpClient: mockClient,
        );
        final result = await service.embed(text: 'T', modelId: 'm');
        expect(result, [0.5]);
      });
    });

    group('OpenAI provider', () {
      test('sends request to OpenAI API', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'api.openai.com');
          expect(request.url.path, '/v1/embeddings');
          expect(request.headers['Authorization'], 'Bearer test-openai-key');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'text-embedding-ada-002');
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': [0.1, 0.2]}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: 'test-openai-key',
          provider: LlmProvider.openAI,
          httpClient: mockClient,
        );
        final result = await service.embed(text: 'Hello', modelId: 'text-embedding-ada-002');
        expect(result, [0.1, 0.2]);
      });

      test('uses custom baseUrl for OpenAI', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'my-openai.local');
          expect(request.url.path, '/v1/embeddings');
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': [0.9]}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: 'key',
          provider: LlmProvider.openAI,
          baseUrl: 'https://my-openai.local/v1',
          httpClient: mockClient,
        );
        final result = await service.embed(text: 'T', modelId: 'm');
        expect(result, [0.9]);
      });
    });

    group('OpenRouter with custom baseUrl', () {
      test('uses custom baseUrl for OpenRouter', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'custom-openrouter.local');
          expect(request.url.path, '/api/v1/embeddings');
          expect(request.headers['HTTP-Referer'], 'StudyKing');
          return http.Response(
            jsonEncode({
              'data': [
                {'embedding': [0.3, 0.6, 0.9]}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final service = EmbeddingService(
          apiKey: 'key',
          provider: LlmProvider.openRouter,
          baseUrl: 'https://custom-openrouter.local/api/v1',
          httpClient: mockClient,
        );
        final result = await service.embed(text: 'Hi', modelId: 'm');
        expect(result, [0.3, 0.6, 0.9]);
      });
    });
  });
}
