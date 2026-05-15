# File Placement Violations Across Feature Architecture

## Context

The project follows a feature-first architecture with layers (`data/`, `presentation/`, `services/`, `providers/`, `models/`). Several features have files placed in the wrong layer, violating separation of concerns. As the codebase grows, these misplacements compound cognitive load, make imports brittle, and confuse new contributors about where to place new code.

## Affected Files

### 1. Models in `presentation/models/` instead of `data/models/`

- `lib/features/dashboard/presentation/models/dashboard_models.dart` (12 lines)
- `lib/features/practice/presentation/models/practice_models.dart` (34 lines)

Per the established convention (used by `settings/data/models/`, `focus_mode/data/models/`), data models belong under `data/models/`, not `presentation/`.

### 2. Services in `presentation/services/` instead of feature root `services/`

- `lib/features/practice/presentation/services/practice_data_service.dart`
- `lib/features/practice/presentation/services/practice_session_service.dart`

These contain business logic (session management, data operations), not UI logic — they belong in `practice/services/`.

### 3. Models at feature root instead of `data/models/`

- `lib/features/mentor/models/mentor_action.dart`
- `lib/features/mentor/models/progress_report.dart`

All other features nest `models/` under `data/`. Mentor's models at the feature root are inconsistent and make the barrel file imports harder to reason about.

### 4. Barrel file naming inconsistency

- `lib/features/subjects/subject_feature.dart` — should be `subjects.dart`
- `lib/features/questions/questions_feature.dart` — should be `questions.dart`

Every other feature uses `feature_name.dart`; these two are outliers.

### 5. Settings barrel missing export

- `lib/features/settings/settings.dart` does not export `data/models/accessibility_preferences.dart`, even though it is consumed by `main.dart`.

### 6. Inline extension in barrel file

- `lib/core/core.dart` (lines 18–23) defines `IterableExtension` inline. Barrel files should only re-export; extensions belong in dedicated files under `lib/core/extensions/`.

## Rationale

Each violation forces developers to:
- Search multiple directories for files that should be in a canonical location.
- Write brittle relative imports (e.g., `../../../../core/`) when a standard layout would allow shorter, predictable paths.
- Make layer-boundary decisions inconsistently (e.g., one feature puts models in `presentation/`, another in `data/`).
- Miss exports from barrel files, leading to runtime failures or confusing import chains.

Fixing these now is cheap — each file is small. Waiting will make the refactor exponentially harder as more code depends on the current paths.

## Acceptance Criteria

- [ ] `dashboard_models.dart` is moved to `lib/features/dashboard/data/models/dashboard_models.dart`. All imports are updated. `dashboard.dart` barrel is updated.
- [ ] `practice_models.dart` is moved to `lib/features/practice/data/models/practice_models.dart`. All imports are updated. `practice.dart` barrel is updated.
- [ ] `practice_data_service.dart` and `practice_session_service.dart` are moved to `lib/features/practice/services/`. All imports are updated. `practice.dart` barrel is updated.
- [ ] `mentor_action.dart` and `progress_report.dart` are moved to `lib/features/mentor/data/models/`. All imports are updated. `mentor.dart` barrel is updated.
- [ ] `lib/features/subjects/subject_feature.dart` is renamed to `lib/features/subjects/subjects.dart`. All imports of `subject_feature.dart` are updated. `pubspec.yaml` (if referenced) is updated.
- [ ] `lib/features/questions/questions_feature.dart` is renamed to `lib/features/questions/questions.dart`. All imports are updated.
- [ ] `lib/features/settings/settings.dart` exports `data/models/accessibility_preferences.dart`.
- [ ] `IterableExtension` is extracted from `lib/core/core.dart` into a dedicated file (e.g., `lib/core/extensions/iterable_extensions.dart`). `core.dart` imports and re-exports it.
- [ ] All existing tests pass after the moves. No functionality changes — pure relocation and import rewiring.
- [ ] A `git mv` history is preserved so file ancestry is not lost.
