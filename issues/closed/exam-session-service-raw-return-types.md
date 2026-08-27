# Public `exam_session_service` methods return raw types instead of `Result<T>`

## Description
Per AGENTS.md, public service/repository methods must return `Result<T>` (throw only in private helpers or startup config validation). In `lib/features/practice/services/exam_session_service.dart` two public methods return raw types and surface failures inconsistently:

- `finishExam(...)` (line 289) returns `Future<ExamResult>` directly. If `_sessionRepo.save` or `_saveExamResult` throws, the caller receives an unhandled exception rather than a `Result`.
- `getSavedExamResults()` (line 328) returns `Future<List<Map<String, dynamic>>>` and silently swallows Hive errors in a `catch (e) { return []; }` (see also `silent-catch-blocks-without-logging.md`). Callers cannot distinguish "no results" from "failed to load".

For contrast, `evaluateRichAnswer` (line 244) correctly returns `Result<EvaluationResult>`, so the file is internally inconsistent.

## Affected files/areas
- lib/features/practice/services/exam_session_service.dart:289
- lib/features/practice/services/exam_session_service.dart:328

## Expected vs Actual
- Expected: `Future<Result<ExamResult>> finishExam(...)` and `Future<Result<List<Map<String, dynamic>>>> getSavedExamResults()`, with failures captured via `Result.capture`/returning `Result.failure`, and errors logged.
- Actual: raw return types; `getSavedExamResults` returns `[]` on failure with no logging, masking load errors.

## Acceptance Criteria
- [ ] `finishExam` returns `Result<ExamResult>` and wraps its persistence work in `Result.capture` (or returns `Result.failure` on error).
- [ ] `getSavedExamResults` returns `Result<List<Map<String, dynamic>>>` and logs the failure (no silent empty list).
- [ ] Callers of these methods are updated to handle the `Result` (unwrap `.data` / check `.isFailure`).
- [ ] A unit test covers the failure path for `getSavedExamResults` (Hive open fails / throws) asserting a `Result.failure`.
- [ ] `flutter analyze` remains clean.
