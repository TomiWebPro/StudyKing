import 'package:flutter/foundation.dart';
import '../../models/llm_config.dart';
import '../services/llm_api_service.dart';

/// Provider for managing LLM engine configuration and state
class LLMEngineProvider with ChangeNotifier {
  final LLMAPIService apiService;
  LLMModelConfig? _selectedModel;
  String _selectedModelName = '';
  bool _isLoading = false;
  String? _lastError;
  List<LLMUsageRecord> _usageHistory = [];
  bool _apiKeyConfigured = false;

  LLMEngineProvider(this.apiService);

  /// Get selected model configuration
  LLMModelConfig? get selectedModel => _selectedModel;

  /// Get selected model name
  String get modelName => _selectedModelName;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Last error message
  String? get lastError => _lastError;

  /// Whether API key is configured
  bool get apiKeyConfigured => _apiKeyConfigured;

  /// Usage history
  List<LLMUsageRecord> get usageHistory => List.unmodifiable(_usageHistory);

  /// Summary of usage statistics
  LLMUsageSummary get usageSummary {
    int totalRequests = _usageHistory.length;
    int totalTokens = 0;
    int totalInputTokens = 0;
    int totalOutputTokens = 0;
    double totalCost = 0.0;

    for (var record in _usageHistory) {
      totalTokens += record.totalTokens;
      totalInputTokens += record.inputTokens;
      totalOutputTokens += record.outputTokens;
      totalCost += record.totalCost;
    }

    return LLMUsageSummary(
      totalRequests: totalRequests,
      totalTokens: totalTokens,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      totalCost: totalCost,
    );
  }

  /// Set selected model
  void setSelectedModel(LLMModelConfig? model) {
    _selectedModel = model;
    _selectedModelName = model?.modelName ?? '';
    _apiKeyConfigured = true;
    notifyListeners();
  }

  /// Configure API endpoint
  void configureEndpoint(APIEndpointConfig config) {
    _apiKeyConfigured = true;
    _selectedModelName = config.modelName;
    if (config.provider == 'openrouter') {
      apiService.configureOpenRouter(apiKey: config.apiKey);
    } else {
      apiService.configureCustomEndpoint(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
      );
    }
    notifyListeners();
  }

  /// Make a chat completion request
  Future<Map<String, dynamic>> makeRequest({
    required String model,
    required String userMessage,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await apiService.chat(
        model: model,
        userMessage: userMessage,
      );

      if (response['success'] == true) {
        final usageRecord = LLMUsageRecord(
          timestamp: DateTime.now(),
          provider: 'OpenRouter',
          model: model,
          inputTokens: 0, // Need to parse from response
          outputTokens: 0,
          totalCost: apiService.calculateUsageCost(response['data']),
        );
        _usageHistory.add(usageRecord);

        onSuccess(response);
        _isLoading = false;
        notifyListeners();
      } else {
        _lastError = response['error'];
        onError('Request failed: ${response['error']}');
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _lastError = e.toString();
      onError('Error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get all available OpenRouter models
  List<LLMModelConfig> getAvailableModels() {
    return AvailableModels.openrouterModels;
  }

  /// Clear usage history
  void clearUsageHistory() {
    _usageHistory.clear();
    notifyListeners();
  }

  /// Reset API configuration
  void resetConfiguration() {
    _apiKeyConfigured = false;
    _selectedModel = null;
    _selectedModelName = '';
    apiService.clearApiKey();
    notifyListeners();
  }
}

/// Simple text input widget for chat
class LLMTextInputField extends StatelessWidget {
  final String controllerText;
  final TextEditingController? controller;
  final void Function(String) onTextChanged;

  const LLMTextInputField({
    Key? key,
    this.controllerText = '',
    this.controller,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Type your message...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      text: controllerText,
      onSubmitted: onTextChanged,
    );
  }
}

/// Model selector wheel widget
class LLMModelSelectorWheel extends StatelessWidget {
  final LLMModelConfig? selectedModel;
  final void Function(LLMModelConfig?) onModelSelected;

  const LLMModelSelectorWheel({
    Key? key,
    this.selectedModel,
    required this.onModelSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final models = AvailableModels.openrouterModels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Model', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(
          height: 200,
          child: BuildForAdvice(
            builder: (BuildContext context, Widget? child) {
              return models.map((model) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(model.providerDisplayName[0]),
                  ),
                  title: Text(model.providerDisplayName),
                  subtitle: Text(
                    model.formatPricing(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  selected: selectedModel == model,
                  onTap: () => onModelSelected(model),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }
}
