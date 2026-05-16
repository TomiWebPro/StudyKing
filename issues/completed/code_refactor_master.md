# [R] Refactor: Practice feature has mutable models, DI bypasses, hardcoded time dependencies, and inconsistent repository patterns

## Context

A deep audit of `lib/features/practice/` (40 source files, 43 test files) revealed several architectural and code-quality issues that degrade maintainability, testability, and correctness. Below is a consolidated issue covering the most impactful findings.

---

## Issue A: `QuestionMasteryState` has 13 mutable non-final fields — breaks immutability pattern

**File:** `lib/features/practice/data/models/question_mastery_state_model.dart`

**What:** Fields like `correctCount`, `currentStreak`, `masteryLevel`, `lastAttempt`, etc. are declared `non-final` and are mutated in-place by `recordAttempt()` (line 89).

**Rationale:**
- Immutable models are the project convention elsewhere. Mutable models break Riverpod state-change detection (same object reference → no notification).
- `recordAttempt()` calls `DateTime.now()` internally (lines 94, 101, 106, 131, 154) making the logic non-deterministic and untestable without controlling the clock.
- Hive auto-saves every mutation to disk, which is unexpected for a model object.

**Affected:** `lib/features/practice/data/models/question_mastery_state_model.dart`

**Acceptance Criteria:**
- [ ] All fields changed to `final`.
- [ ] `QuestionMasteryState` becomes immutable (use `copyWith` or a sealed class for mutations).
- [ ] `recordAttempt()` returns a new instance instead of mutating.
- [ ] `DateTime` parameters injected instead of calling `DateTime.now()`.

---

## Issue B: Dependency injection is bypassed in providers, screens, and services

### B1. Direct `SubjectRepository()` instantiation

**Files:**
- `lib/features/practice/providers/practice_providers.dart` (line 29)
- `lib/features/practice/presentation/practice_screen.dart` (line 52)

Both manually construct `SubjectRepository()` instead of receiving it through a Riverpod provider.

**Rationale:** Creates a hidden coupling to Hive initialization. The provider test also must deal with a real Hive-backed instance.

### B2. `StudentIdService()` used as a service locator in 4 places

**Files:**
- `lib/features/practice/presentation/practice_screen.dart` (line 127)
- `lib/features/practice/presentation/practice_session_screen.dart` (line 229)
- `lib/features/practice/services/practice_data_service.dart` (line 64)
- `lib/features/practice/services/practice_session_service.dart` (line 71)

All call `StudentIdService().getStudentId()` — a service locator anti-pattern.

**Rationale:** Hard to mock in tests, couples every layer to a global singleton.

### B3. Default parameter concretes (`param ?? ConcreteClass()`)

**Files:**
- `lib/features/practice/services/spaced_repetition_service.dart` (lines 60–64)
- `lib/features/practice/data/repositories/spaced_repetition_repository.dart` (lines 15–23)
- `lib/features/practice/data/repositories/mastery_graph_repository.dart` (lines 24–32)

Pattern: `param ?? ConcreteClass()` — if the caller forgets to pass a dependency, a real Hive-backed object is silently created.

**Rationale:** Silent fallback to real implementations can cause test pollution and mask missing DI wiring.

### B4. `MasteryGraphRepository.test()` constructor creates fresh Hive-backed sub-repos

**File:** `lib/features/practice/data/repositories/mastery_graph_repository.dart` (lines 34–48)

The `.test()` named constructor accepts fake boxes but then creates fresh instances of `MasteryStateRepository()`, `QuestionMasteryStateRepository()`, etc. — which will try to open real Hive boxes.

**Rationale:** Defeats the purpose of a test constructor. Sub-repositories should be injected.

**Acceptance Criteria (for all of B):**
- [ ] Introduce a `subjectRepositoryProvider` Riverpod provider and use it everywhere.
- [ ] All `new SubjectRepository()` calls replaced with provider reads or constructor injection.
- [ ] `StudentId` injected as a parameter or via a Riverpod provider instead of `StudentIdService().getStudentId()`.
- [ ] All `param ?? ConcreteClass()` defaults removed; make parameters required.
- [ ] `MasteryGraphRepository.test()` accepts pre-configured sub-repositories.

---

## Issue C: Hardcoded time dependencies make services untestable

**Files:**
- `lib/features/practice/services/practice_session_service.dart` (lines 31–37)
- `lib/features/practice/presentation/practice_session_screen.dart` (lines 82)

Both use `Timer.periodic(const Duration(seconds: 1), ...)` and `DateTime.now()` directly.

**Rationale:**
- Cannot be mocked or injected → timer tests must run in real time.
- `BuildContext` passed to the service for `formatDurationFromContext` couples it to Flutter's widget tree.
- Two independent 1-second timers track the same elapsed time (service + screen), duplicating logic.

**Affected:**
- `lib/features/practice/services/practice_session_service.dart`
- `lib/features/practice/presentation/practice_session_screen.dart`

**Acceptance Criteria:**
- [ ] `Timer` factory injected into `PracticeSessionService` (e.g., via an abstract `TimerFactory`).
- [ ] `DateTime.now()` replaced with a `Clock` abstraction.
- [ ] Screen timer removed; the service timer is the single source of truth.
- [ ] `BuildContext` removed from the service; duration formatting pushed to the UI layer.

---

## Issue D: Repository pattern is inconsistent

**Findings:**
- Some repositories extend `core/data/repository.dart` → `Repository<T>`, others manage their own `Box<>` fields directly.
- `SessionRepository` (in `sessions/`) uses `Box<String>` with JSON serialization — completely different pattern.
- No abstract repository interfaces exist anywhere (no `lib/domain/` directory) → Clean Architecture violation.
- File/class naming mismatch: `answer_repository.dart` contains `QuestionChoiceRepository`.

**Rationale:** Without a uniform contract, swapping storage backends or writing cross-cutting repository logic requires changes to each repository individually.

**Affected:**
- `lib/features/practice/data/repositories/answer_repository.dart` (naming mismatch)
- `lib/features/sessions/data/repositories/session_repository.dart` (different pattern)
- All 8 repository files under `lib/features/practice/data/repositories/` (partial base-class usage)

**Acceptance Criteria:**
- [ ] Rename file to `question_choice_repository.dart` or class to `AnswerRepository` to resolve mismatch.
- [ ] Define abstract repository interfaces in a `lib/domain/repositories/` directory.
- [ ] All repositories consistently extend `Repository<T>` or implement the domain interface.

---

## Issue E: Provider tests only check type identity, no override coverage

**File:** `test/features/practice/providers/practice_providers_test.dart`

**What:** Uses `ProviderContainer` directly without any `overrides`. Tests only assert `isA<T>()`. The `practiceDataServiceProvider` test spins up a real `SubjectRepository()`.

**Rationale:** Per `AGENTS.md`, provider tests should use `ProviderScope` with `overrides`. Current tests don't verify that overrides work or that provider chains resolve correctly.

**Affected:** `test/features/practice/providers/practice_providers_test.dart`

**Acceptance Criteria:**
- [ ] Rewrite tests using `ProviderScope` with `overrides`.
- [ ] Test that overridden providers are returned correctly.
- [ ] Test provider dependency chains.
