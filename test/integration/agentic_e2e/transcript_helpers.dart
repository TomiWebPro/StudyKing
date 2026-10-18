/// Transcript artifact helpers for ailab grant-model e2e tests.
///
/// Vision-next-term §2.2 (Acceptance criteria):
/// > "With grant model configured, at least the teaching + mentor happy paths
/// > run against the real model and produce a transcript artifact."
///
/// This module provides a [dumpTranscript] utility that serializes an
/// [AgentResponse] plus [LlmUsageMeter] and [LlmTaskManager] state into a
/// JSON artifact written to `test/integration/agentic_e2e/transcripts/`.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

/// Directory where transcript artifacts are written.
/// Uses the test working directory (the project root when running
/// `flutter test` from the repo root).
final Directory transcriptDir = Directory(
  'test/integration/agentic_e2e/transcripts',
);

/// Serializes an [AgentResponse] into a JSON-compatible map suitable for
/// writing as a transcript artifact.
Map<String, dynamic> buildTranscript({
  required String scenarioName,
  required String userMessage,
  required String systemPrompt,
  required String modelId,
  required String feature,
  required AgentResponse response,
  required LlmUsageMeter usageMeter,
  required LlmTaskManager taskManager,
}) {
  return {
    'scenario': scenarioName,
    'timestamp': DateTime.now().toIso8601String(),
    'modelId': modelId,
    'feature': feature,
    'input': {
      'userMessage': userMessage,
      'systemPrompt': systemPrompt,
    },
    'toolCalls': response.toolCalls
        .map((tc) => {
              'toolName': tc.toolName,
              'arguments': tc.arguments,
              'result': tc.result,
            })
        .toList(),
    'finalContent': response.content,
    'error': response.error,
    'tokenUsage': {
      'records': usageMeter.getRecords().map((r) => r.toJson()).toList(),
      'totalTokens': usageMeter.getTotalTokens(),
      'totalCost': usageMeter.getTotalCost(),
    },
    'taskLifecycle': taskManager.tasks.map((t) => t.toJson()).toList(),
  };
}

/// Writes a transcript artifact to disk as JSON.
///
/// Returns the [File] that was written so callers can assert on its existence.
/// Creates the `transcripts/` directory if it does not already exist.
Future<File> dumpTranscript({
  required String scenarioName,
  required String userMessage,
  required String systemPrompt,
  required String modelId,
  required String feature,
  required AgentResponse response,
  required LlmUsageMeter usageMeter,
  required LlmTaskManager taskManager,
}) async {
  await transcriptDir.create(recursive: true);
  final transcript = buildTranscript(
    scenarioName: scenarioName,
    userMessage: userMessage,
    systemPrompt: systemPrompt,
    modelId: modelId,
    feature: feature,
    response: response,
    usageMeter: usageMeter,
    taskManager: taskManager,
  );
  final file = File('${transcriptDir.path}/$scenarioName.json');
  await file.writeAsString(jsonEncode(transcript), flush: true);
  return file;
}

/// Reads and parses a transcript artifact, asserting it is well-formed JSON
/// with the expected top-level keys.
///
/// Used by tests to verify that transcript artifacts are persisted and valid.
Future<Map<String, dynamic>> verifyTranscriptArtifact(String scenarioName) async {
  final file = File('${transcriptDir.path}/$scenarioName.json');
  expect(file.existsSync(), isTrue,
      reason: 'Transcript artifact for "$scenarioName" was not persisted to disk');
  final content = await file.readAsString();
  final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;

  // Well-formedness: every transcript must have these top-level keys.
  expect(json, containsPair('scenario', scenarioName));
  expect(json, containsPair('modelId', isNotNull));
  expect(json, containsPair('feature', isNotNull));
  expect(json, containsPair('toolCalls', isA<List>()));
  expect(json, containsPair('finalContent', isA<String>()));
  expect(json, containsPair('error', anyOf(isNull, isA<String>())));
  expect(json, containsPair('input', isA<Map>()));
  expect(json, containsPair('tokenUsage', isA<Map>()));
  expect(json, containsPair('taskLifecycle', isA<List>()));

  // input sub-fields
  final input = json['input'] as Map<String, dynamic>;
  expect(input, containsPair('userMessage', isA<String>()));
  expect(input, containsPair('systemPrompt', isA<String>()));

  // tokenUsage sub-fields
  final tokenUsage = json['tokenUsage'] as Map<String, dynamic>;
  expect(tokenUsage, containsPair('totalTokens', isA<int>()));
  expect(tokenUsage, containsPair('totalCost', isA<double>()));
  expect(tokenUsage, containsPair('records', isA<List>()));

  return json;
}
