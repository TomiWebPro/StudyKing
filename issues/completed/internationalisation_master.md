# Spanish (es) Localization Audit & i18n Architecture Gaps

## Context

The app supports `en` and `es` via Flutter ARB-based l10n (`lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`). The Spanish translation is extensive (~2846 lines) but contains several inaccuracies, hardcoded English fallbacks, and locale-blind formatting. These issues must be fixed first so that adding future languages (fr, de, pt, etc.) follows correct patterns.

## Issues

### 1. Wrong abbreviation in `questionsAndMinutes` / `topicQuestionsAndMinutes` (Spanish)

**File:** `lib/l10n/app_es.arb`

```
"questionsAndMinutes": "{questions}Q · {minutes}min",
"topicQuestionsAndMinutes": "{questions}Q · {minutes}min",
```

The abbreviation `Q` stands for English **"Questions"**. In Spanish the correct abbreviation is **`P`** (preguntas). This is inconsistent with `dailyPlanTarget` which correctly uses `P`:

```
"dailyPlanTarget": "Hoy: {questions}P, {minutes}min",
```

**Fix:** Both keys should use `{questions}P` in Spanish.

**Rationale:** This is a factual translation error visible to all Spanish users on practice/dashboard cards.

---

### 2. Hardcoded English fallback `'0 min 0 sec'`

**File:** `lib/features/practice/presentation/practice_session_screen.dart:347,351`

```dart
label: '${AppLocalizations.of(context)!.time}: ${_elapsedTimeFormatted ?? '0 min 0 sec'}',
```

When `_elapsedTimeFormatted` is null (before first tick), the fallback string is hardcoded in English. This bypasses the entire l10n system.

**Fix:** Use `l10n.sessionDurationMinutes(0)` or a dedicated `l10n.zeroDuration` key, or initialize `_elapsedTimeFormatted` eagerly with a localised value.

---

### 3. Hardcoded date-time format in `_formatTime` (LLM task manager)

**File:** `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:159-161`

```dart
String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
```

This always produces 24-hour `HH:MM:SS`. Many locales prefer 12-hour or different separators. The `intl` `DateFormat` is already a dependency — use it with the locale from `AppLocalizations`.

**Fix:** Replace with `DateFormat.Hms(l10n.localeName).format(dt)`.

---

### 4. `DateFormat('E')` without locale in analytics

**File:** `lib/features/sessions/widgets/session_analytics.dart:59`

```dart
final dayName = DateFormat('E').format(date);
```

`DateFormat('E')` returns English day names (Mon, Tue, etc.) regardless of the app locale. For Spanish users these should be `Lun, Mar, Mié, ...`.

**Fix:** Pass locale: `DateFormat('E', l10n.localeName).format(date)`.

---

### 5. `drawingWithStrokes` plural workaround is fragile

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`

```
"drawingWithStrokes": "Drawing with {count} stroke{plural}",
// Spanish:
"drawingWithStrokes": "Dibujando con {count} trazo{plural}",
```

The `{plural}` placeholder is resolved by the caller as `'s'` or `''`. This works for English and accidentally for Spanish (`trazo` + `s` = `trazos`), but will **break** for any language where the plural suffix is not `'s'` (e.g., French - `trazo` is not a word, but more importantly languages with complex plural morphology).

**Fix:** Replace with proper ICU plural syntax:

```
"drawingWithStrokes": "{count, plural, =1{Drawing with 1 stroke} other{Drawing with {count} strokes}}"
```

And in Spanish:

```
"drawingWithStrokes": "{count, plural, =1{Dibujando con 1 trazo} other{Dibujando con {count} trazos}}"
```

This lets Flutter's `Intl.pluralLogic` handle all plural rules correctly.

---

### 6. No documented locale-adding procedure

**Files:** `lib/l10n/`, `lib/main.dart:129-132`

Only `en` and `es` are registered:

```dart
supportedLocales: const [
  Locale('en'),
  Locale('es'),
],
```

There is no `flutter gen-l10n` configuration in `pubspec.yaml`, no documented workflow for:
- Generating ARB templates for new locales
- Running the codegen
- Validating coverage (though a test file exists at `test/l10n/app_localizations_coverage_test.dart`)

**Fix:** Add `flutter gen-l10n` config to `pubspec.yaml` with `arb-dir`, `template-arb-file`, `output-localization-file`, etc. Document a one-command flow: `flutter gen-l10n && <validate>`.

---

### 7. Missing `localeResolutionCallback`

**File:** `lib/main.dart:119-132`

The app sets `locale:` but does not have a `localeResolutionCallback`. This means:
- On devices set to `es-MX`, `es-AR`, etc., the app will **not** resolve to the `es` locale because exact match is required.
- Similarly, `en-GB`, `en-AU`, etc. will not resolve to `en`.

**Fix:** Add a `localeResolutionCallback` that strips the country code to match the base locale.

```dart
localeResolutionCallback: (locale, supportedLocales) {
  if (locale == null) return supportedLocales.first;
  for (final supported in supportedLocales) {
    if (supported.languageCode == locale.languageCode) return supported;
  }
  return supportedLocales.first;
},
```

---

### 8. `durationSeparator` in ARB is a placeholder hack

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`

```
"durationSeparator": " ",
```

A single space is the most common separator, but some locales may use different conventions (e.g., en dash, no separator). Having a key that just returns a space is brittle — the format logic in `time_utils.dart` string-joins parts instead of using a proper localized template.

**Consideration:** Replace custom concatenation in `formatDuration()` with a localized template like `"{hours}h {minutes}m {seconds}s"` so the complete format per locale is defined in the ARB file, not in Dart code.

---

## Acceptance Criteria

- [ ] `questionsAndMinutes` and `topicQuestionsAndMinutes` use `P` (not `Q`) in `app_es.arb`
- [ ] `_elapsedTimeFormatted` null fallback in `practice_session_screen.dart` is localised
- [ ] `_formatTime` in `llm_task_manager_screen.dart` uses `DateFormat` with `l10n.localeName`
- [ ] `DateFormat('E')` in `session_analytics.dart` passes locale
- [ ] `drawingWithStrokes` uses proper ICU plural syntax in both `app_en.arb` and `app_es.arb`
- [ ] `pubspec.yaml` has `flutter gen-l10n` configuration for repeatable codegen
- [ ] `localeResolutionCallback` is added to `MaterialApp` for country-code fallback
- [ ] Generated Dart files (`app_localizations_es.dart`) are regenerated after ARB edits

## Affected Files

| File | Issue |
|------|-------|
| `lib/l10n/app_es.arb` | #1, #5, #8 |
| `lib/l10n/app_en.arb` | #5, #8 |
| `lib/features/practice/presentation/practice_session_screen.dart` | #2 |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | #3 |
| `lib/features/sessions/widgets/session_analytics.dart` | #4 |
| `lib/main.dart` | #6, #7 |
| `pubspec.yaml` | #6 |
