/// Retry-with-backoff e2e tests for the [AgentLoop] → [LlmService] → HTTP stack.
///
/// Solidification criteria from `issues/closed/e2e-llm-grant-no-retry-backoff.md`:
/// "An e2e test in `test/integration/agentic_e2e/` injects a transient 503 /
/// SocketException (`MockClient` that fails the first N calls then succeeds)
/// and asserts:
/// 1. The request eventually succeeds via retry-with-backoff on the primary
///    provider (not by burning the backup).
/// 2. Backoff delays are non-zero (verifiable via a `Stopwatch`-based assertion
///    in the test).
/// 3. After exhausting retries, the failover path still works for genuine
///    persistent failures."
///
/// Also matches docs/vision_next_term.md §2.1 harness rules:
/// > "Flaky-network resilient: retry with backoff, timeout per step,
/// > CHECK: PASS/FAIL style verdict per scenario."
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

import '../../helpers/hive_init_helper.dart';
import 'fakes.dart';

/// Builds an OpenRouter chat-completion JSON response body.
String _okJson(String content) => jsonEncode({
      'choices': [
        {'message': {'content': content}},
      ],
      'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
    });

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });

  setUp(() async {
    // Clear shared Hive boxes so each test's meter/manager is fresh.
    final usageBox = await Hive.openBox(HiveBoxNames.llmUsageRecords);
    await usageBox.clear();
    final tasksBox = await Hive.openBox(HiveBoxNames.llmTasks);
    await tasksBox.clear();
  });

  group('Retry-with-backoff (docs/vision_next_term.md §2.1)', () {
    // -----------------------------------------------------------------------
    // LlmRetryConfig — the configuration object that controls retry behaviour.
    // -----------------------------------------------------------------------
    group('LlmRetryConfig', () {
      test('default config: maxAttempts=3, initialDelay=1s, multiplier=2.0', () {
        const config = LlmRetryConfig();
        expect(config.maxAttempts, 3);
        expect(config.initialDelay, const Duration(seconds: 1));
        expect(config.multiplier, 2.0);
      });

      test('custom config preserves all fields', () {
        const config = LlmRetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 50),
          multiplier: 3.0,
        );
        expect(config.maxAttempts, 5);
        expect(config.initialDelay, const Duration(milliseconds: 50));
        expect(config.multiplier, 3.0);
      });
    });

    // -----------------------------------------------------------------------
    // Transient 503 → retry with exponential backoff, eventually succeed.
    // Solidification criterion 1 & 2: retry on primary, non-zero delays.
    // -----------------------------------------------------------------------
    group('transient 503 retried on primary (no backup)', () {
      test(
          'succeeds after 2 transient 503s; backoff delays are non-zero and '
          'grow exponentially', () async {
        final stopwatch = Stopwatch()..start();
        int callCount = 0;
        final callTimes = <int>[];

        final client = MockClient((request) async {
          callTimes.add(stopwatch.elapsedMilliseconds);
          callCount++;
          // Fail the first 2 calls (initial + first retry), succeed on 3rd.
          if (callCount < 3) {
            return http.Response('503 Service Unavailable', 503);
          }
          return http.Response(
            _okJson('Recovered after retry'),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        // Short backoff to keep the test fast but still non-zero.
        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 50),
          multiplier: 2.0,
        );

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'primary-key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          retryConfig: retryConfig,
        );

        final result = await service.chat(
          message: 'Hello',
          modelId: 'test-model',
          feature: 'teaching',
        );

        // Criterion 1: succeeds via retry on primary provider.
        expect(result.isSuccess, isTrue);
        expect(result.data, 'Recovered after retry');
        // initial + 2 retries = 3 HTTP calls (no backup burned).
        expect(callCount, 3);

        // Criterion 2: backoff delays are non-zero and exponential.
        // With initialDelay=50ms, multiplier=2.0:
        //   retry 0 → ~50ms delay, retry 1 → ~100ms delay
        expect(callTimes.length, 3);
        final delay1 = callTimes[1] - callTimes[0];
        final delay2 = callTimes[2] - callTimes[1];
        expect(delay1, greaterThanOrEqualTo(40),
            reason: 'first backoff delay should be ~50ms');
        expect(delay2, greaterThanOrEqualTo(90),
            reason: 'second backoff delay should be ~100ms (50ms * 2.0)');
        expect(delay2, greaterThan(delay1),
            reason: 'backoff must grow exponentially');

        stopwatch.stop();
      });

      test('succeeds after retry of a transient SocketException', () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          if (callCount < 3) {
            // Simulate a network blip — the handler throws, which _callWithFallback
            // catches and converts to Result.failure(e.toString()).
            throw const SocketException('Failed host: api.openrouter.ai');
          }
          return http.Response(
            _okJson('Connected after socket retry'),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 20),
          multiplier: 1.0,
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          httpClient: client,
          retryConfig: retryConfig,
        );

        final result = await service.chat(message: 'Hello', modelId: 'm');

        expect(result.isSuccess, isTrue);
        expect(result.data, 'Connected after socket retry');
        expect(callCount, 3);
      });

      test('succeeds after transient timeout exception', () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          if (callCount < 2) {
            throw TimeoutException('Request timed out', const Duration(seconds: 5));
          }
          return http.Response(
            _okJson('Recovered from timeout'),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 20),
          multiplier: 1.0,
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          httpClient: client,
          retryConfig: retryConfig,
        );

        final result = await service.chat(message: 'Hi', modelId: 'm');

        expect(result.isSuccess, isTrue);
        expect(result.data, 'Recovered from timeout');
        expect(callCount, 2); // initial + 1 retry
      });
    });

    // -----------------------------------------------------------------------
    // Retry exhaustion → failover to backup (criterion 3).
    // -----------------------------------------------------------------------
    group('exhaust retries then failover', () {
      test(
          'after exhausting retries on primary, fails over to backup and succeeds',
          () async {
        int primaryCalls = 0;
        int backupCalls = 0;

        final client = MockClient((request) async {
          // Distinguish by Authorization header: primary uses 'primary-key',
          // backup uses 'backup-key'.
          final auth = request.headers['Authorization'] ?? '';
          if (auth.contains('primary-key')) {
            primaryCalls++;
            return http.Response('503 Service Unavailable', 503);
          } else {
            backupCalls++;
            return http.Response(
              _okJson('Served by backup'),
              200,
              headers: {'Content-Type': 'application/json'},
            );
          }
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(milliseconds: 10),
          multiplier: 1.0,
        );

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'primary-key',
          backupProvider: LlmProvider.openAI,
          backupApiKey: 'backup-key',
          backupModel: 'backup-model',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          retryConfig: retryConfig,
        );

        final result = await service.chat(
          message: 'Hello',
          modelId: 'primary-model',
        );

        // After exhausting retries (2) on primary, failed over to backup.
        expect(result.isSuccess, isTrue);
        expect(result.data, 'Served by backup');
        expect(primaryCalls, 3); // initial + 2 retries
        expect(backupCalls, 1);
      });

      test(
          'after exhausting retries with no backup, returns failure', () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          return http.Response('503 Service Unavailable', 503);
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(milliseconds: 10),
          multiplier: 1.0,
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          retryConfig: retryConfig,
          httpClient: client,
        );

        final result = await service.chat(message: 'Hi', modelId: 'm');

        // No backup — after exhausting retries, returns failure.
        expect(result.isFailure, isTrue);
        expect(callCount, 3); // initial + 2 retries, no backup
      });
    });

    // -----------------------------------------------------------------------
    // Non-transient errors must NOT be retried.
    // -----------------------------------------------------------------------
    group('non-transient errors are not retried', () {
      test('401 Unauthorized — single HTTP call, no retry', () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          return http.Response('Unauthorized', 401);
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          multiplier: 1.0,
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          retryConfig: retryConfig,
          httpClient: client,
        );

        final result = await service.chat(message: 'Hi', modelId: 'm');

        expect(result.isFailure, isTrue);
        expect(callCount, 1); // no retries for 401
      });

      test('404 Not Found — single HTTP call, no retry', () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          return http.Response('Not Found', 404);
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          retryConfig: retryConfig,
          httpClient: client,
        );

        final result = await service.chat(message: 'Hi', modelId: 'm');

        expect(result.isFailure, isTrue);
        expect(callCount, 1);
      });

      test('429 Too Many Requests — single HTTP call, no retry', () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          return http.Response('Too Many Requests', 429);
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          retryConfig: retryConfig,
          httpClient: client,
        );

        final result = await service.chat(message: 'Hi', modelId: 'm');

        expect(result.isFailure, isTrue);
        expect(callCount, 1);
      });
    });

    // -----------------------------------------------------------------------
    // AgentLoop integration — retry through the full agentic stack.
    // -----------------------------------------------------------------------
    group('AgentLoop integration through LlmService HTTP stack', () {
      test(
          'AgentLoop succeeds when LlmService retries transient 503 '
          '(CHECK: PASS verdict)', () async {
        int httpCallCount = 0;

        // Mock HTTP client: first call 503, second call returns a tool-call
        // response, third call (tool-result feedback) returns final content.
        final client = MockClient((request) async {
          httpCallCount++;
          if (httpCallCount == 1) {
            // Initial call — transient 503.
            return http.Response('503 Service Unavailable', 503);
          }
          if (httpCallCount == 2) {
            // Retry succeeds — LLM emits a tool call.
            return http.Response(
              _okJson('TOOL_CALL: record\nARGUMENTS: {"query": "retry-test"}'),
              200,
              headers: {'Content-Type': 'application/json'},
            );
          }
          // Third call: LLM returns final content after tool result.
          return http.Response(
            _okJson('CHECK: PASS - retry succeeded, tool executed.'),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 20),
          multiplier: 1.0,
        );

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          retryConfig: retryConfig,
        );

        // Use the real RecordingTool from fakes.dart.
        final tool = RecordingTool(name: 'record');
        final registry = ToolRegistry()..register(tool);

        final loop = AgentLoop(
          llmService: service,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Test retry through the agentic stack',
          studentId: 'retry-stack-student',
          systemPrompt: 'You are a tutor. Use tools when needed.',
          feature: 'teaching',
        );

        // The AgentLoop completed successfully despite the transient 503.
        expect(response.error, isNull, reason: 'AgentLoop should not surface an error');
        expect(response.content, contains('CHECK: PASS'));

        // The tool was invoked (proving the retry succeeded and the LLM
        // response was parsed correctly).
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'record');
        expect(tool.callCount, 1);
        expect(tool.receivedArgs.first['query'], 'retry-test');

        // HTTP layer was called 3 times: initial (503) → retry (tool call)
        // → tool-result feedback (final).
        expect(httpCallCount, 3);
      });

      test(
          'AgentLoop surfaces error after retry exhaustion (CHECK: FAIL verdict)',
          () async {
        int httpCallCount = 0;

        final client = MockClient((request) async {
          httpCallCount++;
          // Always fails — no backup configured, retries exhausted.
          return http.Response('503 Service Unavailable', 503);
        });

        const retryConfig = LlmRetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(milliseconds: 10),
          multiplier: 1.0,
        );

        final config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        );
        final service = LlmService(
          config: config,
          httpClient: client,
          retryConfig: retryConfig,
        );

        final registry = ToolRegistry();
        final loop = AgentLoop(
          llmService: service,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'What is the capital of France?',
          studentId: 'retry-fail-student',
          systemPrompt: 'You are a tutor.',
          feature: 'teaching',
        );

        // AgentLoop gets a failure from LlmService after retries exhausted.
        // It should surface an error response, not crash.
        expect(response.error, isNotNull);
        expect(response.content, contains('error'));

        // HTTP layer: initial + 2 retries = 3 calls, no backup.
        expect(httpCallCount, 3);
      });
    });

    // -----------------------------------------------------------------------
    // Token metering survives transient retries.
    // -----------------------------------------------------------------------
    group('token metering with retries', () {
      test('LlmUsageMeter records tokens only on successful response after retry',
          () async {
        int callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          if (callCount < 3) {
            return http.Response('503 Service Unavailable', 503);
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'OK after retries'}}
              ],
              'usage': {'prompt_tokens': 25, 'completion_tokens': 12},
            }),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        });

        final taskManager = LlmTaskManager();
        await taskManager.init();
        final usageMeter = LlmUsageMeter();
        await usageMeter.init();

        const retryConfig = LlmRetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 20),
          multiplier: 1.0,
        );

        final service = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'key',
          ),
          httpClient: client,
          retryConfig: retryConfig,
          taskManager: taskManager,
          usageMeter: usageMeter,
        );

        final result = await service.chat(
          message: 'Hello',
          modelId: 'm',
          feature: 'teaching',
        );

        expect(result.data, 'OK after retries');

        // Token usage is recorded only from the successful response.
        final records = usageMeter.getRecords();
        expect(records, isNotEmpty);
        final record = records.last;
        expect(record.inputTokens, 25);
        expect(record.outputTokens, 12);
        expect(record.feature, 'teaching');
      });
    });
  });
}
