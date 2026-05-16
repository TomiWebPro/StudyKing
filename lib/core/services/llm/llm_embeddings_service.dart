import 'dart:convert';
import 'package:http/http.dart' as http;
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
        final url = baseUrl.isNotEmpty ? baseUrl : 'https://openrouter.ai/api/v1';
        return '$url/embeddings';
      case LlmProvider.ollama:
        final url = baseUrl.isNotEmpty ? baseUrl : 'http://localhost:11434';
        return '$url/api/embeddings';
      case LlmProvider.openAI:
        final url = baseUrl.isNotEmpty ? baseUrl : 'https://api.openai.com/v1';
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

  Future<List<double>> embed({
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
        return embedding.map((e) => (e as num).toDouble()).toList();
      }
      throw Exception('Embedding API Error: ${response.statusCode}');
    } catch (e) {
      _logger.e('Embedding error', e);
      rethrow;
    }
  }
}
