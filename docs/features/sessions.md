# Sessions Feature

## Overview

The Sessions feature tracks study sessions (focus, practice, tutoring, manual), provides a live timer, displays analytics and history, supports data export in multiple formats (CSV, JSON, PDF), and migrates legacy focus sessions to the typed session model.

## Key Files

| Layer | Files |
|---|---|
| Services | `StudyTimerService`, `SessionExportService`, `SessionMigrationService` |
| Adapters | `SessionAdapter` |
| Providers | `sessionRepositoryProvider`, `allSessionsProvider`, `todayStatsProvider` |
| Screens | `SessionTrackerScreen`, `SessionHistoryScreen` |
| Utils | `sessionIcon`, `sessionColor` (in `session_utils.dart`) |
| Widgets | `SessionAnalyticsWidget` |

## Core Services

### StudyTimerService

Manages the active study session lifecycle:

- `startSession({plannedDurationMinutes, type, subjectId, topicId})` — Begin a new session with optional plan
- `pauseSession()` / `resumeSession()` — Pause/resume the running timer
- `completeSession()` — Finalize session with actual duration, trigger notifications
- `cancelSession()` — Cancel without marking complete
- `reconcileElapsedMs(expectedMs)` — Reconcile timer drift
- `getDailyCapMinutes()` / `isDailyCapReached()` / `getRemainingDailyCapMinutes()` — Daily study cap enforcement
- `getTodayDurationMs()` / `getTodaySessionCount()` / `getTodayCompletedSessionCount()` / `getTodayStats()` — Today's aggregated data
- `getRecentSessions(limit)` — Last N sessions

### SessionExportService

Stateless export utilities:

- `sessionsToCSV(sessions)` — Generate CSV string (invariant `en` format for data)
- `sessionsToJSON(sessions)` — Convert to JSON list
- `sessionsToPDF(sessions, l10n)` — Generate PDF with table and summary (locale-aware)
- `shareCSV()` / `shareJSON()` / `sharePDF()` — Write temp file and share via OS share sheet

### SessionMigrationService

- `migrateIfNeeded()` — Migrates legacy `focusSessions` Hive box (string JSON) into typed `sessions` box as `Session` objects with `SessionType.focus`

## Key Models

| Model | Purpose |
|---|---|
| `Session` (from core) | Study session with id, type, start/end time, duration, questions/correct counts, completion status, source/topic/lesson associations, tutor metadata |
| `SessionType` | Enum: focus, practice, tutoring, manual |
| `TutorMetadata` | Nested metadata: topicTitle, lessonPlanJson, confidence, notes, topicsCovered, message/token counts |

## Key UI Features

- **SessionTrackerScreen:** Live timer display with start/stop controls, subject selector, recent sessions list, streak calculation, and `SessionAnalyticsWidget`
- **SessionAnalyticsWidget:** Bar chart of sessions by day of week, metric cards for average session time, total sessions, current streak, and total study time
- **SessionHistoryScreen:** Filterable history by date and subject, swipe-to-delete, summary stats (total sessions, total time, average), and full export sheet
- **Export Sheet:** Modal bottom sheet with options for CSV, PDF, JSON, and comprehensive reports (via `ProgressExportService`)

## Session Lifecycle

1. **Start:** User taps "Start" on the tracker; a `Session` with `SessionType.manual` is created
2. **Tracking:** Timer ticks every second; elapsed time displayed in large font
3. **End:** User taps "End"; a dialog asks for questions answered and correct count
4. **Save:** Session is persisted via `SessionRepository`; plan adherence and mastery tracking are triggered
5. **View:** Sessions appear in the history screen and are used for analytics and export
6. **Cleanup:** Stale sessions (started but never completed) can be dismissed from the history list
