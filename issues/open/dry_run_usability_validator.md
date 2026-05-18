# Dry-Run Usability Validator — Issue Log

**Scenario:** Returning After a 2-Week Break — Plan Drift, Stale Sessions, and Re-Engagement
**Scenario file:** `dry-run-test/scenario_returning_after_break.md`
**Date:** 2026-05-18

---

## BLOCKER — App Crash or User Cannot Proceed

### B1. No absence/gap detection mechanism exists in the entire app

**Context:** The app has no concept of "last accessed" or "last activity" timestamp. `StudentIdService` (`lib/core/services/student_id_service.dart:27`) stores only a UUID. No profile model, settings box, or repository tracks when the user last opened the app or had any activity. A 2-week absence is indistinguishable from a 5-minute coffee break.

**Affected files:**
- `lib/core/services/student_id_service.dart:27` — UUID only, no timestamp
- `lib/features/planner/data/repositories/plan_adherence_repository.dart:44-56` — `getConsecutiveLowAdherenceDays()` returns 0 when no records exist
- `lib/core/services/plan_adapter.dart:48-91` — `checkAdherence()` cannot detect a clean-slate gap

**Rationale:** Without a last-activity timestamp, the app cannot determine that the user has been away. All downstream features (adherence detection, planner banner, mentor context, re-engagement nudges) depend on this data and fail silently. The returning user receives zero acknowledgement or help.

**Acceptance criteria (fixed):**
- Add a `lastActivityAt` timestamp to `StudentIdService` (persisted to Hive), updated on every app foreground event and after any completed session.
- Add a `daysSinceLastActivity` helper that computes the gap from today.
- Use this timestamp in `PlanAdapter.checkAdherence()` to return a special `AbsenceDeviation` (extending `AdherenceDeviation`) when `daysSinceLastActivity >= 3`.

### B2. Adherence deviation banner never shows for clean-slate gaps

**Context:** `PlanAdapter.checkAdherence()` (`lib/core/services/plan_adapter.dart:48-91`) calls `getConsecutiveLowAdherenceDays()` which returns 0 when no adherence records exist. With `consecutiveLowDays == 0`, `requiresRegeneration` is `false`, and no `AdherenceDeviation` object is returned. The planner screen at `planner_screen.dart:737-796` checks `state.adherenceDeviation != null` — it's null, so no banner renders. A 14-day absence with zero records produces zero deviation.

**Affected files:**
- `lib/features/planner/data/repositories/plan_adherence_repository.dart:44-56` — loop has no "no records" fallback
- `lib/core/services/plan_adapter.dart:48-91` — `checkAdherence()` does not check for zero-record scenarios
- `lib/features/planner/presentation/planner_screen.dart:737-796` — banner only renders for non-null deviation

**Rationale:** The user who most needs to see the adherence banner (returning from long absence with an outdated plan) is the one user who will never see it. The system treats "no data" as "no problem."

**Acceptance criteria (fixed):**
- After fixing B1, modify `checkAdherence()` to return an `AbsenceDeviation` when `daysSinceLastActivity >= 3` with `requiresRegeneration: true`.
- Add a new localized string for the absence banner: "You've been away for {days} days. Your study plan may need adjustment."
- Ensure the planner banner renders for `AbsenceDeviation` with the same redistribute/regenerate buttons.

### B3. No catch-up mechanism for multi-week absences

**Context:** `redistributeMissedWorkload()` (`lib/core/services/personal_learning_plan_service.dart:542-570`) only spreads missed minutes across the next 3 days. For a 14-day absence at 60 min/day, each of the next 3 days gets +280 min (4.7 hours extra per day) — an unreasonable workload. The method does not extend the plan end date, reduce scope, or offer the user a choice of catch-up strategy. There is no "Extend Plan" or "Catch Up" button anywhere in the UI. The regenerate path (`PlannerNotifier.regenerateFromAdherence()` at `planner_providers.dart:441-457`) is gated behind the invisible adherence banner.

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart:542-570` — 3-day redistribution only
- `lib/features/planner/providers/planner_providers.dart:441-457` — regenerate path inaccessible without banner
- `lib/features/planner/presentation/planner_screen.dart` — no "Extend Plan" or "Catch Up" button in the UI

**Rationale:** A student returning from a 2-week absence has no supported path to adjust their plan duration. The only redistribution mechanism unreasonably increases daily workload. Without ability to extend the schedule, the student either falls further behind or must delete and recreate their plan (losing continuity).

**Acceptance criteria (fixed):**
- Add an `extendPlan(days)` method to `PersonalLearningPlanService` that shifts all remaining plan days by `days`, moving the end date later.
- Add a "Catch Up" bottom sheet (accessible from planner screen or the new absence banner) with options: "Redistribute missed workload" (spread across remaining days), "Extend plan duration" (shift end date), "Regenerate plan" (create new plan from current data).
- Modify `redistributeMissedWorkload()` to accept a strategy parameter: `{days: 3, 7, all}` instead of hardcoding 3.

### B4. Engagement scheduler is entirely in-process — no background execution

**Context:** `EngagementScheduler` (`lib/core/services/engagement_scheduler.dart:107-108`) uses `Timer.periodic` for daily checks. This timer stops when the app process is killed. There is no `WorkManager`, `AlarmManager`, or `BGTaskScheduler` integration for platform-level background scheduling. Additionally, there is no missed-nudge accumulation — if the scheduler misses 14 daily checks, those nudges are lost forever with no catch-up on app restart.

**Affected files:**
- `lib/core/services/engagement_scheduler.dart:107-108` — `Timer.periodic`, no platform background scheduling
- `lib/main.dart:100-112` — scheduler created before `runApp()`, no background task registration
- `pubspec.yaml` — check for `workmanager` or `flutter_background_service` dependency (likely absent)

**Rationale:** Users who do not keep the app in memory receive zero engagement nudges during their absence. On return, no catch-up or summary nudge is generated. The entire proactive engagement system is non-functional for absent users.

**Acceptance criteria (fixed):**
- Integrate `workmanager` (Android) and `BGTaskScheduler` (iOS) for daily background checks.
- On app start, compare `lastActivityAt` (from B1) with current time. If gap > 48 hours, generate a single "Welcome back" summary nudge with key stats from the gap period.
- Store the last scheduler run timestamp; on a gap, skip missed checks (don't try to backfill all 14).

### B5. No mechanism to clear stale "scheduled" lessons from absence period

**Context:** `getScheduledLessons()` (`lib/features/planner/services/planner_service.dart:330-343`) filters sessions by `!completed && endTime == null`. A lesson scheduled 14 days ago that was never attended still appears as "upcoming" because it has no `endTime`. There is no time-based filter (e.g., `startTime.isAfter(DateTime.now().subtract(1.hour))`), no auto-expiry, no "missed" label, and no batch-dismiss UI.

**Affected files:**
- `lib/features/planner/services/planner_service.dart:330-343` — no time-based filtering on `getScheduledLessons()`
- `lib/features/planner/presentation/planner_screen.dart:798-897` — scheduled lessons section, no "missed" indicator

**Rationale:** Returning users see old, irrelevant scheduled lessons alongside upcoming ones. This clutters the UI and creates confusion ("Did I miss this lesson or is it still upcoming?").

**Acceptance criteria (fixed):**
- Add time-based filtering to `getScheduledLessons()`: exclude sessions where `startTime` is more than 1 hour in the past.
- Add a `getMissedLessons()` method that returns past sessions with `endTime == null`.
- In the planner screen, add a collapsed "Missed Lessons ({count})" section below scheduled lessons.
- Add a "Dismiss All Missed" button that batch-sets `completed = true` for all missed lessons.

---

## MAJOR — Feature Is Broken or Misleading

### M1. Dashboard shows zeros for absent weeks with no explanation

**Context:** `getWeeklyTrend()` (`lib/core/services/study_progress_tracker.dart:128-157`) iterates 8 weeks and produces entries for every week, including absent weeks where attempts = 0 and accuracy = 0.0. The `WeeklyChart` renders these as zero-height bars. There is no annotation, tooltip, or label explaining that the zero values are due to absence rather than poor performance.

**Affected files:**
- `lib/core/services/study_progress_tracker.dart:128-157` — produces zero entries for absent weeks
- `lib/features/dashboard/presentation/widgets/weekly_chart.dart` — no gap/absence annotation in chart rendering
- `lib/features/dashboard/providers/dashboard_data_providers.dart:46-53` — passes weekly trend data unchanged

**Rationale:** A user looking at their dashboard after returning sees a discouraging flatline of zeros. The chart is factually correct but psychologically misleading — it communicates failure rather than "you were on break."

**Acceptance criteria (fixed):**
- When a week has zero attempts AND the user has existing data before that week, mark the week as an "absence gap" in the trend data.
- In `WeeklyChart`, render gap weeks with a distinct visual style (e.g., dashed outline, lighter fill, or a "no data" label instead of a zero-height bar).
- Add a tooltip on hover/tap: "No activity — you were away this week."

### M2. Past daily plan cards are visually identical to future cards

**Context:** `DailyPlanCard` (`lib/features/planner/presentation/widgets/daily_plan_card.dart:1-119`) renders every plan day identically regardless of whether it's in the past, present, or future. Past days show "Start Tutoring" buttons and priority topics as if the day is still active. There is no `isPast` check, no `completed` state, and no visual distinction.

**Affected files:**
- `lib/features/planner/presentation/widgets/daily_plan_card.dart` — no past/future awareness in rendering
- `lib/features/planner/models/daily_plan.dart` — no `wasCompleted` or `wasAttended` field on the model

**Rationale:** Returning users cannot visually distinguish between days they completed, days they missed, and upcoming days. The plan appears as a flat wall of identical cards. Starting a tutoring session on a day 2 weeks in the past is contextually nonsensical.

**Acceptance criteria (fixed):**
- Add an `isCompleted` field to `DailyPlan` model, populated from adherence records.
- In `DailyPlanCard`, check if the day is in the past. If so:
  - If completed: show a green checkmark overlay, disable action buttons, reduce opacity slightly.
  - If missed (not completed): show a red "MISSED" badge, disable action buttons, add "Catch Up" button that navigates to a catch-up flow.
- If the day is today: add a subtle "Today" indicator (pill badge or accent border).

### M3. Mentor LLM context has no "days since last session" metric

**Context:** `_buildContextPrompt()` (`lib/features/mentor/services/mentor_service.dart:155-256`) assembles a rich context string but does not include `daysSinceLastSession` or any gap-length metric. The `_getConsecutiveStudyDays()` method (`mentor_service.dart:351-374`) returns only the current streak (which is 0 after a break), not the gap length. The LLM cannot differentiate between "studied yesterday and took today off" vs. "last studied 14 days ago."

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:155-256` — context lacks gap metrics
- `lib/features/mentor/services/mentor_service.dart:351-374` — `_getConsecutiveStudyDays()` only counts streak, not gap

**Rationale:** The mentor is the most natural place for a returning user to ask for help ("I've been away, what do I do?"), but the LLM has no data to form a context-aware response. The conversation is generic.

**Acceptance criteria (fixed):**
- After fixing B1, add `daysSinceLastActivity` to the LLM context string: "The student has not been active for {daysSinceLastActivity} days."
- If `daysSinceLastActivity >= 3`, prepend a system instruction: "The student is returning after a {daysSinceLastActivity}-day absence. Provide a warm welcome-back and suggest specific catch-up steps."

### M4. CheckWellbeingAndGenerateNudges() has no differentiated messaging for long absences

**Context:** `checkWellbeingAndGenerateNudges()` (`lib/features/mentor/services/mentor_service.dart:376-462`) has a single inactivity check at lines 433-450: if `consecutiveDays == 0` and the last session was >= 48 hours ago, it generates a `nudgeInactive48h`. There is no differentiated threshold for 7+, 14+, or 30+ day absences. All absences longer than 48 hours get the same "you've been inactive" message.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:433-450` — single 48h threshold, no graduated messaging

**Rationale:** "You haven't studied in 48 hours" is an appropriate nudge for a weekend gap but feels tone-deaf after a 2-week absence. The user needs a different message that acknowledges the longer gap and helps them plan re-engagement.

**Acceptance criteria (fixed):**
- Add graduated thresholds: 48h (>2 days), 7+ days, 14+ days, 30+ days.
- Generate distinct nudge messages per threshold: "It's been {days} days. Let's ease back in..." (7+), "Welcome back! It's been {days} days..." (14+).
- Add localized strings for each threshold in ARB files.

### M5. Stale in-progress sessions orphaned after absence

**Context:** Sessions that were not properly ended (e.g., app killed during Focus Mode or Tutor lesson) have `endTime: null` and `completed: false`. These appear in `getScheduledLessons()` (because `endTime == null` filter) and in `SessionHistoryScreen` with `Duration.zero` and 0 questions. No stale/expired indicator exists.

**Affected files:**
- `lib/features/sessions/presentation/session_history_screen.dart:513-611` — no "in progress" or "stale" badge for sessions with `endTime == null`
- `lib/features/planner/services/planner_service.dart:330-343` — orphaned sessions appear in scheduled lessons
- `lib/features/sessions/data/repositories/session_repository.dart` — no `getStaleOrphaned()` query

**Rationale:** Returning users may see confusing sessions from before their break with zero duration and no context. A tutor session that was never ended looks like an upcoming lesson.

**Acceptance criteria (fixed):**
- In `SessionHistoryScreen`, sessions with `endTime == null` and `startTime` > 1 hour ago should show a "Stale" badge with an explanation tooltip.
- Add a "Dismiss Stale Session" action (sets `completed = true`, `endTime = startTime`, `actualDuration = Duration.zero`).
- Filter out stale sessions (no `endTime` and > 1 hour past) from `getScheduledLessons()`.

---

### M6. Plan duration does not adjust for missed days after user returns

**Context:** After the user returns and begins studying again, the original plan end date remains unchanged. Days 1-14 of the plan are past days that now sit as "missed" (though the app doesn't mark them as such — see M2). The remaining plan days are unchanged. The user is effectively 14 days behind the schedule with no automated adjustment.

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart` — no `shiftPlanDates()` or `extendPlan()` method
- `lib/features/planner/presentation/planner_screen.dart` — no "Extend Plan" or "Re-schedule Remaining" action

**Rationale:** Without duration extension, a returning student's plan becomes increasingly unrealistic. They fall further behind each day as the fixed end date approaches.

**Acceptance criteria (fixed):**
- Same as B3 acceptance criteria.
- Additionally, on first return after absence (detected via B1's `lastActivityAt`), if `daysSinceLastActivity >= 3`, auto-show a dialog: "You were away for {days} days. Would you like to extend your study plan by {days} days?"

### M7. `getAdherenceReport()` returns perfect adherence (1.0) for zero-record periods

**Context:** `PlanAdapter.getAdherenceReport()` (`lib/core/services/plan_adapter.dart:125-152`) returns `averageAdherence: 1.0` when no records exist. Meanwhile `PlanAdherenceRepository.getAverageAdherence()` (`plan_adherence_repository.dart:37-42`) returns `0.0` for the same scenario. Two methods used by different parts of the app return contradictory results for the same data state.

**Affected files:**
- `lib/core/services/plan_adapter.dart:125-152` — returns 1.0 for empty data
- `lib/features/planner/data/repositories/plan_adherence_repository.dart:37-42` — returns 0.0 for empty data

**Rationale:** Depending on which component reads adherence data, the app may report perfect adherence (1.0) or zero adherence (0.0) for the same 14-day absence. This inconsistency could cause conflicting behavior in different parts of the app.

**Acceptance criteria (fixed):**
- Make both methods return `null` or a sentinel value (like `-1`) for "no data" instead of returning meaningful values.
- Update all callers to handle `null` by displaying "No data / Not enough data" instead of treating it as a numeric value.

---

## MINOR — UX Friction

### m1. No "Welcome back" or "re-engagement" localized strings in ARB files

**Context:** Searching `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` for "welcome back," "returning," "away," "break" (absence sense), "holiday," or "vacation" returns zero results. The only re-engagement string is `recommendNoActivity` which is a code-level fallback in `StudyProgressTracker`, not a localized ARB string.

**Affected files:**
- `lib/l10n/app_en.arb` — no re-engagement strings
- `lib/l10n/app_es.arb` — no re-engagement strings

**Acceptance criteria (fixed):**
- Add the following localized strings (English shown; add all locales):
  - `welcomeBackDays`: "Welcome back! You've been away for {days} days."
  - `absenceDetectedTitle`: "Absence Detected"
  - `absenceDetectedBody`: "You haven't used StudyKing in {days} days. How would you like to proceed?"
  - `extendPlan`: "Extend study plan by {days} days"
  - `missedLessonLabel`: "Missed"
  - `staleSessionLabel`: "Not completed"

### m2. Weekly chart zero bars could be misinterpreted

**Context:** The `WeeklyChart` at `lib/features/dashboard/presentation/widgets/weekly_chart.dart` renders bars whose height corresponds to question count. A 0-question week renders as an invisible/flat bar. On a small screen, multiple consecutive flat bars could look like a chart rendering glitch.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/weekly_chart.dart` — zero-height bars are invisible, not distinguishable from "no data"

**Acceptance criteria (fixed):**
- When a week has 0 questions and the user has existing data, render a subtle dashed outline bar at minimum height (2-4px) with a different color (e.g., grey instead of primary).
- Add a label "No activity" or a tooltip on empty bars.

### m3. Consecutive study days computation only considers completed sessions

**Context:** `_getConsecutiveStudyDays()` (`mentor_service.dart:351-374`) only counts sessions where `session.completed == true`. Sessions that were orphaned (see M5) are not counted. This means a user who used the app but had sessions improperly ended will show a shorter streak than reality.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:351-374`

**Acceptance criteria (fixed):**
- Count sessions with any `actualDurationMs > 0` as a study day, regardless of `completed` flag.
- Or add a fallback: if a session has `startTime` on a given date but no `endTime`, count it as a study day with a "partial" qualifier.

### m4. No loading/transition state when returning app processes stale data

**Context:** After a long absence, the app loads all Hive data synchronously on init. There is no intermediate loading state that says "Loading your data...", "Checking for updates...", or "Welcome back! Restoring your session..." The first frame shows whatever data was cached.

**Affected files:**
- `lib/main.dart:127-131` — `runApp(StudyKingApp())` starts immediately
- `lib/features/dashboard/presentation/dashboard_screen.dart` — no "restoring state" overlay

**Acceptance criteria (fixed):**
- After fixing B1, if `daysSinceLastActivity >= 1`, show a brief (1-2 second) "Welcome back" splash overlay while data loads.
- This overlay could show: days since last visit, total progress summary, and a "Continue where you left off" button.

---

## Cross-References to Related Issues

| Finding | Related Issue |
|---|---|
| B1 (no last-activity timestamp) | Related to `scenario_first_launch_ib_chemistry` finding about no profile prompt |
| B4 (in-process scheduler) | Related to scenario 9's `EngagementScheduler` findings |
| B5 (stale scheduled lessons) | Cross-refs `scenario_existing_user_pace_subjects_provider` B1 (no cancel lesson UI) |
| M1 (dashboard zeros) | Related to `ui_ux_master.md` M1 (dashboard skeleton/loading) |
| M3 (mentor LLM context) | Cross-refs `scenario_mentor_study_companion` findings about missing context |
