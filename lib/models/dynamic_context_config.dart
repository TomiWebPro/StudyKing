import 'package:flutter/foundation.dart';

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

  static const _contextMap = {
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

  factory DynamicContextConfig.fromModel(String modelId) {
    return DynamicContextConfig(
      modelId: modelId,
      contextWindow: _contextMap[modelId] ?? 8192,
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
      batchSize: json['batchSize']?.toInt() ?? 10,
      batchInterval: Duration(
        milliseconds: json['batchIntervalMs']?.toInt() ?? 2000,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicContextConfig &&
          runtimeType == other.runtimeType &&
          modelId == other.modelId &&
          contextWindow == other.contextWindow &&
          actualContextUsed == other.actualContextUsed &&
          autoFetched == other.autoFetched &&
          batchSize == other.batchSize &&
          batchInterval == other.batchInterval;

  @override
  int get hashCode => Object.hash(modelId, contextWindow, actualContextUsed, autoFetched, batchSize, batchInterval);

  @override
  String toString() => 'Context($modelId: $contextWindow toks, used: $actualContextUsed, batch: $batchSize, auto: $autoFetched)';
}
