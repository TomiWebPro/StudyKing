# [Scanner] Minor convention violations: .trim().toLowerCase() and non-final Logger

**Source:** automatic scanner
**Severity:** minor

## Finding 1: `.trim().toLowerCase()` instead of `.normalized`

`lib/core/utils/question_import_utils.dart:272` uses `parts[2].trim().toLowerCase()` to normalize a question type string. The AGENTS.md convention states: *"Use the `.normalized` extension (from `lib/core/utils/string_extensions.dart`) instead of `.trim().toLowerCase()`."*

## Finding 2: `_logger` declared without `final`

`lib/core/errors/handlers.dart:8` declares `static Logger _logger = const Logger('AppErrorHandler');` without `final`. While the setter exists for testability (`@visibleForTesting`), all other Logger instances in the codebase use `static final`. Consider adding `final` and using a setter-only approach for test overrides.

## Location

- `lib/core/utils/question_import_utils.dart:272` — `.trim().toLowerCase()` call
- `lib/core/errors/handlers.dart:8` — `static Logger _logger` (non-final)

## Recommendation

- Use `.normalized` from `string_extensions.dart` instead of `.trim().toLowerCase()`.
- Either add `final` to the Logger in `handlers.dart` and keep the `@visibleForTesting` setter, or keep as-is if the mutable pattern is intentional for testing.
