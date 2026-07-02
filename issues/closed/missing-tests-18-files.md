# Missing Test Files — 18 Source Files Without Tests

## Summary

Per the conventions in `AGENTS.md`, every source file in specific directories under `lib/features/*/` and `lib/core/*/` must have a corresponding test file. Currently, **18 source files** have no test coverage at all. This creates blind spots for regressions and makes it unsafe to refactor those modules.

## Affected Files

### `lib/core/` (2 files)

| # | Source | Expected Test |
|---|---|---|
| 1 | `lib/core/data/data.dart` | `test/core/data/data_test.dart` |
| 2 | `lib/core/services/settings_service.dart` | `test/core/services/settings_service_test.dart` |

### `lib/features/dashboard/` (1 file)

| # | Source | Expected Test |
|---|---|---|
| 3 | `lib/features/dashboard/presentation/widgets/dashboard_nav_card.dart` | `test/features/dashboard/presentation/widgets/dashboard_nav_card_test.dart` |

### `lib/features/focus_mode/` (1 file)

| # | Source | Expected Test |
|---|---|---|
| 4 | `lib/features/focus_mode/data/repositories/focus_session_repository.dart` | `test/features/focus_mode/data/repositories/focus_session_repository_test.dart` |

### `lib/features/lessons/` (1 file)

| # | Source | Expected Test |
|---|---|---|
| 5 | `lib/features/lessons/services/session_query_service.dart` | `test/features/lessons/services/session_query_service_test.dart` |

### `lib/features/planner/` (11 files — highest concentration)

| # | Source | Expected Test |
|---|---|---|
| 6 | `lib/features/planner/presentation/widgets/adherence_banner.dart` | `test/features/planner/presentation/widgets/adherence_banner_test.dart` |
| 7 | `lib/features/planner/presentation/widgets/daily_plans_section.dart` | `test/features/planner/presentation/widgets/daily_plans_section_test.dart` |
| 8 | `lib/features/planner/presentation/widgets/missed_lessons_section.dart` | `test/features/planner/presentation/widgets/missed_lessons_section_test.dart` |
| 9 | `lib/features/planner/presentation/widgets/multi_syllabus_input.dart` | `test/features/planner/presentation/widgets/multi_syllabus_input_test.dart` |
| 10 | `lib/features/planner/presentation/widgets/pace_adjustment_card.dart` | `test/features/planner/presentation/widgets/pace_adjustment_card_test.dart` |
| 11 | `lib/features/planner/presentation/widgets/pending_actions_section.dart` | `test/features/planner/presentation/widgets/pending_actions_section_test.dart` |
| 12 | `lib/features/planner/presentation/widgets/roadmaps_tab.dart` | `test/features/planner/presentation/widgets/roadmaps_tab_test.dart` |
| 13 | `lib/features/planner/presentation/widgets/scheduled_lessons_section.dart` | `test/features/planner/presentation/widgets/scheduled_lessons_section_test.dart` |
| 14 | `lib/features/planner/presentation/widgets/study_plan_tab.dart` | `test/features/planner/presentation/widgets/study_plan_tab_test.dart` |
| 15 | `lib/features/planner/presentation/widgets/subject_progress_tabs.dart` | `test/features/planner/presentation/widgets/subject_progress_tabs_test.dart` |
| 16 | `lib/features/planner/providers/plan_providers.dart` | `test/features/planner/providers/plan_providers_test.dart` |

### `lib/features/questions/` (2 files)

| # | Source | Expected Test |
|---|---|---|
| 17 | `lib/features/questions/presentation/widgets/audio_recording_widget.dart` | `test/features/questions/presentation/widgets/audio_recording_widget_test.dart` |
| 18 | `lib/features/questions/presentation/widgets/file_upload_widget.dart` | `test/features/questions/presentation/widgets/file_upload_widget_test.dart` |

## Impact

1. **No regression safety** — Changes to any of these 18 files could introduce bugs that go undetected.
2. **Convention violation** — `AGENTS.md` explicitly requires these tests. A user following the conventions would expect them to exist.
3. **Planner feature is the worst-hit** — The planner module (`lib/features/planner/`) is the most complex feature with the most screens and widgets, yet it has the most test gaps (11 of 18 missing).
4. **Provider without tests** — `plan_providers.dart` is a Riverpod provider file. Per AGENTS.md, provider tests must include behavioral assertions (dependency wiring, fallback logic, singleton behavior, or error state handling). Without tests, provider refactoring is risky.

## Root Cause

The test files were likely never created when the source files were added. This is a common oversight when adding new widgets during feature development.

## Recommended Fix

Create the missing test files following the existing patterns in `test/`. For each category:

- **Widget tests** (`presentation/widgets/*_test.dart`): Use `ProviderScope` with `overrides`, `pumpAndSettle`, `NavigatorObserver`, and verify widget rendering with `find.text(...)` / `find.byType(...)`.
- **Provider tests** (`providers/*_test.dart`): Use hand-written fake classes, inject via `ProviderContainer(overrides: [...])`, and assert behavioral outcomes (wiring, fallback, singleton, error handling).
- **Service tests** (`services/*_test.dart`): Unit-test pure logic functions with hand-written fakes.
- **Repository tests** (`data/repositories/*_test.dart`): Use in-memory Hive boxes or fake implementations.

## Priority

Medium — No immediate crash risk, but the gap grows over time and makes the planner module particularly fragile.
