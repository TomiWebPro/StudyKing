import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../errors/result.dart';
import '../conversation_memory.dart';
export '../conversation_memory.dart' show ConversationMemory;
import '../llm_task_manager.dart';
import '../llm_usage_meter.dart' show LlmUsageMeter;

enum LlmProvider { openRouter, ollama, openAI }

class LlmConfiguration {
  final LlmProvider provider;
  final String apiKey;
  final String baseUrl;
  final void Function(int inputTokens, int outputTokens, String model)? onTokenUsage;

  const LlmConfiguration({
    required this.provider,
    required this.apiKey,
    this.baseUrl = '',
    this.onTokenUsage,
  });
}

class LlmService {
  static String defaultSystemPromptForLocale(String localeName) {
    return lookupAppLocalizations(Locale(localeName)).aiDefaultSystemPrompt;
  }

  final LlmConfiguration config;
  final http.Client _httpClient;
  final LlmTaskManager? _taskManager;
  final LlmUsageMeter? _usageMeter;

  LlmService({
    required this.config,
    http.Client? httpClient,
    LlmTaskManager? taskManager,
    LlmUsageMeter? usageMeter,
  }) : _httpClient = httpClient ?? http.Client(),
       _taskManager = taskManager,
       _usageMeter = usageMeter;

  Uri get _openRouterUrl => ApiConfig.forEnvironment(BuildConfig.environment).openRouterBaseUrl;

  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    if (config.apiKey.isEmpty) {
      return Result.failure('API key is empty');
    }

    final effectiveSystemPrompt = systemPrompt ?? defaultSystemPromptForLocale(localeName);

    switch (config.provider) {
      case LlmProvider.openRouter:
        return await _callOpenRouter(message, modelId, effectiveSystemPrompt, memory: memory, history: history, feature: feature);
      case LlmProvider.ollama:
        return await _callOllama(message, modelId, memory: memory, history: history, feature: feature);
      case LlmProvider.openAI:
        return await _callOpenAI(message, modelId, effectiveSystemPrompt, memory: memory, history: history, feature: feature);
    }
  }

  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    if (config.apiKey.isEmpty) {
      return;
    }

    final effectiveSystemPrompt = systemPrompt ?? defaultSystemPromptForLocale(localeName);

    switch (config.provider) {
      case LlmProvider.openRouter:
        yield* _streamOpenRouter(message, modelId, effectiveSystemPrompt, memory: memory, history: history, feature: feature);
        break;
      case LlmProvider.ollama:
        yield* _streamOllama(message, modelId, memory: memory, history: history, feature: feature);
        break;
      case LlmProvider.openAI:
        yield* _streamOpenAI(message, modelId, effectiveSystemPrompt, memory: memory, history: history, feature: feature);
        break;
    }
  }

  List<Map<String, String>> _buildMessages({
    required String message,
    required String systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
  }) {
    final messages = <Map<String, String>>[];
    messages.add({'role': 'system', 'content': systemPrompt});

    if (memory != null) {
      messages.addAll(ConversationMemory.fromConversationMessages(memory.getHistory()));
    } else if (history != null) {
      messages.addAll(history);
    }

    messages.add({'role': 'user', 'content': message});
    return messages;
  }

  void _initTask(String taskId) {
    if (taskId.isNotEmpty) {
      _taskManager?.startTask(taskId);
    }
  }

  void _completeTask(String taskId, {int tokensUsed = 0, double estimatedCost = 0.0}) {
    if (taskId.isNotEmpty) {
      _taskManager?.completeTask(taskId, tokensUsed: tokensUsed, estimatedCost: estimatedCost);
    }
  }

  void _failTask(String taskId, String error) {
    if (taskId.isNotEmpty) {
      _taskManager?.failTask(taskId, error);
    }
  }

  Future<Result<String>> _callOpenRouter(
    String message,
    String modelId,
    String systemPrompt, {
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    final taskId = _taskManager?.createTask(feature: feature, modelId: modelId) ?? '';
    _initTask(taskId);
    final url = _openRouterUrl;
    final messages = _buildMessages(
      message: message,
      systemPrompt: systemPrompt,
      memory: memory,
      history: history,
    );
    final response = await _httpClient.post(
      Uri.parse('$url/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
        'HTTP-Referer': BuildConfig.appName,
      },
      body: jsonEncode({
        'model': modelId,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      _trackUsage(data, modelId, feature, taskId: taskId);
      return Result.success(content);
    }
    _failTask(taskId, 'OpenRouter API Error: ${response.body}');
    return Result.failure('OpenRouter API Error: ${response.body}');
  }

  Stream<String> _streamOpenRouter(
    String message,
    String modelId,
    String systemPrompt, {
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    final taskId = _taskManager?.createTask(feature: feature, modelId: modelId) ?? '';
    _initTask(taskId);
    final url = _openRouterUrl;
    final messages = _buildMessages(
      message: message,
      systemPrompt: systemPrompt,
      memory: memory,
      history: history,
    );

    final request = http.Request('POST', Uri.parse('$url/chat/completions'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
      'HTTP-Referer': BuildConfig.appName,
    });
    request.body = jsonEncode({
      'model': modelId,
      'messages': messages,
      'stream': true,
    });

    try {
      final streamedResponse = await _httpClient.send(request);
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = '';
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr) as Map<String, dynamic>;
            final choice = data['choices']?[0];
            if (choice != null) {
              final delta = choice['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                fullContent += content;
                yield content;
              }
            }
          } catch (e) {
            const Logger('LlmService').e('Failed to parse SSE response: $e');
          }
        }
      }
      _completeTask(taskId, tokensUsed: fullContent.length ~/ 4);
      _usageMeter?.recordUsage(
        id: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: _estimateInputTokens(message, systemPrompt),
        outputTokens: fullContent.length ~/ 4,
      );
    } catch (e) {
      _failTask(taskId, e.toString());
      rethrow;
    }
  }

  Future<Result<String>> _callOllama(
    String message,
    String modelId, {
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    final taskId = _taskManager?.createTask(feature: feature, modelId: modelId) ?? '';
    _initTask(taskId);
    final baseUrl = config.baseUrl.isNotEmpty ? config.baseUrl : ApiConfig.ollamaDefaultUrl;
    var ollamaMessages = <Map<String, String>>[];
    if (memory != null) {
      ollamaMessages.addAll(ConversationMemory.fromConversationMessages(memory.getHistory()));
    } else if (history != null) {
      ollamaMessages.addAll(history);
    }
    ollamaMessages.add({'role': 'user', 'content': message});

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': modelId,
        'messages': ollamaMessages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['message']['content'] as String;
      _completeTask(taskId, tokensUsed: content.length ~/ 4);
      _usageMeter?.recordUsage(
        id: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: _estimateInputTokens(message, ''),
        outputTokens: content.length ~/ 4,
      );
      return Result.success(content);
    }
    _failTask(taskId, 'Ollama API Error: ${response.body}');
    return Result.failure('Ollama API Error: ${response.body}');
  }

  Stream<String> _streamOllama(
    String message,
    String modelId, {
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    final taskId = _taskManager?.createTask(feature: feature, modelId: modelId) ?? '';
    _initTask(taskId);
    final baseUrl = config.baseUrl.isNotEmpty ? config.baseUrl : ApiConfig.ollamaDefaultUrl;
    var ollamaMessages = <Map<String, String>>[];
    if (memory != null) {
      ollamaMessages.addAll(ConversationMemory.fromConversationMessages(memory.getHistory()));
    } else if (history != null) {
      ollamaMessages.addAll(history);
    }
    ollamaMessages.add({'role': 'user', 'content': message});

    final request = http.Request('POST', Uri.parse('$baseUrl/api/chat'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': modelId,
      'messages': ollamaMessages,
      'stream': true,
    });

    try {
      final streamedResponse = await _httpClient.send(request);
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = '';
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          final done = data['done'] as bool? ?? false;
          final content = data['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            fullContent += content;
            yield content;
          }
          if (done) break;
        } catch (e) {
          const Logger('LlmService').e('Failed to parse Ollama response: $e');
        }
      }
      _completeTask(taskId, tokensUsed: fullContent.length ~/ 4);
      _usageMeter?.recordUsage(
        id: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: _estimateInputTokens(message, ''),
        outputTokens: fullContent.length ~/ 4,
      );
    } catch (e) {
      _failTask(taskId, e.toString());
      rethrow;
    }
  }

  Future<Result<String>> _callOpenAI(
    String message,
    String modelId,
    String systemPrompt, {
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    final taskId = _taskManager?.createTask(feature: feature, modelId: modelId) ?? '';
    _initTask(taskId);
    final baseUrl = config.baseUrl.isNotEmpty ? config.baseUrl : ApiConfig.openAIDefaultUrl;
    final messages = _buildMessages(
      message: message,
      systemPrompt: systemPrompt,
      memory: memory,
      history: history,
    );
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode({
        'model': modelId,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      _trackUsage(data, modelId, feature, taskId: taskId);
      return Result.success(content);
    }
    _failTask(taskId, 'OpenAI API Error: ${response.body}');
    return Result.failure('OpenAI API Error: ${response.body}');
  }

  Stream<String> _streamOpenAI(
    String message,
    String modelId,
    String systemPrompt, {
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    final taskId = _taskManager?.createTask(feature: feature, modelId: modelId) ?? '';
    _initTask(taskId);
    final baseUrl = config.baseUrl.isNotEmpty ? config.baseUrl : ApiConfig.openAIDefaultUrl;
    final messages = _buildMessages(
      message: message,
      systemPrompt: systemPrompt,
      memory: memory,
      history: history,
    );

    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    });
    request.body = jsonEncode({
      'model': modelId,
      'messages': messages,
      'stream': true,
    });

    try {
      final streamedResponse = await _httpClient.send(request);
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = '';
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr) as Map<String, dynamic>;
            final choice = data['choices']?[0];
            if (choice != null) {
              final delta = choice['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                fullContent += content;
                yield content;
              }
            }
          } catch (e) {
            const Logger('LlmService').e('Failed to parse SSE response: $e');
          }
        }
      }
      _completeTask(taskId, tokensUsed: fullContent.length ~/ 4);
      _usageMeter?.recordUsage(
        id: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: _estimateInputTokens(message, systemPrompt),
        outputTokens: fullContent.length ~/ 4,
      );
    } catch (e) {
      _failTask(taskId, e.toString());
      rethrow;
    }
  }

  int _estimateInputTokens(String message, String systemPrompt) {
    return (systemPrompt.length + message.length) ~/ 4;
  }

  void _trackUsage(Map<String, dynamic> responseData, String modelId, String feature, {String taskId = ''}) {
    final usage = responseData['usage'] as Map<String, dynamic>?;
    if (usage != null && config.onTokenUsage != null) {
      final inputTokens = usage['prompt_tokens'] as int? ?? 0;
      final outputTokens = usage['completion_tokens'] as int? ?? 0;
      config.onTokenUsage!(inputTokens, outputTokens, modelId);
    }
    if (usage != null) {
      final inputTokens = usage['prompt_tokens'] as int? ?? 0;
      final outputTokens = usage['completion_tokens'] as int? ?? 0;
      _completeTask(taskId, tokensUsed: inputTokens + outputTokens);
      _usageMeter?.recordUsage(
        id: taskId.isNotEmpty ? taskId : 'usage_${DateTime.now().millisecondsSinceEpoch}',
        feature: feature,
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
    } else {
      _completeTask(taskId);
    }
  }

}
