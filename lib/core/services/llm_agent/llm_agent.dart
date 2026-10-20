import 'dart:async';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart' show LlmUsageMeter;
import 'package:studyking/core/services/prep_budget.dart' show PrepBudgetService;
import 'package:studyking/core/services/system_monitor_service.dart';

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
    String? sessionId,
  }) {
    return _loop.run(
      userMessage: message,
      studentId: _studentId,
      systemPrompt: systemPrompt,
      feature: feature,
      history: history,
      sessionId: sessionId,
    );
  }

  /// Streaming variant of [chat].
  ///
  /// Yields text chunks progressively so the UI can render a live reply while
  /// the agent loop executes tool calls. Tool-call markers are buffered
  /// internally by [AgentLoop.runStream]; the [onToolCall] callback is invoked
  /// once per executed tool for side-effect recording.
  Stream<String> chatStream({
    required String message,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
    Future<void> Function(AgentToolCall call)? onToolCall,
    String? sessionId,
  }) {
    return _loop.runStream(
      userMessage: message,
      studentId: _studentId,
      systemPrompt: systemPrompt,
      feature: feature,
      history: history,
      onToolCall: onToolCall,
      sessionId: sessionId,
    );
  }

  Future<void> enqueueBackgroundTask(String description, Future<void> Function() task) {
    // Post-lesson adherence, weak-topic reanalysis and next-topic prep are
    // off-period, LLM-heat prep: mark them heavy so the SystemMonitorService
    // can defer them under CPU/battery pressure (Vision Next-Term §4.3).
    return _idleExecutor.enqueue(description, task, requiresHeavy: true);
  }

  /// Enqueues an off-period prep task via [IdleExecutor.enqueuePrepTool],
  /// attributing it to the correct `feature`/`taskType` so that
  /// [LlmTaskManager] categorises prep spend under the right prep bucket
  /// (Vision Next-Term §4.1–§4.3) instead of the generic `background`
  /// bucket used by [enqueueBackgroundTask].
  ///
  /// The [task] closure must return a result map with a `success` boolean
  /// (and optionally an `error` string), matching the prep-tool contract
  /// ([PrepTool.execute] / [IdleExecutor.enqueuePrepTool]) so the executor
  /// can record success/failure against the correct prep category.
  Future<void> enqueuePrepTask(
    String description,
    Future<Map<String, dynamic>> Function() task, {
    required bool requiresHeavy,
    required String feature,
    required String taskType,
    String? subjectId,
    int estimatedInputTokens = 0,
    int estimatedOutputTokens = 0,
    String? jobId,
    String? payload,
  }) {
    return _idleExecutor.enqueuePrepTool(
      description,
      task,
      requiresHeavy: requiresHeavy,
      feature: feature,
      taskType: taskType,
      subjectId: subjectId,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
      jobId: jobId,
      payload: payload,
    );
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
    SystemMonitorService? systemMonitor,
    bool Function(DateTime now)? shouldDeferForQuietHours,
    bool Function(String subjectId)? isPrepEnabledForSubject,
    LlmUsageMeter? usageMeter,
    PrepBudgetService? prepBudgetService,
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
      systemMonitor: systemMonitor,
      shouldDeferForQuietHours: shouldDeferForQuietHours,
      isPrepEnabledForSubject: isPrepEnabledForSubject,
      usageMeter: usageMeter,
      prepBudgetService: prepBudgetService,
    );
    // Vision Next-Term §4.2: open the idle-tasks box and restore any queued
    // prep tasks before starting the polling monitor, so post-lesson work
    // enqueued by TutorService.endLesson() survives process termination.
    // Mirrors ingestion_providers.dart:179 (init() before startIdleMonitoring).
    // init() is fire-and-forget and non-throwing (see IdleExecutor.init).
    idleExecutor.init();
    idleExecutor.startIdleMonitoring();

    final loop = AgentLoop(
      llmService: llmService,
      modelId: modelId,
      toolRegistry: toolRegistry,
      taskManager: taskManager,
      idleExecutor: idleExecutor,
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
