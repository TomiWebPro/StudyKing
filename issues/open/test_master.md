# Test Coverage & Convention Audit

**Severity:** MAJOR
**Scope:** All `test/` files cross-referenced against `AGENTS.md` conventions
**Date:** 2026-05-18

---

## Summary

The project has **near-perfect file-to-file test coverage** (every source file has a corresponding test). However, **test quality is uneven**. Several provider tests violate the AGENTS.md behavioural-assertion bar, 4 core widgets have zero tests, error-state coverage is missing in key areas, and several tests still depend on `StudentIdService` instead of the preferred `fixedStudentId` pattern.

**Counting methodology:**
- 232 source files in `lib/features/`
- 84 source files in `lib/core/`
- ~337 test files
- Zero mockito/mocktail imports (all hand-written fakes — good)
- Zero mixed unit/widget test files (properly separated — good)
- Zero skipped/focused tests (no `.skip()` / `.only()` — good)

---

## BLOCKER

*None identified.* All features have at least some test coverage and no convention-violating pattern would crash the app during test execution.

---

## MAJOR

### M1. `practice_providers_test.dart` — Zero behavioral assertions (634 lines, 42 tests)

**File:** `test/features/practice/providers/practice_providers_test.dart`

**Finding:** Every single one of the 42 test cases is construction-only. Every test either checks `isA<Type>()` (the provider creates the expected type) or `same(fakeRepo)` (override returns the same instance). Not a single test exercises actual behaviour through the provider chain.

**Rationale:** Directly violates the AGENTS.md **Provider Test Coverage Bar** which requires *"at least one behavioural assertion beyond construction checks"*. This provider file controls the practice engine (spaced repetition, mastery recording, readiness scoring, difficulty adaptation, exam sessions, mistake review, cross-feature integration) — none of which is verified to actually wire together correctly at the provider level.

**Acceptance criteria:**
- Add ≥1 behavioural test per provider group that exercises real dependency wiring (e.g., override the attempt repo with one that returns seeded data, verify the `MasteryRecorder` actually records an attempt through it).
- Add ≥1 error-state test per provider group (e.g., a repo that returns `Result.failure` causes the downstream service to gracefully handle it).
- Remove or retain construction-only tests only as supplementary coverage.

---

### M2. `dashboard_providers_test.dart` — Mostly construction-only (189 lines, 10 tests)

**File:** `test/features/dashboard/providers/dashboard_providers_test.dart`

**Finding:** Only 1 out of 10 tests is behavioural (`dashboardStudyProgressTrackerProvider uses overridden attemptRepo for stats`). The remaining 9 are `isA<...>()` or `same(...)` checks only.

**Rationale:** Same violation as M1 — insufficient behavioural coverage for the dashboard provider layer. The single behavioural test is well-written but leaves 90% of providers unchecked.

**Acceptance criteria:**
- Add behavioural tests for remaining providers (`dashboardInstrumentationServiceProvider`, `dashboardAdherenceRepositoryProvider`, etc.) that verify wiring produces correct behaviour.
- Add error-state tests (e.g., what happens when `PlanAdherenceRepository` init fails?).

---

### M3. 4 Core Widgets Missing Tests Completely

**Files (untested):**
| Source | Expected Test Location |
|---|---|
| `lib/core/widgets/empty_state_widget.dart` | `test/core/widgets/empty_state_widget_test.dart` |
| `lib/core/widgets/error_retry_widget.dart` | `test/core/widgets/error_retry_widget_test.dart` |
| `lib/core/widgets/loading_indicator.dart` | `test/core/widgets/loading_indicator_test.dart` |
| `lib/core/widgets/loading_screen.dart` | `test/core/widgets/loading_screen_test.dart` |

**Rationale:** These are foundational UI components used across every feature. `error_retry_widget` is particularly critical — it renders error+retry states for the entire app. An untested retry callback could break error recovery everywhere. `empty_state_widget` and `loading_indicator`/`loading_screen` are used in almost every screen.

**Acceptance criteria (each widget):**
- Verify widget renders with given message/icon/title.
- Verify the retry callback fires when the retry button is tapped (for `error_retry_widget`).
- Verify the loading indicator animates / renders correctly.
- Verify semantic labels are correct.
- Verify disabled/hidden states if applicable.

---

### M4. Provider Groups Missing Error-State Coverage (3 Files)

| File | Missing Coverage |
|---|---|
| `test/features/ingestion/providers/ingestion_providers_test.dart` | Zero error-path tests. No coverage of what happens when upload/pipeline/web scraper fails. |
| `test/core/providers/llm_providers_test.dart` | Zero error-path tests. No coverage of what happens when LLM config is invalid or API call fails. |
| `test/core/services/cross_feature_integrator_test.dart` | Zero error-path tests. No coverage of what happens when sessionRepo.save() fails or get() returns failure. |

**Rationale:** The ingestion pipeline involves network calls and file processing — both failure-prone. LLM providers involve API keys and network calls — failures will crash or silently misbehave. `CrossFeatureIntegrator` touches session storage which can fail.

**Acceptance criteria:**
- For each provider group, add ≥1 test where a dependency returns `Result.failure()` or throws, and verify the downstream provider handles it gracefully (returns null/empty, rethrows, logs, etc.).

---

### M5. `tutor_screen_test.dart` — Zero Error-State Coverage at Widget Layer

**File:** `test/features/teaching/presentation/tutor_screen_test.dart`

**Finding:** The widget test covers happy-path UI rendering and message sending, but has no tests for:
- LLM failure (what shows when the tutor AI crashes?)
- Exercise evaluator failure (what shows when grading fails?)
- Session save failure (what shows when the lesson can't be persisted?)

**Rationale:** The tutor screen is the core teaching interface. Failures in the LLM or evaluation pipeline are user-visible and must produce appropriate error UI. Missing widget-layer error coverage means regressions in error handling won't be caught.

**Acceptance criteria:**
- Add widget tests that seed a `FakeTutorService` or provider override that fails, and verify the screen shows an error message/snackbar/retry button.
- Verify that a failed session save doesn't leave the screen in a broken state.

---

## MINOR

### m1. `_FakeStudentIdService` used instead of `fixedStudentId` (6 files)

| File | Pattern Used |
|---|---|
| `test/features/practice/services/practice_data_service_test.dart` | `_FakeStudentIdService extends StudentIdService` |
| `test/features/practice/services/exam_session_service_test.dart` | `_FakeStudentIdService extends StudentIdService` |
| `test/features/practice/services/practice_session_service_test.dart` | `_FakeStudentIdService` (line 31) |
| `test/features/practice/providers/practice_providers_test.dart` | `_FakeStudentIdService extends StudentIdService` |
| `test/features/practice/services/coverage_gaps_integration_test.dart` | `_FakeStudentIdService extends StudentIdService` |
| `test/core/services/cross_feature_integrator_test.dart` | `_FakeStudentIdService extends StudentIdService` |

**Rationale:** AGENTS.md says *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies"*. While unit tests don't always need `fixedStudentId`, creating a `_FakeStudentIdService extends StudentIdService` still ties the test to the `StudentIdService` interface. If `StudentIdService` depends on Hive at construction time, these tests could break.

**Acceptance criteria:**
- Where the service/class accepts a `fixedStudentId` parameter, use `fixedStudentId: 'test-student'` instead of injecting `_FakeStudentIdService()`.
- Where the constructor strictly requires `StudentIdService`, use a minimal fake that does not trigger Hive I/O (already the case for most).

---

### m2. `focus_timer_screen_study_hub_test.dart` imports Hive directly

**File:** `test/features/focus_mode/presentation/focus_timer_screen_study_hub_test.dart`

**Finding:** This file imports `package:hive/hive.dart` (line 30). While it may not call Hive I/O in every test, the import itself suggests the test file is not fully isolated from Hive.

**Rationale:** Widget tests should avoid Hive entirely per AGENTS.md. Even an unused import is a red flag that could mask accidental Hive coupling.

**Acceptance criteria:**
- Remove the `hive` import if it is not used.
- If Hive init is needed, refactor to use `fixedStudentId` and `ProviderScope` overrides instead.

---

### m3. `onboarding_store_test.dart` tests a custom in-memory store, not the real service

**File:** `test/features/onboarding/onboarding_store_test.dart`

**Finding:** This file defines its own `_InMemoryOnboardingStore` class (134 lines) with static fields, and tests that. It does NOT test the real `OnboardingService` or its storage backend. The file provides coverage for *the concept* of onboarding persistence but not *the actual implementation*.

**Rationale:** A test of a custom in-memory implementation proves nothing about the real `OnboardingService`. If the real `OnboardingService` changes its storage logic, this test will still pass. Redundant with the service-level tests in `onboarding_service_test.dart`.

**Acceptance criteria:**
- Either delete this file (if `onboarding_service_test.dart` already covers the real behaviour) or convert it to test the real `OnboardingService` with a fake storage backend.

---

### m4. `export_section_format_instrumentation_test.dart` — Non-standard naming

**File:** `test/features/dashboard/presentation/widgets/export_section_format_instrumentation_test.dart`

**Finding:** The source file is `export_section.dart`. The expected test would be `export_section_test.dart`. Instead, there are two tests: `export_section_test.dart` (general widget tests) and `export_section_format_instrumentation_test.dart` (format/instrumentation-specific tests). The split is reasonable in intent but breaks the naming convention.

**Rationale:** AGENTS.md establishes the convention `<source_name>_test.dart`. A secondary file with a compound name could confuse developers looking for the test file. Also risks naming-creep where more "aspect" files appear.

**Acceptance criteria:**
- Either merge the instrumentation tests into `export_section_test.dart` with a separate `group('format instrumentation', ...)`, or rename to `export_section_format_test.dart` if the source exports are stable. But the simplest fix is to merge.

---

### m5. `onboarding_dialog_persistence_test.dart` — Only 1 test (36 lines)

**File:** `test/features/onboarding/presentation/onboarding_dialog_persistence_test.dart`

**Finding:** This test file has only a single test case, verifying that tapping "Get Started" persists the `onboarding_completed` flag. It uses `tester.pumpWidget` (making it a widget test), which is correctly separated from the unit/model tests.

**Rationale:** A single-test file adds maintenance overhead (separate file, separate test runner invocation) for minimal coverage. The persistence behaviour could be covered in `onboarding_dialog_widget_test.dart` or `onboarding_service_test.dart`.

**Acceptance criteria:**
- Merge this single test into `onboarding_dialog_widget_test.dart` under a group like `group('persistence', ...)`.

---

## Summary Table

| ID | Severity | File(s) | Issue |
|---|---|---|---|
| M1 | MAJOR | `test/features/practice/providers/practice_providers_test.dart` | 42 construction-only tests, zero behavioural assertions |
| M2 | MAJOR | `test/features/dashboard/providers/dashboard_providers_test.dart` | 9/10 tests construction-only |
| M3 | MAJOR | 4 core widgets (`empty_state`, `error_retry`, `loading_indicator`, `loading_screen`) | No tests at all |
| M4 | MAJOR | `ingestion_providers_test.dart`, `llm_providers_test.dart`, `cross_feature_integrator_test.dart` | Zero error-state coverage |
| M5 | MAJOR | `test/features/teaching/presentation/tutor_screen_test.dart` | Zero error-state widget coverage |
| m1 | MINOR | 6 files in `test/features/practice/` + `test/core/services/` | `_FakeStudentIdService` instead of `fixedStudentId` |
| m2 | MINOR | `focus_timer_screen_study_hub_test.dart` | Imports Hive directly |
| m3 | MINOR | `test/features/onboarding/onboarding_store_test.dart` | Tests custom in-memory store, not real implementation |
| m4 | MINOR | `export_section_format_instrumentation_test.dart` | Non-standard naming convention |
| m5 | MINOR | `onboarding_dialog_persistence_test.dart` | Single-test file, should merge |

---

## Positive Findings (Do Not Change)

- **Zero mockito/mocktail imports** across all 337 test files — all hand-written fakes per convention.
- **Zero mixed unit/widget files** — unit and widget tests strictly separated.
- **Zero `.skip()`/`.only()` modifiers** — no disabled/focused tests leaking.
- **Zero fakeAsync usage** — all async tests use real futures/streams.
- **All 9 existing test groups for subjects, planner, sessions, mentor, lessons, practice, teaching** have thorough behavioural coverage with error-state tests.
- **File-to-file coverage is 100%** — every `lib/features/*/*.dart` source has a corresponding `test/` file.
- **NavigatorObserver usage is consistent** across all screen-level widget tests that navigate.
