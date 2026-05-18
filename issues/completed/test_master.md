# Test Coverage & Convention Compliance Audit

**Audit Type:** Full codebase test coverage scan + AGENTS.md convention cross-reference  
**Scope:** `lib/features/*/` and `lib/core/*/` vs `test/features/*/` and `test/core/*/`  
**Date:** 2026-05-18  

---

## BLOCKER Items

### B1. Three source files have zero test coverage (no test file exists)

Convention violation: `AGENTS.md` mandates every source file in `lib/features/*/` must have a corresponding test file.

| Source file | Expected test file | Lines of code |
|---|---|---|
| `lib/features/ingestion/presentation/content_library_screen.dart` | `test/features/ingestion/presentation/content_library_screen_test.dart` | ~581 |
| `lib/features/ingestion/presentation/source_detail_screen.dart` | `test/features/ingestion/presentation/source_detail_screen_test.dart` | ~565 |
| `lib/features/questions/presentation/question_bank_screen.dart` | `test/features/questions/presentation/question_bank_screen_test.dart` | ~539 |

**Rationale:** These are full-screen implementations (500+ lines each) that handle user interaction, state, and navigation. The ingestion feature has tests for `upload_screen.dart` but completely misses two other primary screens. The questions feature has zero presentation-layer screen coverage (painters and widgets are tested, the screen that orchestrates them is not).

**Acceptance criteria:**
- `test/features/ingestion/presentation/content_library_screen_test.dart` created:
  - Verifies content library list renders with mock source data
  - Verifies empty state renders when no sources exist
  - Verifies error state renders when source repo throws
  - Uses NavigatorObserver to verify navigation on source tap
- `test/features/ingestion/presentation/source_detail_screen_test.dart` created:
  - Verifies source detail renders with mock source data
  - Verifies loading/error states
  - Uses NavigatorObserver for back-navigation
- `test/features/questions/presentation/question_bank_screen_test.dart` created:
  - Verifies question list renders
  - Verifies search/filter interactions
  - Verifies navigation to question detail or practice flow

---

## MAJOR Items

### M1. Practice providers test is entirely construction-only — violates Provider Test Coverage Bar

**Affected file:** `test/features/practice/providers/practice_providers_test.dart`

**Context:** Every test group in this file (585 lines) only asserts `isA<...>()`, `same(...)`, or "can be overridden" with no behavioral verification. The AGENTS.md rule states:

> "Every provider test file must include at least one behavioral assertion beyond construction checks"

The "depends on" tests (e.g., lines 137–177) override a dependency and then only check `isA<PracticeDataService>()` — they never verify that the overridden dependency was actually *used* by the downstream provider.

**Affected groups (all construction-only):**
- `spacedRepetitionRepositoryProvider`
- `spacedRepetitionServiceProvider`
- `questionRepositoryProvider`
- `masteryGraphServiceProvider`
- `practiceDataServiceProvider`
- `sessionRepositoryProvider`
- `subjectRepositoryProvider`
- `attemptRepositoryProvider`
- `masteryStateRepositoryProvider`
- `questionMasteryStateRepositoryProvider`
- `topicDependencyRepositoryProvider`
- `questionEvaluationRepositoryProvider`
- `spacedRepetitionRepositoryProvider depends on ...`
- `spacedRepetitionServiceProvider depends on ...`
- `masteryGraphServiceProvider depends on ...`
- `practiceDataServiceProvider depends on ...`

**Rationale:** These tests validate that providers can be *constructed* and *overridden*, but never that the provider graph actually works end-to-end. A refactoring that breaks the wiring between, say, `spacedRepetitionServiceProvider` and `practiceDataServiceProvider` would not be caught.

**Acceptance criteria:**
- At least one group seeds a fake repository with known data and verifies the downstream provider returns that data (e.g., override `attemptRepositoryProvider` with a fake that returns seeded attempts, then verify `masteryGraphServiceProvider` reflects those attempts)
- At least one group tests fallback logic (e.g., when a config value is empty, the provider falls back to a default)
- OR at least one group tests error-state handling (e.g., when `spacedRepetitionRepositoryProvider` throws, `practiceDataServiceProvider` propagates the error)

### M2. Session provider test has error infrastructure but no error tests

**Affected file:** `test/features/sessions/providers/session_providers_test.dart`

**Context:** The `_FakeSessionRepository` defines `throwOnGetAll` and `throwOnGetTodayStats` boolean flags (lines 10–11), and the conditional logic to throw on line 17 (`if (throwOnGetAll) return Result.failure('getAll failed')`). However, **no test ever sets these flags to `true`**. The error paths are dead code in the test suite.

**Rationale:** The error infrastructure was built with intent, but the actual error-state assertions were never written. This means error handling in `allSessionsProvider` and `todayStatsProvider` is untested.

**Acceptance criteria:**
- At least one test in `allSessionsProvider` group sets `throwOnGetAll = true` and verifies the provider propagates the failure
- At least one test in `todayStatsProvider` group sets `throwOnGetTodayStats = true` and verifies graceful error handling

### M3. Three settings screen tests lack NavigatorObserver navigation verification

**Affected files:**
- `test/features/settings/presentation/settings_screen_test.dart` (~1108 lines)
- `test/features/settings/presentation/api_config_screen_test.dart` (~808 lines)
- `test/features/settings/presentation/profile_screen_test.dart` (~799 lines)

**Context:** All three screens contain navigable elements:
- `settings_screen.dart` — 15+ `Navigator.pushNamed()` calls (profile, quick guide, content library, question bank, API config, LLM tasks, focus mode, etc.)
- `api_config_screen.dart` — `Navigator.pop(context)` on save
- `profile_screen.dart` — multiple `Navigator.pop()` calls

None of the test files reference `NavigatorObserver` or import `navigator_observer_helper.dart`.

**Rationale:** AGENTS.md mandates "Use NavigatorObserver for verifying navigation behavior." Without it, a broken route or missing route registration goes undetected.

**Acceptance criteria:**
- `settings_screen_test.dart`: At least one test verifies tapping "Profile" pushes the profile route via `NavigatorObserver`
- `api_config_screen_test.dart`: At least one test verifies save triggers `Navigator.pop`
- `profile_screen_test.dart`: At least one test verifies back navigation

### M4. Exam session screen test lacks NavigatorObserver navigation verification

**Affected file:** `test/features/practice/presentation/screens/exam_session_screen_test.dart` (~961 lines)

**Context:** `exam_session_screen.dart` contains multiple `Navigator.pop()` and `Navigator.pushNamed()` calls (upload navigation on empty sources, back navigation on dismiss, etc.). The test file never uses `NavigatorObserver`.

**Rationale:** Navigation during exam flow (e.g., "no questions — go upload") is a critical user path. Without Observer verification, broken routing goes unnoticed.

**Acceptance criteria:**
- At least one test verifies navigation on exam completion/failure via `NavigatorObserver`

---

## MINOR Items

### m1. Teaching providers test is borderline compliant (1 of 6 groups has behavioral assertions)

**Affected file:** `test/features/teaching/providers/teaching_providers_test.dart`

**Context:** Only the `teachingModelIdProvider` group (lines 15–37) has behavioral assertions (fallback when `selectedModelProvider` returns empty). The remaining five groups are purely construction-only:

| Group | Tests | Behavioral? |
|---|---|---|
| `teachingModelIdProvider` | 2 tests (saved model + fallback) | YES |
| `exerciseEvaluatorProvider` | 2 tests (constructor + override) | NO |
| `voiceControllerProvider` | 2 tests (constructor + override) | NO |
| `clockProvider` | 2 tests (constructor + override) | NO |
| `tutorServiceProvider` | 3 tests (constructor + wiring checks) | NO |
| `promptsProvider` | 2 tests (constructor + override) | NO |

**Rationale:** The file barely passes the "at least one behavioral assertion" rule. The wiring checks in `tutorServiceProvider` (lines 110–139) only verify `isA<TutorService>()` — not that the overridden dependency is actually used.

**Acceptance criteria:**
- At least one more group gains a behavioral assertion (e.g., seed `exerciseEvaluatorProvider` with a fake LLM that returns a known evaluation and verify behavior)

### m2. Widget tests that call `Hive.init()` instead of fully isolating with fakes

**Affected files:**
- `test/features/planner/presentation/planner_screen_test.dart` (line 320)
- `test/features/planner/presentation/widgets/milestone_timeline_test.dart` (line 12)
- `test/features/planner/presentation/widgets/roadmap_card_test.dart` (line 13)
- `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` (line 43)

**Context:** All four files call `Hive.init(Directory.systemTemp...)` and `registerPlannerAdapters()` in `setUpAll`. The convention says "Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."

**Rationale:** Hive init in widget tests introduces filesystem I/O, test order sensitivity, and temp directory cleanup concerns. The planner screen test already uses `fixedStudentId` (good) but still needs Hive because its fake repos or adapters reference Hive types directly. The goal should be full isolation: fakes that don't touch Hive at all.

**Acceptance criteria:**
- `planner_screen_test.dart` refactored so that all injected fakes (PlanRepository, RoadmapRepository, etc.) have no Hive dependency, eliminating the need for `Hive.init()`
- Same pattern applied to the three planner widget test files

### m3. Error-state tests missing or incomplete in provider/service files

**Affected files:**
- `test/features/mentor/providers/mentor_providers_test.dart` — no error-state tests (though mentorModelIdProvider fallback tests exist)
- `test/features/teaching/providers/teaching_providers_test.dart` — no error-state tests in any provider group
- `test/features/practice/services/practice_session_service_test.dart` — has `handles errors gracefully` test names but the bodies test happy path only (no actual error simulation)

**Acceptance criteria:**
- Each affected file has at least one group with a test that verifies behavior when a dependency throws
- The `practice_session_service_test.dart` "handles errors gracefully" tests are corrected to actually simulate failure

### m4. Settings feature has no provider tests (no providers directory in source — confirm intentional)

**Observation:** `lib/features/settings/` has `data/`, `presentation/`, and `services/` (data_backup_service.dart) but no `providers/` directory. Settings state is managed through `lib/core/providers/app_providers.dart`. Since the core providers already have tests (`test/core/providers/app_providers_test.dart`), this is not a gap — just a note confirming the architecture.

**No action required.**

---

## Summary of Convention Compliance

| Convention | Status | Violations |
|---|---|---|
| Every source file has a test file | ❌ 3 missing | B1 |
| Provider tests have behavioral assertions | ❌ 1 file entirely, 1 borderline | M1, m1 |
| Hand-written fakes (not mockito/mocktail) | ✅ | None found |
| Unit and widget tests in separate files | ✅ | No mixing found |
| Widget tests use `fixedStudentId` over `StudentIdService` | ✅ | All fakes are hand-written |
| Widget tests use `NavigatorObserver` | ❌ 4 screens missing | M3, M4 |
| Widget tests avoid Hive I/O | ⚠️ 4 planner widget tests need refactoring | m2 |
| Error-state tests present | ⚠️ Gaps in 5 files | M2, m3 |
| `pumpAndSettle` for async widget tests | ✅ | Widely used |
| `toStringAsFixed()` avoided for user-facing displays | N/A | Not tested in this audit |

---

## Acceptance Criteria Checklist (for a "fixed" state)

### BLOCKER
- [ ] B1: 3 missing test files created for `content_library_screen`, `source_detail_screen`, `question_bank_screen`

### MAJOR
- [ ] M1: `practice_providers_test.dart` has at least one behavioral assertion (wiring, fallback, or error)
- [ ] M2: `session_providers_test.dart` exercises `throwOnGetAll` and `throwOnGetTodayStats`
- [ ] M3: settings screen tests (`settings_screen`, `api_config_screen`, `profile_screen`) use `NavigatorObserver`
- [ ] M4: `exam_session_screen_test.dart` uses `NavigatorObserver` for navigation verification

### MINOR
- [ ] m1: `teaching_providers_test.dart` gains a second behavioral assertion group
- [ ] m2: Planner widget tests eliminate `Hive.init()` through fully-faked dependencies
- [ ] m3: Error-state tests added to `mentor_providers_test`, `teaching_providers_test`, and `practice_session_service_test`
