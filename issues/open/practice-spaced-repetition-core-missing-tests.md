# Add behavioral tests for the spaced-repetition core services

## Description
The spaced-repetition engine is the retention brain of the app, yet none of its
core logic has test coverage. AGENTS.md requires every `lib/features/*/services/*.dart`
file to have a corresponding `test/features/*/services/*_test.dart` with at least one
behavioral assertion. These three files are entirely untested:

- `lib/features/practice/services/spaced_repetition_engine.dart:3` — `ReviewLogEntry`,
  interval/SM-2-style scheduling math, due-date computation.
- `lib/features/practice/services/spaced_repetition_service.dart:20` —
  `SpacedRepetitionService` which orchestrates the engine against the repository.
- `lib/features/practice/services/mastery_recorder.dart:11` — `MasteryRecorder` which
  records attempts and updates mastery state.

A regression in interval calculation would silently break retention for every student
and is currently invisible to CI.

## Affected files/areas
- lib/features/practice/services/spaced_repetition_engine.dart
- lib/features/practice/services/spaced_repetition_service.dart
- lib/features/practice/services/mastery_recorder.dart

## Expected vs Actual
- Expected: Each file has a `*_test.dart` under `test/features/practice/services/`
  that asserts real behavior (e.g. a correct answer increases the interval, an
  incorrect answer lowers ease, a just-reviewed item is not due today, mastery
  recorder updates the stored state for a given topic).
- Actual: No test files exist for any of the three services; only construction
  smoke tests or nothing at all.

## Acceptance Criteria
- [ ] `test/features/practice/services/spaced_repetition_engine_test.dart` exists and
      asserts interval/ease changes for correct vs incorrect reviews and due-date logic.
- [ ] `test/features/practice/services/spaced_repetition_service_test.dart` exists and
      verifies the service delegates to the engine/repository with a hand-written fake
      (no mockito/mocktail) and updates stored state.
- [ ] `test/features/practice/services/mastery_recorder_test.dart` exists and verifies
      a recorded attempt mutates the correct mastery record.
- [ ] `flutter test test/features/practice/services` passes and `flutter analyze` is clean.
