# Missing Tests — Core Data Layer, Planner Repository, and Question Variant Prompts

## Description
Per `AGENTS.md` test placement rules, `lib/core/data/*`, `lib/features/planner/data/repositories/*`, and `lib/features/questions/services/*` source files require companion tests. The following source files currently have **no test coverage**:
- `lib/core/data/hive_box.dart` and `lib/core/data/hive_schema.dart` — foundational Hive box/schema helpers used by every repository; an untested regression here can crash app startup or silently corrupt persistence.
- `lib/features/planner/data/repositories/plan_context_repository.dart` — planner context persistence, untested.
- `lib/features/questions/services/question_variant_prompts.dart` — prompt-building logic for question-variant generation, untested (distinct from the generation pipeline feature work tracked elsewhere).

## Affected files/areas
- lib/core/data/hive_box.dart (expected: test/core/data/hive_box_test.dart)
- lib/core/data/hive_schema.dart (expected: test/core/data/hive_schema_test.dart)
- lib/features/planner/data/repositories/plan_context_repository.dart (expected: test/features/planner/data/repositories/plan_context_repository_test.dart)
- lib/features/questions/services/question_variant_prompts.dart (expected: test/features/questions/services/question_variant_prompts_test.dart)

## Expected vs Actual
- Expected: Each file has a companion unit test using hand-written fakes / in-memory Hive; public methods returning `Result<T>` are asserted for both success and failure paths.
- Actual: No test files exist; bugs in box-open guards, schema versioning, plan-context save/load, or prompt construction would be invisible to CI.

## Acceptance Criteria
- [ ] test/core/data/hive_box_test.dart exists and covers open/close guards and typed accessors (e.g., `openTyped`, `safeGet`, `safePut`) including the not-open error path.
- [ ] test/core/data/hive_schema_test.dart exists and verifies type-id uniqueness / schema version constants.
- [ ] test/features/planner/data/repositories/plan_context_repository_test.dart exists and covers save/load round-trip and `Result` failure handling.
- [ ] test/features/questions/services/question_variant_prompts_test.dart exists and asserts prompt text composition for multiple question types.
- [ ] `flutter test` passes for the new files.
