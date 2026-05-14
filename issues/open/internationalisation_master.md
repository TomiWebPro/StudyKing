# Spanish Localisation Quality & i18n Architecture Improvements

## Summary

The codebase has a solid foundation with `flutter_localizations` + ARB files for English and Spanish, but Spanish translation quality suffers from duplicate keys with conflicting values, and several features bypass the localisation system entirely with hardcoded English strings. These issues block reliable Spanish support and make adding future languages error-prone.

---

## Issue 1: Duplicate JSON Keys in ARB Files

Both `app_en.arb` and `app_es.arb` contain duplicate top-level keys. In JSON, the last occurrence wins silently, meaning one translation is discarded without warning. This creates a maintenance trap where translators see conflicting values for the same key.

**Affected files:**
- `lib/l10n/app_en.arb` — duplicates with identical values (tolerable but noisy)
- `lib/l10n/app_es.arb` — duplicates; one with a **real conflict**

**Confirmed duplicates in `app_es.arb`:**

| Key | First value (line) | Second value (line) | Conflict? |
|---|---|---|---|
| `masteryLevelDeveloping` | `"Desarrollando"` (~1693) | `"En Desarrollo"` (~2549) | **YES** |
| `masteryLevelBrowsing` | `"Explorando"` (~1690) | `"Explorando"` (~2545) | No |
| `masteryLevelProficient` | `"Competente"` (~1698) | `"Competente"` (~2554) | No |
| `noTopicDataYet` | (text) (~1682) | (text) (~2538) | No |
| `achievements` | `"Logros"` (~1642) | `"Logros"` (~2562) | No |
| `topicPerformance` | (text) (~1638) | (text) (~2534) | No |
| `thisWeek` | (text) (~1658) | (text) (~2574) | No |
| `studyTime` | (text) (~1626) | (text) (~2514) | No |
| `exportCsv` | (text) (~1646) | (text) (~2578) | No |
| `masteryOverview` | (text) ~1634) | (text) (~2266) | No |

The `masteryLevelDeveloping` conflict means the effective Spanish translation is whichever appears last — a reader would silently see a different label than the translator intended.

**Rationale:** Duplicate keys make the ARB files unreliable as a source of truth. Adding a CI lint step (`json_validation` or a custom script) to reject duplicates would prevent this. Recommending using `flutter gen-l10n` with `--synthetic-package` and adding a pre-commit/CI check that `jq` can parse ARB files without duplicate-key warnings would catch these.

---

## Issue 2: `progress_export_service.dart` Ignores `AppLocalizations` for PDF/CSV Content

`lib/core/services/progress_export_service.dart` accepts `AppLocalizations l10n` as a parameter (line 95) but uses it **only for the function signature** — every user-facing string inside `exportComprehensivePDF` and `exportComprehensiveCSV` is hardcoded in English.

**Hardcoded strings found (not exhaustive):**
- Lines 43–90: CSV section headers `'=== OVERALL STATS ==='`, `'=== TOPIC MASTERY ==='`, `'=== ALL ATTEMPTS ==='`, `'=== WEEKLY TREND ==='`, `'=== BADGES ==='`
- Lines 114, 281, 313, 328: `'StudyKing Progress Report'`
- Lines 122–130: `'Generated: ...'`, `'Student ID: ...'`
- Lines 135, 163, 214, 248: PDF headers `'Overall Statistics'`, `'Topic Mastery Breakdown'`, `'Badges Earned'`, `'Recent Activity Summary'`
- Lines 139–149: Table headers `'Metric'`, `'Value'`, `'Total Attempts'`, `'Correct Answers'`, `'Accuracy'`, etc.
- Lines 204, 238: Empty state messages `'No mastery data available yet.'`, `'No badges earned yet. Keep studying!'`

**Acceptance criteria:**
- All user-facing strings in `exportComprehensivePDF` and `exportComprehensiveCSV` must use `l10n.*` getters (the parameter already exists).
- Missing ARB keys must be added to both `app_en.arb` and `app_es.arb`.
- `Share.shareXFiles` calls should use localized text for the `text:` parameter.

---

## Issue 3: Focus Mode Entirely Bypasses Localisation

The entire `lib/features/focus_mode/` feature uses hardcoded English strings with no `AppLocalizations` access.

**Affected files and strings:**

| File | Line(s) | Hardcoded string |
|---|---|---|
| `focus_timer_screen.dart` | 134, 184, 191 | `'Focus Mode'` (appBar title ×2) |
| `focus_timer_screen.dart` | 134 | `'Daily Limit Reached'` |
| `focus_timer_screen.dart` | 135–137 | `'You\'ve reached your daily study limit...'` |
| `focus_timer_screen.dart` | 142 | `'OK'` |
| `focus_timer_screen.dart` | 162 | `'Error starting session: $e'` |
| `focus_timer_screen.dart` | 196 | `'Refresh stats'` (tooltip) |
| `focus_timer_widget.dart` | 127–128 | `'PAUSED'`, `'DONE!'`, `'remaining'` |
| `focus_timer_widget.dart` | 153 | `'Resume'` |
| `focus_timer_widget.dart` | 159 | `'Pause'` |
| `focus_timer_widget.dart` | 165 | `'End'` |
| `focus_timer_widget.dart` | 177 | `'Mark Complete'` |

**Acceptance criteria:**
- All focus-mode screens must access `AppLocalizations.of(context)` and use ARB keys.
- New Spanish ARB entries must be added for each key.
- The timer status labels (`'PAUSED'`, `'DONE!'`, `'remaining'`) need lower-cased locale-aware alternatives in Spanish (`EN PAUSA`, `¡TERMINADO!`, `restante`).

---

## Issue 4: `session_history_screen.dart` — Hardcoded `'JSON'`

`lib/features/sessions/presentation/session_history_screen.dart:290` uses `Text('JSON')` instead of a localized key. ARB keys exist for CSV and PDF (`exportCsv`, `exportPdf`, `comprehensiveCsv`, `comprehensivePdf`, `comprehensiveJson`) but a plain `'JSON'` label is missing.

**Acceptance criteria:**
- Add a `labelJson` key to both ARB files (`"JSON"` for English, `"JSON"` or `"Formato JSON"` for Spanish).
- Replace `Text('JSON')` with the localized getter.

---

## Issue 5: Spanish Translation Refinements

Beyond the duplicate-key conflict, several Spanish translations could be improved for naturalness:

| Key | Current Spanish | Suggested | Rationale |
|---|---|---|---|
| `masteryLevelDeveloping` | `"Desarrollando"` or `"En Desarrollo"` | `"En Desarrollo"` | "Desarrollando" (gerund) is ungrammatical as a label; "En Desarrollo" matches the English "Developing" nominal form |
| `instrumentation` | `"Instrumentación"` | `"Instrumentación"` or translate contextually | Technically correct but the English term "Instrumentation" itself is jargon — consider a friendlier label or translatable description |
| `planAdherence` | `"Cumplimiento del Plan"` | `"Adherencia al Plan"` | "Cumplimiento" means compliance; "Adherencia" is closer to "Adherence" in educational contexts |
| `drawingWithStrokes` | `"Dibujando con {count} trazos"` | `"Dibujo con {count} trazos"` | Gerund again as a static label — "Dibujo" (noun) is more natural |
| `considerUsingPieChart` | `"Considere usar un Gráfico Circular para conjuntos pequeños de datos"` | `"Considere usar un gráfico circular para conjuntos pequeños de datos"` | Lowercase "gráfico circular" (Spanish typographic convention for chart types) |
| `considerUsingBarChart` | `"Considere usar un Gráfico de Barras para conjuntos grandes de datos"` | `"Considere usar un gráfico de barras para conjuntos grandes de datos"` | Same lowercase convention |

**Acceptance criteria:**
- Resolve the `masteryLevelDeveloping` duplication conflict.
- Apply lowercase convention to graph-type names in Spanish (matching Spanish typographic norms).
- Review remaining Spanish strings for naturalness by a native speaker.

---

## Acceptance Criteria (full list)

1. **Duplicate keys eliminated** — ARB files pass `jq` duplicate-key validation; a pre-commit or CI hook prevents regressions.
2. **`progress_export_service.dart` fully localized** — PDF and CSV content uses `l10n.*` getters; all needed keys in both ARB files.
3. **Focus mode localized** — `focus_timer_screen.dart` and `focus_timer_widget.dart` use `AppLocalizations`.
4. **`'JSON'` label added** — ARB key `labelJson` created and used in `session_history_screen.dart`.
5. **Spanish refinements applied** — `masteryLevelDeveloping` deduplicated, typographic casing fixed, naturalness reviewed.
6. **All generated files regenerated** — run `flutter gen-l10n` after edits to regenerate `lib/l10n/generated/`.
7. **Existing l10n tests pass** — `test/l10n/app_localizations_test.dart` and `test/l10n/app_localizations_coverage_test.dart` must remain green.
