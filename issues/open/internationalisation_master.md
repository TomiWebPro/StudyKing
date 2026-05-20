# Internationalisation Master — Full-Codebase i18n Audit (Round 2)

**Audit date:** 2026-05-20
**Scope:** `lib/`, `lib/l10n/` (all Dart and ARB files)
**Target locale:** Spanish (`es`) — patterns apply to all future locales.
**Severity key:** BLOCKER = crash/inability to proceed; MAJOR = feature broken or misleading; MINOR = code quality / UX friction.
**Previous round:** `issues/completed/internationalisation_master.md` — many items from Round 1 are now fixed (M1–M5, m2, m6). This round documents newly discovered issues and recurring patterns.

---

## BLOCKER

### B1 — `DateFormat.Hm` forced 24-hour time in 3 files (4 call sites)

`DateFormat.Hm` always produces 24-hour format (e.g. `"14:30"`) regardless of the user's locale preference. A Spanish user sees `"14:30"` instead of locale-respecting `"2:30 p. m."`. `DateFormat.jm` respects the locale (12h for `en`, 24h for `es`, etc.).

| File | Line | Code |
|---|---|---|
| `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` | 122 | `DateFormat.Hm(l10n.localeName).format(s.startTime)` |
| `lib/features/planner/presentation/planner_screen.dart` | 1164 | `DateFormat.Hm(l10n.localeName).format(lesson.startTime)` |
| `lib/features/planner/presentation/planner_screen.dart` | 1212 | `DateFormat.Hm(l10n.localeName).format(lesson.startTime)` |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | 398 | `DateFormat.Hms(l10n.localeName).format(dt)` |

**Note:** `main.dart:561` (orphaned-session dialog) was already fixed in Round 1 — `DateFormat.jm` is used there.

**Rationale:** Every user on every screen that displays a lesson/session time sees an invariant 24-hour clock. `es` users expect `"2:30 p. m."` for afternoon times.

**Fix:** Replace `DateFormat.Hm()` with `DateFormat.jm()` (locale-aware). For `Hms`, implement a locale-aware alternative or use `DateFormat.jm()` without seconds for user display.

---

## MAJOR

### M1 — Hardcoded `'en'` locale defaults in service/tool constructors (12 files, 16+ call sites)

Many core services and AI tool constructors default their `localeName` parameter to `'en'`. When a code path omits the locale parameter, services silently produce English content — even when the UI is set to Spanish.

| File | Line | Code |
|---|---|---|
| `lib/features/ingestion/services/content_pipeline.dart` | 49 | `String localeName = 'en'` |
| `lib/features/ingestion/services/document_extractor.dart` | 36 | `String localeName = 'en'` |
| `lib/features/lessons/services/lesson_agent_service.dart` | 38 | `String localeName = 'en'` |
| `lib/features/lessons/services/lesson_agent_service.dart` | 272 | `String localeName = 'en'` |
| `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` | 10 | `String localeName = 'en'` |
| `lib/features/mentor/services/tools/create_plan_tool.dart` | 10 | `String localeName = 'en'` |
| `lib/features/mentor/services/tools/schedule_lesson_tool.dart` | 10 | `String localeName = 'en'` |
| `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` | 43 | `localeName: (args['localeName'] as String?) ?? 'en'` |
| `lib/features/teaching/services/tutor_service.dart` | 50 | `String _localeName = 'en'` |
| `lib/features/teaching/services/prompts/prompts.dart` | 26 | `ConversationPromptSet(localeName: 'en')` (per AGENTS.md: overridden at call sites) |
| `lib/core/data/extraction/ocr_extractor.dart` | 31 | `String localeName = 'en'` |
| `lib/core/data/extraction/transcription_extractor.dart` | 39 | `String localeName = 'en'` |
| `lib/core/services/llm/llm_chat_service.dart` | 314, 356 | `String localeName = 'en'` |

**Rationale:** These are ticking time bombs. Any future refactor that forgets to pass the locale will silently produce English LLM prompts, English extraction results, or English lesson content. Spanish users would see English AI-generated text even with a Spanish UI.

**Fix:** Remove the default value from the parameter (require locale at every call site). Add a lint rule or test that asserts locale is always provided.

---

### M2 — Hardcoded `Locale('en')` fallbacks in providers (7 files)

Providers that watch `l10nProvider` (nullable) fall back to English when the locale is not yet loaded:

| File | Line | Code |
|---|---|---|
| `lib/core/providers/app_providers.dart` | 40 | `lookupAppLocalizations(const Locale('en'))` |
| `lib/core/providers/app_providers.dart` | 87 | `lookupAppLocalizations(const Locale('en'))` |
| `lib/core/providers/study_progress_provider.dart` | 11 | `lookupAppLocalizations(const Locale('en'))` |
| `lib/core/providers/shared_providers.dart` | 148 | `return const Locale('en')` (device locale resolution fallback) |
| `lib/features/dashboard/providers/dashboard_providers.dart` | 14 | `lookupAppLocalizations(const Locale('en'))` |
| `lib/features/dashboard/services/dashboard_service.dart` | 40 | `lookupAppLocalizations(const Locale('en'))` |
| `lib/features/mentor/providers/mentor_providers.dart` | 23 | `lookupAppLocalizations(const Locale('en'))` |
| `lib/main.dart` | 208 | `lookupAppLocalizations(const Locale('en'))` |

**Rationale:** When `l10nProvider` is `null` (during early startup or provider initialization race), the fallback silently uses English. The impact varies:
- `shared_providers.dart:148` — device locale detection fallback (low risk, only fires when OS locale can't be detected)
- `app_providers.dart:40,87` — tracker/scheduler initialization uses English until localeProvider emits
- `dashboard_providers.dart:14` — dashboard uses English stats labels until locale resolves

**Fix:** Instead of checking `l10n ?? defaultL10n` in every provider, ensure `l10nProvider` is initialised before any dependent providers are read. Use `ref.watch(localeProvider)` to derive locale without l10n dependency.

---

### M3 — `settings_model.dart` `priceDisplay` and `formattedText` getters default to `'en'`

**Files:**
- `lib/features/settings/data/models/settings_model.dart:118` — `priceDisplay => priceDisplayWithLocale('en')`
- `lib/features/settings/data/models/settings_model.dart:125` — `formattedText => formattedTextWithLocale('en')`

**Problem:** Both getters have `@Deprecated` annotations directing callers to use locale-aware variants. However, they are still referenced (e.g. in `toString()` at line 134). If the deprecation period ends and they remain as working getters, any caller that misses the deprecation will produce invariant English.

**Rationale:** Usage records and price displays appear in the settings screen and logs. A Spanish user sees `$1.2345` with a period decimal separator and `en` currency formatting.

**Fix:** Remove the deprecated getters and fix the `toString()` method to require a locale parameter or use the stored locale.

---

### M4 — Hardcoded English rendering in `topic_detail_screen.dart` (2 issues)

**File:** `lib/features/dashboard/presentation/screens/topic_detail_screen.dart`

**M4a — Raw error display (line 53):**
```dart
error: (e, _) => Center(child: Text('$e')),
```
Error text is rendered directly to the user. Exception messages are typically in English regardless of locale.

**M4b — Hardcoded colon formatting (line 285):**
```dart
Text('$label: ', ...)
```
Assumes English punctuation (colon appended directly). In Spanish, colons should mirror the same usage, but this pattern is fragile if label already contains punctuation.

**Rationale:** M4a exposes raw English error messages to Spanish users. M4b is a minor formatting concern but creates inconsistency if labels vary.

**Fix:** M4a: Use `l10n.errorLoadingTopic(e)` or similar ARB key. M4b: Use l10n key that includes the colon, e.g. `l10n.infoRowFormat(label, value)`.

---

### M5 — Keyword fallbacks for mentor and conversation services default to `['en']`

Mentor keyword extraction and conversation phase detection fall back to English keyword lists when the user's locale has no entry:

**File:** `lib/features/mentor/services/mentor_service.dart`
- Line 267: `MentorKeywords.extractKeywordsByLocale[_localeName] ?? MentorKeywords.extractKeywordsByLocale['en']!`
- Line 276: `MentorKeywords.extractTopicKeywordsByLocale[_localeName] ?? MentorKeywords.extractTopicKeywordsByLocale['en']!`
- Lines 317–319: Same pattern for `scheduleKeywords`, `planKeywords`, `rescheduleKeywords`

**File:** `lib/features/teaching/services/conversation_manager.dart`
- Line 362: `_continueKeywordsByLocale[localeName] ?? _continueKeywordsByLocale['en']!`
- Line 367: `_exerciseKeywordsByLocale[localeName] ?? _exerciseKeywordsByLocale['en']!`

**Problem:** When a new locale (e.g., `fr`, `de`) is added but keyword maps are not updated, the service silently uses English keyword matching. The student speaks in French or German, but the system parses it against English keywords, leading to incorrect phase detection.

**Rationale:** The keyword maps for `conversation_manager.dart` already have `es` entries, but `mentor_service.dart` keyword maps (in `mentor_keywords.dart`) only have `en`. If a Spanish speaker uses mentor scheduling, the English keywords fail to match their Spanish requests.

**Fix:** Add complete keyword maps for `es` (and all supported locales) in `mentor_keywords.dart`. For conversation_manager, the fallback should log a warning when a locale is missing rather than silently using `['en']`.

---

### M6 — Orphaned annotation-only entries in ARB tail (5+ entries across both `.arb` files)

Both `app_en.arb` and `app_es.arb` contain annotation-only JSON objects (`"@key"` without a preceding `"key"` value) in their tail sections. These are duplicates of annotations that appear earlier in the file.

**app_en.arb:**
| Line | Entry | Issue |
|---|---|---|
| 7240 | `"@voiceInput"` | Duplicate annotation; key `"voiceInput"` at line 2256 with its own annotation |
| 7255 | `"@exportReports"` | Duplicate annotation; key at line 7130 with its own annotation |
| 7258 | `"@backupAndRestore"` | Duplicate annotation (2nd duplicate); keys at 897 and 7134 |
| 7364 | `"@failedToLoadPlan"` | Duplicate annotation; key at line 5941 with own annotation |
| 7375 | `"@scheduleLesson"` | Duplicate annotation; key at line 1411 with own annotation |

**app_es.arb:**
| Line | Entry | Issue |
|---|---|---|
| 7219 | `"@voiceInput"` | Same as EN |
| 7234 | `"@exportReports"` | Same as EN |
| 7237 | `"@backupAndRestore"` | Same as EN (3rd occurrence) |
| 7331 | `"@failedToLoadPlan"` | Same as EN |
| 7342 | `"@scheduleLesson"` | Same as EN |

**Rationale:** Flutter gen-l10n silently uses the *last* occurrence, so these duplicates are harmless to generated code. However:
1. ARB linters (e.g., `flutter_arb_lint`, Crowdin import) may reject files with keyless annotations.
2. The `@backupAndRestore` in EN appears **three times** (line 898, 7134, 7258) — the first has `"Backup & Restore"`, the others are annotation-only. Tools may interpret the annotation at 7258 as the canonical one, applying its description instead of the one at 898.
3. `voiceInput` has two different descriptions: "Tooltip for voice input button when idle" (line 7240) vs the original annotation (line 2257). Generated Dart uses the last one, so the original annotation's description is lost.

**Fix:** Remove all annotation-only duplicates from the tail section. Merge any unique description text into the canonical annotation that follows its key.

---

### M7 — `grid_painter.dart` hardcodes `TextDirection.ltr`

**File:** `lib/features/questions/presentation/painters/grid_painter.dart:106`

```dart
textDirection: TextDirection.ltr,
```

**Problem:** The grid painter for drawing questions always assumes left-to-right text direction. In Arabic, Hebrew, or other RTL locales, the grid axes, labels, and text rendering would be incorrect.

**Rationale:** While the app currently only supports `en` and `es` (both LTR), this is a latent bug for future RTL locale support.

**Fix:** Accept an optional `TextDirection` parameter (defaulting to `TextDirection.ltr`) and pass `Directionality.of(context)` from callers.

---

## MINOR

### m1 — `'en'` fallback in voice bar and time utils (3 sites)

| File | Line | Code |
|---|---|---|
| `lib/features/teaching/presentation/widgets/voice_bar.dart` | 100 | `localeName = l10n?.localeName ?? 'en'` |
| `lib/core/utils/time_utils.dart` | 76 | `l10n != null ? l10n.localeName : 'en'` |
| `lib/core/utils/time_utils.dart` | 88 | `localeName = l10n?.localeName ?? 'en'` |

**Rationale:** `AppLocalizations` may not be available in these contexts during early startup. The fallback is reasonable, but `es` users during startup screen rendering would briefly see English strings.

**Fix:** Already uses the `l10n?.key ?? 'fallback'` pattern per AGENTS.md. Acceptable as-is but worth documenting.

---

### m2 — `profile_screen.dart` initial language default

**File:** `lib/features/settings/presentation/profile_screen.dart:39`

```dart
String _language = 'en';
```

**Rationale:** The profile screen defaults to English before checking the user's stored preference. If the `userProfileProvider` is not yet loaded, the language selector momentarily shows English.

**Fix:** Initialize from `ref.watch(userProfileProvider).language` instead of hardcoded `'en'`.

---

### m3 — LLM tool descriptions are hardcoded English (7 tools)

All mentor tool description strings (`description` field in the tool definition) are hardcoded in English:

- `search_questions_tool.dart:15-16`
- `get_student_stats_tool.dart:19-20`
- `get_weak_topics_tool.dart:19-20`
- `create_plan_tool.dart:18-19`
- `schedule_lesson_tool.dart:18-19`
- `generate_lesson_blocks_tool.dart:18-19`

**Rationale:** Per AGENTS.md, LLM-facing strings can stay in invariant English. However, the OpenRouter function-calling API passes these descriptions to the LLM. If the LLM is instructed to respond in Spanish, seeing English tool descriptions may confuse weaker models.

**Acceptance:** Low priority — documented as LLM-facing convention. If bilingual LLM prompting becomes important, these can be localized.

---

### m4 — `mentor_context_builder.dart` uses `l10n.mentorContextLateNightWarning` with embedded number

**File:** `lib/features/mentor/services/mentor_context_builder.dart:168`

```dart
buffer.writeln('$bullet${l10n.mentorContextLateNightWarning(lateNight.length)}');
```

The `mentorContextLateNightWarning` ARB key at both `app_en.arb:6380` and `app_es.arb:6582` uses the phrase `"{count} session(s)"` with parenthetical plural. For Spanish this renders as `"{count} sesión(es)"` — which is not idiomatic. The proper Spanish plural would use ICU plural syntax: `{count,plural,=1{1 sesión} other{{count} sesiones}}`.

**Rationale:** This is a translation quality issue, not a crash. The current Spanish string is functional but not natural.

**Fix:** Update the Spanish ARB value to use ICU plural syntax:
```
"mentorContextLateNightWarning": "ADVERTENCIA: {count, plural, =1{1 sesión iniciada después de las 10 PM} other{{count} sesiones iniciadas después de las 10 PM}} (estudio nocturno detectado)"
```

---

### m5 — Tutor session `tutorNotes` hardcodes `'en'` locale for `formatDecimal`

**File:** `lib/features/teaching/services/conversation_manager.dart:448`

```dart
tutorNotes: 'Adaptive pace: ${formatDecimal(adaptivePace, 'en', minFractionDigits: 1, maxFractionDigits: 1)}x',
```

**Per AGENTS.md:** This is annotated as "LLM-facing: invariant English format OK". Acceptable as-is. Noted for completeness.

---

### m6 — `user_profile_model.dart` defaults to `'en'`

**Files:**
- `lib/features/settings/data/models/user_profile_model.dart:43` — `this.language = 'en'`
- `lib/features/settings/data/models/user_profile_model.dart:69` — `json['language'] ... ?? 'en'`

**Rationale:** Safe defaults for model deserialization. If a user has never set their language, English is a reasonable fallback.

**Fix:** Acceptable as-is. This is the stored language preference, not the app locale.

---

## Summary Table

| ID | Severity | File(s) | Issue |
|---|---|---|---|
| B1 | BLOCKER | 4 call sites in 3 files | `DateFormat.Hm` forces 24h time (should use `jm`) |
| M1 | MAJOR | 12 files, 16+ sites | Hardcoded `'en'` defaults in service/tool constructors |
| M2 | MAJOR | 7 providers + main.dart | `Locale('en')` fallback when `l10nProvider` is null |
| M3 | MAJOR | `settings_model.dart:118,125` | `priceDisplay`/`formattedText` default to `'en'` |
| M4a | MAJOR | `topic_detail_screen.dart:53` | Raw error string displayed to user |
| M4b | MINOR | `topic_detail_screen.dart:285` | Hardcoded colon format |
| M5 | MAJOR | `mentor_service.dart`, `conversation_manager.dart` | Keyword fallbacks default to `['en']` |
| M6 | MAJOR | `app_en.arb`, `app_es.arb` | 5+ orphaned annotation-only entries in ARB tails |
| M7 | MINOR | `grid_painter.dart:106` | Hardcoded `TextDirection.ltr` |
| m1 | MINOR | `voice_bar.dart`, `time_utils.dart` | `'en'` fallback for nullable l10n (acceptable pattern) |
| m2 | MINOR | `profile_screen.dart:39` | Initial `_language = 'en'` |
| m3 | MINOR | 7 mentor tool files | LLM tool descriptions hardcoded English |
| m4 | MINOR | `app_es.arb:6582` | Non-idiomatic Spanish plural in `mentorContextLateNightWarning` |
| m5 | MINOR | `conversation_manager.dart:448` | `'en'` in tutorNotes (LLM-facing, accepted) |
| m6 | MINOR | `user_profile_model.dart:43,69` | `'en'` defaults in model (safe fallback) |

## Acceptance Criteria

For each item, "fixed" means:

- **B1:** All 4 `DateFormat.Hm`/`Hms` call sites replaced with `DateFormat.jm()` or locale-aware alternative. Verify Spanish rendering: `"2:30 p. m."` instead of `"14:30"`.
- **M1:** All service/tool constructors remove `localeName = 'en'` default. Parameter becomes required. Locale is propagated from the nearest `l10nProvider` or locale-aware call site.
- **M2:** Providers no longer silently fall back to `Locale('en')`. Either guarantee `l10nProvider` is non-null before provider creation, or log a warning when fallback is used.
- **M3:** `priceDisplay` and `formattedText` getters removed. Any caller using them is migrated to locale-aware alternatives.
- **M4a:** `Text('$e')` replaced with `l10n.errorLoadingTopic(e)` or ICU-formatted error message.
- **M4b:** Colon formatting moved into l10n key or removed with string concatenation replaced.
- **M5:** Spanish keyword entries added to `mentor_keywords.dart` `MentorKeywords` maps. Conversation manager logs warning when locale is missing.
- **M6:** All annotation-only blocks removed from ARB tail sections. Only key-followed-by-annotation pairs remain.
- **M7:** `grid_painter.dart` accepts `TextDirection` parameter. All callers pass `Directionality.of(context)`.
- **m2:** `profile_screen.dart` initializes `_language` from `ref.watch(userProfileProvider).language`.
- **m4:** Spanish ARB value for `mentorContextLateNightWarning` updated to use ICU plural syntax.
