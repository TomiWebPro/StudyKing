/// Fake LLM service and test tools for agentic e2e integration tests.
///
/// These fakes exercise the real [AgentLoop] parser
/// (TOOL_CALL: / ARGUMENTS:) without hitting the network.
/// Every fake LLM response is deterministic — no API keys required.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
library;

import 'dart:convert';

import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';

/// Scripts deterministic [AgentLoop]-compatible responses.
///
/// Each entry in `_script` corresponds to one `chat()` call.
/// Responses may contain `TOOL_CALL:` / `ARGUMENTS:` directives that
/// the real parser in [AgentLoop._parseResponse] will consume.
///
/// When the script is exhausted the service returns the last scripted
/// value, so multi-turn loops that exceed expectations degrade
/// deterministically rather than throwing.
class FakeAgentLlmService extends LlmService {
  final List<String> _script;
  final List<String> chatMessages = [];
  final List<String> chatModels = [];
  final List<String> chatFeatures = [];

  FakeAgentLlmService(
    List<String> script, {
    super.taskManager,
    super.usageMeter,
  })  : _script = List<String>.of(script),
        super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key-for-agentic-e2e',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    chatMessages.add(message);
    chatModels.add(modelId);
    chatFeatures.add(feature);

    final response = _script.isNotEmpty
        ? _script.removeAt(0)
        : (chatMessages.isNotEmpty ? chatMessages.last : '');
    return Result.success(response);
  }

  /// Returns the number of `chat()` calls remaining in the script.
  int get remainingResponses => _script.length;
}

/// A test [AgentTool] that records every invocation.
///
/// Use [returns] to configure the map returned by [execute].
/// Use [throwOnCall] to make the tool fail on a specific 1-based call index.
class RecordingTool extends AgentTool {
  final String _name;
  final String _description;
  final Map<String, dynamic> _parameters;
  final Map<String, dynamic> returns;
  final int? throwOnCall;
  int callCount = 0;
  final List<Map<String, dynamic>> receivedArgs = [];

  RecordingTool({
    String name = 'record',
    String description = 'A recording test tool',
    Map<String, dynamic>? parameters,
    this.returns = const {'success': true, 'result': 'ok'},
    this.throwOnCall,
  })  : _name = name,
        _description = description,
        _parameters = parameters ??
            {'type': 'object', 'properties': {}, 'required': []};

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Map<String, dynamic> get parameters => _parameters;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    callCount++;
    receivedArgs.add(Map<String, dynamic>.from(args));

    if (throwOnCall != null && callCount == throwOnCall) {
      throw StateError('RecordingTool forced failure on call $callCount');
    }

    // Clone to avoid external mutation.
    return Map<String, dynamic>.from(returns);
  }
}

/// Canonical set of tool names registered by `llmAgentToolsProvider` in
/// `lib/core/providers/llm_agent_providers.dart`.
///
/// This is a single source-of-truth used by the dry-run scenario validation
/// and tool-trace coverage tests so they always audit against the real
/// provider tree rather than a hardcoded snapshot that goes stale when a tool
/// is added or removed.
///
/// When a tool is registered/removed in [llmAgentToolsProvider], update this
/// list in lock-step. The [registeredToolNames] constant is the read-side
/// guard: scenario audits that reference it will automatically reflect the
/// current tooling without manual edits to individual test assertions.
const Set<String> registeredToolNames = {
  // Interactive mentor tools
  'schedule_lesson',
  'schedule_rest_day',
  'wellbeing_adjust_schedule',
  'switch_syllabus_focus',
  'switch_provider',
  'create_plan',
  'modify_plan',
  'search_questions',
  'get_student_stats',
  'get_weak_topics',
  'get_adherence_trends',
  'get_lesson_history',
  'create_practice_session',
  'review_mistakes',
  'get_syllabus_structure',
  'generate_lesson_blocks',
  // Off-period preparation toolbox (Vision Next-Term §4.3)
  'ingest_pdf_to_kb',
  'enqueue_question_variants',
  'pre_generate_lesson',
  'refresh_mastery',
};

/// A tool that always throws, regardless of arguments.
class AlwaysThrowTool extends AgentTool {
  @override
  String get name => 'always_throw';

  @override
  String get description => 'Always throws an exception';

  @override
  Map<String, dynamic> get parameters =>
      {'type': 'object', 'properties': {}, 'required': []};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    throw StateError('always_throw simulated failure');
  }
}

/// Captures a single AgentLoop run for assertion — the tool calls made,
/// the final assistant content, and whether an error was surfaced.
class AgentRunCapture {
  final List<AgentToolCall> toolCalls;
  final String content;
  final String? error;

  AgentRunCapture({
    required this.toolCalls,
    required this.content,
    this.error,
  });

  /// Names of all tools invoked during the run, in order.
  List<String> get toolNames => toolCalls.map((t) => t.toolName).toList();

  /// True if [toolName] was invoked.
  bool wasCalled(String toolName) => toolNames.contains(toolName);

  /// Serialised JSON of the arguments passed to the first invocation of [toolName].
  Map<String, dynamic>? argsFor(String toolName) {
    final call = toolCalls.firstWhere(
      (t) => t.toolName == toolName,
      orElse: () => throw StateError('Tool not called: $toolName'),
    );
    return call.arguments;
  }

  /// The result string returned to the LLM for the first invocation of [toolName].
  String? resultFor(String toolName) {
    final call = toolCalls.firstWhere(
      (t) => t.toolName == toolName,
      orElse: () => throw StateError('Tool not called: $toolName'),
    );
    return call.result;
  }

  /// Human-readable trace suitable for dry-run scenario output.
  String toTrace() {
    final buffer = StringBuffer();
    buffer.writeln('CHECK: TRACE');
    buffer.writeln('  Content: $content');
    buffer.writeln('  Error: ${error ?? 'none'}');
    for (final tc in toolCalls) {
      buffer.writeln('  TOOL_CALL: ${tc.toolName}');
      buffer.writeln('    arguments: ${jsonEncode(tc.arguments)}');
      buffer.writeln('    result: ${tc.result ?? "null"}');
    }
    buffer.writeln('CHECK: PASS');
    return buffer.toString();
  }

  /// Audit of tools that were *needed* vs *had* in the registry.
  static String auditTools({
    required List<String> needed,
    required Set<String> available,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('TOOL_CONTEXT_AUDIT:');
    for (final tool in needed) {
      final had = available.contains(tool);
      buffer.writeln('  - NEEDS: $tool -> ${had ? "HAD" : "MISSING"}');
    }
    final missing = needed.where((t) => !available.contains(t)).toList();
    if (missing.isEmpty) {
      buffer.writeln('  RESULT: all needed tools available');
    } else {
      buffer.writeln(
        '  RESULT: ${missing.length} tool(s) missing: ${missing.join(", ")}',
      );
    }
    return buffer.toString();
  }
}
