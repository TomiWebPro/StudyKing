# Scenario: Student practices, reviews answers, system adapts difficulty

**Persona:** Active learner using adaptive practice

## Goal

> "I just finished a practice session on Algebra. The system kept giving me
> harder questions after each correct answer, then easier ones when I got
> stuck. After reviewing my mistakes, it showed me exactly which topics
> need work and scheduled a follow-up lesson."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student starts a practice session on a topic | The mentor should create a practice session targeting the student's current mastery level, pulling questions from the question bank. | `lib/features/mentor/services/tools/create_practice_session_tool.dart` — `CreatePracticeSessionTool` exists and is registered (`llmAgentToolsProvider:87-94`). Uses `ReadinessScorer` to pick question difficulty. | PASS |
| 2. Student answers a question incorrectly | The system should log the attempt, identify the weak sub-topic, and adapt — serving easier questions on the same concept or redirecting to a prerequisite. | `lib/features/practice/services/readiness_scorer.dart:16` — readiness scoring exists. `MasteryGraphService.getWeakTopics` (`lib/core/services/mastery_graph_service.dart`) tracks weak topics. `lib/features/practice/data/repositories/mastery_graph_repository.dart` persists mastery state. | PARTIAL |
| 3. Student reviews mistakes after the session | The system should show a breakdown of wrong answers, the underlying concept, and link to a remediation lesson or question variants. | `lib/features/practice/services/readiness_scorer.dart` — readiness data exists. `lib/features/mentor/services/tools/get_lesson_history_tool.dart` shows past lessons. No explicit "review mistakes" view; `lib/features/practice/` has `practice_sessions_repository.dart` but review UI is sparse. | PARTIAL |
| 4. System schedules a follow-up lesson on weak areas | After detecting weak topics via `get_weak_topics`, the mentor should propose scheduling a lesson on the struggling concept with confirmation. | `lib/features/mentor/services/tools/get_weak_topics_tool.dart:9` — registered (`llp_agent_providers.dart:74-77`). `ScheduleLessonTool` registered at `llp_agents_providers.dart:64`. Mentor uses `_pendingSchedule` for confirmation (`mentor_service.dart:359-370`). | PASS |
| 5. Student sees updated mastery progress | The mastery graph should reflect the practice and show improvement over time. | `lib/core/data/models/mastery_state_model.dart:1` — `MasteryState` model tracks `accuracy`, `reviewUrgency`, `readinessScore`. `lib/features/practice/data/repositories/mastery_graph_repository.dart` persists per-topic mastery. `get_student_stats` tool (`get_student_stats_tool.dart:9`) surfaces stats. | PARTIAL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `create_practice_session` (start a practice session at current mastery) | YES | `lib/features/mentor/services/tools/create_practice_session_tool.dart` |
| `get_weak_topics` (identify struggling concepts) | YES | `lib/features/mentor/services/tools/get_weak_topics_tool.dart` |
| `get_lesson_history` (review past lessons and mistakes) | YES | `lib/features/mentor/services/tools/get_lesson_history_tool.dart` |
| `schedule_lesson` (book follow-up on weak areas) | YES | `lib/features/mentor/services/tools/schedule_lesson_tool.dart` |
| `get_student_stats` (show mastery progress) | YES | `lib/features/mentor/services/tools/get_student_stats_tool.dart` |
| `review_mistakes` (detailed review of wrong answers) | MISSING | No agent tool wraps practice-session mistake review. |

**Gap:** No `review_mistakes` agent tool — the mentor cannot invoke a mistake-review directly.
→ File `issues/open/e2e-practice-missing-review-mistakes-tool.md`

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Current mastery state (weak topics, accuracy) | YES | `mentor_context_builder.dart:195-200` — `_loadWeakTopics` → `getWeakTopics` |
| Readiness scores per topic | PARTIAL | `readiness_scorer.dart:16` — used in `CreatePracticeSessionTool` but not injected into mentor context prompt |
| Past session results (mistakes, time spent) | NO | `session_repository.dart` has session data but mentor context builder does not inject past session accuracy |
| Lesson history (remediation links) | YES | `mentor_context_builder.dart` — `loadUpcomingLessons`; `get_lesson_history_tool.dart` available |

**Gap:** Past session accuracy and readiness scores are not injected into the mentor context prompt.
→ File `issues/open/scenario-practice-context-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `l10n` strings keep feedback at ~6th-grade level. |
| Actionability (one clear next action) | PARTIAL — after review, the system shows weak topics but does not surface exactly one next action (review vs. schedule vs. practice). |
| Confirmation discipline (no silent schedule changes) | PASS — `MentorService._pendingSchedule` enforces explicit confirmation (`mentor_service.dart:359`). |

## Validation Results

Traced against code at:
`lib/features/practice/services/readiness_scorer.dart:16`,
`lib/core/services/mastery_graph_service.dart` (full file),
`lib/features/mentor/services/tools/create_practice_session_tool.dart`,
`lib/features/mentor/services/tools/get_weak_topics_tool.dart:9`,
`lib/core/data/models/mastery_state_model.dart:1`.

- Step 1: PASS — `CreatePracticeSessionTool` is registered and callable from the agent.
- Step 2: PARTIAL — readiness scoring exists but does not feed back into the LLM context.
- Step 3: PARTIAL — no dedicated review-mistakes tool or view.
- Step 4: PASS — `get_weak_topics` + `schedule_lesson` are reachable through AgentLoop.
- Step 5: PARTIAL — mastery model tracks stats but review UI is sparse.

Tool audit: 5 of 6 needed tools exist; `review_mistakes` is missing.
Context audit: readiness scores and past session accuracy not injected → new issue filed.
