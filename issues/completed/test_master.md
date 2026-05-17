# Test Master: Comprehensive Test Coverage Audit

**Generated:** 2026-05-17  
**Scope:** All `lib/` source files → AGENTS.md test mapping, behavioral coverage, error-state coverage, pattern compliance

---

## MAJOR

### M-1: 10 Source Files With No Corresponding Test File (AGENTS.md Violation)

**Rationale:** AGENTS.md mandates "Every source file must have a corresponding test file." These are completely uncovered — regressions here go undetected.

| Source | Missing Test |
|---|---|
| `lib/core/constants/security_config.dart` | `test/core/constants/security_config_test.dart` |
| `lib/core/data/session_adapter.dart` | `test/core/data/session_adapter_test.dart` |
| `lib/core/services/topic_readiness_service.dart` | `test/core/services/topic_readiness_service_test.dart` |
| `lib/core/services/data_backup_service.dart` | `test/core/services/data_backup_service_test.dart` |
| `lib/core/services/llm/llm_chat_service.dart` | `test/core/services/llm/llm_chat_service_test.dart` |
| `lib/core/theme/llm_task_status.dart` | `test/core/theme/llm_task_status_test.dart` |
| `lib/features/dashboard/services/dashboard_service.dart` | `test/features/dashboard/services/dashboard_service_test.dart` |
| `lib/core/utils/utils.dart` (barrel) | `test/core/utils/utils_test.dart` |
| `lib/core/widgets/widgets.dart` (barrel) | `test/core/widgets/widgets_test.dart` |
| `lib/core/core.dart` (barrel) | `test/core/core_test.dart` |

**Acceptance Criteria:**
- Each source file above has a test file at the expected path from AGENTS.md.
- Non-barrel tests contain at least one behavioral assertion.
- Barrel tests verify at least that every re-exported symbol resolves.

---

### M-2: Provider Test Files With Only Construction Checks (AGENTS.md Provider Bar Violation)

**Rationale:** AGENTS.md says "Every provider test file must include at least one **behavioral assertion** beyond construction checks (`isA<...>()` or `isNotNull`)." These files barely pass or fail that bar.

#### `test/features/mentor/providers/mentor_providers_test.dart`
- **4 tests total.** 2 are pure `isA<...>()` construction checks (lines 15, 23).
- 1 override-wiring test (line 26) — the only behavioral assertion.
- 1 default-value test (line 39) — acceptable but minimal.
- **No error-state tests.** A broken `AttemptRepository` or `PendingActionRepository` constructor would pass silently.
- **Acceptance:** Add wiring-verification tests for `mentorPendingActionRepoProvider` and `mentorProgressTrackerProvider`. Add a test exercising fallback or error behavior in `mentorModelIdProvider`.

#### `test/features/teaching/providers/teaching_providers_test.dart`
- **7 tests:** only the `teachingModelIdProvider` group (2 tests) has behavioral assertions.
- 5 remaining tests are pure `isA<...>()` construction checks for `ExerciseEvaluator`, `VoiceController`, `SystemClock`, `TutorService`, `ConversationPromptSet`.
- **No error-state tests.**
- **Acceptance:** Convert at least 3 of the 5 construction-only tests to verify wiring via overrides (e.g., override a dependency and verify the constructed instance delegates to it).

#### `test/features/lessons/providers/lesson_providers_test.dart`
- **13 tests:** 10 are pure `isA<...>()` construction checks.
- 1 singleton test, 2 wiring tests, 1 smoke test qualify as behavioral — barely.
- **No error-state tests.**
- **Acceptance:** Add at least 2 behavioral tests for `lessonServiceProvider` (e.g., override `lessonRepositoryProvider` with a fake, call a service method, verify the fake was invoked).

#### `test/features/focus_mode/providers/focus_mode_providers_test.dart`
- **3 tests total** (43-line file). 1 construction check, 1 wiring check, 1 smoke test.
- **No error-state tests.**
- **Acceptance:** Add tests for `studyTimerServiceProvider` fallback/error behavior. Add wiring verification for `focusTimerProvider`.

#### `test/features/ingestion/providers/ingestion_providers_test.dart`
- Passes the bar (has override and singleton tests) but 80% of tests are construction-only.
- **No error-state tests.** `contentPipelineProvider` or `documentExtractorProvider` could fail at construction and not be caught.
- **Acceptance:** Add error-path tests for at least `contentPipelineProvider` and `documentExtractorProvider`.

---

### M-3: Missing Error-State Tests Across Provider and Service Tests

**Rationale:** The Provider Test Coverage Bar explicitly requires "Testing that error states are handled gracefully." Only 2 of 11 provider test files (`planner_providers_test.dart`, `settings_controller_test.dart`) test error states. In features, only `mentor_service_test.dart` (1 test), `lesson_repository_test.dart` (1), `dashboard_data_providers_test.dart` (1), `subjects/providers/topic_repository_provider_test.dart` (1), and `sessions/study_timer_service_test.dart` (2) test `throwsException`.

**Affected files (not exhaustive, representative list):**
- `test/core/providers/app_providers_test.dart`
- `test/core/providers/llm_providers_test.dart`
- `test/features/mentor/providers/mentor_providers_test.dart`
- `test/features/teaching/providers/teaching_providers_test.dart`
- `test/features/teaching/services/tutor_service_test.dart`
- `test/features/teaching/services/conversation_manager_test.dart`
- `test/features/planner/data/repositories/plan_repository_test.dart`
- `test/features/questions/data/repositories/question_repository_test.dart`
- `test/features/questions/services/question_service_test.dart` (if exists)
- `test/features/practice/providers/practice_providers_test.dart`
- `test/core/services/mastery_graph_service_test.dart`
- `test/core/services/mastery_calculation_service_test.dart`
- `test/core/services/conversation_memory_test.dart`

**Acceptance Criteria:**
- Every provider test file has at least one test where a dependency throws and the provider handles it (returns error state, falls back, re-throws with context).
- Every service test file tests the failure path for each public method that can fail.

---

### M-4: Tests Using `StudentIdService` Singleton Instead of `fixedStudentId` (AGENTS.md Violation)

**Rationale:** AGENTS.md says "Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies." Many non-widget tests also use `StudentIdService()` directly, dragging in Hive I/O.

| File | Line(s) | Issue |
|---|---|---|
| `test/features/practice/providers/practice_providers_test.dart` | 91, 533, 549 | Uses `StudentIdService()` constructor, triggers Hive `openBox` |
| `test/features/practice/services/practice_session_service_test.dart` | 71, 206, 224 | Uses `StudentIdService()` |
| `test/features/practice/services/exam_session_service_test.dart` | 61 | Uses `StudentIdService()` |
| `test/features/practice/services/practice_data_service_test.dart` | 83, 98, 117, 131, 148, 161, 178, 193, 200, 221, 229, 236, 243, 250, 257, 274 | Heavy `StudentIdService()` usage + `.setStudentId()` calls |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | 49 | `StudentIdService().setStudentId()` |
| `test/core/services/cross_feature_integrator_test.dart` | 46 | `StudentIdService()` |
| `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` | 327 | `fixedStudentId` via constructor — GOOD pattern, but needs replication |

**Acceptance Criteria:**
- All `StudentIdService()` constructor calls replaced with `fixedStudentId` parameter.
- Tests that cannot use `fixedStudentId` (e.g., they test `StudentIdService` itself) must use a `FakeStudentIdService` that extends `StudentIdService` and overrides Hive-dependent methods.

---

### M-5: `tab_navigator_test.dart` Tests Navigation Without `NavigatorObserver`

**Rationale:** AGENTS.md says "Use `NavigatorObserver` for verifying navigation behavior." The `tab_navigator_test.dart` tests `Navigator.pushNamed` and `Navigator.pop` but relies on `key.currentState?.canPop()` and widget lookups instead of `NavigatorObserver`.

**File:** `test/core/routes/tab_navigator_test.dart`
- Line 44: tests push via widget-finding
- Line 70: tests pop via `canPop()`

**Acceptance Criteria:**
- Inject a `NavigatorObserver` subclass into the `MaterialApp`.
- Assert `.pushedRoute` and `.poppedRoute` observations directly instead of widget lookups.

---

### M-6: Widespread Hive I/O Dependencies in Repository/Provider Tests

**Rationale:** 27+ test files perform real Hive I/O (`Hive.init`, `registerAdapter`, `openBox`, `deleteBoxFromDisk`). This makes tests slow, order-dependent, and fragile (temp directory cleanup failures cascade). Repository tests inherently need Hive, but the problem is:
1. **No separation** between unit and integration tests for repositories.
2. **Provider tests** that should be unit tests also `Hive.init()` (e.g., `planner_providers_test.dart` inits 4 times).
3. **`dashboard_layout_providers_test.dart`** reads/writes real Hive boxes for preferences.

**Representative files:**
- `test/features/planner/providers/planner_providers_test.dart` — 4 `Hive.init` calls
- `test/features/dashboard/providers/dashboard_layout_providers_test.dart` — full Hive CRUD
- `test/features/planner/data/repositories/*_test.dart` — all 6 do real Hive
- `test/features/practice/data/repositories/*_test.dart` — 7 do real Hive
- `test/features/lessons/data/repositories/lesson_repository_test.dart`
- `test/features/teaching/data/repositories/*_test.dart`

**Acceptance Criteria:**
- Repository tests: Acceptable as integration tests (they test persistence). Move to `test/integration/repositories/` or annotate clearly.
- Provider tests: Inject fakes for Hive-backed dependencies instead of real `Hive.init()`.
- `dashboard_layout_providers_test.dart`: Use an in-memory Hive mock or test the notifier/model logic separately from persistence logic.

---

### M-7: `widget_test.dart` (Root) Is Vestigial

**File:** `test/widget_test.dart`

Contains auto-generated Flutter template code (`MyApp` widget test). This was never updated and provides zero meaningful coverage. It can cause confusion during `flutter test` runs.

**Acceptance:** Delete `test/widget_test.dart`.

---

## MINOR

### m-1: Inconsistent NavigatorObserver Class Names

Some tests define inline `NavigatorObserver` subclasses with underscores, others import from helpers:
- `_TestNavigatorObserver` — `planner_screen_test.dart`, `mode_navigation_widget_test.dart`, `subject_detail_screen_test.dart`, `practice_screen_test.dart`
- `_NavigatorObserverMock` — `lesson_booking_sheet_test.dart`
- `TestNavigatorObserver` — imported in `quick_guide_screen_test.dart`, `practice_session_screen_test.dart`

**Rationale:** No shared `TestNavigatorObserver` in `test/helpers/`. Each file re-implements the same pattern.

**Acceptance:** Extract a shared `TestNavigatorObserver` to `test/helpers/navigator_observer_helper.dart` and reference it from all files.

---

### m-2: `questions_test.dart` Barrel Test Is All `isA<Type>()`

**Rationale:** While barrel tests are inherently minimal-registry checks, 14 tests all using `expect(X, isA<Type>())` means any rename silently succeeds (the old class name still resolves as a Type). A smoke test that actually constructs one instance would catch linker errors.

**File:** `test/features/questions/questions_test.dart`

**Acceptance:** Add at least one construction smoke test (e.g., `expect(QuestionRepository(), isA<QuestionRepository>())`) per type that has a public constructor.

---

### m-3: Barrel Files Missing Smoke Tests Entirely

Some feature barrel files have no test verifying the imports resolve:
- `test/core/utils/utils_test.dart` — MISSING (see M-1)
- `test/core/widgets/widgets_test.dart` — MISSING (see M-1)
- `test/core/core_test.dart` — MISSING (see M-1)

While these are covered by M-1 as missing files, the affected tests that do exist for other barrels (e.g., `planner_test.dart`, `teacher_test.dart`) vary wildly in rigor — some check one export, others check all.

**Acceptance:** Every barrel test must check at least one re-exported symbol from each sub-module to catch broken imports.

---

### m-4: `test/helpers/fakes.dart` Underused

**File:** `test/helpers/fakes.dart`

Only 2 files reference this shared helper. The remaining 100+ test files define their fakes inline, leading to duplication. In particular:
- `FakePlannerService` patterns appear in 4+ test files with near-identical implementations.
- `FakeMasteryGraphService` patterns appear in 3+ files.

**Rationale:** AGENTS.md specifies shared fake names (`FakePlannerService`, `FakeMasteryGraphService`, etc.) but these are not centralized.

**Acceptance:** Extract commonly-used fakes into `test/helpers/fakes.dart` and reference them from consuming tests.

---

## Summary

| Severity | Count | Key Areas |
|---|---|---|
| **MAJOR** | 7 | Missing tests (10 files), provider coverage gaps (5 files), missing error-state tests (~15 files), `StudentIdService` instead of `fixedStudentId` (7+ files), missing `NavigatorObserver` (1 file), Hive I/O in unit tests (27+ files), vestigial `widget_test.dart` |
| **MINOR** | 4 | Inconsistent `NavigatorObserver` naming, barrel test rigor, barrel coverage gaps, fakes underused |
