import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// OCR engine that delegates to an LLM's vision capability.
///
/// Used as the fallback for complex/low-confidence cases or when on-device OCR
/// is unavailable. Reports a fixed [fallbackConfidence] because LLM vision APIs
/// do not expose a reliable confidence score.
class LlmOcrEngine implements OcrEngine {
  static final Logger _logger = const Logger('LlmOcrEngine');

  final LlmService? _llmService;
  final String _modelId;
  final String _localeName;
  final double fallbackConfidence;

  LlmOcrEngine({
    LlmService? llmService,
    required String modelId,
    required String localeName,
    this.fallbackConfidence = 0.7,
  })  : _llmService = llmService,
        _modelId = modelId,
        _localeName = localeName {
    if (modelId.isEmpty) {
      _logger.w('LlmOcrEngine created with empty modelId - LLM OCR will fail');
    }
  }

  @override
  String get name => 'llm';

  @override
  bool get supportsConfidence => false;

  @override
  Future<Result<OcrEngineResult>> recognize(OcrImageInput input) async {
    if (_llmService == null) {
      return Result.failure('no_llm_service');
    }
    if (_modelId.isEmpty) {
      const errorMsg =
          'No vision-capable model configured. Please select a model in Settings.';
      _logger.w(errorMsg);
      return Result.failure(errorMsg);
    }

    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.ocrUserPrompt(_llmPayload(input));

      final result = await _llmService.chat(
        message: prompt,
        modelId: _modelId,
        systemPrompt: l10n.ocrSystemPrompt,
        feature: 'ocr_extraction',
      );

      if (result.isFailure) {
        return Result.failure(result.error ?? 'llm_ocr_failed');
      }

      final response = result.data;
      if (response == null || response.trim().isEmpty) {
        _logger.w('LLM OCR returned empty text');
        return Result.success(
          OcrEngineResult(
            text: '',
            confidence: null,
            segments: const [],
            engineName: name,
          ),
        );
      }

      return Result.success(
        OcrEngineResult(
          text: response.trim(),
          confidence: fallbackConfidence,
          segments: [OcrSegment(response.trim(), fallbackConfidence)],
          engineName: name,
        ),
      );
    } catch (e) {
      _logger.w('LLM OCR failed: $e');
      return Result.failure('llm_ocr_error: $e');
    }
  }

  /// Builds the content payload forwarded to the LLM.
  ///
  /// URLs are passed through directly so the model can resolve them; raw bytes
  /// (file or base64) are re-encoded as base64.
  String _llmPayload(OcrImageInput input) {
    final raw = input.rawContent;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('file://') && input.bytes != null) {
      return base64Encode(input.bytes!);
    }
    if (input.bytes != null) return base64Encode(input.bytes!);
    return raw;
  }
}
