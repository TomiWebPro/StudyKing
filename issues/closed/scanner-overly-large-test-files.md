# [Scanner] 26 test files exceed 1000 lines — need splitting

**Source:** automatic scanner
**Severity:** medium

## Finding

26 test files are over 1000 lines, making them difficult to navigate, maintain, and review. Large test files often indicate that tests are organized by file rather than by logical concern, and they tend to accumulate duplicated setup code.

## Files exceeding 1000 lines

| Lines | File |
|-------|------|
| 2037 | `test/features/planner/presentation/planner_screen_test.dart` |
| 1930 | `test/features/settings/presentation/settings_screen_test.dart` |
| 1886 | `test/features/mentor/presentation/mentor_screen_test.dart` |
| 1863 | `test/features/planner/services/planner_service_test.dart` |
| 1852 | `test/core/errors/handlers_ui_test.dart` |
| 1806 | `test/features/settings/presentation/api_config_screen_test.dart` |
| 1757 | `test/features/dashboard/presentation/dashboard_screen_test.dart` |
| 1721 | `test/features/quickguide/presentation/quick_guide_screen_test.dart` |
| 1665 | `test/features/practice/presentation/screens/practice_session_screen_test.dart` |
| 1558 | `test/features/planner/providers/planner_providers_test.dart` |
| 1544 | `test/l10n/app_localizations_missing_coverage_test.dart` |
| 1544 | `test/features/questions/presentation/widgets/question_card_widget_test.dart` |
| 1505 | `test/core/services/llm/llm_chat_service_test.dart` |
| 1418 | `test/features/mentor/services/mentor_service_test.dart` |
| 1398 | `test/l10n/app_localizations_test.dart` |
| 1300 | `test/features/settings/presentation/profile_screen_test.dart` |
| 1264 | `test/features/practice/presentation/screens/practice_screen_test.dart` |
| 1235 | `test/core/data/models/session_model_test.dart` |
| 1198 | `test/features/planner/services/personal_learning_plan_service_test.dart` |
| 1129 | `test/core/theme/app_theme_ui_test.dart` |
| 1124 | `test/features/subjects/data/repositories/subject_repository_test.dart` |
| 1086 | `test/core/routes/app_router_test.dart` |
| 1077 | `test/features/llm_tasks/presentation/llm_task_manager_screen_test.dart` |
| 1074 | `test/features/practice/services/additional_practice_service_coverage_test.dart` |
| 1039 | `test/core/services/llm_service_test.dart` |
| 1027 | `test/features/settings/data/repositories/settings_repository_hive_test.dart` |

## Root cause

Many of these files group tests by source file rather than by logical concern. For example, `planner_service_test.dart` (1863 lines) tests every method of `PlannerService` in a single file, while `planner_providers_test.dart` (1558 lines) tests all planner providers together. Screen test files (planner, settings, mentor, dashboard, quickguide) each test every possible UI state in one monolithic file.

## Impact

- **Hard to navigate**: Finding a specific test requires scrolling through thousands of lines
- **Hard to review**: PRs touching these files produce massive diffs
- **Duplicated setup**: Each `group()` tends to re-create its own test fixtures, leading to copy-paste code
- **Poor parallelization**: Large files prevent granular test parallelization

## Recommendation

- Split each file by logical concern:
  - `planner_service_test.dart` → `planner_service_generation_test.dart` + `planner_service_scheduling_test.dart` + `planner_service_adherence_test.dart` + ...
  - `planner_screen_test.dart` → `planner_screen_tabs_test.dart` + `planner_screen_planning_test.dart` + `planner_screen_scheduling_test.dart` + ...
  - `dashboard_screen_test.dart` → `dashboard_screen_widgets_test.dart` + `dashboard_screen_data_test.dart` + ...
- Extract common test fixtures and fake classes into shared `test/helpers/` files
- Aim for max ~500 lines per test file as a guideline
