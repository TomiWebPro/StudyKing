import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AI Model Service - Dynamically fetches models from OpenRouter API
class AiModelService {
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  
  final String _apiKey;
  
  AiModelService({required String apiKey}) : _apiKey = apiKey;

  /// Fetch available models from OpenRouter API
  Future<List<AiModel>> fetchAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_openRouterBaseUrl/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://studyking.app',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List;
        return models.map((model) => AiModel.fromOpenRouter(model)).toList();
      } else {
        debugPrint('Failed to fetch models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching models: $e');
      return [];
    }
  }

  /// Get model by ID from fetched list
  AiModel? getModelById(String id, List<AiModel> models) {
    return models.firstWhere(
      (model) => model.id == id,
      orElse: () => AiModel.fromId(id),
    );
  }
}

/// Represents an AI model - fetched dynamically from API
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

    if (id == null) {
      id = 'unknown';
    }

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
  String toString() => 'AiModel(id: $id, name: $name, provider: $provider)';

  /// Create model from ID
  factory AiModel.fromId(String id) {
    String name = id.split('/').last.replaceAll(':', '').replaceAll('-', ' ');
    String provider = 'Unknown';

    return AiModel(id: id, name: name, provider: provider);
  }
}
