import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/logger.dart';
import 'llm_chat_service.dart' show LlmProvider;

class EmbeddingService {
  final String apiKey;
  final String baseUrl;
  final LlmProvider provider;
  final http.Client _httpClient;
  final Logger _logger = const Logger('EmbeddingService');

  EmbeddingService({
    required this.apiKey,
    this.baseUrl = '',
    this.provider = LlmProvider.openRouter,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  String get _embeddingsUrl {
    switch (provider) {
      case LlmProvider.openRouter:
        final url = baseUrl.isNotEmpty ? baseUrl : ApiConfig.openRouterBaseUrlString;
        return '$url/embeddings';
      case LlmProvider.ollama:
        final url = baseUrl.isNotEmpty ? baseUrl : ApiConfig.ollamaDefaultUrl;
        return '$url/api/embeddings';
      case LlmProvider.openAI:
        final url = baseUrl.isNotEmpty ? baseUrl : ApiConfig.openAIDefaultUrl;
        return '$url/embeddings';
    }
  }

  Map<String, String> get _headers {
    switch (provider) {
      case LlmProvider.openRouter:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'StudyKing',
        };
      case LlmProvider.ollama:
        return {'Content-Type': 'application/json'};
      case LlmProvider.openAI:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
    }
  }

  Future<Result<List<double>>> embed({
    required String text,
    required String modelId,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_embeddingsUrl),
        headers: _headers,
        body: jsonEncode({
          'model': modelId,
          'input': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['data'][0]['embedding'] as List;
        return Result.success(embedding.map((e) => (e as num).toDouble()).toList());
      }
      return Result.failure('Embedding API Error: ${response.statusCode}');
    } catch (e) {
      _logger.e('Embedding error', e);
      return Result.failure(e.toString());
    }
  }
}
