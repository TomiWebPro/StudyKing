# Dry-Run Scenario: Using StudyKing as a Spanish Speaker — Complete i18n Journey

## Persona

Soy María, una estudiante de secundaria en la Ciudad de México. Hablo español como lengua materna. Quiero aprender Química IB para prepararme para la universidad. Mi dispositivo está configurado en español (es_MX). No hablo inglés con fluidez. Espero que StudyKing funcione completamente en español — desde los menús hasta las explicaciones del tutor AI y los mensajes de validación.

---

## Step 1: First Launch — System Locale Auto-Detection

My phone is set to Spanish (México). I install and open StudyKing for the first time.

**What I expect:** The app detects my device locale (`es_MX`) and displays everything in Spanish from the very first screen. The onboarding dialog shows Spanish text: "Bienvenido a StudyKing" with descriptions in Spanish.

**What actually happens:**

The `localeProvider` in `app_providers.dart:283-295` checks the device locale against `AppLocalizations.supportedLocales`. The supported locales are `[Locale('en'), Locale('es')]`. My device locale is `es_MX` — the `languageCode` is `'es'`, which matches supported locale `Locale('es')`. So the initial locale is correctly set to Spanish ✓.

However, on first launch there is no saved profile yet. The `postFrameCallback` at `main.dart:157-163` loads the profile and overrides the locale. Since no profile exists, `profileResult.isSuccess` might still be true (returning a default profile with empty `language`), and `profile.language.isNotEmpty` is false, so the override is skipped. The locale stays at the initial device-detected value.

**But there's a subtle problem:** The locale is initialized in `localeProvider` at app build time (`main.dart:153`: `final locale = ref.watch(localeProvider)`). At this point `AppLocalizations.of(context)` is called at line 184 for the title and at `MainScreen.build()` for `l10n`. If the locale hasn't been resolved yet by `MaterialApp`'s `localeResolutionCallback`, these first calls might use the default fallback (English).

Actually, the `localeProvider` value is `Locale('es')` (correctly detected), and `MaterialApp`'s `locale:` parameter receives it. The `supportedLocales` and `localeResolutionCallback` handle the `es_MX` → `es` mapping. So the first frame should be in Spanish. ✓

**But wait** — after the profile loads (which happens on the very first launch), the profile has no saved language preference (since this is a new user), so the locale doesn't change. On *subsequent* launches, the profile WILL have a language preference (saved on first use). 

**Verdict: PASS** — First launch correctly detects Spanish device locale. No startup flicker on first launch (there IS a flicker on subsequent launches when the saved locale differs from device locale, but for first launch it's fine).

---

## Step 2: The Onboarding Dialog — Fully Spanish

The onboarding dialog appears. I read it carefully.

**What I expect:** Everything in Spanish — the welcome text, feature descriptions, the API key notice, the "Get Started" and "Quick Guide" buttons.

**What actually happens:** The onboarding dialog (`onboarding_dialog.dart:26-109`) uses `l10n.*` throughout:
- `l10n.welcomeToStudyKing` → "¡Bienvenido a StudyKing!" ✓
- `l10n.onboardingDescription` → Spanish description ✓
- `l10n.onboardingSubjectsDesc`, `onboardingPracticeDesc`, etc. → All Spanish ✓
- `l10n.needApiKeyNotice` → "Necesitarás una clave API..." ✓
- `l10n.getStarted` → "Comenzar" ✓
- `l10n.quickGuide` → "Guía Rápida" ✓

The `ApiKeyBanner` (`onboarding_dialog.dart:140-178`) also uses `l10n.apiKeyNeeded` → "Se necesita una clave API" and `l10n.configureNow` → "Configurar ahora" ✓.

The `LocalDataNotice` uses `l10n.dataStorageNotice` and `l10n.dataStorageDescription` — both localized ✓.

**Verdict: PASS** — Onboarding is fully localized in Spanish.

---

## Step 3: API Key Missing Banner — Spanish

I dismiss the onboarding. I see a yellow-orange banner at the top: "Se necesita una clave API" with buttons "Configurar ahora" and "Descartar".

**What I expect:** The banner text and buttons are in Spanish since my locale is Spanish.

**What happens:** The `ApiKeyBanner` uses `l10n.apiKeyNeeded`, `l10n.configureNow`, `l10n.dismiss` — all correctly localized. ✓

I tap "Configurar ahora" and navigate to the API configuration screen in Spanish. ✓

**Verdict: PASS**

---

## Step 4: Bottom Navigation — Spanish Labels

The main screen has 6 tabs in the bottom navigation or navigation rail.

**What I expect:** The tab labels to be in Spanish: "Tablero", "Materias", "Práctica", "Mentor", "Enfoque", "Ajustes".

**What happens:** The `MainScreen.build()` at `main.dart:355` uses `l10n.dashboard`, `l10n.subjects`, `l10n.practice`, `l10n.mentor`, `l10n.focusMode`, `l10n.settings` — all correctly localized through ARB keys. ✓

**Verdict: PASS**

---

## Step 5: Dashboard Metric Cards — Number Formatting with Spanish Locale

I look at the Dashboard. Everything is empty (no data yet), but the card titles are in Spanish. ✓

After a few days of practice, I check my stats. I've answered 85 out of 120 questions correctly. My accuracy is 70.8%.

**What I expect:** Accuracy shown with comma decimal separator: "70,8%" (Spanish convention), not "70.8%" (English convention). Study time shown with Spanish locale: "12,5 horas".

**What happens:** The Dashboard and all stat displays use `formatPercent(value, l10n.localeName)` and `formatDecimal(value, l10n.localeName)` from `number_format_utils.dart`. The `localeName` for Spanish is `'es'`. The `NumberFormat` from the `intl` package will use comma as decimal separator for `es` locale. ✓

Similarly, `formatHours()` and `formatCompactNumber()` all use locale-aware formatting. ✓

**But the Subject Detail screen's Stats tab:** Does it use `number_format_utils.dart` or `toStringAsFixed()`? The only known `toStringAsFixed()` UI usage is in `topic_dependency_dialog.dart:119,129` for syllabus weight display — which uses English-format decimals even in Spanish mode.

**Verdict: PASS** for Dashboard formatting. Subject detail's topic dependency dialog has a MINOR issue with English decimal format.

---

## Step 6: Navigating to Settings — Changing Locale in Profile

I go to Settings → I look for language settings.

**What I expect:** A "Language" option in the Settings screen where I can see and change the language. The display name of each language should be in its own language (English → "English", Español → "Español").

**What happens:** I find the Profile screen (`profile_screen.dart`). The language selector at lines 479-504 shows:
- A `ListTile` with title "Idioma" (language in Spanish ✓)
- A `DropdownButton` with items: "English" and "Español"

The display names use `appLocale.localizedLabel(l10n)` which returns `l10n.localeEn` ("Inglés") and `l10n.localeEs` ("Español") — the ARB keys provide the localized language names. So the dropdown shows:
- "Inglés" (English, written in Spanish)
- "Español" (Spanish, written in Spanish)

**Verdict: PASS** — Language labels are correctly localized.

---

## Step 7: Switching Language to English and Back

I change the language from "Español" to "Inglés" and back.

**What I expect:** The UI immediately changes to English when I select it, and back to Spanish when I select Español. The change should be saved and persist after restart.

**What happens:** The dropdown's `onChanged` at line 498-500 calls `ref.read(localeProvider.notifier).state = Locale(value)` — the locale is updated immediately, causing `MaterialApp` to rebuild with the new locale. ✓

The language is saved to the profile at save time (line 128: `language: _language`). On restart, `main.dart:162-163` loads the profile and sets the locale. ✓

**But there's a visible flicker on restart:** The `localeProvider` initializes with the device locale (`es`) synchronously. Then in a `postFrameCallback`, the profile loads and changes to saved locale. If I saved "English", the first frame renders in Spanish, then flickers to English one frame later. This is a 1-frame locale flicker.

**Verdict: PASS** for live switching. PARTIAL for startup — there's a 1-frame locale flicker on subsequent launches.

---

## Step 8: Using the Mentor in Spanish — Context Prompt

I tap the Mentor tab. The mentor greets me in Spanish: "¡Hola! Soy tu mentor de estudio..." The chat input says "Pregunta al mentor lo que sea...".

**What I expect:** The Mentor understands Spanish queries, responds in Spanish, and the context prompt includes my study data with Spanish labels.

**What happens:** The `MentorService` constructor receives `localeName: 'es'` from the provider that reads `localeProvider`. The `_mentorSystemPrompt()` at line 258-261 uses `lookupAppLocalizations(Locale(_localeName)).mentorSystemPrompt` — which is the Spanish system prompt. ✓

The `_buildContextPrompt()` at lines 155-256 uses `l10n.mentorBulletPoint` for bullet formatting. The context data labels (line 170 comments confirm) are in invariant English: "Current student context:", "Total attempts:", etc. This is stated to be intentional — the LLM receives English data regardless of locale. The LLM is instructed (via `_languageInstruction` in `prompts.dart:25-28`) to respond in the student's language. So the mentor WILL respond in Spanish even though the internal data labels are in English. ✓

I type: "¿Cómo voy en mis estudios?" — the Mentor responds in Spanish with my stats. ✓

**Verdict: PASS**

---

## Step 9: Scheduling a Lesson Through the Mentor in Spanish

I type: "¿Puedes programar una lección de química orgánica?"

**What I expect:** The Mentor detects my scheduling intent (the Spanish word "programar") and helps me schedule. It responds in Spanish.

**What happens:** `_checkAndHandlePlanningIntent()` at `mentor_service.dart:454-477` checks:
```dart
final hasScheduleIntent = lower.contains('schedule') ||
    lower.contains('reschedule') ||
    lower.contains('programar') ||    // ✓
    lower.contains('reprogramar') ||  // ✓
    lower.contains('agendar') ||      // ✓
    lower.contains('reagendar') ||    // ✓
    lower.contains('citar');          // ✓
```

"programar" is explicitly in the Spanish keyword list. `hasScheduleIntent` is true. ✓

`_extractTopic()` at lines 263-288 checks `_localeName == 'es'` and uses Spanish keywords:
- `['sobre ', 'para ', 'de ', 'estudiar ', 'aprender ', 'repasar ', 'practicar ', 'acerca de ', 'acerca ']`
- `['tema ', 'materia ', 'lección ', 'asignatura ']`

For "¿Puedes programar una lección de química orgánica?":
- After removing "programar" (moved past in the schedule check), the remaining text "una lección de química orgánica" hits keyword "de " → extracts "química orgánica" ✓

**Verdict: PASS** — The Mentor's Spanish intent detection works correctly. The combination of Spanish keywords in `_checkAndHandlePlanningIntent` and `_extractTopic` (which has a hardcoded `_localeName == 'es'` branch) handles Spanish scheduling requests.

**But there's a design concern:** The `_extractTopic` method uses a hardcoded `_localeName == 'es'` branch. This pattern doesn't scale. If a third language (e.g., French, German) were added, each would need its own `else if` branch with hardcoded keywords. This is a maintainability issue, not a correctness issue for Spanish.

**Verdict (Spanish): PASS. Maintainability: MINOR FAIL.**

---

## Step 10: The AI Tutor in Spanish — Keyword Detection Problem

I attend a tutor lesson on "Estructura Atómica". The tutor greets me in Spanish. ✓

**What I expect:** During the lesson, when I say "Entiendo" (I understand) or "siguiente" (next), the tutor recognizes these as "continue" signals and moves on. When I say "ejercicio" or "práctica", the tutor transitions to exercise mode.

**What actually happens (two problems):**

**Problem 10A: Continue keywords are English-only.**

In `conversation_manager.dart:154-156`:
```dart
final lower = content.toLowerCase();
final continueKeywords = ['understand', 'got it', 'i see', 'continue', 'next', 'ok', 'yes'];
if (continueKeywords.any((k) => lower.contains(k))) {
```

When I say "Entiendo" or "Siguiente" or "Continúa" or "Sí" during adaptive review, the lowercased Spanish text is checked against English keywords. None of the Spanish equivalents match. The adaptive review phase doesn't exit based on my input — it only exits after 3 exchanges (line 160: `_adaptiveReviewExchanges >= 3`). My Spanish "continue" signals are completely ignored.

**Problem 10B: Exercise detection keywords are English-only.**

In `conversation_manager.dart:280`:
```dart
final exerciseKeywords = ['exercise', 'practice', 'quiz'];
```

When I say "¿Podemos hacer un ejercicio?" or "Quiero practicar", the keywords don't match. Damn — actually wait, looking at this more carefully, the exercise transition happens during conversation: the AI asks if the student wants to practice, the student says yes. The English keywords are about the student *requesting* an exercise. In practice, the AI will say "¿Te gustaría hacer un ejercicio?" and I'll say "Sí" — but "Sí" doesn't match any keyword.

The transition to exercise phase is primarily initiated by the AI tutor (via `transitionToExercise()`), not by the student's keyword. But if the language instruction in the system prompt tells the LLM to speak Spanish, the LLM will naturally use Spanish phrases like "¿Quieres practicar con un ejercicio?" — and when I respond "Sí", the keyword check fails.

Actually, looking at line 278-286 more carefully:
```dart
void _detectExerciseRequest(String content) {
    final lower = content.toLowerCase();
    final exerciseKeywords = ['exercise', 'practice', 'quiz'];
    if (exerciseKeywords.any((k) => lower.contains(k))) {
      _logTransition(phase, ConversationPhase.exercise, 'keyword detected in student message');
      phase = ConversationPhase.exercise;
      _pendingExerciseQuestionCapture = true;
    }
  }
```

This is called AFTER the response is streamed (line 197: `_detectExerciseRequest(content)` — where `content` is the *student's* input message, not the AI response). Wait, let me re-read the flow:

```dart
Stream<String> sendMessage(String content) async* {
    _memory.addUserMessage(content);  // content = student's message
    // ... phase transitions based on content ...
    // ... AI response streaming ...
    _detectExerciseRequest(content);  // content is still the student's message
}
```

So `_detectExerciseRequest(content)` checks the STUDENT'S message, not the AI's. If the student says "Quiero un ejercicio" — the English keywords won't match "ejercicio". The student can explicitly say "exercise" (English) and it would work, but the Spanish equivalent doesn't.

**Verdict: FAIL (MAJOR)** — Two critical keyword lists in `ConversationManager` are English-only. Spanish-speaking students cannot naturally use their language for "continue" and "exercise" signals during AI tutor sessions. The adaptive review phase will time out rather than respond to student comprehension signals.

---

## Step 11: Answer Validation — Practice and Exam Sessions Are Localized, But Default Falls Back to English

During a practice session, I answer a typed question. I get the answer wrong.

**What I expect:** The feedback message is in Spanish: "Incorrecto. La respuesta correcta es: 1,67 × 10⁻²⁷ kg"

**What actually happens:** Tracing through the code:

**Good news — practice and exam sessions ARE localized:**
- `practice_session_screen.dart:94-96` creates `AnswerValidationService(messages: ValidationMessages.fromLocalizations(AppLocalizations.of(context)!))` — passes localized Spanish messages ✓
- `exam_session_screen.dart:80-82` does the same ✓

So during normal practice and exam sessions, validation feedback IS shown in Spanish. ✓

**But the default falls back to English everywhere else:**
- `AnswerValidationService` constructor default: `_messages = messages ?? ValidationMessages.english` (line 36)
- `QuestionAnswerValidator` constructor default: `_messages = messages ?? ValidationMessages.english` (line 286)
- Every `static validate*` method default: `final msgs = messages ?? ValidationMessages.english` (lines 293, 318, 354, etc.)

If ANY component besides the practice/exam screens creates an `AnswerValidationService` without passing localized messages (e.g., a hypothetical quiz widget, a widget test, a future feature), it will show English validation messages. The default is English-hardcoded with no runtime locale check.

The `validateWithMarkscheme()` static method (line 57) also defaults to `ValidationMessages.english` — though it's currently dead code (never called from production).

**Verdict: PASS** for practice and exam sessions. **PARTIAL** — the default is English-hardcoded, which could affect future components or non-standard validation paths.

---

## Step 12: Image Processing — Hardcoded English Prompt

During a tutor lesson, I submit a photo of my handwritten work (common in Latin American classrooms where paper homework is still the norm).

**What I expect:** The AI tutor describes the image analysis in Spanish.

**What actually happens:** In `conversation_manager.dart:209-218`:
```dart
final message = 'The student submitted handwritten work / an image. '
    'Analyze and provide feedback, identifying any errors and suggesting improvements.\n\n'
    '$imageData';

final buffer = StringBuffer();
await for (final chunk in _llmService.chatStream(
    message: message,
    modelId: _modelId,
    memory: _memory,
    systemPrompt: 'The student submitted this work. Analyze and provide feedback.',
)) {
```

Both the user message and system prompt are hardcoded in English. The `localeName` is available on the `ConversationManager` (line 44: `String localeName = 'en'`) but is never used in the `processImage` method. Even though the LLM might choose to respond in Spanish due to conversation history, the analysis instruction itself is English-only.

**Verdict: FAIL (MAJOR)** — The image analysis prompt is hardcoded English. A Spanish-speaking student submitting handwritten work gets English analysis instructions sent to the LLM.

---

## Step 13: Engagement Nudges — Always English (Root Cause: Pre-runApp Creation)

After a few days, I start getting notifications from the app.

**What I expect:** Nudge messages in Spanish: "¡Vamos! Has estudiado $hoursStr horas hoy. ¡Considera tomar un descanso!"

**What actually happens — and why it's ALWAYS English:**

The `EngagementScheduler` is created in `main()` at `main.dart:100-112` — **before** `runApp(StudyKingApp())` at line 127. Since `AppLocalizations` doesn't exist until `MaterialApp` is built, **no `l10n` parameter is passed**:
```dart
final schedulerRef = EngagementScheduler(
    tracker: StudyProgressTracker(/* no l10n */),
    // ... no l10n parameter at all (main.dart:100-112)
);
```

The `_l10n` field in `EngagementScheduler` is `null` (line 47: `final AppLocalizations? _l10n` — defaults to null since `l10n` is not passed).

Consequently, EVERY nudge falls through to the English fallback:
- `_l10n?.nudgeOverwork(hoursStr) ?? 'You have studied $hoursStr hours today...'` — ALWAYS the English fallback (line 301-304)
- `_l10n?.nudgeRevision(daysSince, state.topicId) ?? 'It has been $daysSince days since you practiced...'` — ALWAYS English (line 318-319)
- `_l10n?.nudgePlanAdjustment(consecutiveLow) ?? 'You have had $consecutiveLow days...'` — ALWAYS English (line 336-337)
- `_l10n?.nudgeWeeklyDigest(...) ?? 'Weekly Digest: ...'` — ALWAYS English (line 357-364)

Furthermore, `EngagementScheduler._l10n` is a **final field** with no setter — even after `runApp()` and the locale is established, there is no way to inject the localized strings. The scheduler is stuck with English forever.

**Verdict: FAIL (BLOCKER)** — All 4 nudge types (overwork warning, revision reminders, plan adjustment nudges, weekly digest) are ALWAYS in English regardless of user locale, because `EngagementScheduler` is created before `runApp()` with no `l10n` parameter, and has no mechanism to receive localized strings later.

## Step 14: Progress Recommendations — Always English (Systemic Issue)

I check the Dashboard for recommendations.

**What I expect:** Recommendation messages in Spanish: "Tu precisión general está por debajo del 60%. Concéntrate en repasar conceptos fundamentales."

**What actually happens — this is a systemic issue:**

Every single `StudyProgressTracker` in production code is created **without** the `l10n` parameter:

| File | Line | Tracker |
|------|------|---------|
| `main.dart` | 101 | EngagementScheduler's tracker |
| `app_providers.dart` | 302 | `engagementTrackerProvider` |
| `dashboard_providers.dart` | 22 | `dashboardStudyProgressTrackerProvider` |
| `mentor_providers.dart` | 17 | `mentorProgressTrackerProvider` |
| `dashboard_service.dart` | 31 | Dashboard service |
| `progress_export_service.dart` | 28 | Export service |
| `badge_service.dart` | 18 | Badge service |

All 7 instances have `_l10n = null`. The `l10n` parameter exists on the constructor at `study_progress_tracker.dart:24` but is **never supplied by any caller**.

Consequences for Spanish-speaking users:

**All 8 recommendations are ALWAYS English:**
- `_l10n?.recommendAccuracyBelow60 ?? 'Your overall accuracy is below 60%...'` → English (line 179)
- `_l10n?.recommendReviewBasics ?? 'Review basic topics before advancing'` → English (line 180)
- `_l10n?.recommendConsistency ?? 'You studied less than 1 hour total...'` → English (line 196)
- `_l10n?.recommendNoActivity ?? 'No study activity this week...'` → English (line 205)
- `_l10n?.recommendWeakTopics(...) ?? 'You have ... topic(s) that need improvement...'` → English (line 215-216)

**All 5 mastery level labels are ALWAYS English:**
- "Novice" instead of "Novato"
- "Browsing" instead of "Explorando"
- "Developing" instead of "En desarrollo"
- "Proficient" instead of "Competente"
- "Expert" instead of "Experto"

These labels appear in the Dashboard's Mastery Overview card AND in the Planner's subject progress tabs — the user's locale setting has no effect.

**Verdict: FAIL (BLOCKER)** — This is a systemic issue affecting all 7 `StudyProgressTracker` instances. The `l10n` parameter is defined but never passed. All Dashboard recommendations, mastery level labels, and progress suggestions are ALWAYS displayed in English regardless of the user's locale. Spanish-speaking users see "Novice" on their dashboard — a label that means nothing to a non-English speaker.

---

## Step 14: Settings Screen — English Hive Box Names in Backup Dialog

I go to Settings → Backup & Restore → I see the import/export dialog listing my data boxes.

**What I expect:** Box names in Spanish: "Materias", "Temas", "Preguntas", etc.

**What actually happens:** The `_boxDisplayName()` method at `settings_screen.dart:816-838` returns 20 hardcoded English box names:
- `'Subjects'`, `'Topics'`, `'Questions'`
- `'Lessons'`, `'Sessions'`, `'Mastery'`
- `'Conversations'`, `'Pending Actions'`
- etc.

These are displayed in the backup/restore confirmation dialog regardless of the user's locale.

**Verdict: FAIL (MAJOR)** — Backup dialog shows English box names in a Spanish-speaking user's session.

---

## Step 15: PDF Export — English Header

I generate a PDF study report.

**What I expect:** The PDF title and metadata are in Spanish: "Informe de Estudio - Química IB".

**What actually happens:** The `question_pdf_generator.dart:84` has:
```dart
'Total Questions: ${_questions.length}'
```

This hardcoded English string appears in the generated PDF regardless of locale.

**Verdict: FAIL (MAJOR)** — PDF export has hardcoded English header text. User-facing PDFs should use the user's locale (per AGENTS.md conventions).

---

## Step 16: RTL Readiness — Not Applicable for Spanish

Spanish is LTR, so the 14 non-flipping chevron icons don't cause problems. However, if a RTL language (Arabic) were added in the future, all these icons would need to be updated.

**Verdict: PASS** (not applicable, but noted for future)

---

## Step 17: Locale Persistence Across Restart

I close the app and reopen it the next day.

**What I expect:** The app is still in Spanish.

**What happens:** On second launch:
1. `localeProvider` initializes with device locale `es` (synchronous, correct)
2. `MaterialApp` builds with `locale: Locale('es')` — first frame in Spanish
3. `postFrameCallback` runs:
   - Loads profile (Hive read, async)
   - Profile has `language: 'es'` from yesterday's save
   - `ref.read(localeProvider.notifier).state = Locale('es')` → same locale, no change

No flicker on second launch because the saved locale matches the device locale.

But what if I saved "English" on my Spanish-device phone? Then:
1. First frame: `Locale('es')` (from device)
2. Post-frame callback: changes to `Locale('en')`
3. Frame 2: English

This is a visible 1-frame flicker from Spanish → English on every app launch.

**Verdict: PASS** for same-locale persistence. PARTIAL for cross-locale persistence (flicker issue already known).

---

## Step 18: Creating and Reviewing an Exportable Report

I want to share my study report in Spanish.

**What I expect:** The Session History screen shows Spanish date formats (e.g., "18 de mayo de 2026"), Spanish labels on all columns, and the PDF/CSV exports use Spanish headers.

**What happens:** The Session History is unreachable (known blocker from previous scenarios). But the date format in other parts of the app uses `DateFormat.yMd(l10n.localeName)` which for `es` locale produces "18/5/2026" — a period format. ✓

The Session History's export functionality would likely use the locale-aware formatting... but since the screen is unreachable, I can't verify this.

**Verdict: PARTIAL** (inaccessible screen blocks full verification)

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | First launch auto-detects Spanish locale | Correctly detected from device locale | PASS |
| 2 | Onboarding dialog shows Spanish text | All `l10n.*` keys used throughout | PASS |
| 3 | API Key banner is Spanish | `apiKeyNeeded`, `configureNow` localized | PASS |
| 4 | Bottom navigation labels are Spanish | `l10n.subjects` = "Materias", etc. | PASS |
| 5 | Number formatting uses comma decimals | `number_format_utils.dart` uses locale | PASS |
| 6 | Language selector shows localized names | "Inglés" / "Español" correctly | PASS |
| 7 | Language switching is immediate and persists | Immediate rebuild; persists in Hive profile | PASS |
| 8 | Language persistence has no flicker | 1-frame flicker when saved ≠ device locale | PARTIAL |
| 9 | Mentor responds in Spanish and processes Spanish intents | Spanish system prompt; Spanish keywords in intent detection and topic extraction | PASS |
| 10A | "Continue" keywords work in Spanish during tutor lesson | `['understand', 'got it', ...]` — English only | **FAIL (MAJOR)** |
| 10B | "Exercise/practice" detection works in Spanish | `['exercise', 'practice', 'quiz']` — English only | **FAIL (MAJOR)** |
| 11 | Answer validation messages are Spanish in practice/exam | `fromLocalizations()` called in practice and exam screens — localized | PASS |
| 12 | Answer validation defaults are Spanish for other paths | Constructor defaults to `ValidationMessages.english` | PARTIAL |
| 13 | Image/handwriting analysis prompt is Spanish | Hardcoded English in `processImage()` (conversation_manager.dart:209-211) | **FAIL (MAJOR)** |
| 14 | Engagement nudges are Spanish | `_l10n` is null because `EngagementScheduler` created before `runApp()` — ALWAYS English fallback | **FAIL (BLOCKER)** |
| 15 | Progress recommendations and mastery labels are Spanish | `_l10n` is null in ALL 7 `StudyProgressTracker` instances — ALWAYS English | **FAIL (BLOCKER)** |
| 16 | Backup dialog box names are Spanish | 20 hardcoded English Hive box names in `_boxDisplayName()` | **FAIL (MAJOR)** |
| 17 | PDF export header is Spanish | `'Total Questions: ...'` hardcoded English | **FAIL (MAJOR)** |
| 18 | `_extractTopic` Spanish branch is scalable | Hardcoded `_localeName == 'es'` if/else — doesn't scale to new languages | MINOR |
| 19 | `formatCurrency` symbol respects locale | Always hardcoded `$` regardless of locale | MINOR |
| 20 | All `StudyProgressTracker` instances receive l10n | Zero out of 7 pass the `l10n` parameter | **FAIL (BLOCKER)** |
