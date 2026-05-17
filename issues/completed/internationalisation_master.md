# Internationalisation Master Issue

**Audited:** 2026-05-17  
**Scope:** All Dart source files and `.arb` locale bundles  
**Target locale for audit:** `es` (Spanish) — other languages follow same pattern  
**Reference:** `AGENTS.md` i18n / Number Formatting Conventions

---

## Summary

The Spanish locale (`app_es.arb`) is commendably complete — all 500+ keys from `app_en.arb` have a Spanish translation. The codebase already uses `l10n` extensively and has `number_format_utils.dart` with locale-aware helpers. However, several source files contain **hardcoded user-facing English strings** that bypass `AppLocalizations`, use `toStringAsFixed` for numeric displays, or use non-locale-aware date/time formatting. Additionally, the notification service formats timestamps manually, LLM prompts have untranslated English fragments, and layout handling for RTL/expanded strings is minimal.

---

## BLOCKER

| # | File | Line(s) | Issue |
|---|------|---------|-------|
| B1 | `lib/features/questions/presentation/question_bank_screen.dart` | 140, 158–159, 183 | Hardcoded English strings: `const Text('Question deleted')`, `const Text('Delete Questions')`, `'Are you sure you want to delete ${_selectedIds.length} question(s)?'` — these are user-facing confirmations and snackbars. A Spanish user sees mixed English/Spanish UI. |
| B2 | `lib/features/ingestion/presentation/source_detail_screen.dart` | 172 | `SnackBar(content: Text('Reprocess failed: $e'))` — hardcoded English error on a user-visible snackbar. |

**Acceptance (fixed):**
- B1: All three strings use `AppLocalizations.of(context)!` keys defined in `.arb`.
- B2: `'Reprocess failed: $e'` is replaced by `l10n.errorWithMessage(e.toString())` (key exists in both en/es).

---

## MAJOR

### M1. Hardcoded English mastery level labels in CSV and service

**Files:**
- `lib/core/services/study_progress_tracker.dart:268–277` — `getTopicMasteryLevel()` returns English strings `'Novice'`, `'Browsing'`, `'Developing'`, `'Proficient'`, `'Expert'`.
- `lib/core/services/study_progress_tracker.dart:336–342` — `exportSessionHistoryCSV()` hardcodes the same mastery level labels.
- `lib/core/services/progress_export_service.dart:83–89` — `exportComprehensiveCSV()` hardcodes `'Novice'` etc.

**Problem:** The mastery level labels in CSV exports are always English even when the user's UI is Spanish. While AGENTS.md says CSV should use invariant format, the mastery level labels are user-facing content, not number formatting. Spanish users expect `Novato`, `Explorando`, `En Desarrollo`, `Competente`, `Experto`.

**Acceptance (fixed):**
- `getTopicMasteryLevel()` accepts an `AppLocalizations` (or `l10n`) parameter and returns localized labels via `l10n.masteryLevelNovice` etc.
- CSV export methods pass `l10n` and use the localized labels (the CSV is downloaded/shared and read by the user).

### M2. Hardcoded English in LLM prompts

**Files:**
- `lib/features/teaching/services/prompts/prompts.dart:50–63` — `tutorMessage()` contains hardcoded English pace/time-context strings: `'The student is doing well. Accelerate pace.'`, `'The student seems to be struggling...'`, `'Start the lesson warmly.'`, etc. These are LLM-facing per AGENTS.md but they feed into the system prompt that the student sees as AI output.
- `lib/core/constants/llm_defaults.dart:23–32` — `evaluationPromptTemplate()` is entirely hardcoded English with no locale parameter.

**Problem:** When the user's locale is Spanish, the LLM still receives English instructions about "Evaluate this student answer" and English context strings, making the AI less likely to respond consistently in Spanish.

**Acceptance (fixed):**
- Pace/time-context strings in `prompts.dart` are moved to `.arb` keys with placeholder support.
- `evaluationPromptTemplate()` accepts an `AppLocalizations` parameter and constructs the template from locale-aware strings.
- Alternatively, the `_languageInstruction` mechanism is extended to cover these fragments.

### M3. Non-locale-aware time formatting in notification service

**File:** `lib/core/services/notification_service.dart:247`

```dart
final timeStr = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
```

**Problem:** This produces `14:30` regardless of locale. Spanish users expect `14:30` (happens to match 24h format), but French-Canadian, US-English, and other locales have different conventions (`2:30 PM`). This string feeds directly into user-visible notification bodies like `"Your lesson starts at 14:30"`.

**Acceptance (fixed):**
- Use `DateFormat('HH:mm', l10n.localeName)` or `DateFormat.jm(l10n.localeName)` so the time adapts to the locale.

### M4. Hardcoded English in focus timer accessibility labels

**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart`

| Line | Code | Problem |
|------|------|---------|
| 336 | `label: 'Break remaining ${formatTimer(...)}'` | Hardcoded `'Break remaining'` prefix |
| 472 | `label: '$m minutes'` | Hardcoded English `'minutes'` |

**Acceptance (fixed):**
- `'Break remaining'` uses a localized string like `l10n.timerRemaining` with the formatted timer appended.
- `'$m minutes'` uses `l10n.durationMinutes(m)` or `l10n.minutesValue(m)`.

### M5. Hardcoded English in CSV headers

**Files:**
- `lib/core/services/study_progress_tracker.dart:287, 297–298, 302, 314, 321, 333, 353` — CSV column headers like `"Date","Metric","Value"`, `"Weekly Trend","Week","Attempts","Accuracy"` etc.
- `lib/features/sessions/services/session_export_service.dart:26–27` — CSV headers `'Session ID,Student ID,...'`

**Context:** AGENTS.md says CSV exports should remain in invariant `en` format. However, headers like `"Badges","Badge Name","Date Unlocked"` are user-facing text a Spanish speaker would read. If the intent is truly invariant, that's acceptable, but if users see these CSVs, they should be localized.

**Recommendation:** Per `AGENTS.md` convention, CSV headers may remain invariant EN. However, consider that these files are shared/shared to the user (via `share_plus`). Add a comment documenting this choice. If user-facing, move to `.arb`.

---

## MINOR

### m1. Hardcoded English in `study_progress_tracker.dart` CSV empty states

**File:** `lib/core/services/study_progress_tracker.dart:321, 348`

```dart
csvLines.add('"","$studentId","No attempts recorded","",""');
csvLines.add('"No session data available for $studentId","","","","","",""');
```

**Acceptance:** These user-facing messages should use `l10n` or at least be removed/fixed — an empty CSV should have empty data, not English prose.

### m2. Hardcoded mastery level in `study_progress_tracker.dart:268`

The function `getTopicMasteryLevel()` returns `'Novice'`, `'Expert'` etc. These are used internally to derive the level string but could instead return an enum or int, leaving display to the caller with locale support.

**Acceptance:** Change return type to `MasteryLevel` enum and let callers use `l10n.masteryLevelNovice` etc.

### m3. No `Directionality` / RTL awareness in most widgets

**Files:** Only 3 files use `Directionality.of(context)`:
- `lib/features/teaching/presentation/widgets/chat_bubble.dart`
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart`
- `lib/features/lessons/presentation/widgets/lesson_list_item.dart`

**Problem:** If the app ever adds an RTL locale (Arabic, Hebrew), most layouts will break — hardcoded `EdgeInsets.only(left: ...)`, `crossAxisAlignment: CrossAxisAlignment.start`, `MainAxisAlignment.start`, no `Directionality` or `resolve()` calls.

**Acceptance:** This is a proactive finding. No immediate action for `es` locale, but a plan should document these locations for future RTL support.

### m4. Hardcoded English in error handler

**File:** `lib/core/errors/handlers.dart` — verify no hardcoded English in user-facing error SnackBars.

### m5. `toStringAsFixed` usage in display contexts

**Files with `toStringAsFixed`:**
- `lib/features/mentor/services/mentor_service.dart:132, 172` — LLM-facing, marked OK in comments
- `lib/core/services/progress_export_service.dart:76, 91` — CSV export, OK per AGENTS.md
- `lib/features/sessions/services/session_export_service.dart:32, 34` — CSV export, OK per AGENTS.md
- `lib/core/services/study_progress_tracker.dart:293, 344` — CSV export, OK per AGENTS.md
- `lib/features/teaching/services/prompts/prompts.dart:84` — LLM-facing, OK per AGENTS.md

**Verdict:** All `toStringAsFixed` uses are correctly scoped to CSV/LLM contexts per AGENTS.md. No action needed.

### m6. Missing plural forms in `.arb` for select keys

The `.arb` files are complete key-wise (all EN keys have ES translations). However, spot-check quality issues:

- `es` `durationSeconds`: uses `"1s"` / `"{count}s"` — same as English. In Spanish, "s" is understood but `"1 seg"` / `"{count} seg"` would be more natural.
- `milestoneShort`: ES uses `"H{order}"` (H = hito), EN uses `"M{order}"` (M = milestone). This is correct.
- `questionsAbbreviation`: ES uses `{count}P` (P = preguntas), EN uses `{count}Q` (Q = questions). Correct.

**Acceptance:** Review `durationSeconds`, `durationMinutes` ES translations for naturalness in Spanish context.

---

## Concrete Fix Checklist (Prioritised)

### Immediate (fix first, before next release)

- [ ] **B1** — `question_bank_screen.dart` hardcoded strings → `l10n.questionDeleted`, `l10n.deleteQuestions`, `l10n.deleteQuestionsConfirm(count)`
- [ ] **B2** — `source_detail_screen.dart` 'Reprocess failed' → `l10n.errorWithMessage(e.toString())`
- [ ] **M4** — `focus_timer_screen.dart` hardcoded accessibility labels → `l10n`
- [ ] **M3** — `notification_service.dart` hardcoded time format → `DateFormat.jm(l10n.localeName)`

### Short-term (next iteration)

- [ ] **M1** — Mastery labels: convert `getTopicMasteryLevel()` to use `l10n` or return enum
- [ ] **M2** — LLM prompts: extract English fragments to `.arb` keys
- [ ] **m1** — Hardcoded empty-state prose in CSV exports
- [ ] **m2** — Refactor mastery level to enum-based

### Future (i18n backlog)

- [ ] **m3** — Document RTL-aware layout plan
- [ ] **m6** — Review ES translation naturalness for abbreviated duration units

---

## How to verify fixes

1. Set device locale to `es` (Spanish).
2. Navigate to Question Bank → delete a question → confirm the snackbar reads `Pregunta eliminada` not `Question deleted`.
3. Navigate to Source Detail → trigger a reprocess failure → snackbar reads `Error: ...` not `Reprocess failed: ...`.
4. Start a Focus session → activate TalkBack/VoiceOver → accessibility labels should be in Spanish.
5. Schedule a lesson → notification body should show locale-aware time (e.g. `14:30` or `2:30 PM` depending on locale).
6. Export CSV → mastery levels should be `Novato`, `Explorando`, etc.
7. Start an AI Tutor session → the LLM prompt should instruct the AI to respond in Spanish.
