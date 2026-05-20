# Dry-Run Issue: Roadmaps & Milestone Planning — Remaining Fixes

**Source:** `dry-run-test/scenario_roadmaps_milestone_planning.md` (deleted — 85% completed)

**Overall status:** 17/20 COMPLETED, 2 PARTIAL, 1 NOT_COMPLETED

---

## Issue 1 (PARTIAL): Topic IDs shown as raw UUIDs instead of names

**Scenario ref:** Step 5 — "The actual topic IDS are invisible"

**What's done:** `_formatTopicNames()` at `roadmap_card.dart:24-28` now displays topic IDs as subtitle text in the milestone checklist.

**What's still wrong:** The topic IDs are raw UUID strings (e.g., `"a1b2c3d4-..."`) — human-readable topic names are never resolved from `TopicRepository`. Users still can't tell *which* topics are assigned to each milestone.

**Files:**
- `lib/features/planner/presentation/widgets/roadmap_card.dart:24-28` — `_formatTopicNames()` joins raw ID strings
- `lib/features/planner/services/planner_service.dart:239` — IDs stored as raw UUIDs from syllabus resolver

**Suggested fix:** Either:
- (a) Resolve topic IDs to names via `TopicRepository` before display, or
- (b) Store topic names alongside IDs in `MilestoneModel` (add a `topicNames` field)

---

## Issue 2 (PARTIAL): `plannedVsActual` not displayed in UI

**Scenario ref:** Step 8 — "No indication of schedule adherence or being behind/ahead of plan"

**What's done:** `plannedVsActual` map IS now populated in `planner_service.dart:329-349` during `toggleMilestoneCompletion()`.

**What's still wrong:** The `plannedVsActual` data is stored in Hive but never read or displayed in any UI component (`RoadmapCard`, `MilestoneTimeline`, etc.). Users have no way to see if they're ahead of or behind their planned schedule.

**Files:**
- `lib/features/planner/data/models/roadmap_model.dart:33` — Hive field 9, populated but never displayed
- `lib/features/planner/presentation/widgets/roadmap_card.dart` — No planned-vs-actual indicator

**Suggested fix:** Add a visual indicator to `RoadmapCard` showing schedule adherence, e.g.:
- "2 days ahead of schedule" / "3 days behind schedule" text
- A secondary progress bar comparing elapsed time vs milestone completion ratio

---

## Issue 3 (NOT_COMPLETED): Auto-completion doesn't refresh UI state

**Scenario ref:** Step 9 — "Auto-completion of milestones runs in the service layer but doesn't update the planner notifier state"

**What's done:** `PersonalLearningPlanService.linkDailyPlanToRoadmap()` at `personal_learning_plan_service.dart:633-661` correctly auto-completes milestones matching completed topics and saves to Hive.

**What's still wrong:** After auto-completion fires in the service layer, the `PlannerNotifier` state is **never updated**. The `PlannerNotifier.linkDailyPlanToRoadmap()` method was removed entirely — it no longer exists. This means:
- Roadmap card in UI shows stale milestone state
- User must navigate away and back (triggering `loadInitialData()`) to see changes
- Service silently saves to Hive but UI doesn't react

**Files:**
- `lib/features/planner/services/personal_learning_plan_service.dart:623` — Calls `linkDailyPlanToRoadmap()` after adherence
- `lib/features/planner/services/personal_learning_plan_service.dart:633-661` — Service-only operation, no notifier update
- `lib/features/planner/providers/planner_providers.dart:145-161` — `loadRoadmaps()` exists but is never called after auto-completion

**Suggested fix — Architecture options:**
1. **Callback pattern:** Have `recordDailyAdherence()` return a list of updated roadmap IDs. The caller (`PlanAdapter.recordFromTutorSession()`) can then trigger a reload.
2. **Bridge method:** Add a `refreshRoadmaps()` method to `PlannerNotifier` and call it from the adapter after adherence recording.
3. **Reactive listen:** Have the `PlannerNotifier` observe Hive changes to roadmap models (e.g., via `watch()` on the roadmap box).
