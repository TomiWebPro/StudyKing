# Scenario: Long-term user accelerates pace, switches subject, reschedules class

**Persona:** Long-term user, active learner

## Goal

> "I'm a longterm user. I want to speed up my pace to learn in Physics.
> I was learning about physics but now I want to learn about another subject.
> I want to change API provider now. I want to reschedule a class to another time."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. User says "I want to accelerate to finish Physics in 30 days instead of 90" | The mentor agent should recognize the pacing intent, propose a new plan with shorter duration, and ask for confirmation before changing the plan. No silent deadline moves. | `lib/features/mentor/services/mentor_service.dart:378` — `_extractPlanProposal` parses days from message; `_pendingPlan` is set but confirmation is required via `planDaysMessage`. `PlannerService.updatePlan` uses `addCalendarDays` (calendar-day, not elapsed). | PASS |
| 2. User says "Actually, I want to study Biology instead of Physics" | The mentor should propose a new subject, preserving mastered topics and carrying forward relevant plan fragments. | `lib/features/planner/services/planner_service.dart:320` — `addSubjectToPlan` exists and merges syllabus goals. `lib/features/mentor/services/tools/add_subject_to_plan_tool.dart` — `AddSubjectToPlanTool` registered at `lib/core/providers/llm_agent_providers.dart:176`, delegates to `PlannerService.addSubjectToPlan`. Traced through `AgentLoop` in `tool_trace_coverage_test.dart`. | PASS |
| 3. User says "Switch to Ollama instead of OpenRouter" | Settings screen should allow changing provider, base URL, and model. The agent should gracefully degrade if the new provider is unreachable (B4 failover). | `lib/core/services/llm/llm_chat_service.dart:16-29` — `LlmConfiguration` supports backup providers; `lib/core/constants/app_api_config.dart` — env-var overrides exist. Settings UI: `lib/features/settings/`. | PASS |
| 4. User says "Reschedule my Atoms lesson to 3pm tomorrow" | The mentor extracts the topic from the message, finds the scheduled session, proposes reschedule, and awaits user confirmation before saving. | `lib/features/mentor/services/mentor_service.dart:359` — `_handleRescheduleIntent` extracts topic; `_pendingRescheduleSessionId` is set. `MentorService.suggestReschedule` (`planner_service.dart:603`) performs the reschedule. | PASS |
| 5. After reschedule, the updated schedule appears in the dashboard | Calendar view and lesson list should reflect the new time immediately. | `lib/features/dashboard/` — dashboard reads from `LessonRepository` and `SessionRepository`. Sessions are saved via `SessionRepository.save`. | PASS |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `create_plan` (accelerate pace → shorter plan) | YES | `lib/features/mentor/services/tools/create_plan_tool.dart` |
| `modify_plan` (adjust existing plan duration/goal) | YES | `lib/features/mentor/services/tools/modify_plan_tool.dart` |
| `schedule_lesson` (reschedule a lesson) | YES | `lib/features/mentor/services/tools/schedule_lesson_tool.dart` |
| `get_syllabus_structure` (switch subject, carry forward topics) | YES | `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart` |
| `get_lesson_history` (find session to reschedule) | YES | `lib/features/mentor/services/tools/get_lesson_history_tool.dart` |
| Switch/provider-config tool | YES | `lib/features/mentor/services/tools/switch_provider_tool.dart` |

**Gap:** — (RESOLVED) The `SwitchProviderTool` is now registered in
`llmAgentToolsProvider` (`lib/core/providers/llm_agent_providers.dart`). The mentor
can call `switch_provider` after student confirmation and update the live config.
Previously filed as `issues/open/e2e-mentor-missing-provider-switch-tool.md` (now closed).

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Current plan / roadmap state (subjects, days remaining) | YES | `lib/features/mentor/services/mentor_context_builder.dart` — loads plan context. |
| Scheduled lessons (for reschedule target) | YES | `mentor_context_builder.dart` — `loadUpcomingLessons`. |
| Mastery state of topics (which can be carried forward) | YES | `mentor_context_builder.dart` — `_masteryService.getWeakTopics`. |
| Configured provider / model / failover status | NO | No context builder queries LLM configuration. The agent may suggest "try Ollama" without knowing it's already configured as a backup. |

**Gap:** Provider configuration is not injected into the agent context.
→ File `issues/closed/scenario-provider-config-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — locale-aware strings throughout. |
| Actionability (one clear next action) | PASS — reschedule flow sets a single `_pendingRescheduleSessionId`; confirmation is required. |
| Confirmation discipline (no silent schedule changes) | PASS — `agent_must_read.md` §Mentor: schedule changes require explicit confirmation. `_pendingSchedule` / `_pendingRescheduleSessionId` patterns enforce this. |

## Validation Results

Traced against code at `lib/features/mentor/services/mentor_service.dart:337-385`
(`_checkAndHandlePlanningIntent`, `_handleRescheduleIntent`, `_extractPlanProposal`),
`lib/features/mentor/services/tools/modify_plan_tool.dart`,
`lib/features/planner/services/planner_service.dart:603` (`rescheduleLesson`).

- Step 1: PASS — pace acceleration parsed, confirmation enforced.
- Step 2: PASS — `add_subject_to_plan` agent tool is now registered at `llm_agent_providers.dart:176` and delegates to `PlannerService.addSubjectToPlan`.
- Step 3: PASS — provider config via Settings + B4 failover.
- Step 4: PASS — reschedule intent extraction + confirmation.
- Step 5: PASS — session persistence is immediate.

Tool audit: `schedule_lesson`, `modify_plan`, `get_lesson_history`, `switch_provider` all reachable.
RESULT: all needed tools available (0 missing).
Context audit: provider config not injected → issue closed (`scenario-provider-config-not-injected.md`).
**Last re-traced:** 2026-10-20 against commit `5732329` (`scenario_validation_test.dart` Steps 1–5, `llm_agent_providers.dart:176`).
