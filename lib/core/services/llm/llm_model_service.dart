import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import 'llm_chat_service.dart';

class AiModel {
  final String id;
  final String name;
  final String provider;
  final String? contextLength;
  final String? pricing;

  const AiModel({
    required this.id,
    required this.name,
    required this.provider,
    this.contextLength,
    this.pricing,
  });

  factory AiModel.fromOpenRouter(dynamic data) {
    String? id = data['id'] as String?;
    String? name = data['name'] as String?;
    dynamic providers = data['providers'] as Map?;
    String? provider = providers?.values.isNotEmpty == true 
        ? providers?.values.first['id'] as String?
        : null;
    String? contextLength = data['context_length']?.toString();
    String? pricing = (data['pricing'] as Map?)?['prompt'] as String?;

    id ??= 'unknown';

    if (name == null) {
      final parts = id.split('/');
      name = parts.last.replaceAll(':', '').replaceAll('-', ' ');
    }

    if (provider == null || provider.isEmpty) {
      provider = 'Unknown';
    }

    return AiModel(
      id: id,
      name: name,
      provider: provider,
      contextLength: contextLength,
      pricing: pricing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          provider == other.provider;

  @override
  int get hashCode => Object.hash(id, name, provider);

  @override
  String toString() => 'AiModel(id: $id, name: $name, provider: $provider)';

  factory AiModel.fromId(String id) {
    String name = id.split('/').last.replaceAll(':', '').replaceAll('-', ' ');
    String provider = 'Unknown';

    return AiModel(id: id, name: name, provider: provider);
  }

  factory AiModel.fromOllama(dynamic data) {
    final name = data['name'] as String? ?? 'unknown';
    return AiModel(
      id: name,
      name: name.replaceAll(':', ' ').replaceAll('-', ' '),
      provider: 'Ollama',
    );
  }

  factory AiModel.fromOpenAI(dynamic data) {
    final id = data['id'] as String? ?? 'unknown';
    return AiModel(
      id: id,
      name: id.replaceAll('-', ' ').replaceAll('_', ' '),
      provider: 'OpenAI',
    );
  }
}

class ModelListingService {
  final String _apiKey;
  final String _baseUrl;
  final http.Client _httpClient;
  final LlmProvider? _provider;
  static final Logger _logger = const Logger('ModelListingService');

  ModelListingService({
    required String apiKey,
    String baseUrl = '',
    http.Client? httpClient,
    LlmProvider? provider,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client(),
        _provider = provider;

  Uri get _openRouterBaseUrl => ApiConfig.forEnvironment(BuildConfig.environment).openRouterBaseUrl;

  String get _effectiveBaseUrl {
    if (_baseUrl.isNotEmpty) return _baseUrl;
    switch (_provider ?? LlmProvider.openRouter) {
      case LlmProvider.ollama:
        return ApiConfig.ollamaDefaultUrl;
      case LlmProvider.openAI:
        return ApiConfig.openAIDefaultUrl;
      case LlmProvider.openRouter:
        return _openRouterBaseUrl.toString().replaceAll('/v1', '');
    }
  }

  Future<List<AiModel>> fetchAvailableModels({LlmProvider? provider}) async {
    final activeProvider = provider ?? _provider ?? LlmProvider.openRouter;
    try {
      switch (activeProvider) {
        case LlmProvider.ollama:
          return await _fetchOllamaModels();
        case LlmProvider.openAI:
          return await _fetchOpenAIModels();
        case LlmProvider.openRouter:
          return await _fetchOpenRouterModels();
      }
    } catch (e) {
      _logger.w('Error fetching models', e);
      return [];
    }
  }

  Future<List<AiModel>> _fetchOpenRouterModels() async {
    final response = await _httpClient.get(
      Uri.parse('$_openRouterBaseUrl/models'),
      headers: {
        'Authorization': '${ApiConfig.bearerAuth}$_apiKey',
        'HTTP-Referer': BuildConfig.appName,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = data['data'] as List;
      return models.map((model) => AiModel.fromOpenRouter(model)).toList();
    } else {
      _logger.w('Failed to fetch OpenRouter models: ${response.statusCode}');
      return [];
    }
  }

  Future<List<AiModel>> _fetchOllamaModels() async {
    final response = await _httpClient.get(
      Uri.parse('$_effectiveBaseUrl/api/tags'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = data['models'] as List;
      return models.map((model) => AiModel.fromOllama(model)).toList();
    } else {
      _logger.w('Failed to fetch Ollama models: ${response.statusCode}');
      return [];
    }
  }

  Future<List<AiModel>> _fetchOpenAIModels() async {
    final response = await _httpClient.get(
      Uri.parse('$_effectiveBaseUrl/models'),
      headers: {
        'Authorization': '${ApiConfig.bearerAuth}$_apiKey',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = data['data'] as List;
      return models.map((model) => AiModel.fromOpenAI(model)).toList();
    } else {
      _logger.w('Failed to fetch OpenAI models: ${response.statusCode}');
      return [];
    }
  }

  AiModel? getModelById(String id, List<AiModel> models) {
    return models.firstWhere(
      (model) => model.id == id,
      orElse: () => AiModel.fromId(id),
    );
  }
}
