/// Agentic e2e integration tests for the **streaming** [AgentLoop.runStream()]
/// path.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
///
/// The existing [agentic_e2e_test.dart] comprehensively tests [AgentLoop.run()]
/// (non-streaming), but [AgentLoop.runStream()] — the **production** conversation
/// path used by [LlmAgent.chatStream] (`llm_agent.dart:64`) and
/// [ConversationManager] (`conversation_manager.dart:442`) — had zero fake-mode
/// coverage (see `issues/closed/e2e-agent-loop-runstream-not-tested.md`).
///
/// These tests exercise [AgentLoop.runStream()] with [FakeStreamingLlmService],
/// which emits deterministic `Stream<String>` chunks containing `TOOL_CALL:` /
/// `ARGUMENTS:` directives. They cover:
///   - single tool call via streaming (text-before-marker yielded, syntax suppressed)
///   - multi-step tool sequence via streaming
///   - malformed JSON arguments via streaming
///   - unknown tool name via streaming
///   - partial marker detection (`TOOL_CALL: tool` arrives before `ARGUMENTS:`)
///   - max-iterations guard via streaming
///   - `onToolCall` callback invoked per tool execution
///   - LlmTaskManager task lifecycle + LlmUsageMeter wiring
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

import '../../helpers/hive_init_helper.dart';
import 'fakes.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });

  /// Collects all strings yielded by [stream] into a single concatenated
  /// string, preserving order and chunk boundaries.
  Future<String> collectStream(Stream<String> stream) async {
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  group('Agentic e2e - fake mode — AgentLoop.runStream()', () {
    group('single tool call via streaming', () {
      test('text before marker is yielded; TOOL_CALL syntax is suppressed',
          () async {
        // The LLM stream emits: human text, then a tool call directive.
        // Only the human text before the marker should be yielded to the
        // caller — the TOOL_CALL / ARGUMENTS lines must never appear in the
        // collected output.
        final fakeLlm = FakeStreamingLlmService([
          [
            'I will create your plan.',
            ' ',
            'TOOL_CALL: record\nARGUMENTS: {"query": "physics"}',
          ],
        ]);

        final tool = RecordingTool(
          name: 'record',
          returns: {'success': true, 'count': 2, 'items': ['A', 'B']},
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final stream = loop.runStream(
          userMessage: 'Find physics questions',
          studentId: 'stream-student-1',
          systemPrompt: 'You are a tutor.',
        );

        final collected = await collectStream(stream);

        // The human-readable text before the tool call was yielded.
        expect(collected, contains('I will create your plan.'));

        // TOOL_CALL / ARGUMENTS syntax must NEVER appear in the yielded output.
        expect(collected, isNot(contains('TOOL_CALL')));
        expect(collected, isNot(contains('ARGUMENTS')));
        expect(collected, isNot(contains('"query"')));

        // The tool was still dispatched and executed.
        expect(tool.callCount, 1);
        expect(tool.receivedArgs.first['query'], 'physics');
      });

      test('text is yielded progressively (chunk by chunk)', () async {
        // Verify that streaming yields text in the same order as the chunks
        // arrive, not all at once.
        final fakeLlm = FakeStreamingLlmService([
          [
            'Hello ',
            'there, ',
            'here is your answer.',
          ],
        ]);

        final registry = ToolRegistry(); // no tools — final response only
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final collected = <String>[];
        await for (final chunk in loop.runStream(
          userMessage: 'Hi',
          studentId: 'stream-student-2',
          systemPrompt: 'You are a tutor.',
        )) {
          collected.add(chunk);
        }

        // Each chunk was yielded separately.
        expect(collected, hasLength(3));
        expect(collected[0], 'Hello ');
        expect(collected[1], 'there, ');
        expect(collected[2], 'here is your answer.');
      });
    });

    group('multi-step tool sequence via streaming', () {
      test('both tools execute in order, text yielded, syntax suppressed',
          () async {
        final fakeLlm = FakeStreamingLlmService([
          // Turn 1: create_plan tool call
          [
            'Creating your plan.',
            'TOOL_CALL: create_plan\n'
            'ARGUMENTS: {"course": "IB Chemistry", "daysValue": 90, "hoursValue": 2}',
          ],
          // Turn 2: schedule_lesson tool call
          [
            'Scheduling first lesson.',
            'TOOL_CALL: schedule_lesson\n'
            'ARGUMENTS: {"topicId": "chem-1", "topicTitle": "Atoms", '
            '"subjectId": "chem", "scheduledTime": "2026-01-15T10:00:00Z", '
            '"durationMinutes": 45}',
          ],
          // Turn 3: final response
          ["Your Chemistry study plan is ready and the first lesson is scheduled."],
        ]);

        final planTool = RecordingTool(
          name: 'create_plan',
          returns: {'success': true, 'planId': 'plan-1', 'totalDays': 90},
        );
        final scheduleTool = RecordingTool(
          name: 'schedule_lesson',
          returns: {'success': true, 'message': 'scheduled'},
        );

        final registry = ToolRegistry()
          ..register(planTool)
          ..register(scheduleTool);

        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final collected = await collectStream(loop.runStream(
          userMessage: 'I want to learn IB Chemistry in 90 days.',
          studentId: 'stream-student-3',
          systemPrompt: 'You are an academic mentor.',
        ));

        // Both tools were called in order.
        expect(planTool.callCount, 1);
        expect(scheduleTool.callCount, 1);

        // Text from all turns was yielded.
        expect(collected, contains('Creating your plan.'));
        expect(collected, contains('Scheduling first lesson.'));
        expect(collected, contains('Your Chemistry study plan is ready'));

        // No TOOL_CALL / ARGUMENTS syntax leaked.
        expect(collected, isNot(contains('TOOL_CALL')));
        expect(collected, isNot(contains('ARGUMENTS')));
        expect(collected, isNot(contains('create_plan')));
      });
    });

    group('malformed JSON arguments via streaming', () {
      test('degrades to empty args, tool still executes, no syntax leak',
          () async {
        final fakeLlm = FakeStreamingLlmService([
          [
            'Let me try that.',
            'TOOL_CALL: record\nARGUMENTS: {this is not valid json}',
          ],
          ['I will try again with valid input.'],
        ]);

        final tool = RecordingTool(name: 'record');
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final collected = await collectStream(loop.runStream(
          userMessage: 'Do something with bad args',
          studentId: 'stream-student-4',
          systemPrompt: 'You are a tutor.',
        ));

        // Tool was called with empty args due to parse error.
        expect(tool.callCount, 1);
        expect(tool.receivedArgs.first, isEmpty);

        // Final content from second LLM turn.
        expect(collected, contains('I will try again with valid input.'));

        // No syntax leaked.
        expect(collected, isNot(contains('TOOL_CALL')));
        expect(collected, isNot(contains('ARGUMENTS')));
      });
    });

    group('unknown tool name via streaming', () {
      test('surfaces descriptive error; never crashes; no syntax leak',
          () async {
        final fakeLlm = FakeStreamingLlmService([
          [
            'I need to use a tool.',
            'TOOL_CALL: nonexistent_tool\nARGUMENTS: {}',
          ],
        ]);

        final registry = ToolRegistry()..register(RecordingTool(name: 'record'));
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final collected = await collectStream(loop.runStream(
          userMessage: 'Do something',
          studentId: 'stream-student-5',
          systemPrompt: 'You are a tutor.',
        ));

        // Content must name the missing tool.
        expect(collected, contains('nonexistent_tool'));
        expect(collected, isNot(contains('Instance of')));

        // No TOOL_CALL / ARGUMENTS syntax leaked.
        expect(collected, isNot(contains('TOOL_CALL')));
        expect(collected, isNot(contains('ARGUMENTS')));
      });
    });

    group('partial marker detection via streaming', () {
      test('TOOL_CALL marker arrives before ARGUMENTS — tool waits for completeness',
          () async {
        // Simulate a real LLM stream where the tool call directive arrives
        // across multiple chunks:
        //   chunk 1: "I will create the plan. TOOL_CALL: record"
        //   chunk 2: "\nARGUMENTS: {"query": "physics"}"
        //
        // When chunk 1 arrives, the buffer is:
        //   "I will create the plan. TOOL_CALL: record"
        // The regex finds `TOOL_CALL:` and `record` as the tool name, but
        // `ARGUMENTS:` is NOT present — so this is a **partial** tool call.
        // The code should yield "I will create the plan." (text before marker)
        // and hold back the marker + tool name, waiting for ARGUMENTS.
        //
        // When chunk 2 arrives, the buffer becomes complete and the tool
        // executes.
        final fakeLlm = FakeStreamingLlmService([
          [
            'I will create the plan. ',
            'TOOL_CALL: record',
            '\nARGUMENTS: {"query": "physics"}',
          ],
          ['Plan created.'],
        ]);

        final tool = RecordingTool(
          name: 'record',
          returns: {'success': true, 'planId': 'plan-1'},
        );
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final collected = await collectStream(loop.runStream(
          userMessage: 'Plan something',
          studentId: 'stream-student-6',
          systemPrompt: 'You are a mentor.',
        ));

        // The tool was dispatched once (not twice or zero times).
        expect(tool.callCount, 1);
        expect(tool.receivedArgs.first['query'], 'physics');

        // Human text was yielded.
        expect(collected, contains('I will create the plan.'));
        expect(collected, contains('Plan created.'));

        // No TOOL_CALL / ARGUMENTS syntax leaked to the caller.
        expect(collected, isNot(contains('TOOL_CALL')));
        expect(collected, isNot(contains('ARGUMENTS')));
        expect(collected, isNot(contains('record')));
      });
    });

    group('onToolCall callback', () {
      test('callback invoked once per tool execution with correct data', () async {
        final fakeLlm = FakeStreamingLlmService([
          [
            'Using tools.',
            'TOOL_CALL: record\nARGUMENTS: {"x": 1}',
          ],
          [
            'More tools.',
            'TOOL_CALL: record\nARGUMENTS: {"x": 2}',
          ],
          ['Done.'],
        ]);

        final tool = RecordingTool(name: 'record');
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final capturedCalls = <AgentToolCall>[];
        final collected = await collectStream(loop.runStream(
          userMessage: 'Call record twice',
          studentId: 'stream-callback-student',
          systemPrompt: 'You are a mentor.',
          onToolCall: (call) async {
            capturedCalls.add(call);
          },
        ));

        // Callback was invoked for each of the two tool calls.
        expect(capturedCalls, hasLength(2));
        expect(capturedCalls[0].toolName, 'record');
        expect(capturedCalls[0].arguments['x'], 1);
        expect(capturedCalls[1].toolName, 'record');
        expect(capturedCalls[1].arguments['x'], 2);

        // Tool was executed twice.
        expect(tool.callCount, 2);
        expect(collected, contains('Done.'));
      });
    });

    group('max iterations guard via streaming', () {
      test('stops after maxIterations when LLM keeps calling tools', () async {
        // Script 20 tool-call responses — the loop should stop after
        // [AgentLoop.maxIterations] (10) iterations.
        final fakeLlm = FakeStreamingLlmService(
          List.generate(
            20,
            (i) => ['TOOL_CALL: record\nARGUMENTS: {}'],
          ),
        );

        final tool = RecordingTool(name: 'record');
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final collected = await collectStream(loop.runStream(
          userMessage: 'Keep calling tools',
          studentId: 'stream-student-7',
          systemPrompt: 'You are a mentor.',
        ));

        // Should have hit the max-iterations guard.
        expect(tool.callCount, AgentLoop.maxIterations);

        // The loop sets a default completion message when finalContent is empty.
        expect(collected, contains('completed the required actions'));

        // No syntax leaked.
        expect(collected, isNot(contains('TOOL_CALL')));
        expect(collected, isNot(contains('ARGUMENTS')));
      });
    });

    group('LlmTaskManager task lifecycle via streaming', () {
      test('task created/started/completed on the shared manager', () async {
        final taskManager = LlmTaskManager();

        final fakeLlm = FakeStreamingLlmService(
          [
            ['TOOL_CALL: record\nARGUMENTS: {"x": 1}'],
            ['Done.'],
          ],
          taskManager: taskManager,
        );

        final tool = RecordingTool(name: 'record');
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
          taskManager: taskManager,
        );

        await collectStream(loop.runStream(
          userMessage: 'Test task tracking (streaming)',
          studentId: 'stream-student-8',
          systemPrompt: 'You are a tutor.',
          feature: 'mentor',
        ));

        // Exactly one task was created for the agent turn.
        expect(taskManager.tasks, hasLength(1));
        final task = taskManager.tasks.first;
        expect(task.feature, 'mentor');
        expect(task.modelId, 'test-model');
        // Task completed successfully.
        expect(task.status, LlmTaskStatus.done);
        expect(task.endTime, isNotNull);
      });

      test('task marked completed even when tool throws', () async {
        final taskManager = LlmTaskManager();

        final fakeLlm = FakeStreamingLlmService(
          [
            ['TOOL_CALL: always_throw\nARGUMENTS: {}'],
            ['I see there was an error. Let me handle this differently.'],
          ],
          taskManager: taskManager,
        );

        final registry = ToolRegistry()..register(AlwaysThrowTool());
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
          taskManager: taskManager,
        );

        final collected = await collectStream(loop.runStream(
          userMessage: 'Trigger a failing tool (streaming)',
          studentId: 'stream-student-9',
          systemPrompt: 'You are a tutor.',
        ));

        // Tool error was caught — AgentLoop did not throw.
        expect(collected, contains('differently'));
        expect(collected, isNot(contains('TOOL_CALL')));

        // Task was created and completed (loop catches tool errors).
        expect(taskManager.tasks, hasLength(1));
        final task = taskManager.tasks.first;
        expect(task.status, LlmTaskStatus.done);
      });
    });

    group('LlmUsageMeter wiring via streaming', () {
      test('meter initialises and accepts records; task lifecycle tracked', () async {
        final usageMeter = LlmUsageMeter();
        final taskManager = LlmTaskManager();

        final fakeLlm = FakeStreamingLlmService(
          [
            ['TOOL_CALL: record\nARGUMENTS: {}'],
            ['Final answer.'],
          ],
          taskManager: taskManager,
          usageMeter: usageMeter,
        );

        final tool = RecordingTool(name: 'record');
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
          taskManager: taskManager,
        );

        await collectStream(loop.runStream(
          userMessage: 'Test streaming usage metering',
          studentId: 'stream-student-10',
          systemPrompt: 'You are a tutor.',
        ));

        // In fake streaming mode, the overridden chatStream does not record
        // usage (no HTTP call), but the meter is correctly held by the service
        // for the real model path. Verify the meter can accept records.
        expect(usageMeter.getRecords(), isEmpty);

        // Record a synthetic usage entry to prove the meter works.
        usageMeter.recordUsage(
          id: 'test-streaming-usage-1',
          feature: 'agent',
          modelId: 'test-model',
          inputTokens: 100,
          outputTokens: 50,
        );
        expect(usageMeter.getRecords(), hasLength(1));
        expect(usageMeter.getTotalTokens(), 150);
        expect(usageMeter.getTotalCost(), greaterThan(0));

        // Task lifecycle was tracked.
        expect(taskManager.tasks, hasLength(1));
        expect(taskManager.tasks.first.status, LlmTaskStatus.done);
      });
    });
  });
}
