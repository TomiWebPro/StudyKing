import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';

class AgentLoop {
  static final Logger _logger = const Logger('AgentLoop');
  static const int _maxIterations = 10;

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

  Future<AgentResponse> run({
    required String userMessage,
    required String studentId,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
  }) async {
    final taskId = _taskManager?.createTask(feature: feature, modelId: _modelId) ?? '';
    _taskManager?.startTask(taskId);

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
          history: messages.sublist(1),
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
          finalContent = 'I tried to use a tool "$parsed" but it is not available.';
          break;
        }

        Map<String, dynamic> toolArgs = {};
        try {
          toolArgs = parsed.toolArguments.isNotEmpty
              ? jsonDecode(parsed.toolArguments) as Map<String, dynamic>
              : {};
        } catch (e) {
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
          toolResult = {'error': e.toString()};
        }

        final resultStr = toolResult is String ? toolResult : jsonEncode(toolResult);
        messages.add({'role': 'assistant', 'content': jsonEncode({
          'tool_call': parsed.toolName,
          'tool_call_id': toolCallId,
          'arguments': parsed.toolArguments,
        })});
        messages.add({'role': 'user', 'content': 'Tool result for $parsed.toolName}: $resultStr'});

        toolCalls.last.result = resultStr;
      }

      if (iteration >= _maxIterations && finalContent.isEmpty) {
        finalContent = 'I completed the required actions. Is there anything else you need help with?';
      }

      _taskManager?.completeTask(taskId);
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

    final jsonBlock = RegExp(r'```(?:json)?\s*\n?(\{[\s\S]*?\})\s*\n?```').firstMatch(response);
    if (jsonBlock != null) {
      try {
        final parsed = jsonDecode(jsonBlock.group(1)!);
        if (parsed is Map<String, dynamic>) {
          final toolName = parsed['tool'] as String? ?? parsed['tool_call'] as String? ?? '';
          final args = parsed['arguments'] ?? parsed['args'] ?? <String, dynamic>{};
          final argsStr = args is String ? args : jsonEncode(args);
          if (toolName.isNotEmpty) {
            return _ParsedResponse(toolName: toolName, toolArguments: argsStr);
          }
        }
      } catch (e) {
        _logger.w('Failed to parse JSON block tool call: $e');
      }
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
