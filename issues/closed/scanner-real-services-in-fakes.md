# [Scanner] Real Hive-backed services constructed inside fake classes

**Source:** automatic scanner
**Severity:** major

## Finding

Several test files define fake classes that construct **real backend services** (with real Hive-backed repositories) inside their constructors. This defeats the purpose of fakes — the tests still depend on real Hive initialization, real database access, and potentially real network calls.

Per AGENTS.md: *"Use hand-written fake classes (not mockito/mocktail) for dependency stubbing."* The intent is that fakes should be lightweight in-memory implementations, not wrappers around real infrastructure.

## Locations

### 1. `test/features/teaching/presentation/tutor_screen_test.dart`

The `_FailingTutorService` (lines 84–106) and `_FakeTutorService` (lines 125–147) construct these real services inside `super()`:

- `DatabaseService(...)` with real `TopicRepository()`, `QuestionRepository()`, `AttemptRepository()`, `LessonRepository()`, `SessionRepository()`, `SubjectRepository()`, `ConversationRepository()`, `TutorSessionRepository()`
- `MasteryGraphService()` (real, lines 98, 139)
- `SpacedRepetitionService(questionRepo: QuestionRepository(), attemptRepo: AttemptRepository())` (real, lines 99–102, 140–142)
- `ConversationRepository()` (real, lines 105, 146)

These are **not true fakes** — they construct the entire real dependency tree. If any service tries to open Hive or make network calls, tests would either crash or require heavy setup.

### 2. `test/features/focus_mode/presentation/widgets/inline_practice_widget_test.dart`

`_FakeMasteryRecorder` (lines 72–78) constructs its parent with real `MasteryGraphService()`, `SpacedRepetitionEngine()`, `AttemptRepository()`, `QuestionMasteryStateRepository()`, `QuestionRepository()`.

### 3. `test/features/focus_mode/services/focus_practice_service_test.dart`

`_FakeSpacedRepetitionService` (lines 37–44) passes real `AttemptRepository()` to its super constructor.

### 4. `test/features/planner/services/planner_service_test.dart`

**24+ instances** of `masteryService: MasteryGraphService()` — passes the real `MasteryGraphService()` instead of a lightweight fake. Spread across test groups throughout the 1863-line file.

### 5. `test/features/planner/providers/planner_providers_test.dart`

**6 instances** of `masteryService: MasteryGraphService()` — same pattern.

### 6. `test/features/planner/presentation/planner_screen_test.dart`

Line 294: `masteryService: MasteryGraphService()` — in a widget screen test, this creates a real `MasteryGraphService` that could trigger Hive initialization.

## Impact

- Tests become **brittle** — they can fail due to Hive initialization order, adapter registration, or file system state
- Test execution is **slow** — real database/service initialization adds overhead
- Tests are **not isolated** — shared Hive state between tests can cause order-dependent failures
- If Hive is not initialized before these tests run, they **crash with hard-to-debug errors**

## Recommendation

- Replace all real service constructors (e.g., `MasteryGraphService()`, `SpacedRepetitionService(...)`, etc.) with lightweight hand-written fakes that:
  - Store data in in-memory `List`s or `Map`s
  - Return controlled values without any I/O
  - Do not depend on Hive or any database initialization
- In `tutor_screen_test.dart`, completely rewrite `_FailingTutorService` and `_FakeTutorService` to not chain to real service constructors
- Verify that fake classes in tests override ALL methods that would hit the database
