import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

class _FakeHttpClient extends http.BaseClient {
  int statusCode = 200;
  Map<String, dynamic> responseBody = {
    'choices': [{'message': {'content': 'Test response'}}]
  };
  int callCount = 0;
  String? lastUrl;
  Map<String, String>? lastHeaders;
  String? lastBody;

  Future<http.Response> Function(http.Request)? handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    lastUrl = request.url.toString();
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }

    if (handler != null) {
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

    if (statusCode != 200) {
      return http.StreamedResponse(
        Stream.fromIterable([utf8.encode(jsonEncode(responseBody))]),
        statusCode,
      );
    }
    final responseContent = utf8.encode(jsonEncode(responseBody));
    return http.StreamedResponse(
      Stream.fromIterable([responseContent]),
      statusCode,
    );
  }
}

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('llm_chat_test_').path;
    Hive.init(hivePath);
  });

  group('LlmConfiguration', () {
    test('creates with required fields', () {
      const config = LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'test_key',
      );
      expect(config.provider, LlmProvider.openRouter);
      expect(config.apiKey, 'test_key');
      expect(config.baseUrl, '');
      expect(config.onTokenUsage, isNull);
    });

    test('creates with custom baseUrl', () {
      const config = LlmConfiguration(
        provider: LlmProvider.ollama,
        apiKey: 'test_key',
        baseUrl: 'http://localhost:11434',
      );
      expect(config.baseUrl, 'http://localhost:11434');
    });

    test('stores onTokenUsage callback', () {
      int? capturedInput;
      int? capturedOutput;
      String? capturedModel;
      void onUsage(int input, int output, String model) {
        capturedInput = input;
        capturedOutput = output;
        capturedModel = model;
      }

      final config = LlmConfiguration(
        provider: LlmProvider.openAI,
        apiKey: 'key',
        onTokenUsage: onUsage,
      );
      config.onTokenUsage!(100, 200, 'gpt-4');
      expect(capturedInput, 100);
      expect(capturedOutput, 200);
      expect(capturedModel, 'gpt-4');
    });
  });

  group('LlmProvider', () {
    test('has all expected values', () {
      expect(LlmProvider.values, [
        LlmProvider.openRouter,
        LlmProvider.ollama,
        LlmProvider.openAI,
      ]);
    });
  });

  group('LlmService', () {
    test('defaultSystemPrompt is defined', () {
      expect(LlmService.defaultSystemPromptForLocale('en'), isNotEmpty);
    });

    test('chat with empty API key returns failure', () async {
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

      expect(result.isFailure, isTrue);
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

      expect(chunks.length, 1);
      expect(chunks[0], contains('API key not configured'));
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

      expect(result.data, 'Hello from AI');
      expect(client.callCount, 1);
      expect(client.lastUrl, contains('/chat/completions'));
      expect(client.lastHeaders, containsPair('Authorization', 'Bearer test-key'));
    });

    test('chat returns failure on non-200 status code', () async {
      final config = const LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'test-key',
      );
      final client = _FakeHttpClient();
      client.statusCode = 400;
      client.responseBody = {'error': 'Bad request'};
      final service = LlmService(config: config, httpClient: client);

      final result = await service.chat(message: 'Hi', modelId: 'test-model');
      expect(result.isFailure, isTrue);
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

    group('chat', () {
      test('returns failure when apiKey is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);
        final result = await service.chat(
          message: 'Hello',
          modelId: 'test-model',
        );
        expect(result.isFailure, isTrue);
      });

      test('calls OpenRouter provider successfully', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/chat/completions');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'openrouter-model');
          expect(body['messages'], isA<List>());
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OpenRouter response'}}
              ],
              'usage': {'prompt_tokens': 10, 'completion_tokens': 20},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test_key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Test message',
          modelId: 'openrouter-model',
        );
        expect(result.data, 'OpenRouter response');
      });

      test('calls Ollama provider successfully', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/chat');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'ollama-model');
          return http.Response(
            jsonEncode({
              'message': {'content': 'Ollama response'}
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'ollama-model',
        );
        expect(result.data, 'Ollama response');
      });

      test('calls Ollama with custom baseUrl', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'my-ollama.local');
          expect(request.url.port, 8080);
          return http.Response(
            jsonEncode({
              'message': {'content': 'Custom Ollama'}
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
          baseUrl: 'http://my-ollama.local:8080',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'model',
        );
        expect(result.data, 'Custom Ollama');
      });

      test('calls OpenAI provider successfully', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'POST');
          expect(request.url.host, 'api.openai.com');
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OpenAI response'}}
              ],
              'usage': {'prompt_tokens': 5, 'completion_tokens': 10},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'openai_key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Hello',
          modelId: 'gpt-4',
        );
        expect(result.data, 'OpenAI response');
      });

      test('calls OpenAI with custom baseUrl', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'my-openai.local');
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'Custom OpenAI'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
          baseUrl: 'https://my-openai.local/v1',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'gpt-4',
        );
        expect(result.data, 'Custom OpenAI');
      });

      test('returns failure on OpenRouter API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Not Found', 404);

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(message: 'Hi', modelId: 'm');
        expect(result.isFailure, isTrue);
      });

      test('returns failure on Ollama API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Server Error', 500);

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(message: 'Hi', modelId: 'm');
        expect(result.isFailure, isTrue);
      });

      test('returns failure on OpenAI API error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Unauthorized', 401);

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(message: 'Hi', modelId: 'gpt-4');
        expect(result.isFailure, isTrue);
      });

      test('uses ConversationMemory history', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 3);
          expect(messages[0]['role'], 'system');
          expect(messages[1]['role'], 'user');
          expect(messages[2]['role'], 'user');
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'With memory'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous message');
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'New message',
          modelId: 'm',
          memory: memory,
        );
        expect(result.data, 'With memory');
      });

      test('uses history list', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 3);
          expect(messages[0]['role'], 'system');
          expect(messages[1]['role'], 'user');
          expect(messages[1]['content'], 'User msg');
          expect(messages[2]['role'], 'user');
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'From history'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'User msg',
          modelId: 'm',
          history: [{'role': 'user', 'content': 'User msg'}],
        );
        expect(result.data, 'From history');
      });

      test('uses custom system prompt', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages[0]['content'], 'Custom prompt');
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'Custom response'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'm',
          systemPrompt: 'Custom prompt',
        );
        expect(result.data, 'Custom response');
      });
    });

    group('chatStream', () {
      test('returns empty stream when apiKey is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);
        final stream = service.chatStream(
          message: 'Hello',
          modelId: 'm',
        );
        await expectLater(
          stream,
          emits('API key not configured. Please set up an API key in Settings to use AI features.'),
        );
      });
    });

    group('task manager integration', () {
      test('creates and starts task on chat', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OK'}}
              ],
              'usage': {'prompt_tokens': 5, 'completion_tokens': 10},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final taskManager = LlmTaskManager();
        await taskManager.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          taskManager: taskManager,
        );

        await service.chat(message: 'Hi', modelId: 'm', feature: 'test-feature');
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.feature, 'test-feature');
      });

      test('marks task as failed on error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Error', 500);

        final taskManager = LlmTaskManager();
        await taskManager.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          taskManager: taskManager,
        );

        final result = await service.chat(message: 'Hi', modelId: 'm');
        expect(result.isFailure, isTrue);
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.status, LlmTaskStatus.failed);
      });
    });

    group('usage meter integration', () {
      test('records usage on successful chat', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OK'}}
              ],
              'usage': {'prompt_tokens': 10, 'completion_tokens': 20},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final usageMeter = LlmUsageMeter();
        await usageMeter.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          usageMeter: usageMeter,
        );

        await service.chat(
          message: 'Hi',
          modelId: 'gpt-4',
          feature: 'test',
        );
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.inputTokens, 10);
        expect(usageMeter.getRecords().first.outputTokens, 20);
      });
    });

    group('token usage callback (onTokenUsage)', () {
      test('calls onTokenUsage when usage data is present', () async {
        int? capturedInput;
        int? capturedOutput;
        String? capturedModel;

        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OK'}}
              ],
              'usage': {'prompt_tokens': 15, 'completion_tokens': 25},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          onTokenUsage: (input, output, model) {
            capturedInput = input;
            capturedOutput = output;
            capturedModel = model;
          },
        );
        final service = LlmService(config: config, httpClient: client);
        await service.chat(message: 'Hi', modelId: 'claude-3');

        expect(capturedInput, 15);
        expect(capturedOutput, 25);
        expect(capturedModel, 'claude-3');
      });
    });

    group('chatStream with streaming data', () {
      test('streams from OpenRouter provider', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'POST');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Hello"}}]})}\n'
            'data: ${jsonEncode({"choices": [{"delta": {"content": " world"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsInOrder(['Hello', ' world']));
      });

      test('streams from Ollama provider', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'POST');
          return http.Response(
            '${jsonEncode({"message": {"content": "Hello"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": " world"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsInOrder(['Hello', ' world']));
      });

      test('streams from OpenAI provider', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.method, 'POST');
          expect(request.url.host, 'api.openai.com');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Hello"}}]})}\n'
            'data: ${jsonEncode({"choices": [{"delta": {"content": " world"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsInOrder(['Hello', ' world']));
      });

      test('streams with ConversationMemory', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 3);
          expect(messages[1]['role'], 'user');
          expect(messages[1]['content'], 'Previous message');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Reply"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous message');
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(
          message: 'New message',
          modelId: 'm',
          memory: memory,
        );
        await expectLater(stream, emits('Reply'));
      });

      test('streams with custom system prompt', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages[0]['content'], 'Custom prompt');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(
          message: 'Hi',
          modelId: 'm',
          systemPrompt: 'Custom prompt',
        );
        await expectLater(stream, emits('OK'));
      });

      test('throws on OpenRouter stream network error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Network error');

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });

      test('throws on Ollama stream network error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Network error');

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });

      test('throws on OpenAI stream network error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Network error');

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });
    });

    group('streaming task manager integration', () {
      test('creates and completes task on stream', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        final taskManager = LlmTaskManager();
        await taskManager.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          taskManager: taskManager,
        );

        final stream = service.chatStream(message: 'Hi', modelId: 'm', feature: 'test-stream');
        await expectLater(stream, emitsInOrder(['OK', emitsDone]));
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.status, LlmTaskStatus.done);
        expect(taskManager.tasks.first.feature, 'test-stream');
      });

      test('marks task as failed on stream error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Stream error');

        final taskManager = LlmTaskManager();
        await taskManager.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          taskManager: taskManager,
        );

        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.status, LlmTaskStatus.failed);
      });
    });

    group('streaming usage meter integration', () {
      test('records usage on successful stream', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Hello"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        final usageMeter = LlmUsageMeter();
        await usageMeter.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          usageMeter: usageMeter,
        );

        final stream = service.chatStream(message: 'Hi', modelId: 'm', feature: 'stream-test');
        await expectLater(stream, emitsInOrder(['Hello', emitsDone]));
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'stream-test');
      });
    });

    group('chat with memory for all providers', () {
      test('Ollama chat with memory', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 2);
          expect(messages[0]['role'], 'user');
          expect(messages[0]['content'], 'Previous');
          expect(messages[1]['role'], 'user');
          expect(messages[1]['content'], 'Current');
          return http.Response(
            jsonEncode({'message': {'content': 'Ollama memory response'}}),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous');
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Current',
          modelId: 'm',
          memory: memory,
        );
        expect(result.data, 'Ollama memory response');
      });

      test('OpenAI chat with memory', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 3);
          expect(messages[0]['role'], 'system');
          expect(messages[1]['role'], 'user');
          expect(messages[1]['content'], 'Previous');
          expect(messages[2]['role'], 'user');
          expect(messages[2]['content'], 'Current');
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OpenAI memory response'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous');
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Current',
          modelId: 'gpt-4',
          memory: memory,
        );
        expect(result.data, 'OpenAI memory response');
      });

      test('Ollama chat with history', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 2);
          expect(messages[0]['role'], 'assistant');
          expect(messages[0]['content'], 'Previous response');
          return http.Response(
            jsonEncode({'message': {'content': 'Ollama history response'}}),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'm',
          history: [
            {'role': 'assistant', 'content': 'Previous response'},
          ],
        );
        expect(result.data, 'Ollama history response');
      });
    });

    group('onTokenUsage for all providers', () {
      test('calls onTokenUsage for OpenAI', () async {
        int? capturedInput;
        int? capturedOutput;
        String? capturedModel;

        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OK'}}
              ],
              'usage': {'prompt_tokens': 3, 'completion_tokens': 7},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
          onTokenUsage: (input, output, model) {
            capturedInput = input;
            capturedOutput = output;
            capturedModel = model;
          },
        );
        final service = LlmService(config: config, httpClient: client);
        await service.chat(message: 'Hi', modelId: 'gpt-4');

        expect(capturedInput, 3);
        expect(capturedOutput, 7);
        expect(capturedModel, 'gpt-4');
      });

      test('does not call onTokenUsage when usage data is absent', () async {
        bool callbackCalled = false;

        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'No usage data'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          onTokenUsage: (input, output, model) {
            callbackCalled = true;
          },
        );
        final service = LlmService(config: config, httpClient: client);
        await service.chat(message: 'Hi', modelId: 'm');

        expect(callbackCalled, isFalse);
      });
    });

    group('chat with usage meter for Ollama', () {
      test('Ollama chat records usage', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            jsonEncode({'message': {'content': 'Ollama usage'}}),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final usageMeter = LlmUsageMeter();
        await usageMeter.init();
        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          usageMeter: usageMeter,
        );
        await service.chat(message: 'Hi', modelId: 'm', feature: 'ollama-test');
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'ollama-test');
      });
    });

    group('LlmConfiguration.hasBackup', () {
      test('returns true when backup provider and apiKey are configured', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          backupProvider: LlmProvider.openAI,
          backupApiKey: 'backup-key',
        );
        expect(config.hasBackup, isTrue);
      });

      test('returns false when backupProvider is null', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        expect(config.hasBackup, isFalse);
      });

      test('returns false when backupApiKey is empty', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          backupProvider: LlmProvider.openAI,
          backupApiKey: '',
        );
        expect(config.hasBackup, isFalse);
      });

      test('returns false when backupApiKey is null', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          backupProvider: LlmProvider.openAI,
        );
        expect(config.hasBackup, isFalse);
      });
    });

    group('LlmConfiguration.copyWithBackup', () {
      test('overrides all backup fields', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final updated = config.copyWithBackup(
          backupProvider: LlmProvider.openAI,
          backupApiKey: 'new-key',
          backupBaseUrl: 'https://backup.example.com',
          backupModel: 'gpt-4',
        );
        expect(updated.backupProvider, LlmProvider.openAI);
        expect(updated.backupApiKey, 'new-key');
        expect(updated.backupBaseUrl, 'https://backup.example.com');
        expect(updated.backupModel, 'gpt-4');
      });

      test('preserves existing fields when not overridden', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          backupProvider: LlmProvider.ollama,
          backupApiKey: 'existing-key',
          backupBaseUrl: 'http://existing.local',
          backupModel: 'llama3',
        );
        final updated = config.copyWithBackup(backupApiKey: 'new-key');
        expect(updated.backupProvider, LlmProvider.ollama);
        expect(updated.backupApiKey, 'new-key');
        expect(updated.backupBaseUrl, 'http://existing.local');
        expect(updated.backupModel, 'llama3');
      });
    });

    group('backup provider fallback in chat', () {
      test('uses backup provider on server error', () async {
        final client = _FakeHttpClient();
        int callCount = 0;
        client.handler = (request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('Server Error', 500);
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'Backup response'}}
              ],
              'usage': {'prompt_tokens': 5, 'completion_tokens': 10},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        };

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'primary-key',
          backupProvider: LlmProvider.openAI,
          backupApiKey: 'backup-key',
          backupModel: 'gpt-4',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(message: 'Hi', modelId: 'primary-model');
        expect(result.data, 'Backup response');
        expect(callCount, 2);
      });

      test('does not use backup on non-server error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Bad Request', 400);

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          backupProvider: LlmProvider.openAI,
          backupApiKey: 'backup-key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(message: 'Hi', modelId: 'm');
        expect(result.isFailure, isTrue);
      });

      test('does not use backup when no backup configured', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Server Error', 500);

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final result = await service.chat(message: 'Hi', modelId: 'm');
        expect(result.isFailure, isTrue);
      });
    });

    group('backup provider fallback in chatStream', () {
      test('uses backup provider on server error', () async {
        final client = _FakeHttpClient();
        int callCount = 0;
        client.handler = (request) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('HTTP 500 Internal Server Error');
          }
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Backup stream"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'primary-key',
          backupProvider: LlmProvider.openRouter,
          backupApiKey: 'backup-key',
          backupModel: 'backup-model',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'primary-model');
        await expectLater(
          stream,
          emitsInOrder([
            '\n\n[Primary provider failed. Trying backup provider...]\n\n',
            'Backup stream',
            emitsDone,
          ]),
        );
        expect(callCount, 2);
      });

      test('does not use backup on non-server error', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => throw Exception('Network error');

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          backupProvider: LlmProvider.openAI,
          backupApiKey: 'backup-key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });
    });

    group('chatStream non-200 status', () {
      test('OpenRouter non-200 yields error message', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Unauthorized', 401);

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'bad-key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(
          stream,
          emits('\n\n[API key is invalid or expired. Update in Settings.]\n\n'),
        );
      });

      test('Ollama non-200 yields error message', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Not Found', 404);

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(
          stream,
          emits('\n\n[Model not found. Check model name in Settings.]\n\n'),
        );
      });

      test('OpenAI non-200 yields error message', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async => http.Response('Too Many Requests', 429);

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'gpt-4');
        await expectLater(
          stream,
          emits('\n\n[Too many requests. Wait and try again.]\n\n'),
        );
      });
    });

    group('Ollama and OpenAI streaming with custom baseUrl', () {
      test('Ollama stream uses custom baseUrl', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'my-ollama.local');
          expect(request.url.port, 8080);
          return http.Response(
            '${jsonEncode({"message": {"content": "Hello"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
          baseUrl: 'http://my-ollama.local:8080',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emits('Hello'));
      });

      test('OpenAI stream uses custom baseUrl', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          expect(request.url.host, 'my-openai.local');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
          baseUrl: 'https://my-openai.local/v1',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Hi', modelId: 'gpt-4');
        await expectLater(stream, emits('OK'));
      });
    });

    group('streaming usage meter for all providers', () {
      test('Ollama streaming records usage', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            '${jsonEncode({"message": {"content": "Hi"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        };

        final usageMeter = LlmUsageMeter();
        await usageMeter.init();
        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          usageMeter: usageMeter,
        );
        final stream = service.chatStream(message: 'Hi', modelId: 'm', feature: 'ollama-stream');
        await expectLater(stream, emitsInOrder(['Hi', emitsDone]));
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'ollama-stream');
      });

      test('OpenAI streaming records usage', () async {
        final client = _FakeHttpClient();
        client.handler = (_) async {
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        };

        final usageMeter = LlmUsageMeter();
        await usageMeter.init();
        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          usageMeter: usageMeter,
        );
        final stream = service.chatStream(message: 'Hi', modelId: 'gpt-4', feature: 'openai-stream');
        await expectLater(stream, emitsInOrder(['OK', emitsDone]));
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'openai-stream');
      });

      test('Ollama streaming with history covers history branch', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 2);
          expect(messages[0]['role'], 'assistant');
          expect(messages[0]['content'], 'Prior');
          return http.Response(
            '${jsonEncode({"message": {"content": "Answer"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(
          message: 'Question',
          modelId: 'm',
          history: [
            {'role': 'assistant', 'content': 'Prior'},
          ],
        );
        await expectLater(stream, emitsInOrder(['Answer', emitsDone]));
      });

      test('Ollama streaming with memory covers memory branch', () async {
        final client = _FakeHttpClient();
        client.handler = (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages.length, 2);
          expect(messages[0]['role'], 'user');
          expect(messages[0]['content'], 'Prev');
          return http.Response(
            '${jsonEncode({"message": {"content": "Reply"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        };

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Prev');
        final service = LlmService(config: config, httpClient: client);
        final stream = service.chatStream(message: 'Current', modelId: 'm', memory: memory);
        await expectLater(stream, emitsInOrder(['Reply', emitsDone]));
      });
    });
  });
}
