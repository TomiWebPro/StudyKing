# Test Coverage & Quality Audit

## Summary

Comprehensive audit of test coverage and quality across all `lib/features/*/` and `lib/core/*/` source files, cross-referenced against [AGENTS.md](../AGENTS.md) conventions. Findings grouped by severity.

---

## MAJOR

### M1 — Missing test files (5 source files with zero test coverage)

Per AGENTS.md mapping rules, these source files have **no corresponding test file**:

| Source file | Expected test location |
|---|---|
| `lib/features/onboarding/services/onboarding_service.dart` | `test/features/onboarding/services/onboarding_service_test.dart` |
| `lib/core/data/contracts/plan_adherence_contract.dart` | `test/core/data/contracts/plan_adherence_contract_test.dart` |
| `lib/core/data/contracts/session_query_contract.dart` | `test/core/data/contracts/session_query_contract_test.dart` |
| `lib/core/data/models/markscheme_model.dart` | `test/core/data/models/markscheme_model_test.dart` (current test lives at `test/features/questions/data/models/markscheme_model_test.dart` — wrong location) |
| `lib/core/services/session_plan_adherence_service.dart` | `test/core/services/session_plan_adherence_service_test.dart` |

**Rationale**: `OnboardingService` contains business logic (flag persistence, first-launch detection). The four core files define contracts and services consumed across features. Missing test coverage means regressions in contract parsing or service behavior will go undetected.

**Acceptance criteria**:
- [ ] `test/features/onboarding/services/onboarding_service_test.dart` exists and covers flag persistence (completed/dontShowAgain → isOnboardingNeeded), first-launch detection, and Hive-backed caching.
- [ ] `test/core/data/contracts/plan_adherence_contract_test.dart` and `test/core/data/contracts/session_query_contract_test.dart` cover JSON deserialization, null handling, and query building.
- [ ] `test/core/data/models/markscheme_model_test.dart` exists at the correct location (or test is moved from `test/features/questions/`).
- [ ] `test/core/services/session_plan_adherence_service_test.dart` covers adherence computation logic.

### M2 — Unit tests placed in presentation screen test files (3 files)

These files in `test/*/presentation/` directories contain **only unit tests** (model tests) and **zero widget tests**. The file name suggests they should test the screen, but they test the model instead.

| Misplaced file | Contains tests for |
|---|---|
| `test/features/ingestion/presentation/content_library_screen_test.dart` | Source model (`createdAt`, `copyWith`, JSON roundtrip) |
| `test/features/ingestion/presentation/source_detail_screen_test.dart` | Source model (`createdAt`, `fromJson`) |
| `test/features/questions/presentation/question_bank_screen_test.dart` | Question model (`model` field, `sourceIds`, `subjectId`) |

**Rationale**: Violates test file placement conventions. The same model tests already exist in the correct `test/features/*/data/models/` directories. These files should be either (a) converted to actual widget tests, or (b) removed if duplicate.

**Acceptance criteria**:
- [ ] Each of the three files is either converted to a real widget test (using `testWidgets`, `ProviderScope` with overrides, and `NavigatorObserver` for navigation) or deleted.
- [ ] No duplicate model tests exist across presentation and data/model directories.

### M3 — Unit and widget tests mixed in same file (4 files)

AGENTS.md mandates: *"Keep unit tests and widget tests in separate files — never mix them in the same file."*

| File | `test()` calls | `testWidgets()` calls |
|---|---|---|
| `test/features/dashboard/presentation/widgets/export_section_test.dart` | 7 | 4 |
| `test/features/settings/data/models/settings_box_test.dart` | 13 | 1 |
| `test/features/settings/data/models/settings_model_test.dart` | 42 | 1 |
| `test/features/subjects/providers/topic_repository_provider_test.dart` | 7 | 1 |

**Rationale**: Mixing test types makes files harder to maintain and violates the project convention. The widget test in `export_section_test.dart` (testing `ExportSection`) belongs in a widget test file; the static method tests (`formatInstrumentation`) belong in a unit test file.

**Acceptance criteria**:
- [ ] Each file above is split into two files: one pure unit test and one pure widget test.
- [ ] The unit-only halves remain in the same directory; widget-only halves use `*_widget_test.dart` suffix or stay in the presentation directory as appropriate.

### M4 — Widget test using real StudentIdService with Hive I/O

AGENTS.md says: *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."*

**Violation**: `test/features/sessions/presentation/session_tracker_screen_test.dart` calls `StudentIdService().setStudentId('test-student')` directly. This instantiates a real `StudentIdService` that touches Hive (file I/O).

**Rationale**: Widget tests that touch Hive are fragile (require Hive initialization), slower (I/O), and can leak state between tests. Using `fixedStudentId` (a constructor parameter) eliminates this dependency entirely.

**Acceptance criteria**:
- [ ] `session_tracker_screen_test.dart` uses `fixedStudentId` instead of `StudentIdService().setStudentId()`.
- [ ] No other widget test files call `StudentIdService().setStudentId()` directly.

### M5 — Widget tests missing NavigatorObserver for navigation verification

AGENTS.md says: *"Use `NavigatorObserver` for verifying navigation behavior."*

**Missing NavigatorObserver** (with navigation-capable screens):
| Widget test file | Has NavigatorObserver? |
|---|---|
| `test/features/dashboard/presentation/dashboard_screen_test.dart` | NO |
| `test/features/lessons/presentation/topic_list_screen_test.dart` | NO |

**Rationale**: These screens include navigation actions (tap to navigate to another screen). Without `NavigatorObserver`, tests cannot assert the correct route was pushed.

**Acceptance criteria**:
- [ ] `dashboard_screen_test.dart` injects a `NavigatorObserver` and verifies navigation on tap.
- [ ] `topic_list_screen_test.dart` injects a `NavigatorObserver` and verifies navigation on topic tap.

### M6 — Error-state test coverage gaps

While many provider tests cover error paths well (`planner_providers_test.dart`: 15+ error paths; `dashboard_data_providers_test.dart`: null/exception handling), several service-layer tests lack error-state coverage:

| Service | Error states not tested |
|---|---|
| `MentorService` (`mentor_service_test.dart`) | `checkWellbeingAndGenerateNudges()` exception propagation, planner service failures |
| `TutorService` (`tutor_service_test.dart`) | LLM service failures, conversation manager timeout |
| `ExerciseEvaluator` (`exercise_evaluator_test.dart`) | Malformed LLM response parsing |
| `SessionExportService` (`session_export_service_test.dart`) | Repository failure during CSV generation |
| `StudyTimerService` (`study_timer_service_test.dart`) | Timer cancellation/error recovery |

**Rationale**: Services that interact with LLM or Hive can fail in production. Tests should verify graceful error handling (e.g., `Result.failure` returns, empty lists, fallback defaults) rather than crashing or propagating raw exceptions.

**Acceptance criteria**:
- [ ] Each listed service test file adds at least one test for each thrown exception or `Result.failure` return path.
- [ ] Error-state tests assert specific behavior (fallback value, error state in provider, user-facing message) rather than just verifying that an exception was thrown.

### M7 — `MentorService` tests missing required fake overrides

AGENTS.md specifies required fakes for `MentorService` tests: `FakePlannerService`, `FakeEngagementNudgeRepository`, `FakeSessionRepository`, `FakeMasteryGraphService`, `FakeProgressTracker`. Each must override specific methods listed in the conventions table.

**Violation**: Some fakes in `mentor_service_test.dart` or `mentor_screen_test.dart` may not override all required methods. Missing overrides cause tests to call real implementations (if available) or throw `UnimplementedError` at runtime.

**Acceptance criteria**:
- [ ] All five fake classes in mentor tests override every method listed in the AGENTS.md conventions table.
- [ ] `mentor_service_test.dart` explicitly wires all five fakes through provider overrides.

---

## MINOR

### m1 — Barrel export tests with construction-only checks (3 files)

These tests verify only that barrel files export types — no behavioral assertions.

| File | Assertion type |
|---|---|
| `test/core/utils/utils_test.dart` | 2× `isA<Type>()` |
| `test/core/widgets/widgets_test.dart` | 4× `isA<Type>()` |
| `test/features/onboarding/onboarding_test.dart` | 4× `isNotNull` |

**Rationale**: Per AGENTS.md's Provider Test Coverage Bar, these aren't provider tests, so the behavioral-assertion rule doesn't formally apply. However, these tests provide near-zero value. Either remove them or add a meaningful assertion (e.g., verify the exported type has expected properties).

**Acceptance criteria**:
- [ ] Each barrel test is either removed or expanded to include a behavioral assertion (e.g., instantiate the exported type and verify a property).

### m2 — `markscheme_model` test in wrong location

`lib/core/data/models/markscheme_model.dart` is a **core** model, but its test lives at `test/features/questions/data/models/markscheme_model_test.dart` instead of `test/core/data/models/markscheme_model_test.dart`.

Per AGENTS.md: `lib/core/data/**/*.dart` → `test/core/data/**/*_test.dart`.

**Rationale**: Misplaced tests are harder to discover when onboarding new developers or running targeted test suites.

**Acceptance criteria**:
- [ ] Test is moved (or symlinked) to `test/core/data/models/markscheme_model_test.dart`.
- [ ] `test/features/questions/data/models/markscheme_model_test.dart` is removed.

### m3 — Missing test for `notification_channel_ids.dart` and `timeouts.dart`

These files in `lib/core/constants/` lack any test coverage. While not required by AGENTS.md (no explicit mapping exists for `lib/core/constants/`), identical files in the same directory **do** have tests (`app_constants_test.dart`, `app_config_test.dart`, `security_config_test.dart`, etc.), making these an inconsistency.

**Rationale**: Inconsistent coverage within the same directory.

**Acceptance criteria**:
- [ ] `test/core/constants/notification_channel_ids_test.dart` exists and verifies channel ID uniqueness and format.
- [ ] `test/core/constants/timeouts_test.dart` exists and verifies timeout values are positive and internally consistent.

### m4 — Integration tests limited in scope

Four integration test files exist (total 1463 lines) covering dashboard↔planner, mentor↔sessions, practice↔teaching, and a basic e2e flow. Missing integration coverage:

- **Onboarding → App**: No test verifies that completing onboarding transitions to the main app correctly.
- **Settings → Providers**: No test verifies that changing a setting (e.g., theme mode) propagates through providers to visible widgets.
- **Full cycle**: No test exercises the complete flow: ingest source → generate questions → practice → review results.

**Rationale**: Integration tests catch cross-feature regressions that unit tests miss. The onboarding and settings gaps are particularly notable because these are cross-cutting features.

**Acceptance criteria**:
- [ ] At least one integration test covers onboarding completion → app launch flow.
- [ ] At least one integration test covers settings change → provider → widget visibility.
- [ ] Add a flow test covering a full practice cycle from source ingestion to results review.

---

## Convention Compliance Summary

| Convention | Status |
|---|---|
| Hand-written fakes, no mockito/mocktail | ✅ Pass (zero mockito/mocktail imports found) |
| `ProviderScope` with `overrides` for provider stubbing | ✅ Pass (all widget tests use this pattern) |
| `fixedStudentId` over `StudentIdService` in widget tests | ⚠️ One violation (M4) |
| `pumpAndSettle` for async widget tests | ✅ Pass (64 files use it) |
| `NavigatorObserver` for navigation verification | ⚠️ 2 widget tests missing it (M5) |
| Unit and widget tests in separate files | ⚠️ 4 violations (M3) |
| Behavioral assertions in provider tests | ✅ Pass (all provider tests have behavioral assertions) |
| Proper model adapter test placement | ⚠️ 1 misplacement (m2) |
| Error-state coverage for services | ⚠️ 5 services with gaps (M6) |
| MentorService required fakes | ⚠️ Needs verification (M7) |
