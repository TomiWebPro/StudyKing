import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class OcrExtractionResult {
  final String text;
  final double? confidence;
  final String extractionMethod;
  final String? errorMessage;

  const OcrExtractionResult({
    required this.text,
    this.confidence,
    required this.extractionMethod,
    this.errorMessage,
  });

  bool get isError => errorMessage != null;
}

class OcrExtractor {
  final LlmService? _llmService;
  final String _modelId;
  final String _localeName;
  static final Logger _logger = const Logger('OcrExtractor');

  OcrExtractor({LlmService? llmService, required String modelId, String localeName = 'en'})
      : _llmService = llmService,
        _modelId = modelId,
        _localeName = localeName {
    if (modelId.isEmpty) {
      _logger.w('OcrExtractor created with empty modelId - LLM OCR will fail');
    }
  }

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
      _logger.w('Failed to read image file', e);
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
        errorMessage: 'No LLM service configured',
      );
    }

    if (_modelId.isEmpty) {
      const errorMsg = 'No vision-capable model configured. '
          'Please select a model in Settings > AI Configuration.';
      _logger.w(errorMsg);
      return const OcrExtractionResult(
        text: '',
        extractionMethod: 'model_id_empty',
        errorMessage: errorMsg,
      );
    }

    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.ocrUserPrompt(content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: _modelId,
        systemPrompt: l10n.ocrSystemPrompt,
        feature: 'ocr_extraction',
      );
      if (result.isFailure) {
        return const OcrExtractionResult(
          text: '',
          extractionMethod: 'ocr_llm_failed',
          errorMessage: 'OCR extraction failed',
        );
      }
      final response = result.data!;

      if (response.trim().isEmpty) {
        _logger.w('LLM OCR returned empty text');
        return const OcrExtractionResult(
          text: '',
          extractionMethod: 'ocr_empty_result',
          errorMessage: 'OCR extraction returned empty result. '
              'The model may not support vision tasks.',
        );
      }

      return OcrExtractionResult(
        text: response.trim(),
        confidence: 0.7,
        extractionMethod: 'ocr_llm',
      );
    } catch (e) {
      _logger.w('LLM OCR failed', e);
      return OcrExtractionResult(
        text: '',
        extractionMethod: 'ocr_llm_failed',
        errorMessage: 'OCR extraction failed: $e',
      );
    }
  }
}
