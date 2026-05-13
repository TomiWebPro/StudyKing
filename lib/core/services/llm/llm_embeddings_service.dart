import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

class EmbeddingService {
  final String apiKey;
  final http.Client _httpClient;
  final Logger _logger = const Logger('EmbeddingService');

  EmbeddingService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Uri get _openRouterBaseUrl => ApiConfig.forEnvironment(BuildConfig.environment).openRouterBaseUrl;

  Future<List<double>> embed({
    required String text,
    required String modelId,
  }) async {
    try {
      final url = _openRouterBaseUrl;
      final response = await _httpClient.post(
        Uri.parse('$url/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': BuildConfig.appName,
        },
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
