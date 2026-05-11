# Issue: Build proper i18n support and migrate Planner + shared date/time copy

## Why this is high value
StudyKing currently ships user-facing copy as hardcoded English strings, and the app shell is not configured for Flutter localization delegates or supported locales. This blocks non-English users from using core flows and makes future translation expensive because strings are embedded directly in widgets and utility formatters.

The Planner flow is a strong first migration target (high visibility, many user-facing strings, dynamic sentence generation, validation feedback), and shared time/date formatting also contains English-only output that appears across features.

## Evidence and affected files
- `lib/main.dart:226` - `MaterialApp` is missing `localizationsDelegates`, `supportedLocales`, and locale wiring.
- `lib/features/planner/presentation/planner_screen.dart` - hardcoded English UI/feedback strings (title, labels, button states, snackbar messages, schedule section, `Topic` text).
- `lib/core/utils/time_utils.dart` - English-only tokens and labels (`Unknown`, `Today`, `Yesterday`, `d/h/m/s`) in shared formatting paths.

## Internationalisation gaps to address
1. No localization infrastructure in app root, so locale-specific resources are not formally supported.
2. Planner copy is not translatable and includes dynamic text that is not localization-safe.
3. Dynamic grammar is English-centric (e.g., "over X days", "total hours") and lacks pluralization handling.
4. Date/time helper output mixes locale-aware date formatting with non-localized relative labels/units, causing inconsistent localization quality.

## Proposed fix (single implementation issue)
Implement first-class Flutter i18n and migrate Planner + shared date/time strings to localized resources:

- Add l10n setup (ARB-based) and wire it into `MaterialApp`.
- Introduce at least `en` + one additional locale (project-selected target language) to validate real multilingual behavior.
- Replace hardcoded Planner strings with localized keys, including interpolated messages and pluralized variants.
- Localize shared date/time labels and duration units used by `time_utils` (or route them through localized formatters).

## Acceptance criteria
- `MaterialApp` declares localization delegates and supported locales, and locale switching follows app settings/system locale.
- All user-facing text in `planner_screen.dart` is sourced from localization keys (no hardcoded English literals).
- Planner snackbar/status sentences use parameterized translations with correct pluralization for day/hour/session-style values.
- `formatDate` relative labels and duration unit output are localized (no English-only `Unknown/Today/Yesterday/d/h/m/s` in UI output).
- Localization resources include complete keys for Planner + shared date/time strings in all supported locales, with no missing-translation runtime warnings.
