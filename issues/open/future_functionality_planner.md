# Future Architecture: Planner Feature is a Facade with Critical Missing Layers

## Context

The `lib/features/planner/` directory presents itself as a properly structured feature (with `presentation/`, `providers/`, `services/`, and `widgets/` subdirectories) but is actually a facade:

- `providers/` — **empty** (0 files)
- `services/` — **empty** (0 files)
- `widgets/` — **empty** (0 files)
- `presentation/` — contains a single **845-line** `PlannerScreen` StatefulWidget that handles all logic inline

The screen directly instantiates `PlanRepository`, `MasteryGraphService`, `RoadmapRepository`, etc. in `initState` rather than receiving them through dependency injection or providers. It also contains hardcoded roadmap milestone generation logic (line 232–243 of `planner_screen.dart`) that creates milestones by simply dividing days by 7 with generic "Week N" labels — no AI, no topic awareness, no student history.

Simultaneously, the **Mentor** feature (`lib/features/mentor/`) independently handles scheduling/rescheduling via fragile keyword-matching (`_isScheduleRequest` at `mentor_service.dart:124`), duplicating planning concern in another feature. The **Lessons** feature (`lib/features/lessons/`) is also a shell — its `providers/`, `services/`, and `widgets/` directories are **all empty** too.

This creates three interrelated problems:
1. Planner is a monolith with no service/state layer — business logic is untestable and unreusable
2. Mentor re-implements planning via substring matching (English/Spanish) instead of delegating to the planner
3. Lessons have no programmatic structure — no lesson generation, no lesson CRUD beyond basic screens

---

## Detailed Findings

### 1. Empty Provider/Service/Widget Directories in `planner`

**Affected directories (all empty):**
- `lib/features/planner/providers/`
- `lib/features/planner/services/`
- `lib/features/planner/widgets/`

**Evidence:** The barrel file `lib/features/planner/planner.dart` exports only `presentation/planner_screen.dart`, but the `planner.dart` feature-file and directory structure imply a full feature module exists. The three empty subdirectories are dead scaffolding.

### 2. PlannerScreen is a 845-Line Monolith Mixing All Concerns

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart` (845 lines)

**Evidence:** This single StatefulWidget:
- Creates repositories directly in `initState` (lines 56–60, 64): `PlanRepository()`, `MasteryGraphService()`, `RoadmapRepository()`
- Directly instantiates services (line 59): `MasteryGraphService(repository: widget.masteryGraphRepository)`
- Handles its own async lifecycle with no state management abstraction
- Contains inline roadmap creation with hardcoded milestone generation (lines 232–243):
  ```dart
  final numMilestones = (days / 7).ceil().clamp(1, 52);
  final milestones = <MilestoneModel>[];
  for (var i = 0; i < numMilestones; i++) {
    final milestoneDeadline = now.add(Duration(
      days: ((i + 1) * days / numMilestones).round(),
    ));
    milestones.add(MilestoneModel(
      id: const Uuid().v4(),
      title: l10n.weekNumber(i + 1),
      description: l10n.milestoneForWeek(i + 1),
      deadline: milestoneDeadline,
      order: i + 1,
    ));
  }
  ```
- Build methods inline all widget rendering — no extracted widget classes, no widget tests possible
- The screen mixes form input, roadmap CRUD, plan generation, daily plan rendering, timeline rendering, and milestone display

### 3. MentorService Duplicates Planning via Keyword Matching

**Affected file:** `lib/features/mentor/services/mentor_service.dart`

**Evidence:**
- `_isScheduleRequest()` (lines 124–137) uses substring matching on English and Spanish phrases
- `_handleScheduleRequest()` (lines 165–206) queries tutor sessions and returns formatted text — no actual schedule modification
- `_isConfirmation()` (lines 98–110) and `_isRejection()` (lines 112–122) duplicate confirmation patterns
- `_pendingAction` state machine (lines 23–24, 52–62, 256–272) is fragile — only handles `reschedule` and `schedule` action types, with no rollback or audit trail
- The system prompt (lines 274–303) instructs the assistant to "NEVER alter schedules without asking for confirmation first" but the confirmation mechanism is a fragile in-memory flag that is lost if the widget rebuilds

### 4. Lessons Feature is an Empty Shell

**Affected directories (all empty):**
- `lib/features/lessons/providers/`
- `lib/features/lessons/services/`
- `lib/features/lessons/widgets/`

**Evidence:** The barrel file `lessons.dart` only exports three screen files: `topic_list_screen.dart`, `lesson_list_screen.dart`, and `lesson_detail_screen.dart`. There are no lesson services, no lesson generation logic, no lesson plan management, and no lesson progress tracking. The `TutorService` in the teaching feature generates lesson plans, but the lessons feature has no way to store, organize, or manage them as first-class entities.

### 5. Badge/Gamification System is Ephemeral (Query-Time Computation)

**Affected file:** `lib/core/services/study_progress_tracker.dart` (lines 183–224)

**Evidence:** `getBadges()` recomputes badges on every invocation:
```dart
Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
  final stats = await getOverallStats(studentId);
  final badges = <Map<String, dynamic>>[];
  if ((stats['totalAttempts'] as int) >= 1) {
    badges.add({...});
  }
  // ... all badges recomputed from current stats
  return badges;
}
```
- Badges are NOT persisted — a stat drop means badges disappear
- No unlock timestamps are preserved (the method sets them to `DateTime.now()`)
- No badge notification, no unlock animation, no badge detail screen
- No badge history or collection view

### 6. Engagement Scheduler Operates on Hardcoded Student ID

**Affected file:** `lib/core/services/engagement_scheduler.dart`

**Evidence:**
- Line 47: `final studentId = 'default';` — hardcoded, multi-student impossible
- Line 38: Daily check timer is fixed to 9:00 AM — no configurable window
- `_sendNudgeNotifications()` (lines 51–99) catches and swallows all exceptions individually with empty catch blocks — failures are invisible
- No in-app nudge UI — all nudges go through `NotificationService` which may not be available on all platforms
- No engagement history tracking — no record of what nudges were sent, when, or whether the student acted on them

### 7. Adaptive Practice Engine Exists but is Disconnected

**Affected file:** `lib/core/services/adaptive_practice_engine.dart` (171 lines)

**Evidence:** The engine has methods for question selection based on weakness scores, topic progress, and spaced repetition intervals. However:
- It is not imported or used by the planner feature
- It is not integrated with `PersonalLearningPlanService`
- It is not referenced by the mentor feature
- Its `_questionStates` map is in-memory only — lost on app restart
- Neither `PracticeSessionService` nor `PersonalLearningPlanService` delegate to this engine

### 8. No Cross-Feature Plan Adherence Tracking

**Affected files (multiple):**

**Evidence:**
- `PersonalLearningPlanService.generatePlan()` generates plans but has no mechanism to track actual vs. planned adherence
- `DashboardScreen` shows a `PlanAdherenceCard` but relies on `InstrumentationService` which has its own separate adherence tracking
- `EngagementScheduler._countConsecutiveLowAdherence()` tries to compute adherence from `InstrumentationService.getAdherenceHistory()` but the data source is disconnected from the planner
- There is no single "plan adherence" concept — three different abstractions exist: `PlanAdherenceMetric` (instrumentation), `plannedVsActual` (roadmap), and the engagement scheduler's ad-hoc check

---

## Rationale

The planner is the central orchestration point for the entire StudyKing vision described in `agent_must_read.md`. The vision calls for:
- "break longterm goals into manageable schedules" — currently handled by hardcoded milestone generation
- "adapt plans as progress changes" — no adaptation mechanism exists
- "track actual adherence vs intended schedule" — three disconnected systems attempt this
- "intelligent and long-term" planning — the current planner uses simple priority sorting

The mentor's keyword-based scheduling creates a parallel, lower-quality planning system that is fragile (depends on exact substring matches) and in-memory only. These two systems must converge into a single planning architecture.

The lessons feature is a structural gap — without lesson services, there is no programmatic way to create, organize, or track lessons as part of a study plan.

---

## Acceptance Criteria

### Phase 1: Planner Feature Architecture (foundational)

- [ ] Extract `PlannerService` from `PlannerScreen` — move plan generation, roadmap CRUD, and recommendation logic into `lib/features/planner/services/planner_service.dart`
- [ ] Create `PlannerState` with Riverpod `Notifier` in `lib/features/planner/providers/planner_providers.dart` covering: current plan, roadmaps list, generation status, error state
- [ ] Extract reusable widgets from `PlannerScreen`:
  - `PlanSummaryCard` (lines 713–748)
  - `DailyPlanCard` (lines 779–844)
  - `RoadmapCard` (lines 497–586)
  - `MilestoneTimeline` (lines 588–711)
  - Place them in `lib/features/planner/widgets/`
- [ ] Remove empty `providers/`, `services/`, `widgets/` directory placeholders once populated (or add `.gitkeep` if intentional)
- [ ] Rewire `initState` repository instantiation to use Riverpod providers for testability
- [ ] Add `mounted` guards to all async callbacks in `PlannerScreen`

### Phase 2: Mentor Scheduling Delegation

- [ ] Remove `_isScheduleRequest()`, `_handleScheduleRequest()`, `_isConfirmation()`, `_isRejection()`, and `_executePendingAction()` from `MentorService`
- [ ] Replace with delegation to `PlannerService` — mentor detects scheduling intent via LLM (not keyword matching), then delegates to planner
- [ ] Remove `_pendingAction` / `_pendingConfirmation` in-memory state machine — replace with planned actions persisted to a new `PendingActionRepository`
- [ ] Add structured action type union (`ScheduleAction`, `RescheduleAction`, `PlanAdjustmentAction`) instead of `Map<String, dynamic>`

### Phase 3: Lessons Feature Service Layer

- [ ] Create `LessonService` in `lib/features/lessons/services/lesson_service.dart`:
  - CRUD for lessons (create from tutor session, organize by topic/subject)
  - Lesson generation pipeline (delegate to `TutorService.generateLessonPlan`)
  - Lesson progress tracking
- [ ] Create `LessonProvider` (Riverpod) in `lib/features/lessons/providers/`
- [ ] Extract lesson list item widget and lesson detail sections into `lib/features/lessons/widgets/`
- [ ] Remove empty directory placeholders when populated

### Phase 4: Persistent Gamification System

- [ ] Create `Badge` model and `BadgeRepository` in `core/data/` with persistent storage (Hive)
- [ ] Create `BadgeService` with badge unlock logic that fires once and persists
- [ ] Add badge unlock notification via `NotificationService`
- [ ] Create a badge collection/achievement screen
- [ ] Remove ephemeral badge computation from `StudyProgressTracker.getBadges()` — migrate to `BadgeService`

### Phase 5: Multi-Student Engagement Scheduler

- [ ] Remove hardcoded `studentId = 'default'` — iterate over all known student IDs or make student ID configurable
- [ ] Replace fixed 9:00 AM timer with configurable check window (e.g., config in settings)
- [ ] Add `EngagementNudgeRepository` to persist sent nudges and student responses
- [ ] Build in-app nudge banner/inbox UI (not just platform notifications)
- [ ] Add `_countConsecutiveLowAdherence` integration with actual planner data instead of `InstrumentationService`

### Phase 6: Adaptive Practice ↔ Planner Integration

- [ ] Integrate `AdaptivePracticeEngine` into `PersonalLearningPlanService.generatePlan()` to influence daily topic selection
- [ ] Connect `PracticeSessionService` to `AdaptivePracticeEngine` for within-session question ordering
- [ ] Persist `_questionStates` from `AdaptivePracticeEngine` to `SpacedRepetitionRepository` instead of in-memory map

### Phase 7: Unified Plan Adherence

- [ ] Define a single `PlanAdherence` model and repository
- [ ] Remove ad-hoc adherence tracking from `EngagementScheduler._countConsecutiveLowAdherence()` and `InstrumentationService`
- [ ] Have `PersonalLearningPlanService` record actual progress vs. planned
- [ ] Have `DashboardScreen` read from this single source

---

## Files That Must Be Modified or Created

| Action | File |
|--------|------|
| Refactor | `lib/features/planner/presentation/planner_screen.dart` |
| Create | `lib/features/planner/services/planner_service.dart` |
| Create | `lib/features/planner/providers/planner_providers.dart` |
| Create | `lib/features/planner/widgets/plan_summary_card.dart` |
| Create | `lib/features/planner/widgets/daily_plan_card.dart` |
| Create | `lib/features/planner/widgets/roadmap_card.dart` |
| Create | `lib/features/planner/widgets/milestone_timeline.dart` |
| Refactor | `lib/features/mentor/services/mentor_service.dart` |
| Create | `lib/core/data/models/pending_action_model.dart` |
| Create | `lib/core/data/repositories/pending_action_repository.dart` |
| Create | `lib/features/lessons/services/lesson_service.dart` |
| Create | `lib/features/lessons/providers/lesson_providers.dart` |
| Create | `lib/core/data/models/badge_model.dart` |
| Create | `lib/core/data/repositories/badge_repository.dart` |
| Create | `lib/core/services/badge_service.dart` |
| Refactor | `lib/core/services/study_progress_tracker.dart` (getBadges) |
| Refactor | `lib/core/services/engagement_scheduler.dart` |
| Create | `lib/core/data/models/engagement_nudge_model.dart` |
| Create | `lib/core/data/repositories/engagement_nudge_repository.dart` |
| Refactor | `lib/core/services/adaptive_practice_engine.dart` (persistence) |
| Create | `lib/core/data/models/plan_adherence_model.dart` |
| Create | `lib/core/data/repositories/plan_adherence_repository.dart` |
| Refactor | `lib/core/services/personal_learning_plan_service.dart` (adherence tracking) |
| Remove/refactor | `lib/features/dashboard/services/` (if empty, populate or remove) |
| Update | `lib/features/planner/planner.dart` (barrel exports) |
| Update | `lib/features/lessons/lessons.dart` (barrel exports) |
