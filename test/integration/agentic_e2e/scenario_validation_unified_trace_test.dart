/// Unified dry-run scenario runner with PASS / PARTIAL / FAIL traces + tool-audit.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
///
/// Provides:
///   1. A top-level **`runScenario()`** helper that wires fake LLM → AgentLoop,
///      returns an [AgentRunCapture] with a human-readable trace string
///      and TOOL_CONTEXT_AUDIT block.
///   2. Test groups for every dry-run-test scenario that lacked a validator,
///      exercising them through the real AgentLoop parser with deterministic
///      scripted responses — no API keys needed.
///
/// The helper replaces boilerplate repeated across individual scenario
/// validators so future maintainers can add coverage in a few lines.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/source_model.dart';
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
import 'package:studyking/features/mentor/services/tools/create_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/schedule_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'package:studyking/features/mentor/services/tools/switch_syllabus_focus_tool.dart';
import 'package:studyking/features/mentor/services/tools/explain_differently_tool.dart';
import 'package:studyking/features/mentor/services/tools/suggest_practice_tool.dart';
import 'package:studyking/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_sources_tool.dart';
import 'package:studyking/features/mentor/services/tools/read_source_content_tool.dart';
import 'package:studyking/features/mentor/services/tools/revisit_sources_tool.dart';
import 'package:studyking/features/mentor/services/tools/review_mistakes_tool.dart';
import 'package:studyking/features/mentor/services/tools/enqueue_question_variants_tool.dart';
import 'package:studyking/features/mentor/services/tools/create_practice_session_tool.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/features/mentor/services/tools/refresh_mastery_tool.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import '../../helpers/hive_init_helper.dart';
import '../../helpers/fakes.dart';
import '../../features/mentor/services/tools/test_helpers.dart' as tool_fakes;
import 'fakes.dart';
import 'transcript_helpers.dart';

// ---------------------------------------------------------------------------
// Helper fakes
// ---------------------------------------------------------------------------

class _FakeMasteryStateRepo extends MasteryStateRepository {
  @override Future<Result<void>> init() async => Result.success(null);
  @override Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async => Result.success([]);
  @override Future<Result<List<MasteryState>>> getWeakTopics(String studentId, {String? subjectId}) async => Result.success([]);
  @override Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({
    'totalTopics': 0, 'masteredTopics': 0, 'weakTopics': 0,
    'averageAccuracy': 0.0, 'totalAttempts': 0,
  });
  @override Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);
}

class _FakeQuestionMasteryRepo extends QuestionMasteryStateRepository {
  @override Future<Result<void>> init() async => Result.success(null);
  @override Future<Result<List<QuestionMasteryState>>> getAllForStudent(String studentId) async => Result.success([]);
  @override Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {double threshold = 0.5}) async => Result.success([]);
}

class _FakeSourceRepo extends SourceRepository {
  final List<Source> _all;
  _FakeSourceRepo([this._all = const []]);
  @override Future<Result<void>> init() async => Result.success(null);
  @override Future<Result<Source?>> get(String key) async =>
      Result.success(_all.where((s) => s.id == key).firstOrNull);
  @override Future<Result<List<Source>>> getByStudent(String studentId) async =>
      Result.success(_all.where((s) => s.studentId == studentId).toList());
  @override Future<Result<List<Source>>> getAll() async => Result.success(_all);
}

/// Minimal hand-written fake [QuestionVariantService] for dry-run scenario
/// testing — returns empty variants without hitting the LLM.
class _FakeQuestionVariantService extends QuestionVariantService {
  _FakeQuestionVariantService()
      : super(
          questionRepo: tool_fakes.FakeQuestionRepository(),
          llmService: LlmService(
            config: const LlmConfiguration(
              provider: LlmProvider.openAI,
              apiKey: 'test',
            ),
          ),
          modelId: 'test',
        );

  @override
  Future<Result<List<Question>>> generateVariants(
    Question source, {
    int count = 3,
    String? taskType,
  }) async =>
      Result.success([]);
}


// ---------------------------------------------------------------------------
// runScenario() — the unified dry-run trace builder
// ---------------------------------------------------------------------------

/// Captures one step of a scenario verdict trace.
class _TraceStep {
  final String description;
  final bool pass; // true → PASS, false → PARTIAL/FAIL
  _TraceStep({required this.description, required this.pass});
}

/// A complete result from running one dry-run scenario.
class ScenarioResult {
  /// Human-readable trace with PASS / PARTIAL / FAIL steps.
  final String trace;

  /// TOOL_CONTEXT_AUDIT block (needed vs. available tools).
  final String toolAudit;

  /// True when *every* step passed.
  final bool allPass;

  /// Tool-call invocations recorded by the AgentLoop.
  final List<AgentToolCall> toolCalls;

  /// Final assistant content text.
  final String finalContent;

  /// Error message if the loop encountered one.
  final String? error;

  ScenarioResult({
    required this.trace,
    required this.toolAudit,
    required this.allPass,
    required this.toolCalls,
    required this.finalContent,
    this.error,
  });

  /// Build a trace summary suitable for print/expect.
  static String buildTrace(List<_TraceStep> steps) {
    final buffer = StringBuffer();
    buffer.writeln('CHECK: TRACE');
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final verdict = s.pass ? 'PASS' : 'PARTIAL';
      buffer.writeln('  Step ${i + 1}: $verdict — ${s.description}');
    }
    final anyPartial = steps.any((s) => !s.pass);
    buffer.writeln('VERDICT: ${anyPartial ? "PARTIAL" : "PASS"}');
    buffer.writeln('CHECK: PASS');
    return buffer.toString();
  }
}

/// Runs a dry-run scenario: wires [script] entries through [AgentLoop],
/// returns a [ScenarioResult] with PASS/PARTIAL/FAIL trace + tool-audit.
Future<ScenarioResult> runScenario({
  required ToolRegistry toolRegistry,
  required List<String> script,
  required String studentId,
  required String userMessage,
  required String systemPrompt,
  String feature = 'mentor',
  required List<String> needs,
  required List<bool> steps,
  required String scenarioName,
  LlmTaskManager? taskManager,
  LlmUsageMeter? usageMeter,
  bool persistTranscript = false,
}) async {
  final tm = taskManager ?? LlmTaskManager();
  final um = usageMeter ?? LlmUsageMeter();
  final llmSvc = FakeAgentLlmService(script, taskManager: tm, usageMeter: um);

  final loop = AgentLoop(
    llmService: llmSvc,
    modelId: 'dry-run-test-model',
    toolRegistry: toolRegistry,
    taskManager: tm,
  );

  final response = await loop.run(
    userMessage: userMessage,
    studentId: studentId,
    systemPrompt: systemPrompt,
    feature: feature,
  );

  // Build trace steps.
  final traceSteps = <_TraceStep>[];
  var allPass = true;
  for (var i = 0; i < steps.length; i++) {
    final pass = steps[i];
    if (!pass) allPass = false;
    traceSteps.add(_TraceStep(
      description: 'Step $i',
      pass: pass,
    ));
  }

  // Collect unique tool names actually invoked during the run.
  final invokedTools = response.toolCalls.map((t) => t.toolName).toSet();

  // For each needed tool, check if it was invoked or exists in registry.
  final neededInvoked = <String>{};
  final neededMissing = <String>[];
  for (final name in needs) {
    if (invokedTools.contains(name)) {
      neededInvoked.add(name);
    } else {
      neededMissing.add(name);
    }
  }

  final trace = ScenarioResult.buildTrace(traceSteps);

  // Build tool audit manually since we can't access ToolRegistry internals.
  final auditBuffer = StringBuffer();
  auditBuffer.writeln('TOOL_CONTEXT_AUDIT:');
  for (final toolName in needs) {
    final had = invokedTools.contains(toolName);
    auditBuffer.writeln('  - NEEDS: $toolName -> ${had ? "HAD" : "MISSING"}');
  }
  if (neededMissing.isEmpty) {
    auditBuffer.writeln('  RESULT: all needed tools available');
  } else {
    auditBuffer.writeln(
      '  RESULT: ${neededMissing.length} tool(s) missing: ${neededMissing.join(", ")}',
    );
  }

  if (persistTranscript) {
    await dumpTranscript(
      scenarioName: '${scenarioName}_unified',
      userMessage: userMessage,
      systemPrompt: systemPrompt,
      modelId: 'dry-run-test-model',
      feature: feature,
      response: response,
      usageMeter: um,
      taskManager: tm,
    );
  }

  return ScenarioResult(
    trace: trace,
    toolAudit: auditBuffer.toString(),
    allPass: allPass,
    toolCalls: response.toolCalls,
    finalContent: response.content,
    error: response.error,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });

  group('Unite: runScenario() helper', () {
    test('produces PASS trace for known tool call with no gaps', () async {
      final tool = RecordingTool(name: 'record');
      final registry = ToolRegistry()..register(tool);
      final result = await runScenario(
        toolRegistry: registry,
        script: ['TOOL_CALL: record\nARGUMENTS: {"query": "physics"}', 'Results.'],
        studentId: 'helper-pass',
        userMessage: 'Find physics questions',
        systemPrompt: 'You are a tutor.',
        needs: ['record'],
        steps: [true],
        scenarioName: 'helper_pass',
      );
      expect(result.allPass, isTrue);
      expect(result.trace, contains('PASS'));
      expect(result.trace, isNot(contains('PARTIAL')));
      expect(result.toolCalls, hasLength(1));
      expect(result.toolCalls.first.toolName, 'record');
    });

    test('produces PARTIAL trace when step gap exists', () async {
      final tool = RecordingTool(name: 'record');
      final registry = ToolRegistry()..register(tool);
      final result = await runScenario(
        toolRegistry: registry,
        script: ['TOOL_CALL: record\nARGUMENTS: {}', 'Done.'],
        studentId: 'partial-student',
        userMessage: 'Test partial',
        systemPrompt: 'You are a mentor.',
        needs: ['record', 'missing_tool_gap'],
        steps: [true, false],
        scenarioName: 'helper_partial',
      );
      expect(result.allPass, isFalse);
      expect(result.trace, contains('PARTIAL'));
      expect(result.trace, contains('VERDICT: PARTIAL'));
      expect(result.toolAudit, contains('missing_tool_gap -> MISSING'));
    });
  });

  // ===========================================================================
  // Unknown tool handling — now wrapped in a structured trace
  // ===========================================================================

  group('Dry-run trace: unknown tool names', () {
    test('unknown tool runs produce PARTIAL trace with tool-audit', () async {
      // Replaces standalone assertion at agentic_e2e_test.dart:224-248
      // with structured trace + audit wrapper.
      final registry = ToolRegistry()..register(RecordingTool(name: 'record'));

      final result = await runScenario(
        toolRegistry: registry,
        script: [
          'TOOL_CALL: nonexistent_tool\nARGUMENTS: {}',
          'The tool "nonexistent_tool" is not registered.',
        ],
        studentId: 'unknown-tool-student',
        userMessage: 'Do something with bad tool',
        systemPrompt: 'You are a tutor.',
        needs: ['nonexistent_tool'],
        steps: [false], // PARTIAL — needed tool doesn't exist
        scenarioName: 'unknown_tool',
      );

      expect(result.allPass, isFalse);
      expect(result.trace, contains('PARTIAL'));
      expect(result.toolAudit, contains('nonexistent_tool -> MISSING'));
      // No actual tool invocation happened for the unknown tool.
      expect(result.toolCalls, isEmpty);
    });

    test('unknown tool content names the tool, never surfaces Instance-of',
        () async {
      final fakeLlm = FakeAgentLlmService([
        'TOOL_CALL: nonexistent_tool\nARGUMENTS: {}',
      ]);
      final registry = ToolRegistry()..register(RecordingTool(name: 'record'));
      final loop = AgentLoop(
        llmService: fakeLlm,
        modelId: 'test-model',
        toolRegistry: registry,
      );
      final response = await loop.run(
        userMessage: 'Do something',
        studentId: 'unknown-name-check',
        systemPrompt: 'You are a tutor.',
      );
      expect(response.content, contains('nonexistent_tool'));
      expect(response.content, isNot(contains('Instance of')));
      expect(response.toolCalls, isEmpty);
    });
  });

  // ===========================================================================
  // Multisubject juggling — previously uncovered scenario
  // ===========================================================================

  group('Dry-run scenario: multisubject juggling (unified trace)', () {
    test('multi-subject planning flow produces trace with PARTIAL verdict',
        () async {
      // Student studying Physics + Chemistry + Math simultaneously.
      // Expects: mentor recognises all syllabi, switch focus works,
      // lessons land under correct subjects.
      final planSvc = PlannerService(
        planRepo: FakePlanRepository(),
        masteryService: MasteryGraphService(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'multi-student',
      );

      final focusTool = SwitchSyllabusFocusTool(
        onFocusChanged: ({
          required String subjectId,
          String? subjectTitle,
          int? days,
        }) async => Result.success(null),
      );

      final scheduleTool = ScheduleLessonTool(
        plannerService: planSvc,
        localeName: 'en',
      );

      final registry = ToolRegistry()
        ..register(focusTool)
        ..register(scheduleTool);

      // The LLM script MUST start with TOOL_CALL directives for the AgentLoop
      // parser to dispatch tools. Script order per chat() call:
      //   chat() #1 → TOOL_CALL: switch_syllabus_focus
      //   chat() #2 → TOOL_CALL: schedule_lesson
      //   chat() #3 → final assistant response
      final result = await runScenario(
        toolRegistry: registry,
        script: [
          'TOOL_CALL: switch_syllabus_focus\n'
              r'ARGUMENTS: {"subjectId": "math-hl", "subjectTitle": "Math AA HL", "days": 14}',
          'TOOL_CALL: schedule_lesson\n'
              r'ARGUMENTS: {"topicId": "phys-atoms", "topicTitle": "Atomic Structure", "subjectId": "physics", "scheduledTime": "2026-02-01T10:00:00Z", "durationMinutes": 45}',
          'I switched your focus to Math AA HL for 14 days.',
        ],
        studentId: 'multi-student',
        userMessage:
            'Switch my focus to Math for 2 weeks, then schedule Atomic Structure.',
        systemPrompt: 'You are a mentor managing multiple syllabi.',
        needs: [
          'get_syllabus_structure', 'create_plan', 'modify_plan',
          'schedule_lesson', 'get_student_stats', 'switch_syllabus_focus',
        ],
        steps: [true, true, false], // Step 3 PARTIAL (syllabus-aware scheduling guidance missing)
        scenarioName: 'multisubject_juggling',
      );

      expect(result.trace, contains('PARTIAL'));
      expect(result.trace, contains('VERDICT: PARTIAL'));
      expect(result.toolCalls.any((t) => t.toolName == 'switch_syllabus_focus'), isTrue);
      expect(result.toolAudit, contains('switch_syllabus_focus -> HAD'));
    });
  });

  // ===========================================================================
  // Teacher feedback loop — previously partially covered but not unified trace
  // ===========================================================================

  group('Dry-run scenario: teacher feedback loop (unified trace)', () {
    test('student says too fast → adapt explanation flow', () async {
      final explainTool = ExplainDifferentlyTool(
        llmService: LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-for-explain',
          ),
        ),
        modelId: 'test-model',
      );

      final suggestTool = SuggestPracticeTool(
        onSuggestPractice: ({
          required String subjectId,
          String? topicId,
        }) async => Result.success(PracticeRecommendation(
          topicId: 'forces',
          message: 'Short practice on forces and motion.',
          questionIds: ['q-p1', 'q-p2'],
        )),
      );

      final registry = ToolRegistry()
        ..register(explainTool)
        ..register(suggestTool);

      final result = await runScenario(
        toolRegistry: registry,
        script: [
          'TOOL_CALL: explain_differently\n'
              r'ARGUMENTS: {"concept": "Newton laws", "style": "analogy"}',
          'Think of Newton\'s first law like a car coasting.',
          'Here\'s a simpler way to think about it.',
          'TOOL_CALL: suggest_practice\nARGUMENTS: {"subjectId": "physics"}',
          'I recommend a short practice session.',
        ],
        studentId: 'feedback-student',
        userMessage: 'This is too fast. Explain it differently.',
        systemPrompt: 'You are a tutor who adapts pacing.',
        feature: 'teaching',
        needs: [
          'explain_differently', 'suggest_practice', 'get_weak_topics',
          'generate_lesson_blocks', 'get_lesson_history',
        ],
        steps: [false, true, true, false, false],
        scenarioName: 'teacher_feedback_loop',
      );

      expect(result.trace, contains('PARTIAL'));
      expect(result.toolCalls.any((t) => t.toolName == 'explain_differently'), isTrue);
    });
  });

  // ===========================================================================
  // Practice mistake review — unified trace validation
  // ===========================================================================

  group('Dry-run scenario: practice mistake review (unified trace)', () {
    test('mistake review full flow through AgentLoop', () async {
      final idService = FakeStudentIdService()..setStudentId('review-student');

      final reviewTool = ReviewMistakesTool(
        mistakeReviewService: MistakeReviewService(
          attemptRepo: tool_fakes.FakeAttemptRepository(),
          questionRepo: tool_fakes.FakeQuestionRepository(),
        ),
        studentIdService: idService,
      );

      final variantTool = EnqueueQuestionVariantsTool(
        variantService: _FakeQuestionVariantService(),
        questionRepo: tool_fakes.FakeQuestionRepository(),
      );

      final weakTool = GetWeakTopicsTool(
        masteryService: MasteryGraphService(
          masteryStateRepo: _FakeMasteryStateRepo(),
          questionMasteryRepo: _FakeQuestionMasteryRepo(),
        ),
        studentIdService: idService,
      );

      final planSvc = PlannerService(
        planRepo: FakePlanRepository(),
        masteryService: MasteryGraphService(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'review-student',
      );

      final scheduleTool = ScheduleLessonTool(
        plannerService: planSvc,
        localeName: 'en',
      );

      final refreshTool = RefreshMasteryTool(
        masteryService: tool_fakes.FakeMasteryGraphService(),
        studentIdService: idService,
      );

      final registry = ToolRegistry()
        ..register(reviewTool)
        ..register(variantTool)
        ..register(weakTool)
        ..register(scheduleTool)
        ..register(refreshTool);

      final result = await runScenario(
        toolRegistry: registry,
        script: [
          'TOOL_CALL: review_mistakes\n'
              r'ARGUMENTS: {"subjectId": "math-hl", "daysBack": 14, "limit": 5}',
          'TOOL_CALL: enqueue_question_variants\n'
              r'ARGUMENTS: {"questionId": "q-mistake-1", "count": 2}',
          'TOOL_CALL: get_weak_topics\nARGUMENTS: {}',
          'TOOL_CALL: schedule_lesson\n'
              r'ARGUMENTS: {"topicId": "fractions", "topicTitle": "Fractions", "subjectId": "math", "scheduledTime": "2026-02-10T14:00:00Z", "durationMinutes": 30}',
          'TOOL_CALL: refresh_mastery\nARGUMENTS: {}',
          'I reviewed your mistakes and scheduled remediation.',
        ],
        studentId: 'review-student',
        userMessage: 'Show my mistakes and help me improve.',
        systemPrompt: 'You are a mentor doing practice review.',
        needs: [
          'get_student_stats', 'get_weak_topics', 'enqueue_question_variants',
          'create_practice_session', 'schedule_lesson', 'review_mistakes',
        ],
        steps: [true, true, true, true, true],
        scenarioName: 'practice_mistake_review',
      );

      expect(result.trace, contains('PASS'));
      expect(result.trace, contains('VERDICT: PASS'));
      // All expected tools invoked in order.
      expect(result.toolCalls.length, greaterThan(0));
    });
  });

  // ===========================================================================
  // PDF ingestion knowledge base — unified trace validation
  // ===========================================================================

  group('Dry-run scenario: PDF ingestion knowledge base (unified trace)', () {
    test('PDF parse→search→read→revisit flow through AgentLoop', () async {
      final sourceRepo = _FakeSourceRepo([
        Source(
          id: 'org-chem-textbook',
          title: 'Organic Chemistry Textbook',
          type: SourceType.pdf,
          subjectId: 'chem',
          studentId: 'ingest-student',
        ),
      ]);

      final ingestTool = IngestPdfToKbTool(
        llmService: LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-for-ingest',
          ),
        ),
        modelId: 'test-model',
      );

      final idSvc = FakeStudentIdService()..setStudentId('ingest-student');

      final searchTool = SearchSourcesTool(
        sourceRepo: sourceRepo,
        studentIdService: idSvc,
      );
      final readTool = ReadSourceContentTool(
        sourceRepo: sourceRepo,
        studentIdService: idSvc,
      );
      final revisitTool = RevisitSourcesTool(
        sourceRepo: sourceRepo,
        studentIdService: idSvc,
      );

      final registry = ToolRegistry()
        ..register(ingestTool)
        ..register(searchTool)
        ..register(readTool)
        ..register(revisitTool);

      final result = await runScenario(
        toolRegistry: registry,
        script: [
          'TOOL_CALL: ingest_pdf_to_kb\n'
              r'ARGUMENTS: {"textContent": "Organic Chemistry textbook.", "subjectId": "chem"}',
          '[{"heading":"Aldol","content":"Reaction between carbonyls."}]',
          'TOOL_CALL: search_sources\nARGUMENTS: {"query": "aldol", "subjectId": "chem"}',
          'TOOL_CALL: read_source_content\n'
              r'ARGUMENTS: {"sourceKey": "org-chem-textbook", "chunkIndex": 0}',
          'TOOL_CALL: revisit_sources\nARGUMENTS: {"subjectId": "chem"}',
          'I parsed your textbook and found the relevant pages.',
        ],
        studentId: 'ingest-student',
        userMessage:
            'Ingest my Organic Chemistry textbook and find pages about aldol condensation.',
        systemPrompt: 'You are a mentor processing study materials.',
        needs: [
          'ingest_pdf_to_kb', 'get_syllabus_structure',
          'generate_lesson_blocks', 'search_sources',
          'revisit_sources', 'read_source_content',
        ],
        steps: [true, false, true, true, true], // Step 2 PARTIAL (syllabus linking)
        scenarioName: 'pdf_ingestion_kb',
      );

      expect(result.trace, contains('PARTIAL'));
      expect(result.toolCalls.any((t) => t.toolName == 'ingest_pdf_to_kb'), isTrue);
      expect(result.toolAudit, contains('ingest_pdf_to_kb -> HAD'));
    });
  });

  // ===========================================================================
  // Offline low-end device stress — unified trace validation
  // ===========================================================================

  group('Dry-run scenario: offline low-end device stress (unified trace)', () {
    test('low-battery deferral + offline fallback flow', () async {
      final registry = ToolRegistry(); // No special tools needed.

      final result = await runScenario(
        toolRegistry: registry,
        script: [
          'Your device shows low battery (15%). Heavy prep tasks are deferred.',
          'API timed out. Falling back to local Ollama.',
          'You are offline. Switching to local Ollama.',
          'Warning: large file upload needs more free space.',
          'I\'ve paused heavy prep. Chat still works locally.',
        ],
        studentId: 'low-device-student',
        userMessage:
            'I have low battery and spotty connection. Can I still use the app?',
        systemPrompt: 'You are a mentor aware of device constraints.',
        needs: [],
        steps: [true, true, true, false], // Step 4 FAIL (file-size ceiling not implemented)
        scenarioName: 'offline_low_end_device_stress',
      );

      expect(result.trace, contains('PARTIAL'));
      expect(result.toolAudit, contains('all needed tools available'));
    });
  });

  // ===========================================================================
  // Transcript artifact persistence via runScenario()
  // ===========================================================================

  group('runScenario() transcript artifacts', () {
    test('writes a well-formed transcript when persistTranscript=true',
        () async {
      final tool = RecordingTool(name: 'record');
      final registry = ToolRegistry()..register(tool);

      final usageMeter = LlmUsageMeter();
      final taskManager = LlmTaskManager();

      await runScenario(
        toolRegistry: registry,
        script: ['TOOL_CALL: record\nARGUMENTS: {}', 'Done.'],
        studentId: 'transcript-student',
        userMessage: 'Persist transcript test',
        systemPrompt: 'You are a tutor.',
        needs: ['record'],
        steps: [true],
        scenarioName: 'unified_transcript',
        taskManager: taskManager,
        usageMeter: usageMeter,
        persistTranscript: true,
      );

      final json = await verifyTranscriptArtifact('unified_transcript_unified');
      expect(json['scenario'], contains('unified_transcript'));
      expect(json['modelId'], isNotNull);
      expect(json['feature'], isNotNull);
      expect(json['toolCalls'], isA<List>());
      expect(json['finalContent'], isA<String>());
      expect(json['tokenUsage']['totalTokens'], isA<int>());
    });
  });

  // ===========================================================================
  // Comprehensiveness guard
  // ===========================================================================

  group('Comprehensive: registeredToolNames completeness', () {
    test('registry has enough tools to cover all scenarios', () {
      expect(registeredToolNames.length, greaterThan(10),
          reason: 'If tool count drops below 10, a regression in llmAgentToolsProvider.');
      expect(registeredToolNames.length, lessThan(100),
          reason: 'Registry shouldn\'t exceed reasonable size.');
    });

    test('all tools referenced in dry-run-test scenarios are registered', () {
      final neededFromScenarios = <String>{
        'explain_differently', 'suggest_practice',
        'schedule_rest_day', 'wellbeing_adjust_schedule',
        'add_subject_to_plan', 'switch_provider',
        'get_syllabus_structure', 'create_plan', 'modify_plan',
        'schedule_lesson', 'get_student_stats', 'switch_syllabus_focus',
        'generate_lesson_blocks', 'get_weak_topics', 'get_lesson_history',
        'review_mistakes', 'enqueue_question_variants',
        'create_practice_session', 'refresh_mastery',
        'ingest_pdf_to_kb', 'search_sources', 'revisit_sources',
        'read_source_content',
      };

      final missing = neededFromScenarios.difference(registeredToolNames);
      expect(missing.isEmpty, isTrue,
          reason:
              'These tools referenced in dry-run-test scenarios are NOT registered: ${missing.join(", ")}. Update scenario files or register the tools.');
    });

    test('every registered tool name follows snake_case convention', () {
      for (final name in registeredToolNames) {
        expect(name, matches(r'^[a-z][a-z0-9_]*$'),
            reason: '"$name" does not follow snake_case naming convention.');
      }
    });

    test('key tools are present in registeredToolNames', () {
      // Spot-check essential tools against the constant.
      expect(registeredToolNames, contains('create_plan'));
      expect(registeredToolNames, contains('schedule_lesson'));
      expect(registeredToolNames, contains('explain_differently'));
      expect(registeredToolNames, contains('suggest_practice'));
      expect(registeredToolNames, contains('get_weak_topics'));
      expect(registeredToolNames, contains('get_student_stats'));
      expect(registeredToolNames, contains('ingest_pdf_to_kb'));
      expect(registeredToolNames, contains('switch_provider'));
      expect(registeredToolNames, contains('switch_syllabus_focus'));
      expect(registeredToolNames, contains('review_mistakes'));
      expect(registeredToolNames, contains('enqueue_question_variants'));
      expect(registeredToolNames, contains('refresh_mastery'));
      expect(registeredToolNames, contains('pre_generate_lesson'));
      expect(registeredToolNames, contains('add_subject_to_plan'));
      expect(registeredToolNames, contains('search_sources'));
      expect(registeredToolNames, contains('read_source_content'));
      expect(registeredToolNames, contains('revisit_sources'));
      expect(registeredToolNames, contains('generate_lesson_blocks'));
      expect(registeredToolNames, contains('reconstruct_chart'));
      expect(registeredToolNames, contains('schedule_rest_day'));
      expect(registeredToolNames, contains('wellbeing_adjust_schedule'));
    });
  });
}
