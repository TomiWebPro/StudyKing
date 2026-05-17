# Code Refactor Master — Architecture & Quality Audit

**Date:** 2026-05-17
**Scope:** Full code quality audit across `lib/` — dead code, circular deps, monolithic functions, error-handling inconsistency, redundant abstractions, file placement, hardcoded config, and repeated patterns.
**Method:** Manual diff, static analysis, dependency graph tracing, and cross-reference of AGENTS.md conventions.

---

## BLOCKER: Core Layer Heavily Depends on Feature Modules (Architecture Violation)

**Problem:** `lib/core/` services, data layer, and routes directly import from `lib/features/*/`, creating a tight coupling that violates clean-architecture principles. Core should define interfaces; features should implement them.

### 75+ imports from `lib/core/` → `lib/features/`

| Core file | Feature modules imported | Import count |
|---|---|---|
| `lib/core/services/personal_learning_plan_service.dart` | `practice/`, `subjects/`, `planner/`, `questions/` | 11 |
| `lib/core/services/mastery_graph_service.dart` | `practice/`, `questions/` | 8 |
| `lib/core/data/database_service.dart` | `lessons/`, `practice/`, `questions/`, `sessions/`, `subjects/`, `teaching/` | 8 |
| `lib/core/providers/app_providers.dart` | `lessons/`, `practice/`, `questions/`, `sessions/`, `settings/`, `subjects/`, `teaching/` | 10 |
| `lib/core/data/hive_initializer.dart` | `questions/`, `practice/`, `planner/`, `subjects/`, `teaching/`, `sessions/` | 6 |
| `lib/core/routes/app_router.dart` | All 13 feature screens | 19 |
| `lib/core/services/engagement_scheduler.dart` | `planner/`, `sessions/` | 4 |
| `lib/core/services/study_progress_tracker.dart` | `practice/`, `sessions/` | 3 |
| `lib/core/services/instrumentation_service.dart` | `practice/`, `planner/` | 6 |
| `lib/core/services/conversation_memory.dart` | `teaching/` | 2 |
| `lib/core/services/badge_service.dart` | `dashboard/`, `practice/` | 3 |
| `lib/core/services/topic_readiness_service.dart` | `subjects/`, `practice/` | 4 |
| `lib/core/services/plan_adapter.dart` | `planner/` | 3 |
| `lib/core/services/mastery_integration_service.dart` | `practice/` | 3 |
| `lib/core/services/cross_feature_integrator.dart` | `ingestion/`, `sessions/` | 2 |
| `lib/core/services/progress_export_service.dart` | `practice/`, `sessions/` | 4 |
| `lib/core/services/answer_validation_service.dart` | `questions/` | 2 |
| `lib/core/services/mastery_calculation_service.dart` | `practice/` | 1 |
| `lib/core/data/models/question_model.dart` | `questions/` | 1 |

**Rationale:** Every `package:studyking/features/...` import in core/ means core cannot be tested, reused, or reasoned about independently. If a feature's data layer changes, it can break core services. The proper fix involves extracting shared interfaces (e.g., `Repository<T>`, `MasteryRepository`) into `lib/core/` and injecting concrete feature implementations via Riverpod overrides or constructor injection.

**Acceptance criteria:**
1. Zero `package:studyking/features/` imports remain in `lib/core/`.
2. Every core service that needs feature data accepts an abstract interface defined in `lib/core/`.
3. Feature-specific wiring (which concrete repo to inject) lives in that feature's provider layer.
4. `app_router.dart` uses a lazy route registry pattern (features register their routes rather than core importing feature screens).

---

## BLOCKER: Circular Dependency Between planner_service.dart and action_executor.dart

**Problem:** `PlannerService` creates an `ActionExecutor` passing itself, and `ActionExecutor` calls back into `PlannerService` methods.

**Affected files:**
- `lib/features/planner/services/planner_service.dart:21` — `import 'action_executor.dart';`
- `lib/features/planner/services/planner_service.dart:38-41` — lazy getter `actionExecutor` creates `ActionExecutor(plannerService: this)`
- `lib/features/planner/services/action_executor.dart:2` — `import 'planner_service.dart';`

**Rationale:** While Dart handles this at runtime, it signals tight coupling: `ActionExecutor` cannot exist without `PlannerService`, and `PlannerService` cannot function without `ActionExecutor`. This makes unit testing harder (must mock both simultaneously) and prevents extracting `ActionExecutor` into its own testable unit.

**Acceptance criteria:**
1. Break the cycle by extracting the methods `ActionExecutor` calls on `PlannerService` into a separate abstract interface (e.g., `ActionPlanner`).
2. `PlannerService` implements `ActionPlanner`; `ActionExecutor` depends only on `ActionPlanner`.
3. The `actionExecutor` getter in `PlannerService` is replaced by constructor injection of `ActionExecutor`.

---

## MAJOR: Monolithic 132-Line `_buildPlan()` Function

**Problem:** `_buildPlan()` in `personal_learning_plan_service.dart:92-223` is 132 lines and does everything: init repos, fetch mastery states, build recommendations, generate daily plans, link questions, generate summaries, and save — violating single-responsibility principle.

**Longest functions:**

| File | Function | Lines | Responsibilities |
|---|---|---|---|
| `lib/core/services/personal_learning_plan_service.dart:92` | `_buildPlan()` | 132 | init, fetch, recommend, generate, link, summarize, save |
| `lib/features/mentor/services/mentor_service.dart:102` | `_buildContextPrompt()` | 134 | 6 independent try-catch blocks for stats, topics, plans, roadmaps, actions, lessons |
| `lib/core/services/personal_learning_plan_service.dart:591` | `_generateDailyPlans()` | 122 | sort, loop, readiness-check, assign, limit |
| `lib/core/services/personal_learning_plan_service.dart:225` | `_buildEmptyMasteryPlan()` | 91 | fallback plan builder |
| `lib/core/services/engagement_scheduler.dart:89` | `_sendNudgeNotifications()` | 103 | 5 sequential nudge checks in one try-catch block |
| `lib/features/mentor/services/mentor_service.dart:315` | `checkWellbeingAndGenerateNudges()` | 76 | overwork, late-night, at-risk, streak, inactivity, limit checks |
| `lib/core/services/personal_learning_plan_service.dart:430` | `recordDailyAdherence()` | 61 | record, redistribute, roadmap-link |
| `lib/core/services/plan_adapter.dart:155` | `getDailyAdherenceFeedback()` | 59 | load, date-match, ratio, message |

**Rationale:** Functions over 80 lines are extremely difficult to reason about, test, and modify without regression. Each function should do one thing. Deep nesting (>3 levels) in `_generateDailyPlans` (lines 624-709, day loop → recommendation loop → readiness check → score lookup) compounds the problem.

**Acceptance criteria:**
1. Every function above 80 lines is split into smaller functions (max 40 lines each, max 2 levels of nesting).
2. Private helper functions are extracted with descriptive names and single responsibility.
3. The 6 try-catch blocks in `_buildContextPrompt` are extracted into individual `_loadX()` methods.

---

## MAJOR: Inconsistent Error Handling — `Result<T>` vs Raw `throw` vs Silent `catch (_) {}`

**Problem:** Three distinct error-handling strategies coexist with no clear boundary:

| Strategy | Examples | Files |
|---|---|---|
| `Result<T>` type | `return Result.failure(...)` / `.isSuccess` checks | `planner_service.dart`, `mastery_graph_service.dart`, `plan_adapter.dart`, `session_repository.dart`, `syllabus_resolver.dart` |
| Raw `throw` / `try-catch` | `throw ArgumentError(...)` | `app_api_config.dart:20,37`, `security_config.dart:24,40,43,50,68`, `app_build_config.dart:31,41,44,47`, `hive_type_ids.dart:82`, `app_config.dart:86` |
| Silent `catch (_) {}` | Empty catch swallows all exceptions | `mentor_service.dart:108,115,120,127,134,141,284,310` |

### Worst offenders: 8 silent `catch (_) {}` in MentorService

```
lib/features/mentor/services/mentor_service.dart:108   catch (_) { weakResult = Result.success([]); }
lib/features/mentor/services/mentor_service.dart:115   catch (_) {}                          // plan silently null
lib/features/mentor/services/mentor_service.dart:120   catch (_) { roadmaps = []; }
lib/features/mentor/services/mentor_service.dart:127   catch (_) { pendingActions = []; }
lib/features/mentor/services/mentor_service.dart:134   catch (_) { upcomingLessons = []; }
lib/features/mentor/services/mentor_service.dart:141   catch (_) {}                          // adherence silently null
lib/features/mentor/services/mentor_service.dart:284   catch (_) { ... }
lib/features/mentor/services/mentor_service.dart:310   catch (_) { ... }
```

**Rationale:** Silent catches hide production bugs. When a repository throws (e.g., Hive box not initialized), the underlying error is lost and the user sees a broken UI with no error report. Raw `throw ArgumentError` in config constructors is acceptable for build-time validation but inconsistent with the `Result<T>` pattern used everywhere else for runtime operations.

**Acceptance criteria:**
1. All runtime operations use `Result<T>` consistently — no raw `throw` for recoverable errors.
2. Zero bare `catch (_) {}` blocks remain. Every catch either re-throws, logs with context, or returns a `Result.failure`.
3. `MentorService` uses `Result<T>` for all method return types instead of silently falling back to empty defaults.

---

## MAJOR: Duplicated `_calculateAdherenceScore()` in Two Core Services

**Problem:** Identical 17-line method duplicated verbatim in two core service files.

- `lib/core/services/personal_learning_plan_service.dart:573-589`
- `lib/core/services/instrumentation_service.dart:126-142`

Both implement:
```dart
double _calculateAdherenceScore({
  required int plannedQuestions, required int actualQuestions,
  required int plannedMinutes, required int actualMinutes,
}) {
  if (plannedQuestions == 0 && plannedMinutes == 0) return 1.0;
  final questionScore = plannedQuestions > 0
      ? (actualQuestions / plannedQuestions).clamp(0.0, 1.0) : 0.5;
  final timeScore = plannedMinutes > 0
      ? (actualMinutes / plannedMinutes).clamp(0.0, 1.5) : 0.5;
  return (questionScore * 0.6 + timeScore * 0.4).clamp(0.0, 1.0);
}
```

**Rationale:** Duplicated logic means bug fixes or weighting adjustments must be applied in two places. The weights (0.6, 0.4, 1.5 cap) are magic numbers duplicated across both copies.

**Acceptance criteria:**
1. Extract into a shared utility: `lib/core/utils/study_utils.dart` or add to `lib/core/utils/number_format_utils.dart`.
2. Both callers use the shared function.
3. Magic weights become named constants.

---

## MAJOR: Repeated `DateTime(now.year, now.month, now.day)` Pattern (8+ Locations)

**Problem:** The date-truncation-to-midnight pattern appears in at least 8 files:

| File | Line |
|---|---|
| `lib/features/planner/providers/planner_providers.dart` | 63 |
| `lib/core/utils/time_utils.dart` | 65 |
| `lib/core/services/study_progress_tracker.dart` | 46 |
| `lib/features/mentor/services/mentor_service.dart` | 267, 300 |
| `lib/core/services/personal_learning_plan_service.dart` | 538 |
| `lib/features/planner/services/planner_service.dart` | 394 |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart` | 151 |

**Rationale:** Duplicated knowledge. If the date-truncation logic needs to change (e.g., timezone handling), all 8 sites must be updated.

**Acceptance criteria:**
1. Add `DateTime dateOnly(DateTime dt)` getter to `lib/core/utils/time_utils.dart`.
2. Replace all 8+ call sites with `dateOnly(someDate)` or `someDate.dateOnly`.

---

## MAJOR: File Placement Violations — `lib/utils/` Outside `lib/core/`

**Problem:** `lib/utils/id_generator.dart` lives outside `lib/core/utils/`, breaking the convention that all utilities are under `lib/core/utils/`. Yet it's imported by core services:

- `lib/core/services/instrumentation_service.dart:1` — imports from `lib/utils/id_generator.dart`
- `lib/features/ingestion/services/content_pipeline.dart:17` — imports from `lib/utils/id_generator.dart`

**Rationale:** This creates a reverse dependency (core depends on a non-core path) and is inconsistent with every other utility file.

**Acceptance criteria:**
1. Move `lib/utils/id_generator.dart` → `lib/core/utils/id_generator.dart`.
2. Update all imports in both files to point to the new location.

---

## MAJOR: Redundant `MasteryIntegrationService` (~60% Pure Delegation)

**Problem:** `lib/core/services/mastery_integration_service.dart` has 10 public methods; 6 of them are pure pass-throughs to `MasteryGraphService`:

| Method | Lines | Action |
|---|---|---|
| `initialize()` | 19-21 | Delegates to `_masteryService.init()` |
| `recordAttemptWithMasteryUpdate()` | 23-41 | Delegates to `_masteryService.recordAttempt()` |
| `getMasterySnapshot()` | 146-148 | Delegates to `_masteryService.getMasterySnapshot()` |
| `getTopicMasteries()` | 150-152 | Delegates to `_masteryService.getAllTopicMastery()` |
| `getTopicMastery()` | 154-156 | Delegates to `_masteryService.getTopicMastery()` |
| `migrateLegacyQuestion()` | 158-172 | Delegates to `_masteryService.migrateLegacyQuestion()` |

Also has a `@Deprecated` method `calculateSpacedRepetitionInterval()` (line 75) that is still fully implemented and presumably still called.

**Rationale:** The 4 non-trivial methods (`getAdaptiveRecommendation`, `getPrioritizedQuestionIds`, `_recommendedDifficulty`, `_calculateReviewInterval`) could live directly in `MasteryGraphService` or be extracted to a separate focused class. The delegation adds indirection without abstraction.

**Acceptance criteria:**
1. Remove pure delegation methods from `MasteryIntegrationService` — callers use `MasteryGraphService` directly.
2. Keep or relocate the 4 value-adding methods.
3. Remove the `@Deprecated` method or migrate all callers and delete it.

---

## MAJOR: Repetitive Try-Catch-Logger Pattern (13+ Locations)

**Problem:** The same 3-line pattern appears in 13+ places in `personal_learning_plan_service.dart` alone:

```dart
try {
  // operation
} catch (e) {
  const Logger('ClassName').e('Failed to do X', e);
  return defaultValue;
}
```

Also repeated extensively in `engagement_scheduler.dart` (8 separate try-catch blocks in `_sendNudgeNotifications()` lines 89-191).

**Rationale:** Boilerplate makes services harder to read and obscures the actual business logic. A helper `capture<T>(Future<T> Function() fn, T fallback)` or a Dart `Result.catchError()` pattern would eliminate the repetition.

**Acceptance criteria:**
1. Add a utility: `Result<T> capture<T>(Future<T> Function() block, {String? context})` that wraps try-catch-logger.
2. Replace all 13+ inline try-catch-logger blocks with a single-line call to the utility.

---

## MAJOR: `CrossFeatureIntegrator` — 4 Near-Identical Methods

**Problem:** `lib/core/services/cross_feature_integrator.dart` has 4 methods (`getUnifiedTimeline`, `getTotalStudyDurationMs`, `getCompletedSessionCount`, `getDurationByType`) that all follow the exact boilerplate:

1. Resolve student ID
2. Call `_sessionRepo.getByStudent(sid)`
3. Check `isFailure`
4. Log error with wrong level (`.e()` for recoverable failure)
5. Return default value
6. Process data

Lines 88-169 are highly repetitive.

**Rationale:** Any change to error handling or logging must be applied to all 4 copies. The shared plumbing (ID resolution, repo call, error check) should be a single helper.

**Acceptance criteria:**
1. Extract a private `_getSessions(String? studentId)` helper returning `Result<List<Session>>`.
2. Each public method only contains the unique data-processing logic.
3. Change log level from `.e()` to `.w()` for recoverable failures (method returns gracefully).

---

## MAJOR: `AppErrorHandler.handleSyncError()` — Pure Pass-Through

**Problem:** `lib/core/errors/handlers.dart:30-32` defines `handleSyncError()` that simply calls `handleError()` with the same arguments. It adds zero value.

```dart
static void handleSyncError({
  required BuildContext context,
  required dynamic error,
  String? message,
  bool retry = false,
  VoidCallback? onRetry,
}) {
  handleError(
    context: context,
    error: error,
    message: message,
    retry: retry,
    onRetry: onRetry,
  );
}
```

**Rationale:** Dead abstraction. Every call to `handleSyncError` can be replaced with `handleError` directly.

**Acceptance criteria:**
1. Remove `handleSyncError()`.
2. Replace all calls to `handleSyncError(...)` with `handleError(...)`.

---

## MAJOR: Hardcoded Magic Numbers Scattered Across 20+ Files

**Problem:** Mastery thresholds, scoring weights, time constants, and learning parameters are hardcoded inline rather than centralized in config. Any tuning requires touching multiple files.

### Examples of duplicated magic numbers (>3 occurrences):

| Value | Occurrences | Files |
|---|---|---|
| `0.5` | 15+ | `mastery_calculation_service.dart`, `personal_learning_plan_service.dart`, `plan_adapter.dart`, `instrumentation_service.dart`, `remaining_workload_estimator.dart`, etc. |
| `0.8` | 10+ | `mastery_calculation_service.dart`, `personal_learning_plan_service.dart`, `mastery_integration_service.dart`, `study_progress_tracker.dart`, `practice/practice_session_service.dart` |
| `30` (minutes) | 4+ | `personal_learning_plan_service.dart:33`, `plan_adapter.dart:104`, `mentor_service.dart:459,465` |
| `15` (questions/day) | 2 | `planner_service.dart:107,135` |
| `7` (days) | 5+ | `mastery_calculation_service.dart:121`, `planner_service.dart:154`, `personal_learning_plan_service.dart:233,652` |
| `1000` (ms conversion) | 5+ | `engagement_scheduler.dart:207`, `study_progress_tracker.dart:79-80,316`, `study_timer_service.dart:26,106`, `session_migration_service.dart:70` |

**Rationale:** To adjust pedagogy defaults (e.g., reduce mastery threshold from 0.8 to 0.75), a developer must search-and-replace across the entire codebase with risk of missing a location.

**Acceptance criteria:**
1. Define named constants in `lib/core/constants/app_constants.dart` for all mastery/scoring thresholds.
2. Define named constants in `lib/core/constants/timeouts.dart` for all duration/time-interval constants.
3. Define feature-level defaults in `lib/core/constants/app_config.dart`.
4. All 20+ files reference constants instead of inline literals.

---

## MAJOR: Wrong Log Levels — `.e()` Used for Recoverable Failures

**Problem:** `cross_feature_integrator.dart` (lines 96, 126, 142, 155) uses `_logger.e()` (error) for failures that are gracefully handled (method returns empty list/zero/default). These should be `.w()` (warning).

In contrast, `engagement_scheduler.dart` (lines 109, 135, 157, 169, 188, 199, 212, 262) uses `_logger.w()` for the same pattern (recoverable failure, operation continues). This inconsistency means log monitoring cannot distinguish between "expected transient failure" and "real bug."

**Affected files:**
- `lib/core/services/cross_feature_integrator.dart:96,126,142,155` — `.e()` should be `.w()`
- `lib/core/errors/handlers.dart:146` — always uses `.e()` for all logged errors including recoverable ones

**Acceptance criteria:**
1. All gracefully-handled failures (method returns fallback/default) use `.w()`.
2. Only unrecoverable errors (method throws, app state is corrupt) use `.e()`.

---

## MINOR: Redundant Barrel Export Overlap

**Problem:** `lib/core/core.dart` re-exports `data/enums.dart` and `data/database_service.dart` and all 4 data models; but `lib/core/data/data.dart` also re-exports the same files. Both barrels are consumed by different importers, but the overlap creates confusion about which barrel to use.

**Files:**
- `lib/core/core.dart` — exports: enums, database_service, hive_initializer, 4 models, iterable_extensions, utils
- `lib/core/data/data.dart` — exports: enums, hive_initializer, database_service, 4 models, repository, hive_box_names

**Rationale:** A new developer or automated tool might import the wrong barrel, leading to unused imports or confusion about module boundaries.

**Acceptance criteria:**
1. `lib/core/core.dart` re-exports `lib/core/data/data.dart` instead of duplicating its exports.
2. Review all imports of `core/data/` items to prefer the feature-level barrel where possible.

---

## MINOR: Missing Tests for 5 Core Files

**Problem:** 5 core files have no corresponding test files (93.4% core coverage vs. 100% feature coverage):

1. `lib/core/constants/notification_channel_ids.dart`
2. `lib/core/constants/timeouts.dart`
3. `lib/core/services/llm/llm_embeddings_service.dart`
4. `lib/core/services/llm/llm_model_service.dart`
5. `lib/core/services/pdf_generator/question_pdf_generator.dart`

**Rationale:** Per AGENTS.md convention, every source file must have a test file. Gaps reduce confidence in refactoring.

**Acceptance criteria:**
1. Test files exist at `test/core/constants/notification_channel_ids_test.dart`, etc.
2. Tests verify expected behavior (constants have correct values, services handle success/failure paths).

---

## MINOR: Hardcoded API URL Duplicated in Settings Screen

**Problem:** `lib/features/settings/presentation/api_config_screen.dart:122` hardcodes `'https://openrouter.ai/api/v1/models'` with a `.timeout(const Duration(seconds: 15))` instead of using the shared config.

**Affected files:**
- `lib/core/constants/app_api_config.dart:56` — defines `openRouterBaseUrlString` but the settings screen ignores it
- `lib/features/settings/presentation/api_config_screen.dart:122,126` — duplicated URL + hardcoded timeout

**Acceptance criteria:**
1. `api_config_screen.dart` uses `ApiConfig.openRouterBaseUrlString` or a derived URL.
2. Timeout uses a constant from `lib/core/constants/timeouts.dart`.

---

## MINOR: Hardcoded LLM Evaluation Prompt Duplicated in Two Files

**Problem:** The same full JSON prompt template (for LLM-based exercise evaluation) is hardcoded in two places:

- `lib/features/teaching/services/exercise_evaluator.dart:33-41`
- `lib/features/teaching/services/prompts/prompts.dart:94-102`

**Affected:** Both files contain an identical multi-line string template for LLM interaction.

**Acceptance criteria:**
1. Extract the shared prompt string into `lib/core/constants/llm_defaults.dart`.
2. Both callers import the shared constant.
