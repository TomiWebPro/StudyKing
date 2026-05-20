# Dry-Run Issue: Syllabus-Driven Curriculum Learning

**Source scenario:** `dry-run-test/scenario_syllabus_driven_curriculum.md`
**Audit date:** 2026-05-19
**Status:** 4/9 steps completed (~56%) — below 80% threshold for deletion

---

## NOT_COMPLETED — Must Be Fixed

### Issue 1: Syllabus PDF Upload Cannot Auto-Create Topics

**Step:** 1 — Upload syllabus PDF → topic creation

**Root cause:** `content_pipeline.dart:310` — `_classifyTopic()` short-circuits when `possibleTopics` is empty. The upload screen (`upload_screen.dart:225-234`) populates `possibleTopics` only from existing topics in the subject. When uploading a syllabus to a fresh subject, no topics exist → `possibleTopics` is empty → classification skipped → no topics created.

**What needs to change:**

Option A (pipeline-level fix): In `content_pipeline.dart`, add a fallback pass in `_classifyTopic()` (or a new method) when `possibleTopics` is empty:
- Ask the LLM: "Extract topic names from this syllabus PDF"
- For each extracted name, create a `Topic` object via `_topicRepository.create()`
- Return the created topic IDs

Option B (UI-level fix): In `upload_screen.dart`, before calling `processFullPipeline`, if the uploaded document is a syllabus and no topics exist, first run a separate LLM pass to extract topic names, create `Topic` objects, then proceed with classification against the newly created topics.

**Files involved:**
- `lib/features/ingestion/services/content_pipeline.dart:304-364` — `_classifyTopic()` with empty-guard at line 310
- `lib/features/ingestion/presentation/upload_screen.dart:225-234` — `possibleTopics` population from existing topics only
- `lib/features/ingestion/presentation/source_detail_screen.dart:232` — re-process path (already has correct topic loading)

### Issue 2: Syllabus Completion Tracking

**Step:** 5 — No syllabus completion percentage

**Root cause:** Multiple gaps:

1. **No syllabus completion percentage UI component.** Dashboard shows mastery-based progress only. Subject stats tab shows attempts/accuracy/time only. No card or metric anywhere computes "X% of syllabus mastered."

2. **`subject_plans` metadata never written.** `PersonalLearningPlanService._buildPlan()` (`personal_learning_plan_service.dart:236-240`) writes `syllabus_goals` to metadata but never writes `subject_plans`. The getter `PersonalLearningPlan.subjectPlans` (`personal_learning_plan_model.dart:75-82`) reads `metadata['subject_plans']` which is always absent → `_buildSubjectProgressTabs` at `planner_screen.dart:866` always shows 0 topics.

3. **`estimatedCoverage` is crude heuristic.** `_calculateCoverage()` (`personal_learning_plan_service.dart:941-947`) falls back to `uniqueTopics / 10` when `totalSyllabusTopics` is 0. Even when `totalSyllabusTopics > 0`, this only tracks topics attempted vs. total topics in syllabus — not topics mastered vs. total.

**What needs to change:**

1. Write `subject_plans` to plan metadata during `_buildPlan()` — map each subjectId to its list of `DailyPlan` entries.
2. Add a proper syllabus progress component (e.g., `SyllabusProgressCard`) that computes: `topicsMastered / totalSyllabusTopics`.
3. Expose this component in Dashboard, Planner's subject progress section, and Subject Detail screen.
4. Fix `estimatedCoverage` to use a real total (from subject's topic count) rather than hardcoded fallback.

**Files involved:**
- `lib/features/planner/services/personal_learning_plan_service.dart:236-240` — missing `subject_plans` write
- `lib/features/planner/data/models/personal_learning_plan_model.dart:75-82` — `subjectPlans` getter (reads never-written key)
- `lib/features/planner/presentation/planner_screen.dart:856-895` — `_buildSubjectProgressTabs` shows 0 topics
- `lib/features/planner/services/personal_learning_plan_service.dart:941-947` — `_calculateCoverage` crude heuristic

---

## PARTIAL — Needs Additional Work

### Issue 3: Study Plan from Syllabus — Topic Count Display Broken

**Step:** 3 — Study plan from syllabus goals

**Root cause:** same as Issue 2 item 2 — `subject_plans` metadata never written.

**What needs to change:** Write `subject_plans` metadata in `_buildPlan()`. Also consider writing per-subject topic lists to enable the progress tabs to work.

**Files involved:**
- `lib/features/planner/services/personal_learning_plan_service.dart:236-240`
- `lib/features/planner/presentation/planner_screen.dart:866`

### Issue 4: Prerequisite Enforcement — Gaps in 6/7 Practice Entry Points

**Step:** 4 — Prerequisite enforcement

**Root cause:** While `TutorScreen` and `PracticeScreen._startTopicPractice` DO check prerequisites, the following entry points do NOT:
- `_startPractice()` (subject-level practice, line 236)
- `_startSpacedRepetitionSession()` (line 388)
- `_startWeakAreasPractice()` (line 644)
- `_startAtRiskPractice()` (line 430)
- `_showSourcePracticeSheet()` (line 489)
- `_startExamMode()` (line 419)
- `PracticeSessionScreen._loadQuestions()` itself (practice_session_screen.dart:112-151)
- `ExamSessionScreen` (zero prerequisite references)

Additionally, `PracticeScreen._startTopicPractice()` at `practice_screen.dart:258` has a bug: the dialog result is discarded (`await showPrerequisiteDialog(...)` with no return value capture), so the method always returns and blocks ALL topic practice regardless of user choice. The "Practice Prerequisites" and "Continue Anyway" buttons in the dialog are ineffective.

**What needs to change:**

1. Fix `_startTopicPractice()` — capture the dialog result and only block practice if the user chooses not to continue.
2. Add prerequisite checking to the other practice entry points (spaced repetition, weak areas, at-risk, exam mode, source practice).
3. Consider adding prerequisite filtering in `PracticeSessionScreen._loadQuestions()` to exclude topics whose prerequisites aren't met.
4. Either wire up `TopicReadinessService` into the practice/tutor flows OR remove it as dead code.

**Files involved:**
- `lib/features/practice/presentation/screens/practice_screen.dart:242-259` — dialog result discarded
- `lib/features/practice/presentation/screens/practice_screen.dart:236-240` — subject-level practice
- `lib/features/practice/presentation/screens/practice_session_screen.dart:112-151` — session-level questioning
- `lib/features/practice/presentation/screens/exam_session_screen.dart` — exam mode
- `lib/core/services/topic_readiness_service.dart` — dead code (no production callers)

### Issue 5: Planner Syllabus UI — No Syllabus Document Selection

**Step:** 7 — Planner's syllabus UI

**Root cause:** The multi-syllabus form has a subject picker dropdown, topic count preview, and validation — but no way to select a specific syllabus document from the content library to base the plan on. The plan is generated purely from topic lists, not from a syllabus document's structured outline.

**What needs to change:** Consider adding a syllabus document picker to the multi-syllabus form so the user can select which uploaded source (PDF, etc.) represents the official syllabus for this subject. This would also help with the syllabus completion tracking issue.

**Files involved:**
- `lib/features/planner/presentation/planner_screen.dart:726-842` — multi-syllabus input form
- `lib/features/planner/services/personal_learning_plan_service.dart:176-261` — plan generation

---

## Summary of Work Items

| Priority | Area | Effort | Key Files |
|---|---|---|---|
| **HIGH** | Syllabus PDF → topic auto-creation | Medium | `content_pipeline.dart`, `upload_screen.dart` |
| **HIGH** | Syllabus completion percentage tracking | Medium | `personal_learning_plan_model.dart`, `personal_learning_plan_service.dart`, new UI component |
| **HIGH** | Fix `subject_plans` metadata write | Small | `personal_learning_plan_service.dart:236-240` |
| **MEDIUM** | Fix practice prerequisite dialog bug | Small | `practice_screen.dart:258` |
| **MEDIUM** | Add prereq checking to remaining practice entry points | Medium | `practice_screen.dart`, `practice_session_screen.dart` |
| **LOW** | Syllabus document selection in planner | Small | `planner_screen.dart:726-842` |
| **LOW** | Wire up or remove TopicReadinessService | Small | `topic_readiness_service.dart` |
