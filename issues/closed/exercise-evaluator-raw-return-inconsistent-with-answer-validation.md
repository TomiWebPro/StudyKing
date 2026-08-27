# exercise_evaluator.evaluate returns raw type, inconsistent with answer_validation_service

## Description
Two services compute the same concept (an answer evaluation) with different contracts:

- `lib/features/teaching/services/exercise_evaluator.dart:43` declares `Future<EvaluationResult> evaluate({...})` — a raw (non-`Result`) return.
- `lib/core/services/answer_validation_service.dart:87` declares `Future<Result<EvaluationResult>> evaluateRichAnswer(...)` — the `Result`-wrapped contract that AGENTS.md requires for public service methods.

Per AGENTS.md ("Public repository and service method return types must be Result<T>"), `exercise_evaluator.evaluate` should return `Result<EvaluationResult>` so callers can handle failures uniformly and errors are not thrown across the boundary. The current raw return is also an inconsistency that makes error handling ad hoc.

## Affected files/areas
- lib/features/teaching/services/exercise_evaluator.dart:43
- lib/core/services/answer_validation_service.dart:87 (reference contract to align with)

## Expected vs Actual
- Expected: `exercise_evaluator.evaluate` returns `Future<Result<EvaluationResult>>`, wrapping failures in `Result.failure` and successes in `Result.success`, matching `answer_validation_service`.
- Actual: it returns the raw `EvaluationResult`, forcing callers to rely on throws and creating an inconsistent contract across the two evaluators.

## Acceptance Criteria
- [ ] `exercise_evaluator.evaluate` return type is changed to `Future<Result<EvaluationResult>>`.
- [ ] Internal failures are returned via `Result.failure` (with a logged, descriptive error) rather than thrown.
- [ ] All call sites are updated to handle the `Result`, and tests are added/updated accordingly.
- [ ] `flutter analyze` still passes.
