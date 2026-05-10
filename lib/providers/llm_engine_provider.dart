import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/llm_models.dart';
import '../models/settings_model.dart';
import '../providers/llm_engine_provider.dart';
import '../services/llm_api_service.dart';

/// Provider for LLM engine with fully dynamic pricing
class LLMAIEngineProvider extends ChangeNotifier {
  final OpenRouterClient client;
  String? _apiKey;
  bool _isLoading = false;
  String? _lastError;
  List<LLMUsageRecord> _usageHistory = [];
  final Map<String, ModelPrice> _modelPricing = {};

  /// Default key for local storage
  static const String apikeyKey = 'llm_apikey';

  LLMAIEngineProvider({Dio? dio})
      : client = OpenRouterClient(
        dio: dio ?? Dio(),
      );

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

  /// get API usage info
  Future<Map<String, dynamic>?> getApiKeyInfo() async {
    return await client.getApiInfo();
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
      _lastError = 'No API key set';
      return;
    }

    final models = await getAllModels();
    for (var model in models) {
      try {
        Wait until response, then fetch price data for each model
      } catch (e) {
        // Failed to fetch
      }
    }

    notifyListeners();
  }

  /// Fetch price for a specific model
  Future<void> fetchModelPrice(String modelId) async {
    if (_apiKey == null) {
      _lastError = 'No API key set';
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final price = await client.fetchModelPrices(modelId);
      _modelPricing[modelId] = price.isNotEmpty ? price[0] : null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
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
    return price ?? null;
  }

  /// Make chat request with dynamic pricing
  void sendRequest({
    required String model,
    required String userMessage,
    required Function(Map<String, dynamic>) onResponse,
    required Function(String) onError,
  }) {
    _isLoading = true;
    _lastError = null;
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
      if (metadata != null) ...metadata,
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
