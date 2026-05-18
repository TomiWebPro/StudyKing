# Internationalisation Master Issue

## Summary

Comprehensive audit of i18n readiness for Spanish (`es`) locale, with guidance for future locales. Two locales are configured (`en`, `es`) with 100% key parity across ~900 keys. The foundation is solid, but multiple gaps exist in UI strings, plural handling, service defaults, RTL readiness, and test coverage.

---

## BLOCKER — App crashes or user cannot proceed

*(None found. All critical paths are localised. However, the issues below are MAJOR in-practice.)*

---

## MAJOR — Feature broken or misleading for Spanish users

### M1. Validation messages default to English

**Files:**
- `lib/core/services/answer_validation_service.dart:36` — `AnswerValidationService` defaults to `ValidationMessages.english`
- `lib/core/services/answer_validation_service.dart:186-199` — `ValidationMessages.english` static constant
- `lib/core/services/answer_validation_service.dart:250-278` — Fallback strings in `someAnswersIncorrect()`, `correctAnswerIs()`, `allStepsFormat()` etc.
- `lib/features/teaching/services/exercise_evaluator.dart:68-77` — Hardcoded `'Could not evaluate answer: ...'` / `'Could not evaluate answer.'`

**Problem:** `ValidationMessages.english` is the default everywhere. Wile `ValidationMessages.fromLocalizations(l10n)` exists, it is not wired as the default. `ExerciseEvaluator` never calls `lookupAppLocalizations`. A Spanish user gets English feedback on every answer evaluation.

**Fix:** Inject `AppLocalizations` or `localeName` into `AnswerValidationService` constructor; remove the `ValidationMessages.english` default; make `ExerciseEvaluator` use `lookupAppLocalizations(Locale(_localeName))` for its error messages.

**AC:**
- [ ] `AnswerValidationService` defaults to locale-aware messages when constructed with a locale
- [ ] `ExerciseEvaluator` shows Spanish error messages when locale is `es`
- [ ] All UI paths that call validators pass locale context

---

### M2. Hardcoded English display names for Hive boxes (backup/restore)

**File:** `lib/features/settings/presentation/settings_screen.dart:816-838`

**Problem:** `_boxDisplayName()` returns 20 hardcoded English names (`'Subjects'`, `'Topics'`, `'Questions'`, `'Sessions (old)'`, `'Mastery States'` etc.) for the selective-restore dialog. A Spanish user sees English-only labels for backup sections.

**Fix:** Move to `AppLocalizations` keys. E.g., `l10n.boxSubjects`, `l10n.boxTopics`, `l10n.boxQuestions` etc.

**AC:**
- [ ] Each Hive box has a corresponding ARB key in both `app_en.arb` and `app_es.arb`
- [ ] `_boxDisplayName` is replaced with `l10n.boxSubjects`, `l10n.boxTopics`, etc.
- [ ] Backup restore dialog shows Spanish labels when locale is `es`

---

### M3. ICU plural gaps — keys that will display "1 seconds" / "1 minutes"

**File:** `lib/l10n/app_en.arb`
- `secondsValue` (~line 708): `"{count} seconds"` → needs `"{count,plural,=1{1 second} other{{count} seconds}}"`
- `minutesValue` (~line 733): `"{count} minutes"` → needs `"{count,plural,=1{1 minute} other{{count} minutes}}"`
- `dueQuestionsCount` (~line 429): `"{count} due"` → needs pluralisation
- `activeCount` (~line 2116): `"{count} active"` → needs pluralisation
- `attemptsCount` (~line 1961): `"{count} attempts"` → needs `"{count,plural,=1{1 attempt} other{{count} attempts}}"`
- `focusForMinutes` (~line 3514): `"Focus for {minutes} minutes"` → needs `"{minutes,plural,=1{Focus for 1 minute} other{Focus for {minutes} minutes}}"`

**Problem:** These 6 keys use a simple `{count}` placeholder without ICU plural syntax. In English `1 minutes`, `1 seconds` etc. are grammatically incorrect. In Spanish, the word for "minute" changes (`minuto`/`minutos`) but the template can't express that.

**Fix:** Convert each to ICU plural syntax in both `app_en.arb` and `app_es.arb`; run `flutter gen-l10n`.

**AC:**
- [ ] `secondsValue(1)` returns `"1 second"` / `"1 segundo"` not `"1 seconds"` / `"1 segundos"`
- [ ] `minutesValue(1)` returns `"1 minute"` / `"1 minuto"` not `"1 minutes"`
- [ ] `attemptsCount(1)` returns `"1 attempt"` / `"1 intento"`
- [ ] `focusForMinutes(1)` returns `"Focus for 1 minute"` / `"Enfócate por 1 minuto"`
- [ ] All 6 keys updated in both ARB files

---

### M4. `(s)` hack in ARB keys — asymmetric between English and Spanish

**File:** `lib/l10n/app_en.arb`
- `sourceCountFailed` (~line 5405): `"{count} source(s) failed to process"` — English uses `(s)` hack; Spanish uses proper ICU plural
- `recommendWeakTopics` (~line 4086): `"You have {count} topic(s) that need improvement."`
- `planBlocksDownstream` (~line 4282): `"Blocks {count} downstream topic(s)"`
- `nudgeRevisionNeeded` (~line 4912): `"You have {count} question(s) approaching their review date."`
- `nudgeLateNight` (~line 4905): `"...had {count} late-night study session(s)."`

**Problem:** The `(s)` suffix hack never localises correctly. `sourceCountFailed` is asymmetric: English uses the hack while Spanish uses proper plural syntax. The other 4 keys use the hack in both locales.

**Fix:** Convert all 5 keys to proper ICU plural syntax in both ARB files. For `sourceCountFailed`, ensure both files use the same plural pattern.

**AC:**
- [ ] `sourceCountFailed` uses ICU plural in both `app_en.arb` and `app_es.arb`
- [ ] `recommendWeakTopics` shows `"You have 1 topic that needs improvement."` for count=1
- [ ] `planBlocksDownstream` shows `"Blocks 1 downstream topic"` for count=1
- [ ] `nudgeRevisionNeeded` handles singular/plural correctly
- [ ] `nudgeLateNight` handles singular/plural correctly

---

### M5. Hardcoded English string concatenation instead of localised templates

**Files and lines:**
1. `lib/features/practice/presentation/screens/exam_session_screen.dart:481` — `Text('${l10n.practiceMode} - ${widget.subjectName}')`
2. `lib/features/settings/presentation/settings_screen.dart:1214` — `Text('${l10n.signOut} - ${l10n.done}')`
3. `lib/features/settings/presentation/settings_screen.dart:918` — `Text('${l10n.importFailed}: $e')`
4. `lib/features/mentor/presentation/mentor_screen.dart:312-314` — `'${l10n.time}: $dateStr'` and `'${l10n.duration}: ...'`
5. `lib/features/settings/presentation/settings_screen.dart:956` — `'${records.length} records'`

**Problem:** English word order (`X - Y`, `X: Y`) does not work for all locales. E.g., Spanish might want `"Cerrar sesión — Hecho"` but the hardcoded ` - ` prevents proper reordering. The `'${records.length} records'` pattern is entirely hardcoded English.

**Fix:** Add localised ARB keys:
- `examSessionTitle(subjectName)` = `"{mode} – {subject}"` / `"{mode} – {subject}"`
- `signOutComplete` = `"Sign out – Done"` / `"Cerrar sesión – Hecho"`
- `importFailedWithError(error)` = `"Import failed: {error}"` / `"Importación fallida: {error}"`
- `scheduleTimeLabel(time)` = `"Time: {time}"` / `"Hora: {time}"`
- `scheduleDurationLabel(duration)` = `"Duration: {duration}"` / `"Duración: {duration}"`
- `recordCount(count)` = `"{count} records"` / `"{count} registros"` (with ICU plural)

**AC:**
- [ ] Exam session screen uses `l10n.examSessionTitle(widget.subjectName)` instead of string concatenation
- [ ] Settings screen sign-out shows localised `signOutComplete`
- [ ] Settings screen import error shows localised `importFailedWithError`
- [ ] Mentor screen schedule uses localised labels
- [ ] Restore dialog shows `l10n.recordCount(length)` instead of `${length} records`

---

### M6. Locale-unaware English defaults in service constructors

**Files:**
- `lib/features/mentor/services/mentor_service.dart:79` — `String localeName = 'en'`
- `lib/features/teaching/services/tutor_service.dart:58` — `String localeName = 'en'`
- `lib/features/teaching/services/conversation_manager.dart:44,59` — `String localeName = 'en'`
- `lib/features/teaching/services/exercise_evaluator.dart:19` — `String localeName = 'en'`
- `lib/features/teaching/services/prompts/prompts.dart:21` — `String localeName = 'en'`

**Problem:** If any service is instantiated without explicitly passing the locale (e.g., via Riverpod provider without locale override), it silently operates in English even when the app is in Spanish. There is no compile-time guard or runtime warning.

**Fix:** Remove the default value `= 'en'` from all 5 constructors, making `localeName` a required parameter. Update all instantiation sites (providers, tests) to pass `l10n.localeName` or `ref.watch(localeProvider).languageCode`.

**AC:**
- [ ] `MentorService` constructor requires `localeName`
- [ ] `TutorService` constructor requires `localeName`
- [ ] `ConversationManager` constructor requires `localeName`
- [ ] `ExerciseEvaluator` constructor requires `localeName`
- [ ] `Prompts` constructor requires `localeName`
- [ ] All Riverpod providers that create these services pass the current locale from `localeProvider`
- [ ] All tests pass an explicit locale

---

### M7. Hardcoded ESL chatbot/default responses for ExerciseEvaluator

**File:** `lib/features/teaching/services/conversation_manager.dart`
- Lines 155 — phase-detection keywords: `['understand', 'got it', 'i see', 'continue', 'next', 'ok', 'yes']`
- Lines 280 — exercise-detection keywords: `['exercise', 'practice', 'quiz']`
- Lines 201-218 — Image analysis prompts hardcoded English

**File:** `lib/features/mentor/services/mentor_service.dart`
- Lines 265-267 — Topic keyword extraction: `['about ','for ','on ','study ','learn ','review ','practice ']`
- Lines 456-468 — Intent detection: `'schedule'`, `'reschedule'`, `'plan'`, `'roadmap'`

**Problem:** These keyword lists are used to detect student intent from their typed messages. A Spanish-speaking student typing `"entiendo"`, `"siguiente"`, `"ejercicio"`, `"estudiar"`, `"planificar"` would fail to match any keyword, causing the conversation manager to misinterpret their intent. The image analysis prompt is always in English regardless of locale.

**Fix:** Make keyword detection locale-aware. Pass the detected student language to the matching logic, and provide locale-specific keyword arrays.

**AC:**
- [ ] `ConversationManager` uses locale-specific continue/understanding keywords for `es` (e.g., `['entiendo', 'comprendo', 'siguiente', 'continuar', 'ok', 'sí']`)
- [ ] `ConversationManager` uses locale-specific exercise keywords for `es` (e.g., `['ejercicio', 'práctica', 'examen']`)
- [ ] Image analysis prompt varies by locale, e.g., via `lookupAppLocalizations`
- [ ] `MentorService` topic keywords support `es` without hardcoded `_localeName == 'es'` branching (scales to future locales)
- [ ] Mentor intent detection has `es` equivalents

---

## MINOR — Code quality / UX friction

### m1. Non-directional chevron icons (RTL readiness)

**Files (14 occurrences):**
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart:92,113` — `Icons.chevron_left` / `Icons.chevron_right`
- `lib/features/ingestion/presentation/content_library_screen.dart:613` — `Icons.chevron_right`
- `lib/features/ingestion/presentation/source_detail_screen.dart:453` — `Icons.chevron_right`
- `lib/features/subjects/presentation/subject_detail_screen.dart:548` — `Icons.chevron_right`
- `lib/features/subjects/presentation/widgets/subject_lessons_tab.dart:100` — `Icons.chevron_right`
- `lib/features/lessons/presentation/topic_list_screen.dart:76` — `Icons.chevron_right`
- `lib/features/dashboard/presentation/dashboard_screen.dart:132,273,312,344,415` — `Icons.chevron_right`
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:114` — `Icons.chevron_right`
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:618` — `Icons.chevron_right`

**Problem:** `Icons.chevron_right` / `Icons.chevron_left` do NOT auto-flip in RTL mode. `Icons.arrow_back_ios` / `Icons.arrow_forward_ios` DO auto-flip — but the codebase uses `chevron_*` instead. Adding an RTL locale (e.g., Arabic `ar`) would show wrong-direction chevrons in 14 places.

**Fix:** Replace with `Icons.chevron_right` → `Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right` (ternary), or create a helper widget. Alternatively migrate to `Icons.arrow_back_ios`/`arrow_forward_ios` which auto-flip, or use `Transform.flip` wrapper.

**AC:**
- [ ] All 14 chevron icon usages are RTL-aware
- [ ] In an RTL locale, calendar navigation chevrons point right for "next" and left for "previous"
- [ ] In an RTL locale, list item expansion chevrons point left (expansion cue)
- [ ] No regressions in LTR rendering

---

### m2. Hardcoded English fallbacks in notification service

**File:** `lib/core/services/notification_service.dart:200-292`

**Problem:** 22 fallback notification strings (e.g., `'Time to Review!'`, `'Take a Break'`, `'Plan Adjustment'`, `'Badge Unlocked!'`) are hardcoded in English. These are used only when `_l10n` is null, but localised alternatives exist. If `setAppLocalizations()` is never called or called late, users get English.

**Fix:** Remove hardcoded fallbacks; throw if `_l10n` is null (enforce the existing assertion at lines 47-48). Alternatively, guard every notification path so `_l10n` is guaranteed before scheduling.

**AC:**
- [ ] All 22 notification title/body strings have no English fallback
- [ ] `NotificationService` throws or logs warning if `_l10n` is null when a notification is created
- [ ] Riverpod provider ensures `setAppLocalizations` is called early enough in app startup

---

### m3. Hardcoded English fallbacks in engagement scheduler

**File:** `lib/core/services/engagement_scheduler.dart:301-364`

**Problem:** 4 English fallback nudge strings (overwork, revision, plan adjustment, weekly digest) used when localised version returns null. Same issue as m2 but smaller scope.

**Fix:** Same treatment — remove English fallbacks, ensure `_l10n` is always set.

**AC:**
- [ ] `EngagementScheduler` never falls back to English hardcoded strings
- [ ] All nudge messages respect current locale

---

### m4. Hardcoded English fallbacks in study_progress_tracker

**File:** `lib/core/services/study_progress_tracker.dart:179-271`

**Problem:** 15 English fallback recommendation strings (accuracy, consistency, weak topics, mastery levels) are hardcoded. Localised versions exist but `_l10n` parameter is optional and defaults to null.

**Fix:** Make `_l10n` required in the constructor; update all callers.

**AC:**
- [ ] `StudyProgressTracker` constructor requires `AppLocalizations` instance
- [ ] All recommendation strings are locale-aware

---

### m5. Hardcoded `'Unknown'` fallback in mentor service

**File:** `lib/features/mentor/services/mentor_service.dart:216`

**Problem:** `final title = ... ?? 'Unknown';` — hardcoded English fallback for unlabeled lessons in LLM context prompt.

**Fix:** Use localised `l10n.unknown` or handle the null case differently.

**AC:**
- [ ] Mentor context prompt never includes English `'Unknown'` for Spanish users

---

### m6. Hardcoded English in question PDF generator

**File:** `lib/core/services/pdf_generator/question_pdf_generator.dart:84`

**Problem:** `'Total Questions: ${_questions.length}'` is hardcoded English in a user-facing PDF header. Per AGENTS.md, PDFs should use the user's locale.

**Fix:** Accept an `AppLocalizations` parameter or locale string; use localised template.

**AC:**
- [ ] `QuestionPDFGenerator` accepts locale parameter
- [ ] Generated PDF shows localised header text

---

### m7. Hardcoded `'en'` locale in tests — only 5 test files test `es`

**Finding:** 194+ test files hardcode `Locale('en')`. Only 5 test files ever test with `es` locale:
- `test/features/teaching/providers/teaching_providers_test.dart`
- `test/features/settings/presentation/profile_screen_test.dart`
- `test/features/sessions/presentation/widgets/session_analytics_test.dart`
- `test/features/planner/presentation/widgets/plan_summary_card_test.dart`
- `test/l10n/app_localizations_comprehensive_test.dart`

**Fix:** Add a CI check that runs the test suite with `es` locale injected. Add locale-aware widget tests that verify Spanish string rendering for critical screens (settings, backup/restore, practice session, mentor).

**AC:**
- [ ] CI pipeline includes a locale-switching test run
- [ ] At least 3 widget tests assert Spanish string rendering
- [ ] All services that accept a `localeName` parameter are tested with `'es'`

---

### m8. `EdgeInsets.only(left:)` pattern (none found — confirm clean)

The codebase is clean on directional padding — zero uses of `EdgeInsets.only(left:)` or `EdgeInsets.only(right:)`. This pattern must not be re-introduced.

---

### m9. `TextAlign.left` / `TextAlign.right` (none found — confirm clean)

The codebase is clean on non-directional text alignment — zero uses of `TextAlign.left` or `TextAlign.right`. This pattern must not be re-introduced.

---

### m10. Locale flicker on startup (race condition)

**File:** `lib/main.dart:153-167`

**Problem:** `localeProvider` initialises with device locale via `postFrameCallback`. The saved user locale overrides one frame later, causing a visible locale flicker. If profile load fails, the user's saved language is silently lost.

**Fix:** Make `localeProvider` async-first: wait for profile load before providing the initial locale value. Use `FutureProvider` or an async initialisation step.

**AC:**
- [ ] Startup locale is set before first frame render when profile data is available
- [ ] Profile load failure falls back gracefully without flicker
- [ ] No visible locale change after initial app render

---

### m11. Hardcoded `Locale('en')` fallback in locale config

**File:** `lib/core/providers/app_providers.dart:293`

**Problem:** `return const Locale('en');` — if device locale is unsupported, fallback is always English. This is reasonable for now but should be configurable as more locales are added.

**Fix:** Extract fallback locale to a constant or config file. No functional change needed now, but mark for future.

---

### m12. `secondsValue` / `minutesValue` test coverage

**File:** `test/l10n/app_localizations_test.dart`

**Problem:** Tests for `secondsValue(1)` and `minutesValue(1)` exist (`expect(l10n.secondsValue(1), '1 seconds')`) which asserts the *wrong* current behaviour. After fixing M3, these tests must be updated to expect `'1 second'` / `'1 segundo'`.

**Fix:** Update test expectations after ARB change.

---

## Appendix A: Files verified as correctly localised (no action needed)

- `lib/features/onboarding/presentation/onboarding_dialog.dart` — all strings via l10n
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — all strings via l10n
- `lib/core/utils/number_format_utils.dart` — correct locale-aware API
- `lib/core/utils/localization_helpers.dart` — correct localisation pattern
- `lib/core/utils/time_utils.dart` — locale-aware via `l10n.localeName`
- `lib/core/config/locale_config.dart` — correct setup
- `lib/l10n/app_es.arb` — all ~900 keys present, no missing translations
- All `SnackBar`, `AlertDialog`, `tooltip`, `AppBar` (`title:`) usages checked — all use l10n
- All `DateFormat` usages — all use `l10n.localeName`
- All `toStringAsFixed` usages — only in CSV exports and LLM-facing strings (intentional per AGENTS.md)

## Appendix B: LLM-facing strings (intentionally English, no action needed)

- `lib/features/teaching/services/prompts/prompts.dart` — all via l10n, `_languageInstruction` uses student locale
- `lib/features/mentor/services/mentor_service.dart:155-256` — context prompt labels, clearly documented as invariant English for LLM data formatting
- `lib/core/constants/llm_defaults.dart` — JSON schema instruction, not user-facing
- `lib/core/services/progress_export_service.dart` — CSV headers are data format, invariant

## Appendix C: Key tables

### Affected ARB keys to update (plural gaps)

| Key | Current (en) | Must become |
|---|---|---|
| `secondsValue` | `"{count} seconds"` | `"{count,plural,=1{1 second} other{{count} seconds}}"` |
| `minutesValue` | `"{count} minutes"` | `"{count,plural,=1{1 minute} other{{count} minutes}}"` |
| `dueQuestionsCount` | `"{count} due"` | `"{count,plural,=1{1 due} other{{count} due}}"` |
| `activeCount` | `"{count} active"` | `"{count,plural,=1{1 active} other{{count} active}}"` |
| `attemptsCount` | `"{count} attempts"` | `"{count,plural,=1{1 attempt} other{{count} attempts}}"` |
| `focusForMinutes` | `"Focus for {minutes} minutes"` | `"{minutes,plural,=1{Focus for 1 minute} other{Focus for {minutes} minutes}}"` |

### `(s)` hack keys to convert to plural

| Key | Current (en) | Must become |
|---|---|---|
| `sourceCountFailed` | `"{count} source(s) failed..."` | `"{count,plural,=1{{count} source failed...} other{{count} sources failed...}}"` |
| `recommendWeakTopics` | `"You have {count} topic(s)..."` | `"{count,plural,=1{You have 1 topic that needs...} other{You have {count} topics that need...}}"` |
| `planBlocksDownstream` | `"Blocks {count} downstream topic(s)"` | proper plural |
| `nudgeRevisionNeeded` | `"You have {count} question(s)..."` | proper plural |
| `nudgeLateNight` | `"...had {count} late-night study session(s)"` | proper plural |

### New ARB keys to add

| Proposed key | en template | es template |
|---|---|---|
| `boxSubjects` | `Subjects` | `Materias` |
| `boxTopics` | `Topics` | `Temas` |
| `boxQuestions` | `Questions` | `Preguntas` |
| `boxSources` | `Sources` | `Fuentes` |
| `boxLessons` | `Lessons` | `Lecciones` |
| `boxLessonBlocks` | `Lesson Blocks` | `Bloques de Lecciones` |
| `boxSessions` | `Sessions` | `Sesiones` |
| `boxSessionsOld` | `Sessions (old)` | `Sesiones (antiguas)` |
| `boxMasteryStates` | `Mastery States` | `Estados de Dominio` |
| `boxQuestionMastery` | `Question Mastery` | `Dominio de Preguntas` |
| `boxQuestionEvals` | `Question Evaluations` | `Evaluaciones de Preguntas` |
| `boxLearningPlans` | `Learning Plans` | `Planes de Aprendizaje` |
| `boxPlanAdherence` | `Plan Adherence` | `Adherencia al Plan` |
| `boxPlanMetrics` | `Plan Metrics` | `Métricas del Plan` |
| `boxMasteryMetrics` | `Mastery Metrics` | `Métricas de Dominio` |
| `boxConversations` | `Conversations` | `Conversaciones` |
| `boxTutorSessions` | `Tutor Sessions` | `Sesiones de Tutoría` |
| `boxTopicDeps` | `Topic Dependencies` | `Dependencias de Temas` |
| `boxSettings` | `Settings` | `Configuración` |
| `boxProfile` | `Profile` | `Perfil` |
| `recordCount` | `{count,plural,=1{1 record} other{{count} records}}` | `{count,plural,=1{1 registro} other{{count} registros}}` |
| `signOutComplete` | `Sign out – Done` | `Cerrar sesión – Hecho` |
| `importFailedWithError` | `Import failed: {error}` | `Importación fallida: {error}` |
| `scheduleTimeLabel` | `Time: {time}` | `Hora: {time}` |
| `scheduleDurationLabel` | `Duration: {duration}` | `Duración: {duration}` |
| `examSessionTitle` | `{mode} – {subject}` | `{mode} – {subject}` |

### Services requiring mandatory `localeName` parameter

| Service | File | Line | Current default | Action |
|---|---|---|---|---|
| `MentorService` | `lib/features/mentor/services/mentor_service.dart` | 79 | `= 'en'` | Remove default, make required |
| `TutorService` | `lib/features/teaching/services/tutor_service.dart` | 58 | `= 'en'` | Remove default, make required |
| `ConversationManager` | `lib/features/teaching/services/conversation_manager.dart` | 44,59 | `= 'en'` | Remove default, make required |
| `ExerciseEvaluator` | `lib/features/teaching/services/exercise_evaluator.dart` | 19 | `= 'en'` | Remove default, make required |
| `Prompts` | `lib/features/teaching/services/prompts/prompts.dart` | 21 | `= 'en'` | Remove default, make required |

---

## Implementation order (recommended)

1. **Phase 1** — Fix MAJOR M3 and M4 (plural ARB keys). Run `flutter gen-l10n`. Update tests.
2. **Phase 2** — Fix MAJOR M1 (validation messages), M2 (box names), M5 (string concatenation).
3. **Phase 3** — Fix MAJOR M6 (service defaults). Remove `= 'en'` from constructors.
4. **Phase 4** — Fix MAJOR M7 (chatbot keywords). Add Spanish keyword arrays.
5. **Phase 5** — Fix MINOR items m1-m12.
6. **Phase 6** — Add test infrastructure for locale switching. Write `es`-locale widget tests.
7. **Phase 7** — Fix MINOR m10 (locale flicker on startup).
