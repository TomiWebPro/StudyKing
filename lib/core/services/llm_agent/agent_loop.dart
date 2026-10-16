import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';

class AgentLoop {
  static final Logger _logger = const Logger('AgentLoop');

  /// Maximum think→act→observe iterations before the loop stops.
  /// Exposed for offline integration tests that script tool-call loops.
  @visibleForTesting
  static const int maxIterations = 10;
  static const int _maxIterations = maxIterations;

  final LlmService _llmService;
  final String _modelId;
  final ToolRegistry _toolRegistry;
  final LlmTaskManager? _taskManager;

  AgentLoop({
    required LlmService llmService,
    required String modelId,
    required ToolRegistry toolRegistry,
    LlmTaskManager? taskManager,
  })  : _llmService = llmService,
        _modelId = modelId,
        _toolRegistry = toolRegistry,
        _taskManager = taskManager;

  /// Read-only access to the tool registry, exposed for tests that need
  /// to assert on the set of registered tools (e.g. dry-run scenario audits).
  ToolRegistry get toolRegistry => _toolRegistry;

  Future<AgentResponse> run({
    required String userMessage,
    required String studentId,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
  }) async {
    final taskType = LlmTaskType.fromFeature(feature)?.name;
    final taskId = _taskManager?.createTask(
      feature: feature,
      modelId: _modelId,
      taskType: taskType,
    ) ?? '';
    _taskManager?.startTask(taskId);

    // Snapshot task IDs that already existed before this run so we can
    // aggregate token counts from the LLM service's per-call tasks after
    // the loop finishes (they share the same [LlmTaskManager]).
    final preRunTaskIds = _taskManager != null
        ? Set<String>.from(_taskManager!.tasks.map((t) => t.id))
        : const <String>{};

    final messages = <Map<String, String>>[];
    messages.add({'role': 'system', 'content': _buildAgentSystemPrompt(systemPrompt)});
    if (history != null) {
      messages.addAll(history);
    }
    messages.add({'role': 'user', 'content': userMessage});

    final toolCalls = <AgentToolCall>[];
    var finalContent = '';
    var iteration = 0;

    try {
      while (iteration < _maxIterations) {
        iteration++;
        final result = await _llmService.chat(
          message: messages.last['content']!,
          modelId: _modelId,
          systemPrompt: _buildAgentSystemPrompt(systemPrompt),
          // The last message is passed as `message` above; chat appends it
          // after the history entries, so it must NOT also appear in history
          // or the LLM would receive it twice. Index 0 is the agent system
          // prompt, which chat also takes separately as `systemPrompt`.
          history: messages.sublist(1, messages.length - 1),
          feature: feature,
        );

        if (result.isFailure) {
          _taskManager?.failTask(taskId, result.error!);
          return AgentResponse(
            content: 'I encountered an error processing your request.',
            toolCalls: toolCalls,
            error: result.error,
          );
        }

        final response = result.data!;
        final parsed = _parseResponse(response);

        if (parsed == null || parsed.toolName.isEmpty) {
          finalContent = response;
          break;
        }

        final tool = _toolRegistry.get(parsed.toolName);
        if (tool == null) {
          finalContent = 'I tried to use a tool "${parsed.toolName}" but it is not available.';
          break;
        }

        Map<String, dynamic> toolArgs = {};
        try {
          toolArgs = parsed.toolArguments.isNotEmpty
              ? jsonDecode(parsed.toolArguments) as Map<String, dynamic>
              : {};
        } catch (e) {
          _logger.w('Failed to parse tool arguments JSON: $e');
          toolArgs = {};
        }

        final toolCallId = const Uuid().v4();
        toolCalls.add(AgentToolCall(
          id: toolCallId,
          toolName: parsed.toolName,
          arguments: toolArgs,
        ));

        dynamic toolResult;
        try {
          toolResult = await tool.execute(toolArgs);
        } catch (e) {
          _logger.w('Tool execution failed: $e');
          toolResult = {'error': e.toString()};
        }

        final resultStr = toolResult is String ? toolResult : jsonEncode(toolResult);
        messages.add({'role': 'assistant', 'content': jsonEncode({
          'tool_call': parsed.toolName,
          'tool_call_id': toolCallId,
          'arguments': parsed.toolArguments,
        })});
        messages.add({'role': 'user', 'content': 'Tool result for ${parsed.toolName}: $resultStr'});

        toolCalls.last.result = resultStr;
      }

      if (iteration >= _maxIterations && finalContent.isEmpty) {
        finalContent = 'I completed the required actions. Is there anything else you need help with?';
      }

      // Aggregate tokens from LLM-service per-call tasks created during this
      // run, so the agent-turn task carries real token usage instead of 0
      // (vision next-term §4.2 token transparency).
      var totalTokens = 0;
      var totalCost = 0.0;
      if (_taskManager != null) {
        for (final t in _taskManager!.tasks) {
          if (preRunTaskIds.contains(t.id) || t.id == taskId) continue;
          totalTokens += t.tokensUsed;
          totalCost += t.estimatedCost;
        }
      }

      _taskManager?.completeTask(
        taskId,
        tokensUsed: totalTokens,
        estimatedCost: totalCost,
      );
      return AgentResponse(content: finalContent, toolCalls: toolCalls);
    } catch (e) {
      _logger.w('Agent loop error', e);
      _taskManager?.failTask(taskId, e.toString());
      return AgentResponse(
        content: 'An error occurred during processing.',
        toolCalls: toolCalls,
        error: e.toString(),
      );
    }
  }

  /// Streaming variant of [run].
  ///
  /// Like [run], this drives the think→act→observe loop, but instead of
  /// blocking on every LLM call and returning a single [AgentResponse], it
  /// yields text tokens progressively via [LlmService.chatStream] so callers
  /// (e.g. the mentor UI) can render a live, word-by-word reply while tools
  /// are still executing.
  ///
  /// Tool-call markers (`TOOL_CALL:` / `ARGUMENTS:`) are buffered internally
  /// and never surfaced to the caller — only the human-readable text *before*
  /// a tool call is yielded. The [onToolCall] callback (if supplied) is invoked
  /// once per executed tool so the caller can record side-effects (e.g. adding
  /// a system message to conversation memory).
  ///
  /// Token aggregation and task-lifecycle tracking mirror [run]: per-call LLM
  /// tasks created by [LlmService] are aggregated onto the agent-turn task.
  Stream<String> runStream({
    required String userMessage,
    required String studentId,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
    Future<void> Function(AgentToolCall call)? onToolCall,
  }) async* {
    final taskType = LlmTaskType.fromFeature(feature)?.name;
    final taskId = _taskManager?.createTask(
          feature: feature,
          modelId: _modelId,
          taskType: taskType,
        ) ??
        '';
    _taskManager?.startTask(taskId);

    final preRunTaskIds = _taskManager != null
        ? Set<String>.from(_taskManager!.tasks.map((t) => t.id))
        : const <String>{};

    final messages = <Map<String, String>>[];
    messages.add({'role': 'system', 'content': _buildAgentSystemPrompt(systemPrompt)});
    if (history != null) {
      messages.addAll(history);
    }
    messages.add({'role': 'user', 'content': userMessage});

    final toolCalls = <AgentToolCall>[];
    var finalContent = '';
    var iteration = 0;

    try {
      while (iteration < _maxIterations) {
        iteration++;

        // ---- Stream one LLM turn, yielding text progressively ----
        final buffer = StringBuffer();
        var yieldedCount = 0; // chars of [buffer] already emitted to caller

        await for (final chunk in _llmService.chatStream(
          message: messages.last['content']!,
          modelId: _modelId,
          systemPrompt: _buildAgentSystemPrompt(systemPrompt),
          history: messages.sublist(1, messages.length - 1),
          feature: feature,
        )) {
          buffer.write(chunk);
          final current = buffer.toString();

          // Detect the bare `TOOL_CALL:` marker first. A partial marker may
          // appear before the tool name and ARGUMENTS arrive, so we hold back
          // any text from the marker onward to avoid leaking tool-call syntax
          // to the UI.
          final markerMatch = RegExp(r'TOOL_CALL:').firstMatch(current);

          if (markerMatch != null) {
            final toolMatch = RegExp(r'TOOL_CALL:\s*(\S+)').firstMatch(current);
            final argsMatch = toolMatch != null
                ? RegExp(r'ARGUMENTS:\s*(\{.*\})', dotAll: true).firstMatch(current)
                : null;

            if (toolMatch != null && argsMatch != null) {
              // Complete tool call — yield only text before the marker, then
              // break to execute the tool.
              final textBeforeTool = current.substring(0, markerMatch.start);
              final remaining = textBeforeTool.substring(yieldedCount);
              if (remaining.isNotEmpty) {
                yield remaining;
                finalContent += remaining;
              }
              yieldedCount = current.length;
              break;
            } else {
              // Partial tool call (marker seen but ARGUMENTS incomplete or no
              // tool name yet). Yield text up to the marker, hold the rest.
              final textBeforeMarker = current.substring(0, markerMatch.start);
              final remaining = textBeforeMarker.substring(yieldedCount);
              if (remaining.isNotEmpty) {
                yield remaining;
                finalContent += remaining;
              }
              yieldedCount = markerMatch.start;
            }
          } else {
            // No tool call marker — yield the new text.
            final remaining = current.substring(yieldedCount);
            if (remaining.isNotEmpty) {
              yield remaining;
              finalContent += remaining;
            }
            yieldedCount = current.length;
          }
        }

        final response = buffer.toString();
        final parsed = _parseResponse(response);

        if (parsed == null || parsed.toolName.isEmpty) {
          // No tool call in this turn — streaming is complete.
          break;
        }

        final tool = _toolRegistry.get(parsed.toolName);
        if (tool == null) {
          finalContent = 'I tried to use a tool "${parsed.toolName}" but it is not available.';
          yield finalContent;
          break;
        }

        Map<String, dynamic> toolArgs = {};
        try {
          toolArgs = parsed.toolArguments.isNotEmpty
              ? jsonDecode(parsed.toolArguments) as Map<String, dynamic>
              : {};
        } catch (e) {
          _logger.w('Failed to parse tool arguments JSON: $e');
          toolArgs = {};
        }

        final toolCallId = const Uuid().v4();
        final toolCall = AgentToolCall(
          id: toolCallId,
          toolName: parsed.toolName,
          arguments: toolArgs,
        );

        dynamic toolResult;
        try {
          toolResult = await tool.execute(toolArgs);
        } catch (e) {
          _logger.w('Tool execution failed: $e');
          toolResult = {'error': e.toString()};
        }

        final resultStr = toolResult is String ? toolResult : jsonEncode(toolResult);
        toolCall.result = resultStr;
        toolCalls.add(toolCall);

        // Notify caller (e.g. MentorService records a system message).
        await onToolCall?.call(toolCall);

        messages.add({'role': 'assistant', 'content': jsonEncode({
          'tool_call': parsed.toolName,
          'tool_call_id': toolCallId,
          'arguments': parsed.toolArguments,
        })});
        messages.add({'role': 'user', 'content': 'Tool result for ${parsed.toolName}: $resultStr'});
      }

      if (iteration >= _maxIterations && finalContent.isEmpty) {
        finalContent = 'I completed the required actions. Is there anything else you need help with?';
        yield finalContent;
      }

      // Aggregate tokens from LLM-service per-call tasks created during this
      // run, so the agent-turn task carries real token usage instead of 0
      // (vision next-term §4.2 token transparency).
      var totalTokens = 0;
      var totalCost = 0.0;
      if (_taskManager != null) {
        for (final t in _taskManager!.tasks) {
          if (preRunTaskIds.contains(t.id) || t.id == taskId) continue;
          totalTokens += t.tokensUsed;
          totalCost += t.estimatedCost;
        }
      }

      _taskManager?.completeTask(
        taskId,
        tokensUsed: totalTokens,
        estimatedCost: totalCost,
      );
    } catch (e) {
      _logger.w('Agent loop stream error', e);
      if (_taskManager != null) {
        _taskManager!.failTask(taskId, e.toString());
      }
      yield 'An error occurred during processing.';
    }
  }

  String _buildAgentSystemPrompt(String basePrompt) {
    final toolDescriptions = _toolRegistry.toolDescriptions;
    final toolsJson = jsonEncode(toolDescriptions);
    return '$basePrompt\n\nYou have access to the following tools. When you need to use a tool, respond with exactly:\nTOOL_CALL: tool_name\nARGUMENTS: {"key": "value"}\n\nAvailable tools:\n$toolsJson\n\nIf no tool is needed, respond normally. You can call multiple tools sequentially.';
  }

  _ParsedResponse? _parseResponse(String response) {
    final toolMatch = RegExp(r'TOOL_CALL:\s*(\S+)').firstMatch(response);
    if (toolMatch != null) {
      final toolName = toolMatch.group(1)!.trim();
      final argsMatch = RegExp(r'ARGUMENTS:\s*(\{.*\})', dotAll: true).firstMatch(response);
      final args = argsMatch != null ? argsMatch.group(1)!.trim() : '{}';
      return _ParsedResponse(toolName: toolName, toolArguments: args);
    }

    try {
      final jsonMatch = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true).firstMatch(response);
      final jsonStr = jsonMatch != null ? jsonMatch.group(1)!.trim() : response.trim();
      final parsed = jsonDecode(jsonStr);
      if (parsed is Map<String, dynamic>) {
        final toolName = parsed['tool'] as String? ?? parsed['tool_call'] as String? ?? '';
        final args = parsed['arguments'] ?? parsed['args'] ?? <String, dynamic>{};
        final argsStr = args is String ? args : jsonEncode(args);
        if (toolName.isNotEmpty) {
          return _ParsedResponse(toolName: toolName, toolArguments: argsStr);
        }
      }
    } catch (e) {
      _logger.w('Failed to parse inline JSON tool call: $e');
    }

    return null;
  }
}

class _ParsedResponse {
  final String toolName;
  final String toolArguments;
  _ParsedResponse({required this.toolName, required this.toolArguments});
}

class AgentToolCall {
  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  String? result;

  AgentToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.result,
  });
}

class AgentResponse {
  final String content;
  final List<AgentToolCall> toolCalls;
  final String? error;

  AgentResponse({
    required this.content,
    required this.toolCalls,
    this.error,
  });
}
