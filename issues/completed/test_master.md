# Critical Test Coverage Gap: Subjects Feature Has Zero Tests

## Context
The StudyKing project has a dedicated `features/subjects` module that manages subjects, topics, and their relationships. However, **this entire feature has zero test coverage** across all layers.

## Affected Files
- `lib/features/subjects/data/repositories/subject_repository.dart`
- `lib/features/subjects/models/subject_model.dart`
- `lib/features/subjects/presentation/subject_list_view.dart`
- `lib/features/subjects/presentation/subject_selection_screen.dart`
- `lib/features/subjects/presentation/subject_management_screen.dart`
- `lib/features/subjects/presentation/subject_detail_view.dart`
- `lib/features/subjects/presentation/subject_form_widgets.dart`
- `lib/features/subjects/providers/subjects_repository_provider.dart`

## Rationale
1. **SubjectRepository** contains critical business logic:
   - CRUD operations for subjects
   - Topic-subject relationship management (`addTopicToSubject`, `removeTopicFromSubject`)
   - Filtering subjects by topics (`getWithTopics`)
   - Code-based lookups (`getByCode`)
   - Student-subject associations

2. **SubjectModel** is a Hive-persisted model with:
   - JSON serialization/deserialization
   - Deep copy via `copyWith`
   - Custom field handling (optional fields, defaults)

3. **Current state**: No tests exist in `test/features/subjects/` - this is verified by glob search returning zero matches.

4. **Contrast with other features**: The `questions` feature has well-structured tests (e.g., `answer_validator_test.dart` with 550+ lines, model tests). The subjects feature is at equal architectural importance but completely untested.

## Missing Test Scenarios

### SubjectRepository Tests
- `init()`: Handles Hive box initialization
- `getAll()`: Returns all subjects, handles empty box
- `get()`: Returns subject by ID, returns null for non-existent
- `save()`: Creates new subject, updates existing
- `delete()`: Removes subject, handles non-existent ID
- `getWithTopics()`: Filters correctly by topic IDs
- `addTopicToSubject()`: Adds topic without duplicates
- `removeTopicFromSubject()`: Removes topic correctly
- `getByCode()`: Finds subject by code, case sensitivity
- `getStudentSubjects()`: Returns student-specific subjects

### SubjectModel Tests
- Constructor with required/optional fields
- `toJson()`: Produces correct JSON structure
- `fromJson()`: Parses JSON correctly, handles nulls
- `copyWith()`: Creates modified copy correctly
- Hive adapter integration

### Presentation Layer Tests
- Subject list renders correctly
- Subject CRUD operations via UI
- Provider integration

## Acceptance Criteria
1. Create `test/features/subjects/data/repositories/subject_repository_test.dart` with >90% line coverage
2. Create `test/features/subjects/models/subject_model_test.dart` with full model coverage
3. All repository methods must have tests for:
   - Happy path
   - Edge cases (empty data, null returns)
   - Error handling
4. Model tests must verify JSON round-trip for all fields
5. Tests must mock Hive boxes appropriately

## Priority
**HIGH** - This is a core feature with no test coverage, posing significant risk to data integrity and business logic correctness.