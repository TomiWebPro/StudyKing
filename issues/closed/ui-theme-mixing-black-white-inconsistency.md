# UI theme shows mixed black/white widgets on startup (especially on Ubuntu Linux)

**Severity:** major
**Affected area:** UI theme / NavigationBar / overall theming
**Reported by:** user

## Description

When opening the app with no explicit theme selected (defaults to `ThemeMode.system`), some widgets render with a dark/black appearance while others render with a light/white appearance simultaneously. The issue occurs only sometimes (rare race condition) and is most noticeable on Ubuntu Linux. The user has not selected any explicit theme mode in Settings, so the app uses the default `ThemeMode.system`.

The root cause is multi-faceted:

1. **NavigationBar is missing `surfaceTintColor: Colors.transparent`** — The `AppBarTheme` in `_baseTheme()` explicitly sets `surfaceTintColor: Colors.transparent` (line 44), but the `NavigationBarThemeData` (line 94) does not. With `elevation: 2` on the NavigationBar, Flutter's Material 3 applies a default `surfaceTintColor` (from `colorScheme.surfaceTint`, a semi-transparent deep purple overlay from the seed color `#673AB7`/`#9575CD`). This causes the bottom navigation bar to render with a visible purple tint, making it look visually inconsistent with the scaffold background and app bar — like it belongs to a different theme.

2. **Different surface color tokens create visual discrepancy** — The scaffold uses `colorScheme.surface`, cards use `surfaceContainerHighest`, the nav bar uses `surfaceContainerHigh`. In dark mode these are different shades of dark (near-black vs dark-gray), and in light mode they're different shades of light (white vs light-gray). Without consistent surface-tint handling, this can look like a broken mix of themes.

3. **SettingsController async initialization race** — The `SettingsController` (created by `settingsProvider`) starts with default `SettingsBox()` (`themeMode = 0` = `ThemeMode.system`) and calls `_loadSettings()` asynchronously in its constructor. On rare occasions, the widget tree may partially render with the default theme before the saved settings are applied, or the `platformBrightness` detection on Linux may produce inconsistent results during startup, causing some widgets to resolve to light theme while others resolve to dark.

4. **Card surfaceTint also inconsistent** — High-contrast themes explicitly set `surfaceTintColor: Colors.transparent` on cards (lines 205, 324) but regular themes do not. This creates a secondary inconsistency where cards may also show a tint overlay in normal mode.

## Steps to reproduce

1. Install and run the app on Ubuntu Linux
2. Do not change the theme in Settings (leave it as default)
3. Close and reopen the app repeatedly
4. Observe that sometimes the navigation bar has a visibly different tint/color from the rest of the app, or individual widgets appear to belong to different themes

## Expected behavior

All widgets should consistently use the same resolved theme (all light or all dark) with no visible tint mismatch between the navigation bar, scaffold background, cards, and other UI elements.

## Actual behavior

- The bottom NavigationBar renders with a purple surface-tint overlay (from `colorScheme.surfaceTint`) that makes it look mismatched with the rest of the app
- Different surface containers (`surface`, `surfaceContainerHigh`, `surfaceContainerHighest`) can visually appear to belong to different themes
- On rare occasions (race condition during startup), some widgets may render in light while others render in dark

## Code analysis

- `lib/core/theme/app_theme.dart:94-99` — `NavigationBarThemeData` has `elevation: 2` but **no `surfaceTintColor`**. Unlike the `AppBarTheme` (line 44) which sets `surfaceTintColor: Colors.transparent`, the NavigationBar inherits the default Material 3 surface tint behavior, causing a visible colored overlay on top of `surfaceContainerHigh`.
- `lib/core/theme/app_theme.dart:48-55` — `CardThemeData` in the base theme (used by light/dark) does **not** set `surfaceTintColor`, while the high-contrast variants (lines 197-206, 316-325) explicitly set `surfaceTintColor: Colors.transparent`. This inconsistency means cards in normal mode can also show a surface tint.
- `lib/core/providers/shared_providers.dart:55-57` — `SettingsController` constructor initializes with `super(SettingsBox())` (default `themeMode = 0` = `ThemeMode.system`), then calls `_loadSettings()` async. The race between default state and loaded state can cause a brief window where the theme is unresolved.
- `lib/features/settings/data/models/settings_box.dart:112` — Default `themeMode = 0` which resolves to `ThemeMode.system` via the `themeModeEnum` getter (line 142-145).

## Suggested approach

1. Add `surfaceTintColor: Colors.transparent` to `NavigationBarThemeData` in `_baseTheme()` (around line 94 in `app_theme.dart`) to match the `AppBarTheme` behavior.
2. Add `surfaceTintColor: Colors.transparent` to the base `CardThemeData` in `_baseTheme()` (around line 54) to match the high-contrast variants, making card tinting consistent across all theme modes.
3. Consider pre-loading the settings synchronously or showing a loading state until the `SettingsController` has finished loading, to eliminate the async race on theme resolution.
4. Consider using a single consistent surface color token (e.g., always `surfaceContainerHighest`) for major UI containers instead of mixing `surface`, `surfaceContainerLowest`, `surfaceContainerHigh`, and `surfaceContainerHighest` across different widgets, which can create visual fragmentation.
