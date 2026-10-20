# Scenario: Overworked student (late-night, streak break, wellbeing nudge)

**Persona:** Student who studies late, risks burnout

## Goal

> "I've been studying every night until 2am. My streak is about to break
> because I'm exhausted. I need a wellbeing nudge, not another lesson."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student studies past 22:00 on multiple days | The system should detect late-night sessions and generate a wellbeing nudge: "You've been studying past 10pm a lot lately. Consider taking a break to protect your sleep." | `lib/features/mentor/services/mentor_wellbeing_service.dart` — `_checkLateNightSessions` exists. `lib/features/mentor/services/mentor_service.dart:15` — `checkWellbeingAndGenerateNudges()` is called proactively. | PASS |
| 2. Student has a streak at risk of breaking | The system should send a gentle streak-reminder, not a guilt-trip: "Your 7-day streak is in reach — you can continue tomorrow or take a scheduled rest day." | `lib/features/dashboard/` — streak tracking exists in dashboard. No dedicated streak-preservation nudge in `EngagementNudgeModel`. | PARTIAL |
| 3. Student opens the mentor and says "I'm exhausted" | The mentor should empathize, review recent study logs, and suggest: "You studied X hours last night. Let's reschedule tomorrow's lesson to 11am and set a bedtime reminder." | `lib/features/mentor/services/mentor_service.dart:158` — `chat()` routes to `_agent?.chat()` when agent is configured. No wellbeing-specific prompt branch. System prompt is from `l10n.mentorSystemPrompt`. | PARTIAL |
| 4. Student's session data shows >3 hours/day for 5+ days | System should recommend an automatic rest day: "Your study load has been high. I've scheduled a rest day for you tomorrow — confirm or adjust." Must require confirmation (no silent schedule change). | `schedule_rest_day_tool.dart` — `ScheduleRestDayTool` registered at `llm_agent_providers.dart:136`. `PlannerService.markRestDay()` exists. Agent calls tool after student confirms (non-silent). `wellbeing_adjust_schedule_tool.dart` — `WellbeingAdjustScheduleTool` registered at `llm_agent_providers.dart:137`. Both traced through `AgentLoop` in `tool_trace_coverage_test.dart`. | PASS |
| 5. Student on a low-end device with battery < 20% | Heavy prep tasks (question generation, embeddings) should pause. A notification: "Background prep paused — battery low. Will resume when charging." | `system_monitor_service.dart:20` — `SystemMonitorService` implemented with `canRunHeavyPrepNow`, battery/CPU/load-avg reads; wired at `llm_providers.dart:28`. `IdleExecutor` defers heavy tasks when false. | PASS |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `get_student_stats` (study volume, session times) | YES | `lib/features/mentor/services/tools/get_student_stats_tool.dart` |
| `get_weak_topics` (if overwork is affecting mastery) | YES | `lib/features/mentor/services/tools/get_weak_topics_tool.dart` |
| `schedule_lesson` (reschedule to a gentler time) | YES | `lib/features/mentor/services/tools/schedule_lesson_tool.dart` |
| `schedule_rest_day` (rest-day scheduling, requires confirmation) | YES | `lib/features/mentor/services/tools/schedule_rest_day_tool.dart` |
| `wellbeing_adjust_schedule` (bedtime/break/pacing reminders) | YES | `lib/features/mentor/services/tools/wellbeing_adjust_schedule_tool.dart` — registered at `llm_agent_providers.dart:137`. |

Both tools are now traced through `AgentLoop` with real-implementation e2e
tests in `test/integration/agentic_e2e/tool_trace_coverage_test.dart`
(`ScheduleRestDayTool` and `WellbeingAdjustScheduleTool` groups), covering
happy-path + validation-failure paths (invalid date string, invalid reminder
type, invalid time format).

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Recent session start/end times (for late-night detection) | YES | `lib/features/mentor/services/mentor_context_builder.dart:49` — `loadSessionSummary` provides session data. |
| Streak count and streak risk status | NO | Streak data is in the dashboard but not injected into mentor context. |
| Battery level and charging status | PARTIAL | `system_monitor_service.dart:20` — `SystemMonitorService` exists with battery/CPU reads, but not injected into mentor context prompt. |
| Student self-reported wellbeing (fatigue level) | NO | No wellbeing input mechanism in mentor chat. |

**Gap:** Streak status and self-reported wellbeing are not injected into
the mentor agent's context.
→ File `issues/closed/scenario-wellbeing-context-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `l10n` strings used for nudge messages. |
| Actionability (one clear next action) | PARTIAL — wellbeing nudge exists but does not offer "reschedule with confirmation" as a single next action. |
| Confirmation discipline (no silent schedule changes) | PASS — `agent_must_read.md` §Mentor: schedule changes require explicit confirmation. `MentorService._pendingSchedule` enforces this. |

## Validation Results

Traced against code at:
`lib/features/mentor/services/mentor_wellbeing_service.dart` (full file),
`lib/features/mentor/services/mentor_service.dart:387-404` (`checkWellbeingAndGenerateNudges`),
`lib/features/planner/services/planner_service.dart:520-560` (`scheduleLesson`),
`lib/core/data/models/session_model.dart:17` (`SessionType.tutoring`, start/end times),
`lib/features/dashboard/` (streak tracking).

- Step 1: PASS — late-night session detection + nudge generation.
- Step 2: PARTIAL — streak exists in dashboard, no streak-preservation nudge.
- Step 3: PARTIAL — mentor can respond but no wellbeing-specific branching.
- Step 4: PASS — `schedule_rest_day` and `wellbeing_adjust_schedule` tools
  are registered and have real-implementation e2e traces through `AgentLoop`
  in `tool_trace_coverage_test.dart` (happy path + validation-failure paths:
  invalid date string, invalid reminder type, invalid time format).
- Step 5: PASS — `SystemMonitorService` is implemented
  (`system_monitor_service.dart:20`) and wired into the provider tree
  (`llm_providers.dart:28`); `IdleExecutor` defers heavy prep when
  `canRunHeavyPrepNow` is false.

Tool audit: 5 of 5 needed tools exist (including `wellbeing_adjust_schedule`).
RESULT: all needed tools available (0 missing).
Context audit: streak + wellbeing input not injected → issue closed.
**Last re-traced:** 2026-10-20 against commit `5732329` (`scenario_validation_test.dart` Steps 1–5, `system_monitor_service.dart:20`, `mentor_wellbeing_service.dart`).
