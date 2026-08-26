import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:studyking/core/data/extraction/llm_ocr_engine.dart';
import 'package:studyking/core/data/extraction/ml_kit_ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';

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

/// Orchestrates OCR extraction across one or more [OcrEngine] backends.
///
/// The on-device [MlKitOcrEngine] is the primary, offline engine. The
/// [LlmOcrEngine] is used as a fallback for complex/low-confidence cases or
/// when on-device OCR is unavailable. The active engines and the fallback
/// behavior are driven by [mode].
class OcrExtractor {
  static final Logger _logger = const Logger('OcrExtractor');

  final OcrMode mode;
  final OcrEngine _mlKitEngine;
  final OcrEngine _llmEngine;
  final double _lowConfidenceThreshold;

  OcrExtractor({
    this.mode = OcrMode.hybrid,
    LlmService? llmService,
    required String modelId,
    required String localeName,
    OcrEngine? mlKitEngine,
    OcrEngine? llmEngine,
    double lowConfidenceThreshold = 0.6,
  })  : _mlKitEngine = mlKitEngine ?? MlKitOcrEngine(),
        _llmEngine = llmEngine ??
            LlmOcrEngine(
              llmService: llmService,
              modelId: modelId,
              localeName: localeName,
            ),
        _lowConfidenceThreshold = lowConfidenceThreshold {
    if (modelId.isEmpty && mode != OcrMode.fast) {
      _logger.w('OcrExtractor created with empty modelId - '
          'LLM OCR fallback will fail');
    }
  }

  List<OcrEngine> get _orderedEngines {
    switch (mode) {
      case OcrMode.fast:
        return [_mlKitEngine];
      case OcrMode.accurate:
        return [_llmEngine];
      case OcrMode.hybrid:
        return [_mlKitEngine, _llmEngine];
    }
  }

  Future<OcrExtractionResult> extractText({
    required String rawContent,
    required String? sourceUrl,
  }) async {
    final input = await _resolveInput(rawContent, sourceUrl);
    if (input == null) {
      // Treat unreadable input as "no text" so callers can fall back to
      // embedding the raw reference (e.g. the file path) instead of failing.
      return const OcrExtractionResult(
        text: '',
        extractionMethod: 'ocr_input_unreadable',
      );
    }

    final engines = _orderedEngines;
    OcrExtractionResult? lowConfidenceBest;

    for (var i = 0; i < engines.length; i++) {
      final engine = engines[i];
      final result = await engine.recognize(input);

      if (result.isFailure) {
        _logger.w('OCR engine ${engine.name} failed: ${result.error}');
        continue;
      }

      final data = result.data!;
      if (!data.hasText) continue;

      final extractionMethod = engines.length == 1
          ? engine.name
          : (i == 0 ? '${engine.name}_primary' : '${engine.name}_fallback');

      // Hybrid mode: when the on-device engine produced low-confidence text,
      // attempt the next (LLM) engine and keep whichever result is produced.
      if (mode == OcrMode.hybrid &&
          i == 0 &&
          engine.name == _mlKitEngine.name &&
          engines.length > 1 &&
          (data.confidence == null ||
              data.confidence! < _lowConfidenceThreshold)) {
        lowConfidenceBest = OcrExtractionResult(
          text: data.text,
          confidence: data.confidence,
          extractionMethod: extractionMethod,
        );
        continue;
      }

      return OcrExtractionResult(
        text: data.text,
        confidence: data.confidence,
        extractionMethod: extractionMethod,
      );
    }

    if (lowConfidenceBest != null) return lowConfidenceBest;

    return const OcrExtractionResult(
      text: '',
      extractionMethod: 'ocr_no_text',
    );
  }

  Future<OcrImageInput?> _resolveInput(String rawContent, String? sourceUrl) async {
    try {
      if (rawContent.startsWith('file://')) {
        final filePath = rawContent.substring(7);
        final file = File(filePath);
        if (!file.existsSync()) {
          return null;
        }
        final bytes = await file.readAsBytes();
        return OcrImageInput(
          rawContent: rawContent,
          bytes: bytes,
          filePath: filePath,
          sourceUrl: sourceUrl,
        );
      }

      if (rawContent.startsWith('http://') ||
          rawContent.startsWith('https://')) {
        try {
          final response = await http.get(Uri.parse(rawContent));
          if (response.statusCode == 200) {
            return OcrImageInput(
              rawContent: rawContent,
              bytes: response.bodyBytes,
              sourceUrl: sourceUrl,
            );
          }
        } catch (e) {
          _logger.w('Failed to download image for OCR: $e');
        }
        // Fall back to letting the LLM resolve the URL directly.
        return OcrImageInput(
          rawContent: rawContent,
          sourceUrl: sourceUrl,
        );
      }

      final isBase64 = rawContent.length > 100 &&
          RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(rawContent.substring(0, 100));
      if (isBase64) {
        return OcrImageInput(
          rawContent: rawContent,
          bytes: base64Decode(rawContent),
          sourceUrl: sourceUrl,
        );
      }

      return OcrImageInput(
        rawContent: rawContent,
        sourceUrl: sourceUrl,
      );
    } catch (e) {
      _logger.w('Failed to resolve OCR input: $e');
      return null;
    }
  }
}
