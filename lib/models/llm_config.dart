import 'package:flutter/foundation.dart';

enum ServiceProvider { openrouter }

/// LLM model configuration with pricing information
@immutable
class LLMModelConfig {
  final String provider;
  final String modelName;
  final String providerDisplayName;
  final double inputPricePerMillionTokens;
  final double outputPricePerMillionTokens;
  final int contextWindow;

  const LLMModelConfig({
    required this.provider,
    required this.modelName,
    required this.providerDisplayName,
    required this.inputPricePerMillionTokens,
    required this.outputPricePerMillionTokens,
    required this.contextWindow,
  });

  /// Calculate approximate cost for a given input and output token count
  double calculateCost(
    int inputTokens,
    int outputTokens,
  ) {
    final inputCost = (inputTokens / 1000000) * inputPricePerMillionTokens;
    final outputCost = (outputTokens / 1000000) * outputPricePerMillionTokens;
    return inputCost + outputCost;
  }

  /// Format pricing for display
  String formatPricing() {
    return '$inputPricePerMillionTokens/\$M input, $outputPricePerMillionTokens/\$M output';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LLMModelConfig &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          modelName == other.modelName;

  @override
  int get hashCode => Object.hash(provider, modelName);

  @override
  String toString() => 'LLMConfig($provider, $modelName, ${(inputPricePerMillionTokens + outputPricePerMillionTokens) / 2}/M)';
}

/// API endpoint configuration
@immutable
class APIEndpointConfig {
  final String provider;
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final int contextWindow;

  APIEndpointConfig({
    required this.provider,
    required this.baseUrl,
    required String apiKey,
    this.modelName = '',
    this.contextWindow = 4096,
  }) : apiKey = apiKey.isEmpty ? '' : apiKey;

  LLMModelConfig toModelConfig() {
    switch (provider.toLowerCase()) {
      case 'openrouter':
        return LLMModelConfig(
          provider: 'openrouter',
          modelName: modelName,
          providerDisplayName: 'OpenRouter',
          inputPricePerMillionTokens: 0.5, // default fallback
          outputPricePerMillionTokens: 10.0,
          contextWindow: contextWindow,
        );
      default:
        return LLMModelConfig(
          provider: 'custom',
          modelName: modelName,
          providerDisplayName: provider,
          inputPricePerMillionTokens: 0.0,
          outputPricePerMillionTokens: 0.0,
          contextWindow: contextWindow,
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is APIEndpointConfig &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          baseUrl == other.baseUrl;

  @override
  int get hashCode => Object.hash(provider, baseUrl);
}

/// Usage tracking record
@immutable
class LLMUsageRecord {
  final DateTime timestamp;
  final String provider;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final double totalCost;

  const LLMUsageRecord({
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCost,
  });

  /// Calculate total tokens used
  int get totalTokens => inputTokens + outputTokens;

  /// Create JSON representation for storage
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'provider': provider,
      'model': model,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalCost': totalCost,
    };
  }

  static LLMUsageRecord fromJson(Map<String, dynamic> json) {
    return LLMUsageRecord(
      timestamp: DateTime.parse(json['timestamp']),
      provider: json['provider'],
      model: json['model'],
      inputTokens: json['inputTokens'],
      outputTokens: json['outputTokens'],
      totalCost: json['totalCost'],
    );
  }
}

/// Summary of usage statistics
@immutable
class LLMUsageSummary {
  final int totalRequests;
  final int totalTokens;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCost;

  const LLMUsageSummary({
    required this.totalRequests,
    required this.totalTokens,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCost,
  });

  /// Cost per token
  double get costPerToken =>
      totalTokens > 0 ? (totalCost / totalTokens) : 0.0;

  /// Monthly projection at current rate
  double get monthlyProjection =>
      totalRequests > 0 ? (totalCost / totalRequests * 30) : 0.0;

  @override
  String toString() {
    return 'Usage: $totalRequests reqs, $totalTokens tokens, '
        '\$${totalCost.toStringAsFixed(4)} total';
  }
}

/// Available models for different providers
@immutable
class AvailableModels {
  const AvailableModels._();
  /// OpenRouter models with pricing
  static const List<LLMModelConfig> openrouterModels = [
    // Anthropic
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'anthropic/claude-3.5-sonnet',
      providerDisplayName: 'Anthropic Claude 3.5 Sonnet',
      inputPricePerMillionTokens: 3.0,
      outputPricePerMillionTokens: 15.0,
      contextWindow: 200000,
    ),
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'anthropic/claude-3-haiku',
      providerDisplayName: 'Anthropic Claude 3 Haiku',
      inputPricePerMillionTokens: 0.25,
      outputPricePerMillionTokens: 1.25,
      contextWindow: 200000,
    ),

    // Google
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'google/gemini-1.5-pro',
      providerDisplayName: 'Google Gemini 1.5 Pro',
      inputPricePerMillionTokens: 2.5,
      outputPricePerMillionTokens: 10.0,
      contextWindow: 2097152,
    ),
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'google/gemini-1.5-flash',
      providerDisplayName: 'Google Gemini 1.5 Flash',
      inputPricePerMillionTokens: 0.15,
      outputPricePerMillionTokens: 0.6,
      contextWindow: 1000000,
    ),

    // Meta
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'meta/llama-3.1-405b-instruct',
      providerDisplayName: 'Meta Llama 3.1 405B',
      inputPricePerMillionTokens: 0.85,
      outputPricePerMillionTokens: 3.82,
      contextWindow: 131072,
    ),
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'meta/llama-3.1-8b-instruct',
      providerDisplayName: 'Meta Llama 3.1 8B',
      inputPricePerMillionTokens: 0.15,
      outputPricePerMillionTokens: 0.75,
      contextWindow: 8192,
    ),

    // Mistral
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'mistral/mistral-large',
      providerDisplayName: 'Mistral Large',
      inputPricePerMillionTokens: 2.0,
      outputPricePerMillionTokens: 6.0,
      contextWindow: 32000,
    ),
    LLMModelConfig(
      provider: 'openrouter',
      modelName: 'mistral/mistral-7b-instruct',
      providerDisplayName: 'Mistral 7B Instruct',
      inputPricePerMillionTokens: 0.15,
      outputPricePerMillionTokens: 0.75,
      contextWindow: 32000,
    ),

    // Other
    LLMModelConfig(
      provider: 'openrouter',
      modelName: '椰子/椰子-1.0',
      providerDisplayName: 'Nemo 1.0',
      inputPricePerMillionTokens: 0.25,
      outputPricePerMillionTokens: 1.0, // estimated
      contextWindow: 4096,
    ),
  ];

  /// Default model for OpenRouter
  static const String defaultOpenRouterModel = 'anthropic/claude-3.5-sonnet';

  /// Get models by provider
  static List<LLMModelConfig> getModelsByProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'openrouter':
        return openrouterModels;
      default:
        return [];
    }
  }
}
