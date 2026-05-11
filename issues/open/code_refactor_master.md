# Code Refactoring: Model Boilerplate Code Duplication

## Context

The StudyKing codebase contains 20+ HiveObject model classes in `lib/core/data/models/` (and a few in feature directories) that each implement identical `toJson()`, `fromJson()`, and `copyWith()` methods. This creates significant maintenance burden and violates the DRY principle.

## Affected Files

- `lib/core/data/models/question_model.dart` (191 lines, 60+ lines boilerplate)
- `lib/core/data/models/topic_model.dart` (83 lines, ~45 lines boilerplate)
- `lib/core/data/models/study_session_model.dart` (91 lines, ~45 lines boilerplate)
- `lib/core/data/models/markscheme_model.dart` (84 lines, ~50 lines boilerplate)
- `lib/core/data/models/lesson_model.dart` (69 lines, missing copyWith - inconsistent)
- `lib/core/data/models/student_attempt_model.dart` (53 lines, no serialization methods)
- `lib/core/data/models/source_model.dart` (24 lines, no serialization methods)
- `lib/core/data/models/lesson_block_model.dart`
- `lib/core/data/models/topic_progress_model.dart`
- `lib/core/data/models/answer_model.dart`
- `lib/core/data/models/personal_learning_plan_model.dart`
- `lib/core/data/models/mastery_state_model.dart`
- `lib/core/data/models/question_mastery_state_model.dart`
- `lib/core/data/models/topic_dependency_model.dart`
- `lib/core/data/models/question_evaluation_model.dart`
- `lib/core/data/models/task_model.dart`
- `lib/features/subjects/models/subject_model.dart`
- `lib/features/settings/data/models/user_profile_model.dart`

## Rationale

1. **Duplication**: Each model repeats identical serialization/deserialization patterns
2. **Maintenance burden**: Any change to JSON structure requires updating 20+ files
3. **Inconsistency**: Some models have all methods, others have none, some have partial implementations (e.g., `Lesson` missing `copyWith`, `Source` missing JSON methods)
4. **Inconsistent error handling**: `Question.fromJson` has complex fallback logic (`correctAnswer ?? json['correct_answer'] ?? json['answer']`) while other models lack similar resilience

## Acceptance Criteria

1. Create a `JsonSerializableModel` mixin or abstract base class that provides:
   - `Map<String, dynamic> toJson()` method
   - `static T fromJson(Map<String, dynamic> json)` factory method
   - `T copyWith(...)` method using runtime type detection

2. Refactor all affected models to use the new base class/mixin

3. Ensure consistent error handling in `fromJson` across all models

4. Add comprehensive tests for the base class serialization behavior

5. Verify all existing functionality remains intact (run existing test suite)