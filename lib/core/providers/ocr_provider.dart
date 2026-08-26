import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';

/// User-selectable OCR strategy (Fast / Accurate / Hybrid).
///
/// Read by [documentExtractorProvider] so ingestion uses the configured engine
/// pipeline. Defaults to [OcrMode.hybrid] for the best accuracy/latency balance.
final ocrModeProvider = StateProvider<OcrMode>((ref) => OcrMode.hybrid);
