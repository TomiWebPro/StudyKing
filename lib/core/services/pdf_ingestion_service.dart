import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_api_config.dart';
import '../constants/app_build_config.dart';
import '../utils/logger.dart';
import '../errors/result.dart';

class PdfIngestionException implements Exception {
  final String message;
  PdfIngestionException(this.message);
  @override
  String toString() => message;
}

class PdfIngestionService {
  final String apiKey;
  final Logger _logger = const Logger('PdfIngestionService');

  PdfIngestionService({required this.apiKey});

  Future<Result<List<Map<String, dynamic>>>> parsePdf({
    required String pdfContent,
    required String syllabus,
    required String modelId,
  }) async {
    if (apiKey.isEmpty) {
      return Result.failure('API key not configured. Please set up an AI provider in Settings.');
    }

    final prompt = '''
Parse this educational content and extract topics.
Content: $pdfContent
Syllabus: $syllabus

JSON response.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      final parsed = _parseContent(response);
      return Result.success(parsed);
    } catch (e) {
      _logger.e('PDF Parsing Error', e);
      return Result.failure('Failed to parse content: $e');
    }
  }

  Future<Result<String>> classifyTopic({
    required String content,
    required List<String> possibleTopics,
    required String modelId,
  }) async {
    if (apiKey.isEmpty) {
      return Result.failure('API key not configured.');
    }

    final prompt = '''
Classify content into one of: ${possibleTopics.join(', ')}
Content: $content

Return topic name.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return Result.success(response.trim());
    } catch (e) {
      return Result.failure('Classification failed: $e');
    }
  }

  Future<Result<List<Map<String, dynamic>>>> extractQuestions(String content, String modelId) async {
    if (apiKey.isEmpty) {
      return Result.failure('API key not configured.');
    }

    final prompt = '''
Extract questions from content: $content

JSON array.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      final decoded = jsonDecode(response);
      if (decoded is List) {
        return Result.success(decoded.cast<Map<String, dynamic>>());
      }
      return Result.success([]);
    } catch (e) {
      return Result.failure('Question extraction failed: $e');
    }
  }

  Future<Result<String>> generateSummary(String content, String topicName, String modelId) async {
    if (apiKey.isEmpty) {
      return Result.failure('API key not configured.');
    }

    final prompt = '''
Summarize the following content about "$topicName".
Content: $content

Provide a concise 3-5 sentence summary.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return Result.success(response.trim());
    } catch (e) {
      return Result.failure('Summary generation failed: $e');
    }
  }

  Future<String> _callLlm(String prompt, String model) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': BuildConfig.appName,
    };

    final baseUrl = ApiConfig.forEnvironment(BuildConfig.environment).openRouterBaseUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: headers,
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': 'Content analyzer'},
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw PdfIngestionException('API returned ${response.statusCode}: ${response.body}');
    }
  }

  List<Map<String, dynamic>> _parseContent(String response) {
    try {
      final data = jsonDecode(response);
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['topics'] is List) return List.castFrom(data['topics']);
      return [];
    } catch (e) {
      throw PdfIngestionException('Failed to parse LLM response: $e');
    }
  }
}
