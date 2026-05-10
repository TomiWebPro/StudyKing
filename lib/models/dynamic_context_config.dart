import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Dynamic context window configuration fetched from LLM provider
/// Automatically determined per model, with fallback
@immutable
class DynamicContextConfig {
  final String modelId;
  final int contextWindow;
  final int actualContextUsed;
  final bool autoFetched;
  final int batchSize;
  final Duration batchInterval;

  const DynamicContextConfig({
    required this.modelId,
    required this.contextWindow,
    this.actualContextUsed = 0,
    this.autoFetched = false,
    this.batchSize = 10,
    this.batchInterval = const Duration(seconds: 2),
  });

  factory DynamicContextConfig.fromModel(String modelId) {
    // Common model context windows (OpenRouter aware)
    final _contextMap = {
      'anthropic/claude-3-5-sonnet': 200000,
      'meta/llama-3-1-405b-instruct': 128000,
      'google/gemini-2.0-flash': 1000000,
      'google/gemini-1.5-pro': 200000,
      'mistralai/mistral-large': 32000,
      'meta/llama-3.2-90b-vision-instruct': 128000,
      'meta/llama-3.1-70b-instruct': 128000,
      'meta/llama-3-70b-instruct': 8192,
      'mistralai/mistral-7b-instruct': 32768,
      'openai/gpt-4o': 128000,
    };

    return DynamicContextConfig(
      modelId: modelId,
      contextWindow: _contextMap[modelId] ?? 4096,
      autoFetched: false,
      batchSize: 10,
      batchInterval: const Duration(seconds: 2),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'contextWindow': contextWindow,
      'actualContextUsed': actualContextUsed,
      'batchSize': batchSize,
      'batchIntervalMs': batchInterval.inMilliseconds,
    };
  }

  factory DynamicContextConfig.fromJson(Map<String, dynamic> json) {
    return DynamicContextConfig(
      modelId: json['modelId'] ?? 'unknown',
      contextWindow: json['contextWindow']?.toInt() ?? 4096,
      actualContextUsed: json['actualContextUsed']?.toInt() ?? 0,
      autoFetched: json['autoFetched'] ?? false,
      batchSize: json['batchSize']?.toInt() ?? 5,
      batchInterval: Duration(
        milliseconds: json['batchIntervalMs']?.toInt() ?? 2000,
      ),
    );
  }

  @override
  String toString() => 'Context($modelId: $contextWindow toks, batch: ${batchSize})';
}
