# Refactor: Extract duplicated decorated-container, stat-card, and session-tile patterns into shared components

## Context

Three UI layout patterns are identically reimplemented across 4+ files in 2 features (sessions, subjects). Every variant uses the same gradient-with-border decoration, same icon+value+label card layout, and same session-list-tile structure. This forces manual synchronization when changing visual styling (border radius, gradient alpha, padding) and bloats each screen by 30--60 lines of boilerplate.

The `formatDuration` utility also has a latent runtime crash: its `l10n` parameter is nullable but force-unwrapped with `!` at every callsite, and the `session_analytics.dart` file calls it without passing `l10n`, meaning it will throw a `Null check operator used on a null value` error at runtime.

## Duplicated patterns

### 1. Gradient container ("stat card" decoration)

All three files build a `Container` with the same structure:
- `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight)` with two alpha-adjusted color stops
- `BorderRadius.circular(12)` (or 16)
- `Border.all` with same color at alpha 0.3

| File | Lines |
|---|---|
| `lib/features/sessions/widgets/session_analytics.dart` | 214--224 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 209--224 |
| `lib/features/subjects/presentation/subject_detail_view.dart` | 576--584 (similar, flat fill instead of gradient) |

### 2. Stat/metric card widget

Three structurally identical card widgets: icon (top-left or centered), value (title-large bold), label (body-small).

| File | Method | Lines |
|---|---|---|
| `lib/features/sessions/widgets/session_analytics.dart` | `_buildMetricCard` | 208--266 |
| `lib/features/sessions/presentation/session_history_screen.dart` | `_buildSummaryStat` | 229--244 |
| `lib/features/subjects/presentation/subject_detail_view.dart` | `_buildStatCard` | 576--602 |

### 3. Session list tile

Two files render a `ListTile` with `play_arrow` icon, "Session N" title, formatted duration + date subtitle, and trailing duration. One adds swipe-to-delete and question stats on top.

| File | Lines |
|---|---|
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 359--379 |
| `lib/features/sessions/presentation/session_history_screen.dart` | 274--341 |

### 4. Day-of-week bar chart

A 60-line animated bar chart (`_buildDayOfWeekChart` at `session_analytics.dart:88--150`) is self-contained but tightly coupled to the analytics widget. It could be extracted as a reusable `AnimatedBarChart` widget parameterized by `Map<String, int>`.

## Additional structural issues

### 5. `formatDuration` null crash hazard

`lib/core/utils/time_utils.dart:21` declares `l10n` as `AppLocalizations?` (nullable) but uses `l10n!` (force-unwrap) on lines 29, 31, 33, 35, 42, 44, 46. Every call to `formatDuration` that omits the `l10n` argument (or passes `null`) will crash with a `NullError`.

Affected callsites without `l10n`:
- `session_analytics.dart:162` — `formatDuration(avgTimePerSession)`
- `session_analytics.dart:196` — `formatDuration(_totalStudyTime)`
- `session_history_screen.dart:207,211` — `formatDuration(Duration(minutes: totalMinutes))`
- `session_history_screen.dart:332` — `formatDuration(timeSpent)`
- `session_tracker_screen.dart:368,372` — `formatDuration(Duration(milliseconds: ...))`
- `subject_detail_view.dart:408,506,679` — `formatDuration(...)`

The existing `formatDurationFromContext` helper (line 67--69) already does this correctly; all callsites should use it or pass `l10n`.

### 6. Dead code in `_buildMetricCard`

`session_analytics.dart:208` declares an `onTap` parameter that is never passed at any call site (lines 160, 170, 184, 194). The 10-line `InkWell` / `Material` wrapper (lines 254--263) is dead code.

### 7. Hardcoded strings bypassing i18n

`session_analytics.dart` uses literal strings for metric labels ("Avg Session", "Total Sessions", "Current Streak", "Total Time") and section headers ("Sessions by Day of Week", "Performance Metrics") instead of `AppLocalizations.of(context)`. Same pattern in `session_tracker_screen.dart` ("Current Session", "No Active Session", "Recent Sessions") and `session_history_screen.dart` ("Session History", "Delete Session", etc.).

## Affected files

| File | Role |
|---|---|
| `lib/features/sessions/widgets/session_analytics.dart` | Primary: 4/5 patterns, dead code, missing l10n |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | Duplicates: gradient container, session tile |
| `lib/features/sessions/presentation/session_history_screen.dart` | Duplicates: stat card, session tile |
| `lib/features/subjects/presentation/subject_detail_view.dart` | Duplicates: stat card, gradient-adjacent container |
| `lib/core/utils/time_utils.dart` | Root cause: nullable parameter with force-unwrap |
| `lib/core/widgets/` (to be created) | Target: shared `GradientContainer`, `MetricCard`, `AnimatedBarChart` |

## Rationale

- **DRY**: 4 files ship independent copies of the same 3 layout patterns. Changing the border radius or gradient alpha requires touching every file.
- **Maintainability**: new features needing a stats grid or session list will copy-paste yet another variant. A shared widget in `core/widgets/` provides a single source of truth.
- **Correctness**: the `formatDuration` null crash is latent in every screen that displays session duration — it will fail on the first non-zero duration rendered without localization.
- **i18n readiness**: hardcoded metric labels cannot be translated; extracting them to the ARB file is a prerequisite for complete localization.

## Acceptance criteria

1. A `lib/core/widgets/` directory exists with at least these shared components:
   - `GradientContainer` — applies the gradient + border + radius decoration, takes a `Color accent`, `Widget child`, and optional `double borderRadius`
   - `MetricCard` — icon + value + label in a gradient container, takes `IconData`, `String value`, `String label`, `Color accent` (replaces `_buildMetricCard`, `_buildSummaryStat`, `_buildStatCard`)
   - `AnimatedBarChart` — takes `Map<String, int>` data, renders animated vertical bars (replaces `_buildDayOfWeekChart`)

2. All four affected files import the shared widgets and have their private `_build*` methods removed or replaced with a 1--3 line call to the shared widget.

3. `formatDuration` in `time_utils.dart` either:
   - Makes `l10n` required (remove `?`), OR
   - Removes the force-unwrap and gracefully degrades to English (e.g. `l10n?.durationSeconds(seconds) ?? '${seconds}s'`), AND all callsites that lack context access use `formatDurationFromContext` or pass a non-null `l10n`.

4. Dead `onTap` code path in `session_analytics.dart:254--263` is removed.

5. Hardcoded display strings in `session_analytics.dart`, `session_tracker_screen.dart`, and `session_history_screen.dart` are moved into `lib/l10n/app_en.arb` (and `app_es.arb`) and referenced through `AppLocalizations.of(context)`.

6. All existing tests pass. No visual regression in the sessions or subjects feature screens.
