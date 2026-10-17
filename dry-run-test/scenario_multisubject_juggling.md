# Scenario: Long-term user juggling multiple syllabi (Physics + Chemistry + Math)

**Persona:** Student studying multiple subjects simultaneously

## Goal

> "I'm studying IB Physics, IB Chemistry, and Math AA HL at the same time.
> My plan shows all three syllabi with remaining days for each. When I ask
> about a specific topic, the mentor knows which syllabus I'm referring to.
> I can switch focus between subjects, and the dashboard shows my progress
> across all three without mixing them up."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student has multiple syllabi in their plan | The mentor should recognise multiple syllabi and summarise remaining days per subject. | `lib/features/planner/data/models/personal_learning_plan_model.dart:1` — `SyllabusGoal` list. `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart:9` — `GetSyllabusStructureTool` registered (`llp_agent_providers.dart:95-101`). `lib/features/mentor/services/tools/modify_plan_tool.dart:9` — `ModifyPlanTool` registered. | PASS |
| 2. Student asks "How's my Chemistry progress?" | The mentor should resolve "Chemistry" to the right syllabus and report progress without confusion from other subjects. | `lib/features/mentor/services/mentor_context_builder.dart:285-336` — `_buildSyllabusContext` resolves the active syllabus from upcoming lessons or single-goal state. Resolves by `subjectId` mapping. Multi-syllabus ambiguity is surfaced as a notice. | PASS |
| 3. Student says "Switch my focus to Math for the next 2 weeks" | The mentor should adjust the plan's pacing for Math, preserving Physics and Chemistry schedules. Requires confirmation. | `lib/features/mentor/services/tools/modify_plan_tool.dart:9` — `ModifyPlanTool` can adjust duration. `MentorService._pendingPlan` enforces confirmation (`mentor_service.dart:359-370`). `PlannerService.updatePlan` (`planner_service.dart:241`) uses calendar days. | PARTIAL |
| 4. Student schedules a lesson on "Atoms" and a lesson on "Quanta" | Each lesson should land under the correct subject with no cross-contamination. | `lib/features/mentor/services/tools/schedule_lesson_tool.dart:9` — `ScheduleLessonTool` registered (`llp_agent_providers.dart:64`). Requires `subjectId` arg. No syllabus-aware scheduling guidance in the tool description. | PARTIAL |
| 5. Dashboard shows progress per subject | The dashboard should show accuracy, streak, and mastery per subject, not aggregated. | `lib/features/dashboard/` — dashboard reads from `LessonRepository` and `SessionRepository`. `lib/core/services/study_progress_tracker.dart:1` aggregates stats. Multi-subject breakdown is limited in the current dashboard summary. `vision-multi-subject-navigation-juggling-hard.md` — open issue. | PARTIAL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `get_syllabus_structure` (list all syllabi) | YES | `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart` |
| `create_plan` (add a new subject to the plan) | YES | `lib/features/mentor/services/tools/create_plan_tool.dart` |
| `modify_plan` (adjust pacing for a specific syllabus) | YES | `lib/features/mentor/services/tools/modify_plan_tool.dart` |
| `schedule_lesson` (book under the correct subject) | YES | `lib/features/mentor/services/tools/schedule_lesson_tool.dart` |
| `get_student_stats` (per-subject progress breakdown) | YES | `lib/features/mentor/services/tools/get_student_stats_tool.dart` |
| `switch_syllabus_focus` (set active syllabus for upcoming scheduling) | YES | `lib/features/mentor/services/tools/switch_syllabus_focus_tool.dart` |

**Gap:** No `switch_syllabus_focus` agent tool — the mentor cannot explicitly set which syllabus is "active" for subsequent tool calls.
→ File `issues/open/e2e-mentor-missing-switch-syllabus-focus-tool.md`

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Active syllabus identification (which subject the student means) | YES (partial) | `mentor_context_builder.dart:302-336` — `_buildSyllabusContext` resolves from upcoming lessons or single goal. Multi-goal ambiguity surfaces a notice but no explicit "active" flag. |
| Per-subject mastery (weak topics per subject) | YES | `get_weak_topics_tool.dart:9` — can be scoped by `subjectId`. `mastery_graph_service.dart` tracks per-topic mastery. |
| Per-subject study time / streak | PARTIAL | `mentor_context_builder.dart:202-208` injects today's study time but not per-subject breakdown. `get_student_stats_tool.dart:9` surfaces aggregate stats. |
| Daily study cap adherence per subject | NO | `adherence` is tracked at the plan level, not per-subject. No per-subject cap injection. |

**Gap:** No per-subject study time / daily cap context injected into mentor prompt.
→ File `issues/open/scenario-multisubject-context-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — multi-subject labels use `l10n` with subject titles. |
| Actionability (one clear next action) | PARTIAL — after identifying multiple syllabi, the mentor does not present one clear next action; instead lists options. |
| Confirmation discipline (no silent schedule changes) | PASS — `ModifyPlanTool` + `_pendingPlan` enforces confirmation (`mentor_service.dart:359`). |

## Validation Results

Traced against code at:
`lib/features/mentor/services/mentor_context_builder.dart:285-336`,
`lib/features/mentor/services/tools/modify_plan_tool.dart:9`,
`lib/features/planner/data/models/personal_learning_plan_model.dart:1`,
`lib/features/dashboard/` (dashboard widgets reading from repositories).

- Step 1: PASS — `GetSyllabusStructureTool` + `ModifyPlanTool` are registered and reachable.
- Step 2: PASS — syllabus context resolves from upcoming lessons; ambiguity is surfaced.
- Step 3: PARTIAL — planning works but pacing per-subject may not be intuitive.
- Step 4: PARTIAL — scheduling works but no subject-aware guidance in tool description.
- Step 5: PARTIAL — dashboard aggregates; per-subject breakdown is limited.

Tool audit: 5 of 6 needed tools exist; `switch_syllabus_focus` is missing.
Context audit: per-subject study time and daily cap not injected → new issues filed.
