# Test: Critical Coverage Gaps — Planner Roadmaps Tab Entirely Untested, SessionExportService Uncovered, and Test Structure Deficiencies

## Context

A systematic audit of the 133 test files across 161 source `.dart` files reveals coverage gaps that expose the highest-risk feature code to undetected regressions. The most critical findings are: (1) the Planner screen's **Roadmaps tab** (~400 lines of business logic, dialog flows, and conditional rendering) has zero test coverage despite being a core feature; (2) `SessionExportService` (198 lines, CSV/JSON/PDF export with file I/O and sharing) is entirely untested; (3) `MentorScreen` (314 lines, `ConsumerStatefulWidget` with streaming chat) has no presentation-layer test; and (4) the few tests that exist for the Planner screen depend on the real `StudentIdService` singleton, creating a fragile, non-deterministic test environment. Additionally, test file placement is inconsistent across features.

## Affected Files

### Critical Untested Source Files

| File | Lines | Risk | Missing Coverage |
|------|-------|------|------------------|
| `test/features/planner/presentation/planner_screen_test.dart` | 396 | **Roadmaps tab at 0% coverage.** The test file has 13 test cases covering only the "Study Plan" tab. The `_createRoadmap` dialog flow, `_loadRoadmaps` loading/error/empty states, `_buildRoadmapCard` rendering (status badge, progress bar, milestone timeline, target completion date), `_buildMilestoneTimeline` layout logic, `_openTutorMode` navigation, edge case milestone positioning (zero-duration plans, single milestone, many milestones), and the `_isLoadingRoadmaps` spinner state are completely untested. | ~15+ widget tests |
| `lib/features/sessions/services/session_export_service.dart` | 198 | **Zero tests for data export — a user-facing output path.** Tests needed: `sessionsToCSV` CSV escaping (commas, quotes, newlines in fields), accuracy formatting when `questionsAnswered == 0`, `sessionsToJSON` correctness, `sessionsToPDF` empty-session and single-session edge cases, `_formatDuration` and `_formatTotalDuration` rounding, error handling in `shareCSV`/`shareJSON`/`sharePDF` when temp directory fails, and null/invalid session data. | ~10+ unit tests |
| `lib/features/mentor/presentation/mentor_screen.dart` | 314 | **Zero presentation-layer tests.** The `MentorService` layer has unit tests, but the `ConsumerStatefulWidget` (streaming chat, text input, scroll controller, initialization via Riverpod, `_isSending` guard, error states, empty state) is entirely uncovered. | ~10+ widget tests |

### Test Quality Deficiencies in Existing Tests

| File | Issue |
|------|-------|
| `test/features/planner/presentation/planner_screen_test.dart:365` | Uses `StudentIdService().getStudentId()` (a singleton that opens a Hive box). This introduces a real I/O dependency into widget tests, creates non-deterministic student IDs across runs, and can cause cascading failures if Hive initialization is not correctly set up in the test environment. The service should be injectable or stubbed. |
| `test/features/planner/presentation/planner_screen_test.dart:82` | `_loadExistingPlan()` silently catches all exceptions (`catch (_) {}`), but there is no test verifying this silent-catch behavior or that the screen remains in an empty state when the repository throws. |
| `test/features/planner/presentation/planner_screen_test.dart:78` | There is no test for the edge case where `_planRepo.init()` throws, even though the real `PlanRepository.init()` calls `Hive.box()` which can fail. |
| `test/features/planner/presentation/planner_screen_test.dart:200-224` | The "generate plan with valid data" test uses the real `PlannerScreen` which calls `PersonalLearningPlanService.generatePlan()` internally — meaning this test is actually an integration test of the whole generation pipeline, not a unit test of the screen's UI. It depends on internal service behavior and could break for reasons unrelated to the screen's rendering. |
| `test/features/planner/presentation/planner_screen_test.dart` | No tests for: negative or zero days/hours input, extremely large numbers, empty course name with valid numbers, non-numeric input in numeric fields, or the `FocusTraversalGroup` wrapping the study plan form. |

### Test Structure & Placement Inconsistencies

Several patterns undermine discoverability and CI efficiency:

- **Missing `services/` test directories**: `lib/features/sessions/services/session_export_service.dart` has no corresponding `test/features/sessions/services/` directory. Same pattern applies to `lib/features/practice/providers/practice_providers.dart` (no `test/features/practice/providers/`).
- **Inconsistent model test locations**: Models are tested under `test/core/data/models/` for core models but under `test/features/subjects/models/` for feature models and `test/models/` for settings — there is no convention enforced.
- **Missing data-layer tests**: The `lib/features/planner/` directory has no `data/` or `services/` subdirectories; all planner logic lives in `core/data/repositories/` and `core/services/`, making it unclear where module-level repository tests should go.
- **Unit vs widget test blurring**: The planner test file mixes widget-rendering assertions with integration-level generation flow validation, making it harder to isolate failures and run targeted test suites.

## Rationale

1. **Roadmaps tab is a core feature area, not a secondary detail.** It encompasses dialog-based user input, async repository operations, error handling, date-based milestone calculations, and multi-state conditional rendering (loading spinner, empty state, roadmap cards, milestone timeline). Leaving this untested means every refactor or enhancement to roadmaps risks regression with no safety net. The fact that adjacent study-plan tab has 13 tests while the roadmaps tab has zero is a disproportionate coverage gap.

2. **Session export is a data-critical output path.** CSV escaping bugs can corrupt exported data; PDF generation errors produce broken files for users; sharing failures silently fail since `shareCSV`/`shareJSON`/`sharePDF` catch no exceptions from file operations. These are I/O-heavy paths that are expensive to test manually but cheap to test programmatically.

3. **Mentor screen is a complex consumer-stateful widget** with Riverpod integration, streaming responses, scroll-to-bottom behavior, and sending guards. Current `mentor_service_test.dart` tests only the service layer, missing the entire UI state machine that users interact with.

4. **Planner test's use of `StudentIdService` singleton** makes the test suite vulnerable to test-ordering issues (shared mutable state in a singleton) and environment dependencies (Hive box initialization). A true unit test should inject stubs for all external dependencies.

5. **Inconsistent test file placement** forces developers to guess where to put new tests, leads to duplicated test setup code, and slows CI by mixing fast unit tests with slow widget/integration tests in the same file.

## Acceptance Criteria

### A. Planner Screen — Roadmaps Tab Coverage
- [ ] `test/features/planner/presentation/planner_screen_test.dart` gains tests for the roadmaps tab:
  - [ ] `_loadRoadmaps` shows `CircularProgressIndicator` while loading
  - [ ] `_loadRoadmaps` shows the empty-state icon and message (`noRoadmapsYet`, `roadmapGoalHint`) when no roadmaps exist
  - [ ] `_loadRoadmaps` shows a `ListView` of `_buildRoadmapCard` widgets when roadmaps exist (verify card renders status badge, goal text, progress bar, milestone count, target completion date)
  - [ ] `_loadRoadmaps` error path does not crash and shows the empty state
  - [ ] Tapping "Create Roadmap" opens an `AlertDialog` with goal and days fields
  - [ ] Cancelling the roadmap dialog does not create a roadmap
  - [ ] Submitting empty goal cancels creation
  - [ ] Submitting valid goal creates a roadmap and shows success snackbar
  - [ ] Roadmap card `_buildMilestoneTimeline` renders milestones correctly (completed, past-due, future milestone colors; zero milestones shows empty; multiple milestones render within width constraints)
  - [ ] `_openTutorMode` triggers navigation when topic ID is non-empty
  - [ ] Plan tab's `_generatePlan` validates edge cases: zero/negative days/hours, non-numeric input, empty course

### B. Planner Screen — Test Quality Improvements
- [ ] `StudentIdService` dependency is removed from the test — inject a stub or use a configurable fake
- [ ] `_loadExistingPlan` silent-catch behavior is explicitly tested (verify screen shows no plan when repository throws)
- [ ] `_planRepo.init()` failure path in `initState` does not crash the screen

### C. SessionExportService Tests
- [ ] `test/features/sessions/services/session_export_test.dart` created with:
  - [ ] `sessionsToCSV` produces correct header row
  - [ ] `sessionsToCSV` CSV-escapes commas, quotes, and newlines in fields
  - [ ] `sessionsToCSV` formats accuracy as `0.0` when `questionsAnswered == 0`
  - [ ] `sessionsToCSV` rounds duration to 1 decimal place
  - [ ] `sessionsToJSON` returns correct `List<Map<String, dynamic>>` matching `toJson()`
  - [ ] `sessionsToJSON` handles empty list
  - [ ] `_formatDuration` correctly formats minutes+seconds and just-seconds cases
  - [ ] `_formatTotalDuration` handles hours+minutes, just-minutes, and zero
  - [ ] `sessionsToPDF` produces non-empty bytes for a non-empty session list
  - [ ] `sessionsToPDF` produces non-empty bytes for an empty session list (no crash)

### D. Mentor Screen — Presentation Layer Tests
- [ ] `test/features/mentor/presentation/mentor_screen_test.dart` created with:
  - [ ] Screen renders initial chat input and send button
  - [ ] Loading state during `_initializeMentor` is shown
  - [ ] Error state renders error message
  - [ ] Sending a message disables input and shows sending indicator
  - [ ] Streamed responses render as chat bubbles
  - [ ] Scroll controller auto-scrolls on new messages
  - [ ] Empty state shows welcome/placeholder message

### E. Test Structure Standardization
- [ ] Feature-level convention established in `AGENTS.md` or `CONTRIBUTING.md`:
  - Every `lib/features/*/services/` file → `test/features/*/services/` test
  - Every `lib/features/*/data/repositories/` file → `test/features/*/data/repositories/` test  
  - Every `lib/features/*/providers/` file → `test/features/*/providers/` test
  - Unit tests and widget tests are in separate files (not mixed)
- [ ] `test/features/sessions/services/` directory created with `session_export_test.dart`
- [ ] `test/features/practice/providers/` directory created with `practice_providers_test.dart`
- [ ] `test/features/mentor/presentation/` directory created with `mentor_screen_test.dart`
