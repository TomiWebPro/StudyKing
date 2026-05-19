import 'dart:async';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';

class LlmAgent {
  final AgentLoop _loop;
  final ToolRegistry _toolRegistry;
  final AgentMemoryStore _memoryStore;
  final IdleExecutor _idleExecutor;
  final String _studentId;

  ToolRegistry get toolRegistry => _toolRegistry;
  AgentMemoryStore get memory => _memoryStore;
  IdleExecutor get idleExecutor => _idleExecutor;
  AgentLoop get loop => _loop;

  LlmAgent({
    required AgentLoop loop,
    required ToolRegistry toolRegistry,
    required AgentMemoryStore memoryStore,
    required IdleExecutor idleExecutor,
    required String studentId,
  })  : _loop = loop,
        _toolRegistry = toolRegistry,
        _memoryStore = memoryStore,
        _idleExecutor = idleExecutor,
        _studentId = studentId;

  Future<AgentResponse> chat({
    required String message,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
  }) {
    return _loop.run(
      userMessage: message,
      studentId: _studentId,
      systemPrompt: systemPrompt,
      feature: feature,
      history: history,
    );
  }

  Future<void> enqueueBackgroundTask(String description, Future<void> Function() task) {
    return _idleExecutor.enqueue(description, task);
  }

  String? recallFact(String key) => _memoryStore.recallFact(_studentId, key);

  Future<void> rememberFact(String key, String value) => _memoryStore.rememberFact(_studentId, key, value);

  Future<void> dispose() async {
    _idleExecutor.dispose();
  }
}

class AgentFactory {
  static LlmAgent create({
    required LlmService llmService,
    required String modelId,
    required String studentId,
    LlmTaskManager? taskManager,
    List<AgentTool>? tools,
  }) {
    final toolRegistry = ToolRegistry();
    if (tools != null) {
      for (final tool in tools) {
        toolRegistry.register(tool);
      }
    }

    final memoryStore = AgentMemoryStore();
    final idleExecutor = IdleExecutor(
      llmTaskManager: taskManager,
      studentId: studentId,
    );
    idleExecutor.startIdleMonitoring();

    final loop = AgentLoop(
      llmService: llmService,
      modelId: modelId,
      toolRegistry: toolRegistry,
      taskManager: taskManager,
    );

    return LlmAgent(
      loop: loop,
      toolRegistry: toolRegistry,
      memoryStore: memoryStore,
      idleExecutor: idleExecutor,
      studentId: studentId,
    );
  }
}
