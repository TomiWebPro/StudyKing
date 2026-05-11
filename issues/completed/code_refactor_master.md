# Duplicate Hive typeId Assignments

## Context

Hive requires each registered TypeAdapter to have a **globally unique** `typeId` integer. The codebase has a critical bug where multiple models share the same `typeId: 5`, causing potential data corruption and serialization failures at runtime.

### Conflicting typeId: 5 Assignments

| Model | File | typeId |
|-------|------|--------|
| `ProfileData` | `lib/features/settings/data/models/settings_box.dart` | **5** |
| `StudentAttempt` | `lib/core/data/models/student_attempt_model.dart` | **5** |
| `Markscheme` | `lib/core/data/models/markscheme_model.dart` | **5** |

## Affected Files

- `lib/core/data/models/student_attempt_model.dart:3`
- `lib/core/data/models/markscheme_model.dart:5`
- `lib/features/settings/data/models/settings_box.dart:109`

## Additional Observations

1. **Duplicate functionality**: `QuestionEvaluation` (`typeId: 14`) and `Markscheme` (`typeId: 5`) implement nearly identical `isMatch()` and `_isSimilar()` methods—likely a remnant of migration/refactoring.

2. **Inconsistent adapter strategy**: Models with `@HiveType` annotations (e.g., `mastery_state_model.dart`) also have manually maintained adapters in `lib/core/data/adapters/`. The manual adapters may be dead code if code generation (`build_runner`) is used.

3. **Duplicate model**: `StudentAttempt` (`typeId: 5`) is a separate model from `markscheme_model.dart` (`typeId: 5`), yet both use the same ID.

## Rationale

Hive typeId collisions cause silent data corruption: when deserializing, Hive uses the typeId to lookup the adapter. If multiple adapters share an ID, the wrong model may be instantiated, leading to runtime crashes or corrupted state.

## Acceptance Criteria

- [ ] Assign a unique `typeId` to each model. Suggested mapping:
  - `StudentAttempt`: reassign to `typeId: 24`
  - `Markscheme`: reassign to `typeId: 25`
  - `ProfileData` (`typeId: 5`): keep or reassign—decide based on usage
- [ ] Verify no other duplicate typeIds exist across the codebase
- [ ] If `Markscheme` is deprecated in favor of `QuestionEvaluation`, remove `Markscheme` entirely
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs` if using generated adapters
- [ ] Add a static assertion or unit test that validates typeId uniqueness at compile time
