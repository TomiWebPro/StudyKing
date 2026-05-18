import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

class FakeAgentLoop extends AgentLoop {
  String? capturedMessage;
  String? capturedStudentId;
  String? capturedSystemPrompt;
  String? capturedFeature;
  List<Map<String, String>>? capturedHistory;

  FakeAgentLoop()
      : super(
          llmService: _FakeLlmService(),
          modelId: 'test-model',
          toolRegistry: ToolRegistry(),
        );

  @override
  Future<AgentResponse> run({
    required String userMessage,
    required String studentId,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
  }) async {
    capturedMessage = userMessage;
    capturedStudentId = studentId;
    capturedSystemPrompt = systemPrompt;
    capturedFeature = feature;
    capturedHistory = history;
    return AgentResponse(content: 'AI response', toolCalls: []);
  }
}

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openAI,
            apiKey: 'test-key',
          ),
        );
}

class FakeToolRegistry extends ToolRegistry {}

class FakeAgentMemoryStore extends AgentMemoryStore {
  final Map<String, String> _facts = {};

  @override
  String? recallFact(String studentId, String key) => _facts['${studentId}_$key'];

  @override
  Future<void> rememberFact(String studentId, String key, String value) async {
    _facts['${studentId}_$key'] = value;
  }
}

class FakeIdleExecutor extends IdleExecutor {
  bool disposed = false;
  String? enqueuedDescription;
  Future<void> Function()? enqueuedTask;

  @override
  Future<void> enqueue(String description, Future<void> Function() task) async {
    enqueuedDescription = description;
    enqueuedTask = task;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  group('LlmAgent', () {
    late FakeAgentLoop fakeLoop;
    late ToolRegistry fakeToolRegistry;
    late FakeAgentMemoryStore fakeMemory;
    late FakeIdleExecutor fakeIdleExecutor;
    late LlmAgent agent;

    setUp(() {
      fakeLoop = FakeAgentLoop();
      fakeToolRegistry = FakeToolRegistry();
      fakeMemory = FakeAgentMemoryStore();
      fakeIdleExecutor = FakeIdleExecutor();
      agent = LlmAgent(
        loop: fakeLoop,
        toolRegistry: fakeToolRegistry,
        memoryStore: fakeMemory,
        idleExecutor: fakeIdleExecutor,
        studentId: 'test-student',
      );
    });

    test('constructor stores parameters and exposes getters', () {
      expect(agent.loop, same(fakeLoop));
      expect(agent.toolRegistry, same(fakeToolRegistry));
      expect(agent.memory, same(fakeMemory));
      expect(agent.idleExecutor, same(fakeIdleExecutor));
    });

    test('chat delegates to AgentLoop.run', () async {
      final response = await agent.chat(
        message: 'Hello',
        systemPrompt: 'Be helpful',
        feature: 'test-feature',
        history: const [{'role': 'user', 'content': 'prev msg'}],
      );

      expect(fakeLoop.capturedMessage, 'Hello');
      expect(fakeLoop.capturedStudentId, 'test-student');
      expect(fakeLoop.capturedSystemPrompt, 'Be helpful');
      expect(fakeLoop.capturedFeature, 'test-feature');
      expect(fakeLoop.capturedHistory, [
        {'role': 'user', 'content': 'prev msg'},
      ]);
      expect(response.content, 'AI response');
    });

    test('chat with default feature', () async {
      await agent.chat(message: 'Hi', systemPrompt: 'Help');

      expect(fakeLoop.capturedFeature, 'agent');
    });

    test('chat without history', () async {
      await agent.chat(message: 'Hi', systemPrompt: 'Help');

      expect(fakeLoop.capturedHistory, isNull);
    });

    test('enqueueBackgroundTask delegates to idleExecutor.enqueue', () async {
      Future<void> task() async {}
      await agent.enqueueBackgroundTask('test task', task);

      expect(fakeIdleExecutor.enqueuedDescription, 'test task');
      expect(fakeIdleExecutor.enqueuedTask, task);
    });

    test('recallFact delegates to memoryStore', () {
      fakeMemory.rememberFact('test-student', 'color', 'blue');

      expect(agent.recallFact('color'), 'blue');
      expect(agent.recallFact('nonexistent'), isNull);
    });

    test('rememberFact delegates to memoryStore', () async {
      await agent.rememberFact('color', 'red');

      expect(agent.recallFact('color'), 'red');
    });

    test('dispose calls idleExecutor.dispose', () {
      agent.dispose();

      expect(fakeIdleExecutor.disposed, isTrue);
    });

    test('dispose does not throw when called multiple times', () {
      agent.dispose();
      agent.dispose();
      expect(fakeIdleExecutor.disposed, isTrue);
    });
  });

  group('AgentFactory', () {
    test('create returns a fully wired LlmAgent', () {
      final llmService = _FakeLlmService();
      final agent = AgentFactory.create(
        llmService: llmService,
        modelId: 'gpt-4',
        studentId: 'student1',
      );

      expect(agent, isA<LlmAgent>());
      expect(agent.toolRegistry, isA<ToolRegistry>());
      expect(agent.memory, isA<AgentMemoryStore>());
      expect(agent.idleExecutor, isA<IdleExecutor>());
      expect(agent.loop, isA<AgentLoop>());
    });

    test('create with custom tools registers them', () {
      final llmService = _FakeLlmService();
      final tool = _TestAgentTool();
      final agent = AgentFactory.create(
        llmService: llmService,
        modelId: 'gpt-4',
        studentId: 'student1',
        tools: [tool],
      );

      expect(agent.toolRegistry.get('test_tool'), isNotNull);
      expect(agent.toolRegistry.toolNames, contains('test_tool'));
    });

    test('create with taskManager wires it to loop and idleExecutor', () {
      final llmService = _FakeLlmService();
      final agent = AgentFactory.create(
        llmService: llmService,
        modelId: 'gpt-4',
        studentId: 'student1',
      );

      expect(agent.idleExecutor.hasPendingTasks, isFalse);
    });
  });
}

class _TestAgentTool extends AgentTool {
  @override
  String get name => 'test_tool';

  @override
  String get description => 'A test tool';

  @override
  Map<String, dynamic> get parameters => {'param1': {'type': 'string'}};

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return 'executed ${args['param1']}';
  }
}
