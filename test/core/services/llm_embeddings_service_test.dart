import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  });
}
