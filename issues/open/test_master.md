# Test Coverage & Convention Compliance Audit

## Summary

Cross-referenced 263 source files in `lib/features/*/` against AGENTS.md test conventions. **15 source files lack test coverage entirely.** Beyond missing files, the codebase has significant gaps in error-state testing (25 files), mixed unit/widget tests (2 files), unnecessary Hive I/O in widget tests, and anomalous test file placement.

---

## BLOCKER — App crashes or user cannot proceed

*(None identified. All features have at least partial test coverage.)*

---

## MAJOR — Feature is broken or misleading

### M1: 15 source files missing corresponding test files

**Rationale:** AGENTS.md defines exact source-to-test mappings. Every source file without a test represents untested logic that can silently regress.

#### Lessons (1 missing)

| Source file | Expected test file |
|---|---|
| `lib/features/lessons/services/session_query_service.dart` | `test/features/lessons/services/session_query_service_test.dart` |

#### Planner (12 missing)

| Source file | Expected test file |
|---|---|
| `lib/features/planner/presentation/widgets/daily_plans_section.dart` | `test/features/planner/presentation/widgets/daily_plans_section_test.dart` |
| `lib/features/planner/presentation/widgets/roadmaps_tab.dart` | `test/features/planner/presentation/widgets/roadmaps_tab_test.dart` |
| `lib/features/planner/presentation/widgets/study_plan_tab.dart` | `test/features/planner/presentation/widgets/study_plan_tab_test.dart` |
| `lib/features/planner/presentation/widgets/multi_syllabus_input.dart` | `test/features/planner/presentation/widgets/multi_syllabus_input_test.dart` |
| `lib/features/planner/presentation/widgets/pace_adjustment_card.dart` | `test/features/planner/presentation/widgets/pace_adjustment_card_test.dart` |
| `lib/features/planner/presentation/widgets/subject_progress_tabs.dart` | `test/features/planner/presentation/widgets/subject_progress_tabs_test.dart` |
| `lib/features/planner/presentation/widgets/scheduled_lessons_section.dart` | `test/features/planner/presentation/widgets/scheduled_lessons_section_test.dart` |
| `lib/features/planner/presentation/widgets/missed_lessons_section.dart` | `test/features/planner/presentation/widgets/missed_lessons_section_test.dart` |
| `lib/features/planner/presentation/widgets/adherence_banner.dart` | `test/features/planner/presentation/widgets/adherence_banner_test.dart` |
| `lib/features/planner/presentation/widgets/pending_actions_section.dart` | `test/features/planner/presentation/widgets/pending_actions_section_test.dart` |
| `lib/features/planner/providers/plan_providers.dart` | `test/features/planner/providers/plan_providers_test.dart` |
| `lib/features/planner/services/planner_advisor_strategy.dart` | `test/features/planner/services/planner_advisor_strategy_test.dart` |

#### Questions (2 missing)

| Source file | Expected test file |
|---|---|
| `lib/features/questions/presentation/widgets/audio_recording_widget.dart` | `test/features/questions/presentation/widgets/audio_recording_widget_test.dart` |
| `lib/features/questions/presentation/widgets/file_upload_widget.dart` | `test/features/questions/presentation/widgets/file_upload_widget_test.dart` |

**Acceptance criteria:**
- Each missing test file exists at the expected path
- Widget tests use `ProviderScope` with overrides, `fixedStudentId`, and `NavigatorObserver`
- Service/repository tests stub dependencies with hand-written fakes
- Provider tests include behavioral assertions verifying dependency wiring

---

### M2: Mixed unit tests and widget tests in same file (2 files)

**Rationale:** AGENTS.md states: *"Keep unit tests and widget tests in separate files — never mix them in the same file."* Mixing them makes test organization unclear, complicates CI filtering, and allows logic tests to accidentally depend on widget infrastructure.

#### Affected files

| File | Pure `test()` blocks | `testWidgets()` blocks |
|---|---|---|
| `test/features/practice/presentation/widgets/confidence_selector_test.dart` | 6 (`getConfidenceColor`) | 12 |
| `test/features/practice/presentation/widgets/source_practice_sheet_status_test.dart` | 3 (`SourceItemData` constructor) | 5 |

**Acceptance criteria:**
- `getConfidenceColor` tests extracted to a separate unit test file (e.g., `test/features/practice/services/...` or alongside the source)
- `SourceItemData` constructor tests extracted to `test/features/practice/data/models/` (since `SourceItemData` is a model)
- The original files retain only `testWidgets` rendering tests

---

### M3: Unnecessary Hive I/O in widget test

**Rationale:** AGENTS.md says: *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."* The `session_tracker_screen_test.dart` widget test calls `Hive.init()` despite faking all repositories and already passing `fixedStudentId`.

#### Affected file

`test/features/sessions/presentation/session_tracker_screen_test.dart`:
- Line 6: `import 'package:hive_flutter/hive_flutter.dart';`
- Line 80: defines `_FakeStudentIdService extends StudentIdService` (redundant — `fixedStudentId` is already passed at line 115)
- Line 109: `studentIdServiceProvider.overrideWithValue(_FakeStudentIdService())` (redundant override)
- Line 128: `Hive.init(hivePath);` (unnecessary — no real Hive-backed repos used)
- Line 284: second `_FakeStudentIdService` override (redundant)

**Acceptance criteria:**
- Remove `import 'package:hive_flutter/hive_flutter.dart'`
- Remove `_FakeStudentIdService` class and all `studentIdServiceProvider` overrides
- Remove `Hive.init()` call
- Verify the test passes without any Hive initialization

---

### M4: 25 files missing error-state tests

**Rationale:** AGENTS.md mandates `Result<T>` return types for public repository and service methods. Tests that only verify success paths give false confidence — silent failures propagate through `Result.failure` paths undetected.

#### Core services (19 gaps — most critical)

| File | Notes |
|---|---|
| `test/core/services/secure_api_key_service_test.dart` | No error path tests at all |
| `test/core/services/answer_validation_service_test.dart` | No error path tests |
| `test/core/services/engagement_scheduler_test.dart` | Imports `Result` but no failure tests |
| `test/core/services/voice_service_test.dart` | Also uses empty `catch (_) {}` (see M5) |
| `test/core/services/student_id_service_test.dart` | No error path tests |
| `test/core/services/progress_export_service_test.dart` | No error path tests |
| `test/core/services/badge_service_test.dart` | "runs without errors" only, no failure propagation |
| `test/core/services/remaining_workload_estimator_test.dart` | No error path tests |
| `test/core/services/llm_usage_meter_test.dart` | No error path tests |
| `test/core/services/conversation_memory_test.dart` | Imports `Result` but no failure tests |
| `test/core/services/mastery_calculation_service_test.dart` | Edge-case tests only (zero inputs), no `Result.failure` |
| `test/core/services/notification_service_test.dart` | Also uses empty `catch (_) {}` (see M5) |
| `test/core/services/long_term_memory_test.dart` | No error path tests |
| `test/core/services/llm_agent/agent_tool_test.dart` | No error path tests |
| `test/core/services/llm_agent/idle_executor_test.dart` | No error path tests |
| `test/core/services/llm_agent/llm_agent_test.dart` | No error path tests |
| `test/core/services/llm_agent/agent_memory_test.dart` | No error path tests |
| `test/core/services/llm_agent/agent_loop_test.dart` | No error path tests |
| `test/core/services/prerequisite_check_service_ui_test.dart` | Widget test, no error-state testing |

#### Core data repositories (4 gaps)

| File | Notes |
|---|---|
| `test/core/data/repositories/question_mastery_state_repository_test.dart` | Happy-path only — no failure box |
| `test/core/data/repositories/topic_repository_test.dart` | Happy-path only — no failure box |
| `test/core/data/repositories/engagement_nudge_repository_test.dart` | Happy-path only — no failure box |
| `test/core/data/repositories/mastery_state_repository_test.dart` | Happy-path only — no failure box |

#### Feature repositories (2 gaps)

| File | Notes |
|---|---|
| `test/features/subjects/data/repositories/subject_repository_test.dart` | Fallback tests only, no Hive failure paths |
| `test/features/questions/data/repositories/question_repository_hive_test.dart` | Integration test — no error paths |

**Acceptance criteria:**
- Each service/repository test file includes a dedicated error-handling `group` or equivalent
- Repositories: inject a throwing fake box and verify `Result.failure` is returned
- Services: inject a throwing fake repository and verify the service returns `Result.failure` or handles gracefully
- Minimum coverage: at least one error-path test per public method that returns `Result<T>`

---

### M5: Empty `catch (_) {}` blocks in tests (2 files)

**Rationale:** AGENTS.md: *"Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message."* This applies to both production and test code.

#### Affected files

| File | Line numbers | Count |
|---|---|---|
| `test/core/services/notification_service_test.dart` | 23, 33, 40, 48, 55, 62, 69, 76, 83, 90, 97, 104, 111 | 13 |
| `test/core/services/voice_service_test.dart` | 37, 46, 55, 64, 79 | 5 |

**Acceptance criteria:**
- Each `catch (_) {}` is replaced with `catch (e) { /* log or assert */ }`
- Minimum: add a comment or an `expect` assertion inside each catch block
- Better: assert the caught exception type or verify error logging behavior

---

## MINOR — Code quality / UX friction

### m1: Misplaced test files

**Rationale:** Files that test data models belong in `test/features/*/data/models/`, not `presentation/widgets/`. Misplacement confuses future contributors and violates the AGENTS.md directory mapping.

#### Affected files

| File | Tests | Should be in |
|---|---|---|
| `test/features/dashboard/presentation/screens/topic_detail_screen_args_test.dart` | `TopicDetailArgs` constructor | `data/models/` (if model exists) |
| `test/features/practice/presentation/widgets/source_practice_sheet_test.dart` | `SourceItemData` model | `data/models/source_item_data_test.dart` |
| `test/features/questions/presentation/widgets/canvas_drawing_widget_test.dart` | `Stroke`, `DrawingPoint` models | `data/models/` |
| `test/features/questions/presentation/widgets/graph_drawing_widget_test.dart` | `Stroke` model with tool types | `data/models/` |

**Acceptance criteria:**
- Model tests are moved to the appropriate `data/models/` directory
- File renaming follows the AGENTS.md convention (`<model_name>_test.dart`)
- UI companion files (e.g., `canvas_drawing_widget_ui_test.dart`) remain in `presentation/widgets/`

---

## Conventions that PASSED inspection

The following areas were found to be fully compliant with AGENTS.md and require no action:

| Convention | Result |
|---|---|
| No mockito/mocktail usage | PASS — 0 violations out of 300+ test files |
| Provider tests include behavioral assertions beyond construction checks | PASS — all 21 provider test files verified |
| Provider tests verify dependency wiring via overrides | PASS — all 21 provider test files verified |
| NavigatorObserver used for navigation verification | PASS — 45/110 presentation files use it; no gaps in screen-level tests |
| Feature services test error states | PASS — 36/36 applicable files (3 are pure algorithm/static data, N/A) |

---

## Quick-reference checklist

### Create new test files (15)
- [ ] `test/features/lessons/services/session_query_service_test.dart`
- [ ] `test/features/planner/presentation/widgets/daily_plans_section_test.dart`
- [ ] `test/features/planner/presentation/widgets/roadmaps_tab_test.dart`
- [ ] `test/features/planner/presentation/widgets/study_plan_tab_test.dart`
- [ ] `test/features/planner/presentation/widgets/multi_syllabus_input_test.dart`
- [ ] `test/features/planner/presentation/widgets/pace_adjustment_card_test.dart`
- [ ] `test/features/planner/presentation/widgets/subject_progress_tabs_test.dart`
- [ ] `test/features/planner/presentation/widgets/scheduled_lessons_section_test.dart`
- [ ] `test/features/planner/presentation/widgets/missed_lessons_section_test.dart`
- [ ] `test/features/planner/presentation/widgets/adherence_banner_test.dart`
- [ ] `test/features/planner/presentation/widgets/pending_actions_section_test.dart`
- [ ] `test/features/planner/providers/plan_providers_test.dart`
- [ ] `test/features/planner/services/planner_advisor_strategy_test.dart`
- [ ] `test/features/questions/presentation/widgets/audio_recording_widget_test.dart`
- [ ] `test/features/questions/presentation/widgets/file_upload_widget_test.dart`

### Split mixed tests (2 files)
- [ ] Split `test/features/practice/presentation/widgets/confidence_selector_test.dart`
- [ ] Split `test/features/practice/presentation/widgets/source_practice_sheet_status_test.dart`

### Remove unnecessary Hive I/O
- [ ] Fix `test/features/sessions/presentation/session_tracker_screen_test.dart`

### Add error-state tests (25 files)
- [ ] 19 core service files (see M4 table)
- [ ] 4 core data repository files (see M4 table)
- [ ] 2 feature repository files (see M4 table)

### Fix empty catch blocks (2 files)
- [ ] `test/core/services/notification_service_test.dart` (13 blocks)
- [ ] `test/core/services/voice_service_test.dart` (5 blocks)

### Relocate misplaced tests (4 files)
- [ ] `topic_detail_screen_args_test.dart` → model tests directory
- [ ] `source_practice_sheet_test.dart` → model tests directory
- [ ] `canvas_drawing_widget_test.dart` → model tests directory
- [ ] `graph_drawing_widget_test.dart` → model tests directory
