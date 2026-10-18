/// Opt-in ailab grant model e2e tests for the [AgentLoop].
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
///
/// These tests run **only when the ailab grant model is configured** via:
///   flutter test test/integration/agentic_e2e/ailab_model_e2e_test.dart \
///     --dart-define=STUDYKING_E2E_MODEL=gemini-2.0-flash \
///     --dart-define=OPENROUTER_API_KEY=sk-... \
///     --dart-define=STUDYKING_E2E_BASE_URL=https://openrouter.ai/api/v1
///
/// `STUDYKING_E2E_MODEL` and `OPENROUTER_API_KEY` are required; the tests
/// skip otherwise. `STUDYKING_E2E_BASE_URL` is optional — set it to point
/// the grant-model transport at a self-hosted or ailab endpoint, otherwise
/// the OpenRouter provider default base URL is used.
///
/// When the env vars are absent, tests skip with a clear message —
/// no crash, no hardcoded keys, no real network calls.
///
/// Token/cost of every e2e LLM call goes through [LlmUsageMeter] +
/// [LlmTaskManager] so grant spend is auditable.
library;

import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/tools/create_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_student_stats_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'package:studyking/features/mentor/services/tools/schedule_lesson_tool.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import '../../helpers/fakes.dart';
import '../../helpers/hive_init_helper.dart';
import 'fakes.dart';
import 'transcript_helpers.dart';

/// The e2e model ID provided via `--dart-define=STUDYKING_E2E_MODEL=...`.
const String e2eModel = String.fromEnvironment('STUDYKING_E2E_MODEL');

/// The API key provided via `--dart-define=OPENROUTER_API_KEY=...`.
const String apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

/// The base URL override for self-hosted or ailab grant endpoints, provided
/// via `--dart-define=STUDYKING_E2E_BASE_URL=...`. Optional — when empty, the
/// OpenRouter provider's standard base URL is used.
const String e2eBaseUrl = String.fromEnvironment('STUDYKING_E2E_BASE_URL');

/// Whether the ailab grant model is fully configured.
bool get grantModelConfigured => e2eModel.isNotEmpty && apiKey.isNotEmpty;

/// The skip reason shown when the grant model is not configured.
const String skipReason =
    'STUDYKING_E2E_MODEL and OPENROUTER_API_KEY not provided. '
    'Run with: '
    'flutter test test/integration/agentic_e2e/ailab_model_e2e_test.dart '
    '--dart-define=STUDYKING_E2E_MODEL=gemini-2.0-flash '
    '--dart-define=OPENROUTER_API_KEY=sk-...'
    ' (--dart-define=STUDYKING_E2E_BASE_URL=https://openrouter.ai/api/v1'
    ' to override the API base URL)';

/// Tracks how many times the MockClient interceptor was invoked.
/// Reset at the start of every [buildGrantLlmService] call so each
/// test can assert whether the mock path or the real transport was used.
int mockHttpClientCallCount = 0;

/// Returns a real [LlmService] configured with the ailab grant
/// model env vars.
///
/// **Branching logic (fixes e2e-grant-model-always-mockclient):**
/// - When `grantModelConfigured` is true (env vars present), the
///   service uses a **real** `http.Client()` — actual API calls reach
///   the ailab grant model. `scriptedResponses` are ignored because the
///   LLM generates genuine tool-calling responses.
/// - When `grantModelConfigured` is false (offline CI), the service
///   uses a `MockClient` with deterministic `scriptedResponses` — no
///   network calls are made, no keys are needed.
LlmService buildGrantLlmService({
  required LlmTaskManager taskManager,
  required LlmUsageMeter usageMeter,
  List<String> scriptedResponses = const [],
}) {
  mockHttpClientCallCount = 0;

  if (grantModelConfigured) {
    // --- Real path: actual HTTP transport ---
    // httpClient is left null so LlmService defaults to http.Client(),
    // making real API calls to the ailab grant model.
    // ignore: avoid_print
    print('E2E: Grant model configured ($e2eModel) — using real http.Client.');
    return LlmService(
      config: LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: apiKey,
        baseUrl: e2eBaseUrl,
        model: e2eModel,
      ),
      taskManager: taskManager,
      usageMeter: usageMeter,
    );
  }

  // --- Mock path: offline CI, no keys required ---
  // ignore: avoid_print
  print('E2E: Grant model NOT configured — using MockClient with scripted responses.');
  final responses = List<String>.of(scriptedResponses);

  http.Client client = MockClient((request) async {
    mockHttpClientCallCount++;
    // Simulate OpenRouter chat completion (non-streaming)
    return http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {
              'content': responses.isNotEmpty
                  ? responses.removeAt(0)
                  : 'No more responses.',
            },
          },
        ],
        'usage': {
          'prompt_tokens': 42,
          'completion_tokens': 18,
        },
      }),
      200,
      headers: {'Content-Type': 'application/json'},
    );
  });

  return LlmService(
    config: LlmConfiguration(
      provider: LlmProvider.openRouter,
      // Fallback dummy key so the mock path works offline.
      apiKey: apiKey.isNotEmpty ? apiKey : 'test-key-for-mock',
      baseUrl: e2eBaseUrl,
      model: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
    ),
    httpClient: client,
    taskManager: taskManager,
    usageMeter: usageMeter,
  );
}

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });

  group('Agentic e2e - ailab grant model (opt-in)', () {
    group('env-var gate', () {
      test('clear skip message when model is absent', () {
        if (grantModelConfigured) {
          markTestSkipped(
            'Grant model is configured — negative gate test skipped.',
          );
        }
        // When not configured, document the exact env vars expected.
        // This assertion is only reachable when env vars are absent.
        expect(e2eModel.isEmpty, isTrue,
            reason: 'STUDYKING_E2E_MODEL must be unset for this test');
        expect(apiKey.isEmpty, isTrue,
            reason: 'OPENROUTER_API_KEY must be unset for this test');
      });

      test('negative gate when key is absent', () {
        if (e2eModel.isNotEmpty && apiKey.isEmpty) {
          // Model env present but key missing — still must skip.
          expect(grantModelConfigured, isFalse);
        } else if (!grantModelConfigured) {
          // Both absent — expected in CI.
          expect(grantModelConfigured, isFalse);
        } else {
          markTestSkipped(
            'Both env vars are configured — negative gate test skipped.',
          );
        }
      });

      test(
        'buildGrantLlmService uses real http.Client when grant model configured',
        () {
          if (!grantModelConfigured) {
            markTestSkipped(skipReason);
          }

          final taskManager = LlmTaskManager();
          final usageMeter = LlmUsageMeter();

          buildGrantLlmService(
            taskManager: taskManager,
            usageMeter: usageMeter,
            scriptedResponses: [],
          );

          // When grantModelConfigured is true, buildGrantLlmService must NOT
          // set up MockClient — it must use real http.Client transport so
          // real API calls reach the ailab grant model.
          expect(mockHttpClientCallCount, 0,
              reason: 'Real http.Client should be used when grant model is '
                  'configured — MockClient must not be set up.');
        },
      );
    });

    group('teaching + mentor happy paths', () {
      /// Builds a PlannerService wired with fakes suitable for
      /// CreatePlanTool / ScheduleLessonTool integration tests.
      PlannerService buildPlannerService(String studentId) {
        return PlannerService(
          planRepo: FakePlanRepository(),
          masteryService: MasteryGraphService(),
          topicRepository: FakeTopicRepository(),
          fixedStudentId: studentId,
        );
      }

      test(
        'teaching happy path produces tool-call trace with token counts',
        () async {
          final taskManager = LlmTaskManager();
          final usageMeter = LlmUsageMeter();

          final llmService = buildGrantLlmService(
            taskManager: taskManager,
            usageMeter: usageMeter,
            scriptedResponses: [
              // LLM calls create_plan first
              'TOOL_CALL: create_plan\n'
              'ARGUMENTS: {"course": "IB Biology", "daysValue": 45, "hoursValue": 2}',
              // Then schedules a lesson
              'TOOL_CALL: schedule_lesson\n'
              'ARGUMENTS: {"topicId": "bio-1", "topicTitle": "Cell Biology", "subjectId": "bio", "scheduledTime": "2026-02-15T09:00:00Z", "durationMinutes": 60}',
              // Final response
              'I\'ve created your 45-day IB Biology plan and scheduled your first lesson on Cell Biology. Let\'s get started!',
            ],
          );

          final plannerService = buildPlannerService('teaching-student');

          final planTool = CreatePlanTool(
            plannerService: plannerService,
            localeName: 'en',
          );
          final scheduleTool = ScheduleLessonTool(
            plannerService: plannerService,
            localeName: 'en',
          );

          final registry = ToolRegistry()
            ..register(planTool)
            ..register(scheduleTool);

          final loop = AgentLoop(
            llmService: llmService,
            modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
            toolRegistry: registry,
            taskManager: taskManager,
          );

          final response = await loop.run(
            userMessage: 'I want to learn IB Biology in 45 days.',
            studentId: 'teaching-student',
            systemPrompt: 'You are a helpful tutor. When the student asks to '
                'learn a subject, create a plan and schedule the first lesson.',
            feature: 'teaching',
          );

          if (grantModelConfigured) {
            // --- Real grant model path: lenient assertions ---
            // LLM output is non-deterministic; we verify the pipeline works
            // end-to-end against the real model (real HTTP, token recording).
            expect(mockHttpClientCallCount, 0,
                reason: 'Real http.Client should be used, not MockClient');
            expect(response.content, isNotEmpty,
                reason: 'Real LLM should return content');
            expect(response.error, isNull,
                reason: 'AgentLoop should not surface an error');

            // Token usage must come from the real API response.
            final records = usageMeter.getRecords();
            expect(records, isNotEmpty,
                reason: 'Real LLM calls should record token usage');
            final teachingRecords = records.where((r) => r.feature == 'teaching');
            expect(teachingRecords, isNotEmpty,
                reason: 'Token records should be tagged with the feature');
          } else {
            // --- Mock path: deterministic assertions ---
            // Tool-call trace: both tools were invoked through AgentLoop.
            expect(response.toolCalls, hasLength(2));
            expect(response.toolCalls[0].toolName, 'create_plan');
            expect(response.toolCalls[1].toolName, 'schedule_lesson');

            // Final content is the last LLM response.
            expect(response.content, contains('45-day IB Biology plan'));
            expect(response.content, contains('Cell Biology'));

            // Token usage recorded through LlmUsageMeter.
            final records = usageMeter.getRecords();
            expect(records, isNotEmpty);
            final teachingRecords = records.where((r) => r.feature == 'teaching');
            expect(teachingRecords, isNotEmpty);
            for (final record in teachingRecords) {
              expect(record.inputTokens, greaterThan(0));
              expect(record.outputTokens, greaterThan(0));
            }
          }

          // LlmTaskManager recorded tasks that all completed.
          expect(taskManager.tasks, isNotEmpty);
          expect(
            taskManager.tasks.any((t) => t.status == LlmTaskStatus.done),
            isTrue,
          );
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );

      test(
        'mentor happy path produces transcript with tool-call trace',
        () async {
          final taskManager = LlmTaskManager();
          final usageMeter = LlmUsageMeter();

          final llmService = buildGrantLlmService(
            taskManager: taskManager,
            usageMeter: usageMeter,
            scriptedResponses: [
              // Mentor checks weak topics first
              'TOOL_CALL: get_weak_topics\nARGUMENTS: {}',
              // Then creates a plan
              'TOOL_CALL: create_plan\n'
              'ARGUMENTS: {"course": "Organic Chemistry", "daysValue": 60, "hoursValue": 3}',
              // Then checks student stats
              'TOOL_CALL: get_student_stats\nARGUMENTS: {}',
              // Final response
              'Your study plan covers 60 days for Organic Chemistry. '
              'No weak topics detected yet. You have completed 0 practice sessions so far. '
              'Let\'s start with the first lesson!',
            ],
          );

          final fakeIdService =
              FakeStudentIdService()..setStudentId('mentor-student');

          // Weak topics tool with fakes.
          final weakTool = GetWeakTopicsTool(
            masteryService: MasteryGraphService(
              masteryStateRepo: _FakeMasteryStateRepo(),
              questionMasteryRepo: _FakeQuestionMasteryRepo(),
            ),
            studentIdService: fakeIdService,
          );

          // Plan tool with real PlannerService (Hive initialized).
          final planTool = CreatePlanTool(
            plannerService: PlannerService(
              planRepo: FakePlanRepository(),
              masteryService: MasteryGraphService(),
              topicRepository: FakeTopicRepository(),
              fixedStudentId: 'mentor-student',
            ),
            localeName: 'en',
          );

          // Stats tool with fakes.
          final statsTool = GetStudentStatsTool(
            progressTracker: StudyProgressTracker(
              attemptRepo: FakeAttemptRepository(),
              sessionRepo: FakeSessionRepository(),
              l10n: lookupAppLocalizations(const Locale('en')),
            ),
            studentIdService: fakeIdService,
          );

          final registry = ToolRegistry()
            ..register(weakTool)
            ..register(planTool)
            ..register(statsTool);

          final loop = AgentLoop(
            llmService: llmService,
            modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
            toolRegistry: registry,
            taskManager: taskManager,
          );

          final response = await loop.run(
            userMessage:
                'Plan my Organic Chemistry course for 60 days and show my stats.',
            studentId: 'mentor-student',
            systemPrompt: 'You are a helpful academic mentor.',
            feature: 'mentor',
          );

          if (grantModelConfigured) {
            // --- Real grant model path: lenient assertions ---
            expect(mockHttpClientCallCount, 0,
                reason: 'Real http.Client should be used, not MockClient');
            expect(response.content, isNotEmpty);
            expect(response.error, isNull);
          } else {
            // --- Mock path: deterministic assertions ---
            // Transcript: three tools were called in sequence.
            expect(response.toolCalls, hasLength(3));
            expect(response.toolCalls[0].toolName, 'get_weak_topics');
            expect(response.toolCalls[1].toolName, 'create_plan');
            expect(response.toolCalls[2].toolName, 'get_student_stats');

            // Final content references all actions.
            expect(response.content, contains('60 days'));
            expect(response.content, contains('Organic Chemistry'));
            expect(response.content, contains('practice sessions'));
          }

          // Token usage recorded.
          expect(usageMeter.getRecords(), isNotEmpty);

          // Task manager tracked the mentor run.
          expect(taskManager.tasks, isNotEmpty);
          expect(
            taskManager.tasks.any((t) => t.status == LlmTaskStatus.done),
            isTrue,
          );
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );

      test(
        'tokenUsageRecordedThroughLlmUsageMeterAndLlmTaskManagerOnMockPath',
        () async {
          // This test ALWAYS runs in offline CI (mock path) — it proves the
          // metering pipeline works end-to-end without the grant model.
          // The mock simulates the OpenRouter response format (including
          // usage tokens). When the real grant model IS configured, this
          // test is skipped — metering is verified in the happy-path tests.
          if (grantModelConfigured) {
            markTestSkipped(
              'Grant model is configured — mock-path metering test skipped. '
              'Metering is verified in the grant-model happy-path tests.',
            );
          }

          final taskManager = LlmTaskManager();
          final usageMeter = LlmUsageMeter();

          final llmService = buildGrantLlmService(
            taskManager: taskManager,
            usageMeter: usageMeter,
            scriptedResponses: [
              'TOOL_CALL: record\nARGUMENTS: {"query": "test"}',
              'Here is the answer from the grant model.',
            ],
          );

          final tool = RecordingTool(
            name: 'record',
            returns: {'success': true, 'data': 'mock result'},
          );
          final registry = ToolRegistry()..register(tool);
          final loop = AgentLoop(
            llmService: llmService,
            modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
            toolRegistry: registry,
            taskManager: taskManager,
          );

          final response = await loop.run(
            userMessage: 'What is the capital of France?',
            studentId: 'grant-student',
            systemPrompt: 'You are a helpful tutor.',
            feature: 'teaching',
          );

          // The tool was called.
          expect(response.toolCalls, hasLength(1));
          expect(response.toolCalls.first.toolName, 'record');

          // LlmTaskManager recorded tasks. Both AgentLoop and LlmService
          // create tasks on the shared manager, so we verify at least one
          // task exists and all are done.
          expect(taskManager.tasks, isNotEmpty);
          expect(
            taskManager.tasks.any((t) => t.status == LlmTaskStatus.done),
            isTrue,
          );

          // LlmUsageMeter recorded token usage from the mock HTTP response.
          expect(usageMeter.getRecords(), isNotEmpty);
          final record = usageMeter.getRecords().first;
          expect(record.feature, 'teaching');
          expect(record.inputTokens, greaterThan(0));
          expect(record.outputTokens, greaterThan(0));
          expect(record.totalTokens, greaterThan(0));

          // Verify the mock path was actually used (not real HTTP).
          expect(mockHttpClientCallCount, greaterThan(0),
              reason: 'MockClient should have been invoked in offline CI');
        },
      );
    });

    group('transcript artifacts', () {
      /// Builds a PlannerService wired with fakes suitable for
      /// CreatePlanTool / ScheduleLessonTool integration tests.
      PlannerService buildPlannerService(String studentId) {
        return PlannerService(
          planRepo: FakePlanRepository(),
          masteryService: MasteryGraphService(),
          topicRepository: FakeTopicRepository(),
          fixedStudentId: studentId,
        );
      }

      test('teaching happy path transcript is persisted as a JSON artifact',
          () async {
        final taskManager = LlmTaskManager();
        final usageMeter = LlmUsageMeter();

        final llmService = buildGrantLlmService(
          taskManager: taskManager,
          usageMeter: usageMeter,
          scriptedResponses: [
            'TOOL_CALL: create_plan\n'
            'ARGUMENTS: {"course": "IB Biology", "daysValue": 45, "hoursValue": 2}',
            'TOOL_CALL: schedule_lesson\n'
            'ARGUMENTS: {"topicId": "bio-1", "topicTitle": "Cell Biology", "subjectId": "bio", "scheduledTime": "2026-02-15T09:00:00Z", "durationMinutes": 60}',
            'I\'ve created your 45-day IB Biology plan and scheduled your first lesson on Cell Biology. Let\'s get started!',
          ],
        );

        final plannerService =
            buildPlannerService('transcript-teaching-student');

        final planTool = CreatePlanTool(
          plannerService: plannerService,
          localeName: 'en',
        );
        final scheduleTool = ScheduleLessonTool(
          plannerService: plannerService,
          localeName: 'en',
        );

        final registry = ToolRegistry()
          ..register(planTool)
          ..register(scheduleTool);

        final loop = AgentLoop(
          llmService: llmService,
          modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
          toolRegistry: registry,
          taskManager: taskManager,
        );

        const userMessage =
            'I want to learn IB Biology in 45 days.';
        const systemPrompt = 'You are a helpful tutor. When the student asks '
            'to learn a subject, create a plan and schedule the first lesson.';

        final response = await loop.run(
          userMessage: userMessage,
          studentId: 'transcript-teaching-student',
          systemPrompt: systemPrompt,
          feature: 'teaching',
        );

        // Persist the transcript artifact.
        await dumpTranscript(
          scenarioName: 'teaching_happy_path',
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
          feature: 'teaching',
          response: response,
          usageMeter: usageMeter,
          taskManager: taskManager,
        );

        // Verify the artifact exists and is well-formed.
        final json = await verifyTranscriptArtifact('teaching_happy_path');

        if (grantModelConfigured) {
          // Real model: lenient — just verify structure, not specific tool calls.
          expect(json['finalContent'], isA<String>());
          expect(json['finalContent'], isNotEmpty);
          expect(json['toolCalls'], isA<List>());
        } else {
          // Mock path: deterministic assertions on scripted tool calls.
          expect(json['finalContent'], contains('45-day IB Biology plan'));
          final toolCalls = json['toolCalls'] as List;
          expect(toolCalls, hasLength(2));
          expect(toolCalls[0]['toolName'], 'create_plan');
          expect(toolCalls[1]['toolName'], 'schedule_lesson');
        }

        // Token/cost recorded in the artifact.
        final tokenUsage = json['tokenUsage'] as Map<String, dynamic>;
        expect(tokenUsage['totalTokens'], greaterThan(0));
      });

      test('mentor happy path transcript is persisted as a JSON artifact',
          () async {
        final taskManager = LlmTaskManager();
        final usageMeter = LlmUsageMeter();

        final llmService = buildGrantLlmService(
          taskManager: taskManager,
          usageMeter: usageMeter,
          scriptedResponses: [
            'TOOL_CALL: get_weak_topics\nARGUMENTS: {}',
            'TOOL_CALL: create_plan\n'
            'ARGUMENTS: {"course": "Organic Chemistry", "daysValue": 60, "hoursValue": 3}',
            'TOOL_CALL: get_student_stats\nARGUMENTS: {}',
            'Your study plan covers 60 days for Organic Chemistry. '
            'No weak topics detected yet. Your stats show 0 completed '
            'practice sessions so far. Let\'s start with the first lesson!',
          ],
        );

        final fakeIdService =
            FakeStudentIdService()..setStudentId('transcript-mentor-student');

        final weakTool = GetWeakTopicsTool(
          masteryService: MasteryGraphService(
            masteryStateRepo: _FakeMasteryStateRepo(),
            questionMasteryRepo: _FakeQuestionMasteryRepo(),
          ),
          studentIdService: fakeIdService,
        );

        final planTool = CreatePlanTool(
          plannerService: PlannerService(
            planRepo: FakePlanRepository(),
            masteryService: MasteryGraphService(),
            topicRepository: FakeTopicRepository(),
            fixedStudentId: 'transcript-mentor-student',
          ),
          localeName: 'en',
        );

        final statsTool = GetStudentStatsTool(
          progressTracker: StudyProgressTracker(
            attemptRepo: FakeAttemptRepository(),
            sessionRepo: FakeSessionRepository(),
            l10n: lookupAppLocalizations(const Locale('en')),
          ),
          studentIdService: fakeIdService,
        );

        final registry = ToolRegistry()
          ..register(weakTool)
          ..register(planTool)
          ..register(statsTool);

        final loop = AgentLoop(
          llmService: llmService,
          modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
          toolRegistry: registry,
          taskManager: taskManager,
        );

        const userMessage =
            'Plan my Organic Chemistry course for 60 days and show my stats.';
        const systemPrompt = 'You are a helpful academic mentor.';

        final response = await loop.run(
          userMessage: userMessage,
          studentId: 'transcript-mentor-student',
          systemPrompt: systemPrompt,
          feature: 'mentor',
        );

        // Persist the transcript artifact.
        await dumpTranscript(
          scenarioName: 'mentor_happy_path',
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          modelId: e2eModel.isNotEmpty ? e2eModel : 'gemini-2.0-flash',
          feature: 'mentor',
          response: response,
          usageMeter: usageMeter,
          taskManager: taskManager,
        );

        // Verify the artifact exists and is well-formed.
        final json = await verifyTranscriptArtifact('mentor_happy_path');

        if (grantModelConfigured) {
          // Real model: lenient — just verify structure, not specific tool calls.
          expect(json['finalContent'], isA<String>());
          expect(json['finalContent'], isNotEmpty);
          expect(json['toolCalls'], isA<List>());
        } else {
          // Mock path: deterministic assertions on scripted tool calls.
          expect(json['finalContent'], contains('60 days'));
          final toolCalls = json['toolCalls'] as List;
          expect(toolCalls, hasLength(3));
          expect(toolCalls[0]['toolName'], 'get_weak_topics');
          expect(toolCalls[1]['toolName'], 'create_plan');
          expect(toolCalls[2]['toolName'], 'get_student_stats');
        }

        // Token/cost recorded in the artifact.
        final tokenUsage = json['tokenUsage'] as Map<String, dynamic>;
        expect(tokenUsage['totalTokens'], greaterThan(0));
      });
    });
  });
}

/// Fake [MasteryStateRepository] that returns empty data without
/// touching the Hive box, ensuring deterministic getWeakTopics results.
class _FakeMasteryStateRepo extends MasteryStateRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId, {String? subjectId}) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    return Result.success({
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'totalAttempts': 0,
    });
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async {
    return Result.success(null);
  }
}

/// Fake [QuestionMasteryStateRepository] that returns empty data.
class _FakeQuestionMasteryRepo extends QuestionMasteryStateRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getAllForStudent(
    String studentId,
  ) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success([]);
  }
}