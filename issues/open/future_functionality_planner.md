# Mentor-Planner Convergence & Proactive Engagement Engine

## Context

The `agent_must_read.md` vision describes two distinct AI interaction systems: **Teaching Mode** (live tutoring) and **Assistance/Mentor Mode** (persistent companion for planning, motivation, accountability, scheduling, and wellbeing). The teaching mode is well-implemented through the `teaching` feature. However, the mentor mode has a critical gap: the `MentorService` (`lib/features/mentor/services/mentor_service.dart`) is a thin chat wrapper with minimal context awareness, while the `PlannerService` (`lib/features/planner/services/planner_service.dart`) and the plan/roadmap/scheduling infrastructure remain disconnected from the mentor conversation flow.

Additionally, proactive engagement — a core requirement ("The system should proactively engage students with reminders, prompts, revision nudges...") — is entirely unimplemented: the `EngagementNudgeRepository` (`lib/features/planner/data/repositories/engagement_nudge_repository.dart`) is fully built but never called by any service or provider.

## Problem

### 1. Mentor context is too thin for intelligent assistance

`MentorService._buildContextPrompt()` (`lib/features/mentor/services/mentor_service.dart:143-154`) injects only 6 aggregate stats (total attempts, correct attempts, accuracy, topics studied, weekly activity, total study hours). It has **zero awareness** of:

- The student's current plan status, adherence, or deviation
- Roadmap goals or milestones
- Pending actions awaiting the student's decision
- Upcoming scheduled lessons
- Weak topics from the mastery graph (separate `getProgressReport` call not in chat context)
- Multi-syllabus progress breakdown
- Recent tutor session outcomes or feedback

This makes the mentor feel shallow and disconnected from the student's actual study journey.

### 2. Mentor cannot execute planning actions conversationally

When a student says "schedule a lesson on photosynthesis," `MentorService._checkAndHandlePlanningIntent()` (`mentor_service.dart:79-141`) creates a `PendingActionModel` with a naive `DateTime.now() + 1 hour` schedule that:

- Does not consult `StudentAvailabilityModel` (`lib/features/planner/data/models/student_availability_model.dart`) for preferred study times
- Does not check for scheduling conflicts via `PlannerService.hasSchedulingConflict()`
- Does not involve the student in a back-and-forth negotiation ("I see you're free tomorrow at 3pm — shall I book it?")
- Does not use `PlannerService.scheduleLesson()` for actual booking

The student must manually go to the Planner screen, find the pending action, and accept/reject it. This breaks the conversational flow.

### 3. Proactive engagement is entirely dead code

`EngagementNudgeRepository` (`lib/features/planner/data/repositories/engagement_nudge_repository.dart`, 63 lines) implements full CRUD for `EngagementNudgeModel` (overwork nudges, revision nudges, plan adjustment suggestions, lesson reminders, auto-regeneration). **Zero callers exist.** No service checks conditions and creates nudges. The `EngagementScheduler` (`core/services/engagement_scheduler.dart`) exists but its nudge creation logic has no integration point with the mentor.

The vision requires proactive engagement: "reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement." None of this is functional.

### 4. Mentor has no wellbeing/overwork awareness

The vision states: "prevent student from overworking and stress" and "wellbeing support related to studying." The `EngagementNudgeModel.nudgeType` includes `overwork`, but no code ever detects excessive study sessions, late-night study, or consecutive days above target. The `StudyTimerService` (`lib/features/sessions/services/study_timer_service.dart`) has a `dailyCapMinutes` setting but this is never surfaced to the mentor.

### 5. No accountability or motivation subsystem

The vision requires accountability ("accountability messaging") and motivation ("motivation and encouragement"). The current code has:
- `BadgeService` (`core/services/badge_service.dart`) — tracks badge unlocks but no integration with mentor conversation
- `StudyProgressTracker` (`core/services/study_progress_tracker.dart`) — has recommendations but no structured motivation flow
- No streak celebrations, milestone congratulations, or low-adherence check-ins

### 6. Dead / unused code burden

| Dead Code | Location | Lines | Impact |
|---|---|---|---|
| `EngagementNudgeRepository` | `planner/data/repositories/engagement_nudge_repository.dart` | 63 | Full CRUD, zero callers |
| `AdaptivePracticeEngine` | `core/services/adaptive_practice_engine.dart` | 122 | Full engine, no provider wired, no screen uses it |
| `lessonPlanProvider` | `teaching/providers/teaching_providers.dart` | 4 | Always returns null |
| `promptTemplatesProvider` | `teaching/providers/teaching_providers.dart` | 4 | Exact duplicate of `promptsProvider` |
| 6 `FutureProvider.family` in lessons | `lessons/providers/lesson_providers.dart` | ~30 | Defined, never consumed by any widget |

### 7. Service-layer duplication

`PlannerService.redistributeWorkload()` (planner) is a near-exact duplicate of `PersonalLearningPlanService._redistributeMissedWorkload()` (core). Same for `linkDailyPlanToRoadmap()` vs `_linkDailyPlanToRoadmap()`. Two versions of the same logic, risking divergence.

### 8. Repository pattern inconsistency

`core/data/repository.dart:4` states: "All repositories MUST wrap their public method return types in Result." `TutorSessionRepository` (`lib/features/teaching/data/repositories/tutor_session_repository.dart`) and `ConversationRepository` (`lib/features/teaching/data/repositories/conversation_repository.dart`) both throw raw exceptions instead of returning `Result<T>`, violating the project convention.

## Proposed Solution

### Phase 1: Mentor Context Expansion

Extend `MentorService._buildContextPrompt()` to inject rich, structured context:

- **Plan context**: Does a plan exist? Current phase? Adherence score? Deviation warning?
- **Roadmap context**: Active roadmaps, nearest milestone, completion percentage
- **Pending actions**: Count and types of actions awaiting decision
- **Upcoming lessons**: Next 3 scheduled sessions with times
- **Weak topics**: From `MasteryGraphService.getWeakTopics()`
- **Recent session feedback**: Last tutor session outcome (if any today)
- **Multi-syllabus**: Per-subject progress breakdown
- **Wellbeing signals**: Today's study minutes vs daily cap, consecutive study days, late-night sessions

### Phase 2: Conversational Scheduling & Action Execution

Replace the PendingActionModel passthrough with direct conversational execution:

- When the student asks to schedule, the mentor calls `PlannerService.scheduleLessonWithConflictCheck()` after checking `StudentAvailabilityModel`
- The mentor proposes a time slot to the student for confirmation before booking
- Rescheduling follows the same pattern: propose a new time, get confirmation, execute
- Long-term planning ("I want to learn IB Physics in 180 days") calls `PlannerService.createRoadmap()` + `PlannerService.generatePlanFromSyllabus()` with conversational confirmation

### Phase 3: Proactive Engagement Engine

Wire `EngagementNudgeRepository` into a background service that:

- **Overwork detection**: Checks daily study time against daily cap; fires nudge when exceeded
- **Revision nudges**: Checks `QuestionMasteryStateRepository.getAtRiskQuestions()` for items approaching review date
- **Plan adherence nudges**: Checks `PlanAdapter.checkAdherence()` and surfaces low-adherence warnings
- **Lesson reminders**: Checks upcoming `TutorSession` objects and reminds before start
- **Streak celebrations**: Detects consecutive study days and generates congratulatory messages

Nudges flow into the mentor conversation as system-introduced messages and surface as notification-service notifications.

### Phase 4: Wellbeing Monitor

Add a background monitor that tracks:

- Daily total study minutes from `StudyTimerService` / `SessionRepository`
- Consecutive days above target
- Late-night session detection (sessions starting after 10 PM)
- Session count per day
- Surfaces concerns through the mentor ("You've studied 6 hours today — that's above your usual. Want to take a break?")

### Phase 5: Accountability & Motivation Subsystem

- **Milestone celebrations**: When a roadmap milestone completes or adherence streak reaches 7 days, the mentor proactively congratulates
- **Low-activity check-in**: If no study activity for 48+ hours, the mentor asks if everything is okay
- **Plan regeneration prompt**: When adherence drops below 50% for 3 consecutive days, the mentor suggests a plan review
- **Weekly digest**: Every Sunday, the mentor generates a short weekly summary of what was accomplished

### Phase 6: Cleanup

- Remove dead `AdaptivePracticeEngine` from core (superseded by `SpacedRepetitionEngine` in practice)
- Remove dead providers: `lessonPlanProvider`, `promptTemplatesProvider`, the 6 unused lesson providers
- Consolidate `PlannerService` duplication by delegating to `PersonalLearningPlanService` instead of duplicating
- Fix repository pattern: wrap `TutorSessionRepository` and `ConversationRepository` methods in `Result<T>`
- Remove dual block storage in `LessonRepository` (blocks stored both inline and separately)

## Affected Files

### Mentor Feature
- `lib/features/mentor/services/mentor_service.dart` — Expand context, add proactive methods
- `lib/features/mentor/providers/mentor_providers.dart` — Add new dependencies
- `lib/features/mentor/presentation/mentor_screen.dart` — Surface proactive messages, add wellbeing UI

### Planner Feature
- `lib/features/planner/data/repositories/engagement_nudge_repository.dart` — Wire into services (currently dead code)
- `lib/features/planner/data/models/engagement_nudge_model.dart` — May need condition-trigger fields
- `lib/features/planner/services/planner_service.dart` — Expose scheduling/roadmap methods for conversational use
- `lib/features/planner/services/syllabus_resolver.dart` — May need refactoring for mentor querying
- `lib/features/planner/providers/planner_providers.dart` — Expose engagement nudge providers

### Core Services
- `lib/core/services/engagement_scheduler.dart` — Integrate nudge creation with repository
- `lib/core/services/study_progress_tracker.dart` — Add wellbeing/motivation metrics
- `lib/core/services/mastery_graph_service.dart` — Already has weak topic detection
- `lib/core/services/personal_learning_plan_service.dart` — Consolidate duplicated logic from planner

### Teaching Feature
- `lib/features/teaching/providers/teaching_providers.dart` — Remove dead `lessonPlanProvider`, `promptTemplatesProvider`
- `lib/features/teaching/data/repositories/tutor_session_repository.dart` — Wrap in `Result<T>`
- `lib/features/teaching/data/repositories/conversation_repository.dart` — Wrap in `Result<T>`

### Lessons Feature
- `lib/features/lessons/providers/lesson_providers.dart` — Remove 6 unused providers or wire them to actual consumers
- `lib/features/lessons/data/repositories/lesson_repository.dart` — Remove dual block storage

### Practice Feature
- `lib/core/services/adaptive_practice_engine.dart` — Remove (dead code, superseded by SpacedRepetitionEngine)
- `lib/features/practice/providers/practice_providers.dart` — Remove `AdaptivePracticeEngine` provider reference if any

## Rationale

The mentor mode is central to the StudyKing vision as "a persistent mentor that understands the student's history, habits, preferences, and academic goals." Currently, the mentor is a generic chat LLM with basic stats — it knows the student's accuracy but not their plan, their weak topics, their schedule, or their wellbeing. The gap between vision and implementation is the largest in the codebase.

Fixing this delivers disproportionate user value because:
1. It makes the mentor feel intelligent and personalized, not generic
2. It enables a single conversational interface for scheduling, planning, motivation — reducing UX friction
3. It completes the proactive engagement system that the architecture scaffolds but doesn't power
4. It cleans up dead code that adds maintenance burden without providing value
5. It consolidates duplicated business logic

## Acceptance Criteria

1. **Mentor context injection**: The mentor conversation prompt includes plan status, weak topics, upcoming lessons, and wellbeing signals. Verifiable by inspecting `_buildContextPrompt()` output.

2. **Conversational scheduling**: Saying "schedule a lesson on [topic]" to the mentor proposes a time slot based on student availability, checks conflicts, waits for confirmation, and books via `PlannerService.scheduleLesson()`. No manual PendingAction acceptance required.

3. **Roadmap creation**: Saying "create a roadmap for [subject] in [N] days" triggers `PlannerService.createRoadmap()` after conversational confirmation.

4. **Engagement nudge generation**: At least three nudge types are generated and persisted (overwork, revision, plan adjustment). Nudges appear in the mentor conversation.

5. **Wellbeing detection**: The mentor warns when daily study time exceeds the daily cap, and when sessions occur late at night.

6. **Motivation/accountability**: The mentor congratulates after a 7-day study streak, and checks in after 48 hours of inactivity.

7. **Plan adherence awareness**: The mentor knows the student's adherence score and can discuss plan adjustments.

8. **Dead code removed**: `EngagementNudgeRepository` is wired into services. `AdaptivePracticeEngine` is removed. Dead providers are removed. No runtime errors from removal.

9. **Duplicate logic consolidated**: `PlannerService.redistributeWorkload()` and `linkDailyPlanToRoadmap()` delegate to `PersonalLearningPlanService` instead of duplicating.

10. **Repository consistency**: `TutorSessionRepository` and `ConversationRepository` return `Result<T>` from all public methods.

11. **All existing tests pass** with zero changes to test logic.

12. **New tests exist** for engagement nudge generation, conversational scheduling flow, wellbeing detection, and mentor context expansion.
