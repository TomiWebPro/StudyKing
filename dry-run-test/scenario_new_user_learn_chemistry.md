# Scenario: New user learns IB Chemistry in 90 days, no materials

**Persona:** New user, first launch

## Goal

> "I'm a new user opening StudyKing for the first time. I want to learn IB
> Chemistry in 90 days. I don't know what this program is about or what it
> can do."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. On first launch, does the app explain itself or just show a blank screen? | App should show a welcome / onboarding flow that explains the AI-native tutoring and planning features before showing the main dashboard. | `lib/features/onboarding/` — onboarding exists but may not mention AI mentor or ailab grant. | PARTIAL |
| 2. Does it nudge me to upload content (PDFs, notes, question banks), or do I have to hunt for the feature? | A first-run coach should ask: "Upload your syllabus, textbook, or notes to get personalised lessons." The upload should be a prominent first action. | `lib/features/ingestion/` — ingestion exists but first-run nudge is not wired. | FAIL |
| 3. Can I just tell the planner "I want to learn IB Chemistry in 90 days" and have everything generated automatically? | Typing or speaking this utterance should trigger [CreatePlanTool] → PlannerService.generatePlan → plan saved → roadmap created. No manual subject/topic entry required. | `lib/features/mentor/services/tools/create_plan_tool.dart:37` — tool exists; `lib/features/planner/services/planner_service.dart:241` — generatePlan exists. AgentLoop wiring: `lib/core/providers/llm_agent_providers.dart:86` (returns null when apiKey empty). | PARTIAL |
| 4. Are lesson plans, lesson content, and practice questions auto-generated from the syllabus? | After plan creation, off-period prep should generate lesson blocks and question variants. `GenerateLessonBlocksTool` should be callable from the agent. | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart:6` — tool exists and is registered. `test/integration/agentic_e2e/tool_trace_coverage_test.dart:548` traces `GenerateLessonBlocksTool` end-to-end through `AgentLoop` with a `FakeLessonAgentServicePrep` in fake mode (no real LLM call). `registeredToolNames` count assertion at `tool_trace_coverage_test.dart:2176` confirms 27 tools including `generate_lesson_blocks`. | PASS |
| 5. Does the system detect missing materials and guide me to fix that? | If no syllabus is uploaded, the agent should ask: "I don't have your IB Chemistry syllabus yet — would you like to upload it or shall I use a standard curriculum?" | `lib/features/mentor/services/mentor_service.dart:146` — `hasMeaningfulData()` detects no subjects but returns a generic "no subjects" message, not a syllabus-guided prompt. | FAIL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `create_plan` (create a study plan from a natural-language goal) | YES | `lib/features/mentor/services/tools/create_plan_tool.dart` |
| `get_syllabus_structure` (extract syllabus from uploaded materials) | YES | `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart` |
| `generate_lesson_blocks` (generate lesson content blocks) | YES | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` |
| `search_questions` (search question bank by topic) | YES | `lib/features/mentor/services/tools/search_questions_tool.dart` |
| `get_weak_topics` (identify weak areas) | YES | `lib/features/mentor/services/tools/get_weak_topics_tool.dart` |
| `schedule_lesson` (book a lesson slot) | YES | `lib/features/mentor/services/tools/schedule_lesson_tool.dart` |
| `get_student_stats` (overall progress stats) | YES | `lib/features/mentor/services/tools/get_student_stats_tool.dart` |

All six mentor tools exist and are registered in `llmAgentToolsProvider`
(`lib/core/providers/llm_agent_providers.dart:45-83`). The gap is **context
injection** — the AgentLoop system prompt does not inform the LLM about
missing materials, so it cannot proactively ask the student to upload them.

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Student profile (grade level, goals, subjects) | PARTIAL | `lib/features/llm_agent/agent_memory.dart` — AgentMemoryStore exists but is not populated on first launch. |
| Uploaded materials list (syllabus, textbooks, notes) | NO | No context-builder for ingestion state. MentorContextBuilder (`lib/features/mentor/services/mentor_context_builder.dart`) does not query ingestion state. |
| Mastery graph weak topics | YES (when API key set) | `lib/features/mentor/services/mentor_context_builder.dart` — calls `_masteryService.getWeakTopics`. |
| Existing plan / roadmap status | PARTIAL | `lib/features/mentor/services/mentor_context_builder.dart` — loads upcoming lessons and plan context but not ingestion state. |

**Gap:** AgentLoop system prompt does not inject a "missing materials" check.
Context audit: missing "uploaded materials" context injection → `issues/closed/scenario-new-user-missing-materials-nudge.md`.

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `lookupAppLocalizations` localised strings keep language at ~6th-grade level. |
| Actionability (one clear next action) | FAIL — first-run flow does not present exactly one next action; user faces multiple unlabelled entry points. |
| Confirmation discipline (no silent schedule changes) | PASS — `agent_must_read.md` §Mentor requires explicit confirmation; `MentorService.chat` sets `_pendingSchedule` / `_pendingPlan` and awaits confirmation. |

## Validation Results

Traced against code at `lib/features/onboarding/`, `lib/features/ingestion/`,
`lib/features/mentor/services/tools/create_plan_tool.dart:37`,
`lib/features/planner/services/planner_service.dart:241`,
`lib/core/providers/llm_agent_providers.dart:86-101`.

- Step 1: PARTIAL — onboarding exists but does not mention AI mentor or grant model.
- Step 2: FAIL — no first-run nudge to upload syllabus/textbook.
- Step 3: PARTIAL — CreatePlanTool is wired but `llmAgentProvider` returns `null` when `apiKey` is empty (line 92), so the agent path is unreachable without API config.
- Step 4: PASS — `GenerateLessonBlocksTool` is registered and traced through `AgentLoop` in `tool_trace_coverage_test.dart:548` (fake mode with `FakeLessonAgentServicePrep`).
- Step 5: FAIL — `hasMeaningfulData()` returns a generic message, not a syllabus-guided prompt.

Tool audit: all 6 mentor tools exist and are registered. No missing-tools issue.
**Last re-traced:** 2026-10-20 against commit `5732329` (`scenario_validation_test.dart` Steps 1–5, `tool_trace_coverage_test.dart:2171-2176`).
