# Test Master — Coverage & Convention Audit

Audit date: 2026-05-20  
Scope: `lib/` (features + core) vs `test/`, cross-referenced against `AGENTS.md`

---

## BLOCKER

### B1 — 4 source files have zero test coverage

| Source | Expected test location | File type |
|---|---|---|
| `lib/core/widgets/splash_screen.dart` | `test/core/widgets/splash_screen_test.dart` | Widget (navigation entry point) |
| `lib/core/providers/shared_providers.dart` | `test/core/providers/shared_providers_test.dart` | Provider (wires shared state) |
| `lib/core/providers/service_providers.dart` | `test/core/providers/service_providers_test.dart` | Provider (wires core services) |
| `lib/features/dashboard/presentation/widgets/absence_banner.dart` | `test/features/dashboard/presentation/widgets/absence_banner_test.dart` | Widget (renders absence warning) |

**Rationale**: Splash screen is the app entry point — untested means startup failures are silent. `shared_providers.dart` and `service_providers.dart` wire core services together; a miswiring causes cascading failures. The `absence_banner` is shown to users on the dashboard.

**Acceptance**: Each file gets a corresponding test file. Provider tests must include behavioural assertions (dependency wiring, fallback, or error-state). Widget tests must use `NavigatorObserver` for navigation checks.

---

### B2 — Exact duplicate widget test files waste CI time and cause maintenance drift

**Files** (identical content, 0 lines differ):
- `test/core/services/prerequisite_check_widget_test.dart`
- `test/core/services/prerequisite_check_service_widget_test.dart`

**Impact**: Both files run the same 3 widget tests in CI, doubling execution time for no benefit. Updates to one are not reflected in the other.

**Acceptance**: Keep the correctly-named file (`prerequisite_check_service_widget_test.dart` — matched to the source service name) and delete the duplicate.

---

## MAJOR

### M1 — 11 test files live in wrong directories (violate AGENTS.md §Test File Placement)

| Source (lib/) | Current test (wrong) | Expected location |
|---|---|---|
| `core/data/repositories/session_repository.dart` | `test/features/sessions/data/repositories/session_repository_test.dart` | `test/core/data/repositories/session_repository_test.dart` |
| `core/data/repositories/engagement_nudge_repository.dart` | `test/features/planner/data/repositories/engagement_nudge_repository_test.dart` | `test/core/data/repositories/engagement_nudge_repository_test.dart` |
| `core/data/repositories/plan_adherence_repository.dart` | `test/features/planner/data/repositories/plan_adherence_repository_test.dart` | `test/core/data/repositories/plan_adherence_repository_test.dart` |
| `core/data/repositories/attempt_repository.dart` | `test/features/practice/data/repositories/attempt_repository_test.dart` | `test/core/data/repositories/attempt_repository_test.dart` |
| `core/data/repositories/topic_repository.dart` | `test/features/subjects/data/repositories/topic_repository_test.dart` | `test/core/data/repositories/topic_repository_test.dart` |
| `core/data/repositories/question_mastery_state_repository.dart` | `test/features/practice/data/repositories/question_mastery_state_repository_test.dart` | `test/core/data/repositories/question_mastery_state_repository_test.dart` |
| `core/data/repositories/mastery_state_repository.dart` | `test/features/practice/data/repositories/mastery_state_repository_test.dart` | `test/core/data/repositories/mastery_state_repository_test.dart` |
| `core/data/models/mastery_state_model.dart` | `test/features/practice/data/models/mastery_state_model_test.dart` | `test/core/data/models/mastery_state_model_test.dart` |
| `core/data/models/question_mastery_state_model.dart` | `test/features/practice/data/models/question_mastery_state_model_test.dart` | `test/core/data/models/question_mastery_state_model_test.dart` |
| `core/data/models/mastery_improvement_metric_model.dart` | `test/features/practice/data/models/mastery_improvement_metric_model_test.dart` | `test/core/data/models/mastery_improvement_metric_model_test.dart` |
| `core/utils/difficulty_controller.dart` | `test/features/practice/services/difficulty_controller_test.dart` | `test/core/utils/difficulty_controller_test.dart` |

**Rationale**: Violates the explicit mapping table in AGENTS.md. Convention exists so every developer can immediately locate tests without guessing which feature "owns" core code. Discovery tools (`glob`, IDE navigation) also fail to find these tests.

**Acceptance**: Move each test file to the expected location (or create a forwarding symlink if both `core/` and `features/` consumers are expected). Update any package import paths inside the moved files. Ensure `import` paths reference the correct source location (e.g. `../../../../core/...` for `test/core/` tests).

---

### M2 — 7 service test files have zero or near-zero error-state coverage

Per AGENTS.md §Error Handling Conventions, public repository/service methods return `Result<T>`. Error paths must be tested.

| File | Gap |
|---|---|
| `test/features/sessions/services/session_export_service_test.dart` | No tests for file write failures, nonexistent directories, invalid session data, or I/O errors. All 385 lines are happy-path. |
| `test/features/teaching/services/exercise_evaluator_test.dart` | No tests for invalid evaluation parameters, LLM failures, or malformed responses. |
| `test/features/teaching/services/conversation_phase_test.dart` | Tests state transitions only — no dependency-throws or error-return scenarios. |
| `test/features/practice/services/question_type_localizer_test.dart` | No tests for null/invalid question types or edge cases in locale resolution. |
| `test/features/ingestion/services/extraction_result_test.dart` | No failure-path tests for extraction errors or malformed chunk data. |
| `test/features/sessions/services/session_migration_service_test.dart` | No tests for migration failure, data corruption, or invalid JSON in old format. |
| `test/features/focus_mode/services/focus_practice_service_test.dart` | Only tests error path for `getDueQuestions`. Missing: `startPracticeSession` repo failure, `endPracticeSession` save failure. |

**Examples of well-covered files to follow**: `test/features/practice/services/mistake_review_service_test.dart` (dedicated `error-state: repository failures` group), `test/features/planner/services/planner_service_test.dart`, `test/features/ingestion/services/web_scraper_test.dart`.

**Acceptance**: Each file gains at least one error-group with tests like "returns failure when dependency throws", "handles malformed input", "returns fallback on error". Use `catch`-friendly fake classes that can be configured to throw or return `Result.failure(...)`.

---

### M3 — 4 widget test files depend on real Hive I/O instead of `fixedStudentId` + fake repos

Convention (AGENTS.md §Test Patterns): "Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests."

| File | Hive I/O usage |
|---|---|
| `test/features/practice/presentation/screens/exam_session_screen_additional_test.dart` | `Hive.init('/tmp/hive_test')` + `Hive.deleteFromDisk()` (lines 170-175). Uses `_FakeStudentIdService` but still initialises real Hive. |
| `test/features/planner/presentation/planner_screen_test.dart` | 5+ `Hive.init()` calls scattered across setUp/helpers |
| `test/features/planner/presentation/widgets/syllabus_progress_card_test.dart` | `Hive.init(hivePath)` (line 16) |
| `test/main_screen_test.dart` | `Hive.init(dir.path)` (line 192) — integration test, but still couples to disk I/O |

**Rationale**: Real Hive I/O makes tests slower, flaky (temp directory cleanup races), and introduces a dependency on the Hive binary format. The project convention explicitly prefers `fixedStudentId`/fake repos.

**Acceptance**: Eliminate `Hive.init()` and `Hive.deleteFromDisk()` from all widget tests. Use `ProviderScope` overrides with fake repositories and `fixedStudentId` where applicable. For `main_screen_test.dart`, document why Hive is acceptable if unavoidable, or refactor to an integration test pattern with explicit Hive boxing.

---

## MINOR

### m1 — `not_found_screen_test.dart` does not verify navigation via `NavigatorObserver`

**File**: `test/core/widgets/not_found_screen_test.dart`  
**Issue**: The screen has a `FilledButton` labelled "Go to Dashboard", but the test only asserts the button exists (`findsOneWidget`). It does NOT verify that pressing the button triggers navigation.

AGENTS.md: "Use `NavigatorObserver` for verifying navigation behavior."

**Acceptance**: Add a `TestNavigatorObserver`, tap the button, and assert `observer.pushedRoutes` contains the expected dashboard route.

### m2 — `coverage_gaps_integration_test.dart` is misnamed and misplaced

**File**: `test/features/practice/services/coverage_gaps_integration_test.dart`  
**Issue**: Despite the name, this file contains pure unit tests (no `pumpWidget`, no UI) for 9 different classes across 4 features. It tests `SpacedRepetitionService`, `SpacedRepetitionEngine`, `MasteryRecorder`, `ExamSessionService`, `MistakeReviewService`, `DifficultyController`, `ReadinessScorer`, `PracticeDataService`, and `PracticeSessionService` — all in one bloated 1600+ line file.  

It is a **test gap patch**, not an integration test. The name is misleading for CI triage.

**Acceptance**: Split into individual focused test files placed in each class's correct test directory. Retain error-state edge cases that the main test files miss. Update the CI/squad configuration if this file is listed anywhere.

### m3 — `session_export_service_test.dart` uses `toStringAsFixed()` for locale-invariant assertions

**File**: `test/features/sessions/services/session_export_service_test.dart`  
**Issue**: The test asserts `expect(csv, contains('70.0'))` and `expect(csv, contains('0.0'))` (lines 119, 127). CSV is explicitly allowed to use invariant `en` format per AGENTS.md §i18n, so this is *technically* correct. However, the test also checks `expect(csv, contains('61.0'))` (line 178) which comes from `Session.durationMinutes` computed via `toStringAsFixed(1)`. If that method is ever locale-wrapped, the test would break.  
**Severity**: Low — but worth documenting that CSV tests must remain invariant-en only.

**Acceptance**: Add a comment explaining why the decimal format assertions are correct for CSV, or extract a CSV decimal formatter to keep locale separation explicit.

---

## Summary

| Priority | Count | Key action required |
|---|---|---|
| BLOCKER | 2 (B1, B2) | Create 4 missing test files; delete 1 duplicate |
| MAJOR | 3 (M1–M3) | Move 11 files to correct dirs; add error-state coverage to 7 files; remove Hive I/O from 4 widget tests |
| MINOR | 3 (m1–m3) | Add NavigatorObserver to 1 file; split 1 bloated file; document CSV locale invariant |

**Total actionable items**: 8 groups covering 25+ files.
