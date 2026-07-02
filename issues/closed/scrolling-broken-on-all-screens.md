# Scrolling broken on all screens (Linux desktop)

**Severity:** critical
**Affected area:** All screens (Dashboard, Settings, Practice, Focus Timer, etc.)
**Reported by:** user

## Description

Scrolling via two-finger trackpad gesture and keyboard (arrow keys, Page Up/Down) does not work on any screen. However, **click-and-drag scrolling works** (clicking and dragging the scrollable content with the mouse/trackpad button). This reveals that the scroll infrastructure (physics, layout, dimensions) is functional — the issue is specifically with how `PointerScrollEvent` (trackpad scroll) and keyboard scroll events are delivered to scrollable widgets.

## Steps to reproduce

1. Launch the app on Linux desktop (Flutter 3.44.0)
2. Navigate to Settings screen — content is long enough to require scrolling
3. Attempt to scroll down using **two-finger trackpad gesture** → nothing happens
4. Attempt to scroll using **arrow keys** or **Page Down** → nothing happens
5. **Click and drag** the content with the mouse/trackpad button → scrolling works

## Expected behavior

- Two-finger trackpad scrolling should work natively (as in any Linux desktop app)
- Keyboard arrow keys / Page Up-Down should scroll the active scrollable
- Click-and-drag is a mobile-appropriate fallback, not the primary scroll method on desktop

## Actual behavior

- Trackpad two-finger scroll: no response
- Keyboard scroll: no response
- Click-and-drag scroll: works ✅

## Root cause analysis

### Confirmed: Click-and-drag works → scroll infrastructure is fine
Since click-and-drag works, this rules out:
- Layout constraint issues (zero-height viewport, overflow)
- Scroll physics issues (`AlwaysScrollableScrollPhysics`, `ClampingScrollPhysics`)
- Widget tree / `AnimatedSwitcher` / `RepaintBoundary` issues
- Scroll controller issues

The `dragDevices` configuration in `_AppScrollBehavior` must be correct for `PointerDeviceKind.mouse` (which handles click-and-drag).

### Cause #1: Two-finger trackpad scrolling not working — Likely Flutter Linux embedding issue

On Linux, two-finger trackpad scroll generates `PointerScrollEvent` events via GDK. These events should be handled by `Scrollable`'s internal `Listener(onPointerSignal:)` callback, which routes them to `ScrollPosition.handlePointerScroll()`.

Since click-and-drag works but trackpad doesn't, the issue is isolated to how the Linux Flutter embedding converts GDK touchpad scroll events into Flutter `PointerScrollEvent`:
- The events may not be generated at all (Flutter embedding bug on this Linux config)
- Or the events are generated with an unexpected device kind or delta format
- Or the events are being consumed by a widget before reaching the scrollable

**Code-side mitigation:** Adding `PointerDeviceKind.trackpad` to `dragDevices` in `_AppScrollBehavior` (`lib/main.dart:472`) may help if the Linux embedding routes trackpad events through the drag system on some configurations.

### Cause #2: Keyboard scrolling not working — Likely `FocusTraversalGroup` blocking focus

`FocusTraversalGroup` wraps scrollable content on most screens (Settings line 142, Dashboard line 151, etc.), creating a separate `FocusScope`. This can prevent the scrollable's internal `FocusNode` from receiving focus, which is required for keyboard scroll events (arrow keys, Page Up/Down) to be dispatched to the scrollable via `ScrollIntent`/`ScrollAction`.

## Code analysis

### `_AppScrollBehavior` — missing `PointerDeviceKind.trackpad`

**File:** `lib/main.dart:472-477`
```dart
@override
Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
    // PointerDeviceKind.trackpad is MISSING
};
```

### `FocusTraversalGroup` on affected screens

| Screen | File:Line | Wrapping pattern |
|---|---|---|
| DashboardScreen | `lib/features/dashboard/presentation/dashboard_screen.dart:151` | `SingleChildScrollView > FocusTraversalGroup > Column` |
| SettingsScreen | `lib/features/settings/presentation/settings_screen.dart:142` | `FocusTraversalGroup > ListView` |
| MentorScreen | `lib/features/mentor/presentation/mentor_screen.dart:695` | `FocusTraversalGroup > Column > Expanded > ListView.builder` |
| LessonListScreen | `lib/features/lessons/presentation/lesson_list_screen.dart:166` | `FocusTraversalGroup > ListView.builder` |
| PracticeResultsScreen | `lib/features/practice/presentation/screens/practice_results_screen.dart:57` | `FocusTraversalGroup > SingleChildScrollView` |
| QuickGuideScreen | `lib/features/quickguide/presentation/quick_guide_screen.dart:299` | `FocusTraversalGroup` wrapping body |

### Screens with NO `FocusTraversalGroup` (confirmed scrolling works via click-and-drag)

| Screen | File | Scroll wrapper |
|---|---|---|
| PracticeScreen | `lib/features/practice/presentation/screens/practice_screen.dart:1114` | `RefreshIndicator > ListView` |
| FocusTimerScreen | `lib/features/focus_mode/presentation/focus_timer_screen.dart:595` | `SingleChildScrollView` with `AlwaysScrollableScrollPhysics` |

## Suggested approach

1. **Add `PointerDeviceKind.trackpad`** to `_AppScrollBehavior.dragDevices` in `lib/main.dart:477`:
   ```dart
   Set<PointerDeviceKind> get dragDevices => {
     PointerDeviceKind.touch,
     PointerDeviceKind.mouse,
     PointerDeviceKind.stylus,
     PointerDeviceKind.trackpad,
     PointerDeviceKind.unknown,
   };
   ```

2. **Remove `FocusTraversalGroup` from scrollable wrappers** to fix keyboard scrolling. Move it outside the scrollable (wrap the entire `Scaffold` body) or remove it entirely on screens with only one scrollable. Key files:
   - `lib/features/settings/presentation/settings_screen.dart:142`
   - `lib/features/dashboard/presentation/dashboard_screen.dart:151`
   - `lib/features/mentor/presentation/mentor_screen.dart:695`
   - `lib/features/lessons/presentation/lesson_list_screen.dart:166`

3. **Test on the actual Linux device** to verify whether trackpad scrolling is a Flutter embedding issue or a code-level issue. Run with `flutter run --verbose` to check if `PointerScrollEvent` events are logged.

4. **Check Flutter Linux embedding** — if the issue persists after code changes, it may be a Flutter 3.44.0 Linux-specific bug where GDK touchpad events are not properly mapped to `PointerScrollEvent`. Consider:
   - Testing with a mouse wheel to isolate desktop scroll event handling
   - Filing a Flutter issue if mouse wheel works but trackpad doesn't
   - Upgrading Flutter version
