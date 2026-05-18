# Code Refactor Master & Quality

> **Audit scope:** `lib/core/` (87 files), `lib/features/` (14 modules, ~150+ files), `test/` (entire test suite)
> **Audit date:** 2026-05-18
> **Total findings:** 38 (3 BLOCKER, 21 MAJOR, 14 MINOR)

---

## BLOCKER — App crashes or user cannot proceed

### B-1: `costByFeature` uses `const` map then mutates it — will not compile

| Field | Value |
|---|---|
| **File** | `lib/features/llm_tasks/services/llm_task_service.dart:46-52` |
| **Severity** | BLOCKER |

**Context:**
```dart
Map<String, double> get costByFeature {
  const cost = <String, double>{};   // compile-time constant — immutable
  for (final task in _manager.tasks) {
    cost[task.feature] = (cost[task.feature] ?? 0) + task.estimatedCost; // mutates const!
  }
  return cost;
}
```

**Rationale:** Assigning to `cost[key]` on a `const` collection is a compile-time error in Dart (`Cannot modify an unmodifiable collection`). This code literally cannot compile. Every consumer (analytics dashboard, cost display) gets an empty map. If this somehow made it past compilation, analytics are silently broken.

**AC:** Change `const cost` → `final cost`.

---

### B-2: `IdleExecutor.enqueue()` silently discards all tasks

| Field | Value |
|---|---|
| **File** | `lib/core/services/llm_agent/idle_executor.dart:49-55` |
| **Severity** | BLOCKER |

**Context:** `enqueue(String description, Future<void> Function() task)` accepts a closure but never stores it in `IdleTask` (which only has `id`, `description`, `createdAt`). `_executeTask` (line 87) only logs `"Executing idle task: ..."` and returns — never invokes the callback. Any caller calling `LlmAgent.enqueueBackgroundTask` believes their work is being executed, but it is silently lost.

**Rationale:** Background analytics, data sync, and maintenance tasks queued via this executor are all silently dropped. This is data loss.

**AC:** Add a `Future<void> Function()?` field to `IdleTask`, store the closure in `enqueue()`, and invoke it in `_executeTask()`.

---

### B-3: `PrerequisiteCheckService` returns `Result.success` on every failure

| Field | Value |
|---|---|
| **File** | `lib/core/services/prerequisite_check_service.dart:86-88` |
| **Severity** | BLOCKER |

**Context:**
```dart
} catch (e) {
  _logger.e('Failed to check prerequisites', e);
  return Result.success(const PrerequisiteCheckResult(isReady: true));
}
```

**Rationale:** When any exception occurs during prerequisite checking (Hive I/O failure, box not found, etc.), the method tells the caller `isReady: true` — the student can proceed. This actively misleads the UI, allowing students to attempt topics they may not be ready for, with no indication that the readiness check itself failed.

**AC:** Return `Result.failure(AppException('Prerequisite check failed: $e'))` instead. Let callers decide how to surface the error.

---

## MAJOR — Feature broken or misleading

### M-1: 21-parameter `updateSettings` god method + 14 duplicate wrappers

| Field | Value |
|---|---|
| **File** | `lib/core/providers/app_providers.dart:70-263` |
| **Severity** | MAJOR |

**Context:**
- `SettingsController.updateSettings()` accepts **21 named parameters** (every single user-configurable setting).
- Followed by **14 single-parameter wrapper methods** (`updateTheme`, `updateFontSize`, `updateModel`, `updateStudyReminders`, `updateBreakDuration`, etc.), each duplicating the same 8-line pattern:
  ```dart
  final result = await _repository.updateSettings(...);
  if (result.isFailure) { log; return; }
  final settings = await _repository.getSettings();
  if (settings.isSuccess) state = settings.data!;
  ```

**Rationale:** ~170 lines of near-identical boilerplate. Adding a new setting requires adding a parameter AND a new wrapper method. Violates both SRP and DRY.

**AC:** Replace with a single `applySettings(Map<String, dynamic> changes)` method that merges changes into the existing settings and saves. Eliminate all 14 wrapper methods.

---

### M-2: 102-line `_buildContextPrompt` violates SRP

| Field | Value |
|---|---|
| **File** | `lib/features/mentor/services/mentor_service.dart:155-256` |
| **Severity** | MAJOR |

**Context:** Single function builds an LLM context prompt by loading stats, weak topics, syllabus plans, roadmaps, pending actions, upcoming lessons, adherence deviations, today's study time, daily cap, consecutive days, and today's sessions — all inlined with 10+ responsibilities.

**Rationale:** If any data source changes signature, this function needs modification. Extremely hard to test (requires mocking every data source at once). Any exception in one data block kills the entire prompt.

**AC:** Extract each data-loading block into separate private methods (`_appendStats`, `_appendRoadmaps`, `_appendWeakTopics`, etc.) that append to a `StringBuffer`. Target ≤15 lines per method.

---

### M-3: 82-line `_checkWellbeingInner` mixes 5 nudge types

| Field | Value |
|---|---|
| **File** | `lib/features/mentor/services/mentor_service.dart:371-452` |
| **Severity** | MAJOR |

**Context:** Handles overwork nudges, late-night nudges, revision nudges, streak nudges, inactivity nudges, AND rate-limiting in one method.

**Rationale:** Hard to test individual nudge types. Changes to one nudge logic risk breaking others. Rate-limiting logic mixed with nudge generation makes both harder to reason about.

**AC:** Extract each nudge type into its own private method. Keep rate-limiting as a separate concern.

---

### M-4: `QuestionPdfGenerator` is a 152-line non-functional placeholder

| Field | Value |
|---|---|
| **File** | `lib/core/services/pdf_generator/question_pdf_generator.dart` |
| **Severity** | MAJOR |

**Context:** `generate()` calls `_generatePlaceholderPDF()` which returns a plain text string, not a PDF. Comment says "placeholder implementation — In production use dart_pdf package". But 152 lines of code give a false sense of capability. Real PDF generation happens in `progress_export_service.dart` using the real `pdf` package.

**Rationale:** Any caller gets back text, not a PDF. This is dead code that misleads developers into thinking PDF export is implemented.

**AC:** Either implement using the `pdf` package (matching `ProgressExportService`) or delete the file entirely.

---

### M-5: 118-line `_sendNudgeNotifications` — monolithic engagement logic

| Field | Value |
|---|---|
| **File** | `lib/core/services/engagement_scheduler.dart:153-271` |
| **Severity** | MAJOR |

**Context:** Single method handles overwork nudges, revision nudges, plan adjustment nudges, weak topics nudges, AND plan adherence checks. 5 near-identical `if (!isNotificationEnabled(X)) ... else { try { ... } catch }` blocks, 4+ levels of nesting.

**Rationale:** Test setup must mock all 5 paths. Adding one nudge type requires modifying this growing block. The repeated try/catch with identical error handling is ~50 lines of duplication.

**AC:** Extract each nudge type into its own method. Use early returns to flatten nesting.

---

### M-6: 134-line `_buildPlan` orchestrates 8+ steps

| Field | Value |
|---|---|
| **File** | `lib/core/services/personal_learning_plan_service.dart:95-229` |
| **Severity** | MAJOR |

**Context:** Does: init repos → load mastery → load dependencies → build recommendations → resolve syllabus → generate daily plans → link questions → generate summary → save plan. Uses raw `try/catch` (line 100) then `Result` (line 114) — inconsistent error handling within the same method.

**Rationale:** Any failure in early steps cancels everything. Impossible to unit test individual stages. Mixing `try/catch` with `Result` return types is confusing.

**AC:** Extract `_loadPlanData`, `_buildRecommendations`, `_generateDailyPlans`, `_savePlan`. Compose them in `_buildPlan` with `Result.capture` throughout.

---

### M-7: 121-line `_generateDailyPlans` — O(n×m) async calls inside loops

| Field | Value |
|---|---|
| **File** | `lib/core/services/personal_learning_plan_service.dart:584-705` |
| **Severity** | MAJOR |

**Context:** Outer `for` loop over 30 days, inner `while` distributing recommendations. Inside the inner loop: 4 async Hive calls per topic (`_getReadinessScore`, `_getReviewUrgency`, `_getTopicTitle`, `_getSubjectId`). 30 × 5 × 4 = 600 async calls.

**Rationale:** Performance degrades linearly with plan duration × topics-per-day. Each async call has Hive overhead.

**AC:** Batch-load all topic metadata upfront before entering loops.

---

### M-8: Circular dependency between `ActionExecutor` and `PlannerService`

| Field | Value |
|---|---|
| **Files** | `lib/features/planner/services/action_executor.dart:3,10` — imports and instantiates `PlannerService()` as default |
| | `lib/features/planner/services/planner_service.dart:23,41-44` — imports and lazily creates `ActionExecutor(actionPlanner: this)` |
| **Severity** | MAJOR |

**Context:** `ActionExecutor` creates `PlannerService()` as default. `PlannerService` lazily creates `ActionExecutor` passing `this`. The cycle is:
```
ActionExecutor → PlannerService (default) → ActionExecutor (lazy)
```
Runtime-safe only because `PlannerService` uses lazy init. If anything changes to eager init (e.g., constructor injection), stack overflow.

**Rationale:** Fragile design. Adding constructor injection to either side triggers infinite recursion. Both files import each other's module.

**AC:** Remove the default `PlannerService()` from `ActionExecutor`. Inject `ActionPlanner` (the interface) explicitly through the constructor. Never let `ActionExecutor` create its own dependency.

---

### M-9: Three competing error-handling patterns across codebase

| Field | Value |
|---|---|
| **Files** | See table below |
| **Severity** | MAJOR |

**Context:**

| Pattern | Files |
|---|---|
| `Result<T>` return (preferred) | Most repositories, `mastery_graph_service.dart` |
| Raw `throw AppException` | `settings_repository.dart:18-32`, `app_build_config.dart`, `security_config.dart`, `app_api_config.dart` |
| Silent `try/catch` swallow | `notification_service.dart`, `engagement_scheduler.dart`, `document_extractor.dart:85-87`, `upload_screen.dart:244-245` |
| Mixed in same file | `personal_learning_plan_service.dart` (line 100 `try/catch`, line 114 `Result`), `cross_feature_integrator.dart` (both patterns) |

**Rationale:** Callers never know which pattern to expect. Silent swallows cause undebuggable failures. Raw throws crash the app when uncaught. The `repository.dart` doc comment says "All repositories MUST wrap their return types in Result" but many services ignore this.

**AC:** Adopt `Result<T>` project-wide. Ban raw throws in services/repositories (enforce with custom lint). Replace all silent catch blocks with at minimum a debug log.

---

### M-10: `MasteryGraphService` holds duplicate repo references

| Field | Value |
|---|---|
| **File** | `lib/core/services/mastery_graph_service.dart:20-37` |
| **Severity** | MAJOR |

**Context:** Constructor accepts `masteryStateRepo`, `questionMasteryRepo`, `topicDependencyRepo`, `questionEvaluationRepo` and passes them to BOTH `_repository` (a `MasteryGraphRepository`) AND stores as direct fields. Same repo instances held in two places. Some methods delegate to local fields, others through `_repository`.

**Rationale:** If a repo is swapped via constructor but not in `_repository`, behavior silently diverges. Dead maintenance burden — changes to delegation strategy require touching both paths.

**AC:** Pick one strategy. Either keep `_repository` and route all calls through it, or keep direct fields and remove `_repository`.

---

### M-11: `@Deprecated` models still actively wired

| Field | Value |
|---|---|
| **File** | `lib/core/data/models/markscheme_model.dart:3,87` |
| **Severity** | MAJOR |

**Context:** `Markscheme` and `MarkSchemeStep` are annotated `@Deprecated('Use QuestionEvaluation instead (typeId 14)')`. Yet `question_model.dart:40` declares `Markscheme? markscheme` and `answer_validation_service.dart` imports and uses them extensively. The replacement types (`QuestionEvaluation`, `EvaluationStep`) exist but are never wired into the `Question` model or validation service.

**Rationale:** Half-finished refactor. 65 callers get deprecation warnings with no migration path. The replacement types are unused dead code (or vice versa).

**AC:** Either finish the migration (wire `QuestionEvaluation` into `Question` model, update `AnswerValidationService`) or remove the `@Deprecated` annotations.

---

### M-12: `DashboardProvider` creates duplicate service instances

| Field | Value |
|---|---|
| **File** | `lib/features/dashboard/providers/dashboard_providers.dart:1-36` |
| **Severity** | MAJOR |

**Context:** Dashboard creates its OWN `TopicRepository`, `AttemptRepository`, `SessionRepository`, `PlanAdherenceRepository` instead of reusing the shared providers (`sessionRepositoryProvider`, `topicRepositoryProvider`, etc.). This means dashboard gets different Hive box instances.

**Rationale:** Data inconsistency — if other features modify session data, dashboard sees stale/divergent state. Duplicate Hive box inits waste resources.

**AC:** Reuse existing feature providers. Dashboard should use `sessionRepositoryProvider`, `topicRepositoryProvider`, `attemptRepositoryProvider`, etc.

---

### M-13: Hardcoded model provider defaults across multiple files

| Field | Value |
|---|---|
| **Files** | `lib/features/settings/data/repositories/settings_repository.dart:86-88`, `lib/features/ingestion/providers/ingestion_providers.dart:15`, `lib/features/teaching/providers/teaching_providers.dart:11-16` |
| **Severity** | MAJOR |

**Context:** Multiple files hardcode `'openRouter'` as default provider, `'en'` as default locale, and default model strings. Should be environment-driven (env vars, platform channels, or a config file).

**Rationale:** Changing the default provider requires touching 3+ files. Environment-specific config (dev/staging/prod) is impossible without code changes.

**AC:** Create a single `AppConfig` class read from environment variables / platform channels. All defaults reference this single source.

---

### M-14: `MentorEngagementNudgeRepo` lives in `planner` but is consumed by `mentor`

| Field | Value |
|---|---|
| **File** | `lib/features/planner/data/repositories/engagement_nudge_repository.dart` |
| **Severity** | MAJOR |

**Context:** `EngagementNudgeRepository` is in `features/planner/data/repositories/` but consumed by `MentorService` in `features/mentor/`. Mentor depends on Planner's data layer.

**Rationale:** Cross-feature dependency. If planner restructures, mentor breaks. Violates feature isolation.

**AC:** Either move nudge-related models/repos to `core/data/` or extract into a shared `features/engagement/` module.

---

### M-15: `TaskModel` is in `planner` but used across modules

| Field | Value |
|---|---|
| **File** | `lib/features/planner/data/models/task_model.dart` |
| **Severity** | MAJOR |

**Context:** `TaskModel` represents a cross-cutting concern (task/todo items) potentially used by mentoring, sessions, and dashboard. Not exported from `planner.dart` package.

**Rationale:** If other features need task representation, they'll either duplicate the model or import planner internals.

**AC:** Move to `core/data/models/task_model.dart` and re-export from appropriate barrel files.

---

### M-16: SR data serialization duplicated verbatim in 2 files

| Field | Value |
|---|---|
| **Files** | `lib/features/practice/services/spaced_repetition_service.dart:156-183`, `lib/features/practice/services/mastery_recorder.dart:116-143` |
| **Severity** | MAJOR |

**Context:** `_deserializeSrData()` and `_serializeSrData()` are copied verbatim between `SpacedRepetitionService` and `MasteryRecorder`. ~56 lines of identical code.

**Rationale:** Bug fix or schema change in one copy won't be applied to the other. Already a maintenance risk.

**AC:** Extract to a shared utility class `SrDataCodec` in `lib/features/practice/utils/` or `lib/core/utils/`.

---

### M-17: `ConversationManager.sendMessage()` is 73 lines with 5+ concerns

| Field | Value |
|---|---|
| **File** | `lib/features/teaching/services/conversation_manager.dart:125-198` |
| **Severity** | MAJOR |

**Context:** Handles phase transitions (greeting/exercise/feedback/adaptive-review), evaluates exercises, builds adaptive chunks, detects keywords, and manages pending captures — all intertwined in one method.

**Rationale:** Phase transition logic mixed with response generation. Changing how a phase works risks breaking response streaming.

**AC:** Separate phase-transition logic from streaming response logic.

---

### M-18: 99-line `_handleExport` with 7 duplicated export cases

| Field | Value |
|---|---|
| **File** | `lib/features/sessions/presentation/session_history_screen.dart:96-195` |
| **Severity** | MAJOR |

**Context:** Switch statement with 7 export format cases, each duplicating mounted-check + snackbar pattern.

**Rationale:** Adding an export format means duplicating the entire pattern. Common post-export logic scattered across cases.

**AC:** Extract common post-export handler. Each case only specifies format-specific params.

---

### M-19: `settings_repository.dart:updateSettings()` has 30 positional parameters

| Field | Value |
|---|---|
| **File** | `lib/features/settings/data/repositories/settings_repository.dart:179-234` |
| **Severity** | MAJOR |

**Context:** `updateSettings()` takes 30 nullable positional parameters. Callers must count positions — error-prone and unmaintainable.

**Rationale:** Adding or removing a parameter changes the position of all subsequent params, silently breaking callers.

**AC:** Use a `SettingsUpdate` data class with named fields.

---

### M-20: `onboarding_service_test.dart` duplicated as `onboarding_store_test.dart`

| Field | Value |
|---|---|
| **Files** | `test/features/onboarding/services/onboarding_service_test.dart`, `test/features/onboarding/onboarding_store_test.dart` |
| **Severity** | MAJOR |

**Context:** Both files test the same `OnboardingService` with nearly identical test cases. `onboarding_store_test.dart` has no corresponding source file (`onboarding_store.dart` does not exist).

**Rationale:** Maintenance burden doubles. If a test needs updating, both files must change. The `_store` file is likely leftover from a refactoring.

**AC:** Delete `test/features/onboarding/onboarding_store_test.dart`. Ensure `onboarding_service_test.dart` has full coverage.

---

### M-21: Real Hive I/O in 30+ unit tests instead of fake boxes

| Field | Value |
|---|---|
| **Files** | 30+ test files in `test/features/*/`, `test/core/*/` (e.g., `planner_providers_test.dart`, `session_repository_test.dart`, `attempt_repository_test.dart`, etc.) |
| **Severity** | MAJOR |

**Context:** Many unit tests initialize real Hive databases with `Directory.systemTemp.createTemp()` and register real adapters. Per AGENTS.md convention, tests should use hand-written fake classes. The pattern for repository tests should use fake `Box<T>` implementations (as done in `badge_repository_test.dart`), not disk-backed Hive.

**Rationale:** Filesystem I/O slows tests. Cross-test state pollution if temp dirs collide. Fails if `/tmp` is full or permissions wrong. The AGENTS.md convention (`hand-written fake classes`) is being violated.

**AC:** For **repository tests**: use fake `Box<T>` implementations (e.g., `_FakeBadgeBox` pattern). For **provider/service tests**: inject fake repositories via Riverpod overrides. Reserve real Hive I/O for dedicated integration tests in `test/integration/`.

---

## MINOR — Code quality / UX friction

### m-1: `costByFeature` always returns empty map (also see B-1)

| Field | Value |
|---|---|
| **File** | `lib/features/llm_tasks/services/llm_task_service.dart:47-52` |
| **Severity** | MINOR (after B-1 is fixed) |

**AC:** Use `final cost` instead of `const cost`. Also consider using `Map.fromIterable` or `fold` for functional style.

---

### m-2: `SpacedRepetitionQueries` static class is dead code

| Field | Value |
|---|---|
| **File** | `lib/features/practice/services/spaced_repetition_service.dart:21-60` |
| **Severity** | MINOR |

**Context:** 40-line static class with methods requiring raw `Box<Question>` but never called anywhere in the codebase. Appears to be an incomplete refactoring attempt.

**AC:** Either remove or document intended use with a TODO.

---

### m-3: `LlmTaskService` is a thin delegate wrapper

| Field | Value |
|---|---|
| **File** | `lib/features/llm_tasks/services/llm_task_service.dart` (73 lines) |
| **Severity** | MINOR |

**Context:** Every method just delegates to `_manager` with zero transformation. Providers already access `llmTaskManagerProvider` directly.

**AC:** Consider removing the service and using the manager directly in providers.

---

### m-4: `PlanRepository.savePlan()` and `RoadmapRepository.saveRoadmap()` are one-line `create()` wrappers

| Files | `lib/features/planner/data/repositories/plan_repository.dart:15-17`, `lib/features/planner/data/repositories/roadmap_repository.dart:15-17` |
| **Severity** | MINOR |

**AC:** Remove the wrapper methods. Inline calls to `create()`.

---

### m-5: `OnboardingService.setTestStorage()` is test injection via static mutable state

| Field | Value |
|---|---|
| **File** | `lib/features/onboarding/services/onboarding_service.dart:9-14` |
| **Severity** | MINOR |

**Context:** Uses `static StorageBackend? _testStorage` for test injection. Tests must remember to reset — state leaks between tests.

**AC:** Use dependency injection (constructor-inject the storage backend) instead of static mutable state.

---

### m-6: `PlannerNotifier` has 370 lines of repeated try→call→catch→setError boilerplate

| Field | Value |
|---|---|
| **File** | `lib/features/planner/providers/planner_providers.dart:188-556` |
| **Severity** | MINOR |

**Context:** Every one of the 16+ methods follows: try → call service → load data → catch → log → set error.

**AC:** Extract a `_safeCall<T>(Future<T> Function() call)` helper that wraps the try/catch/log/set pattern.

---

### m-7: Error state widgets duplicated across screens

| Files | `lesson_detail_screen.dart`, `lesson_list_screen.dart`, `session_tracker_screen.dart`, `session_history_screen.dart`, and others |
| **Severity** | MINOR |

**Context:** Each screen defines its own `_buildErrorState()` with identical icon + message + retry pattern.

**AC:** Create a reusable `ErrorStateWidget` in `lib/core/widgets/`.

---

### m-8: Subject loading pattern duplicated across 4+ screens

| Files | `planner_screen.dart:74-87`, `focus_timer_screen.dart:124-136`, `upload_screen.dart:64-77`, `session_history_screen.dart` |
| **Severity** | MINOR |

**Context:** The pattern `SubjectRepository → init → getAll → setState` is repeated identically.

**AC:** Create a reusable `SubjectsLoader` widget or provider.

---

### m-9: `QuestionType` label switch duplicated

| Files | `lib/features/practice/services/question_type_localizer.dart:4-19`, `lib/features/ingestion/presentation/source_detail_screen.dart:591-614` |
| **Severity** | MINOR |

**Context:** Extension `questionTypeLabel` in `question_type_localizer.dart` provides the canonical mapping, but `source_detail_screen.dart` has its own standalone `_questionTypeLabel()` function.

**AC:** Use the extension everywhere, remove the standalone function.

---

### m-10: Misleading "Orphaned" comment in session providers

| Field | Value |
|---|---|
| **File** | `lib/features/sessions/providers/session_providers.dart:11-12` |
| **Severity** | MINOR |

**Context:** Comment says "Orphaned: consumed only in tests... Kept as future-use convenience providers" but the providers ARE referenced in the Focus Timer screen and other places.

**AC:** Update or remove the comment.

---

### m-11: Wrong log levels in `SpacedRepetitionService`

| Field | Value |
|---|---|
| **File** | `lib/features/practice/services/spaced_repetition_service.dart:143,171` |
| **Severity** | MINOR |

**Context:** Line 143 uses `.w()` for serialization error (should be `.e()`). Line 171 uses `.e()` for caught auto-save exception (should be `.w()` since it's handled).

**AC:** `.e()` for unrecoverable errors, `.w()` for handled/caught exceptions.

---

### m-12: Hardcoded defaults in planner and focus timer

| Files | `lib/features/planner/services/planner_service.dart:112,139` (targetQuestionsPerDay: 15), `lib/features/focus_mode/presentation/focus_timer_screen.dart:46` (breakDuration: 300) |
| **Severity** | MINOR |

**AC:** Make configurable via user preferences. Show loading state in focus timer until settings are loaded.

---

### m-13: `ConversationMemory._trimRepository` is `void async` — fire-and-forget

| Field | Value |
|---|---|
| **File** | `lib/core/services/conversation_memory.dart:15-27` |
| **Severity** | MINOR |

**Context:** `void _trimRepository() async { ... await ... }` — async void means errors are unhandled futures and caller cannot await completion.

**AC:** Change return type to `Future<void>` and `await` at the call site.

---

### m-14: `EngagementSchedulerConfig` hardcodes `studentId = 'default'`

| Field | Value |
|---|---|
| **File** | `lib/core/services/engagement_scheduler.dart:25` |
| **Severity** | MINOR |

**Context:** When created without explicit config, `studentId` defaults to `'default'` which never matches any real student. `engagementSchedulerProvider` uses this default, meaning all scheduled nudges operate on wrong/no data.

**AC:** Make `studentId` a required parameter or inject from `StudentIdService`.

---

## Summary

| Severity | Count | Key areas |
|---|---|---|
| **BLOCKER** | 3 | Compilation error (B-1), silent task loss (B-2), masked prerequisite failures (B-3) |
| **MAJOR** | 21 | God methods, circular deps, inconsistent error handling, dead code, missing/fragile tests, file placement violations |
| **MINOR** | 14 | Dead code, duplicate patterns, wrong log levels, hardcoded defaults, misleading comments |
| **Total** | **38** | |

## Suggested triage order

1. **B-1** (compilation error — app won't build)
2. **B-3** (masked failures — students misled)
3. **B-2** (background tasks silently lost)
4. **M-8** (circular dependency — future stack overflow risk)
5. **M-9** (inconsistent error handling — crash risk)
6. **M-12** (duplicate service instances — data inconsistency)
7. **Remaining M** items
8. **Remaining m** items
