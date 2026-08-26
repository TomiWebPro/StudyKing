# Public Methods Rethrow Result Failures Instead of Returning Result

## Description
`AGENTS.md` states: "Public repository and service method return types must be `Result<T>`" and "`throw` is only allowed in private helper methods or config validation at startup." Several **public** methods catch a `Result` failure and rethrow it as an `Exception` (rather than propagating the `Result.failure` directly). This both violates the "no throw in public methods" rule and is an anti-pattern: even though `Result.capture` will convert the thrown `Exception` back into a `Result.failure`, it obscures the original error type and bypasses the intended `Result` error channel.

## Affected files/areas
- lib/core/services/progress_export_service.dart:395 — `shareComprehensiveCSV` does `if (csvResult.isFailure) throw Exception(csvResult.error);`
- lib/core/services/progress_export_service.dart:467 — `shareComprehensivePDF` does `if (pdfResult.isFailure) throw Exception(pdfResult.error);`
- lib/features/teaching/data/repositories/lesson_feedback_repository.dart:62 — `submitFeedback` does `if (result.isFailure) { throw Exception(result.error); }` inside `Result.capture`.

## Expected vs Actual
- Expected: Public methods return the inner `Result` directly (e.g., `if (csvResult.isFailure) return csvResult;` or map it with context) without using `throw`. Error handling stays within the `Result` channel; `throw` appears only in private helpers or startup config validation.
- Actual: Public methods use `throw Exception(result.error)` to bail out, violating the convention and losing the structured error code/message carried by the original `Result`.

## Acceptance Criteria
- [ ] All three cited sites are refactored to return/proagate the `Result` failure instead of `throw Exception(...)`.
- [ ] No `throw` remains in public service/repository method bodies (except inside `Result.capture` only when truly wrapping an unexpected exception — preferably replaced with `Result.failure`).
- [ ] `flutter analyze` reports no new issues and existing tests still pass.
