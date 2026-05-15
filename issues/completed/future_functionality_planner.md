# Issue: Triple-Redundant Validation/Mastery Layer & Disconnected LLM Infrastructure Block Core User-Facing Features

## Context

The codebase has evolved with overlapping abstractions in three critical domains — **answer validation**, **mastery/progress tracking**, and **LLM service orchestration** — creating maintenance drag and preventing the platform from delivering on core product vision items (token-aware cost tracking, adaptive practice, model-agnostic provider support, and accurate student progress analytics).

## Redundancies Identified

### 1. Triple Answer Validation Path

Three separate validation systems exist with overlapping responsibilities:

| Service | File | Scope |
|---|---|---|
| `AnswerValidationService` | `lib/core/services/answer_validation_service.dart` | Per-question-type validation, caching, markscheme matching, step-based eval |
| `EvaluationAdapterService` | `lib/core/services/evaluation_adapter_service.dart` | Converts between `QuestionEvaluation`/`Markscheme`/`Question`, reimplements `validateWithEvaluation` |
| `LlmService.validateAnswer` | `lib/core/services/llm/llm_chat_service.dart:530` | LLM-powered answer validation (fallback to `_mockValidateAnswer`) |
| `MasteryGraphService.evaluateAnswer` | `lib/core/services/mastery_graph_service.dart:113` | Delegates to `AnswerValidationService.validateWithEvaluation` — thin wrapper |

Each has its own `ValidationResult`-like return type (`EvaluationResult`, `ValidationResult`, raw `String`). All four do essentially the same thing: compare a user answer against a correct answer/acceptable answers/expected steps. This creates confusion about which path to use and wastes developer time.

**Affected files:**
- `lib/core/services/answer_validation_service.dart`
- `lib/core/services/evaluation_adapter_service.dart`
- `lib/core/services/llm/llm_chat_service.dart` (lines 530–563, 783–785)
- `lib/core/services/mastery_graph_service.dart` (lines 113–130)

### 2. Dual Mastery/Progress Tracking Systems

Mastery and progress tracking is split across at least three services with overlapping state:

| Service | File | Tracks |
|---|---|---|
| `AdaptivePracticeEngine` (with `_QuestionState`) | `lib/core/services/adaptive_practice_engine.dart` | Per-question in-memory state, streak, confidence history, review interval |
| `MasteryGraphService` + `MasteryCalculationService` | `lib/core/services/mastery_graph_service.dart`, `mastery_calculation_service.dart` | Per-topic `MasteryState`, question-level `QuestionMasteryState`, spaced repetition, forgetting risk |
| `StudyProgressTracker` | `lib/core/services/study_progress_tracker.dart` | Overall stats, topic progress, weekly trends, CSV export, badge recommendations |

`AdaptivePracticeEngine.updateQuestionState` (line 68) independently recalculates mastery and writes to `SpacedRepetitionRepository`, while `MasteryGraphService.recordAttempt` (line 21) also calculates mastery and writes to `MasteryGraphRepository`. Both are called from different code paths and will diverge over the same student data — giving inconsistent progress reports and recommendations.

**Affected files:**
- `lib/core/services/adaptive_practice_engine.dart`
- `lib/core/services/mastery_graph_service.dart`
- `lib/core/services/mastery_calculation_service.dart`
- `lib/core/services/mastery_integration_service.dart`
- `lib/core/services/study_progress_tracker.dart`

### 3. LLM Infrastructure Not Connected to Usage/Task Tracking

`LlmTaskManager` and `LlmUsageMeter` exist as standalone classes but are **never integrated** into the actual `LlmService` or any caller:

- `LlmTaskManager` (`lib/core/services/llm_task_manager.dart`): Has `createTask`, `startTask`, `completeTask`, `failTask` — zero callers outside itself (`rg -n "LlmTaskManager"` only shows its own file and test files).
- `LlmUsageMeter` (`lib/core/services/llm_usage_meter.dart`): Records usage, totals per feature, cost — zero callers in production code (`rg -n "LlmUsageMeter"` only shows its own file).
- `LlmService._trackUsage` (line 408) fires `onTokenUsage` callback but nothing subscribes to it.

**Affected files:**
- `lib/core/services/llm_task_manager.dart`
- `lib/core/services/llm_usage_meter.dart`
- `lib/core/services/llm/llm_chat_service.dart` (lines 408–415)
- `lib/features/llm_tasks/presentation/` (UI with no backing data)

### 4. ConversationMemory Not Used Consistently

`ConversationMemory` is defined inside `llm_chat_service.dart` (line 15) and used in `ConversationManager` (teaching mode) and `MentorService` (mentor mode). However:
- `ConversationManager` constructs its own `ConversationMemory` with `maxTurns: 30` and manages it alongside its own `_messages` list — the same data is stored twice.
- `MentorService` constructs its own `ConversationMemory` with `maxTurns: 50` — independent from `ConversationManager`.
- Neither persists conversation memory across app restarts. When the app reopens, all teaching/mentoring context is lost — the student has to reintroduce themselves.

**Affected files:**
- `lib/core/services/llm/llm_chat_service.dart` (lines 15–57)
- `lib/features/teaching/services/conversation_manager.dart` (lines 18, 41, 104–105, 128, 151)
- `lib/features/mentor/services/mentor_service.dart` (lines 19, 40, 45, 50–51, 61, 271)

### 5. Hardcoded Model IDs in QuestionGenerationService

`QuestionGenerationService._getModelForDifficulty` (line 139) hardcodes three specific model IDs (`google/gemini-2.5-flash-preview-05-20`, `anthropic/claude-3.5-haiku`, `anthropic/claude-3.5-sonnet`). These will break or become obsolete. The service also calls `_llmService.chat()` (line 120) which includes a `_mockChatResponse` fallback for empty API keys — meaning users who want full offline usage (e.g., with Ollama) will silently get mocked content.

**Affected files:**
- `lib/core/services/question_generation_service.dart` (lines 139–150)

## Rationale

The vision document states that the platform must "track student performance," "continuously validate and improve AI-generated content," and "be model-agnostic." The current architecture actively works against all three goals:

1. **Inconsistent student progress**: With dual mastery systems, a student who uses practice questions gets different progress data depending on which code path records the attempt. The mentor, planner, and dashboard all query different sources and will show contradictory data.

2. **No token cost visibility**: The `LlmTaskManager` UI and `LlmUsageMeter` exist but are disconnected from actual LLM calls. Students cannot see what their AI usage costs, and there is no budgeting mechanism — contradicting the "LLM token usage for different tasks" requirement.

3. **Fragile model selection**: Hardcoded model IDs and the mock fallback pattern mean the system cannot gracefully support local/offline providers (Ollama) or provider failover.

4. **Lost conversation history**: Teaching and mentoring sessions lose all context on app restart. The vision explicitly calls for an AI that "deeply understands the student" and acts as a "persistent mentor" — impossible without persistent conversation memory.

## Acceptance Criteria

1. **Unified answer validation**: Consolidate `AnswerValidationService`, `EvaluationAdapterService`, `LlmService.validateAnswer`, and `MasteryGraphService.evaluateAnswer` into a single `AnswerEvaluationService` with a single `EvaluationResult` type and remove the redundant files. All four call sites must be migrated.

2. **Unified mastery tracking**: Merge `AdaptivePracticeEngine._QuestionState` into `MasteryGraphService` + `MasteryCalculationService`. `AdaptivePracticeEngine` must use `MasteryGraphService.recordAttempt` instead of maintaining its own state and writing to a separate `SpacedRepetitionRepository`. Remove the orphaned `SpacedRepetitionRepository` dependency.

3. **Integrate LLM infrastructure**: Wire `LlmTaskManager` and `LlmUsageMeter` into `LlmService._callOpenRouter`, `_callOpenAI`, `_callOllama`, and all streaming variants. Every chat completion must create a task and record usage. The `llm_tasks` feature UI must render live data.

4. **Persistent conversation memory**: Extract `ConversationMemory` into its own file under `lib/features/teaching/` or `lib/core/services/`. Add persistence via Hive or DatabaseService for both `TutorService` and `MentorService` so context survives app restart. Removal of message double-storage in `ConversationManager`.

5. **Model-agnostic question generation**: Move model IDs from hardcoded constants to `LlmConfiguration` or a provider-agnostic resolution strategy. `QuestionGenerationService` must respect the user's selected provider/model from settings instead of ignoring it.

6. **Remove dead exports/types**: Delete `lib/core/services/llm_service.dart` (barrel file), remove unused methods (`_mockChatResponse`, `_getMockQuestions`, `_getMockLessonBlocks`, `_getMockLesson`, `_mockValidateAnswer`, `_mockStudyPlan`) from `llm_chat_service.dart` once production paths are verified.
