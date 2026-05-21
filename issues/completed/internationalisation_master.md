# Internationalisation Master Issue

**Target locale for verification:** Spanish (`es`)
**Generated:** 2026-05-20
**Scope:** Hardcoded strings, number formatting, RTL layout, .arb correctness, LLM prompts

---

## BLOCKER

### B1. Hardcoded English strings in sign-out confirmation dialog

**Files:**
- `lib/features/settings/presentation/settings_screen.dart:1669-1680`

**Context:** The sign-out dialog (`_buildSignOutDialog`) contains four `const Text(...)` widgets with hardcoded English strings that are never routed through `AppLocalizations`:

```dart
title: const Text('Clear all study data'),                            // line 1669
subtitle: const Text('Removes all subjects, questions, attempts, and progress'),  // line 1670
title: const Text('Back up before signing out'),                      // line 1679
subtitle: const Text('Creates a backup file before clearing data'),   // line 1680
```

**Rationale:** A Spanish user navigating through Ajustes → Cerrar Sesión will see these options in English while the rest of the dialog is in Spanish (cancel, signOut, descriptive bullet points). This is a UX blocker — the user cannot make an informed decision about data deletion.

**Acceptance criteria:**
1. Add four new keys to `app_en.arb`:
   - `signOutClearAllData` → `"Clear all study data"`
   - `signOutRemovesAllData` → `"Removes all subjects, questions, attempts, and progress"`
   - `signOutBackupBeforeSignOut` → `"Back up before signing out"`
   - `signOutCreatesBackupFile` → `"Creates a backup file before clearing data"`
2. Add Spanish translations for these keys in `app_es.arb`.
3. Replace `const Text(...)` with `Text(l10n.signOutClearAllData)`, etc.
4. `const` must be removed since `l10n` is a runtime value.

---

## MAJOR

### M1. Non-directional EdgeInsets in drawing widgets (RTL breakage)

**Files:**
- `lib/features/questions/presentation/widgets/graph_drawing_widget.dart:176`
- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart:226`

**Context:** Both widgets use `EdgeInsets.only(right: 4)` for inline padding. In an RTL locale (Arabic, Hebrew, Urdu), `right: 4` still pads the right side, but visually the "right" of a canvas toolbar should be the logical end. The padding is not flipped.

**Rationale:** When the app is used in an RTL locale, these 4px margins appear on the wrong side, causing visual misalignment of toolbar buttons.

**Acceptance criteria:**
1. Replace `EdgeInsets.only(right: 4)` with `EdgeInsetsDirectional.only(end: 4)` in both files.
2. Verify visually using an RTL locale (e.g., `const Locale('ar')` forced in `main.dart`).

### M2. Locale-unaware integer display in topic detail screen

**Files:**
- `lib/features/dashboard/presentation/screens/topic_detail_screen.dart:136-174`

**Context:** `_buildStatBox` calls pass raw integer interpolation for numeric counts:

```dart
_buildStatBox(context, l10n.totalQuestions, '${state.totalAttempts}', ...)
_buildStatBox(context, l10n.correctAnswers, '${state.correctAttempts}', ...)
_buildStatBox(context, l10n.currentStreak, '${state.currentStreak}', ...)
_buildStatBox(context, l10n.bestStreak, '${state.bestStreak}', ...)
```

`'${int}'` produces invariant format (no digit-group separators). In Spanish locale, _1234_ should display as _1.234_. The `formatDecimal` helper in `lib/core/utils/number_format_utils.dart` exists to handle this.

**Rationale:** Users in Spanish-locale regions expect number grouping (`.` in Spanish `es`, ` ` in French `fr`). Showing `1234` instead of `1.234` is confusing on large numbers (streaks, total questions).

**Acceptance criteria:**
1. Replace `'${state.totalAttempts}'` with `formatDecimal(state.totalAttempts.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)`
2. Same for `correctAttempts`, `currentStreak`, `bestStreak`.
3. Verify that ES locale shows `1.234` (not `1234`) for a value of 1234.

### M3. Absence of locale-aware formatting in session summary card times

**File:**
- `lib/features/focus_mode/presentation/widgets/session_summary_card.dart:130`

**Context:**
```dart
DateFormat.jm(l10n.localeName).format(s.startTime),
```
DateFormat is used with `localeName` — this is actually correct. However, verify that `NumberFormat`-sensitive fields on this card also use locale. Check for any `.toString()` of numeric fields nearby.

**Action:** Audit the entire file for raw int-to-String conversions of user-facing numeric fields (scores, durations, counts). If found (e.g. `${session.durationMinutes}`), replace with `formatDecimal`.

### M4. `%` sign position varies by locale — verify all accuracy/percent format strings

**Files:**
- `lib/l10n/app_en.arb:3075` & `lib/l10n/app_es.arb:3075` (paceLabel)

**Context:**
- EN: `"{pace}% pace"` — percent sign immediately after number
- ES: `"{pace} % ritmo"` — Spanish typography puts a non-breaking space before `%`

The ARB handles this correctly for `paceLabel`. But audit all other percent-display code paths to ensure they do NOT hardcode `"%"` in Dart string interpolation. Every percent display must flow through either:
- `formatPercent(value, localeName)` from `number_format_utils.dart`, OR
- an ARB key that includes the `%` symbol (like `paceLabel` does).

**Key callers to verify:**
- `lib/core/widgets/practice_performance_card.dart:66-72` — uses `formatPercent` ✓
- `lib/features/practice/presentation/screens/practice_results_screen.dart` — uses `formatPercent` ✓
- `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` — uses `formatPercent` ✓

**Acceptance criteria:**
1. Grep for `'%'` string literals in `lib/features/` and `lib/core/` (excluding `.arb` and generated files).
2. Every match must be an invariant data format (CSV) or an LLM-facing string — NOT a user-facing widget.
3. Flag any remaining user-facing `'%'` in Dart strings and migrate to `formatPercent` or ARB.

---

## MINOR

### m1. Unused ARB keys increasing maintenance burden

**Files:**
- `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`

**Context:** The following ARB keys are defined but never referenced in any Dart code (searched via `rg -rn 'l10n\.accuracyLabel\|l10n\.avgAccuracyLabel\|l10n\.avgReadinessLabel'` — zero results):

| Key | EN Value | ES Value |
|---|---|---|
| `accuracyLabel` | `"Accuracy: {percent}"` | `"Precisión: {percent}"` |
| `avgAccuracyLabel` | `"Avg Accuracy: {percent}"` | `"Precisión Prom.: {percent}"` |
| `avgReadinessLabel` | `"Avg Readiness: {percent}"` | `"Preparación Prom.: {percent}"` |

These strings are translated and maintained but never rendered. Either:
- Wire them into the UI (e.g., in `topic_detail_screen.dart` or dashboard cards), OR
- Remove them from both ARB files to reduce translation overhead.

### m2. LLM prompt JSON template contains hardcoded English instructional text

**Files:**
- `lib/core/constants/llm_defaults.dart:30-36`

**Context:** The `evaluationPromptTemplate` function builds a JSON schema example with English instructional strings inside JSON values:

```dart
'  "score": <0.0 to 1.0>,\n'
'  "$explanationKey": "<detailed feedback explaining what was correct/incorrect>",\n'
...
```

While the JSON keys themselves must remain English (they are consumed programmatically), the **instructional descriptions inside the JSON values** (`<detailed feedback explaining...>`) are hints to the LLM about what to generate. Since the `languageInstruction` prompt tells the LLM to respond in the user's locale, these English hints may cause the LLM to generate English feedback even when the user is Spanish-speaking.

**Acceptance criteria:**
1. Add a locale-aware variant of the JSON template in the ARB file, or
2. Move the instructional descriptions into localised ARB keys so that Spanish descriptions like `"<comentario detallado explicando qué fue correcto/incorrecto>"` are shown to the LLM.
3. This is low priority because the `languageInstruction` system prompt should overrule the hint, but in practice LLMs may still latch onto the English examples.

### m3. Hardcoded `\n` in error display strings with `$e` interpolation

**Files:**
- `lib/features/dashboard/presentation/screens/topic_detail_screen.dart:54`

**Context:**
```dart
error: (e, _) => Center(child: Text('${l10n.errorLoadingSource}\n$e')),
```

The `\n` newline is hardcoded. In some languages, the error message might need a different connector (e.g., Spanish `" — "` or colon). The `\n` works for both EN and ES structurally but should ideally be part of the ARB template or use `Container` layout instead of a hardcoded linebreak.

**Acceptance criteria:**
1. Add a separate ARB key `errorLoadingSourceWithDetail` that accepts an `{error}` placeholder and includes the necessary separator in the template.
2. Replace the `\n` concatenation with the ARB method call.
3. Example ES value: `"Error al cargar la fuente: {error}"` instead of `"Ocurrió un error al cargar la fuente.\n{error}"`.

### m4. No `EdgeInsetsDirectional` lint rule enforced

The codebase has two occurrences of `EdgeInsets.only(right: ...)` (M1 above) and zero `EdgeInsets.fromLTRB(...)`. To prevent future RTL regressions, add a lint rule:

**File:**
- `analysis_options.yaml` — add:
```yaml
linter:
  rules:
    - use_directional_edge_insets: true
```

This catches any new `EdgeInsets.only(right: ...)` or `EdgeInsets.fromLTRB(...)` at analysis time.

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 1 | Hardcoded English in sign-out dialog |
| MAJOR | 4 | RTL EdgeInsets, locale-unaware int display, percent format audit |
| MINOR | 4 | Unused ARB keys, LLM prompt locale hints, error string `\n`, lint rule |

### Quick-win order of fixes
1. **B1** — add 4 ARB keys + replace `const Text` → ~30 min
2. **M1** — two `EdgeInsetsDirectional` swaps → ~10 min
3. **M2** — `formatDecimal` in topic detail screen → ~15 min
4. **m4** — add lint rule → ~2 min
5. **M4** — audit hardcoded `'%'` → ~20 min
6. **m1** — remove unused ARB keys → ~10 min
7. **m3** — ARB key for error-with-detail → ~15 min
8. **m2** — LLM prompt locale → ~30 min
