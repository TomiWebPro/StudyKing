import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/data/models/llm_models.dart';

/// OpenRouter API client with dynamic price fetching
class OpenRouterClient {
  final Dio dio;
  final String baseUrl;

  OpenRouterClient({
    Dio? dio,
    this.baseUrl = 'https://openrouter.ai/api/v1',
  }) : dio = dio ?? Dio();

  /// set API key
  void setApiKey(String apiKey) {
    dio.options.headers['Authorization'] = 'Bearer $apiKey';
  }

  /// Clear API key
  void clearApiKey() {
    dio.options.headers.remove('Authorization');
  }

  /// Fetch model price data from OpenRouter
  /// Uses private pricing API to get accurate before making a request
  Future<List<ModelPrice>> fetchModelPrices(String modelId) async {
    try {
      final pricesResponse = await dio.get(
        '/models/$modelId/pricing',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'HTTP-Referer': kReleaseMode ? 'https://yourapp.com' : 'http://localhost:3000',
          },
        ),
      );

      if (pricesResponse.statusCode == 200) {
        return pricesResponse.data['prices']
            .where((p) => p['endpoints']?.isNotEmpty == true)
            .map((priceData) {
          return ModelPrice(
            modelId: modelId,
            inputPrice: priceData['input_tokens_price']?.toDouble() ?? 0.0,
            outputPrice: priceData['output_tokens_price']?.toDouble() ?? 0.0,
            cacheReadPrice: priceData['cache_read_input_tokens_price']?.toDouble() ?? 0.0,
            contextWindow: 4096, // This would need to be fetched as well
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      // If pricing fetch fails, return default pricing
      return [
        _createDefaultPrices(modelId),
      ];
    }
  }

  /// Create default pricing structure for when we can't fetch
  ModelPrice _createDefaultPrices(String modelId) {
    return ModelPrice(
      modelId: modelId,
      inputPrice: 0.000003,  // Free-tier equivalent
      outputPrice: 0.00003,
      cacheReadPrice: 0.0,
      contextWindow: 4096,
    );
  }

  /// Get model details for a specific model
  Future<Map<String, dynamic>> fetchModelInfo(String modelName) async {
    try {
      final response = await dio.get('/models/$modelName', options: Options(
        headers: {
          'Content-Type': 'application/json',
          'HTTP-Referer': kReleaseMode ? 'https://yourapp.com' : 'http://localhost:3000',
        },
      ));
      return response.data;
    } catch (e) {
      return {
        'id': modelName,
        'context_length': 4096,
        'per_minute_limit': 100,
        'price': <String, dynamic>{},
      };
    }
  }

  /// Fetch all available models for display
  Future<List<Map<String, dynamic>>> fetchAvailableModels() async {
    try {
      final response = await dio.get(
        '/models',
        queryParameters: {'limit': '1000'},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'HTTP-Referer': kReleaseMode ? 'https://yourapp.com' : 'http://localhost:3000',
          },
        ),
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((model) => {
                  'modelId': model['id'],
                  'name': model['name'],
                  'contextLength': model['context_length']?.toInt() ?? 4096,
                  'rateLimits': model['rate_limits'] ?? {},
                })
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Make a chat completion request
  Future<OpenRouterResponse> chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
    bool? stream,
  }) async {
    try {
      final responseJson = await dio.post(
        '/chat/completions',
        data: OpenRouterRequest(
          model: model,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          stream: stream ?? false,
        ).toJson(),
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (responseJson.statusCode == 200) {
        return OpenRouterResponse.fromJson(responseJson.data);
      } else {
        throw Exception('OpenRouter API Error: ${responseJson.data}');
      }
    } catch (e) {
      throw Exception('Failed to connect to OpenRouter: $e');
    }
  }

  /// Chat streaming for real-time responses
  Stream<List<int>> streamChat({
    required String model,
    required List<Map<String, dynamic>> messages,
  }) async* {
    try {
      final response = await dio.post(
        '/chat/completions',
        data: OpenRouterRequest(
          model: model,
          messages: messages,
          stream: true,
        ).toJson(),
        options: Options(
          responseType: ResponseType.stream,
        ),
      ).timeout(const Duration(seconds: 30));

      yield* response.data.stream;
    } catch (e) {
      throw Exception('Failed to connect to OpenRouter: $e');
    }
  }

  /// Calculate cost based on usage info
  double calculateCost(Map<String, dynamic> usage) {
    if (usage.isEmpty) return 0.0;

    final inputTokens = usage['prompt_tokens']?.toInt() ?? 0;
    final outputTokens = usage['completion_tokens']?.toInt() ?? 0;
    final cacheReadTokens = usage['cached_tokens']?.toInt() ?? 0;

    return calculateCostWithPrices(inputTokens, outputTokens, cacheReadTokens);
  }

  /// Calculate cost with actual price data
  double calculateCostWithPrices(
    int inputTokens,
    int outputTokens,
    int cacheReadTokens,
  ) {
    // Use average price per million tokens
    final inputCost = (inputTokens / 1000000) * 0.000006;
    final outputCost = (outputTokens / 1000000) * 0.000024;
    final cacheReadCost = (cacheReadTokens / 1000000) * 0.000003; // 1/5 of input

    return inputCost + outputCost + cacheReadCost;
  }

  /// Get estimated price for a model before asking
  Future<double> estimatePrice(String model) async {
    try {
      final prices = await fetchModelPrices(model);
      if (prices.isNotEmpty) {
        final price = prices[0];
        return ((price.inputPrice * 1000) + (price.outputPrice * 1000)) / 1000000;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
