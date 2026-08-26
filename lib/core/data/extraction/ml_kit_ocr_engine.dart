import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// On-device OCR engine backed by Google ML Kit text recognition.
///
/// Runs fully offline, is fast (sub-second per page), works with any LLM
/// provider, and exposes per-line confidence scores. Only supported on Android
/// and iOS; on other platforms [recognize] returns a failure result so callers
/// can fall back to the LLM engine.
class MlKitOcrEngine implements OcrEngine {
  static final Logger _logger = const Logger('MlKitOcrEngine');

  final TextRecognitionScript script;

  MlKitOcrEngine({this.script = TextRecognitionScript.latin});

  @override
  String get name => 'ml_kit';

  @override
  bool get supportsConfidence => true;

  bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<Result<OcrEngineResult>> recognize(OcrImageInput input) async {
    if (!_isSupported) {
      return Result.failure(
        'ml_kit_unavailable: on-device OCR requires Android or iOS',
      );
    }

    final recognizer = TextRecognizer(script: script);
    try {
      final inputImage = await _toInputImage(input);
      final recognized = await recognizer.processImage(inputImage);

      final segments = <OcrSegment>[];
      var confidenceSum = 0.0;
      var confidenceCount = 0;

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final conf = line.confidence;
          if (conf != null) {
            confidenceSum += conf;
            confidenceCount++;
            segments.add(OcrSegment(line.text, conf));
          } else {
            // ML Kit occasionally omits confidence; treat the line as
            // fully confident rather than discarding recognized text.
            segments.add(OcrSegment(line.text, 1.0));
          }
        }
      }

      final text = recognized.text;
      if (text.trim().isEmpty) {
        return Result.success(
          OcrEngineResult(
            text: '',
            confidence: null,
            segments: const [],
            engineName: name,
          ),
        );
      }

      final overall =
          confidenceCount > 0 ? confidenceSum / confidenceCount : null;

      return Result.success(
        OcrEngineResult(
          text: text,
          confidence: overall,
          segments: segments,
          engineName: name,
        ),
      );
    } catch (e) {
      _logger.w('ML Kit OCR failed: $e');
      return Result.failure('ml_kit_error: $e');
    } finally {
      try {
        await recognizer.close();
      } catch (e) {
        _logger.w('Failed to close ML Kit recognizer: $e');
      }
    }
  }

  Future<InputImage> _toInputImage(OcrImageInput input) async {
    if (input.filePath != null) {
      return InputImage.fromFilePath(input.filePath!);
    }
    if (input.bytes != null) {
      final temp = File(
        '${Directory.systemTemp.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await temp.writeAsBytes(input.bytes!);
      return InputImage.fromFilePath(temp.path);
    }
    throw const OcrInputException(
      'No readable image bytes or file path provided',
    );
  }
}

class OcrInputException implements Exception {
  final String message;
  const OcrInputException(this.message);
  @override
  String toString() => 'OcrInputException: $message';
}
