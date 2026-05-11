# Internationalisation: Practice Module Has 50+ Hardcoded Strings

## Context

The StudyKing app uses a Flutter ARB-based localisation system (`lib/l10n/`) with `AppLocalizations` for English and Spanish. However, the practice feature screens contain **over 50 hardcoded English strings** that bypass the localisation system entirely. These strings cover critical user-facing content including prompts, labels, feedback messages, empty states, and navigation buttons.

### Affected Files

- `lib/features/practice/presentation/practice_screen.dart` (lines: 71, 79, 96, 131–136, 140, 150, 154, 167, 183–184, 189–191, 196–198, 203–205, 225, 269–271, 342, 392, 443–444, 460)
- `lib/features/practice/presentation/practice_session_screen.dart` (lines: 149–150, 259, 273, 292, 298, 306, 376, 445, 460, 473, 497, 523, 529, 572, 579, 583–587, 593)

### Examples of Missing Translations

From `practice_screen.dart`:
- `'Practice Mode'` (AppBar title)
- `'No Practice Sessions Yet'` (empty state heading)
- `'Add subjects and questions to start practicing'` (empty state body)
- `'Practice Modes'`, `'Quick Practice'`, `'10 random questions'`, `'Coming soon'`, `'Spaced Repetition'`, `'Topic Focus'`, `'Practice specific topics'`, `'Weak Areas'`, `'Focus on mistakes'`
- `'Your Subjects'`, `'Ready for practice'`
- `'Practice Options'` (tooltip), `'No Subjects'` / `'Practice'` (FAB label)

From `practice_session_screen.dart`:
- `'No Questions Available'`, `'There are no questions for the selected subject/topic. Start creating questions!'`
- `'Practice'`, `'Time'`, `'Score'`, `'Correct'` (stat labels)
- `'Your Answer'`, `'Your Answer (N characters)'` (input labels)
- `'Submit Answer'`, `'Correct!'`, `'Incorrect'`
- `'Previous'`, `'Next'`
- `'Session Results'`, `'Practice Complete!'`, `'Total Questions'`, `'Correct Answers'`, `'Accuracy'`, `'Practice Again'`

## Rationale

Users with a device language set to Spanish see a mixed-experience: the planner, subjects tab, and settings are fully localised, but every screen within the practice flow remains in English. This is a degraded experience for non-English users and makes the app appear unfinished. Additionally, any future expansion to other languages (French, German, etc.) would require manual string replacements rather than being handled by the existing i18n infrastructure.

## Acceptance Criteria

1. All user-visible strings in `practice_screen.dart` and `practice_session_screen.dart` are replaced with `AppLocalizations.of(context).<key>` calls using keys defined in `app_en.arb`.
2. All new keys are added to `app_en.arb` with `description` metadata, and corresponding translations are added to `app_es.arb`.
3. The ARB files are regenerated via `flutter gen-l10n` (or equivalent) to update the generated `app_localizations_*.dart` files.
4. The Spanish translations use natural phrasing (e.g., `'Práctica'` not `'Práctica'` on every label — some labels like `'No Questions Available'` should be `'No hay preguntas disponibles'` not a literal word-for-word translation).
5. No regressions: build passes and existing localized strings continue to display correctly.
