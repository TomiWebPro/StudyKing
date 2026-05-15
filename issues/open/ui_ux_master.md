# Tab Navigation Destroys Deep Navigation State (IndexedStack + Nested Routes)

## Context

The app uses `IndexedStack` in `lib/main.dart:245-248` to keep 5 root tab screens alive simultaneously. However, `IndexedStack` only preserves the _root_ widget state — it does not preserve any pushed sub-routes. Any screen reached via `Navigator.pushNamed` is hosted on the tab's individual `Navigator` stack, which gets discarded the moment the tab is switched (since there is no nested `Navigator` / `Router` per tab).

## Observed Behavior

1. User opens **Subjects** tab → taps a subject → taps a topic → opens a lesson → enters AI Tutor mode.
2. User taps another tab (e.g. **Mentor** or **Dashboard**) to check something.
3. User taps **Subjects** tab again.
4. **Result:** The entire navigation stack is gone. The user is back at the root subject list. All progress in the deep flow (lesson content, tutor chat session, scroll position, timer state) is lost.

This pattern repeats across all tabs: navigating into any sub-screen and switching tabs destroys that state.

## Affected Files

| File | Lines | Role |
|---|---|---|
| `lib/main.dart` | 245–248 | `IndexedStack` host — only keeps root widgets alive |
| `lib/main.dart` | 215–231 | Root screens list — no nested `Navigator` per tab |
| `lib/core/routes/app_router.dart` | 124–227 | `onGenerateRoute` pushes onto a single `Navigator` shared by the active tab |

Every pushed route through `Navigator.pushNamed` in the app is affected — this includes all screens in:
- `lib/features/subjects/presentation/` (subject list → detail → topics)
- `lib/features/lessons/presentation/` (topic list → lesson list → lesson detail)
- `lib/features/teaching/presentation/tutor_screen.dart` (lesson → AI tutor)
- `lib/features/practice/presentation/practice_session_screen.dart` (practice → session)
- `lib/features/settings/presentation/` (settings → profile / API config)

## Rationale

- **Frustration multiplier:** Users studying a lesson or in the middle of a tutor session lose all progress if they briefly switch tabs to check their planner or dashboard. This forces them to re-navigate the entire tree every time.
- **Design language inconsistency:** The FAB in `main.dart:249-257` calls `_openDashboard()` which imperatively sets `_selectedIndex = 3`, implying the app "knows" about tab switching — yet there is no mechanism to restore previous navigation stacks.
- **Compared to platform conventions:** Both iOS (UITabBarController) and Android (BottomNavigationView) preserve per-tab navigation stacks as a baseline UX expectation. The current implementation violates this platform convention.

## Acceptance Criteria

- [ ] A user can navigate into a deep sub-flow from any tab (e.g., Subjects > Topic > Lesson > Tutor), switch to another tab, and switch back to find their entire navigation stack intact.
- [ ] Each tab has its own `Navigator` (or `Router`) so pushed routes are preserved independently of other tabs.
- [ ] The `IndexedStack` approach is replaced or augmented so that each tab maintains its own route history.
- [ ] The FAB `_openDashboard()` either navigates within the dashboard's own navigator or switches tabs without losing other tabs' state.
- [ ] No existing screen-level state (scroll position, form input, timer values, tutor chat history) is lost when switching tabs and returning.
