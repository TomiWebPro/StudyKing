# Catch blocks return Result.failure without logging

## Description
Several `catch` blocks catch an exception and immediately return `Result.failure(e.toString())` (or a custom message) without ever logging the error via a `Logger`. AGENTS.md states "Every catch must log the error with a descriptive message" and that inline handling of expected error paths should use `.w()`. These catches swallow the stack trace and context, making production failures hard to diagnose. The previously closed catch-related issues covered scanner/exam-session/document-extractor only, so these repository/service catches remain unaddressed.

## Affected files/areas
- `lib/features/teaching/services/lesson_recap_service.dart:202` `catch (storeErr)` → `return Result.failure('Failed to generate lesson recap: $storeErr')` (no `_logger` call)
- `lib/features/subjects/data/repositories/subject_repository.dart:25` `catch (e)` → `Result.failure(e.toString())` (also `:45`, `:62`, `:73`)
- `lib/features/teaching/data/repositories/tutor_session_repository.dart:102` `catch (e)` → `Result.failure(e.toString())`
- `lib/features/settings/services/data_backup_service.dart:145` `catch (e)` → `Result.failure('Decryption_failed: ...')`

## Expected vs Actual
- Expected: every `catch` logs the error with a descriptive message (`_logger.w('...', e)` for expected paths, `_logger.e(...)` for unexpected), then returns `Result.failure(...)`.
- Actual: the exception is captured into a `Result.failure` string but never logged, losing the original stack trace and context.

## Acceptance Criteria
- [ ] Each listed `catch` block adds a `Logger` call (use the class's existing `static final Logger _logger`, or add one) with a descriptive message and the caught error/stackTrace.
- [ ] The returned `Result.failure` message remains meaningful to callers.
- [ ] `flutter analyze` stays clean and the files' existing tests still pass.
