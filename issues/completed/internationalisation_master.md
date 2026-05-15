# Internationalisation Master: Architectural Bottlenecks & Spanish Translation Quality

## Summary

The codebase has **879 localisation keys** across 2 locales (EN, ES) with full key parity — but several **architectural bottlenecks** make adding new languages unnecessarily error-prone, and the **Spanish translation has quality defects** that set a poor template for future languages.

---

## Issue 1: No Centralised Locale Registry (High Severity)

### Problem
Adding a new language requires editing **4 separate locations** with no single source of truth, making the process fragile and error-prone:

| File | What must change |
|---|---|
| `l10n.yaml` | Add locale to `supported-locales` list |
| `lib/main.dart` | Add `Locale('xx')` to `supportedLocales` + locale resolution callback |
| `lib/features/settings/presentation/profile_screen.dart` | Add `DropdownMenuItem` for the new language |
| `lib/l10n/app_xx.arb` | Create new ARB file with 879 translated keys |

There is no `enum`, `const` list, or config class that centralises which locales are supported.

### Rationale
Every new language risks silent inconsistencies (e.g. missing `supportedLocales` entry but present in dropdown, or vice versa). A `LocaleConfig` registry would eliminate this.

### Affected Files
- `l10n.yaml` (lines 6-8)
- `lib/main.dart` (`supportedLocales`, locale resolution)
- `lib/features/settings/presentation/profile_screen.dart` (language dropdown)
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
- `docs/i18n.md`

### Acceptance Criteria
- [ ] Create `lib/core/config/locale_config.dart` with:
  - An `enum AppLocale { en, es }` (extensible) mapping to `Locale` objects
  - A static `List<Locale> get supportedLocales` derived from the enum
  - A static `String Function(AppLocale)` for display name lookup
  - A static `List<DropdownMenuItem>` builder for the language picker
- [ ] Refactor `l10n.yaml` `supported-locales`, `main.dart` `supportedLocales`, and `profile_screen.dart` dropdown to use this single source of truth
- [ ] Update `docs/i18n.md` to reference the enum as the single registration step

---

## Issue 2: Spanish Translation Grammar Defect — `planAdherence` (High Severity)

### Problem
`lib/l10n/app_es.arb` line 1619:
```json
"planAdherence": "cumplimiento al Plan"
```

This is grammatically incorrect. The Spanish preposition should be **"del"** (de + el), not **"al"** (a + el):
- ❌ `"cumplimiento al Plan"` → implies "compliance TO the Plan"
- ✅ `"Cumplimiento del Plan"` → means "Plan Adherence" (correct)

Additionally, the lowercase `c` is inconsistent with all other ES section headers which use title case (e.g. `"Resumen de Dominio"`, `"Progreso de la Lección"`, `"Tiempo Total de Estudio"`).

### Impact
This string appears in the **dashboard UI** as a section card title (`lib/features/dashboard/presentation/dashboard_screen.dart:122` and `plan_adherence_card.dart:28`). Every Spanish-speaking user sees a grammatically incorrect label.

### Affected Files
- `lib/l10n/app_es.arb` (line 1619-1620)
- `lib/l10n/generated/app_localizations_es.dart` (line 1246)
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart`

### Acceptance Criteria
- [ ] Change to `"Cumplimiento del Plan"` in `app_es.arb`
- [ ] Regenerate localizations with `flutter gen-l10n`
- [ ] Verify rendering in dashboard screen renders correct title-case header

---

## Issue 3: Hardcoded User-Facing String in Planner (High Severity)

### Problem
Two hardcoded English strings exist that bypass the entire localisation system:

| File | Line | String |
|---|---|---|
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 258 | `'Time conflict with existing scheduled lesson'` |
| `lib/features/planner/providers/planner_providers.dart` | 446 | `'Time conflict with existing scheduled lesson'` |

These are displayed to the user via `SnackBar` and `state.error` respectively, and **cannot be translated**.

### Rationale
As discovered during exploration, the `subjects`, `practice`, and `settings` features are fully localised, making this hardcoded string in `planner` a regression that must be fixed before adding new languages.

### Affected Files
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` (258)
- `lib/features/planner/providers/planner_providers.dart` (446)

### Acceptance Criteria
- [ ] Add a new key `"timeConflict"` to `app_en.arb` and `app_es.arb`
- [ ] Replace both hardcoded strings with `l10n.timeConflict`
- [ ] Confirm via test/localisation coverage check

---

## Issue 4: Duplicate Badge Key Definitions (Medium Severity)

### Problem
Two sets of keys exist for the same badge concept:

| Old Key | Duplicate Key | Same value |
|---|---|---|
| `badgeCenturyName` | `badgeCenturyClubName` | `"Club del Centenar"` / `"Club del Centenario"` |
| `badgeCenturyDesc` | `badgeCenturyClubDesc` | `"¡Respondió más de 100 preguntas!"` |

The `badgeCenturyName` key (ES line 3512) uses `"Club del Centenar"` while `badgeCenturyClubName` (ES line 3856) uses `"Club del Centenario"` — they are **different translations of the same concept**. The `LocalizationService` references `badgeCenturyClub*` for the "century" badge ID.

This means:
- One translation is never displayed (dead key)
- The two translations differ (`Centenar` vs `Centenario`), risking confusion
- Any future language would inherit this duplication

### Affected Files
- `lib/l10n/app_en.arb` (century badge)
- `lib/l10n/app_es.arb` (lines 3512-3519, 3856-3863)

### Acceptance Criteria
- [ ] Remove `badgeCenturyName` / `badgeCenturyDesc` from both ARB files (keep `badgeCenturyClub*` which is what `LocalizationService` uses)
- [ ] Regenerate localizations
- [ ] Verify coverage test still passes

---

## Issue 5: Inconsistent Description Languages in ARB (Medium Severity)

### Problem
The `@key` description fields in `app_es.arb` are a **mix of Spanish and English**, making maintenance harder for native Spanish translators:

- English descriptions: `"The application title"`, `"Bottom navigation label for subjects"`
- Spanish descriptions: `"Nombre de la insignia por responder la primera pregunta"`, `"Encabezado para la sección de estadísticas generales en CSV"`

This split means:
- A translator cannot quickly scan descriptions for context
- Generated code comments (from descriptions) are in mixed languages
- No consistent policy is documented

### Affected Files
- `lib/l10n/app_es.arb` (throughout — ~50% of descriptions are in Spanish, ~50% in English)

### Acceptance Criteria
- [ ] Decide and document in `docs/i18n.md` the convention: descriptions in the locale's source language (English) or the target language
- [ ] Audit and normalise all `@key` descriptions in `app_es.arb` to follow the chosen convention
- [ ] Regenerate localizations

---

## Issue 6: No Regional Variant Infrastructure (Low Severity, Strategic)

### Problem
`l10n.yaml` (lines 9-15) has a comment:
```yaml
# - 'es' targets neutral Latin American Spanish (formal "usted" register).
# - Regional variants (es-MX, es-ES, es-AR) are not yet supported.
# - To add Spain-specific vocabulary, create app_es_ES.arb with
#   overrides for terms like "ordenador", "vale", "añadir", etc.
```

But there is no `localeResolutionCallback` fallback chain or documentation for how to add regional variants. The locale resolution callback in `main.dart` currently maps all Spanish variants to `'es'` — which is correct, but undocumented and invisible to future contributors.

### Affected Files
- `l10n.yaml` (lines 9-15)
- `lib/main.dart` (locale resolution callback)
- `docs/i18n.md`

### Acceptance Criteria
- [ ] Document the regional variant fallback chain in `docs/i18n.md`
- [ ] Extract locale resolution logic from `main.dart` into `LocaleConfig.supportedLocales` (see Issue 1)
- [ ] Add test confirming that `Locale('es_MX')` resolves to `Locale('es')` and uses the base ES ARB

---

## Issue 7: `durationMinutes` Abbreviation Inconsistency (Low Severity)

### Problem
English abbreviates minutes as `"1m"` / `"{count}m"` while Spanish uses `"1min"` / `"{count}min"`. This is a legitimate locale-aware difference, but it reveals that **duration abbreviations are not consistently locale-aware** across all duration keys:

| Key | EN | ES |
|---|---|---|
| `durationMinutes` | `1m` / `{count}m` | `1min` / `{count}min` |
| `durationHours` | `1h` / `{count}h` | `1h` / `{count}h` (identical — no `h` → `hr` change) |
| `durationDays` | `1d` / `{count}d` | `1d` / `{count}d` (identical) |
| `durationSeconds` | `1s` / `{count}s` | `1s` / `{count}s` (identical) |

If the intent is that abbreviations should be locale-sensitive (as shown by `minutes`), then `hours`, `days`, and `seconds` should follow. If the intent is to keep abbreviations universal, `minutes` should be aligned.

### Affected Files
- `lib/l10n/app_en.arb` (durationMinutes, durationHours, durationDays, durationSeconds)
- `lib/l10n/app_es.arb` (same keys)

### Acceptance Criteria
- [ ] Decide and document policy: are time abbreviations locale-sensitive or universal?
- [ ] If locale-sensitive: update ES hours to `"1h"` → `"1hr"` (or 1h remains universal)
- [ ] If universal: align ES `durationMinutes` to match EN `"1m"` / `"{count}m"`
- [ ] Verify all 4 duration keys are consistent per the chosen policy

---

## Summary of Impact

| # | Issue | Severity | Effort | Category |
|---|---|---|---|---|
| 1 | No centralised locale registry | High | 2-3 days | Architecture |
| 2 | `planAdherence` grammar error | High | 30 min | Translation quality |
| 3 | Hardcoded `Time conflict` in planner | High | 1 hour | Missing localisation |
| 4 | Duplicate badge key definitions | Medium | 1 hour | Maintenance |
| 5 | Inconsistent ARB description languages | Medium | 2 hours | Convention |
| 6 | No regional variant infrastructure | Low | 1 day | Architecture |
| 7 | Duration abbreviation inconsistency | Low | 30 min | Consistency |
