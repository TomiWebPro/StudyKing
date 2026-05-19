# Dry-Run Result: Attending an AI Tutor Lesson

**Scenario file:** `dry-run-test/scenario_attending_tutor_lesson.md`
**Date:** 2026-05-19
**Overall completion:** 75% (9/12 claim items COMPLETED, 3 PARTIAL)

## Summary

The scenario described 8 steps covering the full flow of attending a scheduled AI tutor lesson. The actual source code has addressed most of the issues raised (9 of 12 specific claims), but 3 issues remain partially or not completed.

Issues that were **fixed** (scenario claims now outdated):
- Join button exists in scheduled lessons section
- Scheduled duration is correctly passed from scheduled lessons entry point
- No character clipping (condition is `> 0`, not `> 2`)
- Exercise question is properly captured and passed to evaluator
- End lesson confirmation dialog exists
- Scheduled lesson status transitions to completed
- Errors are logged (not silently swallowed) in critical paths
- PopScope handles back button with confirmation dialog
- Messages are persisted per-message during the lesson (not batched)
- Voice input supports multiple locales
- Microphone permission is requested from UI

---

## Issue 1: Daily plan card "Start Tutoring" doesn't pass scheduled duration or session ID

**Severity:** MINOR
**Location:** `lib/features/planner/presentation/widgets/daily_plan_card.dart:150-151` → `lib/features/planner/presentation/planner_screen.dart:107-108`

**Description:**
The daily plan card's "Start Tutoring" (`smart_toy_outlined` icon) calls `onStartTutoring(topicId, topicTitle, subjectId)` with only three positional parameters. The handler `_openTutorMode()` defaults `durationMinutes` to 45 and `scheduledSessionId` to null.

This means a user who starts their scheduled lesson from the daily plan card (instead of the "Scheduled Lessons" section) will:
1. Get a 45-minute lesson instead of their scheduled 30 minutes
2. Have no link between the lesson and their scheduled session slot
3. The scheduled lesson slot will NOT be marked as completed after the lesson ends

The scheduled lessons section (`planner_screen.dart:1170-1179`) correctly passes both parameters — the gap is specifically in the daily plan card entry point.

**How to reproduce:**
1. Schedule a 30-minute lesson on "Atomic Structure"
2. On the planner screen, tap the smart_toy icon on the daily plan card's Atomic Structure topic
3. The tutor screen starts with 45-minute duration (instead of 30)
4. After ending the lesson, the scheduled slot remains "planned" (never transitions to completed)

**Suggested fix:**
- Update the `DailyPlanCard` callback signature and/or `_openTutorMode` to accept optional `durationMinutes` and `scheduledSessionId`
- The `DailyPlanCard` needs access to the scheduled session's duration and ID — this may require passing scheduled lesson data into the daily plan model or looking it up in the handler

---

## Issue 2: Summary dialog double-pop

**Severity:** MINOR
**Location:** `lib/features/teaching/presentation/tutor_screen.dart:474-481`

**Description:**
The "Done" button in the lesson summary dialog pops the dialog (`Navigator.of(ctx).pop()`) then pops the tutor screen (`Navigator.of(context).pop()`) after a 200ms delay. This creates a disorienting "double-pop" effect where the user briefly sees a flash of the tutor screen before being returned to wherever they came from.

**How to reproduce:**
1. Start and end a tutor lesson
2. In the summary dialog, tap "Done"
3. Observe the brief flash of the empty tutor screen before it pops

**Suggested fix:**
Replace the two-step pop with a single pop that dismisses both the dialog and the tutor screen. Use `Navigator.of(context).pop()` directly (the dialog context will find the screen's navigator, and since the dialog is shown via `showDialog` which uses `Navigator.of(context)`, `Navigator.of(context).pop()` at the dialog level pops the dialog, not the screen — so the fix needs to ensure the screen is popped after the dialog closes). Options:

1. Pop the tutor screen directly from the dialog action without waiting:
   ```dart
   onPressed: () {
     Navigator.of(context)..pop()..pop();  // pop dialog + screen
   }
   ```
   
2. Use `Navigator.of(context, rootNavigator: true).pop()` to pop the dialog, then immediately pop the screen.

---

## Issue 3: No orphaned `inProgress` session cleanup

**Severity:** MAJOR
**Location:** `lib/features/teaching/services/tutor_service.dart:433-438`

**Description:**
If the app crashes during a tutor lesson, the `TutorSession` is left with `status: SessionStatus.inProgress` and is never cleaned up or recovered. Similarly, if the user chooses "Discard and Exit" in the back-navigation confirmation dialog (`tutor_screen.dart:369-372`), the session is abandoned without updating its status.

There is no startup check that looks for orphaned `inProgress` sessions and either:
- Resumes them (if the user wants to continue)
- Marks them as `cancelled` (if the user wants to discard)

`TutorService.getActiveSession()` exists at line 433 but is never called during app initialization.

**How to reproduce:**
1. Start a tutor lesson
2. Force-kill the app
3. Reopen the app
4. The `TutorSession` remains `inProgress` forever — no recovery offered, no cleanup performed

**Suggested fix:**
Add a startup check in the app initialization flow (or in the `TutorService`/`TutorScreen` route guard) that:
1. Calls `getActiveSession()` to find any `inProgress` sessions
2. If found, shows a dialog asking the user if they want to resume or cancel
3. If cancel, marks the session as `cancelled` and cleans up related data
4. If resume, navigates to `TutorScreen` with the existing session data

---

## Appendix: Code References for Fixed Issues

| Scenario Claim | Code That Fixes It | File:Line |
|---|---|---|
| Join button missing | `IconButton(icon: Icons.play_circle_filled, ...)` | `planner_screen.dart:1162-1182` |
| Duration defaults to 45 | `durationMinutes: lesson.plannedDurationMinutes ?? 45` | `planner_screen.dart:1177` |
| No session link | `scheduledSessionId: lesson.id` | `planner_screen.dart:1178` |
| Character clipping | `if (buffer.length > 0)` (not `> 2`) | `conversation_manager.dart:191` |
| Empty question in eval | `question: _lastExerciseQuestion` | `conversation_manager.dart:275` |
| No confirmation dialog | `_showEndLessonConfirmation()` | `tutor_screen.dart:316-339, 606` |
| Scheduled lesson stays planned | `SessionStatus.completed` update | `tutor_service.dart:215-230` |
| Silent errors | `_logger.e(...)` in all catch blocks | `tutor_service.dart:181, 212, 228, 255` |
| No PopScope | `PopScope(canPop: !_isInitialized, ...)` | `tutor_screen.dart:571-576` |
| Messages lost on crash | `ConversationMemory._persistMessage()` called per-message | `conversation_memory.dart:60, 64-68` |
| Voice hardcoded to en_US | `_localeForSpeech()` supports 8 locales | `voice_service.dart:113-140` |
| Permission not called | `requestPermission()` in initState | `voice_bar.dart:41-43` |
