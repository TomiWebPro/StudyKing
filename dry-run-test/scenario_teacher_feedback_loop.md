# Scenario: Teaching feedback loop — student says "too fast", system adapts

**Persona:** Student in a live teaching session

## Goal

> "I told the tutor 'this is too fast,' and it slowed down, broke the concept
> into smaller steps, and gave me a simpler example. When I got a question
> wrong, it asked what part confused me and redirected to a prerequisite.
> After the lesson, it summarised what I mastered and what to review."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student says "this is too fast" mid-lesson | The tutor should detect the pacing feedback, slow down, and offer a more granular explanation or simpler example. | `lib/features/teaching/services/tutor_service.dart:59` — TutorService holds `_llmAgent`. `lib/features/teaching/services/prompts/prompts.dart:70-89` — `buildTutorPrompt` injects `feedbackContext` but it is not populated from student utterances "too fast/slow". | PARTIAL |
| 2. Tutor offers a simpler explanation | The system should vary explanation style (visual, real-world analogy, step-by-step). | `lib/features/lessons/data/models/lesson_block_model.dart:1` — `LessonBlockType` supports `text`, `example`, `exercise`, `quiz`, `summary` but no `visual` or `analogy`. `dry-run-test/scenario_confused_student_fractions.md:step2` — no variation mechanism. `e2e-teaching-missing-explanation-variation-tool.md` — missing tool. | FAIL |
| 3. Student gets a question wrong during practice | The tutor should ask "which part confused you?" and redirect to a prerequisite topic or simpler question. | `lib/features/practice/services/readiness_scorer.dart:16` — readiness scoring exists. `lib/features/mentor/services/tools/get_weak_topics_tool.dart:9` — identifies weak areas. But the **teaching** flow (`tutor_service.dart`) does not invoke readiness scoring during lessons. | FAIL |
| 4. After lesson, system summarises mastery | The mentor should show what was mastered, what needs review, and schedule a follow-up if needed. | `lib/core/services/study_progress_tracker.dart:1` — tracks attempts/sessions. `lib/core/data/models/mastery_state_model.dart:1` — mastery model. `get_student_stats_tool.dart:9` — surfaces stats but is a mentor tool, not invoked post-teaching. | PARTIAL |
| 5. Student provides explicit feedback | The feedback should be logged and influence future lesson recommendations (learning method analytics). | `lib/core/services/learning_method_analytics_service.dart:1` — tracks preferred block type, optimal session length, visual preference. `lib/features/teaching/data/repositories/conversation_repository.dart` — persists conversation data. Feedback is logged but not explicitly fed back into lesson generation. | PARTIAL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `generate_lesson_blocks` (adapt lesson content on feedback) | YES | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` |
| `get_weak_topics` (identify prerequisite gaps) | YES | `lib/features/mentor/services/tools/get_weak_topics_tool.dart` |
| `get_lesson_history` (reference past explanations) | YES | `lib/features/mentor/services/tools/get_lesson_history_tool.dart` |
| `explain_differently` (request a different explanation modality) | YES | `lib/features/mentor/services/tools/explain_differently_tool.dart` — LLM-backed tool generating visual, analogy, or step-by-step explanations. `LessonBlockType` now has `visual` and `analogy` variants. |
| `suggest_practice` (redirect to prerequisite practice) | YES | `lib/features/mentor/services/tools/suggest_practice_tool.dart` — callback-based tool querying mastery data for weak-topic recommendations. |

**Gap:** Teaching mode has no `explain_differently` or `suggest_practice` agent tools
in its system prompt, and teaching mode bypasses `AgentLoop` — so even though the tools
are registered in the agent registry, they cannot be invoked during lessons.
→ Teaching-mode context-injection (`e2e-teaching-missing-context-injection.md`).

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Conversation history (prior failed explanations) | YES | `lib/core/services/conversation_memory.dart` — `ConversationMemory` persists history. |
| Current lesson block type and content | NO | No context builder for active lesson blocks in teaching mode. |
| Available explanation modalities (text, example, visual, analogy) | NO | Not described in the teaching system prompt (`prompts.dart:70-89`). |
| Learning method analytics (prefers visual, optimal session length) | PARTIAL | `learning_method_analytics_service.dart:1` exists but is not injected into teaching prompt. |

**Gap:** Teaching context lacks active lesson block info and explanation modality options.
→ File `issues/open/e2e-teaching-missing-context-injection.md` (already open)

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `l10n` strings keep language accessible. |
| Actionability (one clear next action) | FAIL — after "I don't get it," no single clear next action is offered. |
| Confirmation discipline | PASS — no schedule changes in this flow. |

## Validation Results

Traced against code at:
`lib/features/teaching/services/tutor_service.dart:59-110`,
`lib/features/teaching/services/prompts/prompts.dart:70-89`,
`lib/features/lessons/data/models/lesson_block_model.dart` (LessonBlockType enum),
`lib/core/services/learning_method_analytics_service.dart:1`,
`lib/features/mentor/services/tools/explain_differently_tool.dart`,
`lib/features/mentor/services/tools/suggest_practice_tool.dart`,
`lib/core/data/enums.dart` (LessonBlockType: visual, analogy added).

- Step 1: PARTIAL — pacing feedback not explicitly handled in teaching prompt.
- Step 2: PASS — `explain_differently` tool registered; `LessonBlockType` has `visual`/`analogy`.
- Step 3: FAIL — teaching mode does not invoke readiness scoring or weak-topic tools.
- Step 4: PARTIAL — mastery stats exist but not surfaced post-lesson automatically.
- Step 5: PARTIAL — feedback is logged but not fed back into lesson generation.

Tool audit: 5 of 5 needed tools exist (`explain_differently` and `suggest_practice` registered).
Context audit: active lesson blocks and modality options not injected → issue open.
