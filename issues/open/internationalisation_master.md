# Internationalisation Master Report

**Target locale**: Spanish (es) — findings apply to all non-English locales.
**Audit date**: 2026-05-21
**Scope**: All source files under `lib/`, all ARB files under `lib/l10n/`.

---

## Executive Summary

The StudyKing codebase has solid i18n foundations: `flutter_localizations` + `intl` are wired correctly, `l10n.yaml` is well-configured, both `.arb` files (en/es) are comprehensive with full placeholder parity and proper pluralisation, and most UI strings route through `AppLocalizations`. Directionality is handled correctly across the board.

However, **7 hardcoded English strings** remain in production widgets, **10 layout patterns** will break with translated strings, and **5 number-formatting sites** bypass the locale-aware utilities in `number_format_utils.dart`. These are concentrated in `planner/`, `settings/`, and `subjects/` features.

---

## BLOCKER

*None found.*

---

## MAJOR

### M1 — Hardcoded English user-facing strings (7 locations)

These strings bypass `AppLocalizations` entirely. A Spanish user will see English fragments embedded in an otherwise localised UI.

| # | File | Line(s) | String | Context |
|---|---|---|---|---|
| 1 | `lib/features/settings/presentation/api_config_screen.dart` | 149 | `'Please select a model before saving.'` | SnackBar — no model selected |
| 2 | same file | 590–593 | `'Provider Changed'` + `'Changing the provider will clear…'` | AlertDialog title + body |
| 3 | same file | 598 | `'OK'` | AlertDialog button |
| 4 | `lib/features/planner/presentation/widgets/syllabus_progress_card.dart` | 126 | `'No progress yet'` | Fallback text when `masteredCount == 0` |
| 5 | same file | 155–157 | `'You haven\'t practiced…yet. Start by…'` | Descriptive sentence below progress bar |
| 6 | same file | 173 | `'Practice Questions'` | ActionChip label |
| 7 | same file | 178 | `'Start Lesson'` | ActionChip label |
| 8 | `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 317–318 | `'Move … from … to …?\n\nThis will update your schedule.'` | Reschedule confirmation dialog |
| 9 | same file | 327 | `'Confirm'` | FilledButton in the same dialog |
| 10 | `lib/features/questions/presentation/question_bank_screen.dart` | 259 | `'JSON'` | Export-format button (next to `l10n.exportCsv`) |
| 11 | `lib/core/widgets/animated_bar_chart.dart` | 162–163 | `'No activity'` | Semantics fallback when no `semanticsLabelBuilder` is provided |

**AC**: Each of these strings is replaced with a corresponding `l10n.someKey` entry. New ARB keys are added to both `app_en.arb` and `app_es.arb`. Confirmed via `grep` that no `const Text('…')` with a user-facing English string remains outside of data labels.

---

### M2 — Fixed-width label column clips translated labels

`lib/features/ingestion/presentation/source_detail_screen.dart:675–681`

```dart
SizedBox(
  width: 120,
  child: Text(label),
),
```

The `_InfoRow` widget bakes a `width: 120` for the label column. Labels like `"Status"`, `"Subject"`, `"Source Type"` fit in English but their Spanish equivalents (e.g. `"Estado de procesamiento"`, `"Tipo de fuente"`) are longer and will be clipped.

**AC**: Replace `SizedBox(width: 120` with `SizedBox(width: 160` or (better) use a `Row` with `IntrinsicWidth` for the label and `Expanded` for the value, so the label column auto-sizes to content.

---

### M3 — Rows without `Expanded` wrapping — text overflow with long translations

Ten `Row` widgets that use `MainAxisAlignment.spaceBetween` or bare concatenation without `Expanded` will overflow horizontally when labels are translated to longer Spanish equivalents.

| File | Line(s) | Pattern |
|---|---|---|
| `lib/features/dashboard/presentation/screens/topic_detail_screen.dart` | 284–293 | `_buildInfoRow`: `Row > Text('$label: ') + Text(value)` — no `Expanded` |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 417–428 | `_detailRow`: `Row(mainAxisAlignment: spaceBetween) > Text(label) + Text(value)` |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 827–838 | `_buildResultRow` — same `spaceBetween` + no `Expanded` |
| `lib/features/practice/presentation/screens/practice_results_screen.dart` | 262–269 | `_buildStatRow` — same pattern |
| `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` | 167–179 | `Row > Text(attemptsCount) + Text(masteryLabel)` — no `Expanded` |
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | 97–103 | `Row(spaceBetween) > _miniStat × 3` — three `Text` widgets without `Expanded` |
| `lib/features/planner/presentation/widgets/roadmap_card.dart` | 130–142 | `Row(spaceBetween) > Text(completion) + Text(milestones)` |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 561–576 | subtitle `Row` — status badge + question count with no `Expanded` |

**AC**: Every `Row` containing a `Text` with a translatable string wraps the text in `Expanded(...)`. Or the entire row is refactored to use `MainAxisAlignment.start` + a `Spacer` if the layout intent is start-aligned label + end-aligned value.

---

### M4 — Locale-unaware number formatting (`toString` / string interpolation)

The project `AGENTS.md` mandates `formatDecimal` / `formatPercent` from `number_format_utils.dart`. Five sites ignore this and use plain string interpolation, which produces an invariant period decimal separator and no digit-grouping — incorrect for `es` (comma decimal) and all non-English locales that use grouping.

| File | Line | Code | Fix |
|---|---|---|---|
| `lib/features/subjects/presentation/widgets/subject_stats_tab.dart` | 289 | `'${l10n.mastered} ${data.masteredCount} / ${data.totalTopics}'` | `'${l10n.mastered} ${formatDecimal(data.masteredCount.toDouble(), l10n.localeName)} / ${formatDecimal(data.totalTopics.toDouble(), l10n.localeName)}'` |
| `lib/features/planner/presentation/widgets/roadmap_card.dart` | 138 | `'$completedMilestones/$totalMilestones ${l10n.milestones}'` | Wrap both ints in `formatDecimal()` |
| `lib/features/practice/presentation/screens/practice_screen.dart` | 960–968 | `'$_weakTopicCount ${l10n.masteryLevelDeveloping}'` (×3) | Wrap each count in `formatDecimal()` |
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | 82–83 | `'$masteredTopics'`, `'${totalTopics - masteredTopics - weakTopics}'` | Wrap in `formatDecimal()` |
| `lib/features/settings/presentation/settings_screen.dart` | 814, 837 | `'$d ${l10n.days}'` | `'${formatDecimal(d.toDouble(), l10n.localeName)} ${l10n.days}'` |

**AC**: All five sites are updated. Verified that `flutter test` passes and the rendered UI in `es` locale shows comma decimal separators and digit-grouping dots where expected.

---

### M5 — PDF export uses hardcoded unit suffixes

`lib/core/services/progress_export_service.dart:184–185`

```dart
[l10n.avgTime, '${overallStats['avgTimePerQuestion']}s'],
[l10n.totalStudyTime, '${formatDecimal(…)}h'],
```

The `'s'` (seconds) and `'h'` (hours) suffixes are hardcoded English abbreviations. The project convention states *"PDF exports should use the user's locale"*.

**AC**: Replace with locale-aware alternatives:
- `l10n.hoursAbbreviation` / `l10n.secondsAbbreviation` ARB keys (or reuse existing `durationSeconds` / `durationHours` patterns).
- If the surrounding value is always numeric, use `l10n.formatDuration` or `l10n.durationMinutesSeconds`.

---

## MINOR

### m1 — ARB `@description` language inconsistency

In `lib/l10n/app_es.arb`, ~20 keys near the end of the file have `@description` values written in Spanish instead of English (e.g. `"Subtitulo para el mosaico de monitoreo de tareas de IA"`). ARB convention dictates that `@description` metadata for non-template files should remain in the template language (English) so tooling and code reviewers can understand it.

**AC**: Revert the ~20 Spanish `@description` values to English, matching the convention used by the other ~7,600 keys.

---

### m2 — LLM prompts hardcoded in English (system-to-LLM)

| File | Lines | Context |
|---|---|---|
| `lib/features/planner/services/llm_planner_advisor_strategy.dart` | 75–150 | `_buildPlanGenerationPrompt` and `_buildAdaptationPrompt` — full English instruction blocks |
| `lib/features/mentor/services/mentor_context_builder.dart` | 85, 96, 102 | `'$bullet Missed lessons: …'`, `'$bullet Redistribution was applied…'`, `'$bullet Extra minutes per day: …'` |

These are LLM-facing prompts, so the impact on the UI is indirect. However, Spanish-speaking students receive English system prompts when the LLM responds. The mentor context builder already uses `l10n.mentorContext*` keys for most strings — these three lines should follow the same pattern.

**AC**:
- `mentor_context_builder.dart`: Replace the three hardcoded bullet strings with `l10n.mentorContextMissedLessons(count)`, `l10n.mentorContextRedistributionApplied`, and `l10n.mentorContextExtraMinutes(extra, remaining)`.
- `llm_planner_advisor_strategy.dart`: At minimum, inject a `"Respond in the student's language"` instruction derived from the current locale.

---

### m3 — Answer validation service English defaults

`lib/core/services/answer_validation_service.dart:189–200` — The `ValidationMessages._english()` constructor contains 11 hardcoded English strings (e.g. `'No markscheme available'`, `'Correct!'`, `'Incorrect.'`). These are used as the `ValidationMessages.english` static constant, which is the fallback when no `AppLocalizations` is available.

The `fromLocalizations()` factory (line 234) correctly pulls from l10n, so the production path is localised. The English defaults are only reached in edge cases.

**AC**: No urgent action needed. Optionally, add a runtime locale check in the static `english` constant so it logs a warning when used unexpectedly.

---

### m4 — PDF export RTL alignment limitation

`lib/features/sessions/services/session_export_service.dart:139–149` — The `cellAlignments` map hardcodes `pw.Alignment.centerLeft` and `pw.Alignment.centerRight`. A code comment on line 139–140 acknowledges this limitation: *"For RTL support, this would need centerStart/centerEnd once the library adds it."*

**AC**: Track the upstream `pdf` library for `centerStart`/`centerEnd` alignment support. Until then, document this as a known RTL limitation.

---

### m5 — Hardcoded padding reduces text area for translated strings

Several screens wrap error/empty-state text in `EdgeInsets.symmetric(horizontal: 32)` or `EdgeInsets.all(24)` inside `SizedBox`-constrained cards. These were designed for short English messages; Spanish equivalents (and other locales) are typically 25–30% longer and may wrap awkwardly or overflow.

| File | Line(s) | Padding |
|---|---|---|
| `lib/features/settings/presentation/settings_screen.dart` | 381 | `horizontal: 32` on error text |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 494 | `horizontal: 32` on error text |
| `lib/features/settings/presentation/profile_screen.dart` | 311 | `horizontal: 32` on error text |

**AC**: Reduce to `horizontal: 16` or switch to percentage-based padding using `MediaQuery.of(context).size.width * 0.05` for small screens.

---

### m6 — Dashboard header title overflow risk

`lib/features/dashboard/presentation/widgets/dashboard_header.dart:25`

```dart
overflow: TextOverflow.ellipsis,
```

The title `l10n.studyDashboard` is short in English but `overflow: ellipsis` with no `maxLines` provides no defensive measure. In `es` the string is `"Panel de estudio"` — still fine — but if a future locale has a longer title (e.g. `"Tableau de bord d'étude"` in French) it will be silently truncated.

**AC**: Add `maxLines: 2` alongside the existing `overflow: TextOverflow.ellipsis`.

---

### m7 — `lesson_booking_sheet.dart` uses locale-aware date format but not locale-aware number format

`lib/features/planner/presentation/widgets/lesson_booking_sheet.dart:310–311`

```dart
final fmt = DateFormat.yMMMd(l10n.localeName);
final oldTime = fmt.format(widget.initialDate!);
```

The date formatter is correct. However, the dialog body (line 317–318) embeds `widget.topicTitle` via raw interpolation — fine since topic titles are user data. The `'Confirm'` button is already flagged in M1.

**AC**: Addressed by M1 (the button) and M4 (numbers in the broader file). No additional action needed for the date format itself.

---

### m8 — Pluralisation edge case: `=0` message style divergence

In `overDaysPlural`:
- EN: `"{count, plural, =0{no days} =1{1 day} other{{count} days}}"`
- ES: `"{count, plural, =0{0 días} =1{1 día} other{{count} días}}"`

The English zero-case says `"no days"` (qualitative), but Spanish zero-case says `"0 días"` (quantitative). Both are valid, but for consistency with English style the Spanish could use `"ningún día"`.

**AC**: No urgent action. Flag for UX review to confirm whether qualitative ("ningún día") or quantitative ("0 días") is preferred for all zero-case plural messages.

---

## Summary Table

| ID | Severity | Area | Type | Count |
|---|---|---|---|---|
| M1 | MAJOR | settings, planner, questions, core | Hardcoded English strings | 7 sites / 11 strings |
| M2 | MAJOR | ingestion | Fixed-width layout | 1 site |
| M3 | MAJOR | dashboard, subjects, practice, planner | Row overflow (no Expanded) | 8 sites |
| M4 | MAJOR | subjects, dashboard, practice, settings | Unformatted numbers | 5 sites |
| M5 | MAJOR | core (PDF export) | Hardcoded unit suffixes | 1 site |
| m1 | MINOR | l10n | ARB @description language | ~20 keys |
| m2 | MINOR | planner, mentor | Hardcoded LLM prompts | 2 files |
| m3 | MINOR | core (validation) | English fallback defaults | 1 file |
| m4 | MINOR | sessions (PDF) | RTL alignment limitation | 1 site |
| m5 | MINOR | settings, subjects | Tight padding for error text | 3 sites |
| m6 | MINOR | dashboard | Title overflow risk | 1 site |
| m7 | MINOR | planner | Covered by M1 | — |
| m8 | MINOR | l10n | Zero-case style divergence | 1 key |

---

## Quick Wins (fix in order)

1. **M1** — Add 7 new ARB keys to `app_en.arb` + `app_es.arb` and replace the `const Text('…')` calls.
2. **M4** — Wrap 5 number interpolations with `formatDecimal(count.toDouble(), l10n.localeName)`.
3. **M5** — Add `hoursAbbreviation` / `secondsAbbreviation` ARB keys and use them in the PDF table.
4. **M3** — Wrap 8 `Row` > `Text` patterns in `Expanded(...)`.
5. **M2** — Increase or auto-size the `SizedBox(width: 120)` in `source_detail_screen.dart`.
