# Test Coverage & Quality Audit

## Summary

Cross-referenced all source files in `lib/features/*/` and `lib/core/` against the test conventions in `AGENTS.md`. Found **3 missing test files**, **7 tests using Hive I/O directly** (violating `fixedStudentId` convention), **4 provider test files with only construction checks** (no behavioral assertions per the Provider Test Coverage Bar), **1 missing widget test**, and **6 stray test files in the project root**.

---

## BLOCKER

### B1. Source files with no corresponding test file

Per AGENTS.md, every source file must have a test file at the mapped path.

| Source file | Expected test location | Status |
|---|---|---|
| `lib/features/planner/services/action_planner.dart` | `test/features/planner/services/action_planner_test.dart` | **MISSING** |
| `lib/core/utils/study_utils.dart` | `test/core/utils/study_utils_test.dart` | **MISSING** |
| `lib/core/utils/id_generator.dart` | `test/core/utils/id_generator_test.dart` | **MISSING** |
| `lib/features/dashboard/presentation/widgets/workload_card.dart` | `test/features/dashboard/presentation/widgets/workload_card_test.dart` | **MISSING** |

**Rationale:** `action_planner.dart` is a core service in the planner feature used by `planner_service.dart`. `study_utils.dart` and `id_generator.dart` are utility modules that could contain bugs with no test safety net. `workload_card.dart` is a rendered UI component.

**Acceptance criteria:**
- Create `test/features/planner/services/action_planner_test.dart` with unit tests covering the public API
- Create `test/core/utils/study_utils_test.dart` with unit tests for each utility function
- Create `test/core/utils/id_generator_test.dart` with unit tests for each generator function
- Create `test/features/dashboard/presentation/widgets/workload_card_test.dart` with widget tests covering rendering and interaction

### B2. Tests using `StudentIdService()` directly (Hive I/O dependency)

AGENTS.md states: *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."* The following files construct `StudentIdService()` directly, creating a real Hive dependency in tests:

| Test file | Lines |
|---|---|
| `test/features/practice/providers/practice_providers_test.dart` | 91, 533, 549 |
| `test/features/practice/services/coverage_gaps_test.dart` | 797, 979, 996, 1351, 1384, 1397, 1405, 1411, 1431, 1449, 1459, 1476 |
| `test/features/practice/services/practice_session_service_test.dart` | 71, 206, 224 |
| `test/features/practice/services/exam_session_service_test.dart` | 61 |
| `test/features/practice/services/practice_data_service_test.dart` | 83, 98, 117, 131, 148, 161, 178, 193, 200, 221, 229, 236, 243, 250, 257, 274 |
| `test/core/services/cross_feature_integrator_test.dart` | 46 |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | 49 |

**Rationale:** `StudentIdService()` instantiates Hive-backed storage. In test environments this can cause stale box state, file lock errors, or silent failures when Hive isn't initialized. The `fixedStudentId` pattern avoids all I/O entirely.

**Acceptance criteria:**
- Replace every `StudentIdService()` construction in test files with `fixedStudentId: 'test-student'` or inject a fake/dummy student ID through constructor parameters
- Verify tests pass without a Hive environment
- The `student_id_service_test.dart` file is exempt since it must test the service itself

### B3. Stray test files in project root

The following test files exist in the project root (not under `test/`):

- `hive_init_test.dart`
- `hive_open_test.dart`
- `hive_sync_test.dart`
- `test_hive_widget_test.dart`
- `test_onboarding_minimal_test.dart`
- `debug2_test.dart`

**Rationale:** These files will be executed by `flutter test` and can cause confusing failures or CI noise. They lack the organizational structure of the test directory.

**Acceptance criteria:**
- Move each stray file into `test/` with a proper path, or delete if redundant
- Remove `debug2_test.dart` (appears to be a left-over debug file)

---

## MAJOR

### M1. Provider test files with no behavioral assertions

Per AGENTS.md Provider Test Coverage Bar: *"Every provider test file must include at least one behavioral assertion beyond construction checks (`isA<...>()` or `isNotNull`)."*

**`test/features/practice/providers/practice_providers_test.dart`** (551 lines)
- Contains 34 test cases, all of which only assert `isA<>` or `same()`
- The "dependency wiring" tests (lines 130–170) override a sub-provider but only verify the result `isA<PracticeDataService>()` — they never verify that the override actually changed behavior
- Lines 362–367 (`masteryRecorderProvider creates recorder with dependencies`), 383–388 (`readinessScorerProvider creates default scorer`), 425–430 (`examSessionServiceProvider creates service with dependencies`), 446–451 (`mistakeReviewServiceProvider creates service with dependencies`), 467–472 (`crossFeatureIntegratorProvider creates integrator with dependencies`) are pure `isA<>` checks with no behavioral assertion

**`test/features/dashboard/providers/dashboard_providers_test.dart`** (134 lines)
- Every test checks only `isA<>` or `same()`
- The "wiring" test at line 56 (`dashboardStudyProgressTrackerProvider is wired to dashboardAttemptRepositoryProvider`) overrides `dashboardAttemptRepositoryProvider` but only asserts `isA<StudyProgressTracker>()` — never verifies the fake was consumed by the tracker

**`test/features/mentor/providers/mentor_providers_test.dart`** (90 lines)
- Lines 30–41 and 56–67 override sub-providers but only check `isA<>` without proving the override propagated to behavior
- The `mentorModelIdProvider` fallback test at line 77 is a valid behavioral assertion (good), but the wiring tests lack behavioral verification

**`test/features/ingestion/providers/ingestion_providers_test.dart`** (275 lines)
- The "is wired" tests (lines 35, 212, 233) override a sub-provider but only verify `isA<DocumentExtractor>()` or `isA<ContentPipeline>()`
- The "passes llmService to DocumentExtractor" test (line 35) overrides `llmServiceProvider` but never confirms the fake service was actually passed into the extractor

**Rationale:** Construction-only tests give false confidence. They pass even if the provider wiring is completely broken (e.g., if a provider ignores its dependency and creates a default). Behavioral assertions catch real regressions.

**Acceptance criteria:**
- `practice_providers_test.dart`: Add at least one test per provider group that proves the override affects behavior (e.g., inject a fake that returns canned data and assert the downstream service produces that data)
- `dashboard_providers_test.dart`: For `dashboardStudyProgressTrackerProvider`, inject a fake tracker that returns known stats and verify the provider returns those exact stats
- `mentor_providers_test.dart`: For wiring tests, verify the overridden dependency is actually used by inspecting the result
- `ingestion_providers_test.dart`: For `llmServiceProvider` wiring, create a fake with a distinguishable config and verify it propagates to the built object

### M2. No error-state tests when services throw

The following service tests have **no test** for what happens when the underlying repository throws:

| Test file | Services tested | Error-state test missing |
|---|---|---|
| `test/features/planner/services/planner_service_test.dart` | `PlannerService` | No test for `loadExistingPlan` when repo throws |
| `test/features/lessons/services/lesson_service_test.dart` | `LessonService` | No test for repo failure in `getLessonsForStudent` returns error |
| `test/features/teaching/services/tutor_service_test.dart` | `TutorService` | No test for LLM service failure |
| `test/features/mentor/services/mentor_service_test.dart` | `MentorService` | Line 498 checks `throws`, but no coverage for graceful fallback paths |
| `test/features/practice/services/practice_session_service_test.dart` | `PracticeSessionService` | No test for repository failure during session creation |
| `test/features/practice/services/mastery_recorder_test.dart` | `MasteryRecorder` | No test for recording failure |
| `test/features/sessions/services/study_timer_service_test.dart` | `StudyTimerService` | Has error test at line 180, but coverage is inconsistent |
| `test/features/ingestion/services/content_pipeline_test.dart` | `ContentPipeline` | No test for LLM or repository failure during ingestion |

**Rationale:** Services that silently swallow errors or return empty results on failure can mask production bugs. Tests should verify the specific error-handling behavior — rethrow, return failure Result, return default value, etc.

**Acceptance criteria:**
- Each service test file should have at least one test that injects a failing fake dependency and asserts the service's error-handling contract (e.g., `throwsA`, `Result.failure`, empty list, etc.)

---

## MINOR

### m1. Unit test in presentation directory

`test/features/onboarding/presentation/onboarding_dialog_test.dart` (137 lines) is a pure unit test — it uses `group`/`test` (not `testWidgets`), imports no Flutter widgets, and tests an in-memory store class. Per AGENTS.md: *"Keep unit tests and widget tests in separate files."*

The companion file `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart` (548 lines) correctly uses `testWidgets` for UI tests.

**Rationale:** The unit test's location in `presentation/` is misleading. It doesn't test any presentation logic; it tests a local data store pattern. A developer looking for widget tests will find this file first and be confused.

**Acceptance criteria:**
- Rename or relocate `onboarding_dialog_test.dart` to a non-presentation path, or merge its coverage into an appropriate service/unit test location
- Ensure the file name clearly conveys it is not a widget test

### m2. Missing `NavigatorObserver` in widget tests that verify navigation

AGENTS.md says: *"Use `NavigatorObserver` for verifying navigation behavior."* Some widget tests do navigation verification without `NavigatorObserver`:

| Test file | Issue |
|---|---|
| `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart` | Lines 266–274 and 276–297 test navigation by checking `find.text('Subject Selection')` instead of `observer.pushedRoutes`. These pass only if the route destination happens to match the widget text. |
| `test/features/subjects/presentation/subject_detail_screen_test.dart` | Lines 455+ use NavigatorObserver but earlier tests may not |

**Acceptance criteria:**
- Audit all widget tests that call `Navigator.push` or `Navigator.pushNamed` and ensure their navigation assertions use `TestNavigatorObserver.pushedRoutes` rather than checking for destination widget presence

### m3. Widget test missing `pumpAndSettle` for async navigation

Several widget tests use `tester.pump()` after navigation events instead of `tester.pumpAndSettle()`, which can lead to flaky tests when routes have async initialization.

**Acceptance criteria:**
- Audit widget tests that trigger navigation and replace `pump()` with `pumpAndSettle()` after route transitions

### m4. `coverage_gaps_test.dart` naming and scope

`test/features/practice/services/coverage_gaps_test.dart` (1834 lines) tests multiple services (PracticeSessionService, ExamSessionService, etc.) in a single file. This deviates from the "one source file → one test file" convention.

**Acceptance criteria:**
- Split `coverage_gaps_test.dart` into per-service test files matching the standard convention, or rename it to clarify it is an integration-style test
