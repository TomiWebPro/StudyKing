# Test Coverage & Structure Issues Across Features

## Context

The project has 15 feature directories under `lib/features/`. While many source files have corresponding tests (per the convention in `AGENTS.md`), several features have **zero widget test coverage**, tests placed in structurally wrong locations, overly bloated test files that duplicate coverage, and missing unit-test coverage for critical business-logic paths (partial failure states, state machines).

This issue consolidates four categories of findings. Each is actionable independently.

---

## 1. Missing Test Files (per `AGENTS.md` Convention)

The project convention states: *Every source file in `lib/features/*/` must have a corresponding test file.* The following source files have no test at all:

### Focus Mode

| Source | Expected Test |
|---|---|
| `lib/features/focus_mode/providers/focus_mode_providers.dart` | `test/features/focus_mode/providers/focus_mode_providers_test.dart` |

Defines two Riverpod providers (`focusSessionRepositoryProvider`, `focusSessionServiceProvider`) that are central to the focus-timer workflow. No tests verify provider resolution, override behavior, or container isolation.

### Lessons

| Source | Expected Test |
|---|---|
| `lib/features/lessons/presentation/widgets/lesson_list_item.dart` | `test/features/lessons/presentation/widgets/lesson_list_item_test.dart` |
| `lib/features/lessons/presentation/widgets/lesson_block_card.dart` | `test/features/lessons/presentation/widgets/lesson_block_card_test.dart` |

These two leaf widgets account for ~40% of the lesson feature's UI surface but are entirely untested.

### Planner

| Source | Expected Test |
|---|---|
| `lib/features/planner/presentation/widgets/roadmap_card.dart` | `test/features/planner/presentation/widgets/roadmap_card_test.dart` |
| `lib/features/planner/presentation/widgets/daily_plan_card.dart` | `test/features/planner/presentation/widgets/daily_plan_card_test.dart` |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | `test/features/planner/presentation/widgets/lesson_booking_sheet_test.dart` |
| `lib/features/planner/presentation/widgets/pending_action_card.dart` | `test/features/planner/presentation/widgets/pending_action_card_test.dart` |
| `lib/features/planner/presentation/widgets/milestone_timeline.dart` | `test/features/planner/presentation/widgets/milestone_timeline_test.dart` |
| `lib/features/planner/presentation/widgets/plan_summary_card.dart` | `test/features/planner/presentation/widgets/plan_summary_card_test.dart` |

The planner feature has **6 untested presentation widgets** -- the highest gap of any feature. Only `planner_screen_test.dart` provides integration-level coverage, meaning individual card rendering, empty states, and interaction patterns (booking a lesson, toggling milestones) have zero coverage.

### Practice

| Source | Expected Test |
|---|---|
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | `test/features/practice/presentation/widgets/practice_session_question_card_test.dart` |
| `lib/features/practice/presentation/services/practice_data_service.dart` | `test/features/practice/presentation/services/practice_data_service_test.dart` |
| `lib/features/practice/presentation/services/practice_session_service.dart` | `test/features/practice/presentation/services/practice_session_service_test.dart` |

`PracticeSessionQuestionCard` is the core interactive widget during a practice session (displays the question, captures answers). The two presentation-layer services (`PracticeDataService`, `PracticeSessionService`) encapsulate session orchestration logic and are pure Dart -- ideal for fast unit tests, yet untested.

---

## 2. Structural Mismatch: Test File Not Mirroring Source Location

| Test File | Imports From | Source Location | Correct Location |
|---|---|---|---|
| `test/features/subjects/models/subject_model_test.dart` | `lib/core/data/models/subject_model.dart` | **core** (not a feature) | `test/core/data/models/subject_model_test.dart` |

The `Subject` model lives in `lib/core/data/models/subject_model.dart` (the core layer), but its test was placed under `test/features/subjects/models/`. Per `AGENTS.md`, tests should mirror source location. Placing a core-model test under a feature directory breaks discoverability and sets a misleading precedent.

---

## 3. Bloated / Duplicative Tests

### Dashboard: `dashboard_screen_test.dart` + `dashboard_screen_coverage_test.dart`

| File | Lines |
|---|---|
| `dashboard_screen_test.dart` | 1132 |
| `dashboard_screen_coverage_test.dart` | 907 |

These two files share substantial overlap:

| Test Scenario | In `_test` | In `_coverage` |
|---|---|---|
| Weak area boundary at 60% | Yes (lines 495-522) | Yes (lines 485-502) |
| Practice All button navigation | Yes (lines 571-599) | Yes (lines 550-573) |
| High/medium/low adherence values | Yes (lines 1052-1130) | Yes (lines 721-806) |
| Mastery labels for all 5 levels | Yes (lines 970-997) | Yes (lines 837-886) |
| Refresh indicator presence | Yes (lines 1000-1017) | Yes (lines 889-904) |

The coverage file was clearly added later to fill gaps, but rather than merging scenarios into the existing test groups, it duplicated setup boilerplate and re-tested the same widget behavior. This doubles maintenance cost and makes it hard to tell which scenarios are actually novel.

**Recommendation**: Merge the two files, eliminating duplicate test cases. Keep ~800 unique lines covering all widget behaviors in a single file.

### Dashboard Providers: `dashboard_providers_test.dart`

| Source lines | Test lines | Ratio |
|---|---|---|
| 36 | 434 | 12:1 |

The test file exhaustively tests every Riverpod provider against 6 scenarios (uniqueness, different containers, simple override, combined overrides, container isolation, disposal, watch). Most of these tests exercise Riverpod's `ProviderContainer` behavior rather than any project-specific logic. The 6 providers are trivial factory functions (`Provider<TopicRepository>((ref) => TopicRepository())`).

**Recommendation**: Replace the combinatorial grid with 1--2 tests per provider that verify (a) the provider resolves without throwing and (b) overrides propagate to consumers. Keep the file under 100 lines.

---

## 4. Missing Unit-Level Coverage for Business Logic

The `DashboardScreen._loadData()` method (lines 68--113 of `dashboard_screen.dart`) contains complex error-handling with distinct behaviors per service:

| Operation | Error Behavior | Tested? |
|---|---|---|
| Focus service + `repo.init()` | Silent `catch (_) {}` -- `_focusTodayStats` stays `null` | No |
| `getAllTopicMastery` failure | `_allMastery` stays `[]` | **Only at widget level** (coverage file lines 270-301) |
| `getMasterySnapshot` failure | `_snapshot` stays `null` | **Only at widget level** (coverage file lines 303-327) |
| Adherence repo failure | **Unhandled** -- will propagate and crash the widget | No |
| Focus repo `init()` failure | Silent catch -- `_focusTodayStats` stays `null` | No |

Only two of these five failure paths have widget-level coverage. None have unit-level coverage. Unit tests that inject fake services and verify the `_allMastery`/`_snapshot`/`_focusTodayStats` fields after partial failures would be faster to run and more precise than widget tests.

**Recommendation**: Extract the data-loading orchestration into a testable service or use Riverpod `AsyncNotifier` with a well-defined state class, then write unit tests for each partial-failure permutation.

---

## Acceptance Criteria

- [ ] **1. Missing tests**: All 12 source files listed in Section 1 have corresponding test files with at least one passing test.
- [ ] **2. Structural fix**: `subject_model_test.dart` moved from `test/features/subjects/models/` to `test/core/data/models/` (or the old path re-exported from the new one with a deprecation note).
- [ ] **3a. Deduplication**: `dashboard_screen_test.dart` and `dashboard_screen_coverage_test.dart` merged; no duplicate test scenarios.
- [ ] **3b. Provider tests**: `dashboard_providers_test.dart` reduced to ≤100 lines, testing only project-specific behavior (no Riverpod framework tests).
- [ ] **4. Unit coverage**: At least one unit test per partial-failure path in `DashboardScreen._loadData()` (focus failure, mastery failure, adherence failure, combined partial failures).
