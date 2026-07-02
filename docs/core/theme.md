# Theming & Accessibility

## Theme System

StudyKing uses **Material Design 3** with full support for light and dark themes. The theme is defined in `lib/core/theme/app_theme.dart`.

### Theme Modes

- **Light theme** — `AppTheme.lightTheme(fontSize, largeTouchTargets)`
- **Dark theme** — `AppTheme.darkTheme(fontSize, largeTouchTargets)`
- **High contrast light** — `AppTheme.highContrastLightTheme(fontSize, largeTouchTargets)`
- **High contrast dark** — `AppTheme.highContrastDarkTheme(fontSize, largeTouchTargets)`

The active theme is controlled by the `themeModeEnum` setting (system/light/dark) from the settings provider.

### Theme Mode Switching

Users can toggle between light, dark, and system themes in Settings. The current mode is stored in `SettingsModel` and wired through the `settingsProvider` Riverpod provider.

## Accessibility Features

### Font Size Scaling

- Base font size is configurable (10–30 range, clamped via `UiConfig.minFontSize` / `maxFontSize`)
- Combined with system text scale factor, clamped to 1.0–2.0 range
- Applied via `MediaQuery.textScaler` override in `StudyKingApp.builder`

### Bold Text

- Can be enabled system-wide or via settings toggle
- Applied via `MediaQuery.boldTextOf(context)` combined with the `boldText` setting flag

### High Contrast Mode

- Separate high-contrast theme variants
- Can be triggered by system settings or manually enabled
- Uses `MediaQuery.highContrastOf(context)` combined with settings flag

### Large Touch Targets

- Optional larger minimum tap targets for accessibility
- Applied via `MaterialApp` theme configuration

### Reduce Motion

- Disables animation transitions between tabs
- Uses `KeyedSubtree` instead of `AnimatedSwitcher` when enabled

## Theme Application

The theme is applied in `StudyKingApp.build()`:

```dart
MaterialApp(
  theme: useHighContrast
      ? AppTheme.highContrastLightTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets)
      : AppTheme.lightTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets),
  darkTheme: useHighContrast
      ? AppTheme.highContrastDarkTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets)
      : AppTheme.darkTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets),
  themeMode: settings.themeModeEnum,
);
```

## Widgets

Shared UI components are in `lib/core/widgets/`:

| Widget | Purpose |
|---|---|
| `SplashScreen` | Initial loading screen during startup |
| `ShimmerWidget` | Loading placeholder with shimmer animation |
| `ErrorRetryWidget` | Error state with retry button |
| `EmptyStateWidget` | Empty data state with illustration |
| `LoadingIndicator` | Centered loading spinner |
| `LoadingScreen` | Full-screen loading overlay |
| `MetricCard` | Stats/metric display card |
| `GradientContainer` | Container with gradient background |
| `NotFoundScreen` | 404-style route not found screen |
| `DialogUtils` | Reusable dialog helpers |
| `SnackbarUtils` | Reusable snackbar helpers |
| `ConversationInput` | Chat-style text input widget |
| `PracticePerformanceCard` | Practice performance display |
| `AnimatedBarChart` | Simple animated bar chart widget |
