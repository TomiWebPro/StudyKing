# Mentor progress report shows raw `**` markdown instead of bold text

**Severity:** minor
**Affected area:** AI Mentor — Progress Report dialog
**Reported by:** user

## Description

The progress report dialog in the AI Mentor screen renders literal `**` characters where bold markdown syntax was intended. Strings like `**Total Study Time:**` and `**Completed Lessons:**` display the asterisks directly to the user (e.g. "**Total Study Time:** 5.0 hours" instead of "Total Study Time: 5.0 hours").

## Steps to reproduce

1. Open the AI Mentor screen.
2. Tap the "Progress Report" button (or trigger the report via the action chip).
3. Observe the stat rows under the accuracy bar — "Total Study Time", "Weekly Activity", "Completed Lessons", and "Topics Studied".
4. The `**` characters are visible around each label, e.g. `**Total Study Time:** 5.0 hours`.

## Expected behavior

The text should display cleanly without raw markdown syntax. Either:
- The labels should render as plain text (no visible `**`), or
- The labels should be styled as bold using Flutter `TextStyle` (`FontWeight.bold`).

## Actual behavior

Asterisks are shown literally in the dialog, e.g. `**Total Study Time:** 5.0 hours`, `**Completed Lessons:** 3`, etc. This looks like a rendering bug.

## Code analysis

### Root cause

The localization strings in `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` contain markdown-style `**` syntax intended for bold, but the UI uses plain `Text` widgets which do not parse markdown:

- **`lib/l10n/app_en.arb:3184`** — `"mentorTotalStudyTime": "**Total Study Time:** {hours} hours"`
- **`lib/l10n/app_en.arb:3193`** — `"mentorWeeklyActivity": "**Weekly Activity:** {attempts} attempts"`
- **`lib/l10n/app_en.arb:3202`** — `"mentorCompletedLessons": "**Completed Lessons:** {count}"`
- **`lib/l10n/app_en.arb:3211`** — `"mentorTopicsStudied": "**Topics Studied:** {count}"`

(Same patterns exist in the Spanish ARB at corresponding lines.)

These strings are consumed in `lib/features/mentor/presentation/mentor_screen.dart`:

- **`mentor_screen.dart:1286`** — `l10n.mentorTotalStudyTime(...)` passed to `_reportStatRow`
- **`mentor_screen.dart:1291`** — `l10n.mentorWeeklyActivity(...)` passed to `_reportStatRow`
- **`mentor_screen.dart:1295`** — `l10n.mentorCompletedLessons(...)` passed to `_reportStatRow`
- **`mentor_screen.dart:1299`** — `l10n.mentorTopicsStudied(...)` passed to `_reportStatRow`
- **`mentor_screen.dart:1280`** — `l10n.mentorCompletedLessons('').split(':').first` also contains `**`

The rendering widget is **`mentor_screen.dart:1460`** (`_reportStatRow`), which displays the string in a plain `Text` widget:

```dart
Widget _reportStatRow(BuildContext context, IconData icon, String text) {
  // ...
  child: Text(
    text,
    style: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  ),
  // ...
}
```

No markdown parsing is applied, so `**` is printed verbatim.

### Note on AI conversation markdown

The `mentor_context_builder.dart` uses separate `mentorContext*` l10n methods (e.g. `mentorContextTotalStudyTime`) which do NOT contain `**` — those are used for LLM context prompts and are fine. The `**`-containing methods are only used in the progress report dialog UI.

## Suggested approach

Two options, either is acceptable:

**Option A (cleanest):** Remove `**` from the ARB source strings:
1. Edit `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` — remove `**` from `mentorTotalStudyTime`, `mentorWeeklyActivity`, `mentorCompletedLessons`, and `mentorTopicsStudied`.
2. Re-run `flutter gen-l10n` to regenerate `lib/l10n/generated/`.
3. The dialog will display clean text without asterisks.

**Option B (preserve bold):** Apply bold styling in the widget:
1. Keep `**` in the ARB strings (so translators can see the intent).
2. In `_reportStatRow`, split the text on the `**` pattern and use `Text.rich` with `TextSpan` to apply `FontWeight.bold` to the label portion.
3. This preserves the bold visual while removing the raw asterisks.

Option A is simpler and sufficient because each stat row already has a contextual icon that provides visual hierarchy.
