# Issue: Accessibility Preferences Unconsumed, Hardcoded UI Strings, Missing SafeArea, and Navigation/Responsive Inconsistencies

## Severity: High

## Summary

Five distinct high-value UI/UX problem categories that degrade the experience for users with accessibility needs, non-English speakers, and users with notched/physical-keyboard devices.

---

### 1. Accessibility Preferences Declared but Never Consumed

The `AccessibilityPreferences` model (`lib/features/settings/data/models/accessibility_preferences.dart:6-24`) defines four boolean flags: `boldText`, `highContrast`, `reduceMotion`, and `largeTouchTargets`. Users can toggle `highContrast`, `largeTouchTargets`, and `reduceMotion` via `lib/features/settings/presentation/settings_screen.dart:54-70`. However, `reduceMotion` and `largeTouchTargets` are **never read** by any widget in the entire app.

#### Impact

- **`reduceMotion`**: Users who experience vertigo/nausea from motion (vestibular disorders, WCAG 2.1 Guideline 2.3) toggle this on but the app continues animating: `AnimatedBarChart` always plays its grow-from-zero animation (`lib/core/widgets/animated_bar_chart.dart:99-118`), `AnimatedSwitcher` fades feedback in (`lib/features/questions/ui/widgets/single_answer_widget.dart:86-92`), and the typing indicator bounces dots (`lib/features/teaching/presentation/widgets/chat_bubble.dart:128-131`).
- **`largeTouchTargets`**: Users who toggle this expect 48×48 dp minimum touch targets app-wide. Widgets like `_buildIconButton` in `CanvasDrawingWidget` (`lib/features/questions/ui/widgets/canvas_drawing_widget.dart:164`) compute padding as `ResponsiveUtils.minTouchTarget * 0.3` (14.4 dp), producing a sub-30 dp effective target. No widget checks `largeTouchTargets`.

#### Affected Files

| File | Lines | Issue |
|------|-------|-------|
| `lib/core/widgets/animated_bar_chart.dart` | 99–118 | `TweenAnimationBuilder` always animates; no `reduceMotion` check |
| `lib/features/questions/ui/widgets/single_answer_widget.dart` | 86–92 | `AnimatedSwitcher` always animates feedback |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 128–131 | Typing indicator always loops |
| `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 152–170 | `_buildIconButton` touch target too small, no `largeTouchTargets` check |
| `lib/features/settings/presentation/settings_screen.dart` | 54–70 | Switch toggles exist but writes never propagate to widgets |

---

### 2. Hardcoded English Strings Bypass l10n System

The app has a full `AppLocalizations` system with English and Spanish localizations (`lib/l10n/generated/`). Despite this, several user-visible strings are hardcoded in English.

#### Affected Strings

| File | Line(s) | Hardcoded Text |
|------|---------|----------------|
| `lib/features/settings/presentation/settings_screen.dart` | 428 | `'Request timed out. Please try again.'` |
| `lib/features/settings/presentation/settings_screen.dart` | 430 | `'Unable to load models. Please try again.'` |
| `lib/features/settings/presentation/settings_screen.dart` | 452 | `'Retry'` |

These appear in the `_AiModelLoadingSheet` widget when an API call fails or times out. A Spanish-speaking user configuring their AI model will see English error messages.

---

### 3. Bottom Sheets Missing SafeArea

At least 5 modal bottom sheets wrap content in a `Container` without `SafeArea`. On devices with system navigation bars, gesture handles, or keyboard insets, content is truncated or obscured.

#### Affected Files

| File | Line(s) | Sheet |
|------|---------|-------|
| `lib/features/practice/presentation/practice_screen.dart` | 380–420 | `_showSubjectSelector` |
| `lib/features/practice/presentation/practice_screen.dart` | 423–479 | `_showPracticeModeDialog` |
| `lib/features/practice/presentation/practice_screen.dart` | 514–547 | `_showTopicSelector` |
| `lib/features/practice/presentation/practice_screen.dart` | 611–686 | `_showSpacedRepetitionSubjectSelector` |
| `lib/features/practice/presentation/practice_screen.dart` | 703–738 | `_startWeakAreasPractice` subject selector |

The fix pattern for each is to change:

```diff
- showModalBottomSheet(
-   builder: (sheetContext) => Container(
-     padding: ...
```

to:

```dart
showModalBottomSheet(
  builder: (sheetContext) => SafeArea(
    child: Container(
      padding: ...
```

---

### 4. Drawing Canvas Hardcoded to 300px Height

`lib/features/questions/ui/widgets/canvas_drawing_widget.dart:69` sets `height: 300` regardless of screen size.

- On a phone in landscape, 300 px may force the canvas offscreen.
- On a 12-inch tablet, 300 px wastes ~75% of vertical space.
- `ResponsiveUtils` already provides height helpers; the canvas should use `MediaQuery.sizeOf(context).height * 0.4` or similar, constrained by a sensible min/max.

---

### 5. Inconsistent Navigation Pattern

The codebase mixes two navigation approaches in the same files, making the routing layer unreliable and keyboard/accessibility navigation harder to audit.

**Pattern A (named routes via `AppRoutes` constants):**
- `lib/features/dashboard/presentation/dashboard_screen.dart:426-431` — `Navigator.pushNamed(context, AppRoutes.practiceSession, ...)`
- `lib/features/planner/presentation/planner_screen.dart:139-148` — `Navigator.pushNamed(context, AppRoutes.tutor, ...)`

**Pattern B (direct `MaterialPageRoute`):**
- `lib/features/lessons/presentation/lesson_list_screen.dart:89-98` — `Navigator.push(context, MaterialPageRoute(...))`
- `lib/features/lessons/presentation/lesson_list_screen.dart:175-182` — `Navigator.push(context, MaterialPageRoute(...))`
- `lib/features/practice/presentation/practice_screen.dart:576-585` — `Navigator.push(context, MaterialPageRoute(...))`

#### Impact

- Named routes support deep linking, deferred route loading, and `onGenerateRoute` analytics hooks; direct `MaterialPageRoute` bypasses all of them.
- A developer adding a middleware guard (e.g., "require API key before practice") must patch two parallel code paths.

---

### 6. Keyboard Focus Traversal Incomplete

`FocusTraversalGroup` is used in several screens (`lib/features/settings/presentation/settings_screen.dart:36`, `lib/features/planner/presentation/planner_screen.dart:157`, `lib/features/practice/presentation/practice_session_screen.dart:382`) but only `PlannerScreen` sets focus order via `NumericFocusOrder` (`planner_screen.dart:164-165`).

Without explicit `FocusTraversalOrder`, the default reading-order traversal may produce illogical tab sequences in complex layouts (e.g., the dashboard grid of MetricCards, bottom-sheet option lists).

---

## Acceptance Criteria

- [ ] **Accessibility**: `reduceMotion` flag is checked before `TweenAnimationBuilder` / `AnimatedSwitcher` executes; animations skip to end state when true. `largeTouchTargets` flag elevates all interactive padding to 48 dp minimum.
- [ ] **l10n**: The three hardcoded English strings in `_AiModelLoadingSheet` are migrated to `AppLocalizations` methods (add new keys if missing in `.arb`).
- [ ] **SafeArea**: All bottom sheets in `practice_screen.dart` wrap their content in `SafeArea` + top padding preserved (non-content area).
- [ ] **Canvas responsiveness**: `CanvasDrawingWidget` height derives from `MediaQuery.sizeOf(context)` with a clamp (e.g., 200–500 dp).
- [ ] **Navigation consistency**: All `Navigator.push(context, MaterialPageRoute(...))` calls in lesson list/detail and practice screens are replaced with `Navigator.pushNamed(context, AppRoutes.xxx, arguments: ...)`. Register any missing routes in `AppRouter`.
- [ ] **Keyboard navigation**: At minimum, `SettingsScreen`, `PlannerScreen`, and `PracticeSessionScreen` get explicit `FocusTraversalOrder` widgets on their interactive children.
- [ ] **No regressions**: All existing tests pass. Manual verification of bottom-sheet rendering on a device with a gesture bar (iPhone X-style) and on a device with soft navigation keys.
