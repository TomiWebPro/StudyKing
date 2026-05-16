# UI/UX: Responsive Layout Fragility, Data Viz Accessibility Gaps, and Fragmented Navigation Patterns

## Context

Three cross-cutting UI/UX problems degrade the experience across device sizes and user abilities:

1. **Responsive layout fragility** — Several key screens hardcode dimensions or use fixed-percentage sizing that breaks on short, tall, or wide viewports.
2. **Screen-reader accessibility gaps** — Interactive data visualizations (`AnimatedBarChart`, `MetricCard`) and critical gestures (`Dismissible`) lack `Semantics` trees, making them invisible to assistive technology.
3. **Fragmented bottom-sheet navigation** — Practice entry flow uses 6+ different bottom sheet widgets with inconsistent visual patterns and no progress indication, creating a disjointed user journey.

---

## Issue 1: Hardcoded & percentage-based sizing breaks on diverse viewports

### `lib/features/subjects/presentation/subject_detail_screen.dart:55`

```dart
expandedHeight: MediaQuery.sizeOf(context).height * 0.25,
```

**Problem**: The `SliverAppBar` consumes a fixed 25% of screen height. On landscape phones (~360×640, usable height after status bar ≈ 590px), the header eats 148px leaving ~442px for tabs + content — the `TabBarView` below the fold is barely visible on first load. On tablets in portrait (e.g. 820×1180), 25% = 295px, creating a massive empty header. Split-screen or foldable devices (e.g., ~412×360 landscape half-screen) leave virtually no content area.

**Rationale**: The header should use `ConstrainedBox` with `minHeight`/`maxHeight` (e.g., clamped to 100–200px) rather than a raw percentage of viewport height. The subject name/code + avatar can collapse into the `title` slot without needing a tall expanded state.

### `lib/core/widgets/animated_bar_chart.dart:37-43`

```dart
double _computeBarWidth(double availableWidth) {
  if (widget.barWidth != null) return widget.barWidth!;
  final count = widget.data.length;
  if (count == 0) return AnimatedBarChart.minBarWidth;
  final computed = (availableWidth - 8 * (count - 1)) / count;
  return computed.clamp(AnimatedBarChart.minBarWidth, double.infinity);
}
```

**Problem**: Bars share available width equally with no upper bound. On tablet (1200px), with 7 data points, each bar can be ~170px wide — comically oversized for a single-digit value. On very narrow screens (320px), 7 bars at `minBarWidth` (24px) leave gaps so small labels overflow. No `maxBarWidth` cap.

**Rationale**: Add a `maxBarWidth` parameter (default ~48–64px) and center/group the bars when the container exceeds `count * maxBarWidth + spacing`, similar to how `flex` charts handle overflow.

### `lib/features/sessions/presentation/session_tracker_screen.dart:280` (the timer text)

```dart
style: theme.textTheme.displayLarge?.copyWith(
  fontWeight: FontWeight.w600,
  ...
),
```

**Problem**: `displayLarge` is typically 57–60pt on Material 3. A 5–6 line text like "01:23:45" rendered at 60pt on a 360px-wide phone occupies nearly the full width. On tablets, it renders at the same size (no responsive scaling) while the timer gutter is oddly small relative to surrounding content.

**Rationale**: Scale timer font size based on `MediaQuery.sizeOf(context).shortestSide`, e.g., `clamp(36, 64, shortestSide * 0.09)`. Or use `ResponsiveUtils` to pick a text style variant per breakpoint.

### `lib/features/practice/presentation/practice_screen.dart:415-483` (extra modes row)

```dart
Row(
  children: [
    Expanded(child: Card(/* Exam Mode */)),
    const SizedBox(width: 12),
    Expanded(child: Card(/* Source Practice */)),
  ],
)
```

**Problem**: Two cards forced side-by-side with `Expanded` regardless of width. On an `xs` phone (<600px), each card's `bodySmall` description text wraps awkwardly to 3–4 lines. The `titleSmall` + `bodySmall` vertical stack at ~120px minimum height with cramped horizontal space.

**Rationale**: Use `ResponsiveUtils.breakpointOf(context)` — stack vertically on `xs` (or `Column` with full-width cards), side-by-side on `sm+`.

---

## Issue 2: Screen-reader inaccessibility of data visualizations & gestures

### `lib/core/widgets/animated_bar_chart.dart:124-172`

**Problem**: Renders day-labels, value tooltips, and colored bars — but the entire chart is a `Semantics` void. Screen reader users get zero information about:
- Which day each bar represents (labels are `Text` widgets, not in a `Semantics`-merged subtree)
- The numeric value of each bar (visible as a tiny `Text` above the bar but not labeled as the bar's value)
- The y-axis label (purely visual)
- The trend / which day has the highest count

**Rationale**: Wrap each bar column in:
```dart
Semantics(
  label: '$day: $count sessions',
  value: '$count',
  child: Column(...),
)
```
Wrap the entire chart in `Semantics(sortKey: ...)` so a screen reader can navigate per-bar. The existing `Tooltip` is mouse-only and provides no assistive-tech benefit.

### `lib/core/widgets/metric_card.dart:24-52`

**Problem**: `MetricCard` renders an icon + value + label inside `GradientContainer`, but the `Semantics` wrapper at `session_analytics.dart:93` only wraps the entire 4-card grid with a single `label: l10n.performanceMetrics`. Individual cards have no accessible name, role, or value. A screen reader hears "performance metrics" and then unlabeled "timer 00:30:00 avg session" — the `value` and `label` are just `Text` widgets without `Semantics.merge` or explicit labels.

**Rationale**: Add to `MetricCard.build()`:
```dart
Semantics(
  label: '$label: $value',
  child: GradientContainer(...),
)
```

### `lib/features/sessions/presentation/session_history_screen.dart:454-466`

```dart
return Dismissible(
  key: Key(session.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (direction) => _deleteSession(session),
  background: Container(
    alignment: Alignment.centerRight,
    ...
    child: Icon(Icons.delete, ...),
  ),
  child: Card(...),
);
```

**Problem**: The `Dismissible` swipe-to-delete gesture has no `Semantics` hint, label, or custom accessibility action. A screen reader user cannot discover that swiping left deletes the item, and the delete icon in the background is decorative-only (`Semantics(excludeSemantics: true)` is not set). The `ListTile` inside does have a `delete_outline` `IconButton` as a fallback (`session_history_screen.dart:519-527`), but the Dismissible's gesture path is silent.

**Rationale**: Add `Semantics( hint: l10n.swipeToDelete, child: Dismissible(...) )` or use `ExcludeSemantics` on the background `Container`. Ensure the delete `IconButton` fallback has proper `Semantics(button: true)` (it already does) and the `Dismissible` is not incorrectly overriding focus.

### `lib/features/sessions/presentation/session_tracker_screen.dart:507` (end-session dialog)

**Problem**: The `_SessionEndDialog` has `TextField` widgets for "questions answered" and "correct answers" with no input validation. A user can enter `correct > questions` (e.g., 10 correct of 5 answered), or negative/zero values, and the dialog saves silently. No `Form`-level validation, no `errorText` feedback, no keyboard action (`textInputAction`) that moves to the next field.

**Rationale**: Wrap in a `Form` with `TextFormField` + `validator` ensuring `correct <= questions` and both `>= 0`. Show inline `errorText`. Set `textInputAction: TextInputAction.next` on the first field and `TextInputAction.done` on the second.

---

## Issue 3: Fragmented bottom-sheet navigation in practice entry flow

### `lib/features/practice/presentation/practice_screen.dart` — 6 entry surfaces, 5 bottom sheet types

```
Practice Screen
├── FAB → SubjectSelectionSheet (if >1 subject) or direct practice
├── PracticeModeGrid
│   ├── Quick Practice → PracticeModeSheet
│   ├── Spaced Repetition → SpacedRepetitionSheet
│   ├── Topic Focus → TopicSelectionSheet
│   └── Weak Areas → WeakAreasSheet
├── Extra Modes Row
│   ├── Exam Mode → direct navigation
│   └── Source Practice → SourcePracticeSheet
└── Subject Practice Cards → direct navigation
```

**Problems**:
1. **Inconsistent visual language**: Each bottom sheet (`SubjectSelectionSheet`, `PracticeModeSheet`, `TopicSelectionSheet`, `SpacedRepetitionSheet`, `WeakAreasSheet`, `SourcePracticeSheet`) is a standalone widget built with `showModalBottomSheet`. Some use `ListTile`, some use custom card layouts, some have scrollable content, some don't. No shared sheet template or consistent `DraggableScrollableSheet` usage.
2. **No exit awareness**: A user who opens "Spaced Repetition" then finds no due items gets a bare `SpacedRepetitionSheet.showAllCaughtUp(context)` dialog with no "back to practice" affordance — just "OK". They lose their mental position in the flow.
3. **No visual progress**: If a user opens the FAB → `SubjectSelectionSheet` picks subject, they're dumped into a practice session. There's no "loading..." / "starting practice..." state — the session screen appears with no context of what practice mode was chosen.
4. **Crowded app bar**: `PracticeScreen` app bar has a `tune` `IconButton` that opens `PracticeModeSheet` — duplicating the Quick Practice tile behavior. Two routes to the same sheet, one hidden in the app bar.

**Rationale**: Consolidate the bottom sheets into a single reusable `PracticeSheet` component that adapts its content list (subjects, modes, topics) based on a parameter. Add a visual progress stepper for multi-step flows (e.g., Select Subject → Select Mode → Practice). Remove the duplicate `tune` icon in the app bar or rename it to a clearly different action (e.g., "Filters").

### `lib/features/sessions/presentation/session_history_screen.dart:265-320` (export popup menu)

**Problem**: The `PopupMenuButton` lists 6 export options (CSV, PDF, JSON, comprehensive CSV, comprehensive PDF, comprehensive JSON) as a flat list with duplicate icons (`Icons.picture_as_pdf` appears twice, `Icons.code` appears twice). A user scanning this list cannot differentiate quick export from comprehensive export without reading each label line carefully. No grouping, no submenu, no disabled states for unavailable formats.

**Rationale**: Group into sections with `PopupMenuSection` or use a bottom sheet with section headers: "Quick Export" / "Comprehensive Report". Alternatively, collapse comprehensive options into a single "Comprehensive Report" entry that then opens a format-picker sub-sheet.

---

## Acceptance Criteria

### AC1: Responsive Sizing
- [ ] `SubjectDetailScreen` header height is clamped to `min(200, max(100, viewportHeight * 0.25))` and collapses gracefully on landscape orientation.
- [ ] `AnimatedBarChart` bars have a `maxBarWidth` (default 48px); when total chart width exceeds `count * maxBarWidth + spacing`, bars are centered with surplus space on each side.
- [ ] Timer display in `SessionTrackerScreen` uses responsive font sizing (36–64px range based on `shortestSide`).
- [ ] Extra modes row in `PracticeScreen` stacks vertically on `xs` breakpoint, side-by-side on `sm+`.

### AC2: Accessibility
- [ ] Each bar in `AnimatedBarChart` is wrapped in `Semantics(label: '$day: $count sessions')`.
- [ ] `MetricCard` has per-card `Semantics(label: '$label: $value')`.
- [ ] `Dismissible` in `session_history_screen.dart` has `Semantics(hint: l10n.swipeToDelete)` on the gesture surface; background container has `ExcludeSemantics`.
- [ ] `_SessionEndDialog` uses `Form` + `TextFormField` with `validator` enforcing `correct <= questions` and `>= 0`.

### AC3: Navigation Consistency
- [ ] Practice bottom sheets follow a shared template (`PracticeSheet`) with consistent padding, spacing, scroll behavior, and border radius.
- [ ] `SpacedRepetitionSheet.showAllCaughtUp` includes a "Back to Practice" button (not just "OK").
- [ ] Practice FAB → subject → session includes a brief "Starting practice…" loading state or an overlay explaining the practice mode chosen.
- [ ] Export menu in `SessionHistoryScreen` groups quick/comprehensive options visually.
- [ ] Duplicate `tune` icon in `PracticeScreen.appBar.actions` is removed or given a distinct purpose.

### AC4: Testing
- [ ] `AnimatedBarChart` widget test verifies `Semantics` labels on bars for screen readers.
- [ ] `MetricCard` widget test verifies combined semantics label.
- [ ] `SessionHistoryScreen` widget test verifies `Dismissible` accessibility hint.
- [ ] `PracticeScreen` widget test verifies responsive stacking of extra modes on `xs` breakpoint.
