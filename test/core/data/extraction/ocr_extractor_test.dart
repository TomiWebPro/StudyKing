import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

class _FakeLlmService extends LlmService {
  final Future<Result<String>> Function()? _onChat;

  _FakeLlmService({Future<Result<String>> Function()? onChat})
      : _onChat = onChat,
        super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    if (_onChat != null) return _onChat();
    return Result.success('extracted text');
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'stream response';
  }
}

void main() {
  group('OcrExtractionResult', () {
    test('isError returns true when errorMessage is set', () {
      const result = OcrExtractionResult(
        text: '',
        extractionMethod: 'test',
        errorMessage: 'error',
      );
      expect(result.isError, isTrue);
    });

    test('isError returns false when errorMessage is null', () {
      const result = OcrExtractionResult(
        text: 'hello',
        extractionMethod: 'test',
      );
      expect(result.isError, isFalse);
    });

    test('stores confidence value', () {
      const result = OcrExtractionResult(
        text: 'hello',
        confidence: 0.95,
        extractionMethod: 'test',
      );
      expect(result.confidence, 0.95);
    });

    test('confidence is null when not provided', () {
      const result = OcrExtractionResult(
        text: 'hello',
        extractionMethod: 'test',
      );
      expect(result.confidence, isNull);
    });
  });

  group('OcrExtractor', () {
    group('constructor', () {
      test('accepts empty modelId without throwing', () {
        expect(
          () => OcrExtractor(modelId: '', localeName: 'en'),
          returnsNormally,
        );
      });

      test('accepts valid modelId', () {
        expect(
          () => OcrExtractor(modelId: 'test-model', localeName: 'en'),
          returnsNormally,
        );
      });
    });

    group('extractText without LLM', () {
      late OcrExtractor extractor;

      setUp(() {
        extractor = OcrExtractor(modelId: 'test-model', localeName: 'en');
      });

      test('returns empty result for file:// path without LLM', () async {
        final result = await extractor.extractText(
          rawContent: 'file:///path/to/image.png',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'image_file_not_found');
      });

      test('returns empty result for http URL without LLM', () async {
        final result = await extractor.extractText(
          rawContent: 'https://example.com/photo.jpg',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'image_url_no_llm');
      });

      test('returns empty for base64 content without LLM', () async {
        final result = await extractor.extractText(
          rawContent: 'SGVsbG8gV29ybGQ=' * 10,
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'image_base64_no_llm');
      });

      test('returns empty for short content that appears as raw', () async {
        final result = await extractor.extractText(
          rawContent: 'short text',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_no_llm_available');
      });

      test('returns empty for base64 shorter than 100 chars', () async {
        final result = await extractor.extractText(
          rawContent: 'abc123',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_no_llm_available');
      });
    });

    group('extractText with file:// edge cases', () {
      test('returns image_file_read_error for restricted file', () async {
        final dir = Directory.systemTemp.createTempSync('ocr_perm_test_');
        try {
          final file = File('${dir.path}/restricted.png');
          await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);
          await Process.run('chmod', ['000', file.path]);

          final extractor = OcrExtractor(modelId: 'test-model', localeName: 'en');
          final result = await extractor.extractText(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );
          expect(result.text, '');
          expect(result.extractionMethod, 'image_file_read_error');
        } finally {
          await Process.run('chmod', ['-R', '777', dir.path]);
          dir.deleteSync(recursive: true);
        }
      });

      test('returns image_file_no_llm for existing file without LLM', () async {
        final dir = Directory.systemTemp.createTempSync('ocr_test_');
        try {
          final file = File('${dir.path}/test_image.png');
          await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

          final extractor = OcrExtractor(modelId: 'test-model', localeName: 'en');
          final result = await extractor.extractText(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );
          expect(result.text, '');
          expect(result.extractionMethod, 'image_file_no_llm');
        } finally {
          dir.deleteSync(recursive: true);
        }
      });

      test('returns image_file_no_llm for existing file with empty modelId', () async {
        final dir = Directory.systemTemp.createTempSync('ocr_test_');
        try {
          final file = File('${dir.path}/test_image.png');
          await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

          final extractor = OcrExtractor(modelId: '', llmService: _FakeLlmService(), localeName: 'en');
          final result = await extractor.extractText(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );
          expect(result.text, '');
          expect(result.extractionMethod, 'model_id_empty');
        } finally {
          dir.deleteSync(recursive: true);
        }
      });
    });

    group('extractText with LLM service', () {
      test('returns extracted text on successful LLM response', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('Hello World'),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'not a url or base64',
          sourceUrl: null,
        );

        expect(result.text, 'Hello World');
        expect(result.confidence, 0.7);
        expect(result.extractionMethod, 'ocr_llm');
      });

      test('returns empty result when LLM returns empty text', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('   '),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'not a url or base64',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_empty_result');
      });

      test('returns error when LLM chat fails', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.failure('API error'),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'not a url or base64',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_llm_failed');
      });

      test('returns error when LLM throws exception', () async {
        final llm = _FakeLlmService(
          onChat: () async => throw Exception('Network error'),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'not a url or base64',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_llm_failed');
        expect(result.errorMessage, contains('Network error'));
      });

      test('returns model_id_empty when modelId is empty with LLM', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('text'),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: '',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'not a url or base64',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'model_id_empty');
      });
    });

    group('extractText with http URL and LLM', () {
      test('extracts via LLM from http URL', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('URL text'),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'https://example.com/image.jpg',
          sourceUrl: null,
        );

        expect(result.text, 'URL text');
        expect(result.extractionMethod, 'ocr_llm');
      });
    });

    group('extractText with base64 and LLM', () {
      test('extracts via LLM from base64 content', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('base64 text'),
        );
        final extractor = OcrExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.extractText(
          rawContent: 'SGVsbG8gV29ybGQ=' * 10,
          sourceUrl: null,
        );

        expect(result.text, 'base64 text');
        expect(result.extractionMethod, 'ocr_llm');
      });
    });

    group('extractText with file:// existing file and LLM', () {
      test('extracts via LLM from existing file', () async {
        final dir = Directory.systemTemp.createTempSync('ocr_llm_test_');
        try {
          final file = File('${dir.path}/test_image.png');
          await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

          final llm = _FakeLlmService(
            onChat: () async => Result.success('file text'),
          );
          final extractor = OcrExtractor(
            llmService: llm,
            modelId: 'test-model',
            localeName: 'en',
          );

          final result = await extractor.extractText(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );

          expect(result.text, 'file text');
          expect(result.extractionMethod, 'ocr_llm');
        } finally {
          dir.deleteSync(recursive: true);
        }
      });
    });
  });
}
