# Build an Intelligent Syllabus-Aware Planning Engine with Closed-Loop Adaptive Rescheduling

## Context

The current planner feature (`lib/features/planner/`) generates daily study plans by sorting existing topics from the mastery graph by priority. It has no awareness of **syllabus structure**, **learning sequences**, **lesson bookings**, or how to **adapt plans based on actual adherence**. The roadmap feature generates generic "Week N" milestones with no AI-driven content and no actionable way to mark progress. Meanwhile, the `agent_must_read.md` vision describes a system that should:

- "I want to learn IB Physics in 180 days" — break long-term goals into manageable schedules
- Track actual adherence vs intended schedule
- Adapt plans as progress changes (closed-loop adjustment)
- Support multiple syllabi simultaneously
- Schedule lessons from within the planner
- Integrate practice sessions, focus mode, and review into the plan

None of these capabilities exist in the current implementation. The planner has the right skeleton (cards, providers, service, plan model, roadmap model, adherence tracking) but lacks the intelligence and integration to fulfill the product vision.

## Affected Files

| Scope | Files |
|---|---|
| **Planner Service** | `lib/features/planner/services/planner_service.dart` |
| **Planner Providers** | `lib/features/planner/providers/planner_providers.dart` |
| **Planner Screen** | `lib/features/planner/presentation/planner_screen.dart` |
| **Planner Widgets** | `lib/features/planner/widgets/plan_summary_card.dart`, `daily_plan_card.dart`, `roadmap_card.dart`, `milestone_timeline.dart` |
| **PLP Service** | `lib/core/services/personal_learning_plan_service.dart` |
| **PLP Model** | `lib/core/data/models/personal_learning_plan_model.dart` |
| **Roadmap Model** | `lib/core/data/models/roadmap_model.dart` |
| **Plan Adherence** | `lib/core/data/models/plan_adherence_model.dart`, `lib/core/data/repositories/plan_adherence_repository.dart` |
| **Engagement** | `lib/core/services/engagement_scheduler.dart` |
| **Mentor** | `lib/features/mentor/services/mentor_service.dart`, `lib/features/mentor/presentation/mentor_screen.dart` |
| **Routes** | `lib/core/routes/app_router.dart` |
| **Topics** | `lib/core/data/models/topic_model.dart`, `lib/core/data/repositories/topic_repository.dart` |
| **Lessons** | `lib/features/lessons/` |
| **Practice** | `lib/features/practice/` |
| **Focus Mode** | `lib/features/focus_mode/` |
| **Tests** | `test/features/planner/` |

## Rationale

### 1. No syllabus-aware plan generation

`PersonalLearningPlanService.generatePlan()` only considers topics already in the mastery graph. If a student says "I want to learn IB Physics in 180 days", the planner has no way to:
- Fetch the syllabus topics for IB Physics
- Structure them into a logical learning sequence (prerequisites first)
- Create lessons for brand-new topics (not yet in mastery graph)
- Allocate study time proportionally across the full syllabus

The `course` parameter in the planner form is just a text string — it's never used to resolve syllabus content.

### 2. Daily plans are never adapted

`PlanAdherenceRepository` and `PersonalLearningPlanService.recordDailyAdherence()` exist but are never called from any user-facing flow. The generated plan is static — once created, plan adherence data accumulates silently but the plan is never regenerated or adjusted based on:
- Consecutive low adherence days
- Topics that were actually practiced (vs planned)
- New weak areas detected from practice sessions
- Spaced repetition review needs

### 3. Roadmaps are decorative

Roadmap milestones are all generated as `"Week N"` / `"Milestone for week N"` with no AI-driven content:
- No topics are linked to milestones (topicsCovered is always empty)
- No assessment criteria are set (assessmentCriteria is always empty)
- No way for the student to mark milestones as complete from the UI
- No way to edit, pause, archive, or delete roadmaps
- completionPercentage is manually set to 0.0 and never updated

### 4. No lesson scheduling from planner

The planner shows a "Start Tutoring" button per planned topic, but it opens an ad-hoc tutor session immediately — it does not schedule a lesson at a specific future time. There is no:
- Calendar view of planned vs completed lessons
- Booking system to allocate tutor sessions for specific days/times
- Recurring lesson scheduling
- Integration between `DailyPlan` and `TutorSession`

### 5. Multiple syllabus planning is absent

The vision explicitly states "students should learn and track from multiple syllabi simultaneously." The current planner has no concept of subjects or syllabi — plans are a flat list of priority topics regardless of subject.

### 6. No practice session integration in plans

`DailyPlan` has `reviewQuestionIds` and `stretchGoalQuestionIds` fields, but they are always empty. The planner never:
- Selects actual questions for the planned topics
- Passes planned review questions to the practice session
- Uses spaced repetition data to determine what review questions to include

### 7. Focus mode is not linked to plan adherence

Focus sessions (`FocusSessionRepository`) track actual study time, but this data is never fed into `PlanAdherenceRepository` or used to update planned vs actual metrics in the plan.

### 8. Pending actions from mentor are never fulfilled

The `PendingActionRepository` stores scheduling/planning intents detected by the mentor (`_checkAndHandlePlanningIntent`), but there is no UI or workflow to:
- Display pending actions to the student
- Convert them into actual plan modifications or lesson bookings
- Dismiss or act on them

## Recommended Architecture

### A — Syllabus-Aware Planner Engine

```
PlannerService
 ├── SyllabusResolver (new)
 │    ├── Fetches topics by subject_id + syllabus_code
 │    ├── Builds a learning DAG from topic dependencies
 │    └── Supports multiple syllabi per plan
 ├── PlanGenerator (refactor from PersonalLearningPlanService)
 │    ├── Accepts List<SyllabusGoal> (subjectId, syllabusCode, targetDays)
 │    ├── Uses mastery data for known topics, syllabus structure for new topics
 │    ├── Generates lesson slots (not just "review this topic")
 │    └── Produces [DailyPlan] with linked question IDs
 └── PlanAdapter (new)
      ├── Reads PlanAdherenceRepository daily
      ├── Detects deviation patterns
      └── Triggers plan regeneration with adjusted parameters
```

### B — Roadmap-to-Action Pipeline

```
Roadmap
 ├── Metadata: subjectId, topicIds per milestone, assessment criteria
 ├── AI-generated: per-milestone learning objectives + topic breakdown
 ├── Actions:
 │    ├── Mark milestone complete → updates completionPercentage
 │    ├── "Schedule lesson for milestone N" → opens lesson booking
 │    └── "View milestone progress" → filtered dashboard
 └── Auto-progression:
      └── When all topics in a milestone reach ≥80% mastery → suggest marking complete
```

### C — Lesson Booking & Calendar

```
LessonScheduler (new service)
 ├── Reads DailyPlan from planner
 ├── Accepts time slot selection from student
 ├── Creates a TutorSession record (not yet started) with planned start time
 ├── Supports reschedule/cancel from mentor flow
 └── Renders in a CalendarView widget
```

### D — Closed-Loop Adherence

```
Daily
 ├── Focus session ends → updates PlanAdherenceRepository (actualMinutes)
 ├── Practice session ends → updates PlanAdherenceRepository (actualQuestions)
 ├── Tutor session ends → updates PlanAdherenceRepository
 └── PlanAdapter runs at end of day:
      ├── Checks consecutiveLowAdherenceDays
      ├── If >3 days low → auto-suggest regeneration
      └── If >7 days low → escalate to mentor with full context
```

### E — Multi-Syllabus Plan Model

Extend `PersonalLearningPlan` to support:
```dart
class PersonalLearningPlan {
  // ... existing fields
  final List<SyllabusGoal> syllabusGoals;  // NEW
  final Map<String, List<DailyPlan>> subjectPlans;  // NEW
  // Track progress per subject, not just globally
}
```

## Acceptance Criteria

1. **Syllabus-Based Plan Generation**: Generate a plan from a real syllabus (e.g., IB Physics) that structures topics in prerequisite order and allocates study days proportionally.

2. **Adaptive Plan Regeneration**: After 3+ days of low adherence, the system auto-suggests regenerating the plan with adjusted daily targets. Student can accept or customize.

3. **Lesson Booking Flow**: Student can tap a planned topic and choose "Schedule Lesson" → pick date/time → creates a `TutorSession` with status `scheduled` → shows in a calendar view.

4. **Question-Linked Daily Plans**: `DailyPlan.reviewQuestionIds` and `stretchGoalQuestionIds` are populated with actual question IDs from the question repository based on spaced repetition urgency and mastery level.

5. **Roadmap Topic Linking**: Creating a roadmap with a subjectId automatically fetches the syllabus, populates milestone `topicsCovered`, and generates meaningful milestone descriptions with AI.

6. **Milestone Completion**: Student can manually mark a milestone complete, which updates `completionPercentage`. Auto-suggest when all milestone topics reach proficient mastery.

7. **Focus Mode Integration**: Ending a focus session updates today's plan adherence (actualMinutes). `PlanAdherenceCard` in dashboard reflects this in real-time.

8. **Multi-Syllabus View**: The planner screen shows per-subject tabs (or a combined view) where each subject has its own progress bar and daily plan list.

9. **Pending Action Workflow**: Mentor-created pending actions (schedule/reschedule intent) appear as notification cards in the planner screen with "Accept" / "Dismiss" buttons.

10. **Existing tests continue to pass** — all changes to `PersonalLearningPlanModel`, `PlannerService`, `PlannerState`, and widgets must be backward-compatible or have updated tests.
