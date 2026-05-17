# Code Refactor Master — Comprehensive Code Quality Issue

## Executive Summary

This issue catalogs systemic code quality problems across the StudyKing codebase identified during an architectural audit. Findings are grouped by severity and affect approximately 65+ source files across all layers (core, features, presentation, data).

---

## BLOCKER

*None identified.* The application compiles, tests pass, and no crash-path was found that a user would trigger in normal operation.

---

## MAJOR

### M1. Dead Code: Unused Classes & Interfaces (4 items)

**Rationale:** These artifacts compile but serve no purpose in production. They increase maintenance surface area and confuse new developers.

| Dead Item | File | Lines | Evidence |
|---|---|---|---|
| `SessionQueryContract` (abstract class) | `lib/core/data/contracts/session_query_contract.dart` | All | Zero implementations in `lib/` or `test/`. Grep for `implements SessionQueryContract` returns nothing. |
| `TaskModel` | `lib/features/planner/data/models/task_model.dart` | All | Zero imports from `lib/`. Only referenced in `test/` and `hive_type_ids.dart` (type ID constant). Never instantiated. |
| `QuestionPDFGenerator` | `lib/core/services/pdf_generator/question_pdf_generator.dart` | All | Zero imports from `lib/`. Only referenced in test file. Scaffolding never wired into production. |
| `DashboardService` | `lib/features/dashboard/services/dashboard_service.dart` | All | Zero imports from `lib/`. All dashboard logic is in providers directly. |
| `safely()` and `safelySync()` | `lib/core/errors/handlers.dart` | 113–139 | Zero callers in `lib/` (only called in tests). Dead production utilities. |

**Acceptance Criteria:**
- [ ] `SessionQueryContract` is deleted (or gets an implementation if the contract is still needed).
- [ ] `TaskModel` is deleted (along with its hive type ID in `hive_type_ids.dart`).
- [ ] `QuestionPDFGenerator` is deleted or wired into a production code path.
- [ ] `DashboardService` is deleted (providers already handle the logic).
- [ ] `safely`/`safelySync` are deleted or given production callers.

---

### M2. Error Handling Inconsistency: 4 Competing Patterns

**Rationale:** The documented contract (`lib/core/data/repository.dart:5-7`) states all public repository methods must return `Result<T>`. In practice, 4 different patterns coexist, creating unpredictable failure modes.

**Pattern A — Canonical `try`→`Result.success` / `catch`→`Result.failure`:**
~40+ methods across 8 repositories. Correct per contract.

**Pattern B — `try`→`catch`→`rethrow` (init methods):**
8 repository `init()` methods + `DatabaseService.init()`. Log then rethrow raw exception. No `Result` wrapping.
- `lib/features/lessons/data/repositories/lesson_repository.dart:16`
- `lib/features/practice/data/repositories/mastery_state_repository.dart:15`
- `lib/features/practice/data/repositories/question_mastery_state_repository.dart:15`
- `lib/features/practice/data/repositories/question_evaluation_repository.dart:15`
- `lib/features/practice/data/repositories/topic_dependency_repository.dart:16`
- `lib/features/practice/data/repositories/spaced_repetition_repository.dart:30`
- `lib/features/practice/data/repositories/mastery_graph_repository.dart:68`
- `lib/features/questions/data/repositories/question_repository.dart:17`
- `lib/core/data/database_service.dart:46`

**Pattern C — No `Result` at all (raw `Future<T>` return types that can fail):**
- `lib/features/subjects/data/repositories/subject_repository.dart`
- `lib/features/subjects/data/repositories/topic_repository.dart`
- `lib/features/practice/data/repositories/attempt_repository.dart`
- `lib/features/settings/data/repositories/settings_repository.dart`
- `lib/features/dashboard/data/repositories/badge_repository.dart`

**Pattern D — Empty `catch (_) {}` (silent swallow):**
- `lib/features/ingestion/services/document_extractor.dart:84` — **most dangerous instance in codebase**

**Acceptance Criteria:**
- [ ] All repository `init()` methods return `Future<Result<void>>` or exceptions are consistently handled upstream.
- [ ] `SubjectRepository`, `TopicRepository`, `AttemptRepository`, `BadgeRepository`, `SettingsRepository` use `Result<T>` wrapping consistent with the documented contract.
- [ ] The empty `catch (_) {}` in `document_extractor.dart:84` is replaced with at minimum logging + `Result.failure`.
- [ ] `Result.capture()` / `Result.captureSync()` are either used or removed from `result.dart`.

---

### M3. Circular Dependencies Between Features (3 verified cycles)

**Rationale:** Compile-time circular dependencies create brittle code where changes in one feature can transitively break unrelated features. Refactoring or extracting a feature into a package becomes impossible without breaking all cycles first.

**Cycle A — SUBJECTS ↔ INGESTION (direct 2-way cycle):**
- `subjects/presentation/subject_detail_screen.dart` imports `ingestion/data/repositories/source_repository.dart`
- `ingestion/` (5 files) imports `subjects/data/repositories/subject_repository.dart` or `topic_repository.dart`

**Cycle B — PRACTICE → SESSIONS → PLANNER → PRACTICE (3-hop cycle):**
- `practice/services/practice_session_service.dart` and `exam_session_service.dart` import `sessions/data/repositories/session_repository.dart`
- `sessions/presentation/session_tracker_screen.dart` imports `planner/data/repositories/plan_adherence_repository.dart` and `plan_repository.dart`
- `planner/services/planner_service.dart` and `syllabus_resolver.dart` import `practice/data/repositories/mastery_graph_repository.dart` and `mastery_state_model.dart`

**Cycle C — SUBJECTS → SESSIONS → PLANNER → PRACTICE → SUBJECTS (4-hop):**
Superset of Cycle B with `subjects/` at both ends.

**Acceptance Criteria:**
- [ ] No compile-time circular dependency exists between any two features (verified by `dart analyze` or a dependency graph tool).
- [ ] Cycle A is broken (e.g., extract `SourceRepository` into core/data, or introduce a core abstraction that both features depend on).
- [ ] Cycle B is broken (e.g., `session_tracker_screen.dart` uses providers/callbacks instead of direct repo imports).

---

### M4. `_logger.e()` Misuse (~70+ instances across 8+ files)

**Rationale:** `_logger.e()` (error level) is used for caught, expected, recoverable failures — inflating error monitoring and masking genuine crashes. Expected failures (data not found, network timeout, fallback to default) should be `_logger.w()`.

**Affected files with highest density:**
- `lib/features/sessions/data/repositories/session_repository.dart` — all 16 catch blocks use `_logger.e()` for operations that return `Result.failure()`
- `lib/features/mentor/services/mentor_service.dart` — 12+ catch blocks for optional data lookups (returns `[]` or `null` on failure)
- `lib/features/practice/services/spaced_repetition_service.dart` — 7 catch blocks
- `lib/features/sessions/presentation/session_tracker_screen.dart` — 3 UI-level catch blocks
- `lib/features/sessions/presentation/session_history_screen.dart` — 2 UI-level catch blocks
- `lib/core/data/extraction/transcription_extractor.dart` — 4 catch blocks for network failures
- `lib/core/data/extraction/ocr_extractor.dart` — 1 catch block

**Acceptance Criteria:**
- [ ] All `_logger.e()` calls wrapping expected/recoverable failures are demoted to `_logger.w()`.
- [ ] `_logger.e()` is reserved for unexpected errors that indicate bugs, data corruption, or unrecoverable states.

---

### M5. Reverse Dependency: Core Services Importing Feature Repositories

**Rationale:** `lib/core/services/` is architecturally supposed to be the foundation layer. Currently 12 core services import from `lib/features/`, inverting the dependency direction. This is caused by 19 shared domain models living inside feature folders.

**Core services that import feature repositories/models:**
- `personal_learning_plan_service.dart` — 5 feature repos, 2 feature models, 1 feature service
- `engagement_scheduler.dart` — 2 feature repos, 2 feature models, 1 feature service
- `mastery_graph_service.dart` — 5 feature repos, 3 feature models
- `instrumentation_service.dart` — 2 feature repos, 3 feature models
- `study_progress_tracker.dart` — 2 feature repos, 1 feature model
- `progress_export_service.dart` — 2 feature repos, 1 feature model
- `topic_readiness_service.dart` — 2 feature repos, 2 feature models
- `plan_adapter.dart` — 2 feature repos, 1 feature model
- `badge_service.dart` — 2 feature repos, 1 feature model
- `conversation_memory.dart` — 1 feature repo, 1 feature model
- `answer_validation_service.dart` — 1 feature model
- `llm_usage_meter.dart` — 1 feature model

**Key models to promote to `lib/core/data/models/` (19 identified):**
| Current Location | Key Consumers |
|---|---|
| `features/practice/data/models/mastery_state_model.dart` | 7 core services, 4 features |
| `features/planner/data/models/personal_learning_plan_model.dart` | 2 core services, 4 features |
| `features/planner/data/models/plan_adherence_model.dart` | 2 core services, 2 features |
| `features/planner/data/models/engagement_nudge_model.dart` | 1 core service, 2 features |
| `features/questions/data/models/question_evaluation_model.dart` | 1 core service, 3 features |
| `features/subjects/data/models/topic_dependency_model.dart` | 2 core services, 4 features |
| `features/practice/data/models/question_mastery_state_model.dart` | 1 core service, 2 features |
| `features/practice/data/models/mastery_improvement_metric_model.dart` | 1 core service, 1 feature |
| `features/ingestion/data/models/source_model.dart` | 4 features |
| `features/lessons/data/models/lesson_model.dart` | 3 features |
| `features/teaching/data/models/conversation_message_model.dart` | 4 features |
| `features/dashboard/data/models/badge_model.dart` | 1 core service, 1 feature |
| `features/dashboard/data/models/dashboard_models.dart` | 2 features |
| `features/lessons/data/models/lesson_block_model.dart` | 2 features |

**Acceptance Criteria:**
- [ ] All models imported by 2+ features or by core services are promoted to `lib/core/data/models/`.
- [ ] After promotion, no `lib/core/` file imports from `lib/features/`.
- [ ] After promotion, no feature imports from another feature's `data/models/` (only from core).

---

## MINOR

### N1. Feature-Specific Services in `lib/core/services/` (misplaced, 6 items)

| Service | Only Used By |
|---|---|
| `badge_service.dart` | `focus_mode/presentation/focus_timer_screen.dart` |
| `answer_validation_service.dart` | `features/practice/` |
| `data_backup_service.dart` | `features/settings/presentation/settings_screen.dart` |
| `remaining_workload_estimator.dart` | `features/dashboard/` |
| `session_plan_adherence_service.dart` | Zero imports (dead code) |
| `cross_feature_integrator.dart` | `features/practice/providers/practice_providers.dart` |

**Acceptance Criteria:**
- [ ] Each service is moved into its consuming feature's `services/` directory.
- [ ] `session_plan_adherence_service.dart` is either removed or given a production consumer.

---

### N2. Overly Long / Complex Functions (SRP violations, top 5)

| Function | File | Lines | `if`s | Problem |
|---|---|---|---|---|
| `_parseExpression()` | `lib/features/questions/presentation/widgets/math_expression_widget.dart:75` | 321 | 12-branch chain | Mixes LaTeX tokenization with widget construction. Should split into tokenizer + renderer. |
| `_fetchTranscript()` | `lib/core/data/extraction/transcription_extractor.dart:199` | 153 | 13 | Highest cyclomatic density. Multiple API fallbacks with nested JSON/text/HTML detection. |
| `build()` | `lib/features/ingestion/presentation/upload_screen.dart:356` | 295 | — | Giant form with 15+ fields, all inline. Extract per-section builder methods. |
| `_sendNudgeNotifications()` | `lib/core/services/engagement_scheduler.dart:153` | 119 | 8 | Five near-identical nudge blocks. Extract to a config-driven helper. |
| `processFullPipeline()` | `lib/features/ingestion/services/content_pipeline.dart:86` | 143 | 6 | 14 parameters, mutable state threaded through stages. Split into pipeline-stage pattern. |

**Acceptance Criteria for each:**
- [ ] Function is split so no function exceeds 80 lines.
- [ ] Cyclomatic complexity per function is ≤ 8 (per Dart lint `cyclomatic_complexity`).
- [ ] Each new function has a single responsibility.

---

### N3. Redundant Abstractions (6 items)

| Abstraction | File | Issue |
|---|---|---|
| `MasteryGraphRepository` (facade) | `lib/features/practice/data/repositories/mastery_graph_repository.dart` | Self-acknowledged anti-pattern ("New code should depend on the specific repositories directly"). All 8 delegations are pass-throughs. |
| `MasteryGraphService` (9/17 methods) | `lib/core/services/mastery_graph_service.dart` | 9 methods are pure repository pass-throughs adding no business logic. |
| `ActionPlanner` (abstract class) | `lib/features/planner/services/action_planner.dart` | Exactly 1 implementation (`PlannerService`). No polymorphism benefit. |
| `PlanAdherenceContract` | `lib/core/data/contracts/plan_adherence_contract.dart` | Exactly 1 implementation (`SessionPlanAdherenceService`). |
| `Clock` | `lib/core/utils/clock.dart` | Single impl, single consumer. Replace with `DateTime Function()` parameter. |
| `createRoadmapFromGoal()` | `lib/features/planner/services/planner_service.dart:211` | Pure pass-through to `createRoadmap()` with identical signature. |

**Acceptance Criteria:**
- [ ] `MasteryGraphRepository` is removed; consumers inject specific repos directly.
- [ ] `MasteryGraphService` pure pass-throughs are removed; consumers inject repos directly.
- [ ] `ActionPlanner`, `PlanAdherenceContract`, `Clock` are inlined or removed.
- [ ] `createRoadmapFromGoal()` is removed; callers use `createRoadmap()` directly.

---

### N4. Repeated Code Patterns Extractable to Shared Utilities

| Pattern | Occurrences | Lines Wasted | Suggested Fix |
|---|---|---|---|
| `try`→`Result.success` / `catch`→`Result.failure` | ~164 instances across 8+ repos | ~400 | Add `_wrap<T>(Future<T> Function() fn, String op)` helper to `Repository<T>` base class |
| Nudge notification blocks | 5 near-identical blocks in `engagement_scheduler.dart:153-271` | ~95 | Extract to config-driven `_processNudgeType()` method |
| Repository `init()` (try/catch/rethrow) | 6 identical blocks | ~36 | Extract to base class: `Future<void> init(String boxName, {Logger? logger})` |
| Logger field declarations | 94 instances across codebase | ~94 | Add `HasLogger` mixin with `Logger get _logger => const Logger('$runtimeType');` |

**Acceptance Criteria:**
- [ ] The `try`→`Result` pattern is extracted to a reusable helper and used consistently.
- [ ] Nudge notifications are refactored to eliminate the 5-block duplication.
- [ ] Repository `init()` uses the base-class extraction.
- [ ] Logger declarations follow a consistent mixin or computed-property pattern.

---

### N5. Hardcoded Configuration Values (no environment override mechanism)

**API URLs** — `lib/core/constants/app_api_config.dart:56-61`: All 6 endpoint URLs and `User-Agent` are compile-time constants. `ApiConfig.forEnvironment()` accepts an `AppEnvironment` param but returns the same URLs for all environments.

**Token pricing** — `lib/core/constants/token_pricing_config.dart:8-11`: LLM pricing changes when providers update their rates. No runtime override.

**Magic numbers across business logic:**
| File | Values | Context |
|---|---|---|
| `lib/features/sessions/services/study_timer_service.dart` | 25, 500, 5000, 60000 | Timer defaults & caps |
| `lib/features/mentor/services/mentor_service.dart` | 48 (hrs), 5 (cap), 30 (min) | Nudge thresholds |
| `lib/core/services/engagement_scheduler.dart` | 4, 3, 7 (days) | Nudge timing |
| `lib/core/services/plan_adapter.dart` | 7 (days), 30 (min), 15 (questions) | Plan defaults |
| `lib/core/data/extraction/transcription_extractor.dart:255-257` | Hardcoded User-Agent (should reuse `ApiConfig.userAgent`) | Duplicated config |

**Acceptance Criteria:**
- [ ] Environment-level overrides are supported for API URLs (env vars or runtime config).
- [ ] Hardcoded magic numbers >= 3 in business logic are extracted to named constants.
- [ ] Duplicated User-Agent in `transcription_extractor.dart` is replaced with `ApiConfig.userAgent`.
- [ ] Token pricing is configurable at runtime.

---

### N6. Outdated / Misleading Comments (3 items)

| File | Line | Comment | Problem |
|---|---|---|---|
| `lib/features/teaching/data/models/lesson_plan_model.dart` | 72 | `// TODO: i18n - callers should override with localized values from ARB keys` | i18n system is mature; TODO never acted on. `defaultPlan()` returns hardcoded English. |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 130 | `// silent - badge check is non-critical` | Error silently swallowed with no logging. |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 144 | `// Logged internally by PlanAdapter, non-critical for UX` | Misleading — PlanAdapter does not log errors caused by record call failures. |

**Acceptance Criteria:**
- [ ] `lesson_plan_model.dart` TODO is resolved (localize default plan strings) or the comment is removed.
- [ ] `focus_timer_screen.dart` empty catches are replaced with at minimum `_logger.w()`.

---

### N7. Missing Test Files (per AGENTS.md conventions, 6 files)

| Source File | Expected Test |
|---|---|
| `lib/features/onboarding/services/onboarding_service.dart` | `test/features/onboarding/services/onboarding_service_test.dart` |
| `lib/features/sessions/data/repositories/session_utils.dart` | `test/features/sessions/data/repositories/session_utils_test.dart` |
| `lib/core/data/models/markscheme_model.dart` | `test/core/data/models/markscheme_model_test.dart` |
| `lib/core/data/contracts/plan_adherence_contract.dart` | (if not removed per N3) |
| `lib/core/data/contracts/session_query_contract.dart` | (if not removed per M1) |
| `lib/core/services/session_plan_adherence_service.dart` | (if not removed per N1) |

**Acceptance Criteria:**
- [ ] Every production Dart file has a corresponding test file following the AGENTS.md convention.
- [ ] Orphaned source files (identified for deletion in M1/N1/N3) are removed rather than tested.

---

### N8. Barrel File / Export Inconsistencies

`lib/features/dashboard/dashboard.dart` does not export `workload_card.dart` even though `lib/features/dashboard/presentation/dashboard_screen.dart` imports it directly (bypassing the barrel).

Similar violations exist in `subjects.dart`, `questions.dart`, and others (see full list in audit).

**Acceptance Criteria:**
- [ ] All feature barrel files export every public file in the feature.
- [ ] No production import in `lib/` bypasses a feature's barrel file (verified by lint rule or manual check).

---

## Appendix: Files Referenced in This Issue

| Category | Files |
|---|---|
| **Dead code** | `lib/core/data/contracts/session_query_contract.dart`, `lib/features/planner/data/models/task_model.dart`, `lib/core/services/pdf_generator/question_pdf_generator.dart`, `lib/features/dashboard/services/dashboard_service.dart`, `lib/core/errors/handlers.dart` |
| **Error handling** | `lib/core/data/repository.dart`, `lib/core/errors/result.dart`, `lib/core/errors/handlers.dart`, all repository files in features/*/data/repositories/, `lib/features/ingestion/services/document_extractor.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/subjects/data/repositories/subject_repository.dart`, `lib/features/subjects/data/repositories/topic_repository.dart`, `lib/features/practice/data/repositories/attempt_repository.dart`, `lib/features/dashboard/data/repositories/badge_repository.dart` |
| **Circular dependencies** | `lib/features/subjects/presentation/subject_detail_screen.dart`, `lib/features/ingestion/` (5 files), `lib/features/sessions/presentation/session_tracker_screen.dart`, `lib/features/planner/services/planner_service.dart`, `lib/features/planner/services/syllabus_resolver.dart`, `lib/features/practice/services/practice_session_service.dart`, `lib/features/practice/services/exam_session_service.dart` |
| **Log level misuse** | `lib/features/sessions/data/repositories/session_repository.dart`, `lib/features/mentor/services/mentor_service.dart`, `lib/features/practice/services/spaced_repetition_service.dart`, `lib/features/sessions/presentation/session_tracker_screen.dart`, `lib/features/sessions/presentation/session_history_screen.dart`, `lib/core/data/extraction/transcription_extractor.dart`, `lib/core/data/extraction/ocr_extractor.dart` |
| **Reverse dependencies** | 12 core services listed in M5, 19 shared models listed in M5 |
| **Feature services in core** | `lib/core/services/badge_service.dart`, `lib/core/services/answer_validation_service.dart`, `lib/core/services/data_backup_service.dart`, `lib/core/services/remaining_workload_estimator.dart`, `lib/core/services/session_plan_adherence_service.dart`, `lib/core/services/cross_feature_integrator.dart` |
| **Complex functions** | `lib/features/questions/presentation/widgets/math_expression_widget.dart`, `lib/core/data/extraction/transcription_extractor.dart`, `lib/features/ingestion/presentation/upload_screen.dart`, `lib/core/services/engagement_scheduler.dart`, `lib/features/ingestion/services/content_pipeline.dart` |
| **Redundant abstractions** | `lib/features/practice/data/repositories/mastery_graph_repository.dart`, `lib/core/services/mastery_graph_service.dart`, `lib/features/planner/services/action_planner.dart`, `lib/core/data/contracts/plan_adherence_contract.dart`, `lib/core/utils/clock.dart`, `lib/features/planner/services/planner_service.dart` |
| **Hardcoded config** | `lib/core/constants/app_api_config.dart`, `lib/core/constants/token_pricing_config.dart`, `lib/features/sessions/services/study_timer_service.dart`, `lib/core/services/plan_adapter.dart`, `lib/core/data/extraction/transcription_extractor.dart` |
| **Misleading comments** | `lib/features/teaching/data/models/lesson_plan_model.dart`, `lib/features/focus_mode/presentation/focus_timer_screen.dart` |
| **Missing tests** | `lib/features/onboarding/services/onboarding_service.dart`, `lib/features/sessions/data/repositories/session_utils.dart`, `lib/core/data/models/markscheme_model.dart` |
| **Barrel inconsistencies** | `lib/features/dashboard/dashboard.dart`, `lib/features/subjects/subjects.dart` |
