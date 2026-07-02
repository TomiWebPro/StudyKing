# Content Library filter bar has cramped spacing against divider

**Severity:** minor
**Affected area:** Content Library screen (filters/UI)
**Reported by:** user

## Description

In the Content Library screen, the filter bar row (containing "All Subjects", "All Types", "All Statuses" chips) has zero bottom padding before the divider line below it. This makes the filter chips appear to be touching or crammed against the divider with no breathing room, creating an inconsistent and visually cramped look.

The filter bar's padding is set to `bottom: 0`, and the `Divider` immediately follows with `height: 1`. The lack of spacing makes the transition from filters to content feel abrupt and visually unpolished.

## Steps to reproduce

1. Open the app and navigate to the Content Library screen (via Dashboard card or Settings > My Uploads).
2. Observe the filter bar area at the top of the main content area, just below the AppBar.
3. Notice the filter chips ("All Subjects", "All Types", "All Statuses") and the thin divider line directly below them with no visible gap.

## Expected behavior

The filter bar should have adequate spacing (e.g., 8–12 dp) below the filter chips before the divider, consistent with how other screens handle filter-to-content transitions. The divider should provide a clear visual separation without feeling pressed against the chips.

## Actual behavior

The filter bar has `bottom: 0` padding, so the divider touches the chips with no gap. The divider itself has `height: 1`, making it extremely thin and barely visible, which compounds the cramped appearance.

## Code analysis

- `lib/features/ingestion/presentation/content_library_screen.dart:330` — The filter bar `Padding` widget has `bottom: 0`:
  ```dart
  padding: const EdgeInsetsDirectional.only(start: 16, top: 8, end: 16, bottom: 0),
  ```
- `lib/features/ingestion/presentation/content_library_screen.dart:277` — The divider immediately follows the filter bar with no spacing:
  ```dart
  const Divider(height: 1),
  ```

The column layout is:
```
Column(
  children: [
    _buildFilterBar(l10n),          // <-- bottom padding = 0
    const Divider(height: 1),       // <-- zero gap above this
    Expanded(child: ...),
  ],
)
```

## Suggested approach

Change the filter bar bottom padding from `0` to `8` (or wrap the filter bar in a `Column` and add a `SizedBox` between it and the divider). For example:

```dart
// Option A: Increase bottom padding on the filter bar
padding: const EdgeInsetsDirectional.only(start: 16, top: 8, end: 16, bottom: 8),

// Option B: Add SizedBox between filter bar and divider
// (between _buildFilterBar and Divider in the Column)
const SizedBox(height: 4),
```

Either approach gives the filters visual breathing room before the divider, matching the spacing conventions used elsewhere in the app.
