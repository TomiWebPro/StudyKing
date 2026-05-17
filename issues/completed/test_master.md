# Test Coverage & Quality Audit

**Audited:** 2026-05-17  
**Scope:** Full cross-reference of `lib/` source files vs `test/` files against AGENTS.md conventions

---

## BLOCKER

### B1. `onboarding_dialog_widget_test.dart` uses bare `NavigatorObserver()` — navigation verification is dead code

**File:** `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart:271`

**Problem:** The test instantiates `NavigatorObserver()` (the abstract base class with no-op implementations). No `didPush`/`didPop` calls are recorded, so subsequent assertions like `observer.pushedRoutes` or `observer.poppedRoutes` would always be empty. Navigation behaviour is never actually verified.

**Rationale:** The dialog performs navigation (routes to `AppRoutes.subjectSelection`, `quickGuide`, `apiConfig`), but the test cannot confirm any route was pushed.

**Acceptance criteria:**
- Replace bare `NavigatorObserver()` with `TestNavigatorObserver` from `test/helpers/navigator_observer_helper.dart`.
- Add at least one assertion per navigable action (e.g., `expect(observer.pushedRoutes, hasLength(1))` and verify the pushed route name matches the expected `AppRoutes` constant).

---

## MAJOR

### M1. `app_theme_test.dart` mixes unit and widget tests in the same file

**File:** `test/core/theme/app_theme_test.dart`

**Problem:** 28 `test()` calls (pure logic: `createTextTheme`, theme configuration) and 12+ `testWidgets()` calls (UI rendering: scaffold, app bar, card, button, FAB, navigation bar) are in the same file. AGENTS.md mandates: *"Keep unit tests and widget tests in separate files — never mix them in the same file."*

**Rationale:** Separated files are faster to run (widget tests require `flutter_test`, unit tests don't) and prevent confusion between test categories.

**Acceptance criteria:**
- Move all `testWidgets` blocks to `test/core/theme/app_theme_widget_test.dart`.
- Keep all pure `test(...)` blocks in the existing `app_theme_test.dart`.
- Verify both files pass independently.

### M2. 20+ test files depend on real Hive I/O instead of fakes / `fixedStudentId`

**Affected files (representative sample):**

| File | Hive dependency |
|---|---|
| `test/features/onboarding/presentation/onboarding_dialog_test.dart` | `Hive.init()`, reads `HiveBoxNames.settings` |
| `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart` | `Hive.init()`, temp dir per run |
| `test/features/dashboard/providers/dashboard_layout_providers_test.dart` | `Hive.init()`, `Hive.openBox('dashboard_layout_prefs')` |
| `test/features/dashboard/providers/dashboard_data_providers_test.dart` | `Hive.init()`, `Hive.openBox('dashboard_layout_prefs')` |
| `test/features/sessions/data/repositories/session_repository_test.dart` | `Hive.init()`, `Hive.registerAdapter()`, `Hive.openBox()` |
| `test/features/sessions/services/study_timer_service_test.dart` | `Hive.init()`, `Hive.openBox('settings')` |
| `test/features/ingestion/presentation/upload_screen_test.dart` | `Hive.init()`, `Hive.registerAdapter()`, `Hive.openBox()` |
| `test/features/focus_mode/presentation/focus_timer_screen_test.dart` | `Hive.init()` |
| `test/features/mentor/services/mentor_service_test.dart` | `Hive.init()` |
| `test/features/mentor/presentation/mentor_screen_test.dart` | `Hive.init()`, opens 'settings' box |
| `test/features/teaching/data/repositories/tutor_session_repository_test.dart` | `Hive.init()`, real Hive integration |
| `test/core/services/engagement_scheduler_test.dart` | `Hive.init()` |
| `test/features/subjects/data/repositories/topic_repository_test.dart` | `Hive.init()`, real "topics" box |
| `test/features/subjects/data/repositories/subject_repository_test.dart` | `Hive.init()` |
| `test/features/practice/presentation/screens/practice_session_screen_test.dart` | `Hive.init()` for session pop tests |
| `test/features/practice/presentation/screens/exam_session_screen_test.dart` | Extends `StudentIdService` instead of using `fixedStudentId` |

**Problem:** AGENTS.md says: *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."* Real Hive I/O introduces:
- Temp directory management boilerplate (`setUp`/`tearDown`)
- Risk of cross-test state pollution when run together
- Slower test execution
- False negatives when Hive type adapters aren't registered

**Rationale:** A hand-written fake repository backed by in-memory `List`/`Map` is faster, deterministic, and requires no disk I/O. Widget tests that need a student ID should inject a `fixedStudentId` string constant rather than opening a Hive box.

**Acceptance criteria:**
- Widget tests using `StudentIdService` → inject `fixedStudentId` string constant directly.
- Repository tests using `Hive.init()` + real boxes → replace with in-memory fake implementations (e.g., `_FakeSessionRepository` pattern already in `session_providers_test.dart`).
- Service tests that only read config (e.g., `mentor_screen_test.dart` opens 'settings' box) → inject config values via provider overrides instead.
- No test file should call `Hive.init()` or `Hive.openBox()` unless it is specifically testing Hive adapter serialization.

### M3. No cross-feature integration tests exist

**Problem:** There is only `test/integration/e2e_test.dart`, which tests a handful of features (planner, lessons, practice, teaching) in a single scenario. There are zero tests verifying that feature boundaries compose correctly — e.g., that the dashboard correctly reads planner adherence data, or that the mentor feature's nudges integrate with the session service.

**Affected integration paths (untested):**
- Dashboard consuming planner `plan_adherence` data → no test that `dashboardAdherenceDataProvider` correctly reads from a faked `PlanAdherenceRepository`
- Mentor nudges engaging with session data → no test that `MentorService.checkWellbeingAndGenerateNudges()` correctly queries a faked `SessionRepository`
- Practice calling back to teaching (mistake review re-teach) → no cross-provider wiring test
- Planner creating lessons → teaching session flow → no end-to-end test

**Rationale:** Without cross-feature tests, regressions that span boundaries (e.g., a change in planner adherence calculation breaking the dashboard's adherence card) will go undetected.

**Acceptance criteria:**
- Create `test/integration/` test files (at least 3) covering the untested paths above.
- Each integration test should use `ProviderContainer` with hand-written fakes for all repositories, wiring real feature providers together and verifying the composed output.
- At minimum cover:
  1. Dashboard + Planner (adherence data flows correctly)
  2. Mentor + Sessions (nudge generation uses session data)
  3. Practice + Teaching (mistake review produces a re-teach request)

### M4. 69 "Mock"‑named classes are actually hand-written fakes — naming inconsistency

**Problem:** AGENTS.md says: *"Use hand-written fake classes (not `mockito`/`mocktail`)."* But the codebase has 69 classes named `Mock*` or `_Mock*` that are simply hand-written test doubles (extending real classes, manually overriding methods). Examples:

| File | Class |
|---|---|
| `test/features/planner/services/planner_service_test.dart` | `_MockMasteryGraphRepository` |
| `test/features/ingestion/services/content_pipeline_test.dart` | `_MockLlmService` |
| `test/features/lessons/data/repositories/lesson_repository_test.dart` | `_MockLessonRepository` |
| `test/core/services/mastery_graph_service_test.dart` | `MockMasteryGraphRepository` |

**Rationale:** Using `Mock` suggests a generated mocking framework (mockito/mocktail). New contributors may be confused about whether these are auto-generated or hand-written. The convention in `test/helpers/fakes.dart` uses `Fake*` — all test doubles should follow this.

**Acceptance criteria:**
- Rename all `Mock*` / `_Mock*` hand-written test doubles to `Fake*` / `_Fake*` or `Stub*` / `_Stub*`.
- Ensure none import from `package:mockito/` or `package:mocktail/`.

### M5. Two LLM service test files are at the wrong directory level

**Files:**
- `test/core/services/llm_embeddings_service_test.dart` → should be `test/core/services/llm/llm_embeddings_service_test.dart`
- `test/core/services/llm_model_service_test.dart` → should be `test/core/services/llm/llm_model_service_test.dart`

**Problem:** The source file `lib/core/services/llm/llm_embeddings_service.dart` lives in `llm/` subdirectory, so the test should mirror that path per AGENTS.md convention.

**Acceptance criteria:**
- Move both test files to `test/core/services/llm/` subdirectory.
- Update any relative imports if needed.

---

## MINOR

### m1. 6+ files define inline `NavigatorObserver` instead of using the shared helper

**Affected files:**

| File | Observer class |
|---|---|
| `test/features/practice/presentation/screens/practice_screen_test.dart` | `_TestNavigatorObserver` (inline) |
| `test/features/subjects/presentation/widgets/subject_lessons_tab_test.dart` | `_TestNavigatorObserver` (inline) |
| `test/features/subjects/presentation/subject_detail_screen_test.dart` | `_TestNavigatorObserver` (inline) |
| `test/features/quickguide/presentation/widgets/mode_navigation_widget_test.dart` | `_TestNavigatorObserver` (inline) |
| `test/features/planner/presentation/planner_screen_test.dart` | `_TestNavigatorObserver` (inline) |
| `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` | `_NavigatorObserverMock` (inline) |

**Problem:** `test/helpers/navigator_observer_helper.dart` already provides a shared `TestNavigatorObserver` with `pushedRoutes`, `poppedRoutes`, and `reset()`. The inline versions duplicate this (varying by whether they include a `onPush` callback) and fragment the observer logic.

**Rationale:** DRY principle — one shared implementation reduces maintenance burden and ensures consistent behavior across all navigation tests.

**Acceptance criteria:**
- Replace all inline `_TestNavigatorObserver`/`_NavigatorObserverMock` definitions with `TestNavigatorObserver` from `test/helpers/navigator_observer_helper.dart`.
- Remove the obsolete inline class definitions.

### m2. `coverage_gaps_test.dart` is 1834 lines — should be split

**File:** `test/features/practice/services/coverage_gaps_test.dart`

**Problem:** This single file tests 12+ services (`DifficultyAdapter`, `ExamSessionService`, `MasteryRecorder`, `MistakeReviewService`, `PracticeDataService`, `PracticeSessionService`, `ReadinessScorer`, `SpacedRepetitionEngine`, `SpacedRepetitionService`, `AttemptRepository`, `QuestionMasteryStateRepository`, `SessionRepository`) with 10+ fake classes and dozens of test cases. It mixes repository tests and service tests.

**Rationale:** Giant test files are hard to navigate, slow to run, and cause merge conflicts. Each service should have its own test file, matching the source file structure. Most of these services already have dedicated test files in `test/features/practice/services/` — this file appears to add "coverage gap" tests. The new tests should be merged into the existing dedicated files or split into appropriately scoped files.

**Acceptance criteria:**
- Distribute the test cases from `coverage_gaps_test.dart` into the pre-existing dedicated test files (e.g., `difficulty_adapter_test.dart`, `exam_session_service_test.dart`, etc.).
- If a test truly covers multiple services, move it to `test/features/practice/services/integration/` or scope it to the appropriate single-service file.
- Delete `coverage_gaps_test.dart` after distribution.

### m3. Duplicate fake classes defined inline across files

**Problem:** Some fake classes are re-defined in multiple test files instead of being shared via `test/helpers/fakes.dart`:

| Fake class | Defined in |
|---|---|
| `FakeSessionRepository` | `test/features/lessons/providers/lesson_providers_test.dart`, `test/features/planner/providers/planner_providers_test.dart`, `test/features/dashboard/providers/dashboard_data_providers_test.dart`, `test/features/sessions/providers/session_providers_test.dart`, and more |
| `_FakeAttemptRepository` | `test/features/dashboard/providers/dashboard_providers_test.dart`, `test/features/dashboard/providers/dashboard_data_providers_test.dart` |
| `FakeMasteryGraphService` | `test/features/mentor/services/mentor_service_test.dart`, `test/features/dashboard/presentation/dashboard_screen_test.dart`, `test/helpers/fakes.dart` |

**Rationale:** Duplicated fakes drift apart as teams add behavior to one copy but not another, leading to inconsistent test results.

**Acceptance criteria:**
- Audit all `Fake*` / `_Fake*` / `Mock*` / `_Mock*` classes across test files.
- Consolidate common fakes into `test/helpers/fakes.dart`.
- Keep only domain-specific fakes inline (e.g., a fake with a very specific error-throwing mode used in only one test file).

### m4. Barrel/export tests lack behavioral assertions

**Affected files (barrel-only tests with only `isNotNull`/`isA<>` checks):**

- `test/features/features_barrel_test.dart`
- `test/features/planner/planner_test.dart`
- `test/features/planner/data/planner_data_test.dart`
- `test/features/mentor/mentor_test.dart`
- `test/features/practice/practice_test.dart`
- `test/features/practice/data/practice_data_test.dart`
- `test/features/settings/settings_test.dart`
- `test/features/subjects/subjects_test.dart`
- `test/features/subjects/data/subjects_data_test.dart`
- `test/features/onboarding/onboarding_test.dart`
- `test/features/ingestion/ingestion_test.dart`
- `test/features/lessons/lessons_test.dart`
- `test/features/teaching/teaching_test.dart`
- `test/features/quickguide/quickguide_test.dart`
- `test/core/core_test.dart`
- `test/core/data/data_test.dart`
- `test/core/widgets/widgets_test.dart`
- `test/core/utils/utils_test.dart`

**Problem:** While barrel tests serve a legitimate purpose (validate export integrity), the AGENTS.md *Provider Test Coverage Bar* says: *"Every provider test file must include at least one behavioral assertion beyond construction checks."* These barrel files aren't provider tests, so they technically don't violate the rule. However, they provide minimal value and could be enhanced.

**Acceptance criteria:**
- Consider merging each barrel test into a single `test/features/<name>/exports_test.dart` to reduce overhead.
- No change strictly required — but document that barrel files are exempt from the behavioral-assertion rule, and ensure no provider-specific barrel file lacks behavioral coverage.

### m5. `e2e_test.dart` has low coverage density

**File:** `test/integration/e2e_test.dart` (337 lines)

**Problem:** The single integration test file covers only a narrow scenario (planner → lessons → practice → teaching). It doesn't test dashboard, focus mode, sessions, settings, or mentor flows. Many fake classes in the test are defined inline rather than from `test/helpers/fakes.dart`.

**Acceptance criteria:**
- Expand e2e coverage to include at least dashboard + planner adherence and mentor + session interactions.
- Prefer `Fake*` classes from `test/helpers/fakes.dart` when available (e.g., `FakePlanRepository`, `FakeMasteryGraphRepository`).

### m6. `planner_providers_test.dart` overrides each dependency individually instead of using the service-level override

**File:** `test/features/planner/providers/planner_providers_test.dart`

**Problem:** This file overrides 7+ individual repositories (`_MockPlanRepository`, `_MockMasteryRepository`, `_MockTopicRepository`, etc.) directly in the provider container. AGENTS.md says to use `plannerServiceProvider.overrideWithValue` with a single `FakePlannerService` (already defined in `test/helpers/fakes.dart`) that internally wraps fake repos. This would reduce boilerplate and better match the documented convention.

**Acceptance criteria:**
- Refactor `planner_providers_test.dart` to use `FakePlannerService` from `test/helpers/fakes.dart` instead of overriding 7 individual repositories.
- Only override specific sub-dependencies when testing provider-level error propagation.

---

## Summary

| Severity | Count | Issues |
|---|---|---|
| BLOCKER | 1 | B1 — dead navigation verification in onboarding widget test |
| MAJOR | 5 | M1 unit/widget mixing, M2 Hive I/O, M3 missing integration tests, M4 Mock naming, M5 LLM test location |
| MINOR | 6 | m1 duplicate observers, m2 giant file, m3 duplicate fakes, m4 barrel tests, m5 e2e density, m6 planner overrides |
| **Total** | **12** | |
