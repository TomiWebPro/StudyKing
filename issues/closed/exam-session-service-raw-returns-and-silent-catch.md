# exam_session_service public methods return raw types and silently swallow errors

## Description
`ExamSessionService` has two public methods that violate AGENTS.md conventions:
1. `finishExam(...)` returns `Future<ExamResult>` instead of `Result<ExamResult>` (lib/features/practice/services/exam_session_service.dart:289). It performs persistence (`_sessionRepo.save`, `_saveExamResult`) whose failures are not surfaced as a `Result`.
2. `getSavedExamResults()` is a `static Future<List<Map<String, dynamic>>>` (lib/features/practice/services/exam_session_service.dart:328) that internally opens a Hive box; on any exception it does `catch (e) { return []; }` (lib/features/practice/services/exam_session_service.dart:337-339) — returning an empty list while **silently swallowing the error with no log**. This violates both the `Result<T>` return-type rule and the "every catch must log" rule, and hides real failures (e.g. box-not-open) from callers.

Callers that must be updated:
- `lib/features/practice/presentation/screens/practice_screen.dart:564` uses `await ExamSessionService.getSavedExamResults()` and treats the list as truth.
- `lib/features/practice/presentation/screens/exam_session_screen.dart:253` and `:279` use `await _examService.finishExam(...)`.

## Affected files/areas
- lib/features/practice/services/exam_session_service.dart:289 (finishExam)
- lib/features/practice/services/exam_session_service.dart:328, 337-339 (getSavedExamResults)
- lib/features/practice/presentation/screens/practice_screen.dart:564
- lib/features/practice/presentation/screens/exam_session_screen.dart:253, 279

## Expected vs Actual
- Expected: public service methods return `Result<T>`; the `getSavedExamResults` catch logs the error with `_logger.w(...)` and surfaces failure via `Result.failure` rather than returning an empty list.
- Actual: `finishExam` returns a raw `ExamResult`; `getSavedExamResults` returns `[]` on any exception with no logging, masking storage failures.

## Acceptance Criteria
- [ ] `finishExam` returns `Future<Result<ExamResult>>`; internal failures are captured into a `Result.failure` (use `Result.capture` or explicit fold).
- [ ] `getSavedExamResults` is wrapped to return `Result<List<Map<String, dynamic>>>`; the catch logs the error with `_logger.w('...', e)` (descriptive message) instead of returning `[]` silently.
- [ ] Callers (`practice_screen.dart:564`, `exam_session_screen.dart:253/279`) are updated to read `.data`/handle `isFailure`.
- [ ] Existing tests in `test/features/practice/services/exam_session_service_test.dart` are updated accordingly and pass.
