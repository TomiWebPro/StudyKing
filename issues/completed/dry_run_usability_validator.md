# Issue: Focus Mode & Study Hub — Dry-Run Usability Validation

**Scenario**: `dry-run-test/scenario_focus_mode_study_hub.md`
**Validated**: 2026-05-20
**Previous scenario**: `dry-run-test/scenario_focus_mode_daily_habit.md` (deleted — >80% resolved, moved to `issues/completed/`)
**Status**: NEW findings — issue remains open

---

## BLOCKER (user cannot achieve core goal)

### B1 — Session type selector in timer setup has no effect on the user experience

The timer setup form (`focus_timer_screen.dart:1198`) offers 4 session types: Quick Practice, Spaced Repetition, Weak Area Attack, Free Focus. But the only code path that reads `_sessionType` is:

```dart
// focus_timer_screen.dart:373-375
if (_sessionType != FocusSessionType.freeFocus) {
  await _captureMasteryBefore();
}
```

The timer experience (circular progress, pause/resume, complete/cancel) is **identical** for all 4 types. No questions appear during the timer regardless of selection. The user selects "Spaced Repetition" expecting SR-prioritized questions but gets a blank timer. `_captureMasteryBefore()` only stores mastery data for potential later use — invisible backend operation.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:1198` — session type selector UI
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:57` — `_sessionType` state variable
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:373-375` — only usage of session type

**Acceptance criteria for "fixed":**
- Selecting "Spaced Repetition" + starting timer should show due questions inline during the timer, OR the session type selector should be removed/replaced with a clear explanation that the timer is purely a focus timer (no questions during session).
- At minimum: session type chips should be disabled or labeled to indicate they affect post-session analytics only.

---

### B2 — `defaultDurationMinutes` accepted but silently ignored

`FocusTimerScreen` accepts `defaultDurationMinutes` in its constructor (`focus_timer_screen.dart:31, 37`) and the `FocusTimerScreenArgs` (`app_router.dart:140`). The `TutorScreen` passes `defaultDurationMinutes: 15` (`tutor_screen.dart:551`) and `defaultDurationMinutes: 30` (`tutor_screen.dart:565`).

But `_selectedMinutes` is hardcoded to `25` at `focus_timer_screen.dart:49`. The `defaultDurationMinutes` parameter is **never read** in `initState()` or anywhere in the setup view.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:31` — parameter declaration
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:49` — `_selectedMinutes = 25` (ignores defaultDurationMinutes)
- `lib/features/teaching/presentation/tutor_screen.dart:549-551` — passes 15 min
- `lib/features/teaching/presentation/tutor_screen.dart:563-565` — passes 30 min
- `lib/core/routes/app_router.dart:140, 272-274` — passes via FocusTimerScreenArgs

**Acceptance criteria for "fixed":**
- `initState()` should set `_selectedMinutes` from `widget.defaultDurationMinutes` if it's non-null and > 0.
- The duration preset chips and slider should reflect this pre-set value.
- If the value doesn't match any preset chip, the slider position should represent it.

---

### B3 — Inline practice results never persisted (`FocusSession` is in-memory only)

`_lastFocusSession` (`focus_timer_screen.dart:72`) stores the last inline practice result purely in local widget state. The `FocusSession` model (`focus_session_model.dart:32-65`) has full `toJson()`/`fromJson()` serialization and is registered in Hive (`settings_screen.dart:34`) but **no code path ever calls `toJson()` to persist it**.

On app restart, navigation away and back, or widget rebuild, `_lastFocusSession` is `null`. The inline practice performance shown in `SessionSummaryCard` (focus_timer_screen.dart:634-639) disappears forever.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:72` — `_lastFocusSession` local state
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:995-1053` — `_onInlinePracticeComplete()` creates FocusSession but never calls `toJson()` or persists it
- `lib/features/focus_mode/data/models/focus_session_model.dart:32-65` — `toJson()`/`fromJson()` dead code
- `lib/features/settings/presentation/settings_screen.dart:34` — Hive type registration but no storage

**Acceptance criteria for "fixed":**
- `_onInlinePracticeComplete()` should persist the `FocusSession` to a Hive box (either dedicated repository or in `SessionRepository`).
- On Focus Mode load, the persisted session should be read and displayed in `SessionSummaryCard`.
- The `FocusSession` model's serialization should be reachable from production code.

---

## MAJOR (feature is broken or misleading)

### M1 — First-visit Focus Mode onboarding is too generic

The `firstFocusVisit` flag is correctly read (`focus_timer_screen.dart:126-132`) and an onboarding card is shown (line 647-691). But the card text (`l10n.focusFirstVisitHelp`) is a generic help message. It does NOT explain:

- The dual-mode toggle (Study Hub vs Timer) and what each mode does
- What session types mean (Quick Practice vs Spaced Repetition vs Weak Area Attack vs Free Focus)
- How inline practice differs from full-screen practice sessions
- Where to find focus stats and session history
- That session type in timer setup doesn't affect question delivery

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:647-691` — `_buildOnboardingCard()`
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:557-572` — help icon dialog same generic text

**Acceptance criteria for "fixed":**
- The onboarding card should explain the dual-mode design with specific callouts.
- Should distinguish inline practice (stays in Focus Mode) from full practice (opens PracticeSessionScreen).
- Should clarify that timer mode is a silent focus timer — questions are available only in Study Hub.
- Should direct users to session stats location.

---

### M2 — Study Hub labels are ambiguous about navigation

The bottom sheet at `_showPracticeOptions()` (`focus_timer_screen.dart:944-978`) shows:
- **Quick Practice** → starts inline practice (stays in Focus Mode)
- **Spaced Repetition** → navigates to full `PracticeSessionScreen` (leaves Focus Mode)

The standalone buttons below subject cards also show "Spaced Repetition" and "Weak Areas" (lines 828-845), which both navigate away from Focus Mode. The method `_startQuickPractice()` (`focus_timer_screen.dart:406`) is named misleadingly — it launches a full SR practice session, not a quick practice.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:406-411` — `_startQuickPractice()` name vs behavior mismatch
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:828-845` — standalone buttons ambiguous
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:944-978` — bottom sheet options

**Acceptance criteria for "fixed":**
- Add subtitle text distinguishing inline vs full-screen: "Practice here in Focus Mode" vs "Open full practice session."
- Rename `_startQuickPractice()` to `_startFullPracticeSession()`.
- Consider adding an icon indicator for "opens in new screen" vs "stays here."

---

### M3 — Inline practice confidence hardcoded to 4/2

At `inline_practice_widget.dart:167`:
```dart
confidence: _isCorrect ? 4 : 2,
```

This is identical to the exam mode bug (`scenario_exam_mode_spaced_repetition.md` finding #9). The SM-2 algorithm receives binary confidence only — a lucky guess (correct + low confidence) gets the same treatment as reliable knowledge (correct + high confidence).

**Affected files:**
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart:167`

**Acceptance criteria for "fixed":**
- Add a confidence selector (1-5 scale) after each answer in inline practice, like the full `PracticeSessionQuestionCard`.
- Pass the user's actual confidence to `MasteryRecorder.recordAttempt()`.

---

### M4 — `TopicPerformance.topicId` is set to `subjectId`

At `focus_timer_screen.dart:1011`:
```dart
final topicPerformance = TopicPerformance(
  topicId: subjectId,  // parameter name is "topicId" but receives a subjectId
  ...
);
```

The `TopicPerformance` model's `topicId` field is designed to hold a topic identifier, but inline practice completion sets it to the subject ID. This means the topic breakdown displayed in `PracticePerformanceCard` labels entries by subject IDs — not topic names. The data is semantically incorrect.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:1011` — wrong field assignment
- `lib/features/focus_mode/data/models/focus_session_model.dart:98-111` — `TopicPerformance` model
- `lib/core/widgets/practice_performance_card.dart` — renders the breakdown (receives wrong data)

**Acceptance criteria for "fixed":**
- Change line 1011 to track per-topic performance, not per-subject. The `_perSubjectCorrect`/`_perSubjectTotal` maps are keyed by `question.subjectId` but should be keyed by `question.topicId` for the topic breakdown.
- Or change the model field name to `subjectId` if this is intentional — but the current naming is misleading.

---

### M5 — Timer and Study Hub are architecturally disconnected from inline practice

There is no user flow that combines a running timer with inline practice. The timer setup (`_buildSetupView`) and study hub (`_buildStudyHubView`) are mutually exclusive via the mode toggle:

- Timer mode: shows a silent countdown, no questions
- Study Hub mode: shows practice options, no timer

Users who want to "focus with practice" cannot do so in a single screen flow. They must either:
1. Use the timer only (no questions), or
2. Use Study Hub inline practice (no time tracking)

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:693-725` — `_buildModeToggle` (mutual exclusion)
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:727-858` — `_buildStudyHubView` (no timer)
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:1098-1126` — `_buildActiveSessionView` (no questions)

**Acceptance criteria for "fixed":**
- Consider adding an inline practice panel that can coexist with the timer, or
- Clarify in the UI that timer mode is purely a focus timer and Study Hub is for practice, with clear labels making this distinction obvious.

---

### M6 — `FocusPracticeService` returns raw types, not `Result<T>`

`FocusPracticeService.startPracticeSession()` returns `Future<Session>` (`focus_practice_service.dart:120`) and `endPracticeSession()` returns `Future<void>` (line 137). This violates the AGENTS.md convention: "Public repository and service method return types must be `Result<T>`."

Errors are caught and logged silently (lines 133, 145), making failures invisible to callers.

**Affected files:**
- `lib/features/focus_mode/services/focus_practice_service.dart:120-135` — `startPracticeSession()` raw return
- `lib/features/focus_mode/services/focus_practice_service.dart:137-146` — `endPracticeSession()` raw return

**Acceptance criteria for "fixed":**
- Change return types to `Future<Result<Session>>` and `Future<Result<void>>`.
- The `PracticePerformanceCard` or `SessionSummaryCard` should handle failure states.

---

### M7 — Study Hub session type alignment broken

The `_sessionType` state variable (line 57) is only used to gate `_captureMasteryBefore()` in the timer flow (line 373). The Study Hub inline practice (`_startInlinePractice` at line 981) and full practice sessions (`_startQuickPractice` at line 406) ignore `_sessionType`. The bottom sheet always offers Quick Practice inline and SR full — regardless of what session type was last selected.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:57` — `_sessionType` (unused by study hub)
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:406-411` — `_startQuickPractice` ignores session type
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:981-986` — `_startInlinePractice` ignores session type

**Acceptance criteria for "fixed":**
- Either wire the session type selection to the Study Hub's inline practice method selection, or
- Move session type selection into the Study Hub view so it's clear what type of practice will occur.
- Remove the session type from the timer setup if it only gates mastery capture.

---

### M8 — Inline practice hardcoded to 10 questions

At `focus_timer_screen.dart:1164`:
```dart
InlinePracticeWidget(
  subjectId: subject?.id,
  questionCount: 10,  // HARDCODED
  ...
);
```

The `InlinePracticeWidget` defaults `questionCount` to 10 (`inline_practice_widget.dart:30`). This is too few for serious practice and cannot be configured by the user. The "Review Due Questions" button (`_startAllSubjectsInlinePractice`, line 988-993) also uses the default 10.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:1164` — hardcoded 10
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:988-993` — `_startAllSubjectsInlinePractice` uses default
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart:30` — default parameter

**Acceptance criteria for "fixed":**
- Make question count configurable: add a slider or chips in the inline practice setup (similar to timer duration).
- For "Review Due Questions," show all due questions (no cap, or cap at a generous limit like 50).
- Consider adding "Load 10 more" or pagination.

---

## MINOR (UX friction)

### m1 — Break view is a passive countdown with no interactive elements

After a timer session completes, the break view (`_buildBreakView`, `focus_timer_screen.dart:1055-1096`) shows "Break Time!" with a countdown and session duration. There is:

- No "Skip Break" button
- No "Practice due questions during break" link
- No "Review what you just studied" option

The user must wait for the countdown or kill the app to bypass.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:1055-1096` — break view

**Acceptance criteria for "fixed":**
- Add "Skip Break" button.
- Consider adding "Review due questions" link that starts inline practice during the break.

---

### m2 — Inline practice results not visible on Dashboard

The Dashboard's `SessionSummaryCard` (`dashboard_screen.dart`) does not receive `lastPracticeSession`. Only the Focus Mode `SessionSummaryCard` shows inline practice performance. Dashboard users see focus time stats but not practice accuracy.

**Affected files:**
- `lib/features/focus_mode/presentation/widgets/session_summary_card.dart:12-16` — accepts `lastPracticeSession` but Dashboard doesn't pass it
- Dashboard provider wiring — no passing of `FocusSession` data to Dashboard

**Acceptance criteria for "fixed":**
- Persist inline practice results (see B3), then expose last session data to Dashboard providers.
- Display last inline practice session performance on Dashboard, not just in Focus Mode.

---

### m3 — `_loadStats()` called without `await` after session events

At `focus_timer_screen.dart:204` (inside `_onSessionComplete`) and line 524 (inside `_onWillPop`), `_loadStats()` is invoked without `await`. This is fire-and-forget — the stats reload may not complete before the widget disposes (especially after pop at line 550). While `mounted` check at line 308 prevents crash, the stats update is lost if the widget pops before completion.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:204` — `_loadStats()` unawaited
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:524` — `_loadStats()` unawaited

**Acceptance criteria for "fixed":**
- Add `await` before both `_loadStats()` calls. For the `_onWillPop` case, await it before returning the pop decision.

---

### m4 — `SessionSummaryCard` on Dashboard uses different data than Focus Mode

The Dashboard's `SessionSummaryCard` renders focus time stats from `dashboardFocusStatsProvider`. The Focus Mode's `SessionSummaryCard` renders from `_service.getTodayStats()`. Both draw from `SessionRepository.getTodayStats()`, so data is consistent. But the Dashboard card cannot show inline practice performance because the `FocusSession` model is not shared with the Dashboard.

**Affected files:**
- Dashboard data providers (`dashboard_data_providers.dart`) — no FocusSession data
- Shared `SessionSummaryCard` widget — unused `lastPracticeSession` parameter by Dashboard

---

## Summary of Severity Counts

| Severity | Count | Items |
|---|---|---|
| **BLOCKER** | 3 | B1, B2, B3 |
| **MAJOR** | 8 | M1, M2, M3, M4, M5, M6, M7, M8 |
| **MINOR** | 4 | m1, m2, m3, m4 |

## Key Files Referenced

| File | Key Lines | Role |
|---|---|---|
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 31, 37, 49, 57, 72, 204, 373-375, 524, 557-572, 586-589, 634-639, 647-691, 693-725, 727-858, 828-845, 944-978, 981-986, 988-993, 995-1053, 1055-1096, 1098-1126, 1164, 1176-1255, 1198, 1200, 1202-1237 | Main screen: all flows |
| `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` | 30, 167 | Inline practice, hardcoded values |
| `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` | 12-16 | Stats display |
| `lib/features/focus_mode/providers/focus_mode_providers.dart` | 9-22 | Provider declarations |
| `lib/features/focus_mode/services/focus_practice_service.dart` | 120-146 | Service (non-Result returns) |
| `lib/features/focus_mode/data/models/focus_session_model.dart` | 32-65, 98-111 | Model with dead serialization |
| `lib/features/sessions/services/study_timer_service.dart` | 120-154, 194-234 | Timer session management |
| `lib/features/teaching/presentation/tutor_screen.dart` | 549-565 | Post-lesson Focus Mode arguments |
| `lib/core/routes/app_router.dart` | 138-145, 272-274 | FocusTimerScreenArgs wiring |
| `lib/features/settings/presentation/settings_screen.dart` | 34 | Hive registration only |
| `lib/features/settings/data/models/settings_box.dart` | 79 | `firstFocusVisit` flag |
