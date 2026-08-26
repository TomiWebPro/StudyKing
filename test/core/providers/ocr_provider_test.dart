import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/providers/ocr_provider.dart';

void main() {
  group('ocrModeProvider', () {
    test('defaults to hybrid', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(ocrModeProvider), OcrMode.hybrid);
    });

    test('updates when the user selects a different mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Behavioral assertion: the provider reflects user-driven state changes,
      // which downstream ingestion uses to choose the OCR engine pipeline.
      container.read(ocrModeProvider.notifier).state = OcrMode.fast;
      expect(container.read(ocrModeProvider), OcrMode.fast);

      container.read(ocrModeProvider.notifier).state = OcrMode.accurate;
      expect(container.read(ocrModeProvider), OcrMode.accurate);
    });
  });
}
