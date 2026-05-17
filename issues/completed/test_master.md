# Test Coverage & Quality Audit

**Severity:** MIXED (see per-item severity)
**Audit Date:** 2026-05-17
**Scope:** Full codebase cross-referenced against AGENTS.md conventions

---

## BLOCKER — App crashes or user cannot proceed

### B1. Onboarding feature has zero test coverage

| Metric | Value |
|---|---|
| **Source** | `lib/features/onboarding/presentation/onboarding_dialog.dart` (200 lines) |
| **Classes exposed** | `OnboardingService` (static Hive I/O), `OnboardingDialog` (StatefulWidget), `ApiKeyBanner`, `LocalDataNotice` |
| **Missing test** | `test/features/onboarding/presentation/onboarding_dialog_test.dart` |
| **Barrel test** | `test/features/onboarding/onboarding_test.dart` — also missing |
| **Rationale** | This is the **only feature** with zero test files. `OnboardingService` performs Hive I/O that gates the entire app entry flow (`isOnboardingNeeded`, `markCompleted`, `markDontShowAgain`, `isFirstLaunch`). A regression here can lock every user out of the app. |
| **Acceptance criteria** | Create `test/features/onboarding/presentation/onboarding_dialog_test.dart` with: (1) unit tests for all 4 `OnboardingService` static methods with a faked Hive box, (2) widget test for `OnboardingDialog` rendering and interaction, (3) widget test for `ApiKeyBanner`, (4) widget test for `LocalDataNotice`. Create `test/features/onboarding/onboarding_test.dart` barrel test. |

### B2. `lib/utils/id_generator.dart` has no test file

| Metric | Value |
|---|---|
| **Source** | `lib/utils/id_generator.dart` (12 lines) |
| **Classes** | `IdGenerator` with two static methods: `generate(String prefix)` and `reset()` |
| **Missing test** | Any file under `test/utils/` |
| **Rationale** | `IdGenerator` is used across features for generating unique IDs. A regression (e.g., non-unique IDs from `generate`, or reset not clearing state) leads to silent data corruption. |
| **Acceptance criteria** | Create `test/utils/id_generator_test.dart` verifying: (1) `generate` produces unique IDs on successive calls, (2) IDs include the prefix, (3) `reset()` clears internal counter so a new generate starts from 1. |

---

## MAJOR — Feature is broken or misleading

### M1. 10 test files mix unit tests (`test()`) and widget tests (`testWidgets()`) in the same file

| File | `test()` count | `testWidgets()` count |
|---|---|---|
| `test/core/theme/app_theme_test.dart` | 36 | 15 |
| `test/features/dashboard/presentation/widgets/export_section_test.dart` | 7 | 4 |
| `test/features/practice/presentation/screens/exam_session_screen_test.dart` | 17 | 26 |
| `test/features/practice/presentation/screens/practice_session_screen_test.dart` | 1 | 45 |
| `test/features/practice/presentation/widgets/source_practice_sheet_test.dart` | 1 | 8 |
| `test/features/questions/presentation/widgets/canvas_drawing_widget_test.dart` | 9 | 65 |
| `test/features/quickguide/presentation/quick_guide_screen_test.dart` | 5 | 67 |
| `test/features/settings/data/models/settings_box_test.dart` | 13 | 1 |
| `test/features/settings/data/models/settings_model_test.dart` | 49 | 1 |
| `test/features/subjects/presentation/subject_form_widgets_test.dart` | 11 | 17 |

**Rationale:** AGENTS.md states *"Keep unit tests and widget tests in separate files — never mix them in the same file."* Widget tests require `flutter_test` and a `TestWidgetsFlutterBinding`; unit tests should be pure Dart and runnable without a binding. Mixing them prevents running each category independently, slows CI, and couples UI concerns with logic.

**Acceptance criteria:** Split each file into two files: one `*_test.dart` (unit tests only, no `testWidgets`) and one `*_widget_test.dart` (widget tests only, no `test()`). Move pure-logic tests (model serialization, formatting, calculations) out of screen/widget test files.

### M2. 12 widget/screen tests navigate without `NavigatorObserver`

Files that use `pumpAndSettle` for navigation but **do not** use `NavigatorObserver` to verify the route:

| File | Lines | Notes |
|---|---|---|
| `test/features/dashboard/presentation/dashboard_screen_test.dart` | 1656 | No observer |
| `test/features/settings/presentation/settings_screen_test.dart` | 1096 | No observer |
| `test/features/sessions/presentation/session_history_screen_test.dart` | 934 | No observer |
| `test/features/lessons/presentation/lesson_list_screen_test.dart` | 266 | No observer |
| `test/features/teaching/presentation/tutor_screen_test.dart` | — | No observer |
| `test/features/subjects/presentation/subject_list_screen_test.dart` | 328 | No observer (uses `pumpAndSettle` 19 times) |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | — | No observer |
| `test/features/focus_mode/presentation/focus_timer_screen_test.dart` | — | No observer |
| `test/features/ingestion/presentation/upload_screen_test.dart` | — | No observer |
| `test/features/llm_tasks/presentation/llm_task_manager_screen_test.dart` | — | No observer |
| `test/features/mentor/presentation/mentor_screen_test.dart` | 1065 | No observer |
| `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` | — | Uses mock NavigatorObserver (not real observer) |

**Only 9 test files use NavigatorObserver correctly.** AGENTS.md requires *"Use `NavigatorObserver` for verifying navigation behavior"*.

**Acceptance criteria:** Add `NavigatorObserver` to each screen test that exercises navigation. Assert expected route pushes/pops in at least one test per screen. Refactor `lesson_booking_sheet_test.dart` to use a real `NavigatorObserver` subclass instead of a mock.

### M3. 8 widget tests initialize Hive I/O directly instead of using `fixedStudentId` or fakes

| File | Line(s) | Pattern |
|---|---|---|
| `test/features/mentor/presentation/mentor_screen_test.dart` | 218–220 | `Hive.init(dir.path)` + `Hive.openBox('settings')` |
| `test/features/planner/presentation/planner_screen_test.dart` | 274 | `Hive.init(...tempDir...)` |
| `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` | 42 | `Hive.init(...tempDir...)` |
| `test/features/focus_mode/presentation/focus_timer_screen_test.dart` | 284 | `Hive.init(...tempDir...)` |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | 48 | `Hive.init(...tempDir...)` |
| `test/features/settings/presentation/profile_screen_test.dart` | 19 | `Hive.init(tempDir.path)` |
| `test/features/ingestion/presentation/upload_screen_test.dart` | 227 | `Hive.init(hivePath)` |
| `test/features/practice/presentation/screens/practice_session_screen_test.dart` | 886 | `Hive.init(...tempDir...)` |

**Rationale:** AGENTS.md states *"Use `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."* Direct Hive initialization couples tests to file-system state, leaves temp dirs behind on failure, and slows test execution. Several non-widget tests also use `StudentIdService()` directly (in practice providers, coverage gaps, practice session/data/exam services, cross-feature integrator) instead of injecting a fixed ID.

**Acceptance criteria:** Remove all `Hive.init()` calls from widget tests. Replace `StudentIdService()` with `fixedStudentId` string injection where applicable. Ensure all Hive-backed services are faked at the boundary (repository level).

### M4. 6 provider test files lack required behavioral assertions

Per AGENTS.md "Provider Test Coverage Bar": every provider test file must include at least one behavioral assertion beyond `isA<...>()`/`isNotNull`.

| File | Status | Problem |
|---|---|---|
| `test/features/focus_mode/providers/focus_mode_providers_test.dart` | **FAIL** | All 5 tests are construction-only (`isA`, `same`, `returnsNormally`). Zero behavioral assertions (no error handling, no fallback, no data-value verification). |
| `test/features/lesson/providers/lesson_providers_test.dart` | **FAIL** | All tests are construction-only (`isA<LessonRepository>()`, `isA<LessonService>()`). Override tests verify `same()` identity but not data flow. |
| `test/features/teaching/providers/teaching_providers_test.dart` | **FAIL** | 7 of 9 tests are `isA` only (ExerciseEvaluator, VoiceController, Clock, TutorService, Prompts). Only `teachingModelIdProvider` has behavioral checks. |
| `test/features/mentor/providers/mentor_providers_test.dart` | **PARTIAL FAIL** | 2 of 7 tests are pure `isA<>()` (`AttemptRepository`, `PendingActionRepository`). 2 wiring tests use overrides but only assert `isA<StudyProgressTracker>()` — they never verify the override data flows through. |
| `test/features/practice/providers/practice_providers_test.dart` | **PARTIAL FAIL** | 7 tests (`SpacedRepetitionEngine`, `MasteryRecorder`, `ReadinessScorer`, `DifficultyAdapter`, `ExamSessionService`, `MistakeReviewService`, `CrossFeatureIntegrator`) are pure `isA<>()`. Override identity checks are present but no data-flow or error testing. |
| `test/features/dashboard/providers/dashboard_providers_test.dart` | **PARTIAL FAIL** | 4 of 7 tests are pure `isA<>()` (TopicRepository, AttemptRepository, InstrumentationService, AdherenceRepository). |

**Acceptance criteria:** For each FAIL file, add at least one of: (a) dependency-wiring test where a fake repo is injected and the downstream service uses it (verify concrete data, not just `same()`), (b) fallback logic test (e.g., when config is empty, default is returned), (c) singleton identity test across multiple reads, (d) error-state test (service throws → provider propagates error).

### M5. Missing error-state test coverage in 4 feature areas

Files with **minimal or zero** error-path coverage (`throws`, `Result.failure`, exception propagation):

| Area | File(s) | Gap |
|---|---|---|
| **Focus Mode providers** | `focus_mode_providers_test.dart` | Zero error tests. No simulation of timer/repository failures. |
| **Lessons providers** | `lesson_providers_test.dart` | No error testing. All tests assume success path. |
| **Teaching services** | `tutor_service_test.dart`, `voice_controller_test.dart`, `exercise_evaluator_test.dart`, `conversation_manager_test.dart` | No explicit error/exception coverage. No failure-mode fakes. |
| **Settings models** | `settings_model_test.dart`, `settings_box_test.dart` | `throwsUnsupportedError` only (from unimplemented methods) — no business-logic error coverage. |

**Rationale:** AGENTS.md requires testing *"what happens when a service throws"*. Without error-path coverage, regressions that introduce unhandled exceptions silently crash the app.

**Acceptance criteria:** For each area, add at least 2 error-state tests: (1) a repository or service method throws an exception and the caller handles it gracefully (returns fallback/error state), (2) an invalid input produces a documented error response.

### M6. 8 barrel/export test files contain only construction checks with zero behavioral value

| File | Assertions | Problem |
|---|---|---|
| `test/features/features_barrel_test.dart` | 13 `isNotNull` | Pure compilation check |
| `test/core/core_test.dart` | 6 `isA<Type>()`, 1 behavioral | 6 of 7 are construction |
| `test/core/utils/utils_test.dart` | 2 `isA<Type>()` | Pure compilation check |
| `test/core/widgets/widgets_test.dart` | 4 `isA<Type>()` | Pure compilation check |
| `test/features/sessions/sessions_test.dart` | 10 `isA`/`isNotNull` | Pure compilation check |
| `test/features/ingestion/ingestion_test.dart` | 3 `isNotNull` | Pure compilation check |
| `test/features/questions/questions_test.dart` | 12 of 15 `isA` | Mostly construction |
| `test/core/theme/llm_task_status_test.dart` | 5 `isA`, 1 weak (`hasLength`) | Mostly construction |

**Rationale:** These tests verify only that `export` statements compiled. They provide no runtime behavioral coverage and create maintenance burden (must update when barrel exports change). AGENTS.md does not exempt barrel tests from the behavioral-assertion bar.

**Acceptance criteria:** Either (a) remove these files if they add no value (compilation errors are caught by any consumer import), or (b) add meaningful assertions — e.g., for `sessions_test.dart`, verify that `SessionRepository` constructed via the barrel actually reads/writes; for `utils_test.dart`, call methods from the barrel and verify they work.

---

## MINOR — Code quality / UX friction

### m1. 3 test files placed at flat paths instead of mirroring source subdirectories

| Source | Expected test path (per convention) | Actual test path |
|---|---|---|
| `lib/core/services/llm/llm_embeddings_service.dart` | `test/core/services/llm/llm_embeddings_service_test.dart` | `test/core/services/llm_embeddings_service_test.dart` |
| `lib/core/services/llm/llm_model_service.dart` | `test/core/services/llm/llm_model_service_test.dart` | `test/core/services/llm_model_service_test.dart` |
| `lib/core/services/pdf_generator/question_pdf_generator.dart` | `test/core/services/pdf_generator/question_pdf_generator_test.dart` | `test/core/services/question_pdf_generator_test.dart` |

**Acceptance criteria:** Move these 3 test files into subdirectories that mirror the source tree to match AGENTS.md convention.

### m2. AGENTS.md convention patterns are stale — `models/` no longer exists

All feature models live under `data/models/` (not top-level `models/`). The AGENTS.md states:
  `lib/features/*/models/*.dart` → `test/features/*/models/*_test.dart`

But in reality:
  `lib/features/*/data/models/*.dart` → `test/features/*/data/models/*_test.dart`

Additionally, these real subdirectories have test coverage but are undocumented:
- `presentation/screens/`
- `presentation/painters/`
- `services/prompts/`
- `data/<feature>_data.dart` barrel files

**Acceptance criteria:** Update AGENTS.md to add `data/models/`, `presentation/screens/`, `presentation/painters/`, and `services/prompts/` mapping rows. Deprecate the `models/` row. Clarify that feature data barrels (`planner_data.dart`, `practice_data.dart`, etc.) belong at the barrel level.

### m3. `StudentIdService()` used directly in 7 non-widget test files instead of injecting a fixed ID

These are not widget tests but still couple to Hive I/O via `StudentIdService`:

- `test/features/practice/providers/practice_providers_test.dart` (lines 91, 533, 549)
- `test/features/practice/services/coverage_gaps_test.dart` (12 occurrences)
- `test/features/practice/services/practice_session_service_test.dart` (lines 71, 206, 224)
- `test/features/practice/services/practice_data_service_test.dart` (12 occurrences)
- `test/features/practice/services/exam_session_service_test.dart` (line 61)
- `test/core/services/cross_feature_integrator_test.dart` (line 46)
- `test/core/services/study_progress_tracker_test.dart` (check needed)

**Acceptance criteria:** Refactor these tests to accept a `String studentId` parameter instead of constructing `StudentIdService()`. Use `fixedStudentId` or a test constant.

### m4. l10n test files also mix unit and widget tests

5 files in `test/l10n/` contain both `test()` and `testWidgets()`:
- `test/l10n/app_localizations_test.dart`
- `test/l10n/app_localizations_comprehensive_test.dart`
- `test/l10n/app_localizations_coverage_test.dart`
- `test/l10n/app_localizations_coverage_gaps_test.dart`
- `test/l10n/app_localizations_final_coverage_test.dart`

**Acceptance criteria:** Split into separate `*_test.dart` (unit) and `*_widget_test.dart` (widget) files.

### m5. No integration coverage for onboarding flow, mentor nudges end-to-end

The only integration test (`test/integration/e2e_test.dart`) covers QuickGuide, Planner, and Route Navigation. Missing integration scenarios:
- Onboarding flow (dialog → set key → app entry)
- Mentor nudges (wellbeing check → nudge creation → display)
- Practice → Results flow (complete session → see results screen)
- Focus timer → Session record flow

**Acceptance criteria:** Add integration tests for at least 2 missing scenarios.

---

## Compliance Summary

| AGENTS.md Rule | Compliance | Severity |
|---|---|---|
| Every source file has a test file | ✅ 198/198 convention-mapped OK; ❌ 1 feature (Onboarding) + 1 util (IdGenerator) | B1, B2 |
| Provider tests have behavioral assertions | ❌ 6 files fail partially/totally | M4 |
| Error-state tests exist | ❌ 4 feature areas have minimal/zero coverage | M5 |
| Hand-written fakes (no mockito/mocktail) | ✅ 100% compliant | — |
| `fixedStudentId` over `StudentIdService` in widget tests | ❌ 8 widget tests + 7 non-widget tests violate | M3, m3 |
| `NavigatorObserver` for navigation verification | ❌ 12 screen tests fail | M2 |
| Unit and widget tests in separate files | ❌ 10 files violate | M1 |

---

## File Count Summary

| Category | Count |
|---|---|
| Source `.dart` files examined | ~299 |
| Convention-mapped source files with tests | 198 |
| Convention-mapped source files MISSING tests | 0 (strict convention) / 2 (total orphan) |
| Test files examined | 316 |
| Construction-only test files | 8 barrel + 6 partial provider |
| Mixed unit+widget files | 10 |
| Missing NavigatorObserver | 12 files |
| Hive I/O in widget tests | 8 files |
| Fake repo used instead of Hive init needed | 8 widget + 7 non-widget |
