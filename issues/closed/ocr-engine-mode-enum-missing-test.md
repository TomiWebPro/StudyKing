# OcrMode enum in ocr_engine.dart has no unit test

## Description
Per AGENTS.md, every source file under `lib/core/data/**/` must have a corresponding test at `test/core/data/**/*_test.dart`. `lib/core/data/extraction/ocr_engine.dart` defines the `OcrMode` enum with non-trivial, user-facing logic — `OcrMode.label` (switch over enum values) and the `OcrMode.fromString(String? value)` parser (which normalizes via `.normalized`, maps `'fast'`/`'accurate'`/`'hybrid'`, and defaults unknowns/null to `OcrMode.hybrid`). None of this logic is covered by a test, while its sibling extraction files (`ml_kit_ocr_engine_test.dart`, `llm_ocr_engine_test.dart`, `ocr_extractor_test.dart`, `pdf_extractor_test.dart`) all have tests.

A regression in `fromString` (e.g. wrong default or a typo in the normalized match) would silently misconfigure OCR mode selection with no test to catch it.

## Affected files/areas
- lib/core/data/extraction/ocr_engine.dart:30 (`OcrMode.fromString`), :14 (`OcrMode.label`)
- test/core/data/extraction/ (missing `ocr_engine_test.dart`)

## Expected vs Actual
- Expected: A `test/core/data/extraction/ocr_engine_test.dart` covering `OcrMode.fromString` for each value, null, and unknown strings (all must return `OcrMode.hybrid` by default), plus `OcrMode.label` for each enum value.
- Actual: No test file exists for `ocr_engine.dart`; its parsing/defaulting logic is unverified.

## Acceptance Criteria
- [ ] `test/core/data/extraction/ocr_engine_test.dart` exists and passes.
- [ ] Tests assert `OcrMode.fromString('fast') == OcrMode.fast`, `OcrMode.fromString('accurate') == OcrMode.accurate`, `OcrMode.fromString('hybrid') == OcrMode.hybrid`.
- [ ] Tests assert `OcrMode.fromString(null) == OcrMode.hybrid` and `OcrMode.fromString('garbage') == OcrMode.hybrid` (default behavior).
- [ ] Tests assert `OcrMode.fast.label == 'Fast'`, `OcrMode.accurate.label == 'Accurate'`, `OcrMode.hybrid.label == 'Hybrid'`.
- [ ] `flutter test test/core/data/extraction/ocr_engine_test.dart` passes.
