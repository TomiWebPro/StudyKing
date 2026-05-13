import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/pdf_ingestion_service.dart';

void main() {
  group('PdfIngestionService', () {
    group('parsePdf', () {
      test('returns failure when api key is empty', () async {
        final service = PdfIngestionService(apiKey: '');

        final result = await service.parsePdf(
          pdfContent: 'Sample PDF content',
          syllabus: 'Basic syllabus',
          modelId: 'gpt-3.5-turbo',
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('classifyTopic', () {
      test('returns failure when api key is empty', () async {
        final service = PdfIngestionService(apiKey: '');

        final result = await service.classifyTopic(
          content: 'Some content',
          possibleTopics: ['Algebra', 'Calculus', 'Geometry'],
          modelId: 'gpt-3.5-turbo',
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('extractQuestions', () {
      test('returns failure when api key is empty', () async {
        final service = PdfIngestionService(apiKey: '');

        final result = await service.extractQuestions('Content here', 'gpt-3.5-turbo');

        expect(result.isFailure, isTrue);
      });
    });

    group('generateSummary', () {
      test('returns failure when api key is empty', () async {
        final service = PdfIngestionService(apiKey: '');

        final result = await service.generateSummary('Content', 'Algebra', 'gpt-3.5-turbo');

        expect(result.isFailure, isTrue);
      });
    });
  });
}
