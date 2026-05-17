# Internationalisation Master: Full Codebase i18n Audit

**Target locale:** Spanish (`es`) — formal Latin American "usted" register per `l10n.yaml`
**Audit scope:** All `.dart` presentation, service, and prompt files + `.arb` translation files
**Audit date:** 2026-05-17

---

## Severity Key

| Tag | Meaning |
|---|---|
| **BLOCKER** | App crashes, user cannot proceed, or data is silently wrong |
| **MAJOR** | Feature is broken or misleading for non-English users |
| **MINOR** | Code quality, UX friction, or future-proofing |

---

## BLOCKER

### B1. Hardcoded English user-facing dialog in planner_screen.dart

**File:** `lib/features/planner/presentation/planner_screen.dart:587`

```dart
content: const Text('Are you sure you want to cancel this lesson?'),
```

`l10n` is in scope (passed as parameter to `_confirmCancelLesson`) but the content text bypasses it. A Spanish user sees an English confirmation dialog.

**Fix:** Add `cancelLessonConfirmation` key to both ARB files and replace with `Text(l10n.cancelLessonConfirmation)`.

---

### B2. Hardcoded English nudge/message strings in mentor_service.dart

**File:** `lib/features/mentor/services/mentor_service.dart`

Multiple user-facing English strings are embedded directly (lines 322, 336, 351, 361, 372–374, 441–445, 458–465, 498–501, 576–579, 600–603). These are shown to the user via the mentor chat or notification system. The system prompt method `_mentorSystemPrompt()` correctly uses `l10n.mentorSystemPrompt`, but the actual nudge messages, scheduling confirmations, and activity warnings are all hardcoded English.

Key examples:
- Line 322: `'You have studied $todayMinutes minutes today, which exceeds your daily cap...'`
- Line 336: `'I noticed you had ${lateNight.length} late-night study session(s)...'`
- Line 351: `'You have $atRiskCount question(s) approaching their review date...'`
- Line 361: `'Congratulations on your $consecutiveDays-day study streak!...'`
- Lines 441–603: All scheduling confirmation/error messages are English

Most of these already have corresponding Spanish translations in the ARB files (e.g., `nudgeOverwork`, `nudgeRevision`, `nudgePlanAdjustment`, `lessonScheduled`, etc.) but the code doesn't use them.

**Fix:** Replace each hardcoded message with the corresponding `l10n.xxx()` lookup. Pass `AppLocalizations` to the service or use `lookupAppLocalizations()` (already used for the system prompt).

---

### B3. LLM context prompt is always English in mentor_service.dart

**File:** `lib/features/mentor/services/mentor_service.dart:147–230`

The `_buildContextPrompt()` method constructs the student context block entirely in English:

```dart
buffer.writeln('Current student context:');
buffer.writeln('- Total attempts: ${stats['totalAttempts']}');
buffer.writeln('- Correct attempts: ${stats['correctAttempts']}');
// ... all English
```

This context is fed to the LLM even when the system prompt is in Spanish. The LLM receives mixed-language input (Spanish system prompt + English context data), which degrades response quality in Spanish.

**Fix:** Either (a) localise the context template strings via ARB, or (b) keep it in `en` as LLM-internal data format but add a leading note like `"Note: context labels are in invariant English regardless of user locale"`.

---

## MAJOR

### M1. All teaching/AI tutor prompts are hardcoded English

**File:** `lib/features/teaching/services/prompts/prompts.dart` (entire file, 206 lines)

Every prompt string — lesson plan, tutor instruction, summary, evaluation — is hardcoded English. These are the most substantial user-facing AI interactions.

Key examples:
- Line 94: `'You are a knowledgeable AI tutor for $subjectId...'`
- Line 112: `'You are a curriculum designer creating lesson plans...'`
- Line 116: `'You are an AI tutor for $subjectId teaching "$topicTitle"...'`
- Lines 119–155: `_buildTutorPrompt()` — full English with phase-based instructions like `'Start the lesson warmly.'`, `'Teach the concept step by step...'`
- Lines 157–175: `_buildSummaryPrompt()` — English summary instructions
- Lines 179–203: `_buildEvaluationPrompt()` — English evaluation instructions

**Fix:** Add prompt template keys to ARB files with placeholders for dynamic values (`subjectId`, `topicTitle`, `durationMinutes`, `adaptivePace`, etc.). Replace all prompt builders with `l10n.lessonPlanPrompt(...)`, `l10n.tutorInstructionPrompt(...)`, etc. This is a large but mechanical task.

---

### M2. Exercise evaluator prompt is hardcoded English

**File:** `lib/features/teaching/services/exercise_evaluator.dart:18–41`

```dart
static const String _defaultSystemPrompt = 'You are an expert academic evaluator...';
String _buildPrompt() { return '''Evaluate this student answer...'''; }
```

**Fix:** Add to ARB and use `l10n.evaluatorSystemPrompt` and `l10n.evaluatorPrompt(...)`.

---

### M3. Content ingestion prompts are hardcoded English

**File:** `lib/features/ingestion/services/content_pipeline.dart:238–331`

Three prompt sets — classification (line 238), summarization (line 284), question generation (line 318) — are all English.

**Fix:** Add ARB keys for each prompt template and use locale-aware lookups.

---

### M4. LLM default system prompt is hardcoded English

**File:** `lib/core/services/llm/llm_chat_service.dart:27`

```dart
static const String defaultSystemPrompt = 'You are a helpful AI study assistant called StudyKing. Keep responses concise and educational.';
```

This is used as fallback whenever no system prompt is supplied. English-only.

**Fix:** Make `defaultSystemPrompt` accept a locale parameter or remove the default and require callers to supply a locale-appropriate prompt.

---

### M5. Extraction prompts (transcription + OCR) are hardcoded English

**Files:**
- `lib/core/data/extraction/transcription_extractor.dart:274–284`
- `lib/core/data/extraction/ocr_extractor.dart:116–127`

Both use English-only user and system prompts for AI-powered transcription/OCR.

**Fix:** Add ARB keys and localise.

---

### M6. toStringAsFixed used in user-facing and LLM-facing contexts (locale-unsafe)

**Found in 9 locations across 5 files:**

| File | Lines | Context |
|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 159, 199 | LLM-facing context prompt — uses period decimals, fine for LLM but should be documented |
| `lib/core/services/progress_export_service.dart` | 73, 88 | CSV export — CSV should stay invariant `en` format (OK per AGENTS.md) |
| `lib/core/services/study_progress_tracker.dart` | 260, 311 | CSV export — same as above, acceptable |
| `lib/features/sessions/services/session_export_service.dart` | 30, 32 | CSV export — acceptable |
| `lib/features/teaching/services/prompts/prompts.dart` | 170 | LLM-facing summary prompt — uses period decimals |

**Ruling:** The CSV exports are correct (should stay `en` invariant). The LLM-facing uses are acceptable if documented. However, **if any of these values are shown in UI widgets, they MUST use `number_format_utils.dart`**. Verify each call site:

- `mentor_service.dart:159`: LLM context only → **OK** (but add comment explaining)
- `mentor_service.dart:199`: LLM context only → **OK**
- `prompts.dart:170`: `adaptivePace.toStringAsFixed(1)` → LLM-facing, but an LLM receiving `"1.5"` will produce output referencing `"1.5"` — the Spanish LLM output will contain English-format numbers. Consider formatting with locale-aware `formatDecimal` then noting in the prompt that the comma/period is the user's decimal separator.

**Fix:** For any UI-displayed use, replace with `formatDecimal()` from `number_format_utils.dart`. Add inline comments at all LLM-facing `toStringAsFixed` calls explaining they are intentionally invariant.

---

### M7. Hardcoded English semantics/accessibility labels

| File | Line | String |
|---|---|---|
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 160, 163 | `'Decrease duration'` |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 174, 177 | `'Increase duration'` |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 382 | `'Session progress: ${_currentIndex + 1} of ${_questions.length}'` |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 299 | `'Exam progress: ${_currentIndex + 1} of ${_questions.length}'` |
| `lib/core/widgets/animated_bar_chart.dart` | 140 | `'$day: $count sessions'` (hardcoded `sessions`) |

Screen-reader users in Spanish hear English labels. All of these must use `l10n` lookups.

**Fix:** Add corresponding ARB keys and replace. For `animated_bar_chart.dart`, accept a `semanticsLabelBuilder` callback to avoid coupling the generic widget to `AppLocalizations`.

---

### M8. RTL layout: zero support in the codebase

Search results for `TextDirection`, `textDirection:`, `Directionality` — all zero outside of standard `Directionality.of(context)` for margin resolution.

**Files checked (representative sample):**
- All `presentation/` directories
- All `core/widgets/` files
- All custom layout widgets

**No** `Directionality` wrappers, `textDirection:` parameters, or `TextAlign.start`/`TextAlign.end` usage. Hardcoded `TextAlign.left` and `TextAlign.center` are used throughout.

This means if Arabic, Hebrew, Persian, or Urdu locales are ever added, every screen will be broken (left-aligned text in a right-to-left language).

**Fix:** As a first step, convert ALL `TextAlign.left` → `TextAlign.start` and `TextAlign.right` → `TextAlign.end`. This is a mechanical find-and-replace. Add a lint rule to prevent regressions. Full RTL support is a larger effort requiring layout reviews.

---

### M9. Inconsistent "tú" vs "usted" register in Spanish ARB

Per `l10n.yaml`: `"'es' targets neutral Latin American Spanish (formal 'usted' register)."`

But one translation uses informal "tú":

| Key | Line | Value | Register |
|---|---|---|---|
| `uploadPrompt` | 851 | `"¿Deseas subir material de estudio para {subject}?"` | ❌ Informal **tú** |
| All others | — | e.g. `"Por favor, complete todos los campos..."` | ✅ Formal **usted** |

**Fix:** Change `"¿Deseas subir..."` → `"¿Desea subir..."` in `app_es.arb:851`.

---

## MINOR

### m1. Weekday abbreviation first-char truncation is locale-unsafe

**File:** `lib/features/planner/presentation/widgets/calendar_view_widget.dart:130`

```dart
return DateFormat.E(l10n.localeName).format(date).substring(0, 1);
```

This works for English (`M`, `T`, `W`, `T`, `F`, `S`, `S`) and Spanish (`L`, `M`, `M`, `J`, `V`, `S`, `D`) but will produce collisions in many locales (e.g., German: `M` for both Montag and Mittwoch). For some CJK locales, the first character may not even be the abbreviation.

**Fix:** Either (a) use full weekday names with truncation via `TextOverflow.ellipsis`, (b) use `DateFormat.E(localeName).format(date)` without substring and reduce font size, or (c) maintain an explicit locale→abbreviation mapping.

---

### m2. DateFormat('E', localeName) in weekly_chart uses unlocalised fallback

**File:** `lib/features/dashboard/presentation/widgets/weekly_chart.dart:14–21`

```dart
Map<String, int> _fallbackDayLabels(String localeName) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  return {
    for (var i = 0; i < 7; i++)
      DateFormat('E', localeName).format(startOfWeek.add(Duration(days: i))): 0,
  };
}
```

The `DateFormat` construction uses the locale correctly, but the method is called `_fallbackDayLabels` and only runs when `weeklyTrend` is empty — meaning the chart still shows empty bars with locale-aware day labels. This is **correct** in the current form, but the `'E'` pattern (not `EEE`) may not work identically across all `intl` data versions. Change to `DateFormat.EEEE` or keep `DateFormat.E` but add a comment noting it's intentionally short.

**Fix:** No urgent change needed, but consider `DateFormat.EEEE` for full names with text wrapping to avoid ambiguity.

---

### m3. Some ARB descriptions use English only (consistency issue)

Many `@description` fields in the Spanish ARB (`app_es.arb`) are in English. While this doesn't affect runtime behaviour, it makes maintenance harder for Spanish-speaking translators.

Example (app_es.arb:9):
```json
"@subjects": {
  "description": "Bottom navigation label for subjects"
}
```

**Fix:** Either translate all `@description` fields to Spanish, or accept that they remain English as per Flutter convention (descriptions are for developers, not users).

---

### m4. No gender-neutral Spanish translations

Spanish translations use masculine defaults in several places (e.g., `"Estudioso Diario"` for a badge name). Consider reviewing for gender neutrality or providing both masculine/feminine forms.

---

### m5. missing_translation_keys.md / i18n_coverage script could check unused keys

The `scripts/check_i18n_coverage.sh` (referenced in `l10n.yaml`) validates key parity between ARB files. Consider extending it to also warn about:
- Keys in ARB files that are never referenced in `.dart` files (dead translations)
- `toStringAsFixed` usages in UI code
- Hardcoded `Text('...')` strings

---

## Translation Quality Notes (Spanish)

These are advisory recommendations, not bugs:

| Key | Current ES | Suggested |
|---|---|---|
| `practiceMode` | `Modo de Práctica` | `Modo de práctica` (sentence case per Material Design guidelines) |
| `studySessionTracker` | `Seguimiento de sesiones de estudio` | `Seguimiento de Sesiones de Estudio` (title case) |
| `paceLabel` | `{pace}% ritmo` | `Ritmo: {pace}%` (natural Spanish word order) |
| `weakAreas` | `Áreas por mejorar` | `Áreas débiles` or keep current (euphemism is fine) |

---

## Acceptance Criteria

A "fixed" state means:

1. **ARB keys exist** for every user-facing string currently hardcoded in Dart files (B1, B2, M7)
2. **AI prompts** (M1–M5) accept a locale parameter and use ARB templates with placeholders
3. **RTL baseline** — all `TextAlign.left/right` are converted to `TextAlign.start/end` (M8)
4. **Number formatting** — any UI widget displaying a percentage, decimal, or currency uses `number_format_utils.dart` (M6 verified)
5. **Register consistency** — `uploadPrompt` uses formal `usted` (M9)
6. **Weekday abbreviation** — calendar view handles CJK and multi-byte locales (m1)
7. **Script check** — `check_i18n_coverage.sh` is extended to flag hardcoded strings and `toStringAsFixed` in presentation code (m5)
