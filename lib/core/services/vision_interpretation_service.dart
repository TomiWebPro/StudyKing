import 'dart:convert';
import 'dart:typed_data';

import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Interprets an uploaded image of student work (handwritten or drawn) by
/// extracting its text with the OCR-based [OcrExtractor] and returns the
/// recognized text so it can be routed into the answer-validation pipeline.
///
/// This is a text-only OCR path: it does not reason about diagrams, graphs,
/// geometry, or math layout. Images without recognizable text (e.g. pure
/// drawings) yield a failure.
class VisionInterpretationService {
  static final Logger _logger = const Logger('VisionInterpretationService');

  final OcrExtractor _ocrExtractor;

  VisionInterpretationService({required OcrExtractor ocrExtractor})
      : _ocrExtractor = ocrExtractor;

  Future<Result<String>> interpretImage(Uint8List image) async {
    if (image.isEmpty) {
      return Result.failure('Image is empty');
    }
    try {
      final result = await _ocrExtractor.extractText(
        rawContent: base64Encode(image),
        sourceUrl: null,
      );
      if (result.isError) {
        return Result.failure(result.errorMessage);
      }
      final text = result.text.trim();
      if (text.isEmpty) {
        return Result.failure('No text recognized in image');
      }
      return Result.success(text);
    } catch (e) {
      _logger.w('Vision interpretation failed', e);
      return Result.failure('Vision interpretation failed: $e');
    }
  }
}
