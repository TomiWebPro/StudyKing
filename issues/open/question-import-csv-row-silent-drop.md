# Question CSV import silently drops malformed rows

## Description
`QuestionImportUtils._parseCsvRow()` wraps row parsing in `try { ... } catch (e) { return null; }`. A malformed CSV row throws and is silently dropped with no logging, causing silent data loss during bulk question import with no way to know which rows failed or why.

## Affected files/areas
- lib/core/utils/question_import_utils.dart:91-100 (`_parseCsvRow`)

## Expected vs Actual
- Expected: Parse failures are logged (`.w(...)`) and surfaced so the user knows some rows were skipped.
- Actual: Malformed rows return `null` silently; the import reports success while dropping data.

## Acceptance Criteria
- [ ] The `catch` block logs the offending row/exception (`_logger.w('Failed to parse question CSV row', e)`).
- [ ] Callers/UI surface a count or list of skipped rows to the user.
- [ ] A test verifies a malformed row is logged and reported rather than silently ignored.
