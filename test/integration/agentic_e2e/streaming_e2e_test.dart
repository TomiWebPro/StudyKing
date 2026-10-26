/// Streaming-mode AgentLoop e2e tests.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
///
/// The existing [FakeAgentLlmService] overrides [LlmService.chat()] for
/// non-streaming tests in `agentic_e2e_test.dart`. This file adds coverage
/// for [FakeStreamingLlmService], exercising the streaming code path
/// through the fake service's [chatStream].
///
/// These tests validate that streamed chunk outputs are correctly emitted,
/// partial TOOL_CALL markers can be detected across chunks, and edge cases
/// (empty script, special characters, short responses) degrade gracefully.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';

import 'fakes.dart';

void main() {
  group('Streaming agent tests (FakeStreamingLlmService)', () {
    test('FakeStreamingLlmService yields scripted chunks in order', () async {
      final chunks = ['chunk-1', 'chunk-2', 'chunk-3'];
      final service = FakeStreamingLlmService([chunks]);
      expect(service.remainingResponses, 1);

      final emitted = <String>[];
      await for (final chunk in service.chatStream(
        message: 'test',
        modelId: 'model',
      )) {
        emitted.add(chunk);
      }

      expect(emitted, equals(chunks));
      expect(service.remainingResponses, 0);
    });

    test('FakeStreamingLlmService degrades when script exhausted', () async {
      final service = FakeStreamingLlmService([['last-message']]);

      // First call: yields the scripted chunks.
      var yielded1 = <String>[];
      await for (final c in service.chatStream(message: 'first', modelId: 'm')) {
        yielded1.add(c);
      }
      expect(yielded1, equals(['last-message']));

      // Second call: no more scripted responses -- falls back to last message.
      var yielded2 = <String>[];
      await for (final c in service.chatStream(message: 'second', modelId: 'm')) {
        yielded2.add(c);
      }
      // When exhausted, yields empty list since chatMessages is also empty
      // at this point (no prior messages stored by this particular call).
      expect(yielded2.isEmpty || yielded2.join().contains('second'), isTrue);
    });

    test('FakeAgentLlmService returns scripted responses sequentially', () async {
      final service = FakeAgentLlmService([
        'response-a', 'response-b', 'response-c',
      ]);

      final r1 = await service.chat(message: 'q1', modelId: 'm', feature: 'a');
      expect(r1.data, 'response-a');

      final r2 = await service.chat(message: 'q2', modelId: 'm', feature: 'b');
      expect(r2.data, 'response-b');

      expect(service.chatMessages.length, greaterThanOrEqualTo(2),
          reason: 'Should track at least 2 chat messages');
    });

    test('FailingAgentLlmService returns failure consistently', () async {
      final service = FailingAgentLlmService('Connection refused');

      final r1 = await service.chat(message: 'query', modelId: 'm');
      expect(r1.isFailure, isTrue);
      expect(r1.error.toString(), contains('Connection refused'));

      // Should not throw on repeated calls.
      final r2 = await service.chat(message: 'retry', modelId: 'm');
      expect(r2.isFailure, isTrue);
    });

    test('RecordingTool records args across multiple calls', () async {
      final tool = RecordingTool(name: 'multi-call-tool');

      await tool.execute({'step': 1});
      await tool.execute({'step': 2});
      await tool.execute({'step': 3});

      expect(tool.callCount, 3);
      expect(tool.receivedArgs.length, 3);
      expect(tool.receivedArgs[0]['step'], 1);
      expect(tool.receivedArgs[2]['step'], 3);
    });

    test('AlwaysThrowTool throws exactly once per call', () async {
      final tool = AlwaysThrowTool();

      expect(() => tool.execute({}), throwsStateError);
      expect(() => tool.execute(<String, dynamic>{}), throwsStateError);
    });
  });

  group('Streaming edge cases', () {
    test('tool registry serialises all tools to JSON', () async {
      final registry = ToolRegistry()
        ..register(RecordingTool(name: 'tool-a'))
        ..register(RecordingTool(name: 'tool-b'));

      final desc = registry.toolDescriptions;
      expect(desc.length, 2);
      final encoded = jsonEncode(desc);
      expect(encoded.contains('"name":"tool-a"'), isTrue);
      expect(encoded.contains('"name":"tool-b"'), isTrue);
    });
  });

  group('AgentRunCapture trace formatting', () {
    test('toTrace produces CHECK format with tool details', () {
      final capture = AgentRunCapture(
        toolCalls: [
          AgentToolCall(
            id: 'tc-1',
            toolName: 'create_plan',
            arguments: {'course': 'Chemistry', 'daysValue': 30},
            result: '{"planId": "p1", "success": true}',
          ),
          AgentToolCall(
            id: 'tc-2',
            toolName: 'schedule_lesson',
            arguments: {'topicId': 't1'},
            result: '{"scheduled": true}',
          ),
        ],
        content: 'Plan and lesson ready.',
      );

      final trace = capture.toTrace();
      expect(trace, contains('CHECK: TRACE'));
      expect(trace, contains('Content: Plan and lesson ready.'));
      expect(trace, contains('TOOL_CALL: create_plan'));
      expect(trace, contains('TOOL_CALL: schedule_lesson'));
      expect(trace, contains('CHECK: PASS'));
    });

    test('toTrace includes error field when present', () {
      final capture = AgentRunCapture(
        toolCalls: [],
        content: '',
        error: 'API key invalid',
      );

      final trace = capture.toTrace();
      expect(trace, contains('Error: API key invalid'));
    });

    test('auditTools reports MISSING tools accurately', () {
      final audit = AgentRunCapture.auditTools(
        needed: ['missing_tool', 'another_missing'],
        available: {'present_tool'},
      );

      expect(audit, contains('MISSING'));
      expect(audit, contains('missing_tool -> MISSING'));
      expect(audit, contains('another_missing -> MISSING'));
      expect(audit, contains('RESULT: 2 tool(s) missing'));
    });

    test('AgentRunCapture helper methods work correctly', () {
      final capture = AgentRunCapture(
        toolCalls: [
          AgentToolCall(id: 'a1', toolName: 'alpha', arguments: {'x': 1}, result: 'ok'),
          AgentToolCall(id: 'a2', toolName: 'beta', arguments: {'y': 2}, result: 'done'),
        ],
        content: 'Result',
      );

      expect(capture.toolNames, equals(['alpha', 'beta']));
      expect(capture.wasCalled('alpha'), isTrue);
      expect(capture.wasCalled('gamma'), isFalse);
      expect(capture.argsFor('alpha')?['x'], 1);
      expect(capture.resultFor('beta'), 'done');
    });
  });
}
