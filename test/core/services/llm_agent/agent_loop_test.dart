import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';

import '../../../helpers/hive_init_helper.dart';

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
    String? taskType,
  }) async {
    messageCalls.add(message);
    historyCalls.add(List<Map<String, String>>.from(history ?? []));
    return Result.success(_scriptedResponses.removeAt(0));
  }
}

/// Fake LLM service that also registers and completes tasks on a shared
/// [LlmTaskManager], mirroring how the real [LlmService.chat] creates a
/// per-call task via [LlmTaskManager.createTask] and completes it via
/// [_trackUsage]. This lets [AgentLoop] tests verify token aggregation.
class _TaskTrackingFakeLlmService extends _FakeLlmService {
  final LlmTaskManager taskManager;
  final String feature;
  final int simulatedTokens;
  final double simulatedCost;

  _TaskTrackingFakeLlmService(
    super.scriptedResponses,
    this.taskManager,
    this.feature, {
    this.simulatedTokens = 500,
    this.simulatedCost = 0.005,
  });

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    String? taskType,
  }) async {
    messageCalls.add(message);
    historyCalls.add(List<Map<String, String>>.from(history ?? []));

    // Simulate the real service creating a per-call task and completing it
    // with token usage, so AgentLoop can aggregate it.
    final callTaskId = taskManager.createTask(
      feature: feature,
      modelId: modelId,
      taskType: _LlmTaskTypeForTest.fromFeature(feature),
    );
    taskManager.startTask(callTaskId);
    taskManager.completeTask(
      callTaskId,
      tokensUsed: simulatedTokens,
      estimatedCost: simulatedCost,
    );

    return Result.success(_scriptedResponses.removeAt(0));
  }
}

/// Hand-written fake that scripts streaming LLM replies and records the
/// conversation history and current message seen on each call. Each scripted
/// response is split into word-sized chunks to exercise progressive yield.
class _StreamingFakeLlmService extends LlmService {
  final List<String> _scriptedResponses;
  final List<List<Map<String, String>>> historyCalls = [];
  final List<String> messageCalls = [];
  final List<String> allChunks = [];

  _StreamingFakeLlmService(this._scriptedResponses)
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    String? taskType,
  }) async* {
    messageCalls.add(message);
    historyCalls.add(List<Map<String, String>>.from(history ?? []));

    final response = _scriptedResponses.removeAt(0);
    // Split into word-sized chunks so the consumer can assert progressive yield.
    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      final chunk = words[i] + (i < words.length - 1 ? ' ' : '');
      allChunks.add(chunk);
      yield chunk;
    }
  }
}

/// Streaming fake that also records per-call task token usage on a shared
/// [LlmTaskManager], so [AgentLoop.runStream] token aggregation can be tested.
class _TaskTrackingStreamingFakeLlmService extends _StreamingFakeLlmService {
  final LlmTaskManager taskManager;
  final String feature;
  final int simulatedTokens;

  _TaskTrackingStreamingFakeLlmService(
    super.scriptedResponses,
    this.taskManager,
    this.feature, {
    this.simulatedTokens = 500,
  });

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    String? taskType,
  }) async* {
    messageCalls.add(message);
    historyCalls.add(List<Map<String, String>>.from(history ?? []));

    final callTaskId = taskManager.createTask(
      feature: feature,
      modelId: modelId,
      taskType: _LlmTaskTypeForTest.fromFeature(feature),
    );
    taskManager.startTask(callTaskId);
    taskManager.completeTask(
      callTaskId,
      tokensUsed: simulatedTokens,
      estimatedCost: 0.005,
    );

    final response = _scriptedResponses.removeAt(0);
    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      final chunk = words[i] + (i < words.length - 1 ? ' ' : '');
      allChunks.add(chunk);
      yield chunk;
    }
  }
}

/// Minimal mirror of LlmTaskType.fromFeature for test purposes — returns
/// the enum name string for known features, null otherwise.
class _LlmTaskTypeForTest {
  static String? fromFeature(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('mentor')) return 'mentor';
    if (f.contains('tutor') || f.contains('teaching')) return 'tutor';
    if (f.contains('question_generation') || f.contains('variant')) return 'generation';
    if (f.contains('summar')) return 'summarization';
    if (f.contains('classif')) return 'classification';
    if (f.contains('eval')) return 'evaluation';
    if (f.contains('transcription') || f.contains('ocr')) return 'transcription';
    if (f.contains('background') || f.contains('idle')) return 'background';
    return null;
  }
}

/// Hand-written fake [PrepTool] that records whether its [execute] was invoked
/// and what arguments it received. Used to assert that prep work is deferred
/// to the [IdleExecutor] rather than running during the agent turn.
class _FakePrepTool extends PrepTool {
  bool executeCalled = false;
  Map<String, dynamic>? receivedArgs;

  @override
  String get name => 'fake_prep_tool';

  @override
  String get description => 'A fake prep tool for testing deferral';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {'type': 'string', 'description': 'Subject ID'},
        },
        'required': ['subjectId'],
      };

  @override
  int get estimatedInputTokens => 1000;

  @override
  int get estimatedOutputTokens => 500;

  @override
  PrepCpuClass get cpuClass => PrepCpuClass.heavy;

  @override
  PrepCategory get prepCategory => PrepCategory.pdfIngestion;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    executeCalled = true;
    receivedArgs = args;
    return {'success': true, 'prepared': true};
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

  group('AgentLoop task tracking', () {
    setUpAll(() async {
      await initializeHiveForIntegrationTests();
    });

    test('records taskType and aggregates tokensUsed', () async {
      // Initialize a real LlmTaskManager with Hive persistence.
      await Hive.openBox(HiveBoxNames.llmTasks);
      await Hive.box(HiveBoxNames.llmTasks).clear();
      final taskManager = LlmTaskManager();
      await taskManager.init();
      addTearDown(() async {
        await taskManager.persistenceComplete;
        Hive.box(HiveBoxNames.llmTasks).clear();
      });

      final fakeLlm = _TaskTrackingFakeLlmService(
        [
          'TOOL_CALL: searchQuestions\nARGUMENTS: {"topic": "physics"}',
          'Here are the results.',
        ],
        taskManager,
        'mentor',
        simulatedTokens: 1500,
        simulatedCost: 0.012,
      );

      final registry = ToolRegistry()..register(_SearchTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
        taskManager: taskManager,
      );

      await loop.run(
        userMessage: 'Find physics questions',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'mentor',
      );

      // The agent-loop task is the one with tokensUsed > 0 (it aggregated
      // from the per-call tasks which each have simulatedTokens=1500).
      final agentTask = taskManager.tasks.firstWhere((t) =>
          t.endTime != null && t.taskType == 'mentor' && t.tokensUsed > 0);

      // taskType should be populated from LlmTaskType.fromFeature('mentor').
      expect(agentTask.taskType, isNotNull);
      expect(agentTask.taskType, 'mentor');

      // tokensUsed should be > 0, aggregated from the LLM service's per-call tasks.
      // Two LLM calls each create a task with 1500 tokens, so total = 3000.
      expect(agentTask.tokensUsed, greaterThan(0));
      expect(agentTask.tokensUsed, 3000);

      // estimatedCost should also be aggregated.
      expect(agentTask.estimatedCost, closeTo(0.024, 0.0001));

      // There should be 3 tasks total: 1 agent task + 2 LLM-call tasks.
      expect(taskManager.tasks.where((t) => t.endTime != null), hasLength(3));
    });

    test('aggregates tokens from multiple LLM calls within a loop', () async {
      await Hive.openBox(HiveBoxNames.llmTasks);
      await Hive.box(HiveBoxNames.llmTasks).clear();
      final taskManager = LlmTaskManager();
      await taskManager.init();
      addTearDown(() async {
        await taskManager.persistenceComplete;
        Hive.box(HiveBoxNames.llmTasks).clear();
      });

      final fakeLlm = _TaskTrackingFakeLlmService(
        [
          'TOOL_CALL: searchQuestions\nARGUMENTS: {"topic": "physics"}',
          'TOOL_CALL: searchQuestions\nARGUMENTS: {"topic": "chemistry"}',
          'Final answer.',
        ],
        taskManager,
        'mentor',
        simulatedTokens: 400,
        simulatedCost: 0.001,
      );

      final registry = ToolRegistry()..register(_SearchTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
        taskManager: taskManager,
      );

      await loop.run(
        userMessage: 'Find questions',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'tutor',
      );

      // The agent-loop task is the one with tokensUsed > 0; LLM-call tasks
      // have tokensUsed = simulatedTokens (400), so the agent task should
      // have 3×400 = 1200.
      final completedTasks = taskManager.tasks.where((t) => t.endTime != null);
      expect(completedTasks, hasLength(4)); // 1 agent task + 3 LLM-call tasks

      final agentTask = taskManager.tasks.firstWhere(
          (t) => t.endTime != null && t.taskType == 'tutor' && t.tokensUsed == 1200);
      expect(agentTask.tokensUsed, greaterThan(0));
    });

    test('agent task is created with taskType even on LLM failure', () async {
      await Hive.openBox(HiveBoxNames.llmTasks);
      await Hive.box(HiveBoxNames.llmTasks).clear();
      final taskManager = LlmTaskManager();
      await taskManager.init();
      addTearDown(() async {
        await taskManager.persistenceComplete;
        Hive.box(HiveBoxNames.llmTasks).clear();
      });

      final fakeLlm = _TaskTrackingFakeLlmService(
        ['Here is a direct answer without tools.'],
        taskManager,
        'mentor',
      );

      final registry = ToolRegistry();
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
        taskManager: taskManager,
      );

      await loop.run(
        userMessage: 'Tell me about photosynthesis.',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'mentor',
      );

      final agentTask = taskManager.tasks.firstWhere((t) => t.feature == 'mentor');
      expect(agentTask.taskType, 'mentor');
    });
  });

  group('AgentLoop.runStream', () {
    test('streams chunks progressively for a plain text response', () async {
      final fakeLlm = _StreamingFakeLlmService([
        'Sure I can help with that',
      ]);
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: ToolRegistry(),
      );

      final chunks = await loop.runStream(
        userMessage: 'Hello',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
      ).toList();

      expect(chunks, isNotEmpty);
      expect(chunks.length, greaterThan(1)); // progressive, not one chunk
      expect(chunks.join(), 'Sure I can help with that');
    });

    test('does not yield tool-call text to the caller', () async {
      final fakeLlm = _StreamingFakeLlmService([
        'Let me check. TOOL_CALL: searchQuestions\nARGUMENTS: {"topic": "math"}',
        'Here are the results.',
      ]);
      final registry = ToolRegistry()..register(_SearchTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );

      final chunks = await loop.runStream(
        userMessage: 'Find math questions',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
      ).toList();

      // Tool call markers must never appear in yielded chunks.
      expect(chunks, isNotEmpty);
      expect(chunks.any((c) => c.contains('TOOL_CALL')), isFalse);
      expect(chunks.any((c) => c.contains('ARGUMENTS')), isFalse);
      // Text before the tool call should be present.
      expect(chunks.join(), contains('Let me check.'));
      // The final LLM response (after tool execution) should be yielded.
      expect(chunks.join(), contains('Here are the results.'));
      // Progressive: more than one chunk.
      expect(chunks.length, greaterThan(1));
    });

    test('invokes onToolCall callback for each executed tool', () async {
      final fakeLlm = _StreamingFakeLlmService([
        'TOOL_CALL: searchQuestions\nARGUMENTS: {"topic": "physics"}',
        'Done.',
      ]);
      final registry = ToolRegistry()..register(_SearchTool());
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );

      final calls = <String>[];
      await loop.runStream(
        userMessage: 'Find physics questions',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        onToolCall: (call) async {
          calls.add(call.toolName);
        },
      ).toList();

      expect(calls, ['searchQuestions']);
    });

    test('handles unknown tool in streaming mode', () async {
      final fakeLlm = _StreamingFakeLlmService([
        'TOOL_CALL: nonexistentTool\nARGUMENTS: {}',
      ]);
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: ToolRegistry(),
      );

      final chunks = await loop.runStream(
        userMessage: 'Do something',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
      ).toList();

      expect(chunks.join(), contains('nonexistentTool'));
      expect(chunks.join(), isNot(contains('TOOL_CALL')));
    });

    test('aggregates tokens from per-call LLM tasks', () async {
      await Hive.openBox(HiveBoxNames.llmTasks);
      await Hive.box(HiveBoxNames.llmTasks).clear();
      final taskManager = LlmTaskManager();
      await taskManager.init();
      addTearDown(() async {
        await taskManager.persistenceComplete;
        Hive.box(HiveBoxNames.llmTasks).clear();
      });

      final fakeLlm = _TaskTrackingStreamingFakeLlmService(
        ['Final answer streamed.'],
        taskManager,
        'mentor',
        simulatedTokens: 800,
      );

      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: ToolRegistry(),
        taskManager: taskManager,
      );

      await loop.runStream(
        userMessage: 'Tell me about photosynthesis.',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'mentor',
      ).toList();

      final agentTask = taskManager.tasks.firstWhere(
        (t) => t.endTime != null && t.taskType == 'mentor',
      );
      expect(agentTask.tokensUsed, greaterThan(0));
    });
  });

  group('AgentLoop prep-tool deferral', () {
    test('runStream defers PrepTool to IdleExecutor instead of executing synchronously', () async {
      final prepTool = _FakePrepTool();
      final fakeLlm = _StreamingFakeLlmService([
        'TOOL_CALL: fake_prep_tool\nARGUMENTS: {"subjectId": "math"}',
      ]);
      final registry = ToolRegistry()..register(prepTool);

      // Quiet-hours callback always defers so the task never auto-executes
      // during the test — mirroring the real scenario where prep runs off-period.
      final idleExecutor = IdleExecutor(
        shouldDeferForQuietHours: (_) => true,
      );

      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
        idleExecutor: idleExecutor,
      );

      final chunks = await loop.runStream(
        userMessage: 'Prepare knowledge chunks',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'mentor',
      ).toList();

      // The prep tool's execute() must NOT have run during the stream.
      expect(prepTool.executeCalled, isFalse);

      // The IdleExecutor queue holds the deferred task.
      expect(idleExecutor.queue, isNotEmpty);
      expect(idleExecutor.queue.first.description, contains('fake_prep_tool'));

      // The student receives a confirmation message.
      final output = chunks.join();
      expect(output, contains("I'll prepare this while you're away"));
    });

    test('run defers PrepTool to IdleExecutor instead of executing synchronously', () async {
      final prepTool = _FakePrepTool();
      final fakeLlm = _FakeLlmService([
        'TOOL_CALL: fake_prep_tool\nARGUMENTS: {"subjectId": "math"}',
      ]);
      final registry = ToolRegistry()..register(prepTool);

      final idleExecutor = IdleExecutor(
        shouldDeferForQuietHours: (_) => true,
      );

      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
        idleExecutor: idleExecutor,
      );

      final response = await loop.run(
        userMessage: 'Prepare knowledge chunks',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'mentor',
      );

      // The prep tool's execute() must NOT have run synchronously.
      expect(prepTool.executeCalled, isFalse);

      // The IdleExecutor queue holds the deferred task.
      expect(idleExecutor.queue, isNotEmpty);
      expect(idleExecutor.queue.first.description, contains('fake_prep_tool'));

      // The student receives a confirmation.
      expect(response.content, contains("I'll prepare this while you're away"));

      // The tool-call record is preserved.
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls.first.toolName, 'fake_prep_tool');
    });

    test('falls back to synchronous execution when IdleExecutor is not wired', () async {
      final prepTool = _FakePrepTool();
      final fakeLlm = _FakeLlmService([
        'TOOL_CALL: fake_prep_tool\nARGUMENTS: {"subjectId": "math"}',
        'Done preparing.',
      ]);
      final registry = ToolRegistry()..register(prepTool);

      // No idleExecutor provided — backward-compatible synchronous execution.
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );

      final response = await loop.run(
        userMessage: 'Prepare knowledge chunks',
        studentId: 's1',
        systemPrompt: 'You are a tutor.',
        feature: 'mentor',
      );

      // Without an IdleExecutor, the tool executes synchronously.
      expect(prepTool.executeCalled, isTrue);
      expect(prepTool.receivedArgs, containsPair('subjectId', 'math'));

      // The conversation continues after the tool result.
      expect(response.content, 'Done preparing.');
    });
  });
}
