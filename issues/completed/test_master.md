# Test Coverage Quality & Structural Gaps

## Context

The test suite is **complete by file count** — every source widget, service, provider, repository, model, and adapter has a matching test file. However, many tests are **superficial, missing assertions, or omit critical scenarios**. Additionally, **85 `_Fake*` classes are duplicated** across files rather than shared, creating maintenance fragility.

---

## Issue 1 — Vacuous Tests (no assertions)

Two tests in `plan_summary_card_test.dart` call `pumpWidget` but never call `expect` — they pass trivially and provide zero coverage value.

**Files:**
- `test/features/planner/presentation/widgets/plan_summary_card_test.dart:71` — `shows estimated coverage percentage` (no assertions)
- `test/features/planner/presentation/widgets/plan_summary_card_test.dart:104` — `does not show focus areas section when empty` (no assertions)

**Rationale:** These tests create a widget with specific data but verify nothing. They give a false sense of coverage and waste CI time.

**AC:** Both tests should contain appropriate `expect` calls (e.g. verifying the coverage % text renders, verifying focus area text is absent).

---

## Issue 2 — Duplicate Identical Test

Two tests in `planner_screen_test.dart` assert exactly the same thing.

**Files:**
- `test/features/planner/presentation/planner_screen_test.dart:304` — `shows title and form fields`
- `test/features/planner/presentation/planner_screen_test.dart:315` — `shows title and form labels`

Both pump the same widget and assert `find.text('Study Planner')`, `find.text('Create Study Plan')`, `find.text('Generate Plan')`.

**Rationale:** Duplicate tests increase maintenance burden without improving coverage.

**AC:** Remove the duplicate (`shows title and form labels`) or differentiate it with a unique assertion.

---

## Issue 3 — Incomplete / Misleading Test Scenarios

### 3a. "duration can be decreased" never decreases
`lesson_booking_sheet_test.dart:170` — test name promises a decrease interaction but only checks the initial `'30 minutes'` text. The decrease button is never tapped.

**Fix:** Tap `Icons.remove_circle_outline` and verify `'15 minutes'` appears.

### 3b. ProgressOverlayWidget color tests only check text, not color
`progress_overlay_widget_test.dart:37-65` — Three tests ("green/50%/red" for 100%/50%/30%) only assert the percentage text string. The actual `progressColor` logic determining green/orange/red is never verified.

**Fix:** Check for specific `Color` values on the rendered container or progress bar using `tester.widget`.

### 3c. CalendarViewWidget misses key behaviors
`calendar_view_widget_test.dart` — covers month header, day cells, and navigation, but misses:
- Tapping a day **without** topics (no `onDayTap` fire)
- Rest day rendering in calendar
- Empty plan (zero `dailyPlans`)
- Month-boundary navigation (Dec → Jan)

**Fix:** Add tests for each edge case.

### 3d. LessonBookingSheet: conflict UI untested
The source widget has a `_hasConflict` flag showing a `warning_amber_rounded` icon and a red container, plus a `SnackBar` when scheduling with a conflict. None of these paths are tested.

**Fix:** Add tests for conflict detection rendering and conflict-blocked scheduling.

### 3e. PlannerScreen: "Pending Actions" tab untested
The 1408-line `planner_screen_test.dart` covers "Study Plan" and "Roadmaps" tabs thoroughly, but never switches to the "Pending Actions" tab.

**Fix:** Add tests for the Pending Actions tab — empty state, list rendering, accept/dismiss interactions.

---

## Issue 4 — Massive Duplication of Fake Classes (85 classes)

**85 `_Fake*` classes** are defined across the test suite, with identical fakes for the same repository/service repeated across files:

| Fake Class | Files where duplicated |
|---|---|
| `_FakeSessionRepository` | `session_history_screen_test`, `subject_detail_screen_test`, `subject_history_tab_test`, `subject_stats_tab_test`, `dashboard_data_loader_test`, `practice_session_service_test`, `engagement_scheduler_test`, `session_tracker_screen_test`, `planner_screen_test` |
| `_FakeTopicRepository` | `planner_screen_test`, `lesson_service_test`, `dashboard_data_loader_test`, `topic_list_screen_test`, `upload_screen_test`, `database_service_test` |
| `_FakeMasteryGraphRepository` | `planner_screen_test`, `dashboard_screen_test` |
| `_FakeQuestionRepository` | `practice_data_service_test`, `practice_screen_test`, `database_service_test`, `main_screen_test`, `question_repository_test` |

**Root Cause:** There are no shared test utility or `test_helpers` directories. Each test file reinvents its own fakes.

**Rationale:** When a repository interface changes, every file with its duplicate fake must be updated. This has already caused inconsistency (some fakes use `noSuchMethod`, others don't; some implement all methods, others only partial).

**AC:** Extract shared fake classes into `test/helpers/` or per-feature `test/features/*/helpers/`. Each repository/service should have exactly one canonical fake used across the suite.

---

## Acceptance Criteria (Summary)

1. Add assertions to the two vacuous tests in `plan_summary_card_test.dart`.
2. Remove the duplicate planner screen test.
3. Add the missing interaction/assertion to `lesson_booking_sheet` duration decrease test.
4. Verify actual rendered colors (not just text) in `progress_overlay_widget` color tests.
5. Add edge-case tests to `calendar_view_widget`: empty plan, rest day, no-topic tap.
6. Add conflict-UI and conflict-blocking tests to `lesson_booking_sheet`.
7. Add "Pending Actions" tab tests to `planner_screen_test`.
8. Extract the 85 duplicated `_Fake*` classes into shared test helpers.
