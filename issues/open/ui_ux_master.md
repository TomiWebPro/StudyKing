# Broken Accessibility: Duplicate `NumericFocusOrder` Values Break Keyboard & Switch Navigation Across All Features

## Context

Every screen in StudyKing that uses `FocusTraversalOrder` with `NumericFocusOrder` assigns **duplicate order values** within the same `FocusTraversalGroup`. Because Flutter's focus traversal system uses `NumericFocusOrder` values as a strict ascending sequence (lower = earlier focus), duplicates cause **undefined, non-deterministic focus ordering**. This breaks keyboard tab navigation, screen reader scan mode, and switch-control sequential navigation — all core accessibility requirements.

## Root Cause

Developers copy-pasted `NumericFocusOrder(order: 1)` as the starting focus value in every `FocusTraversalGroup` without realizing that **each group must have globally unique order values across all children**. Instead of using `NumericFocusOrder`, most screens should simply rely on Flutter's **default lexical widget-order traversal** (which matches visual reading order) and use `FocusTraversalOrder` only when a non-lexical order is truly needed.

## Affected Files

| File | Issue | Line(s) |
|---|---|---|
| `lib/features/lessons/presentation/lesson_list_screen.dart` | Orders 1 used twice — once in the empty-state `FocusTraversalGroup` and once in the AppBar actions `FocusTraversalGroup`. In the populated-state ListView, the tutor button (AppBar action, order=1) competes with the first lesson item (order=2) even though they are in different `FocusTraversalGroup`s. Expected: no manual ordering needed at all — lexical order is correct. | 100–185 |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | `NumericFocusOrder(1)` used in both the AppBar actions (line 112) and the `BottomAppBar` row (line 151). The main-body lesson blocks start at order=1 as well (line 131). Three groups with order=1 causes focus to skip unpredictably. | 112, 131, 151 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | No `FocusTraversalOrder` exists, but the screen uses `Semantics` on some InteractiveViewers without pairing with a `FocusTraversalGroup`. The `_buildRecentSessionsList` (line 420) wraps cards in `Semantics` with no focus ordering, causing tab navigation to skip entire card content areas. | 420–456 |
| `lib/features/sessions/presentation/session_history_screen.dart` | No `FocusTraversalOrder` at all. The `Dismissible` items (line 452) are not keyboard-accessible — swipe-to-delete has no keyboard alternative. Filter buttons (date, subject) have no `FocusTraversalOrder`. The share menu `PopupMenuButton` (line 267) is not keyboard-navigable. | 267, 339, 452 |
| `lib/features/planner/presentation/planner_screen.dart` | Heaviest offender. The `_buildStudyPlanTab` method applies `NumericFocusOrder` from 1–4 for course/days/hours/generate inputs (lines 273–369). But `_buildPendingActionsSection`, `_buildAdherenceBanner`, `_buildScheduledLessonsSection`, and `_buildDailyPlans` all render children **outside** any `FocusTraversalGroup`, making their interactive items unreachable or interleaved arbitrarily. `NumericFocusOrder(1)` is reused across multiple independent groups. | 253–396 |
| `lib/features/settings/presentation/settings_screen.dart` | Every section resets order to 1: accessibility toggles start at 1, notification toggles start at 1, analytics tiles start at 1. Within the same `ListView`, focus hops erratically across the 6+ sections. The `_tile` helper method (line 217–228) skips `FocusTraversalOrder` when `order <= 0`, causing some tiles (e.g., about, sign-out) to receive no order at all, making them unfocusable by keyboard. | 39–197, 217–228 |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | No `FocusTraversalOrder` anywhere in the main scrollable body. All interactive cards (collapsible headers, InkWell for focus mode, planner card) rely on default widget-order traversal, which is fine — but the `CollapsibleCard` titles have `button: true` semantics (collapsible_card.dart:74) without integrating with focus traversal, causing screen readers to incorrectly announce collapsed content as interactive. | dashboad_screen.dart:78–174, collapsible_card.dart:72–93 |

## Rationale

1. **WCAG 2.1 SC 2.4.3 (Focus Order)**: "If a Web page can be navigated sequentially and the navigation sequences affect meaning or operation, focusable components receive focus in an order that preserves meaning and operability." Duplicate `NumericFocusOrder` values violate this — focus jumps are unpredictable.

2. **Platform compliance**: Both iOS and Android accessibility guidelines require predictable focus order. Flutter's `NumericFocusOrder` with duplicates creates a hard failure on automated a11y scanners (e.g., `flutter analyze --fatal-infrastructure` with `a11y` enabled, axe‑dev for web).

3. **Degraded experience for real users**: Students using switch-control, voice control (iOS Switch Control, Android Switch Access), or keyboard-only navigation (desktop web) cannot reliably navigate StudyKing. This includes students with motor disabilities who are a key demographic for an all-in-one study platform.

4. **Copy-paste compounding**: The pattern of `NumericFocusOrder(order: 1)` was copied across features without understanding the semantics. Most screens don't need `NumericFocusOrder` at all — Flutter's default lexical ordering (based on widget tree position) is sufficient and correct.

## Acceptance Criteria

1. Remove all `NumericFocusOrder` annotations from `lesson_list_screen.dart`, `lesson_detail_screen.dart`, `session_tracker_screen.dart`, `session_history_screen.dart`, `planner_screen.dart`, and `settings_screen.dart` where the default widget-tree traversal order is already correct.

2. Where `NumericFocusOrder` is genuinely needed (e.g., a floating action button should be reached before a bottom-app-bar item), ensure **every order value within a single `FocusTraversalGroup` is unique** and respects visual reading order.

3. Add keyboard-action alternatives for touch-only interactions:
   - `Dismissible` in `session_history_screen.dart` must have a keyboard-triggerable delete action (e.g., a `FocusTraversalOrder`-wrapped trailing IconButton that calls `_deleteSession`).
   - `PopupMenuButton` export share menu must be keyboard-navigable without needing pointer hover.
   - ChoiceChip duration selectors in `focus_timer_screen.dart` must be reachable by sequential keyboard navigation.

4. Add `FocusTraversalGroup` to the body of `session_tracker_screen.dart`, `session_history_screen.dart`, and `dashboard_screen.dart` with appropriate (non-conflicting) child ordering so that all interactive elements are keyboard-reachable.

5. Verify with `SemanticsDebugger` enabled (wrap `MaterialApp` with `showSemanticsDebugger: true` in debug mode) that every interactive element has a unique and readable semantic label and that tab-order flows left-to-right, top-to-bottom without jumps.

6. Existing unit/widget tests must continue to pass. Add a widget test for each affected screen verifying that keyboard tab navigation visits all interactive elements in the correct visual order.
