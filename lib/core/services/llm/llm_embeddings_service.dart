import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/logger.dart';
import 'llm_chat_service.dart' show LlmProvider;

class EmbeddingService {
  final String apiKey;
  final String baseUrl;
  final LlmProvider provider;
  final http.Client _httpClient;
  static final Logger _logger = const Logger('EmbeddingService');

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
      case LlmProvider.custom:
        final url = baseUrl.isNotEmpty ? baseUrl : ApiConfig.openAIDefaultUrl;
        return '$url/embeddings';
    }
  }

  Map<String, String> get _headers {
    switch (provider) {
      case LlmProvider.openRouter:
        return {
          'Content-Type': 'application/json',
          'Authorization': '${ApiConfig.bearerAuth}$apiKey',
          'HTTP-Referer': 'StudyKing',
        };
      case LlmProvider.ollama:
        return {'Content-Type': 'application/json'};
      case LlmProvider.openAI:
        return {
          'Content-Type': 'application/json',
          'Authorization': '${ApiConfig.bearerAuth}$apiKey',
        };
      case LlmProvider.custom:
        return {
          'Content-Type': 'application/json',
          'Authorization': '${ApiConfig.bearerAuth}$apiKey',
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
          // Ollama's legacy /api/embeddings endpoint expects the text
          // under "prompt"; OpenAI-compatible APIs use "input".
          if (provider == LlmProvider.ollama)
            'prompt': text
          else
            'input': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = _extractEmbedding(data);
        if (embedding == null) {
          return Result.failure(
            'Embedding API Error: unrecognized response shape',
          );
        }
        return Result.success(embedding);
      }
      return Result.failure('Embedding API Error: ${response.statusCode}');
    } catch (e) {
      _logger.w('Embedding error', e);
      return Result.failure(e.toString());
    }
  }

  /// Parses the embedding vector from the provider-specific response
  /// shapes: OpenAI-compatible (`data[0].embedding`), Ollama legacy
  /// (`embedding`), and Ollama newer (`embeddings[0]`).
  List<double>? _extractEmbedding(dynamic body) {
    if (body is! Map) return null;

    final dataList = body['data'] as List?;
    if (dataList != null && dataList.isNotEmpty) {
      final first = dataList.first;
      if (first is Map) {
        final embedding = first['embedding'] as List?;
        if (embedding != null) return _toDoubleList(embedding);
      }
    }

    final direct = body['embedding'] as List?;
    if (direct != null) return _toDoubleList(direct);

    final batch = body['embeddings'] as List?;
    if (batch != null && batch.isNotEmpty) {
      final first = batch.first;
      if (first is List) return _toDoubleList(first);
    }

    return null;
  }

  List<double>? _toDoubleList(List values) {
    try {
      return values.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      _logger.w('Failed to convert embedding values', e);
      return null;
    }
  }
}
