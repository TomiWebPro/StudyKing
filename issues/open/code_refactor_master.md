# Code Refactor Master — Architecture & Quality Audit

**Generated:** 2026-05-18
**Scope:** Full codebase audit (315 lib/ files, 331 test/ files)
**Analysis areas:** Dead code, circular deps, SRP violations, error handling inconsistency, redundant abstractions, file placement, hardcoded configs, log levels, repeated patterns

---

## BLOCKER — App crashes or user cannot proceed

### B1. Silent catch blocks swallow fatal errors (`catch (_) {}`)

**Context:** 11+ locations catch exceptions with empty bodies or `catch (_) {}` that silently discard errors. The user receives no feedback and the app appears to do nothing.

| File | Line | Impact |
|---|---|---|
| `lib/features/mentor/presentation/mentor_screen.dart` | 144 | `_loadSuggestedAction()` — user sees blank area with no retry |
| `lib/features/mentor/presentation/mentor_screen.dart` | 291 | `_sendMessage()` — message appears sent but is lost |
| `lib/features/ingestion/presentation/source_detail_screen.dart` | 217 | Reprocess silently fails — user thinks content was reprocessed |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | 77 | Lesson list silently fails to load |
| `lib/features/mentor/services/mentor_service.dart` | 367 | Study streak silently returns 0 |
| `lib/features/practice/services/spaced_repetition_service.dart` | 162 | SR data deserialization silently falls back to defaults |
| `lib/core/services/answer_validation_service.dart` | 457 | Validation error silently returns empty result |
| `lib/features/settings/presentation/api_config_screen.dart` | 90 | Config test silently fails |
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | 232, 282 | Canvas operations silently fail |
| `lib/features/dashboard/data/models/badge_model.dart` | 119 | Badge data silently returns null |

**Rationale:** Errors in catch blocks have the highest user impact in presentation layers because they leave the UI in a stale/unresponsive state. An LLM message that appears sent but isn't is a UX blocker.

**Fix:**
- Remove bare `catch (_) {}` — at minimum log every caught exception
- In presentation-layer catches, show a SnackBar via `AppErrorHandler.handleError()` or set an error state
- Define a lint rule banning empty catch blocks

---

### B2. Repository contract mandate violated by 7 repositories

**Context:** `lib/core/data/repository.dart:5` states *"All repositories MUST wrap their public method return types in `Result`"*. Seven repositories return raw values instead, discarding the `Result<T>` wrapper that callers depend on for uniform error handling.

| Repository | Violating methods | Return type (should be) |
|---|---|---|
| `SubjectRepository` | `create`, `addTopicToSubject`, `removeTopicFromSubject`, `getWithTopics`, `getByCode` | `void` / `Subject?` / `List<Subject>` → `Result<void>` / `Result<Subject?>` |
| `AttemptRepository` | `create`, `getByStudent`, `getByStudentAndSubject`, `getByQuestion`, `getBySubject`, `getSubjectStats` | All raw |
| `PlanRepository` | `create`, `savePlan`, `loadPlan`, `deletePlan`, `hasPlan`, `getAllPlans` | All raw |
| `RoadmapRepository` | all methods | All raw |
| `ConversationRepository` | all methods | All raw |
| `TutorSessionRepository` | all methods | All raw |
| `EngagementNudgeRepository` | all methods | All raw |

**Rationale:** When a repository method throws or fails, callers get a raw exception (crash) instead of a `Result.failure` to handle gracefully. This also forces downstream services into ad-hoc `try/catch` patterns (see M1).

**Fix:**
- Audit all 7 repos listed above and wrap all public method return types in `Result<T>`
- `AttemptRepository.create` at `features/practice/data/repositories/attempt_repository.dart:10` calls `await save(...)` but discards the returned `Result` — this is a latent bug
- Add a `Repository` base class template method or mixin to enforce the contract automatically

---

### B3. `planner` ↔ `sessions` direct bidirectional dependency cycle

**Context:** `planner` imports `sessions/SessionRepository`; `sessions` imports `planner/PlanRepository` and `planner/PlanAdherenceRepository`. This is a direct 2-node cycle that makes the features inseparable.

| Direction | File | Import |
|---|---|---|
| planner → sessions | `lib/features/planner/services/planner_service.dart:10` | `package:studyking/features/sessions/data/repositories/session_repository.dart` |
| sessions → planner | `lib/features/sessions/presentation/session_tracker_screen.dart:13,18` | `package:studyking/features/planner/data/repositories/...` |

**Rationale:** Bidirectional dependencies prevent independent testing, increase coupling, and make it impossible to extract either feature into its own package. Refactoring one feature risks breaking the other at runtime with no compile-time guard.

**Fix:**
- Move the shared dependency (session repository access needed by planner) into a contract in `core/data/contracts/session_query_contract.dart` — this file already exists but is **never implemented** (see M4)
- `SessionTrackerScreen` should receive planner data via a Riverpod provider that bridges features, not import planner repos directly
- Alternatively, invert the dependency: have `planner` define an interface that `sessions` implements

---

### B4. `dashboard` ↔ `subjects` direct bidirectional dependency cycle

| Direction | File | Import |
|---|---|---|
| dashboard → subjects | `lib/features/dashboard/providers/dashboard_providers.dart:4` | `package:studyking/features/subjects/data/repositories/topic_repository.dart` |
| subjects → dashboard | `lib/features/subjects/presentation/subject_detail_screen.dart:11` | `package:studyking/features/dashboard/data/models/dashboard_models.dart` |

**Fix:** Extract `dashboard_models.dart` into `core/data/models/` since it's referenced by features beyond dashboard. Route the TopicRepository dependency via a core-level contract or provider.

---

### B5. `ingestion` ↔ `questions` and `ingestion` ↔ `subjects` bidirectional cycles

- **ingestion ↔ questions**: `ingestion` imports `question_repository`; `questions` imports `source_model` + `source_repository`
- **ingestion ↔ subjects**: `ingestion` imports subject repositories (6 imports); `subjects` imports `source_repository`

**Topology note:** The 4 cycles above (B3–B5) merge into a transitive mega-cycle spanning 6 features: `dashboard → subjects → ingestion → questions → practice → sessions → planner → dashboard`. This means no feature in this cycle can be extracted or tested independently.

**Fix:** Break the cycles at their weakest links:
1. Make `questions` depend on `ingestion` (unidirectional — questions come from ingested sources) by removing `questions → source_model` import
2. Make `subjects` depend on `ingestion` (unidirectional — subjects own topics, sources belong to subjects) by removing `subjects → source_repository` import
3. Elevate cross-feature data models to `core/data/models/`

---

## MAJOR — Feature is broken or misleading

### M1. Error handling inconsistency: three coexisting failure patterns

**Context:** The codebase has **three** distinct error-handling strategies with no consistency around when to use which:

| Pattern | Used by | Problem |
|---|---|---|
| `Result<T>` from repository | SessionRepository, QuestionRepository, SettingsRepository (correct) | Correct but inconsistently applied |
| Raw `try/catch` returning defaults | MentorService (6×), StudyProgressTracker (4×), PracticeDataService, MistakeReviewService | Duplicates the `Result` pattern — repos already return `Result`, outer `try/catch` is redundant |
| `throw` raw `StateError`/`ArgumentError` | SettingsRepository (init), SecurityConfig, AppBuildConfig, HiveTypeIds | Bypasses `AppException` hierarchy and `convertToAppException` dispatch |
| `Result.capture()` / `Result.captureSync()` | Defined in `core/errors/result.dart:15-35` but **never used** anywhere in the codebase | Dead utility |

**Rationale:** A developer cannot predict whether calling a method will return `Result.failure`, throw `AppException`, throw `StateError`, or silently return `[]`. This leads to uncaught crashes in production when a method changes its implementation.

**Fix:**
1. Make every public method in every service/repository return `Result<T>`
2. Ban raw `throw` in data-access/service layers via lint rule
3. Use `Result.capture()` / `Result.captureSync()` as the single entry point for all try/catch — it's defined but unused
4. Kill the bare `try/catch => defaultValue` pattern in MentorService, ProgressTracker, etc. — delegate to `Result.capture()`

---

### M2. Wrong log levels across 80+ locations

**Pervasive pattern:** `.e()` (error) used for expected, recoverable failures that return defaults gracefully. Error level should be for unexpected fatal conditions; expected data-absence should be `.w()`.

| File | Count | Current | Should be |
|---|---|---|---|
| `lib/features/sessions/data/repositories/session_repository.dart` | 16× | `.e()` | `.w()` |
| `lib/core/services/personal_learning_plan_service.dart` | 13× | `.e()` | `.w()` |
| `lib/features/mentor/services/mentor_service.dart` | 10× | `.e()` | `.w()` |
| `lib/core/providers/app_providers.dart` | 9× | `.e()` | `.w()` |
| `lib/features/practice/services/spaced_repetition_service.dart` | 7× | `.e()` | `.w()` |
| `lib/core/services/engagement_scheduler.dart` | 6× | `.e()` | `.w()` |
| `lib/core/services/study_progress_tracker.dart` | 4× | `.e()` | `.w()` |
| `lib/features/practice/services/practice_data_service.dart` | 3× | `.e()` | `.w()` |
| `lib/features/teaching/services/tutor_service.dart` | 4× | `.w()` | **Correct** (uses warn for recoverable) |

**Additionally,`.d()` used for significant state changes that should be `.i()`:**
- `lib/features/sessions/services/study_timer_service.dart` — session lifecycle events (`Session started`, `paused`, `completed`) logged at debug

**Fix:**
- Audit all `.e()` calls in repository/service/provider layers; demote to `.w()` when the method returns a graceful default
- Audit all `.d()` calls for session lifecycle, notification events, and feature integrations; promote to `.i()`
- Add a linting rule or logging guideline to AGENTS.md

---

### M3. `SessionQueryContract` and `PlanAdherenceContract` — dead abstract classes

**Context:** Two files in `core/data/contracts/` are declared but never implemented:
- `lib/core/data/contracts/session_query_contract.dart:1-17` — `SessionQueryContract` is **never implemented** by any class. `SessionRepository` extends `Repository<Session>` directly
- `lib/core/data/contracts/plan_adherence_contract.dart:1-6` — single-method abstract, only one (unnamed) implementation in `SessionPlanAdherenceService`

**Fix:** Either implement these contracts on the corresponding repositories (which would also break the planner↔sessions cycle) or remove them as dead code.

---

### M4. 18 `core/` files import from features — upward dependency

**Context:** Files in `lib/core/` should be the lowest architectural layer, depending only on themselves and external packages. 18 core files import from features, creating an upward dependency.

| Core File | Feature imports |
|---|---|
| `lib/core/routes/app_router.dart` | all 15 features |
| `lib/core/data/database_service.dart` | 6 features |
| `lib/core/data/hive_initializer.dart` | 6 features |
| `lib/core/providers/app_providers.dart` | 8+ features |
| `lib/core/services/personal_learning_plan_service.dart` | 4 features |
| `lib/core/services/mastery_graph_service.dart` | 2 features |
| `lib/core/services/instrumentation_service.dart` | 2 features |
| `lib/core/services/progress_export_service.dart` | 2 features |
| `lib/core/services/badge_service.dart` | 2 features |
| `lib/core/services/cross_feature_integrator.dart` | 2 features |
| ... and 8 more | |

**Note on routing:** `app_router.dart` importing every feature is architecturally acceptable — a router must know about all screens. The problematic ones are the **service-layer** imports (e.g., `mastery_graph_service.dart` importing `features/practice/...`).

**Fix:**
- Move the "orchestration" services (`personal_learning_plan_service`, `mastery_graph_service`, `badge_service`, `cross_feature_integrator`, `instrumentation_service`, `progress_export_service`) into dedicated `lib/features/crosscutting/` or keep in core but have features provide data through contracts defined in core
- For pure-data services (e.g., `llm_usage_meter.dart` importing `features/settings/`), extract the referenced model into `core/data/models/`

---

### M5. 10 overly long functions violating Single Responsibility Principle

| Function | File | Lines | SRP violations |
|---|---|---|---|
| `_parseExpression` | `lib/features/questions/presentation/widgets/math_expression_widget.dart:75` | 256 | Tokenization + parsing + widget rendering in one giant if/else chain (30+ branches) |
| `exportComprehensivePDF` | `lib/core/services/progress_export_service.dart:131` | 189 | Data loading + PDF widget tree construction + 3 table layouts + conditional sections |
| `_showProgressReport` | `lib/features/mentor/presentation/mentor_screen.dart:567` | 205 | Data fetching + AlertDialog building + theme access + Navigator routing |
| `processFullPipeline` | `lib/features/ingestion/services/content_pipeline.dart:88` | 142 | 4 processing stages + progress callbacks + status updates + saves + error handling |
| `_buildPlan` | `lib/core/services/personal_learning_plan_service.dart:95` | 132 | 3 data source loads + recommendation scoring + 3 input modes + daily plan generation + persistence |
| `_sendNudgeNotifications` | `lib/core/services/engagement_scheduler.dart:153` | 118 | 5 nudge types in a near-identical repeated pattern |
| `_generateDailyPlans` | `lib/core/services/personal_learning_plan_service.dart:579` | 121 | Triple-nested loop + live readiness fetches per topic + sorting + rest days |
| `_buildContextPrompt` | `lib/features/mentor/services/mentor_service.dart:157` | 101 | 10+ data fetches + try/catch per section + conditional formatting |
| `checkWellbeingAndGenerateNudges` | `lib/features/mentor/services/mentor_service.dart:399` | 84 | 5 wellbeing checks + nudge creation + persistence + memory update |
| `_buildEmptyMasteryPlan` | `lib/core/services/personal_learning_plan_service.dart:229` | 90 | Topic generation + daily plan creation + summary + persistence |

**Fix:** Break each function into focused methods. Specific suggestions in the detailed analysis above. Add a Cyclomatic Complexity lint threshold (< 15 branches per function).

---

### M6. 10× repeated `onRetry` lambda pattern in dashboard

**Context:** `lib/features/dashboard/presentation/dashboard_screen.dart:103-220` repeats this near-identical pattern 10 times:

```dart
onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardXxxProvider(studentId)); },
```

Only the provider name changes. 10 individual `onRetry: () => ref.invalidate(...)` callbacks.

**Fix:** Extract into a helper method or use a shared `retryDashboard` function that invalidates the init provider and a given target provider.

---

## MINOR — Code quality / UX friction

### m1. Repeated repository boilerplate (9 files)

**Context:** 9 repositories (`AttemptRepository`, `SubjectRepository`, `TopicRepository`, `PlanRepository`, `RoadmapRepository`, `PendingActionRepository`, `BadgeRepository`, `ConversationRepository`, `TutorSessionRepository`) all have identical `init() { openBox(HiveBoxNames.xxx) }` + `create(x) { save(x.id, x) }` boilerplate.

**Fix:** Add these as default methods on the `Repository<T>` base class or generate them via a mixin. The box name can be passed as a constructor parameter.

---

### m2. `llm_tasks` — feature with single file and no subdirectories

**Context:** `lib/features/llm_tasks/` is a full feature barrel directory containing exactly one file (`presentation/llm_task_manager_screen.dart`) with no `data/`, `services/`, or `providers/` subdirectories. The file's logic is tightly coupled to `lib/core/services/llm_task_manager.dart`.

**Fix:** Either promote to core (it's a singleton service with a single UI entry point) or restructure to follow the standard feature pattern with at minimum a provider.

---

### m3. `onboarding` has no `data/` or `providers/` directories; `quickguide` has no `data/`, `providers/`, or `services/`; `focus_mode` has no `data/`

**Context:** These features are structurally incomplete compared to the established convention. Over time this will cause feature-creep as data or state management gets added ad-hoc.

**Fix:** Add the standard subdirectories with barrel files even if initially empty, or document the exception.

---

### m4. `Clock` / `SystemClock` — single-implementation abstraction

**Context:** `lib/core/utils/clock.dart:1-8` defines a `Clock` abstract + `SystemClock` implementation. Only one implementation exists. While this is somewhat justified for testability (4 services inject it), it adds boilerplate for no polymorphic benefit.

**Accept if:** The team values testability through injection. However, verify that tests actually use a fake clock (search test/ for `FakeClock` or similar) — if not, remove the abstraction.

---

### m5. Hardcoded configuration values that should be environment-driven

| Value | File | Hardcoded as |
|---|---|---|
| OpenRouter base URL | `lib/core/constants/app_api_config.dart:56` | `'https://openrouter.ai/api/v1'` |
| Ollama base URL | `lib/core/constants/app_api_config.dart:57` | `'http://localhost:11434'` |
| OpenAI base URL | `lib/core/constants/app_api_config.dart:58` | `'https://api.openai.com/v1'` |
| YouTube transcript URL | `lib/core/constants/app_api_config.dart:59-60` | `'https://youtubetranscript.com/...'` |
| Google API URL | `lib/core/constants/app_api_config.dart:68-69` | `'https://www.googleapis.com/...'` |
| User-Agent header | `lib/core/constants/app_api_config.dart:61` | `'Mozilla/5.0 (compatible; StudyKing/1.0)'` |
| Token pricing | `lib/core/constants/token_pricing_config.dart:8-11` | `cachedInputCostPerToken`, `inputCostPerToken`, `outputCostPerToken`, `divisor` |
| Cache expiration | `lib/core/constants/app_runtime_config.dart:8` | `Duration(hours: 24)` |
| Session timeout | `lib/core/constants/security_config.dart:7` | `Duration(minutes: 30)` |

**Fix:** Move runtime-configurable values (URLs, timeouts, pricing) to a config file or environment variables. The TODO at `app_api_config.dart:30` already flags this: `// TODO(security): prefer runtime secret injection`.

---

### m6. No shared loading / empty-state / error widgets despite 15+ duplicate implementations

**Context:** `Center(child: CircularProgressIndicator())` appears 15+ times. 4 separate empty-state implementations (`PracticeEmptyState`, `MentorScreen._buildEmptyState()`, `SessionHistoryScreen._buildEmptyState()`, `QuickGuideScreen._buildEmptyState()`). No shared widget in `core/widgets/`.

**Fix:** Add to `core/widgets/`:
- `LoadingIndicator` (standard spinner with optional message)
- `EmptyStateWidget` (icon + title + subtitle + optional action button)
- `ErrorRetryWidget` (error message + retry button)

Then replace all 15+ instances across features.

---

### m7. `throw` in config/constant files breaks the `AppException` error UI

**Context:** Several constant files throw raw `ArgumentError` or `StateError` instead of `AppException`:
- `lib/core/constants/security_config.dart:24,40,43,50,68` — `ArgumentError`
- `lib/core/constants/app_build_config.dart:31,41,44,47` — `ArgumentError`
- `lib/core/constants/app_api_config.dart:20,37` — `ArgumentError`
- `lib/core/constants/app_config.dart:86` — `StateError`
- `lib/core/data/hive_type_ids.dart:82` — `StateError`
- `lib/features/settings/data/repositories/settings_repository.dart:20,28` — `StateError`

While `convertToAppException` in `handlers.dart:147` does translate `StateError` and `ArgumentError`, the translation is by string matching (`errorStr.contains('401')`, etc.) which is fragile and locale-dependent.

**Fix:** Switch to `AppException` with the correct `ExceptionType` (e.g., `ExceptionType.database` for `StateError`, `ExceptionType.validation` for `ArgumentError`). This gives typed, i18n-aware error messages without fragile string matching.

---

### m8. `Result.capture()` / `Result.captureSync()` defined but never used

**Context:** `lib/core/errors/result.dart:15-35` provides `Result.capture()` and `Result.captureSync()` — static factory methods that wrap a block in try/catch and return `Result.success`/`Result.failure`. These are the **exact** tool needed to eliminate the 25+ repeated try/catch patterns found (MentorService, ProgressTracker, SessionRepository, LessonRepository).

**Fix:** Replace all ad-hoc `try { return x; } catch (e) { log; return default; }` with `Result.capture(() => x, context: 'method')`.

---

### m9. TODO without timeline or ticket reference

**File:** `lib/core/constants/app_api_config.dart:30`
```dart
// TODO(security): prefer runtime secret injection (keystore/native layer) over compile-time embedding where possible.
```

**Fix:** Assign a timeline (target version) or ticket reference, or resolve the TODO by implementing secret injection.

---

### m10. `// ignore: invalid_null_aware_operator` likely stale

**File:** `lib/features/planner/services/syllabus_resolver.dart:93`
**Rationale:** Suppression comments that outlive their need mask new null-safety issues. Verify it's still needed.

---

## Summary of Acceptance Criteria

For this issue to be considered "fixed":

1. **All `catch (_) {}` blocks** (B1) — replaced with at-minimum `_logger.w(...)` and preferably user-visible feedback
2. **All repository return types** (B2) — wrapped in `Result<T>` per the contract in `repository.dart`
3. **All 4 bidirectional dependency cycles** (B3-B5) — resolved (unidirectional or contracted)
4. **Error handling strategy** (M1) — unified: use `Result.capture()` everywhere, ban raw `throw` in services/repos, remove redundant outer try/catch
5. **Log level audit** (M2) — `.e()` only for fatal, `.w()` for recoverable, `.i()` for state transitions
6. **Dead contracts** (M3) — either implemented or removed
7. **Core→feature dependencies** (M4) — only `app_router.dart` and `app_providers.dart` may import features
8. **Top 10 longest functions** (M5) — each broken into focused sub-methods under 60 lines
9. **Dashboard retry lambda** (M6) — extracted to shared helper
10. **Repository boilerplate** (m1) — default methods on `Repository<T>` base class
11. **Incomplete feature directories** (m2-m3) — standardized or documented
12. **Shared widgets** (m6) — `LoadingIndicator`, `EmptyStateWidget`, `ErrorRetryWidget` in `core/widgets/`
13. **Raw `throw`** in config/constants (m7) — replaced with `AppException`
14. **`Result.capture()` used** (m8) — replaces all ad-hoc try/catch blocks in data-access layer
15. **Stale TODO and `// ignore:`** (m9-m10) — resolved or converted to tracked tickets

---

## Reference: Key Files Requiring Changes

| Priority | File | Issue(s) |
|---|---|---|
| BLOCKER | `lib/core/data/repository.dart` | B2, m1 (add enforcements, default methods) |
| BLOCKER | `lib/features/sessions/presentation/session_tracker_screen.dart` | B3 (remove planner import) |
| BLOCKER | `lib/features/subjects/presentation/subject_detail_screen.dart` | B4 (remove dashboard import) |
| BLOCKER | `lib/features/questions/presentation/question_bank_screen.dart` | B5 (remove ingestion import) |
| BLOCKER | 7 repository files under `features/*/data/repositories/` | B2 (wrap return types in Result) |
| MAJOR | `lib/features/mentor/services/mentor_service.dart` | M1, M5, m8 (error handling, SRP, Result.capture) |
| MAJOR | `lib/core/services/personal_learning_plan_service.dart` | M4 (imports features), M5 (3 long functions) |
| MAJOR | `lib/core/services/engagement_scheduler.dart` | M5 (118-line function) |
| MAJOR | `lib/features/ingestion/services/content_pipeline.dart` | M5 (142-line function) |
| MAJOR | `lib/features/mentor/presentation/mentor_screen.dart` | B1 (silent catch), M5 (205-line function) |
| MAJOR | `lib/features/presentation/widgets/math_expression_widget.dart` | M5 (256-line function) |
| MAJOR | `lib/core/services/progress_export_service.dart` | M4 (imports features), M5 (189-line function) |
| MAJOR | `lib/features/sessions/data/repositories/session_repository.dart` | M2 (16× wrong log level) |
| MAJOR | `lib/core/errors/exceptions.dart` + `handlers.dart` | M1, m7 (AppException adoption) |
| MAJOR | `lib/core/errors/result.dart` | m8 (`Result.capture` is unused) |
| MINOR | `lib/core/data/contracts/session_query_contract.dart` | M3 (dead abstract) |
| MINOR | `lib/core/data/contracts/plan_adherence_contract.dart` | M3 (dead abstract) |
| MINOR | `lib/core/widgets/` (new files) | m6 (shared loading/empty/error widgets) |
| MINOR | `lib/core/constants/app_api_config.dart` | m5, m9 (hardcoded URLs, stale TODO) |
| MINOR | `lib/core/constants/token_pricing_config.dart` | m5 (hardcoded pricing) |
| MINOR | `lib/features/llm_tasks/` | m2 (incomplete feature) |
| MINOR | `lib/features/onboarding/`, `focus_mode/`, `quickguide/` | m3 (incomplete feature dirs) |
