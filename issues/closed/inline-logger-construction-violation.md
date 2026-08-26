# Inline Logger Construction Violates Static-final Convention

## Description
`AGENTS.md` logger conventions require: "All Logger instances must be `static final` at class level" and "Inline `const Logger('Name').e(...)` is forbidden." In `lib/features/ingestion/services/chunked_content_processor.dart:373` a `Logger` is constructed inline at the call site instead of using a class-level `static final` instance. This bypasses the project's logging tag/lifecycle conventions and is exactly the pattern the convention forbids.

(Note: `lib/core/errors/result.dart:34` and `:45` also build `Logger(context)` inline; those may be an intentional exception inside the `Result` infrastructure, but should be reviewed for consistency.)

## Affected files/areas
- lib/features/ingestion/services/chunked_content_processor.dart:373 — `Logger('QuestionParser').w('Failed to parse question response', e);`
- lib/core/errors/result.dart:34 and lib/core/errors/result.dart:45 — `Logger(context).w(...)` (review for consistency)

## Expected vs Actual
- Expected: A `static final` `Logger` field is declared at the top of `ChunkedContentProcessor` (e.g., `static final _logger = Logger('ChunkedContentProcessor');`) and the warning call uses `_logger.w(...)`. The string tag should reflect the class, not be constructed ad hoc per call site.
- Actual: `Logger('QuestionParser')` is instantiated inline at the call site, violating the static-final rule and creating a new logger instance on every invocation.

## Acceptance Criteria
- [ ] `chunked_content_processor.dart` declares a `static final` `Logger` instance and replaces the inline `Logger('QuestionParser').w(...)` call with it.
- [ ] `flutter analyze` reports no issues and the log tag remains meaningful (prefer the class name).
- [ ] (Optional) `result.dart` inline `Logger(context)` usages are reviewed and, if not intentionally exempt, refactored to a consistent static logger.
