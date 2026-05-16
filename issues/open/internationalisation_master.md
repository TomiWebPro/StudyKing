# Locale-Unaware Number Formatting Blocks Proper Spanish Localisation

## Context

The app currently supports English (`en`) and Spanish (`es`, LatAm formal register). The ARB-based string localisation (2193 keys, 100% parity) and presentation-layer `AppLocalizations.of(context)` usage are well-implemented. However, a systematic gap exists in **numeric value formatting**: the app uses Dart's `toStringAsFixed()` instead of `intl`'s locale-aware `NumberFormat` everywhere.  For any locale that uses comma as decimal separator—including Spanish (`85,5%`), French, German, Italian, Portuguese, and many others—every percentage, score, hours, and cost value renders with the wrong separator.

## Problem

`toStringAsFixed()` always produces a period decimal separator (e.g. `"85.5%"`), but **Spanish locale (`es`) expects a comma separator** (`"85,5%"`).  This affects every user-facing numeric display in the app.

### Affected files (user-facing display — 15+ locations)

| File | Line(s) | Expression | Renders in Spanish |
|---|---|---|---|
| `lib/features/subjects/presentation/widgets/subject_stats_tab.dart` | 63, 108 | `avgScore.toStringAsFixed(1)` | `"85.5%"` → should be `"85,5%"` |
| `lib/features/practice/presentation/practice_results_screen.dart` | 41 | `accuracy.toStringAsFixed(0)` | OK (no decimals), but pattern breaks when precision changes |
| `lib/features/practice/presentation/widgets/practice_session_stats_bar.dart` | 42 | `toStringAsFixed(0)` | OK (no decimals) but inconsistent pattern |
| `lib/features/sessions/presentation/widgets/session_analytics.dart` | 62 | `DateFormat('E', localeName)` | Hardcoded pattern should be skeleton-based for locale flexibility |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | 121, 283 | `totalCost.toStringAsFixed(4)` | `$0.0025` → should be `$0,0025` |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | 171, 174 | Token formatting | `"1.5K"`, `"2.3M"` → locale-unaware number grouping |
| `lib/features/settings/data/models/settings_model.dart` | 113, 117, 183 | Cost/token display | Same decimal-separator problem |
| `lib/core/services/notification_service.dart` | 150 | `hoursStr = hoursStudied.toStringAsFixed(1)` | Notification body content — user sees `"3.5 hours"` instead of `"3,5 horas"` |
| `lib/core/services/engagement_scheduler.dart` | 201 | `totalHours.toStringAsFixed(1)` | Nudge content — same problem |
| `lib/features/dashboard/data/models/dashboard_models.dart` | 128 | `(totalSeconds / 3600).toStringAsFixed(1)` | Dashboard hours display |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | 69 | Same pattern | Dashboard data layer |
| `lib/features/dashboard/services/dashboard_data_loader.dart` | 71 | Same pattern | Dashboard data layer |

### Additional non-display uses (lower priority, for completeness)

These are data-storage or export paths where locale formatting is less critical but should be consistent:

| File | Lines | Context |
|---|---|---|
| `lib/core/services/study_progress_tracker.dart` | 48, 301 | JSON/CSV export |
| `lib/core/services/progress_export_service.dart` | 62, 125, 190, 192 | PDF generation + hardcoded `DateFormat('yyyy-MM-dd HH:mm')` (also locale-unaware) |
| `lib/features/sessions/data/repositories/session_repository.dart` | 241 | Data storage (Hive) |
| `lib/features/sessions/services/session_export_service.dart` | 29, 31, 101 | CSV export |
| `lib/features/teaching/services/prompts/prompts.dart` | 126 | AI prompt context (LLM-facing) |

### Bonus: Regional inconsistency in Spanish ARB

`lib/l10n/app_es.arb:2299` — `"Ayuda con problemas de mates"` uses **"mates"** (distinctly Peninsular Spanish slang) while the rest of the translation targets **neutral Latin American Spanish** as documented in `l10n.yaml:10`.  This should be `"Ayuda con problemas de matemáticas"` for consistency.

## Rationale

1. **Spanish is a comma-decimal locale.**  Every user-facing percentage, score, hours figure, and cost renders incorrectly for Spanish users. This is not a cosmetic issue—in many Spanish-speaking countries, `"85.5%"` is ambiguous or confusing.

2. **The pattern compounds with every new locale.** French, German, Italian, Portuguese—all use comma as decimal separator.  Fixing `toStringAsFixed()` → `NumberFormat` once establishes the correct pattern for all future locales.

3. **The `intl` dependency is already declared** (`intl: ^0.20.2` in `pubspec.yaml`). `NumberFormat` is available. No new dependency needed.

4. **The ARB system works well** for strings; this is the one systematic gap in the i18n architecture.

## Proposed Solution

Replace `toStringAsFixed(n)` with locale-aware `NumberFormat` from the `intl` package for **all user-facing numeric displays**:

```dart
// Before (wrong for Spanish):
'${accuracy.toStringAsFixed(1)}%'

// After (correct for all locales):
final numberFormat = NumberFormat.percentPattern(l10n.localeName)
  ..minimumFractionDigits = 1
  ..maximumFractionDigits = 1;
numberFormat.format(accuracy / 100); // percentPattern expects 0-1 range
```

Or for plain decimals:

```dart
final decimalFormat = NumberFormat('#,##0.#', l10n.localeName);
'${decimalFormat.format(accuracy)}%'
```

### Specific fix per tier

1. **Presentation widgets** (subject_stats_tab, practice_results_screen, practice_session_stats_bar, llm_task_manager_screen): Inject `NumberFormat` via `l10n.localeName`. These have direct access to `AppLocalizations.of(context)`.

2. **Dashboard models/providers** (dashboard_models, dashboard_data_providers, dashboard_data_loader): Pass `localeName` as parameter or use `NumberFormat` at the display boundary.

3. **Notification/nudge services** (notification_service, engagement_scheduler): These already receive `AppLocalizations? l10n` via `LocalizationService` — use `l10n.localeName` to create the `NumberFormat`.

4. **Settings model** (settings_model): This is a data model; move formatting to the presentation layer or inject `localeName`.

5. **Export services** (progress_export_service, study_progress_tracker, session_export_service): For CSV — locale-agnostic `en` format is acceptable (CSV is data, not display). For PDF — use the user's locale.

6. **Spanish ARB fix**: Change `app_es.arb:2299` from `"Ayuda con problemas de mates"` to `"Ayuda con problemas de matemáticas"`.

7. **Hardcoded DateFormat**: Change `lib/core/services/progress_export_service.dart:125` `DateFormat('yyyy-MM-dd HH:mm')` to `DateFormat.yMd(l10n.localeName).add_Hm()`.

## Acceptance Criteria

1. [ ] A Spanish user sees `"85,5%"` instead of `"85.5%"` on subject stats, practice results, practice stats bar, and dashboard.
2. [ ] A Spanish user sees `"$0,0025"` instead of `"$0.0025"` in LLM task manager cost displays.
3. [ ] Nudge/notification text for Spanish locale uses comma as decimal separator in hour/session values.
4. [ ] A centralised `NumberFormat` helper or utility is created (e.g. `lib/core/utils/number_format_utils.dart`) to avoid repeated `NumberFormat('#,##0.#', localeName)` boilerplate.
5. [ ] `formattedDate` in `progress_export_service.dart` is locale-aware (skeleton-based, not hardcoded pattern).
6. [ ] `"mates"` → `"matemáticas"` in `app_es.arb`.
7. [ ] All CSV exports remain in invariant `en` format (data, not display).
8. [ ] All existing tests pass; new tests verify `NumberFormat` usage for `es` locale produces comma separators.
9. [ ] The fix pattern is documented in `AGENTS.md` under i18n conventions so new contributors use `NumberFormat` by default.
