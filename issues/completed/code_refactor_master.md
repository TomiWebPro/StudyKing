# Architectural Inconsistency: Scattered Hive Adapters & Unclear Model Ownership

## Context

The codebase suffers from a structural anti-pattern where **28 domain models are dumped into `core/data/models/`** while their corresponding Hive `TypeAdapter`s are scattered across **5 different feature-specific `data/adapters/` directories**. This makes it impossible to determine which feature "owns" a given model without cross-referencing multiple locations. Adapters drift far from their models, violating the principle of locality.

## Inconsistency Pattern

| Model (in `core/data/models/`) | Adapter Location |
|---|---|
| `markscheme_model.dart` | `features/questions/data/adapters/markscheme_adapter.dart` |
| `question_evaluation_model.dart` | `features/questions/data/adapters/question_evaluation_adapter.dart` |
| `mastery_state_model.dart` | `features/practice/data/adapters/mastery_state_adapter.dart` |
| `mastery_improvement_metric_model.dart` | `features/practice/data/adapters/mastery_improvement_adapter.dart` |
| `question_mastery_state_model.dart` | `features/practice/data/adapters/question_mastery_state_adapter.dart` |
| `personal_learning_plan_model.dart` | `features/planner/data/adapters/personal_learning_plan_adapter.dart` |
| `plan_adherence_metric_model.dart` | `features/planner/data/adapters/plan_adherence_adapter.dart` |
| `topic_dependency_model.dart` | `features/subjects/data/adapters/topic_dependency_adapter.dart` |
| `conversation_message_model.dart` | `features/teaching/data/adapters/conversation_message_adapter.dart` |
| `tutor_session_model.dart` | `features/teaching/data/adapters/...` |

Meanwhile, `subject_model.dart`, `topic_model.dart`, `question_model.dart`, `answer_model.dart`, `lesson_model.dart`, `lesson_block_model.dart`, `study_session_model.dart`, `source_model.dart`, `student_attempt_model.dart` — all in `core/data/models/` — have **no adapters in their owning features** (they likely rely on implicit Hive adapters or are registered elsewhere).

To make matters worse, some features (`practice/`, `settings/`, `mentor/`) define their own local `data/models/` meaning there are **three patterns in play simultaneously**:
1. Model in `core/data/models/`, adapter in a feature's `data/adapters/`
2. Model in feature's `data/models/`, adapter in same feature's `data/adapters/`
3. Model in `core/data/models/` with no visible adapter file at all

## Additional Related Issues

- **Repository output inconsistency**: `QuestionRepository` wraps all methods in `Result<T>` with `Logger` calls, while `AnswerRepository`, `StudySessionRepository`, and `LessonRepository` return raw values with no error handling. No shared contract exists.
- **Dead placeholder code in `core/data/database_migration.dart`** (lines 57–68): `_migrateToV1()` contains empty methods whose comment reads "Placeholder for actual migration logic". This code executes unconditionally on startup but does nothing.
- **`hive_type_ids.dart` runs a top-level side-effect** (`final bool _typeIdsValid = _checkUniqueIds()`) that is never consumed — `validateHiveTypeIds()` is never called outside the file.

## Affected Files

- `lib/core/data/models/` (entire 29-file directory)
- `lib/core/data/hive_type_ids.dart` (lines 35–83, top-level side-effect)
- `lib/core/data/database_migration.dart` (lines 57–68, dead placeholder)
- `lib/core/data/hive_initializer.dart` (lines 6–14, fragile adapter registration)
- `lib/features/questions/data/adapters/markscheme_adapter.dart`
- `lib/features/questions/data/adapters/question_evaluation_adapter.dart`
- `lib/features/practice/data/adapters/mastery_state_adapter.dart`
- `lib/features/practice/data/adapters/mastery_improvement_adapter.dart`
- `lib/features/practice/data/adapters/question_mastery_state_adapter.dart`
- `lib/features/planner/data/adapters/personal_learning_plan_adapter.dart`
- `lib/features/planner/data/adapters/plan_adherence_adapter.dart`
- `lib/features/subjects/data/adapters/topic_dependency_adapter.dart`
- `lib/features/teaching/data/adapters/conversation_message_adapter.dart`
- `lib/features/questions/data/repositories/question_repository.dart` (inconsistent Result wrapping)
- `lib/features/practice/data/repositories/answer_repository.dart` (no Result wrapping)
- `lib/features/sessions/data/repositories/study_session_repository.dart` (no Result wrapping)
- `lib/features/lessons/data/repositories/lesson_repository.dart` (no Result wrapping)

## Rationale

1. **Discoverability**: A developer working on the "questions" feature must know to look in `core/data/models/` for the Question model, then in `features/questions/data/adapters/` for its adapter. This cognitive overhead slows onboarding and refactoring.
2. **Ownership ambiguity**: When a model conceptually belongs to a feature (e.g., `Markscheme` belongs to `questions`), placing it in a shared `core/` directory creates a "tragedy of the commons" — no team/owner feels responsible for it.
3. **Maintenance hazard**: The `hive_initializer.dart` must import every adapter by absolute path from `features/*/data/adapters/` (see lines 6–14). Adding a new model requires touching 3–4 files in different feature trees.
4. **Dead code**: The 32-line migration boilerplate that does nothing (`database_migration.dart:57-68`) adds noise and misleads future readers into thinking a migration system exists when it doesn't.
5. **Testing difficulty**: Without a consistent repository contract (`Result<T>` vs raw), writing a shared test fake or mock is impossible — each repository must be stubbed individually.

## Acceptance Criteria

1. **Model co-location**: Each feature that owns a domain model must define its model within that feature's `data/models/` directory. Models truly shared across ≥3 features may remain in `core/data/models/` but must be explicitly justified with a doc comment.
   - Move `markscheme_model.dart` → `features/questions/data/models/`
   - Move `question_evaluation_model.dart` → `features/questions/data/models/`
   - Move `mastery_state_model.dart` → `features/practice/data/models/`
   - Move `question_mastery_state_model.dart` → `features/practice/data/models/`
   - Move `mastery_improvement_metric_model.dart` → `features/practice/data/models/`
   - Move `personal_learning_plan_model.dart` → `features/planner/data/models/`
   - Move `plan_adherence_metric_model.dart` → `features/planner/data/models/`
   - Move `topic_dependency_model.dart` → `features/subjects/data/models/`
   - Move `conversation_message_model.dart` → `features/teaching/data/models/`
   - Move `tutor_session_model.dart` → `features/teaching/data/models/`

2. **Adapter co-location**: After the moves above, every feature that contains a Hive model must also contain its `TypeAdapter` in `data/adapters/` — the adapter must live next to the model, not in a different feature.

3. **Repository contract consistency**: All repositories must adopt a unified return type. Either:
   - All use `Result<T>` (like `QuestionRepository`), or
   - All return raw types (like `AnswerRepository`).
   Document the decision in `core/data/repository.dart`.

4. **Remove dead migration code**: Delete or complete the empty placeholder methods `_migrateQuestionSubjectId` and `_migrateLessonSubjectId` in `database_migration.dart`. If no migration is needed, remove the migration framework entirely.

5. **Eliminate top-level side-effect in `hive_type_ids.dart`**: Remove the `_typeIdsValid` evaluation at line 83. Either make `validateHiveTypeIds()` a real function called from `hive_initializer.dart` or delete it.

6. **Simplify `hive_initializer.dart`**: Replace explicit feature path imports (lines 6–14) with a registration mechanism that each feature exposes via its own barrel file (e.g., `QuestionsModule.registerAdapters()`), so no single file needs to know the full adapter registry.
