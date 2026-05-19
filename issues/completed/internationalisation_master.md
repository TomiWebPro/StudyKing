# Internationalisation (i18n) Master Issue

**Date:** 2026-05-19  
**Auditor:** Internationalisation Master  
**Scope:** All user-facing strings across lib/ and l10n/  
**Target Locale:** Spanish (es), patterns generalisable to other locales  

---

## BLOCKER

None identified. ARB coverage is broad (6500+ keys per locale), `AppLocalizations.of(context)` is used consistently, and format helper utilities (`number_format_utils.dart`) are wired through most display paths.

---

## MAJOR

### M1. Hardcoded `%` sign missing locale-appropriate spacing in ARB values

**Rationale:** Spanish typographic convention requires a non-breaking space between the number and the `%` sign (`85 %` not `85%`). Several ARB values hardcode `%` immediately adjacent to the placeholder/number with no space, producing incorrect output for `es`.

**Affected ARB keys (es only, en values likely need no change):**

| ARB Key | Current (es) | Should be |
|---|---|---|
| `completionOfValue` | `"{value}% Completo"` | `"{value} % Completo"` |
| `percentComplete` | `"{percent}% Completado: ..."` | `"{percent} % Completado: ..."` |
| `weakAreasAccuracy` | `"Áreas por mejorar (Precisión < 60%)"` | `"Áreas por mejorar (Precisión < 60 %)"` |
| `paceLabel` | `"{pace}% ritmo"` | `"{pace} % ritmo"` |
| `score` comment (accuracy labels) | Several ARB placeholders that receive pre-formatted `formatPercent` output | N/A — callers must ensure `formatPercent` output already has correct spacing (it does, since `NumberFormat.percentPattern(locale)` is locale-aware) |

**Acceptance Criteria:**
- All ARB strings containing `%` without a preceding space are updated in `app_es.arb` to use `" % "` (with non-breaking space or regular space per convention).
- Visual confirmation on a Spanish device shows `85 %` not `85%`.

---

### M2. `completionOfValue` uses raw `double` placeholder with hardcoded `%` instead of ICU message format

**File:** `app_en.arb:3279`, `app_es.arb:3279`

```json
"completionOfValue": "{value}% Complete",
"@completionOfValue": {
  "placeholders": { "value": { "type": "double" } }
}
```

**Rationale:** The `%` is glued to the value literal. ICU message format for percentages exists (`{value, number, ::percent}`) but Flutter's ARB ICU does not support the `::percent` skeleton in placeholders reliably in generated Dart code. This means the `%` must remain in the string body, but the locale-appropriate spacing is lost when the value is rendered via the double placeholder.

**Alternative:** Remove `%` from the ARB and have the caller use `formatPercent(value, localeName)` instead, OR keep `%` in the ARB but ensure spacing is locale-appropriate (see M1).

**Affected files:**  
- `lib/l10n/app_en.arb` (~line 3279)  
- `lib/l10n/app_es.arb` (~line 3279)  
- All callers of `completionOfValue`  

**Acceptance Criteria:**
- `completionOfValue` either (a) drops the `%` from the ARB and callers pass a `formatPercent`-formatted string via the placeholder, or (b) ARB value is corrected to `"{value} % Completo"` for es.

---

### M3. `formatPercent` calling convention inconsistency — risk of silent off-by-100× errors

**File:** `lib/core/utils/number_format_utils.dart:15-24`

```dart
String formatPercent(double value, String localeName, {...}) {
  final fmt = NumberFormat.percentPattern(localeName)...
  return fmt.format(value / 100);
}
```

**Rationale:** The function divides by 100, which means it expects 0–100 input range (as documented in AGENTS.md). However, callers are inconsistent:

| Caller | Passes | Expectation |
|---|---|---|
| `lib/.../summary_row.dart:43` | `accuracy.toDouble()` (no `* 100`) | Assumes caller is already 0–100 (OK if `accuracy` is 0–100) |
| `lib/.../subject_stats_tab.dart:117` | `avgScore` (no `* 100`) | Same assumption |
| `lib/.../practice_results_screen.dart:66` | `accuracy` (no `* 100`) | Same assumption |
| `lib/.../mentor_screen.dart:836` | `report.accuracy` (no `* 100`) | Same assumption |
| `lib/.../exam_session_screen.dart:669` | `result.accuracy * 100` | Assumes caller is 0–1 (inconsistent style) |
| `lib/.../weak_areas_card.dart:66` | `state.accuracy * 100` | Same (0–1 → 0–100) |
| `lib/.../plan_adherence_card.dart:42` | `averageAdherence * 100` | Same |
| `lib/.../mastery_progress_card.dart:61` | `avgAccuracy * 100` | Same |

**Risk:** If any field that is **not** multiplied by 100 is actually in 0–1 range (e.g. `0.85`), the displayed value would be `0.85 %` instead of `85 %`. The dev needs to audit each caller's data source to confirm.

**Acceptance Criteria:**
- All callers are audited and either consistently multiply by 100 or the function is changed to **not** divide by 100 (and instead callers pass 0–1 range).  
- A lint rule or code review checklist item prevents new ambiguous callers.  
- Unit tests for `formatPercent` verify the contract with known values and a locale.

---

### M4. PDF export table alignments use `centerLeft`/`centerRight` — not RTL-safe

**File:** `lib/features/sessions/services/session_export_service.dart:126-134`

```dart
cellAlignments: {
  0: pw.Alignment.centerLeft,   // Column #
  1: pw.Alignment.centerLeft,   // Subject
  2: pw.Alignment.centerLeft,   // Date
  3: pw.Alignment.centerRight,  // Duration
  4: pw.Alignment.centerRight,  // Correct
  5: pw.Alignment.centerRight,  // Accuracy
  6: pw.Alignment.centerLeft,   // Type
},
```

**Rationale:** `centerLeft`/`centerRight` are physical alignment values that do not flip for RTL locales (Arabic, Hebrew). The `pdf` package does not yet support `centerStart`/`centerEnd`, but a comment on line 124 acknowledges this. For Arabic users, numeric columns would appear on the wrong side.

Also: column header `l10n.sessionType` is used in the PDF header (line 96) but `s.type.name` at line 113 is the raw enum name (e.g. `"focus"`, `"practice"`), not a localized label. Enum `.name` is English.

**Affected files:**
- `lib/features/sessions/services/session_export_service.dart`
- `lib/core/services/progress_export_service.dart` (similar PDF table)

**Acceptance Criteria:**
- PDF tables use locale-aware alignment (if library supports it, otherwise document limitation).  
- `s.type.name` is replaced with a localized session type string via `l10n`.

---

### M5. Spanish `hoursPerDayAbbrev` translation is ungrammatical

**File:** `lib/l10n/app_es.arb` (~line 5335)

| Key | EN | ES |
|---|---|---|
| `hoursPerDayAbbrev` | `{hours}/Days` | `{hours}/Días` |

**Usage** at `lib/features/planner/presentation/planner_screen.dart:851`:
```dart
Text(l10n.hoursPerDayAbbrev(formatDecimal(...)))
```
→ Renders as e.g. `"1.5/Días"` in Spanish.

**Rationale:** `"1.5/Días"` is not idiomatic Spanish. The conventional abbreviation is `"1.5 h/día"` (horas por día). The slash with "Días" capitalised and pluralised reads as broken English calque.

**Acceptance Criteria:**
- Spanish value changed to `"{hours} h/día"` (or `"{hours} h/d"` for brevity).  
- Unit test verifies Spanish output matches expected pattern.

---

## MINOR

### m1. `planAdjustmentSuggested` lacks ICU pluralisation

**File:** `lib/l10n/app_en.arb:2227`, `lib/l10n/app_es.arb:2227`

| Key | Current value |
|---|---|
| EN | `"You've had {count} days of low plan adherence. ..."` |
| ES | `"Ha tenido {count} días de bajo cumplimiento del plan. ..."` |

**Rationale:** When `count == 1`, the string reads `"You've had 1 days of low plan adherence."` (grammar error). Both EN and ES should use ICU plural syntax:
```
"You've had {count,plural,=1{1 day} other{{count} days}} of low plan adherence. ..."
```

**Acceptance Criteria:**
- ARB values use `{count,plural,=1{...} other{...}}` for the count phrase.  
- Generated Dart code compiles and reads correctly for count = 0, 1, 5.

---

### m2. `paceLabel` percentage spacing for Spanish

**File:** `lib/l10n/app_es.arb:2973`

```
"paceLabel": "{pace}% ritmo"
```

Same issue as M1 — should be `"{pace} % ritmo"` in Spanish.

---

### m3. CSV columns are hardcoded English (intentional, but worth documenting)

**File:** `lib/features/sessions/services/session_export_service.dart:26-27`

```dart
buffer.writeln('Session ID,Student ID,Subject,Type,Start Time,End Time,'
    'Duration (min),Planned Duration (min),Questions Answered,Correct,Accuracy (%)');
```

**Rationale:** Per AGENTS.md, CSV exports must remain invariant `en` because CSV is data, not display. However, there is no automated test asserting that future contributors don't accidentally localise CSV headers. Add a test that verifies invariants.

**Acceptance Criteria:**
- Test at `test/features/sessions/services/session_export_service_test.dart` asserts CSV header line matches the exact English string.

---

### m4. `completionOfValue` `double` placeholder may lose fractional digits

**File:** `lib/l10n/app_en.arb:3279`

```json
"completionOfValue": "{value}% Complete",
"@completionOfValue": {
  "placeholders": { "value": { "type": "double" } }
}
```

**Rationale:** Flutter's ARB codegen for `double` placeholders uses `value.toStringAsFixed(...)` internally, which always uses period decimal separator regardless of locale. For locale-aware formatting, callers should pass a `String` (pre-formatted with `formatDecimal`/`formatPercent`) instead of a `double`.

**Affected callers:** TBD — need to grep for `l10n.completionOfValue(` usage.

**Acceptance Criteria:**
- Placeholder type changed to `String`, or callers use `formatDecimal`/`formatPercent` before passing.  
- Spanish output shows `"85,5 % Completo"` not `"85.5% Completo"`.

---

### m5. `_languageInstruction` in `prompts.dart` constructs locale instruction inline rather than via ARB

**File:** `lib/features/teaching/services/prompts/prompts.dart:25-28`

```dart
String get _languageInstruction {
  if (localeName == 'en') return '';
  return '\nIMPORTANT: Respond in the same language as the student (locale: $localeName). Do not use English unless the student does.';
}
```

**Rationale:** The instruction text is hardcoded in English. For a Spanish-speaking student receiving lessons from an AI, this instruction should be **in Spanish** so the AI understands the language requirement expressed in the student's own language. Move this string to ARB as a parameterised message.

**Acceptance Criteria:**
- ARB key `languageInstruction` added to both EN and ES ARB files.  
- `_languageInstruction` reads from `l10n.languageInstruction(localeName)` instead of hardcoded English.

---

### m6. `ConversationManager` keyword detection for `continue`/`exercise` has limited locale support

**File:** `lib/features/teaching/services/conversation_manager.dart:279-287`

```dart
static const Map<String, List<String>> _continueKeywordsByLocale = {
  'en': ['understand', 'got it', 'i see', 'continue', 'next', 'ok', 'yes'],
  'es': ['entiendo', 'entendido', 'ya veo', 'siguiente', 'continúa', 'ok', 'sí', 'si'],
};
static const Map<String, List<String>> _exerciseKeywordsByLocale = {
  'en': ['exercise', 'practice', 'quiz'],
  'es': ['ejercicio', 'práctica', 'práct', 'examen', 'quiz'],
};
```

**Rationale:** This static list approach does not scale to additional locales. It also misses variations (e.g. `"d'accordo"` for Italian, `"compris"` for French). The Spanish list includes `'práct'` which would match `"prácticamente"` (unrelated word) as a false positive.

**Acceptance Criteria:**
- (Future) Keyword detection is refactored to use LLM-based phase detection or locale-packaged keyword lists loaded from config.  
- For now, add a known-issue comment and test that the Spanish list does not produce false positives on common words.

---

### m7. `s.type.name` in PDF export is not localised

**File:** `lib/features/sessions/services/session_export_service.dart:113`

```dart
s.type.name,  // e.g. "focus", "practice", "exam"
```

The session type enum name is always English. A lookup map from enum value to `l10n.sessionTypeFocus`, `l10n.sessionTypePractice`, etc. (if they exist) should be used.

---

### m8. `formatCurrency` in `number_format_utils.dart` — `minFractionDigits != maxFractionDigits` case is a no-op

**File:** `lib/core/utils/number_format_utils.dart:57-61`

```dart
if (minFractionDigits == maxFractionDigits) {
  return fmt.format(value);
}
final result = fmt.format(value);
return result;
```

When `minFractionDigits != maxFractionDigits`, the function sets `decimalDigits: maxFractionDigits` on `NumberFormat.currency`, which fixes fractional digits to exactly `maxFractionDigits`. The intent of having different min/max is lost — `NumberFormat.currency` does not support a variable range for decimal digits. This should be documented or reimplemented (e.g. format with `maxFractionDigits`, then strip trailing zeros if above `minFractionDigits`).

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 0 | |
| MAJOR | 5 | Percent spacing, formatPercent convention, RTL-safe PDF alignments, ungrammatical ES shorthand, hardcoded `%` in completion value |
| MINOR | 8 | Plural gaps, locale keyword lists, enum .name, currency formatting, double placeholders, CSV invariant test |
