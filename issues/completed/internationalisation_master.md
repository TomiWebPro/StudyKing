# Internationalisation: CSV Headers Localised (Breaks Data Portability) + ~25 Untranslated Spanish Keys + Hardcoded `$` Sign

## Context

The project uses Flutter's ARB-based `AppLocalizations` for i18n with `en` and `es` locales. 920 translation keys exist in both languages. The AGENTS.md conventions explicitly state:

> **CSV exports** should remain in invariant `en` format (CSV is data, not display).
> **PDF exports** should use the user's locale (they are user-facing documents).

Three issues violate these conventions.

---

## Issue 1: CSV Column Headers Are Localised — Architectural Anti-Pattern

**Affected file:** `lib/core/services/progress_export_service.dart:44-87`

The CSV writer reads column headers from `l10n` ARB keys (`csvColTotalAttempts`, `csvColAccuracy`, etc.). This means:

- A user with locale `es` exports a CSV with Spanish column headers (`"Intentos Totales"`, `"Precisión (%)"`).
- A user with locale `en` exports a CSV with English headers (`"Total Attempts"`, `"Accuracy (%)"`).
- **Result:** CSV files from Spanish users cannot be merged or processed programmatically with English CSVs. Spreadsheet scripts, data pipelines, and `pandas.read_csv()` break because column names differ per locale.

Meanwhile, `lib/features/sessions/services/session_export_service.dart` uses **hardcoded English column names** (no locale at all), creating a second inconsistency — the two CSV exports use different approaches.

**Fix:** Hard-code CSV column headers to invariant English strings (or a fixed set of keys) regardless of locale. PDF exports (`progress_export_service.dart:126-200`) correctly use `l10n` ARB keys and locale-aware `formatDecimal` — that's the right pattern for PDFs, the wrong pattern for CSVs.

| Export | Current | Required |
|---|---|---|
| CSV (progress) | Localised headers via `l10n.csvCol*` | Invariant English headers |
| CSV (sessions) | Hardcoded English headers | Invariant English headers (already correct) |
| PDF | Localised headers + locale-aware formatting | Already correct |

---

## Issue 2: ~25 Spanish ARB Keys Untranslated (Identical to English)

**Affected file:** `lib/l10n/app_es.arb`

The following keys have identical values in both `app_en.arb` and `app_es.arb`. Several should differ for genuine Spanish localisation:

| Key | English value | Spanish value (identical) | Should differ? |
|---|---|---|---|
| `mentor` | `"Mentor"` | `"Mentor"` | Yes → `"Mentor/a"` or keep as-is (arguable) |
| `senderTutor` | `"Tutor"` | `"Tutor"` | Yes → `"Tutor/a"` or `"Tutor"` (same but worth noting) |
| `ok` | `"OK"` | `"OK"` | Yes → `"Aceptar"` or keep English (arguable) |
| `total` | `"Total"` | `"Total"` | Fine (same word) |
| `labelJson` | `"JSON"` | `"JSON"` | Fine (acronym) |
| `minutesCountMetric` | `"{count} min"` | `"{count} min"` | Fine (universal abbreviation) |
| `hoursAbbreviation` | `"{hours}h"` | `"{hours}h"` | Fine (universal abbreviation) |
| `tokensAndCost` | `"Tokens: {count} (${cost})"` | `"Tokens: {count} (${cost})"` | **See Issue 3** |
| `durationDays` | `"{count,plural, =1{1d} other{{count}d}}"` | `"{count,plural, =1{1d} other{{count}d}}"` | Fine (abbreviations) |
| `durationHours` | `"{count,plural, =1{1h} other{{count}h}}"` | `"{count,plural, =1{1h} other{{count}h}}"` | Fine (abbreviations) |
| `durationSeconds` | `"{count,plural, =1{1s} other{{count}s}}"` | `"{count,plural, =1{1s} other{{count}s}}"` | Fine (abbreviations) |
| `durationSeparator` | `" "` | `" "` | Fine (space is universal) |
| `apiKeyHint` | `"sk-or-v1-..."` | `"sk-or-v1-..."` | Fine (technical value) |
| `apiBaseUrlHint` | `"https://openrouter.ai/api/v1"` | `"https://openrouter.ai/api/v1"` | Fine (technical value) |
| `aboutApplicationName` | `"StudyKing"` | `"StudyKing"` | Fine (brand name) |
| `aboutVersion` | `"v0.1.0"` | `"v0.1.0"` | Fine (version string) |
| `aboutLegalese` | `"© 2026 StudyKing."` | `"© 2026 StudyKing."` | Fine (legal text often kept as-is) |
| `unknownModelId` | `"unknown-model"` | `"unknown-model"` | Fine (data value) |
| `errorWithMessage` | `"Error: {error}"` | `"Error: {error}"` | Yes → `"Error: {error}"` is fine for ES |

**Actionable items:**
- Translate `ok` → `"Aceptar"` or `"De acuerdo"` (Spanish users expect native confirmation labels)
- Translate `mentor` → could keep `"Mentor"` (it's the same in Spanish) — low priority
- The truly problematic keys are `tokensAndCost` (see Issue 3)

---

## Issue 3: Hardcoded `$` Sign in `tokensAndCost` (Locale-Unaware Currency)

**Affected file:** `lib/l10n/app_en.arb` line 1969, `lib/l10n/app_es.arb` line 1969

```arb
"tokensAndCost": "Tokens: {count} (${cost})"
```

The `$` is hardcoded into the translation template. The `cost` parameter is passed as a pre-formatted string (via `formatCurrency` in `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:275`), so the `$` in the template is redundant and misleading. If the `formatCurrency` call is ever changed to use a non-USD symbol, the `$` in the template will be a visual double-currency bug.

**Fix:** Remove `$` from both ARB files. The `cost` placeholder already contains the currency symbol from `formatCurrency`.

---

## Acceptance Criteria

- [ ] `progress_export_service.dart` CSV headers use invariant English strings, not `l10n` keys — CSV files are locale-independent
- [ ] `session_export_service.dart` CSV approach remains consistent (already uses invariant English)
- [ ] PDF exports in `progress_export_service.dart` continue using `l10n` keys and locale-aware number formatting (no regression)
- [ ] `ok` in `app_es.arb` is translated to `"Aceptar"`
- [ ] `tokensAndCost` in both EN and ES ARB files removes the hardcoded `$` prefix from the template
- [ ] All other ~25 keys reviewed and confirmed appropriate for Spanish (most are fine, no change needed)
- [ ] `csvOverallStats`, `csvTopicMastery`, `csvAllAttempts`, `csvWeeklyTrend`, `csvBadges` and all `csvCol*` keys remain in ARB files for PDF use, but are **not used** for CSV column construction (or are used only for PDFs)
