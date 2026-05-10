# Strengthen Practice Feature Tests: replace placeholders with behavior-level coverage

## Context

The current practice-related test suite is mostly placeholder-level and does not protect core user flows in `lib/features/practice`.

Examples:
- `test/screens.practice.test.dart` asserts trivial values and widget construction, but does not validate screen behavior (loading, error state, subject selection, navigation).
- `test/validation.answer.test.dart` checks enum equality and static lists instead of real answer validation outcomes.
- `test/features.practice.test.dart` contains placeholder assertions (e.g., `1 + 1 == 2`) and does not exercise `PracticeAnswerRecord` or session behavior.

Meanwhile, important production logic exists in:
- `lib/features/practice/presentation/practice_screen.dart`
- `lib/features/practice/presentation/practice_session_screen.dart`
- `lib/features/practice/services/answer_validation_service.dart`

This creates high regression risk in the practice journey (question loading, submission, correctness tracking, completion flow, and validator behavior).

## Problem

There is no meaningful automated coverage for the most failure-prone practice paths:
- repository failure/empty-question handling
- question count clamping and topic filtering
- submission/feedback/next-question progression
- session completion and timer cleanup behavior
- `AnswerValidationService` correctness across question types and cache behavior

## Affected Files

- `test/screens.practice.test.dart`
- `test/validation.answer.test.dart`
- `test/features.practice.test.dart`
- `lib/features/practice/presentation/practice_screen.dart`
- `lib/features/practice/presentation/practice_session_screen.dart`
- `lib/features/practice/services/answer_validation_service.dart`

## Why this is high value

Practice is a core learning loop; regressions here directly affect grading trust and user confidence. Current tests can pass while the actual session flow is broken, so they provide low signal and poor release safety.

## Acceptance Criteria

1. Replace placeholder assertions in the three practice test files with behavior-driven tests that fail on real regressions.
2. Add widget tests for `PracticeScreen` covering:
   - loading indicator before subjects resolve,
   - empty state when no subjects exist,
   - subject list rendering for one and multiple subjects,
   - tap paths (`Practice` FAB and subject card) leading to practice session navigation.
3. Add widget tests for `PracticeSessionScreen` covering:
   - successful question load and first question render,
   - empty/failure repository result showing no-questions path,
   - submit disabled until answer exists,
   - score/correct count updates after submit,
   - next question progression and completion pop flow.
4. Add unit tests for `AnswerValidationService.validateAnswer` covering:
   - markscheme present vs missing,
   - typed/single-choice/multi-choice correctness outcomes,
   - cache behavior when validating the same `question.id` repeatedly (ensuring no stale-validator false positives).
5. Ensure tests use deterministic fixtures/fakes (no `DateTime.now()` assertions without clock control, no trivial tautology checks).
6. CI test run demonstrates these tests execute and pass under `flutter test`.
