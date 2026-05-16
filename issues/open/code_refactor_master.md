# Dashboard Module: Dead Code, Duplicated Logic, and Misplaced Concerns

## Context

The dashboard module (`lib/features/dashboard/`) has accumulated structural issues: a dead service file that duplicates logic from active providers, a providers file that mixes data-fetching concerns with UI state management, and a barrel file that silently omits dead code while lacking exports for internally-used widgets.

---

## Issues

### 1. Dead code: `services/dashboard_data_loader.dart`

`DashboardDataLoader` and its `DashboardData` model class are **never imported** by any file under `lib/`. The only consumer is `test/features/dashboard/services/dashboard_data_loader_test.dart`.

**Affected files:**
- `lib/features/dashboard/services/dashboard_data_loader.dart` (entire file, ~126 lines)

**Rationale:**
- Zero imports from `lib/` — confirmed by grep across the entire `lib/` tree.
- Not exported in `dashboard.dart` barrel.
- The class was likely a precursor to the provider-based approach in `dashboard_data_providers.dart` but was never removed.
- Retaining dead code increases maintenance burden (readers wonder if it is used) and misleads new contributors.

**Acceptance criteria:**
- Delete `lib/features/dashboard/services/dashboard_data_loader.dart`.
- Delete `test/features/dashboard/services/dashboard_data_loader_test.dart`.
- Verify all imports referencing this file are removed (there should be none in `lib/` and only one in `test/`).
- Confirm dashboard tests still pass.

---

### 2. Duplicated business logic: focus-today-stats computed in two places

The same "today's focus session" computation appears in **two locations** with slightly different error handling and return types:

| Location | File:Line | Return type | Error handling |
|---|---|---|---|
| Provider | `dashboard_data_providers.dart:56-72` | `FocusTodayStats?` (typed model) | Silent `catch (_)` |
| Dead service | `dashboard_data_loader.dart:60-77` | `Map<String, dynamic>?` (raw map) | `_logger.w('...')` |

The duplication itself has been rendered harmless by the dead code in (1), but the live provider still has a subtle issue: `totalMs` is computed but only `totalSeconds` (a derived value) is actually stored in the model. The `totalMs` field is **computed and then discarded**.

**Affected files:**
- `lib/features/dashboard/providers/dashboard_data_providers.dart:56-72`

**Rationale:**
- Unnecessary CPU work: `fold<int>(0, ...)` computes `totalMs` but the value is never used outside the scope.
- Inconsistency with the now-dead service version (which used `totalMs` in a map) suggests the computation was copied without cleanup.
- After deletion of the dead file in (1), this is the only remaining copy — an opportunity to simplify.

**Acceptance criteria:**
- Remove the unused `totalMs` variable from `dashboardFocusStatsProvider`.
- Keep only `totalSeconds` (computed via `totalMs ~/ 1000` can become a direct computation) or simplify further.
- Confirm `FocusTodayStats.fromMap` call reflects the change.

---

### 3. Misplaced concerns: UI state management in `dashboard_data_providers.dart`

The file `dashboard_data_providers.dart` is named to suggest it contains **data-layer providers** (fetchers of mastery, stats, adherence, etc.). However, it also houses the **UI layout state** for card collapse/expand:

| Lines | Concern | Correctness |
|---|---|---|
| 127–143 | `DashboardLayoutPreferences` (model) | Layout concern |
| 145–168 | `DashboardLayoutNotifier` (StateNotifier) | Layout concern |
| 170–174 | `dashboardLayoutPreferencesProvider` | Layout concern |

These three declarations are UI-state management — they control which dashboard cards are collapsed — and have nothing to do with "data providers." Placing them here violates the **Single Responsibility Principle** and makes the file harder to navigate.

**Affected files:**
- `lib/features/dashboard/providers/dashboard_data_providers.dart:125-174`

**Rationale:**
- A developer looking for "dashboard layout preferences" will not look in a file named `dashboard_data_providers.dart`.
- The file already spans 174 lines with 8 `FutureProvider.family` declarations; adding UI state on top makes it a grab-bag.
- Clean separation: data providers belong together (`dashboard_providers.dart` or `dashboard_data_providers.dart`), layout state should live in a dedicated file like `providers/dashboard_layout_providers.dart`.

**Acceptance criteria:**
- Extract `DashboardLayoutPreferences`, `DashboardLayoutNotifier`, and `dashboardLayoutPreferencesProvider` into a new file `lib/features/dashboard/providers/dashboard_layout_providers.dart`.
- Update the barrel export in `dashboard.dart` (add the new file).
- Update any imports that reference `dashboardLayoutPreferencesProvider`.
- Confirm no imports are broken and all tests pass.

---

## Summary

| # | Issue | Severity | Effort |
|---|---|---|---|
| 1 | Dead code: `dashboard_data_loader.dart` (126 lines, zero imports) | High | Low |
| 2 | Duplicated/unused `totalMs` computation in focus-stats provider | Low | Trivial |
| 3 | Layout UI state mixed into `dashboard_data_providers.dart` | Medium | Low |

All three are independent but affect the same module; addressing them together restores clarity to the dashboard data layer.
