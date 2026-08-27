# Heatmap accessibility label uses raw double with locale-incorrect decimal

## Description
In `lib/features/dashboard/presentation/widgets/daily_activity_heatmap.dart:265`, the `_semanticLabel` method (used for the `Semantics` accessibility label of each heatmap cell) interpolates `entry.accuracy` — a `double` in the 0–100 range — directly into a string:

```dart
return '$dateStr: ${entry.attempts} ${l10n.sessionsLabel}, ${entry.accuracy}%';
```

This produces a period decimal separator unconditionally (e.g. `"85.5%"`) regardless of the user's locale, violating the i18n/number-formatting convention in AGENTS.md ("Never use `toStringAsFixed()` for user-facing numeric displays" and use the locale-aware helpers in `lib/core/utils/number_format_utils.dart`). It is also internally inconsistent with `_tooltipText` on line 254, which uses `entry.accuracy.round()` and with every other user-facing numeric display in the app that uses `formatPercent`/`formatDecimal`.

## Affected files/areas
- lib/features/dashboard/presentation/widgets/daily_activity_heatmap.dart:265 (and the `_semanticLabel` helper at lines 260–266)
- test/features/dashboard/presentation/widgets/daily_activity_heatmap_test.dart (should assert locale-aware output)

## Expected vs Actual
- Expected: the accessibility/semantic label renders the accuracy with the user's locale decimal separator (e.g. `"85,5%"` in `de`, `"85.5%"` in `en`) via `formatPercent(entry.accuracy, l10n.localeName)` (or `.round()` to match `_tooltipText`), consistent with the rest of the app.
- Actual: the accuracy is interpolated as a raw `double`, always using a period and ignoring locale.

## Acceptance Criteria
- [ ] `_semanticLabel` uses `formatPercent(entry.accuracy, l10n.localeName)` (or `.round()` to match `_tooltipText`) instead of `${entry.accuracy}%`.
- [ ] A widget test asserts the semantic label uses the locale decimal separator (e.g. German locale yields `"85,5%"`).
- [ ] `flutter analyze` and the heatmap test suite pass.
