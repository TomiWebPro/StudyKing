import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/errors/result.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeOcrEngine implements OcrEngine {
  final String engineName;
  final Result<OcrEngineResult> Function(OcrImageInput input)? handler;
  final List<OcrImageInput> calls = [];

  FakeOcrEngine(this.engineName, [this.handler]);

  @override
  String get name => engineName;

  @override
  bool get supportsConfidence => true;

  @override
  Future<Result<OcrEngineResult>> recognize(OcrImageInput input) async {
    calls.add(input);
    if (handler != null) return handler!(input);
    return Result.failure('not configured');
  }
}

String base64Image(String content) => base64Encode(utf8.encode(content));

// ---------------------------------------------------------------------------
// OcrMode
// ---------------------------------------------------------------------------

void main() {
  group('OcrMode', () {
    test('fromString maps known values case-insensitively', () {
      expect(OcrMode.fromString('FAST'), OcrMode.fast);
      expect(OcrMode.fromString('accurate'), OcrMode.accurate);
      expect(OcrMode.fromString(' hybrid '), OcrMode.hybrid);
    });

    test('fromString defaults to hybrid for unknown/null', () {
      expect(OcrMode.fromString(null), OcrMode.hybrid);
      expect(OcrMode.fromString('bogus'), OcrMode.hybrid);
    });

    test('prefersOnDeviceFirst is false only for accurate', () {
      expect(OcrMode.fast.prefersOnDeviceFirst, isTrue);
      expect(OcrMode.hybrid.prefersOnDeviceFirst, isTrue);
      expect(OcrMode.accurate.prefersOnDeviceFirst, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // OcrExtractionResult
  // -------------------------------------------------------------------------

  group('OcrExtractionResult', () {
    test('isError reflects errorMessage', () {
      expect(
        const OcrExtractionResult(
          text: '',
          extractionMethod: 't',
          errorMessage: 'e',
        ).isError,
        isTrue,
      );
      expect(
        const OcrExtractionResult(text: 'x', extractionMethod: 't').isError,
        isFalse,
      );
    });

    test('stores and omits confidence', () {
      expect(
        const OcrExtractionResult(
          text: 'x',
          confidence: 0.9,
          extractionMethod: 't',
        ).confidence,
        0.9,
      );
      expect(
        const OcrExtractionResult(text: 'x', extractionMethod: 't').confidence,
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  // OcrExtractor orchestration
  // -------------------------------------------------------------------------

  group('OcrExtractor', () {
    late FakeOcrEngine mlKit;
    late FakeOcrEngine llm;

    OcrExtractor runWith({
      required OcrMode mode,
      Result<OcrEngineResult>? mlKitResult,
      Result<OcrEngineResult>? llmResult,
    }) {
      mlKit = FakeOcrEngine(
        'ml_kit',
        (_) => mlKitResult ?? Result.failure('ml_kit_unavailable'),
      );
      llm = FakeOcrEngine(
        'llm',
        (_) => llmResult ?? Result.failure('no_llm'),
      );
      return OcrExtractor(
        mode: mode,
        mlKitEngine: mlKit,
        llmEngine: llm,
        modelId: 'm',
        localeName: 'en',
      );
    }

    final highConf = OcrEngineResult(
      text: 'on-device text',
      confidence: 0.95,
      segments: const [OcrSegment('on-device text', 0.95)],
      engineName: 'ml_kit',
    );
    final lowConf = OcrEngineResult(
      text: 'fuzzy text',
      confidence: 0.3,
      segments: const [OcrSegment('fuzzy text', 0.3)],
      engineName: 'ml_kit',
    );
    final llmResult = OcrEngineResult(
      text: 'ai text',
      confidence: 0.7,
      segments: const [OcrSegment('ai text', 0.7)],
      engineName: 'llm',
    );

    test('fast mode uses only the on-device engine', () async {
      final extractor = runWith(mode: OcrMode.fast, mlKitResult: Result.success(highConf));
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.text, 'on-device text');
      expect(result.confidence, 0.95);
      expect(result.extractionMethod, 'ml_kit');
      expect(llm.calls, isEmpty);
    });

    test('accurate mode uses only the LLM engine', () async {
      final extractor = runWith(mode: OcrMode.accurate, llmResult: Result.success(llmResult));
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.text, 'ai text');
      expect(result.extractionMethod, 'llm');
      expect(mlKit.calls, isEmpty);
    });

    test('hybrid uses on-device result when confidence is high', () async {
      final extractor = runWith(mode: OcrMode.hybrid, mlKitResult: Result.success(highConf));
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.text, 'on-device text');
      expect(result.extractionMethod, 'ml_kit_primary');
      expect(llm.calls, isEmpty);
    });

    test('hybrid falls back to LLM when on-device confidence is low', () async {
      final extractor = runWith(
        mode: OcrMode.hybrid,
        mlKitResult: Result.success(lowConf),
        llmResult: Result.success(llmResult),
      );
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.text, 'ai text');
      expect(result.extractionMethod, 'llm_fallback');
      expect(mlKit.calls, isNotEmpty);
      expect(llm.calls, isNotEmpty);
    });

    test('hybrid falls back to LLM when on-device engine fails', () async {
      final extractor = runWith(
        mode: OcrMode.hybrid,
        mlKitResult: Result.failure('ml_kit_unavailable'),
        llmResult: Result.success(llmResult),
      );
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.text, 'ai text');
      expect(result.extractionMethod, 'llm_fallback');
    });

    test('returns empty result when both engines fail', () async {
      final extractor = runWith(
        mode: OcrMode.hybrid,
        mlKitResult: Result.failure('unavailable'),
        llmResult: Result.failure('no_llm'),
      );
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'ocr_no_text');
    });

    test('reports actual (non-hardcoded) confidence from the engine', () async {
      final custom = OcrEngineResult(
        text: 'x',
        confidence: 0.42,
        segments: const [OcrSegment('x', 0.42)],
        engineName: 'ml_kit',
      );
      final extractor = runWith(mode: OcrMode.fast, mlKitResult: Result.success(custom));
      final result = await extractor.extractText(
        rawContent: base64Image('scan'),
        sourceUrl: null,
      );
      expect(result.confidence, 0.42);
    });

    test('resolves file input to bytes before calling engines', () async {
      final dir = Directory.systemTemp.createTempSync('ocr_in_test_');
      try {
        final file = File('${dir.path}/img.png');
        await file.writeAsBytes([1, 2, 3, 4]);
        final extractor = runWith(mode: OcrMode.fast, mlKitResult: Result.success(highConf));
        await extractor.extractText(
          rawContent: 'file://${file.path}',
          sourceUrl: null,
        );
        expect(mlKit.calls.single.bytes, isNotEmpty);
        expect(mlKit.calls.single.filePath, file.path);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
