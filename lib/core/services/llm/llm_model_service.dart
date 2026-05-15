import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

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
}

class ModelListingService {
  final String _apiKey;
  final http.Client _httpClient;
  final Logger _logger = const Logger('ModelListingService');

  ModelListingService({
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client();

  Uri get _openRouterBaseUrl => ApiConfig.forEnvironment(BuildConfig.environment).openRouterBaseUrl;

  Future<List<AiModel>> fetchAvailableModels() async {
    try {
      final url = _openRouterBaseUrl;
      final response = await _httpClient.get(
        Uri.parse('$url/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': BuildConfig.appName,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List;
        return models.map((model) => AiModel.fromOpenRouter(model)).toList();
      } else {
        _logger.w('Failed to fetch models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching models', e);
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
