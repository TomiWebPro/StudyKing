# Internationalisation Master — i18n Audit & Blitz

**Target locale:** Spanish (`es`) — fixes here serve as a pattern for all other locales (French, German, Arabic, etc.)

---

## BLOCKER

*None found.* The app bootstraps correctly with `supportedLocales: [Locale('en'), Locale('es')]`, no key is completely missing from the Spanish ARB, and the app does not crash on locale switch.

---

## MAJOR

### M1. Missing ICU plural syntax in two Spanish ARB keys

**File:** `lib/l10n/app_es.arb` lines 6654, 6661  
**Keys:** `prerequisitesCount`, `downstreamCount`

The English versions use ICU plural syntax:
```json
"prerequisitesCount": "{count, plural, =1{1 prerequisite} other{{count} prerequisites}}",
"downstreamCount": "{count, plural, =1{1 downstream} other{{count} downstream}}"
```

The Spanish versions drop ICU entirely — they always render the plural form:
```json
"prerequisitesCount": "{count} requisitos previos",       // shows "1 requisitos previos"
"downstreamCount": "{count} dependientes"                  // shows "1 dependientes"
```

**Rationale:** When `count == 1`, the user sees ungrammatical "1 requisitos previos" or "1 dependientes" instead of "1 requisito previo" / "1 dependiente". This is a user-facing grammar error that affects a core navigation affordance (topic dependency dialog).

**Acceptance criteria:**
- Fix both keys to use `{count, plural, =1{...} other{{...}}}` syntax matching the English structure but with correct Spanish singular/plural forms.
- Verify: `prerequisitesCount(1)` → `"1 requisito previo"`, `prerequisitesCount(3)` → `"3 requisitos previos"`
- Verify: `downstreamCount(1)` → `"1 dependiente"`, `downstreamCount(3)` → `"3 dependientes"`

---

### M2. Mentor context prompt is invariant English — LLM bias toward English

**File:** `lib/features/mentor/services/mentor_service.dart`, lines 212–322  
**Method:** `_buildContextPrompt()`

**Problem:** The entire student context block that is injected into every mentor system prompt is hardcoded in English, regardless of the user's locale. Key lines:
- Line 232: `buffer.writeln('Current student context:');`
- Line 233: `buffer.writeln('${bullet}Total attempts: ${stats['totalAttempts']}');`
- Line 234: `buffer.writeln('${bullet}Correct attempts: ${stats['correctAttempts']}');`
- Line 235: `buffer.writeln('${bullet}Accuracy: ${stats['accuracy']}%');`
- Line 288: `buffer.writeln('${bullet}Weak topics needing attention:');`
- Line 304: `buffer.writeln('${bullet}Congratulations! $consecutiveDays day study streak!');`

This structural English text **biases the LLM to respond in English** even when the user writes in Spanish, because the system prompt contains paragraphs of English that the model treats as normative.

**Rationale:** When a Spanish-speaking student uses the Mentor, the context section should be in Spanish so the LLM stays in Spanish throughout the conversation. The `_languageInstruction` in `prompts.dart` is appended after the context, but the context's sheer volume of English text often overrides it.

**Acceptance criteria:**
- Refactor `_buildContextPrompt()` to pull all structural labels from `AppLocalizations` via the injected `l10n` or `_localeName`.
- Add at minimum the following new ARB keys (or reuse existing ones where they overlap with practice/dashboard labels):
  - `mentorContextHeader` → `"Contexto actual del estudiante:"`
  - `mentorContextTotalAttempts` → `"Intentos totales: {count}"`
  - `mentorContextCorrectAttempts` → `"Intentos correctos: {count}"`
  - `mentorContextAccuracy` → `"Precisión: {percent}%"`
  - `mentorContextWeakTopics` → `"Temas débiles que necesitan atención:"`
  - `mentorContextStreak` → `"¡Felicidades! Racha de {count} días de estudio!"`
  - ...and analogous keys for all label strings in the 212–322 block.
- Numbers and percentages in the context should remain in invariant format (these are LLM-facing data points, per `AGENTS.md`).
- Verify: with `localeName = 'es'`, the context block fed to the LLM has Spanish structural labels.

---

### M3. Hardcoded user-facing strings in presentation layer

**File:** `lib/features/practice/presentation/screens/exam_session_screen.dart`

| Line | String | Fix |
|------|--------|-----|
| 815 | `'Avg time/question'` | Replace with new ARB key `avgTimePerQuestion` → `"Tiempo prom./pregunta"` |
| 826 | `'Results will affect spaced repetition scheduling for ${result.questionResults.length} questions.'` | Replace with new ARB key `examResultsSrsImpact({count})` → `"Los resultados afectarán la programación de repaso espaciado de {count} preguntas."` |
| 845 | `'Questions at a glance'` | Replace with new ARB key `questionsAtAGlance` → `"Preguntas de un vistazo"` |

**File:** `lib/features/practice/presentation/screens/practice_screen.dart`

| Line | String | Fix |
|------|--------|-----|
| 508 | `'No exam history available'` | Replace with new ARB key `noExamHistory` → `"No hay historial de exámenes disponible"` |
| 517 | `'Exam History'` | Replace with new ARB key `examHistory` → `"Historial de Exámenes"` |

**File:** `lib/features/planner/services/personal_learning_plan_service.dart`

| Line | String | Fix |
|------|--------|-----|
| 848–852 | Fallback recommendation strings (used when `_l10n` is null) | These should either be removed (if `_l10n` is never null) or translated via ARB keys. Since the service already has a `_l10n` field, consider making it non-nullable. If fallback must remain, use invariant English (fine for defensive fallback—low priority). |
| 915, 917–918 | Focus labels like `'General review'`, `'Focus on weak areas'` | These already have `_l10n` path via `planFocusLabel()` but the fallbacks remain English. Remove the `if (l10n != null)` condition entirely and make `_l10n` required. |

**Rationale:** These strings are directly user-visible. In Spanish locale they appear as English text, degrading UX.

**Acceptance criteria:**
- All five strings in `exam_session_screen.dart` are replaced with `l10n.*` calls backed by new ARB keys.
- Both strings in `practice_screen.dart` are replaced with `l10n.*` calls.
- The `personal_learning_plan_service.dart` fallback path is either removed (by making `_l10n` required) or the fallback strings are added to ARB.

---

### M4. Locale-unaware percentage formatting in user-facing displays

These use `toStringAsFixed`, `round()` + string interpolation, or manual `%` concatenation where `formatPercent()` from `lib/core/utils/number_format_utils.dart` should be used instead. All affect user-facing displays in Spanish (where the percent sign should be `"85 %"` not `"85%"`).

| # | File | Line | Pattern | Fix |
|---|------|------|---------|-----|
| 1 | `lib/features/practice/presentation/screens/practice_screen.dart` | 873 | `'${(s.correctAnswers / s.questionsAnswered * 100).round()}%'` | `formatPercent(value, l10n.localeName, min:0, max:0)` |
| 2 | `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` | 78 | `'${(progress * 100).round()}%'` (Semantics) | `formatPercent(progress * 100, l10n.localeName, min:0, max:0)` |
| 3 | `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart` | 97 | `'${(_masteryThreshold * 100).round()}'` passed to `l10n.masteryThreshold(...)` | Pass `formatPercent(...)` result instead of raw number |
| 4 | `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart` | 104 | `'${(_masteryThreshold * 100).round()}%'` (Slider label) | `formatPercent(..., localeName)` |
| 5 | `lib/core/services/progress_export_service.dart` | 180 | `'${overallStats['accuracy']}%'` (PDF export — user-facing per conventions) | `formatPercent(value, l10n.localeName, min:0, max:0)` |

**Rationale:** Per `AGENTS.md`: "Never use `toStringAsFixed()` for user-facing numeric displays. It always produces a period decimal separator." The same applies to manual `round()` + `%` concatenation. Spanish (and French, German) use a non-breaking space before `%` or different decimal separators.

**Acceptance criteria:**
- All five sites use `formatPercent()` with the locale-aware localeName.
- Verify: en display shows `"85%"`, es display shows `"85 %"`.
- Verify: no regression in CSV exports (which should remain in invariant `en` format).

---

### M5. NavigationBar overflow with longer translated strings

**File:** `lib/main.dart`, lines 641–654  
**6 destinations on NavigationBar:** Dashboard, Subjects, Practice, Mentor, Focus Mode, Settings

**Problem:** Material 3 `NavigationBar` with 6 icon+text destinations on a narrow phone (~360px) already risks overflow in English. With Spanish translations like `"Panel"`, `"Materias"`, `"Práctica"`, `"Mentor"`, `"Estudio"`, `"Ajustes"`, labels get truncated or overlap. The `NavigationBar` widget does NOT auto-scroll or wrap labels.

**File:** `lib/features/subjects/presentation/subject_detail_screen.dart`, lines 186–198  
**6 tabs in TabBar:** Lessons, Practice, Topics, Sources, History, Stats — with icon + text labels. Same overflow risk.

**Rationale:** These are the app's primary navigation surfaces. Truncated labels make the app confusing to navigate.

**Acceptance criteria:**
- Make the `NavigationBar` labels scrollable or use `NavigationBar.labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected` (or similar) to handle overflow gracefully.
- Set `isScrollable: true` on the subject detail `TabBar` so tabs can scroll horizontally instead of overflowing.
- Verify: on a 360px-wide viewport in Spanish locale, all navigation labels are either fully visible or properly handled without overlap.

---

## MINOR

### m1. RTL-unaware directional icons (15 sites)

When Arabic/Hebrew/Persian support is added, these icons will point the wrong way. Fix now while only LTR locales are supported to avoid a future RTL blitz.

| # | File | Line | Icon | Context |
|---|------|------|------|---------|
| 1 | `lib/features/dashboard/presentation/dashboard_screen.dart` | 536 | `Icons.chevron_right` | Empty source card affordance |
| 2 | `lib/features/dashboard/presentation/widgets/next_up_card.dart` | 134 | `Icons.chevron_right` | ListTile trailing icon |
| 3 | `lib/features/teaching/presentation/tutor_screen.dart` | 961 | `Icons.chevron_left` | Previous slide button |
| 4 | `lib/features/teaching/presentation/tutor_screen.dart` | 972 | `Icons.chevron_right` | Next slide button |
| 5 | `lib/features/lessons/presentation/widgets/lesson_block_card.dart` | 165 | `Icons.chevron_left` | Lesson page navigation |
| 6 | `lib/features/lessons/presentation/widgets/lesson_block_card.dart` | 189 | `Icons.chevron_right` | Lesson page navigation |
| 7 | `lib/features/lessons/presentation/lesson_detail_screen.dart` | 128 | `Icons.arrow_back` | Back navigation |
| 8 | `lib/features/practice/presentation/widgets/practice_session_nav_buttons.dart` | 31 | `Icons.arrow_back` | Previous button (stacked) |
| 9 | same file | 44 | `Icons.arrow_forward` | Next button (stacked) |
| 10 | same file | 64 | `Icons.arrow_back` | Previous button (row) |
| 11 | same file | 79 | `Icons.arrow_forward` | Next button (row) |
| 12 | `lib/features/settings/presentation/settings_screen.dart` | 264, 420, 463, 1931, 1974 | `Icons.arrow_forward_ios` | ListTile trailing (5 locations) |
| 13 | `lib/features/subjects/presentation/subject_list_screen.dart` | 189 | `Icons.arrow_forward_ios` | Subject card trailing |
| 14 | `lib/features/practice/presentation/widgets/practice_mode_option.dart` | 60 | `Icons.arrow_forward_ios` | Mode option trailing |

**Acceptance criteria:**
- Wrap each directional icon with a ternary or helper function using `Directionality.of(context)` to flip the icon for RTL.
- Pattern: `Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right)`
- Verify: with `Directionality.rtl` wrapping, all navigation affordances point in the correct direction.

---

### m2. Mentor tool descriptions and result messages are English-only

**Files:** `lib/features/mentor/services/tools/*.dart` (6 files)

These tool definitions and their result messages are sent to the LLM as part of the function-calling schema. They are always in English regardless of user locale.

| File | Lines | String |
|------|-------|--------|
| `get_student_stats_tool.dart` | 20 | `"Get overall student performance statistics and study data."` |
| `schedule_lesson_tool.dart` | 14 | `"Schedule a lesson/session for a specific topic at a given time."` |
| `schedule_lesson_tool.dart` | 48–50 | Result messages like `"Lesson scheduled: ..."` / `"Failed to schedule lesson"` |
| `generate_lesson_blocks_tool.dart` | 14 | `"Generate structured lesson blocks..."` |
| `generate_lesson_blocks_tool.dart` | 43 | `"Failed to generate lesson blocks"` |
| `create_plan_tool.dart` | 14 | `"Create a learning plan or roadmap..."` |
| `create_plan_tool.dart` | 44–46 | Result messages like `"Plan created for ..."` / `"Failed to create plan"` |
| `get_weak_topics_tool.dart` | 19 | `"Get weak or at-risk topics that need student attention."` |
| `search_questions_tool.dart` | 14 | `"Search for questions by subject, topic, or keyword."` |

**Rationale:** While many LLMs understand English tool names, the result messages fed back to the mentor agent are also English, and the tool descriptions bias the LLM toward English.

**Acceptance criteria:**
- Pull tool descriptions from `AppLocalizations` using the locale-aware map, or accept that tool definitions are a low-priority i18n item and document the decision.
- At minimum, localize the result messages in `schedule_lesson_tool.dart`, `generate_lesson_blocks_tool.dart`, and `create_plan_tool.dart` by pulling from ARB keys.

---

### m3. `languageInstruction` omits instruction for unsupported locales

**File:** `lib/features/teaching/services/prompts/prompts.dart`, lines 25–28

```dart
String _languageInstruction(AppLocalizations l10n) {
  if (localeName == 'en') return '';
  return '\n${l10n.languageInstruction(localeName)}';
}
```

**Problem:** When the locale is `'en'`, the instruction is empty. When a future locale (e.g. `'fr'`) is added but its `app_fr.arb` does NOT include `languageInstruction`, the `l10n.languageInstruction(localeName)` will throw a runtime error because the method is generated from the ARB key. Also, a user with English UI who wants tutoring in Spanish gets no language instruction.

**Acceptance criteria:**
- Gracefully handle missing `languageInstruction` for unsupported locales (fallback to English instruction or silently skip).
- Consider making the language instruction always present (even for `'en'`) but stating "Respond in English" to make the behavior explicit and consistent.

---

### m4. Mixed directional EdgeInsets

**File:** `lib/features/planner/presentation/planner_screen.dart`, line 541

```dart
padding: const EdgeInsets.only(top: 4).add(const EdgeInsetsDirectional.only(start: 4)),
```

This mixes `EdgeInsets.only` (non-directional) with `EdgeInsetsDirectional.only` (directional). While it works, it's fragile. Should be consolidated.

**Acceptance criteria:**
- Replace with `EdgeInsetsDirectional.only(start: 4, top: 4)`.

---

### m5. `maxLines: 1` truncation risk for translated content

**Files:**
- `lib/features/ingestion/presentation/content_library_screen.dart:528` — source title
- `lib/features/subjects/presentation/subject_detail_screen.dart:557` — source list item title
- `lib/features/planner/presentation/widgets/roadmap_card.dart:175` — sub-task text
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart:141` — calendar event label

**Rationale:** German compound words (e.g. "Benachrichtigungseinstellungen") or Spanish longer phrases may exceed the single-line limit. Switching to `maxLines: 2` or removing `maxLines` constraint (with `SoftWrap`) avoids truncation.

**Acceptance criteria:**
- Review each site and either remove `maxLines` or increase to `maxLines: 2`.
- For known cases where space is tight (e.g. calendar events), ensure `overflow: TextOverflow.clip` or `ellipsis` is acceptable.

---

### m6. `tokensAndCost` and `tokensLabel` not translated in Spanish ARB

**File:** `lib/l10n/app_es.arb`, line 2160

```json
"tokensAndCost": "Tokens: {count} ({cost})",
"tokensLabel": "{count} tokens",
```

**Problem:** The word "Tokens" is an English loanword that translates to "Fichas" or "Tokens" (accepted in many Spanish contexts, but inconsistent with the rest of the localisation). At minimum, the phrasing `"Tokens:"` should be `"Tokens:"` (acceptable) or `"Fichas:"` (preferred).

**Rationale:** Minor — "Tokens" is widely understood in Spanish tech contexts. Flagged for consistency review.

**Acceptance criteria:**
- Either accept current value (document decision) or change to `"Fichas: {count} ({cost})"` / `"{count} fichas"`.

---

### m7. Stale locale after switching language (documented gotcha)

**File:** `lib/features/settings/presentation/profile_screen.dart`, line 81  
**Referenced in:** `AGENTS.md` — "i18n Locale Switching Gotcha"

When the user changes language in Profile, `ref.read(localeProvider.notifier).state = Locale(profile.language)` updates the locale, but screens that cached `AppLocalizations.of(context)!` in a local variable (outside `build`) will display stale strings until re-entered.

**Rationale:** This is a known pattern but not audited. A sweep is needed to find all screens that cache `l10n` as a local variable instead of reading it inside `build`.

**Acceptance criteria:**
- Search for all occurrences of `AppLocalizations.of(context)` or `l10n` being stored in a field or local variable outside the `build` method in presentation layer files.
- Refactor any such occurrences to read `l10n` inside `build` (or use `ref.watch(localeProvider)`).
- Verify: after switching locale from `en` to `es` on the Profile screen, navigating to _any_ other screen shows the new locale immediately without requiring a screen re-entry.

---

### m8. Score/ratio display with plain integer concatenation (PDF- and user-facing)

| # | File | Line | Pattern | Fix |
|---|------|------|---------|-----|
| 1 | `lib/features/sessions/services/session_export_service.dart` | 124 | `'${s.correctAnswers}/${s.questionsAnswered}'` (PDF) | Use `formatDecimal` for each component |
| 2 | `lib/features/subjects/presentation/widgets/subject_history_tab.dart` | 120 | `'${session.correctAnswers}/${session.questionsAnswered}'` | Use `formatDecimal` for each component |
| 3 | `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` | 234 | `'${e.value.correct}/${e.value.total}'` | Use `formatDecimal` for each component |
| 4 | `lib/features/practice/presentation/screens/exam_session_screen.dart` | 917 | `'${minutes}m ${seconds}s'` / `'${seconds}s'` | Use new ARB keys `durationMinutesSeconds(minutes, seconds)` / `durationSeconds(seconds)` |

**Acceptance criteria:**
- Items 1–3 use `formatDecimal()` from `number_format_utils.dart` with the user's `localeName`.
- Item 4 uses an ARB-backed localized duration format.
- For CSV exports (item 1 is PDF per context), keep invariant format per conventions; item 2 and 3 are definitely user-facing.

---

## Summary of ARB keys to add

| New key | Purpose | Priority |
|---------|---------|----------|
| `avgTimePerQuestion` | "Avg time/question" label | M3 |
| `examResultsSrsImpact` | "Results will affect spaced repetition for {count} questions" | M3 |
| `questionsAtAGlance` | "Questions at a glance" | M3 |
| `noExamHistory` | "No exam history available" | M3 |
| `examHistory` | "Exam History" | M3 |
| `durationMinutesSeconds` | "{minutes}m {seconds}s" for exam results | m8 |
| `mentorContextHeader` | "Current student context:" localized | M2 |
| `mentorContextTotalAttempts` | "Total attempts: {count}" | M2 |
| `mentorContextCorrectAttempts` | "Correct attempts: {count}" | M2 |
| `mentorContextAccuracy` | "Accuracy: {percent}%" | M2 |
| `mentorContextWeakTopics` | "Weak topics needing attention:" | M2 |
| `mentorContextStreak` | "Congratulations! {count} day study streak!" | M2 |
| ... | (~15 more context labels for full mentor context i18n) | M2 |
| Tool descriptions | 6+ ARB keys for tool descriptions and result messages | m2 |

## ARB keys to fix (existing)

| Key | File | Fix | Priority |
|-----|------|-----|----------|
| `prerequisitesCount` | `app_es.arb:6654` | Add ICU plural syntax | M1 |
| `downstreamCount` | `app_es.arb:6661` | Add ICU plural syntax | M1 |
| `tokensAndCost` | `app_es.arb:2160` | Review/sync translation | m6 |
| `tokensLabel` | `app_es.arb` | Review/sync translation | m6 |
