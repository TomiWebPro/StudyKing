# File Placement Violation: `teaching/models/` breaks project convention

## Context

The project convention (documented in `AGENTS.md`) mandates that all model files reside under `data/models/` within each feature:

| Source Location | Test Location |
|---|---|
| `lib/features/*/data/models/*.dart` | `test/features/*/data/models/*_test.dart` |

The `teaching` feature violates this convention. Two model files (`evaluation_result.dart`, `lesson_plan_model.dart`) sit directly under `teaching/models/` instead of `teaching/data/models/`. This is inconsistent with the other 6 model files in `teaching/data/models/` (tutor_session_model, conversation_message_model, plus the two that should be there).

The barrel file `teaching.dart` mixes paths, exporting from both `data/models/` (correct) and `models/` (wrong).

## Affected Files

### Source files to move:
- `lib/features/teaching/models/evaluation_result.dart` → `lib/features/teaching/data/models/evaluation_result.dart`
- `lib/features/teaching/models/lesson_plan_model.dart` → `lib/features/teaching/data/models/lesson_plan_model.dart`

### Barrel file to update:
- `lib/features/teaching/teaching.dart` — change `export 'models/evaluation_result.dart';` and `export 'models/lesson_plan_model.dart';` to `export 'data/models/evaluation_result.dart';` and `export 'data/models/lesson_plan_model.dart';`

### Test files to move:
- `test/features/teaching/models/evaluation_result_test.dart` → `test/features/teaching/data/models/evaluation_result_test.dart`
- `test/features/teaching/models/lesson_plan_model_test.dart` → `test/features/teaching/data/models/lesson_plan_model_test.dart`

### Test files that need import path updates (direct imports):
- `test/features/teaching/presentation/widgets/lesson_progress_bar_test.dart` (line 3)
- `test/features/teaching/services/tutor_service_test.dart` (line 24)
- `test/features/teaching/services/conversation_manager_test.dart` (line 8)
- `test/features/teaching/presentation/tutor_screen_test.dart` (line 20)
- `test/features/teaching/models/evaluation_result_test.dart` (line 2)
- `test/features/teaching/models/lesson_plan_model_test.dart` (line 2)

## Rationale

- **Consistency**: Every other feature places models in `data/models/`. The two misplaced files are the only violation of this convention in the entire project.
- **Discoverability**: New contributors following the convention will look under `data/models/` and miss these files.
- **Tooling**: CLI scaffolding, test file generators, and lint rules that assume the standard layout will produce incorrect results.
- **Barrel purity**: Currently `teaching.dart` mixes `export 'data/models/...'` with `export 'models/...'` — a clear signal the placement is an accident that should be corrected.

## Acceptance Criteria

1. `lib/features/teaching/models/` directory no longer exists (both files moved to `data/models/`)
2. `lib/features/teaching/data/models/` contains `evaluation_result.dart`, `lesson_plan_model.dart`, `conversation_message_model.dart`, and `tutor_session_model.dart`
3. All `export` directives in `teaching.dart` use the `data/models/` prefix
4. All test imports reference `package:studyking/features/teaching/data/models/...`
5. Existing test suite passes after the move
6. No compilation errors across the entire project
