# Dry-Run Issue Fixes: Syllabus-Driven Curriculum

**Source:** `dry-run-test/scenario_syllabus_driven_curriculum.md`

**Overall progress:** 6/9 steps completed (~67%). 2 PARTIAL, 1 NOT_COMPLETED.

---

## Issue 1: Syllabus PDF Upload Does Not Auto-Create Topics

**Status:** NOT_COMPLETED

**Root cause:** `SourceType.syllabus` is never assigned through the upload flow.

In `upload_screen.dart:329-359`, `_inferSourceType()` maps file extensions:
- `.pdf` -> `SourceType.pdf`
- `.docx` / `.epub` / `.md` -> `SourceType.document`
- etc.

There is no code path that produces `SourceType.syllabus`. The content pipeline's `_extractTopicsFromSyllabus()` at `content_pipeline.dart:379-445` correctly parses syllabus content via LLM and auto-creates topics via `TopicRepository.create()`. However, the trigger at line 173 requires `type == SourceType.syllabus`, which never fires.

Meanwhile, the `_classifyTopic()` path at line 159 requires `possibleTopics.isNotEmpty`, which is populated from existing topics only (chicken-and-egg problem for new syllabi).

**What to fix:**

1. Add a "This is a syllabus" toggle/checkbox in the upload screen that overrides `sourceType` to `SourceType.syllabus`.
2. OR add a dedicated "Upload Syllabus" entry point that hardcodes `sourceType: SourceType.syllabus`.
3. Ensure `_extractTopicsFromSyllabus()` is called when `type == SourceType.syllabus` (currently yes at line 173) and `subjectId` is provided.

**Files to modify:**
- `lib/features/ingestion/presentation/upload_screen.dart` — add syllabus toggle or new entry point
- Optionally: `lib/features/ingestion/services/content_pipeline.dart` — verify existing code handles the syllabus path (lines 173-186, 379-445)

---

## Issue 2: Plan Generation Fails for New Users With No Practice History

**Status:** PARTIAL

**Root cause:** Empty `topicMastery` check blocks syllabus-based plan generation.

In `personal_learning_plan_service.dart:133-144`:
```dart
if (topicMastery.isEmpty && courseName.isNotEmpty) {
  return _buildEmptyMasteryPlan(...);  // bypass only works when courseName is set
}
if (topicMastery.isEmpty) {
  return Result.failure('You need to add a subject and its topics...');
}
```

When `generatePlanFromSyllabus()` is called, `courseName` defaults to `''` (line 100, `_buildPlan`). The empty-mastery bypass at line 133 is skipped because `courseName.isNotEmpty` is false. The second check at line 140 returns failure.

This means a student who just created a subject, uploaded a syllabus, and has topics but has NOT yet practiced any questions cannot generate a syllabus-based plan.

**What to fix:**
- Also allow the empty-mastery bypass when `syllabusGoals` is non-null (i.e., call `_buildEmptyMasteryPlan` for syllabus-based plans too).
- OR restructure the logic to: if topics exist for goals but no mastery states exist, generate a plan based on syllabus topic order rather than failing.

**Files to modify:**
- `lib/features/planner/services/personal_learning_plan_service.dart` lines 133-144
- Need to also handle `_buildEmptyMasteryPlan` with syllabus goals (or create equivalent)

---

## Issue 3: Syllabus Completion Not Shown Outside Planner

**Status:** PARTIAL

**Root cause:** Syllabus completion tracking (`SyllabusProgressCard`, `estimatedCoverage` in `PlanSummaryCard`) exists only in the planner screen. Dashboard and Subject Stats tabs lack syllabus completion percentage.

**Current state (what works):**
- `SyllabusProgressCard` (`syllabus_progress_card.dart`) shows mastered/total topics with percentage and progress bar in planner's `_buildSubjectProgressTabs` (line 903 of `planner_screen.dart`)
- `PlanSummaryCard` (`plan_summary_card.dart:66`) shows `estimatedCoverage` as percentage
- `_calculateCoverage()` at `personal_learning_plan_service.dart:972-977` uses proper `uniqueTopics / totalSyllabusTopics` division

**What to fix:**
1. Add syllabus completion percentage to the **Dashboard** (e.g., in the mastery overview section, add a card showing syllabus progress per subject)
2. Add syllabus completion percentage to the **Subject Stats tab** (`subject_stats_tab.dart`) — show mastered topics / total topics with progress bar
3. Consider adding a syllabus progress section to the **Subject Detail** header area

**Files to modify:**
- `lib/features/dashboard/presentation/` (add syllabus progress widget)
- `lib/features/subjects/presentation/widgets/subject_stats_tab.dart` (add syllabus progress section)
- Optionally: `lib/features/subjects/presentation/subject_detail_screen.dart` (add progress indicator to header)

---

## Verification Checklist

After fixes are applied:

1. [ ] Upload a PDF named "IB Chemistry Syllabus.pdf" with `subjectId` set → verify topics are auto-created
2. [ ] Create two topics with a prerequisite relationship via `SubjectTopicsTab` → verify `TopicDependency` persists
3. [ ] Create a syllabus-based plan for a brand-new subject (no practice history) → verify plan generation succeeds
4. [ ] Attempt to practice a topic with unmet prerequisites → verify dialog blocks or warns
5. [ ] Complete some practice → verify Dashboard and Subject Stats show syllabus completion percentage
