# Code Refactoring & Quality Audit

**Audit scope**: `lib/` (all Dart source files), `pubspec.yaml`  
**Audit date**: 2026-05-17  
**Severity legend**: 🔴 BLOCKER — ⚠️ MAJOR — 🟡 MINOR

---

## 🔴 BLOCKER

### B1. Direct circular dependency: `sessions` ↔ `planner`

**Context**: `sessions` imports `planner` repositories while `planner` imports `sessions` repositories, forming a hard cycle.

| Direction | File | Imports |
|---|---|---|
| `sessions` → `planner` | `lib/features/sessions/presentation/session_tracker_screen.dart` | `planner/data/repositories/plan_adherence_repository.dart`, `planner/data/repositories/plan_repository.dart` |
| `planner` → `sessions` | `lib/features/planner/services/planner_service.dart` | `sessions/data/repositories/session_repository.dart` |

**Rationale**: This is a true circular dependency. At runtime, Dart's lazy initialization prevents an immediate crash, but the modules cannot be independently tested, extracted, or reasoned about. Any change to `planner`'s repository API requires coordinated changes in `sessions` and vice versa.

**Acceptance criteria**:
- Extract the shared session/plan query concern (e.g. `getSessionsForPlan`, `getPlanAdherenceForSession`) into a new service in `lib/core/services/` that both `sessions` and `planner` depend on.
- After extraction, run `rg 'package:studyking/features/(sessions|planner)/' lib/features/(planner|sessions)/` and confirm zero cross-imports between the two features.

---

## ⚠️ MAJOR

### M1. Transitive cycles: practice ↔ sessions ↔ planner ↔ practice

**Context**: Beyond the direct cycle, there are transitive cycles involving `practice`:

```
practice → sessions → planner → practice
practice → subjects → sessions → planner → practice
```

**Affected files** (not exhaustive):
- `lib/features/practice/services/practice_session_service.dart` (imports `sessions`)
- `lib/features/sessions/presentation/session_tracker_screen.dart` (imports `planner`)
- `lib/features/planner/services/planner_service.dart` (imports `practice`)
- `lib/features/subjects/presentation/subject_detail_screen.dart` (imports `sessions`)

**Rationale**: These cycles prevent clean feature isolation and make module extraction impossible without breaking the graph.

**Acceptance criteria**:
- Same as B1 — after extracting the shared concern, re-verify the full dependency graph with `rg` to confirm no cycles remain among `practice`, `sessions`, `planner`, and `subjects`.

---

### M2. Core layer imports from features (20 files violate layering)

**Context**: Files under `lib/core/` import from `lib/features/`, violating the principle that core should be a foundation layer with no knowledge of features.

**Worst offenders**:

| Core file | What it imports from features |
|---|---|
| `lib/core/data/hive_initializer.dart` | `questions/data/questions_data.dart`, `practice/data/practice_data.dart`, `planner/data/planner_data.dart`, `subjects/data/subjects_data.dart`, `teaching/data/teaching_data.dart`, `sessions/services/session_migration_service.dart` |
| `lib/core/routes/app_router.dart` | Screens from **13 of 15 features** |
| `lib/core/providers/app_providers.dart` | `lesson_repository_provider`, `practiceProviders`, `questionProviders`, `sessionProviders`, `settingsRepositoryProvider`, `subjectProviders`, `teachingProviders` |
| `lib/core/services/personal_learning_plan_service.dart` | `planner`, `practice`, `questions`, `subjects` repositories/models |

**Rationale**: Core should not depend on features. `app_router.dart` is pragmatically justified (routing must reference screens), but `hive_initializer.dart`, `app_providers.dart`, and the core services pulling feature repositories directly violate the architecture. Feature-specific initialisation and providers should live in feature barrel files, not in core.

**Acceptance criteria**:
- `hive_initializer.dart`: Move feature adapter registration into each feature's own `data/` barrel (e.g. `questions/data/questions_data.dart` registers its own adapters). Core should only call a generic `FeatureRegistry.registerAll()` or similar.
- `app_providers.dart`: Remove feature-provider imports from core. Feature providers should be self-contained.
- `core/services/*` that import feature repositories: Extract the cross-cutting logic into core-level interfaces/abstractions, or move the service into the feature layer.

---

### M3. LLM services (`llm_chat_service.dart`, `llm_embeddings_service.dart`) throw raw `Exception` instead of using `Result<T>`

**Context**: Every other core service and all repositories return `Result<T>` for recoverable errors. The LLM services are the only core services that throw raw `Exception(...)`.

**Affected throw sites**:

| File | Line | Statement |
|---|---|---|
| `lib/core/services/llm/llm_chat_service.dart` | 170 | `throw Exception('OpenRouter API Error: ...')` |
| `lib/core/services/llm/llm_chat_service.dart` | 283 | `throw Exception('Ollama API Error: ...')` |
| `lib/core/services/llm/llm_chat_service.dart` | 382 | `throw Exception('OpenAI API Error: ...')` |
| `lib/core/services/llm/llm_embeddings_service.dart` | 71 | `throw Exception('Embedding API Error: ...')` |

**Rationale**: Callers must handle both thrown exceptions (from LLM methods) and `Result` failures (from everything else), creating an inconsistent error-handling surface. This has already caused issues — see `export_section.dart:183` where a `Result.failure` is explicitly converted back to `throw Exception(...)`.

**Acceptance criteria**:
- Change all four `throw Exception(...)` sites to `return Result.failure(...)`.
- Update all callers of `LlmService` methods to handle `Result<String>` instead of `String`.
- Remove the `throw Exception(result.error)` workaround in `lib/features/dashboard/presentation/widgets/export_section.dart:183`.

---

### M4. Provider silent error swallowing (especially `planner_providers.dart` — 18 empty catch blocks)

**Context**: Providers swallow errors with empty `catch (_) {}` blocks, making failures invisible.

| File | Count of `catch (_)` with empty body |
|---|---|
| `lib/features/planner/providers/planner_providers.dart` | 18 |
| `lib/features/planner/services/planner_service.dart` | 6 |
| `lib/core/services/personal_learning_plan_service.dart` | 9 |
| `lib/core/providers/app_providers.dart` | 8 (logs but never propagates) |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | 2 |

**Rationale**: Silent error swallowing is the #1 cause of "it just doesn't work" bugs that are impossible to debug. The 18 empty catches in `planner_providers.dart` alone make the planner feature effectively untestable for error states.

**Acceptance criteria**:
- Every `catch` block must either (a) log the error via `_logger.e(...)`, (b) set an error state in the provider for the UI to display, or (c) both. Zero empty catch bodies.
- In `planner_providers.dart`, add a `String? errorMessage` field to `PlannerState` and populate it on failure.
- After changes, run the existing planner provider tests and confirm no regressions.

---

### M5. `StudyTimerService` throws `StateError` instead of returning `Result<Session>`

**Context**: `lib/features/sessions/services/study_timer_service.dart:131,158` throws `StateError('No active session')` when completing or cancelling a session without an active session. Every other feature service returns `Result<T>`.

**Rationale**: Inconsistent with the codebase convention. Forces callers to wrap calls in try/catch instead of checking `.isFailure`.

**Acceptance criteria**:
- Change `completeSession()` and `cancelSession()` return types to `Result<Session>`.
- Return `Result.failure('No active session')` instead of throwing `StateError`.
- Update callers to handle the `Result` return value.
- Run `test/features/sessions/services/study_timer_service_test.dart` to confirm.

---

### M6. `progress_export_service.dart:exportComprehensivePDF()` — 190-line monolithic method

**Context**: `lib/core/services/progress_export_service.dart:121` is a 190-line method that builds an entire PDF document (MultiPage, tables, headers, charts) in a single function.

**Rationale**: Violates single-responsibility principle. Impossible to test individual sections. Any change to one section risks breaking the entire PDF layout.

**Acceptance criteria**:
- Extract each PDF section (summary table, topic breakdown, adherence chart, recommendations, etc.) into separate private methods or small builder classes.
- Each builder should accept the data it needs and return a single `Widget` (the pdf package's `Widget`).
- After refactoring, run `test/core/services/progress_export_service_test.dart` and visually verify a generated PDF.

---

### M7. Notification channel IDs hardcoded inline in `notification_service.dart`

**Context**: `lib/core/services/notification_service.dart` has 8 hardcoded notification channel ID strings. The centralized `notificationChannelId = 'study_reminders'` in `lib/core/constants/app_runtime_config.dart:9` is never used.

**Hardcoded IDs**:
| Method | Channel ID |
|---|---|
| `showNotification()` | `'studyking_general'` |
| `showDailyReminder()` | `'studyking_daily_reminder'` |
| `showRevisionNudge()` | `'studyking_revision'` |
| `showOverworkWarning()` | `'studyking_wellbeing'` |
| `showPlanAdjustmentSuggestion()` | `'studyking_planning'` |
| `showLessonReminder()` | `'studyking_lessons'` |
| `showLowMasteryWarning()` | `'studyking_mastery'` |
| `showBadgeUnlocked()` | `'studyking_badges'` |

**Rationale**: Hardcoded strings cannot be changed without editing source code. They should be constants in a config class, making them testable and environment-configurable. Also, `app_runtime_config.dart` already defines `notificationChannelId = 'study_reminders'` but nothing uses it — either remove it or migrate to it.

**Acceptance criteria**:
- Define a `NotificationChannelIds` class in `lib/core/constants/` with static const strings for each channel.
- Update `notification_service.dart` to reference these constants instead of inline strings.
- Remove or repurpose the unused `UiConfig.notificationChannelId` in `app_runtime_config.dart`.
- Run `test/core/services/notification_service_test.dart` (checking it exists/passes).

---

## 🟡 MINOR

### m1. Dead code: Entire `PdfIngestionService` and `PdfIngestionException` are `@Deprecated` with zero callers

**Context**: `lib/core/services/pdf_ingestion_service.dart` — The whole file is deprecated and not imported anywhere in `lib/`.

```
rg 'pdf_ingestion_service' lib/  →  no results
```

**Rationale**: Dead code that still compiles, still carries a maintenance burden, and may confuse developers who find it.

**Acceptance criteria**:
- Remove `lib/core/services/pdf_ingestion_service.dart`.
- Remove any barrel-export references (check `lib/core/services/` barrel files).
- Run `flutter analyze` to confirm no breakage.

---

### m2. Dead code: `AppException` hierarchy (18 subclasses) defined but never thrown

**Context**: `lib/core/errors/exceptions.dart` defines 18 `AppException` subclasses (`NetworkException`, `DatabaseException`, `PdfParseException`, `LlmException`, etc.). Zero of these are ever thrown with `throw` in `lib/`. The only consumer is `AppErrorHandler.convertToAppException()` in `handlers.dart` which uses string matching on `error.toString()` to retroactively classify unknown exceptions.

**Rationale**: The entire hierarchy is dead code if nothing ever throws these types. The `convertToAppException` string-matching approach is fragile and should either be removed or the subclasses should actually be thrown (e.g., catch Dio errors and rethrow as `NetworkException`).

**Acceptance criteria**:
- **Option A (preferred)**: Remove all unused `AppException` subclasses and simplify `handlers.dart` to work directly on exception messages.
- **Option B**: Start throwing the appropriate `AppException` in the Dio interceptors, repository catch blocks, and LLM service error paths. Remove the string-matching fallback in `convertToAppException`.
- After changes, run `test/core/errors/exceptions_test.dart` and `test/core/errors/handlers_test.dart`.

---

### m3. Redundant provider: `apiKeyValueProvider`

**Context**: `lib/core/providers/llm_providers.dart:32-34`:

```dart
final apiKeyValueProvider = Provider<String>((ref) {
  return ref.watch(apiKeyProvider);
});
```

This is a pure pass-through that adds zero logic. Every consumer could just read `apiKeyProvider` directly.

**Rationale**: Unnecessary indirection makes the provider graph harder to trace.

**Acceptance criteria**:
- Remove `apiKeyValueProvider`.
- Update all `ref.watch(apiKeyValueProvider)` calls to `ref.watch(apiKeyProvider)` (search with `rg 'apiKeyValueProvider' lib/`).
- Run `test/core/providers/llm_providers_test.dart`.

---

### m4. Unused dependencies in `pubspec.yaml`

**Context**: Three declared dependencies are never imported in `lib/`:

| Package | Evidence |
|---|---|
| `provider: ^6.1.1` | `rg 'package:provider' lib/` → no results |
| `vector_math: ^2.2.0` | `rg 'package:vector_math' lib/` → no results |
| `cupertino_icons: ^1.0.8` | `rg 'package:cupertino_icons' lib/` → no results |

**Rationale**: Unused dependencies increase `flutter pub get` time, risk version conflicts, and bloat the bundle (for `cupertino_icons` which includes assets).

**Acceptance criteria**:
- Remove all three from `pubspec.yaml` under `dependencies:`.
- Run `flutter pub get` and `flutter analyze` to confirm no breakage.

---

### m5. Repeated `const Duration(...)` values scattered across features

**Context**: At least 34 inline Duration literals exist across `lib/features/`. Common repeated values:

| Value | Occurrences | Example files |
|---|---|---|
| `const Duration(seconds: 1)` | 10+ | mentor, practice, sessions |
| `const Duration(milliseconds: 100)` | 5+ | animation controllers |
| `const Duration(milliseconds: 500)` | 2 | focus_mode, planner |
| `const Duration(hours: 1)` | 3 | mentor_service, spaced_repetition |
| `const Duration(minutes: 5)` | 2 | spaced_repetition |
| `const Duration(days: 7)` | 4 | dashboard, planner, mastery |

**Rationale**: Inline literals cannot be changed globally. If the 7-day window needs to become 14, each site must be found and changed individually.

**Acceptance criteria**:
- Add a `class Timeouts` or `class DurationDefaults` in `lib/core/constants/app_constants.dart` with named constants for each common duration.
- Replace all matching inline literals with the named constant.
- Do NOT extract feature-specific durations (e.g. focus timer duration is a user setting, not a constant).

---

### m6. Repository `init()` methods rethrow while data methods return `Result.failure` — inconsistent contract

**Context**: Every repository follows this pattern:

```dart
// init() — rethrows
Future<void> init() async {
  try { await openBox(name); } catch (e) { _logger.e(...); rethrow; }
}

// data methods — return Result.failure
Future<Result<T>> get() async {
  try { ...; return Result.success(data); } catch (e) { return Result.failure(...); }
}
```

**Affected repositories**: `lesson_repository.dart`, `question_repository.dart`, `mastery_state_repository.dart`, `topic_dependency_repository.dart`, `question_evaluation_repository.dart`, `spaced_repetition_repository.dart`, `mastery_graph_repository.dart`.

**Rationale**: Callers must handle two different error pathways from the same class. A typical usage pattern is:
```dart
await repo.init();             // ← can throw
final result = await repo.get(); // ← returns Result
```

**Acceptance criteria**:
- Change `init()` to return `Result<void>` instead of throwing: `return Result.failure('Failed to init repo: ...')`.
- Update all callers to `await repo.init().isFailure` instead of wrapping in try/catch.
- Alternative: make `init()` idempotent and auto-called by data methods so callers don't need to call it.

---

### m7. `cross_feature_integrator.dart` silently discards Result error messages

**Context**: `lib/core/services/cross_feature_integrator.dart` — multiple methods call repository methods, check `result.isFailure`, and return default values without logging `result.error`.

```dart
if (result.isFailure || result.data == null) return {};
// result.error is silently discarded
```

**Rationale**: When the integrator silently returns defaults, downstream features receive empty data and the original failure is invisible. A master graph failure could be mistaken for "no data yet."

**Acceptance criteria**:
- Add `_logger.e('cross_feature_integrator: ...', result.error)` before returning defaults.
- Ensure `cross_feature_integrator_test.dart` covers this logging behavior.

---

### m8. Lying/wrong log levels in configuration guard throws

**Context**: `lib/core/constants/app_api_config.dart:20,37` and `app_build_config.dart:31,41,44,47` and `security_config.dart:24,40,43,50,68` all throw `StateError` with static messages. These are config validation errors, not state errors per se.

**Rationale**: `StateError` implies an illegal runtime state. These are configuration/environment errors. Using a more specific type (or at minimum `ArgumentError` or a custom `ConfigException`) would make stack traces more informative.

**Acceptance criteria**:
- Replace `throw StateError(...)` in config files with either:
  - `throw ArgumentError(...)` if the mistake is in the caller's arguments, or
  - A new `ConfigException` (or throw the existing `ApiKeyMissingException` from `exceptions.dart` if relevant).
- Update `handlers.dart` to handle the new exception types if needed.

---

### m9. Unused Hive typeId 25 collision (latent)

**Context**: `lib/core/data/hive_type_ids.dart:27` defines `_typeIdMarkschemeLegacy = 25`, but no adapter is registered for it. Meanwhile, `lib/features/planner/data/models/roadmap_model.dart:108` uses `@HiveType(typeId: 25)` for `MilestoneModel`. If both adapters were registered, Hive would throw a typeId collision.

**Rationale**: Currently safe (no adapter for `MarkschemeLegacy`). But if anyone adds one in the future, it will conflict with `MilestoneModel`. Remove the dead constant or reclaim the ID.

**Acceptance criteria**:
- Remove `_typeIdMarkschemeLegacy = 25` from `hive_type_ids.dart`.
- Remove it from `_allTypeIds` list as well.
- Reassign it to `_typeIdPlanAdherenceModel` (currently 33, which is fine) to close the gap, or leave a comment that ID 25 is claimed by `MilestoneModel`.
- Run `hive_type_ids_test.dart` to confirm `validateHiveTypeIds()` passes.

---

### m10. `planner_service.dart` constructor has 29 parameters — violates single-responsibility principle

**Context**: `lib/features/planner/services/planner_service.dart:41` accepts 29 positional parameters (8+ repositories + config). This is a "Service God Object" that orchestrates plan loading, roadmap loading, pending actions, adherence checking, scheduling, and lesson management.

**Rationale**: A class with 29 constructor parameters cannot be reasoned about, tested easily, or reused partially. It most likely does too many things.

**Acceptance criteria**:
- Split `PlannerService` into smaller, focused services: `PlanLoaderService`, `SchedulingService`, `AdherenceService`, `ActionExecutor` (which already exists as a separate file).
- Each new service should have ≤5 constructor parameters.
- After extraction, update consumers (especially `planner_providers.dart` and `mentor_service.dart`).
- Run `test/features/planner/services/planner_service_test.dart`.

---

### m11. `personal_learning_plan_service.dart` is a 877-line God class

**Context**: `lib/core/services/personal_learning_plan_service.dart` has 877 lines, 38 methods, and accepts 10 constructor parameters. It handles plan generation, syllabus resolution, adherence calculation, and daily plan generation.

**Rationale**: Same as m10 — violates single-responsibility principle.

**Acceptance criteria**:
- Split into `PlanGeneratorService`, `PlanAdherenceService`, `DailyPlanService`.
- Each new service should have ≤5 constructor parameters.
- Run `test/core/services/personal_learning_plan_service_test.dart`.

---

### m12. `planner_screen.dart` has 756 lines, 53 methods, 278 deeply-nested lines

**Context**: `lib/features/planner/presentation/planner_screen.dart` is the largest screen file with 756 lines, 53 methods in `_PlannerScreenState`, and 278 lines indented ≥14 spaces (7+ nesting levels).

**Rationale**: A single state class managing 3 tabs + plan loading + scheduling + adherence is too large. It's impossible to unit test the state logic separately from widget rendering.

**Acceptance criteria**:
- Extract each tab (Study Plan, Roadmap, Pending Actions) into its own screen or widget file in `planner/presentation/tabs/`.
- Move non-UI orchestration (data loading, caching) into the `PlannerService` (or the new split services from m10).
- After extraction, each widget file should be <300 lines.
- Run `test/features/planner/presentation/planner_screen_test.dart` and existing widget tests.

---

### m13. `math_expression_widget.dart:_parseExpression()` — 28-branch if-else chain

**Context**: `lib/features/questions/presentation/widgets/math_expression_widget.dart:74` — `_parseExpression()` method contains a 256-line `while` loop with ~28 `if/else if` branches for LaTeX symbol parsing.

**Rationale**: Extremely high cyclomatic complexity. Adding a new symbol type requires modifying the chain. Cannot be tested exhaustively.

**Acceptance criteria**:
- Replace the if-else chain with a `Map<String, MathTokenBuilder>` lookup (command pattern).
- Each token type gets its own builder class/function.
- Ensure the existing `test/features/questions/presentation/widgets/math_expression_widget_test.dart` covers all 28 branches.

---

### m14. Hardcoded YouTube transcript URLs in `transcription_extractor.dart`

**Context**: `lib/core/data/extraction/transcription_extractor.dart:185-186,232-237` contains hardcoded URLs and User-Agent strings:

```dart
'https://youtubetranscript.com/?v=$videoId'
'https://youtubetranscript.com/api/transcript/$videoId'
'User-Agent': 'Mozilla/5.0 (compatible; StudyKing/1.0)'
```

**Rationale**: These should be in `app_api_config.dart` alongside the existing `youtubeBaseUrl` constant. Hardcoded service URLs cannot be mocked in tests without intercepting HTTP.

**Acceptance criteria**:
- Move `youtubetranscript.com` base URL to `ApiConfig` (or a new `ExtractionConfig`).
- Move User-Agent string to a constant.
- Update `transcription_extractor.dart` to reference the config.
- Run `test/core/data/extraction/transcription_extractor_test.dart`.

---

### m15. Hardcoded fallback URLs in `llm_embeddings_service.dart` duplicate `ApiConfig` constants

**Context**: `lib/core/services/llm/llm_embeddings_service.dart:23,26,29` defines:
```dart
const _openRouterBase = 'https://openrouter.ai/api/v1';     // duplicates ApiConfig.openRouterBaseUrlString
const _ollamaBase = 'http://localhost:11434';                // duplicates ApiConfig.ollamaDefaultUrl
const _openAIBase = 'https://api.openai.com/v1';             // duplicates ApiConfig.openAIDefaultUrl
```

**Rationale**: Duplicate constants. If the base URL changes, it must be updated in two places.

**Acceptance criteria**:
- Remove the three `_*Base` constants from `llm_embeddings_service.dart`.
- Reference `ApiConfig.openRouterBaseUrlString`, `ApiConfig.ollamaDefaultUrl`, and `ApiConfig.openAIDefaultUrl` instead.
- Run `test/core/services/llm_embeddings_service_test.dart`.

---

### m16. `planner_providers.dart` `PlannerNotifier` mixes data-loading orchestration with state management (48 methods across 4 classes)

**Context**: `lib/features/planner/providers/planner_providers.dart` contains 48 methods across 4 classes. `PlannerNotifier` itself handles loading plans, roadmaps, pending actions, lessons, adherence — it's an orchestrator, not a state holder.

**Rationale**: Riverpod `Notifier` classes should be thin state holders that delegate to services. The `PlannerNotifier` contains business logic that should be in services.

**Acceptance criteria**:
- Move data-loading logic out of `PlannerNotifier` into `PlannerService` (or the split services from m10).
- `PlannerNotifier` should only call service methods and update state.
- Run `test/features/planner/providers/planner_providers_test.dart`.

---

### m17. `provider` (legacy) package used alongside Riverpod — dual state management

**Context**: `pubspec.yaml` declares both `flutter_riverpod: ^2.4.11` and `provider: ^6.1.1`. Riverpod is used throughout the codebase via `flutter_riverpod`, while `provider: ^6.1.1` is never imported in `lib/`.

**Rationale**: Actual usage is exclusively Riverpod. The `provider` dependency is unused. Removing it eliminates confusion about which state management to use.

**Acceptance criteria**:
- Remove `provider: ^6.1.1` from `pubspec.yaml`.
- Run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` (if needed).
- Run the full test suite to confirm.

---

### m18. `engagement_scheduler.dart` multi-student design is unused

**Context**: `lib/core/services/engagement_scheduler.dart:14-32` — `EngagementSchedulerConfig` accepts a `List<String> studentIds` defaulting to `['default']`, but the scheduler is never called with more than one student ID. The plumbing for multi-student iteration exists but is dead.

**Rationale**: Adds complexity (list iteration, for-each loops) for a never-used feature.

**Acceptance criteria**:
- Simplify `EngagementSchedulerConfig` to take a single `String studentId` instead of `List<String>`.
- Update internal iteration to work on a single ID.
- Run `test/core/services/engagement_scheduler_test.dart`.

---

### m19. Config files (`app_api_config.dart`, `app_runtime_config.dart`) mix concerns with formatting/UI constants

**Context**: `lib/core/constants/app_runtime_config.dart` defines `bottomSheetShape` — a `RoundedRectangleBorder` widget constant — alongside `CacheConfig` and `UiConfig`. This is a UI constant in a config file.

**Rationale**: Misplaced. `bottomSheetShape` belongs in the theme files (`lib/core/theme/`), not in config.

**Acceptance criteria**:
- Move `bottomSheetShape` to `lib/core/theme/app_theme.dart`.
- Update all imports from `app_runtime_config.dart` to `app_theme.dart`.
- Run `flutter analyze` to confirm.

---

### m20. Dead Hive typeId `_typeIdTopicProgressModel = 1` with no adapter registration

**Context**: `lib/core/data/hive_type_ids.dart:4` defines `_typeIdTopicProgressModel = 1`, but `lib/core/data/hive_initializer.dart` never registers a `TypeAdapter<TopicProgressModel>`. The model class `TopicProgressModel` itself is `@Deprecated` at `lib/features/subjects/data/models/topic_progress_model.dart:3`.

**Rationale**: The typeId reservation is a fossil from the old `ProgressRepository` that has been superseded by `MasteryState`.

**Acceptance criteria**:
- Remove `_typeIdTopicProgressModel = 1` from `hive_type_ids.dart`.
- Verify `validateHiveTypeIds()` still passes.
- Remove `topic_progress_model.dart` and `progress_repository.dart` if they are `@Deprecated` with zero callers.
