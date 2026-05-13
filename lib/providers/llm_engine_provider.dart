import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/data/models/llm_config.dart';
import '../core/data/models/llm_models.dart';
import '../services/llm_api_service.dart';

/// Provider for LLM engine with fully dynamic pricing
class LLMAIEngineProvider extends ChangeNotifier {
  final OpenRouterClient client;
  String? _apiKey;
  bool _isLoading = false;
  final List<LLMUsageRecord> _usageHistory = [];
  final Map<String, ModelPrice> _modelPricing = {};
  LLMModelConfig? _selectedModel;

  /// Default key for local storage
  static const String apikeyKey = 'llm_apikey';

  LLMAIEngineProvider({Dio? dio, OpenRouterClient? client})
      : client = client ?? OpenRouterClient(
          dio: dio ?? Dio(),
        );

  /// Selected model getter
  LLMModelConfig? get selectedModel => _selectedModel;

  void setSelectedModel(LLMModelConfig model) {
    _selectedModel = model;
    notifyListeners();
  }

  /// Whether the provider is loading
  bool get isLoading => _isLoading;

  /// Whether API key is configured
  bool get apiKeyConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Usage summary
  LLMUsageSummary get usageSummary {
    final totalInput = _usageHistory.fold<int>(0, (s, r) => s + r.inputTokens);
    final totalOutput = _usageHistory.fold<int>(0, (s, r) => s + r.outputTokens);
    final totalCost = _usageHistory.fold<double>(0.0, (s, r) => s + r.totalCost);
    return LLMUsageSummary(
      totalRequests: _usageHistory.length,
      totalTokens: totalInput + totalOutput,
      totalInputTokens: totalInput,
      totalOutputTokens: totalOutput,
      totalCost: totalCost,
    );
  }

  /// Key field
  String get apiKey => _apiKey ?? '';

  /// Set API key
  Future<String> setApiKey(String newKey) async {
    _apiKey = newKey;
    client.setApiKey(newKey);
    notifyListeners();
    return newKey;
  }

  /// Get current API key
  String? get currentKey => _apiKey;

  /// Clear API key
  void clearApiKey() {
    _apiKey = null;
    client.clearApiKey();
    notifyListeners();
  }

  /// Get ISO8601 formatted timestamp string
  String getTimestamp() {
    return DateTime.now().toIso8601String();
  }

  /// Configure endpoint with API key
  Future<void> configureEndpoint(String apiKey) => setApiKey(apiKey);

  /// Reset configuration
  Future<void> resetConfiguration() async {
    _apiKey = null;
    _selectedModel = null;
    client.clearApiKey();
    notifyListeners();
  }

  /// Make request (compatible wrapper for pages that expect Map callback)
  void makeRequest({
    required String model,
    required String userMessage,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) {
    sendRequest(
      model: model,
      userMessage: userMessage,
      onResponse: (response) {
        onSuccess(<String, dynamic>{
          'id': response.id,
          'success': response.choices.isNotEmpty,
          'provider': 'OpenRouter',
          'usage': response.usage,
          'totalCost': 0.0,
        });
      },
      onError: onError,
    );
  }

  /// Get all available models with dynamic pricing
  Future<List<OpenRouterModelModel>> getAllModels() async {
    final models = await client.fetchAvailableModels();
    final dynamicModels = <OpenRouterModelModel>[];

    for (var model in models) {
      dynamicModels.add(OpenRouterModelModel(
        modelId: model['modelId'],
        provider: 'openrouter',
        modelName: model['name'] ?? model['modelId'],
        contextLength: model['contextLength'] ?? 4096,
      ));
    }

    return dynamicModels;
  }

  /// Fetch prices for all models
  Future<void> fetchAllModelPrices() async {
    if (_apiKey == null) {
      return;
    }

    final models = await getAllModels();
    for (var model in models) {
      try {
        await fetchModelPrice(model.modelId);
      } catch (e) {
        // Failed to fetch
      }
    }

    notifyListeners();
  }

  /// Fetch price for a specific model
  Future<void> fetchModelPrice(String modelId) async {
    if (_apiKey == null) {
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final price = await client.fetchModelPrices(modelId);
      if (price.isNotEmpty) _modelPricing[modelId] = price[0];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get price for a model
  ModelPrice? getModelPrice(String modelId) {
    return _modelPricing[modelId];
  }

  /// Calculate cost for given model
  double calculateModelCost(String modelId) {
    final price = _modelPricing[modelId];
    return price != null ? price.inputPrice + price.outputPrice : 0.0;
  }

  /// Make chat request with dynamic pricing
  void sendRequest({
    required String model,
    required String userMessage,
    required Function(OpenRouterResponse) onResponse,
    required Function(String) onError,
  }) {
    _isLoading = true;
    notifyListeners();

    client.chat(
      model: model,
      messages: [_buildMessage(userMessage)],
    ).then((response) {
      _isLoading = false;
      onResponse(response);
    }).catchError((error) {
      _isLoading = false;
      onError(error.toString());
      notifyListeners();
    });
  }

  /// Build user message structure
  Map<String, dynamic> _buildMessage(String content) {
    return {
      'role': 'user',
      'content': content,
    };
  }

  /// Add usage record to history
  void addUsageRecord(LLMUsageRecord record) {
    _usageHistory.insert(0, record);
    notifyListeners();
  }

  /// Get usage history
  List<LLMUsageRecord> getUsageHistory() {
    return List.unmodifiable(_usageHistory);
  }

  /// Clear usage history
  void clearUsageHistory() {
    _usageHistory.clear();
    _modelPricing.clear();
    notifyListeners();
  }
}

/// Model configuration from OpenRouter
class OpenRouterModelModel {
  final String modelId;
  final String provider;
  final String modelName;
  final int contextLength;
  final Map<String, dynamic>? metadata;

  const OpenRouterModelModel({
    required this.modelId,
    required this.provider,
    required this.modelName,
    required this.contextLength,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'provider': provider,
      'modelName': modelName,
      'contextLength': contextLength,
      ...?metadata,
    };
  }

  factory OpenRouterModelModel.fromMap(Map<String, dynamic> map) {
    return OpenRouterModelModel(
      modelId: map['modelId'] ?? '',
      provider: map['provider'] ?? '',
      modelName: map['modelName'] ?? '',
      contextLength: map['contextLength'] ?? 4096,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'Model(\$: ${modelId.substring(0, (modelId.length > 20) ? 20 : modelId.length)})';
  }
}
