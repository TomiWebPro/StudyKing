# Issue: `ResponsiveUtils` is systematically ignored — 7 features hardcode dimensions instead of using the built-in responsive API

## Context

`lib/core/utils/responsive.dart` defines a complete responsive toolkit (`ResponsiveUtils` + `ResponsiveContext` extension) covering breakpoint-aware padding, spacing, icon sizes, touch targets, and grid layouts. However, a codebase-wide audit reveals that **every feature** in the presentation layer ignores these utilities in favor of hardcoded literals (`EdgeInsets.all(12)`, `SizedBox(height: 16)`, `Icon(size: 64)`, etc.).

The problem is not cosmetic — it directly causes:
- **Layout overflow crashes** (e.g., `help_dialog.dart` has no `SingleChildScrollView`; `exam_session_screen.dart` config/results screens have bare `Column`s)
- **Sub-48dp touch targets** (`dense: true` `ListTile`s, `Chip`s, `ChoiceChip`s — some triple-shrunk with `visualDensity: VisualDensity.compact`)
- **Accessibility gaps** (screen readers cannot interpret `GestureDetector` day cells, bar chart bars, or stat rows)
- **RTL breakage** (`Positioned(right: 8)` instead of `end: 8` in `practice_mode_card.dart`)
- **Font-size-invariant rendering** (hardcoded `fontSize: 11/12` in `llm_task_manager_screen.dart`, `practice_mode_card.dart`, etc.)

## Affected Files

### Planner (`lib/features/planner/presentation/`)

| File | Issue |
|---|---|
| `planner_screen.dart` | `EdgeInsets.all(12)` x3 instead of `cardPadding()`; `SizedBox(height: 8/12/16/24)` x12 instead of `verticalSpacing()`; `Icon(size: 64)` empty-state instead of `emptyStateIconSize()`; `CircularProgressIndicator` in bare `SizedBox(20,20)` instead of `loaderInTouchTarget()`; TabBar `Tab` widgets missing `semanticLabel` |
| `calendar_view_widget.dart` | `GestureDetector` day cells lack `InkWell`/`Semantics`/`semanticLabel`; `childAspectRatio: 1.0` with 7 columns produces ~46dp cells on narrow screens (`SliderGridDelegateWithFixedCrossAxisCount`); `IconButton` month nav missing `semanticLabel` |
| `daily_plan_card.dart` | `EdgeInsets.all(12)` instead of `cardPadding()`; `ListTile(dense: true, contentPadding: EdgeInsets.zero)` shrunken touch target; hardcoded `fontSize: 10/12` |
| `lesson_booking_sheet.dart` | `EdgeInsets.only(left: 24, right: 24)` instead of `screenPadding()`; `IconButton` +/- duration buttons lack `tooltip`/`semanticLabel` |
| `milestone_timeline.dart` | `SizedBox(height: 60)` fixed height breaks under font scaling; `Stack` with `Positioned` children overlap when milestones cluster; no `Semantics` on milestone dots |
| `pending_action_card.dart` | `EdgeInsets.all(12)` instead of `cardPadding()` |
| `plan_summary_card.dart` | `EdgeInsets.all(16)` instead of `cardPadding()`; 5-chip `Wrap` overflows into excessive height on small screens |
| `progress_overlay_widget.dart` | `SizedBox(height: 120)` fixed bar chart; `fontSize: 9` illegible at standard viewing distance; weekly bars are bare `Container`s with zero semantic labelling — invisible to screen readers |
| `roadmap_card.dart` | `EdgeInsets.all(16)` instead of `cardPadding()`; `CheckboxListTile(dense: true, visualDensity: compact, contentPadding: EdgeInsets.zero)` — triple-shrunk touch target |

### Practice (`lib/features/practice/presentation/`)

| File | Issue |
|---|---|
| `practice_session_screen.dart` | `LinearProgressIndicator` lacks `semanticLabel`; `AnimatedSwitcher` 300ms duration not shortened under `reduceMotion`; `SlideTransition(Offset(0.3, 0.0))` may trigger vestibular discomfort; confidence-selector `Row` of 5 fixed 48dp circles may overflow on narrow screens |
| `exam_session_screen.dart` | Config/results screens use bare `Column` with **no `SingleChildScrollView`** — overflow crash risk; `ChoiceChip` selectors lack minimum-size enforcement; no `reduceMotion` support at all; timer/icon hardcoded `size: 16` |
| `practice_results_screen.dart` | `Column` without scroll; stat rows lack `Semantics` grouping |
| `practice_session_question_card.dart` | `TextField(maxLines: 3/5` fixed instead of `minLines`/`maxLines` dynamic; hardcoded `SizedBox(height: 12/24)` |
| `practice_session_stats_bar.dart` | `Icon(size: 16)` fixed; no responsive width capping on wide screens |
| `practice_session_nav_buttons.dart` | Good use of breakpoints; disabled "Previous" lacks `Semantics(enabled: false)` |
| `practice_feedback_widget.dart` | Icon+text `Row` not `mergeSemantics`; explanation text may overflow parent |
| `practice_mode_card.dart` | `EdgeInsets.all(12)` → `cardPadding()`; `fontSize: 11` hardcoded (subtitle); `Positioned(top: 8, right: 8)` breaks RTL (`end: 8` needed) |
| `practice_mode_option.dart` | `fontSize: 12` hardcoded; no `mergeSemantics` on `Row` |
| `practice_mode_grid.dart` | `childAspectRatio` clamp `(0.6, 2.0)` causes overflow at large text scales |
| `subject_practice_card.dart` | Fixed `56x56` icon container; `fontSize: 12` x2; `Icon(size: 14)` below visibility threshold; no `Semantics` on tappable card |
| `mistake_review_widget.dart` | `SizedBox(width: 100, child: Text(label))` fixed label width; `CircleAvatar(radius: 12)` + `fontSize: 12` too small; `SizedBox(height/width: 8/12/16)` copiously hardcoded |
| `spaced_repetition_sheet.dart` / `subject_selection_sheet.dart` / `weak_areas_sheet.dart` | `SizedBox(height: 16)`; `_getSubjectColor` no WCAG contrast guarantee against card backgrounds in dark mode; bottom sheets lack `DraggableScrollableSheet` (overflow when many subjects) |
| `source_practice_sheet.dart` | Drag handle hardcoded `40×4`; `SizedBox(height: 8/16)` |
| `practice_empty_state.dart` | No `Semantics` on icon or button |
| `practice_screen.dart` | `FloatingActionButton.extended` label may clip on <360dp screens; `_ExtraModeCard` `EdgeInsets.all(16)` → `cardPadding()`; `InkWell` card has no `Semantics` wrapper |

### Mentor (`lib/features/mentor/presentation/`)

| File | Issue |
|---|---|
| `mentor_screen.dart` | **Hardcoded theme colors** `Colors.green`/`Colors.orange`/`Colors.red`/`Colors.amber.shade700` instead of `colorScheme.primary`/`tertiary`/`error` — breaks in dark and high-contrast themes; `EdgeInsets.symmetric(horizontal: 32)` wasted space on xs; `ListTile(dense: true)` touch target below 48dp; `Chip` badges lack `Semantics`; `size: 64` empty-state → `emptyStateIconSize()` |

### Focus Mode (`lib/features/focus_mode/presentation/`)

| File | Issue |
|---|---|
| `focus_timer_screen.dart` | `EdgeInsets.all(24)` x3 → `cardPadding()`; `Icon(size: 48/64)` fixed; `ChoiceChip` touch targets below 48dp; `displayLarge` timer text (could be 40dp+) may overflow narrow card with no `FittedBox`; custom `Slider` hidden behind `bp.isTablet` — phone users cannot set custom duration |
| `session_summary_card.dart` | `EdgeInsets.all(16)` → `cardPadding()`; decorative check/cancel icons have no `semanticLabel` |
| `focus_timer_widget.dart` | Pulse ring `IgnorePointer` + `Container` not wrapped in `ExcludeSemantics`; ring size clamped at 200–260dp — wasted space on tablets; button `Row` may overflow on xs |

### LLM Tasks (`lib/features/llm_tasks/presentation/`)

| File | Issue |
|---|---|
| `llm_task_manager_screen.dart` | **Hardcoded `fontSize: 11` (three occurrences)** — ~8.25pt, below the 12pt WCAG AA minimum for small text; 4-column `Row` token stats crammed into ~70dp per column on xs; `EdgeInsets.all(16)` → `cardPadding()`; status badge `EdgeInsets.symmetric(horizontal: 8, vertical: 4)` overrides theme default |

### QuickGuide (`lib/features/quickguide/presentation/`)

| File | Issue |
|---|---|
| `help_dialog.dart` | **`AlertDialog` content has no `SingleChildScrollView`** — long `quickGuideHelpContent` strings cause an overflow crash |
| `mode_navigation_widget.dart` | Section title "Choose a study mode" not marked as `Semantics(headingLevel: ...)`; `Expanded` cards side-by-side truncate subtitle text on xs |
| `suggested_prompts_widget.dart` | `ActionChip` default height ~32dp (below 48dp touch target); `fontSize: 12/13` hardcoded |

## Rationale

The project owns `ResponsiveUtils` and `ResponsiveContext` in `lib/core/utils/responsive.dart`, offering breakpoint-aware spacing (`verticalSpacing`, `horizontalSpacing`), padding (`screenPadding`, `cardPadding`, `listPadding`), icon sizing (`emptyStateIconSize`), touch-target enforcement (`ensureMinTouchTarget`, `minTouchTarget = 48.0`), and even a spinner widget (`loaderInTouchTarget`). The extension on `BuildContext` makes consumption trivial (`.breakpoint`, `.screenPadding`, `.cardPadding`).

The audit found **zero uses** of `verticalSpacing`/`horizontalSpacing` across all seven features — every `SizedBox(height: X)` is a hardcoded literal. Only one file (`message_list_widget.dart`) uses `ResponsiveUtils.listPadding`. The `ResponsiveContext` extension is never imported in any presentation file.

This means:
1. **Every screen renders identically** on a 320px phone and a 1440px tablet — no adaptation occurs.
2. **Font scaling breaks layouts** because hardcoded `SizedBox(60)` in timelines, `SizedBox(120)` in bar charts, and `fontSize: 11` in stat labels don't respond to the user's system font size.
3. **Screen reader users get zero value** from `GestureDetector` calendar cells, bar chart bars, stat rows, and bottom-sheet content.
4. **Dark/high-contrast theme users** in `mentor_screen.dart` see hardcoded Material green/orange/red instead of semantic `colorScheme` tokens.
5. **Small-screen and foldable users** hit layout overflows in help dialogs, exam config screens, and 4-column stat rows.

## Acceptance Criteria

1. **Every `EdgeInsets.all/fixed` in presentation widget/screen files is replaced** with the appropriate `ResponsiveUtils.*Padding(context)` or `context.cardPadding` / `context.screenPadding` / `context.listPadding` call (whichever pattern the file already imports).

2. **Every `SizedBox(height: X)` and `SizedBox(width: X)` used for spacing** (not for fixed-size widgets) is replaced with `SizedBox(height: ResponsiveUtils.verticalSpacing(context))` / `SizedBox(width: ResponsiveUtils.horizontalSpacing(context))`.

3. **Every hardcoded `fontSize` below `14`** (roughly `bodySmall` at default scale) is promoted to a theme text style (`labelSmall`, `bodySmall`, etc.) or uses `MediaQuery.textScalerOf(context).scale(fontSize)`.

4. **Every `GestureDetector`-only tappable area** (e.g. calendar day cells, `InkWell` cards without semantics) gains a `Semantics(button: true, label: ...)` wrapper and an `InkWell` for visual ripple feedback.

5. **Every `Positioned` with `right:` or `left:`** that positions a widget near the edge is changed to `end:` / `start:` for RTL support.

6. **Every `AlertDialog` with multi-line or expansion-prone content** gets `scrollable: true` or wraps its `content` in `SingleChildScrollView` (target: `help_dialog.dart`, `planner_screen.dart` create-plan dialog).

7. **Every `Column` inside a scrollable parent** that may contain variable-length content (exam config, exam results, bottom-sheet bodies with unknown item counts) is wrapped in `SingleChildScrollView` or uses `DraggableScrollableSheet`.

8. **Every `LinearProgressIndicator` and `CircularProgressIndicator`** used for progress display is wrapped in `Semantics(liveRegion: true, label: ...)`.

9. **Every hardcoded `Colors.green/orange/red/amber`** in `mentor_screen.dart` is replaced with `colorScheme.primary`/`colorScheme.tertiary`/`colorScheme.error`/`colorScheme.secondary`.

10. **Every `Icon(size: 64)` in empty-state illustrations** is replaced with `Icon(size: ResponsiveUtils.emptyStateIconSize(context))`.

11. **Every `AnimatedSwitcher` / `AnimatedContainer` / slide transition** is audited to either shorten duration or skip entirely when `MediaQuery.disableAnimationsOf(context)` is true (pattern already demonstrated by `focus_timer_widget.dart` lines 70–81 and `chat_bubble.dart`).

12. **Every `dense: true` `ListTile` / `CheckboxListTile` with `contentPadding: EdgeInsets.zero` and/or `visualDensity: compact`** is examined and at minimum given `SizedBox(height: 48)` or replaced with a custom row widget that enforces the 48dp touch target.
