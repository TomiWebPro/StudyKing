# Exam session saved-results method returns raw type and silently swallows errors

## Description
`ExamSessionService.getSavedExamResults()` is a public service method that returns a raw `Future<List<Map<String, dynamic>>>` instead of `Result<T>`, and its `catch (e)` returns `[]` with no logging. A Hive/storage failure is therefore silently masked as "you have no exam history" — the user sees an empty state while the real error is invisible to logs.

## Affected files/areas
- lib/features/practice/services/exam_session_service.dart:328-339 (`getSavedExamResults`)
- lib/features/practice/presentation/screens/practice_screen.dart:564 (caller treats `isEmpty` as "no history")

## Expected vs Actual
- Expected: Public service methods return `Result<T>`; failures are logged (`.w(...)`) and distinguishable from a genuinely empty result.
- Actual: Returns raw `List`; on any exception returns `[]` with no log, so storage failures look identical to "no exam history taken yet".

## Acceptance Criteria
- [ ] `getSavedExamResults` returns `Future<Result<List<Map<String, dynamic>>>>`.
- [ ] The `catch` block logs the exception with `_logger.w('Failed to load saved exam results', e)`.
- [ ] Caller (`practice_screen.dart:564`) handles the `Result` and distinguishes error from empty.
- [ ] A unit test covers the error path (e.g., failing box open returns a failure Result, not `[]`).
