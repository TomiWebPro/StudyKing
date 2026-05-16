# Spanish Localization Gaps: Hardcoded English Strings and Locale-Unaware Formatting

## Context

The codebase has 100% ARB key parity and strong i18n infrastructure (`locale_config.dart`, `number_format_utils.dart`, `time_utils.dart`, CI coverage checks). However, several UI surfaces still bypass the translation system with hardcoded English strings or locale-unaware formatting. These gaps mean Spanish (and future) users see English fragments mixed into their localized UI.

## Affected Files

| File | Lines | Issue |
|---|---|---|
| `lib/features/ingestion/presentation/upload_screen.dart` | 83, 136, 141, 150, 363, 428 | Hardcoded English SnackBar/chip/button strings |
| `lib/features/dashboard/presentation/widgets/summary_row.dart` | 43, 52 | `'$accuracy%'` and `'...h'` bypass locale-aware formatting |
| `lib/features/planner/presentation/planner_screen.dart` | 408 | `'${goal.targetHoursPerDay}h/${l10n.days}'` — hardcoded `h` |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | 122, 270, 278 | Hardcoded `$` symbol and `tokens` label |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | 141 | Timer format `m:ss` — hardcoded `:` separator |
| `lib/features/settings/data/models/settings_model.dart` | 114–188 | `formattedText`, `formatUsageSummary` produce English-only sentences |
| `lib/features/sessions/services/session_export_service.dart` | 158–169 | PDF duration format uses `'h'` / `'m'` instead of locale-aware `l10n.durationHours` |
| `lib/l10n/app_en.arb` / `app_es.arb` | missing keys | Missing ARB keys for URL/file fetch messages, `tokens` label, `currencySymbol` |

## Issues

### P0 — Missing ARB keys (6 strings never reach translations)

Six user-facing strings in `upload_screen.dart` are hardcoded in English. They never pass through `AppLocalizations`, so Spanish users always see English messages.

- **Line 83**: `Text('File picker error: $e')`
- **Line 136**: `Text('URL content fetched successfully')`
- **Line 141**: `Text('Failed to fetch URL: ${result.error}')`
- **Line 150**: `Text('URL fetch error: $e')`
- **Line 363**: `label: const Text('File')`
- **Line 428**: `label: const Text('Fetch & Scrape')`

The existing keys `uploadFailed` and `contentUploadedSuccessfully` are for *submission* errors — these are *content ingestion* errors and need separate keys.

**Fix**: Add ARB keys in both `app_en.arb` and `app_es.arb`:
- `filePickerError` → `"File picker error: {error}"` / `"Error del selector de archivos: {error}"`
- `urlFetchSuccess` → `"URL content fetched successfully"` / `"Contenido de URL obtenido exitosamente"`
- `urlFetchFailed` → `"Failed to fetch URL: {error}"` / `"Error al obtener URL: {error}"`
- `urlFetchError` → `"URL fetch error: {error}"` / `"Error de obtención de URL: {error}"`
- `file` → `"File"` / `"Archivo"`
- `fetchAndScrape` → `"Fetch & Scrape"` / `"Obtener y extraer"`

### P1 — Locale-unaware unit abbreviations

Three files render unit abbreviations (`%`, `h`, `$`) by concatenation, which is invisible to the ARB system and unbreakable for comma-decimal locales.

- **`summary_row.dart:43`**: `'$accuracy%'` — should use `formatPercent(accuracy / 100, l10n.localeName)` (note: `formatPercent` takes 0–100 range internally and handles division)

- **`summary_row.dart:52`**: `'${formatDecimal(...)}h'` — the `h` suffix should use `l10n.hoursAbbreviation` or be wrapped in an ARB template. Same pattern in **`planner_screen.dart:408`** (`'...h/${l10n.days}'`).

- **`llm_task_manager_screen.dart:122`**: `'\$${formatDecimal(...)}'` — hardcodes `$`. Should use `NumberFormat.currency(...)` with locale or an ARB `currencySymbol` key. Same pattern in **`settings_model.dart:114,120,188`**.

- **`llm_task_manager_screen.dart:270`**: `'${_formatTokens(task.tokensUsed, l10n.localeName)} tokens'` — hardcodes `tokens`. Should use ARB key `tokensLabel: "{count} tokens"` / `"{count} tokens"` or `l10n.tokensAndCost`.

### P1 — English-only user-facing model strings

`settings_model.dart` has three methods that produce fully English strings:

- **`formattedText`/`formattedTextWithLocale`** (lines 118–122): Produces strings like `"2025-01-15: $0.1234, cost/tk: 0.0000001234"` — the labels `cost/tk` are English.
- **`formatUsageSummary`** (line 184–189): Produces `"Usage: $X.XX over Y tokens, avg: $Z.ZZ per 1k tokens"` — a whole English sentence.

These are used in `settings_screen.dart` (a user-facing screen). The text should be assembled from ARB template keys with placeholders, or the methods should accept `AppLocalizations`.

**Fix**: Create ARB keys:
- `usageRecordFormat` → `"{date}: {cost}, cost/tk: {costPerToken}"` (ES: `"{date}: {cost}, costo/token: {costPerToken}"`)
- `usageSummary` → `"Usage: {totalCost} over {totalTokens} tokens, avg: {avgCost} per 1k tokens"` (ES: `"Uso: {totalCost} sobre {totalTokens} tokens, promedio: {avgCost} por cada 1k tokens"`)

### P2 — PDF duration format bypasses locale

`session_export_service.dart` lines 158–169 format durations in PDF output using hardcoded `'h'`, `'m'`, `'s'` suffixes. Per AGENTS.md, "PDF exports should use the user's locale." The ARB already has `durationHours`, `durationMinutes`, `durationSeconds` keys with proper pluralization.

**Fix**: Replace `_formatTotalDuration` and `_formatDuration` to accept `AppLocalizations` (or `l10n.localeName`) and use `l10n.durationHours(count)`, `l10n.durationMinutes(count)`, etc.

### P2 — Lesson detail timer separator

`lesson_detail_screen.dart:141`: `'${_elapsed.inMinutes}:${_elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}'` — the `:` separator is hardcoded. Consider whether this timer is always 7-segment digital (in which case `:` is acceptable as a non-linguistic separator) or should be localized. Minor issue, flagged for awareness.

## Acceptance Criteria

1. **New ARB keys** added to both `app_en.arb` and `app_es.arb`:
   - `filePickerError` (with `{error}` placeholder)
   - `urlFetchSuccess` (no placeholder)
   - `urlFetchFailed` (with `{error}` placeholder)
   - `urlFetchError` (with `{error}` placeholder)
   - `file` (no placeholder)
   - `fetchAndScrape` (no placeholder)
   - `hoursAbbreviation` (e.g., `"{count}h"` → ES: `"{count}h"`)
   - `tokensLabel` (e.g., `"{count} tokens"` → ES: `"{count} tokens"`)
   - `usageRecordFormat` / `usageSummary` (templated with placeholders)
2. **All 6 hardcoded strings in `upload_screen.dart`** replaced with `l10n.*` calls.
3. **`summary_row.dart:43`** uses `formatPercent()` instead of `'$accuracy%'`.
4. **No hardcoded `$` currency signs remain** in user-facing UI code (use `NumberFormat.currency` or ARB key).
5. **No hardcoded `h` suffixes remain** in user-facing widgets (use `l10n.hoursAbbreviation` or `l10n.durationHours`).
6. **`settings_model.dart`** `formattedText`/`formatUsageSummary` methods accept `AppLocalizations` or use templated ARB keys.
7. **PDF export** in `session_export_service.dart` uses locale-aware durations instead of `'h'`/`'m'`/`'s'`.
8. **Coverage tests** pass (existing `check_i18n_coverage.sh` and test suite).
9. **`check_i18n_coverage.sh`** updated if needed to validate the new keys.

## Rationale

Spanish was chosen as the first non-English locale because it is the second most spoken language globally and follows Latin American conventions. Fixing these gaps now ensures that adding new locales (fr, de, pt, etc.) is purely additive (new ARB file + new `AppLocale` entry) with zero code changes. Every hardcoded English string is a barrier to adding the next language.
