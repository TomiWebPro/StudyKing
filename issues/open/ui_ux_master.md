# Focus Mode: Uncontrolled Animation Lifecycle, Break Timer Stale-Listener Bug, and Invisible Navigation Tab

## Summary

The Focus Mode feature has three interrelated UI/UX defects: (1) a stale-listener memory/state bug in the break countdown, (2) an unscoped pulse animation that rebuilds the entire timer widget per frame, and (3) the entire feature is unreachable from the bottom navigation bar, requiring users to discover it through unmarked deep links.

---

## Context

Focus Mode (`lib/features/focus_mode/`) is a cross-cutting feature for timed study sessions with a Pomodoro-style break. It is the app's primary tool for tracking study duration and adherence. Despite its importance, it has no dedicated navigation tab, its animations are not properly scoped, and its break timer accumulates listeners on every session completion.

---

## Issue 1: Break Timer Listener Accumulation (Stale Closure Bug)

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart:99-117`

### What happens

Each time a session completes, `_onSessionComplete` → `_startBreakTimer()` is called. Inside `_startBreakTimer`, a **new listener** is attached to `_breakController` via `addListener`. The listener closure captures `_breakRemaining` by reference and decrements it.

- **First session:** 1 listener → break counts down correctly.
- **Second session (after break ends, user starts another):** 2 listeners → `_breakRemaining` decrements twice per tick. The break ends in ~150s instead of 300s.
- **Nth session:** N listeners → break time shrinks proportionally.

### Root cause

`_startBreakTimer` calls `_breakController.addListener(...)` but the old listener is never removed. `_breakController.dispose()` in `dispose()` discards the controller object but does not cleanly remove the individual listener closures. The `_breakController` is only created once in `initState` but listeners are appended unconditionally.

### Acceptance criteria

- [ ] Each call to `_startBreakTimer` must register exactly **one** listener.
- [ ] The listener must be removed when the break state resets (`_inBreak = false`) or when the widget disposes.
- [ ] An alternative: use a `Timer.periodic` for the break countdown instead of `AnimationController.addListener`, which is semantically clearer and avoids listener-management issues entirely.

---

## Issue 2: Unscoped Pulse Animation — Full Widget Tree Rebuild Per Frame

**Affected file:** `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart:33-76, 104-110`

### What happens

The `_pulseController` is a repeating `AnimationController` (1s duration) that drives a `Transform.scale` (`1.0 + _pulseController.value * 0.03` — a 3% scale pulse). The `AnimatedBuilder` wrapping the timer circle rebuilds the **entire** widget subtree (the `SizedBox`, `Stack`, `CircularProgressIndicator`, `Column`, `FittedBox`, two `Text` widgets) on every animation frame (~60fps).

### Problems

1. **Performance:** `CircularProgressIndicator` is itself a repaint-boundary-breaking widget. Nesting it inside an `AnimatedBuilder` that fires 60 times per second forces a relayout of the entire timer display, including the `FittedBox` and text measuring.
2. **Offstate energy waste:** The controller is never stopped when the widget is offstage (tab switched away). It continues to tick server frames that are never displayed.
3. **Paused state gap:** When `isPaused` is true, `_syncPulseAnimation` stops the controller. But when `isPaused` transitions back to false, the check `!_pulseController.isAnimating` may be false (controller still in `Animating` state from a previous `.repeat()` call), causing the pulse to **not resume**. The `didUpdateWidget` → `_syncPulseAnimation` call does not properly reset the controller's animation state.

### Acceptance criteria

- [ ] The pulse animation should be driven by a **reactive state** (e.g., a simple `AnimatedScale` or a custom `AnimatedWidget` that does not rebuild the entire child subtree) rather than an unscoped `AnimatedBuilder`.
- [ ] The `_pulseController` must be stopped when `isPaused` is true and properly retriggered when it becomes false (verify `_syncPulseAnimation` logic).
- [ ] The controller should respect `TickerMode` (it already does via the tab navigator's `Offstage`+`TickerMode`, but verify that break timer and pulse both pause/resume correctly when the user switches tabs and returns).

---

## Issue 3: Focus Mode Has No Navigation Tab

**Affected files:** `lib/main.dart:293-327`, `lib/features/focus_mode/presentation/focus_timer_screen.dart`

### What happens

Focus Mode is **not** listed in the `NavigationBar` destinations. The bottom bar shows: Subjects, Practice, Mentor, Dashboard, Settings. There is no Focus Mode tab.

### How users reach Focus Mode today

1. A `Card` on the Dashboard screen (line 98 in `dashboard_screen.dart`) with `Navigator.pushNamed(context, AppRoutes.focusMode)` — no label explaining this navigates to Focus Mode.
2. An `InkWell` wrapping `SessionSummaryCard` inside a `CollapsibleCard` titled "Focus Time" on the dashboard.
3. Deep links from planner adherence features.
4. There is no direct entry point from the main navigation.

### Why this matters

- **Discoverability failure:** A first-time user has no way to know Focus Mode exists. It is buried two levels deep inside the Dashboard's focus stats card.
- **Navigation inconsistency:** The app has a tab for Mentor (an AI chat) but not for the study timer — a core study tool in any serious study app.
- **Context loss:** When the user navigates from the dashboard to Focus Mode, the back button returns to the dashboard, not to wherever they were before. A dedicated tab would preserve context via `TabNavigator`.

### Acceptance criteria

- [ ] Add a Focus Mode destination to the `NavigationBar` (replace one existing tab or add a 6th tab, whichever preserves visual balance — max 5 is recommended by Material Design guidelines, so consider merging or re-labeling).
- [ ] If adding a 6th tab is undesirable (Material guideline recommends 3–5), consider replacing the Dashboard tab with Focus Mode and making Dashboard a top-level app bar action or the FAB (which is already a duplicate Dashboard button).
- [ ] Ensure the entry point from Dashboard's focus card still works as a shortcut (deep link to the tab).
- [ ] Add a visual indicator (e.g., badge or dot) when a focus session is active.

---

## Related Observations (Low Priority)

| Observation | Location | Notes |
|---|---|---|
| `FocusTimerScreen` creates `StudyTimerService` by reading the provider in `initState`, but holds a raw reference instead of watching it — if the provider's state is ever invalidated, the stale reference is used silently. | `focus_timer_screen.dart:53` | Not critical since the service is a singleton-like provider, but violates Riverpod conventions. |
| `SessionSummaryCard` reads `todayStats` by hardcoded string keys (`'completedSessions'`, `'totalSessions'`, `'totalMs'`) — the caller in `dashboard_screen.dart` passes keys `'totalSeconds'`, `'plannedMinutes'`, `'hours'`. There is a partial key mismatch: `totalMs` vs `totalSeconds`. | `session_summary_card.dart:34-35`, `dashboard_screen.dart:100-106` | The card will show 0 for totals if keys mismatch; only `completedSessions`/`totalSessions` survive. |
| All route transitions use `FadeTransition` only (`app_router.dart:234`). No visual hierarchy — a settings dialog fades in identically to a detail screen push. | `lib/core/routes/app_router.dart:229-240` | Monotonous; consider slide transitions for drill-down routes, fade for modals, aligning with Material 3 navigation semantics. |
