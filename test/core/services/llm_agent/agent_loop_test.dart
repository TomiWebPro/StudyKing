import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';

class _SearchTool extends AgentTool {
  @override
  String get name => 'searchQuestions';
  @override
  String get description => 'Search questions by topic';
  @override
  Map<String, dynamic> get parameters => {'topic': {'type': 'string'}};

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return {'results': ['Q1', 'Q2'], 'count': 2};
  }
}

class _BrokenTool extends AgentTool {
  @override
  String get name => 'broken';
  @override
  String get description => 'Always throws';
  @override
  Map<String, dynamic> get parameters => {};

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    throw StateError('tool exploded');
  }
}

/// Hand-written fake that scripts LLM replies and records the
/// conversation history and current message seen on each call.
class _FakeLlmService extends LlmService {
  final List<String> _scriptedResponses;
  final List<List<Map<String, String>>> historyCalls = [];
  final List<String> messageCalls = [];

  _FakeLlmService(this._scriptedResponses)
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    messageCalls.add(message);
    historyCalls.add(List<Map<String, String>>.from(history ?? []));
    return Result.success(_scriptedResponses.removeAt(0));
  }
}

void main() {
  group('ToolRegistry integration', () {
    test('searchQuestions tool executes', () async {
      final registry = ToolRegistry();
      final tool = _SearchTool();
      registry.register(tool);

      final retrieved = registry.get('searchQuestions');
      expect(retrieved, isNotNull);

      final result = await retrieved!.execute({'topic': 'physics'});
      expect(result, isA<Map>());
      expect((result as Map)['count'], 2);
    });

    test('unknown tool returns null from registry', () {
      final registry = ToolRegistry();
      expect(registry.get('unknown'), isNull);
    });
  });

  group('AgentLoop conversation', () {
    test('tool result message names the tool and carries its result', () async {
      final fakeLlm = _FakeLlmService([
        'TOOL_CALL: searchQuestions\nARGUMENTS: {"topic": "physics"}',
        'Here are the results.',
      ]);
      final registry = ToolRegistry()..register(_SearchTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );

      final response = await loop.run(
        userMessage: 'Find physics questions',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
      );

      expect(response.content, 'Here are the results.');
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls.first.toolName, 'searchQuestions');
      expect(response.toolCalls.first.arguments, {'topic': 'physics'});

      // The tool RESULT is the current message of the second call,
      // not a history entry: it must name the tool and carry its
      // result, never "Instance of '_ParsedResponse'".
      final toolResultMessage = fakeLlm.messageCalls[1];
      expect(toolResultMessage, startsWith('Tool result for searchQuestions:'));
      expect(toolResultMessage, contains('{"results":["Q1","Q2"],"count":2}'));
      expect(toolResultMessage, isNot(contains('Instance of')));

      // The current message must reach the LLM exactly once: as
      // `message`, never duplicated inside `history`.
      expect(
        fakeLlm.historyCalls[1]
            .map((m) => m['content'])
            .where((content) => content == toolResultMessage),
        isEmpty,
      );
      expect(
        fakeLlm.messageCalls.where((m) => m == toolResultMessage),
        hasLength(1),
      );

      // History still carries the original user message and the
      // assistant tool-call turn (nothing older is dropped).
      final historyRoles = fakeLlm.historyCalls[1].map((m) => m['role']).toList();
      expect(historyRoles, ['user', 'assistant']);
    });

    test('unknown tool error names the requested tool', () async {
      final fakeLlm = _FakeLlmService([
        'TOOL_CALL: nonexistent\nARGUMENTS: {}',
      ]);
      final registry = ToolRegistry()..register(_SearchTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );

      final response = await loop.run(
        userMessage: 'Do something',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
      );

      expect(response.content, contains('nonexistent'));
      expect(response.content, isNot(contains('Instance of')));
    });

    test('tool execution errors are surfaced to the agent', () async {
      final fakeLlm = _FakeLlmService([
        'TOOL_CALL: broken\nARGUMENTS: {}',
        'Done.',
      ]);
      final registry = ToolRegistry()..register(_BrokenTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );

      final response = await loop.run(
        userMessage: 'Trigger a failing tool',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
      );

      expect(response.content, 'Done.');
      final toolResultMessage = fakeLlm.messageCalls[1];
      expect(toolResultMessage, startsWith('Tool result for broken:'));
      expect(toolResultMessage, contains('error'));
    });
  });
}
