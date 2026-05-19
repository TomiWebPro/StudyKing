# Test Coverage Audit — Findings & Remediation Plan

**Generated:** 2026-05-19
**Scope:** Full codebase cross-referenced against `AGENTS.md` test conventions and quality bars.

---

## CRITICAL

### C1. 35+ test files use real Hive I/O instead of in-memory fakes

**Context:** Per `AGENTS.md`, "[Use] hand-written fake classes (not `mockito`/`mocktail`) for dependency stubbing". The project does NOT use mockito/mocktail (good), but ~35 test files bypass the fake convention by calling `Hive.init()` + `registerAdapter()` + `openBox()` with a real temp directory. This produces slow, flaky, non-parallelizable tests that leave debris on disk.

**Affected files (representative sample — full list in analysis):**

| File | Est. lines |
|---|---|
| `test/features/sessions/data/repositories/session_repository_hive_test.dart` | ~1400 |
| `test/features/planner/providers/planner_providers_test.dart` | ~1538 |
| `test/features/planner/services/planner_service_test.dart` | ~1212 |
| `test/features/practice/services/coverage_gaps_integration_test.dart` | ~1863 |
| `test/features/subjects/data/repositories/subject_repository_test.dart` | ~1000 |
| `test/features/subjects/data/repositories/topic_repository_test.dart` | ~600 |
| `test/features/practice/data/repositories/mastery_graph_repository_test.dart` | ~550 |
| `test/features/teaching/data/repositories/conversation_repository_test.dart` | ~460 |
| `test/features/ingestion/data/repositories/source_repository_test.dart` | ~400 |
| `test/core/services/plan_adherence_orchestrator_test.dart` | ~200+ |
| `test/core/services/study_progress_tracker_test.dart` | ~200+ |
| `test/core/data/repository_test.dart` | ~160 |
| `test/features/dashboard/data/repositories/badge_repository_test.dart` | ~320 |
| `test/features/practice/data/repositories/mastery_state_repository_test.dart` | ~350 |
| `test/features/planner/data/repositories/plan_repository_test.dart` | ~300 |
| ~20 more planner/practice/sessions repo tests | 200-550 each |

Plus the following test files that also call `Hive.init`:
- `test/features/sessions/services/session_migration_service_test.dart`
- `test/features/subjects/providers/subjects_repository_provider_test.dart`
- `test/features/subjects/providers/topic_repository_provider_test.dart`
- `test/core/data/database_migration_test.dart`
- `test/core/data/hive_initializer_test.dart` (acceptable — tests the initializer itself)
- `test/core/services/student_id_service_test.dart` (acceptable — tests the Hive-backed service)
- `test/main_screen_test.dart`
- `test/features/practice/presentation/screens/practice_screen_additional_test.dart`
- `test/features/practice/presentation/screens/practice_session_screen_additional_test.dart`

**Rationale:** Real Hive I/O couples tests to disk. Concurrent test runs collide on temp directories. Tests are ~10-50x slower than in-memory fakes. The `settings_repository_test.dart` + `settings_repository_test_helper.dart` pattern (abstract interface + `InMemorySettingsRepository` + parameterized shared tests) is the proven template to follow.

**Acceptance criteria:**
- Every repository test that currently calls `Hive.init()` is migrated to a hand-written in-memory fake (e.g., `InMemoryXxxRepository` implementing the same abstract interface).
- The real-Hive integration tests are moved to a separate `_hive_test.dart` suffix file (if kept at all) or eliminated.
- All migrated tests pass without a Hive initialization call.
- Parallel test runs (`dart test --concurrency=4`) complete without collisions.

---

### C2. 6 service test files missing error-state coverage (gaps in exception/failure testing)

**Context:** Per `AGENTS.md`, tests must cover "what happens when a service throws". Several service test files only test happy paths.

**Affected files & specific gaps:**

| File | Missing error paths |
|---|---|
| `test/features/practice/services/difficulty_controller_test.dart` | No tests for exception handling in `recordResult` (e.g., invalid state, extreme threshold values). Pure logic only (clamping, streaks, reset). |
| `test/features/onboarding/services/onboarding_service_test.dart` | Storage throwing during read/write is not tested. Malformed persisted data (corrupt JSON) not tested. |
| `test/features/llm_tasks/services/llm_task_service_test.dart` | No tasks are actually created/run in tests. No failure paths for task execution or listener errors. Service is very thin; real error coverage may be in `LlmTaskManager` tests (check). |
| `test/features/practice/services/readiness_scorer_test.dart` | Tests scoring with empty/default data but no exception or `Result.failure` propagation when `scoreQuestions` encounters unexpected null maps. |
| `test/features/practice/services/mistake_review_service_test.dart` | Repository throwing during `getByStudent`, `getByQuestion`, or `getByStudentAndSubject` is not tested. (Partially covered by integration test.) |
| `test/features/practice/services/exam_session_service_test.dart` | `startExam` failure (session save fails), timer-related exceptions, `finishExam` on save failure are not tested. (Partially covered by integration test.) |

**Rationale:** Missing error coverage means regressions in failure paths go undetected. These are the services closest to production data paths.

**Acceptance criteria:**
- Each file listed above gains at least one `group` of tests simulating a dependency failure (exception from repo/LLM/storage).
- Tests verify that the service returns `Result.failure` or throws a meaningful exception, and that the caller can handle it gracefully.
- Edge cases (corrupt data, null maps, extreme values) are explicitly covered.

---

## MAJOR

### M1. `ExamSessionScreen` has zero test coverage

| Source file | Expected test | Status |
|---|---|---|
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | `test/features/practice/presentation/screens/exam_session_screen_test.dart` | **MISSING** |

**Context:** The `ExamSessionScreen` is a user-facing screen for timed exam-mode practice sessions. It has no widget test and no unit test anywhere.

**Rationale:** This is a navigation target from the practice mode sheet. Any regression (wrong rendering, broken timer, incorrect result display) would ship undetected.

**Acceptance criteria:**
- A widget test file `test/features/practice/presentation/screens/exam_session_screen_test.dart` exists.
- Tests cover: screen renders with exam config, timer display renders, answer submission workflow, navigation to results screen (verified via `NavigatorObserver`).
- A corresponding screen test for `exam_session_screen.dart` barrel export is added.

---

### M2. `SessionRepository` has no standalone unit test (only Hive-backed test)

| Source file | Expected test | Actual test |
|---|---|---|
| `lib/features/sessions/data/repositories/session_repository.dart` | `test/features/sessions/data/repositories/session_repository_test.dart` | `test/features/sessions/data/repositories/session_repository_hive_test.dart` (Hive I/O only) |

**Context:** The `session_repository_hive_test.dart` (~1400 lines) tests the repository through real Hive I/O. There is no test file that tests the repository logic with an in-memory fake.

**Rationale:** Hive-backed tests are slow and brittle. The business logic of `SessionRepository` (query construction, sorting, filtering, date-range logic) should be unit-testable against a fake backend.

**Acceptance criteria:**
- A test file `test/features/sessions/data/repositories/session_repository_test.dart` is created.
- It injects an in-memory fake (no `Hive.init()`).
- Tests cover: `getAll` (empty, seeded, sorted), `getByDate` (single, range, no results, boundaries), error propagation on store failure.
- The existing `session_repository_hive_test.dart` is either removed or renamed to `session_repository_integration_test.dart` and marked as slow.

---

### M3. `TeachingProviders` test has heavy construction-check smell

**File:** `test/features/teaching/providers/teaching_providers_test.dart`

**Context:** This file has many tests that only verify `isA<...>()` after an override — pattern:
```dart
test('...', () {
  final container = _createContainer(overrides: [...]);
  expect(container.read(someProvider), isA<ExpectedType>());
});
```
These tests verify the override compiles and returns the right type, but don't assert any _behavior_ (no method calls, no state changes, no error paths).

**Rationale:** The `AGENTS.md` Provider Test Coverage Bar requires "at least one behavioral assertion beyond construction checks". Several tests in this file technically pass because they have some error-state and wiring tests, but ~40% of the test body is construction-only.

**Acceptance criteria:**
- Every test group has at least one behavioral assertion: either method call output verification, error propagation, or fallback logic.
- Construction-only tests (`isA<...>`) are either removed or merged into a single barrel test.

---

### M4. `study_progress_provider_test.dart` singleton test barely meets the bar

**File:** `test/core/providers/study_progress_provider_test.dart`

**Context:** This file has 4 tests: one `isA<...>` (construction), one `isA<...>` after null-l10n fallback, one singleton check (`same()`), and one after override. The singleton test (`expect(tracker1, same(tracker2))`) qualifies as a behavioral assertion per AGENTS.md, which is the minimum.

**Rationale:** While it technically complies, the file has zero error-state tests and no dependency-wiring verification (no fake repo injected to verify it's used downstream). The fallback test only checks the return type, not the fallback behavior.

**Acceptance criteria:**
- At least one test injects a fake `StudyProgressTracker` dependency and verifies that the provider uses it (e.g., calling a method on the fake and checking the result).
- At least one test verifies error propagation when the tracker's upstream repository throws.

---

### M5. Missing integration tests for key cross-feature flows

**Existing integration tests (10 + 1 e2e):**
| File | Coverage |
|---|---|
| `test/integration/dashboard_planner_integration_test.dart` | Dashboard + Planner |
| `test/integration/settings_llm_integration_test.dart` | Settings + LLM |
| `test/integration/focus_mode_sessions_integration_test.dart` | Focus Mode + Sessions |
| `test/integration/planner_mentor_integration_test.dart` | Planner + Mentor |
| `test/integration/ingestion_lessons_integration_test.dart` | Ingestion + Lessons |
| `test/integration/mentor_sessions_integration_test.dart` | Mentor + Sessions |
| `test/integration/practice_teaching_integration_test.dart` | Practice + Teaching |
| `test/integration/teaching_practice_integration_test.dart` | Teaching + Practice |
| `test/integration/practice_mastery_dashboard_integration_test.dart` | Practice + Mastery + Dashboard |
| `test/features/practice/services/coverage_gaps_integration_test.dart` | Practice internal services |
| `test/integration/e2e_test.dart` | Full app smoke |

**Gaps (features with no integration test at all):**
- **QuickGuide** — no integration test verifying that quick-guide help dialogs work alongside other features.
- **LlmTasks** — no integration test verifying the LLM task manager integrates with ingestion or teaching.
- **Questions** (as a standalone feature) — question bank screen integration with filtering/searching.
- **Onboarding + Settings** — no integration test verifying onboarding completion feeds into settings state.

**Acceptance criteria:**
- At least one integration test covers the QuickGuide + Teaching flow (help dialog context in tutor screen).
- At least one integration test covers LLM Tasks + Ingestion (content ingestion triggers LLM preprocessing task).
- At least one integration test covers Questions + Practice (selecting a question source → practice session).

---

## MINOR

### m1. `onboarding_dialog_test.dart` missing (has `_widget_test` variant only)

| Source file | Expected test |
|---|---|
| `lib/features/onboarding/presentation/onboarding_dialog.dart` | `test/features/onboarding/presentation/onboarding_dialog_test.dart` |

Only `onboarding_dialog_widget_test.dart` exists. Per AGENTS.md convention (`presentation/*.dart` → `presentation/*_test.dart`), the plain test file is missing. Since the source is a widget (dialog), the `_widget_test` is sufficient for rendering coverage, but the convention mismatch may confuse automated tooling.

**Acceptance:** Rename existing `onboarding_dialog_widget_test.dart` → `onboarding_dialog_test.dart`, or add a stub barrel test alongside.

---

### m2. NavigatorObserver coverage gaps in widget tests

**Context:** AGENTS.md says "Use NavigatorObserver for verifying navigation behavior." About 65 widget test files use `pumpWidget`/`pumpAndSettle` but never reference `NavigatorObserver`. While not all widget tests need navigation verification, some test user taps that should trigger navigation and don't verify it.

**Affected files (notably):**
- `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` — has observer in places but some test scenarios may be missing.
- `test/features/practice/presentation/screens/practice_results_screen_test.dart` — has observer at file-scope but only uses it in setup/teardown.
- `test/features/lessons/presentation/widgets/lesson_block_card_test.dart` — tests tap handlers but doesn't verify navigation via observer.
- `test/features/sessions/presentation/session_tracker_screen_test.dart` — tests pause/resume but not navigation.
- `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart` — tests dialog open/confirm but uses observer inconsistently across test cases.

**Acceptance:** No immediate action required, but new widget tests that exercise navigation should use `TestNavigatorObserver`. Existing tests should be audited during regular maintenance.

---

### m3. `practice_test.dart` (barrel) mixes construction checks with behavioral assertions

**File:** `test/features/practice/practice_test.dart`

The first ~15 tests are `isNotNull` barrel checks. The remaining tests have actual behavioral assertions. While not strictly a violation, separating the barrel checks into `test/features/practice/practice_barrel_test.dart` would be cleaner.

**Acceptance:** Optional. If the file is ever refactored, split barrel checks from behavioral model tests.

---

### m4. Some barrel/export test files are purely construction checks

| File | Tests |
|---|---|
| `test/features/lessons/lessons_test.dart` | 8 `isNotNull` + 2 `isA<Type>` checks |
| `test/features/ingestion/ingestion_test.dart` | 7 `isNotNull` checks |
| `test/features/llm_tasks/llm_tasks_test.dart` | 4 `isNotNull` + 1 `isA<Provider>` check |
| `test/features/focus_mode/focus_mode_test.dart` | 4 `isA<Type>` + 2 `isNotNull` checks |
| `test/features/dashboard/dashboard_test.dart` | 12 `isNotNull` checks |
| `test/features/questions/questions_test.dart` | (check — likely similar) |

These are barrel tests and don't need behavioral assertions per `AGENTS.md`. They serve as compile-time smoke tests for barrel imports. No action required.

---

## Summary of Action Items (Priority-Ordered)

| ID | Severity | Title | Effort |
|---|---|---|---|
| C1 | CRITICAL | Migrate 35+ Hive I/O tests to in-memory fakes | Weeks (large files) |
| C2 | CRITICAL | Add error-state tests to 6 service files | Days |
| M1 | MAJOR | Write test for `ExamSessionScreen` | Hours |
| M2 | MAJOR | Write standalone unit test for `SessionRepository` | Hours |
| M3 | MAJOR | Reduce construction checks in `teaching_providers_test.dart` | Hours |
| M4 | MAJOR | Enrich `study_progress_provider_test.dart` with wiring test | Hours |
| M5 | MAJOR | Add integration tests for QuickGuide, LLM Tasks, Questions | Days |
| m1 | MINOR | Align `onboarding_dialog_test.dart` naming | Minutes |
| m2 | MINOR | Audit NavigatorObserver coverage (ongoing) | Ongoing |
| m3 | MINOR | Clean up `practice_test.dart` barrel/model mix | Hours (optional) |
