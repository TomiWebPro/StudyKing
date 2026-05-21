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
| 16 | `getAdherenceReport()` and `getAverageAdherence()` return consistent results for empty periods | `getAdherenceReport()` returns `null` (not 1.0); `getAverageAdherence()` returns 0.0 — still contradictory | FAIL (MINOR) |

---

## Code Validation Results

*Validated against actual source code at commit HEAD. Each step assessed on whether the user's expectation is met by the current codebase.*

### Step 1: First Launch After 14 Days — Absence Detection

**Status: NOT_COMPLETED**

| Aspect | Finding | Code Reference |
|---|---|---|
| `StudentIdService` stores `lastActivityAt` | ✅ EXISTS — `_lastActivityKey = 'lastActivityAt'`, `getLastActivityAt()`, `updateLastActivity()`, `getDaysSinceLastActivity()` all present | `lib/core/services/student_id_service.dart:10,43-63` |
| `PlanAdherenceOrchestrator.checkAdherence()` checks absence >=3 days | ✅ EXISTS — returns `AbsenceDeviation` with `requiresRegeneration: true` | `lib/core/services/plan_adherence_orchestrator.dart:63-74` |
| Sequencing bug: `updateLastActivity()` called BEFORE check | ❌ CRITICAL BUG — `main.dart:200-201` calls `updateLastActivity()` during init, which resets the timestamp to "now". By the time `checkAdherence()` runs (later via `PlannerNotifier.loadAdditionalData()`), `daysSinceLastActivity` is 0 | `lib/main.dart:200-201`, `lib/features/planner/providers/planner_providers.dart:222` |
| User-facing welcome-back UI | ❌ MISSING — no splash screen, no welcome-back dialog, no absence banner on dashboard. l10n strings `welcomeBackDays` and `absenceDetectedTitle` exist but are unused in UI | `lib/features/dashboard/presentation/dashboard_screen.dart`, `lib/l10n/generated/app_localizations_en.dart` |

**What is still missing:**
1. Fix sequencing bug: read `daysSinceLastActivity` BEFORE calling `updateLastActivity()`, or remove the auto-update on init and only update on explicit user interaction.
2. Add welcome-back banner/dialog to Dashboard that uses `StudentIdService.getDaysSinceLastActivity()`.

---

### Step 2: Dashboard — Gap Context

**Status: PARTIAL**

| Aspect | Finding | Code Reference |
|---|---|---|
| Weekly chart gap annotation | ✅ WORKS — `getWeeklyTrend()` sets `isGap = true` for weeks with no attempts + prior data. `AnimatedBarChart` renders gap weeks as small outlined boxes with dashed border. Legend shows "No activity — you were away this week." | `lib/core/services/study_progress_tracker.dart:136,163`, `lib/core/widgets/animated_bar_chart.dart:57-95` |
| Adherence card with 0% no explanation | ❌ MISSING — `PlanAdherenceCard` shows `formatPercent(0.0)` with no "absent" vs "failed all targets" distinction | `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` |
| Mastery overview stale data warning | ❌ MISSING — `MasterySnapshot` has no timestamp. `MasteryProgressCard` renders data with no "last updated X days ago" indication | `lib/features/dashboard/data/models/dashboard_models.dart:1`, `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` |
| Dashboard absence banner | ❌ MISSING — `DashboardHeader` and `DashboardScreen` have no absence/welcome-back widget. `EmptyDashboardChecklist` only shows for new users | `lib/features/dashboard/presentation/widgets/dashboard_header.dart`, `lib/features/dashboard/presentation/dashboard_screen.dart:95` |

**What is still missing:**
1. `PlanAdherenceCard` should accept a `daysSinceLastActivity` parameter and show absence context when > 0 (e.g., "0% — you were away for 14 days").
2. `MasteryProgressCard` should show "Last updated X days ago" if the snapshot data is stale.
3. `DashboardScreen` should read `StudentIdService.getDaysSinceLastActivity()` and show a welcome-back/absence banner at the top.

---

### Step 3: Scheduled Lessons — Stale Lessons

**Status: COMPLETED** ✗ *Scenario claim was: "no time-based filtering", "stale lessons persist indefinitely"*

| Aspect | Finding | Code Reference |
|---|---|---|
| `getScheduledLessons()` has time filter | ✅ EXISTS — filters `!s.startTime.isBefore(now - 1 hour)` | `lib/features/planner/services/planner_service.dart:372-376` |
| `getMissedLessons()` for older lessons | ✅ EXISTS — inverse filter: `startTime.isBefore(now - 1 hour)` | `lib/features/planner/services/planner_service.dart:385-401` |
| Missed lessons section in planner | ✅ EXISTS — strikethrough, error icon, "missed" label, dismiss button | `lib/features/planner/presentation/planner_screen.dart:1082-1143` |
| `dismissAllMissed()` bulk action | ✅ EXISTS — marks all missed sessions as `completed: true` | `lib/features/planner/services/planner_service.dart:404-415` |

**Minor caveat:** 1-hour threshold means lessons 30-min past still appear as "upcoming." This is a UX polish issue, not a functional gap.

---

### Step 4: Daily Plan Cards — Past vs Future Visual Distinction

**Status: COMPLETED** ✗ *Scenario claim was: "past cards look identical to future ones", "no missed badge"*

| Aspect | Finding | Code Reference |
|---|---|---|
| Past completed: opacity 0.6, check icon, strikethrough | ✅ EXISTS | `lib/features/planner/presentation/widgets/daily_plan_card.dart:41,56-62,68-70` |
| Past missed: error badge ("missed") | ✅ EXISTS | `daily_plan_card.dart:85-96` |
| Catch Up button for past incomplete | ✅ EXISTS | `daily_plan_card.dart:156-162` |
| Schedule/Start buttons hidden for past | ✅ EXISTS (`!isPast` guard) | `daily_plan_card.dart:127` |
| `isCompleted` dynamically annotated from adherence records | ✅ EXISTS | `lib/features/planner/providers/planner_providers.dart:238-244` |

**Minor caveat:** `isCompleted` is not persisted to Hive (no `@HiveField` annotation). It's computed in-memory on every load. This is acceptable for current architecture but could be fragile if plans are exported/imported.

---

### Step 5: Adherence Banner — Absence Detection

**Status: NOT_COMPLETED**

| Aspect | Finding | Code Reference |
|---|---|---|
| `PlanAdherenceOrchestrator.checkAdherence()` checks absence >=3d | ✅ EXISTS — returns `AbsenceDeviation` | `lib/core/services/plan_adherence_orchestrator.dart:63-74` |
| `_buildAdherenceBanner()` handles `AbsenceDeviation` with catch-up button | ✅ EXISTS | `lib/features/planner/presentation/planner_screen.dart:949-1017` |
| Sequencing bug defeats detection | ❌ CRITICAL BUG — `updateLastActivity()` at `main.dart:201` resets timestamp before the Planner checks | `lib/main.dart:200-201` |
| `getConsecutiveLowAdherenceDays()` returns 0 for empty records | ✅ CONFIRMED — no records → 0 | `lib/features/planner/data/repositories/plan_adherence_repository.dart:44-56` |
| `getAdherenceReport()` returns null (not 1.0 as scenario claimed) | ✅ EXISTS — returns `averageAdherence: null`, not `1.0` | `lib/core/services/plan_adherence_orchestrator.dart:150-155` |
| `getAverageAdherence()` returns 0.0 for empty | ✅ CONFIRMED — inconsistency with `null` above remains | `lib/features/planner/data/repositories/plan_adherence_repository.dart:37-42` |

**What is still missing:**
1. Fix the sequencing bug: restructure `main.dart` to check last activity BEFORE updating it, or move `updateLastActivity()` out of init.
2. Align `getAdherenceReport()` and `getAverageAdherence()` to return consistent values for empty periods.

---

### Step 6: Mentor Context — Absence Awareness

**Status: PARTIAL**

| Aspect | Finding | Code Reference |
|---|---|---|
| `daysSinceLastActivity` in LLM context | ✅ EXISTS — included at line 254 | `lib/features/mentor/services/mentor_service.dart:228,254-258` |
| Explicit "welcome back" instruction for >=3 days | ✅ EXISTS — line 257 | `mentor_service.dart:256-258` |
| Tiered inactivity nudges (48h, 7d, 14d, 30d+) | ✅ EXISTS — differentiated severity and messages | `mentor_service.dart:585-601` |
| Sequencing bug may cause 0 on first launch | ❌ AFFECTED — same `updateLastActivity()` bug | `lib/main.dart:200-201` |
| Missed lessons not in context | ❌ MISSING — only loads `upcomingLessons`, not `missedLessons` | `mentor_service.dart:223` |
| Redistribution status not in context | ❌ MISSING — no info about what adjustments were made | `mentor_service.dart:216-259` |

**What is still missing:**
1. Add `missedLessons` to mentor context so the LLM knows what was missed.
2. Include redistribution/catch-up status (e.g., "workload redistributed over next N days with +M min/day").
3. Fix sequencing bug so `daysSinceLastActivity` is accurate on first launch.

---

### Step 7: Workload Redistribution — Multi-Week Absence

**Status: NOT_COMPLETED**

| Aspect | Finding | Code Reference |
|---|---|---|
| Default `days:3` redistribution | ❌ UNREASONABLE for 14-day absence — 14×60=840min → 280min/day extra | `lib/features/planner/services/personal_learning_plan_service.dart:643-684` |
| `redistribute:all` strategy across all remaining days | ✅ EXISTS | `personal_learning_plan_service.dart:646-648` |
| `extend` strategy (add content-less days) | ✅ EXISTS | `personal_learning_plan_service.dart:686-721` |
| `regenerate` strategy (new plan from scratch) | ✅ EXISTS | `lib/core/services/plan_adherence_orchestrator.dart:116-143` |
| Catch-up sheet with all 3 strategies | ✅ EXISTS but gated behind adherence banner | `lib/features/planner/presentation/planner_screen.dart:1019-1079` |
| Auto-redistribution compounds without dedup | ❌ BUG — `recordDailyAdherence()` calls `redistributeMissedWorkload()` on every low day, compounding on the same 3-day window | `personal_learning_plan_service.dart:570-578` |
| No dedicated extended-absence handler | ❌ MISSING — no "return-from-14-day-break" flow | nowhere |
| No gradual catch-up ramp | ❌ MISSING — flat `extraPerDay = ceil(missedMinutes / N)` | `personal_learning_plan_service.dart:651` |

**What is still missing:**
1. Add absence-duration-aware redistribution: use `daysSinceLastActivity` to pick appropriate `N` days.
2. Fix compounding bug: deduplicate auto-redistribution calls or only trigger once per absence period.
3. Add gradual catch-up (e.g., 50% extra day 1, 75% day 2, 100% day 3+).
4. Make the catch-up sheet accessible even when the adherence banner doesn't show (e.g., via a "Plan" menu action).

---

### Step 8: Engagement Scheduler — Background Execution

**Status: NOT_COMPLETED**

| Aspect | Finding | Code Reference |
|---|---|---|
| In-process `Timer.periodic` only | ❌ CONFIRMED — no WorkManager/AndroidAlarmManager/BGTaskScheduler | `lib/core/services/engagement_scheduler.dart:54-55,106,113` |
| Platform-level scheduled notifications | ❌ MISSING — `flutter_local_notifications` only used for immediate, not future-scheduled | `lib/core/services/notification_service.dart:190` |
| Missed-nudge accumulation | ❌ MISSING — no backfill or catch-up logic | `engagement_scheduler.dart` (entire file) |
| Catch-up nudge on return | ❌ MISSING — no code that checks "how long since last daily check" | `engagement_scheduler.dart` (entire file) |
| `_planOrchestrator.checkAdherence()` called in scheduler | ✅ EXISTS — but also affected by sequencing bug | `engagement_scheduler.dart:299` |

**What is still missing:**
1. Implement platform-level background scheduling (WorkManager on Android, BGTaskScheduler on iOS).
2. Add missed-nudge backfill logic that checks "last scheduler run" timestamp on init and generates summary nudges.
3. Add a "catch-up nudge" that tells returning users what they missed.

---

### Step 9: Stale/Orphaned Sessions

**Status: PARTIAL**

| Aspect | Finding | Code Reference |
|---|---|---|
| `Session` model has no persistent stale field | ❌ CONFIRMED — no `isStale`, `expiredAt`, `orphanedSince` | `lib/core/data/models/session_model.dart:93-138` |
| `getStaleOrphaned()` in repository | ✅ EXISTS — runtime query for `endTime==null && !completed && startTime < now-1h` | `lib/features/sessions/data/repositories/session_repository.dart:206-217` |
| `_isStale()` in session history screen | ✅ EXISTS — same runtime heuristic | `lib/features/sessions/presentation/session_history_screen.dart:498-502` |
| Stale session visual indicator (error icon + badge) | ✅ EXISTS — icon background, error icon, "stale" label, dismiss button | `session_history_screen.dart:540,562-590,618-623` |
| Orphaned tutor session dialog on launch | ✅ EXISTS — `_checkOrphanedSessions()` in `main.dart` shows dialog | `lib/main.dart:483-524` |
| No auto-finalization/auto-timeout | ❌ MISSING — no mechanism to auto-close stale sessions | nowhere |
| Orphaned sessions in `getScheduledLessons()` | ✅ MITIGATED — 1-hour filter moves them to "missed" section | `lib/features/planner/services/planner_service.dart:376` |

**What is still missing:**
1. Add auto-finalization for sessions exceeding a staleness threshold (e.g., 24h without endTime → auto-close with `status: cancelled`).
2. Consider adding a persistent `isStale` field to avoid recomputation.

---

### Step 10: Post-Return — Gap Adjustment

**Status: NOT_COMPLETED**

| Aspect | Finding | Code Reference |
|---|---|---|
| Plan duration unchanged after return | ❌ CONFIRMED — `planDurationDays` never auto-adjusted | `lib/core/services/plan_adherence_orchestrator.dart`, `lib/features/planner/services/personal_learning_plan_service.dart` |
| No automatic gap adjustment | ❌ CONFIRMED — no code extends plan after detected absence | `lib/main.dart:446-481` (`_handleFirstLaunch` has no plan adjustment logic) |
| `extendPlan()` exists but needs manual action | ✅ EXISTS | `personal_learning_plan_service.dart:686-721` |
| `catchUpWithStrategy()` exists | ✅ EXISTS | `lib/features/planner/providers/planner_providers.dart:638-658` |
| Gap weeks scroll off chart after 8 weeks | ✅ CONFIRMED — eventually forgotten | `lib/core/services/study_progress_tracker.dart:128-157` |

**What is still missing:**
1. Add automatic plan duration extension on return after extended absence (e.g., after detecting 7+ day gap, prompt user to extend plan by X days).
2. Add a "Plan Adjustments" tab or panel showing past gaps and their impact.
3. Consider a "catch-up mode" that temporarily increases targets with a clear end date.

---

## Summary

| Step | Result | Key Gap |
|---|---|---|
| 1. Absence detection / welcome-back | NOT_COMPLETED | Sequencing bug + no welcome-back UI |
| 2. Dashboard gap context | PARTIAL | Chart ok; adherence card, mastery warning, banner missing |
| 3. Stale lessons filtering | COMPLETED | Lessons handled correctly — 1h filter, missed section, dismiss |
| 4. Past vs future plan cards | COMPLETED | Missed badge, catch-up button, visual distinction all present |
| 5. Adherence banner for absence | NOT_COMPLETED | Infrastructure exists but sequencing bug defeats it |
| 6. Mentor absence awareness | PARTIAL | Context includes daysSinceLastActivity; shallow (no missed lessons, no redistribution status) |
| 7. Multi-week redistribution | NOT_COMPLETED | Default 3-day only, no absence-aware strategy, compounds |
| 8. Background scheduling | NOT_COMPLETED | In-process timer only; no platform-level scheduling |
| 9. Stale/orphaned sessions | PARTIAL | UI detection exists; no auto-finalization, no persistent field |
| 10. Post-return gap adjustment | NOT_COMPLETED | No auto-extension, gap silently forgotten |

**Overall: 2 COMPLETED, 3 PARTIAL, 5 NOT_COMPLETED — well below 80% threshold. Scenario file retained. Issue file created.**
