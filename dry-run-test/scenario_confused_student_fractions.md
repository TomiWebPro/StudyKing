# Scenario: Confused student asks for repeated explanations (fractions)

**Persona:** Student struggling with a concept, asks for different explanations

## Goal

> "I don't get fractions. Explain differently." (×3)
> The student asks the AI tutor to explain a concept three different ways
> because the first explanations were not understood.

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student says "I don't get fractions" during a teaching session | The tutor should detect the confusion, ask a follow-up question ("Can you tell me which part is confusing you?"), and offer a simpler explanation. | `lib/features/teaching/services/tutor_service.dart:59` — TutorService has `_llmAgent` but the teaching prompt does not include a "confusion detection" directive. No retry-different-explanation logic in teaching flow. | FAIL |
| 2. Student says "Explain differently" | The tutor should vary the explanation style: visual/pie-chart, real-world analogy (pizza slices), step-by-step breakdown. The tutor should NOT repeat the same text. | `lib/features/lessons/data/models/lesson_block_model.dart` — `LessonBlockType` supports `text`, `example`, `exercise`, `quiz`, `summary` but no `visual` or `analogy` block type. No mechanism to vary explanation style. | FAIL |
| 3. Student repeats "I still don't get it" after the second explanation | The tutor should escalate: ask the student to show their working, or redirect to a simpler prerequisite topic (e.g., "What is a number?"), or suggest a practice session on the prerequisite. | `lib/features/practice/services/readiness_scorer.dart` — readiness scoring exists but is not invoked during teaching. No escalation logic in `TutorService`. | FAIL |
| 4. After the 3rd attempt, the tutor suggests a different approach | The tutor should suggest: (a) a practice session on basic fractions, (b) switching to a different learning mode (flashcards, video), or (c) asking the student to upload their textbook for custom examples. | `lib/features/mentor/services/tools/create_practice_session_tool.dart` — practice session creation exists, but teaching flow cannot invoke it (separate agent/mode). | FAIL |

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

**Gap:** Teaching mode calls `LlmService.chatStream()` directly and does not use
`AgentLoop`/`ToolRegistry`, so it cannot invoke these tools at runtime. The tools
exist in the agent registry but are not wired into the teaching flow.
→ Tracked by `issues/open/e2e-teaching-missing-context-injection.md` (context injection).

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Conversation history (prior failed explanations) | YES | `lib/core/services/conversation_memory.dart` — ConversationMemory persists history. |
| Current lesson block type being delivered | NO | No context builder for active lesson blocks. |
| Available explanation modalities (text, example, visual, analogy) | NO | Not described in the teaching system prompt. |
| Student's prerequisite mastery gaps | YES (partial) | `lib/features/practice/services/readiness_scorer.dart` — but not injected into teaching context. |
| Uploaded materials relevant to the topic | YES (partial) | `lib/features/mentor/services/mentor_context_builder.dart` — sources loaded but not for teaching. |

**Gap:** Teaching mode does not inject conversation history or explanation
modality options, so the tutor cannot vary its approach.
→ File `issues/open/e2e-teaching-missing-context-injection.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — lesson blocks use `LessonBlockType.text` with localised strings. |
| Actionability (one clear next action) | FAIL — after "I don't get it", there is no clear single next action. The tutor repeats the same explanation. |
| Confirmation discipline | N/A — no schedule changes in this flow. |

## Validation Results

Traced against code at:
`lib/features/teaching/services/tutor_service.dart:59-110`,
`lib/features/lessons/data/models/lesson_block_model.dart` (LessonBlockType),
`lib/features/practice/services/readiness_scorer.dart:16`,
`lib/features/mentor/services/tools/create_practice_session_tool.dart`,
`lib/features/mentor/services/tools/explain_differently_tool.dart`,
`lib/features/mentor/services/tools/suggest_practice_tool.dart`,
`lib/core/data/enums.dart` (LessonBlockType: visual, analogy added).

- Step 1: FAIL — no confusion detection in teaching prompt.
- Step 2: PARTIAL — `LessonBlockType` now has `visual`/`analogy` and `explain_differently`
  tool is registered, but teaching mode bypasses AgentLoop (context injection issue).
- Step 3: PARTIAL — `suggest_practice` tool is registered but teaching mode does not invoke it.
- Step 4: FAIL — teaching mode cannot invoke practice/session tools (bypasses AgentLoop).

Tool audit: 5 of 5 needed tools exist (`explain_differently` and `suggest_practice` registered).
Context audit: teaching context lacks conversation history injection and modality options in system prompt → tracked by `e2e-teaching-missing-context-injection.md`.
