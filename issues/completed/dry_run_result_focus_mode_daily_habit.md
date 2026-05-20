# Dry-Run Issue: Focus Mode Daily Habit — Remaining Gaps

**Source scenario:** `dry-run-test/scenario_focus_mode_daily_habit.md` (deleted — >80% validated)

**Validator date:** May 2026

## Remaining PARTIAL Items

### 1. No First-Time Focus Mode Onboarding (Step 1)

**Status:** PARTIAL

The `firstFocusVisit` flag exists in `SettingsBox` (default `true`) and is read at `focus_timer_screen.dart:113`, but it is silently cleared only — no onboarding UI, tooltip, or explanatory text is shown to first-time Focus Mode users.

**Code references:**
- `lib/features/settings/data/models/settings_box.dart:79,119` — `firstFocusVisit` field
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:113-119` — silently clears flag without showing any UI

**What needs to be done:** When `firstFocusVisit` is `true`, show a one-time brief explanation card/tooltip explaining what Focus Mode is and how it works (e.g. "Use Focus Mode to study distraction-free with a built-in timer. Each session counts toward your daily study goal.").

---

### 2. Daily Study Cap Not Enforced Mid-Session (Step 6)

**Status:** PARTIAL

The daily cap is checked at session start (`study_timer_service.dart:72-78`, `focus_timer_screen.dart:267-293`) with a warning dialog that offers an override. However, `isDailyCapExceededMidSession()` at `study_timer_service.dart:80-87` exists but is **never called** — once a session starts, the cap is not checked again.

**Code references:**
- `lib/features/sessions/services/study_timer_service.dart:72-78` — `isDailyCapReached()` (called at start)
- `lib/features/sessions/services/study_timer_service.dart:80-87` — `isDailyCapExceededMidSession()` (exists, **unused**)
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:265-314` — `_startFocus()` (cap check with warning dialog)

**What needs to be done:** Either call `isDailyCapExceededMidSession()` periodically during the session (e.g., every minute in the timer tick) to warn the user, or at minimum check it when returning from background in `didChangeAppLifecycleState` / `_reconcileBackgroundTime()`.

---

### 3. BadgeService Instantiated Directly (Step 10)

**Status:** PARTIAL

`_checkBadges()` at `focus_timer_screen.dart:195-203` creates a new `BadgeService()` instance instead of obtaining one from a Riverpod provider. This breaks dependency injection and testability.

**Code references:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:195-203` — `_checkBadges()` uses `BadgeService()` directly (line 198)
- `lib/core/services/badge_service.dart:6-107` — `BadgeService` class

**What needs to be done:** Create a `badgeServiceProvider` in a Riverpod provider file and inject `BadgeService` with all its dependencies (repository, `getStats` callback, notification service). Use `ref.read(badgeServiceProvider)` in the focus timer screen.

---

### 4. Background Timer May Under-Count Time (Step 11)

**Status:** PARTIAL

`StudyTimerService._startTimer()` at `study_timer_service.dart:128-150` uses diff-based wall-clock calculation (`now.difference(_lastTickTime)`), which is better than a fixed 1000ms increment. When the app returns to foreground, `_reconcileBackgroundTime()` at `focus_timer_screen.dart:93-102` adds any expected elapsed time.

However, `Timer.periodic` does not fire when the app is fully suspended (especially on iOS). The reconciliation only handles returning from background — time spent while the app is suspended and then returns is corrected, but there is no platform-level alarm to detect timer completion in the background and no notification fires when the timer completes in the background.

**Code references:**
- `lib/features/sessions/services/study_timer_service.dart:128-150` — `_startTimer()` with diff-based calculation
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:93-102` — `_reconcileBackgroundTime()` for foreground return
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:82-91` — `didChangeAppLifecycleState` lifecycle handler

**What needs to be done (stretch):** For production quality, consider using `flutter_local_notifications` scheduled notifications as a fallback timer (schedule a notification at `now + remainingDuration` when the app goes to background). Alternatively, use a platform-specific background isolate or workmanager to ping the timer. At minimum, ensure `_reconcileBackgroundTime()` handles edge cases correctly (e.g., phone was locked for 5 minutes, diff could be very large).

---

## Items That Were BLOCKER/MAJOR FAIL in Scenario but Are Now COMPLETED

| # | Old Verdict | Resolution |
|---|---|---|
| 7 | Notification preferences cosmetic only | **FIXED** — `_isNotificationEnabled()` reads all toggles; settings synced to scheduler |
| 8 | Daily reminder never callable | **FIXED** — UI exists in Settings; `showDailyReminder()` called from time picker |
| 9 | Lesson reminders never scheduled | **FIXED** — `_checkUpcomingLessons()` runs every 5 min via scheduler |
| 14 | EngagementScheduler orphaned | **FIXED** — stored as global + Riverpod provider; settings synced on build |
