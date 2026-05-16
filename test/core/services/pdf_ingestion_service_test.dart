import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/pdf_ingestion_service.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService() : super(config: LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'));

  String response = '';
  bool shouldThrow = false;

  @override
  Future<String> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    if (shouldThrow) throw Exception('LLM error');
    return response;
  }
}

void main() {
  group('PdfIngestionService', () {
    group('parsePdf', () {
      test('returns parsed topics from llm response', () async {
        final llm = _FakeLlmService();
        llm.response = '[{"title": "Algebra", "description": "Algebra topics"}]';
        final service = PdfIngestionService(llmService: llm);

        final result = await service.parsePdf(
          pdfContent: 'Sample PDF content',
          syllabus: 'Basic syllabus',
          modelId: 'gpt-3.5-turbo',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
        expect(result.data!.first['title'], 'Algebra');
      });

      test('returns failure on invalid response', () async {
        final llm = _FakeLlmService();
        llm.response = 'invalid json';
        final service = PdfIngestionService(llmService: llm);

        final result = await service.parsePdf(
          pdfContent: 'Content',
          syllabus: 'Syllabus',
          modelId: 'model',
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('classifyTopic', () {
      test('returns classified topic', () async {
        final llm = _FakeLlmService();
        llm.response = 'Math';
        final service = PdfIngestionService(llmService: llm);

        final result = await service.classifyTopic(
          content: 'Some math content',
          possibleTopics: ['Math', 'Physics'],
          modelId: 'model',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, 'Math');
      });
    });

    group('extractQuestions', () {
      test('returns extracted questions', () async {
        final llm = _FakeLlmService();
        llm.response = '[{"text": "Q1", "type": "singleChoice"}]';
        final service = PdfIngestionService(llmService: llm);

        final result = await service.extractQuestions('Content', 'model');

        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
      });

      test('returns failure on invalid response', () async {
        final llm = _FakeLlmService();
        llm.response = 'invalid';
        final service = PdfIngestionService(llmService: llm);

        final result = await service.extractQuestions('Content', 'model');

        expect(result.isFailure, isTrue);
      });
    });

    group('generateSummary', () {
      test('returns generated summary', () async {
        final llm = _FakeLlmService();
        llm.response = 'Concise summary text';
        final service = PdfIngestionService(llmService: llm);

        final result = await service.generateSummary('Content', 'Algebra', 'model');

        expect(result.isSuccess, isTrue);
        expect(result.data, 'Concise summary text');
      });
    });
  });
}
