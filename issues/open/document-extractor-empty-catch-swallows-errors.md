# document_extractor silently swallows XML parse errors without logging

## Description
In `lib/features/ingestion/services/document_extractor.dart`, two PPTX/OOXML extraction helpers catch exceptions but neither logs nor rethrows:

- `extractSlideText` (around line 929) catches `e` and returns `''` with no log.
- `extractSlideImages` (around line 946) has an effectively empty `catch (e) { // Ignore parse errors }` body — a silent swallow forbidden by AGENTS.md.

These run during document ingestion; silent failures make malformed-input bugs invisible. The file has no `Logger` today, so one must be added (a `static final Logger _logger = const Logger('DocumentExtractor')` at class level).

## Affected files/areas
- lib/features/ingestion/services/document_extractor.dart:929 (`return ''`)
- lib/features/ingestion/services/document_extractor.dart:946 (empty `catch (e)`)

## Expected vs Actual
- Expected: parse failures are logged via a `Logger` (with `.w()` for expected malformed input) and callers can still receive a safe empty default.
- Actual: exceptions are swallowed silently; no log, no visibility into why slides/images were dropped.

## Acceptance Criteria
- [ ] A `static final Logger _logger` is added to the document extractor class.
- [ ] The `extractSlideText` catch logs the error (`.w(...)`) before returning `''`.
- [ ] The `extractSlideImages` empty catch logs the error (`.w(...)`) before continuing.
- [ ] `flutter analyze` passes and existing document_extractor tests still pass.
