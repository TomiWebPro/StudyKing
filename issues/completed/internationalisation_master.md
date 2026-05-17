# Internationalisation Master — i18n Audit

## Scope

Audit of the StudyKing codebase (`lib/`, `test/`, `lib/l10n/`) for internationalisation (i18n) and localisation (l10n) gaps. Spanish (`es`) is the target locale; recommendations apply to all locales.

---

## BLOCKER — Bilingual error messages in repositories

**Problem:** Repository and service classes construct error messages in English and pass them as the `{error}` parameter to localized ARB strings. The result is a bilingual sentence (e.g. `"Error al guardar la sesión: Failed to save session: ..."`).

**Root cause:** Repositories return `Result.failure('Failed to do X: ${e.toString()}')` — the English message becomes the placeholder value for a localized wrapper.

**Affected files (24 error sites):**
- `lib/features/sessions/data/repositories/session_repository.dart` — lines 23, 33, 44, 59, 69, 79, 89, 102, 117, 129, 139, 149, 159, 171, 182, 193, 207, 231, 252
- `lib/features/practice/data/repositories/question_mastery_state_repository.dart` — lines 35, 47, 69, 86
- `lib/features/practice/data/repositories/question_evaluation_repository.dart` — lines 28, 38, 64
- `lib/features/practice/services/spaced_repetition_service.dart` — lines 100, 135, 193, 214, 232
- `lib/core/services/instrumentation_service.dart` — lines 202, 235
- `lib/core/data/extraction/transcription_extractor.dart` — line 261

**Fix:** Define `AppLocalizations`-aware error keys in `.arb` files for each error type, or refactor repositories to accept/return error codes that the UI layer translates. **Never embed English prose in `Result.failure()` strings that are passed to localized placeholders.**

**Acceptance criteria:**
- Spanish users see fully Spanish error messages.
- No English text bleeds into any user-facing error dialog, snackbar, or toast.

---

## MAJOR — Locale-unaware timer / elapsed formatting

**Problem:** Three timer displays use hardcoded `mm:ss` or `HH:MM:SS` colon-separated formats. The colon separator is ASCII-only and not locale-aware; some locales use different separators (e.g. `H.mm` in some European contexts).

**Affected files:**
- `lib/features/lessons/presentation/lesson_detail_screen.dart:180` — `'${_elapsed.inMinutes}:${_elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}'`
- `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart:90-92` — `_formatTime()` returns `HH:MM:SS` or `MM:SS` with hardcoded colons
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:259` — `'${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'`
- `lib/features/focus_mode/presentation/widgets/session_summary_card.dart:119` — `'${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}'`

**Fix:** Create a `formatTimer(Duration, localeName)` helper in `lib/core/utils/time_utils.dart` that uses the ARB `durationSeparator` key (already exists: `"durationSeparator": " "` in en, `"durationSeparator": " "` in es) or `NumberFormat` with locale-aware time patterns.

**Acceptance criteria:**
- Timer displays in lesson detail, focus mode, and session summary respect `durationSeparator`.
- The visual colon `:` is replaced by the locale's preferred separator (currently space for both locales, but could differ for e.g. `fr` or `de`).

---

## MAJOR — User-facing integer stats use `.toString()` instead of locale-aware formatting

**Problem:** Several screens display numeric stats using Dart's `.toString()`, which produces a locale-invariant ASCII representation. This is fine for single-digit values but fails for values ≥ 1,000 (no thousands separator) and will be confusing in Spanish where `1000` should render as `1.000` (period as grouping separator).

**Affected files:**
- `lib/features/practice/presentation/screens/practice_results_screen.dart:39` — `totalQuestions.toString()`
- `lib/features/practice/presentation/widgets/practice_session_stats_bar.dart:60` — `correctAnswers.toString()`
- `lib/features/sessions/presentation/session_history_screen.dart:401` — `_filteredSessions.length.toString()`
- `lib/features/subjects/presentation/subject_detail_screen.dart:328` — `questions.toString()`
- `lib/features/subjects/presentation/widgets/subject_stats_tab.dart:65` — `totalSessions.toString()`
- `lib/features/subjects/presentation/widgets/subject_stats_tab.dart:89` — `totalQuestions.toString()`

**Fix:** Replace `.toString()` with `formatDecimal(value.toDouble(), localeName)` from `lib/core/utils/number_format_utils.dart`.

**Acceptance criteria:**
- Spanish users see `1.234` instead of `1234`.
- English users continue to see `1,234`.

---

## MAJOR — Locale-unaware date formatting in Mentor service

**Problem:** Mentor service formats dates using `toLocal().toString().substring(0, 10)` which always produces ISO 8601 format (`2026-05-17`). This is not locale-aware.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart` — lines 178, 195, 446, 447, 465, 607

**Fix:** Use `DateFormat.yMd(localeName)` or `formatDate()` from `lib/core/utils/time_utils.dart` (which already does this for the UI layer, but is not used in the mentor service).

**Acceptance criteria:**
- Spanish dates appear as `17/5/2026` rather than `2026-05-17`.
- The `formatDate()` helper is consistently used in the mentor service.

---

## MAJOR — Planner screen passes raw `.toString()` to `hoursAbbreviation`

**Problem:** `lib/features/planner/presentation/planner_screen.dart:411` passes `goal.targetHoursPerDay.toString()` to `l10n.hoursAbbreviation()`. The ARB placeholder for `hoursAbbreviation` is typed as `String` (not `int`), meaning it expects a pre-formatted string. For Spanish users, a value like `2.5` would render as `2.5h` instead of `2,5h`.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:411`

**Fix:** Use `formatDecimal(goal.targetHoursPerDay.toDouble(), l10n.localeName)` before passing to `hoursAbbreviation`.

**Acceptance criteria:**
- Spanish users see `2,5h` instead of `2.5h`.

---

## MAJOR — Hardcoded English separator in stat row

**Problem:** `lib/features/practice/presentation/screens/practice_results_screen.dart:43` constructs `'$correctAnswers/$totalQuestions'` with a hardcoded `/` separator. The slash is understood in many locales but the overall pattern should be locale-aware (e.g. Spanish might prefer `"Correctas: 5/10"`).

**Affected files:**
- `lib/features/practice/presentation/screens/practice_results_screen.dart:43`

**Fix:** Use the existing `l10n.correctOf(correctAnswers, totalQuestions)` ARB key instead of manual string interpolation.

---

## MINOR — RTL: Hardcoded `EdgeInsets.only(right: ...)` and `Alignment.centerRight`

**Problem:** Four widgets use `EdgeInsets.only(right: ...)` which does not flip in RTL locales (Arabic, Hebrew, Urdu, etc.). One uses `Alignment.centerRight` instead of `AlignmentDirectional.centerEnd`. These should use `EdgeInsetsDirectional.only(end: ...)` and `AlignmentDirectional.centerEnd`.

**Affected files:**
- `lib/features/teaching/presentation/widgets/voice_bar.dart:83` — `EdgeInsets.only(right: 8)`
- `lib/features/sessions/presentation/session_history_screen.dart:483-484` — `Alignment.centerRight` and `EdgeInsets.only(right: 16)`
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:52` — `EdgeInsets.only(right: 12)`
- `lib/features/sessions/presentation/session_tracker_screen.dart:346` — `EdgeInsets.only(right: 4)`

**Fix:** Replace with `EdgeInsetsDirectional.only(end: ...)` and `AlignmentDirectional.centerEnd`.

**Acceptance criteria:**
- In an RTL locale, padding and alignment properly flip to the leading edge.

---

## MINOR — Hardcoded invalid-region locale identifier

**Problem:** `lib/l10n/generated/app_localizations.dart:66` uses `intl.Intl.canonicalizedLocale(locale.toString())`. If the locale string contains an invalid region subtag (e.g. `es_MX` where `MX` is not an official region for `es`), `canonicalizedLocale` may strip or mangle it. This can cause fallback chains to break.

**Affected files:**
- `lib/l10n/generated/app_localizations.dart:66` (generated file — review the l10n.yaml configuration)

**Fix:** Ensure `l10n.yaml` sets `suppress-warnings: false` and validates locale tags. Add `es_MX` or other regional variants explicitly if supported.

---

## MINOR — CSV headers use localized strings but CSV is data, not display

**Audit:** Project conventions (AGENTS.md) state "CSV exports should remain in invariant en format". Currently, CSV column headers ARE localised (e.g. `"csvColAccuracy"` exists in both en and es ARB files). This is **acceptable** per current design. Flagging as a potential future concern if CSV consumers (e.g. spreadsheet apps) expect English headers.

**No action required at this time.** Documented for awareness.

---

## MINOR — Duplicate ARB key names across contexts

**Audit:** The key `dismiss` appears once in both EN and ES ARB files (as button label). The key `correctCount` appears as both a session label and a correct-count label (distinct placeholders). The key `questionsCount` has both `questionsCount` and `questionsCountLabel` and `questionsCountMetric`. These duplicates are functional but add maintenance burden.

**Affected keys (EN):**
- `correctCount` (line 2816) and `correctCountLabel` (line 2794) — near-duplicate semantics
- `questionsCount` (line 1031) and `questionsCountLabel` (line 1678) and `questionsCountMetric` (line 2391)

**Fix:** Consolidate where possible. Ensure each unique semantic has exactly one key.

---

## Summary Table

| Severity | Count | Key Areas |
|---|---|---|
| BLOCKER | 24 sites | Repositories: hardcoded English in error strings → bilingual output |
| MAJOR | 10 sites | Timer formatting, `.toString()` on user-facing ints, date formatting, hours abbreviation, stat separator |
| MINOR | 5 sites | RTL directions, locale identifier, duplicate ARB keys |

## Priority Order for Fixes

1. **BLOCKER — Repository error messages** (bilingual output = broken UX)
2. **MAJOR — Timer/elapsed formatting** (visible in every lesson and focus session)
3. **MAJOR — `.toString()` on user-facing numbers** (stat screens, results)
4. **MAJOR — Date formatting in mentor service** (AI mentor output)
5. **MAJOR — Hours abbreviation in planner** (planning screen)
6. **MAJOR — Stat row separator** (practice results)
7. **MINOR — RTL directions** (future-proofing for Arabic/Hebrew)
