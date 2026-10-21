# Scenario: Student reviews practice mistakes and receives targeted remediation

**Persona:** Student doing review-after-practice

## Goal

> "I finished a practice session and 3 questions tripped me up. The app showed
> me each one with the explanation, flagged the underlying concept I missed,
> and offered 2 variant questions to try again. If I still struggle, it books
> a follow-up lesson on that concept."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student completes a practice session | After the last question, the system shows a summary: correct answers, wrong answers, time spent, and weak topics. | `lib/core/services/study_progress_tracker.dart:1` — tracks attempts/sessions. `lib/core/data/models/mastery_state_model.dart:1` — `MasteryState` tracks accuracy per topic. `lib/features/mentor/services/tools/get_student_stats_tool.dart:9` — surfaces stats. | PASS |
| 2. System shows wrong answers with explanations | Each incorrect question should display with the markscheme explanation and a link to the concept it tested. | `lib/core/data/models/question_model.dart:1` — `Markscheme` has `correctAnswer` and `acceptableAnswers`. `lib/core/data/models/markscheme_model.dart:1` — markscheme model. No explicit "review mistakes" UI — review is via practice session replay. | PARTIAL |
| 3. System offers variant questions on the same concept | For each wrong answer, the system should generate or fetch variant questions from the same difficulty/difficulty-adjusted to reinforce. | `lib/features/questions/services/question_variant_service.dart:1` — generates variants. `lib/features/mentor/services/tools/enqueue_question_variants_tool.dart:9` — registered (`llp_agent_providers.dart:114-120`). Variants are enqueued, not immediately served. | PARTIAL |
| 4. Student still struggles after variants | The mentor should propose scheduling a lesson or practice session on the prerequisite concept, with confirmation. | `lib/features/mentor/services/tools/get_weak_topics_tool.dart:9` — identifies weak areas. `ScheduleLessonTool` and `CreatePracticeSessionTool` are registered. `MentorService._pendingSchedule` enforces confirmation. | PASS |
| 5. Mistake review updates mastery | After the review, the mastery state for the concept should reflect the remediation attempt (improved or still-at-risk). | `lib/features/practice/data/repositories/mastery_graph_repository.dart` — persists mastery updates. `lib/core/services/mastery_graph_service.dart` — `updateMasteryState`. `RefreshMasteryTool` registered (`llp_agent_providers.dart:127-133`). | PASS |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `get_student_stats` (session summary) | YES | `lib/features/mentor/services/tools/get_student_stats_tool.dart` |
| `get_weak_topics` (identify struggling concepts) | YES | `lib/features/mentor/services/tools/get_weak_topics_tool.dart` |
| `enqueue_question_variants` (generate follow-up variants) | YES | `lib/features/mentor/services/tools/enqueue_question_variants_tool.dart` |
| `create_practice_session` (remediation practice) | YES | `lib/features/mentor/services/tools/create_practice_session_tool.dart` |
| `schedule_lesson` (book remedial lesson) | YES | `lib/features/mentor/services/tools/schedule_lesson_tool.dart` |
| `review_mistakes` (detailed mistake review UI) | YES | `lib/features/mentor/services/tools/review_mistakes_tool.dart` — returns wrong answers with markscheme explanations and linked concepts, reachable through AgentLoop. |

**Gap:** None for conversational review — the `review_mistakes` agent tool is now registered in `llmAgentToolsProvider`. (Per-question accuracy and variant availability are now injected into mentor context — see Context audit below.)

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Session accuracy by question/concept | YES | `mentor_context_builder.dart:323-335` — `_buildMistakeLines()` injects per-question accuracy snapshot with concept labels resolved from `QuestionRepository` |
| Variant availability (already generated variants for this concept) | YES | `mentor_context_builder.dart:522` — variant count injected per-question in the mistakes block |
| Remediation history (prior review attempts) | YES | `get_lesson_history_tool.dart` shows past lessons. `conversation_repository.dart` persists conversation data. |

**Gap:** None for context injection. Remaining PARTIAL (Steps 2 & 3): no dedicated review-mistakes UI — the `ReviewMistakesTool` agent tool exists but lacks a student-facing review screen; variants are enqueued, not immediately served.
→ File `issues/open/scenario-review-mistakes-ui-missing.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — markscheme explanations use `l10n` strings. |
| Actionability (one clear next action) | PARTIAL — after review, system offers multiple options (try variants, schedule lesson, practice) but no single clear next action. |
| Confirmation discipline | PASS — scheduling requires explicit confirmation (`mentor_service.dart:359`). |

## Validation Results

Traced against code at:
`lib/core/services/study_progress_tracker.dart:1`,
`lib/features/questions/services/question_variant_service.dart:1`,
`lib/features/mentor/services/tools/get_weak_topics_tool.dart:9`,
`lib/features/practice/data/repositories/mastery_graph_repository.dart`,
`lib/core/data/models/markscheme_model.dart:1`.

- Step 1: PASS — session summary stats are available via `get_student_stats`.
- Step 2: PARTIAL — markscheme explanations exist but no dedicated review-mistakes UI.
- Step 3: PARTIAL — variants are enqueued but not immediately served for remediation; however, the `review_mistakes` agent tool IS registered (`llm_agent_providers.dart:318`) and traced in `tool_trace_coverage_test.dart`, returning wrong answers with markscheme explanations and linked concepts.
- Step 4: PASS — `get_weak_topics` + `create_practice_session` + `schedule_lesson` all reachable.
- Step 5: PASS — `RefreshMasteryTool` + MasteryGraphService update mastery state.

Tool audit: 6 of 6 needed tools exist; `review_mistakes` is FOUND.
RESULT: all needed tools available (0 missing).
Context audit: per-question accuracy + variant availability now injected into mentor context (`mentor_context_builder.dart:323-335`).
**Last re-traced:** 2026-10-21 against current HEAD (`mentor_context_builder_test.dart` recent-mistakes + readiness groups).
