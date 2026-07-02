# [Scanner] Hardcoded user-facing strings that should be in l10n/ARB files

**Source:** automatic scanner
**Severity:** major

## Finding

The project has excellent l10n coverage overall (~3,400+ ARB keys), but 9 hardcoded user-facing strings remain across 5 files. These strings are visible to end users and should be localized to support both English and Spanish locales.

## Locations

### 1. `lib/features/settings/presentation/settings_screen.dart` — Spaced Repetition section
- **Line 296**: `'Spaced Repetition'` — section heading
- **Line 297**: `'Min interval'` — tile title for SR min interval setting
- **Line 300**: `'Max interval'` — tile title for SR max interval setting
- **Line 303**: `'Daily review limit'` — tile title for SR daily review limit setting

These appear in the Study Preferences section. Nearby entries (e.g., `l10n.sessionDuration`) properly use l10n, making these inconsistent.

### 2. `lib/features/settings/presentation/api_config_screen.dart` — AI provider config
- **Line 149**: `'Please select a model before saving.'` — SnackBar error when saving without selecting a model
- **Line 590**: `'Provider Changed'` — AlertDialog title when switching AI provider
- **Line 591-593**: `'Changing the provider will clear the selected model...'` — AlertDialog body text
- **Line 598**: `'OK'` — AlertDialog action button label

Other dialogs in the same file properly use `l10n.unsavedChanges`, `l10n.cancel`, `l10n.discard`.

### 3. `lib/features/planner/presentation/widgets/syllabus_progress_card.dart` — Action chips
- **Line 173**: `'Practice Questions'` — ActionChip label
- **Line 178**: `'Start Lesson'` — ActionChip label

The adjacent chip on line 168 properly uses `l10n.uploadMaterials`.

### 4. `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — Confirm button
- **Line 327**: `'Confirm'` — FilledButton label in confirmation dialog

The cancel button on line 323 properly uses `l10n.cancel`.

### 5. `lib/features/questions/presentation/question_bank_screen.dart` — Export format button
- **Line 259**: `'JSON'` — FilledButton label in export dialog

The CSV button on line 258 properly uses `l10n.exportCsv`. An existing key `labelJson` is already in the ARB files (line 2915 of `app_en.arb`) and should be used instead.

## Recommendation

Add corresponding ARB keys to `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` for each hardcoded string, then replace the literals with `l10n.*` calls. Key suggestions:
- `srSectionTitle`, `srMinInterval`, `srMaxInterval`, `srDailyReviewLimit` for settings
- `selectModelWarning`, `providerChangedTitle`, `providerChangedBody` for api_config
- `practiceQuestions`, `startLesson` for syllabus_progress_card
- `confirm` for lesson_booking_sheet
- Use existing `labelJson` for question_bank_screen
