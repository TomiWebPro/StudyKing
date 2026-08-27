# Forbidden `catch (_)` in AnswerValidationService without logging

## Description
`AnswerValidationService.isLikelyImageAnswer` uses `catch (_)` and returns `false` without logging the error. AGENTS.md forbids `catch (_)` and requires every catch to log via a `static final` Logger with a descriptive message. The file already has a `static final Logger _logger` (verified), so a `.w()` call should be added.

## Affected files/areas
- lib/core/services/answer_validation_service.dart:151 (`catch (_) { return false; }`)

## Expected vs Actual
- Expected: when `base64Decode`/validation throws, the error is logged via `_logger.w(...)` and the method returns a safe default.
- Actual: `catch (_)` silently swallows the error and returns `false` with no log entry, violating the "every catch must log" and "forbidden empty/catch (_)" rules.

## Acceptance Criteria
- [ ] The `catch (_)` in `answer_validation_service.dart:151` is replaced with a typed `catch (e, st)` (or `catch (e)`) that calls `_logger.w('Failed to validate image answer', error: e, stackTrace: st)`.
- [ ] No `catch (_)` remains in the file.
- [ ] Existing tests for `AnswerValidationService` still pass.
