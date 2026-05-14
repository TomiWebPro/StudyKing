# High-Value Test Coverage and Quality Gaps

## Summary

Systematic audit of the StudyKing test suite reveals **56 source files** (35 feature + 21 core) with zero tests, **15 structurally misplaced/duplicate test files**, and critical quality issues in several existing tests that make them effectively meaningless. The `focus_mode` feature is structurally complete but has a severely broken fake in its service test. The `practice` and `dashboard` features are the largest lacunae with 18 and 10 untested source files respectively.

---

## 1. Critical: `FocusSessionService` Test Fakes Return Fabricated Data

**Severity: High** — Tests pass but assert nothing meaningful.

**Affected file:** `test/features/focus_mode/services/focus_session_service_test.dart`

**Problem:** `FakeFocusSessionRepository.get()`, `getAll()`, and `getByDate()` ignore stored data and return fabricated `FocusSession` objects constructed with `DateTime.now()` and hardcoded values:

```dart
// Lines 24-32: get() ignores _store content
Future<FocusSession?> get(String id) async {
  final raw = _store[id];
  if (raw == null) return null;
  return FocusSession(          // <-- fabricates new session, ignores stored data
    id: id,
    startTime: DateTime.now(),  // <-- loses original startTime
    plannedDurationMinutes: 25,
  );
}
```

**Consequences:**
- `getTodayStats`, `getTodayFocusSeconds`, `getTodaySessionCount`, `getTodayCompletedSessionCount`, `getWeeklyFocusSeconds`, `getRecentSessions` — all 6 stats tests in the "stats" group only verify the *zero-data* case because the fake's `getByDate` returns sessions but the tests never assert non-zero values.
- `isDailyCapReached` / `getRemainingDailyCapMinutes` tests cannot verify cap logic with real data.
- The Hive `init(dir.path)` call in `setUp` is dead code since the fake never uses Hive.
- `onTick` callback test uses `Future.delayed(1500ms)` — a flaky time-dependent pattern.

**Rationale:** This makes ~40% of the service test file (stats + daily cap groups) provide zero regression value. A real bug in stats aggregation would not be caught.

---

## 2. Dashboard: 10 Widgets + 1 Provider Totally Untested

**Severity: High** — Core user-facing feature with zero widget-level coverage.

**Affected files (missing tests):**
| Source | Expected test path |
|---|---|
| `lib/features/dashboard/presentation/widgets/badges_card.dart` | `test/features/dashboard/presentation/widgets/badges_card_test.dart` |
| `lib/features/dashboard/presentation/widgets/dashboard_header.dart` | `test/features/dashboard/presentation/widgets/dashboard_header_test.dart` |
| `lib/features/dashboard/presentation/widgets/export_section.dart` | `test/features/dashboard/presentation/widgets/export_section_test.dart` |
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | `test/features/dashboard/presentation/widgets/mastery_progress_card_test.dart` |
| `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` | `test/features/dashboard/presentation/widgets/plan_adherence_card_test.dart` |
| `lib/features/dashboard/presentation/widgets/summary_row.dart` | `test/features/dashboard/presentation/widgets/summary_row_test.dart` |
| `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` | `test/features/dashboard/presentation/widgets/topic_breakdown_card_test.dart` |
| `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` | `test/features/dashboard/presentation/widgets/weak_areas_card_test.dart` |
| `lib/features/dashboard/presentation/widgets/weekly_chart.dart` | `test/features/dashboard/presentation/widgets/weekly_chart_test.dart` |
| `lib/features/dashboard/providers/dashboard_providers.dart` | `test/features/dashboard/providers/dashboard_providers_test.dart` |

**Additionally:**
- `test/features/dashboard/dashboard_barrel_test.dart` is an **8-line skeleton** that only asserts `DashboardScreen` is not null.
- A **907-line `dashboard_screen_coverage_test.dart`** exists alongside the main `dashboard_screen_test.dart` — this is a code smell: either redundant or should be consolidated.

**Rationale:** The DashboardScreen uses all 9 widgets but only the screen-level integration is tested. Individual widget behavior (empty states, edge cases, interaction callbacks) is completely uncovered.

---

## 3. Practice Feature: 18 Source Files Untested

**Severity: High** — Largest feature with fewest tests per source file (4 tests for 23 source files = 17% coverage).

**Affected files (missing tests):**
| Source | Expected test path |
|---|---|
| `lib/features/practice/presentation/models/practice_models.dart` | `test/features/practice/models/practice_models_test.dart` |
| `lib/features/practice/presentation/services/practice_data_service.dart` | (non-standard location — see §5) |
| `lib/features/practice/presentation/services/practice_session_service.dart` | (non-standard location — see §5) |
| `lib/features/practice/presentation/widgets/practice_empty_state.dart` | `test/features/practice/presentation/widgets/practice_empty_state_test.dart` |
| `lib/features/practice/presentation/widgets/practice_feedback_widget.dart` | `test/features/practice/presentation/widgets/practice_feedback_widget_test.dart` |
| `lib/features/practice/presentation/widgets/practice_mode_card.dart` | `test/features/practice/presentation/widgets/practice_mode_card_test.dart` |
| `lib/features/practice/presentation/widgets/practice_mode_grid.dart` | `test/features/practice/presentation/widgets/practice_mode_grid_test.dart` |
| `lib/features/practice/presentation/widgets/practice_mode_option.dart` | `test/features/practice/presentation/widgets/practice_mode_option_test.dart` |
| `lib/features/practice/presentation/widgets/practice_mode_sheet.dart` | `test/features/practice/presentation/widgets/practice_mode_sheet_test.dart` |
| `lib/features/practice/presentation/widgets/practice_results_screen.dart` | `test/features/practice/presentation/widgets/practice_results_screen_test.dart` |
| `lib/features/practice/presentation/widgets/practice_session_nav_buttons.dart` | `test/features/practice/presentation/widgets/practice_session_nav_buttons_test.dart` |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | `test/features/practice/presentation/widgets/practice_session_question_card_test.dart` |
| `lib/features/practice/presentation/widgets/practice_session_stats_bar.dart` | `test/features/practice/presentation/widgets/practice_session_stats_bar_test.dart` |
| `lib/features/practice/presentation/widgets/spaced_repetition_sheet.dart` | `test/features/practice/presentation/widgets/spaced_repetition_sheet_test.dart` |
| `lib/features/practice/presentation/widgets/subject_practice_card.dart` | `test/features/practice/presentation/widgets/subject_practice_card_test.dart` |
| `lib/features/practice/presentation/widgets/subject_selection_sheet.dart` | `test/features/practice/presentation/widgets/subject_selection_sheet_test.dart` |
| `lib/features/practice/presentation/widgets/topic_selection_sheet.dart` | `test/features/practice/presentation/widgets/topic_selection_sheet_test.dart` |
| `lib/features/practice/presentation/widgets/weak_areas_sheet.dart` | `test/features/practice/presentation/widgets/weak_areas_sheet_test.dart` |
| `lib/features/practice/services/question_type_localizer.dart` | `test/features/practice/services/question_type_localizer_test.dart` |

**Additionally:**
- `test/features/practice/providers/practice_providers_test.dart` is **43 lines** — only asserts providers can be read, never tests their behavior or business logic.
- `test/features/practice/presentation/practice_test.dart` is at the wrong path (see §5).

---

## 4. Core Layer: 21 Untested Files Including Critical Services

**Severity: Medium** — Untested foundational services risk silent regressions across all features.

| Source | Notes |
|---|---|
| `lib/core/services/llm/llm_chat_service.dart` | LLM integration — untested |
| `lib/core/services/llm/llm_embeddings_service.dart` | LLM integration — untested |
| `lib/core/services/llm/llm_model_service.dart` | LLM integration — untested |
| `lib/core/services/llm_task_manager.dart` | Task orchestration — untested |
| `lib/core/services/llm_usage_meter.dart` | Cost tracking — untested |
| `lib/core/services/engagement_scheduler.dart` | User engagement — untested |
| `lib/core/services/mastery_calculation_service.dart` | Core mastery algorithm — untested |
| `lib/core/services/notification_service.dart` | Notifications — untested |
| `lib/core/services/progress_export_service.dart` | Data export — untested |
| `lib/core/services/student_id_service.dart` | Student identity — untested |
| `lib/core/utils/logger.dart` | Logging utility — untested |
| `lib/core/utils/responsive.dart` | Responsive layout — untested |
| `lib/core/utils/utils.dart` | General utilities — untested |
| `lib/core/providers/app_providers.dart` | App-wide providers — untested |
| `lib/core/providers/llm_providers.dart` | LLM providers — untested |
| `lib/core/constants/app_config.dart` | Config constants — untested |
| `lib/core/constants/app_constants.dart` | Constants — untested |
| `lib/core/constants/security_config.dart` | Security config — untested |
| `lib/core/constants/token_pricing_config.dart` | Pricing config — untested |
| `lib/core/data/adapters/mastery_improvement_adapter.dart` | Hive adapter — untested |
| `lib/core/data/adapters/plan_adherence_adapter.dart` | Hive adapter — untested |

---

## 5. Structural / Convention Violations

| Issue | Path | Fix |
|---|---|---|
| Wrong location | `test/features/settings/data/models_test.dart` | Move to `test/features/settings/data/models/settings_box_test.dart` |
| Wrong location | `test/features/practice/presentation/practice_test.dart` | Move to `test/features/practice/practice_test.dart` (tests the barrel) |
| Empty directory | `test/features/questions/models/` | Remove or populate with tests |
| Non-standard layout | `lib/features/questions/ui/widgets/` | Either rename to `presentation/widgets/` or update AGENTS.md to cover `ui/widgets/` |
| Non-standard layout | `lib/features/practice/presentation/services/` | Convention has no rule for `presentation/services/` — services live at feature root in the convention. Either move them or add a convention exception. |
| Non-standard layout | `lib/features/practice/presentation/models/` | Convention has `models/` at feature root, not under `presentation/` |
| Duplicate test files | `test/features/quickguide/presentation/` 3 files for 1 source | Consolidate `quick_guide_screen_coverage_test.dart` and `quick_guide_screen_advanced_test.dart` into `quick_guide_screen_test.dart` or remove if redundant |
| Duplicate test files | `test/features/dashboard/presentation/dashboard_screen_coverage_test.dart` (907 lines) | Consolidate into `dashboard_screen_test.dart` |
| Missing model tests | `test/features/settings/data/models/accessibility_preferences_test.dart` | Missing dedicated test file (covered only partially in `models_test.dart`) |
| Missing model tests | `test/features/settings/data/models/settings_model_test.dart` | Missing entirely |

---

## 6. Skeleton / Token Tests with Negligible Value

These test files exist but provide minimal regression protection:

| File | Lines | Problem |
|---|---|---|
| `test/features/dashboard/dashboard_barrel_test.dart` | 8 | Single `isNotNull` assertion |
| `test/features/quickguide/quickguide_test.dart` | 34 | Only checks exported types exist |
| `test/features/practice/providers/practice_providers_test.dart` | 43 | Only checks providers can be read — no behavior tests |
| `test/features/practice/presentation/practice_test.dart` | 94 | Only 3 basic rendering assertions for PracticeScreen |

---

## Acceptance Criteria

1. **Fix FocusSessionService fake (`focus_session_service_test.dart`):**
   - Rewrite `FakeFocusSessionRepository` to actually preserve and retrieve session data.
   - Add tests verifying `getTodayStats`, `getWeeklyFocusSeconds`, etc. return correct non-zero values with real session data.
   - Add tests for `isDailyCapReached` and `getRemainingDailyCapMinutes` using a settings box mock.
   - Remove the dead `Hive.init` call from `setUp`.
   - Replace the flaky `Future.delayed(1500ms)` onTick test with a deterministic timer mock.

2. **Add dashboard widget tests:** Write tests for all 9 dashboard widgets (badges_card: empty state, full state; dashboard_header: renders student info; weekly_chart: data rendering; etc.) and the dashboard provider.

3. **Add practice widget/service tests:** Write tests for at least the 18 untested practice files, prioritizing the services (`practice_data_service`, `practice_session_service`), models (`practice_models`), and session widgets (`practice_session_question_card`, `practice_session_nav_buttons`, `practice_results_screen`).

4. **Upgrade skeleton tests:**
   - `dashboard_barrel_test.dart` → add actual widget smoke test or remove.
   - `practice_providers_test.dart` → add behavior tests with mocked repositories.
   - `practice_test.dart` → expand beyond 3 assertions.

5. **Fix structural violations:**
   - Move `test/features/settings/data/models_test.dart` to proper path.
   - Move `test/features/practice/presentation/practice_test.dart` to feature root.
   - Remove or populate `test/features/questions/models/`.
   - Consolidate duplicate test files in dashboard and quickguide.

6. **Add core service tests:** Write tests for at least the 5 highest-risk untested core services (llm_chat_service, mastery_calculation_service, student_id_service, notification_service, llm_task_manager).
