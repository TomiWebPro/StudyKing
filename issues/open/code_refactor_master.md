# Code Quality & Refactoring Master Issue

**Generated:** 2026-05-18
**Scope:** Entire `lib/` tree — dead code, circular deps, error handling, provider wiring, complexity, hardcoded values, test gaps

---

## BLOCKER — App crashes or user cannot proceed

### B1. Duplicate `sessionRepositoryProvider` — two competing declarations

| Severity | BLOCKER |
|----------|---------|
| **Files** | `lib/features/sessions/providers/session_providers.dart:6`<br>`lib/features/lessons/providers/lesson_providers.dart:12` |
| **Rationale** | `sessionRepositoryProvider` is declared in **two separate files** with **different implementations**:<br><br>**sessions** version creates a bare `SessionRepository()` (no database integration).<br>**lessons** version delegates to `ref.watch(databaseProvider).sessionRepository` (shared via `DatabaseService`).<br><br>The `lessons` barrel (`lib/features/lessons/lessons.dart:7`) uses `hide sessionRepositoryProvider`, but files that import `lesson_providers.dart` **directly** — `lesson_list_screen.dart:11`, `lesson_detail_screen.dart:11` — bypass the barrel. Consumers are split across these two instances: `practice_providers.dart`, `focus_mode_providers.dart`, `dashboard_data_providers.dart` use the bare version; lesson screens use the database-shared version.<br><br>If `SessionRepository` holds any mutable state or cache, these instances **will diverge**, causing inconsistent session data across features. |
| **Acceptance criteria** | 1. Eliminate one declaration.<br>2. All consumers pick up the same `SessionRepository` instance.<br>3. Widget tests verify that overriding `sessionRepositoryProvider` in a `ProviderScope` propagates to both `LessonListScreen` and `PracticeScreen`. |

### B2. `engagementSchedulerProvider` hard-codes all dependencies (untestable)

| Severity | BLOCKER (for testability) |
|----------|---------------------------|
| **File** | `lib/core/providers/app_providers.dart:295-313` |
| **Rationale** | The provider creates **every dependency inline** using `new` constructors — `StudyProgressTracker`, `MasteryGraphService`, `EngagementNudgeRepository`, `PlanAdherenceRepository`, `PlanAdapter`, `SessionRepository`, `PlannerService` — instead of reading them from existing Riverpod providers. This means:<br><br>1. **No override possible** in widget tests (`ProviderScope(overrides: [...])` has no effect on the inner `new` calls).<br>2. **Duplicate instances** — `MasteryGraphService()` is created twice (lines 299, 302); `PlanAdapter` on line 305 ignores `planAdapterProvider` defined just 14 lines above (line 291).<br>3. Violates AGENTS.md convention requiring override-based stubbing. |
| **Acceptance criteria** | 1. `engagementSchedulerProvider` reads every dependency from its own provider (e.g. `ref.watch(masteryGraphServiceProvider)`).<br>2. A widget test overrides exactly one inner dependency and proves the scheduler uses the override.<br>3. No `new` constructor calls remain inside the provider body. |

---

## MAJOR — Feature is broken or misleading

### M1. Completely dead code: `SessionPlanAdherenceService` + `PlanAdherenceContract`

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/services/session_plan_adherence_service.dart` (44 lines)<br>`lib/core/data/contracts/plan_adherence_contract.dart` (7 lines) |
| **Rationale** | Neither `SessionPlanAdherenceService` nor `PlanAdherenceContract` is imported or referenced anywhere outside their own files. The service creates internal `PlanRepository()` and `InstrumentationService()` instances inline. This is 51 lines of dead code that has likely bit-rotted (it uses `DateTime.now()` directly instead of `Clock`). |
| **Acceptance criteria** | 1. Delete both files.<br>2. Run `dart analyze` — zero new warnings.<br>3. Run full test suite — zero failures. |

### M2. `TopicProgressModel` deprecated & unused — dead Hive typeId

| Severity | MAJOR |
|----------|-------|
| **File** | `lib/features/subjects/data/models/topic_progress_model.dart` (62 lines) |
| **Rationale** | Marked `@Deprecated('Use MasteryState and MasteryStateRepository instead')`. Zero imports from production code. The class carries a Hive `typeId: 1` that occupies a slot in the Hive type registry — occupying a type ID that could conflict if reused. |
| **Acceptance criteria** | 1. Delete the file.<br>2. Remove any references in `hive_type_ids.dart` if it listed typeId 1.<br>3. Verify no Hive box still stores `TopicProgress` objects (or add a migration).<br>4. Full test suite passes. |

### M3. `@Deprecated` classes still actively consumed

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/data/models/markscheme_model.dart` (lines 3, 87) — `Markscheme` and `MarkSchemeStep`<br>`lib/features/practice/data/repositories/spaced_repetition_repository.dart` (line 10) |
| **Rationale** | **`Markscheme`** (`@Deprecated('Use QuestionEvaluation instead')`) is used by 6 production files: `answer_validation_service.dart`, `question_repository.dart`, `content_pipeline.dart`, `question_pdf_generator.dart`, `markscheme_adapter.dart` — plus their tests.<br><br>**`SpacedRepetitionRepository`** (`@Deprecated('Use SpacedRepetitionService directly instead')`) is used by 4 production files: `practice_providers.dart`, `practice_screen.dart`, `practice_session_screen.dart`, `practice_session_service.dart`.<br><br>Deprecation annotations are meaningless when the replacement (`QuestionEvaluation`, `SpacedRepetitionService`) isn't actually wired in. Developers ignore `@Deprecated` warnings because they have no choice. |
| **Acceptance criteria** | 1. For `Markscheme` → `QuestionEvaluation`: migrate all 6 consumers, remove the model and its adapter.<br>2. For `SpacedRepetitionRepository`: inline or delete the repository; migrate all 4 consumers to `SpacedRepetitionService`.<br>3. Run full test suite — zero failures. |

### M4. Mixed error handling: `throw Exception()` inside `Result.capture()`

| Severity | MAJOR |
|----------|-------|
| **File** | `lib/features/sessions/data/repositories/session_repository.dart` (lines 106, 152, 160, 180, 200) |
| **Rationale** | Five methods wrap logic in `Result.capture()` (which catches errors and returns `Result.failure`) but then manually `throw Exception(error)` when an inner `Result` is a failure. This defeats the purpose of the `Result` type — the exception bubbles up as an unhandled error at the provider level instead of propagating as a typed failure. Compare with all other repositories in the codebase that use `Result.capture()` correctly. |
| **Acceptance criteria** | 1. Replace all `throw Exception(result.error)` with `return Result.failure(result.error)` (or `throw AppException(result.error)` if the outer `Result.capture()` catches it).<br>2. Verify `allSessionsProvider` and `todayStatsProvider` in `session_providers.dart` correctly handle the error state.<br>3. Tests prove both success and failure paths. |

### M5. Top-level mutable `settingsRepository` singleton

| Severity | MAJOR |
|----------|-------|
| **Files** | `lib/core/providers/app_providers.dart:40` (declaration)<br>`lib/main.dart:86,117,156`<br>`lib/features/settings/presentation/profile_screen.dart:53,132,570` |
| **Rationale** | `var settingsRepository = SettingsRepository()` is a top-level mutable variable outside the Riverpod provider tree. It is used directly in `main.dart` (lines 86, 117, 156) and `profile_screen.dart` (lines 53, 132, 570), bypassing Riverpod's lifecycle and DI. This means:<br><br>1. **Cannot override** in widget tests.<br>2. **Mutable global state** — any mutation at runtime affects all consumers.<br>3. **`settingsProvider`** wraps it at line 260, so there are now two ways to access settings (provider vs. raw singleton). |
| **Acceptance criteria** | 1. Convert `settingsRepository` to a proper Riverpod `Provider<SettingsRepository>`.<br>2. `main.dart` uses `ref.read(settingsRepositoryProvider)` instead of the bare import.<br>3. `profile_screen.dart` reads it via provider.<br>4. Widget tests override `settingsRepositoryProvider` and prove the override propagates. |

---

## MINOR — Code quality / UX friction

### m1. Hardcoded English locale bypasses i18n

| Severity | MINOR |
|----------|-------|
| **Files** | `lib/core/errors/handlers.dart:3` imports `app_localizations_en.dart` directly<br>`lib/core/services/llm/llm_chat_service.dart:4` imports `app_localizations_en.dart` directly |
| **Rationale** | Both files create `AppLocalizationsEn()` directly instead of using the abstract `AppLocalizations.of(context)`. In `handlers.dart`, the `_defaultL10n` getter returns `AppLocalizationsEn()`, meaning error messages shown to users are **always in English** regardless of the app locale. In `llm_chat_service.dart`, hardcoded English prompts appear in LLM-facing contexts (explicitly OK in AGENTS.md for LLM strings, but `handlers.dart` is user-facing). |
| **Acceptance criteria** | 1. `handlers.dart` accepts a `AppLocalizations` parameter from the caller (passed from the widget/provider that has context).<br>2. All call sites pass the correct locale-aware instance.<br>3. Remove the `app_localizations_en.dart` import. |

### m2. `debugPrint()` used instead of `Logger`

| Severity | MINOR |
|----------|-------|
| **Files** | `lib/core/utils/color_utils.dart:26`<br>`lib/core/services/badge_service.dart:61` |
| **Rationale** | The project has a custom `Logger` class (`lib/core/utils/logger.dart`) that uses `debugPrint` internally with proper formatting (timestamp, level, stack trace). Two files bypass it and call `debugPrint` directly, producing unformatted output that won't be caught if the logging strategy changes. |
| **Acceptance criteria** | 1. Replace both `debugPrint(...)` calls with `Logger(...).e(...)` (or appropriate level).<br>2. Run full test suite. |

### m3. `settingsLoadingProvider` never flips to `true`

| Severity | MINOR |
|----------|-------|
| **Files** | `lib/core/providers/app_providers.dart:263` (declaration)<br>`lib/main.dart:150` (consumer) |
| **Rationale** | `settingsLoadingProvider` is a `StateProvider<bool>` initialized to `false`. No code in the entire project ever sets it to `true`. `main.dart:150` watches it for a loading indicator — meaning the loading state is **always false** and the user sees no loading feedback while settings are being loaded (which is async on lines 86/117/156). |
| **Acceptance criteria** | 1. Set `.state = true` before the async init calls in `main.dart` and `.state = false` after.<br>2. Or remove the provider if the async init is fast enough not to need loading UI.<br>3. Widget test verifies the loading state transitions. |

### m4. Orphaned providers (defined, never consumed in `lib/`)

| Severity | MINOR |
|----------|-------|
| **Files** | `lib/features/practice/providers/practice_providers.dart`: |
| | `difficultyAdapterProvider` (line 104) |
| | `crossFeatureIntegratorProvider` (line 122) |
| | `practiceDataServiceProvider` (line 129) |
| | `lib/features/sessions/providers/session_providers.dart`: |
| | `allSessionsProvider` (line 12) |
| | `todayStatsProvider` (line 16) |
| **Rationale** | These 5 providers are declared with full factory logic but are never `ref.watch()`/`ref.read()`-ed by any production code. They are only exercised in test files. This is dead code that increases maintenance burden and misleads developers about available state. |
| **Acceptance criteria** | 1. Remove each orphaned provider **if** it has no legitimate planned consumer.<br>2. OR add a comment documenting the intended consumer if it's a "future use" provider.<br>3. Run full test suite. |

### m5. Magic numbers instead of named constants

| Severity | MINOR |
|----------|-------|
| **Files & lines** | |
| | `lib/features/practice/services/exam_session_service.dart:132` — `q.difficulty == 3` (magic number for medium difficulty) |
| | `lib/core/services/mastery_calculation_service.dart:89` — `const expectedTimeMs = 60000.0` (60 seconds as a magic float; should be `Duration`-based) |
| | `lib/core/services/remaining_workload_estimator.dart:48-50` — `0.7`, `0.5`, `8` (mastery threshold, at-risk threshold, questions per lesson) |
| | `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart:126` — `Duration(days: 90)` (booking horizon) |
| | `lib/features/planner/presentation/widgets/milestone_timeline.dart:36` — `Duration(days: 30)` (default plan span) |
| **Rationale** | These numeric literals are scattered across multiple files with no documentation of why these specific values were chosen. They should be extracted to the relevant config class (`timeouts.dart`, `app_constants.dart`, or a new feature-specific config) so they can be changed in one place and documented. |
| **Acceptance criteria** | 1. Each magic number is extracted to a named constant in the appropriate config file.<br>2. The constant has a comment explaining the rationale.<br>3. Tests reference the constant, not a re-literal. |

### m6. Inline `Duration(...)` instead of `Timeouts` constants

| Severity | MINOR |
|----------|-------|
| **Files & lines** | |
| | `lib/features/ingestion/presentation/upload_screen.dart:308` — `Duration(seconds: 6)` |
| | `lib/core/routes/app_router.dart:311,325` — `Duration(milliseconds: 200)` |
| | `lib/features/dashboard/presentation/dashboard_screen.dart:412` — `Duration(milliseconds: 1500)` |
| | `lib/core/widgets/animated_bar_chart.dart:68` — `Duration(milliseconds: 300)` |
| | `lib/features/teaching/services/voice_controller.dart:95-96` — `Duration(seconds: 60)`, `Duration(seconds: 3)` |
| **Rationale** | `lib/core/constants/timeouts.dart` defines a `Timeouts` class with named constants (`apiCall`, `ms500`, `second`, etc.), but these files duplicate durations inline. This makes it hard to tune timeouts globally and risks inconsistencies. |
| **Acceptance criteria** | 1. Each inline `Duration` is replaced with the equivalent `Timeouts` constant (or a new constant is added to `timeouts.dart` if no match exists).<br>2. Full test suite passes. |

### m7. Nested `child:` depth makes screens unmaintainable

| Severity | MINOR |
|----------|-------|
| **Files** | |
| | `lib/features/settings/presentation/settings_screen.dart` — 1,112 lines, 37 imports, 3 build methods |
| | `lib/features/planner/presentation/planner_screen.dart` — 946 lines, 39 `child:` nesting levels |
| | `lib/features/focus_mode/presentation/focus_timer_screen.dart` — 841 lines, 41 `child:` levels |
| | `lib/features/practice/presentation/screens/practice_screen.dart` — 801 lines, 26 methods |
| **Rationale** | These files are large, deeply nested widget trees that violate the single-responsibility principle in practice. The `child:` nesting (measured at 30-41 levels) makes diffs hard to review, refactoring risky, and widget tests brittle (small layout changes cascade). |
| **Acceptance criteria** | 1. Extract logical sections into separate widget classes (as done in `dashboard/presentation/widgets/`).<br>2. No file exceeds 500 lines.<br>3. No build method exceeds 10 levels of widget nesting.<br>4. Full test suite passes. |

### m8. Direct field access on `PlannerService` from provider

| Severity | MINOR |
|----------|-------|
| **File** | `lib/features/planner/providers/planner_providers.dart:85-86` |
| **Rationale** | `planProgressProvider` accesses `service.adherenceRepo` and `service.studentId` directly (public fields on `PlannerService`) instead of through method calls. This tightly couples the provider to the service's internal field naming. If the service is refactored, the provider silently breaks. |
| **Acceptance criteria** | 1. Add public methods to `PlannerService` (e.g. `fetchAdherenceRecords()`) and use them in the provider.<br>2. Or the provider should use separate repository providers instead of reaching into the service.<br>3. Tests pass. |

### m9. Missing tests for production files (per AGENTS.md conventions)

| Severity | MINOR |
|----------|-------|
| **Files without tests** | |
| | `lib/features/ingestion/presentation/source_detail_screen.dart` → no `test/features/ingestion/presentation/source_detail_screen_test.dart` |
| | `lib/features/ingestion/presentation/content_library_screen.dart` → no corresponding test |
| | `lib/features/questions/presentation/question_bank_screen.dart` → no corresponding test |
| | `lib/core/data/models/source_model.dart` → no `test/core/data/models/source_model_test.dart` |
| | `lib/core/services/pdf_generator/question_pdf_generator.dart` → no test |
| | `lib/core/widgets/empty_state_widget.dart` → no test |
| | `lib/core/widgets/error_retry_widget.dart` → no test |
| | `lib/core/widgets/loading_indicator.dart` → no test |
| | `lib/core/widgets/loading_screen.dart` → no test |
| **Rationale** | Per AGENTS.md's test-file-placement tables, every source file must have a corresponding test file. These 9 files are gaps. Notably the `core/widgets/` widgets are foundational UI building blocks that other widgets depend on — a regression in `empty_state_widget.dart` would cascade silently. |
| **Acceptance criteria** | 1. Each missing test file is created with at least one behaviorial assertion (per AGENTS.md provider/bar convention).<br>2. `dart analyze` passes.<br>3. All tests pass. Note: some may be widget tests requiring `pumpWidget`. |

### m10. `ref.read()` used inside provider factories (inconsistent style)

| Severity | MINOR |
|----------|-------|
| **Affected files** | `lib/features/practice/providers/practice_providers.dart` (all 17 providers use `ref.read()`)<br>`lib/features/dashboard/providers/dashboard_data_providers.dart` (all providers use `ref.read()`) |
| **Rationale** | All providers in these files use `ref.read(dependencyProvider)` inside their factory callbacks instead of `ref.watch(dependencyProvider)`. While functionally correct for `Provider<T>` (which never changes at runtime), this is inconsistent with the rest of the codebase (e.g. `lesson_providers.dart`, `teaching_providers.dart` use `ref.watch`). `ref.watch` is recommended because it (a) documents the dependency relationship, (b) will dynamically update if the dependency is ever changed to a reactive provider, and (c) triggers Riverpod's dependency tracking. |
| **Acceptance criteria** | 1. Change `ref.read(` to `ref.watch(` in all provider factories in these two files.<br>2. Full test suite passes. |

---

## Summary

| Severity | Count | Labels |
|----------|-------|--------|
| BLOCKER | 2 | `duplicate-provider`, `untestable-provider` |
| MAJOR | 5 | `dead-code`, `deprecated-unmigrated`, `error-handling`, `global-mutable-state` |
| MINOR | 10 | `i18n-bypass`, `debugPrint`, `dead-provider`, `magic-numbers`, `inline-durations`, `deep-nesting`, `encapsulation`, `test-gaps`, `ref-read-vs-watch` |
| **Total** | **17** | |

### Quick-win items (single-file changes, high confidence):

1. **m2** — Replace two `debugPrint()` calls with `Logger` → 2 files, 2 lines changed.
2. **M1** — Delete two dead-code files → 51 lines removed.
3. **m3** — Wire `settingsLoadingProvider` to `true` during init → 1 file, ~3 lines changed.
4. **m1** — Remove `app_localizations_en.dart` imports → 2 files, `AppLocalizations` parameter.
5. **M4** — Replace `throw Exception` with `return Result.failure` in session repo → 1 file, 5 lines changed.
