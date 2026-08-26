import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Strategy for choosing which OCR engine processes a scanned image/PDF.
///
/// - [fast]: on-device ML Kit only (offline, instant). Falls back to the
///   LLM only when the on-device engine is unavailable.
/// - [accurate]: LLM vision only (best accuracy, requires a vision model).
/// - [hybrid]: on-device first; the LLM is used only when the on-device engine
///   fails or returns low-confidence text.
enum OcrMode {
  fast,
  accurate,
  hybrid;

  String get label {
    switch (this) {
      case OcrMode.fast:
        return 'Fast';
      case OcrMode.accurate:
        return 'Accurate';
      case OcrMode.hybrid:
        return 'Hybrid';
    }
  }

  /// Whether this mode prefers the on-device (offline) engine first.
  bool get prefersOnDeviceFirst => this != OcrMode.accurate;

  /// Parses a persisted/serialized [value] into an [OcrMode].
  ///
  /// Unknown or null values default to [OcrMode.hybrid].
  static OcrMode fromString(String? value) {
    switch (value?.normalized) {
      case 'fast':
        return OcrMode.fast;
      case 'accurate':
        return OcrMode.accurate;
      case 'hybrid':
        return OcrMode.hybrid;
      default:
        return OcrMode.hybrid;
    }
  }

  @override
  String toString() => name;
}

/// A single recognized text segment together with its confidence score.
class OcrSegment {
  final String text;
  final double confidence;

  const OcrSegment(this.text, this.confidence);
}

/// Normalized result returned by any [OcrEngine].
class OcrEngineResult {
  final String text;
  final double? confidence;
  final List<OcrSegment> segments;
  final String engineName;
  final Duration? duration;

  const OcrEngineResult({
    required this.text,
    this.confidence,
    this.segments = const [],
    required this.engineName,
    this.duration,
  });

  bool get hasText => text.trim().isNotEmpty;
}

/// Resolved image input that an [OcrEngine] can process.
///
/// [rawContent] preserves the original string the caller passed (file path,
/// URL, or base64) so engines like the LLM one can forward it to their own
/// vision pipeline. [bytes]/[filePath] provide materialized image data for
/// on-device engines.
class OcrImageInput {
  final String rawContent;
  final List<int>? bytes;
  final String? filePath;
  final String? sourceUrl;

  const OcrImageInput({
    required this.rawContent,
    this.bytes,
    this.filePath,
    this.sourceUrl,
  });
}

/// A pluggable OCR backend. Implementations: [MlKitOcrEngine] (on-device),
/// [LlmOcrEngine] (LLM vision fallback), and any future offline engine.
abstract class OcrEngine {
  String get name;

  /// Whether this engine can report a real confidence score.
  bool get supportsConfidence;

  Future<Result<OcrEngineResult>> recognize(OcrImageInput input);
}
