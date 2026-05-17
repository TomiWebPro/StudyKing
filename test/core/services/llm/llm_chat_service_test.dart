import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/services/llm/llm_chat_service.dart';

class _FakeHttpClient extends http.BaseClient {
  int statusCode = 200;
  Map<String, dynamic> responseBody = {'choices': [{'message': {'content': 'Test response'}}]};
  int callCount = 0;
  String? lastUrl;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    lastUrl = request.url.toString();
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }
    if (statusCode != 200) {
      return http.StreamedResponse(
        Stream.fromIterable([utf8.encode(jsonEncode(responseBody))]),
        statusCode,
      );
    }
    final responseContent = utf8.encode(jsonEncode(responseBody));
    return http.StreamedResponse(
      Stream.fromIterable([responseContent]),
      200,
    );
  }
}

void main() {
  group('LlmService', () {
    test('defaultSystemPrompt is defined', () {
      expect(LlmService.defaultSystemPrompt, isNotEmpty);
    });

    test('chat with empty API key returns empty string', () async {
      final config = const LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: '',
      );
      final client = _FakeHttpClient();
      final service = LlmService(config: config, httpClient: client);

      final result = await service.chat(
        message: 'Hello',
        modelId: 'test-model',
      );

      expect(result, '');
      expect(client.callCount, 0);
    });

    test('chatStream with empty API key returns empty stream', () async {
      final config = const LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: '',
      );
      final client = _FakeHttpClient();
      final service = LlmService(config: config, httpClient: client);

      final chunks = await service.chatStream(
        message: 'Hello',
        modelId: 'test-model',
      ).toList();

      expect(chunks, isEmpty);
      expect(client.callCount, 0);
    });

    test('chat with OpenRouter calls API and returns content', () async {
      final config = const LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'test-key',
      );
      final client = _FakeHttpClient();
      client.responseBody = {
        'choices': [{'message': {'content': 'Hello from AI'}}],
        'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
      };
      final service = LlmService(config: config, httpClient: client);

      final result = await service.chat(
        message: 'Hi',
        modelId: 'openai/gpt-4o',
      );

      expect(result, 'Hello from AI');
      expect(client.callCount, 1);
      expect(client.lastUrl, contains('/chat/completions'));
      expect(client.lastHeaders, containsPair('Authorization', 'Bearer test-key'));
    });

    test('chat throws on non-200 status code', () async {
      final config = const LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'test-key',
      );
      final client = _FakeHttpClient();
      client.statusCode = 400;
      client.responseBody = {'error': 'Bad request'};
      final service = LlmService(config: config, httpClient: client);

      expect(
        () => service.chat(message: 'Hi', modelId: 'test-model'),
        throwsA(isA<Exception>()),
      );
    });

    test('uses OpenAI provider correctly', () async {
      final config = const LlmConfiguration(
        provider: LlmProvider.openAI,
        apiKey: 'sk-test',
      );
      final client = _FakeHttpClient();
      final service = LlmService(config: config, httpClient: client);

      await service.chat(message: 'Hello', modelId: 'gpt-4');

      expect(client.callCount, 1);
      expect(client.lastHeaders, containsPair('Authorization', 'Bearer sk-test'));
    });
  });
}
