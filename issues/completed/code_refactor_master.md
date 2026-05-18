# Code Quality & Refactoring Master Issue

**Generated:** 2026-05-18 (Second pass — fresh exploration)
**Scope:** Entire `lib/` tree — duplicate typeIds, missing adapters, circular deps, Result pattern violations, dead code, Clock underuse, overlong functions, empty scaffolding

---

## BLOCKER — App crashes or user cannot proceed

### B1. Duplicate `@HiveType(typeId: 26)` — two `Source` models collide

| Severity | BLOCKER |
|----------|---------|
| **Files** | `lib/core/data/models/source_model.dart:4`<br>`lib/features/ingestion/data/models/source_model.dart:4` |
| **Rationale** | Two files define `@HiveType(typeId: 26)` for a class named `Source`. If both adapters were ever registered, Hive would throw a `HiveError: TypeId 26 is already registered`. Currently neither adapter has a `.g.dart` file or explicit `registerAdapter` call, so no crash occurs **yet** — but this is a ticking time bomb. The `ingestion` version has `topicId`, `type`, and `metadata` fields the `core` version lacks. `SourceRepository` (`features/ingestion/data/repositories/source_repository.dart`) opens `Box<Source>`, but with no adapter registered the `openBox` call would fail at runtime. |
| **Acceptance criteria** | 1. Eliminate one `Source` class. The canonical source model should live in `core/data/models/source_model.dart` (since it's imported by `practice`, `questions`, `settings` — cross-feature). The `ingestion` version should be removed or merged.<br>2. Generate a `SourceAdapter` (`source_model.g.dart`) via `build_runner` and register it in `hive_initializer.dart`.<br>3. Verify `SourceRepository.openBox()` works at runtime in a widget test. |

### B2. Missing Hive adapter registrations for three runtime typeIds

| Severity | BLOCKER |
|----------|---------|
| **Files** | `lib/features/planner/data/repositories/engagement_nudge_repository.dart`<br>`lib/features/planner/data/repositories/student_availability_repository.dart`<br>`lib/features/ingestion/data/repositories/source_repository.dart` |
| **Rationale** | Three repositories open typed Hive boxes (`Box<EngagementNudgeModel>`, `Box<StudentAvailabilityModel>`, `Box<Source>`) but no adapter is registered for any of these types:<br><br>- `EngagementNudgeModel` uses `typeId: 32` — no `.g.dart`, no `registerAdapter` call in any production code<br>- `StudentAvailabilityModel` uses `typeId: 35` — same situation<br>- `Source` uses `typeId: 26` — same situation<br><br>These `openBox` calls will throw `HiveError` at runtime on first access. Only unit tests (which create ad-hoc boxes without registration) pass; production will crash. |
| **Acceptance criteria** | 1. Generate `.g.dart` files for all three models.<br>2. Register all three adapters in `hive_initializer.dart`.<br>3. Widget test proves `EngagementNudgeRepository`, `StudentAvailabilityRepository`, and `SourceRepository` can open their boxes without error. |

---

## MAJOR — Feature is broken or misleading

### M1. Three circular dependency chains between features

| Severity | MAJOR |
|----------|-------|
| **Chain #1: sessions ↔ planner ↔ practice** | |
| | `sessions/session_tracker_screen.dart` imports `planner/data/repositories/plan_adherence_repository.dart` and `planner/data/repositories/plan_repository.dart` |
| | `planner/planner_service.dart` and `planner/syllabus_resolver.dart` import `practice/data/repositories/mastery_graph_repository.dart` and `practice/data/models/mastery_state_model.dart` |
| | `practice/practice_providers.dart`, `practice/practice_session_service.dart`, `practice/exam_session_service.dart` import `sessions/providers/session_providers.dart` and `sessions/data/repositories/session_repository.dart` |
| **Chain #2: questions ↔ practice** | |
| | `questions/question_bank_screen.dart` imports `practice/providers/practice_providers.dart` |
| | `practice/practice_providers.dart` imports `questions/providers/question_providers.dart` |
| **Chain #3: ingestion ↔ questions** | |
| | `ingestion/content_library_screen.dart`, `ingestion/source_detail_screen.dart`, `ingestion/content_pipeline.dart`, `ingestion/ingestion_providers.dart` import `questions/data/repositories/question_repository.dart` |
| | `questions/question_bank_screen.dart`, `questions/question_providers.dart` import `ingestion/data/models/source_model.dart` and `ingestion/data/repositories/source_repository.dart` |
| **Rationale** | These cycles mean the features cannot be extracted into standalone packages. A change in any one feature can silently break consumers in another feature. At import time there's no cycle (Dart allows this), but architectural coupling makes module isolation impossible. |
| **Acceptance criteria** | 1. Break each cycle by introducing a `core/data/contracts/` interface or event bus that features depend on instead of depending on each other directly.<br>2. Verify with `dart analyze` that no feature imports from another feature **except** through a core abstraction.<br>3. Document the defined dependency direction (e.g. `practice → sessions` via abstract contract, not concrete class). |

### M2. `Clock` abstraction defined but ignored in ~50 locations

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/utils/clock.dart` defines `Clock` and `SystemClock` |
| | **Only consumer:** `lib/core/services/cross_feature_integrator.dart` (lines 42, 55) |
| | **Ignored in 17+ files** with direct `DateTime.now()` calls (~50 total): `mastery_calculation_service.dart` (7), `llm_task_manager.dart` (5), `personal_learning_plan_service.dart` (8), `engagement_scheduler.dart` (8), `study_progress_tracker.dart` (2), `badge_service.dart` (1), `progress_export_service.dart` (3), `conversation_memory.dart` (4), `plan_adapter.dart` (1), `instrumentation_service.dart` (4), `llm_chat_service.dart` (1), `logger.dart` (1), `id_generator.dart` (1), `session_model.dart` (1), `subject_model.dart` (1), `session_adapter.dart` (1), `llm_usage_meter.dart` (1) |
| **Rationale** | Direct `DateTime.now()` calls are **untestable** — you cannot control what time it is during a unit test. The `Clock` abstraction exists precisely to solve this. With ~50 untestable time references, any test that depends on relative time (e.g. "was this session within the last hour?") is either skipped, flaky, or uses `fakeAsync` workarounds. |
| **Acceptance criteria** | 1. Every `DateTime.now()` call in production services is replaced with `_clock.now()` where `_clock` is injected via constructor.<br>2. Every class uses `Clock get clock => SystemClock()` as default but allows override.<br>3. Existing provider declarations use `clockProvider` (already exists at `lib/features/teaching/providers/teaching_providers.dart:19`) or a new `core`-level clock provider.<br>4. All existing tests continue to pass (or become simpler by injecting `FakeClock`). |

### M3. 18 files use raw `try/catch` + `Result.failure` instead of `Result.capture`

| Severity | MAJOR |
|----------|-------|
| **Files** | `subject_repository.dart` (4 methods), `settings_repository.dart` (15+ methods), `question_repository.dart` (8), `question_mastery_state_repository.dart` (5), `mastery_state_repository.dart` (7), `lesson_repository.dart` (6), `spaced_repetition_service.dart` (8), `mastery_recorder.dart` (1), `study_timer_service.dart` (2), `syllabus_resolver.dart` (3), `topic_readiness_service.dart` (1), `plan_adapter.dart` (3), `data_backup_service.dart` (3), `content_pipeline.dart` (2), `instrumentation_service.dart` (2), `cross_feature_integrator.dart` (1), `llm_embeddings_service.dart` (1), `llm_chat_service.dart` (3) |
| **Rationale** | `Result.capture(Future<T> Function() block)` wraps the function body, catches exceptions, logs them with context, and returns `Result.failure(error)`. These 18 files manually write `try { ... } catch (e) { return Result.failure(e.toString()); }` instead, losing the logging context and creating an inconsistent code style. 4 additional files (`topic_repository.dart`, `attempt_repository.dart`, `tutor_session_repository.dart`, `engagement_nudge_repository.dart`) **mix** `Result.capture` and raw `try/catch` within the same class, making the pattern even harder to follow. |
| **Acceptance criteria** | 1. Convert every raw `try/catch` + `Result.failure` in these files to use `Result.capture(...)` or `Result.captureSync(...)` wrapping the entire method body.<br>2. No file has both raw `try/catch` AND `Result.capture` — pick one pattern per file (prefer `Result.capture`).<br>3. Full test suite passes. |

### M4. 11 `rethrow` statements completely bypass the Result pattern

| Severity | MAJOR |
|----------|-------|
| **Files** | `question_repository.dart:17`, `question_mastery_state_repository.dart:15`, `mastery_state_repository.dart:15`, `lesson_repository.dart:16`, `question_evaluation_repository.dart:15`, `topic_dependency_repository.dart:16`, `mastery_graph_repository.dart:68`, `database_service.dart:46`, `llm_chat_service.dart:243,349,458` |
| **Rationale** | These `init()` and stream methods catch errors, log them, then `rethrow`. This means the exception propagates upward **outside** any `Result.capture` context, uncaught. The caller (often a Riverpod provider) crashes with an unhandled exception instead of receiving a `Result.failure`. This defeats the entire purpose of using `Result<T>` as the error channel. |
| **Acceptance criteria** | 1. Replace every `catch (e) { ... rethrow; }` in repository `init()` methods with `Result.captureSync(() { ... })` that returns `Result.failure` instead of throwing.<br>2. Stream methods that `rethrow` should emit an error event or use a `Result` stream type.<br>3. Callers that currently assume `init()` throws should be updated to handle `Result.failure`. |

### M5. Non-Result return types silently swallow Result failures (12+ files)

| Severity | MAJOR |
|----------|-------|
| **Files & patterns** | |
| | `CrossFeatureIntegrator` — 4 `Future<void>` methods (`recordTutorSessionAsSession`, `linkPracticeSessionToSource`, `linkSourceToTopic`, `notifyPlannerOfNewContent`) call `_sessionRepo.save()` via `Result` but discard the result |
| | `PlanAdapter` — `recordFromFocusSession`, `recordFromPracticeSession`, `recordFromTutorSession` return `void`, silently ignoring `_planService.recordDailyAdherence()` failures |
| | `StudyTimerService` — `startSession()` returns `Future<Session>` with `.data ?? default` on error, losing error info |
| | `DashboardService` — `getOverallStats()`, `getWeeklyTrend()`, `getFocusStats()` return raw types with `??` fallbacks that hide failures |
| | `MasteryImprovementTracker` — all methods return plain types, no Result wrapping |
| **Rationale** | When a method returns `Future<void>` or `Future<SomeType>` (not `Result<SomeType>`), any internal `Result` failure has nowhere to go. The error is silently dropped. Downstream consumers see `null`, `[]`, or `0` and have no way to distinguish "no data yet" from "operation failed". |
| **Acceptance criteria** | 1. All public methods that perform I/O and currently return `void`/raw types should return `Result<void>` or `Result<List<T>>` etc.<br>2. Callers must handle the `Result` — at minimum log the error.<br>3. Exception: UI-layer methods that intentionally swallow errors to show a default state should have a comment explaining why. |

### M6. `AppErrorHandler` completely disconnected from `Result` type

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/errors/result.dart` — defines `Result<T>` with `.error: String?`<br>`lib/core/errors/handlers.dart` — defines `AppErrorHandler` with `handleError(context, Object error, ...)`<br>`lib/core/errors/exceptions.dart` — defines `AppException` with `ExceptionType` enum |
| **Rationale** | The three error-handling components are siloed:<br><br>1. `Result.failure(error)` stores a raw `String?` — no structured type info<br>2. `AppErrorHandler` accepts `Object error` and string-matches to classify into `ExceptionType`<br>3. `AppException` carries structured `type: ExceptionType` but is never produced by `Result`<br><br>When a repository returns `Result.failure('OpenRouter API Error: 401')`, the caller cannot automatically turn it into a localized SnackBar. They must manually re-parse the string. This means `Result` errors are often ignored at the UI layer because converting them to user-friendly messages is too much boilerplate. |
| **Acceptance criteria** | 1. Change `Result.failure` to accept `Object? error` (or `AppException?`), not just `String?`.<br>2. Add `AppErrorHandler.fromResult(Result result)` that extracts and displays the error.<br>3. Create a `ResultUIProvider` or similar Riverpod utility that watches a `Result` and auto-shows a SnackBar on failure.<br>4. Document the error flow: `service → Result → AppErrorHandler → SnackBar`. |

### M7. `BadgeService` <-> `StudyProgressTracker` runtime circular reference

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/services/badge_service.dart:18` — `BadgeService(StudyProgressTracker? tracker)`<br>`lib/core/services/study_progress_tracker.dart:224-238` — `getBadges()` creates `BadgeService(tracker: this)` |
| **Rationale** | At runtime, `StudyProgressTracker.getBadges()` creates `BadgeService(tracker: this)`. The `BadgeService` holds a reference back to the tracker. While not a compile-time cycle, this creates a tangled object graph where each service knows about the other's internals. It works today only because `BadgeService.getBadges()` calls `_tracker.getOverallStats()` (which does NOT call `getBadges`), but any future maintainer could innocently add a call that creates infinite recursion. |
| **Acceptance criteria** | 1. Extract the dependency: `BadgeService` should accept a `Future<OverallStats>` function parameter instead of the entire `StudyProgressTracker`.<br>2. OR merge `BadgeService` into `StudyProgressTracker` since `getBadges()` is the only consumer.<br>3. Widget test verifies badges can be computed with a fake stats function. |

### M8. Four overlong functions (120-190 lines)

| Severity | MAJOR |
|----------|-------|
| **Files & functions** | |
| | `lib/core/services/progress_export_service.dart` — `exportComprehensivePDF()` is **190 lines** |
| | `lib/core/services/personal_learning_plan_service.dart` — `_buildPlan()` is **133 lines**, `_generateDailyPlans()` is **121 lines** |
| | `lib/core/services/engagement_scheduler.dart` — `_sendNudgeNotifications()` is **118 lines** |
| | `lib/core/providers/app_providers.dart` — `SettingsController.updateSettings()` is **73 lines** with **23 named parameters** |
| **Rationale** | Functions >60 lines violate single-responsibility principle. They are impossible to unit-test thoroughly (too many paths), hard to review in PRs, and risky to refactor. The `exportComprehensivePDF` function at 190 lines is particularly egregious — it likely mixes PDF layout, data querying, and error handling in one monolithic block. |
| **Acceptance criteria** | 1. Break each function into private helpers, each under 30 lines.<br>2. `updateSettings` should split into multiple methods (e.g. `updateTheme`, `updateFontSize`, `updateApiKey`).<br>3. No function in `lib/` exceeds 60 lines (subjective, but a good target).<br>4. Full test suite passes. |

### M9. `MasteryGraphRepository` is a redundant facade (172 lines of pure delegation)

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/features/practice/data/repositories/mastery_graph_repository.dart` (172 lines) |
| **Rationale** | `MasteryGraphRepository` extends `Repository<MasteryState>` but overrides ZERO methods from the base class. Every single public method is a one-line delegation to `masteryStateRepo`, `questionMasteryRepo`, `topicDependencyRepo`, or `questionEvaluationRepo`. The comment at line 16 says: "New code should depend on the specific repositories directly." This is an admission that the facade itself should not exist. It adds an extra layer of indirection with no value — it doesn't combine results, enforce invariants, or provide caching. |
| **Acceptance criteria** | 1. Inline the 10+ delegation methods at every call site.<br>2. Or replace `MasteryGraphRepository` with the individual repositories directly in providers.<br>3. Delete `mastery_graph_repository.dart`.<br>4. Full test suite passes (update any mocks that depend on `MasteryGraphRepository`). |

### M10. `EngagementSchedulerProvider` creates all dependencies inline (untestable)

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/providers/app_providers.dart:295-313` |
| **Rationale** | The provider creates every dependency with `new` constructors — `StudyProgressTracker()`, `MasteryGraphService()`, `EngagementNudgeRepository()`, `PlanAdherenceRepository()`, `PlanAdapter()`, `SessionRepository()`, `PlannerService()` — instead of reading them from existing Riverpod providers. This means `ProviderScope(overrides: [...])` has no effect on these inner `new` calls. `MasteryGraphService()` is created twice (lines 299 and 302). |
| **Acceptance criteria** | 1. Every dependency is read from its own provider via `ref.watch(...)`.<br>2. A widget test overrides exactly one inner dependency and proves the scheduler uses the override.<br>3. No `new` constructor calls remain inside the provider body. |

### M11. Inconsistent error strings in `Result.failure` — fragile string-based flow control

| Severity | MAJOR |
|----------|-------|
| **Files** | All files using `Result.failure(...)` — ~139 uses across the codebase |
| **Rationale** | Error strings in `Result.failure` have no convention:<br><br>- Programmatic keys: `'box_closed'`, `'not_found'`<br>- PascalCase with underscores: `'Question_box_not_open'`, `'Backup_not_found: $filePath'`<br>- Descriptive English: `'Failed to get: $e'`, `'API key is empty'`<br>- Raw API responses: `'OpenRouter API Error: ${response.body}'`<br><br>If any caller checks `result.error == 'box_closed'` for flow control (and some do), a refactored error message silently breaks the logic. |
| **Acceptance criteria** | 1. Introduce typed error codes (e.g., an `ErrorCode` enum) and store them alongside the message in `Result.failure`.<br>2. All `Result.failure` calls use a structured `Result.failure(ErrorCode.databaseOpenFailed, 'box_closed')` or similar.<br>3. All flow-control checks use the typed code, not string comparison.<br>4. Human-readable messages are generated at the UI layer via `AppErrorHandler`. |

---

## MINOR — Code quality / UX friction

### m1. Dead production code — 3 items never imported outside tests

| Severity | MINOR |
|----------|-------|
| **Items** | |
| 1 | `lib/core/services/session_plan_adherence_service.dart` (23 lines) + `lib/core/data/contracts/plan_adherence_contract.dart` (7 lines) — only imported in test files |
| 2 | `lib/features/subjects/data/models/topic_progress_model.dart` (51 lines) — never imported by any `lib/` file, only in `test/` |
| 3 | `lib/features/llm_tasks/data/`, `lib/features/llm_tasks/providers/`, `lib/features/llm_tasks/services/` — three empty directories (dead scaffolding) |
| **Rationale** | 81 lines of dead source code plus three empty directories that confuse developers searching for LLM task logic. The `TopicProgress` model is **not** the same as `MasteryState` — it was a predecessor that was never removed. |
| **Acceptance criteria** | 1. Delete `session_plan_adherence_service.dart`, `plan_adherence_contract.dart`, and `topic_progress_model.dart`.<br>2. Remove the three empty `llm_tasks` subdirectories.<br>3. Run `dart analyze` — zero new warnings.<br>4. Remove or update any test files that reference these deleted items. |

### m2. Orphaned providers — 5 declared but never consumed in production

| Severity | MINOR |
|----------|-------|
| **Providers** | |
| | `lib/features/sessions/providers/session_providers.dart` — `allSessionsProvider` (line 13), `todayStatsProvider` (line 17) — file comments say "Orphaned: consumed only in tests" |
| | `lib/features/planner/providers/planner_providers.dart` — `actionExecutorProvider` (line 17) — ZERO imports anywhere in the entire codebase (not even tests) |
| | `lib/features/mentor/providers/mentor_providers.dart` — `mentorPendingActionRepoProvider` (line 24) — no production consumer |
| | `lib/features/teaching/providers/teaching_providers.dart` — `promptsProvider` (line 47) — only consumed in tests |
| **Rationale** | Unused providers are misleading dead code. They suggest available state that doesn't exist in practice. `actionExecutorProvider` is especially egregious — it was probably created during a refactor and never wired in. These providers still hold `Provider` declarations that run at app startup, consuming minimal-but-real initialization time. |
| **Acceptance criteria** | 1. Remove each orphaned provider **unless** a legitimate consumer is planned within the next sprint (document with a comment).<br>2. Run `dart analyze` — zero new warnings.<br>3. Update any test file that only tests the orphaned provider (delete or inline the test). |

### m3. Three core widgets exported from barrel but never used in production

| Severity | MINOR |
|----------|-------|
| **Widgets** | `lib/core/widgets/empty_state_widget.dart`, `lib/core/widgets/error_retry_widget.dart`, `lib/core/widgets/loading_indicator.dart` |
| **Rationale** | These widgets are re-exported via `lib/core/widgets/widgets.dart` (lines 3, 4, 6) but no production file ever references `EmptyStateWidget`, `ErrorRetryWidget`, or `LoadingIndicator`. They are only used in their own test files. Meanwhile, `lib/core/widgets/loading_screen.dart` is used (in `app_router.dart`). |
| **Acceptance criteria** | 1. Either remove the three unused widget files and their barrel exports, OR wire them into production screens (e.g., replace ad-hoc loading/spinner code with the shared widget).<br>2. Update the barrel file if removed.<br>3. Full test suite passes. |

### m4. Massive screen files — `settings_screen.dart` at 1441 lines

| Severity | MINOR |
|----------|-------|
| **Files** | |
| | `lib/features/settings/presentation/settings_screen.dart` — **1,441 lines**, 37 imports |
| | `lib/features/planner/presentation/planner_screen.dart` — **946 lines** |
| | `lib/features/focus_mode/presentation/focus_timer_screen.dart` — **841 lines** |
| | `lib/features/practice/presentation/screens/practice_screen.dart` — **801 lines** |
| | `lib/features/settings/presentation/profile_screen.dart` — **~600 lines** |
| **Rationale** | Files over 500 lines are hard to navigate, review, and test. The `settings_screen.dart` at 1,441 lines with 37 imports is a maintenance nightmare — it includes debug/developer tools alongside production settings, making it impossible to tell which code runs in production. `dart analyze` may take noticeably longer on this file alone. |
| **Acceptance criteria** | 1. Extract logical sections into separate widget files (as done in `dashboard/presentation/widgets/` and `practice/presentation/widgets/`).<br>2. No screen file exceeds 500 lines.<br>3. No build method exceeds 10 levels of widget nesting.<br>4. Full test suite passes. |

### m5. `settingsLoadingProvider` never set to `true`

| Severity | MINOR |
|----------|-------|
| **Files** | `lib/core/providers/app_providers.dart:263` — declaration<br>`lib/main.dart:150` — consumer |
| **Rationale** | `settingsLoadingProvider` is a `StateProvider<bool>` initialized to `false`. No code ever sets it to `true`. `main.dart:150` watches it for a loading indicator — meaning the loading state is always `false` and users see no feedback during async settings init. |
| **Acceptance criteria** | 1. Set `.state = true` before async init calls and `.state = false` after completion.<br>2. Or remove the provider entirely (and the UI code that watches it) if loading is fast enough to skip.<br>3. Widget test verifies the loading state transitions. |

### m6. `features/features.dart` meta-barrel only used in test

| Severity | MINOR |
|----------|-------|
| **File** | `lib/features/features.dart` — re-exports all 14 feature barrels |
| **Rationale** | This meta-barrel is only imported by `test/features/features_barrel_test.dart`. No production file imports it. It's 15 lines of dead re-export that adds to import resolution time during analysis. |
| **Acceptance criteria** | 1. Either remove `features/features.dart` and update the lone test consumer, or keep it if intended as a convenience barrel for integration tests (add a comment explaining the scope). |

### m7. `hive_type_ids.dart` coverage gaps — typeIds 25 and 26 missing

| Severity | MINOR |
|----------|-------|
| **Files** | `lib/core/data/hive_type_ids.dart` — typeIds 25 and 26 are absent from the `_typeId*` constants and the `_allTypeIds` validation list |
| **Missing typeIds** | |
| | `25` — used by `MilestoneModel` in `lib/features/planner/data/models/roadmap_model.dart:108` |
| | `26` — used by both `Source` models (see B1) |
| **Rationale** | `hive_type_ids.dart` has a `validateHiveTypeIds()` function (line 75-87) that checks for duplicates in the `_allTypeIds` list. If typeIds are missing from this list, the validation is incomplete — a future developer could accidentally reuse typeId 25 or 26 without being caught. |
| **Acceptance criteria** | 1. Add `_typeIdMilestoneModel = 25` and `_typeIdSource = 26` to `hive_type_ids.dart`.<br>2. Add them to the `_allTypeIds` list.<br>3. Run the `validateHiveTypeIds()` call on app startup (already called in `hive_initializer.dart:64`). |

### m8. `session_adapter.dart` hardcodes typeId 36 instead of referencing `hive_type_ids.dart`

| Severity | MINOR |
|----------|-------|
| **File** | `lib/core/data/session_adapter.dart:6` — `@HiveType(typeId: 36)` |
| **Rationale** | All other adapters and models should reference named constants from `hive_type_ids.dart`. Hardcoding `36` means a reader must cross-reference to understand which typeId this is, and a rename requires searching for the magic number. |
| **Acceptance criteria** | 1. Define `const sessionTypeId = 36` in `hive_type_ids.dart`.<br>2. Reference it as `@HiveType(typeId: sessionTypeId)` in `session_adapter.dart`.<br>3. Remove the magic literal. |

### m9. `Logger._verbose` global mutable state

| Severity | MINOR |
|----------|-------|
| **File** | `lib/core/utils/logger.dart:41-48` — `static bool _verbose = false`, `static void setVerbose(bool v)` |
| **Rationale** | Global mutable state (`static`) means any code can change the verbosity level at any time, affecting all Logger instances. This is not thread-safe and makes tests non-hermetic — one test can change verbosity and another test's log output changes. |
| **Acceptance criteria** | 1. Make `_verbose` an instance variable passed via constructor.<br>2. Provide a provider (`verboseLoggingProvider`) instead of a static setter.<br>3. Update `main.dart` to set it via provider override.<br>4. Existing tests should not be affected (create logger with default verbose=false). |

### m10. `id_generator.dart` uses `DateTime.now()` and mutable static counter

| Severity | MINOR |
|----------|-------|
| **File** | `lib/core/utils/id_generator.dart:6` — `DateTime.now().millisecondsSinceEpoch` + `_counter++` |
| **Rationale** | The ID generator is untestable: `DateTime.now()` produces a different value on every call, and `_counter` is a global static. Two tests that generate IDs in the same process get different results, making assertions impossible. The `Clock` abstraction should be used here. |
| **Acceptance criteria** | 1. Accept `Clock? clock` parameter (default `SystemClock()`) in `generateId()` or the class constructor.<br>2. Replace `DateTime.now()` with `_clock.now()`.<br>3. Remove the mutable `_counter` or make it instance-level.<br>4. Update tests to inject `FakeClock`. |

### m11. `updateSettings()` — 23 named parameters on one method

| Severity | MINOR |
|----------|-------|
| **File** | `lib/core/providers/app_providers.dart:70-143` — `SettingsController.updateSettings()` |
| **Rationale** | A method with 23 named parameters is nearly impossible to call correctly. It violates the single-responsibility principle and the Interface Segregation Principle. Adding one new setting requires modifying this monster method. |
| **Acceptance criteria** | 1. Split into individual methods: `updateTheme(ThemeMode)`, `updateFontSize(double)`, `updateApiKey(String)`, `updateLocale(Locale)`, etc.<br>2. Or use a `SettingsUpdate` object with only the changed fields.<br>3. Each individual method is under 10 lines.<br>4. All call sites updated. |

---

## Summary

| Severity | Count | Labels |
|----------|-------|--------|
| BLOCKER | 2 | `duplicate-typeid`, `missing-adapter` |
| MAJOR | 11 | `circular-dep`, `clock-abstraction`, `result-pattern-violation`, `rethrow`, `silent-swallow`, `apperrorhandler-gap`, `circular-ref`, `overlong-function`, `redundant-facade`, `untestable-provider`, `error-string-convention` |
| MINOR | 11 | `dead-code`, `orphaned-provider`, `unused-widget`, `massive-screen`, `dead-loading-provider`, `dead-barrel`, `typeid-coverage`, `magic-typeid`, `global-mutable-state`, `untestable-idgen`, `over-parameterized` |
| **Total** | **24** | |

### Quick-win items (single-file changes, high confidence):

1. **m1** — Delete 3 dead-code files + 3 empty dirs → ~81 lines removed
2. **m2** — Remove 5 orphaned providers → ~50 lines removed
3. **m3** — Remove 3 unused widgets → ~120 lines removed
4. **m5** — Wire `settingsLoadingProvider` or remove it → 1 file
5. **m7** — Add missing typeIds to `hive_type_ids.dart` → 1 file, 2 lines added
6. **m8** — Reference typeId constant instead of magic number → 2 files, 2 lines changed
