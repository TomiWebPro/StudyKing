# Critical Test Gap: `MentorService._checkAndHandlePlanningIntent` Entirely Untested

## Context

`MentorService.chat()` (at `lib/features/mentor/services/mentor_service.dart:50`) delegates to `_checkAndHandlePlanningIntent` (`:73`), which contains the most complex branching logic in the service:

- Keyword-based planning intent detection with **internationalized** Spanish support (`programar`, `reprogramar`, `planificar`)
- `PendingActionRepository` dedup check before creation
- Action type differentiation (`schedule` vs `reschedule`)
- `_extractTopic()` topic parsing with two distinct keyword sets
- A bare `catch (_)` that silently swallows all repository exceptions

**Zero lines of this method are tested.** The existing `mentor_service_test.dart` only verifies that `chat()` yields LLM chunks to the caller — it never asserts that planning keywords actually create pending actions, that duplicate intents are skipped, that Spanish keywords work, or that repository failures are handled gracefully.

## Affected Files

| File | Issue |
|---|---|
| `lib/features/mentor/services/mentor_service.dart` (lines 50–102, 124–145) | Untested `_checkAndHandlePlanningIntent`, `_extractTopic`, error paths |
| `test/features/mentor/services/mentor_service_test.dart` | Covers only LLM delegation, `suggestNextAction`, `suggestReschedule`, `getProgressReport` — **no planning-intent coverage** |

## Systemic Pattern: Boilerplate-Only Provider Tests

Beyond the mentor service gap, every provider test file (`test/features/*/providers/*_test.dart`) follows an identical boilerplate pattern that **tests Riverpod framework behavior** (resolution, override, singleton, lifecycle) rather than real business logic. None verify that the constructed dependency chains are actually wired correctly. This affects 7 files:

- `test/features/mentor/providers/mentor_providers_test.dart` — 137 lines, all boilerplate
- `test/features/practice/providers/practice_providers_test.dart` — 165 lines, all boilerplate
- `test/features/dashboard/providers/dashboard_providers_test.dart`
- `test/features/focus_mode/providers/focus_mode_providers_test.dart`
- `test/features/lessons/providers/lesson_providers_test.dart`
- `test/features/planner/providers/planner_providers_test.dart`
- `test/features/subjects/providers/subjects_repository_provider_test.dart`

These tests provide **near-zero regression protection** and inflate the test suite with low-value assertions.

## Rationale

1. **Planning intent is the riskiest path** — it bridges LLM output → database writes. A bug here creates silent data corruption or missed study plans.
2. **Silent error swallowing** (`catch (_) {}` at line 101) hides repository failures during planning intent handling, making production issues invisible.
3. **i18n keywords** (`programar`, `reprogramar`, `planificar`) have no test coverage — a typo or regression would go undetected.
4. **Provider tests consume maintenance effort** without catching regressions. Real dependency wiring errors (e.g., a new required constructor param) are never caught by the current boilerplate.

## Acceptance Criteria

1. **`MentorService._checkAndHandlePlanningIntent` is fully covered**, including:
   - Each planning keyword (`schedule`, `reschedule`, `plan`, `roadmap`, and Spanish variants)
   - Non-planning messages do NOT create pending actions
   - `reschedule` keyword creates a `PendingActionModel` with `actionType == PendingActionType.reschedule.name`
   - Other planning keywords create `PendingActionType.schedule` actions
   - Existing pending actions prevent duplicate creation
   - Repository throws are caught silently (no crash, no side-effect)
   - `_extractTopic` extracts topics from `about`, `for`, `on`, `study`, `learn`, `review`, `practice` prefixed phrases and falls back to `topic`, `subject`, `lesson` keywords
   - Non-matching messages return `'general'`
2. **Provider tests are replaced with behavior-validating tests** that verify correct dependency wiring (e.g., `mentorProgressTrackerProvider` uses `mentorAttemptRepositoryProvider` as its `attemptRepo`) rather than just type-checking Riverpod resolution.
