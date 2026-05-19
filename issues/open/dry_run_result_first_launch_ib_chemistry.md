# Dry-Run Issue: First Launch — IB Chemistry Scenario

**Generated:** 2026-05-19  
**Source scenario:** `dry-run-test/scenario_first_launch_ib_chemistry.md`  
**Overall completion:** ~84% (borderline; scenario retained due to critical gaps)

---

## Remaining Gaps (Priority Order)

### P1: No syllabus database / auto-complete for subject creation

**File(s):** `lib/features/subjects/presentation/subject_form_widgets.dart` (uses plain `TextFormField`)  
**Step:** 2 — Adding a Subject  
**Description:** Users must manually type subject name, code, syllabus, description. There is no auto-complete, no pre-built syllabus database for common curricula (IB, A-Levels, AP, GCSE, etc.), and no way to search "IB Chemistry" and have topics automatically populated.  
**Acceptance:** Subject name field should offer auto-complete suggestions for common curricula; selecting a curriculum should auto-populate topics/subtopics. Consider shipping seed JSON data for major curricula.  
**Existing behavior:** Post-creation dialog asks user to upload material (`subject_selection_screen.dart:104-120`), but topics must still be added manually.

---

### P2: Empty-mastery plans have zero linked questions

**File(s):** `lib/core/services/personal_learning_plan_service.dart:133-138` (early return for empty mastery)  
**Step:** 3 — Finding the Planner  
**Description:** `_buildEmptyMasteryPlan()` returns at line 133, before `_linkQuestionsToDailyPlans()` is called at line 201. Generated daily plans contain `reviewQuestionIds: []` and `stretchGoalQuestionIds: []` — no linked questions for practice.  
**Acceptance:** Empty-mastery plans should either (a) skip question linking gracefully and still provide meaningful study content, or (b) generate placeholder/sample questions as part of the pipeline.  
**Existing behavior:** Topics, estimated questions count, and estimated minutes ARE set (lines 300-319). Only the question ID lists are empty.

---

### P3: Course name does not influence topic recommendations when mastery data exists

**File(s):** `lib/core/services/personal_learning_plan_service.dart:157-200`  
**Step:** 3 — Finding the Planner  
**Description:** When `topicMastery` is non-empty, `courseName` is only used in `_generateDailyPlans()` (line 198) for summary/labeling. Topic recommendations are driven entirely by existing mastery data (`_buildRecommendations` at line 157). A user who types "IB Chemistry" but has chemistry mastery data from another subject will get a plan biased toward that other subject's topics.  
**Acceptance:** Course name should filter/scoped recommendations to topics belonging to the matching subject. Consider passing the resolved `subjectId` from `PlannerScreen._generatePlan()` to constrain the plan domain.  
**Existing behavior:** `PlannerScreen._generatePlan()` validates the course matches a subject AND that subject has topics (lines 223-262). If validation passes, the only flow path is to `generatePlan(course, days, hours)` — no subject-specific filtering applied.

---

### P4: No "next step" visual emphasis in dashboard checklist

**File(s):** `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart`  
**Step:** 7 — Checking Progress  
**Description:** All 4 checklist items have identical visual weight — same icon container, font weight, chevron. No "Start Here" badge, no numbering, no contextual highlighting to guide new users toward the next logical action.  
**Acceptance:** The first incomplete item should be visually distinguished (e.g., "Next: Add Subject" badge, different background, pulse animation, or numbered step indicator).  
**Existing behavior:** Completed items show checkmark + strikethrough + "Completed" label. Incomplete items all look the same.

---

### P5: No intermediate partial-progress dashboard state

**File(s):** `lib/features/dashboard/presentation/dashboard_screen.dart`  
**Step:** 7 — Checking Progress  
**Description:** The checklist is shown until all 4 steps are complete (`checklistProgress.isComplete`). Alongside it, the full 12-card dashboard is rendered (showing zeros/empty states until data accumulates). There is no intermediate state — e.g., hiding empty cards when the user has no data, showing a partially populated simpler layout, or providing card-by-card dismissals.  
**Acceptance:** Consider hiding metric cards that are guaranteed zero for a new user (e.g., weekly trend, adherence) until the first data point arrives, or using a simplified "getting started" dashboard that promotes to the full dashboard incrementally.  
**Existing behavior:** Checklist + full dashboard coexist. Card widgets internally handle empty states (e.g., `NextUpCard` shows "All caught up" when zero).

---

## Summary

| Issue | Priority | Affected Step | Area |
|---|---|---|---|
| Syllabus database / auto-complete | P1 | Step 2 | Subject Creation |
| No linked questions in empty-mastery plans | P2 | Step 3 | Plan Generation |
| Course name ignored when mastery exists | P3 | Step 3 | Plan Generation |
| No "next step" checklist emphasis | P4 | Step 7 | Dashboard |
| No intermediate dashboard state | P5 | Step 7 | Dashboard |
