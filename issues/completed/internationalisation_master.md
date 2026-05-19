# Internationalisation (i18n) Master Issue — Round 2

**Date:** 2026-05-19  
**Auditor:** Internationalisation Master  
**Scope:** Remaining i18n gaps after Round 1 (see `issues/completed/internationalisation_master.md`)  
**Target Locale:** Spanish (es), patterns generalisable to other locales  

---

## BLOCKER

None identified.

---

## MAJOR

### M6. Hardcoded user-facing English strings in 5 widget files

**Rationale:** These strings are never translated via `AppLocalizations`. A Spanish user will always see English text regardless of their locale setting.

**Affected files and occurrences:**

| # | File | Line | String | Context |
|---|---|---|---|---|
| 6a | `lib/features/settings/presentation/settings_screen.dart` | 96 | `'Share'` | `SnackBarAction` label in auto-backup success |
| 6b | same file | 99 | `'StudyKing Backup — ${...}'` | `Share.shareXFiles` text in auto-backup |
| 6c | same file | 633 | `'Back Up Now'` | `FilledButton` label in backup dialog |
| 6d | same file | 654 | `'StudyKing Backup — ${...}'` | `Share.shareXFiles` text in manual backup |
| 6e | same file | 658 | `'Share last backup'` | `TextButton` label |
| 6f | `lib/features/dashboard/presentation/widgets/dashboard_header.dart` | 29 | `'Export Reports'` | `Semantics` label |
| 6g | same file | 32 | `'Export Reports'` | `IconButton` tooltip |
| 6h | same file | 38 | `'Backup & Restore'` | `Semantics` label |
| 6i | same file | 41 | `'Backup & Restore'` | `IconButton` tooltip |
| 6j | `lib/features/teaching/presentation/tutor_screen.dart` | 557 | `'Chat'` / `'Slides'` | `IconButton` tooltip (toggle) |
| 6k | same file | 563 | `'Voice output'` | `IconButton` tooltip |
| 6l | `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 85 | `'Read aloud'` | `IconButton` tooltip |
| 6m | `lib/features/questions/presentation/widgets/question_card_widget.dart` | 341 | `'Upload file'` | `Semantics` label |
| 6n | same file | 347 | `'File attached'` | Button label (file upload state) |
| 6o | same file | 347 | `'Upload file'` | Button label (no file state) |
| 6p | same file | 356 | `'Record audio'` | `Semantics` label |
| 6q | same file | 362 | `'Recording complete'` | Button label (recording done) |
| 6r | same file | 362 | `'Start recording'` | Button label (idle state) |

**Acceptance Criteria:**
- Every string above is replaced with an `AppLocalizations.of(context)!.someKey` call.
- New ARB keys are added to both `app_en.arb` and `app_es.arb`.
- The generated Dart code compiles without errors.
- A Spanish device shows translated strings for each of these UI elements.
- `scripts/check_i18n_coverage.sh` passes with 100 % key parity.

---

### M7. `lesson_agent_service.dart` uses hardcoded English system prompts instead of ARB

**File:** `lib/features/lessons/services/lesson_agent_service.dart`

**Lines 255–265:**
```dart
String _buildLessonPrompt(String topicTitle, String localeName) {
  return 'Generate a structured lesson plan for the topic: "$topicTitle". '
      'Include slides (key concepts), examples, exercises, and a summary. '
      'Respond in $localeName. '
      'Format your response as a JSON array of blocks...';
}

String _lessonSystemPrompt(String localeName) {
  return 'You are a lesson planning AI. Generate educational content in $localeName. '
      'Your response must be valid JSON.';
}
```

**Rationale:** The `teaching/services/prompts/prompts.dart` file already has a proper pattern — all prompt strings are in ARB and accessed via `lookupAppLocalizations(Locale(localeName))`. This file bypasses that pattern entirely, producing English prompts even when the user's locale is `es`. A Spanish user asking for a lesson will receive a system prompt in English, which means the LLM may produce lesson structure descriptions in English before switching mid-generation.

**Also affected — `question_variant_generator.dart:87-88`:**
```dart
String _variantSystemPrompt() {
  return 'You are a question variant generator. Generate semantically equivalent ...';
}
```
Same pattern — hardcoded English prompt not passed through ARB.

**Acceptance Criteria:**
- All prompt strings in `lesson_agent_service.dart` are moved to ARB keys (`lessonSystemPrompt`, `lessonBuildPrompt`).
- The `_variantSystemPrompt()` in `question_variant_generator.dart` uses `lookupAppLocalizations` or receives the l10n instance.
- Both EN and ES ARB files contain the new keys.
- Generated Dart code compiles.
- A Spanish device triggers lesson generation and the LLM receives a Spanish system prompt.

---

### M8. Locale switch does not trigger rebuild of `AppLocalizations.of(context)`

**Rationale:** When the user changes language in Settings, `ref.read(localeProvider.notifier).state = Locale(value)` is called. This updates a `StateProvider<Locale>`. However, `AppLocalizations.of(context)` is resolved by Flutter's `Localizations` widget ancestor, which does **not** watch `localeProvider`. Screens that call `final l10n = AppLocalizations.of(context)!` inside `build()` **will** see updated strings because Flutter rebuilds the widget tree when `Localizations` changes — but only if the locale change is propagated through `MaterialApp`'s `locale` parameter back to `Localizations`.

**The root cause:** The app likely sets `locale:` on `MaterialApp` from `localeProvider`. If this is a plain `StateProvider<Locale>`, the widget tree rebuilds and `Localizations` re-resolves, so strings refresh. However, `AGENTS.md` explicitly warns about screens that cache `l10n` in a local variable outside `build` — such screens display stale text until re-entered.

**Confirmation needed — investigate:**
- `lib/main.dart` — how is `locale` wired to `MaterialApp`?
- Does `MaterialApp` receive `ref.watch(localeProvider)` so it triggers a full rebuild?
- Are there any `StatefulWidget` screens that assign `l10n` to a field in `initState` / `didChangeDependencies` and read it later without re-reading on rebuild?

**Acceptance Criteria:**
- After switching from English to Spanish in Settings, every visible screen updates its strings (check: dashboard, planner, mentor, tutor, settings).
- `MaterialApp` watches `localeProvider` via `ref.watch(localeProvider)`.
- Any `StatefulWidget` that caches `l10n` outside `build` is refactored to re-read on locale change (e.g. via `didChangeDependencies` + `Locale` key check, or `Consumer` wrapping).
- A test exists that simulates locale switch and verifies string refresh on a representative screen.

---

### M9. Spanish ARB uses English-style `(s)` plural notation instead of ICU plural

**File:** `lib/l10n/app_es.arb`

**Two keys affected:**

Key `sourcesCountLabel` (line 6044):
```json
"sourcesCountLabel": "{count, plural, =1{1 Fuente} other{{count} Fuente(s)}}"
```
The `other` branch uses `Fuente(s)` — this is an English convention (adding `(s)` to indicate optional plural). In Spanish the plural should be `fuentes` (lowercase).

Key `downstreamTopicWarning` (line 6513):
```json
"downstreamTopicWarning": "⚠ {count} tema(s) dependiente(s) dependen de este tema y pueden necesitar actualización."
```
This is not ICU-pluralised at all — it's a plain `{count}` placeholder with English `(s)` appended manually. When `count == 1`, the string reads `"⚠ 1 tema(s) dependiente(s) dependen..."` which is incorrect in both English and Spanish.

**Acceptance Criteria:**
- `sourcesCountLabel` is changed to `"{count,plural,=1{1 fuente} other{{count} fuentes}}"` in `app_es.arb`.
- `downstreamTopicWarning` is changed to use ICU plural syntax: `"⚠ {count,plural,=1{1 tema dependiente depende} other{{count} temas dependientes dependen}} de este tema y pueden necesitar actualización."`
- Generated Dart compiles and displays correctly for count = 1 and count = 5.
- `scripts/check_i18n_coverage.sh` passes.

---

## MINOR

### m9. `settings_screen.dart` 966–968 — `toStringAsFixed` for user-facing file size

**File:** `lib/features/settings/presentation/settings_screen.dart:965-969`

```dart
final sizeStr = fileSize > 1048576
    ? '${(fileSize / 1048576).toStringAsFixed(1)} MB'
    : fileSize > 1024
        ? '${(fileSize / 1024).toStringAsFixed(0)} KB'
        : '$fileSize B';
```

**Rationale:** Per AGENTS.md, `toStringAsFixed` must never be used for user-facing numeric displays — it always produces a period decimal separator (`"1.5 MB"`), which is incorrect for Spanish (`"1,5 MB"`). Use `formatDecimal(fileSizeInMb, localeName, maxFractionDigits: 1)` instead.

**Acceptance Criteria:**
- Replace with `formatDecimal(fileSize / 1048576, localeName, maxFractionDigits: 1)` + `" MB"` (or move the unit into ARB).
- Spanish display shows `"1,5 MB"`, not `"1.5 MB"`.

---

### m10. RTL: Hardcoded `EdgeInsets.only(left:)` in `planner_screen.dart`

**File:** `lib/features/planner/presentation/planner_screen.dart:788`

```dart
padding: const EdgeInsets.only(left: 4),
```

**Rationale:** Hardcoded `left` padding does not flip for RTL locales. Should use `EdgeInsetsDirectional.only(start: 4)`.

**Acceptance Criteria:**
- Changed to `const EdgeInsetsDirectional.only(start: 4)`.
- Visual verification: the spacing appears on the correct side when text direction is RTL.

---

### m11. RTL: Hardcoded `EdgeInsets.only(left:)` in `subject_topics_tab.dart`

**File:** `lib/features/subjects/presentation/widgets/subject_topics_tab.dart:365`

```dart
margin: EdgeInsets.only(bottom: 4, left: indentation * 16.0),
```

**Rationale:** `left:` is direction-fixed and does not flip for RTL. Should use `EdgeInsetsDirectional.only(bottom: 4, start: indentation * 16.0)`.

**Acceptance Criteria:**
- Changed to `EdgeInsetsDirectional.only(bottom: 4, start: indentation * 16.0)`.
- Indentation appears on the correct side for RTL.

---

### m12. `durationMinutes` abbreviation mismatch between EN and ES

**File:** `lib/l10n/app_en.arb:144` vs `lib/l10n/app_es.arb:144`

| Locale | Value |
|---|---|
| `en` | `{count, plural, =1{1m} other{{count}m}}` |
| `es` | `{count, plural, =1{1min} other{{count}min}}` |

**Rationale:** The Spanish version uses the longer `min` abbreviation while English uses `m`. This causes inconsistent layout widths — a planner screen using these values may render `5min` in Spanish where English shows `5m`, potentially breaking tight layouts or grid alignments. Either both should converge on the same abbreviation, or the layout must accommodate the wider string.

**Also note:** The same inconsistency exists for `durationSeconds` and `durationHours` — verify these are consistent.

**Acceptance Criteria:**
- Either change ES to `m` (matching EN) or EN to `min` (matching ES) — not both.
- Visual check on a Spanish planner screen that duration labels fit within their containers.

---

### m13. Badge labels in `settings_screen.dart` use raw integer instead of locale-aware format

**File:** `lib/features/settings/presentation/settings_screen.dart`

- Line 1754: `label: Text('$_failedCount'),` — Badge showing failure count
- Line 1797: `label: Text('$total'),` — Badge showing total active+failed count

**Rationale:** These raw integers are not formatted with locale-aware `NumberFormat`. While Arabic numerals (0-9) are universally understood, `NumberFormat.decimalPattern(localeName)` should be used for consistency and future locale support. More critically, `$_failedCount` and `$total` are just numbers — they should ideally use `l10n.failedCount(_failedCount)` if a pluralised ARB key exists.

**Acceptance Criteria:**
- Replace with `formatDecimal(count.toDouble(), localeName, maxFractionDigits: 0)` or equivalent.
- Verify that the Badge displays correctly for count values 0, 1, 99.

---

### m14. LLM-facing `mentor_service.dart` has hardcoded English strings in diagnostics

**File:** `lib/features/mentor/services/mentor_service.dart:291-294`

```dart
buffer.writeln('${bullet}Sessions today: ${todaySessions.length}');
...
buffer.writeln('${bullet}WARNING: ${lateNight.length} session(s) started after 10 PM (late-night study detected)');
```

**Rationale:** These strings are injected into the LLM prompt context. While LLM-facing strings can be in invariant English (per AGENTS.md), the `session(s)` pattern with English-only `(s)` plural is inconsistent with the rest of the codebase. The content might affect LLM comprehension for Spanish — the LLM may interpret `session(s)` differently when the preceding context is in Spanish.

**Acceptance Criteria:**
- Either extract these to ARB `mentorDiagnosticSessionsToday` and `mentorDiagnosticLateNight` keys, or add a comment explaining why they are intentionally invariant.
- If ARB keys are added, provide Spanish translations.

---

## Summary

| Severity | Count | Key themes |
|---|---|---|
| BLOCKER | 0 | |
| MAJOR | 4 | Hardcoded English UI strings (M6), LLM prompts bypassing ARB (M7), locale-switch staleness (M8), English `(s)` plurals in ES ARB (M9) |
| MINOR | 6 | `toStringAsFixed` in file size (m9), RTL hardcoded left padding ×2 (m10–m11), duration abbreviation mismatch (m12), raw integer badge labels (m13), hardcoded mentor diagnostics (m14) |
