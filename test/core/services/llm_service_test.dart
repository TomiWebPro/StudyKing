import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

void main() {
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
    group('chat', () {
      test('returns empty string when apiKey is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);
        final result = await service.chat(
          message: 'Hello',
          modelId: 'test-model',
        );
        expect(result, '');
      });

      test('calls OpenRouter provider successfully', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test_key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Test message',
          modelId: 'openrouter-model',
        );
        expect(result, 'OpenRouter response');
      });

      test('calls Ollama provider successfully', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'ollama-model',
        );
        expect(result, 'Ollama response');
      });

      test('calls Ollama with custom baseUrl', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'my-ollama.local');
          expect(request.url.port, 8080);
          return http.Response(
            jsonEncode({
              'message': {'content': 'Custom Ollama'}
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
          baseUrl: 'http://my-ollama.local:8080',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'model',
        );
        expect(result, 'Custom Ollama');
      });

      test('calls OpenAI provider successfully', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'openai_key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Hello',
          modelId: 'gpt-4',
        );
        expect(result, 'OpenAI response');
      });

      test('calls OpenAI with custom baseUrl', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
          baseUrl: 'https://my-openai.local/v1',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'gpt-4',
        );
        expect(result, 'Custom OpenAI');
      });

      test('throws on OpenRouter API error', () async {
        final mockClient = MockClient((_) async {
          return http.Response('Not Found', 404);
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        await expectLater(
          service.chat(message: 'Hi', modelId: 'm'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on Ollama API error', () async {
        final mockClient = MockClient((_) async {
          return http.Response('Server Error', 500);
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        await expectLater(
          service.chat(message: 'Hi', modelId: 'm'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on OpenAI API error', () async {
        final mockClient = MockClient((_) async {
          return http.Response('Unauthorized', 401);
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        await expectLater(
          service.chat(message: 'Hi', modelId: 'gpt-4'),
          throwsA(isA<Exception>()),
        );
      });

      test('uses ConversationMemory history', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous message');
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'New message',
          modelId: 'm',
          memory: memory,
        );
        expect(result, 'With memory');
      });

      test('uses history list', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'User msg',
          modelId: 'm',
          history: [{'role': 'user', 'content': 'User msg'}],
        );
        expect(result, 'From history');
      });

      test('uses custom system prompt', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'm',
          systemPrompt: 'Custom prompt',
        );
        expect(result, 'Custom response');
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
        await expectLater(stream, emitsDone);
      });
    });

    group('task manager integration', () {
      test('creates and starts task on chat', () async {
        final mockClient = MockClient((_) async {
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
        });

        final taskManager = LlmTaskManager();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
          taskManager: taskManager,
        );

        await service.chat(message: 'Hi', modelId: 'm', feature: 'test-feature');
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.feature, 'test-feature');
      });

      test('marks task as failed on error', () async {
        final mockClient = MockClient((_) async {
          return http.Response('Error', 500);
        });

        final taskManager = LlmTaskManager();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
          taskManager: taskManager,
        );

        await expectLater(
          service.chat(message: 'Hi', modelId: 'm'),
          throwsA(isA<Exception>()),
        );
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.status, LlmTaskStatus.failed);
      });
    });

    group('usage meter integration', () {
      test('records usage on successful chat', () async {
        final mockClient = MockClient((_) async {
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
        });

        final usageMeter = LlmUsageMeter();
        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
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

        final mockClient = MockClient((_) async {
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
        });

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          onTokenUsage: (input, output, model) {
            capturedInput = input;
            capturedOutput = output;
            capturedModel = model;
          },
        );
        final service = LlmService(config: config, httpClient: mockClient);
        await service.chat(message: 'Hi', modelId: 'claude-3');

        expect(capturedInput, 15);
        expect(capturedOutput, 25);
        expect(capturedModel, 'claude-3');
      });
    });

    group('chatStream with streaming data', () {
      test('streams from OpenRouter provider', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Hello"}}]})}\n'
            'data: ${jsonEncode({"choices": [{"delta": {"content": " world"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsInOrder(['Hello', ' world']));
      });

      test('streams from Ollama provider', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          return http.Response(
            '${jsonEncode({"message": {"content": "Hello"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": " world"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsInOrder(['Hello', ' world']));
      });

      test('streams from OpenAI provider', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.host, 'api.openai.com');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Hello"}}]})}\n'
            'data: ${jsonEncode({"choices": [{"delta": {"content": " world"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsInOrder(['Hello', ' world']));
      });

      test('streams with ConversationMemory', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous message');
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(
          message: 'New message',
          modelId: 'm',
          memory: memory,
        );
        await expectLater(stream, emits('Reply'));
      });

      test('streams with custom system prompt', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          expect(messages[0]['content'], 'Custom prompt');
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(
          message: 'Hi',
          modelId: 'm',
          systemPrompt: 'Custom prompt',
        );
        await expectLater(stream, emits('OK'));
      });

      test('throws on OpenRouter stream network error', () async {
        final mockClient = MockClient((_) async => throw Exception('Network error'));

        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });

      test('throws on Ollama stream network error', () async {
        final mockClient = MockClient((_) async => throw Exception('Network error'));

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });

      test('throws on OpenAI stream network error', () async {
        final mockClient = MockClient((_) async => throw Exception('Network error'));

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Hi', modelId: 'm');
        await expectLater(stream, emitsError(isA<Exception>()));
      });
    });

    group('streaming task manager integration', () {
      test('creates and completes task on stream', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        });

        final taskManager = LlmTaskManager();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
          taskManager: taskManager,
        );

        final stream = service.chatStream(message: 'Hi', modelId: 'm', feature: 'test-stream');
        await expectLater(stream, emitsInOrder(['OK', emitsDone]));
        expect(taskManager.tasks.length, 1);
        expect(taskManager.tasks.first.status, LlmTaskStatus.done);
        expect(taskManager.tasks.first.feature, 'test-stream');
      });

      test('marks task as failed on stream error', () async {
        final mockClient = MockClient((_) async => throw Exception('Stream error'));

        final taskManager = LlmTaskManager();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
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
        final mockClient = MockClient((_) async {
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "Hello"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        });

        final usageMeter = LlmUsageMeter();
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
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
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous');
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Current',
          modelId: 'm',
          memory: memory,
        );
        expect(result, 'Ollama memory response');
      });

      test('OpenAI chat with memory', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Previous');
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Current',
          modelId: 'gpt-4',
          memory: memory,
        );
        expect(result, 'OpenAI memory response');
      });

      test('Ollama chat with history', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
        final result = await service.chat(
          message: 'Hi',
          modelId: 'm',
          history: [
            {'role': 'assistant', 'content': 'Previous response'},
          ],
        );
        expect(result, 'Ollama history response');
      });
    });

    group('onTokenUsage for all providers', () {
      test('calls onTokenUsage for OpenAI', () async {
        int? capturedInput;
        int? capturedOutput;
        String? capturedModel;

        final mockClient = MockClient((_) async {
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
        });

        final config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
          onTokenUsage: (input, output, model) {
            capturedInput = input;
            capturedOutput = output;
            capturedModel = model;
          },
        );
        final service = LlmService(config: config, httpClient: mockClient);
        await service.chat(message: 'Hi', modelId: 'gpt-4');

        expect(capturedInput, 3);
        expect(capturedOutput, 7);
        expect(capturedModel, 'gpt-4');
      });

      test('does not call onTokenUsage when usage data is absent', () async {
        bool callbackCalled = false;

        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'No usage data'}}
              ],
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'key',
          onTokenUsage: (input, output, model) {
            callbackCalled = true;
          },
        );
        final service = LlmService(config: config, httpClient: mockClient);
        await service.chat(message: 'Hi', modelId: 'm');

        expect(callbackCalled, isFalse);
      });
    });

    group('chat with usage meter for Ollama', () {
      test('Ollama chat records usage', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({'message': {'content': 'Ollama usage'}}),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final usageMeter = LlmUsageMeter();
        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
          usageMeter: usageMeter,
        );
        await service.chat(message: 'Hi', modelId: 'm', feature: 'ollama-test');
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'ollama-test');
      });
    });

    group('streaming usage meter for all providers', () {
      test('Ollama streaming records usage', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            '${jsonEncode({"message": {"content": "Hi"}, "done": false})}\n'
            '${jsonEncode({"message": {"content": ""}, "done": true})}\n',
            200,
          );
        });

        final usageMeter = LlmUsageMeter();
        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
          usageMeter: usageMeter,
        );
        final stream = service.chatStream(message: 'Hi', modelId: 'm', feature: 'ollama-stream');
        await expectLater(stream, emitsInOrder(['Hi', emitsDone]));
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'ollama-stream');
      });

      test('OpenAI streaming records usage', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            'data: ${jsonEncode({"choices": [{"delta": {"content": "OK"}}]})}\n'
            'data: [DONE]\n'
            '\n',
            200,
          );
        });

        final usageMeter = LlmUsageMeter();
        const config = LlmConfiguration(
          provider: LlmProvider.openAI,
          apiKey: 'key',
        );
        final service = LlmService(
          config: config,
          httpClient: mockClient,
          usageMeter: usageMeter,
        );
        final stream = service.chatStream(message: 'Hi', modelId: 'gpt-4', feature: 'openai-stream');
        await expectLater(stream, emitsInOrder(['OK', emitsDone]));
        expect(usageMeter.getRecords().length, 1);
        expect(usageMeter.getRecords().first.feature, 'openai-stream');
      });

      test('Ollama streaming with history covers history branch', () async {
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final service = LlmService(config: config, httpClient: mockClient);
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
        final mockClient = MockClient((request) async {
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
        });

        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'key',
        );
        final memory = ConversationMemory(maxTurns: 5);
        memory.addMessage('user', 'Prev');
        final service = LlmService(config: config, httpClient: mockClient);
        final stream = service.chatStream(message: 'Current', modelId: 'm', memory: memory);
        await expectLater(stream, emitsInOrder(['Reply', emitsDone]));
      });
    });
  });
}