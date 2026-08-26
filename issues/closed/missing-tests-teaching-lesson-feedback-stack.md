# Missing Tests — Teaching Lesson Feedback Stack

## Description
Per `AGENTS.md` test placement rules, every source file under `lib/features/teaching/data/models/`, `lib/features/teaching/data/adapters/`, and `lib/features/teaching/providers/` must have a corresponding test file. The lesson-feedback feature (recently added) has **no test coverage at all** for its model, adapters, and providers. The provider, in particular, must satisfy the provider behavioral-assertion bar (dependency wiring, fallback logic, singleton, or error-state handling), which is currently untested.

## Affected files/areas
- lib/features/teaching/data/models/lesson_feedback_model.dart (expected: test/features/teaching/data/models/lesson_feedback_model_test.dart)
- lib/features/teaching/data/adapters/lesson_feedback_adapter.dart (expected: test/features/teaching/data/adapters/lesson_feedback_adapter_test.dart)
- lib/features/teaching/data/adapters/lesson_recap_adapter.dart (expected: test/features/teaching/data/adapters/lesson_recap_adapter_test.dart)
- lib/features/teaching/providers/lesson_feedback_providers.dart (expected: test/features/teaching/providers/lesson_feedback_providers_test.dart)

## Expected vs Actual
- Expected: Each source file has a companion test file; the provider test includes at least one behavioral assertion beyond construction (e.g., verifying `lessonFeedbackRepositoryProvider` is wired into `submitLessonFeedbackProvider`, or that an empty/closed box yields a graceful `Result.failure`).
- Actual: No test files exist for any of these four paths; regressions in feedback submission, recap storage, or model serialization would go undetected.

## Acceptance Criteria
- [ ] test/features/teaching/data/models/lesson_feedback_model_test.dart exists and covers (de)serialization (toJson/fromJson), defaults, and equality.
- [ ] test/features/teaching/data/adapters/lesson_feedback_adapter_test.dart exists and verifies adapter type id + (de)serialization round-trip.
- [ ] test/features/teaching/data/adapters/lesson_recap_adapter_test.dart exists and verifies adapter type id + (de)serialization round-trip.
- [ ] test/features/teaching/providers/lesson_feedback_providers_test.dart exists and includes at least one behavioral assertion (dependency wiring via overrides, or fallback/error handling) per AGENTS.md provider test bar.
- [ ] `flutter test` passes for the new files.
