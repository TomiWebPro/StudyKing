# planner/mentor service methods return raw types instead of Result<T>

## Description
Several public service methods in the planner/mentor features return raw `Future<...>` types instead of `Result<T>`, violating the AGENTS.md rule "Public repository and service method return types must be `Result<T>`":
- `PersonalLearningPlanService.getCurrentAdherence(String studentId)` returns `Future<double>` (lib/features/planner/services/personal_learning_plan_service.dart:1081) — on failure it returns `0.0` via a catch, swallowing the error as a magic value.
- `PersonalLearningPlanService.getConsecutiveLowAdherenceDays(String studentId)` returns `Future<int>` (lib/features/planner/services/personal_learning_plan_service.dart:1092) — same pattern, returns `0` on failure.
- `ActionExecutor.execute(PendingActionModel action)` returns `Future<bool>` (lib/features/planner/services/action_executor.dart:14). Internally it does `result.data ?? false` against underlying `Result`s, so a *failed* `Result` from `_plannerService.scheduleLesson` is silently converted to `false` — failures are never surfaced or logged.

Internal callers that must be updated:
- lib/features/planner/services/personal_learning_plan_service.dart:236-237 call both adherence methods directly.
- Callers of `ActionExecutor.execute` (search via `actionExecutor.execute` / `.execute(`).

## Affected files/areas
- lib/features/planner/services/personal_learning_plan_service.dart:1081, 1092, 236-237
- lib/features/planner/services/action_executor.dart:14, 54, 84, 95

## Expected vs Actual
- Expected: these public methods return `Result<double>` / `Result<int>` / `Result<bool>`; failures are represented by `Result.failure` (and logged with `_logger.w`), not by magic `0.0`/`0`/`false` values.
- Actual: methods return raw numeric/bool types and convert failures into indistinguishable default values, hiding errors (e.g. adherence repo not initialized, scheduling failure).

## Acceptance Criteria
- [ ] `getCurrentAdherence` returns `Future<Result<double>>` (failure logged with `_logger.w`).
- [ ] `getConsecutiveLowAdherenceDays` returns `Future<Result<int>>` (failure logged with `_logger.w`).
- [ ] `ActionExecutor.execute` returns `Future<Result<bool>>` and propagates/does not silently drop underlying `Result` failures.
- [ ] Internal callers (personal_learning_plan_service.dart:236-237) and any external callers are updated to consume `.data`/`.isFailure`.
- [ ] Tests in `test/features/planner/services/personal_learning_plan_service_test.dart` and `test/features/planner/services/action_executor_test.dart` are updated and pass.
