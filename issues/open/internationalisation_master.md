# Internationalisation Master — Full-Codebase i18n Audit

**Audit date:** 2026-05-20
**Scope:** `lib/`, `lib/l10n/` (all Dart and ARB files)
**Target locale:** Spanish (`es`) — patterns apply to all future locales.
**Severity key:** BLOCKER = crash/inability to proceed; MAJOR = feature broken or misleading; MINOR = code quality / UX friction.

---

## BLOCKER

*None found.* No issue currently causes an app crash or prevents the user from proceeding. The most critical items below (MAJOR) are priority targets.

---

## MAJOR

### M1 — Hardcoded English labels in Topic Detail Screen (6 strings)

**Files:** `lib/features/dashboard/presentation/screens/topic_detail_screen.dart:163-184`

**Problem:** Six label strings are passed as raw English string literals instead of `l10n.*` keys:

| Line | String | Context |
|------|--------|---------|
| 163 | `'Confidence'` | `_buildStatBox(context, 'Confidence', ...)` |
| 167 | `'Forgetting Risk'` | `_buildStatBox(context, 'Forgetting Risk', ...)` |
| 171 | `'Review Urgency'` | `_buildStatBox(context, 'Review Urgency', ...)` |
| 177 | `'Last Attempted'` | `_buildInfoRow(context, 'Last Attempted', ...)` |
| 180 | `'Last Updated'` | `_buildInfoRow(context, 'Last Updated', ...)` |
| 184 | `Text('Accuracy Trend', ...)` | Raw `Text` widget |

**Rationale:** These are user-facing stat labels on every topic detail page. A Spanish user sees English labels even when the rest of the screen is localised.

**Fix:** Add ARB keys and use `l10n.confidence`, `l10n.forgettingRisk`, `l10n.reviewUrgency`, `l10n.lastAttempted`, `l10n.lastUpdated`, `l10n.accuracyTrend` in both `.arb` files.

---

### M2 — Hardcoded English loading text in Syllabus Progress Card

**File:** `lib/features/planner/presentation/widgets/syllabus_progress_card.dart:68`

**Problem:**
```dart
Text('Loading syllabus progress...'),
```

**Rationale:** Shown during async data load on the syllabus progress card. Ignores user locale. The `_buildEmpty` method at line 80 correctly uses `AppLocalizations.of(context)!`, but the loading state is hardcoded.

**Fix:** Replace with `l10n.loadingSyllabusProgress` or similar ARB key.

---

### M3 — Default lesson plan strings in model (7 strings) bypass ARB

**File:** `lib/features/teaching/data/models/lesson_plan_model.dart:72-80`

**Problem:** `LessonPlan.defaultPlan()` uses hardcoded English defaults:
```dart
String goal = 'Understand the topic',
String introTitle = 'Introduction',
String mainTitle = 'Main Content',
String practiceTitle = 'Practice',
String checkpointStarted = 'Lesson started',
String checkpointCovered = 'Topic covered',
String checkpointCompleted = 'Practice completed',
```

**Rationale:** These defaults are rendered in the lesson progress bar when the AI fails to generate a plan. They are user-facing. ARB keys already exist (`defaultLessonGoal`, `sectionIntroduction`, `sectionMainContent`, `sectionPractice`, etc.) but the model never calls them. Every caller must pass l10n values, but the defaults silently fall back to English.

**Fix:** Remove defaults from the method signature and require callers to pass l10n-resolved strings, or add an `AppLocalizations` parameter. Alternatively, inline the l10n lookups at the call sites where `defaultPlan()` is invoked.

---

### M4 — `toStringAsFixed()` in mentor context builder (locale-unaware numbers in user-facing text)

**File:** `lib/features/mentor/services/mentor_service.dart:246,294`

**Problem:**
```dart
// Line 246 — inserted into l10n.mentorContextPlanAdherence(...)
adherenceDeviation.averageAdherence.toStringAsFixed(1)

// Line 294 — inserted into l10n.mentorContextWeakTopicItem(...)
(topic.accuracy * 100).toStringAsFixed(0)
```

These numbers are wrapped inside `lookupAppLocalizations(Locale(_localeName)).mentorContextPlanAdherence(...)` and `.mentorContextWeakTopicItem(...)`, which means the strings are localised but **the number format inside is invariant** — `85.5` instead of `85,5` for Spanish. Per AGENTS.md `toStringAsFixed()` is forbidden for user-facing numeric displays.

**Rationale:** The mentor context string appears directly in mentor chat messages that users read. A Spanish user sees period decimal separators in an otherwise localized paragraph.

**Fix:** Replace with `formatDecimal(adherenceDeviation.averageAdherence, _localeName, minFractionDigits: 1, maxFractionDigits: 1)` and `formatPercent(topic.accuracy * 100, _localeName, minFractionDigits: 0)`.

---

### M5 — Hardcoded 24h time format in orphaned-session dialog

**File:** `lib/main.dart:492-494`

**Problem:**
```dart
final hour = session.startTime.hour.toString().padLeft(2, '0');
final minute = session.startTime.minute.toString().padLeft(2, '0');
final timeStr = '$hour:$minute';
```

The `timeStr` is passed to `l10n.orphanedSessionMessage(session.topicTitle, timeStr)`. This always produces 24h format (e.g. `"14:30"`) regardless of locale preference. Spanish users may expect 12h format (`"2:30 p. m."`).

**Rationale:** The orphaned-session dialog interrupts the user at app startup with a time that may feel foreign.

**Fix:** Replace with `DateFormat.jm(l10n.localeName).format(session.startTime.toLocal())`.

---

## MINOR

### m1 — Duplicate ARB keys (12+ pairs across both .arb files)

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`

**Problem:** The ARB tail section (lines ~7000–7356) re-declares keys that already appear earlier, producing duplicate definitions. Flutter gen-l10n silently uses the **last** definition — callers get unpredictable values.

| Key | EN occurrences | EN values | ES occurrences | ES values |
|---|---|---|---|---|
| `backupAndRestore` | 3 | `"Backup & Restore"` × 3 (identical) | 3 | `"Copia de Seguridad"` / `"Copia de seguridad y restaurar"` / `"Copia de Seguridad y Restaurar"` |
| `scheduleLesson` | 2 | `"Schedule Lesson"` / `"Schedule a Lesson"` | 2 | `"Programar Lección"` / `"Programar una Lección"` |
| `failedToLoadPlan` | 2 | `"Failed to load plan: {error}"` / `"Failed to load study plan"` (***structural mismatch*** — one has `{error}`, the other doesn't) | 2 | `"Error al cargar el plan: {error}"` / `"Error al cargar el plan de estudio"` |
| `voiceInput` | 2 | `"Voice Input"` / `"Voice input"` | 2 | `"Entrada de Voz"` / `"Entrada de voz"` |
| `exportReports` | 2 | `"Export Reports"` × 2 | 2 | `"Exportar informes"` / `"Exportar Informes"` |
| `readAloud` | 2 | `"Read aloud"` × 2 | 2 | `"Leer en voz alta"` × 2 |
| `uploadFile` | 2 | `"Upload file"` × 2 | 2 | `"Subir archivo"` × 2 |
| `fileAttached` | 2 | `"File attached"` × 2 | 2 | `"Archivo adjunto"` × 2 |
| `recordAudio` | 2 | `"Record audio"` × 2 | 2 | `"Grabar audio"` × 2 |
| `recordingComplete` | 2 | `"Recording complete"` × 2 | 2 | `"Grabación completa"` × 2 |
| `startRecording` | 2 | `"Start recording"` × 2 | 2 | `"Iniciar grabación"` × 2 |
| `manualSessionTracker` | 2 | (identical) | 1 | (single — fine) |
| `manualSessionTrackerDescription` | 2 | (different values) | 1 | (single) |
| `sessionHistoryDescription` | 2 | (different values) | 1 | (single) |
| `sessionTracking` | 2 | (identical) | 1 | (single) |
| `exportProgressCsv` | 2 | (identical) | 1 | (single) |
| `tapToCollapse` | 2 | (different values) | 1 | (single) |
| `tapToExpand` | 2 | (different values) | 1 | (single) |

**`failedToLoadPlan` structural mismatch detail:**
- First def: `"Failed to load plan: {error}"` with `@failedToLoadPlan.placeholders.error`
- Second def: `"Failed to load study plan"` (no placeholder, no `@placeholders`)
- **Generated Dart uses the getter** (`String get failedToLoadPlan`), so the `{error}` detail is silently lost. No compile error (nothing calls it with a parameter), but error reporting is degraded.

**`backupAndRestore` variability (Spanish):** Three different translations exist: `"Copia de Seguridad"` (settings section), `"Copia de seguridad y restaurar"` (tooltip), `"Copia de Seguridad y Restaurar"` (tooltip with title case). The generated Dart uses only the **last** one (`"Copia de Seguridad y Restaurar"`), so other contexts get the wrong case.

**Rationale:** Duplicates make the ARB files harder to maintain, create ambiguity about which value is canonical, and degrade error reporting (failedToLoadPlan loses its error detail).

**Fix:** De-duplicate all keys. Keep the canonical definition with the most complete placeholder set. Remove or merge the second occurrence. For `backupAndRestore` with differing values, add distinct key names (e.g. `backupAndRestoreSection`, `backupAndRestoreTooltip`).

---

### m2 — Orphaned ARB annotation (spec violation)

**File:** `lib/l10n/app_en.arb:7232-7239`

**Problem:** The `@lessonPracticeWithTopic` annotation block is positioned **after** the unrelated `pageIndicator` block, separated from its key:
```
7219: "lessonPracticeWithTopic": "Lesson Practice: {topic}",
7220: "pageIndicator": "{current} / {total}",
7221: "@pageIndicator": { ... },    // belongs to pageIndicator
7232: "@lessonPracticeWithTopic": { ... },  // ORPHANED — should follow line 7219
```

Per the ARB spec, `@key` annotations must **immediately** follow their corresponding key.

**Rationale:** While Flutter gen-l10n tolerates this, other tools (l10n linting, crowdin) may reject the file or silently drop the annotation.

**Fix:** Reorder so `@lessonPracticeWithTopic` follows `"lessonPracticeWithTopic"` directly.

---

### m3 — Hardcoded Semantics label in Onboarding Dialog

**File:** `lib/features/onboarding/presentation/onboarding_dialog.dart:66`

**Problem:**
```dart
Semantics(
  label: 'Page ${i + 1} of ${pages.length}',
  ...
)
```

**Rationale:** Screen-reader users hear English page indicators regardless of locale.

**Fix:** Add ARB key (e.g. `"pageIndicatorAria": "Page {count} of {total}"`) and use `l10n.pageIndicatorAria(i + 1, pages.length)`.

---

### m4 — Fallback English strings in core widgets (l10n null-coalesce)

**Files:**
- `lib/core/widgets/dialog_utils.dart:18,22` — `cancelLabel ?? 'Cancel'`, `confirmLabel ?? 'Confirm'`
- `lib/core/utils/error_boundary.dart:53,59,71` — `'Something went wrong'`, `'An unexpected error occurred'`, `'Retry'`
- `lib/core/widgets/shimmer_widget.dart:65` — `'Loading'`
- `lib/core/utils/time_utils.dart:64,70,74` — `'Unknown'`, `'Today'`, `'Yesterday'`

**Problem:** These use `l10n?.key ?? 'English fallback'` pattern. When `AppLocalizations.of(context)` returns null (e.g. before locale is loaded), English is shown.

**Rationale:** Low severity because `AppLocalizations.of(context)` is almost always available by the time these widgets render. However, startup screens or error states could race.

**Fix:** Ensure `AppLocalizations` is loaded before these widgets are built, or provide locale-aware fallbacks. At minimum, add a note in AGENTS.md about this pattern.

---

### m5 — Notification strings intentionally English (documented, but worth noting)

**File:** `lib/features/sessions/services/study_timer_service.dart:189-192`

```dart
// Notifications appear in the OS notification shade where locale is OS-
// controlled, not the app. Intentionally invariant English.
'Focus Session Complete',
'Great focus! You completed ${_elapsedMs ~/ msPerMinute} minutes.'
```

**Rationale:** OS notifications use device-level locale, not in-app locale. This is a deliberate trade-off. If full i18n is desired, platform-specific notification localization would be needed.

**Acceptance:** Documented as intentional — no fix required unless platform-level locale matching is implemented.

---

### m6 — `settings_model.dart` locale default

**File:** `lib/features/settings/data/models/settings_model.dart:193` (estimated)

**Problem:** `formatUsageSummary([String localeName = 'en'])` defaults to `'en'`. If any code path calls this without passing the user's locale, numbers render in invariant English format.

**Rationale:** No current caller omits the locale (verified by grep), but the default creates a latent bug for future callers.

**Fix:** Remove the default value or assert that a locale is always passed.

---

### m7 — LLM prompt `defaultTemplates` defaults to `en`

**File:** `lib/features/teaching/services/prompts/prompts.dart:23`

```dart
static const ConversationPromptSet defaultTemplates = ConversationPromptSet(localeName: 'en');
```

**Rationale:** The `localeName` is overridden at construction time. The `defaultTemplates` constant is only a fallback when no locale is explicitly chosen. Verified that all production call sites pass the user's locale.

**Acceptance:** Low risk — document that callers must always pass the resolved locale.

---

## Summary Table

| ID | Severity | File(s) | Issue |
|---|---|---|---|
| M1 | MAJOR | `topic_detail_screen.dart:163-184` | 6 hardcoded English labels |
| M2 | MAJOR | `syllabus_progress_card.dart:68` | Hardcoded English loading text |
| M3 | MAJOR | `lesson_plan_model.dart:72-80` | 7 default plan strings bypass ARB |
| M4 | MAJOR | `mentor_service.dart:246,294` | `toStringAsFixed` in user-facing mentor context (locale-unaware numbers) |
| M5 | MAJOR | `main.dart:492-494` | Hardcoded 24h time format in orphaned-session dialog |
| m1 | MINOR | `app_en.arb`, `app_es.arb` | 12+ duplicate ARB keys with value/structural mismatches |
| m2 | MINOR | `app_en.arb:7232` | Orphaned `@lessonPracticeWithTopic` annotation |
| m3 | MINOR | `onboarding_dialog.dart:66` | Hardcoded Semantics page label |
| m4 | MINOR | 5 core widget files | Fallback English strings in l10n null-coalesce |
| m5 | MINOR | `study_timer_service.dart:189` | English notification strings (intentional) |
| m6 | MINOR | `settings_model.dart` | `localeName` default `'en'` |
| m7 | MINOR | `prompts.dart:23` | `defaultTemplates` locale default (safe — overridden at call sites) |

---

## Acceptance Criteria

For each MAJOR item (M1–M5), "fixed" means:

- **M1:** ARB keys added for all 6 labels and used in `topic_detail_screen.dart`. Verify Spanish rendering: `"Confianza"`, `"Riesgo de Olvido"`, `"Urgencia de Repaso"`, `"Último Intento"`, `"Última Actualización"`, `"Tendencia de Precisión"`.
- **M2:** `'Loading syllabus progress...'` replaced with `l10n.loadingSyllabusProgress`. Spanish value: `"Cargando progreso del plan de estudios..."`.
- **M3:** `LessonPlan.defaultPlan()` no longer uses hardcoded English defaults. Either method takes `AppLocalizations l10n` parameter, or callers pass l10n-resolved strings.
- **M4:** All `toStringAsFixed()` calls in `mentor_service.dart` replaced with `formatDecimal()` / `formatPercent()` from `number_format_utils.dart`. Spanish output: `"85,5"` instead of `"85.5"`.
- **M5:** `main.dart:492-494` uses `DateFormat.jm(l10n.localeName)` instead of manual 24h formatting. Spanish output: `"2:30 p. m."` instead of `"14:30"`.

For MINOR items (m1–m7):

- **m1:** All duplicate ARB keys removed; `failedToLoadPlan` uses the `{error}` placeholder variant; `backupAndRestore` with different values gets distinct key names.
- **m2:** `@lessonPracticeWithTopic` annotation moved immediately after its key.
- **m3:** Semantics label uses l10n key.
- **m4:** Fallback pattern documented or mitigated.
- **m6:** Default value removed from `formatUsageSummary`.
