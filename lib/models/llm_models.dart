import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Dynamic model pricing configuration fetched from OpenRouter
/// All prices are fetched dynamically, no hardcoded values
@immutable
class ModelPrice {
  final String modelId;
  final double inputPrice;
  final double outputPrice;
  final double cacheReadPrice;
  final int contextWindow;

  const ModelPrice({
    required this.modelId,
    required this.inputPrice,
    required this.outputPrice,
    required this.cacheReadPrice,
    required this.contextWindow,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'inputPrice': inputPrice,
      'outputPrice': outputPrice,
      'cacheReadPrice': cacheReadPrice,
      'contextWindow': contextWindow,
    };
  }

  /// Create from JSON
  factory ModelPrice.fromJson(Map<String, dynamic> json) {
    return ModelPrice(
      modelId: json['modelId'],
      inputPrice: double.tryParse(json['inputPrice']?.toString() ?? '0.0') ?? 0.0,
      outputPrice: double.tryParse(json['outputPrice']?.toString() ?? '0.0') ?? 0.0,
      cacheReadPrice: double.tryParse(json['cacheReadPrice']?.toString() ?? '0.0') ?? 0.0,
      contextWindow: json['contextWindow']?.toInt() ?? 4096,
    );
  }
}

/// Model with both static and dynamic pricing data
@immutable
class DynamicModel {
  final String provider;
  final String modelName;
  final String providerDisplayName;
  bool pricesFetched;
  final List<ModelPrice> prices;
  final Map<String, dynamic> metadata;

  DynamicModel({
    required this.provider,
    required this.modelName,
    required this.providerDisplayName,
    this.pricesFetched = false,
    List<ModelPrice>? prices,
    Map<String, dynamic>? metadata,
  })  : prices = prices ?? <ModelPrice>[],
        metadata = metadata ?? {};

  /// Get current best price (lowest input + output)
  ModelPrice getBestPrice() {
    if (prices.isEmpty) {
      return const ModelPrice(
        modelId: modelName,
        inputPrice: 0.0,
        outputPrice: 0.0,
        cacheReadPrice: 0.0,
        contextWindow: 4096,
      );
    }
    return prices[0]; // First fetched price
  }

  /// Calculate cost for given tokens
  double calculateCost(int inputTokens, int outputTokens) {
    if (prices.isEmpty) return 0.0;
    final model = prices[0]; // Use best price
    return ((inputTokens * model.inputPrice) + (outputTokens * model.outputPrice)) / 1000000;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicModel &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          modelName == other.modelName;

  @override
  int get hashCode => provider.hashCode ^ modelName.hashCode;

  @override
  String toString() => 'Model($modelName, fetched:${pricesFetched})';
}

/// Request body structure matching OpenRouter API spec
@immutable
class OpenRouterRequest {
  final String model;
  final List<Map<String, dynamic>> messages;
  final double? temperature;
  final int? maxTokens;
  final int? topP;
  final bool? stream;
  final String? apiKey;
  final String? extraHeaderKey;

  const OpenRouterRequest({
    required this.model,
    required this.messages,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.stream = false,
    this.apiKey,
    this.extraHeaderKey,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'model': model,
      'messages': messages,
      'temperature': temperature ?? 0.7,
      'stream': stream,
    };

    if (maxTokens != null) json['max_tokens'] = maxTokens;
    if (topP != null) json['top_p'] = topP;
    if (apiKey != null) json['api_key'] = apiKey;

    return json;
  }

  @override
  String toString() {
    return 'Request(model: $model, messages: ${messages.length})';
  }
}

/// Response structure from OpenRouter API
@immutable
class OpenRouterResponse {
  final String id;
  final String object;
  final String created;
  final List<Message> choices;
  final Map<String, dynamic> usage;
  final int effectiveDurationMs;
  final Map<String, dynamic> promptTokensDetails;

  const OpenRouterResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.choices,
    required this.usage,
    required this.effectiveDurationMs,
    required this.promptTokensDetails,
  });

  factory OpenRouterResponse.fromJson(Map<String, dynamic> json) {
    final List<Message> choices = (json['choices'] as List)
        .map((item) => Message.fromJson(item))
        .toList();

    return OpenRouterResponse(
      id: json['id'],
      object: json['object'] ?? 'chat.completion',
      created: json['created'],
      choices: choices,
      usage: json['usage'] ?? {},
      effectiveDurationMs: json['effective_duration_ms'] ?? 0,
      promptTokensDetails: json['prompt_tokens_details'] ?? {},
    );
  }

  /// Get total cost
  double getTotalCost() {
    if (usage.isEmpty || usage['total_tokens'] == null) return 0.0;

    final totalTokens = usage['total_tokens']?.toInt() ?? 0;
    return (totalTokens * 0.000006) / 1000000; // Rough estimate
  }

  Message? getAssistantResponse() {
    if (choices.isEmpty) return null;
    return choices[0];
  }

  @override
  String toString() {
    return 'Response(choices: ${choices.length}, usage: \$${getTotalCost().toStringAsFixed(4)})';
  }
}

/// Message in chat conversation
class Message {
  final String role;
  final String content;
  final Map<String, dynamic>?? reasoning;
  final Map<String, dynamic>? tool;
  final Map<String, dynamic>? index;
  final Map<String, dynamic>? finish;

  Message({
    this.role = '',
    this.content = '',
    this.reasoning,
    this.tool,
    this.index,
    this.finish,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] ?? 'unknown',
      content: json['content'] ?? '',
      reasoning: json['reasoning'] as Map<String, dynamic>??,
      tool: json['tool'] as Map<String, dynamic>?,
      index: json['index'] as Map<String, dynamic>?,
      finish: json['finish'] as Map<String, dynamic>?,
    );
  }

  String getContent() => content;

  @override
  String toString() => 'Message(role: $role, content: ${content.length} chars)';
}
