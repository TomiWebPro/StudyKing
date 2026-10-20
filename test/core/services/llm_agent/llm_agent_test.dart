import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';

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
    String? sessionId,
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
  bool? enqueuedRequiresHeavy;

  // Captures for enqueuePrepTool (Vision Next-Term §4 prep wiring).
  String? prepEnqueuedDescription;
  Future<Map<String, dynamic>> Function()? prepEnqueuedTask;
  bool? prepEnqueuedRequiresHeavy;
  String? prepEnqueuedFeature;
  String? prepEnqueuedTaskType;
  String? prepEnqueuedSubjectId;
  int? prepEnqueuedEstimatedInputTokens;
  int? prepEnqueuedEstimatedOutputTokens;

  @override
  Future<void> enqueue(
    String description,
    Future<void> Function() task, {
    bool requiresHeavy = false,
    String? jobId,
    String? payload,
  }) async {
    enqueuedDescription = description;
    enqueuedTask = task;
    enqueuedRequiresHeavy = requiresHeavy;
  }

  @override
  Future<void> enqueuePrepTool(
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
  }) async {
    prepEnqueuedDescription = description;
    prepEnqueuedTask = task;
    prepEnqueuedRequiresHeavy = requiresHeavy;
    prepEnqueuedFeature = feature;
    prepEnqueuedTaskType = taskType;
    prepEnqueuedSubjectId = subjectId;
    prepEnqueuedEstimatedInputTokens = estimatedInputTokens;
    prepEnqueuedEstimatedOutputTokens = estimatedOutputTokens;
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
      // Post-lesson prep is heavy off-period work and must be marked so the
      // SystemMonitorService can defer it under load.
      expect(fakeIdleExecutor.enqueuedRequiresHeavy, isTrue);
    });

    test(
        'enqueuePrepTask delegates to idleExecutor.enqueuePrepTool with feature '
        'and taskType', () async {
      Future<Map<String, dynamic>> task() async => {'success': true};
      await agent.enqueuePrepTask(
        'Next topic lesson prep',
        task,
        requiresHeavy: true,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
        subjectId: 'chemistry',
      );

      expect(fakeIdleExecutor.prepEnqueuedDescription, 'Next topic lesson prep');
      expect(fakeIdleExecutor.prepEnqueuedTask, task);
      expect(fakeIdleExecutor.prepEnqueuedRequiresHeavy, isTrue);
      expect(fakeIdleExecutor.prepEnqueuedFeature, 'lesson_prep');
      expect(fakeIdleExecutor.prepEnqueuedTaskType, 'lesson_prep');
      expect(fakeIdleExecutor.prepEnqueuedSubjectId, 'chemistry');
    });

    test(
        'enqueuePrepTask routes through real IdleExecutor so LlmTask is recorded '
        'under lesson_prep (not background)', () async {
      // Proves the production wiring: the IdleAgent.enqueuePrepTask path reaches
      // IdleExecutor.enqueuePrepTool, which stamps the LlmTask record with the
      // correct taskType/feature instead of the generic 'background' bucket that
      // enqueueBackgroundTask would have used. (idle_executor_test.dart already
      // proves enqueuePrepTool's mechanism; this proves LlmAgent reaches it.)
      final manager = LlmTaskManager();
      final realExecutor = IdleExecutor(llmTaskManager: manager);
      final wiredAgent = LlmAgent(
        loop: fakeLoop,
        toolRegistry: fakeToolRegistry,
        memoryStore: fakeMemory,
        idleExecutor: realExecutor,
        studentId: 'test-student',
      );

      var taskRan = false;
      final completer = Completer<void>();
      await wiredAgent.enqueuePrepTask(
        'Next topic lesson prep',
        () async {
          taskRan = true;
          // Signal the test that the task body executed so assertions run after
          // the LlmTaskManager completeTask() call.
          completer.complete();
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
      );

      // enqueuePrepTool fires _tryExecuteNext() without awaiting it, so the task
      // may still be mid-flight. Wait for the task body to run.
      await completer.future;
      // Flush remaining microtasks so _tryExecuteNext's post-task
      // completeTask(startTask) continuation settles.
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(taskRan, isTrue);
      expect(manager.tasks, isNotEmpty,
          reason: 'LlmTaskManager should record the prep task');
      expect(manager.tasks.any((t) => t.taskType == 'lesson_prep'), isTrue,
          reason: 'next-topic lesson prep must be categorised as lesson_prep');
      expect(manager.tasks.any((t) => t.feature == 'lesson_prep'), isTrue);
      // The lesson_prep task must NOT be lost in the generic background bucket.
      expect(manager.tasks.any((t) => t.taskType == 'background'), isFalse);
      expect(manager.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
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
    late String hivePath;

    setUp(() async {
      // AgentFactory.create() now calls IdleExecutor.init(), which opens the
      // idle-tasks Hive box. Give each test a fresh, isolated box so the
      // persistence tests below are deterministic and the existing
      // construction tests are Hive-clean (no "box not open" warnings).
      hivePath =
          (await Directory.systemTemp.createTemp('sk_agent_factory_')).path;
      Hive.init(hivePath);
      await Hive.openBox(HiveBoxNames.idleTasks);
      await Hive.box(HiveBoxNames.idleTasks).clear();
    });

    tearDown(() async {
      // Let any fire-and-forget init()/persist box writes settle before closing.
      await Future.delayed(const Duration(milliseconds: 5));
      await Hive.close();
      try {
        await Directory(hivePath).delete(recursive: true);
      } catch (_) {
        // Best-effort temp cleanup.
      }
    });

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

    test(
        'create initializes the IdleExecutor so post-lesson prep tasks '
        'survive a simulated app restart', () async {
      // Vision Next-Term §4.2: TutorService.endLesson() enqueues post-lesson
      // prep tasks via LlmAgent.enqueuePrepTask -> IdleExecutor.enqueuePrepTool.
      // Those tasks must be restored by init() after a process termination.
      // This test reproduces the journey end-to-end through AgentFactory.create()
      // (which must call init(), otherwise the box is never opened and the tasks
      // are silently lost on termination — the bug tracked by this issue).
      final agent = AgentFactory.create(
        llmService: _FakeLlmService(),
        modelId: 'gpt-4',
        studentId: 'student-1',
        taskManager: LlmTaskManager(),
        shouldDeferForQuietHours: (_) => true, // keep tasks queued
      );

      // create() fires init() fire-and-forget; await the shared init future so
      // the box is open before enqueueing. If create() did NOT call init(),
      // initComplete resolves immediately and the box stays closed — the
      // enqueue/dispose/re-create sequence then persists nothing, restoring an
      // empty queue below (test fails, surfacing the bug).
      await agent.idleExecutor.initComplete;

      await agent.enqueuePrepTask(
        'post-lesson adherence check',
        () async => {'success': true},
        requiresHeavy: true,
        feature: 'background',
        taskType: 'background',
      );
      await agent.enqueuePrepTask(
        'next-topic lesson pre-generation',
        () async => {'success': true},
        requiresHeavy: true,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
        subjectId: 'chemistry',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      // Tasks are deferred (quiet hours) -> still queued and persisted.
      expect(agent.idleExecutor.queue.length, equals(2));
      await agent.idleExecutor.persistenceComplete;

      // Simulate process termination: dispose flushes the queue to disk and
      // cancels the polling timer.
      agent.idleExecutor.dispose();
      await agent.idleExecutor.persistenceComplete;

      // Simulate app relaunch: a fresh factory instance reuses the same box;
      // create() calls init() again, which opens the box and restores the queue.
      final restored = AgentFactory.create(
        llmService: _FakeLlmService(),
        modelId: 'gpt-4',
        studentId: 'student-1',
        taskManager: LlmTaskManager(),
        shouldDeferForQuietHours: (_) => true,
      );
      await restored.idleExecutor.initComplete;

      expect(restored.idleExecutor.queue.length, equals(2),
          reason: 'init() must restore queued prep tasks across a restart');

      final adherence = restored.idleExecutor.queue
          .firstWhere((t) => t.feature == 'background');
      expect(adherence.id, isNotEmpty);
      expect(adherence.taskType, equals('background'));

      final prep = restored.idleExecutor.queue
          .firstWhere((t) => t.feature == 'lesson_prep');
      expect(prep.subjectId, equals('chemistry'));
      expect(prep.taskType, equals('lesson_prep'));
      expect(prep.estimatedInputTokens, equals(8000));
      expect(prep.estimatedOutputTokens, equals(2000));
      expect(prep.taskFn, isNull,
          reason: 'restored tasks must carry no executable closure');

      restored.idleExecutor.dispose();
      await restored.idleExecutor.persistenceComplete;
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
