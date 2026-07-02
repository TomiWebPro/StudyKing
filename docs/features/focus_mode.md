# Focus Mode Feature

## Overview

Focus Mode combines a Pomodoro-style timer with inline question practice, allowing students to study in timed sessions while answering questions from their subject library. It supports multiple session types (spaced repetition, weak area attack, quick practice, free focus) and tracks session history, daily/weekly stats, and mastery changes.

## Key Files

| Layer | Files |
|---|---|
| Services | `FocusPracticeService` |
| Repositories | `FocusSessionRepository`, `StudyTimerService` (from sessions feature) |
| Models | `FocusSession`, `TopicPerformance`, `FocusSessionType` |
| Screens | `FocusTimerScreen` |
| Widgets | `FocusTimerWidget`, `InlinePracticeWidget`, `SessionSummaryCard` |
| Providers | `focusPracticeServiceProvider`, `focusSessionRepositoryProvider`, `studyTimerServiceProvider` |

## Core Services

### FocusPracticeService

Manages question selection and session lifecycle for focus-mode practice:

- `getDueQuestions(studentId, subjectIds, limit)` — Get questions due for spaced repetition review, prioritizing weak topics
- `getWeakAreaQuestions(studentId, subjectIds, limit)` — Get questions from topics with accuracy below 60%
- `getQuestionsForSessionType(sessionType, studentId, subjectIds, limit)` — Route to the appropriate question-fetching strategy based on session type
- `startPracticeSession(studentId, subjectIds, durationMinutes)` — Create and persist a new `Session` of type `focus`
- `endPracticeSession(session, questionsAnswered, correctAnswers)` — Mark session as completed with results

### StudyTimerService (from sessions feature)

Handles the actual timer logic: start, pause, resume, complete, cancel. Manages elapsed time, daily cap enforcement, and mid-session cap checks.

## Key Models

| Model | Purpose |
|---|---|
| `FocusSession` | A completed inline practice session with questions answered, accuracy, mastery changes, and per-topic breakdown |
| `TopicPerformance` | Per-topic accuracy and mastery delta within a focus session |
| `FocusSessionType` | Enum: `quickPractice`, `spacedRepetition`, `weakAreaAttack`, `freeFocus` |

## Focus Timer Workflow

1. User enters `FocusTimerScreen` and sees a mode toggle (Study Hub vs Timer Only)
2. In **Study Hub** mode, the user selects a session type, question count, and subject
3. In **Timer Only** mode, the user sets a duration and optionally picks a subject
4. User taps start — `StudyTimerService.startSession()` creates a timed session
5. During the session, the timer counts down with pause/resume support
6. A circular progress indicator shows elapsed time with a pulsing animation
7. If inline practice is active, questions are shown within the session flow
8. On completion, a break timer starts (configurable duration from settings)
9. Adherence is recorded via `PlanAdherenceOrchestrator`, and badges are checked
10. Mid-session, the daily cap is checked and the user is warned if exceeded

## Session Tracking

- All focus sessions (with inline practice) are saved as `FocusSession` objects in a dedicated Hive box
- Sessions started by the timer are saved as `Session` objects in the core session repository
- `FocusSessionRepository` stores JSON-serialized focus sessions with full topic breakdown and mastery changes
- `SessionSummaryCard` displays today's stats (duration, completed/total sessions), weekly duration, and recent session history

## Inline Practice Feature

- Accessible from the Study Hub view or via `InlinePracticeWidget`
- Questions are loaded based on the selected `FocusSessionType`:
  - **Quick Practice** — Random questions from selected subjects
  - **Spaced Repetition** — Questions due for review, prioritized by weak topics
  - **Weak Area Attack** — Questions from topics below 60% accuracy
  - **Free Focus** — Same as spaced repetition, without question tracking
- Each question shows a validation/feedback step, then a confidence selector
- On completion, a summary is shown with per-topic accuracy breakdown
- Mastery changes are captured by comparing before/after weak topic accuracies
