# Future Functionality: AI-Powered Question Generation Pipeline

## Context

The StudyKing codebase has a sophisticated Question model (`lib/core/data/models/question_model.dart`) with a `model` field (OpenRouter model ID) intended for AI-generated questions. However, no AI-powered question generation pipeline exists. Additionally, there are **two redundant Markscheme definitions**:

- `lib/core/data/models/markscheme_model.dart` (simpler, with fuzzy matching)
- `lib/features/questions/models/markscheme_model.dart` (richer, with `MarkSchemeStep`)

Both are used differently: the core one via `Question.correctAnswer`, the feature one via `QuestionAnswerValidator`. This duplication causes maintenance burden and inconsistent validation logic.

## Affected Files

- `lib/core/data/models/question_model.dart` — has unused `model` field and `markscheme`/`correctAnswer` redundancy
- `lib/core/data/models/markscheme_model.dart` — duplicate, isolated markscheme
- `lib/features/questions/models/markscheme_model.dart` — duplicate, richer markscheme with step support
- `lib/features/questions/services/answer_validator.dart` — uses feature markscheme
- `lib/features/practice/services/answer_validation_service.dart` — wraps validator, creates markscheme on-the-fly from Question fields
- `lib/core/data/repositories/question_repository.dart` — no generation capability
- `lib/core/services/mastery_graph_service.dart` — rich mastery tracking, but no connection to question generation

## Rationale

1. **Consolidate Markscheme** into a single, comprehensive model (keeping the step-based one from `lib/features/questions/models/markscheme_model.dart`) that both `Question` and the validator can share.
2. **Build an AI Question Generation Service** that:
   - Accepts a topic/syllabus context
   - Calls OpenRouter API to generate questions using the stored `model` field
   - Creates Questions with proper Markscheme, difficulty, tags
   - Integrates with MasteryState to prioritize weak areas when generating
3. **Unified Answer Validation** — refactor `AnswerValidationService` to use the consolidated Markscheme directly, removing the on-the-fly construction.

## Acceptance Criteria

1. Remove `lib/core/data/models/markscheme_model.dart` — consolidate into the feature one
2. Question model should use a single `Markscheme?` field instead of `markscheme` + `correctAnswer` strings
3. Implement `QuestionGenerationService` with:
   - `generateQuestions(topicId, count, difficulty)` method
   - OpenRouter API integration using model's `model` field
   - Proper error handling and retry logic
4. `AnswerValidationService` consumes the consolidated Markscheme directly
5. Optionally: link generation to MasteryState weak areas (generate more questions for topics with low mastery)
6. All existing tests pass after refactoring