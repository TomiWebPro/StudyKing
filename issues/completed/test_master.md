# Test Master Issue: Core Domain Models Lack Dedicated Unit Tests

## Context

The StudyKing project has strong test coverage for models in `lib/models/` (llm_models, llm_config, settings_model, dynamic_context_config, dynamic_lesson_types), but the **core domain models** in `lib/core/data/models/` lack dedicated unit tests. Only surface-level widget tests exist.

## Affected Files

- `lib/core/data/models/question_model.dart` - Only 2 basic tests in `test/core.model.test.dart` (JSON serialization, enum index)
- `lib/core/data/models/topic_model.dart` - Only basic JSON tests embedded in `test/features/lessons/presentation/lesson_presentation_test.dart`
- `lib/core/data/models/lesson_model.dart` - Only basic JSON tests embedded in `test/features/lessons/presentation/lesson_presentation_test.dart`
- `lib/core/data/models/lesson_block_model.dart` - No tests found
- `lib/core/data/models/topic_progress_model.dart` - No tests found
- `lib/core/data/models/student_attempt_model.dart` - No tests found

## Rationale

1. **High Business Logic Value**: These models contain critical domain logic (serialization, copyWith, defaults, Hive adapters) that affects the entire app
2. **Inconsistent Test Coverage**: Compare `lib/models/` which has dedicated test files like `test/models.llm_models.test.dart` (473 lines) vs. core models with minimal coverage
3. **Widget Tests Are Insufficient**: Current JSON tests are embedded in widget tests, which don't verify model behavior in isolation or cover edge cases
4. **Maintenance Risk**: Without unit tests, refactoring core domain models is risky

## Missing Test Scenarios

For `Question` model:
- Edge cases in fromJson (missing fields, type mismatches)
- copyWith behavior with null values
- Hive adapter serialization
- Validation of difficulty values

For `Topic` model:
- parentId handling (null vs. set)
- childTopicIds default value
- sortOrder edge cases
- copyWith behavior

For `Lesson` model:
- GeneratedBy enum handling
- LessonBlock deserialization
- Default values for blocks, difficulty
- Hive adapter tests

## Acceptance Criteria

1. Create dedicated unit test files matching the pattern:
   - `test/core.data.models.question_model_test.dart`
   - `test/core.data.models.topic_model_test.dart`
   - `test/core.data.models.lesson_model_test.dart`

2. Each test file should include:
   - fromJson edge cases (null fields, type mismatches)
   - toJson round-trip tests
   - copyWith behavior verification
   - Default value tests
   - Hive adapter tests (for HiveType classes)

3. Widget tests for these models should remain but gain confidence from unit tests