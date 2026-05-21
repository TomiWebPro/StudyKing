# Code Quality & Architecture Master Issue

> **Owner:** Code Refactor Master & Quality  
> **Generated:** 2026-05-20  
> **Severity distribution:** 7 BLOCKER · 14 MAJOR · 20 MINOR

---

## BLOCKER — App crashes or user cannot proceed

### B1. `result.error!` null-assert crashes (9 sites — 6 files)

`Result.failure(null)` is a valid construction, but 9 call sites use `result.error!` without guarding against null. This will crash at runtime if a `Result.failure(null)` propagates through.

**Affected files:**
- `lib/core/services/llm_agent/agent_loop.dart:60` — `_taskManager?.failTask(taskId, result.error!)`
- `lib/features/planner/services/llm_planner_advisor_strategy.dart:167` — `return Result.failure(result.error!)`
- `lib/features/teaching/services/exercise_evaluator.dart:70` — `l10n.couldNotEvaluateAnswerWithError(result.error!)`
- `lib/features/lessons/services/lesson_agent_service.dart:59` — `_taskManager?.failTask(taskId, createResult.error!)`
- `lib/features/settings/presentation/settings_screen.dart:1140,1215` — **2 sites**
- `lib/features/settings/presentation/profile_screen.dart:136`
- `lib/features/planner/presentation/planner_screen.dart:225` — **2 accesses** (`next.error!.contains(...)`)

**Fix:** Either make `error` non-nullable in `Result.failure()`, or guard each site with `?? 'Unknown error'`.

---

### B2. Empty `catch (_) {}` blocks (2 sites)

**AGENTS.md mandate:** "Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message."

- `lib/core/utils/question_import_utils.dart:128` — silently swallows `DateTime.parse` failure during CSV import. If a user imports a CSV with unparseable dates, the import silently drops rows with no feedback.
- `lib/features/questions/presentation/widgets/file_upload_widget.dart:50` — silently swallows file-picker errors. If the OS denies file access, the user sees nothing.

**Fix:** Add `_logger.e()` with a descriptive message in both catch blocks.

---

### B3. `rethrow` in public methods (8 sites — 5 files)

**AGENTS.md rule:** `throw` is only allowed in private helper methods or config validation at startup.

- `lib/features/mentor/services/mentor_service.dart:217` — `rethrow` in `respond()`
- `lib/core/services/llm/llm_chat_service.dart:217,561,676,794` — `rethrow` in 4 public streaming/calling methods
- `lib/features/teaching/services/tutor_service.dart:195` — `rethrow` in tutor response
- `lib/features/teaching/services/conversation_manager.dart:231,287` — `rethrow` in evaluation/response
- `lib/features/subjects/providers/subjects_repository_provider.dart:20` — `rethrow` in notifier

**Fix:** Wrap with `Result.capture()` or `Result.failure(...)` instead of rethrowing. The caller expects `Result<T>`, not raw exceptions.

---

### B4. Orphaned production files — never imported (11 files)

These files exist in `lib/` but are not imported by any other production file. They represent dead code — unreachable at runtime:

| File | Class | Notes |
|---|---|---|
| `lib/core/services/llm/llm_embeddings_service.dart` | `EmbeddingService` | Zero production references |
| `lib/core/utils/sr_data_codec.dart` | `SrDataCodec` | Zero production references |
| `lib/features/dashboard/services/dashboard_service.dart` | `DashboardService` | Zero production references |
| `lib/features/lessons/services/lesson_service.dart` | `SessionQueryService` | Also has name/file mismatch |
| `lib/features/onboarding/data/models/onboarding_state.dart` | `OnboardingState` | Zero production references |
| `lib/features/planner/data/repositories/advisor_suggestions_repository.dart` | `AdvisorSuggestionsRepository` | Zero production references |
| `lib/features/planner/services/llm_planner_advisor_strategy.dart` | `LlmPlannerAdvisorStrategy` | Implements `PlannerAdvisorStrategy` but not wired |
| `lib/features/practice/presentation/screens/review_answers_screen.dart` | `ReviewAnswersScreen` | No route registered — unreachable |
| `lib/features/questions/presentation/widgets/math_input_toolbar.dart` | `MathInputToolbar` | Zero production references |
| `lib/features/questions/presentation/widgets/question_card_widget.dart` | `QuestionCardWidget` | Zero production references |
| `lib/features/subjects/data/models/topic_progress_model.dart` | `TopicProgress` | Zero production references |

**Fix:** Delete unused files, or register/wire them if they are intentionally awaiting integration.

---

### B5. `Result.fold()` — dead API in core error type

`Result.fold<S>(S Function(T) onSuccess, S Function(String) onFailure)` in `lib/core/errors/result.dart:15` has zero callers in the entire codebase. It is discovered dead code on the `Result` type itself.

**Fix:** Remove the method and simplify the class.

---

### B6. `catchError` wrapping a Result-returning Future

`lib/features/practice/presentation/screens/practice_screen.dart:511`:
```dart
await _questionRepo.getAll().catchError((_) => Result.success(<Question>[]));
```
`_questionRepo.getAll()` already returns `Future<Result<List<Question>>>` — errors are captured inside `Result`. The outer `.catchError` is redundant and indicates confusion about the error handling pattern.

**Fix:** Remove `.catchError` wrapper.

---

### B7. `SpacedRepetitionErrorCode` too narrow — string literals everywhere

The `SpacedRepetitionErrorCode` enum (in `lib/core/errors/spaced_repetition_error_codes.dart`) only has 2 values (`boxClosed`, `notFound`), but 67+ `Result.failure('string literal')` calls exist across 18 files. This means the entire error-space of the app is stringly-typed, making it impossible to match/categorize errors programmatically.

**Most egregious examples:**
- `'No_active_session'` in `sessions/services/study_timer_service.dart`
- `'Pipeline cancelled'`, `'Source has no content to reprocess'` in `ingestion/services/content_pipeline.dart`
- `'Question_not_found: $questionId'` (3 files, redundant pattern)
- `'Failed to $action: $e'` generic pattern across 3 repositories
- `'not_found'` in `practice/data/repositories/question_evaluation_repository.dart`

**Fix:** Expand `SpacedRepetitionErrorCode` (or create `AppErrorCode`/`AppError`) with domain-specific codes. Each distinct string literal in `Result.failure()` should become an enum variant.

---

## MAJOR — Feature is broken or misleading

### M1. Circular dependency: `subjects` ↔ `lessons`

- `subjects` → `lessons`: `subject_lessons_tab.dart` imports `lesson_model.dart`, `lesson_repository.dart`, `lesson_providers.dart`
- `lessons` → `subjects`: `topic_list_screen.dart` imports `topic_repository_provider.dart`

**Fix:** Extract shared providers (`topic_repository_provider`) and models into `lib/core/`. Both features should depend on core only.

### M2. Circular dependency: `subjects` ↔ `ingestion`

- `subjects` → `ingestion`: `subject_detail_screen.dart` imports `source_repository.dart`
- `ingestion` → `subjects`: 4 files import `subjects/data/repositories/subject_repository.dart`

**Fix:** Move `SubjectRepository` and `SourceRepository` to `lib/core/data/repositories/`.

### M3. Circular dependency: `subjects` ↔ `practice`

- `subjects` → `practice`: `subject_topics_tab.dart` imports `practice_providers.dart`
- `practice` → `subjects`: 5 files import `subjects/data/repositories/subject_repository.dart`

**Fix:** Extract shared `practice_providers` deps into core; move `SubjectRepository` to core.

### M4. Circular dependency: `planner` → `subjects` → `practice` → `sessions` → `planner` (4-cycle)

- planner depends on subjects
- subjects depends on practice
- practice depends on sessions
- sessions depends on planner (`session_tracker_screen.dart` imports `planner/data/repositories/plan_repository.dart`)

**Fix:** Move `PlanRepository` to `lib/core/data/repositories/`. Break the sessions→planner edge.

### M5. Circular dependency: `practice` → `questions` → `subjects` → `practice` (3-cycle)

- practice depends on questions (19 imports — heaviest cross-feature edge)
- questions depends on subjects (question_bank_screen, question_providers)
- subjects depends on practice (subject_topics_tab)

**Fix:** Extract `QuestionEvaluation`, `TopicDependency`, and shared subjects components into core.

### M6. Circular dependency: `practice` → `questions` → `ingestion` → `subjects` → `practice` (4-cycle)

**Fix:** Same as M5 + move `SourceRepository` to core.

### M7. Circular dependency: `ingestion` → `lessons` → `subjects` → `ingestion` (3-cycle)

- ingestion → lessons: `content_pipeline.dart` imports `lesson_agent_service.dart`
- lessons → subjects: `topic_list_screen.dart`
- subjects → ingestion: `subject_detail_screen.dart`

**Fix:** Move `LessonAgentService`-like LLM logic to core; extract subjects-to-ingestion shared deps to core.

### M8. 13 shared models deep inside feature folders

These models are referenced from core (`shared_providers.dart`, `hive_initializer.dart`, `database_service.dart`) and multiple sister features, but they live inside a single feature's subtree:

| Model | Current Location | Used By |
|---|---|---|
| `ConversationMessage` | `teaching/data/models/` | core, mentor, quickguide, settings |
| `TutorSession` | `teaching/data/models/` | core, settings |
| `QuestionEvaluation` | `questions/data/models/` | core, practice, settings |
| `StudentAttempt` | `practice/data/models/` | core, settings |
| `PersonalLearningPlan` | `planner/data/models/` | core, dashboard, mentor, settings |
| `PlanAdherenceModel` | `planner/data/models/` | core (2 files), settings |
| `EngagementNudge` | `planner/data/models/` | core, mentor |
| `PendingAction` | `planner/data/models/` | core, mentor |
| `TopicDependency` | `subjects/data/models/` | core, practice, planner, settings |
| `BadgeModel` | `dashboard/data/models/` | core, settings |
| `FocusSessionModel` | `focus_mode/data/models/` | core, settings |
| `SettingsBox` / `SettingsUpdate` | `settings/data/models/` | core, focus_mode |

**Fix:** Move all to `lib/core/data/models/`. Update all imports. This eliminates 7 out of 8 cross-feature cycles at the model layer.

### M9. 9 feature-level repositories used by core and multiple features

| Repository | Current Location | Used By |
|---|---|---|
| `TopicDependencyRepository` | `practice/data/repositories/` | core service |
| `QuestionEvaluationRepository` | `practice/data/repositories/` | core service |
| `LessonRepository` | `lessons/data/repositories/` | core, teaching, subjects, ingestion |
| `QuestionRepository` | `questions/data/repositories/` | core, practice, ingestion, planner, mentor |
| `SubjectRepository` | `subjects/data/repositories/` | core, practice, planner, ingestion, questions, sessions |
| `ConversationRepository` | `teaching/data/repositories/` | core, mentor |
| `TutorSessionRepository` | `teaching/data/repositories/` | core |
| `SourceRepository` | `ingestion/data/repositories/` | core, questions, subjects, practice, settings |
| `SettingsRepository` | `settings/data/repositories/` | core |

**Fix:** Move all to `lib/core/data/repositories/` since they serve as core data access layer. Update imports.

### M10. God class: `_SettingsScreenState` — 1,992 lines

`lib/features/settings/presentation/settings_screen.dart` — a single State class handling settings UI, backup/restore, data deserialization, dialog management (14+ types of dialogs), analytics display, AI model management, sign-out flow.

**Fix:** Split into focused widget classes: `BackupRestoreSection`, `AppearanceSection`, `SpacedRepetitionSection`, `AIConfigurationSection`. Each should be a standalone widget with its own state.

### M11. God class: `_QuestionBankScreenState` — 1,478 lines

`lib/features/questions/presentation/question_bank_screen.dart` — handles question CRUD, bulk operations, 4 filter methods, question form building, topic/subject/source lookups.

**Fix:** Extract question form, filter logic, and bulk operations into separate controller/service classes.

### M12. God class: `_MentorScreenState` — 1,408 lines

`lib/features/mentor/presentation/mentor_screen.dart` — manages chat lifecycle, schedule dialogs, voice input, scroll management, message streaming, intent handling, nudge loading, suggested actions.

**Fix:** Extract chat logic to `MentorChatController`, schedule dialogs to separate widgets, intent handling to a dedicated service.

### M13. God service: `PersonalLearningPlanService` — 1,102 lines

`lib/features/planner/services/personal_learning_plan_service.dart` — plan generation, adherence tracking, workload redistribution, question linking, roadmap updates all mixed in one class with 9 injected repositories/services.

**Fix:** Split into `PlanGeneratorService`, `AdherenceService`, `WorkloadDistributor`, and `QuestionLinker`.

### M14. God service: `LlmService` — 825 lines (8 nearly-identical streaming/calling methods)

`lib/core/services/llm/llm_chat_service.dart` — 4 providers × 2 variants (stream/call) = 8 methods with duplicated HTTP/JSON logic. Only the URL path and payload structure differ.

**Fix:** Extract provider-specific logic into strategy classes (`OpenRouterStrategy`, `OllamaStrategy`, `OpenAIStrategy`, `CustomStrategy`). The main service only routes to the right strategy.

---

## MINOR — Code quality / UX friction

### m1. Inline Logger creation (not `static final`) — 10 sites

Per AGENTS.md: "All Logger instances must be `static final` at class level."

- `lib/subjects/presentation/widgets/subject_stats_tab.dart:73` — `Logger('SubjectStatsTab')`
- `lib/planner/providers/syllabus_providers.dart:63,88` — 2 inline loggers
- `lib/planner/providers/adherence_providers.dart:109,172` — 2 inline loggers
- `lib/sessions/services/session_export_service.dart:207,228,250` — 3 inline loggers
- `lib/subjects/providers/subjects_repository_provider.dart:18` — local `final logger`
- `lib/dashboard/services/dashboard_service.dart:18` — local `const logger` in top-level function
- `lib/core/errors/result.dart:34,45` — `Logger(context).w(...)` with dynamic tag

**Fix:** Replace with `static final Logger _logger = const Logger('ClassName');`.

### m2. Hardcoded durations bypassing `timeouts.dart` — 20+ sites

Durations hardcoded as literals in service/presentation files instead of referencing `lib/core/constants/timeouts.dart`:

- `engagement_scheduler.dart:148` — `Duration(minutes: 5)` lesson timer
- `llm_chat_service.dart:109-110` — rate limiting durations
- `tutor_screen.dart:142,207,264,528` — 4 timer/delay durations
- `mentor_screen.dart:345` — post-chat delay
- `question_bank_screen.dart:79` — debounce timer
- `session_history_screen.dart:653` — date range
- `mastery_calculation_service.dart:88` — expected time per question
- `practice_screen.dart:358` — magic numbers `0.3, 3, 50`
- `planner/syllabus_resolver.dart:220` — ratio clamp `3.0`

**Fix:** Define named constants in `timeouts.dart` or feature-specific config classes.

### m3. `_recencyScore` duplicated in 2 files

Identical 5-tier recency scoring logic exists in:
- `lib/core/data/models/question_mastery_state_model.dart:180` — static method
- `lib/core/services/mastery_calculation_service.dart:118` — instance method

If one is updated and the other is not, mastery calculations diverge.

**Fix:** Extract to `lib/core/utils/mastery_utils.dart` as a shared function.

### m4. `.e()` used for expected errors (should be `.w()`) — 2 sites

- `lib/mentor/presentation/mentor_screen.dart:1308` — `_logger.e('Failed to pop navigator in error handler', e)` — navigator pop failure in error recovery is an expected edge case
- `lib/core/errors/handlers.dart:156` — `_logError` categorizes ALL exceptions (network, API rate limit, validation) as `.e()` when many are anticipated

### m5. `.i()` used for operational diagnostics (should be `.d()`) — 10 sites

- `lib/teaching/services/conversation_manager.dart:461` — phase transitions
- `lib/teaching/presentation/tutor_screen.dart:530` — expected lifecycle event
- `lib/main.dart:137,144,261` — startup diagnostics
- `lib/core/data/database_migration.dart:16` — version diagnostic
- `lib/core/data/hive_initializer.dart:63` — startup diagnostic
- `lib/sessions/services/session_migration_service.dart:19,54` — migration completion

### m6. Misleading class name: `AppConstants` is not constants

`lib/core/constants/app_config.dart` — class `AppConstants` holds a mutable singleton for runtime `AppConfig`. The name implies static constants.

**Fix:** Rename to `AppConfigHolder` or `AppConfigSingleton`.

### m7. File/class name mismatch

`lib/features/lessons/services/lesson_service.dart` contains `class SessionQueryService` — file name doesn't match class name.

**Fix:** Rename file to `session_query_service.dart` or class to `LessonService`.

### m8. Hardcoded API URLs in `app_api_config.dart`

`openRouterBaseUrlString`, `ollamaDefaultUrl`, `openAIDefaultUrl`, `youtubetranscriptApiUrl`, `_youtubeBaseUrl` — all hardcoded strings with only partial `fromEnvironment` support.

**Fix:** Define environment variable keys in `.env.example` and read via `String.fromEnvironment()`.

### m9. Hardcoded backup filename in 2 places

- `lib/main.dart:140` — `File('${dir.path}/studyking_backup.json')`
- `lib/features/settings/services/data_backup_service.dart:64` — default `'studyking_backup'`

**Fix:** Move to `lib/core/constants/app_storage_config.dart`.

### m10. Hardcoded numeric thresholds across services

`mastery_calculation_service.dart` (0.9, 0.8, 0.6, 30.0, 1/3/7/14 days), `readiness_scorer.dart` (0.4, 0.3, 0.2, 0.1 weights), `exam_session_service.dart` (difficulty thresholds 2/3/4), `planner_service.dart` (50 max questions, 2× multiplier) — all magic numbers.

**Fix:** Extract into config files: `lib/core/constants/mastery_config.dart`, `readiness_config.dart`, `exam_config.dart`.

### m11. `lib/core/services/mastery_graph_service.dart` imports from feature repos

This core service imports `TopicDependencyRepository` and `QuestionEvaluationRepository` from `features/practice/data/repositories/`. This is an inverted dependency — core should not know about feature-internal packages.

**Fix:** Move both repositories to `lib/core/data/repositories/` (see M9).

### m12. `lib/core/providers/llm_agent_providers.dart` imports from 5 features

Wires feature-level agent tools (planner, practice, questions, mentor, lessons) directly inside a core provider file.

**Fix:** This is less critical for now since it's "wiring," but ideally feature-level tool providers should live in their respective features and cross-link through core interfaces.

### m13. Hardcoded engagement scheduler check time

`lib/core/services/engagement_scheduler.dart:28-29` — `checkHour = 9, checkMinute = 0`. This should be user-configurable or at least a named constant.

### m14. `QuestionSRData` class lives in a service file

`lib/features/practice/services/spaced_repetition_engine.dart` contains `QuestionSRData` — a pure data class used for serialization in core (`sr_data_codec.dart`). Data classes belong in models, not services.

**Fix:** Move `QuestionSRData` to `lib/core/data/models/sr_data.dart`.

### m15. Teaching prompts inside feature folder

`lib/features/teaching/services/prompts/prompts.dart` contains conversation/system prompts used by core LLM services. Prompts are core-level resources, not feature-specific.

**Fix:** Move to `lib/core/services/llm/prompts/`.

### m16. `todo` comment in engagement_scheduler.dart

`lib/core/services/engagement_scheduler.dart:45` — stale TODO about unifying nudge logic with non-existent `MentorWellbeingService`.

**Fix:** Either implement or remove.

### m17. Stale `ignore_for_file: unused_import` in generated l10n files

`lib/l10n/generated/app_localizations_es.dart:1` and `app_localizations_en.dart:1` — `// ignore: unused_import` for `import 'package:intl/intl.dart'` while `intl` IS used in the file. Redundant suppression.

**Fix:** Remove the stale ignore comments in the next l10n regeneration.

### m18. Services calling `.init()` on repositories inside business methods

Multiple services (e.g., `PersonalLearningPlanService`, `TutorService`, `PlannerService`) call `await _repository.init()` inside their public business methods instead of assuming the provider layer ensures initialization.

**Fix:** Remove `.init()` calls from business methods; move initialization responsibility to providers or `main.dart` startup.

### m19. `ContentPipeline.processFullPipeline` — 207 lines, 5 stages

One method handles: duplicate checking, source creation, text extraction, topic classification, summary generation, question generation, lesson generation, status tracking, cancellation checks, error mapping.

**Fix:** Extract each pipeline stage into its own method/class (e.g., `DuplicationCheckStage`, `ExtractionStage`, `ClassificationStage`, `QuestionGenerationStage`, `LessonGenerationStage`).

### m20. `TutorService.endLesson` — 10 distinct operations

Saves session + records mastery + persists exercises + records adherence + saves Session model + updates scheduled session + saves Lesson record + enqueues 3 background tasks + generates summary + resets state.

**Fix:** Extract background tasks into an `EndLessonPipeline` orchestrator; separate persistence from side-effects.

---

## Acceptance Criteria

"Fixed" means:

1. **BLOCKER items**: Zero nullable-assert crashes from `result.error!`. Zero empty `catch (_) {}` blocks. Zero `rethrow` in public `Result<T>` methods. Dead orphan files removed or wired. Dead `Result.fold()` removed.
2. **Circular dependencies**: The cross-feature import graph has no cycles. Every feature depends only on `lib/core/` and its own subtree.
3. **File placement**: All shared models and repositories listed in M8/M9 live in `lib/core/data/models/` and `lib/core/data/repositories/`. Core services no longer import from feature packages.
4. **God classes**: `_SettingsScreenState` ≤600 lines, `_QuestionBankScreenState` ≤600 lines, `_MentorScreenState` ≤600 lines. `PersonalLearningPlanService` and `LlmService` split into focused services with ≤300 lines each.
5. **Error handling**: `SpacedRepetitionErrorCode` covers all domain error cases. All `Result.failure()` calls use typed error codes.
6. **Logging**: All Logger instances are `static final`. No `.e()` for expected errors. No `.i()` for diagnostics (use `.d()`). No `Logger(context).w(...)` dynamic tags.
7. **Duplication**: `_recencyScore` exists in exactly one shared location.
8. **Configuration**: No hardcoded durations outside `timeouts.dart`. No hardcoded numeric thresholds — all extracted to config files.
9. **Dart analyzer**: `dart analyze lib/` passes with zero issues after all changes.
