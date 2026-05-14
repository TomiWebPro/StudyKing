# UI/UX Issue: Font Size & Animation Accessibility — Double-Scaling in main.dart

## Context

`main.dart` applies text sizing in two independent layers: (1) a `fontSize` parameter passed into `AppTheme.createTextTheme()`, and (2) the system `textScaler` re-applied via a `MediaQuery` override in the `MaterialApp.builder`. These layers compound instead of coördinating, producing text that is significantly larger than the user intended when the system accessibility font scale is active. This is a **pervasive accessibility defect** affecting every screen in the application.

### Code Path (main.dart:110–149)

```dart
final systemTextScaler = MediaQuery.textScalerOf(context);          // e.g. 1.25
final userFontSize = settings.fontSize.clamp(14.0, 30.0);           // e.g. 18
final systemScaledSize = systemTextScaler.scale(16.0);              // = 20
final effectiveFontSize = userFontSize < systemScaledSize           // = max(18, 20)
    ? systemScaledSize                                              // = 20
    : userFontSize;                                                 // chosen

// Layer 1: theme receives 20 as body base size
theme: AppTheme.lightTheme(fontSize: effectiveFontSize),

// Layer 2: system textScaler (1.25) is re-applied on top
builder: (context, child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: systemTextScaler,    // double-scales the themed 20px → 25px
    ),
    child: child!,
  );
},
```

| User font | System scale | Intended | Actual rendered | Error |
|-----------|-------------|----------|----------------|-------|
| 14        | 1.0         | 14       | 14             | none  |
| 18        | 1.25        | 18       | 25             | +39%  |
| 14        | 1.25        | 14       | 25             | +79%  |
| 22        | 1.5         | 22       | 36             | +64%  |

The `effectiveFontSize` formula also replaces the user's chosen size with the system-scaled value **whenever the system scale exceeds the user preference**, which defeats the purpose of providing a separate in-app slider. A user who explicitly picks `14` should see `14`-based theming, not `20`.

## Affected Files

| File | Role |
|---|---|
| `lib/main.dart` (lines 110–149) | `effectiveFontSize` calculation + `MediaQuery` rebuild |
| `lib/core/theme/app_theme.dart` (lines 4–21) | `createTextTheme(fontSize)` — all text styles derive from this param |
| `lib/features/settings/presentation/settings_screen.dart` (lines 284–320) | Font-size slider allows 10–30 (`_showFontSizeDialog`) |
| `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart` (lines 42–48, 96–106) | Pulse animation ignores `reduceMotion` setting (accessibility) |
| `lib/features/practice/presentation/widgets/practice_session_nav_buttons.dart` (lines 17–44) | Previous/Next stacked vertically instead of side-by-side on wider screens |

## Rationale

1. **Accessibility regression** — Users who rely on system font scaling (1.15×–1.5×) because of low vision will see text 39–79 % larger than they configured. This can cause layout overflow, clipped text, and a broken experience across *every* screen.

2. **Defeats user preference** — The `effectiveFontSize = max(user, systemScaled)` logic silently discards the user's in-app choice whenever the OS accessibility scale is active. The settings slider becomes misleading.

3. **Compounding with `reduceMotion` gap** — The `FocusTimerWidget` pulse animation (circular progress ring pulsates via `_pulseController`) never checks `settings.reduceMotion` or `MediaQuery.reduceMotionOf(context)`. A user who disables animations for vestibular reasons still sees intrusive pulsation.

4. **Layout inefficiency in practice navigation** — `PracticeSessionNavButtons` renders Previous and Next as two full-width buttons stacked vertically inside a `Column`. On phones ≥360 dp this wastes vertical space; on tablets it looks broken. A `Row` with `Expanded` children would be more natural and consistent with platform conventions.

## Acceptance Criteria

- [ ] `effectiveFontSize` in `main.dart` uses the **user's chosen `fontSize` directly** for the `TextTheme`, and the `MediaQuery.builder` **disables** system text scaling (`TextScaler.noScaling`) so the theme is the sole authority for type size.
- [ ] OR — if system scaling must be preserved — the `fontSize` passed to `AppTheme` is reset to the base (16) and the user's preference is applied *only* through `textScaler`. Verify that the rendered size matches `settings.fontSize` regardless of the OS accessibility scale.
- [ ] `FocusTimerWidget` pulse animation is gated by `MediaQuery.reduceMotionOf(context)` — when `true` the pulse scale factor stays at `1.0` permanently.
- [ ] `PracticeSessionNavButtons` uses a `Row` with evenly weighted children on breakpoints ≥`sm` and falls back to a stacked column on `xs`.
- [ ] Verify with `flutter run` on a device with system font scale set to 1.25 and in-app font size set to 14: text in the dashboard, practice session, and settings should render at the same physical size as when system scale is 1.0.
