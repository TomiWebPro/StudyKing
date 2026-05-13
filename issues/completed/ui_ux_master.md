# Issue: Systemic Lack of Responsive Layout, Adaptive Design, and Accessibility Infrastructure

## Context

The entire application is built with a fixed-width, phone-first assumption. Every screen uses hardcoded padding (`EdgeInsets.symmetric(horizontal: 16)` or `EdgeInsets.all(16)`), zero `LayoutBuilder`/`OrientationBuilder` usage outside one avatar picker, and no responsive framework dependency. The result is a brittle layout that breaks on tablets, landscape orientation, large-font accessibility modes, and foldable devices.

Simultaneously, accessibility infrastructure is essentially absent: only 3 widgets in the entire codebase carry `Semantics` wrappers, there are zero checks for system accessibility settings (`boldText`, `highContrast`, `accessibleNavigation`), touch targets routinely fall below the 48x48 dp WCAG recommendation, and there is no keyboard focus management for non-touch input. The `UserProfile.accessibilitySettings` field exists as a raw string defaulting to `'default'` but has no corresponding UI, logic, or effect anywhere in the app.

## Affected Files (all presentation-layer files need changes; these are the primary touch-points)

| File | Issue |
|------|-------|
| `lib/main.dart` (lines 234–258) | `MaterialApp` has no `builder` for `MediaQuery` text/bold overrides; no `scrollBehavior` for keyboard nav |
| `lib/core/theme/app_theme.dart` (line 4–122) | Text theme is a flat multiplier of a single base size; no support for `textScaleFactor` beyond the global slider; no `highContrastTheme` or `darkHighContrastTheme` |
| `lib/features/settings/presentation/settings_screen.dart` (lines 38, 96, 144–176, 178–200) | `ListView` padding is fixed 16dp horizontal; font-size slider (line 186) shows no label/value readout; theme picker is a flat `ModalBottomSheet` with no focus management |
| `lib/features/settings/presentation/profile_screen.dart` (lines 204–206, 276–427, 483) | Only `LayoutBuilder` in the app (avatar icons); text fields have fixed `OutlineInputBorder` with no `MediaQuery` size adaptation; `Semantics` wraps avatars but not text fields or buttons |
| `lib/features/settings/data/models/settings_box.dart` (lines 6–107) | `fontSize` is a global scalar with no connection to OS accessibility settings; no `contrast` or `boldText` toggle fields |
| `lib/features/settings/data/models/user_profile_model.dart` (line 20) | `accessibilitySettings` is dead code — stored but never read by any widget or service |
| `lib/features/practice/presentation/practice_screen.dart` (lines 155, 222–268) | `GridView.count` with `crossAxisCount: 2` is fixed; on landscape or tablet the cards become comically wide or cramped; no breakpoint-based column switching |
| `lib/features/practice/presentation/practice_session_screen.dart` | (not fully reviewed but shares the same pattern) |
| `lib/features/questions/ui/widgets/question_card_widget.dart` (lines 92, 143–146, 156–187) | Fixed `margin: EdgeInsets.all(16)`, fixed-width buttons (`width: double.infinity`), no `MediaQuery` for large-font readability |
| `lib/features/questions/ui/widgets/single_answer_widget.dart` | (not fully reviewed but likely shares the same fixed layout) |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` (lines 136, 147–148, 260–330) | Chat bubble `maxWidth` is `size.width * 0.75` — uses `MediaQuery` correctly but only for width, not for font scaling |
| `lib/features/subjects/presentation/subject_list_view.dart` (lines 60–95, 98–105, 110–191) | Empty state icon is a fixed `size: 64`, subject cards have fixed padding/structure with no responsive adjustment |
| `lib/features/subjects/presentation/subject_detail_view.dart` | (not fully reviewed but likely shares the same fixed layout) |
| `lib/features/subjects/presentation/subject_management_screen.dart` | (not fully reviewed but likely shares the same fixed layout) |
| `lib/features/subjects/presentation/subject_selection_screen.dart` | (not fully reviewed but likely shares the same fixed layout) |
| `lib/features/sessions/presentation/session_tracker_screen.dart` (lines 207, 210–316) | Fixed padding `EdgeInsets.all(16)`, timer `displayLarge` text does not scale with system font size; no landscape adaptation |
| `lib/features/sessions/presentation/session_history_screen.dart` (lines 164, 207–220, 270–340) | Summary row uses `Row` with `Expanded` (OK) but `ListView.separated` items have `EdgeInsets.symmetric(horizontal: 16, vertical: 4)` — fixed |
| `lib/features/planner/presentation/planner_screen.dart` (lines 112, 127–150) | `Row` of two `Expanded` text fields is the only layout; no handling for narrow screens or large fonts causing overflow |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | (not reviewed but follows same pattern) |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | (not reviewed but follows same pattern) |
| `lib/features/lessons/presentation/topic_list_screen.dart` | (not reviewed but follows same pattern) |

## Rationale

1. **WCAG 2.1 AA Failure — Resize Text (1.4.4)**: The global font-size slider (range 10–30) overrides the user's system `textScaleFactor` instead of composing with it. If a user sets their OS to 150% and the app slider to 16, the effective size is only 16 — the user's intent is discarded. Furthermore, no widget checks `MediaQuery.textScalerOf(context)` beyond 3 scattered references.

2. **WCAG 2.1 AA Failure — Target Size (2.5.8 / 2.5.5)**: A 48x48 dp minimum is advised. The app has `SizedBox(width: 20, height: 20, child: CircularProgressIndicator(...))` (profile_screen.dart line 264, settings_screen.dart line 157) and `IconButton` with `constraints: BoxConstraints()` that defaults to 48x48 only if not overridden — but several inline `GestureDetector`/`InkWell` taps lack guaranteed minimum sizes.

3. **No Orientation Support**: On a 10" tablet in landscape, the `GridView.count(crossAxisCount: 2)` in `practice_screen.dart` shows two ludicrously wide cards. On a foldable in half-fold portrait, some screens overflow. There is zero orientation-change handling anywhere.

4. **Dead Accessibility Code**: `UserProfile.accessibilitySettings` (default `'default'`) is stored in Hive but never consumed. Any future accessibility features will require schema migration and UI that doesn't exist.

5. **No High-Contrast / Dark Mode Variations**: `lightTheme` and `darkTheme` exist, but there is no `highContrast` variant for either. Users who need high contrast (e.g. low-vision) get the same low-contrast M3 `surfaceContainerHighest` backgrounds.

6. **Semantics Coverage < 5%**: Only the avatar picker (profile_screen.dart:194), chat messages (quick_guide_screen.dart:141–142), and canvas drawing (canvas_drawing_widget.dart) carry semantic labels. Every `ListTile`, `TextField`, `Switch`, `Slider`, card, and navigation destination lacks a meaningful `Semantics` wrapper. Screen reader users will hear generic "button" / "text field" announcements with no context.

7. **No Keyboard / Focus Navigation**: There are zero `FocusTraversalGroup`, `Focus`, or `Actions` widgets. Users navigating with a hardware keyboard or switch device cannot efficiently move through form fields, settings rows, or question options.

## Acceptance Criteria

### A. Responsive Layout Infrastructure

- [ ] **A1**: Add a responsive layout dependency (`flutter_screenutil`, `responsive_builder`, or a custom `LayoutBuilder`-based breakpoint system) to `pubspec.yaml`.
- [ ] **A2**: Wrap `MaterialApp` (in `main.dart`) with a `MediaQuery`-based responsive builder that provides a standard `ResponsiveBreakpoint` (e.g. `xs` < 600, `sm` 600–840, `md` 840–1200, `lg` > 1200) to all descendant widgets.
- [ ] **A3**: Replace every hardcoded `EdgeInsets.symmetric(horizontal: 16)` and `EdgeInsets.all(16)` in every presentation file with a responsive spacing value derived from the current breakpoint.
- [ ] **A4**: `practice_screen.dart` `GridView.count` must dynamically switch `crossAxisCount` based on screen width (e.g. 2 columns on xs, 3 on sm, 4 on md+).
- [ ] **A5**: Every `ListView.builder` padding must scale with breakpoint.
- [ ] **A6**: Session tracker and history screens must lay out their summary stats in a `Wrap` or responsive `Grid` so they don't overflow on narrow screens.

### B. System Accessibility Integration

- [ ] **B1**: In `main.dart`, wrap `body`/`builder` with a widget that reads `MediaQuery.boldTextOf(context)`, `MediaQuery.highContrastOf(context)`, and `MediaQuery.textScalerOf(context)`, composing these with the user's `fontSize` setting. The app font must always **at least** match the system `textScaleFactor`.
- [ ] **B2**: Add `highContrastTheme` and `darkHighContrastTheme` to `AppTheme`, activated automatically when the OS requests high contrast.
- [ ] **B3**: Replace the raw `accessibilitySettings` string in `user_profile_model.dart` with a structured `AccessibilityPreferences` Hive model containing `boldText`, `highContrast`, `reduceMotion`, `largeTouchTargets` booleans; wire it to actual UI in the profile/settings screens; remove dead string field.

### C. Touch Target Sizing (WCAG 2.5.5/2.5.8)

- [ ] **C1**: Audit every `IconButton`, `InkWell`, `GestureDetector`, and `ListTile` in the codebase. Any tappable area under 48x48 dp must be wrapped in a `SizedBox(width: 48, height: 48, child: ...)` or have `minSize: 48` via `Material`.
- [ ] **C2**: The 20x20 `CircularProgressIndicator` in app bars (profile_screen.dart, settings_screen.dart) must be in a 48x48 container to meet minimum touch target if it receives taps.

### D. Semantics Coverage

- [ ] **D1**: Give every `ListTile` (including those in settings, profile, practice mode cards, subject cards, session history) a `Semantics` wrapper with a meaningful `label` derived from its `title`/`subtitle`.
- [ ] **D2**: Give every `Slider` (`_showFontSizeDialog`, `_showTimeoutDialog`) a `Semantics` slider label and value readout.
- [ ] **D3**: Give every `SwitchListTile` a `Semantics` label.
- [ ] **D4**: Add `Semantics` to the `NavigationBar` destinations in `main.dart` (currently they only have `icon` + `label` which is partially handled by Material, but verification labels should exist).
- [ ] **D5**: Ensure the chat input field in `quick_guide_screen.dart` has a proper semantic hint that matches the localized `messageInputHint`.
- [ ] **D6**: Add `MergeSemantics` around tightly grouped controls (e.g. avatar icon + label).

### E. Keyboard & Navigation

- [ ] **E1**: Add `FocusTraversalGroup` ordering to settings screen rows and profile form fields so Tab/Shift+Tab navigation follows a logical order.
- [ ] **E2**: Ensure all dialogs (`AlertDialog`, `ModalBottomSheet`) have initial focus on the first actionable control (or a close button) and trap focus within the dialog.
- [ ] **E3**: Add `shortcuts` and `actions` for common operations (e.g. Ctrl+Enter to send chat message, Escape to close dialogs).

### F. Orientation & Foldable Support

- [ ] **F1**: Every screen must be verified in landscape mode on a phone form-factor (360x780 dp) with no overflow or clipped content.
- [ ] **F2**: Every screen must be verified in portrait mode on a tablet form-factor (820x1180 dp) with reasonable whitespace usage.
- [ ] **F3**: Every screen must be verified in split-screen mode (approx 360x400 dp) with no overflow.

### G. Verification

- [ ] **G1**: Run `flutter run` on a physical Android device in landscape + portrait.
- [ ] **G2**: Enable system font size to "Large" and verify no text is truncated or overflows.
- [ ] **G3**: Enable TalkBack / VoiceOver and verify all interactive elements are announced with meaningful labels.
- [ ] **G4**: Enable high-contrast mode in OS settings and verify the app switches to `highContrastTheme`.
- [ ] **G5**: Run `flutter test` — all existing tests must pass; add new tests for `ResponsiveBreakpoint` utilities, `AccessibilityPreferences` model, and `AppTheme.highContrastTheme`.
- [ ] **G6**: No regressions on the existing practice flow, settings changes, profile editing, chat, and session tracking.
