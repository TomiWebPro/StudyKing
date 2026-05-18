# Dry-Run Usability Validation: Non-English (Spanish) User Experience

**Scenario:** `dry-run-test/scenario_non_english_spanish_user.md`
**Persona:** María, a Spanish-speaking student in Mexico City learning IB Chemistry
**Locale tested:** `es` (Spanish), device locale `es_MX`
**Date:** 2026-05-18

---

## Executive Summary

The StudyKing app has excellent localization infrastructure: 100% ARB key parity between English and Spanish, locale-aware number/date formatting throughout the UI, and fully translated onboarding/settings screens. However, **non-English users encounter English text in three critical areas**: (1) all engagement nudges and progress recommendations are always in English, (2) keyword-based state machines in the AI tutor ignore non-English input, and (3) several service-layer components (image analysis, PDF export, backup dialog, topic extraction branching) have hardcoded English. The root cause of the worst failures is architectural: `EngagementScheduler` and all `StudyProgressTracker` instances are created before `runApp()` (or in providers that never pass `l10n`), so `_l10n` is always null.

**Total findings: 7 BLOCKER, 5 MAJOR, 2 MINOR, 1 PARTIAL**

---

## BLOCKER Findings

### B1. Engagement nudges are ALWAYS English (locale ignored)

**Files:** `lib/core/services/engagement_scheduler.dart:297-364`, `lib/main.dart:100-112`

**Problem:** The `EngagementScheduler` is created in `main()` at line 100-112 **before** `runApp()` (line 127). The `l10n` parameter is never passed. The `_l10n` field (line 47: `AppLocalizations? _l10n`) is null for the entire lifetime of the app. All 4 nudge types fall through to English fallback strings:

| Nudge | Line | Fallback |
|---|---|---|
| Overwork warning | 301-304 | `"You have studied $hoursStr hours today..."` |
| Revision reminder | 318-319 | `"It has been $daysSince days since you practiced..."` |
| Plan adjustment | 336-337 | `"You have had $consecutiveLow days of low plan adherence..."` |
| Weekly digest | 357-364 | `"Weekly Digest: $weeklyActivity questions answered..."` |

Additionally, `_l10n` is a `final` field with no setter — even after `runApp()` establishes the locale, there is no way to inject localized strings into the scheduler.

**Acceptance criteria:**
- `EngagementScheduler` must receive `AppLocalizations` (or equivalent locale context) after `runApp()` establishes it
- All 4 nudge types must display in the user's selected locale
- The `_l10n` field should be updatable, or the scheduler should be created after locale is established

---

### B2. Progress recommendations and mastery labels are ALWAYS English

**Files:**
- `lib/core/services/study_progress_tracker.dart:20-28` (constructor), `:170-222` (recommendations), `:265-272` (mastery labels)
- `lib/main.dart:101` (first instance)
- `lib/core/providers/app_providers.dart:302` (`engagementTrackerProvider`)
- `lib/features/dashboard/providers/dashboard_providers.dart:22`
- `lib/features/mentor/providers/mentor_providers.dart:17`
- `lib/core/services/dashboard_service.dart:31`
- `lib/core/services/progress_export_service.dart:28`
- `lib/core/services/badge_service.dart:18`

**Problem:** `StudyProgressTracker` has an `AppLocalizations? _l10n` parameter (line 24) that is **never supplied by any of the 7 production callers**. Every instance has `_l10n = null`. Consequences:

1. **All 8 recommendations are ALWAYS English** (lines 179, 180, 187, 196, 197, 205, 207, 215-216):
   - `_l10n?.recommendAccuracyBelow60 ?? 'Your overall accuracy is below 60%...'`
   - `_l10n?.recommendConsistency ?? 'You studied less than 1 hour total...'`
   - `_l10n?.recommendWeakTopics(...) ?? 'You have ... topic(s) that need improvement...'`

2. **All 5 mastery level labels are ALWAYS English** (lines 266-272):
   - "Novice" instead of "Novato"
   - "Browsing" instead of "Explorando"
   - "Developing" instead of "En desarrollo"
   - "Proficient" instead of "Competente"
   - "Expert" instead of "Experto"

These labels appear in the Dashboard's Mastery Overview card, the Planner's subject progress tabs, and the Mentor's context prompt — the user's locale setting is ignored.

**Acceptance criteria:**
- All 7 `StudyProgressTracker` callers must pass `l10n` from the current locale context
- All 8 recommendations must display in the user's selected locale
- All 5 mastery level labels must display localized strings from ARB keys
- The Dashboard's Mastery Overview must show Spanish labels when locale is `es`

---

### B3. AI Tutor keyword lists are English-only — no non-English input supported

**Files:**
- `lib/features/teaching/services/conversation_manager.dart:154-156` (continue keywords)
- `lib/features/teaching/services/conversation_manager.dart:280` (exercise keywords)

**Problem:** Two hardcoded English-only keyword lists control phase transitions in the AI tutor:

```dart
// Line 155 — adaptive review continue detection
final continueKeywords = ['understand', 'got it', 'i see', 'continue', 'next', 'ok', 'yes'];

// Line 280 — exercise request detection
final exerciseKeywords = ['exercise', 'practice', 'quiz'];
```

Spanish equivalents (Entiendo, Siguiente, Continúa, Sí, Ejercicio, Práctica, Examen) are never matched. The adaptive review phase must time out after 3 exchanges rather than responding to the student's Spanish comprehension signal. Students cannot naturally request exercises in Spanish.

The `localeName` field is available on `ConversationManager` (line 44) but is never used to select locale-appropriate keyword lists.

**Acceptance criteria:**
- Continue keywords must include Spanish equivalents when locale is `es`
- Exercise keywords must include Spanish equivalents when locale is `es`
- Approach should be extensible (not hardcoded if/else per language) — use a map of locale → keyword list
- Unit tests must pass for Spanish keyword detection

---

### B4. Image/handwriting analysis prompt is hardcoded English

**File:** `lib/features/teaching/services/conversation_manager.dart:209-218`

**Problem:** The `processImage()` method sends hardcoded English prompts to the LLM:
```dart
final message = 'The student submitted handwritten work / an image. '
    'Analyze and provide feedback, identifying any errors and suggesting improvements.\n\n'
    '$imageData';
final systemPrompt = 'The student submitted this work. Analyze and provide feedback.';
```

The `localeName` field (line 44) is available but never used. Even though the LLM may respond in Spanish due to conversation history, the analysis instruction is always English.

**Acceptance criteria:**
- `processImage()` must construct locale-appropriate prompts using `localeName`
- The system prompt and user message should be in the user's language
- ARB keys should be added for image analysis prompts

---

### B5. All nudge and recommendation English fallbacks are ALWAYS used

**Combined finding covering B1 and B2 above.** This pattern of `_l10n?.key ?? 'English fallback'` exists in multiple services and is always resolved to English because `_l10n` is always null:

- `EngagementScheduler._l10n` — null (4 fallback paths)
- `StudyProgressTracker._l10n` — null across 7 instances (13 fallback paths: 8 recommendations + 5 mastery labels)
- `BadgeService` — no l10n parameter at all
- `ProgressExportService` — no l10n parameter

**Root cause:** These "background" services are created during the `main()` initialization phase (before `runApp()`), when `AppLocalizations` is not yet available. Providers replicate this pattern.

**Acceptance criteria (in addition to B1 and B2):**
- Audit all services with nullable `_l10n` and ensure they receive localized strings
- Consider a strategy: either defer service creation until after `runApp()`, or make `_l10n` settable post-construction
- `BadgeService` and `ProgressExportService` should also support localization

---

## MAJOR Findings

### M1. Backup dialog shows 20 hardcoded English Hive box names

**File:** `lib/features/settings/presentation/settings_screen.dart:816-838`

**Problem:** The `_boxDisplayName()` method returns hardcoded English names like `'Subjects'`, `'Topics'`, `'Questions'`, `'Lessons'`, etc. in the backup/restore confirmation dialog. A Spanish user sees "Subjects" instead of "Materias".

**Acceptance criteria:**
- Box display names should use localized strings from ARB keys instead of hardcoded English
- Add ARB keys for each box display name (e.g., `backupBoxSubjects: "Materias"`)

---

### M2. PDF export header is hardcoded English

**File:** `lib/core/services/question_pdf_generator.dart:84`

**Problem:** `'Total Questions: ${_questions.length}'` is hardcoded English. Per AGENTS.md: "PDF exports should use the user's locale (they are user-facing documents)."

**Acceptance criteria:**
- PDF generator must accept a locale parameter or `AppLocalizations`
- Header labels must use localized strings

---

### M3. ConversationManager continue/exercise keywords lack locale-awareness

**File:** `lib/features/teaching/services/conversation_manager.dart:44, 154-156, 280`

**Problem:** As described in B3, two critical keyword lists are English-only. While this is a BLOCKER for Spanish users specifically, the structural issue (no locale-based keyword selection) is a MAJOR architectural deficiency.

**Acceptance criteria:** (same as B3)

---

### M4. MentorService topic extraction uses hardcoded `_localeName == 'es'` branch

**File:** `lib/features/mentor/services/mentor_service.dart:265-267, 276-278`

**Problem:** `_extractTopic()` uses:
```dart
final keywords = _localeName == 'es'
    ? Spanish keywords
    : English keywords;
final topicKeywords = _localeName == 'es'
    ? Spanish topic keywords
    : English topic keywords;
```

This pattern requires a new `else if` branch for every added language. Does not scale. A `Map<String, List<String>>` keyed by locale would be extensible.

**Acceptance criteria:**
- Replace if/else with a map-based lookup: `Map<String, List<String>>` keyed by locale
- Add French, German keyword lists (can be minimal initial implementation)
- Unit tests should verify correct keywords are used for each locale

---

### M5. FormatCurrency hardcodes `$` symbol

**File:** `lib/core/utils/number_format_utils.dart:52`

**Problem:** `symbol: '\$'` is always the dollar sign. In Spanish-speaking regions (Mexico, Spain, etc.), users may expect different currency symbols (MX$, €) depending on configuration. The `NumberFormat.simpleCurrency` can infer symbol from locale.

**Acceptance criteria:**
- `formatCurrency` should infer the currency symbol from the locale, or accept a configurable symbol parameter
- Default behavior should use locale-appropriate symbol

---

### M6. English fallback strings in NotificationService

**File:** `lib/core/services/notification_service.dart:200-292`

**Problem:** 22 hardcoded English fallback strings for notification content. While notifications primarily use nudge messages from `EngagementScheduler` (which has its own BLOCKER issue), direct notification calls also fall through to English.

**Acceptance criteria:**
- `NotificationService` should accept locale context or `AppLocalizations`
- All 22 fallback strings should have corresponding ARB keys

---

## MINOR Findings

### m1. `AnswerValidationService` and `QuestionAnswerValidator` default to English

**Files:** 
- `lib/core/services/answer_validation_service.dart:36, 286, 293, 318, 354, 381, etc.`

**Problem:** Every constructor and static method defaults to `ValidationMessages.english` instead of checking the current locale. Currently this only affects the `validateWithMarkscheme()` static method (which is dead code), but any future code path that creates `AnswerValidationService` without passing localized messages will display English validation feedback.

**Acceptance criteria:**
- Consider removing the English default and making the `messages` parameter required
- Or add a runtime locale check that falls back to an appropriate default

---

### m2. Locale flicker on startup when saved locale ≠ device locale

**Files:** 
- `lib/main.dart:153` (initial renders with device locale)
- `lib/main.dart:163` (post-frame callback overrides with saved locale)

**Problem:** On app launch, the first frame renders with the device locale. A `postFrameCallback` then loads the Hive profile and overrides to the saved locale. If these differ, there's a visible 1-frame flicker.

**Acceptance criteria:**
- Move locale initialization to be synchronous from Hive (Hive is already open by this point)
- Or use a splash/loading screen that resolves the locale before rendering the main UI

---

### m3. `formatCurrency` locale-awareness gap

**File:** `lib/core/utils/number_format_utils.dart:45-61`

**Problem:** (repeated from M5 — kept here as minor since it's cosmetic)

---

## PARTIAL Findings

### P1. Spanish locale startup detection works for same-locale persistence

**Files:** `lib/core/providers/app_providers.dart:283-295`, `lib/main.dart:153-163`

**Detail:** When the device locale is Spanish and no saved profile exists, the first launch correctly renders in Spanish. When the saved language matches the device locale, there is no flicker on subsequent launches. Only cross-locale persistence (saved language ≠ device locale) causes the flicker.

---

## Previously Reported but VERIFIED

| Finding | Status |
|---|---|
| Onboarding dialog fully localized | VERIFIED PASS |
| API Key banner localized | VERIFIED PASS |
| Bottom navigation labels localized | VERIFIED PASS |
| Number formatting locale-aware | VERIFIED PASS |
| Language selector shows localized names | VERIFIED PASS |
| Language switching is immediate | VERIFIED PASS |
| Mentor Spanish intent detection works | VERIFIED PASS |
| Mentor Spanish topic extraction works | VERIFIED PASS |
| `ValidationMessages.fromLocalizations()` IS called (2 callers) | VERIFIED — corrected from earlier draft |
| Practice/exam validation IS localized | VERIFIED PASS |
| `EngagementScheduler.updateSettings()` never reads notification prefs | CONFIRMED from scenario_focus_mode_daily_habit |
