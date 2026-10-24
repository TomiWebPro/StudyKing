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
| 3. Student says "Switch my focus to Math for the next 2 weeks" | The mentor should adjust the plan's pacing for Math, preserving Physics and Chemistry schedules. Requires confirmation. | `lib/features/mentor/services/tools/switch_syllabus_focus_tool.dart:20` — `SwitchSyllabusFocusTool` sets the active syllabus focus. `lib/features/mentor/services/tools/modify_plan_tool.dart:9` — `ModifyPlanTool` can adjust duration. `MentorService._pendingPlan` enforces confirmation (`mentor_service.dart:359-370`). `PlannerService.updatePlan` (`planner_service.dart:241`) uses calendar days. | PARTIAL |
| 4. Student schedules a lesson on "Atoms" and a lesson on "Quanta" | Each lesson should land under the correct subject with no cross-contamination. | `lib/features/mentor/services/tools/schedule_lesson_tool.dart:9` — `ScheduleLessonTool` registered (`llp_agent_providers.dart:64`). Requires `subjectId` arg. No syllabus-aware scheduling guidance in the tool description. | PARTIAL |
| 5. Dashboard shows progress per subject | The dashboard should show accuracy, streak, and mastery per subject, not aggregated. | `lib/features/dashboard/` — dashboard reads from `LessonRepository` and `SessionRepository`. `lib/core/services/study_progress_tracker.dart:1` aggregates stats. Multi-subject breakdown is limited in the current dashboard summary. → File `issues/open/scenario-multisubject-study-time-not-injected.md` | PARTIAL |

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

**Gap (RESOLVED):** `switch_syllabus_focus` is now registered in `llmAgentToolsProvider` and
reachable through AgentLoop (see `tool_trace_coverage_test.dart:SwitchSyllabusFocusTool`). The
mentor can explicitly set the active syllabus via conversation, and `MentorContextBuilder`
honors the explicit focus over implicit upcoming-lesson resolution (verified in
`test/features/mentor/services/tools/switch_syllabus_focus_tool_test.dart`).
→ Issue `e2e-switch-syllabus-focus-tool-missing.md` closed.

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Active syllabus identification (which subject the student means) | YES | `mentor_context_builder.dart:302-336` — `_buildSyllabusContext` resolves from upcoming lessons or single goal. `SwitchSyllabusFocusTool` sets an explicit focus that overrides implicit resolution (verified in unit test `switch_syllabus_focus_tool_test.dart:247-265`). |
| Per-subject mastery (weak topics per subject) | YES | `get_weak_topics_tool.dart:9` — can be scoped by `subjectId`. `mastery_graph_service.dart` tracks per-topic mastery. |
| Per-subject study time / streak | PASS | `mentor_context_builder.dart:346-377` — `_getTodayStudyMinutesBySubject()` feeds a sorted per-subject breakdown with cap-percentage annotations ("Physics: 45 min (50% of 90-min daily cap)"). Unit tests: `mentor_context_builder_test.dart:920-1003`. Integration test: `test/integration/per_subject_study_time_integration_test.dart`. |
| Daily study cap adherence per subject | PASS | Each subject line includes cap percentage (`sharePct = mins/dailyCap * 100`). The total-time line above it also shows "cap exceeded" or "cap remaining" when the global cap is breached. `mentor_context_builder.dart:337-344, 351-377`. |

**Gap (RESOLVED):** Per-subject study time with cap-percentage is now injected into the mentor prompt via `MentorContextBuilder._getTodayStudyMinutesBySubject()` (`mentor_context_builder.dart:351-377`). The agent can answer "How much time did I spend on each subject today?" and "Which subject consumed the most of my daily cap?". Issue `scenario-multisubject-study-time-not-injected.md` resolved.

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
- Step 3: PARTIAL — `switch_syllabus_focus` tool now registered (focus can be set explicitly), but pacing per-subject may not be intuitive.
- Step 4: PARTIAL — scheduling works but no subject-aware guidance in tool description.
- Step 5: PASS — per-subject study time with cap-percentage IS injected into mentor prompt (`mentor_context_builder.dart:351-377`). Per-subject breakdown sorted descending by usage, with each line annotated as "X min (Y% of Z-min daily cap)". Unit tests cover breakdown, fallback, empty-case; integration test validates full flow.

Tool audit: 6 of 6 needed tools exist; `switch_syllabus_focus` is FOUND (registered + traced).
RESULT: all needed tools available (0 missing).
Context audit: per-subject study time AND cap adherence NOW injected → issue resolved (`scenario-multisubject-study-time-not-injected.md` CLOSED).
**Last re-traced:** 2026-10-24 against merged changes for per-subject study time injection.
