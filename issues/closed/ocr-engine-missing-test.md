# Missing test for core OCR engine base classes

## Description
`lib/core/data/extraction/ocr_engine.dart` contains non-trivial, user-facing logic that is currently untested:
- `OcrMode.fromString(String?)` — parses a persisted/serialized mode value with a default of `OcrMode.hybrid` for unknown/null values (lines 33–44).
- `OcrMode.label` — maps each enum value to a display string (lines 16–25).
- `OcrMode.prefersOnDeviceFirst` getter (line 28).
- `OcrEngineResult.hasText` getter (line 74).

The sibling extraction files already have tests (`test/core/data/extraction/llm_ocr_engine_test.dart`, `ml_kit_ocr_engine_test.dart`, `ocr_extractor_test.dart`), but there is no `test/core/data/extraction/ocr_engine_test.dart`. This violates the AGENTS.md test placement table, which maps `lib/core/data/**/*.dart` → `test/core/data/**/*_test.dart`.

## Affected files/areas
- lib/core/data/extraction/ocr_engine.dart (logic to cover)
- test/core/data/extraction/ocr_engine_test.dart (missing)

## Expected vs Actual
- Expected: every `lib/core/data/**/*.dart` source file has a corresponding `*_test.dart` per the AGENTS.md placement table, covering the `OcrMode` parsing/label logic and `OcrEngineResult.hasText`.
- Actual: `lib/core/data/extraction/ocr_engine.dart` has no test file.

## Acceptance Criteria
- [ ] Create `test/core/data/extraction/ocr_engine_test.dart`.
- [ ] Test `OcrMode.fromString` for `'fast'`, `'accurate'`, `'hybrid'`, `null`, and an unknown value (all default to `hybrid` except the explicit ones).
- [ ] Test `OcrMode.label` returns the expected display strings.
- [ ] Test `OcrMode.prefersOnDeviceFirst` (`accurate` is false, others true).
- [ ] Test `OcrEngineResult.hasText` for empty/non-empty text.
- [ ] `flutter test test/core/data/extraction/ocr_engine_test.dart` passes.
