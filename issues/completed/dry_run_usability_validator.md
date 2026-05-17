# Dry-Run Usability Validator: Focus Mode & Notification System

## Scenario

**"I'm a student who wants to build a daily study habit using Focus Mode. I expect the app to remind me to study at my scheduled times, track my focus sessions, and respect my notification preferences."**

Scenario file: `dry-run-test/scenario_focus_mode_daily_habit.md`

---

## Finding Summary

| Severity | Count |
|---|---|
| BLOCKER | 3 |
| MAJOR | 4 |
| MINOR | 4 |
| PARTIAL | 1 |
| PASS | 5 |

---

## BLOCKER Findings

### B1. Notification preferences are cosmetic only — settings never read by scheduler

**Files affected:**
- `lib/core/services/engagement_scheduler.dart:89-191` — `_sendNudgeNotifications()` fires all nudge types unconditionally
- `lib/features/settings/presentation/settings_screen.dart:112-151` — UI toggles exist
- `lib/features/settings/data/models/settings_box.dart:33-61` — fields `studyRemindersEnabled`, `revisionRemindersEnabled`, `lessonNotificationsEnabled`, `overworkAlertsEnabled`, `planAdjustmentNotificationsEnabled`
- `lib/core/providers/app_providers.dart:145-200` — `update*()` methods save to Hive but never publish to scheduler

**Problem:** Settings has 5 notification toggle switches (master, revision, lessons, overwork, plan adjustment) that persist to Hive. However, `EngagementScheduler._sendNudgeNotifications()` never reads any of these fields. Users who disable all notifications will continue receiving push notifications and persisted nudges. The two systems are completely disconnected.

**Acceptance criteria:**
- `EngagementScheduler` must accept or read `SettingsBox` at runtime
- Before firing each nudge type, the scheduler must check the corresponding setting flag
- Disabling the master toggle (`studyRemindersEnabled`) must suppress all notification types
- Toggling a setting should take effect on the next daily check (no restart required)

---

### B2. Lesson reminder notifications are defined but never scheduled

**Files affected:**
- `lib/core/services/notification_service.dart:176-192` — `showLessonReminder()` fully implemented
- `lib/core/services/engagement_scheduler.dart` — no mention of lesson reminders
- `lib/features/planner/providers/` — no scheduler or background check for upcoming lessons

**Problem:** `showLessonReminder()` is implemented and testable, but no code path in the entire app ever invokes it. There is no background scheduler that scans upcoming scheduled lessons and fires a push notification before the lesson time. Users will never receive a reminder notification for an upcoming tutor session.

**Acceptance criteria:**
- A background check (possibly integrated into `EngagementScheduler._runDailyChecks()` or a separate periodic check) must scan upcoming scheduled lessons
- For lessons starting within the next 15-30 minutes, call `showLessonReminder()`
- Consider scheduling platform-level alarms via `flutter_local_notifications` for precise timing
- Toggle `lessonNotificationsEnabled` in `SettingsBox` must gate this behavior

---

### B3. EngagementScheduler lifecycle — orphaned instance, no provider, no disposal

**Files affected:**
- `lib/main.dart:86-102` — `EngagementScheduler` created as local variable in `_initializeApp()`, goes out of scope
- `lib/core/services/engagement_scheduler.dart:291-293` — `dispose()` exists but is unreachable

**Problem:** The `EngagementScheduler` is instantiated as a plain local variable inside `_initializeApp()`. After `init()` returns, the reference is lost. While the internal `Timer` keeps the object alive via closures, the scheduler is:
1. Inaccessible from any other part of the app (no Riverpod provider, no global)
2. Cannot be disposed (no reference to call `dispose()`)
3. Cannot be triggered on-demand (e.g., "Check nudges now" button)
4. Cannot access `settingsProvider` to read notification preferences

**Acceptance criteria:**
- Provide `EngagementScheduler` via a Riverpod provider (e.g., `engagementSchedulerProvider`)
- Store the provider reference so it can be disposed or triggered from the UI
- Add a "Check nudges now" action somewhere (Settings or Mentor screen)
- Ensure `dispose()` is called when the app is terminated or the scheduler is no longer needed

---

## MAJOR Findings

### M1. Daily study reminder (`showDailyReminder()`) is dead code

**Files affected:**
- `lib/core/services/notification_service.dart:79-124` — `showDailyReminder()` fully implemented with `plugin.periodicallyShow()` and `RepeatInterval.daily`
- `lib/features/settings/presentation/settings_screen.dart` — no daily reminder time picker or toggle

**Problem:** `showDailyReminder()` creates a recurring daily notification at a specified time using the platform's inexact alarm API. This method exists and is tested (`test/core/services/notification_service_test.dart:43`), but nothing in the app ever calls it. There is no settings UI to configure a daily reminder time, and the `EngagementScheduler` doesn't invoke it. Users cannot set up a daily study nudge despite the infrastructure existing.

**Acceptance criteria:**
- Add a "Daily Reminder" setting in Settings → Notification Preferences with a time picker
- On save, call `showDailyReminder()` with the selected time
- The `studyRemindersEnabled` master toggle should gate this reminder
- Cancel the periodic notification when reminders are disabled

---

### M2. Focus Mode timer does not work in background — time under-counted, no completion notification

**Files affected:**
- `lib/features/sessions/services/study_timer_service.dart:102-117` — `_startTimer()` uses `Timer.periodic(Duration(seconds: 1))` with fixed +1000ms per tick
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — no background-aware session management

**Problem:** The Focus Mode timer uses an in-memory `Timer.periodic` that only fires when the Dart event loop is active. When the app goes to the background:
1. Flutter may throttle or suspend the timer (especially on iOS)
2. Missed ticks mean `_elapsedMs` is under-counted — the session records less time than actually spent
3. When the timer would have completed in the background, no notification fires
4. No `WidgetsBindingObserver` (lifecycle observer) or app lifecycle callback to handle background transitions

**Acceptance criteria:**
- Register a `WidgetsBindingObserver` in `FocusTimerScreen` or `StudyTimerService` to detect app lifecycle changes
- On app resume, calculate actual wall-clock elapsed time vs tracked elapsed time and reconcile
- On timer completion in background, fire a local push notification via `NotificationService`
- Consider using `Timer.periodic` with diff-based calculation (store `_lastTick`, compute diff from `DateTime.now()`) to handle throttled ticks

---

### M3. No onboarding or explanation for first-time Focus Mode users

**Files affected:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:348-420` — setup view shows cards/chips but no explanatory text

**Problem:** When a user opens Focus Mode for the first time, they see "New Focus Session" with a subject dropdown and timer configuration controls but zero explanation of:
- What Focus Mode is used for
- How sessions are recorded and contribute to study stats
- What the break timer does
- How to interpret the session completion

Compare this to the product vision: "The system should proactively engage students." The Setup view assumes prior knowledge.

**Acceptance criteria:**
- Show an onboarding tooltip or brief card on first visit explaining Focus Mode
- Use a provider-level `firstFocusVisit` flag in settings to gate the onboarding
- Add subtitle text near "New Focus Session": "Set a timer and study distraction-free. Completed sessions count toward your daily plan."

---

### M4. Break timer is hardcoded to 5 minutes, no user control

**Files affected:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:43` — `final int _breakDuration = 300;` (hardcoded 5 minutes)
- `lib/features/settings/presentation/settings_screen.dart` — no break duration setting

**Problem:** The break timer between focus sessions is hardcoded to 300 seconds. The user has no way to configure a shorter or longer break. The product vision mentions "prevent student from overworking" but also "respect the requested class hour" — a user should be able to decide their own break length.

**Acceptance criteria:**
- Add a "Break Duration" setting (e.g., 1-15 minutes) in Settings → Focus Mode
- Store the preference in `SettingsBox`
- Pass the configured duration to `FocusTimerScreen` instead of the hardcoded 300

---

## MINOR Findings

### m1. Daily cap is only enforced at session start, not continuously

**Files affected:**
- `lib/features/sessions/services/study_timer_service.dart:55-61` — `isDailyCapReached()` checks only at session start
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:136` — only called in `_startFocus()`

**Problem:** The daily study cap prevents starting a new session when the cap would be exceeded, but once a session is running, the timer completes regardless of cap. If the daily cap is 120 min and the user has done 115 min today, a 25-min session starts and runs for the full 25 minutes, ending at 140 min (20 over the cap).

**Acceptance criteria:**
- Option A: Auto-stop the session when the daily cap is reached mid-session (with user notification)
- Option B: Show a warning when starting: "Starting this session will exceed your daily cap by X minutes. Continue?"
- The chosen approach should be non-disruptive (never forcefully end a user's active focus without their consent)

---

### m2. Badges evaluated lazily (only on Dashboard visit), not proactively after sessions

**Files affected:**
- `lib/core/services/badge_service.dart:26-64` — `checkAndUnlockBadges()` exists but is only called from Dashboard
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — no badge check after session completion

**Problem:** Badge evaluation only triggers when the user visits the Dashboard. If a user completes 10 focus sessions but never visits the Dashboard, badges are never evaluated and unlocked. The product vision says "The system should proactively engage students" — unlocking a badge should feel reactive to the achievement, not to navigation.

**Acceptance criteria:**
- Call `BadgeService.checkAndUnlockBadges()` after focus session completion (in `_onSessionComplete` or in `StudyTimerService.completeSession()`)
- Same for practice session completion and tutor lesson completion
- Consider debouncing (don't re-evaluate if just evaluated within the last minute)

---

### m3. PlanAdapter instantiated as raw constructor call instead of injected dependency

**Files affected:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:87` — `final planAdapter = PlanAdapter();`

**Problem:** `PlanAdapter()` is created as a new instance inside `_recordAdherence()` rather than obtained from a provider or injected into the screen. This makes the screen harder to test (cannot mock/substitute the PlanAdapter) and breaks dependency injection patterns used elsewhere in the app (e.g., `studyTimerServiceProvider` injects `SessionRepository`).

**Acceptance criteria:**
- Provide `PlanAdapter` via a Riverpod provider (e.g., `planAdapterProvider`)
- Read the provider in `FocusTimerScreen` instead of calling `PlanAdapter()` directly
- Update tests to use provider overrides with a fake PlanAdapter

---

### m4. First-time user has no explanation of what Focus Mode is

*(Same scope as M3 — listed as MINOR here because it's a UX friction rather than a broken feature)*

---

## PARTIAL Findings

### P1. Focus Mode adherence recording works but has no plan error resilience

**Files affected:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:86-94` — `_recordAdherence()` no try/catch
- `lib/core/services/personal_learning_plan_service.dart:430-455` — `recordDailyAdherence()` has try/catch + null check

**Analysis:** The `_recordAdherence` method at line 86-94 calls `planAdapter.recordFromFocusSession()` without its own try/catch. The downstream `PersonalLearningPlanService.recordDailyAdherence()` handles errors internally (try/catch at line 436, null check at line 438). However, `_recordAdherence` is fire-and-forget (called without `await`), so any theoretical uncaught error in the chain would crash the app. In practice, the downstream methods are safe, but the pattern is fragile — any future change that introduces a throw between the fire-and-forget call site and the downstream catch would result in a hard crash. Additionally, `PlanAdapter` is created as a raw `PlanAdapter()` instance (see m3).

**Acceptance criteria:**
- Add try/catch to `_recordAdherence()` for defensive safety
- Add a `planAdapterProvider` and inject it into `FocusTimerScreen` (links to m3)
- Log warnings if adherence recording fails (currently silent)

---

## PASS Findings (for reference)

| Check | Why it Passes |
|---|---|
| Timer starts, counts down, controls work | `FocusTimerWidget` at `focus_timer_widget.dart` implements play/pause/stop/mark-complete correctly |
| Stats are accurate after session | `SessionSummaryCard` at `session_summary_card.dart` reads from `SessionRepository` which is Hive-backed and updates immediately |
| Break flow transitions correctly | `_startBreakTimer()` at `focus_timer_screen.dart:100` counts down and auto-returns to setup view |
| Back button respects active session | `PopScope` + `_onWillPop` at `focus_timer_screen.dart:190-216` shows confirmation dialog with Stay/End options |
| Stats persist across app restarts | `SessionRepository` is Hive-backed, data survives process death |
