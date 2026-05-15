# Future Functionality Plan: Data Model Consolidation & Architectural Debt Resolution

## Context

After a comprehensive audit of the StudyKing codebase (`lib/` and `test/`), several structural issues were identified that reduce maintainability, introduce risk of data corruption, and block future feature development. These issues span the data layer, service layer, and cross-cutting architectural patterns.

None of these issues are surface-level bugs — they are foundational design choices that, if left unaddressed, will compound as new features are added.

---

## Issue 1: Duplicated `NudgeType` Enum — Runtime Bug

**Files affected:**
- `lib/core/data/models/engagement_nudge_model.dart:69` — defines `NudgeType { overwork, revision, planAdjustment, lessonReminder }`
- `lib/core/services/engagement_scheduler.dart:276` — defines `NudgeType { overwork, revision, planAdjustment, lessonReminder, autoRegeneration }`

**Description:**
Two separate `NudgeType` enums exist with the same name but different members. The scheduler creates nudges with `NudgeType.autoRegeneration`, but the model enum (used for Hive serialization/deserialization) does not include `autoRegeneration`. At runtime, when a nudge with type `autoRegeneration` is stored and later deserialized, an enum value-of operation will fail.

**Rationale:**
This is not merely a style issue — it will produce runtime crashes when the engagement scheduler triggers auto-regeneration nudges (e.g., after 7 days of low adherence).

**Acceptance Criteria:**
- A single canonical `NudgeType` enum exists in one location (likely the model file).
- `autoRegeneration` is included in that enum.
- The scheduler references the canonical enum instead of defining its own.
- A test verifies that all nudge types can be serialized/deserialized round-trip.

---

## Issue 2: `Answer` vs `Attempt` Data Model Confusion

**Files affected:**
- `lib/core/data/models/answer_model.dart` — `Answer` model (Hive typeId 3, box `answers`)
- `lib/core/data/models/student_attempt_model.dart` — `StudentAttempt` model (Hive typeId 24, box `attempts`)
- `lib/features/practice/data/repositories/answer_repository.dart` — virtually unused
- `lib/features/practice/data/repositories/attempt_repository.dart` — actively used

**Description:**
The `Answer` model stores predefined correct answer definitions for questions (has `questionId`, `text`, `isCorrect`, `explanation`), but its name implies it stores student-submitted answers. Meanwhile, `StudentAttempt` actually stores student responses. The `AnswerRepository` has only 2 methods (`create`, `getByQuestion`) and is barely referenced in the codebase — it appears to be dead or vestigial code.

This creates confusion for any developer working with the practice/question system: "Should I use `AnswerRepository` or `AttemptRepository`? What is an `Answer` vs an `Attempt`?"

**Rationale:**
Dead code should be removed or repurposed. Ambiguous naming will cause bugs as the system grows. If `Answer` represents a predefined correct answer/choice option, it should be renamed (e.g., `QuestionChoice`, `CorrectAnswer`, `AnswerKey`) and either properly integrated or removed.

**Acceptance Criteria:**
- The purpose of `Answer` model is clarified via rename (e.g., `QuestionChoice`) or integrated into `Question` model's options/markscheme fields.
- `AnswerRepository` is either removed (if truly dead) or fully integrated into the practice/question flow.
- No ambiguity exists between student-submitted responses (`StudentAttempt`) and predefined correct answers.
- Existing tests continue to pass.

---

## Issue 3: Session Model Duplication — Two Session Tracking Systems

**Files affected:**
- `lib/core/data/models/session_model.dart` + `lib/features/sessions/data/repositories/session_repository.dart` — generic `Session`, JSON-serialized, box `sessions`
- `lib/core/data/models/tutor_session_model.dart` + `lib/features/teaching/data/repositories/tutor_session_repository.dart` — `TutorSession`, Hive-annotated, box `tutor_sessions`
- `lib/features/planner/services/planner_service.dart` — uses `TutorSessionRepository` for lesson scheduling
- `lib/features/practice/services/practice_session_service.dart` — uses `SessionRepository` for practice sessions

**Description:**
Two entirely separate session tracking systems exist. `Session` (with `SessionType` enum: practice, focus, tutoring, manual) is used by the practice and focus systems. `TutorSession` (with `SessionStatus` enum: planned, inProgress, completed, cancelled) is used by the teaching system and the planner for lesson scheduling.

Key problems:
- A tutoring session is recorded in `TutorSessionRepository` AND `ConversationRepository` but NOT in `SessionRepository`. This means aggregated study time queries must merge data from 3+ different repositories.
- `SessionRepository.getByStudent()` manually iterates and filters ALL sessions (no Hive indexing), which will become a performance problem at scale.
- `TutorSession` and `Session` have overlapping fields but no shared interface or base class.

**Rationale:**
As the vision demands "track study hours by subject, syllabus progress, performance history, lesson completion", a unified session model is essential. Duplicate session tracking means aggregated dashboards (e.g., "total study time this week") will be incomplete or require complex multi-repository merging.

**Acceptance Criteria:**
- A unified session model (or shared interface/base class) covers tutoring, practice, and focus sessions.
- All session creation flows write to a single canonical session store.
- Aggregated query methods (total study time, session count) work across all session types with a single repository call.
- The existing `TutorSession` and `Session` models can coexist during migration but share a common interface.
- Plan adherence recording uses the unified session model rather than duplicating logic across `recordFromTutorSession`, `recordFromPracticeSession`, `recordFromFocusSession`.

---

## Issue 4: `MasteryGraphRepository` — God Repository Violation

**Files affected:**
- `lib/features/practice/data/repositories/mastery_graph_repository.dart`

**Description:**
`MasteryGraphRepository` manages 4 different entity types across 4 separate Hive boxes within a single class:
- `MasteryState` (box: `mastery_states`)
- `QuestionMasteryState` (box: `question_mastery_states`)
- `TopicDependency` (box: `topic_dependencies`)
- `QuestionEvaluation` (box: `question_evaluations`)

This violates the Single Responsibility Principle. The class is 312 lines long and growing. Each entity type deserves its own dedicated repository.

**Rationale:**
A single repository managing 4 independent entity types means:
- Changes to one entity's storage logic risk breaking all four.
- The class is harder to test, maintain, and extend.
- New developers must understand all 4 entities to work with any one.

**Acceptance Criteria:**
- Each entity type gets its own dedicated repository: `MasteryStateRepository`, `QuestionMasteryStateRepository`, `TopicDependencyRepository`, `QuestionEvaluationRepository`.
- `MasteryGraphRepository` is either removed or refactored into a facade/composite that delegates to the individual repositories.
- `MasteryGraphService` depends on the individual repositories, not the god repository.
- Tests exist for each new repository independently.

---

## Issue 5: `SpacedRepetitionRepository` Operates on `Question` Box — Boundary Violation

**Files affected:**
- `lib/features/practice/data/repositories/spaced_repetition_repository.dart` — `extends Repository<Question>`, opens `HiveBoxNames.questions`
- `lib/features/questions/data/repositories/question_repository.dart` — also `extends Repository<Question>`, opens same `HiveBoxNames.questions`

**Description:**
`SpacedRepetitionRepository` extends `Repository<Question>` and opens the same Hive box (`questions`) that `QuestionRepository` manages. This creates a dual-ownership scenario where two repositories operate on the same underlying data store without coordination. The spaced repetition logic is a query/computation concern, not a data ownership concern.

Additionally, `SpacedRepetitionRepository` contains both static utility methods (`SpacedRepetitionQueries`) and instance methods that duplicate query logic (e.g., `getQuestionsDueForReview` exists as both a static and instance method with different implementations).

**Rationale:**
Two repositories owning the same data box is architecturally unsound — it means there's no single source of truth for question data access. The spaced repetition logic should be a service layer on top of `QuestionRepository`, not a separate repository.

**Acceptance Criteria:**
- `SpacedRepetitionRepository` is renamed to `SpacedRepetitionService` (or similar) and depends on `QuestionRepository` for data access.
- The static `SpacedRepetitionQueries` methods are either inlined into the service or removed (no dead code).
- `SpacedRepetitionRepository` no longer extends `Repository<Question>` or opens the questions Hive box directly.
- All existing functionality is preserved.

---

## Issue 6: Repository `init()` Pattern Fragmentation

**Files affected:**
- `lib/core/data/database_service.dart` — centralizes some inits
- `lib/core/data/repository.dart` — base `openBox()` method
- Nearly every service file calls `.init()` defensively before operations (e.g., `planner_service.dart` calls `await planRepo.init()` inside every method)

**Description:**
There is no guaranteed initialization lifecycle. Repositories are initialized lazily on first use, and every method defensively calls `.init()` before doing work. Some `init()` methods are no-ops (`SessionRepository.init()` is empty). Some bypass `DatabaseService` entirely and init themselves.

This pattern means:
- The `DatabaseService` is not the single source of truth for initialization order.
- Performance cost: `.init()` (which opens a Hive box) may be called many times redundantly.
- If a box fails to open, the error may surface in an unpredictable location (not during app startup).

**Rationale:**
For a production-quality app, the data layer should have a deterministic initialization phase where all boxes are opened and failures are surfaced immediately — not scattered across lazy initialization calls.

**Acceptance Criteria:**
- `DatabaseService` (or equivalent) initializes ALL repositories in a deterministic order during app startup.
- Individual `.init()` calls are removed from service methods (repositories throw if accessed before init).
- `SessionRepository.init()` is implemented properly (currently a no-op despite opening a Hive box internally).
- A startup test verifies all Hive boxes can be opened successfully.

---

## Issue 7: Inconsistent `Result` Pattern Usage

**Files affected:**
- Repositories using `Result<T>`: `QuestionRepository`, `SpacedRepetitionRepository`, `MasteryGraphRepository`
- Repositories NOT using `Result<T>`: `AttemptRepository`, `AnswerRepository`, `TutorSessionRepository`, `ConversationRepository`, `SessionRepository`, `PlanRepository`, `RoadmapRepository`, `PendingActionRepository`, `EngagementNudgeRepository`

**Description:**
Half the repositories wrap responses in `Result<T>` (with `isSuccess`/`isFailure`/`error`), while the other half throw exceptions or return raw values. This means callers must use inconsistent error handling strategies (try/catch in some places, `if (result.isFailure)` in others).

**Rationale:**
Consistent error handling is critical for a reliable application. The mixed pattern creates maintenance burden and increases the risk of unhandled errors.

**Acceptance Criteria:**
- All repositories consistently use `Result<T>` for fallible operations.
- A lint rule or convention document enforces this.
- Existing callers are updated to use consistent error handling.

---

## Issue 8: `PersonalLearningPlanService.generatePlan()` vs `generatePlanFromSyllabus()` — Massive Code Duplication

**Files affected:**
- `lib/core/services/personal_learning_plan_service.dart` — methods `generatePlan()` (lines 73-186) and `generatePlanFromSyllabus()` (lines 188-313)

**Description:**
These two methods share approximately 90% of their code (both ~120 lines of nearly identical logic). The only differences are:
1. `generatePlanFromSyllabus` also fetches syllabus topics and creates recommendations for new topics.
2. `generatePlanFromSyllabus` stores `syllabus_goals` in metadata.

Everything else — topic mastery loading, dependency resolution, recommendation generation, daily plan generation, question linking, summary generation — is duplicated.

**Rationale:**
Code duplication of this magnitude (~200 lines) is a maintainability hazard. Any bug fix or enhancement to plan generation must be applied twice.

**Acceptance Criteria:**
- A shared `_buildPlan({required List<SyllabusGoal>? syllabusGoals, ...})` private method contains the common logic.
- `generatePlan()` and `generatePlanFromSyllabus()` are thin wrappers that provide context-specific setup.
- Behavior is identical for both callers (verified by existing tests).

---

## Issue 9: `PracticeDataService` Depends on `WidgetRef` — Service Anti-pattern

**Files affected:**
- `lib/features/practice/services/practice_data_service.dart` — takes `WidgetRef` in constructor

**Description:**
`PracticeDataService` takes a `WidgetRef` as its constructor argument and reads providers from it internally. This couples a pure data service to the Riverpod dependency injection framework. It means:
- The service cannot be instantiated outside a Riverpod context (e.g., in tests without setting up a `ProviderScope`).
- The service's dependencies are opaque (you can't know what it needs without reading the implementation).
- It breaks the pattern established elsewhere (where services take concrete dependencies via constructor).

**Rationale:**
Clean Architecture dictates that services should depend on abstractions, not on framework injection mechanisms. This service should take `SpacedRepetitionRepository`, `QuestionRepository`, etc. as explicit constructor parameters.

**Acceptance Criteria:**
- `PracticeDataService` takes concrete repository dependencies via constructor.
- `WidgetRef` is removed from the constructor.
- Existing callers pass the required dependencies (read from providers at the call site).
- Tests can instantiate `PracticeDataService` without Riverpod.

---

## Summary of Roadmap Opportunity

Beyond these refactoring issues, the following **feature gaps** exist relative to the product vision:

| Feature | Status |
|---|---|
| Voice conversation (speech-to-text / text-to-speech) | Missing entirely |
| Handwriting/drawing input recognition | Only `canvas_drawing_widget.dart` exists (no interpretation) |
| Content ingestion (PDFs, videos, links, screenshots) | Only `pdf_ingestion_service.dart` exists |
| Lesson recording ("record of how the class went") | Basic session storage exists but no structured lesson report |
| Multiple syllabus tracking simultaneously | Not implemented |
| Token usage tracking per task | `llm_usage_meter.dart` exists but not integrated into task manager |
| Exportable progress (beyond CSV) | No structured export format |
| Localized prompts for different languages | `localization_service.dart` exists but coverage is partial |
| Adaptive practice optimization (beyond simple scheduling) | Only basic interval multipliers exist |

These feature gaps should be evaluated against user needs and prioritized in a separate roadmap exercise.

---

## Priority Assessment

| # | Issue | Impact | Effort | Priority |
|---|---|---|---|---|
| 1 | NudgeType enum duplication | **High** (runtime crash) | Small | P0 |
| 2 | Answer vs Attempt confusion | Medium (developer confusion) | Small | P1 |
| 3 | Session model duplication | High (data fragmentation) | Large | P1 |
| 4 | MasteryGraphRepository God class | Medium (maintainability) | Medium | P2 |
| 5 | SpacedRepetitionRepository boundary violation | Medium (data ownership) | Medium | P2 |
| 6 | Repository init() fragmentation | Medium (fragile startup) | Medium | P2 |
| 7 | Result pattern inconsistency | Low-Medium (error handling) | Large | P3 |
| 8 | Plan generation code duplication | Low-Medium (maintainability) | Medium | P2 |
| 9 | PracticeDataService WidgetRef coupling | Low (testability) | Small | P3 |
