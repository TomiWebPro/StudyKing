# Dry-Run Issue: Returning After a 2-Week Break

**Source:** `dry-run-test/scenario_returning_after_break.md`
**Date:** 2026-05-20

---

This file documents the gaps found during the code validation of the "Returning After a 2-Week Break" scenario. The scenario had several factual inaccuracies (overstating the problem), but the core user experience is still broken. Below are the concrete issues to fix.

---

## P0 — Critical Bugs

### 1. Sequencing Bug: `updateLastActivity()` Resets Before Absence Check

**File:** `lib/main.dart:200-201`
**Problem:** `StudentIdService().updateLastActivity()` is called during app init, which overwrites the persisted `lastActivityAt` timestamp to "now." All downstream code that calls `getDaysSinceLastActivity()` (checking for absence) sees 0, so absence is never detected on the first launch back.

**Impact:** Steps 1, 5, 6, and 8 are all defeated by this bug.

**Fix options:**
- (a) Read `daysSinceLastActivity` BEFORE calling `updateLastActivity()`, store it, and pass it through the initialization chain.
- (b) Move `updateLastActivity()` out of `main.dart` init and call it only on explicit user interaction (e.g., first tap, first session start).

### 2. Compounding Auto-Redistribution

**File:** `lib/features/planner/services/personal_learning_plan_service.dart:570-578`
**Problem:** `recordDailyAdherence()` calls `redistributeMissedWorkload()` on every day with `adherenceScore < 0.3`. During a multi-day absence, each day's 0-score record triggers redistribution, compounding extra minutes onto the same 3-day window repeatedly.

**Fix:** Only auto-redistribute once per absence period. Check if redistribution was already applied (e.g., compare `lastRedistributionDate` field) before compounding.

---

## P1 — Missing Features

### 3. No Welcome-Back / Absence Banner in Dashboard

**Files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_header.dart`

**Problem:** `StudentIdService.getDaysSinceLastActivity()` exists and returns accurate data (if bug #1 is fixed), but the Dashboard never reads it. L10n strings `welcomeBackDays` and `absenceDetectedTitle` exist but are unused in the dashboard UI.

**Fix:** Add a welcome-back banner to `DashboardScreen` that shows when `daysSinceLastActivity >= 1`. Show stronger messaging for >= 3, >= 7, >= 14 days.

### 4. Adherence Card Shows 0% Without Absence Context

**File:** `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart`
**Problem:** The card displays `formatPercent(0.0)` when no adherence records exist, with no distinction between "absent" and "failed all targets."

**Fix:** Pass `daysSinceLastActivity` or an `isAbsent` flag to `PlanAdherenceCard`. If absent, show "0% — You were away for X days" instead of a plain 0%.

### 5. Mastery Overview Lacks Staleness Warning

**Files:**
- `lib/features/dashboard/data/models/dashboard_models.dart`
- `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart`

**Problem:** `MasterySnapshot` has no `lastUpdated` timestamp. The render shows stale 2-week-old data as if it's current.

**Fix:** Add `lastUpdated` field to `MasterySnapshot`. In `MasteryProgressCard`, show "Last updated X days ago" if stale.

### 6. Extend Plan / Catch-Up Options Not Accessible Without Banner

**Files:**
- `lib/features/planner/presentation/planner_screen.dart`
- `lib/features/planner/providers/planner_providers.dart`

**Problem:** The catch-up sheet (with redistribute/extend/regenerate options) is only shown when the adherence banner renders. But the banner relies on `checkAdherence()` which is defeated by bug #1. Even after fixing #1, a user needs to navigate to the Planner and scroll to see the banner.

**Fix:** Add a "Plan Actions" menu button (e.g., in the app bar) that exposes catch-up options explicitly.

### 7. Multi-Week Redistribution Is Unreasonable

**File:** `lib/features/planner/services/personal_learning_plan_service.dart:643-684`
**Problem:** Default `days:3` strategy for 14-day absence adds 280 min/day extra. No absence-duration awareness.

**Fix:** When `daysSinceLastActivity` is available, use it to compute a reasonable redistribution:
- e.g., `N = daysSinceLastActivity` (spread over as many days as were missed)
- e.g., `dailyExtra = max(15, ceil(missedMinutes / remainingDays * 0.5))` (at most 50% increase per day)

### 8. No Background Notification Scheduling

**File:** `lib/core/services/engagement_scheduler.dart`
**Problem:** Only in-process `Timer.periodic`. When the app is killed, the scheduler stops. No platform-level scheduling (WorkManager, BGTaskScheduler).

**Fix:** Integrate `workmanager` package for Android and `flutter_background_service` or `BGTaskScheduler` for iOS to run daily checks even when the app is killed.

---

## P2 — Enhancements

### 9. No Missed-Nudge Accumulation

**File:** `lib/core/services/engagement_scheduler.dart`
**Problem:** When the scheduler doesn't run (app killed), missed daily checks are not backfilled.

**Fix:** Store `lastSchedulerRun` timestamp in Hive. On init, compare with now and generate summary nudges for the gap.

### 10. No Plan Duration Auto-Extension

**Files:**
- `lib/main.dart:446-481`
- `lib/core/services/plan_adherence_orchestrator.dart`

**Problem:** After detecting absence and returning, the plan's end date never shifts. The user is permanently behind schedule.

**Fix:** In `_handleFirstLaunch()` (or via `PlanAdherenceOrchestrator`), when absence >= 7 days is detected, prompt: "You were away for X days. Do you want to extend your plan by X days?"

### 11. Mentor Context Lacks Missed Lessons & Redistribution Status

**File:** `lib/features/mentor/services/mentor_service.dart:216-259`
**Problem:** The LLM context includes `daysSinceLastActivity` and a welcome-back instruction, but doesn't mention:
- What lessons were missed
- Whether redistribution was applied
- How much extra daily workload is expected

**Fix:** Include `missedLessons.count`, `redistributionStatus`, and `extraMinutesPerDay` in the context prompt.

### 12. No Auto-Finalization of Stale Sessions

**Files:**
- `lib/core/data/models/session_model.dart`
- `lib/core/services/engagement_scheduler.dart` (or new cleanup service)

**Problem:** Sessions with `endTime == null` and `completed == false` remain orphaned forever. Staleness is only computed ephemerally.

**Fix:** Add a daily cleanup routine that auto-finalizes sessions where `startTime < now - 24h && endTime == null && !completed` (set `status: cancelled`, `endTime: startTime + plannedDuration`).

---

## P3 — Data Consistency

### 13. Inconsistent Empty Adherence Reports

**Files:**
- `lib/core/services/plan_adherence_orchestrator.dart:150` (returns `averageAdherence: null`)
- `lib/features/planner/data/repositories/plan_adherence_repository.dart:37-42` (returns `0.0`)

**Problem:** Two methods return different values for the same empty scenario. Downstream code must handle both `null` and `0.0`.

**Fix:** Standardize: both should return `0.0` (or both return `null` with documentation).

---

## Summary of Scenario Inaccuracies Corrected

The original scenario file made several claims that the actual code disproves:

| Claim in Scenario | Actual Code |
|---|---|
| "No last-accessed timestamp stored anywhere" | `StudentIdService` has `lastActivityAt` with full getter/setter/calculate |
| "No time-based filtering for scheduled lessons" | `getScheduledLessons()` has 1-hour filter; `getMissedLessons()` handles older |
| "No 'missed' badge on daily plan cards" | `DailyPlanCard` shows `missedLessonLabel` with error styling |
| "Mentor context lacks absence awareness" | `daysSinceLastActivity` and welcome-back instruction are in the LLM prompt |
| "All inactivity nudges at 48h threshold" | Tiered: 48h, 7d, 14d, 30d+ with differentiated severity |
| "getAdherenceReport() returns 1.0" | Returns `null` for empty periods |
| "No stale session handling" | `SessionHistoryScreen` has `_isStale()` with visual indicator and dismiss button |

The infrastructure for several features exists but is defeated by the sequencing bug (#1) or lacks UI integration. **Fixing #1 alone would resolve 3 of the 5 NOT_COMPLETED steps.**
