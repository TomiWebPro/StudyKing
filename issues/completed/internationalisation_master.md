# Internationalisation Master — i18n/L10n Audit (Open Items)

## Reference

Prior audit in `issues/completed/internationalisation_master.md` documented 40+ sites across BLOCKER/MAJOR/MINOR. Several items from that audit remain unresolved (noted below). This issue captures **all currently open findings** discovered via fresh reconnaissance of the entire codebase on 2026-05-17.

**Target locale:** Spanish (`es`). Recommendations apply to all future locales.

---

## BLOCKER — Bilingual error messages from `Result.failure()` with English prose

**Status:** Unresolved from prior audit. 27+ sites remain.

**Problem:** Repositories, services, and providers construct error messages in English and pass them as the `{error}` parameter to localized ARB strings. The result is always bilingual, e.g.:

| Context | Rendered |
|---|---|
| `l10n.failedToSaveSession('Failed to save session: disk full')` | `"Error al guardar la sesion: Failed to save session: disk full"` |
| `l10n.failedToFetchUrl('Failed to fetch URL: HTTP 500')` | `"Error al obtener URL: Failed to fetch URL: HTTP 500"` |

**Affected files (27+ sites):**

| File | Lines | Pattern |
|---|---|---|
| `lib/features/lessons/data/repositories/lesson_repository.dart` | 26, 35, 44, 55, 70, 83, 97 | `Result.failure('Failed to create/get lesson/block: ${e.toString()}')` |
| `lib/features/questions/data/repositories/question_repository.dart` | 27, 70, 99 | `Result.failure('Failed to create/get question: ${e.toString()}')` |
| `lib/core/services/personal_learning_plan_service.dart` | 100 | `Result.failure('Failed to initialize repository: $e')` |
| `lib/core/services/plan_adapter.dart` | 87, 119, 148 | `Result.failure('Failed to check adherence/regenerate plan/get report: $e')` |
| `lib/core/services/data_backup_service.dart` | 29, 75 | `Result.failure('Failed to export/restore backup: $e')` |
| `lib/core/services/topic_readiness_service.dart` | 111 | `Result.failure('Failed to determine topic readiness: $e')` |
| `lib/features/practice/services/mastery_recorder.dart` | 111 | `Result.failure('Failed to record attempt: $e')` |

**Fix:** Either (a) define `AppLocalizations`-aware error keys in `.arb` for each error type, or (b) refactor repositories/services to return typed error codes that the UI layer translates. **Never embed English prose in `Result.failure()` strings passed to localized placeholders.**

**Acceptance criteria:**
- Spanish users see fully Spanish error messages with zero English bleed-through.
- All `Result.failure('Failed to ...')` patterns are either localised or replaced with error-code enums.

---

## MAJOR — Hardcoded user-facing English strings in presentation layer

These are visible UI labels with no ARB key.

### M1 — `const Text('Gallery')` in tutor image picker

**File:** `lib/features/teaching/presentation/tutor_screen.dart:180`

```dart
title: const Text('Gallery'),
```

**Fix:** Replace with `l10n.gallery` (add ARB key if missing).

### M2 — Hardcoded bullet character `•` in mentor recommendations

**File:** `lib/features/mentor/presentation/mentor_screen.dart:536`

```dart
Text('• ', style: theme.textTheme.bodyMedium),
```

**Fix:** Move the bullet into the translated ARB template string or use a `WidgetSpan` approach that handles RTL.

### M3 — Hardcoded `*` for required field indicator

**File:** `lib/features/settings/presentation/profile_screen.dart:536`

```dart
Text('*', style: TextStyle(color: Theme.of(context).colorScheme.error))
```

**Fix:** Use `l10n.requiredFieldIndicator` to support locale-specific symbols (e.g. some locales use `(required)` text).

### M4 — Hardcoded `'Expression: '` in math expression widget

**File:** `lib/features/questions/presentation/widgets/math_expression_widget.dart:385`

```dart
text: 'Expression: ',
```

**Fix:** Replace with `l10n.expressionLabel`.

### M5 — English default lesson plan strings

**File:** `lib/features/teaching/data/models/lesson_plan_model.dart:74-81`

```dart
goals: ['Understand the topic'],
sections: [
  LessonSection(title: 'Introduction', ...),
  LessonSection(title: 'Main Content', ...),
  LessonSection(title: 'Practice', ...),
],
checkpoints: ['Lesson started', 'Topic covered', 'Practice completed'],
```

**Fix:** Add ARB keys: `l10n.defaultLessonGoal`, `l10n.sectionIntroduction`, `l10n.sectionMainContent`, `l10n.sectionPractice`, `l10n.checkpointStarted`, `l10n.checkpointTopicCovered`, `l10n.checkpointPracticeCompleted`.

### M6 — Hardcoded English PDF column header

**File:** `lib/features/sessions/services/session_export_service.dart:94`

```dart
headers: ['#', l10n.subjects, l10n.date, l10n.duration, l10n.correct, l10n.accuracy, 'Type'],
```

`'Type'` is the only header not using `l10n`. **Fix:** Replace with `l10n.sessionType` (add key if missing).

### M7 — `'Study Sessions'` share text fallback

**File:** `lib/features/sessions/services/session_export_service.dart:218,227`

```dart
text: l10n?.shareSessionsText ?? 'Study Sessions',
```

**Fix:** Remove the English fallback; require `l10n` as a non-null parameter.

### M8 — `'unknown'` fallback in upload screen

**File:** `lib/features/ingestion/presentation/upload_screen.dart:162`

```dart
content: Text(l10n.urlFetchFailed(result.error ?? 'unknown')),
```

**Fix:** Use `l10n.unknownError` instead of hardcoded `'unknown'`.

### M9 — Hardcoded English error strings in WebScraper

**File:** `lib/features/ingestion/services/web_scraper.dart:29,36,41`

```dart
Result.failure('Failed to fetch URL: HTTP ${response.statusCode}');
Result.failure('No readable content found at URL');
Result.failure('Failed to fetch URL: $e');
```

These `Result.failure` messages propagate to SnackBars. **Fix:** Accept `l10n` parameter and emit coded errors.

### M10 — `'No active session'` error strings

**File:** `lib/features/sessions/services/study_timer_service.dart:133,160`

```dart
return Result.failure('No active session');
```

**Fix:** Return a typed error or accept `l10n` for `l10n.noActiveSession`.

### M11 — `'Failed to load plan'` error string in provider

**File:** `lib/features/planner/providers/planner_providers.dart:230`

```dart
state = state.copyWith(error: 'Failed to load plan: $e');
```

**Fix:** Use `l10n.failedToLoadPlan(e)` (add ARB key if missing).

### M12 — English fallback in SyllabusResolver

**File:** `lib/features/planner/services/syllabus_resolver.dart:52`

```dart
l10n?.noTopicsFoundForSubject(subjectId) ?? 'No topics found for subject $subjectId',
```

The fallback `??` branch preserves English when `l10n` is null. **Fix:** Remove the fallback and ensure `l10n` is always provided.

---

## MAJOR — Hardcoded separators and concatenation patterns

### M13 — Colon-concatenated error messages in settings screen

**Files:** `lib/features/settings/presentation/settings_screen.dart:485,492,517,557`

Pattern repeated 4 times:
```dart
Text('${l10n.backupExportFailed}: ${result.error}')   // line 485
Text('${l10n.invalidBackupFile}: ${result.error}')    // line 517
```

**Fix:** Create parameterized ARB keys: `l10n.backupExportFailedWithError(error)`, `l10n.invalidBackupFileWithError(error)`, etc.

### M14 — `+` appended to localised label

**File:** `lib/features/planner/presentation/planner_screen.dart:533`

```dart
label: Text('${l10n.courseSubject} +'),
```

**Fix:** Use `l10n.addCourseSubject` instead of concatenating `+`.

### M15 — `/` separator between hours and days

**File:** `lib/features/planner/presentation/planner_screen.dart:567`

```dart
Text('${l10n.hoursAbbreviation(...)}/${l10n.days}'),
```

**Fix:** Use a template `l10n.hoursPerDay(hoursAbbrev)` that embeds the separator in the ARB string.

### M16 — `·` (middle dot) separator in lesson display

**File:** `lib/features/planner/presentation/planner_screen.dart:708`

```dart
'${lesson.topicId ?? ''} · $time${isCompleted ? ' · ${l10n.completed}' : ''}'
```

**Fix:** Use a single ARB template `l10n.lessonTimeStatus(topicId, time, isCompleted)`.

### M17 — ` - ` (space-dash-space) separator in exam screen

**File:** `lib/features/practice/presentation/screens/exam_session_screen.dart:449,475`

```dart
AppBar(title: Text('${l10n.practiceMode} - ${widget.subjectName}'))
```

**Fix:** Use `l10n.practiceModeWithSubject(widget.subjectName)`.

### M18 — `\n\n` separator between mentor greeting and body

**File:** `lib/features/mentor/presentation/mentor_screen.dart:114`

```dart
content: '${l10n.mentorGreeting}\n\n${l10n.mentorWelcomeBody}'
```

**Fix:** Combine into single localised string `l10n.mentorWelcomeFull` so paragraph spacing can vary by locale.

---

## MAJOR — Locale-unaware number and date formatting

### M19 — Hardcoded `day/month/year` in session history

**File:** `lib/features/sessions/presentation/session_history_screen.dart:367`

```dart
'${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
```

**Fix:** Use `DateFormat.yMd(l10n.localeName).format(_selectedDate!)`.

### M20 — Hardcoded `day/month/year` in PDF export

**File:** `lib/features/sessions/services/session_export_service.dart:99`

```dart
'${s.startTime.day}/${s.startTime.month}/${s.startTime.year}'
```

Per AGENTS.md, PDF exports are user-facing and must use locale-aware formatting. **Fix:** Use `DateFormat.yMd(l10n.localeName).format(s.startTime)`.

### M21 — `'0%'` fallback bypasses `formatPercent`

**File:** `lib/features/practice/presentation/widgets/practice_session_stats_bar.dart:43`

```dart
final scoreValue = currentIndex > 0 ? formatPercent(...) : '0%';
```

**Fix:** Replace `'0%'` with `formatPercent(0, l10n.localeName, minFractionDigits: 0)`.

### M22 — `%` concatenated after `formatDecimal` instead of using `formatPercent`

**Files (3 sites):**
- `lib/features/sessions/services/session_export_service.dart:102`
- `lib/core/services/progress_export_service.dart:219,221`

```dart
'${formatDecimal(ms.accuracy * 100, l10n.localeName, ...)}%'
```

**Fix:** Replace with `formatPercent(value, l10n.localeName, ...)` (takes 0-100 range) which handles percent-sign placement per locale conventions (e.g. space before `%` in French).

### M23 — `sessions.length.toString()` bypasses locale formatting

**File:** `lib/features/sessions/presentation/widgets/session_analytics.dart:113`

```dart
value: sessions.length.toString(),
```

**Fix:** Use `formatDecimal(sessions.length.toDouble(), l10n.localeName)`.

### M24 — `formatDecimal(..., 'en', ...)` hardcodes English locale

**File:** `lib/features/teaching/services/conversation_manager.dart:328`

```dart
tutorNotes: 'Adaptive pace: ${formatDecimal(adaptivePace, 'en', ...)}x',
```

The `tutorNotes` field is stored as session metadata and may be surfaced in UI. **Fix:** Pass `localeName` from the session context instead of hardcoded `'en'`.

---

## MAJOR — English-only keyword extraction in MentorService

### M25 — English intent detection keywords

**File:** `lib/features/mentor/services/mentor_service.dart:245,254`

```dart
final keywords = ['about ', 'for ', 'on ', 'study ', ...];
final topicKeywords = ['topic ', 'subject ', 'lesson '];
```

**Fix:** Use a locale-aware keyword provider that can return Spanish/French/German equivalents, or delegate intent detection to the LLM.

### M26 — Partial Spanish + English schedule intent detection

**File:** `lib/features/mentor/services/mentor_service.dart:396-402`

```dart
hasScheduleIntent = lower.contains('schedule') || lower.contains('reschedule')
    || lower.contains('programar') || lower.contains('reprogramar');
```

Spanish keywords exist but only for scheduling. **Fix:** Provide comprehensive locale-to-keyword mappings for all intent categories, or delegate entirely to the LLM.

---

## MAJOR — Hardcoded English in LLM prompts (borderline)

Per AGENTS.md: "LLM-facing strings can stay in `en` invariant format." However, these strings in **prompts.dart** are injected into localized prompt templates, creating a jarring English/ES mix:

**File:** `lib/features/teaching/services/prompts/prompts.dart:48-58`

```dart
'Start the lesson warmly.',
'Teach the concept step by step...',
'The student is doing well. Accelerate pace.',
'The student seems to be struggling...',
'Give the student a practice question...',
```

These `paceContext` and `timeContext` strings are injected via `l10n.tutorInstructionPrompt(timeContext, paceContext)` at line 61. The surrounding prompt is localized, but the injected context cues remain English.

**Acceptance criteria:** Add ARB translations for context cues so they render in the student's language when the surrounding prompt is localized.

---

## MINOR — RTL layout issues

### R1 — Chat bubble `BorderRadius.only` with hardcoded corners

**File:** `lib/features/teaching/presentation/widgets/chat_bubble.dart:48-53`

```dart
BorderRadius.only(
  topLeft: const Radius.circular(16),
  topRight: const Radius.circular(16),
  bottomLeft: Radius.circular(isStudent ? 16 : 4),
  bottomRight: Radius.circular(isStudent ? 4 : 16),
),
```

Bubble tails (sharp corners) are hardcoded: student tail on right, tutor tail on left. In RTL these should be mirrored. **Fix:** Use `Directionality.of(context)` to swap `bottomLeft`/`bottomRight`.

### R2 — Milestone timeline uses hardcoded `left` positioning

**File:** `lib/features/planner/presentation/widgets/milestone_timeline.dart:68-70`

```dart
Positioned(
  left: left - 6,
  top: 0,
```

The timeline assumes left-to-right flow. **Fix:** Use `Directionality.of(context)` and switch to `right` for RTL locales.

### R3 — `Alignment.centerRight` in cancel button

**File:** `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:337`

```dart
Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(onPressed: ..., icon: const Icon(Icons.cancel, ...), ...),
)
```

**Fix:** Replace with `AlignmentDirectional.centerEnd`.

### R4 — `Alignment.centerRight` in upload screen fetch button

**File:** `lib/features/ingestion/presentation/upload_screen.dart:465`

```dart
Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(onPressed: ..., icon: const Icon(Icons.download, ...), ...),
)
```

**Fix:** Replace with `AlignmentDirectional.centerEnd`.

### R5 — `EdgeInsets.only(left:..., right:...)` with symmetrical values

**Files (3 sites, all with equal left/right values):**
- `lib/core/widgets/conversation_input.dart:53-56`
- `lib/core/widgets/conversation_input.dart:151-155`
- `lib/features/teaching/presentation/widgets/chat_bubble.dart:29-33`

```dart
padding: EdgeInsets.only(
  left: someValue,
  right: someValue,
  ...
),
```

**Fix:** Replace with `EdgeInsetsDirectional` or `EdgeInsets.symmetric(horizontal: value)` for symmetrical padding.

### R6 — Directional arrow icons not mirrored in RTL

**12 occurrences of `Icons.chevron_right` in 7 files:**
- `lib/features/practice/presentation/widgets/source_practice_sheet.dart:99`
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart:112`
- `lib/features/dashboard/presentation/dashboard_screen.dart:246`
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:114`
- `lib/features/subjects/presentation/widgets/subject_lessons_tab.dart:99`
- `lib/features/lessons/presentation/topic_list_screen.dart:74`

**5 occurrences of `Icons.arrow_forward_ios` in 3 files:**
- `lib/features/settings/presentation/settings_screen.dart:219`
- `lib/features/subjects/presentation/subject_list_screen.dart:179`
- `lib/features/practice/presentation/widgets/practice_mode_option.dart:60`

**Fix:** Use `Icon(Icons.chevron_right)` with `Directionality` context to swap direction in RTL, or use a custom widget.

### R7 — LinearGradient directions hardcoded

**Files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:77-78`
- `lib/core/widgets/gradient_container.dart:24-25`

```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
),
```

**Fix:** Use `AlignmentDirectional.topStart` / `AlignmentDirectional.bottomEnd` if available, or accept this as decorative (MINOR cosmetic issue).

---

## MINOR — ARB translation defects

### A1 — Duplicate `questionsCount` key (HIGH impact)

**Files:** `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`

| Occurrence | Line | Value |
|---|---|---|
| 1st | ~1091 | `"Questions: {count}"` |
| 2nd | ~4991 | `"{count,plural,=0{No questions available}=1{1 question available}...}"` |

The second definition silently overwrites the first. Any code calling `questionsCount(count)` expecting `"Questions: 5"` now receives `"5 questions available"`. **Fix:** Rename the second to `questionsCountPlural` and keep the simple version for the original use case.

### A2 — Duplicate `dismiss` key (lower impact)

Both ARB files have `dismiss` at ~line 2156 and ~line 4712 with conflicting `@dismiss` descriptions ("Button to dismiss a nudge" vs "Dismiss button label"). **Fix:** Consolidate to one key with a single description.

### A3 — Spanish `correctAnswerKeywords` missing accent

**File:** `lib/l10n/app_es.arb`, near line 4354

```json
"correctAnswerKeywords": "correcto,bien,si,..."
```

`"si"` (meaning "if") should be `"sí"` (meaning "yes"). **Fix:** Correct the orthography.

### A4 — `roadmapGoalHint` uses `"ej.,"` instead of `"p. ej.,"`

**File:** `lib/l10n/app_es.arb`, near line 3146

```json
"roadmapGoalHint": "ej., Quiero aprender Fisica IB en 180 dias"
```

Should be `"p. ej., "` (missing abbreviation prefix). **Fix:** Correct to `"p. ej., Quiero aprender Fisica IB en 180 dias"`.

### A5 — `overtimeLabel` format mismatch

| Locale | Value |
|---|---|
| EN | `"+{minutes}m"` |
| ES | `"+{minutes} min"` |

EN uses `m` suffix with no space; ES uses `min` with a space. This inconsistency means the presentation will differ between locales for the same data. **Fix:** Align on a consistent format (e.g. always use `"m"` or always use a localised abbreviation).

### A6 — Near-duplicate keys: `correctCount` / `correctCountLabel`, `questionsCount` / `questionsCountLabel` / `questionsCountMetric`

ARB keys `correctCount` (~2816) and `correctCountLabel` (~2794) have nearly identical semantics. Same for `questionsCount` family. **Fix:** Consolidate where possible to reduce maintenance burden.

---

## Summary Table

| Severity | Count | Key Areas |
|---|---|---|
| **BLOCKER** | 27+ sites | Repository/service `Result.failure()` English prose → bilingual UI |
| **MAJOR** | 26+ sites | Hardcoded UI strings, separators, number/date formatting, English-only keywords, PDF exports |
| **MINOR** | 20+ sites | RTL positioning, ARB duplicates/defects, directional icons, gradient directions |

## Priority Order

1. **BLOCKER — Bilingual error messages** (broken UX, 27+ sites)
2. **MAJOR — Hardcoded visible UI strings** (M1–M12: `Gallery`, `•`, `*`, `Expression:`, lesson plan, PDF headers, error fallbacks)
3. **MAJOR — Hardcoded separators** (M13–M18: colon, `+`, `/`, `·`, ` - `, `\n\n`)
4. **MAJOR — Locale-unaware formatting** (M19–M24: dates, percent concatenation, `.toString()`, hardcoded `'en'`)
5. **MAJOR — English-only keyword extraction** (M25–M26)
6. **MINOR — RTL preparation** (R1–R7)
7. **MINOR — ARB quality** (A1–A6)
