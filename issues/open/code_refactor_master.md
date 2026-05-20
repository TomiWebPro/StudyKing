# Code Refactor Master & Quality

> **Generated:** 2026-05-20
> **Scope:** Full codebase audit — `lib/` (core + features) and `test/`
> **Focus areas:** Dead code, circular dependencies, complex functions, error handling inconsistencies, redundant abstractions, file placement violations, stale comments, hardcoded configs, repeated code patterns, test gaps

---

## BLOCKER (app crashes or user cannot proceed)

### B1: Circular dependency — `core/providers/app_providers.dart` ↔ `features/mentor/providers/mentor_providers.dart`

- **Files:**
  - `lib/core/providers/app_providers.dart:33` — imports `mentorServiceProvider` from `features/mentor/providers/mentor_providers.dart`
  - `lib/features/mentor/providers/mentor_providers.dart:7` — imports `llmProviderProvider`, `settingsProvider`, `l10nProvider`, `databaseProvider` from `core/providers/app_providers.dart`
- **Rationale:** Direct bidirectional import between core and a feature. Neither file compiles independently. Riverpod's lazy init masks this at runtime but it violates clean architecture and creates a fragile dependency that cascading failures.
- **Acceptance criteria:**
  - Extract `mentorServiceProvider` into its own file that does NOT import `app_providers.dart`
  - OR: move shared providers (`llmProviderProvider`, etc.) into an intermediate core file that both can import
  - Verify: `grep` for import cycles — no `core/...` file should import from `features/...`

### B2: Untested mentor services (zero test coverage)

- **Files:**
  - `lib/features/mentor/services/mentor_schedule_handler.dart` (228 lines) — scheduling/conflict logic
  - `lib/features/mentor/services/mentor_wellbeing_service.dart` (189 lines) — wellbeing nudge generation
  - `lib/features/mentor/services/mentor_context_builder.dart` (229 lines) — LLM context building
- **Rationale:** These three files total 646 lines of complex production logic with zero tests. Scheduling conflicts, nudge generation, and context building are core mentor capabilities. Bugs here directly affect the user's mentor experience.
- **Acceptance criteria:**
  - Each file gets a corresponding `test/features/mentor/services/*_test.dart`
  - Each test file covers: happy path, error path, empty/nil edge cases
  - Reuse fakes from `test/helpers/fakes.dart` (already provides `FakePlannerService`, `FakeEngagementNudgeRepository`, `FakeSessionRepository`, etc.)

### B3: Core data models (SM-2 / spaced repetition) buried inside practice feature

- **Files:**
  - `lib/features/practice/services/spaced_repetition_engine.dart:3-71` — `QuestionSRData`, `ReviewLogEntry`, `SM2Result` models
  - `lib/features/mentor/services/mentor_schedule_handler.dart:17-31` — `ScheduleProposal` model
  - `lib/features/mentor/services/mentor_service.dart:28-34` — `PlanProposal` model
- **Rationale:** `QuestionSRData` and `ReviewLogEntry` are the core SM-2 data types used across practice, questions, and mastery tracking — they belong in `lib/core/data/models/`. Similarly, `ScheduleProposal` and `PlanProposal` are shared domain concepts defined inside feature files, forcing cross-feature model imports.
- **Acceptance criteria:**
  - Move `QuestionSRData`, `ReviewLogEntry`, `SM2Result` to `lib/core/data/models/sr_data_model.dart`
  - Move `ScheduleProposal` to `lib/core/data/models/schedule_proposal.dart` or `lib/features/planner/data/models/`
  - Move `PlanProposal` to `lib/features/planner/data/models/`
  - Update all imports; verify no compilation errors

### B4: `_getConsecutiveStudyDays()` duplicated identically in 2+ files

- **Files:**
  - `lib/features/mentor/services/mentor_context_builder.dart:203-228`
  - `lib/features/mentor/services/mentor_wellbeing_service.dart:163-188`
- **Rationale:** Exact same 25-line algorithm (iterate sessions, group by date, count consecutive days) copy-pasted. Fixing one won't fix the other. Any change to streak logic must be made in N places.
- **Acceptance criteria:**
  - Extract to `lib/core/utils/study_utils.dart` or add method on `SessionRepository`
  - Both callers use the shared implementation
  - Verify with `diff` that call sites accept the same signature

### B5: `_getDailyCapMinutes()` duplicated in 3 files with raw Hive access

- **Files:**
  - `lib/features/mentor/services/mentor_context_builder.dart:194-201`
  - `lib/features/mentor/services/mentor_wellbeing_service.dart:154-161`
  - `lib/features/sessions/services/study_timer_service.dart:63-71`
- **Rationale:** All three independently call `Hive.box(HiveBoxNames.settings).get('dailyCapMinutes')`. This bypasses repository pattern, duplicates the deserialization logic, and makes the settings key a magic string.
- **Acceptance criteria:**
  - Create `SettingsService.getDailyCapMinutes()` in `lib/core/services/settings_service.dart`
  - All three callers use the shared method
  - Remove raw `Hive.box(...)` calls from these files

### B6: `_deserializeSrData()` / `_serializeSrData()` duplicated in 2 files (while shared codec already exists)

- **Files:**
  - `lib/features/practice/services/spaced_repetition_service.dart:132-159`
  - `lib/features/practice/services/mastery_recorder.dart:116-143`
- **Rationale:** Both files define identical JSON serialization/deserialization for `QuestionSRData` fields (`r`, `ef`, `pi`, `lr`). Meanwhile, `lib/core/utils/sr_data_codec.dart` already exists as the intended shared home but is not used by either.
- **Acceptance criteria:**
  - Delete the inline methods from both files
  - Use `SrDataCodec` (or add `QuestionSRData.toJson()`/`fromJson()` methods) in both callers
  - Verify roundtrip equality with existing tests

### B7: Hardcoded `targetQuestionsPerDay: 15` ignores existing constant

- **Files:**
  - `lib/features/planner/services/planner_service.dart:127, 153`
- **Rationale:** The value `15` is hardcoded as `targetQuestionsPerDay:` instead of using `defaultQuestionsPerDay` from `lib/core/utils/study_utils.dart:15`. This means changing the default requires updating multiple locations.
- **Acceptance criteria:**
  - Replace both occurrences with `defaultQuestionsPerDay`
  - Verify no other hardcoded `15` for questions-per-day exists

### B8: Hardcoded duration `30` minutes in 12+ locations

- **Files (non-exhaustive):**
  - `lib/features/mentor/services/mentor_schedule_handler.dart:78,80,83`
  - `lib/features/planner/services/planner_service.dart:313,376,495`
  - `lib/features/planner/providers/planner_providers.dart:512,561`
- **Rationale:** The default lesson duration of 30 minutes is hardcoded in at least a dozen places. The constant `defaultSessionDurationMinutes` exists in `lib/core/utils/study_utils.dart:18` but is not used.
- **Acceptance criteria:**
  - Replace every bare `30` minute default with `defaultSessionDurationMinutes`
  - Verify no remaining hardcoded `30` for duration

### B9: `ContentPipeline.processFullPipeline()` — 170 lines, 16 parameters

- **File:** `lib/features/ingestion/services/content_pipeline.dart:95-265`
- **Rationale:** Single method with 7 distinct stages (save, extract, classify, summarize, generate-questions, validate, generate-lessons), deeply nested try/catch, 16 named parameters. Violates single-responsibility principle. Impossible to unit test individual stages.
- **Acceptance criteria:**
  - Extract each pipeline stage into a private method: `_stageSave`, `_stageExtract`, `_stageClassify`, `_stageSummarize`, `_stageGenerateQuestions`, `_stageValidate`, `_stageGenerateLessons`
  - Reduce parameter count to ≤6 via a PipelineConfig data class
  - Each stage should be independently testable

### B10: `PracticeSessionScreen.build()` — 185 lines

- **File:** `lib/features/practice/presentation/screens/practice_session_screen.dart:591-776`
- **Rationale:** The `build` method is an 185-line deeply nested conditional widget tree with `Consumer`, `AnimatedSwitcher`, multiple `Semantics` layers. Impossible to reason about or test.
- **Acceptance criteria:**
  - Extract into named helper methods: `_buildAppBar()`, `_buildQuestionCard()`, `_buildSubmitArea()`, `_buildConfidenceSelector()`, `_buildSessionComplete()`
  - Verify no widget logic duplication

### B11: `QuestionBankScreen._showCreateQuestionDialog()` — 235 lines

- **File:** `lib/features/questions/presentation/question_bank_screen.dart:280-514`
- **Rationale:** Single method spanning 235 lines with deeply nested widget builders (4+ levels), multiple local controllers and state management. Mixes UI and business logic.
- **Acceptance criteria:**
  - Extract into a standalone widget class `CreateQuestionDialog` in its own file
  - Verify the dialog accepts only the data it needs (not the entire screen state)

### B12: Unused imports — `answer_comparator.dart` imported but not used

- **Files:**
  - `lib/features/planner/presentation/planner_screen.dart:2`
  - `lib/features/subjects/data/curriculum_seed_data.dart:2`
- **Rationale:** `import 'package:studyking/core/utils/answer_comparator.dart'` exists in both files but `AnswerComparator` is never referenced in either body. Likely leftover from a refactor.
- **Acceptance criteria:**
  - Remove the import from both files
  - Verify `lib` tree compiles without errors

### B13: Fire-and-forget `async void _trimRepository()` — silent exception swallowing

- **File:** `lib/core/services/conversation_memory.dart:15,61`
- **Rationale:** `void _trimRepository() async {` is fire-and-forget. Called at line 61 without `await`. Any exceptions thrown by `repo.deleteMessage()` or `repo.getSessionMessages()` are silently swallowed. This can lead to unbounded memory growth if trimming silently fails.
- **Acceptance criteria:**
  - Change return type to `Future<void>`,
  - `await` the call at line 61 (or `unawaited` with explicit error handling),
  - Wrap body in `Result.capture()` with logging

---

## MAJOR (feature broken or misleading)

### M1: `CrossFeatureIntegrator` — 198 lines of dead code

- **File:** `lib/core/services/cross_feature_integrator.dart`
- **Rationale:** `CrossFeatureIntegrator`, `UnifiedTimelineEntry`, and all methods are never imported or referenced outside this file. 198 lines of dead code accumulating maintenance burden.
- **Acceptance criteria:**
  - Delete the entire file
  - Verify no imports reference it
  - If functionality (recordTutorSessionAsSession, linkPracticeSessionToSource) is needed, re-implement in the relevant feature service

### M2: `TopicReadinessService` — 133 lines of dead code

- **File:** `lib/core/services/topic_readiness_service.dart`
- **Rationale:** `TopicReadinessService`, `TopicReadinessResult`, and all methods are never imported anywhere. Overlapping functionality exists in `MasteryGraphService.getTopicMastery()` and `PrerequisiteCheckService`.
- **Acceptance criteria:**
  - Delete the entire file
  - Verify no imports reference it

### M3: Core-to-feature import violations (28+ instances)

- **Files (representative):**
  - `lib/core/services/engagement_scheduler.dart` imports from `features/mentor/`, `features/planner/`, `features/settings/`
  - `lib/core/services/llm_usage_meter.dart:3` imports `UsageRecord` from `features/settings/data/models/settings_model.dart`
  - `lib/core/services/badge_service.dart` imports from `features/dashboard/`
  - `lib/core/providers/app_providers.dart` imports from 7+ features
- **Rationale:** Clean architecture dictates `core/` should not know about `features/`. 28+ violations mean core services and providers are tightly coupled to feature implementations, making independent testing and refactoring impossible.
- **Acceptance criteria:**
  - Move each concrete implementation from core to its respective feature (e.g., `EngagementScheduler` → `features/planner/services/`)
  - OR: Introduce abstract interfaces in core with concrete implementations in features
  - Verify no `lib/core/` file imports from `lib/features/`

### M4: Stale TODO about duplicate nudge logic (EngagementScheduler vs MentorWellbeingService)

- **File:** `lib/core/services/engagement_scheduler.dart:43-46`
- **Rationale:** TODO reads: "Unify overwork/revision nudge logic with MentorWellbeingService." Both classes independently check overwork/revision conditions and generate duplicate `EngagementNudgeModel` entries. Likely producing double notifications.
- **Acceptance criteria:**
  - Consolidate all nudge logic into a single service in `features/planner/services/`
  - Move `EngagementScheduler` itself to `features/planner/services/`
  - Remove the overlapping nudge checks from `MentorWellbeingService`
  - Verify no duplicate nudge creation at runtime

### M5: `MentorKeywords` should live in mentor feature, not core

- **File:** `lib/core/constants/mentor_keywords.dart` (imported by 1 file: `features/mentor/services/mentor_service.dart`)
- **Rationale:** Feature-specific keyword maps with locale-specific data. Core constants should not contain feature-specific logic.
- **Acceptance criteria:**
  - Move to `lib/features/mentor/services/mentor_keywords.dart`
  - Update the single import

### M6: `DifficultyController` — generic state machine in practice feature

- **File:** `lib/features/practice/services/difficulty_controller.dart`
- **Rationale:** Pure state machine with no I/O or practice-specific dependencies. Should be reusable by exam mode and adaptive testing, but is locked inside the practice feature.
- **Acceptance criteria:**
  - Move to `lib/core/utils/difficulty_controller.dart`
  - Update all imports

### M7: `Result` type lacks `fold`/`map` — forces verbose pattern matching

- **File:** `lib/core/errors/result.dart`
- **Rationale:** Callers must write `if (result is SuccessResult<T>) ... else if (result is FailureResult<T>) ...` everywhere. Adding `fold<S>(S Function(T), S Function(String))` would reduce boilerplate and improve readability.
- **Acceptance criteria:**
  - Add `fold<T, S>(S onSuccess(T data), S onFailure(String error))` to `Result`
  - Add `map<T, S>(S Function(T data))` for success-only transforms
  - Update 5-10 representative call sites to demonstrate usage

### M8: `pumpAndSettle()` without timeout (1770+ calls across test suite)

- **Files:** All widget test files. Representative:
  - `test/features/planner/presentation/planner_screen_test.dart` (40+ calls)
  - `test/features/focus_mode/presentation/focus_timer_screen_test.dart`
  - `test/features/onboarding/presentation/onboarding_dialog_widget_test.dart`
  - `test/core/errors/handlers_widget_test.dart`
- **Rationale:** Flutter's default timeout for `pumpAndSettle` is 10 minutes. A genuinely stuck animation or async operation will hang tests for 10 minutes before failing.
- **Acceptance criteria:**
  - Add explicit timeout to every `pumpAndSettle()` call: `pumpAndSettle(const Duration(seconds: 5))` (or appropriate per-call duration)
  - Verify existing tests still pass

### M9: Duplicate fake implementations across test files (428+ private fakes)

- **Files (representative):** `test/features/focus_mode/providers/focus_mode_providers_test.dart`, `test/features/sessions/providers/session_providers_test.dart`, `test/features/subjects/providers/subjects_list_provider_test.dart`, `test/features/mentor/providers/mentor_providers_test.dart`, `test/features/dashboard/providers/dashboard_providers_test.dart`, `test/features/dashboard/providers/dashboard_data_providers_test.dart`
- **Rationale:** ~428 private class definitions (fakes) across the test tree. `test/helpers/fakes.dart` (625 lines) provides shared fakes, but most test files define their own private versions of `FakeSessionRepository`, `FakeAttemptRepository`, `FakeMasteryGraphService`, etc.
- **Acceptance criteria:**
  - Expand `test/helpers/fakes.dart` to cover the commonly re-implemented fakes
  - Refactor private fakes to use the shared versions
  - Track: count of private `class _` definitions should drop by ≥80%

### M10: `try/catch` + `_logger.w()` boilerplate repeated in every service method

- **Files:** Every service file across all features (40+ methods)
- **Rationale:** Nearly every public method follows:
  ```dart
  try {
    // logic
    return Result.success(value);
  } catch (e) {
    _logger.w('MethodName failed', e);
    return Result.failure(e.toString());
  }
  ```
  This is copy-pasted ~40+ times. `Result.capture()` already exists in `lib/core/errors/result.dart` but is rarely used.
- **Acceptance criteria:**
  - Audit usage of `Result.capture()` across the codebase
  - Refactor 10+ representative methods to use `Result.capture(() async { ... }, context: 'methodName')`
  - Verify no regression in existing tests

### M11: `_lateNightHour = 22` duplicated across mentor sub-services

- **Files:**
  - `lib/features/mentor/services/mentor_context_builder.dart:22`
  - `lib/features/mentor/services/mentor_wellbeing_service.dart:14`
- **Rationale:** The constant `22` (10 PM) defining "late night" is duplicated. A policy change to 11 PM requires updating both files.
- **Acceptance criteria:**
  - Define `const int lateNightHour = 22` in `lib/core/constants/app_constants.dart` (or `timeouts.dart`)
  - Both files import and use the shared constant

### M12: Hardcoded English fallback strings instead of l10n

- **Files:**
  - `lib/core/utils/time_utils.dart:70,74` — `'Today'`, `'Yesterday'`
  - `lib/core/utils/time_utils.dart:64` — `'Unknown'`
  - `lib/features/mentor/services/mentor_service.dart:68` — `MentorKeywords.extractKeywordsByLocale['en']!`
- **Rationale:** These strings bypass the l10n system. Users in non-English locales see English text for relative dates.
- **Acceptance criteria:**
  - Replace with `l10n.today`, `l10n.yesterday`, `l10n.unknown` passed as parameters
  - OR: create a locale-aware wrapper in `core/utils/time_utils.dart` that accepts `AppLocalizations`

### M13: `EngagementScheduler` (455 lines) handles too many concerns

- **File:** `lib/core/services/engagement_scheduler.dart`
- **Rationale:** A single class handling: nudge generation (multiple types), mentor nudge delegation, lesson checking, weekly digest, nudge history, schedule management — plus raw `Hive.box()` access instead of `SettingsBox`.
- **Acceptance criteria:**
  - Split into: `NudgeGenerator`, `LessonReminderService`, `WeeklyDigestService`
  - Replace all `Hive.box(HiveBoxNames.settings)` with `SettingsService` calls
  - Each new class should have a single responsibility

### M14: `PlannerNotifier` (484 lines, 20+ public methods)

- **File:** `lib/features/planner/providers/planner_providers.dart:199-683`
- **Rationale:** Monolithic notifier mixing plan CRUD, roadmap management, scheduling, and adherence.
- **Acceptance criteria:**
  - Split into: `PlanNotifier`, `RoadmapNotifier`, `ScheduleNotifier`, `AdherenceNotifier`
  - Each notifier handles exactly one domain

### M15: `PracticeScreen` State class — 1255 lines

- **File:** `lib/features/practice/presentation/screens/practice_screen.dart`
- **Rationale:** The `_PracticeScreenState` class is 1255 lines with 20+ state variables and ~15 handler methods. `_launchWeakAreasForSubject` alone is 80 lines.
- **Acceptance criteria:**
  - Decompose into smaller focused widgets or use a dedicated controller/notifier
  - Extract `_launchWeakAreasForSubject`, `_loadActivity`, and similar into separate classes

### M16: Hardcoded question type strings instead of `QuestionType` enum

- **File:** `lib/features/ingestion/services/content_pipeline.dart:480-491`
- **Rationale:** `_defaultAllowedTypes` uses string literals (`'singleChoice'`, `'multiChoice'`) instead of `QuestionType.values`.
- **Acceptance criteria:**
  - Replace string literals with `QuestionType.singleChoice.name`, etc.
  - OR: define as `const [QuestionType.singleChoice, ...]`

### M17: Unused `dart:async` imports (11+ files)

- **Files (representative):**
  - `lib/features/practice/presentation/screens/exam_session_screen.dart:1`
  - `lib/features/lessons/presentation/lesson_detail_screen.dart:3`
  - `lib/features/lessons/services/lesson_service.dart:1`
  - `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart:1`
  - `lib/features/focus_mode/services/focus_practice_service.dart:1`
  - `lib/features/practice/services/exam_session_service.dart:1`
- **Rationale:** These files import `dart:async` but don't use `Future`, `Stream`, `StreamController`, `Timer`, or `Completer`.
- **Acceptance criteria:**
  - Remove unused `dart:async` imports from all files
  - Verify compilation

---

## MINOR (code quality / UX friction)

### m1: `HiveBoxNames.dbVersion` — unused constant

- **File:** `lib/core/data/hive_box_names.dart:40`
- **Rationale:** `static const String dbVersion = 'db_version'` is declared but never referenced.
- **Acceptance criteria:** Remove the constant.

### m2: `MasteryImprovementTracker` — unnecessarily public top-level class

- **File:** `lib/core/services/instrumentation_service.dart:13-78`
- **Rationale:** Only used by `InstrumentationService` within the same file. 66 lines taking up file-level namespace.
- **Acceptance criteria:** Make it a private class within `InstrumentationService` (prepend `_`).

### m3: `study_progress_provider.dart` — thin wrapper with 1 consumer

- **File:** `lib/core/providers/study_progress_provider.dart` (imported by 1 file: `features/practice/presentation/screens/practice_screen.dart`)
- **Rationale:** Meanwhile, `dashboard_providers.dart` and `mentor_providers.dart` define their own `StudyProgressTracker` instances with duplicate init logic. The abstraction is not shared.
- **Acceptance criteria:**
  - Either delete the file and inline in the sole consumer
  - OR: refactor to be the single shared provider across all features

### m4: `data.dart` barrel file imported by 1 file

- **File:** `lib/core/data/data.dart`
- **Rationale:** Per AGENTS.md: "Do not create barrel files unless they are imported by production code." This barrel re-exports 11 files but is only imported by `main.dart`.
- **Acceptance criteria:** Either remove it (import directly) or make it the canonical data barrel by adding commonly-imported names.

### m5: Providers defined inside service files

- **Files:**
  - `lib/core/services/voice_service.dart:237-239` — `voiceServiceProvider`
  - `lib/core/services/student_id_service.dart:67-79` — 3 providers
- **Rationale:** Mixes service definitions with provider definitions. AGENTS.md convention expects providers in `lib/core/providers/`.
- **Acceptance criteria:** Move provider definitions to `lib/core/providers/` files. Services should not know about Riverpod.

### m6: Duplicate `_masteryLevelLabel` methods

- **Files:**
  - `lib/core/services/study_progress_tracker.dart:327-335`
  - `lib/core/services/progress_export_service.dart:120-128`
- **Rationale:** Identical private methods mapping `MasteryLevel` enum to localized strings. `label_helpers.dart` already exists but doesn't contain this.
- **Acceptance criteria:** Extract to `lib/core/utils/label_helpers.dart` and call from both files.

### m7: `@visibleForTesting` without tests

- **File:** `lib/core/errors/handlers.dart:8,11,153`
- **Rationale:** `logError`, `convertToAppException` are marked `@visibleForTesting` but `test/core/errors/handlers_test.dart` does not test them.
- **Acceptance criteria:** Either add tests for these methods or remove `@visibleForTesting` and make them private.

### m8: Core repository/model tests in wrong location (feature-level instead of core-level)

- **Files:**
  - `lib/core/data/models/mastery_state_model.dart` → tested at `test/features/practice/data/models/mastery_state_model_test.dart`
  - `lib/core/data/models/question_mastery_state_model.dart` → tested at `test/features/practice/data/models/question_mastery_state_model_test.dart`
  - `lib/core/data/repositories/session_repository.dart` → tested at `test/features/sessions/data/repositories/session_repository_test.dart`
  - (7 more — see full list in audit report)
- **Rationale:** Per AGENTS.md, `lib/core/data/**/*.dart` should map to `test/core/data/**/*_test.dart`. These have actual test coverage but it's in the wrong subtree.
- **Acceptance criteria:** Add test stubs or redirect files in `test/core/data/...` that import and run the feature-level tests, OR move the test files.

### m9: Stale redirect test file

- **File:** `test/core/services/localization_service_test.dart` (4-line stub re-exporting moved test)
- **Rationale:** Leftover redirect from a file move. Should be deleted.
- **Acceptance criteria:** Delete the file.

### m10: Duplicate test file for `id_generator`

- **Files:**
  - `test/utils/id_generator_test.dart`
  - `test/core/utils/id_generator_test.dart`
- **Rationale:** Two identical test files for the same source file.
- **Acceptance criteria:** Delete `test/utils/id_generator_test.dart`.

### m11: Inline `AlertDialog` builders instead of `ConfirmDialog`

- **Files (representative):**
  - `lib/features/questions/presentation/question_bank_screen.dart:150-167,189-206`
  - `lib/features/practice/presentation/screens/practice_session_screen.dart:487-512`
  - `lib/features/sessions/presentation/session_tracker_screen.dart:557-647`
- **Rationale:** Each screen duplicates the same `AlertDialog(title: "Confirm", content: ..., actions: [TextButton, FilledButton])` pattern. `ConfirmDialog.show()` already exists in `lib/core/widgets/dialog_utils.dart` but is not used.
- **Acceptance criteria:** Replace inline confirmation dialogs with `ConfirmDialog.show(context, ...)`.

### m12: `Result.success([])` indistinguishable from failure for empty collections

- **Files (representative):** `lib/features/planner/services/planner_service.dart:397,418` and multiple other services
- **Rationale:** Returning `Result.success([])` when data is empty makes it impossible for callers to distinguish "no data (empty list)" from "error fetching data." Both result in `is SuccessResult` being true.
- **Acceptance criteria:**
  - Add `isEmpty` flag to `SuccessResult<List<T>>`
  - OR: return `Result<List<T>>` where `null` data means error and `[]` means empty success
  - OR: add a dedicated `EmptyResult` variant to the sealed class

---

## Appendix: Quick Reference by Severity

| Severity | Count | Key Files |
|---|---|---|
| **BLOCKER** | 13 | `app_providers.dart`, `mentor_providers.dart`, 3 mentor services (untested), `spaced_repetition_engine.dart`, `mentor_schedule_handler.dart`, `mentor_service.dart`, `content_pipeline.dart`, `practice_session_screen.dart`, `question_bank_screen.dart`, `conversation_memory.dart`, `planner_service.dart`, 3 files with `_getConsecutiveStudyDays`/`_getDailyCapMinutes`/`_deserializeSrData` |
| **MAJOR** | 17 | `cross_feature_integrator.dart`, `topic_readiness_service.dart`, `engagement_scheduler.dart`, `mentor_keywords.dart`, `difficulty_controller.dart`, `result.dart`, 1770+ `pumpAndSettle` calls, 428+ private fakes, `_lateNightHour` duplication, `time_utils.dart` hardcoded strings, `planner_providers.dart`, `practice_screen.dart`, `content_pipeline.dart`, 11+ `dart:async` imports |
| **MINOR** | 12 | `hive_box_names.dart`, `instrumentation_service.dart`, `study_progress_provider.dart`, `data.dart`, `voice_service.dart`, `student_id_service.dart`, `study_progress_tracker.dart`, `progress_export_service.dart`, `handlers.dart`, 10 core models/repos in wrong test location, `localization_service_test.dart`, duplicate `id_generator_test.dart`, `dialog_utils.dart` underuse, `Result.success([])` pattern |
| **TOTAL** | **42** | |

---

*This issue was generated by automated codebase exploration. Each finding includes context, affected files, rationale, and concrete acceptance criteria. To fix, address BLOCKER items first, then MAJOR, then MINOR.*
