# Unify Fragmented Session Models into a Single Coherent Study Session

## Summary

The codebase currently contains **three separate session models** that all represent overlapping concepts of "a period of study": `StudySession`, `FocusSession`, and `TutorSession`. These live in different features, use different storage strategies, track different metrics, and are completely disconnected from one another. This fragmentation makes unified analytics impossible, duplicates timer infrastructure, increases maintenance burden, and blocks key roadmap features like intelligent study planning, adherence tracking, and comprehensive reporting.

## Context

### The Three Session Models

| Model | File | Hive | Box | Storage |
|---|---|---|---|---|
| `StudySession` | `lib/core/data/models/study_session_model.dart:4` | TypeId 8 | `sessions` | Proper Hive adapter |
| `FocusSession` | `lib/features/focus_mode/data/models/focus_session_model.dart:2` | **None** | `focus_sessions` | JSON string in Hive box |
| `TutorSession` | `lib/core/data/models/tutor_session_model.dart:6` | TypeId 28 | `tutor_sessions` | Proper Hive adapter |

### Overlap Analysis

**`StudySession` vs `FocusSession`** — the most redundant pair:

| Concern | `StudySession` | `FocusSession` |
|---|---|---|
| Start/end time | `startTime`, `endTime` | `startTime`, `endTime` |
| Duration | `timeSpentMs` (ms) | `actualDurationSeconds` (s) |
| Planned duration | ❌ | `plannedDurationMinutes` |
| Completion status | ❌ (implicit: has endTime) | `completed` (explicit) |
| Student ID | `studentId` | ❌ |
| Subject | `subjectId` | `subjectId` (nullable) |
| Topic | `lessonId` | `topicId` (nullable) |
| Questions answered | `questionsAnswered` | ❌ |
| Correct answers | `correctAnswers` | ❌ |
| Created at | ❌ | `createdAt` |

**`TutorSession`** has a distinct tutoring-focused purpose (lesson plans, messages, tokens, etc.) but still represents time-bounded study and duplicates shared fields (`startTime`, `endTime`, `subjectId`, `plannedDurationMinutes`, question counts).

## Affected Files

| File | Role |
|---|---|
| `lib/core/data/models/study_session_model.dart` | Study session model (Hive typeId 8) |
| `lib/features/focus_mode/data/models/focus_session_model.dart` | Focus timer session model (JSON-in-Hive) |
| `lib/core/data/models/tutor_session_model.dart` | Tutor session model (Hive typeId 28) |
| `lib/features/sessions/data/repositories/study_session_repository.dart` | Repository for StudySession |
| `lib/features/focus_mode/data/repositories/focus_session_repository.dart` | Repository for FocusSession (non-standard, no base class) |
| `lib/features/teaching/data/repositories/tutor_session_repository.dart` | Repository for TutorSession |
| `lib/features/sessions/services/session_export_service.dart` | Export service (only handles StudySession) |
| `lib/features/focus_mode/services/focus_session_service.dart` | Timer service with own analytics and daily cap |
| `lib/features/practice/presentation/services/practice_session_service.dart` | Practice timer that creates StudySession |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | Own inline timer (duplicate of FocusSessionService) |
| `lib/features/sessions/presentation/session_history_screen.dart` | Shows only StudySession data |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | Shows only FocusSession data |
| `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` | Separate analytics card |
| `lib/features/sessions/presentation/widgets/session_analytics.dart` | Separate analytics widget |
| `lib/core/data/hive_box_names.dart` | Holds both `sessions` and `focus_sessions` box names |
| `lib/core/data/hive_type_ids.dart` | Holds type IDs |

## Rationale

### 1. Unified analytics are impossible

The `SessionAnalyticsWidget` and `SessionSummaryCard` exist in parallel, each showing a partial picture. A student who uses the Focus Timer for 3 hours and then does 1 hour of practice will see **two separate session lists**, **two separate time totals**, and **two separate streak calculations**. The dashboard and planner have no way to compute total actual study time across all session types.

### 2. Duplicate timer infrastructure

There are **three independent timer implementations**:
- `FocusSessionService` (features/focus_mode/) — Timer.periodic, pause/resume/complete/cancel, callbacks
- `SessionTrackerScreen._startSession` (features/sessions/) — inline Timer.periodic, no pause, no callbacks
- `PracticeSessionService.startTimer` (features/practice/) — inline Timer.periodic, no pause, no callbacks

### 3. Non-standard storage pattern

`FocusSessionRepository` bypasses Hive type adapters entirely, storing JSON-encoded strings. This means:
- No type safety at the storage layer
- No Hive migration support
- Cannot use `Repository<T>` base class methods like `filterBy`
- Manual serialization/deserialization with error handling

### 4. Blocks roadmap features

The agent_must_read.md envisions:
- *"track study hours by subject"* — currently impossible to get total study hours
- *"track actual adherence vs intended schedule"* — plan adherence adapter (`PlanAdherenceAdapter`, `PlanAdapter`) must integrate with three separate session interfaces
- *"comprehensive reporting"* — export services only know about `StudySession`
- *"intelligent planning that adapts to progress"* — the planner cannot observe focus timer sessions

### 5. Time unit inconsistency

- `StudySession.timeSpentMs` → milliseconds
- `FocusSession.actualDurationSeconds` → seconds  
- `TutorSession.elapsedMinutes` → minutes (computed)

## Proposed Solution

### Phase 1: Unified Session Model

Create a single `Session` model that subsumes `StudySession` and `FocusSession`:

```
Session {
  id: String
  studentId: String
  subjectId: String?
  topicId: String?
  type: SessionType (practice | focus | tutoring | manual)
  startTime: DateTime
  endTime: DateTime?
  plannedDurationMinutes: int?     // from FocusSession
  actualDurationMs: int            // from StudySession.timeSpentMs
  questionsAnswered: int           // from StudySession
  correctAnswers: int              // from StudySession
  completed: bool                  // from FocusSession
  sourceId: String?                // optional link to tutoring/lesson
  tags: List<String>               // extensible metadata
  createdAt: DateTime
}
```

### Phase 2: Migrate Data

1. Write a one-time migration script to merge `focus_sessions` and `sessions` boxes into a single `sessions` box
2. Register Hive type adapter for the unified model
3. Remove `FocusSession` model, repository, and box

### Phase 3: Consolidate Timer Logic

1. Replace `FocusSessionService` and inline timers with a single `StudyTimerService`
2. Standardize timer capabilities: start/pause/resume/complete/cancel/elapsed stream
3. Have practice sessions and focus sessions use the same timer service

### Phase 4: Unify Analytics

1. Merge `SessionAnalyticsWidget` and `SessionSummaryCard` into a single analytics component
2. Update `SessionHistoryScreen` to show all session types with type filtering
3. Feed unified session data into the planner's adherence tracking

### Phase 5: Extend Export

1. Update `SessionExportService` to handle the unified model
2. Include session type and planned duration in CSV/PDF/JSON exports
3. Ensure comprehensive export includes all session types

### Long-Term: Optional TutorSession Integration

Consider whether `TutorSession` should also be unified (its lesson-specific fields could live in a join table or as a `tutor_metadata` JSON field on Session), but this is lower priority given its distinct tutoring-specific semantics.

## Acceptance Criteria

- [ ] A single `Session` model replaces `StudySession` and `FocusSession` with no data loss
- [ ] Existing focus timer sessions are migrated to the new model on first launch
- [ ] A unified `StudyTimerService` replaces all three inline timer implementations
- [ ] Session history screen displays all session types with appropriate icons/labels
- [ ] Session analytics (by day-of-week, total time, streaks) include all session types
- [ ] Focus timer screen works end-to-end using the unified model
- [ ] Practice auto-save creates `Session` records via the unified repository
- [ ] Export services include session type and planned duration in output
- [ ] Hive type adapter is registered and `FocusSession` model/repository/box are removed
- [ ] All existing tests pass; new tests cover the unified model and migration
