import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../models/llm_config.dart';

/// Service for interacting with LLM models via OpenRouter or custom endpoints
class LLMAPIService {
  final Dio dio;
  String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  String _apiKey = '';

  LLMAPIService({Dio? dio})
      : dio = dio ?? Dio() {
    dio.options.headers = {
      'Content-Type': 'application/json',
      'HTTP-Referer': kReleaseMode ? 'https://yourapp.com' : 'http://localhost:3000',
      'X-Title': 'StudyKing LLM',
    };
  }

  /// Configure OpenRouter endpoint
  void configureOpenRouter({required String apiKey}) {
    _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
    _apiKey = apiKey;
    dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }

  /// Configure custom endpoint
  void configureCustomEndpoint({
    required String baseUrl,
    required String apiKey,
  }) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }

  /// Clear API key (useful for testing offline)
  void clearApiKey() {
    _apiKey = '';
    dio.options.headers.remove('Authorization');
  }

  /// Make a chat completion request
  Future<Map<String, dynamic>> chat({
    required String model,
    required String? systemPrompt,
    required String userMessage,
    int? maxTokens,
    int? temperature,
  }) async {
    try {
      final response = await dio.post(
        _baseUrl,
        data: _buildRequest(
          model: model,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          maxTokens: maxTokens,
          temperature: temperature,
        ),
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': response.data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to connect: $e',
      };
      }
    }

    /// Get API usage
  Future<Map<String, dynamic>> getUsage() async {
    try {
      final response = await dio.get(
        '$_baseUrl/keys/meta_id',
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'error': 'Failed to fetch usage',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to fetch usage: $e',
      };
    }
  }

    /// Detect language of a text
  Future<String> detectLanguage(String text) async {
    try {
      final response = await dio.post(
        'https://api.openrouter.ai/v1/detect-language',
        data: {
          'text': text,
        },
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        return response.data['language'] ?? 'en';
      }

      return 'en';
    } catch (e) {
      return 'en';
    }
  }

    /// Streaming request support
  Stream<ChatCompletionChunk> streamChat({
    required String model,
    required String userMessage,
  }) {
    return dio
        .post(
          _baseUrl,
          data: _buildStreamingRequest(
            model: model,
            userMessage: userMessage,
          ),
          options: Options(
            responseType: ResponseType.stream,
          ),
        )
        .timeout(const Duration(seconds: 30))
        .then((response) {
      return response
          .data
          .transform(LineSplitter())
          .whereType<String>()
          .map((line) => '${line.trim()}');
    });
  }

    /// Build a chat completion request
  Map<String, dynamic> _buildRequest({
    required String model,
    String? systemPrompt,
    required String userMessage,
    int? maxTokens,
    int? temperature,
  }) {
    final messages = <Map<String, dynamic>>[];

    /// Add system message if provided
    if (systemPrompts.isNotEmpty && systemPrompt != null)) {
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }

    /// Add user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    return {
      'model': model,
      'messages': messages,
      'temperature': temperature ?? 0.7,
      'stream': false,
      if (maxTokens != null) 'max_tokens': maxTokens,
      'api_key': _apiKey,
      'extra_settings': {}, // For future extensions
    };
  }

  /// Build a streaming request
  Map<String, dynamic> _buildStreamingRequest({
    required String model,
    required String userMessage,
  }) {
    return {
      'model': model,
      'messages': [
        {'role': 'user', 'content': userMessage},
      ],
      'stream': true,
      'api_key': _apiKey,
    };
  }

    /// Calculate usage statistics from a response
  double calculateUsageCost(Map<String, dynamic> response) {
    if (!response.containsKey('usage') || response['usage'] == null) {
      return 0.0;
    }

    final usage = response['usage'] as Map<String, dynamic>;
    final inputTokens = usage['prompt_tokens'] ?? 0;
    final outputTokens = usage['completion_tokens'] ?? 0;

    /// Assuming OpenRouter pricing (input: $0.000003/tk, output: $0.000015/tk)
    final inputCost = (inputTokens / 1000000) * 0.003;
    final outputCost = (outputTokens / 1000000) * 0.015;

    return inputCost + outputCost;
  }
}

/// Chat completion chunk for streaming
class ChatCompletionChunk {
  final String delta;
  final int usage;

  ChatCompletionChunk(this.delta, this.usage);
}

/// Line splitter utility
class LineSplitter extends Converter<List<int>, String> {
  @override
  String convert(List<int> input) => String.fromCharCodes(input);
}
