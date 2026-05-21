# Test Coverage & Convention Audit

**Author:** Test Master
**Date:** 2026-05-20
**Scope:** Full cross-reference of `lib/` source files against `test/` files and AGENTS.md conventions.

---

## Context

Audited every source file under `lib/features/*/` and `lib/core/*/` against the test-mapping table in AGENTS.md. Reviewed all ~300 test files for conformance with provider coverage bar, unit/widget separation, fake-class convention, NavigatorObserver guidance, Hive-avoidance guidance, and error-state coverage.

---

## MAJOR Issues

### M1 — 5 source files have zero test coverage

| Source file | Expected test location |
|---|---|
| `lib/features/focus_mode/data/models/focus_session_type.dart` | `test/features/focus_mode/data/models/focus_session_type_test.dart` |
| `lib/core/services/secure_api_key_service.dart` | `test/core/services/secure_api_key_service_test.dart` |
| `lib/core/providers/secure_api_key_provider.dart` | `test/core/providers/secure_api_key_provider_test.dart` |
| `lib/core/providers/ai_config_provider.dart` | `test/core/providers/ai_config_provider_test.dart` |
| `lib/core/widgets/practice_performance_card.dart` | `test/core/widgets/practice_performance_card_test.dart` |

**Rationale:** These are reachable production files. `secure_api_key_service` handles secrets; `ai_config_provider` gates app startup via `aiConfigReadyProvider`; `practice_performance_card` is a reusable widget used in dashboards and summaries.

**Acceptance criteria:**
- `focus_session_type_test.dart` — verify enum values, `toString`, `fromString` or any parse/serialize methods.
- `secure_api_key_service_test.dart` — verify save/load/delete/validate with an in-memory backing.
- `secure_api_key_provider_test.dart` — verify provider exposes service methods; test error propagation when service throws.
- `ai_config_provider_test.dart` — verify `aiConfigReadyProvider` completes only after `markAiConfigReady()`; verify `isAiConfigReady` toggles; verify double-complete is idempotent.
- `practice_performance_card_test.dart` — widget test verifying rendering with minimal FocusSession data; verify compact mode.

---

### M2 — 5 misplaced test files fragmenting coverage

Each file below tests a source that already has a correctly-located test. The misplaced file creates duplicate maintenance burden:

| Misplaced test | Source belongs to | Correct location already exists |
|---|---|---|
| `test/features/ingestion/data/models/source_model_test.dart` | `lib/core/data/models/source_model.dart` | `test/core/data/models/source_model_test.dart` |
| `test/core/data/engagement_nudge_adapter_test.dart` | `lib/features/planner/data/adapters/engagement_nudge_adapter.dart` | `test/features/planner/data/adapters/engagement_nudge_adapter_test.dart` |
| `test/core/data/student_availability_adapter_test.dart` | `lib/features/planner/data/adapters/student_availability_adapter.dart` | `test/features/planner/data/adapters/student_availability_adapter_test.dart` |
| `test/features/practice/utils/sr_data_codec_test.dart` | `lib/core/utils/sr_data_codec.dart` | `test/core/utils/sr_data_codec_test.dart` |
| `test/features/sessions/data/repositories/session_repository_integration_test.dart` | `lib/core/data/repositories/session_repository.dart` | `test/core/data/repositories/session_repository_test.dart` |

**Rationale:** CI confusion, ambiguous `git blame`, dead code risk, and wasted test-runner time.

**Acceptance criteria:** Delete each misplaced file after confirming its assertions are a subset of (or fully redundant with) the correctly-located test. If the misplaced file contains unique coverage, merge those tests into the correct location first.

---

### M3 — Orphaned and duplicate test files

| File | Problem |
|---|---|
| `test/features/onboarding/onboarding_test.dart` | No corresponding barrel source. Tests `OnboardingService.isOnboardingNeeded()` which is already tested in `test/features/onboarding/services/onboarding_service_test.dart`. Likely a legacy file. |
| `test/features/questions/data/models/question_model_test.dart` | The source `lib/core/data/models/question_model.dart` lives in core. A correct test exists at `test/core/data/models/question_model_test.dart`. This is a duplicate. |

**Rationale:** Files with no source or that duplicate existing coverage add noise, increase CI time, and confuse developers.

**Acceptance criteria:** Delete `test/features/onboarding/onboarding_test.dart` after verifying no unique coverage is lost. Delete `test/features/questions/data/models/question_model_test.dart` after merging any unique assertions into `test/core/data/models/question_model_test.dart`.

---

### M4 — Construction-only test files (no behavioral assertions)

| File | Tests | Issue |
|---|---|---|
| `test/core/data/data_test.dart` | Single `expect(DatabaseService, isNotNull)` | Barrel smoke test, zero behavior |
| `test/core/utils/label_helpers_test.dart` | 3 tests, each only `expect(…, isNotNull)` | All 30 enum values checked for null only — never verify actual string value |
| `test/features/quickguide/presentation/quick_guide_screen_constructor_test.dart` | 5 tests verifying default constructor arguments | Verifies constants declared in source, not runtime behavior |

**Rationale:** AGENTS.md requires "at least one behavioral assertion beyond construction checks" for provider tests. While `data_test.dart` and `label_helpers_test.dart` are not provider files, they demonstrate the same anti-pattern: they assert the test infrastructure works but never exercise business logic. A null check is not a behavioral assertion.

**Acceptance criteria:**
- `data_test.dart` — either add a meaningful barrel-import test that exercises behavior, or delete the file (if `DatabaseService` is tested elsewhere).
- `label_helpers_test.dart` — replace all `isNotNull` with `equals(expectedValue)` assertions. Verify the actual localized string for each enum value.
- `quick_guide_screen_constructor_test.dart` — add at least one behavioral test (e.g., verify that `showModeNavigation: false` hides navigation) or fold into the existing `quick_guide_screen_test.dart`.

---

### M5 — Extreme test file fragmentation in practice and settings

| Source file | # of test files | Fragments |
|---|---|---|
| `lib/features/practice/presentation/screens/practice_screen.dart` | 3 | `practice_screen_test.dart`, `practice_screen_additional_test.dart`, `practice_screen_more_test.dart` |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 2 | `exam_session_screen_test.dart`, `exam_session_screen_additional_test.dart` |
| `lib/features/practice/presentation/screens/practice_results_screen.dart` | 2 | `practice_results_screen_test.dart`, `practice_results_screen_additional_test.dart` |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 2 | `practice_session_screen_test.dart`, `practice_session_screen_additional_test.dart` |
| `lib/features/settings/presentation/api_config_screen.dart` | 4 | `api_config_screen_test.dart`, `_behavioral_test.dart`, `_extended_test.dart`, `_gaps_test.dart` |
| `lib/features/settings/presentation/settings_screen.dart` | 4 | `settings_screen_test.dart`, `_behavioral_test.dart`, `_extended_test.dart`, `_gaps_test.dart` |
| `lib/features/settings/presentation/profile_screen.dart` | 4 | `profile_screen_test.dart`, `_behavioral_test.dart`, `_extended_test.dart`, `_gaps_test.dart` |

**Rationale:** 8 source files spread across 19 test files. This makes it impossible to tell at a glance whether a screen is covered, forces developers to open multiple files to understand test scope, and encourages further fragmentation.

**Acceptance criteria:** Merge all fragments for each source file into a single test file. Use `group()` to organize scenarios (happy path, error state, edge cases). Delete the `_additional`, `_behavioral`, `_extended`, `_gaps` variants after merging.

---

### M6 — 3 widget test files use real Hive I/O instead of fakes

| File | Hive usage |
|---|---|
| `test/features/settings/presentation/settings_screen_extended_test.dart` | `Hive.init(dir.path)` + `Hive.openBox(HiveBoxNames.sources)` — comment says "needed for `_FailedUploadsTile`" |
| `test/features/settings/presentation/settings_screen_gaps_test.dart` | `Hive.init(hiveDir.path)` + `Hive.openBox(HiveBoxNames.settings)` |
| `test/features/settings/presentation/settings_screen_behavioral_test.dart` | `Hive.init` + `Hive.openBox(HiveBoxNames.settings)` |

**Rationale:** AGENTS.md says "Use `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies." Real Hive calls create flaky tests (temp dir cleanup, cross-test pollution, filesystem dependency), slow down the suite, and break in headless CI if Hive isn't properly initialized.

**Acceptance criteria:** Replace each real `Hive.init`/`Hive.openBox` with a fake. For `_FailedUploadsTile`'s `SourceRepository` dependency, inject a `FakeSourceRepository` via provider overrides. Delete all `Directory.systemTemp` / `Hive.init` boilerplate from these files.

---

### M7 — Redundant test file testing a hand-rolled fake

`test/features/practice/services/spaced_repetition_service_fake_repo_test.dart` creates `_FakeSpacedRepetitionService` extending `SpacedRepetitionService`, overrides `getQuestionsDue`, `updateNextReviewDate`, etc. with custom logic, then tests those overridden methods. The real SM-2 engine is never exercised.

**Rationale:** The file tests the fake's implementation, not the production code. The correctly-located `spaced_repetition_service_test.dart` (816 lines) already covers all paths with proper fakes at the repository layer and exercises the real SM-2 algorithm.

**Acceptance criteria:** Delete `spaced_repetition_service_fake_repo_test.dart` after verifying no unique coverage exists that is absent from `spaced_repetition_service_test.dart`. If any edge case is missing from the main test, port it first.

---

### M8 — `TopicDetailScreen` has fragmented test files (unit vs widget separation is correct but naming is non-standard)

Noted here for tracking: `test/features/dashboard/presentation/screens/topic_detail_screen_test.dart` (widget tests) and `topic_detail_screen_unit_test.dart` (unit test for `TopicDetailArgs`). This follows AGENTS.md separation but the `_unit_test` suffix is inconsistent with the rest of the project.

**Acceptance criteria:** Rename `topic_detail_screen_unit_test.dart` to `topic_detail_screen_args_test.dart` or merge its single `TopicDetailArgs` test into the widget test file (since the args object is purely a data class and doesn't warrant a separate file).

---

## MINOR Issues

### m1 — Weakest provider test: `subject_repository_provider_test.dart`

This file has 4 tests: `isA<SubjectRepository>()`, 2x `identical()` singleton checks, and `returnsNormally`. It passes only because AGENTS.md explicitly lists singleton verification as an acceptable behavioral assertion. No data flows through the provider; no error path is tested.

**Acceptance criteria:** Add a test that seeds data into an overridden fake repo and retrieves it through the provider (as `topic_repository_provider_test.dart` does). Add an error-path test showing the provider propagates failures.

---

### m2 — 14 files use non-standard `_widget_test` suffix

These files have `_widget_test` in their name rather than the standard location-based naming:

| File |
|---|
| `test/features/settings/data/models/settings_box_widget_test.dart` |
| `test/features/settings/data/models/settings_model_widget_test.dart` |
| `test/core/errors/handlers_widget_test.dart` |
| `test/core/services/prerequisite_check_service_widget_test.dart` |
| `test/core/routes/app_router_widget_test.dart` |
| `test/core/theme/app_theme_widget_test.dart` |
| `test/features/practice/presentation/widgets/source_practice_sheet_widget_test.dart` |
| `test/features/subjects/presentation/subject_form_widgets_widget_test.dart` |
| `test/features/subjects/providers/subjects_repository_provider_widget_test.dart` |
| `test/features/subjects/providers/topic_repository_provider_widget_test.dart` |
| `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart` |
| `test/features/questions/presentation/painters/drawing_painter_widget_test.dart` |
| `test/features/questions/presentation/painters/grid_painter_widget_test.dart` |
| `test/features/questions/presentation/widgets/canvas_drawing_widget_widget_test.dart` |

Note: `canvas_drawing_widget_widget_test.dart` has a doubled `_widget` suffix (typo).

Also: `settings_box_widget_test.dart` and `settings_model_widget_test.dart` test data models using `testWidgets` — these should either be pure unit tests on the model or be clearly named to indicate they test widget-tree integration of model properties.

**Acceptance criteria:** Remove `_widget` suffix from all files and use the standard location-based naming. For model widget tests (`settings_box_widget_test.dart`, `settings_model_widget_test.dart`), either convert to pure unit tests or rename to reflect their purpose (e.g., `settings_box_theme_integration_test.dart`).

---

### m3 — Naming convention violation: `onboarding_test.dart`

This file at `test/features/onboarding/onboarding_test.dart` tests `OnboardingService` but sits at the top of the `onboarding/` test tree instead of in `features/onboarding/services/`.

**Acceptance criteria:** Delete the file (it duplicates `onboarding_service_test.dart`).

---

## Summary of Remaining Gaps (No Action Needed)

The following areas were reviewed and found **compliant**:

| Check | Result |
|---|---|
| mockito/mocktail usage | **None found** — all fakes are hand-written ✅ |
| Unit/widget test mixing in same file | **None found** — all files are cleanly separated ✅ |
| NavigatorObserver usage in widget tests | **Widely adopted** — `TestNavigatorObserver` used across dashboard, planner, mentor, settings, onboarding, practice ✅ |
| Error-state tests (`Result.failure` paths) | **Widespread** — dedicated `group('error-state')` blocks in mistake_review_service, session_export_service, spaced_repetition_service, focus_practice_service, etc. ✅ |
| Provider test behavioral assertions | **26/27 pass** with override wiring, data-flow verification, error propagation ✅ (only `subject_repository_provider` is borderline — see m1) |

---

## Acceptance Criteria Summary (Checklist)

- [ ] **M1:** Create test files for 5 uncovered sources
- [ ] **M2:** Delete 5 misplaced test files (or merge unique coverage first)
- [ ] **M3:** Delete orphaned `onboarding_test.dart` and duplicate `question_model_test.dart`
- [ ] **M4:** Add behavioral assertions to 3 construction-only test files
- [ ] **M5:** Merge 19 fragmented test files into 8 source-aligned files
- [ ] **M6:** Replace real Hive I/O with fakes in 3 settings screen tests
- [ ] **M7:** Delete redundant `spaced_repetition_service_fake_repo_test.dart`
- [ ] **M8:** Rename or merge `topic_detail_screen_unit_test.dart`
- [ ] **m1:** Strengthen `subject_repository_provider_test.dart` with data-flow test
- [ ] **m2:** Standardize naming of 14 `_widget_test` suffix files
- [ ] **m3:** Delete `test/features/onboarding/onboarding_test.dart`
