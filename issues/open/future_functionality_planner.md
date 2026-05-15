# Unify Planner as Central Learning Command Center with Cross-Feature Adherence & Adaptive Replanning

## Context

The planner feature (`lib/features/planner/`) generates study plans and roadmaps, but it operates largely in isolation from the other learning features (focus mode, practice, teaching/tutor, mentor). Each feature records its own activity independently, and the planner only passively checks adherence via `PlanAdapter.checkAdherence()`. There is no real-time, unified view that answers "how is my plan going?" across all dimensions. Additionally, the **pending action pipeline** is broken: the mentor detects planning intents and creates `PendingActionModel` records, but `PlannerService.acceptPendingAction()` only marks them complete without actually executing the intended action (e.g., scheduling a lesson, rescheduling). The dashboard and planner have overlapping metric displays with no clear boundary.

## Problems Identified

### 1. Broken Pending Action Execution Pipeline
- **MentorService** detects scheduling/rescheduling intents and creates `PendingActionModel` records (`lib/features/mentor/services/mentor_service.dart`).
- **PendingActionCard** shows accept/dismiss buttons (`lib/features/planner/presentation/widgets/pending_action_card.dart`).
- **PlannerService.acceptPendingAction()** (`lib/features/planner/services/planner_service.dart:281`) only marks the action as completed — it never executes the actual scheduling or rescheduling logic.
- Result: Accepting a "Schedule a lesson" action from the pending list does nothing.

### 2. Planner–Dashboard Boundary Bleed & Metric Duplication
- **Planner** shows: `PlanSummaryCard` (total questions, minutes, coverage, focus areas), `DailyPlanCard` (topic questions/minutes), adherence banners, scheduled lessons.
- **Dashboard** shows: `SummaryRow` (accuracy, study hours, weekly activity, topics), `PlanAdherenceCard`, `MasteryProgressCard`, `WeeklyChart`, `TopicBreakdownCard`.
- Several metrics overlap (study time, plan progress, topic performance), but neither screen provides a cohesive planned-vs-actual comparison.
- Dashboard loads data from 8+ FutureProviders; planner loads from its own state. No shared data layer.

### 3. Adherence is Checked but Never Drives Adaptation
- `PlanAdapter.checkAdherence()` only detects after **3+ consecutive low-adherence days** before suggesting regeneration.
- No **real-time feedback**: "You studied 20min today vs 45min planned — want to adjust?".
- No **schedule shift**: If a student misses a day, the remaining plan should rebalance without full regeneration.
- `PlanAdapter.suggestRegeneration()` creates a whole new plan with uniformly scaled targets — it doesn't intelligently redistribute missed workload.

### 4. No Unified "Planned vs Actual" View
- Focus mode records sessions via `SessionPlanIntegrationService.recordFocusSessionCompletion()` — stored in `FocusSessionRepository`.
- Practice records via `recordPracticeSessionCompletion()` — stored via `PlanAdapter`.
- Tutor records via `recordTutorSessionCompletion()` — stored via `PlanAdapter`.
- **But none of these appear in the planner UI.** The planner shows `scheduledLessons` from `TutorSessionRepository` with `SessionStatus.planned` only — not completed sessions.
- There is no "today's progress" bar showing: planned 60min / actual 35min / remaining 25min.

### 5. Roadmaps Disconnected from Daily Plans
- `RoadmapCard` shows milestones with checkboxes and `MilestoneTimeline`.
- Daily plans in `DailyPlanCard` show per-topic targets.
- **No linkage**: completing a daily plan's topics does not update roadmap milestone progress, and roadmap milestone completion does not affect daily plan adjustments.

### 6. SyllabusResolver is Underutilized in Plan Generation
- `SyllabusResolver` (`lib/features/planner/services/syllabus_resolver.dart`) performs topological sort, prerequisite analysis, readiness scoring, and priority calculation.
- But `PersonalLearningPlanService.generatePlan()` does not use `SyllabusResolver` — it only uses `MasteryGraphService` for topic selection. Prerequisite-aware daily ordering is absent.
- The `SyllabusResolver.buildLearningLevels()` method exists but is never called anywhere.

### 7. No Student Availability / Preferences Model
- Plan generation accepts only: course name, days, hours/day.
- No concept of: preferred study times, blackout days, weekly availability windows, learning pace preferences, or session length preferences.
- `LessonBookingSheet` (`lib/features/planner/presentation/widgets/lesson_booking_sheet.dart`) always defaults to next hour, 30-minute duration — no awareness of student's typical availability.

### 8. No Calendar or Timeline Visualization for Plans
- `DailyPlanCard` renders a vertical list of daily plans (can be hundreds of days for long-term plans).
- No weekly grid, monthly calendar, or Gantt-style timeline view.
- `MilestoneTimeline` is the only horizontal timeline, and it only covers the roadmap — not the full plan.

### 9. SessionPlanIntegrationService Creates a Circular/Redundant Recording Chain
- `SessionPlanIntegrationService` (`lib/features/sessions/services/session_plan_integration_service.dart`) wraps `PlanAdapter`, which wraps `PersonalLearningPlanService.recordDailyAdherence()`.
- But `PlannerService` also has `recordFocusSession`/`recordPracticeSession`/`recordTutorSession` methods that duplicate the same `PlanAdapter` calls.
- Recording sources are fragmented: focus/practice/tutor screens use `SessionPlanIntegrationService` directly, while `PlannerService` has its own recording methods that nothing calls.

### 10. Dead Code in SyllabusResolver
- Forum at `syllabus_resolver.dart:106-118` builds `prereqNodes` list but never uses it (assigned to local variable, discarded).

## Affected Files

| File | Issue |
|---|---|
| `lib/features/planner/providers/planner_providers.dart` | Action execution stub; no adherence-driven state updates |
| `lib/features/planner/services/planner_service.dart` | `acceptPendingAction` doesn't execute; redundant record methods |
| `lib/features/planner/presentation/planner_screen.dart` | No planned-vs-actual view; duplicated metrics with dashboard |
| `lib/features/planner/presentation/widgets/pending_action_card.dart` | UI exists but pipeline is incomplete |
| `lib/features/planner/presentation/widgets/daily_plan_card.dart` | No progress indicators for actual completion |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | No conflict detection or availability awareness |
| `lib/features/planner/presentation/widgets/plan_summary_card.dart` | Overlaps with dashboard SummaryRow |
| `lib/features/planner/services/syllabus_resolver.dart` | Dead code (unused `prereqNodes`); topological sort not integrated into plan generation |
| `lib/core/services/plan_adapter.dart` | SuggestRegeneration is blunt (uniform scaling); no real-time adjustment |
| `lib/core/services/personal_learning_plan_service.dart` | generatePlan() doesn't use SyllabusResolver |
| `lib/features/sessions/services/session_plan_integration_service.dart` | Redundant with PlannerService.record* methods |
| `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart` | Could be merged into planner |
| `lib/features/dashboard/presentation/widgets/summary_row.dart` | Metric overlap with planner |
| `lib/features/mentor/services/mentor_service.dart` | Creates pending actions but no follow-through |

## Proposed Solution

### Phase 1: Unify Adherence Recording
1. Eliminate `SessionPlanIntegrationService` — move its logic into `PlanAdapter` (the single source of truth for adherence recording).
2. Remove the redundant `PlannerService.recordFocusSession`/`recordPracticeSession`/`recordTutorSession` methods.
3. Ensure all features (focus, practice, tutor) call `PlanAdapter` directly after session completion.

### Phase 2: Fix the Pending Action Pipeline
1. Add an `ActionExecutor` service that maps each `PendingActionModel.actionType` to real operations:
   - `schedule` → `PlannerService.scheduleLesson()` using stored parameters
   - `reschedule` → `PlannerService.cancelLesson()` + `scheduleLesson()` with new time
   - `planAdjustment` → call mentor to generate adjusted targets, then auto-apply
2. Update `PendingActionModel` to carry the parameters needed for execution (topicId, scheduledTime, etc. — currently only `topicTitle` is stored).
3. Make accept/dismiss in `PendingActionCard` call through the executor.

### Phase 3: Planned-vs-Actual Dashboard Hub
1. Create a `PlanProgressProvider` that aggregates:
   - Planned: from `PersonalLearningPlan.dailyPlans` (target minutes, target questions)
   - Actual: from `FocusSessionRepository`, `StudySessionRepository`, `PlanAdherenceRepository`
   - Output: per-day and cumulative planned vs actual overlay
2. Add a `ProgressOverlayWidget` to the planner showing:
   - Today: green/yellow/red bar for actual vs planned
   - Weekly: mini bar chart comparing daily targets vs actuals
   - Cumulative: "36/180 days complete, 45% of plan"
3. Merge overlapping Dashboard widgets into the planner (or remove from dashboard if planner becomes the hub).

### Phase 4: Adaptive Adherence-Driven Replanning
1. Replace blunt `checkAdherence` with per-day analysis:
   - After each recorded session, check if the day's plan is on track.
   - If student misses a day, suggest a **micro-adjustment**: redistribute missed workload over the next 3 days.
   - Only suggest full regeneration if deviation exceeds a configurable threshold (e.g., >40% off-track over 7 days).
2. Add `PlanAdapter.redistributeWorkload()` that shifts uncompleted daily targets forward without changing total plan scope.

### Phase 5: Syllabus-Aware Plan Generation
1. Inject `SyllabusResolver` into `PersonalLearningPlanService.generatePlan()`.
2. Use `buildLearningLevels()` output to order daily plans by prerequisite topology, not just mastery gaps.
3. Generate daily plans that respect "must learn A before B" constraints.

### Phase 6: Calendar View & Availability Model
1. Introduce `StudentAvailability` model (preferred study days, time windows, max sessions per day, blackout dates).
2. Add a calendar/weekly grid view as an alternative to the vertical daily list.
3. Use availability data in plan generation and lesson booking sheet defaults.
4. Add conflict detection to `LessonBookingSheet` against existing scheduled sessions.

### Phase 7: Roadmap–Plan Linkage
1. After completing a day's plan, auto-check related roadmap milestones.
2. When a milestone is checked, mark the associated topics as reviewed in the plan.
3. Show roadmap progress as an overlay on the daily plan view.

## Acceptance Criteria

1. **Pending actions execute real operations** — Accepting "Schedule a lesson" in the planner actually creates a `TutorSession` with `SessionStatus.planned`.
2. **Single adherence recording path** — All three session types (focus, practice, tutor) record through `PlanAdapter` only, with no duplicate methods.
3. **Planned-vs-actual view visible** — The planner screen shows per-day progress bars comparing target minutes/questions vs actual, without requiring navigation to dashboard.
4. **Micro-adjustment on missed day** — If a student records 0 minutes on a day with 60min planned, the planner suggests redistributing the 60min across the next 3 days without regenerating the full plan.
5. **Prerequisite-aware daily plans** — Plan generation orders topics respecting prerequisite topology from `SyllabusResolver`.
6. **Calendar view available** — A tab/weekly view shows the plan in calendar format, not just a vertical list.
7. **Conflict detection in lesson booking** — Booking a lesson at a time that overlaps an existing scheduled session shows a warning.
8. **Roadmap ↔ plan linkage** — Completing a daily plan's topics auto-updates related roadmap milestone progress.
9. **No dead code** — The unused `prereqNodes` loop in `SyllabusResolver` is removed or put to use.
10. **No metric duplication** — Planner and dashboard have clearly separated responsibilities (planner = planned + tracking, dashboard = historical trends + mastery + badges).
