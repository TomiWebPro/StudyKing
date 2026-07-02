# Focus time sessions display shows "0./0" on first launch

**Severity:** minor
**Affected area:** Focus Time → session summary card
**Reported by:** user

## Description

On first launch (no sessions completed), the Focus Time section on the Focus Timer screen and Dashboard shows `"0./0"` as the sessions count (e.g. `"0./0"` instead of `"0/0"`). The trailing decimal point after the first zero makes the display look confusing and unprofessional.

## Steps to reproduce

1. Open the app for the first time (or reset state so no sessions exist).
2. Navigate to the Focus Timer screen.
3. Look at the "Sessions" metric in the summary card at the bottom.
4. Observe that it displays `"0./0"` instead of `"0/0"`.

Alternatively, view the Dashboard where a similar `SessionSummaryCard` is rendered.

## Expected behavior

The sessions display should show `"0/0"` — plain integers separated by a slash, with no stray decimal point characters.

## Actual behavior

The display shows `"0./0"` — the first zero has a trailing decimal point after it.

## Code analysis

**Root cause:** `lib/core/utils/number_format_utils.dart:9`

The `formatDecimal` function constructs a `NumberFormat` pattern like this:

```dart
final fmt = NumberFormat('#,##0.${'#' * maxFractionDigits}', localeName)
```

When `maxFractionDigits = 0`, the pattern string becomes `'#,##0.'` — note the trailing decimal point with zero fraction digits after it. The `intl` package's `NumberFormat` interprets this pattern literally, and formats `0.0` as `"0."` (with a trailing dot).

**Call site:** `lib/features/focus_mode/presentation/widgets/session_summary_card.dart:86`

```dart
value: '${formatDecimal(completed.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)}/${formatDecimal(total.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)}',
```

Both `completed` and `total` are 0 on first launch, so `formatDecimal(0.0, locale, minFractionDigits: 0, maxFractionDigits: 0)` returns `"0."` instead of `"0"`.

**Missing test coverage:** `test/core/utils/number_format_utils_test.dart` does not include any test case for `maxFractionDigits: 0`. All existing tests use `minFractionDigits >= 1`.

## Suggested approach

Fix the `formatDecimal` function in `lib/core/utils/number_format_utils.dart` to handle `maxFractionDigits == 0` as a special case. When `maxFractionDigits` is 0, the pattern should be `'#,##0'` (without the decimal point) instead of `'#,##0.'`.

A simple conditional would work:

```dart
final pattern = maxFractionDigits == 0
    ? '#,##0'
    : '#,##0.${'#' * maxFractionDigits}';
final fmt = NumberFormat(pattern, localeName)
  ..minimumFractionDigits = minFractionDigits
  ..maximumFractionDigits = maxFractionDigits;
```

Add test coverage for `formatDecimal` with `maxFractionDigits: 0`:

```dart
test('en locale formats zero with maxFractionDigits=0', () {
  expect(formatDecimal(0.0, 'en', minFractionDigits: 0, maxFractionDigits: 0), '0');
});
test('en locale formats non-zero with maxFractionDigits=0', () {
  expect(formatDecimal(42.0, 'en', minFractionDigits: 0, maxFractionDigits: 0), '42');
});
```
