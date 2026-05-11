# Internationalisation: Hardcoded Strings and Locale-Ignoring Duration Formatting

## Context

The StudyKing app uses Flutter's `flutter_localizations` and `intl` package with ARB files for English and Spanish. However, several critical i18n issues were found that cause incorrect or missing translations for end users.

## Affected Files

- `lib/core/utils/time_utils.dart` (lines 5–51) — Duration formatting functions receive `AppLocalizations` but completely ignore it
- `lib/core/utils/time_utils.dart:67` — `DateFormat.yMd()` uses system locale instead of app locale
- `lib/core/utils/color_utils.dart:29–52` — `getColorLabel()` returns hardcoded English color names
- `lib/l10n/app_es.arb` — Missing translations for several keys present in `app_en.arb`
- `lib/l10n/app_es.arb` — Grammatically incorrect Spanish translations

## Issue 1: Duration helpers ignore localization entirely

The private helpers `_getDurationDays`, `_getDurationHours`, `_getDurationMinutes`, and `_getDurationSeconds` each accept an `AppLocalizations l10n` parameter but return **hardcoded English abbreviations** ("1d", "2h", etc.) regardless of locale:

```dart
String _getDurationDays(int count, AppLocalizations l10n) {
  if (count == 1) return '1d';  // l10n unused
  return '${count}d';             // l10n unused
}
```

The ARB files **do** define `durationDays`, `durationHours`, `durationMinutes`, `durationSeconds` plural strings, but the code never calls them. This means every user — whether their locale is Spanish, English, or any future language — sees English duration abbreviations like "2d 3h 5m".

**Expected**: `l10n.durationDays(count)` etc. should be called so each locale returns its own formatted string.

## Issue 2: `DateFormat.yMd()` bypasses app locale

In `formatDate()` (line 67), the date for non-special dates is formatted using `DateFormat.yMd().format(date)`, which uses the **system** locale rather than the Flutter app's configured locale. Users with a Spanish system locale but English app locale will see mixed locales.

**Expected**: Use `DateFormat.yMd(l10nLocale)` with the app's locale, or a locale-aware `DateFormat`.

## Issue 3: Color labels are hardcoded English

`ColorUtils.getColorLabel()` returns hardcoded English color names ("Blue", "Green", "Orange", "Purple", "Pink", "Cyan", "Amber", "Deep Orange", "Blue Grey"). These are displayed in the UI with no localization.

**Expected**: Add color label translations to the ARB files and retrieve them via `l10n` in a new `getColorLabel(l10n)` overload or static utility.

## Issue 4: Missing Spanish ARB translations

Several translation keys from `app_en.arb` are absent from `app_es.arb`:
- `practiceOptions` (tooltip for practice options button)
- `appTitle` (transcribed as "StudyKing" but should likely be localized or have a justification comment)

Additionally, several keys from `app_en.arb` that exist in `app_es.arb` lack `@description` metadata, making future translation work harder.

## Issue 5: Spanish grammar — "Enfócate" is informal imperative

In `app_es.arb`, the translation for `focusOnMistakes` is "Enfócate en tus errores" (informal "focus yourself"). For an educational/study app, the standard formal register is "Enfóquese en sus errores".

Also, "Precisión" for `accuracy` is technically valid but in the context of quiz results, "Exactitud" is more idiomatic in Spanish educational software.

## Rationale

These are high-value i18n improvements because they affect **every non-English user** in real, visible ways:
- Duration abbreviations appear in study sessions and study plans — a core app feature
- Date formatting appears in session history — a core app feature
- Color labels appear in subject management — a visible UI element
- Missing/wrong translations degrade trust in localized apps
- The duration and date formatting issues cannot be fixed by adding more ARB entries alone — the code logic must be corrected first

## Acceptance Criteria

1. `_getDurationDays`, `_getDurationHours`, `_getDurationMinutes`, `_getDurationSeconds` in `time_utils.dart` call `l10n.durationDays(count)`, `l10n.durationHours(count)`, etc. instead of returning hardcoded strings.
2. `formatDate()` in `time_utils.dart` uses a locale-aware `DateFormat` that respects the app's current locale (not the system locale).
3. `ColorUtils.getColorLabel()` is either removed (if the UI already uses localized labels) or replaced with a localized version using the ARB translation system.
4. `app_es.arb` contains translations for all keys present in `app_es.arb` that exist in `app_en.arb`.
5. "Enfócate en tus errores" → "Enfóquese en sus errores" in `app_es.arb`.
6. "Precisión" → "Exactitud" (or the equivalent idiomatic Spanish term for quiz accuracy) in `app_es.arb`.
7. Regenerate `app_localizations_es.dart` and `app_localizations.dart` after fixes.
