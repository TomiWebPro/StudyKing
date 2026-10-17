import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/mentor/services/tools/switch_provider_tool.dart';

void main() {
  group('SwitchProviderTool', () {
    late List<Map<String, dynamic>> receivedCalls;

    setUp(() {
      receivedCalls = [];
    });

    SwitchProviderTool buildTool({
      bool shouldSucceed = true,
    }) {
      return SwitchProviderTool(
        onSwitch: ({
          required LlmProvider provider,
          required String? apiKey,
          required String? baseUrl,
          required String? model,
        }) async {
          receivedCalls.add({
            'provider': provider,
            'apiKey': apiKey,
            'baseUrl': baseUrl,
            'model': model,
          });
          return shouldSucceed
              ? Result.success(null)
              : Result.failure('settings persistence failed');
        },
      );
    }

    test('tool name is switch_provider', () {
      final tool = buildTool();
      expect(tool.name, 'switch_provider');
    });

    test('description mentions provider switching', () {
      final tool = buildTool();
      expect(tool.description, contains('provider'));
      expect(tool.description, contains('switch'));
    });

    test('parameters include provider (required) and optional apiKey/baseUrl/model', () {
      final tool = buildTool();
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], containsPair('provider', isA<Map>()));
      expect(params['properties'], containsPair('apiKey', isA<Map>()));
      expect(params['properties'], containsPair('baseUrl', isA<Map>()));
      expect(params['properties'], containsPair('model', isA<Map>()));
      expect(params['required'], contains('provider'));
      expect(params['required'], isNot(contains('apiKey')));
      expect(params['required'], isNot(contains('baseUrl')));
      expect(params['required'], isNot(contains('model')));
    });

    test('calls onSwitch with ollama provider and model', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'ollama',
        'model': 'llama3',
      });

      expect(result['success'], isTrue);
      expect(result['provider'], 'ollama');
      expect(result['model'], 'llama3');
      expect(result['apiKeySet'], isFalse);
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['provider'], LlmProvider.ollama);
      expect(receivedCalls.first['model'], 'llama3');
      expect(receivedCalls.first['apiKey'], isNull);
    });

    test('ollama does not require API key', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'ollama',
      });

      expect(result['success'], isTrue);
      expect(result['apiKeySet'], isFalse);
      expect(receivedCalls, hasLength(1));
    });

    test('openRouter requires API key', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'openRouter',
        'apiKey': 'sk-test-123',
        'model': 'gemini-2.0-flash',
      });

      expect(result['success'], isTrue);
      expect(result['apiKeySet'], isTrue);
      expect(receivedCalls.first['apiKey'], 'sk-test-123');
    });

    test('non-ollama provider without API key returns failure', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'openAI',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('API key'));
      expect(receivedCalls, isEmpty,
          reason: 'Callback should not be invoked when validation fails');
    });

    test('custom provider requires API key', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'custom',
        'baseUrl': 'http://localhost:8080',
        'apiKey': 'sk-custom',
        'model': 'claude-3-haiku',
      });

      expect(result['success'], isTrue);
      expect(result['model'], 'claude-3-haiku');
      expect(receivedCalls.first['baseUrl'], 'http://localhost:8080');
    });

    test('unknown provider name returns failure', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'unknown_ai',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unknown provider'));
      expect(result['error'], contains('unknown_ai'));
      expect(receivedCalls, isEmpty);
    });

    test('tolerates case-insensitive provider name via parseProvider', () async {
      final tool = buildTool();

      // The LLM might emit "OpenRouter" or "OPENROUTER" — parseProvider
      // normalizes using .normalized (trim + lowercase).
      final result1 = await tool.execute({
        'provider': 'OpenRouter',
        'apiKey': 'sk-test',
      });
      expect(result1['success'], isTrue);
    });

    test('reports failure when onSwitch callback fails', () async {
      final tool = buildTool(shouldSucceed: false);

      final result = await tool.execute({
        'provider': 'ollama',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('settings persistence failed'));
      expect(receivedCalls, hasLength(1));
    });

    test('uses default model when none provided', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': 'ollama',
      });

      expect(result['success'], isTrue);
      expect(result['model'], 'llama3',
          reason: 'Should fall back to default model for ollama');
    });

    test('missing provider argument returns failure', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'apiKey': 'sk-test',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unknown provider'));
      expect(receivedCalls, isEmpty);
    });

    test('empty provider string returns failure', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'provider': '',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unknown provider'));
      expect(receivedCalls, isEmpty);
    });
  });
}
