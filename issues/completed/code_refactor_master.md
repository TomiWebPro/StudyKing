# Code Refactor Master Issue

Generated: 2026-05-19 by automated codebase analysis.

## Priority Summary

| Severity | Count |
|----------|-------|
| BLOCKER  | 0     |
| MAJOR    | 6     |
| MINOR    | 19    |

---

## MAJOR

### M1. Core layer depends on feature modules (layering violation)

**Context:** 12+ files in `lib/core/services/` import from `lib/features/*/`, breaking the intended layered architecture where `core` should have zero knowledge of features.

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart` (942 B) — imports planner, practice, subjects, questions
- `lib/core/services/engagement_scheduler.dart` (432 B) — imports mentor, planner, sessions, settings
- `lib/core/services/mastery_graph_service.dart` (166 B) — imports practice repos/models
- `lib/core/services/mastery_calculation_service.dart` (167 B) — imports practice mastery model
- `lib/core/services/topic_readiness_service.dart` (133 B) — imports subjects, practice
- `lib/core/services/study_progress_tracker.dart` (356 B) — imports practice, sessions
- `lib/core/services/badge_service.dart` (107 B) — imports dashboard
- `lib/core/services/prerequisite_check_service.dart` (121 B) — imports subjects, practice
- `lib/core/services/answer_validation_service.dart` (480 B) — imports questions
- `lib/core/services/conversation_memory.dart` (110 B) — imports teaching
- `lib/core/services/progress_export_service.dart` (374 B) — imports practice
- `lib/core/services/plan_adherence_orchestrator.dart` (269 B) — imports planner
- `lib/core/data/database_service.dart` — imports 6 feature repos
- `lib/core/data/hive_initializer.dart` — imports 6 feature adapter sets
- `lib/core/providers/app_providers.dart` — imports 8 features
- `lib/core/providers/llm_agent_providers.dart` — imports 5 features

**Rationale:** Every time `core` imports a feature, those core services become unreusable outside this project and cannot be tested without the entire feature tree. Fifteen core files have feature imports, meaning nearly 40% of `core/` is tightly coupled to the feature layer.

**Acceptance criteria:**
- Zero `import 'package:studyking/features/'` statements remain in `lib/core/` files
- Feature-specific logic currently in core services is moved into one of:
  - The owning feature's `services/` directory
  - A new `lib/domain/` layer (as recommended by clean architecture)
  - `core/services/` only if it has ZERO feature imports (pure infrastructure)
- The `engagement_scheduler.dart`, `personal_learning_plan_service.dart`, `mastery_graph_service.dart`, `study_progress_tracker.dart` are the top 4 candidates for relocation

---

### M2. Mutual import between `app_router.dart` and `not_found_screen.dart`

**Affected files:**
- `lib/core/routes/app_router.dart:4` — imports `not_found_screen.dart`
- `lib/core/widgets/not_found_screen.dart:2` — imports `app_router.dart`

**Rationale:** `app_router.dart` imports `NotFoundScreen` to register it as a route. `NotFoundScreen` imports `AppRoutes.dashboard` to navigate home. This creates a compile-time circular dependency. Currently it works because Dart allows it in practice, but it is fragile — any static analysis tool or tree-shaking pass could break this, and it prevents lazy-loading of route modules.

**Acceptance criteria:**
- `NotFoundScreen` no longer imports `app_router.dart`
- The navigation to dashboard is achieved via a callback (already exists as `onGoToDashboard` parameter) or via `Navigator.of(context).pushReplacementNamed(...)` using a string literal `/dashboard` (which is already stable)
- No import cycles remain in the route/screen graph

---

### M3. Cross-feature imports within feature modules

**Affected files (representative list):**
- `lib/features/questions/providers/question_providers.dart` → imports `features/ingestion`
- `lib/features/questions/presentation/question_bank_screen.dart` → imports `features/ingestion`, `features/subjects`, `features/practice`
- `lib/features/practice/presentation/screens/practice_screen.dart` → imports `features/questions`, `features/sessions`, `features/ingestion`
- `lib/features/teaching/presentation/tutor_screen.dart` → imports `features/lessons`, `features/focus_mode`
- `lib/features/teaching/providers/teaching_providers.dart` → imports `features/practice`
- `lib/features/planner/services/planner_service.dart` → imports `features/sessions`

**Rationale:** Features that depend on other features create a tangled dependency graph where changing one feature can break others. Feature modules should only depend on `core/` and never on sibling features. The most coupled feature is `practice` (depends on questions, sessions, ingestion) and `questions` (depends on ingestion, subjects, practice).

**Acceptance criteria:**
- Zero `import 'package:studyking/features/<different_feature>/'` statements remain within `lib/features/`
- Shared concepts (e.g., question ↔ practice session integration) are mediated through `core/services/` interfaces or a shared `lib/domain/` layer
- The reverse: core services (after M1 fix) provide clean abstractions that features can depend on without coupling to sibling features

---

### M4. Two Hive adapter classes crammed into one file (convention violation)

**Affected file:**
- `lib/features/teaching/data/adapters/conversation_message_adapter.dart` — defines both `ConversationMessageAdapter` (typeId 27) and `TutorSessionAdapter` (typeId 28)

**Rationale:** Every other adapter in the project follows one-class-per-file. Having two adapters in one file violates discoverability, makes the barrel file less obvious (`teaching/data/adapters.dart` only registers `TutorSessionAdapter`), and is a maintenance hazard when type IDs change.

**Acceptance criteria:**
- `TutorSessionAdapter` is extracted to its own file `lib/features/teaching/data/adapters/tutor_session_adapter.dart`
- `conversation_message_adapter.dart` defines only `ConversationMessageAdapter`
- The barrel file `teaching/data/adapters.dart` is updated to register from the new file

---

### M5. Overlapping session model definitions

**Affected files:**
- `lib/core/data/models/session_model.dart` — core `Session` with `TutorMetadata`, `SessionType`, `SessionStatus`
- `lib/features/focus_mode/data/focus_session_model.dart` — redefines `durationMinutes`, `questionsAnswered`, `correctAnswers`, `accuracy`, `masteryChanges`
- `lib/features/teaching/data/models/tutor_session_model.dart` — redefines `status`, `questionsAsked`, `questionsCorrect`, `confidenceRating`, `tutorNotes`

**Rationale:** `FocusSession` and `TutorSession` both overlap significantly with the core `Session` model. `FocusSession.durationMinutes` duplicates `Session.durationMs`. `TutorSession.status` duplicates `Session.status`. This causes data inconsistency (a focus session stored as both a `Session` and a `FocusSession` could drift) and confusion about which model to use.

**Acceptance criteria:**
- A single `Session` model in `core/data/models/session_model.dart` handles all session types via a `type` field (already exists as `SessionType`) and an optional `metadata` Map or typed union
- `FocusSession` and `TutorSession` are either removed (folded into `Session`) or converted to lightweight wrappers that delegate to `Session`
- Hive adapters are updated accordingly (only one adapter for `Session`)

---

### M6. Core domain models without Hive adapters

**Affected files:**
- `lib/core/data/models/question_model.dart` — **no adapter exists**
- `lib/core/data/models/subject_model.dart` — **no adapter exists**
- `lib/core/data/models/topic_model.dart` — **no adapter exists**

**Rationale:** These models live in `core/data/models/` but have no corresponding Hive adapter registered anywhere. Either they are never persisted via Hive (and should be removed from the data layer or moved) or they are persisted via a mechanism that bypasses the adapter registration system (which means the type-registration guard in `hive_initializer.dart` cannot validate them).

**Acceptance criteria:**
- Each model in `core/data/models/` either has a registered Hive adapter, or is moved out of the data persistence layer
- `hive_initializer.dart` validates that all models have registered adapters
- If these models are serialized via jsonEncode/jsonDecode manually, a comment documents why they skip the Hive adapter system

---

## MINOR

### m1. Monolithic screen files — SRP violations

**Top offenders (all >700 lines with single build() >150 lines):**

| File | Total lines | Largest build/method | What |
|------|-------------|---------------------|------|
| `features/settings/presentation/settings_screen.dart` | 1825 | 208 L `_buildSettingsBody()` + 237 L `_exportBackup()` | Settings, backup, import, AI config all in one file |
| `features/planner/presentation/planner_screen.dart` | 1463 | 173 L `_buildStudyPlanTab()` | Roadmaps, study plan, syllabus input in one screen |
| `features/mentor/presentation/mentor_screen.dart` | 1118 | 238 L `_showProgressReport()` | Chat + progress report as single screen |
| `features/dashboard/presentation/dashboard_screen.dart` | 719 | 371 L `build()` | Entire dashboard rendered in one method |
| `features/practice/presentation/screens/practice_screen.dart` | 863 | — | Practice + question loading + session management |

**Affected files (also):**
- `features/focus_mode/presentation/focus_timer_screen.dart` (1090)
- `core/services/personal_learning_plan_service.dart` (942 — largest service)
- `features/questions/presentation/question_bank_screen.dart` (842)
- `features/ingestion/presentation/upload_screen.dart` (685)
- `features/ingestion/presentation/source_detail_screen.dart` (667)

**Rationale:** Methods >80 lines and build() >150 lines violate SRP. They mix widget construction, business logic, error handling, and navigation. Testing, debugging, and reasoning about such methods is exponentially harder.

**Acceptance criteria:**
- Every `build()` method is <150 lines (extract sub-widgets)
- Every helper method (non-build) is <80 lines (extract services or fine-grained methods)
- Settings screen is split: `BackupSettingsSection`, `AISettingsSection`, `TokenSettingsSection` as separate files/widgets
- Dashboard screen extracts: stat cards, progress charts, quick actions, recent activity into separate widgets
- `personal_learning_plan_service.dart` extracts `_buildPlan()` and `_generateDailyPlans()` into separate service classes

---

### m2. Duplicate repository providers (same repo, multiple instances)

**Affected providers (7 repository types instantiated in ≥2 provider files):**

| Repository | Duplicated in |
|---|---|
| `AttemptRepository` | `mentor_providers.dart` (as `mentorAttemptRepositoryProvider`), `practice_providers.dart` (as `attemptRepositoryProvider`) |
| `EngagementNudgeRepository` | `mentor_providers.dart` (as `mentorEngagementNudgeRepoProvider`), `app_providers.dart` (as `engagementNudgeRepoProvider`) |
| `SessionRepository` | `mentor_providers.dart` (as `mentorSessionRepositoryProvider`), `session_providers.dart` (as `sessionRepositoryProvider`) |
| `SourceRepository` | `ingestion_providers.dart` (as `ingestionSourceRepositoryProvider`), `question_providers.dart` (as `sourceRepositoryProvider`) |
| `TopicRepository` | `ingestion_providers.dart` (as `ingestionTopicRepositoryProvider`), `subjects/providers/topic_repository_provider.dart` (as `topicRepositoryProvider`) |
| `QuestionRepository` | `ingestion_providers.dart` (as `ingestionQuestionRepositoryProvider`), `question_providers.dart` (as `questionRepositoryProvider`) |
| `SubjectRepository` | `practice_providers.dart` (as `subjectRepositoryProvider`), `subjects_repository_provider.dart` (as `subjectsRepositoryProvider` — AsyncNotifier) |

**Rationale:** Each duplicated provider creates a **separate singleton instance** of the same repository backed by the same Hive box. This means data written through one provider may not be visible through another (depending on Hive's caching behavior). It also defeats the purpose of Riverpod's singleton scoping.

**Acceptance criteria:**
- Each repository type has exactly **one** provider definition in the entire codebase
- Other features that need that repository use `ref.read(xxxRepositoryProvider)` from the canonical provider (possibly via a shared provider barrel in `core/providers/`)
- All 7 duplicated providers are consolidated; the mentor feature uses the same `AttemptRepository` instance as the practice feature

---

### m3. `dart:io` in presentation layer (blocks web support)

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart` — `import 'dart:io' show File;`
- `lib/features/dashboard/presentation/widgets/export_section.dart` — `import 'dart:io' show File;`

**Rationale:** Importing `dart:io` in presentation-layer code makes the entire app tree unusable on web. File operations (export, backup) should be delegated to service-layer classes that can be conditionally imported or use `universal_io`/`cross_file`.

**Acceptance criteria:**
- `settings_screen.dart` delegates backup file operations to `DataBackupService` (already exists in `features/settings/services/`)
- `export_section.dart` delegates export file operations to `ProgressExportService` or a similar service
- Zero `import 'dart:io'` statements remain in `lib/**/presentation/`

---

### m4. Redundant barrel file in `planner/data/`

**Affected files:**
- `lib/features/planner/data/planner_data.dart` — contains `export 'adapters.dart'; export 'models/personal_learning_plan_model.dart';`
- `lib/features/planner/data/adapters.dart` — standalone barrel for adapter registration

**Rationale:** `planner_data.dart` is a 2-line file that only re-exports `adapters.dart` and one model. Every other feature has either a single data barrel or a separate `adapters.dart`. This dual-barrel pattern is confusing and unnecessary — `planner_data.dart` should either be removed (with consumers importing `adapters.dart` and models directly) or expanded to export all data artifacts.

**Acceptance criteria:**
- Either `planner_data.dart` is removed and its consumers are updated, or it is expanded to export all models and repositories from `planner/data/`
- The barrel pattern is consistent across all features

---

### m5. File placement violations

**Affected files:**
- `lib/features/practice/utils/sr_data_codec.dart` — generic JSON serializer/deserializer placed inside a feature; should be in `core/utils/`
- `lib/features/sessions/data/repositories/session_utils.dart` — contains `sessionIcon()` and `sessionColor()` returning `IconData`/`Color`; placed in `data/repositories/` but is pure presentation logic, should be in `sessions/presentation/utils/` or `core/widgets/`
- `lib/features/llm_tasks/` — missing `data/` directory entirely (no models, repos, or adapters)
- `lib/features/focus_mode/data/focus_session_model.dart` — flat file in `data/` instead of `data/models/` subdirectory
- `lib/features/onboarding/data/onboarding_state.dart` — flat file in `data/` instead of `data/models/` subdirectory
- `lib/features/quickguide/data/` — empty directory, should be removed

**Acceptance criteria:**
- `sr_data_codec.dart` moved to `core/utils/sr_data_codec.dart`
- `session_utils.dart` moved to `features/sessions/presentation/utils/session_utils.dart`
- `focus_session_model.dart` moved to `features/focus_mode/data/models/focus_session_model.dart`
- `onboarding_state.dart` moved to `features/onboarding/data/models/onboarding_state.dart`
- `features/quickguide/data/` removed (or populated)
- `features/llm_tasks/data/` created if any data layer artifacts are needed

---

### m6. Hardcoded values that should be centralized

| Where | What | Should be |
|-------|------|-----------|
| `lib/features/ingestion/services/web_scraper.dart:23` | User-Agent string duplicates `ApiConfig.userAgent` | `ApiConfig.userAgent` |
| `lib/core/services/engagement_scheduler.dart:134-135` | Magic number `120` for nudge body truncation | Named constant |
| `lib/core/services/mastery_calculation_service.dart:100-109` | Inline thresholds `0.9`, `5`, `10`, `0.8`, `0.6`, `3`, `30.0` | `study_utils.dart` constants |
| `lib/core/services/plan_adherence_orchestrator.dart:131-136` | Inline plan defaults `7`, `30.0`, `15`, `0.8`, `10`, `7`, `5`, `50` | Reference existing constants |
| `lib/main.dart:451` | `7 * 24 * 60 * 60 * 1000` (one week in ms) | `Timeouts.week.inMilliseconds` |
| `lib/features/settings/presentation/settings_screen.dart:583,710,732` | Picker option lists hardcoded | Config constants |
| `lib/main.dart:317` and `settings_screen.dart:472-475` | Font size `10.0`, `30.0` bounds duplicated | Single constant source |
| `lib/core/data/extraction/transcription_extractor.dart:260` | `'https://www.youtube.com/watch?v=$videoId'` hardcoded | `ApiConfig` constant |

**Acceptance criteria:**
- All hardcoded values above are replaced with references to existing constants or newly created named constants
- `web_scraper.dart` uses `ApiConfig.userAgent` instead of duplicating the string
- No duplicated numeric literal appears in two different files for the same semantic value
- `main.dart:451` uses `Timeouts.week.inMilliseconds`

---

### m7. Stale test scaffolding file

**Affected file:**
- `test/temp_should_delete_test.dart` — trivial placeholder test: `test('pass', () => expect(1 + 1, 2));`

**Rationale:** This file is clearly temporary scaffolding and should be removed before any CI pipeline or test coverage report. Its name explicitly says "should delete".

**Acceptance criteria:**
- File `test/temp_should_delete_test.dart` is deleted

---

### m8. Log level inconsistency (`.w()` vs `.e()`)

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart` — 14 `.w()` calls for failures like "Failed to initialize adherence repository", "Failed to save generated plan"
- `lib/features/planner/providers/planner_providers.dart` — 18 `.w()` calls for operation failures

**Rationale:** `.w()` (warning) should indicate a recoverable condition. "Failed to save generated plan", "Failed to initialize repository" are operation failures and should be `.e()` (error). Using `.w()` for genuine failures makes it impossible to filter logs by severity for operational monitoring.

**Acceptance criteria:**
- All genuine operation failures (repository init failure, plan save failure, data load failure) use `.e()` instead of `.w()`
- `.w()` is reserved for recoverable conditions (rate limiting, transient network blips, fallback-to-default scenarios)
- `.i()` is used for lifecycle events (service started/stopped, plan generation began/completed)
- The count of `.e()` vs `.w()` calls is reviewed across all files (current: 134 e, 123 w — nearly even, suggests w is overused)

---

### m9. Inconsistent error handling strategy

**Affected files (pattern mismatch):**
- `lib/core/data/repository.dart` — base class uses raw `try-catch` with `Result.failure()`
- `lib/features/lessons/data/repositories/lesson_repository.dart` — subclass uses raw `try-catch` with logger calls (duplicates base class pattern)
- `lib/features/sessions/data/repositories/session_repository.dart` — uses `Result.capture()` instead of try-catch
- `lib/features/planner/data/repositories/*.dart` — mix of `Result.capture()` and raw try-catch
- `lib/features/mentor/services/mentor_service.dart` — uses `Result.capture()` (10+ calls)
- `lib/features/teaching/data/repositories/tutor_session_repository.dart` — uses `Result.capture()` (6 calls)

**Rationale:** Three competing patterns exist:
1. Raw `try { ... } catch (e) { return Result.failure(...); }`
2. `Result.capture(() async { ... })`
3. Raw try-catch with explicit logger call

This inconsistency makes it unclear which pattern new code should follow. `Result.capture()` is more concise but loses the ability to log specific error context.

**Acceptance criteria:**
- A single pattern is chosen (recommendation: `Result.capture()` for simple operations, raw try-catch with logging for operations needing context)
- All 20+ repositories and services are migrated to the chosen pattern
- The base `Repository<T>` class is updated to use the chosen pattern consistently

---

### m10. Duplicated UI patterns across 20+ screens

**Pattern 1 — Confirmation dialogs (20+ occurrences):**
Repeated identically across: `content_library_screen.dart`, `source_detail_screen.dart`, `planner_screen.dart`, `mentor_screen.dart`, `question_bank_screen.dart`, `focus_timer_screen.dart`, etc.

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(l10n.confirm),
    content: Text(l10n.areYouSure),
    actions: [
      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.confirm)),
    ],
  ),
);
```

**Pattern 2 — SnackBar notifications (40+ occurrences across 9 files):**
Repeated identically across: `settings_screen.dart` (12×), `planner_screen.dart` (7×), `mentor_screen.dart` (5×), `focus_timer_screen.dart` (6×), `profile_screen.dart` (5×), etc.

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.operationCompleted)),
);
```

**Pattern 3 — `ref.read(settingsProvider).reduceMotion` (6+ screens):**
Used in focus_timer_screen, dashboard_screen, mentor_screen, upload_screen, settings_screen, practice_screen.

**Acceptance criteria:**
- A shared `showConfirmationDialog(BuildContext, {required String title, required String message})` utility is created in `core/widgets/` or as an extension on `BuildContext`
- A shared `showSuccessSnackBar` / `showErrorSnackBar` utility is created and all 40+ raw calls are replaced
- A `reduceMotionProvider` is created that derives from `settingsProvider` and is used uniformly across all screens

---

### m11. Stale version string in generated l10n

**Affected files (generated, but should be regenerated with correct version):**
- `lib/l10n/generated/app_localizations.dart:3548` — `'v0.1.0'`
- `lib/l10n/generated/app_localizations_es.dart:2064` — `'v0.1.0'`
- `lib/l10n/generated/app_localizations_en.dart:2044` — `'v0.1.0'`

**Rationale:** The app version displayed in the About screen is statically `v0.1.0` in generated localization files. It should either be dynamic (reading from `BuildConfig.appVersion`) or updated to reflect the current release.

**Acceptance criteria:**
- Version string in `app_en.arb` and `app_es.arb` (source of truth for l10n generator) is updated to match `pubspec.yaml` version
- Generated files are regenerated
- Ideally, the version is read at runtime from `BuildConfig` rather than baked into ARB files

---

### m12. Import path inconsistency

**Affected files (representative):**
- `lib/features/lessons/providers/lesson_providers.dart` — uses relative: `'../../../core/providers/app_providers.dart'`
- Most other provider files — use absolute: `'package:studyking/core/providers/app_providers.dart'`

**Rationale:** Mixing relative and absolute imports is a readability issue and can cause subtle bugs when files are moved (relative paths break silently). The project should standardize on one convention.

**Acceptance criteria:**
- All imports in `lib/` use the same convention (recommendation: absolute `package:` imports)
- No relative `../../` imports remain (except possibly generated code)

---

### m13. Pending TODO with stale static class evaluation

**Affected file:**
- `lib/features/practice/services/spaced_repetition_service.dart:18`
  `// TODO(m-2): Evaluate if this static class is still needed.`

**Rationale:** This TODO references an issue tracker label `m-2` that may no longer exist. If the class has been superseded by `SpacedRepetitionEngine`, remove it.

**Acceptance criteria:**
- `SpacedRepetitionService` is either deleted (if confirmed unused) or the TODO is replaced with a concrete action item (e.g., "Remove after Q3 2026 migration to `SpacedRepetitionEngine`")

---

### m14. Missing test coverage for provider files

**Context per AGENTS.md:**
> Every provider test file must include at least one behavioral assertion beyond construction checks.

**Affected provider files lacking tests (identified by absence of corresponding test file):**
Verify all providers in `lib/features/*/providers/` have matching tests in `test/features/*/providers/`.

**Rationale:** Provider tests are explicitly required by project conventions. Without behavioral assertions, dependency wiring errors (e.g., a renamed provider that is not updated in a consumer) go undetected.

**Acceptance criteria:**
- Every `lib/features/*/providers/*.dart` file has a corresponding `test/features/*/providers/*_test.dart`
- Each test includes at least one behavioral assertion (dependency injection verification, fallback logic, singleton verification, or error state handling)

---

## Recommended Action Plan

| Phase | Focus | Est. effort |
|-------|-------|-------------|
| **Phase 1** | Cri de cœur: delete `temp_should_delete_test.dart`, remove stale l10n version, fix mutual import (M2), consolidate planner_data.dart (m4), fix file placements (m5) | 2–4 h |
| **Phase 2** | High-impact MAJOR: split adapters file (M4), add missing Hive adapters (M6), consolidate overlay session models (M5) — these unblock data correctness | 4–8 h |
| **Phase 3** | Architectural MAJOR: extract feature logic from core/services/ (M1), extract interfaces, add domain layer — largest effort but highest payoff for testability | 3–5 days |
| **Phase 4** | De-dup: consolidate 7 duplicate repository providers (m2), extract shared UI utilities (m10), standardize error handling (m9) | 1–2 days |
| **Phase 5** | Quality pass: fix all hardcoded values (m6), fix log levels (m8), fix imports (m12), resolve stale TODO (m13), add missing provider tests (m14) | 1 day |
| **Phase 6** | SRP refactor: break up the 6 largest screen files (m1) — monitor-driven, can be done incrementally | 2–4 days |
