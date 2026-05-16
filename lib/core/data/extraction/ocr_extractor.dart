import 'dart:convert';
import 'dart:io';

import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';

class OcrExtractionResult {
  final String text;
  final double? confidence;
  final String extractionMethod;

  const OcrExtractionResult({
    required this.text,
    this.confidence,
    required this.extractionMethod,
  });
}

class OcrExtractor {
  final LlmService? _llmService;
  final Logger _logger = const Logger('OcrExtractor');

  OcrExtractor({LlmService? llmService}) : _llmService = llmService;

  Future<OcrExtractionResult> extractText({
    required String rawContent,
    required String? sourceUrl,
  }) async {
    if (rawContent.startsWith('file://')) {
      return _extractFromFile(rawContent.substring(7));
    }

    if (rawContent.startsWith('http://') || rawContent.startsWith('https://')) {
      return _extractFromUrl(rawContent);
    }

    final isBase64 = rawContent.length > 100 &&
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(rawContent.substring(0, 100));
    if (isBase64) {
      return _extractFromBase64(rawContent);
    }

    if (_llmService != null) {
      return _extractWithLlm(rawContent);
    }

    return const OcrExtractionResult(
      text: '',
      extractionMethod: 'ocr_no_llm_available',
    );
  }

  Future<OcrExtractionResult> _extractFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const OcrExtractionResult(
          text: '',
          extractionMethod: 'image_file_not_found',
        );
      }
      final bytes = await file.readAsBytes();
      return _processImageBytes(bytes, 'image_file');
    } catch (e) {
      _logger.e('Failed to read image file', e);
      return const OcrExtractionResult(
        text: '',
        extractionMethod: 'image_file_read_error',
      );
    }
  }

  Future<OcrExtractionResult> _extractFromUrl(String url) async {
    if (_llmService != null) {
      return _extractWithLlm(url);
    }
    return const OcrExtractionResult(
      text: '',
      extractionMethod: 'image_url_no_llm',
    );
  }

  Future<OcrExtractionResult> _extractFromBase64(String base64Str) async {
    if (_llmService != null) {
      return _extractWithLlm(base64Str);
    }
    return const OcrExtractionResult(
      text: '',
      extractionMethod: 'image_base64_no_llm',
    );
  }

  Future<OcrExtractionResult> _processImageBytes(
    List<int> bytes,
    String method,
  ) async {
    final base64Str = base64Encode(bytes);
    if (_llmService != null) {
      return _extractWithLlm(base64Str);
    }
    return OcrExtractionResult(
      text: '',
      extractionMethod: '${method}_no_llm',
    );
  }

  Future<OcrExtractionResult> _extractWithLlm(String content) async {
    if (_llmService == null) {
      return const OcrExtractionResult(
        text: '',
        extractionMethod: 'llm_not_available',
      );
    }

    try {
      final prompt = '''
Extract all text visible in this image content.
Return only the extracted text, preserving the original formatting as much as possible.
If no text is visible, return an empty string.

Image content (base64 or reference): $content''';

      final response = await _llmService.chat(
        message: prompt,
        modelId: '',
        systemPrompt:
            'You are an OCR assistant. Extract text from images accurately.',
        feature: 'ocr_extraction',
      );

      if (response.trim().isEmpty) {
        return const OcrExtractionResult(
          text: '',
          extractionMethod: 'ocr_empty_result',
        );
      }

      return OcrExtractionResult(
        text: response.trim(),
        confidence: 0.7,
        extractionMethod: 'ocr_llm',
      );
    } catch (e) {
      _logger.e('LLM OCR failed', e);
      return const OcrExtractionResult(
        text: '',
        extractionMethod: 'ocr_llm_failed',
      );
    }
  }
}
