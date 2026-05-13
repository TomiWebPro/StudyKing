# Feature / Architecture Roadmap: Consolidate Fragmented Answer Validation, Redundant Question Engines, and Scattered LLM Services

## Context

The codebase has grown organically, leaving behind several critical architectural problems:

1. **Four parallel answer-validation systems** — each with its own `isMatch` logic, `ValidationResult`/`EvaluationResult` class, and caching — spread across features and core.
2. **Two dead question-engine files** that call nonexistent API endpoints, define the same `DynamicQuestionType` enum, and are imported by nothing.
3. **Scattered LLM service implementations** using different HTTP clients (`http` vs `dio`), different configuration models, and different response-handling patterns.
4. **A reverse dependency where core imports feature models** — `Question` (in `lib/core/data/models/`) imports `Markscheme` (in `lib/features/questions/models/`), violating layer isolation.
5. **Incomplete feature-module architecture** — the `features.dart` barrel file exports only 4 of 8 features, and several features lack `services/` or `data/` layers entirely.

These issues block further development: adding a new question type requires touching 4 validation systems, and enabling a new LLM provider requires changes across 3+ different files with incompatible patterns.

---

## Affected Files & Structure

### Issue 1 — Answer Validation Triple Duplication

| File | Role | Lines |
|------|------|-------|
| `lib/features/questions/services/answer_validator.dart` | Contains **both** `QuestionAnswerValidator` (instance) and `AnswerValidationService` (static) classes with identical logic | 368 |
| `lib/features/practice/services/answer_validation_service.dart` | Thin wrapper re-exporting the above with its own caching layer | 39 |
| `lib/core/services/evaluation_adapter_service.dart` | Third validation engine with own `EvaluationResult` and step-scoring logic | 145 |
| `lib/features/questions/models/markscheme_model.dart` | `isMatch()` / `_isSimilar()` baked into model | 133 |
| `lib/core/data/models/question_evaluation_model.dart` | Another `isMatch()` / `_isSimilar()` — same algorithm, different class | 210 |

**Duplicated logic includes:**
- Exact-match normalization (`.trim().toLowerCase()`)
- Fuzzy word-overlap matching (`_isSimilar`)
- Step-by-step required-answer matching (`contains()`)
- Caching strategies (keyed by question ID + markscheme signature)
- `ValidationResult` / `EvaluationResult` both carrying `isCorrect`, `score`, `explanation`, `feedback`

### Issue 2 — Dead Question Engine Files

| File | Problem | Lines |
|------|---------|-------|
| `lib/services/question_engine.dart` | Calls `/api/v1/mcq/options/types`, defines `DynamicQuestionType`, `LessonQuestion`, `DynamicLessonQuestionGenerator` — all unused by any feature | 249 |
| `lib/services/question_engine_dynamic.dart` | Calls `/api/v1/question/types`, defines identical `DynamicQuestionType`, `DynamicTypeFetcher` — all unused | 93 |

Both files appear to be early prototypes that were never wired into the feature system. The `question_generation_service.dart` in `lib/core/services/` is the actual active generator, using `Question` (core model) and `Markscheme` (feature model) — not `LessonQuestion`.

### Issue 3 — Scattered LLM Integration

| File | HTTP client | Config model | Imported by |
|------|-------------|--------------|-------------|
| `lib/core/services/llm_service.dart` | `http` | `LlmConfiguration` (local class) | Unknown |
| `lib/services/llm_api_service.dart` | `dio` | `OpenRouterRequest/Response` | Unknown |
| `lib/core/services/ai_model_service.dart` | (unknown) | (unknown) | Unknown |
| `lib/providers/llm_engine_provider.dart` | Riverpod provider wrapper | (unknown) | Unknown |
| `lib/core/services/question_generation_service.dart` | `http` | Hardcoded OpenRouter URL + API key | Self-contained |

- Each file stores its own copy of API base URL, API key, and model selection logic
- `llm_service.dart` duplicates the OpenRouter and Ollama calling patterns inline (2x identical POST logic)
- No shared token-usage tracking across calls

### Issue 4 — Reverse Dependency (Core → Feature)

```
lib/core/data/models/question_model.dart:3
  → import '../../../features/questions/models/markscheme_model.dart';
```

`Question` (core) carries `Markscheme? markscheme` field. `Markscheme` lives in a **feature module**. This means:
- Core cannot be extracted or tested independently
- `Markscheme` and `QuestionEvaluation` are isomorphic types (same fields, same `isMatch` logic) — one should be canonical

### Issue 5 — Incomplete Feature Module Exports

`lib/features/features.dart`:
```dart
export 'lessons/lessons.dart';      // exists
export 'quickguide/quickguide.dart'; // exists
export 'planner/planner.dart';      // exists
export 'practice/practice.dart';    // exists
// MISSING: sessions, settings, subjects, questions
```

Features missing service layers:
- `lessons/` — no `services/` directory
- `sessions/` — no `services/` directory
- `planner/` — only has `presentation/` (essentially a shell)

---

## Rationale

| Problem | Why it matters now |
|---------|-------------------|
| 4x answer validation | Every new question type requires changes in 4 places. Bug fixes to `_isSimilar` or `_normalizeMathExpression` must be repeated. |
| 2x dead question engines | Confuses new developers. Suggests the architecture is unstable. Unreferenced API endpoint strings will fail at runtime if code is ever reached. |
| Scattered LLM services | Adding Ollama support requires touching 3 files. Token-cost tracking is impossible. Provider-agnostic routing is not possible. |
| Core→feature import | Blocks unit-testing `Question` model in isolation. `Markscheme` cannot be versioned or migrated independently. |
| Half-barreled features | `features.dart` misleads consumers. Planner feature promises scheduling but has only UI scaffolding. |

---

## Proposed Action Plan

### Phase 1 — Consolidate Answer Validation (highest impact)

1. **Pick the canonical model**: Promote `QuestionEvaluation` (`lib/core/data/models/question_evaluation_model.dart`) as the single evaluation model. It already has `EvaluationType`, `EvaluationStep`, version field, and `isMatch()`. Remove `Markscheme` as a Hive type (migrate existing data) or make `Markscheme` a thin alias.
2. **Unify validation into one service**: Merge `answer_validator.dart` and `evaluation_adapter_service.dart` into a single `AnswerValidationService` in `lib/core/services/`. Keep the caching layer.
3. **Delete `lib/features/practice/services/answer_validation_service.dart`** (the thin wrapper).
4. **Delete `Markscheme.isMatch()` / `_isSimilar()`** — evaluation logic should not live in a data model.

**Acceptance criteria:**
- Exactly one `AnswerValidationService` with one `ValidationResult` class
- `Question` model uses `QuestionEvaluation` instead of `Markscheme`
- All features import from `lib/core/services/answer_validation_service.dart`
- No `isMatch()` on any model class
- All existing validation behavior preserved (exact match, fuzzy match, step-based, math expression normalization)

### Phase 2 — Remove Dead Question Engines

1. **Delete** `lib/services/question_engine.dart`
2. **Delete** `lib/services/question_engine_dynamic.dart`
3. Verify `question_generation_service.dart` is the sole active generator
4. Update any dangling imports (search `DynamicQuestionType`, `LessonQuestion`, `DynamicTypeFetcher`)

**Acceptance criteria:**
- `rg 'question_engine'` returns zero results outside `lib/core/services/question_generation_service.dart`
- `rg 'DynamicQuestionType'` returns zero results
- `rg 'LessonQuestion'` returns zero results
- `rg '/api/v1/mcq'` returns zero results

### Phase 3 — Unified LLM Service

1. **Single `LlmService`** in `lib/core/services/llm_service.dart` (promote and refactor the existing one):
   - Accept provider type (`openRouter`, `ollama`, `openAI`) via a config object
   - Single `chat()` method that routes to correct HTTP client
   - Shared token tracking callback
   - Remove duplicate `_callLlm` / inline HTTP calls from `question_generation_service.dart`
2. **Deprecate and remove** `lib/services/llm_api_service.dart` after migration
3. **Move model definitions** (`llm_config.dart`, `llm_models.dart`) into `lib/core/data/models/`

**Acceptance criteria:**
- One `LlmService` class with provider-agnostic interface
- Token usage tracked across all calls
- All `http.post` / `dio.post` LLM calls route through a single entry point
- `rg 'openrouter.ai'` shows results only inside the unified service

### Phase 4 — Fix Module Boundaries

1. **Promote `Markscheme` into core**: Move `markscheme_model.dart` from `lib/features/questions/models/` to `lib/core/data/models/`. Update all imports.
2. **Complete `features.dart`**: Export all 8 feature barrel files.
3. **Add missing service directories** to `lessons/`, `sessions/`, `planner/` features (can be placeholder barrel files initially).

**Acceptance criteria:**
- `rg 'from.*features.*models.*markscheme'` returns zero results
- `features.dart` exports all 8 features
- Every feature has at minimum a `services/` barrel file

---

## Future Opportunity — Adaptive Practice Engine Consolidation

The `AdaptivePracticeEngine` in `lib/core/services/` currently tracks question state only in memory (`Map<String, _QuestionState>`). It should be integrated with the persisted `MasteryGraphService` and `StudyProgressTracker` so that spaced-repetition intervals persist across app restarts. This is a follow-up opportunity once Phase 1 is complete.

---

## Notes

- Do NOT attempt all phases in one PR. Phase 1 alone affects 5 files and carries migration risk.
- The `LessonQuestion` class in `question_engine.dart` has a `clone()` method — no other code calls it, confirming dead code.
- The `Markscheme` → `QuestionEvaluation` migration needs a Hive type adapter migration or a read-time adapter in `Question.fromJson()`.
