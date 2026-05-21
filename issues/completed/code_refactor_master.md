# Code Refactor Master: Technical Debt & Quality Audit

**Date**: 2026-05-20
**Scope**: `lib/` (excluding `l10n/generated/`), `test/`, `pubspec.yaml`, `AGENTS.md`
**Method**: Static analysis via grep, glob, manual read, dependency graph mapping, convention audit against `AGENTS.md`

---

## BLOCKER

*None identified.* No production code paths cause outright crashes or prevent the user from proceeding. However, the MAJOR items below represent latent risks that could escalate under edge conditions (e.g., onboarding silently bailing out, circular imports causing runtime failures in certain widget tree builds).

---

## MAJOR

### M1. Circular Dependencies Between Features (3 cycles)

Three feature-level circular import cycles exist. These violate the architectural principle that features should form a DAG.

| Cycle | Path |
|---|---|
| **teaching ↔ lessons** | `teaching/services/tutor_service.dart` → `features/lessons/...` AND `lessons/providers/lesson_providers.dart` → `features/teaching/data/repositories/tutor_session_repository.dart` |
| **ingestion ↔ questions** | `ingestion/services/content_pipeline.dart` → `features/questions/...` AND `questions/providers/question_providers.dart` → `features/ingestion/data/repositories/source_repository.dart` |
| **subjects ↔ practice + lessons** | `subjects/presentation/widgets/subject_topics_tab.dart` → `features/practice/...`, `practice/data/repositories/...` → `features/subjects/...`, `subjects/presentation/widgets/subject_lessons_tab.dart` → `features/lessons/...`, `lessons/presentation/topic_list_screen.dart` → `features/subjects/...` |

**Rationale**: Circular imports make it impossible to extract any feature as a standalone package. They also create fragile widget-tree build orders where hot-reload can fail depending on import resolution order.

**Acceptance criteria**:
- Each cycle is broken by extracting shared models into `core/data/models/` or creating a shared `core/features_api/` layer.
- `dart analyze` passes without cycle-related warnings.
- Feature-feature imports are unidirectional.

---

### M2. Monolithic Screen Files (28 files > 500 lines, worst > 1,900 lines)

**Affected files** (top offenders by line count):

| File | Lines |
|---|---|
| `lib/features/settings/presentation/settings_screen.dart` | **1,987** |
| `lib/features/planner/presentation/planner_screen.dart` | **1,584** |
| `lib/features/mentor/presentation/mentor_screen.dart` | **1,413** |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | **1,374** |
| `lib/features/practice/presentation/screens/practice_screen.dart` | **1,257** |
| `lib/features/teaching/presentation/tutor_screen.dart` | **1,170** |
| `lib/features/planner/services/personal_learning_plan_service.dart` | **1,065** |
| `lib/main.dart` | **790** |

The `dashboard_screen.dart` `build()` method alone spans **425 lines**. The `settings_screen.dart` `_exportBackup()` method spans **238 lines**.

**Rationale**: Files > 500 lines violate the single-responsibility principle, are hard to review, and cause merge conflicts. 425-line build methods intermix layout, business logic, and state reads.

**Acceptance criteria**:
- No file in `lib/` exceeds 500 lines (excl. generated code and data seed files).
- Build methods > 80 lines are decomposed into private widget methods or extracted widgets.
- Long service methods (> 60 lines) are decomposed.

---

### M3. Empty `catch` Block in `onboarding_dialog.dart` (Misleading Comment)

**File**: `lib/features/onboarding/presentation/onboarding_dialog.dart:40-42`
```dart
} catch (e) {
  // Log the error but don't silently convert to completed
}
```

**Rationale**: The comment explicitly claims the error is logged, but no `Logger` call exists. This is both a violation of `AGENTS.md` ("Every catch must log the error with a descriptive message") and a bug — if the onboarding `markDontShowAgain()` or `markCompleted()` call fails, the dialog disappears silently and the user is stuck in a partially-onboarded state.

**Acceptance criteria**:
- Add `_logger.w('Failed to complete onboarding', e);` (with `_logger` declared as `static final Logger`).
- OR if silent skipping is intentional, replace the comment with a rationale and add logging.

---

### M4. Core Providers Importing Features (Inverted Dependency)

**Affected files**:

| Core file | Features imported |
|---|---|
| `lib/core/providers/app_providers.dart` | practice, planner, mentor, dashboard |
| `lib/core/providers/shared_providers.dart` | lessons, questions, settings, subjects, teaching |
| `lib/core/providers/study_progress_provider.dart` | practice, sessions |

**Rationale**: The `core/` layer should be the foundation that features build upon, not the other way around. Core → feature imports mean (a) `core/` cannot be tested in isolation, (b) any change in a feature provider can ripple-bust all core provider tests, and (c) the dependency graph is a tangled web, not a layered architecture.

**Acceptance criteria**:
- Core providers either (a) use interfaces/abstract classes defined in `core/` with feature implementations injected via Riverpod overrides at the app level, or (b) feature-specific providers live in the feature layer and are only referenced by other features through riverpod overrides + shared abstract interfaces.
- Zero `import 'features/...'` statements in `lib/core/` files, except for legitimate cross-cutting config.

---

### M5. Deprecated Methods in Active Use Without `@Deprecated()` Annotation

| File | Method | Doc says | Used at |
|---|---|---|---|
| `lib/features/practice/services/spaced_repetition_service.dart:122` | `_masteryLevelToGrade` | "Deprecated: binary masteryLevel (0.8/0.2) loses confidence nuance" | Line 100 (same file) |
| `lib/features/practice/services/practice_session_service.dart:50` | `updateNextReview` | "Deprecated: MasteryRecorder.recordAttempt is the single source of truth" | Callers still using it |
| `lib/core/data/models/question_mastery_state_model.dart:209` | `_calculateNextReview` | "Deprecated: SM-2 nextReview from MasteryRecorder is the single source of truth" | Internal fallback |

**Rationale**: Deprecated code without annotation or migration warning is dead code walking. It wastes maintenance effort and can mislead new developers into using the wrong API.

**Acceptance criteria**:
- Add `@Deprecated('Use <replacement> instead')` annotation, OR remove the method entirely if no production callers remain.
- Doc comment deprecations without annotation are removed or promoted to real annotations.

---

### M6. Class Name / File Name Mismatch

**File**: `lib/features/lessons/services/lesson_service.dart`
**Class**: `SessionQueryService`

**Rationale**: Dart convention (and `AGENTS.md` implicit expectation) is that file names match the primary class name. A developer looking for `SessionQueryService` will not find it by filename, and the file `lesson_service.dart` suggests the class inside is `LessonService`.

**Acceptance criteria**:
- Rename to `lib/features/lessons/services/session_query_service.dart`, OR rename the class to `LessonService` (if that better fits).

---

### M7. Unused Barrel File `core/data/data.dart`

**File**: `lib/core/data/data.dart`
**Production imports**: 0
**Test imports**: 1 (`test/core/data/data_test.dart`)

Exports 11 files, none of which are imported through this barrel in production code.

**Rationale**: Violates `AGENTS.md` barrel convention: "Do not create barrel files unless they are imported by production code." Unnecessary barrel file creates confusion about the intended public API surface of `core/data/`.

**Acceptance criteria**:
- Remove `data.dart`, OR make it the canonical import path for at least one production file.

---

### M8. Public Methods Returning Raw Types Instead of `Result<T>`

| File | Method | Return type | Convention violation |
|---|---|---|---|
| `lib/features/mentor/services/mentor_service.dart:366` | `checkWellbeingAndGenerateNudges()` | `Future<List<String>>` | Should be `Future<Result<List<String>>>` |
| `lib/core/services/llm/llm_model_service.dart:124` | `fetchAvailableModels()` | `Future<List<AiModel>>` | Returns `[]` on error instead of `Result.failure` |

**Rationale**: `AGENTS.md` states "Public repository and service method return types must be `Result<T>`." Inconsistent return types force callers to handle both `Result`-wrapped and raw-throwing APIs differently, increasing cognitive load and making error paths harder to audit.

**Acceptance criteria**:
- Both methods return `Result<T>`.
- Callers updated to check `.isSuccess`/`.isFailure`.

---

### M9. Cross-Feature Widget Imports (Leaky Abstractions)

18+ instances where a feature imports another feature's presentation widgets or data models directly rather than through a shared API. Examples:

| Source | Target | Leaked internals |
|---|---|---|
| `practice` | `questions` | `presentation/widgets/single_answer_widget.dart`, `canvas_drawing_widget.dart`, etc. |
| `focus_mode` | `practice` | `presentation/widgets/practice_session_question_card.dart` |
| `mentor` | `teaching` | `presentation/widgets/chat_bubble.dart` |
| `quickguide` | `teaching` | `presentation/widgets/chat_bubble.dart` |
| `teaching` | `lessons` | `presentation/widgets/lesson_block_card.dart` |
| `dashboard` | `planner` | `presentation/widgets/syllabus_progress_card.dart` |
| `subjects` | `lessons` | `data/models/lesson_model.dart`, `data/repositories/lesson_repository.dart` |

**Rationale**: Direct widget imports create tight coupling. Changing a widget's signature in feature A can break feature B silently. The conventional fix is to extract shared widgets into `core/widgets/` or define them as pure function parameters.

**Acceptance criteria**:
- Shared widgets are extracted to `lib/core/widgets/` or `lib/shared_widgets/`.
- Features only import other features via their providers (state) or defined API classes, never via `/presentation/widgets/` or `/data/models/` paths.

---

## MINOR

### m1. Magic Numbers in Business Logic (25+ occurrences)

**Files**:
- `lib/core/services/mastery_calculation_service.dart` — 20+ magic numbers (0.9, 5, 10, 0.8, 0.6, 3, 1.0, 0.7, 0.5, 0.3, 0.1, 0.4, 0.2, 0.2, 0.2, etc.)
- `lib/features/mentor/services/mentor_wellbeing_service.dart` — 5+ (5, 3, 7, 48, 30, 14, 7)
- `lib/core/utils/study_utils.dart` — 10+ (0.6, 0.4, 1.5, 0.5, 0.8, 0.9, 7, 15, 30.0, 10, 30)
- `lib/core/services/engagement_scheduler.dart` — 4+ (5 minutes, 24 hours, 30 minutes)

**Acceptance criteria**:
- All magic numbers are extracted to `static const` fields with descriptive names (e.g., `static const double _masteryExcellentThreshold = 0.9;`).
- Time-based magic numbers use `Duration` constants, not raw integers.

### m2. Logger Convention Violations

| File | Line | Issue |
|---|---|---|
| `lib/core/errors/handlers.dart` | 9 | `static Logger logger` — not `final` (reassignable, violated the `static final` convention) |
| `lib/features/settings/presentation/settings_screen.dart` | 1743 | `final log = const Logger('SettingsScreen');` — local variable, not `static final` class field |

**Acceptance criteria**:
- `handlers.dart` Logger is `static final` (if test reassignment is needed, use a `@visibleForTesting static setter`).
- `settings_screen.dart` Logger at line 1743 is replaced with the existing `_logger` at line 73, or removed.

### m3. Duplicate Logger Tag

**File**: `lib/features/subjects/presentation/subject_detail_screen.dart`
**Lines 41 and 440**: Both `_SubjectDetailScreenState` and `_SubjectSourcesTabState` use tag `'SubjectDetailScreen'`.

**Rationale**: Log output cannot distinguish which inner class produced the message, making debugging harder.

**Acceptance criteria**: The second class uses a distinct tag (e.g., `'SubjectDetailScreen.SubjectSourcesTab'`).

### m4. TODO — Acknowledged Duplicate Nudge Logic

**File**: `lib/core/services/engagement_scheduler.dart:45`
```dart
// TODO: Unify overwork/revision nudge logic with MentorWellbeingService.
```

Both `EngagementScheduler` and `MentorWellbeingService` independently check overwork and revision conditions and create `EngagementNudgeModel` entries, potentially generating duplicate nudges.

**Acceptance criteria**:
- Nudge generation logic extracted into a single `WellbeingOrchestrator` (in `core/services/`) used by both `EngagementScheduler` and `MentorWellbeingService`.
- TODO comment removed after implementation.

### m5. Hardcoded API URLs (YouTube)

**File**: `lib/core/constants/app_api_config.dart`
```dart
'https://youtubetranscript.com'
'https://youtubetranscript.com/api/transcript'
'https://www.googleapis.com/youtube/v3'
```

These URLs are hardcoded with no `.env` fallback. If the upstream API changes endpoints or if a self-hosted alternative is desired, the code must be edited.

**Acceptance criteria**:
- Each URL has a corresponding `String? get youtubeTranscriptBaseUrl => ...` that reads from `Platform.environment` or `.env` first, falling back to the compiled default.

### m6. `Result.failure()` Carries Only String — No Structured Error

`Result.failure(String?)` passes `e.toString()` only — no `ExceptionType`, no error code, no stack trace. This means:
- Callers must string-match to distinguish error types (brittle).
- No mechanism to propagate structured error info from `Result` failures to the UI.

**Acceptance criteria** (`Option A — minimal`):
- Add optional `ExceptionType?` and `StackTrace?` fields to `FailureResult`.
- Update `Result.capture()` and all `Result.failure()` calls to optionally include them.

**Acceptance criteria** (`Option B — full`):
- Replace `String?` error payload with a sealed `AppError` class that wraps type + message + code + stackTrace.

### m7. `AppErrorHandler` Low Adoption

Only 5 screen files use `AppErrorHandler.handleError()` or `AppErrorHandler.safely()`:
- `lesson_detail_screen.dart`, `practice_screen.dart`, `practice_session_screen.dart`, `lesson_list_screen.dart`, `topic_list_screen.dart`

The other 20+ screen files handle errors ad-hoc (direct SnackBar calls, silent logging, or inline try/catch with no user feedback).

**Acceptance criteria**:
- All screen-level async operations use `AppErrorHandler.safely()` or `AppErrorHandler.handleError()` for consistent error UX.

### m8. `catch (_)` Without Logging (6 locations)

| File | Line |
|---|---|
| `lib/features/settings/services/data_backup_service.dart` | 37 |
| `lib/features/teaching/data/models/conversation_message_model.dart` | 72 |
| `lib/features/subjects/presentation/widgets/subject_stats_tab.dart` | 71 |

These `catch (_) { return ...; }` blocks are not truly empty (they return fallback values), but they violate the spirit of the convention requiring every catch to log.

**Acceptance criteria**: Add `_logger.w('...', e)` before the return/fallback in each.

### m9. Files Over 500 Lines (28 files)

Complete list (excl. `l10n/generated/`):

| File | Lines |
|---|---|
| `lib/features/settings/presentation/settings_screen.dart` | 1,987 |
| `lib/features/planner/presentation/planner_screen.dart` | 1,584 |
| `lib/features/mentor/presentation/mentor_screen.dart` | 1,413 |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 1,374 |
| `lib/features/practice/presentation/screens/practice_screen.dart` | 1,257 |
| `lib/features/teaching/presentation/tutor_screen.dart` | 1,170 |
| `lib/features/planner/services/personal_learning_plan_service.dart` | 1,065 |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 938 |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 887 |
| `lib/features/questions/presentation/question_bank_screen.dart` | 859 |
| `lib/features/ingestion/presentation/upload_screen.dart` | 848 |
| `lib/core/services/llm/llm_chat_service.dart` | 812 |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 807 |
| `lib/main.dart` | 790 |
| `lib/features/ingestion/services/content_pipeline.dart` | 726 |
| `lib/features/settings/presentation/api_config_screen.dart` | 724 |
| `lib/features/sessions/presentation/session_history_screen.dart` | 714 |
| `lib/features/ingestion/presentation/source_detail_screen.dart` | 706 |
| `lib/features/planner/providers/planner_providers.dart` | 693 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 650 |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 618 |
| `lib/features/settings/presentation/profile_screen.dart` | 617 |
| `lib/features/teaching/services/tutor_service.dart` | 614 |
| `lib/features/ingestion/services/document_extractor.dart` | 609 |
| `lib/features/ingestion/presentation/content_library_screen.dart` | 607 |
| `lib/features/planner/services/planner_service.dart` | 586 |
| `lib/features/subjects/data/curriculum_seed_data.dart` | 545 |
| `lib/features/lessons/presentation/widgets/lesson_block_card.dart` | 504 |

Target: reduce to 0 files over 500 lines (see M2 acceptance criteria).

### m10. Hardcoded Duration Values

Scattered across the codebase rather than using centralized `Duration` constants:

| File | Values |
|---|---|
| `lib/core/services/engagement_scheduler.dart` | `Duration(minutes: 5)`, `Duration(hours: 24)`, `diff.inMinutes <= 30` |
| `lib/core/services/llm/llm_chat_service.dart` | `Duration(milliseconds: 500)`, `Duration(milliseconds: 200)`, `Duration(seconds: 1)` |
| `lib/core/widgets/conversation_input.dart` | `Duration(milliseconds: 100)` |

**Acceptance criteria**: Extract to `lib/core/constants/timeouts.dart` (where some duration constants already exist — consolidate).

---

## Summary Table

| ID | Severity | Category | Count / Scope |
|---|---|---|---|
| M1 | MAJOR | Architecture | 3 circular dependency cycles |
| M2 | MAJOR | Maintainability | 28 files > 500 lines |
| M3 | MAJOR | Bug risk | 1 empty catch (no logging) |
| M4 | MAJOR | Architecture | 3 core files → 7+ features |
| M5 | MAJOR | Tech debt | 3 deprecated methods without annotation |
| M6 | MAJOR | Convention | 1 file/class name mismatch |
| M7 | MAJOR | Convention | 1 unused barrel file |
| M8 | MAJOR | Convention | 2 public methods not returning `Result<T>` |
| M9 | MAJOR | Architecture | 18+ cross-feature widget imports |
| m1 | MINOR | Readability | 25+ magic numbers |
| m2 | MINOR | Convention | 2 Logger convention violations |
| m3 | MINOR | Debugging | 1 duplicate Logger tag |
| m4 | MINOR | Tech debt | 1 acknowledged TODO (duplicate logic) |
| m5 | MINOR | Configurability | 3 hardcoded API URLs |
| m6 | MINOR | Error handling | `Result.failure` lacks structured error type |
| m7 | MINOR | Consistency | `AppErrorHandler` used in only 5/25+ screens |
| m8 | MINOR | Convention | 6 catch blocks without logging |
| m9 | MINOR | Maintainability | 28 files > 500 lines |
| m10 | MINOR | Configurability | 4+ hardcoded Duration values |
