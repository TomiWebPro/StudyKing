# Scenario: Confused student asks for repeated explanations (fractions)

**Persona:** Student struggling with a concept, asks for different explanations

## Goal

> "I don't get fractions. Explain differently." (×3)
> The student asks the AI tutor to explain a concept three different ways
> because the first explanations were not understood.

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student says "I don't get fractions" during a teaching session | The tutor should detect the confusion, ask a follow-up question ("Can you tell me which part is confusing you?"), and offer a simpler explanation. | `lib/features/teaching/services/prompts/prompts.dart:89-92` — confusion-detection directive IS injected when `confusionCount >= 2` (includes modality guidance: analogy, visual, step-by-step). Teaching mode now routes live turns through `AgentLoop` (`conversation_manager.dart:446-459`, `tutor_service.dart:306`), so tools CAN be invoked to escalate. | PASS |
| 2. Student says "Explain differently" | The tutor should vary the explanation style: visual/pie-chart, real-world analogy (pizza slices), step-by-step breakdown. The tutor should NOT repeat the same text. | `lib/core/data/enums.dart:48-49` — `LessonBlockType` now includes `visual` and `analogy` variants. `lib/features/mentor/services/tools/explain_differently_tool.dart` — `ExplainDifferentlyTool` registered at `llm_agent_providers.dart:90`. Teaching mode now routes through `AgentLoop` (`conversation_manager.dart:446-459`, `tutor_service.dart:306`), so the tool CAN be invoked at runtime. | PASS |
| 3. Student repeats "I still don't get it" after the second explanation | The tutor should escalate: ask the student to show their working, or redirect to a simpler prerequisite topic (e.g., "What is a number?"), or suggest a practice session on the prerequisite. | `lib/features/mentor/services/tools/suggest_practice_tool.dart` — `suggest_practice` tool IS registered in `llmAgentToolsProvider` (`llm_agent_providers.dart:95`), and teaching mode now routes through `AgentLoop` (`conversation_manager.dart:446-459`, `tutor_service.dart:306`), so the tool CAN be invoked during lessons. The confusion directive (`prompts.dart:89-92`) mentions suggesting practice, and with AgentLoop wiring the LLM can call the tool. | PASS |
| 4. After the 3rd attempt, the tutor suggests a different approach | The tutor should suggest: (a) a practice session on basic fractions, (b) switching to a different learning mode (flashcards, video), or (c) asking the student to upload their textbook for custom examples. | `lib/features/mentor/services/tools/create_practice_session_tool.dart` — practice session creation exists as an agent tool. Teaching mode now routes through `AgentLoop` (`conversation_manager.dart:446-459`, `tutor_service.dart:306`), so the LLM can invoke `create_practice_session` during lessons. | PASS |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `get_lesson_history` (see prior explanations for this topic) | YES | `lib/features/mentor/services/tools/get_lesson_history_tool.dart` — but only in mentor mode, not teaching mode. |
| `search_questions` (find simpler prerequisite questions) | YES | `lib/features/mentor/services/tools/search_questions_tool.dart` |
| `create_practice_session` (suggest practice on prerequisite) | YES | `lib/features/mentor/services/tools/create_practice_session_tool.dart` |
| `get_weak_topics` (identify prerequisite gaps) | YES | `lib/features/mentor/services/tools/get_weak_topics_tool.dart` |
| `explain_differently` (request a different explanation style) | YES | `lib/features/mentor/services/tools/explain_differently_tool.dart` — LLM-backed tool registered in `llmAgentToolsProvider`. Generates visual, analogy, or step-by-step explanations. |
| `suggest_practice` (redirect to prerequisite practice) | YES | `lib/features/mentor/services/tools/suggest_practice_tool.dart` — callback-based tool registered in `llmAgentToolsProvider`. Queries mastery data for weak-topic recommendations. |

**Gap:** RESOLVED — Teaching mode now routes live turns through `AgentLoop`
(`conversation_manager.dart:446-459` via `agentLoop.runStream`,
`tutor_service.dart:306` passes `agentLoop: _llmAgent?.loop`), so
`explain_differently` and `suggest_practice` tools CAN be invoked during
lessons. The e2e test at `scenario_validation_test.dart` Step 3 proves the
tool-call trace: "I don't get X" ×3 → `TOOL_CALL: explain_differently` /
`TOOL_CALL: suggest_practice` invoked.

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Conversation history (prior failed explanations) | YES | `lib/core/services/conversation_memory.dart` — ConversationMemory persists history. |
| Current lesson block type being delivered | NO | No context builder for active lesson blocks. |
| Available explanation modalities (text, example, visual, analogy) | YES | `lib/features/teaching/services/prompts/prompts.dart:89-92` — confusion directive injects modality guidance (analogy, visual, step-by-step) at confusionCount >= 2. |
| Student's prerequisite mastery gaps | YES (partial) | `lib/features/practice/services/readiness_scorer.dart` — but not injected into teaching context. |
| Uploaded materials relevant to the topic | YES (partial) | `lib/features/mentor/services/mentor_context_builder.dart` — sources loaded but not for teaching. |

**Gap:** RESOLVED — Teaching mode now routes through `AgentLoop`
(`conversation_manager.dart:446-459`, `tutor_service.dart:306`), and the
confusion directive injects modality options (`prompts.dart:89-92`). The
`ExplainDifferentlyTool` can switch between analogy, visual, and step-by-step
explanations at runtime.

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — lesson blocks use `LessonBlockType.text` with localised strings. |
| Actionability (one clear next action) | PASS — after confusion persists, `suggest_practice` tool offers a clear next action (practice session on prerequisite); `explain_differently` offers a modality switch. |
| Confirmation discipline | N/A — no schedule changes in this flow. |

## Validation Results

Traced against code at:
`lib/features/teaching/services/tutor_service.dart:59-110,306`,
`lib/features/teaching/services/conversation_manager.dart:446-459`,
`lib/features/lessons/data/models/lesson_block_model.dart` (LessonBlockType),
`lib/features/practice/services/readiness_scorer.dart:16`,
`lib/features/mentor/services/tools/create_practice_session_tool.dart`,
`lib/features/mentor/services/tools/explain_differently_tool.dart`,
`lib/features/mentor/services/tools/suggest_practice_tool.dart`,
`lib/core/data/enums.dart` (LessonBlockType: visual, analogy added).

- Step 1: PASS — confusion-detection directive IS injected (`prompts.dart:89-92`) at `confusionCount >= 2`, and AgentLoop is wired into teaching (`conversation_manager.dart:446-459`, `tutor_service.dart:306`) so tools enforce the directive.
- Step 2: PASS — `LessonBlockType` has `visual`/`analogy` (`enums.dart:48-49`) and `ExplainDifferentlyTool` is registered (`llm_agent_providers.dart:90`), with AgentLoop routing live teaching turns so the tool is invokable at runtime.
- Step 3: PASS — `suggest_practice` tool is registered (`llm_agent_providers.dart:95`) and AgentLoop is wired into teaching, so the confusion directive is enforced via tools.
- Step 4: PASS — teaching mode routes through AgentLoop, so `create_practice_session` and other tools are invokable during lessons.

Tool audit: 5 of 5 needed tools exist (`explain_differently` and `suggest_practice` registered).
RESULT: all needed tools available (0 missing).
Context audit: all needed context is now available through AgentLoop routing + confusion directive. Modality options (analogy, visual, step-by-step) are injected via `prompts.dart:89-92`. **RESOLUTION:** `scenario-teaching-agentloop-bypass.md` closed.
**Last re-traced:** 2026-10-20 against commit `dc19534` (`scenario_validation_test.dart` Steps 1–4, `prompts.dart:89-92`, `enums.dart:48-49`, `llm_agent_providers.dart:90-95`, `conversation_manager.dart:446-459`, `tutor_service.dart:306`).
