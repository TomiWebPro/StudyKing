# Systemic Hardcoded Color Values Break Dark Mode & Accessibility

## Context

The codebase uses 30+ instances of hardcoded Material `Colors.*` constants instead of `Theme.of(context).colorScheme` or `AppTheme` helpers. In dark mode, these colors (e.g. `Colors.white` on `Colors.blue.shade50`, `Colors.black` strokes on dark canvases, `Colors.green` status badges) produce illegible contrast ratios and fail WCAG 2.1 AA compliance. This affects users with visual impairments, those using dark theme, and those relying on high-contrast mode.

The app already defines a theming system in `lib/core/theme/app_theme.dart` (with `lightTheme`, `darkTheme`, `highContrastLightTheme`, `highContrastDarkTheme`) and helper utilities like `AppTheme.progressColor()` — but many widgets bypass the theme entirely.

## Affected Files

| File | Issue | Lines |
|---|---|---|
| `lib/features/questions/presentation/widgets/math_expression_widget.dart` | All colors hardcoded (`Colors.blue.shade50`, `Colors.blue[700]`, `Colors.teal[700]`, `Colors.deepOrange.shade700`, `Colors.green`, etc.) — completely unreadable in dark mode | 24, 26, 184, 189, 194, 223, 246, 260, 270, 285, 294, 315, 362-366 |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | `Colors.white` backgrounds and `Colors.red` buttons break in dark mode | 63, 91, 109, 117, 127, 235-236, 267 |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | Status indicator colors hardcoded (`Colors.blue`, `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.grey`) | 181-185, 265-267, 272, 276, 280, 284, 297, 302, 322 |
| `lib/features/ingestion/presentation/upload_screen.dart` | SnackBar `backgroundColor: Colors.red` / `Colors.green` | 84, 117, 142, 151 |
| `lib/features/settings/presentation/api_config_screen.dart` | Same SnackBar color pattern | 54, 78, 87, 104, 126, 133, 142 |
| `lib/features/teaching/presentation/tutor_screen.dart` | `Colors.green` for correct count chip | 197 |
| `lib/features/planner/presentation/widgets/progress_overlay_widget.dart` | Hardcoded `Colors.green`/`Colors.orange`/`Colors.red` instead of `AppTheme.progressColor()` | 44-48 |
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | Stroke default `Colors.black` invisible on dark canvas | 290 |
| `lib/core/widgets/metric_card.dart` | `Colors.grey` fallback instead of `colorScheme.onSurfaceVariant` | 46 |
| `lib/core/widgets/animated_bar_chart.dart` | `Colors.blue` default accent | 18 |

## Rationale

The app already supports theme switching (light, dark, high-contrast variants) via `lib/core/theme/app_theme.dart`, and the settings feature includes a reduce-motion toggle. Hardcoded colors directly contradict the existing design system investment. Every new screen that uses raw `Colors.*` instead of `Theme.of(context).colorScheme.*` creates a regression point:

1. **Dark mode becomes unusable** — light-on-light or dark-on-dark text is invisible.
2. **High-contrast mode is defeated** — hardcoded colors bypass the contrastLevel parameter in `ColorScheme.fromSeed(contrastLevel: 1.0)`.
3. **Maintenance burden** — fixing dark mode per-widget is more costly than a systematic sweep.
4. **Accessibility non-compliance** — WCAG 2.1 AA requires a minimum 4.5:1 contrast ratio for normal text. Hardcoded light pastels on white backgrounds fail this.

## Proposed Fix Pattern

Replace each hardcoded color with the semantically equivalent theme value:

| Hardcoded | Theme Replacement |
|---|---|
| `Colors.blue.shade50` / `Colors.grey[100]` (background tints) | `colorScheme.surfaceContainerHighest` or `colorScheme.surfaceVariant` |
| `Colors.blue[700]`, `Colors.deepOrange.shade700`, etc. (foreground text/icons) | `colorScheme.primary`, `colorScheme.secondary`, `colorScheme.tertiary`, or `colorScheme.error` |
| `Colors.red` / `Colors.green` (status/error) | `colorScheme.error` / `colorScheme.primary` or `colorScheme.tertiary` |
| `Colors.white` (container backgrounds) | `colorScheme.surface` |
| `Colors.black` (canvas stroke) | `colorScheme.onSurface` |
| `Colors.grey` (fallback) | `colorScheme.onSurfaceVariant` |
| `Colors.green` / `Colors.orange` / `Colors.red` (progress) | `AppTheme.progressColor(value, context)` |
| Status colors (`Colors.blue`/`Colors.green`/`Colors.red`/`Colors.orange`/`Colors.grey`) | Add helper in `AppTheme` (e.g. `AppTheme.statusColor(status, context)`) mapping each status to the appropriate `colorScheme` role |

## Acceptance Criteria

1. **Math Expression Widget** (`math_expression_widget.dart`): Every `Colors.*` reference is replaced with `Theme.of(context).colorScheme.*` or a derived semantic color. Verify rendered output in both light and dark mode — all operators, subscripts, numbers, and solution containers must be legible with ≥4.5:1 contrast.

2. **Subject Detail Screen** (`subject_detail_screen.dart`): `Colors.white` and `Colors.red` are replaced. Verify the delete button, stats cards, and section backgrounds render correctly in dark mode.

3. **LLM Task Manager** (`llm_task_manager_screen.dart`): Status colors (`running`, `done`, `failed`, `cancelled`, `queued`) use a theme-aware helper. Verify each status chip is distinguishable in both light and dark mode.

4. **SnackBars** (`upload_screen.dart`, `api_config_screen.dart`): All `backgroundColor: Colors.red` and `backgroundColor: Colors.green` replaced with `colorScheme.error` and `colorScheme.primary` respectively.

5. **Tutor Screen** (`tutor_screen.dart`): `Colors.green` correct-count chip uses `colorScheme.primary` or `colorScheme.tertiary`.

6. **Progress Overlay** (`progress_overlay_widget.dart`): Uses `AppTheme.progressColor()` instead of raw `Colors.green`/`Colors.orange`/`Colors.red`.

7. **Canvas Drawing** (`canvas_drawing_widget.dart`): Default stroke color is `colorScheme.onSurface` instead of `Colors.black`. Verify drawn strokes are visible on dark canvas backgrounds.

8. **Metric Card** (`metric_card.dart`): Fallback color uses `colorScheme.onSurfaceVariant`.

9. **No regressions**: All existing unit tests and widget tests pass. Visual diff confirms light mode appearance is preserved (or improved with better semantic color alignment).

## Effort Estimate

Approximately 40-60 minutes per file for a total of ~4-6 hours, including verification in both light and dark mode across phone and tablet form factors.
