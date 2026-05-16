# Systematic Locale-Unaware Percentage Formatting & Hardcoded User-Facing Strings

## Context

The codebase already has a locale-aware percentage utility (`formatPercent` in `lib/core/utils/number_format_utils.dart`) and an ARB-based i18n system. However, **12 presentation widgets bypass both** and use the pattern `'${(value * 100).round()}%'` directly. For **Spanish (es)** and other comma-decimal locales like French, German, Portuguese, this produces **incorrect output**: e.g. `85.5%` instead of the correct `85,5%`.

Additionally, several widgets embed **untranslated shorthand strings** and **hardcoded status labels** that are invisible to the i18n system.

---

## Issue 1: Hardcoded `'${(value * 100).round()}%'` in 12 locations across 8 files

These use Dart's default number-to-string conversion which always produces a period decimal separator, ignoring the active locale.

### Affected files

| File | Line(s) | Current Code |
|---|---|---|
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart` | 77, 183 | `'${(data.todayProgress * 100).round()}%'` and `'${(data.cumulativeProgress * 100).round()}%'` |
| `lib/features/planner/presentation/widgets/plan_summary_card.dart` | 62 | `'${(summary.estimatedCoverage * 100).round()}%'` |
| `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` | 108 | `'${(progress * 100).round()}%'` |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 151 | `'${(score * 100).round()}%'` |
| `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` | 49 | `'${(state.accuracy * 100).round()}%'` |
| `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` | 79 | `'${(state.accuracy * 100).round()}%'` |
| `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` | 60–61 | `'${(avgAccuracy * 100).round()}%'` and `'${(avgReadiness * 100).round()}%'` |
| `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` | 41, 49 | `'${(averageAdherence * 100).round()}%'` and `'${(weeklyAdherence * 100).round()}%'` |

### Rationale

The only way to render locale-correct percentages in Flutter is through `NumberFormat.percentPattern(localeName)`, which is already wrapped in `formatPercent()` at `lib/core/utils/number_format_utils.dart:15`. All these call sites should either use that utility or pass the formatted string through an ARB message (preferred when the surrounding text also needs translation).

---

## Issue 2: Untranslated roadmap status badge (`roadmap_card.dart:51`)

The `roadmap.status` string (values: `"active"`, `"completed"`, etc.) is displayed directly via `Text(roadmap.status, ...)`.

- **Spanish speakers** see `"active"` and `"completed"` in English.
- The ARB files already have `"inProgress"`, `"completed"`, `"notStarted"` keys.
- **Fix**: Map the raw status string to the appropriate ARB key.

---

## Issue 3: Hardcoded `'M${milestone.order}'` label (`milestone_timeline.dart:86`)

The milestone abbreviation prefix `"M"` is hardcoded. In Spanish, an abbreviation like `"H"` (for "Hito") would be expected. This should go through an ARB key or use `l10n.milestone` combined with numbering.

---

## Issue 4: Hardcoded Shorthand Labels

Three widgets embed English-centric shorthand that is not exposed to the i18n system:

| File | Line | Code | Problem |
|---|---|---|---|
| `plan_summary_card.dart` | 53 | `'${summary.totalQuestions}Q'` | "Q" is English; Spanish uses `"P"` (preguntas) |
| `calendar_view_widget.dart` | 168 | `'${dailyPlan.targetMinutes}m'` | "m" is assumed universal but should go through ARB (cf. `minutesCountMetric` and `durationMinutes` keys) |
| `lesson_progress_bar.dart` | 166 | `'${section.durationMinutes}min'` | Hardcoded "min" instead of using `l10n.durationMinutes` or `l10n.minutesValue` |

Note: the ARB files already have `questionsAndMinutes`, `topicQuestionsAndMinutes`, `minutesCountMetric`, `durationMinutes` keys that cover these shorthands. The widgets simply aren't using them for these specific labels.

---

## Issue 5: Hardcoded ISO date format in `lesson_booking_sheet.dart:106`

```dart
'${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'
```

This always renders `YYYY-MM-DD` regardless of locale. **Spanish** expects `DD/MM/YYYY` (or a named format like `15 de mayo de 2026`). Should use `DateFormat.yMd(l10n.localeName)`.

---

## Acceptance Criteria

1. All 12 hardcoded `${(value * 100).round()}%` patterns replaced with `formatPercent(value, localeName)` — verify with `Locale('es')` that the output is `85,5%` not `85.5%`.
2. `roadmap.status` shows translated label ("Activo", "Completado") when locale is Spanish.
3. `'M${milestone.order}'` goes through ARB (e.g., `l10n.milestoneShort(milestone.order)` or equivalent).
4. Shorthand labels (`Q`, `m`, `min`) replaced with existing ARB keys: `questionsAndMinutes`, `minutesCountMetric`, `durationMinutes`.
5. Hardcoded ISO date in `lesson_booking_sheet.dart:106` replaced with `DateFormat.yMd(localeName)` or `.yMMMd()` depending on UX intent.
6. All changes produce correct output for both `es` and `en` locales without regression.
7. At least one widget test for a percentage-displaying widget asserts the correct Spanish-formatted output.

## Spanish as a Template for Future Locales

Every fix above should be implemented by **adding an ARB key** (if one doesn't already exist) and referencing it through `AppLocalizations.of(context)`. This creates a clear pattern: any new language only needs a new `.arb` file without touching source code.
