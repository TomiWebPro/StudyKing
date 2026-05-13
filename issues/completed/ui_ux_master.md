# Issue: Hardcoded Color Values Break Dark Mode, High-Contrast Accessibility, and Thematic Consistency

## Severity: High

## Context

The app defines a full `ThemeData` / `ColorScheme` system via `AppTheme` (light, dark, high-contrast light, high-contrast dark) in `lib/core/theme/app_theme.dart:73-189`. Utility functions like `AppTheme.progressColor()`, `AppTheme.masteryColor()`, and `AppTheme.urgencyColor()` already exist to derive semantic colors from the current `colorScheme`. **Despite this, at least 8 screens/widgets bypass the theme system entirely with hardcoded `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.grey.shade*`, `Colors.blue`, and `Colors.white` values.**

This makes the high-contrast accessibility theme and dark mode partially non-functional on the most data-dense screens.

## Affected Files and Hardcoded Values

| File | Line(s) | Hardcoded Value | Should Use |
|------|---------|----------------|------------|
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 159-161, 267, 311-312, 669-671 | `Colors.green`, `Colors.orange`, `Colors.red`, `Colors.blue`, `Colors.teal`, `Colors.purple` | `Theme.of(context).colorScheme.primary/tertiary/error`, `AppTheme.progressColor()` |
| `lib/features/practice/presentation/analytics_dashboard.dart` | 159-190, 267 | `Colors.green`, `Colors.blue`, `Colors.teal`, `Colors.purple` (MetricCard accents) | `Theme.of(context).colorScheme` equivalents |
| `lib/features/practice/presentation/learning_plan_dashboard.dart` | 144-148 (container decorations) | Implicit `surfaceContainerHighest` vs `cardPadding` mismatch | Consistent `ResponsiveUtils.cardPadding` / theme-derived decoration |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | 183-185, 194-196 | `Colors.green`, `Colors.orange`, `Colors.grey` | `Theme.of(context).colorScheme.primary/tertiary/error` |
| `lib/features/questions/ui/widgets/single_answer_widget.dart` | 51 | `Colors.grey.shade300` (border) | `Theme.of(context).colorScheme.outline` |
| `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` | 71, 144, 162, 326 | `Colors.grey.shade300/200/600/700`, `Colors.blue.shade400`, `Colors.white` | `Theme.of(context).colorScheme.outline/onSurface/primaryContainer` |
| `lib/features/sessions/presentation/session_history_screen.dart` | 248-249 | `Theme.of(context).primaryColor` (Material 3 deprecation) | `Theme.of(context).colorScheme.primary` |
| `lib/features/practice/presentation/practice_session_screen.dart` | 626 | `Theme.of(context).primaryColor` (deprecated) | `Theme.of(context).colorScheme.primary` |
| `lib/core/widgets/animated_bar_chart.dart` | 55 | `theme.cardColor`, `theme.dividerColor` | `theme.colorScheme.surfaceContainerHighest`, `theme.colorScheme.outlineVariant` |

## Rationale

1. **Dark mode is broken** – e.g. `canvas_drawing_widget.dart:71` uses `Colors.grey.shade300` for border. In dark mode, `grey.shade300` is lighter than the surface, producing no visible border. `Colors.white` backgrounds at `:162` on dark mode create a bright white card inside a dark theme.
2. **High-contrast theme is ineffective** – `AppTheme.highContrastLightTheme` and `AppTheme.highContrastDarkTheme` exist and are toggled via `settings.highContrastEnabled` (`main.dart:111`), but hardcoded colors ignore any contrastLevel changes.
3. **Thematic inconsistency** – `dashboard_screen.dart:159` uses `Colors.green` for accuracy >= 80 but `analytics_dashboard.dart:264` uses `AppTheme.progressColor()` which maps to `cs.primary`. Same metric, two different colors depending on which screen the user visits.
4. **Missed abstraction** – `AppTheme.progressColor(value, context)` (app_theme.dart:124) already encodes the green→tertiary→error logic using colorScheme colors, but `dashboard_screen.dart:669-671` duplicates this logic with hardcoded green/orange/red.

## Acceptance Criteria

- [ ] All 8 files above replace hardcoded `Colors.*` values with `Theme.of(context).colorScheme.*` or existing `AppTheme.*Color()` helpers.
- [ ] The canvas drawing widget renders visible borders and backgrounds in both light and dark mode.
- [ ] Dark mode toggle produces no unreadable or invisible UI elements.
- [ ] High-contrast mode (`settings.highContrastEnabled`) actually changes border widths, contrast ratios, and outline colors on all screens.
- [ ] No regression: accuracy/progress/urgency colors remain semantically correct (red=low, green=high) but derive from the active colorScheme.
- [ ] All `Theme.of(context).primaryColor` usages (deprecated in Material 3) are migrated to `Theme.of(context).colorScheme.primary`.
- [ ] `session_history_screen.dart:248` - the `MetricCard` accent uses `Theme.of(context).colorScheme.primary` instead of `Theme.of(context).primaryColor`.
- [ ] `practice_session_screen.dart:626` - `_buildMiniStat` fallback color uses `Theme.of(context).colorScheme.primary`.
- [ ] `animated_bar_chart.dart:55` - container decoration uses `colorScheme.surfaceContainerHighest` and `colorScheme.outlineVariant`.

## Example Fix Pattern

```dart
// Instead of:
color: Colors.green,
// Use:
color: AppTheme.progressColor(accuracy, context),

// Instead of:
color: Colors.grey.shade300,
child: Icon(Icons.radio_button_unchecked, color: Colors.grey),
// Use:
color: Theme.of(context).colorScheme.outline,
child: Icon(Icons.radio_button_unchecked, color: Theme.of(context).colorScheme.onSurfaceVariant),

// Instead of:
backgroundColor: Colors.amber.shade50,
// Use:
backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
```

## Test Guidance

Manually verify:
1. Toggle **Settings → Theme → Dark** – all cards, borders, text, and icons are legible.
2. Toggle **Settings → Accessibility → High Contrast** – borders thicken to 2px, outline colors change, contrast ratios increase.
3. Compare `DashboardScreen` vs `AnalyticsDashboard` accuracy metric colors – they should match.
4. Canvas drawing widget border is visible in dark mode.
