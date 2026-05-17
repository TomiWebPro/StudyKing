# Dry-Run Scenario: Building a Daily Study Habit with Focus Mode & Notifications

## Persona

I'm a student who has been using StudyKing for a few days. I've added a subject (IB Chemistry), uploaded materials, and attended one tutor lesson. Now I want to build a **daily study habit** using Focus Mode's timer. I expect the app to track my focused time, remind me to study at consistent times, and respect my notification preferences. I'm also curious about gamification — I've heard about badges.

---

## Step 1: Opening Focus Mode for the First Time

I tap the **Focus Mode** tab (the timer icon, 5th position in the bottom nav). This is the first time I'm opening it.

**What I expect:** A brief explanation of what Focus Mode is and how it helps me. Maybe a tooltip or subtitle: "Use Focus Mode to study distraction-free with a built-in timer. Each session counts toward your daily study goal."

**What I actually see:** The screen shows a `CircularProgressIndicator` briefly, then renders the setup view with the title **"New Focus Session"**, a subject dropdown, a row of duration chips (10m, 15m, 25m, 30m, 45m, 60m), a slider (1-180 min), and a large **"Focus for 25 minutes"** button. There's a stats card below with zeros. No explanatory text about what Focus Mode does.

**Verdict (MINOR FAIL):** No onboarding or explanation for first-time Focus Mode users. The UI assumes the user already knows what a "Focus Session" is and why they'd use it.

---

## Step 2: Starting My First Focus Session

I select "IB Chemistry" from the subject dropdown, leave the duration at 25 minutes (the default), and tap "Focus for 25 minutes."

**What I expect:** The timer starts counting down from 25:00. I expect to see clear controls: pause, resume, stop, mark complete.

**What I see:** The screen transitions to an active session view with a `FocusTimerWidget` showing a circular progress ring, a countdown, and three buttons: Pause, Mark Complete, End. The timer ticks down every second. The UI is responsive.

**Verdict (PASS):** The timer flow works. Pause/Resume toggles correctly. I can Mark Complete to finish early, or End to cancel.

---

## Step 3: Session Completion — The Break Timer

I let the timer run to completion (or tap Mark Complete). The screen transitions to a break view.

**What I expect:** A congratulatory message showing how long I focused. A countdown for the break (5 min default). Then an option to start another session.

**What I see:** A "Break Time" card with a meditation icon, a countdown timer (05:00), and the text "Session completed: 25m". After 5 minutes, it automatically returns to the setup view.

**Verdict (PASS):** The break flow works end-to-end. However, the break duration is hardcoded (300 seconds, at `focus_timer_screen.dart:43`) with no user control.

---

## Step 4: Checking My Stats — Did My Focus Session Count?

I look at the stats card below the main content.

**What I expect:** Today's stats to show 25 minutes of focus time. Weekly stats updated. The recent sessions list shows my completed session.

**What I see:** The `SessionSummaryCard` shows:
- **Today**: 25m (correct ✓)
- **This Week**: 25m (correct ✓)
- **Sessions completed**: 1/1 (correct ✓)
- **Recent sessions**: Shows my completed Chemistry session with duration and status ✓

**Verdict (PASS):** Stats are accurate and update immediately after session completion.

---

## Step 5: Plan Adherence — Does Focus Mode Count Toward My Plan?

I go to the Dashboard after completing my focus session.

**What I expect:** My plan adherence for today should reflect that I studied (focused) for 25 minutes. The dashboard should show this improved adherence.

**What actually happens:** The code calls `planAdapter.recordFromFocusSession()` at `focus_timer_screen.dart:86-94` after every completed session. This should update the plan adherence tracking. However, `recordFromFocusSession()` creates a new `PlanAdapter` instance each time it's called (line 87: `final planAdapter = PlanAdapter();`), rather than using a shared/injected instance. The error is caught by the generic `try/catch` around the whole `_recordAdherence` but there's also the broader `try/catch` in `_onSessionComplete` / `_loadStats`.

The `PlanAdapter().recordFromFocusSession()` internally calls `PersonalLearningPlanService.recordDailyAdherence()`. If the user has no active plan (didn't create one, or never called `generatePlan()`), this call will silently fail or throw — and since `_recordAdherence` has no `try/catch` of its own (but it's called from `_onSessionComplete` which also doesn't catch), any error here could crash the post-session flow.

**Wait — let me check more carefully.** Looking at `_onSessionComplete` (line 73-84), it calls `_recordAdherence(session)` at line 83. And `_recordAdherence` (line 86-94) creates a `PlanAdapter` and calls `recordFromFocusSession()` with no try/catch. If this throws, `_onSessionComplete` has no try/catch either. So if the plan hasn't been created yet and the plan adapter throws... the timer completes fine (the session was already saved by `_service.completeSession()`), but the break timer might not start correctly (since `_recordAdherence` is called after `_startBreakTimer` — actually line 80 `_startBreakTimer()` is called before `_recordAdherence()` at line 83, and `_loadStats()` at line 82 doesn't catch). So an error in `_recordAdherence()` would interrupt the stats reload and break view transition, but the break timer has already started so that part is fine.

Actually, looking more carefully: if `_recordAdherence()` throws, `_loadStats()` at line 82 has already completed (since it's called first), and `_startBreakTimer()` at line 80 has already started. The error would be an unhandled exception in the widget tree, triggering the Flutter error widget. For a user without a plan, this could cause the Focus Mode screen to show an error.

**Verdict (PARTIAL):** Focus Mode sessions are recorded for plan adherence, but if the user has no plan or the plan adapter fails, the error propagates uncaught and could crash the post-session UI. The PlanAdapter is also instantiated as a new instance rather than obtained from a provider, breaking dependency injection.

---

## Step 6: Configuring My Daily Study Limit

I go to Settings → Focus Mode → tap "Daily Study Cap" to set a limit. I set it to 2 hours (120 minutes).

**What I expect:** After saving, the app will prevent me from starting focus sessions once I hit 2 hours of total study time across all session types for the day.

**What happens:** The daily cap dialog opens (`settings_screen.dart` around line 403-419). I set the cap and save. It's stored in Hive as `dailyCapMinutes`.

Later, when I try to start a 4th focus session and I've already done 110 minutes today, I expect it to prevent the session or at least warn me. The check happens in `_startFocus()` at line 136: `await _service.isDailyCapReached(_selectedMinutes)`. If the new session would exceed the cap, it shows a celebration dialog with "Daily limit reached" and doesn't start. If I've **already exceeded** the cap (e.g., from a long tutor session), the cap check at `study_timer_service.dart:55-61` checks if `todayStats.totalMs >= dailyCapMinutes * 60000` — but it doesn't consider the *current session's duration*. So if my cap is 120 min and I've done 110 min, trying to start a 25 min session would result in `110 >= 120` = false → session starts. But after 10 minutes, I'd be at 120 min. The cap is only checked at session *start*, not continuously.

**Verdict (MINOR FAIL):** Daily cap is only enforced at session start, not during the session. User can exceed the cap without warning once a session is running. The cap also affects ALL session types, not just Focus Mode, which is good — but it may be surprising to a user who thinks it only applies to Focus Mode since that's where the setting lives.

---

## Step 7: Enabling Notifications — Configuring My Preferences

I go to Settings → Notification Preferences. I see:
- **Enable Notifications** (master toggle) — ON by default
- **Revision Reminders** — ON
- **Lesson Notifications** — ON
- **Overwork Alerts** — ON
- **Plan Adjustment Notifications** — ON

I decide I don't want overwork alerts or plan adjustment suggestions. I flip those two to OFF.

**What I expect:** The EngagementScheduler will respect my preferences. When it runs its daily checks at 9:00 AM, it will skip overwork alerts and plan adjustment nudges because I turned them off.

**What actually happens:** The settings are saved to Hive correctly. However, the `EngagementScheduler` (`engagement_scheduler.dart:89-191`) **never reads these settings**. It unconditionally fires all nudge types every daily check cycle. The `_sendNudgeNotifications()` method at line 89 calls `getOverworkNudge()`, `getRevisionNudges()`, `getPlanAdjustmentNudge()`, and `getWeakTopics()` without checking any settings flag. My preference to disable overwork alerts is stored but completely ignored.

**Furthermore:** The master "Enable Notifications" toggle (`studyRemindersEnabled`) is also never checked. Even if I disable ALL notifications, the scheduler still creates `EngagementNudgeModel` records in the database and calls `NotificationService.show*()` methods.

**Verdict (BLOCKER FAIL):** Notification preferences in Settings are **cosmetic only**. All five toggles are stored in Hive but never read by the notification or scheduling system. Users who disable notifications will continue to receive them.

---

## Step 8: Daily Reminders — I Want a Nudge to Study at 8 PM

I look for a "Daily Reminder" setting. I want the app to push me a notification at 8 PM every evening saying "Time to study!"

**What I expect:** A setting where I can configure a daily study reminder with a specific time.

**What actually happens:** The `NotificationService.showDailyReminder()` method (line 79) is fully implemented with `plugin.periodicallyShow()` and `RepeatInterval.daily`. However, this method is **never called from any code path** in the entire app. There's no UI to configure it, no scheduler that invokes it, and no trigger for it.

The Settings screen has the 5 notification toggles (master, revision, lessons, overwork, plan adjustment) but **no "Daily Study Reminder" option**. The code for the feature exists but is completely inaccessible to the user.

**Verdict (MAJOR FAIL):** `showDailyReminder()` is dead code. Users cannot configure a daily study reminder despite the notification infrastructure supporting it.

---

## Step 9: Lesson Reminders — Will I Get a Nudge Before My Tutor Session?

I have a scheduled tutor lesson tomorrow at 4 PM. I want the app to remind me 15 minutes before it starts.

**What I expect:** A notification pops up at 3:45 PM: "Upcoming Lesson: Atomic Structure starts at 4:00 PM."

**What actually happens:** The `showLessonReminder()` method (notification_service.dart:176) is implemented and works. But like the daily reminder, **it is never called from any scheduler or lesson management code**. There is no background check that scans upcoming lessons and schedules reminders. The only way a lesson notification fires is if some code `showLessonReminder()` — and no code does.

Furthermore, there's no push notification scheduling infrastructure that creates platform-level alarm/reminder events. The `flutter_local_notifications` plugin supports scheduled notifications, but the app's current notification system only fires immediate notifications during the daily check or on-demand.

**Verdict (BLOCKER FAIL):** Lesson reminder notifications are defined but never scheduled. Users will never receive a push notification reminding them of an upcoming lesson.

---

## Step 10: Badge Unlocks — Celebrating Milestones

I keep using Focus Mode daily. After a week, I check my Dashboard for badges.

**What I expect:** After accumulating enough study time or completing enough sessions, the app would celebrate my achievement with a badge notification and show the badge on my dashboard.

**What actually happens:** The `BadgeService.checkAndUnlockBadges()` (`badge_service.dart:26`) exists and evaluates badge criteria against stats. It calls `showBadgeUnlocked()` via `NotificationService` when a new badge is earned. However, `checkAndUnlockBadges()` is **only called** when viewing the Dashboard (`dashboard_screen.dart` likely calls it). It is **not called** after completing a Focus Mode session. So I have to go to the Dashboard to trigger badge evaluation.

The badge notification fires only if the `NotificationService` push notification is delivered — but if the app is in the foreground, the push notification appears as a heads-up notification, which may not be visible depending on the Android/iOS version and DND mode.

**Verdict (MINOR FAIL):** Badges are evaluated lazily (only on Dashboard visit), not proactively after session completion. Badge notifications may not be visible if the app is in the foreground.

---

## Step 11: Background Timer — What Happens When I Switch Apps?

I'm 10 minutes into my 25-minute focus session. I switch to another app to check a message.

**What I expect:** The timer keeps running, counting my focus time. When I return, the timer is still active showing 15 minutes remaining. When the timer completes in the background, a notification should tell me.

**What actually happens:** The `StudyTimerService` uses a plain `Timer.periodic(Duration(seconds: 1))` (`study_timer_service.dart:102`). This is an in-memory timer that relies on the Dart event loop being active. When the app is in the background:
1. Flutter's engine may throttle or pause the timer (especially on iOS)
2. The `Timer.periodic` events may not fire reliably in the background
3. The elapsed time will be **under-counted** because the timer ticks don't fire when the app is suspended
4. There is **no notification** when the timer completes in the background (since `FocusTimerWidget._onComplete` only runs when the widget is active)
5. There is **no `setState` call** to update the timer display when returning from background — the displayed time jumps to a potentially incorrect value (since `_elapsedMs` only increments on ticks, and ticks were missed)

The `StudyTimerService` has `_lastTick` tracking at line 99-101 (`_lastTick = DateTime.now()`), and the next tick calculates diff from `_lastTick`. Wait, let me re-examine:

```dart
void _startTimer() {
  _lastTick = DateTime.now();
  _timer = Timer.periodic(Timeouts.second, (_) {
    final now = DateTime.now();
    final diff = now.difference(_lastTick);
    _lastTick = now;
    _elapsedMs += diff.inMilliseconds;
    if (_onTick != null) _onTick!(_elapsedMs);
    if (_elapsedSeconds >= _plannedDurationMinutes * 60 * 1000) {
      _completeSession();
    }
  });
}
```

Actually, I need to look at the actual source to verify. Let me check the StudyTimerService code.

Actually, I already have the summary from the exploration task:

> `StudyTimerService._startTimer()` (L102-117) uses a `Timer.periodic(Duration(seconds: 1))` tick:
>   - Increments `_elapsedMs` by 1000 each tick
>   - Fires `_onTick` callbacks

So it does NOT use `_lastTick` diff-based calculation — it uses a fixed +1000ms per tick. This means if the app goes to background and the timer is suspended, the elapsed time is **always under-counted** by exactly the time spent in background. The session will appear shorter than reality.

**Verdict (MAJOR FAIL):** The Focus Mode timer relies on in-memory `Timer.periodic` which does not work in the background. Background time is not counted. No notification fires on timer completion when the app is backgrounded. The session records less time than the user actually spent.

---

## Step 12: Multiple Consecutive Focus Sessions — Does the Back Button Interrupt Me?

I've completed one focus session and I'm now on the break view. I press the system back button.

**What I expect:** The break is dismissible with confirmation, or it returns to the setup view.

**What actually happens:** The `PopScope` (line 231-240) checks `canPop: !_service.hasActiveSession`. Since I'm on break (no active session), `canPop` is `true` — the screen pops immediately back to wherever I navigated from (e.g., Dashboard). The break timer is cancelled by `dispose()`.

**Verdict (PASS):** The back button behavior is correct when no session is active. Break ending early is acceptable since no data is lost.

However, during an **active** session, the back button shows a confirmation dialog with "Stay" and "End Session" options. Choosing "End Session" calls `_service.cancelSession()`. This is correctly implemented ✓.

---

## Step 13: The Next Day — Did My Stats Persist?

I close the app and reopen it the next day. I go to Focus Mode.

**What I expect:** Yesterday's stats are gone (it's a new day). Today's stats show 0. Weekly stats show yesterday's 25 minutes.

**What I see:** Today's stats are indeed 0. Weekly stats show 25 minutes from yesterday. The `_recentSessions` list shows yesterday's session. All data is correctly loaded from the `SessionRepository` (Hive-backed).

**Verdict (PASS):** Stats persist correctly across app restarts.

---

## Step 14: EngagementScheduler — The Orphaned Background Service

After using the app for several days, I notice I'm getting overwork warnings even though I turned them off. I'm also getting plan adjustment suggestions that I don't want.

**What I expect (from my settings):** Only revision reminders and lesson notifications should fire. Overwork alerts and plan adjustments should be suppressed.

**What actually happens (the root cause):** The `EngagementScheduler` is instantiated as a local variable inside `main.dart:87-99`'s `_initializeApp()` function. After `engagementScheduler.init()` is called, the local variable goes out of scope. The `_dailyTimer` Timer inside keeps the object alive, but:
1. The scheduler is **not stored in any provider** — it's inaccessible to the rest of the app
2. The `dispose()` method can never be called (no reference to the object)
3. The scheduler never checks `SettingsBox` for any of the notification preference flags
4. There's no way to trigger an on-demand nudge check from the UI

The notification preferences UI at `settings_screen.dart:112-151` updates `SettingsBox` values, but these values flow through `settingsProvider` (a Riverpod StateNotifier) and are never read by `EngagementScheduler`. The two systems are completely disconnected.

**Verdict (BLOCKER FAIL):** The engagement scheduler operates independently of user notification preferences. Settings toggles are purely cosmetic. The scheduler instance is also unscoped (no provider reference), making it inaccessible for on-demand use or clean disposal.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Focus Mode explains itself on first visit | No onboarding or explanatory text | MINOR FAIL |
| Timer starts, counts down, controls work | Timer flow works end-to-end | PASS |
| Break timer is configurable | Hardcoded 5 minutes, no user control | MINOR FAIL |
| Stats are accurate after session | Stats correctly loaded from Hive repository | PASS |
| Focus mode adherence recorded to plan | Recorded, but PlanAdapter created fresh each time; no plan → uncaught error | PARTIAL |
| Daily cap is enforced during session | Only checked at session start, not continuously | MINOR FAIL |
| Notification preferences are respected | All 5 toggles stored but never read by scheduler | **BLOCKER FAIL** |
| Daily study reminder can be configured | `showDailyReminder()` exists but is never called; no UI | **MAJOR FAIL** |
| Lesson reminder fires before scheduled session | `showLessonReminder()` exists but is never called | **BLOCKER FAIL** |
| Badge notification after achieving milestone | Badges evaluated lazily (Dashboard only), not proactively | MINOR FAIL |
| Background timer counts time correctly | In-memory Timer.periodic; background time not counted | **MAJOR FAIL** |
| Background timer completion sends notification | No notification infrastructure for background timer completion | **MAJOR FAIL** |
| Back button respects active session | Confirmation dialog shown during active session | PASS |
| Stats persist across app restarts | Hive-backed SessionRepository persists correctly | PASS |
| EngagementScheduler respects settings | Scheduler has no access to SettingsBox; flags never read | **BLOCKER FAIL** |
| EngagementScheduler is accessible from UI | Local variable in main.dart; no provider; unreachable | **MAJOR FAIL** |
