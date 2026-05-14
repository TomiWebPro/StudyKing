# UI/UX: Navigation state loss, accessibility gaps, and animation anti-patterns

## Context

The app has several systemic UI/UX issues spanning navigation architecture, accessibility compliance, and animation patterns. These are not surface-level bugs but fundamental design decisions that degrade the user experience across multiple features.

## Issues

### 1. Navigation model conflict: `IndexedStack` + pushed named routes causes blank/confusing screens

**Severity:** High  
**Category:** Confusing navigation  

`MainScreen` (`lib/main.dart:232`) uses `IndexedStack` to preserve tab state across 5 tabs. However, all feature screens push named routes on *top* of the entire `MainScreen` via `Navigator.pushNamed` (e.g., `practice_session_screen.dart:86`, `focus_timer_screen.dart:204`, `practice_screen.dart:85`). This creates two problems:

- **Tab switch during sub-screen**: If a user is on the Practice tab, navigates into a practice session (pushed route), then switches to the Focus tab, the pushed practice session screen **remains visible on top** of the Focus tab content. The user sees an entirely different feature than expected.
- **Back navigation confusion**: Pressing the system back button from a sub-screen pops back to the same tab's root — but the `IndexedStack` preserves scroll position separately per tab, so the user's mental model (tab == screen) is broken. They expect tab switches to show that tab's content, not a dangling sub-screen.

**Root cause:** The app mixes two navigation models — tab-based (`IndexedStack`) and stack-based (pushed routes). They conflict because pushed routes overlay the entire widget tree, not individual tab content stacks.

**Affected files:**
- `lib/main.dart:211-281` — `MainScreen` with `IndexedStack`
- `lib/core/routes/app_router.dart` — all push-named route destinations
- `lib/features/practice/presentation/practice_screen.dart:85,102,151,173` — pushes practice session
- `lib/features/dashboard/presentation/dashboard_screen.dart:99,222` — pushes focus mode, dashboard
- `lib/features/planner/presentation/planner_screen.dart:54,68` — pushes tutor, lesson booking
- `lib/features/sessions/presentation/session_tracker_screen.dart:344` — pushes session history

**Acceptance criteria:**
- Each tab should maintain its own `Navigator` stack so sub-screens are scoped to the active tab
- Switching tabs should always reveal that tab's root content, never a sub-screen from another tab
- Back navigation from a sub-screen should return to the tab's root, not exit the app

---

### 2. `MediaQuery.textScaler: TextScaler.noScaling` disables system font size accessibility

**Severity:** High  
**Category:** Accessibility  

`lib/main.dart:142` forces `TextScaler.noScaling` in the `MediaQuery` builder. This overrides the user's device-level font size setting, making the app completely ignore system text scaling preferences (e.g., "Large Text" or "Extra Large Text" in Android/iOS accessibility settings).

While the app provides its own font size slider in settings (`lib/features/settings/presentation/settings_screen.dart:52`), this creates a bifurcated accessibility model:
- Users who rely on system-wide font scaling (e.g., visually impaired users who set large fonts at the OS level) are silently blocked
- The app's internal font size setting must be configured separately, which many users won't discover

**Affected files:**
- `lib/main.dart:138-146` — the `builder` override
- `lib/core/theme/app_theme.dart:4-22` — `createTextTheme` accepts a `fontSize` param but it's never driven by system scaling

**Acceptance criteria:**
- Remove `TextScaler.noScaling` and allow `MediaQuery.textScaler` to propagate from the system
- Apply the app's internal `fontSize` setting as a **multiplier on top** of the system scaling factor (e.g., `MediaQuery.of(context).textScaler * (settings.fontSize / 16)`)
- Verify with system font set to "Large" on Android and "Larger Text" on iOS

---

### 3. Dashboard rebuild storm: 8+ independent async providers cause excessive rebuilds on every data change

**Severity:** Medium  
**Category:** Problematic animation choice / Performance  

`DashboardScreen` (`lib/features/dashboard/presentation/dashboard_screen.dart:31-38`) watches 8 independent `AsyncValue` providers in a single `build` method:

```dart
final allMasteryAsync = ref.watch(dashboardAllMasteryProvider(studentId));
final snapshotAsync = ref.watch(dashboardMasterySnapshotProvider(studentId));
final overallStatsAsync = ref.watch(dashboardOverallStatsProvider(studentId));
final weeklyTrendAsync = ref.watch(dashboardWeeklyTrendProvider(studentId));
final focusStatsAsync = ref.watch(dashboardFocusStatsProvider(studentId));
final adherenceAsync = ref.watch(dashboardAdherenceDataProvider(studentId));
final topicNamesAsync = ref.watch(dashboardTopicNamesProvider(studentId));
final badgesAsync = ref.watch(dashboardBadgesProvider(studentId));
```

Every time any single provider emits a new state (loading → data, or data → error), the **entire dashboard widget tree rebuilds** — all 11 card widgets, the header, and the export section. This causes visible jank, especially during initial load when providers cascadingly transition through `isLoading → data` states.

Additionally, the `CollapsibleCard` wrapper (`lib/features/dashboard/presentation/widgets/collapsible_card.dart:32-62`) uses `asyncValue.when()` which reactively swaps entire widget subtrees on each state change, preventing implicit `const` optimizations.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:31-60,69-183`
- `lib/features/dashboard/presentation/widgets/collapsible_card.dart:30-65`
- `lib/features/dashboard/providers/dashboard_data_providers.dart`

**Acceptance criteria:**
- Only rebuild sections of the dashboard whose provider data actually changed (e.g., by splitting into smaller `Consumer` widgets or using `select` with granular keys)
- During initial load, show a single skeleton/loading state instead of 8 sequential spinners
- After initial load, individual card updates (e.g., badges refreshing) should not cause other cards to rebuild
- Verify that scrolling to a card and having it update does not reset scroll position

---

### 4. Break countdown timer misuses `AnimationController` as a general-purpose timer

**Severity:** Medium  
**Category:** Problematic animation choice  

`FocusTimerScreen._startBreakTimer()` (`lib/features/focus_mode/presentation/focus_timer_screen.dart:98-116`) uses an `AnimationController` with `repeat(period: Duration(seconds: 1))` solely to count down 5 minutes. The `addListener` callback decrements `_breakRemaining` each frame tick.

This is an anti-pattern for three reasons:
- `AnimationController` is designed for driving widget animations with vsync, not for simple time tracking
- The listener fires every vsync frame (potentially 60-120 fps) but only meaningfully changes state once per second, wasting CPU cycles
- It couples the break timer to the widget's `TickerProviderStateMixin`, preventing extraction into a pure service

A `Timer.periodic` would be more appropriate, as already used elsewhere in the same feature (`practice_session_screen.dart:81`).

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:39,49-55,98-116`
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:30` — `TickerProviderStateMixin` (only needed for the misused `_breakController`)

**Acceptance criteria:**
- Replace `AnimationController`-based break countdown with `Timer.periodic` or `Stream.periodic`
- Remove `TickerProviderStateMixin` if no other animation controllers remain
- The break countdown must still update the UI every second and auto-dismiss when reaching 0

---

### 5. Non-internationalized (hardcoded English) strings in dashboard and settings

**Severity:** Medium  
**Category:** Design language inconsistency / Internationalization gap  

- `lib/features/dashboard/presentation/widgets/collapsible_card.dart:45`: `'Something went wrong'` should use `AppLocalizations`
- `lib/features/dashboard/presentation/widgets/collapsible_card.dart:55`: `'Retry'` should use `AppLocalizations`
- `lib/features/settings/presentation/settings_screen.dart:158`: `'Focus Mode'` section title
- `lib/features/settings/presentation/settings_screen.dart:159`: `'Focus Timer'` list tile title
- `lib/features/settings/presentation/settings_screen.dart:160`: `'Start a focused study session'` subtitle
- `lib/features/settings/presentation/settings_screen.dart:162`: `'Daily Study Cap'`
- `lib/features/settings/presentation/settings_screen.dart:403`: `'No limit'` and `'$cap min/day'`
- `lib/features/planner/presentation/planner_screen.dart:147`: `'Subject ID (optional)'`
- `lib/features/planner/presentation/planner_screen.dart:148`: `'e.g. sub_physics'`
- `lib/features/planner/presentation/planner_screen.dart:388`: `'Subject Progress'`
- `lib/features/planner/presentation/planner_screen.dart:411`: `'$topicCount study days'` / `days plan`
- `lib/features/planner/presentation/planner_screen.dart:434`-`509`: `'Pending Actions'`, `'Scheduled Lessons'`, `'Regenerate Plan'`, `'$m more...'`

These strings are invisible to translation tooling (`l10n`) and will remain English in all locales.

**Acceptance criteria:**
- All user-visible strings must be routed through `AppLocalizations.of(context)!`
- Hardcoded English string literals should be removed from widget build methods

---

### 6. Loading indicators lack accessible semantics labels

**Severity:** Medium  
**Category:** Accessibility  

Multiple screens show `CircularProgressIndicator` without any `Semantics` wrapper, making screen readers silent during loading:

- `lib/features/practice/presentation/practice_session_screen.dart:265`
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:196`
- `lib/features/dashboard/presentation/dashboard_screen.dart:81`
- `lib/features/practice/presentation/practice_screen.dart:297`
- `lib/features/planner/presentation/planner_screen.dart:576`
- `lib/features/sessions/presentation/session_tracker_screen.dart:231`
- `lib/features/settings/presentation/settings_screen.dart:565`

**Acceptance criteria:**
- Each loading state should be wrapped in `Semantics(container: true, label: l10n.loadingMessage)` or similar
- The label should describe what is loading (e.g., "Loading subjects", "Loading questions")

---

### 7. Practice results screen has no navigation exit beyond "Practice Again"

**Severity:** Low-Medium  
**Category:** Confusing navigation  

`PracticeResultsScreen` (`lib/features/practice/presentation/widgets/practice_results_screen.dart`) only offers a single action: "Practice Again". After completing a full session, the user is shown their score and asked to repeat — but there is no button to:
- Return to the practice mode selection screen
- View detailed answer breakdown
- Navigate to the dashboard or subject detail

The only exit is the system back button, which pops to the practice screen. The "Practice Again" button calls `_restartSession` (`practice_session_screen.dart:235`) which reloads questions and starts over — if the user taps it accidentally, there is no confirmation or undo.

**Acceptance criteria:**
- Add an additional navigation option ("Back to Practice" or "View Details") alongside "Practice Again"
- Consider confirmation before restarting a completed session
- Show question-by-question result review (which question was right/wrong) instead of just aggregate stats

---

### 8. Session end dialog allows `correctAnswers > questionsAnswered`

**Severity:** Low  
**Category:** Widget sizing/placement / Data integrity  

`_SessionEndDialog` (`lib/features/sessions/presentation/session_tracker_screen.dart:426-492`) provides two text fields for "questions answered" and "correct answers" with no cross-field validation. A user can input `5` correct answers out of `3` questions, corrupting analytics data.

**Acceptance criteria:**
- Show inline validation error when correct answers exceed total questions
- Disable the "Save" button until valid input is provided
- Consider using a single stepper/slider UI to prevent impossible combinations

---

## Summary of impact

| # | Issue | Category | Affected features |
|---|---|---|---|
| 1 | Navigation model conflict | Confusing navigation | All tabs, all sub-screens |
| 2 | `TextScaler.noScaling` | Accessibility | Entire app |
| 3 | Dashboard rebuild storm | Performance | Dashboard |
| 4 | AnimationController as timer | Problematic animation | Focus mode |
| 5 | Hardcoded English strings | Design inconsistency | Dashboard, Settings, Planner |
| 6 | Missing Semantics on loaders | Accessibility | Practice, Focus, Dashboard, Planner, Sessions |
| 7 | Results screen locked navigation | Confusing navigation | Practice |
| 8 | Session dialog lacks validation | Data integrity | Sessions |

Priority order for fixes: 1, 2, 3, 4, 6, 5, 7, 8.
