import 'dart:convert';
import 'dart:typed_data';

import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Interprets an uploaded image of student work (handwritten or drawn) into
/// text using the vision-capable [OcrExtractor] and returns the recognized
/// answer so it can be routed into the answer-validation pipeline.
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
