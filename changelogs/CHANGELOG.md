# Changelog

## 2026-05-19

### BLOCKER fixes
- **B1**: Fixed `export_section.dart` — private methods `_exportCSV`, `_exportPDF`, `_exportJSON`, `_exportProgressCSV`, `_exportInstrumentation` referenced local variables from `build()` scope causing compile errors. Methods now accept dependencies as parameters. Added widget test coverage for the "Export Backup (full)" dialog button path in `settings_screen_test.dart`.
- **B1**: Removed dead `_checkAutoBackup()` method from `SettingsScreen` (moved to `main.dart` startup flow in a prior change). Removed empty `initState` override.
- **B3**: Fixed dead `l10n.share` reference in `_performAutoBackup()` SnackBar (no such translation key). Replaced with hardcoded `'Share'` label.
- **B2/B3**: Fixed missing `student_id_service.dart` import in `settings_screen.dart` causing `StudentIdService` compile error in restore flow.

### MAJOR fixes
- **M10**: Fixed `progress_export_service.dart` unused imports (`flutter/material.dart`, `session_repository.dart`).
- **M1**: Added `toJson`/`fromJson` round-trip serialization tests for 9 box types: `BadgeModel`, `EngagementNudgeModel`, `PendingActionModel`, `TaskModel`, `StudentAvailabilityModel`, `SettingsAPIKey`, `UserProfile`, `LlmTask`, `LlmUsageRecord`.

### MINOR fixes
- **N4**: Added export icon (`Icons.file_download_outlined`) to `DashboardHeader` with scroll-to-export behaviour via `_exportSectionKey` GlobalKey and `Scrollable.ensureVisible`. Added `onExportTap` callback parameter to `DashboardHeader`. Added `ScrollController` to `DashboardScreen`.
- **N5/N4**: Fixed `l10n.boxCount()` → `'$boxCount boxes'` (no such translation method in generated l10n).

## 2026-05-18

### Code Refactor Master (continued)
- **M-1**: Deleted dead duplicate `engagement_nudge_adapter.dart` and `student_availability_adapter.dart` in `features/planner/data/adapters/` (typeId 32 and 35, never registered by `registerPlannerAdapters()`). Removed corresponding test files. Core adapter tests at `test/core/data/` remain.
- **M-2**: Deleted dead duplicate `source_model.dart` in `features/ingestion/data/models/` (typeId 26, same as core copy). All 8 consumers already import from `core/data/models/source_model.dart`.
- **M-6**: Renamed `DifficultyAdapter` → `DifficultyController` (file: `difficulty_adapter.dart` → `difficulty_controller.dart`). Renamed `PlanAdapter` → `PlanAdherenceOrchestrator` (file: `plan_adapter.dart` → `plan_adherence_orchestrator.dart`). Updated all 25+ import sites and provider references.
- **M-7**: Removed barrel leak: `export 'subject_model.dart'` from `features/subjects/subjects.dart` (core model re-exported as feature concept). Removed barrel leak: `export 'question_providers.dart'` from `features/practice/providers/practice_providers.dart` (transitive feature dependency).
- **m-1**: Removed unused `repository` constructor parameter from `MasteryGraphService` (was suppressed with `// ignore` comment).
- **m-2**: Consolidated `recordFromFocusSession`, `recordFromPracticeSession`, `recordFromTutorSession` into single `recordActivity({required studentId, required actualMinutes, int actualQuestions = 0, planId})` on `PlanAdherenceOrchestrator`. Updated 3 call sites and 7 fake implementations.
- **m-5**: Updated stale `TODO(v2.0)` in `app_api_config.dart` to reference concrete tracking issue.
- **m-6**: Changed `Logger.shouldLog()` to allow `info` level by default (previously only `warn`/`error` were visible unless `--verbose` was set).
- **m-7**: Added `test/architecture/architectural_constraints_test.dart` with three constraint groups: feature→feature imports, core→feature imports, and raw `throw` in services/repositories.
- **M-8**: Consolidated duplicate timeouts from `app_api_config.dart` into `timeouts.dart`; added `openRouterTimeoutProduction/Staging/Development`, `youtubeTimeoutDefault/Development` constants. Replaced hardcoded `Duration(seconds: 4)` in `llm_task_manager_screen.dart` with `Timeouts.animationMedium`.

### Code Refactor Master
- Added Hive annotations (`@HiveType`, `@HiveField`) to `TopicProgress` model in `lib/features/subjects/data/models/` and registered type ID 37 in `hive_type_ids.dart`
- Replaced hardcoded `Duration` literals with `Timeouts.*` constants: `Duration(minutes: 1)` → `Timeouts.oneMinute` (tutor_screen), `Duration(days: 365)` → `Timeouts.year` (lesson_detail_screen), `Duration(seconds: 10)` → `Timeouts.apiHealthCheck` (settings_screen), `Duration(seconds: retry ? 4 : 3)` → `Timeouts.snackbarErrorRetry`/`snackbarShort` (handlers.dart)
- Added missing `Timeouts` constants: `oneMinute`, `year`, `snackbarErrorRetry`, `snackbarShort`
- Made `AppErrorHandler._logger` follow private-field-with-public-getter pattern (m20 fix)
- Replaced `.catchError((_) => Result.success(...))` patterns in `practice_screen.dart` with proper try/catch error logging (M9 fix)
- Made default LLM model names configurable via `--dart-define`: `DEFAULT_OPENROUTER_MODEL`, `DEFAULT_OLLAMA_MODEL`, `DEFAULT_OPENAI_MODEL` (m22 fix)
- Added `.env.example` with all 8 `--dart-define` configuration keys documented (m21 fix)
- Removed unused `Result` class import from `practice_screen.dart`

### BLOCKER fixes
- Added global error boundary (`ErrorWidget.builder` override + `PlatformDispatcher.onError` handler) to prevent white screen on init failure
- Fixed mentor progress report dialog potential double `Navigator.pop` crash by using captured context, post-frame delay, and try-catch fallback
- Replaced raw `error.toString()` exposure with user-friendly localized messages in subject list screen

### MAJOR fixes
- **Dashboard skeleton**: Skeleton now renders immediately as default loading state; empty states use `EmptyStateWidget` for consistency
- **Pull-to-refresh**: Added `RefreshIndicator` to subject list screen
- **API key banner**: Dismissal now persisted to `SettingsBox` with 7-day re-show suppression and "Don't show again" option
- **Disabled practice cards**: Cards now show clear reason when disabled and open dialog with call-to-action on tap
- **Session history export**: Replaced 9-item overflow menu with dedicated bottom sheet (3 options) and format sub-picker for comprehensive report
- **Onboarding dialog**: Converted text-heavy list to interactive `PageView` (3 pages) with page indicator, skip button, and icon illustrations
- **Empty state standardization**: Migrated subject list and practice screens to use `EmptyStateWidget` as single source of truth

### MINOR fixes
- Added `destructiveFilledButtonTheme` to `AppTheme` for consistent delete/remove button styling
- Added `Semantics(liveRegion: true)` to loading indicators; added `Semantics(enabled: false)` to disabled interactive elements
- Replaced bare `CircularProgressIndicator` with `LoadingScreen` in focus timer and practice session screens
- Wrapped multi-choice `Column` in `ConstrainedBox` + `ListView` to prevent overflow
- Fixed `SliverAppBar` text color readability with scrim overlay and `onSurface` color
- Increased `CollapsibleCard` tap target to minimum 48px height
- Added loading screen with cancel button to tutor initialization
- Constrained `FloatingActionButton.extended` width on small screens (`maxWidth: screenWidth - 64`)
- Deduplicated navigation destination lists into single `_DestinationData` list with tooltips
- Replaced `SizedBox.shrink()` with meaningful messages in workload and weak areas cards
- Applied high-contrast mode to subject detail gradient (solid color fallback)
- Added `Semantics` loading state labels to `ConversationInput` send button
- Added "Review answers" button to practice results screen
