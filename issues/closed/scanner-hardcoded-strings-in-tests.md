# [Scanner] Hardcoded user-facing strings in test assertions instead of l10n

**Source:** automatic scanner
**Severity:** minor

## Finding

Several test files use hardcoded English strings for `find.text(...)` assertions instead of referencing `l10n.*` keys. This means:
- Tests will fail if the app is localized to a non-English locale
- Tests don't verify that l10n keys actually resolve correctly
- String changes in the app require updating both l10n files AND test files

## Locations

### `test/features/practice/presentation/screens/practice_session_screen_test.dart` (lines 22–29)

```dart
const _kCorrectFeedback = 'Correct!';
const _kIncorrectFeedback = 'Incorrect';
const _kPracticeComplete = 'Practice Complete!';
const _kSubmitAnswer = 'Submit Answer';
const _kNext = 'Next';
const _kPrevious = 'Previous';
const _kNoQuestionsAvailable = 'No Questions Available';
const _kPracticeAgain = 'Practice Again';
```

These are user-facing strings used in `expect(find.text(...))` assertions. Any change to the app's l10n strings will silently break these tests.

### `test/features/questions/presentation/widgets/canvas_drawing_widget_ui_test.dart`

- Lines 531, 551, 568, 589, 608, 639: `find.widgetWithText(ElevatedButton, 'Save Drawing')`
- Line 595: `find.textContaining('Failed to save drawing')`
- Line 645: `find.text('Drawing saved.')`

### `test/features/planner/presentation/planner_screen_test.dart`

- Lines 648–649: `find.text('Your Study Schedule')`, `find.text('Plan Summary')`
- Line 665: `find.text('Create Study Plan')`

## Impact

- Tests are **locale-dependent** — they only pass when the app is in English
- Tests don't exercise the l10n layer — a missing or incorrect l10n translation goes undetected
- String refactoring requires updating both source and test files

## Recommendation

- For widget tests that render user-facing text, inject `AppLocalizations` via `ProviderScope` overrides and reference `l10n.myKey` in assertions
- Alternatively, use localized string constants from a test helper that mirrors the l10n keys
- For simple existence checks where the exact string doesn't matter, consider using `find.byType` or semantic matchers instead
- Exception: Tests in `test/l10n/` that explicitly test translations may use hardcoded strings by design — this finding only concerns non-l10n test files
