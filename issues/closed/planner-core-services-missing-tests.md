# Add behavioral tests for planner core services

## Description
The planner is responsible for long-term study plans, roadmaps, and adherence — a
core pillar of the vision (agent_must_read.md lines 73-84). The following planner
services have no test coverage, violating the AGENTS.md test-placement rule:

- `lib/features/planner/services/planner_service.dart:30` — `PlannerService` (plan
  load/save/orchestration).
- `lib/features/planner/services/personal_learning_plan_service.dart:26` —
  plan generation from `PlanGenerationConfig`.
- `lib/features/planner/services/syllabus_resolver.dart:12` — `SyllabusTopicNode`
  topological ordering / learning-order resolution.
- `lib/features/planner/services/action_executor.dart` — executes pending plan actions.

A bug here can silently produce an invalid or cyclic study plan without any test
catching it.

## Affected files/areas
- lib/features/planner/services/planner_service.dart
- lib/features/planner/services/personal_learning_plan_service.dart
- lib/features/planner/services/syllabus_resolver.dart
- lib/features/planner/services/action_executor.dart

## Expected vs Actual
- Expected: Each service has `test/features/planner/services/*_test.dart` with at least
  one behavioral assertion (e.g. `SyllabusTopicNode` topological sort respects
  dependencies and detects cycles; `PlannerService` falls back to a default when no
  stored plan exists).
- Actual: None of these service files have a corresponding test file.

## Acceptance Criteria
- [ ] `test/features/planner/services/syllabus_resolver_test.dart` exists and verifies
      dependency-ordered output and cycle detection using hand-written fakes.
- [ ] `test/features/planner/services/planner_service_test.dart` exists and verifies
      wiring/fallback behavior via `ProviderScope` overrides or injected fakes.
- [ ] `test/features/planner/services/personal_learning_plan_service_test.dart` and
      `action_executor_test.dart` exist with behavioral assertions.
- [ ] `flutter test test/features/planner/services` passes and `flutter analyze` is clean.
