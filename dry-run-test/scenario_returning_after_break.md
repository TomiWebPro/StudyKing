# Dry-Run Scenario: Returning After a 2-Week Break — Plan Drift, Stale Sessions, and Re-Engagement

## Persona

I'm a student who has been using StudyKing for about a month. I've been studying **IB Chemistry** with a 90-day study plan, attended several AI tutor lessons, completed practice sessions, and accumulated solid progress data. Then life got in the way — I had exams in other subjects, got sick, and simply stopped opening StudyKing for **14 days**. Now I'm back. I want to understand what I missed, get back on track with my plan, and have the app help me re-engage without being overwhelmed.

---

## Step 1: First Launch After 14 Days — Does the App Know I've Been Away?

I open the app for the first time in two weeks.

**What I expect:** Some kind of acknowledgement that I've been away. A "Welcome back!" message, a notification banner, or at least an updated dashboard that shows my 2-week gap clearly. The app should understand my context — it has my data, it knows my plan, and it should help me pick up where I left off.

**What actually happens:**

The app initializes silently (same as first launch — `main.dart` → `MainScreen`). No splash screen, no welcome-back dialog, no absence banner. I'm dropped straight into whatever tab I was last on (likely the Dashboard or Planner).

The `StudentIdService` (`student_id_service.dart:27`) generates a UUID on first install and persists it. **There is no last-accessed timestamp stored anywhere.** The app has zero awareness that I've been away for 14 days. It cannot distinguish between "I just returned from a 2-week break" and "I was here 5 minutes ago."

**Verdict (FAIL — BLOCKER):** The app has no mechanism to detect that a user has been away. No last-accessed timestamp is stored on `StudentIdService`, `SettingsBox`, or any profile model. The returning user gets zero acknowledgement of their absence.

---

## Step 2: The Dashboard — Gaps Everywhere But No Explanation

I go to the Dashboard to see how I'm doing.

**What I expect:** A clear visual showing my 2-week gap — maybe the weekly chart has a gap annotation, or there's a "You missed X days" banner, or the adherence card shows "No activity for 14 days."

**What actually happens:**

The `DashboardScreen` (`dashboard_screen.dart:138-155`) shows:

1. **Weekly Activity Chart:** The `getWeeklyTrend()` method (`study_progress_tracker.dart:128-157`) iterates 8 weeks back and queries attempt records per week. For my 2 absent weeks, there are zero attempts, so those weeks render as **empty bars with 0 height** and **0 accuracy**. The chart shows a flatline of zeros for the gap period, with no annotation explaining why. It looks like I was studying poorly rather than not studying at all. On a small phone screen, this flatline could easily be mistaken for a UI glitch or empty data.

2. **Plan Adherence Card:** The `dashboardAdherenceDataProvider` (`dashboard_data_providers.dart:77-91`) queries adherence records. Since there are zero records for the gap period, `weeklyAdherence` defaults to `0.0`. The card shows "0%" adherence with no indication this is due to absence — it just looks like I completely ignored my plan.

3. **Mastery Overview / Weak Areas:** These show my pre-break mastery levels as stale snapshots. There's no "stale data" warning — the mastery levels haven't been updated in 14 days but look like current information.

4. **No "Welcome back" or absence banner:** The dashboard checks `allEmpty` at `dashboard_screen.dart:58` for first-run detection. On second thought — I have data, so `allEmpty` is false. But there's no separate check for "data exists but has a gap." The `EmptyDashboardChecklist` from scenario 1 only shows for completely new users.

**Verdict (FAIL — MAJOR):** The dashboard visually shows gaps (zero bars, zero adherence) but provides **zero context** that the cause is absence rather than poor performance. A returning student might feel discouraged seeing "0% adherence" without understanding it's due to a break.

---

## Step 3: Checking My Scheduled Lessons — Stale Lessons Still Listed

I go to the Planner to check if I have any upcoming lessons.

**What I expect:** Lessons I missed during my break are either auto-cancelled, marked as "missed," or at least visually distinguished from upcoming lessons. The planner helps me clean up the past so I can focus on what's ahead.

**What actually happens:**

The `getScheduledLessons()` method (`planner_service.dart:330-343`) filters sessions where `!completed && endTime == null`. **There is no time-based filtering.** A lesson I scheduled for 2 weeks ago (which I never attended) still meets the criteria because:
- `completed` is `false` (I never attended it)
- `endTime` is `null` (no tutor session was started)

So a lesson titled "Atomic Structure" scheduled for May 4 at 16:00 (14 days ago) still appears at the top of my "Scheduled Lessons" list as if it's upcoming. The UI shows the date and time — if I glance at it, I might think it's tomorrow's lesson until I notice the actual date. There is:
- No "Past" or "Missed" label
- No visual dimming or strikethrough
- No auto-cleanup after the scheduled start time passes
- No way to bulk-dismiss old stale lessons

The `cancelLesson()` method (`planner_service.dart:295-307`) exists but requires manual per-lesson action — and there's no UI to cancel from the scheduled lessons list anyway (as found in scenario 2).

**Verdict (FAIL — MAJOR):** Old scheduled lessons from the absence period persist as "upcoming" indefinitely. No filtering, no "missed" label, no auto-cleanup. The returning user sees a cluttered, misleading schedule.

---

## Step 4: Looking at My Daily Plan — Past Cards Look Identical to Future Ones

I scroll through the daily plan cards below the schedule.

**What I expect:** Past days should look different — maybe greyed out, marked as "MISSED," or with a "Catch up" button. I should be able to see at a glance which days I completed and which I missed.

**What actually happens:**

The `DailyPlanCard` (`daily_plan_card.dart:1-119`) renders each plan day identically regardless of whether it's in the past, present, or future. Past days from 2 weeks ago show:
- The same `dayNumber` circle avatar
- The same `day.focus` title
- The same "Priority Topics" list
- The same **"Start Tutoring"** button (which is still tappable — but starting a tutoring session for a day that was 2 weeks ago makes no sense contextually)
- The same **"Schedule Lesson"** button

There is no:
- "Missed" badge or overlay
- Visual difference between past completed and past missed days
- Completed/not-completed indicator
- Greyed-out state for past days

The plan data (`DailyPlan` model) has no `wasCompleted` or `wasAttended` field — the plan is a static schedule, not a tracked checklist. The only way to know if a day was completed is to check adherence records, which are displayed in a completely separate view.

**Verdict (FAIL — MAJOR):** Past plan days are visually indistinguishable from future ones. The returning user sees a wall of identical cards with no way to tell what they've done vs. what they missed.

---

## Step 5: The Adherence Banner — Silent When I Need It Most

I scroll down to see if there's any warning banner about my missed days.

**What I expect:** A prominent banner saying something like "You've missed 14 days of your study plan. Would you like to redistribute the workload or regenerate your plan?"

**What actually happens:**

The `_buildAdherenceBanner()` at `planner_screen.dart:737-796` checks `state.adherenceDeviation?.requiresRegeneration`. The `deviation` comes from `PlanAdapter.checkAdherence()` (`plan_adapter.dart:48-91`), which calls `getConsecutiveLowAdherenceDays()`.

`getConsecutiveLowAdherenceDays()` (`plan_adherence_repository.dart:44-56`) iterates adherence records from most recent to oldest, stopping at the first day with `adherenceScore >= 0.5`. Since my 14-day absence produced **zero adherence records**, the loop finds nothing and returns **0**. The system interprets 0 as "no deviation" — indistinguishable from perfect attendance.

The `AdherenceDeviation` object is `null`. The banner does not render. No redistribute button. No regenerate button. No warning. Total silence.

**Even worse:** `PlanAdapter.getAdherenceReport()` (`plan_adapter.dart:125-152`) returns `averageAdherence: 1.0` (100%) when no records exist — the system literally reports perfect adherence for a 2-week absence. Meanwhile `PlanAdherenceRepository.getAverageAdherence()` returns `0.0` for the same scenario. Two methods return contradictory results.

**Verdict (FAIL — BLOCKER):** The adherence system has zero visibility into activity gaps. A complete absence produces "0 consecutive low adherence days" which triggers no deviation, no banner, no redistribute option, and no regenerate option. The user who most needs plan adjustment help gets none.

---

## Step 6: Asking the Mentor for Help — "How Am I Doing?"

I go to the Mentor tab to ask: "I've been away for 2 weeks. How do I get back on track?"

**What I expect:** The Mentor knows I've been absent, acknowledges it, and gives me specific advice about catching up.

**What actually happens:**

The `_buildContextPrompt()` method (`mentor_service.dart:155-256`) assembles a context string with ~10 data sources. But it does **not** include any "days since last activity" or "gap length" metric. The `_getConsecutiveStudyDays()` method (`mentor_service.dart:351-374`) counts consecutive days backward from today — a 2-week absence means `consecutiveDays == 0`, but the LLM has no way to know whether `0` means "you studied yesterday and took today off" vs. "you last studied 14 days ago."

The context includes:
- `todayMinutes` — how many minutes today (0, because I just opened the app)
- `consecutiveDays` — 0 (no recent sessions)
- Plan adherence data — but the adherence repo reports 0 records, so the plan context isn't helpful
- Mastery data — stale 2-week-old snapshots, presented as current

**The LLM cannot detect the absence.** The context it receives doesn't differentiate between a student who studied yesterday and a student who was away for 2 weeks. The mentor's response will be generic ("You seem to be struggling") rather than specific ("Welcome back! It's been 14 days since your last session.").

The `checkWellbeingAndGenerateNudges()` method (`mentor_service.dart:376-462`) has an inactivity check at lines 433-450: if `consecutiveDays == 0` and the last session was >= 48 hours ago, it sends a `nudgeInactive48h` message. But:
- This only triggers at the 48-hour mark, not the 14-day mark
- It fires independently (not through the chat flow)
- The nudge message doesn't differentiate between "2 days" and "14 days"
- As found in scenario 7, this method is never called during normal mentor session flow

**Verdict (FAIL — MAJOR):** The Mentor's context prompt lacks gap/absence awareness. The LLM cannot know the user has been away. All 14-day absence nudges are the same as 2-day absence nudges.

---

## Step 7: Redistributing Missed Workload — Can I Catch Up?

I try to use the planner's redistribute feature (assuming I can find the banner — which I can't, but let's pretend).

**What I expect:** After 14 missed days, the system should spread the missed workload intelligently across remaining plan days, or suggest extending the plan duration.

**What actually happens (if the banner were shown):**

The `redistributeMissedWorkload()` method (`personal_learning_plan_service.dart:542-570`) takes a `missedMinutes` parameter and spreads it across **only the next 3 future non-rest days**:
```dart
final redistributeDays = 3;
final extraPerDay = (missedMinutes / redistributeDays).ceil();
```

If I missed 14 days × 60 min/day = 840 minutes, each of the next 3 days gets an extra 280 minutes — adding ~4.7 hours per day. This is an **unreasonable workload** that ignores the reality that I couldn't keep up before.

The method does not:
- Extend the plan end date
- Skip past days and adjust future ones
- Consider reducing scope (fewer topics, lower targets)
- Ask the user how they want to catch up

The `regenerateFromAdherence()` path (`PlannerNotifier:441-457`) through `PlanAdapter.suggestRegeneration()` is better — it recalculates targets using the `_calculateAdjustmentFactor` (0.7 default when no records). But since the adherence banner never appears for a clean-absence gap, the user can't even find this option without knowing the secret path.

**What must I do:** There is no "Catch Up" or "Extend Plan" button anywhere. My options are:
1. Delete my plan and create a new one from scratch (losing all progress data)
2. Manually adjust daily targets day by day (no such UI exists)
3. Wait for the adherence banner to appear — which requires at least 3 days back with low adherence, during which time I'm supposed to perform poorly on purpose

**Verdict (FAIL — BLOCKER):** No catch-up mechanism exists for multi-week absences. The redistribute method only covers 3 days of catch-up with unreasonable workload increases. The regenerate path is inaccessible. The user cannot extend their plan duration.

---

## Step 8: Notification Backlog — Did the App Try to Reach Me?

I check my phone's notification shade. I might have missed notifications during my break.

**What I expect:** The `EngagementScheduler` runs daily checks and sends nudges. During my 2-week absence, I should have received revision reminders, plan adjustment suggestions, and inactivity nudges (if notifications are enabled).

**What actually happens:**

The `EngagementScheduler` (`engagement_scheduler.dart`) has a `_dailyTimer` that fires once per day (line 107-108) and runs `_sendNudgeNotifications()`. During my 14-day absence, this daily check **would have fired** each day — but only if the app process was running or scheduled via a platform background service.

**Critical problem — Android/iOS background execution:** The `_dailyTimer` is a plain `Timer.periodic` started when the app initializes (`main.dart:100-112`). This is an **in-process timer**. When the app is killed (swiped away), the timer stops. On Android, no `WorkManager` or `AlarmManager` keeps it alive. On iOS, no `BGTaskScheduler` handles it. **The scheduler only runs while the app is in memory.**

If my phone kept the StudyKing process alive in the background for 14 days (unlikely on modern Android/iOS), the scheduler would have fired daily checks. But since the app process was killed after my last session, **the scheduler never ran during my absence**.

Furthermore, even if the scheduler did run:
- **No accumulation logic:** The scheduler doesn't backfill missed checks when the app restarts. It only runs from the current time forward. If it missed 14 days of checks, those nudges are gone forever.
- **No "catch-up nudge" on return:** There's no code that checks "how long has it been since the last daily check?" and generates summary nudges for the gap period.
- **No platform-level scheduling:** The `flutter_local_notifications` plugin supports scheduled notifications, but the app only uses it for *immediate* notifications, not *future scheduled* ones.

**What I actually see on return:** No accumulated notifications. No "You missed X days" summary. No revision backlog. Just whatever nudge fires on the day I return (overwork check: I've studied 0 minutes, so no overwork nudge; revision check: topics haven't been practiced in 14+ days, so revision nudges might fire if the scheduler runs today; plan adjustment: no consecutive low records, so no nudge).

**Verdict (FAIL — BLOCKER):** The engagement scheduler is entirely in-process. It cannot run while the app is killed. There is no platform-level background scheduling. No missed-nudge accumulation exists. Users on a 2-week break receive zero notifications and zero catch-up nudges on return.

---

## Step 9: Stale In-Progress Sessions — Did My Last Session Get Orphaned?

My last session before the break was a Focus Mode timer. I wonder if it's still "in progress" somewhere.

**What I expect:** The app should auto-timeout or auto-finalize sessions that have been running for too long without activity.

**What actually happens:**

The `Session` model has `completed`, `endTime`, and `actualDuration` fields. If my last Focus Mode session was never properly ended (e.g., the app was killed while the timer was running, or I closed it without ending), the session has:
- `completed: false`
- `endTime: null`
- `actualDuration: Duration.zero`

The `getAll()` method (`session_repository.dart:29-35`) returns **all** sessions including this orphaned one. The `getTodayDurationMs()` method filters by `startTime` on "today" — so yesterday's orphaned session would no longer count in today's stats. But the orphaned record remains in Hive forever.

`SessionHistoryScreen` renders orphaned sessions without any special handling — it shows `actualDuration: Duration.zero` (displayed as "0 min") and `questionsAnswered: 0`. No "in progress" badge, no "stale session" indicator, no cleanup option.

If the orphaned session was an AI tutor session (with `endTime: null`), it would also appear in `getScheduledLessons()` — because that method filters for `endTime == null`. A tutor session from 14 days ago that was never ended would appear as a "scheduled lesson."

**Verdict (FAIL — MAJOR):** Sessions that were never properly ended during the break remain as orphaned records. They appear in scheduled lessons and session history with incorrect metadata, no stale/expired indicator, and no cleanup mechanism.

---

## Step 10: After Getting Back on Track — Does the App Learn from My Break?

I've been back for 3 days. I've been studying consistently. I check the Dashboard again.

**What I expect:** Now that I have 3 days of new data, the adherence system should detect my renewed consistency and adjust accordingly. The gap should be acknowledged but not over-emphasized.

**What actually happens:**

The adherence system now has 3 new records. `getConsecutiveLowAdherenceDays()` checks backwards from today — finds good days. Returns 0. The gap period is still invisible.

The weekly chart gradually pushes the gap weeks further into history as new weeks are added. Eventually (after 8 weeks), the gap weeks scroll off the chart. The gap is silently forgotten.

The plan is still the original 90-day plan with no duration adjustment. Days 1-14 are past and show as identical cards to future days. The plan's end date has not shifted despite 14 missed days. The user is effectively 14 days behind the original schedule with no automated adjustment.

**Verdict (FAIL — MAJOR):** Once the user returns, the gap is silently forgotten. The plan duration remains unchanged. No retrospective adjustment accounts for the missed period. The user falls further behind as the plan progresses.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | App detects 2-week absence and acknowledges it | No last-accessed timestamp stored anywhere. Zero absence detection. | **FAIL (BLOCKER)** |
| 2 | Dashboard weekly chart shows gap with context | Zero-height bars for absent weeks; no annotation or explanation | FAIL (MAJOR) |
| 3 | Plan adherence card shows absence-aware status | "0%" adherence with no indication it's due to absence | FAIL (MAJOR) |
| 4 | Old scheduled lessons from break period are auto-cleaned or marked | Stale lessons persist with no "missed" label, no time-based filtering | FAIL (MAJOR) |
| 5 | Past daily plan cards look different from future ones | All cards identical — no completed/missed visual distinction | FAIL (MAJOR) |
| 6 | Adherence deviation banner detects complete absence | `getConsecutiveLowAdherenceDays()` returns 0 for zero records — no banner shown | **FAIL (BLOCKER)** |
| 7 | Mentor context includes gap/absence awareness | No "days since last session" in LLM context; LLM cannot detect absence | FAIL (MAJOR) |
| 8 | Mentor has differentiated messaging for long vs. short absence | All inactivity triggers at 48h threshold; no 14-day special handling | FAIL (MAJOR) |
| 9 | Workload redistribution handles multi-week absences | Only covers next 3 days; doesn't extend plan; unreasonable per-day increase | **FAIL (BLOCKER)** |
| 10 | Catch-up / extend-plan button exists | No such UI anywhere; must delete and recreate plan | **FAIL (BLOCKER)** |
| 11 | Engagement scheduler runs in background during absence | In-process Timer.periodic — stops when app is killed | **FAIL (BLOCKER)** |
| 12 | Missed nudges accumulate and are shown on return | No accumulation logic; no catch-up nudge summary | **FAIL (BLOCKER)** |
| 13 | Stale/orphaned sessions are auto-finalized or flagged | Orphaned sessions remain with no stale indicator; appear in scheduled lessons | FAIL (MAJOR) |
| 14 | Plan duration adjusts for missed days after return | Original plan unchanged; end date doesn't shift | FAIL (MAJOR) |
| 15 | Consecutive-day streak correctly reflects break | Streak is 0; correct but no explanation of why | PASS (data) |
| 16 | `getAdherenceReport()` and `getAverageAdherence()` return consistent results for empty periods | `getAdherenceReport()` returns 1.0 (perfect); `getAverageAdherence()` returns 0.0 — contradictory | FAIL (MINOR) |
