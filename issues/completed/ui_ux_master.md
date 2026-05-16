# UI/UX Issue: Systemic accessibility, theming, responsive navigation, and i18n gaps

## Context

A review of the presentation layer across all features reveals four high-impact UI/UX problems that collectively degrade the experience for users with accessibility needs, users on non-mobile form factors, users in dark/high-contrast mode, and non-English users.

---

## Issue 1 — Accessibility: `TextScaler.noScaling` prevents system font scaling

**File:** `lib/main.dart:135`

```dart
MediaQuery.of(context).copyWith(
  boldText: systemBoldText,
  textScaler: TextScaler.noScaling,  // ← disables user font-size preferences
)
```

**Problem:** The global `MediaQuery` override uses `TextScaler.noScaling`, which flatly ignores the user's system font size setting (`Settings > Display > Font size` on Android, `Display > Text size` on iOS, etc.). Visually impaired users who rely on system-wide font scaling are unable to read any UI text in the app. While the app has its own in-app `fontSize` setting (`settings.fontSize`), this is a separate opt-in mechanism that many users will not discover.

**Rationale:** WCAG Success Criterion 1.4.4 (Resize Text) requires that text can be resized up to 200% without loss of content or functionality. `noScaling` is a direct violation. The in-app slider at `lib/features/settings/presentation/settings_screen.dart` partially mitigates this, but:
- Only accessible via Settings → Font Size (hidden from first-time users)
- Does not respond to OS-level accessibility preferences
- Users with motor impairments who rely on OS-wide settings are excluded

**Acceptance criteria:**
- Remove `TextScaler.noScaling` (default behaviour uses `TextScaler.linear` which respects the system text scale factor)
- OR replace with `TextScaler.linear(clamp(1.0, systemFactor * effectiveFontSize / 16, 2.0))` if there is a strong justification for capping
- Verify that all screens render correctly at 1.5× and 2.0× text scale factors (no overflow, no clipped text, no overlapping widgets)
- The in-app font-size slider should compound with (multiply) the OS scale factor

---

## Issue 2 — Design language: Hardcoded colors break dark mode and high-contrast themes

**Files:** `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart:81`, `lib/features/teaching/presentation/tutor_screen.dart:305`

```dart
// lesson_progress_bar.dart:81
remaining <= 5
    ? Colors.orange   // ← hardcoded, not a theme token

// tutor_screen.dart:305
_isVoiceListening ? Colors.red : null   // ← hardcoded, should use colorScheme.error
```

**Problem:** Hardcoded material `Colors.orange` and `Colors.red` do not adapt:
- In dark mode, `Colors.orange` (0xFFFF9800) maintains high luminance against a dark background but has poor contrast on the `AlwaysStoppedAnimation` composited on `surfaceContainerHighest`.
- In high-contrast mode (`highContrastLightTheme` / `highContrastDarkTheme`), these colors are not part of the seed-derived scheme and jar against the increased contrast palette.
- `Colors.orange` (`#FF9800`) has a contrast ratio of only ~2.8:1 against `surfaceContainerHighest` in light mode, failing WCAG AA for non-text elements.

**Rationale:** A review of the entire widget layer shows that **every other file** correctly uses `Theme.of(context).colorScheme.*` tokens. These two locations are regression points that were likely added as quick visual indicators without considering theming. The `AppTheme` class already defines `progressColor()` at `lib/core/theme/app_theme.dart:124`, but `LessonProgressBar` does not use it.

**Affected scenarios:**
1. High-contrast theme enabled: orange bar is visually jarring, no longer matches the increased-contrast outline palette
2. Custom seed colour: only `primary`/`tertiary`/`error` derive from seed; `Colors.orange` stays fixed
3. Mic icon in `TutorScreen` — `Colors.red` is not `colorScheme.error`, so in dark mode the high-luminance red overpowers the UI

**Acceptance criteria:**
- Replace `Colors.orange` in `lesson_progress_bar.dart:81` with `Theme.of(context).colorScheme.tertiary` (or use `AppTheme.progressColor()` which maps ranges to `primary`/`tertiary`/`error`)
- Replace `Colors.red` in `tutor_screen.dart:305` with `Theme.of(context).colorScheme.error`
- Verify visually in both light and dark themes at default and high-contrast settings

---

## Issue 3 — Responsive navigation: Bottom NavigationBar used on all screen widths, no NavigationRail for tablets

**Files:** `lib/main.dart:281-315`

**Problem:** The app uses `NavigationBar` (Material 3 bottom navigation) unconditionally for all form factors. On tablets (≥840px width, `ScreenBreakpoint.md` and `lg`) and desktop windows, the bottom nav:
- Wastes horizontal space that could be used for a side rail with labels
- Violates Material 3 guidance that recommends `NavigationRail` for medium–large screens
- The 5-destination bar becomes crowded on tablets in landscape mode (text labels clip)

The `MainScreen` at `lib/main.dart:206` has no `LayoutBuilder` or breakpoint-conditional build:
```dart
body: Stack(children: [...]),
bottomNavigationBar: NavigationBar(...)
```

**Rationale:** The `ResponsiveUtils` class already defines breakpoints (`xs`/`sm`/`md`/`lg`) and several widgets use `LayoutBuilder` or `bp` checks to adapt (e.g., `SummaryRow`, `PracticeSessionNavButtons`, `PlannerScreen`). The navigation shell is the most fundamental layout component and should be the first to adapt, yet it is fully static.

The 5-tab structure maps naturally to `NavigationRail`:
- `NavigationRail` with `leading` containing the FAB (dashboard) — replaces the separate `FloatingActionButton`
- `NavigationRail.destinations` for subjects / practice / mentor / focus / settings
- `NavigationRail.extended` can optionally show labels

**Acceptance criteria:**
- At breakpoints ≥ `ScreenBreakpoint.md` (840px), replace `NavigationBar` with `NavigationRail` pinned to the leading edge
- Move the dashboard FAB into the `NavigationRail.leading` or a `NavigationRail`-adjacent slot so it does not require a separate `FloatingActionButton`
- Preserve `Offstage` + `TickerMode` tab switching (or migrate to `IndexedStack` if preferred)
- Verify on a 10" tablet (landscape and portrait) and a desktop window ≥1200px

---

## Issue 4 — Localization: Hardcoded untranslated string in PlannerScreen tabs

**File:** `lib/features/planner/presentation/planner_screen.dart:225`

```dart
Tab(text: l10n.studyPlanner),
const Tab(text: 'Calendar'),      // ← hardcoded English, not localised
Tab(text: l10n.roadmaps),
```

**Problem:** The second tab in the Planner screen's `TabBar` is a `const Tab(text: 'Calendar')` literal while both neighbouring tabs use `AppLocalizations.of(context)!.studyPlanner` and `AppLocalizations.of(context)!.roadmaps`. This causes `'Calendar'` to display in English for all locales.

**Rationale:** Since `AppLocalizations` is auto-generated with a `.calendar` key (or should have one added), using a raw string here breaks the i18n contract. Every other string in the planner screen correctly uses `l10n.*`.

**Acceptance criteria:**
- Add `calendar` to the ARB localisation file(s)
- Replace `const Tab(text: 'Calendar')` with `Tab(text: l10n.calendar)`
- Verify no regressions in `TabBar` rendering (the `Tab` is no longer `const`, which is acceptable since the screen is stateful)

---

## Summary

| Issue | Area | Severity | Effort |
|-------|------|----------|--------|
| 1. Text scaling disabled | Accessibility | Critical | Small (1–3 files) |
| 2. Hardcoded theme colours | Design language | High | Small (2 files) |
| 3. No responsive navigation shell | Responsive layout | High | Medium (main.dart) |
| 4. Hardcoded 'Calendar' string | i18n | Medium | Trivial (1 string) |
