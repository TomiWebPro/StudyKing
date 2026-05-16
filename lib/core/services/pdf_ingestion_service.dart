import 'dart:convert';
import '../errors/result.dart';
import '../utils/logger.dart';
import 'llm/llm_chat_service.dart';

@Deprecated('Use ContentPipeline instead. PdfIngestionService duplicates logic '
    'that ContentPipeline already handles (classification, summarization, '
    'question generation/extraction).')
class PdfIngestionException implements Exception {
  final String message;
  PdfIngestionException(this.message);
  @override
  String toString() => message;
}

@Deprecated('Use ContentPipeline instead. PdfIngestionService duplicates logic '
    'that ContentPipeline already handles. The _generateQuestions method in '
    'ContentPipeline now handles both extracting existing questions and '
    'generating new ones.')
class PdfIngestionService {
  final LlmService _llmService;
  final Logger _logger = const Logger('PdfIngestionService');

  PdfIngestionService({required LlmService llmService})
      : _llmService = llmService;

  Future<Result<List<Map<String, dynamic>>>> parsePdf({
    required String pdfContent,
    required String syllabus,
    required String modelId,
  }) async {
    final prompt = '''
Parse this educational content and extract topics.
Content: $pdfContent
Syllabus: $syllabus

Return a JSON array of topics with "title" and "description" fields.
''';

    try {
      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: 'You are a content analyzer. Return valid JSON.',
        feature: 'pdf_parsing',
      );
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
    final prompt = '''
Classify content into one of: ${possibleTopics.join(', ')}
Content: $content

Return topic name.
''';

    try {
      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: 'Content classifier.',
        feature: 'content_classification',
      );
      return Result.success(response.trim());
    } catch (e) {
      return Result.failure('Classification failed: $e');
    }
  }

  Future<Result<List<Map<String, dynamic>>>> extractQuestions(
    String content,
    String modelId,
  ) async {
    final prompt = '''
Extract questions from content: $content

Return a JSON array of question objects with "text" and "type" fields.
''';

    try {
      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: 'You extract questions. Return valid JSON.',
        feature: 'question_extraction',
      );
      final decoded = jsonDecode(response);
      if (decoded is List) {
        return Result.success(decoded.cast<Map<String, dynamic>>());
      }
      return Result.success([]);
    } catch (e) {
      return Result.failure('Question extraction failed: $e');
    }
  }

  Future<Result<String>> generateSummary(
    String content,
    String topicName,
    String modelId,
  ) async {
    final prompt = '''
Summarize the following content about "$topicName".
Content: $content

Provide a concise 3-5 sentence summary.
''';

    try {
      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: 'You summarize educational content.',
        feature: 'content_summarization',
      );
      return Result.success(response.trim());
    } catch (e) {
      return Result.failure('Summary generation failed: $e');
    }
  }

  List<Map<String, dynamic>> _parseContent(String response) {
    try {
      final data = jsonDecode(response);
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['topics'] is List) {
        return List<Map<String, dynamic>>.from(data['topics']);
      }
      return [];
    } catch (e) {
      throw PdfIngestionException('Failed to parse LLM response: $e');
    }
  }
}
