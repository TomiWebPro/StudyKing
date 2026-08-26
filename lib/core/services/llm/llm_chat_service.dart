import 'dart:async';
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
import '../../../features/settings/data/models/settings_model.dart' show UsageRecord;
import 'llm_response_cache.dart' show LlmResponseCache;
import 'model_router.dart' show LlmTaskType;

enum LlmProvider { openRouter, ollama, openAI, custom }

class LlmConfiguration {
  final LlmProvider provider;
  final String apiKey;
  final String baseUrl;
  final String model;

  // Backup provider fields (B4: provider fallback/failover)
  final LlmProvider? backupProvider;
  final String? backupApiKey;
  final String? backupBaseUrl;
  final String? backupModel;

  final void Function(int inputTokens, int outputTokens, String model)? onTokenUsage;

  const LlmConfiguration({
    required this.provider,
    required this.apiKey,
    this.baseUrl = '',
    this.model = '',
    this.backupProvider,
    this.backupApiKey,
    this.backupBaseUrl,
    this.backupModel,
    this.onTokenUsage,
  });

  bool get hasBackup => backupProvider != null && (backupApiKey != null && backupApiKey!.isNotEmpty);

  LlmConfiguration copyWithBackup({
    LlmProvider? backupProvider,
    String? backupApiKey,
    String? backupBaseUrl,
    String? backupModel,
  }) {
    return LlmConfiguration(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      backupProvider: backupProvider ?? this.backupProvider,
      backupApiKey: backupApiKey ?? this.backupApiKey,
      backupBaseUrl: backupBaseUrl ?? this.backupBaseUrl,
      backupModel: backupModel ?? this.backupModel,
      onTokenUsage: onTokenUsage,
    );
  }
}

class TokenBucket {
  final int _capacity;
  final Duration _refillInterval;
  int _tokens;
  DateTime _lastRefill;

  TokenBucket({
    required int capacity,
    required Duration refillInterval,
  })  : _capacity = capacity,
        _refillInterval = refillInterval,
        _tokens = capacity,
        _lastRefill = DateTime.now();

  bool tryConsume(int count) {
    _refill();
    if (_tokens >= count) {
      _tokens -= count;
      return true;
    }
    return false;
  }

  void _refill() {
    final elapsed = DateTime.now().difference(_lastRefill);
    final tokensToAdd = elapsed.inMilliseconds ~/ _refillInterval.inMilliseconds;
    if (tokensToAdd > 0) {
      _tokens = (_tokens + tokensToAdd).clamp(0, _capacity);
      _lastRefill = DateTime.now();
    }
  }
}

class LlmService {
  static final Logger _logger = const Logger('LlmService');
  static String defaultSystemPromptForLocale(String localeName) {
    return lookupAppLocalizations(Locale(localeName)).aiDefaultSystemPrompt;
  }

  final LlmConfiguration config;
  final http.Client _httpClient;
  final LlmTaskManager? _taskManager;
  final LlmUsageMeter? _usageMeter;
  final LlmResponseCache? _cache;

  /// Client-side throttling: minimum 500ms between calls (B3)
  DateTime _lastCallTime = DateTime.now().subtract(const Duration(seconds: 1));
  static const Duration _minCallInterval = Duration(milliseconds: 500);

  /// Per-user token-bucket rate limiter (B3 enhancement)
  static final Map<String, TokenBucket> _userBuckets = {};
  String _studentId = '';

  void setStudentId(String id) {
    _studentId = id;
    if (id.isNotEmpty && !_userBuckets.containsKey(id)) {
      _userBuckets[id] = TokenBucket(
        capacity: 20,
        refillInterval: const Duration(seconds: 1),
      );
    }
  }

  /// Returns true if the last throttle call had to wait (i.e., it was active)
  bool _lastThrottleWasActive = false;

  bool get wasThrottleActive => _lastThrottleWasActive;

  LlmService({
    required this.config,
    http.Client? httpClient,
    LlmTaskManager? taskManager,
    LlmUsageMeter? usageMeter,
    LlmResponseCache? cache,
  }) : _httpClient = httpClient ?? http.Client(),
       _taskManager = taskManager,
       _usageMeter = usageMeter,
       _cache = cache;

  Uri get _openRouterUrl => ApiConfig.forEnvironment(BuildConfig.environment).openRouterBaseUrl;

  /// Status code to typed error mapping (B2)
  static String _errorForStatusCode(int code, String providerName) {
    return switch (code) {
      401 => 'API key is invalid or expired. Update in Settings.',
      403 => 'Access forbidden. Check your API key permissions.',
      404 => 'Model not found. Check model name in Settings.',
      429 => 'Too many requests. Wait and try again.',
      500 || 502 || 503 => '$providerName server error (HTTP $code). Try again later or switch providers.',
      _ => '$providerName API Error (HTTP $code)',
    };
  }

  /// Enforce minimum interval between calls (B3) using token-bucket per-user
  Future<void> _throttle() async {
    _lastThrottleWasActive = false;
    final elapsed = DateTime.now().difference(_lastCallTime);
    if (elapsed < _minCallInterval) {
      _lastThrottleWasActive = true;
      await Future.delayed(_minCallInterval - elapsed);
    }
    _lastCallTime = DateTime.now();
    if (_studentId.isNotEmpty) {
      final bucket = _userBuckets[_studentId];
      if (bucket != null) {
        if (!bucket.tryConsume(1)) {
          _lastThrottleWasActive = true;
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }
  }

  /// Attempt streaming with a backup provider if primary fails (B4)
  Stream<String> _streamWithFallback({
    required String message,
    required String modelId,
    required String systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    required Stream<String> Function({
      required String message,
      required String modelId,
      required String systemPrompt,
      ConversationMemory? memory,
      List<Map<String, String>>? history,
      String feature,
    }) primaryStream,
  }) async* {
    try {
      // NOTE: `yield*` forwards inner-stream errors to the listener rather than
      // re-throwing them in this generator's body, so the surrounding try/catch
      // would never see them. Consuming via `await for` routes errors through
      // the body where failover can handle them.
      await for (final chunk in primaryStream(
        message: message,
        modelId: modelId,
        systemPrompt: systemPrompt,
        memory: memory,
        history: history,
        feature: feature,
      )) {
        yield chunk;
      }
    } catch (e) {
      final errorStr = e.toString();
      final isServerError = errorStr.contains('500') || errorStr.contains('502') ||
          errorStr.contains('503') || errorStr.contains('timed out') ||
          errorStr.contains('ConnectionFailedError') || errorStr.contains('SocketException');

      if (isServerError && config.hasBackup) {
        yield '\n\n[Primary provider failed. Trying backup provider...]\n\n';
        yield* _streamBackup(
          message: message,
          modelId: config.backupModel ?? modelId,
          systemPrompt: systemPrompt,
          memory: memory,
          history: history,
          feature: feature,
        );
      } else {
        rethrow;
      }
    }
  }

  Stream<String> _streamBackup({
    required String message,
    required String modelId,
    required String systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    final backupConfig = LlmConfiguration(
      provider: config.backupProvider!,
      apiKey: config.backupApiKey!,
      baseUrl: config.backupBaseUrl ?? '',
      model: config.backupModel ?? modelId,
    );
    final backupService = LlmService(
      config: backupConfig,
      httpClient: _httpClient,
      taskManager: _taskManager,
      usageMeter: _usageMeter,
      cache: _cache,
    );
    yield* backupService.chatStream(
      message: message,
      modelId: modelId,
      systemPrompt: systemPrompt,
      memory: memory,
      history: history,
      feature: feature,
    );
  }

  /// Non-streaming fallback (B4)
  Future<Result<String>> _callWithFallback({
    required String message,
    required String modelId,
    required String systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
    required Future<Result<String>> Function({
      required String message,
      required String modelId,
      required String systemPrompt,
      ConversationMemory? memory,
      List<Map<String, String>>? history,
      String feature,
    }) primaryCall,
  }) async {
    final result = await primaryCall(
      message: message,
      modelId: modelId,
      systemPrompt: systemPrompt,
      memory: memory,
      history: history,
      feature: feature,
    );

    if (result.isFailure && config.hasBackup) {
      final errorStr = result.error ?? '';
      final isServerError = errorStr.contains('500') || errorStr.contains('502') ||
          errorStr.contains('503') || errorStr.contains('timed out') ||
          errorStr.contains('SocketException');

      if (isServerError) {
        final backupConfig = LlmConfiguration(
          provider: config.backupProvider!,
          apiKey: config.backupApiKey!,
          baseUrl: config.backupBaseUrl ?? '',
          model: config.backupModel ?? modelId,
        );
        final backupService = LlmService(
          config: backupConfig,
          httpClient: _httpClient,
          taskManager: _taskManager,
          usageMeter: _usageMeter,
          cache: _cache,
        );
        return await backupService.chat(
          message: message,
          modelId: config.backupModel ?? modelId,
          systemPrompt: systemPrompt,
          memory: memory,
          history: history,
          feature: '$feature (fallback)',
        );
      }
    }
    return result;
  }

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
    if (modelId.isEmpty) {
      return Result.failure(
        'No model selected. Please go to Settings and select an AI model.',
      );
    }

    final effectiveSystemPrompt = systemPrompt ?? defaultSystemPromptForLocale(localeName);

    final cached = _cache?.get(modelId, effectiveSystemPrompt, message);
    if (cached != null) {
      _logger.w('Cache hit for feature=$feature, model=$modelId');
      return Result.success(cached);
    }

    final result = await _callWithFallback(
      message: message,
      modelId: modelId,
      systemPrompt: effectiveSystemPrompt,
      memory: memory,
      history: history,
      feature: feature,
      primaryCall: ({
        required String message,
        required String modelId,
        required String systemPrompt,
        ConversationMemory? memory,
        List<Map<String, String>>? history,
        String feature = 'general',
      }) async {
        switch (config.provider) {
          case LlmProvider.openRouter:
            return await _callOpenRouter(message, modelId, systemPrompt, memory: memory, history: history, feature: feature);
          case LlmProvider.ollama:
            return await _callOllama(message, modelId, memory: memory, history: history, feature: feature);
          case LlmProvider.openAI:
            return await _callOpenAI(message, modelId, systemPrompt, memory: memory, history: history, feature: feature);
          case LlmProvider.custom:
            return await _callOpenAI(message, modelId, systemPrompt, memory: memory, history: history, feature: feature);
        }
      },
    );

    if (result.isSuccess) {
      final ttl = _cache?.ttlForFeature(feature) ?? const Duration(minutes: 10);
      _cache?.set(modelId, effectiveSystemPrompt, message, result.data!, ttl: ttl);
    }

    return result;
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
      yield 'API key not configured. Please set up an API key in Settings to use AI features.';
      return;
    }
    if (modelId.isEmpty) {
      yield 'No model selected. Please go to Settings and select an AI model.';
      return;
    }

    final effectiveSystemPrompt = systemPrompt ?? defaultSystemPromptForLocale(localeName);

    final cached = _cache?.get(modelId, effectiveSystemPrompt, message);
    if (cached != null) {
      _logger.w('Cache hit (stream) for feature=$feature, model=$modelId');
      yield cached;
      return;
    }

    String fullContent = '';
    yield* _streamWithFallback(
      message: message,
      modelId: modelId,
      systemPrompt: effectiveSystemPrompt,
      memory: memory,
      history: history,
      feature: feature,
      primaryStream: ({
        required String message,
        required String modelId,
        required String systemPrompt,
        ConversationMemory? memory,
        List<Map<String, String>>? history,
        String feature = 'general',
      }) {
        switch (config.provider) {
          case LlmProvider.openRouter:
            return _streamOpenRouter(message, modelId, systemPrompt, memory: memory, history: history, feature: feature);
          case LlmProvider.ollama:
            return _streamOllama(message, modelId, memory: memory, history: history, feature: feature);
          case LlmProvider.openAI:
            return _streamOpenAI(message, modelId, systemPrompt, memory: memory, history: history, feature: feature);
          case LlmProvider.custom:
            return _streamOpenAI(message, modelId, systemPrompt, memory: memory, history: history, feature: feature);
        }
      },
    ).transform(
      StreamTransformer<String, String>.fromHandlers(
        handleData: (data, sink) {
          fullContent += data;
          sink.add(data);
        },
        handleDone: (sink) {
          if (fullContent.isNotEmpty) {
            final ttl = _cache?.ttlForFeature(feature) ?? const Duration(minutes: 10);
            _cache?.set(modelId, effectiveSystemPrompt, message, fullContent, ttl: ttl);
          }
          sink.close();
        },
      ),
    );
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

  void _completeTask(
    String taskId, {
    int tokensUsed = 0,
    int inputTokens = 0,
    int outputTokens = 0,
    double estimatedCost = 0.0,
  }) {
    if (taskId.isEmpty) return;
    final totalTokens = tokensUsed > 0 ? tokensUsed : (inputTokens + outputTokens);
    final cost = estimatedCost > 0
        ? estimatedCost
        : UsageRecord.calculateTotalCost(inputTokens, outputTokens, 0);
    _taskManager?.completeTask(
      taskId,
      tokensUsed: totalTokens,
      estimatedCost: cost,
    );
  }

  /// Finalizes a task and records usage, computing the estimated cost from the
  /// model's pricing so the LLM task-manager portal shows accurate totals.
  void _recordCompletion({
    required String taskId,
    required String feature,
    required String modelId,
    required int inputTokens,
    required int outputTokens,
    int? tokensUsed,
  }) {
    _completeTask(
      taskId,
      tokensUsed: tokensUsed ?? (inputTokens + outputTokens),
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
    _usageMeter?.recordUsage(
      id: taskId.isNotEmpty ? taskId : 'usage_${DateTime.now().millisecondsSinceEpoch}',
      feature: feature,
      modelId: modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      taskType: LlmTaskType.fromFeature(feature)?.name,
    );
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
    await _throttle();
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
        'Authorization': '${ApiConfig.bearerAuth}${config.apiKey}',
        'HTTP-Referer': BuildConfig.appName,
      },
      body: jsonEncode({
        'model': modelId,
        'messages': messages,
      }),
    ).timeout(Timeouts.openRouterTimeoutProduction);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      _trackUsage(data, modelId, feature, taskId: taskId);
      return Result.success(content);
    }
    final errorMsg = _errorForStatusCode(response.statusCode, 'OpenRouter');
    _failTask(taskId, errorMsg);
    return Result.failure(errorMsg);
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
    await _throttle();
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
      'Authorization': '${ApiConfig.bearerAuth}${config.apiKey}',
      'HTTP-Referer': BuildConfig.appName,
    });
    request.body = jsonEncode({
      'model': modelId,
      'messages': messages,
      'stream': true,
      'stream_options': {'include_usage': true},
    });

    try {
      final streamedResponse = await _httpClient.send(request).timeout(Timeouts.openRouterTimeoutProduction);
      if (streamedResponse.statusCode != 200) {
        final errorMsg = _errorForStatusCode(streamedResponse.statusCode, 'OpenRouter');
        _failTask(taskId, errorMsg);
        yield '\n\n[$errorMsg]\n\n';
        return;
      }
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = '';
      Map<String, dynamic>? lastUsage;
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr) as Map<String, dynamic>;
            final usage = data['usage'] as Map<String, dynamic>?;
            if (usage != null) {
              lastUsage = usage;
            }
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
            _logger.w('Failed to parse SSE response: $e');
          }
        }
      }
      int inputTokens;
      int outputTokens;
      if (lastUsage != null) {
        inputTokens = lastUsage['prompt_tokens'] as int? ?? 0;
        outputTokens = lastUsage['completion_tokens'] as int? ?? 0;
      } else {
        inputTokens = _estimateInputTokens(message, systemPrompt);
        outputTokens = fullContent.length ~/ 4;
      }
      _recordCompletion(
        taskId: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
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
    await _throttle();
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
    ).timeout(Timeouts.openRouterTimeoutProduction);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['message']['content'] as String;
      final inputTokens = data['prompt_eval_count'] as int? ?? _estimateInputTokens(message, '');
      final outputTokens = data['eval_count'] as int? ?? content.length ~/ 4;
      _recordCompletion(
        taskId: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
      return Result.success(content);
    }
    final errorMsg = _errorForStatusCode(response.statusCode, 'Ollama');
    _failTask(taskId, errorMsg);
    return Result.failure(errorMsg);
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
    await _throttle();
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
      final streamedResponse = await _httpClient.send(request).timeout(Timeouts.openRouterTimeoutProduction);
      if (streamedResponse.statusCode != 200) {
        final errorMsg = _errorForStatusCode(streamedResponse.statusCode, 'Ollama');
        _failTask(taskId, errorMsg);
        yield '\n\n[$errorMsg]\n\n';
        return;
      }
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = '';
      Map<String, dynamic>? lastUsage;
      int? promptEvalCount;
      int? evalCount;
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          final usage = data['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            lastUsage = usage;
          }
          final done = data['done'] as bool? ?? false;
          if (done) {
            promptEvalCount = data['prompt_eval_count'] as int?;
            evalCount = data['eval_count'] as int?;
          }
          final content = data['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            fullContent += content;
            yield content;
          }
          if (done) break;
        } catch (e) {
          _logger.w('Failed to parse Ollama response: $e');
        }
      }
      int inputTokens;
      int outputTokens;
      if (lastUsage != null) {
        inputTokens = lastUsage['prompt_tokens'] as int? ?? 0;
        outputTokens = lastUsage['completion_tokens'] as int? ?? 0;
      } else {
        inputTokens = promptEvalCount ?? _estimateInputTokens(message, '');
        outputTokens = evalCount ?? fullContent.length ~/ 4;
      }
      _recordCompletion(
        taskId: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
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
    await _throttle();
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
        'Authorization': '${ApiConfig.bearerAuth}${config.apiKey}',
      },
      body: jsonEncode({
        'model': modelId,
        'messages': messages,
      }),
    ).timeout(Timeouts.openRouterTimeoutProduction);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      _trackUsage(data, modelId, feature, taskId: taskId);
      return Result.success(content);
    }
    final errorMsg = _errorForStatusCode(response.statusCode, 'OpenAI');
    _failTask(taskId, errorMsg);
    return Result.failure(errorMsg);
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
    await _throttle();
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
      'Authorization': '${ApiConfig.bearerAuth}${config.apiKey}',
    });
    request.body = jsonEncode({
      'model': modelId,
      'messages': messages,
      'stream': true,
      'stream_options': {'include_usage': true},
    });

    try {
      final streamedResponse = await _httpClient.send(request).timeout(Timeouts.openRouterTimeoutProduction);
      if (streamedResponse.statusCode != 200) {
        final errorMsg = _errorForStatusCode(streamedResponse.statusCode, 'OpenAI');
        _failTask(taskId, errorMsg);
        yield '\n\n[$errorMsg]\n\n';
        return;
      }
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = '';
      Map<String, dynamic>? lastUsage;
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr) as Map<String, dynamic>;
            final usage = data['usage'] as Map<String, dynamic>?;
            if (usage != null) {
              lastUsage = usage;
            }
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
            _logger.w('Failed to parse SSE response: $e');
          }
        }
      }
      int inputTokens;
      int outputTokens;
      if (lastUsage != null) {
        inputTokens = lastUsage['prompt_tokens'] as int? ?? 0;
        outputTokens = lastUsage['completion_tokens'] as int? ?? 0;
      } else {
        inputTokens = _estimateInputTokens(message, systemPrompt);
        outputTokens = fullContent.length ~/ 4;
      }
      _recordCompletion(
        taskId: taskId,
        feature: feature,
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
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
      _recordCompletion(
        taskId: taskId,
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
