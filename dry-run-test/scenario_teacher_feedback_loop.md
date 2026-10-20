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
| 2. Tutor offers a simpler explanation | The system should vary explanation style (visual, real-world analogy, step-by-step). | `lib/core/data/enums.dart:48-49` — `LessonBlockType` now includes `visual` and `analogy` variants. `lib/features/mentor/services/tools/explain_differently_tool.dart` — `ExplainDifferentlyTool` registered at `llm_agent_providers.dart:90`. Teaching mode now routes live turns through `AgentLoop` (`conversation_manager.dart:446-459`, `tutor_service.dart:306`), so the tool CAN be invoked at runtime to vary explanations. | PASS |
| 3. Student gets a question wrong during practice | The tutor should ask "which part confused you?" and redirect to a prerequisite topic or simpler question. | `lib/features/practice/services/readiness_scorer.dart:16` — readiness scoring exists. `lib/features/mentor/services/tools/get_weak_topics_tool.dart:9` — identifies weak areas. Teaching mode now routes through `AgentLoop` (`conversation_manager.dart:446-459`, `tutor_service.dart:306`), so the LLM CAN invoke `get_weak_topics` and `suggest_practice` during lessons. The confusion directive (`prompts.dart:89-92`) directs the LLM to suggest practice when confusion persists. | PASS |
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

**Gap:** RESOLVED — Teaching mode now routes live turns through `AgentLoop`
(`conversation_manager.dart:446-459` via `agentLoop.runStream`,
`tutor_service.dart:306` passes `agentLoop: _llmAgent?.loop`), so
`explain_differently` and `suggest_practice` tools CAN be invoked during lessons.
The e2e test at `scenario_validation_test.dart` Step 3-4 proves the tool-call trace:
student gets a question wrong → `TOOL_CALL: get_weak_topics`, then "I still don't get
it" → `TOOL_CALL: suggest_practice` invoked through AgentLoop. Remaining gap: active
lesson block info is not injected into the teaching context prompt.
→ File `issues/open/scenario-practice-readiness-not-injected.md`

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Conversation history (prior failed explanations) | YES | `lib/core/services/conversation_memory.dart` — `ConversationMemory` persists history. |
| Current lesson block type and content | YES | `LessonPlanContextBuilder` (lib/features/teaching/services/lesson_plan_context_builder.dart) builds a bounded "Current lesson plan" note from active `LessonBlock`s (capped to 5 blocks, 200-char snippets); `TutorService._injectLessonPlanContext` (tutor_service.dart:399, 439-445) sets `ConversationManager.lessonPlanContext` (conversation_manager.dart:93), and `prompts.tutorMessage` (prompts.dart:100-107) appends it to the system prompt after `masteryContext`. |
| Available explanation modalities (text, example, visual, analogy) | YES | `prompts.dart:89-92` — confusion directive injects modality guidance (analogy, visual, step-by-step) at `confusionCount >= 2`. AgentLoop wiring (`conversation_manager.dart:446-459`, `tutor_service.dart:306`) allows tools to act on it. |
| Learning method analytics (prefers visual, optimal session length) | PARTIAL | `learning_method_analytics_service.dart:1` exists but is not injected into teaching prompt. |

**Gap:** Active lesson block info is now injected into the tutor system prompt
via `LessonPlanContextBuilder` (lesson_plan_context_builder.dart) →
`ConversationManager.lessonPlanContext` (conversation_manager.dart:93) →
`prompts.tutorMessage` (prompts.dart:100-107), so the live tutor reads pre-built
artefacts instead of synthesising from scratch. The remaining gap is readiness
scores not yet injected into the teaching prompt.
→ File `issues/open/scenario-practice-readiness-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `l10n` strings keep language accessible. |
| Actionability (one clear next action) | PASS — after confusion persists, `suggest_practice` tool offers a clear next action (practice session on prerequisite); `get_weak_topics` identifies the specific gap. |
| Confirmation discipline | PASS — no schedule changes in this flow. |

## Validation Results

Traced against code at:
`lib/features/teaching/services/tutor_service.dart:59-110,306,399,439-445`,
`lib/features/teaching/services/conversation_manager.dart:93,343,446-459`,
`lib/features/teaching/services/prompts/prompts.dart:89-92,100-107`,
`lib/features/teaching/services/lesson_plan_context_builder.dart` (new builder),
`lib/features/lessons/data/models/lesson_block_model.dart` (LessonBlockType enum),
`lib/core/services/learning_method_analytics_service.dart:1`,
`lib/features/mentor/services/tools/explain_differently_tool.dart`,
`lib/features/mentor/services/tools/suggest_practice_tool.dart`,
`lib/core/data/enums.dart` (LessonBlockType: visual, analogy added).

- Step 1: PARTIAL — pacing feedback not explicitly handled in teaching prompt (`feedbackContext` not populated from student utterances "too fast/slow").
- Step 2: PASS — `explain_differently` tool registered (`llm_agent_providers.dart:90`); `LessonBlockType` has `visual`/`analogy` (`enums.dart:48-49`); AgentLoop wired into teaching (`conversation_manager.dart:446-459`, `tutor_service.dart:306`).
- Step 3: PASS — teaching mode now invokes `get_weak_topics` + `suggest_practice` through AgentLoop (traced in `scenario_validation_test.dart` Step 3-4).
- Step 4: PARTIAL — mastery stats exist but not surfaced post-lesson automatically.
- Step 5: PARTIAL — feedback is logged but not fed back into lesson generation.

Tool audit: 5 of 5 needed tools exist (`explain_differently` and `suggest_practice` registered).
RESULT: all needed tools available (0 missing).
Context audit: active lesson block info now injected into the teaching prompt via `LessonPlanContextBuilder` (lesson_plan_context_builder.dart) → `ConversationManager.lessonPlanContext` (conversation_manager.dart:93) → `prompts.tutorMessage` (prompts.dart:100-107). Readiness scores still not injected → open issue (`scenario-practice-readiness-not-injected.md`). Modality options resolved.
**Last re-traced:** 2026-10-20 against commit `dc19534` (`scenario_validation_test.dart` Steps 1–5, `prompts.dart:89-92,100-107`, `enums.dart:48-49`, `llm_agent_providers.dart:90-95`, `conversation_manager.dart:93,343,446-459`, `tutor_service.dart:306,399,439-445`, `lesson_plan_context_builder.dart`).
