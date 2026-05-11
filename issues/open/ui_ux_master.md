# Issue: Missing Text Scaling Infrastructure Causes UI Overflows at Non-Default Font Sizes

## Context
StudyKing has a user-configurable font size (`SettingsBox.fontSize`, range 10–30px) and a dedicated settings slider in `SettingsScreen._showFontSizeDialog`. The font size is stored in Hive and propagated via `TextTheme` in `StudyKingApp` (main.dart:240–266). However, the implementation has two critical gaps:

1. **Font size is not applied globally**: Only `bodyLarge`, `bodyMedium`, `bodySmall`, `titleLarge`, `titleMedium`, and `titleSmall` are overridden. All other text style contexts (chips, list tiles, buttons, labels, subtitles, captions, etc.) remain at Flutter's default font size and do not scale.

2. **No minimum touch target guarantees**: Flutter's Material components (ListTile, Chip, SwitchListTile, DropdownButton, etc.) used across all screens have hardcoded internal padding that does not account for enlarged text. Text-heavy chips in `QuestionCardWidget` (lines 99–113), `CheckboxListTile` options in `QuestionCardWidget` (line 254), avatar choice icons in `ProfileScreen` (60×60px, line 198–199), and the `_buildAvatarChoice` container (60×60px) all lack responsive sizing.

## Affected Files
- `lib/main.dart` — text theme overrides (lines 240–266), `SettingsController.updateFontSize` (lines 119–126)
- `lib/features/settings/presentation/settings_screen.dart` — font size dialog (lines 158–179)
- `lib/features/questions/ui/widgets/question_card_widget.dart` — chip labels, option text (lines 99–113, 254)
- `lib/features/settings/presentation/profile_screen.dart` — avatar containers, text fields
- `lib/features/sessions/widgets/session_analytics.dart` — chart labels (lines 129–144)
- `lib/features/practice/presentation/practice_screen.dart` — mode cards, subject cards
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — suggestion chips, message bubbles
- `lib/core/theme/app_theme.dart` — no `textTheme` defined; uses Material defaults

## Rationale
- **Accessibility**: WCAG 1.4.4 requires text to be resizable up to 200% without loss of content/functionality. Current implementation fails at font size >16 because chips truncate, list tiles overflow, and chat bubbles exceed screen width (0.75×MediaQuery width, `quick_guide_screen.dart:125–127`).
- **Responsive layout**: Fixed-pitch avatar icons (60×60), small chat input (48×48 button minimum per Material guidelines), and hardcoded grid child aspect ratios (`practice_screen.dart:179`) do not adapt to text size changes.
- **Design language inconsistency**: The app theme (`app_theme.dart`) defines no custom `textTheme`, so light/dark themes diverge — deep purple seed in `main.dart:232` vs indigo/deep purple in `app_theme.dart:17,56`. Font size overrides in `main.dart` do not exist in `app_theme.dart`, making theme-based scaling inconsistent.

## Acceptance Criteria
1. A global `textTheme` in `app_theme.dart` applies the user-selected `fontSize` multiplier to **all** `TextStyle` variants (`labelLarge`, `labelMedium`, `labelSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `bodyText1`, `bodyText2`, `caption`, `overline`, `button`, `buttonSmall`, all titles).
2. `StudyKingApp` reads `fontSize` from settings and passes it to `AppTheme.lightTheme` / `AppTheme.darkTheme` rather than overriding `TextTheme` in the widget tree.
3. All touch targets (avatar containers, chip touch areas, icon buttons) meet Material's 48×48dp minimum and scale with text size via `MediaQuery.textScaleFactor` or explicit `MediaQuery.size` constraints.
4. Wrapped text widgets (chat bubbles, chips, MCQ options) use `Flexible` or `FittedBox` with `BoxFit.scaleDown` to prevent overflow at large font sizes.
5. The `PracticeScreen` grid uses dynamic `childAspectRatio` based on available width rather than a fixed value.
6. All screens render correctly at 30px font size without horizontal overflow or text clipping on a 375dp-wide viewport.
