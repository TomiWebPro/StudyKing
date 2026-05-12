# UI/UX Issue: Material 2/3 Hybrid Theme — Inconsistent Design Language Across All Screens

## Context

The app uses `useMaterial3: false` in `AppTheme` (`lib/core/theme/app_theme.dart:26,66`) while simultaneously adopting Material 3 widgets like `NavigationBar` (`lib/main.dart:285`). This creates a hybrid M2/M3 design language that produces visual inconsistency in every screen. The theme also sets `centerTitle: false` on AppBar globally, but individual screens override it to `centerTitle: true` (e.g., `practice_session_screen.dart:304`, `session_history_screen.dart:145`). Additionally, `ThemeMode.system` is missing from the theme selection bottom sheet, preventing users from following device-level dark/light preference.

## Affected Files

- `lib/core/theme/app_theme.dart` — M2 `ThemeData()` with `useMaterial3: false` (lines 26, 66)
- `lib/main.dart` — M3 `NavigationBar` on M2 theme (line 285)
- `lib/features/settings/presentation/settings_screen.dart` — Theme dialog omits `ThemeMode.system` (lines 134–156); inconsistent `AppBar` centering
- `lib/features/practice/presentation/practice_session_screen.dart` — `centerTitle: true` overrides theme default (line 304)
- `lib/features/sessions/presentation/session_history_screen.dart` — `centerTitle: true` overrides theme default (line 145); `centerTitle` and `elevation` set individually (lines 145–146)
- `lib/features/subjects/presentation/subject_detail_view.dart` — Custom tab bar without theme integration (lines 149–163); gradient header bypasses theme system
- `lib/features/settings/presentation/api_config_screen.dart` — Scoped header styles hardcoded (lines 94–101)
- `lib/features/settings/presentation/profile_screen.dart` — Hardcoded `Color(0xFFF5F5F5)`-adjacent danger card (line 391); inline font sizing (line 464)
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — Chat bubble uses `FittedBox` with `BoxFit.scaleDown` (lines 135–147), which can shrink message text to illegible sizes

## Rationale

1. **M2/M3 widget mismatch** — `NavigationBar` (M3) renders with M2 tokens: wrong shape, wrong elevation, wrong label styling. Cards from `CardThemeData` (M2 elevation 2 with rounded 12) conflict with M3 surface/container tokens. Buttons styled with M2 `ElevatedButton.styleFrom` ignore M3 elevation semantics.

2. **No `ThemeMode.system` option** — The theme picker bottom sheet offers only "Light" and "Dark". Users who rely on system-wide dark mode scheduling (e.g., Android 10+ dark theme toggle or macOS auto) cannot delegate theme choice to the OS. This is especially impactful for accessibility users who depend on system-wide high-contrast or dark themes.

3. **`FittedBox` on chat text** — Quick Guide message bubbles wrap text in `FittedBox(fit: BoxFit.scaleDown, ...)`. When a message exceeds the bubble's `maxWidth` (75% of screen width), the text is uniformly shrunk rather than wrapping naturally. A sentence longer than ~30 characters becomes illegibly small with no way for the user to zoom or scroll horizontally.

4. **Navigation inconsistency** — `centerTitle` switches between `true` and `false` across screens with no rationale. This breaks user spatial memory — the title location jumps left and right during navigation.

5. **Scattered visual constants** — Header fonts, icon sizes, and color values are hardcoded per-screen instead of sourced from `Theme.of(context).textTheme` or `colorScheme`. This increases maintenance burden and guarantees drift between screens as the theme evolves.

## Acceptance Criteria

1. **Choose M2 or M3** — Decide on a single design system and set `useMaterial3` consistently. If M3 is adopted, replace `NavigationBar`'s implicit M3 usage with an explicit M3 `NavigationBar` theme and migrate `CardTheme`, `ElevatedButtonTheme`, and `AppBarTheme` to M3 tokens.
2. **Add `ThemeMode.system`** — The theme picker in `settings_screen.dart:_showThemeDialog` must include a "System default" option that maps to `ThemeMode.system`.
3. **Remove `FittedBox` from chat bubbles** — Replace with standard `Text` wrapping inside a constrained `Container` so that long messages wrap naturally and remain at the font size defined by the user's accessibility settings.
4. **Unify `centerTitle`** — Set a single `centerTitle` value in `AppTheme.appBarTheme` and remove all per-screen overrides. Justify the choice: `false` for multi-tool screens (settings), `true` for focused-task screens (practice).
5. **Eliminate hardcoded visual constants** — Audit all settings/subject screens and replace inline `TextStyle(fontSize: …)` values with tokens from `Theme.of(context).textTheme`; replace literal `Color(0xFF…)` values with `colorScheme` lookups.
