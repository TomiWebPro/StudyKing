# Code Quality & Architecture Refactoring

**Severity Assessment:** This issue consolidates findings across dead code, circular dependencies, complex functions, inconsistent error handling, redundant abstractions, file placement violations, hardcoded configuration, and repeated patterns. Fix order should prioritize BLOCKER items first, then MAJOR, then MINOR.

---

## BLOCKER — App crashes or silent data loss

### B1. Silent Error Swallowing (34 `catch (_) {}` instances)

**Context:** Empty catch blocks throughout the codebase silently discard errors with no logging, state update, or user feedback. This is the single most dangerous pattern in the codebase.

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart` — **8 instances** (lines 100, 161, 196, 370, 438, 617, 627, 637, 647, 757, 766): Silently fails on plan build, adherence recording, redistribution, topic title/resolve/readiness/urgency/subjectId lookups, and adherence queries.
- `lib/features/planner/providers/planner_providers.dart` — **5 instances** (lines 226, 237, 246, 253, 260, 484): Silently fails on plan loading, pending actions, scheduled lessons, adherence checks, roadmap linking.
- `lib/features/planner/services/planner_service.dart` — **5 instances** (lines 265, 278, 292, 307, 317): Silently fails on lesson scheduling, cancellation, fetching, and action acceptance/dismissal.
- `lib/core/services/plan_adapter.dart` — **2 instances** (lines 213, 264): Returns default values on failure without logging.
- `lib/main.dart:142` — Silently swallows profile loading errors at startup.
- `lib/core/providers/app_providers.dart:229` — Silently swallows locale resolution errors.
- `lib/features/mentor/services/mentor_service.dart:113,139` — Silently fails on plan/adherence data gathering for context prompts.
- `lib/features/teaching/services/tutor_service.dart:121,148` — Silently fails on plan adherence and session save.
- `lib/core/services/badge_service.dart:59` — Silently fails on badge loading.
- `lib/features/lessons/presentation/lesson_list_screen.dart:76` — Silent failure on lesson list load.
- `lib/features/sessions/presentation/session_tracker_screen.dart:197,211` — Silent failure on session tracking.
- `lib/features/teaching/services/voice_controller.dart:108,138` — Silent failure on voice operations.
- `lib/core/data/extraction/transcription_extractor.dart:212,219` — Silent failure on transcription.
- `lib/core/data/extraction/pdf_extractor.dart:67` — Silent failure on PDF extraction.
- `lib/features/ingestion/presentation/upload_screen.dart:60` — Silent failure on upload.
- `lib/features/settings/presentation/settings_screen.dart:400` — Silent failure on settings save.

**Rationale:** Silent catches make the app appear to work while silently dropping critical errors. A user's study plan may fail to build, their progress data may not save, and errors in the learning pipeline are entirely invisible — both to the user and to developers (no logs).

**Acceptance criteria:**
- [ ] Every `catch (_) {}` block replaced with either: (a) `_logger.e(...)` + meaningful recovery, (b) rethrow, or (c) user-facing error state update.
- [ ] All `catch (e) {}` with no body resolved.
- [ ] No silent error swallowing remains in the codebase.

### B2. Circular Dependency: `core/services/` imports `features/planner/services/`

**File:** `lib/core/services/personal_learning_plan_service.dart:8`
**Chain:** `planner_service.dart` → `personal_learning_plan_service.dart` → `syllabus_resolver.dart`

**Context:** `PersonalLearningPlanService` (in `core/services/`) directly imports `SyllabusResolver` from `features/planner/services/syllabus_resolver.dart`. This is a textbook layer violation — core must never depend on features. It creates Cycles 1 and 4 from the analysis:
- `planner_service.dart` → `personal_learning_plan_service.dart` → `syllabus_resolver.dart`
- `mentor_service.dart` → `planner_service.dart` → `personal_learning_plan_service.dart` → `syllabus_resolver.dart`

**Rationale:** This circular chain means changes to `syllabus_resolver.dart` can break core services, and vice versa. It breaks Dart's import graph and makes testing impossible without circular mock setup. Dependency injection is the fix.

**Acceptance criteria:**
- [ ] Extract `SyllabusResolver` interface/abstract class into `core/services/` or a shared `core/interfaces/` directory.
- [ ] Move implementation details to `features/planner/services/` if they are planner-specific.
- [ ] `PersonalLearningPlanService` depends only on the abstract interface.
- [ ] Concrete resolver injected via constructor / provider overrides.
- [ ] Verify no `core/` → `features/` import chain remains for this dependency.

### B3. Mutual Circular Dependency: `planner_service.dart` ↔ `action_executor.dart`

**Files:**
- `lib/features/planner/services/planner_service.dart:20` imports `action_executor.dart`
- `lib/features/planner/services/action_executor.dart:2` imports `planner_service.dart`

**Context:** `PlannerService` holds an `ActionExecutor` which takes `PlannerService` in its constructor. These two files in the same directory have a direct mutual dependency. They cannot be instantiated or tested independently.

**Rationale:** Mutual circular dependencies violate the single-responsibility principle — if A needs B and B needs A, their responsibilities are not properly separated. This makes unit testing impossible without shared instances and creates brittle coupling.

**Acceptance criteria:**
- [ ] Break the cycle by one of: (a) extracting shared logic into a third class both depend on, (b) passing callbacks/interfaces instead of the full `PlannerService` reference, or (c) merging the two classes if they truly share a single responsibility.
- [ ] `action_executor.dart` should not import `planner_service.dart`.
- [ ] All unit tests pass with independently mockable dependencies.

---

## MAJOR — Feature broken, misleading behavior, or maintainability hazard

### M1. Dead / Unreachable Code

**M1a. Dead classes and services (never imported or referenced in `lib/`):**

| # | File | Symbol |
|---|---|---|
| 1 | `lib/core/services/topic_readiness_service.dart` | `TopicReadinessService`, `TopicReadinessResult` |
| 2 | `lib/core/services/data_backup_service.dart` | `DataBackupService` |
| 3 | `lib/core/services/question_generation_service.dart` | `QuestionGenerationService`, `GenerationResult`, `GenerationException` |
| 4 | `lib/features/dashboard/services/dashboard_service.dart` | `DashboardService` |
| 5 | `lib/features/practice/data/repositories/question_choice_repository.dart` | `QuestionChoiceRepository` |
| 6 | `lib/features/practice/data/models/answer_model.dart` | `QuestionChoice` |
| 7 | `lib/core/extensions/iterable_extensions.dart` | `IterableExtension<T>` |
| 8 | `lib/core/data/database_migration.dart` | `validateSchema()`, `DatabaseValidationResult` |
| 9 | `lib/core/constants/app_storage_config.dart` | `StorageConfig` |

**M1b. Unused public fields/constants:**

| # | File | Symbol |
|---|---|---|
| 10 | `lib/core/constants/app_api_config.dart:11-12` | `ApiSecrets.googleApiKey`, `ApiSecrets.whisperApiKey` |
| 11 | `lib/core/constants/app_api_config.dart:62-63` | `ApiConfig.youtubeBaseUrl`, `ApiConfig.youtubeRequestTimeout` |
| 12 | `lib/core/constants/security_config.dart:7` | `SecurityConfig.sessionTimeout` |
| 13 | `lib/core/constants/app_config.dart:70` | `AppConfig.debugLogSnapshot()` |
| 14 | `lib/core/constants/app_config.dart:48,58` | `AppConfig.redactSensitiveValues()`, `AppConfig.redactedRuntimeSnapshot()` |

**M1c. Deprecated-but-present wrappers:**

| # | File | Symbol | Reason |
|---|---|---|---|
| 15 | `lib/features/practice/data/repositories/mastery_graph_repository.dart` | `MasteryGraphRepository` | Deprecated in its own doc comment; pure delegation to 4 sub-repos |
| 16 | `lib/features/practice/data/repositories/spaced_repetition_repository.dart` | `SpacedRepetitionRepository` | `@Deprecated('Use SpacedRepetitionService directly')` but still referenced |
| 17 | `lib/features/subjects/data/repositories/progress_repository.dart` | `ProgressRepository` | `@Deprecated('Use MasteryStateRepository instead')` |

**M1d. Unused barrel files (never imported by anything in `lib/`):**

All feature-level barrel files (`lib/features/*/*.dart`) are unused — 16 files total. Also `lib/core/core.dart`, `lib/core/utils/utils.dart`, `lib/features/features.dart`, and internal data barrel files `lib/features/planner/data/planner_data.dart`, `lib/features/practice/data/practice_data.dart`.

**Rationale:** Dead code creates maintenance burden (devs wonder if it's used), increases cognitive load, and inflates codebase size. The deprecated wrappers (`MasteryGraphRepository`, `SpacedRepetitionRepository`) are particularly harmful because new code might accidentally depend on them.

**Acceptance criteria:**
- [ ] All dead classes/services/files removed, with one removal per commit for auditability.
- [ ] `MasteryGraphRepository` removed and all consumers migrated to sub-repositories directly.
- [ ] `SpacedRepetitionRepository` removed and `PracticeSessionService` depends on `SpacedRepetitionService` directly.
- [ ] `ProgressRepository` removed (verify zero references remain).
- [ ] Unused barrel files removed. Verify all current direct imports still work (they import individual files, so removal is safe).
- [ ] Confirm `lib/main.dart:12` and `:14` don't silently break — consolidate to direct imports of only what's needed.

### M2. Wrong-Direction Imports: 15 Core Service Files Import from Features

**Files in `core/services/` that import from `features/*/`:**

1. `personal_learning_plan_service.dart` → features/practice, features/subjects, features/planner, features/questions
2. `mastery_graph_service.dart` → features/practice (4 repos, 2 models), features/questions (1 model)
3. `plan_adapter.dart` → features/planner (1 repo, 1 model)
4. `study_progress_tracker.dart` → features/practice (1 repo, 1 model)
5. `mastery_integration_service.dart` → features/practice (2 models, 1 repo)
6. `instrumentation_service.dart` → features/practice (2 repos, 2 models), features/planner (1 repo, 1 model)
7. `engagement_scheduler.dart` → features/planner (2 repos, 1 model), features/sessions (1 repo)
8. `topic_readiness_service.dart` → features/subjects (1 repo, 1 model), features/practice (1 repo, 1 model)
9. `badge_service.dart` → features/dashboard (1 repo, 1 model), features/practice (1 repo)
10. `conversation_memory.dart` → features/teaching (1 repo, 1 model)
11. `progress_export_service.dart` → features/practice (1 model, 1 repo)
12. `mastery_calculation_service.dart` → features/practice (1 model)
13. `question_generation_service.dart` → features/questions (2 models, 1 repo)
14. `answer_validation_service.dart` → features/questions (2 models)
15. `cross_feature_integrator.dart` → features/ingestion (1 repo), features/sessions (1 repo)

Also `core/data/database_service.dart` imports from 6 feature data layers.
Also `core/data/hive_initializer.dart` imports `features/sessions/services/session_migration_service.dart`.
Also `core/data/models/question_model.dart` imports from `features/questions/data/models/`.

**Rationale:** The entire `core/services/` directory has the wrong dependency direction. Core services should define interfaces/abstractions that feature services implement. Instead, core services reach directly into feature data layers, creating tight coupling and making features undeployable independently. This violates the fundamental principle of layered architecture.

**Acceptance criteria:**
- [ ] Audit each of the 15 core services: does it contain true cross-cutting logic, or is it feature-specific logic in the wrong place?
- [ ] Move clearly feature-specific services: `personal_learning_plan_service.dart` and `plan_adapter.dart` → `features/planner/services/`; `mastery_graph_service.dart`, `mastery_calculation_service.dart`, `mastery_integration_service.dart` → `features/practice/services/`; `conversation_memory.dart` → `features/teaching/services/`; `topic_readiness_service.dart` → `features/subjects/services/`.
- [ ] For remaining core services, define abstract interfaces in `core/services/` and inject feature implementations via constructor/provider.
- [ ] `core/data/models/question_model.dart` moved to `features/questions/data/models/`.
- [ ] All imports re-verified to ensure no `core/` → `features/` dependency remains after refactor.

### M3. Inconsistent Error Handling (Result Type vs Raw Throws)

**Context:** The codebase has a `Result<T>` sealed class in `lib/core/errors/result.dart` used by many repositories and services, but other parts (especially LLM services) throw bare `Exception(...)`.

**Pattern clashes:**

1. **`lib/core/services/llm/llm_chat_service.dart`** — All 6 public/private methods (`_callOpenRouter`, `_callOllama`, `_callOpenAI`, `_streamOpenRouter`, `_streamOllama`, `_streamOpenAI`) throw bare `Exception('ProviderName API Error: ...')`. No typed exceptions, no `Result<T>` wrapping. Consumed by modules that DO use `Result<T>` (e.g., `content_pipeline.dart`), forcing callers to catch raw exceptions.

2. **`lib/core/services/llm/llm_embeddings_service.dart:71`** — `throw Exception('Embedding API Error: ...')`.

3. **`lib/features/dashboard/presentation/widgets/export_section.dart:94-95`** — Calls `instrumentation.getInstrumentationDashboard()` which returns `Result<Map>`, then immediately converts to `throw Exception(result.error)` — mixing patterns at the call site.

4. **`lib/core/services/pdf_ingestion_service.dart`** — Public methods return `Result<T>`, but private helper `_parseContent()` throws `PdfIngestionException`.

5. **`lib/core/services/question_generation_service.dart`** — Defines its OWN `GenerationResult<T>` separate from the standard `Result<T>`, creating a second parallel result system.

6. **`lib/core/constants/app_api_config.dart`, `app_build_config.dart`, `app_config.dart`, `security_config.dart`** — All throw `StateError(...)` for configuration validation, which is a different concern than operational errors.

**Rationale:** Developers must know which pattern a given method uses to handle errors correctly. Mixed patterns cause runtime crashes when exceptions propagate through Result-handling code unwrapped. The custom `GenerationResult` is an unnecessary fork.

**Acceptance criteria:**
- [ ] All `throw Exception(...)` in `llm_chat_service.dart` replaced with typed exceptions from `lib/core/errors/exceptions.dart` (e.g., `LlmException`, `NetworkException`), OR wrapped in `Result<T>`.
- [ ] `llm_embeddings_service.dart:71` uses typed exception or Result.
- [ ] `export_section.dart:94-95` propagates `Result.failure` instead of converting to throw.
- [ ] `pdf_ingestion_service.dart`: private helpers consistently return `Result<T>` or use typed exceptions — not both.
- [ ] `question_generation_service.dart`: merge `GenerationResult<T>` into standard `Result<T>` or remove entirely.
- [ ] Config validation throws in `app_api_config.dart`, `app_build_config.dart`, `app_config.dart`, `security_config.dart` moved to a single consistent approach (e.g., `ConfigValidationException`).

### M4. Repositories Violating `Result<T>` Convention

**Files that do NOT wrap public methods in `Result<T>`** (per the convention stated in `lib/core/data/repository.dart:4-5`):

- `lib/features/practice/data/repositories/attempt_repository.dart`
- `lib/features/subjects/data/repositories/subject_repository.dart`
- `lib/features/subjects/data/repositories/topic_repository.dart`
- `lib/features/ingestion/data/repositories/source_repository.dart`
- `lib/features/dashboard/data/repositories/badge_repository.dart`
- `lib/features/planner/data/repositories/plan_repository.dart`
- `lib/features/planner/data/repositories/roadmap_repository.dart`
- `lib/features/planner/data/repositories/pending_action_repository.dart`
- `lib/features/planner/data/repositories/plan_adherence_repository.dart`
- `lib/features/planner/data/repositories/engagement_nudge_repository.dart`

**Rationale:** Inconsistent return types. Some callers may expect `Result<T>` and miss errors when repositories simply return raw values or throw.

**Acceptance criteria:**
- [ ] All listed repositories wrap public method return types in `Result<T>` following the codebase convention.
- [ ] Callers updated to handle `Result<T>` appropriately.

### M5. `SessionRepository` and `TopicDependencyRepository` Not Extending `Repository<T>`

**Files:**
- `lib/features/sessions/data/repositories/session_repository.dart` — Manually manages `late Box<Session> _box` and reimplements `save`/`get`/`getAll`/`delete` from scratch (19 methods, ~237 lines).
- `lib/features/practice/data/repositories/topic_dependency_repository.dart` — Manually manages `late Box<TopicDependency> _box` (lines 9-56).
- `lib/features/settings/data/repositories/settings_repository.dart` — Same pattern.

**Rationale:** The base `Repository<T>` class provides all CRUD operations. Not extending it means ~100 lines of duplicated boilerplate across these 3 files. `SessionRepository` in particular could be reduced from 19 custom methods to ~5 truly unique methods.

**Acceptance criteria:**
- [ ] `SessionRepository` refactored to extend `Repository<Session>`. Only the truly unique methods (not in the base class) remain.
- [ ] `TopicDependencyRepository` refactored to extend `Repository<TopicDependency>`.
- [ ] `SettingsRepository` refactored to extend `Repository<Settings>` or similar.
- [ ] All tests pass after refactoring.

### M6. Duplicate `MasteryGraphService` Instances in `DashboardService`

**File:** `lib/features/dashboard/services/dashboard_service.dart:28-37`

The constructor creates dependencies inline:
```dart
MasteryGraphService(),  // line 29 — first instance
StudyProgressTracker(attemptRepo: AttemptRepository(), masteryService: MasteryGraphService()),  // line 32 — second instance!
```

**Context:** Two separate `MasteryGraphService` instances are created. The first is stored in `_masteryService`, the second is nested inside `_progressTracker`. This means the progress tracker and dashboard service operate on different in-memory state — an actual bug, not a cosmetic issue.

**Rationale:** Single-instance invariant is violated. If `MasteryGraphService` holds any in-memory cache (which it does, via its repository references), the two instances have divergent state.

**Acceptance criteria:**
- [ ] `DashboardService` constructor receives shared `MasteryGraphService` instance (via dependency injection).
- [ ] `StudyProgressTracker` receives the same `MasteryGraphService` instance.
- [ ] `Provider` definitions in `lib/features/dashboard/providers/dashboard_providers.dart` updated to wire shared instances.

### M7. SM-2 Serialization Code Duplicated

**Files:**
- `lib/features/practice/services/spaced_repetition_service.dart:147-173` — `_deserializeSrData()` and `_serializeSrData()`
- `lib/features/practice/services/mastery_recorder.dart:115-141` — identical `_deserializeSrData()` and `_serializeSrData()`

**Rationale:** DRY violation. Any change to SM-2 data format must be made in two files in sync.

**Acceptance criteria:**
- [ ] Extract serialization/deserialization methods into `QuestionSRData` model class or a shared utility.
- [ ] Both files import and use the shared methods.

### M8. 15 Overly Long / Complex Functions Violating SRP

**Functions exceeding ~50 lines with multiple responsibilities:**

| # | Function | File | Lines | Key Issue |
|---|---|---|---|---|
| 1 | `exportComprehensivePDF()` | `core/services/progress_export_service.dart` | 189 | 6 major sections in one function |
| 2 | `_buildContextPrompt()` | `features/mentor/services/mentor_service.dart` | 130 | Gathers data from 6+ services, ~20 conditionals |
| 3 | `_buildPlan()` | `core/services/personal_learning_plan_service.dart` | 111 | Orchestrates 8+ sub-steps directly |
| 4 | `_generateDailyPlans()` | `core/services/personal_learning_plan_service.dart` | 121 | Mixes scheduling, data fetch, readiness checks |
| 5 | `_sendNudgeNotifications()` | `core/services/engagement_scheduler.dart` | 101 | 5 nudge types in one function |
| 6 | `processFullPipeline()` | `features/ingestion/services/content_pipeline.dart` | 132 | 4-5 stages in one function |
| 7 | `checkWellbeingAndGenerateNudges()` | `features/mentor/services/mentor_service.dart` | 74 | 4 nudge types + streak tracking |
| 8 | `_showProgressReport()` | `features/mentor/presentation/mentor_screen.dart` | 185 | 5 UI sections in one dialog builder |
| 9 | `_buildStudyPlanTab()` | `features/planner/presentation/planner_screen.dart` | 128 | 6+ UI sections in one method |
| 10 | `createRoadmap()` | `features/planner/services/planner_service.dart` | 62 | Calculation + persistence mixed |
| 11 | `endLesson()` | `features/teaching/services/tutor_service.dart` | 60 | 6 persistence steps in one function |
| 12 | `exportComprehensiveCSV()` | `core/services/progress_export_service.dart` | 61 | Data fetch + 5 CSV sections mixed |
| 13 | `recordAttempt()` | `core/services/mastery_calculation_service.dart` | 72 | Updates 12+ fields directly |
| 14 | `_streamOpenRouter/Ollama/OpenAI()` | `core/services/llm/llm_chat_service.dart` | ~60 each | HTTP + parsing + task mgmt mixed in each |
| 15 | `validateWithEvaluation()` | `core/services/answer_validation_service.dart` | 52 | 4 matching strategies combined |

**Rationale:** Long functions are hard to test, hard to reason about, and hide bugs. Each function should do one thing.

**Acceptance criteria (per function):**
- [ ] Each function split into smaller single-responsibility methods (aim: ≤30 lines per method).
- [ ] Each split method has a clear name describing its single responsibility.
- [ ] Widget functions (M8.8, M8.9) extract UI sections into separate widget classes.
- [ ] `_streamOpenRouter/Ollama/OpenAI` extract HTTP streaming + SSE parsing into a shared utility.
- [ ] All existing tests pass, and new tests cover extracted methods where appropriate.

### M9. `MasteryStateModel` Misplaced in `features/practice/`

**File:** `lib/features/practice/data/models/mastery_state_model.dart`

**Context:** Imported by **8 core services** (engagement_scheduler, personal_learning_plan, study_progress_tracker, mastery_graph_service, mastery_calculation_service, topic_readiness_service, progress_export_service, instrumentation_service) and 6+ other feature files. This is a core domain model used pervasively across the codebase — it should not live in a single feature folder.

**Cross-feature model placement issues:**

- `lib/features/practice/data/models/mastery_state_model.dart` — used by 8 core services → should be in `lib/core/data/models/`
- `lib/features/practice/data/models/question_mastery_state_model.dart` — used by 2 core services → should be in `lib/core/data/models/`
- `lib/features/practice/data/repositories/mastery_graph_repository.dart` — core data concept used by 5+ core services → should be `lib/core/data/repositories/`
- `lib/features/practice/data/repositories/mastery_state_repository.dart` — cross-cutting repo → should be `lib/core/data/repositories/`
- `lib/features/practice/data/repositories/question_mastery_state_repository.dart` — cross-cutting repo → should be `lib/core/data/repositories/`

**Rationale:** Per AGENTS.md file placement conventions, core concepts should live in `lib/core/`. When a model/repo is used by 5+ core services, it is unequivocally a core concern. Leaving it in a feature folder invites circular dependencies and violates separation of concerns.

**Acceptance criteria:**
- [ ] `MasteryStateModel` moved to `lib/core/data/models/`.
- [ ] `QuestionMasteryStateModel` moved to `lib/core/data/models/`.
- [ ] `MasteryGraphRepository`, `MasteryStateRepository`, `QuestionMasteryStateRepository` moved to `lib/core/data/repositories/`.
- [ ] All imports across the codebase updated.
- [ ] Hive adapter registration in `hive_initializer.dart` updated with new paths.

---

## MINOR — Code quality / UX friction

### m1. 30+ Magic Numbers Duplicated Across Services

**Context:** Threshold values like accuracy thresholds (0.6, 0.8, 0.9), attempt counts (3, 5, 10), day boundaries (3, 7, 30), study minute caps (15, 30, 52), and adherence ratios (0.3, 0.5, 0.7, 1.2) are duplicated across `mastery_calculation_service.dart`, `study_progress_tracker.dart`, `personal_learning_plan_service.dart`, `plan_adapter.dart`, `engagement_scheduler.dart`, `mentor_service.dart`, and `planner_service.dart`.

**Key clumps of duplicated magic numbers:**

| Constant Concept | Duplicated In | Values |
|---|---|---|
| Mastery level thresholds (accuracy × attempts) | `mastery_calculation_service.dart:103-108`, `study_progress_tracker.dart:236` | (0.9,10), (0.8,5), (0.6,3) |
| Review urgency day boundaries | `mastery_calculation_service.dart:151-161` | 0.1, 0.3, 0.5, 0.7, 0.9 |
| Adherence thresholds | `plan_adapter.dart:200-208`, `personal_learning_plan_service.dart:355-362` | 0.3, 0.5, 0.7, 1.2 |
| Streak thresholds | `mentor_service.dart:211-213`, `personal_learning_plan_service.dart:224` | 3, 7 |
| Consecutive low days | `plan_adapter.dart:56-66`, `engagement_scheduler.dart:254` | 3, 7 |
| Daily nudge / question caps | `mentor_service.dart:379`, `planner_service.dart:106` | 5, 15 |

**Rationale:** If a threshold changes, developers must find and update every copy. There is no single source of truth.

**Acceptance criteria:**
- [ ] Centralize all learning-related constants in `lib/core/constants/learning_constants.dart` (or similar).
- [ ] Centralize adherence-related constants in `lib/core/constants/planning_constants.dart`.
- [ ] All services reference the centralized constants instead of inline literals.
- [ ] Constants named descriptively (e.g., `expertAccuracyThreshold = 0.9`, `expertMinAttempts = 10`).

### m2. `toStringAsFixed()` Violations in User-Facing Contexts

**Per AGENTS.md: "Never use `toStringAsFixed()` for user-facing numeric displays."**

**Violations:**
- `lib/features/mentor/services/mentor_service.dart:158` — `adherenceDeviation.averageAdherence.toStringAsFixed(1)` — in LLM prompt building (user-facing)
- `lib/features/mentor/services/mentor_service.dart:198` — `(topic.accuracy * 100).toStringAsFixed(0)` — in LLM prompt building (user-facing)
- `lib/features/teaching/services/conversation_manager.dart:272` — `adaptivePace.toStringAsFixed(1)` — tutor note visible to student
- `lib/features/teaching/services/prompts/prompts.dart:170` — same adaptive pace

**Acceptance criteria:**
- [ ] `mentor_service.dart:158,198` replaced with `formatPercent` from `number_format_utils.dart`.
- [ ] `conversation_manager.dart:272` and `prompts.dart:170` replaced with `formatDecimal` or `formatPercent`.
- [ ] Note: `progress_export_service.dart` and `study_progress_tracker.dart` usages for CSV export are acceptable per AGENTS.md (CSV is data, not display).

### m3. Trivial Delegate Methods in Repositories

**Files with methods that pass through to parent `Repository<T>` with no added logic:**

- `lib/features/teaching/data/repositories/tutor_session_repository.dart:15-16`: `saveSession` → `create()`
- `lib/features/teaching/data/repositories/conversation_repository.dart:14-15`: `saveMessage` → `create()`
- `lib/features/planner/data/repositories/plan_repository.dart:14-15`: `savePlan` → `create()`
- `lib/features/planner/data/repositories/roadmap_repository.dart:14-15`: `saveRoadmap` → `create()`

Also in `lib/features/sessions/services/study_timer_service.dart:179-202` — 5 read-method delegations (`getTodayDurationMs`, `getTodaySessionCount`, `getTodayCompletedSessionCount`, `getTodayStats`, `getRecentSessions`) that add zero business logic.

**Rationale:** These methods add noise. If a method does nothing but call `super.create(key, item)`, callers should call `create()` directly.

**Acceptance criteria:**
- [ ] Inline consumers of `savePlan`/`loadPlan`/`deletePlan` to use `Repository.create`/`get`/`delete` directly, or keep named methods if they improve readability.
- [ ] Remove trivial delegations from `study_timer_service.dart`; consumers access `SessionRepository` directly for read-only queries.
- [ ] Each removal verified with grep: no remaining callers.

### m4. Outdated and Misleading Comments

| File | Line | Issue |
|---|---|---|
| `lib/core/constants/app_api_config.dart:30` | `// TODO(security): prefer runtime secret injection (keystore/native layer)` | Only TODO in the codebase, tracks known security debt |
| `lib/core/services/engagement_scheduler.dart:297` | `// NudgeType and NudgeSeverity are imported from engagement_nudge_model.dart` | Redundant — the import is at the top of the file and is standard Dart |
| `lib/core/constants/app_constants.dart:3-4` | Comment says prefer the barrel file, but barrel files throughout the codebase are unused | Partially outdated |
| `lib/core/services/question_generation_service.dart:198` | Prompt says `"For stepByStep: ..."` but `_parseQuestionType` maps `stepbystep`/`step_by_step` to `QuestionType.stepByStep` | Casing mismatch between prompt comment and actual parsing |
| `lib/core/services/mastery_graph_repository.dart:15-16` | Doc comment says "New code should depend on the specific repositories directly" | Self-declared deprecated, but still widely used |

**Acceptance criteria:**
- [ ] All redundant/obvious comments removed.
- [ ] `// TODO` either resolved (implement runtime secret injection) or moved to a proper issue tracker.
- [ ] Prompt/parsing casing mismatch in `question_generation_service.dart` fixed.
- [ ] Deprecated comments in `mastery_graph_repository.dart` resolved (remove the file per M1).

### m5. Wrong Log Levels

**Context:** The project has `_logger.w()` (warn) vs `_logger.e()` (error). Several places use `w()` for operational failures that actually represent errors.

| File | Lines | Issue |
|---|---|---|
| `lib/features/sessions/data/repositories/session_repository.dart` | 19 instances throughout | Hive read/write failures logged as `w()` — should be `e()` |
| `lib/core/services/engagement_scheduler.dart` | 8 instances (110, 136, 158, 170, 189, 200, 213, 263) | Nudge generation/notification failures logged as `w()` — these are operational errors |
| `lib/features/mentor/services/mentor_service.dart` | 4 instances (382, 466, 501, 516) | "Failed to check wellbeing", "Failed to handle intent" — all `w()` but are actual errors |
| `lib/main.dart:98` | "Failed to init EngagementScheduler" — `w()` but is a startup error |
| `lib/core/services/study_progress_tracker.dart` | 4 instances (188, 208, 228, 241) | `w()` for getOverallStats/getBadges/getWeakTopics failures — data loss events should be `e()` |
| `lib/features/practice/services/mastery_recorder.dart:84` | Mastery recording failure logged as `w()` — significant data loss should be `e()` |

**Rationale:** Wrong log levels make production monitoring difficult — true errors are invisible if logged as warnings, and ops teams tune alerts based on level.

**Acceptance criteria:**
- [ ] All "Failed to ..." operational failures that prevent intended functionality changed to `_logger.e()`.
- [ ] `session_repository.dart` Hive read/write failures changed to `_logger.e()`.
- [ ] Startup errors in `main.dart` changed to `_logger.e()`.

### m6. Hardcoded Configuration Values

**API and network configuration:**

| File | Line(s) | Value | Issue |
|---|---|---|---|
| `lib/core/constants/app_api_config.dart` | 56-58 | `openRouterBaseUrlString`, `ollamaDefaultUrl`, `openAIDefaultUrl` | Compile-time constants; should be runtime-configurable via env vars |
| `lib/core/services/llm/llm_embeddings_service.dart` | 23-30 | Fallback URL duplicates of `app_api_config.dart` | Duplicated defaults |
| `lib/core/constants/app_api_config.dart` | 73-89 | Per-environment timeouts (45s/90s/60s) | Should be env-configurable |
| `lib/core/services/question_generation_service.dart` | 17-18 | `maxRetries = 3`, `retryDelay = Duration(seconds: 2)` | Business-level config |

**Feature flags and business logic:**

| File | Line(s) | Issue |
|---|---|---|
| `lib/core/constants/app_runtime_config.dart:7` | `defaultNotificationsEnabled = true` | Cannot be overridden |
| `lib/core/services/engagement_scheduler.dart:22` | `studentIds = const ['default']` | Hardcoded default student ID |
| `lib/features/practice/services/spaced_repetition_engine.dart:89` | `useFSRS = false` | FSRS toggle hardcoded |
| `lib/features/mentor/services/mentor_service.dart:65` | `maxTurns: 50` | Conversation memory limit hardcoded |

**File paths:**

| File | Line(s) | Issue |
|---|---|---|
| `lib/core/constants/app_storage_config.dart:9-13` | `databaseName`, `hiveBoxName`, `tempDirectoryName`, etc. | Reasonable defaults but no env override |
| `lib/features/mentor/services/mentor_service.dart:276` | `await Hive.openBox('settings')` | Box name as string literal instead of referencing config constant |
| `lib/core/services/data_backup_service.dart:23` | `'studyking_backup'` | Backup filename hardcoded |

**Magic number configs (consolidated from m1):** All learning/adherence/spaced-repetition thresholds (3, 7, 30 days; 0.6, 0.8, 0.9 accuracy; 5, 10, 15 limits).

**Rationale:** Hardcoded values prevent runtime configuration, make testing against non-production environments harder, and create deployment inflexibility.

**Acceptance criteria:**
- [ ] API base URLs, timeouts, retry policies moved to a `Config` class populated from environment variables (e.g., `Platform.environment` or `.env` file loaded at startup).
- [ ] Duplicate fallback URLs in `llm_embeddings_service.dart` removed; reference `ApiConfig` exclusively.
- [ ] Feature flags (`defaultNotificationsEnabled`, `useFSRS`) moved to a configurable provider.
- [ ] `studentIds` in `engagement_scheduler.dart` made injectable via constructor.
- [ ] `maxTurns` in `mentor_service.dart` made configurable (constructor or provider).
- [ ] Hive box name `'settings'` in `mentor_service.dart:276` replaced with constant reference.
- [ ] All magic number thresholds centralized per `m1`.

### m7. `QuestionGenerationService` Custom Result Type

**File:** `lib/core/services/question_generation_service.dart:353-367`

Defines `GenerationResult<T>` and `GenerationException` as a separate result system parallel to the standard `lib/core/errors/result.dart`.

**Rationale:** Two parallel Result types create confusion. New developers must learn both systems. The `GenerationResult` is essentially identical to `Result` but cannot be used with generic `Result`-handling code.

**Acceptance criteria:**
- [ ] `GenerationResult<T>` replaced with standard `Result<T>` from `lib/core/errors/result.dart`.
- [ ] `GenerationException` moved to `lib/core/errors/exceptions.dart` (or removed if all error paths use `Result.failure`).
- [ ] All call sites updated.

### m8. `PracticeAnswerRecord` Duplicates `StudentAttempt`

**Files:**
- `lib/features/practice/data/models/practice_models.dart:3-17` — `PracticeAnswerRecord` (questionId, questionType, isCorrect, timeSpent, userAnswer)
- `lib/features/practice/data/models/student_attempt_model.dart` — `StudentAttempt` (id, studentId, questionId, subjectId, isCorrect, timeSpentMs, confidence, timestamp, userAnswer, markschemeMatch, lastDueDate)

**Context:** `PracticeAnswerRecord` is a subset of `StudentAttempt` fields. It is used in `PracticeSessionService` and `ExamSessionService` as a transient value type.

**Rationale:** Duplicate model creates confusion about which to use and requires mapping between them.

**Acceptance criteria:**
- [ ] Replace `PracticeAnswerRecord` usage with `StudentAttempt` where feasible, or extract a shared value type if `StudentAttempt` is too heavy.
- [ ] Remove `PracticeAnswerRecord` if no remaining references.

### m9. `TutorSession` Model Duplicates `Session` + `TutorMetadata`

**Files:**
- `lib/features/teaching/data/models/tutor_session_model.dart` — `TutorSession`
- `lib/core/data/models/session_model.dart` + `TutorMetadata`

Significant field overlap (id, studentId, subjectId, topicId, startTime, endTime, status, tutorNotes/tutorMetadata.tutorNotes, topicsCovered, totalMessages, totalTokensUsed, confidenceRating). `TutorSession` adds `topicTitle`, `lessonPlanJson`, `questionsAsked`, `questionsCorrect` — which `TutorMetadata` already holds.

**Rationale:** Tutor sessions are stored in a separate Hive box (`tutorSessions`) instead of using the core `Session` model with `type: SessionType.tutoring`. This duplicates schema, repository code, and creates cross-feature querying challenges (e.g., "get all sessions" misses tutor sessions).

**Acceptance criteria:**
- [ ] Audit whether `TutorSession` can be folded into `Session` with `type: SessionType.tutoring` + populated `TutorMetadata`.
- [ ] If kept separate, at minimum remove overlapping fields and reference `TutorMetadata` from core.
- [ ] Update repositories, providers, and presentation code accordingly.

### m10. Provider Boilerplate Repetition

**File:** `lib/features/practice/providers/practice_providers.dart:23-130` — 14 near-identical `Provider<Xxx>` definitions (~110 lines).

**Context:** Every provider follows the same pattern:
```dart
final xxxProvider = Provider<Xxx>((ref) => Xxx());
```

**Rationale:** Repetitive boilerplate that could be consolidated.

**Acceptance criteria:**
- [ ] Investigate whether a provider registry/factory or code generation could reduce this.
- [ ] At minimum, ensure each provider is actually consumed (remove unused ones).
- [ ] Consider grouping related providers into fewer composite providers.

---

## Implementation Order

| Priority | Items | Effort Estimate | Dependencies |
|---|---|---|---|
| **Phase 1** | B1 (silent catches), B2 (circular core→feature), B3 (circular planner←→action) | 2-3 days | None |
| **Phase 2** | M1 (dead code removal), M2 (wrong-direction imports), M4 (Result convention), M5 (Repository<T> base class) | 3-4 days | Phase 1 |
| **Phase 3** | M3 (error handling consistency), M6 (duplicate instances), M7 (SM-2 dedup), M8 (complex function decomposition) | 4-5 days | Phase 2 |
| **Phase 4** | M9 (model/repo placement), m1-m10 (all minors) | 3-4 days | Phase 3 |
| **Phase 5** | Lint, type checks, full test suite pass | 1 day | All prior phases |

**Total estimated effort: 13-17 developer-days.**

---

## Verification

After each phase:
1. Run `dart analyze` — zero new warnings.
2. Run `dart run test` — all existing tests pass.
3. Run the app on both emulator and device — smoke test core flows (login, study plan, practice, mentor chat).
4. For Phase 2 (moves/removals), verify with `grep -r "old_import_path" lib/` that no stale references remain.
