# Systemic Repository Test Anti-Pattern: Fakes Tested Instead of Real Implementations

## Context

The project has ~219 test files covering ~212 source files — impressive file-level coverage. However, a large portion of repository tests validate **in-memory fakes that reimplement the repository interface**, never exercising the real Hive-backed logic. This creates a false sense of safety.

## Affected Files

### Purely mock/fake-based tests (no real Hive, no integration group):

| Test File | Mock | Problem |
|---|---|---|
| `test/features/practice/data/repositories/attempt_repository_test.dart` | `_MockAttemptRepository` (full in-memory `Map`) | Zero real logic tested |
| `test/features/practice/data/repositories/mastery_state_repository_test.dart` | `_MockMasteryStateRepository` | Zero real logic tested |
| `test/features/practice/data/repositories/question_choice_repository_test.dart` | `_MockQuestionChoiceRepository` | Zero real logic tested |
| `test/features/practice/data/repositories/spaced_repetition_repository_test.dart` | `_MockSpacedRepetitionRepository` | Zero real logic tested |
| `test/features/practice/data/repositories/question_mastery_state_repository_test.dart` | `_MockQuestionMasteryStateRepository` + fake `Box` | Fake box, no real Hive |
| `test/features/practice/data/repositories/question_evaluation_repository_test.dart` | `_MockQuestionEvaluationRepository` + fake `Box` | Fake box, no real Hive |
| `test/features/practice/data/repositories/topic_dependency_repository_test.dart` | `_MockTopicDependencyRepository` + fake `Box` | Fake box, no real Hive |
| `test/features/practice/data/repositories/mastery_graph_repository_test.dart` | `MasteryGraphRepository.test(…)` with 4 fake boxes | Fake boxes, no real Hive |
| `test/features/subjects/data/repositories/progress_repository_test.dart` | `_MockProgressRepository` | Zero real logic tested |
| `test/features/subjects/data/repositories/topic_repository_test.dart` | `_MockTopicRepository` | Zero real logic tested |
| `test/features/planner/data/repositories/pending_action_repository_test.dart` | `_MockPendingActionRepository` | Zero real logic tested |
| `test/features/planner/data/repositories/roadmap_repository_test.dart` | `_MockRoadmapRepository` | Zero real logic tested |
| `test/features/planner/data/repositories/plan_adherence_repository_test.dart` | `_MockPlanAdherenceRepository` | Zero real logic tested |
| `test/features/planner/data/repositories/engagement_nudge_repository_test.dart` | `_MockEngagementNudgeRepository` | Zero real logic tested |
| `test/features/planner/data/repositories/student_availability_repository_test.dart` | `MockStudentAvailabilityBox` | Fake box, no real Hive |

### Missing test file:

| Source | Location |
|---|---|
| `lib/features/practice/presentation/widgets/practice_sheet_template.dart` | No test file exists anywhere |

### Misplaced tests (inconsistent with conventions & sibling `exam_session_screen_test.dart`):

| Current Location | Correct Location |
|---|---|
| `test/features/practice/presentation/practice_screen_test.dart` | `test/features/practice/presentation/screens/practice_screen_test.dart` |
| `test/features/practice/presentation/practice_results_screen_test.dart` | `test/features/practice/presentation/screens/practice_results_screen_test.dart` |
| `test/features/practice/presentation/practice_session_screen_test.dart` | `test/features/practice/presentation/screens/practice_session_screen_test.dart` |

## Rationale

The mock/fake-based repository tests verify that an **in-memory `Map` with a hand-written CRUD wrapper** works correctly — they do not test the actual `AttemptRepository`, `SpacedRepetitionRepository`, etc. This means:

- **Hive serialization/deserialization** is never exercised for these repositories.
- **Box initialization errors** (`init()` calling `Hive.openBox`) are never tested.
- **Migration scenarios** (adding/removing fields, legacy data) have zero coverage.
- **Null-safety and type coercion** in real Hive reads are not validated.
- **Write conflicts, concurrent access, and deletion cascades** are invisible.

The project already has a working pattern for proper repository testing: `badge_repository_test.dart` (fake box + real Hive `init()` group), `question_repository_test.dart` (unit tests with mock box + Hive integration group), and `lesson_repository_test.dart` show how to do it right.

The `practice_sheet_template_test.dart` gap violates the explicit convention in `AGENTS.md` that every source file must have a test.

The misplaced screen tests create confusion: sibling `exam_session_screen_test.dart` correctly lives under `presentation/screens/`, but 3 other screen tests sit in the parent directory. Tooling and convention-aware developers will not find them in the expected location.

## Acceptance Criteria

1. **Real Hive integration group added to each affected repository test**: Each repository listed above should have a test group that initializes a real Hive instance (temp directory), registers the real adapter, opens the real box, and performs at least one CRUD round-trip. Follow the pattern in `badge_repository_test.dart` (lines 291–358) or `question_repository_test.dart` (lines 727–761).

2. **`practice_sheet_template_test.dart` created**: Tests should verify:
   - Widget renders with title and children
   - `PracticeSheetTemplate.show()` opens a modal bottom sheet
   - Calling `show()` with various children renders correctly
   - Tapping the title area does not dismiss (if applicable)
   - Empty children list renders safely

3. **Three screen tests moved**: `practice_screen_test.dart`, `practice_results_screen_test.dart`, and `practice_session_screen_test.dart` should be moved to `test/features/practice/presentation/screens/` and import paths updated. No test logic should change.

4. **Build/tests pass**: `flutter test` passes with zero failures after all changes.
