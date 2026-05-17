# Codebase Health & Refactor Audit

**Generated:** 2026-05-17  
**Audit scope:** `lib/` — 58K+ lines across 12 feature modules + core  
**Methodology:** Static analysis (`dart analyze`), cross-reference import graph, manual review of top-30 largest files, log-level audit, error-handling pattern audit.

---

## BLOCKER: Systemic `Result<T>` misuse — error handling is completely broken

**Severity:** BLOCKER — app crashes, data loss, and silent failures are guaranteed at runtime.

**Root cause:** `Repository<T>.get()` in `core/data/repository.dart` returns `Future<Result<T?>>`, but every single caller treats the return value as `T?` directly (bypassing the `Result` wrapper). This means:
1. All `if (x == null)` checks after a `get()` call are **always false** — the result is a `Result` object (non-null), never `null`. Dead branches everywhere.
2. All error paths (`Result.failure`) are **silently ignored** — the `Result` object is treated as a successful value, so failures never propagate.
3. All `.where()`, `.isEmpty`, `for..in` on `Result` objects would be compile-errors under strict analysis.

**Affected locations confirmed by `dart analyze`:**

| File | Lines | Issue |
|---|---|---|
| `lib/features/practice/data/repositories/mastery_state_repository.dart` | 26–29 | `Result<MasteryState?>` used as `MasteryState` — null check always true |
| `lib/features/lessons/data/repositories/lesson_repository.dart` | 62, 65–66, 77, 80, 91 | `Result<Lesson?>` used as `Lesson?` — null checks dead |
| `lib/features/planner/services/planner_service.dart` | 344 | `Result<PendingActionModel?>` used as `PendingActionModel?` |
| `lib/features/practice/services/mastery_recorder.dart` | 46, 54, 87 | `Result<Question?>` used as `Question` |
| `lib/features/practice/services/mistake_review_service.dart` | 57, 60–63, 101, 104–107 | `Result<Question?>` — null checks dead |
| `lib/features/practice/services/spaced_repetition_service.dart` | 113, 118, 126, 180, 184–185 | `Result<Question?>` / `Result<StudentAttempt?>` |
| `lib/core/services/cross_feature_integrator.dart` | 172–176, 187–191 | `Result<Source?>` used as `Source?` — null checks dead |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 517 | `Future<Result<List>>>` passed as `Future<List>` |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 267–268 | `Result<Subject?>` used as `Subject?` |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | 53, 56 | `Result<Lesson?>` used as `Lesson?` |
| `lib/features/lessons/presentation/topic_list_screen.dart` | 30, 33 | `Result<List<Topic>>` used as `List<Topic>` |
| `lib/features/lessons/services/lesson_service.dart` | 29–31 | `Result` passed to `.add()` |
| `lib/features/planner/services/syllabus_resolver.dart` | 122–145 | `Result<List<Question>>` used as `List<Question>` |
| `lib/features/mentor/services/mentor_service.dart` | 454–457, 586 | `Result` used as `List` |
| `lib/features/practice/presentation/screens/practice_screen.dart` | 120, 135, 186, 193, 273, 303, 346 | `Result<List<Question>>` used as `List<Question>` |
| `lib/features/practice/services/practice_data_service.dart` | 28, 47, 49, 62, 83 | `Result` used as `List` |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | 99, 139, 173 | `Result<List>` used in `for..in` |
| `lib/features/dashboard/services/dashboard_service.dart` | 107 | `Result<List<Topic>>` used in `for..in` |
| `lib/features/ingestion/presentation/upload_screen.dart` | 64, 67 | `Result<List<Subject>>` assigned to `List<Subject>` |
| `lib/features/ingestion/services/content_pipeline.dart` | 274–278 | `Result<List<Topic>>` used as `List<Topic>` |
| `lib/features/subjects/presentation/subject_list_screen.dart` | 46 | `Result` from provider → `Future<List>` |
| `lib/features/subjects/presentation/widgets/subject_lessons_tab.dart` | 29 | `Result` used with `.where()` |
| `lib/core/services/personal_learning_plan_service.dart` | 399, 723, 755 | `Result` used with `.where()`, `.title`, `.subjectId` |

**Acceptance criteria:**
- Every `Repository.get()` caller explicitly handles both `Result.success` and `Result.failure` branches.
- `Result.failure` cases are logged at error level and produce user-visible fallback states (not silent swallows).
- All dead null-check branches are removed.
- `dart analyze` produces zero warnings related to `Result` type mismatch.

---

## BLOCKER: `planner` ↔ `sessions` circular dependency

**Severity:** BLOCKER — creates fragile compile-time coupling; refactoring either feature breaks the other.

**Cycle chain:**
- `planner_service.dart:10` → `sessions/data/repositories/session_repository.dart`
- `session_tracker_screen.dart:13,18` → `planner/data/repositories/plan_adherence_repository.dart` and `plan_repository.dart`

**Acceptance criteria:**
- Extract the shared concern (plan adherence data for session tracking) into a `core` adapter/contract.
- Neither `planner` nor `sessions` imports directly from the other's internal files.
- Only `core` or a shared `adapters/` module bridges the two.

---

## MAJOR: Core layer violates dependency inversion — 19 files import features

**Severity:** MAJOR — features cannot be extracted, tested, or reasoned about independently.

**The rule:** `core/` must not import from `features/`. Yet 19 files in `core/` do so:

| Core file | Feature imports |
|---|---|
| `core/routes/app_router.dart` | 13 features (acceptable for routing) |
| `core/providers/app_providers.dart` | 8 features |
| `core/services/personal_learning_plan_service.dart` | 4 features (practice, subjects, planner, questions) |
| `core/services/mastery_graph_service.dart` | 2 features (practice, questions) |
| `core/data/database_service.dart` | 6 features |
| `core/data/hive_initializer.dart` | 6 features |
| `core/services/engagement_scheduler.dart` | 3 features |
| `core/services/instrumentation_service.dart` | 2 features |
| `core/services/progress_export_service.dart` | 2 features |
| `core/services/study_progress_tracker.dart` | 2 features |
| `core/services/topic_readiness_service.dart` | 2 features |
| `core/services/badge_service.dart` | 2 features |
| `core/services/answer_validation_service.dart` | 1 feature |
| `core/services/cross_feature_integrator.dart` | 2 features |
| `core/services/mastery_integration_service.dart` | 1 feature |
| `core/services/plan_adapter.dart` | 1 feature |
| `core/services/conversation_memory.dart` | 1 feature |
| `core/services/llm_usage_meter.dart` | 1 feature |

**Acceptance criteria:**
- `core/services/` that depend on feature internals are moved into the owning feature or have their dependencies inverted (features implement contracts defined in `core/contracts/`).
- `core/data/` (database_service, hive_initializer) use registration, not direct imports, to discover feature repositories.
- `core/services/personal_learning_plan_service.dart` is the highest-priority extraction candidate.

---

## MAJOR: 14 dead code branches from `Result` misuse

**Severity:** MAJOR — error-handling fallback code is dead; bugs hidden under always-true null checks.

**Locations:**
| File | Lines | Description |
|---|---|---|
| `lib/core/services/cross_feature_integrator.dart` | 172–176 | `source == null` always false |
| `lib/core/services/cross_feature_integrator.dart` | 187–191 | Same pattern |
| `lib/features/lessons/data/repositories/lesson_repository.dart` | 62–64 | `lesson == null` always false |
| `lib/features/lessons/data/repositories/lesson_repository.dart` | 77–79 | Same pattern |
| `lib/features/planner/services/planner_service.dart` | 344 | `action == null` always false |
| `lib/features/practice/services/mastery_recorder.dart` | 46–48 | `question == null` always false |
| `lib/features/practice/services/mistake_review_service.dart` | 57–58 | `question == null` always false |
| `lib/features/practice/services/mistake_review_service.dart` | 101–102 | Same pattern |
| `lib/features/practice/services/spaced_repetition_service.dart` | 113–115 | `question == null` always false |
| `lib/features/practice/services/spaced_repetition_service.dart` | 180–182 | `attempt == null` always false |
| `lib/features/practice/data/repositories/mastery_state_repository.dart` | 26 | `state != null` always true |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 268 | `subject == null` always false |
| `lib/features/subjects/data/repositories/progress_repository.dart` | 17–22 | `progress == null` always false |

**Acceptance criteria:**
- Every dead branch is removed or rewritten with proper `Result` unwrapping.
- Null-check patterns are migrated to `result.when(success: ..., failure: ...)` or `result.fold(...)`.

---

## MAJOR: Wrong log levels — ~70 catch blocks use `.w()` instead of `.e()`

**Severity:** MAJOR — production monitoring cannot distinguish warnings from actual errors.

Every caught exception in these files logs at **warning** level instead of **error**:

| File | Lines | Count |
|---|---|---|
| `lib/features/sessions/data/repositories/session_repository.dart` | 24, 34, 45, 60, 70, 80, 90, 103, 118, 130, 140, 150, 160, 172, 184, 195, 208, 232, 254 | 19 |
| `lib/core/services/engagement_scheduler.dart` | 149, 176, 206, 232, 248, 268, 279, 292, 342 | 9 |
| `lib/features/mentor/services/mentor_service.dart` | 241, 250, 259, 268, 277, 286, 311, 338, 416, 509, 543, 558 | 12 |
| `lib/core/services/study_progress_tracker.dart` | 221, 241, 261, 274 | 4 |
| `lib/core/services/cross_feature_integrator.dart` | 79, 93, 174, 189 | 4 |
| `lib/core/data/extraction/transcription_extractor.dart` | 44 | 1 |
| `lib/core/data/extraction/ocr_extractor.dart` | 36, 162 | 2 |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | 142, 210 | 2 |
| `lib/features/teaching/services/conversation_manager.dart` | 86 | 1 |
| `lib/features/practice/services/mastery_recorder.dart` | 84 | 1 |

**Acceptance criteria:**
- All caught exceptions in repository/service/utility files use `logger.e()` (not `.w()`).
- `logger.w()` is reserved for recoverable business-logic warnings (e.g., "rate limit approaching").
- `logger.e()` always includes the exception object and a stack trace.

---

## MAJOR: ~100+ line `build()` methods violate SRP

**Severity:** MAJOR — difficult to test, reason about, or modify without side effects.

| File | Lines | Method | Lines in method |
|---|---|---|---|
| `lib/features/ingestion/presentation/upload_screen.dart` | 339–633 | `build()` | 295 |
| `lib/features/settings/presentation/profile_screen.dart` | 271–485 | `build()` | 215 |
| `lib/features/settings/presentation/settings_screen.dart` | 55–249 | `build()` | 195 |
| `lib/features/mentor/presentation/mentor_screen.dart` | 380–566 | `_showProgressReport()` | 187 |
| `lib/features/sessions/presentation/session_history_screen.dart` | 248–428 | `build()` | 181 |
| `lib/features/planner/presentation/planner_screen.dart` | 312–456 | `_buildStudyPlanTab()` | 145 |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | 418–565 | `build()` | 148 |
| `lib/core/services/personal_learning_plan_service.dart` | 94–226 | `_buildPlan()` | 133 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 230–380 | `build()` | 151 |
| `lib/features/ingestion/services/content_pipeline.dart` | 85–226 | `processFullPipeline()` | 142 |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | 292–414 | `build()` | 123 |
| `lib/core/services/progress_export_service.dart` | 124–313 | `exportComprehensivePDF()` | 190 |
| `lib/core/services/personal_learning_plan_service.dart` | 577–698 | `_generateDailyPlans()` | 122 |
| `lib/features/planner/providers/planner_providers.dart` | 58–137 | `planProgressProvider` | 80 |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 406–509 | `_buildSetupView()` | 104 |

**Acceptance criteria:**
- Every `build()` method exceeding 100 lines extracts at least 3 focused widget methods or separate `StatelessWidget` classes.
- `personal_learning_plan_service.dart` `_buildPlan()` is decomposed into orchestrated steps (`_prepareData`, `_buildRecommendations`, `_resolveSyllabus`, `_generatePlanStructure`, `_finalizePlan`).
- `content_pipeline.dart` `processFullPipeline()` extracts each pipeline stage as a separate method.

---

## MAJOR: `SessionRepository` duplicates `Repository<T>` instead of extending it

**Severity:** MAJOR — 257 lines of repetitive boilerplate that `PlanAdherenceRepository` (73 lines) does correctly.

**File:** `lib/features/sessions/data/repositories/session_repository.dart`

The class manually reimplements `save`, `get`, `getAll`, `delete`, `clearAll` — all identical to the generic `Repository<T>` base class in `core/data/repository.dart`. It does NOT extend `Repository<Session>`.

**Acceptance criteria:**
- `SessionRepository` extends `Repository<Session>` and inherits CRUD operations.
- Only custom query methods (`getByType`, `getBySubject`, `getActive`, etc.) remain implemented.
- File size drops from ~257 lines to ~100 lines.

---

## MAJOR: 3 entire extension files are completely dead code

**Severity:** MAJOR — 60+ lines of dead code that mislead developers about available utilities.

| File | Content | Status |
|---|---|---|
| `lib/core/extensions/build_context_extensions.dart` | `.theme`, `.colorScheme`, `.textTheme`, `.l10n` on `BuildContext` | **Never imported anywhere** |
| `lib/core/extensions/string_extensions.dart` | `.isBlank`, `.capitalize()`, `.truncate()`, etc. on `String` | **Never imported anywhere** |
| `lib/core/extensions/iterable_extensions.dart` | `.firstOrNull` on `Iterable` | **Never imported** + **redundant** (Dart 3.x built-in) |
| `lib/core/core.dart` | Barrel re-exporting the above | **Never imported anywhere** |

**Acceptance criteria:**
- Dead extension files are removed (or resurrected by importing and using them across the codebase).
- `lib/core/core.dart` barrel is removed.

---

## MAJOR: `SettingsRepository.updateSettings()` — 22 fields repeated 3x each

**Severity:** MAJOR — ~90 lines of fragile boilerplate; adding a field requires touching 3 locations.

**File:** `lib/features/settings/data/repositories/settings_repository.dart`

`updateSettings()` (152–241) repeats all 22 field names in `SettingsBox(...)` constructor AND `box.put(...)`. `updateStats()` (244–272) repeats them all again. `getSettings()` (112–149) repeats all `box.get(...)` with defaults.

**Acceptance criteria:**
- `SettingsBox` has `toJson()`/`fromJson()` methods.
- `updateSettings` calls `box.put('settings', settings.toJson())`.
- `getSettings` calls `SettingsBox.fromJson(box.get('settings', defaultValue: {}))`.
- Files that previously read 22 individual fields now read one JSON blob.

---

## MAJOR: 14 silent catch blocks swallow errors completely

**Severity:** MAJOR — production failures are invisible; debugging requires source-code inspection.

| File | Line | Code |
|---|---|---|
| `lib/core/services/llm/llm_chat_service.dart` | 230 | `catch (_) {}` — malformed SSE silently skipped |
| `lib/core/services/llm/llm_chat_service.dart` | 335 | `catch (_) {}` — same pattern |
| `lib/core/services/llm/llm_chat_service.dart` | 441 | `catch (_) {}` — same pattern |
| `lib/features/settings/presentation/settings_screen.dart` | 482 | `catch (_) {}` — daily cap dialog failure |
| `lib/features/subjects/presentation/subject_detail_screen.dart` | 274 | `catch (_) {}` |
| `lib/features/ingestion/presentation/upload_screen.dart` | 70 | `catch (_) {}` |
| `lib/features/sessions/services/study_timer_service.dart` | 185 | `catch (_) {}` — notification failure |
| `lib/core/data/extraction/transcription_extractor.dart` | 229, 236 | `catch (_) {}` — YouTube transcript parse failure |
| `lib/core/data/extraction/pdf_extractor.dart` | 67 | `catch (_) {}` — PDF cleaning failure |
| `lib/features/ingestion/services/document_extractor.dart` | 107 | `catch (_) {}` |
| `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` | 73 | `catch (_) {}` |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 93 | `catch (_) {}` |

**Acceptance criteria:**
- Every `catch (_) {}` either logs the error AND shows user feedback, or is replaced by a specific catch (e.g., `catch (FormatException e)`).
- Greenfield rule: no empty catch blocks.

---

## MINOR: Unused deprecated classes

| File | Class | Deprecation notice |
|---|---|---|
| `lib/core/services/mastery_integration_service.dart` | `MasteryIntegrationService` | `@Deprecated('Use MasteryGraphService directly')` — never imported |
| `lib/features/subjects/data/repositories/progress_repository.dart` | `ProgressRepository` | `@Deprecated('Use MasteryStateRepository instead')` — never imported |
| `lib/features/subjects/data/models/topic_progress_model.dart` | `TopicProgress` | `@Deprecated('Use MasteryState...')` — only imported by dead repo above |

**Acceptance criteria:** Remove or replace all usages before removal.

---

## MINOR: Unused imports

- `lib/core/services/llm/llm_chat_service.dart:3` — `import 'package:flutter/material.dart'`
- `lib/core/services/llm/llm_chat_service.dart:5` — `import 'package:studyking/l10n/generated/app_localizations.dart'`

**Acceptance criteria:** Remove unused imports; `dart analyze` shows zero `unused_import` warnings.

---

## MINOR: `LLMChatService` has 6 near-duplicate streaming/call implementations

**File:** `lib/core/services/llm/llm_chat_service.dart`

The class has 3 near-identical streaming methods (`_streamOpenRouter` 178–245, `_streamOllama` 291–349, `_streamOpenAI` 390–456) and 3 near-identical non-streaming methods (`_callOpenRouter`, `_callOllama`, `_callOpenAI`). Only URL construction and response parsing differ.

**Acceptance criteria:**
- Extract a single parameterized streaming core that accepts URL, headers, body, and response parser.
- Provider-specific configuration is injected via strategy/function parameter.
- Lines of code reduced by ~40%.

---

## MINOR: God classes with 15+ methods

| File | Class | Methods | Responsibilities mixed |
|---|---|---|---|
| `lib/features/settings/presentation/settings_screen.dart` | `_SettingsScreenState` | ~19 | Theme, font, AI model, timeout, daily cap, reminder, break, analytics, backup, export/import, sign-out |
| `lib/features/practice/presentation/screens/practice_session_screen.dart` | `_PracticeSessionScreenState` | ~16 | Question loading, answer submission, navigation, mistake review, adherence, confidence |
| `lib/features/practice/presentation/screens/practice_screen.dart` | `_PracticeScreenState` | ~17 | Subject listing, due counts, 6 practice modes, subject selection, loading |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | `_ExamSessionScreenState` | ~17 | Config, timer, auto-submit, results, mistake review |
| `lib/features/planner/presentation/planner_screen.dart` | `_PlannerScreenState` | ~15 | Tabs, plan gen, roadmaps, milestones, lesson scheduling, adherence |

**Acceptance criteria:**
- Each god class is split into composable focused widgets or mixins.
- `practice_session_screen.dart` and `exam_session_screen.dart` share a common session mixin/service.

---

## MINOR: `Clock` abstract class is dead code

**File:** `lib/core/utils/clock.dart`

```dart
abstract class Clock { DateTime now(); }
class SystemClock implements Clock { @override DateTime now() => DateTime.now(); }
```

Never imported anywhere. Dead abstraction.

**Acceptance criteria:** Remove the file and all references (there are none).

---

## MINOR: `MentorService.mentor_service.dart` and `TutorScreen` duplicate identical patterns

| Pattern | Files | Lines |
|---|---|---|
| `_buildInitErrorCard` (same layout, retry + settings buttons) | `mentor_screen.dart:282–335`, `tutor_screen.dart:484–537` | Duplicated |
| `_scrollToBottom` (reduceMotion check + animate/jump) | `mentor_screen.dart:204–221`, `tutor_screen.dart:379–396` | Duplicated |

**Acceptance criteria:** Extract into a shared widget (`InitErrorCard`) and a shared mixin (`ChatScroller` or similar).

---

## MINOR: `OnboardingService` co-located in a widget file

**File:** `lib/features/onboarding/presentation/onboarding_dialog.dart`

Contains `OnboardingService` (Hive data-access logic) in the same file as `OnboardingDialog`, `ApiKeyBanner`, and `LocalDataNotice` — all in a `presentation/` folder.

**Acceptance criteria:** Extract `OnboardingService` into `lib/features/onboarding/services/onboarding_service.dart`.

---

## MINOR: Missing barrel file for `onboarding` feature

Every other feature has `<feature>.dart` barrel. `onboarding` does not.

**Acceptance criteria:** Create `lib/features/onboarding/onboarding.dart` and add it to `features/features.dart`.

---

## MINOR: Wrong-class DTOs stored in `data/models/`

- `lib/features/practice/data/models/practice_models.dart` — `PracticeAnswerRecord`, `PracticeSessionResult` are presentation-layer DTOs (no Hive annotations, no serialization), not data entities.
- `lib/features/practice/presentation/widgets/source_practice_sheet.dart:115–125` — `SourceItemData` is a model class defined in a widget file.

**Acceptance criteria:** Move presentation DTOs to `presentation/models/` or inline them where used.

---

## MINOR: `duplicate_markscheme_model.dart` re-export creates confusion

- Primary: `lib/core/data/models/markscheme_model.dart`
- Re-export: `lib/features/questions/data/models/markscheme_model.dart` (just re-exports core version)

**Acceptance criteria:** Remove the feature-level re-export file; all imports go through core directly.

---

## MINOR: `PersonalLearningPlanService` creates Logger inline per-call instead of class field

**File:** `lib/core/services/personal_learning_plan_service.dart`

Every error log creates `const Logger('PersonalLearningPlanService')` inline (lines 108, 185, 222, 314, 428, ... ~13 occurrences).

**Acceptance criteria:** Add `static final Logger _logger = const Logger('PersonalLearningPlanService');` and use it.

---

## MINOR: `Duration(minutes: 30)` hardcoded instead of using `Timeouts`

**File:** `lib/features/practice/services/spaced_repetition_service.dart:29`

```dart
final cutover = asOf.subtract(const Duration(minutes: 30));
```
Lines 17 and 37 in the same file correctly use `Timeouts.hour` and `Timeouts.fiveMinutes`.

**Acceptance criteria:** Extract `30 minutes` into `Timeouts` constants and reference it.

---

## MINOR: Hardcoded numeric defaults in `SettingsRepository`

**File:** `lib/features/settings/data/repositories/settings_repository.dart:119–147`

Hardcoded defaults: `fontSize: 16`, `requestTimeoutSeconds: 120`, `sessionDurationMinutes: 30`, `breakDurationSeconds: 300`, `dailyReminderHour: 9`.

**Acceptance criteria:** Extract to named constants (e.g., `static const _defaultFontSize = 16.0`).

---

## MINOR: `PlanGenerationConfig.restDayFrequency` defaults to `planDurationDays`, making rest days inert

**File:** `lib/core/services/personal_learning_plan_service.dart:38`

```dart
this.restDayFrequency = defaultPlanDurationDays, // 7
```

When `planDurationDays = 7`, `restDayFrequency = 7` means a rest day every 7 days in a 7-day plan — effectively zero rest days. This makes `restDayFrequency` redundant when `includeRestDays = false`.

**Acceptance criteria:** `restDayFrequency` should default to a sane independent value (e.g., 3 or 4), or should be explicitly required when `includeRestDays = true`.

---

## MINOR: Duplicate `showDialog`/`AlertDialog` pattern appears 30+ times

No shared helper for common dialog types (confirmation, error, info).

**Acceptance criteria:** Create `core/widgets/dialog_utils.dart` with `showConfirmDialog(context, ...)`, `showErrorDialog(context, ...)`, etc. Migrate ~30 call sites.

---

## MINOR: `quickguide` → `teaching` cross-feature widget/model import

**Files:**
- `lib/features/quickguide/presentation/quick_guide_screen.dart:7` — imports `ConversationMessage` from teaching
- `lib/features/quickguide/presentation/widgets/message_list_widget.dart:2,4` — imports `ConversationMessage` + `ChatBubble` from teaching

**Acceptance criteria:** If `ConversationMessage` and `ChatBubble` are genuinely shared, extract them into `core/`.

---

## Action Priority Summary

| Priority | Finding | Type |
|---|---|---|
| **P0** | Systemic `Result<T>` misuse across 25+ files | Bug/Error handling |
| **P0** | `planner` ↔ `sessions` circular dependency | Architecture |
| **P1** | Core → feature inverted dependency (19 files) | Architecture |
| **P1** | 14 dead code branches from `Result` misuse | Dead code |
| **P1** | ~70 catch blocks log `.w()` instead of `.e()` | Observability |
| **P1** | 9 files with 100+ line `build()` / monolith methods | Maintainability |
| **P1** | `SessionRepository` duplicates `Repository<T>` | Maintainability |
| **P1** | 3 dead extension files + barrel | Dead code |
| **P1** | `SettingsRepository` 22 fields × 3 boilerplate | Maintainability |
| **P1** | 14 silent `catch (_) {}` blocks | Observability |
| **P2** | God classes (6 screens with 15+ methods) | Architecture |
| **P2** | `LLMChatService` 6 near-duplicate methods | Maintainability |
| **P2** | Unused deprecated classes (3) | Dead code |
| **P2** | `Clock` dead abstraction | Dead code |
| **P2** | Duplicate error card + scroll patterns | Maintainability |
| **P2** | Empty catch blocks without logging | Reliability |
| **P3** | `OnboardingService` in presentation file | File placement |
| **P3** | Missing onboarding barrel file | Consistency |
| **P3** | DTOs in wrong layers | File placement |
| **P3** | `markscheme_model.dart` duplicate location | File placement |
| **P3** | Inline `Logger` creation in PLP service | Consistency |
| **P3** | Hardcoded duration in `spaced_repetition_service.dart` | Maintainability |
| **P3** | Hardcoded defaults in SettingsRepository | Maintainability |
| **P3** | `PlanGenerationConfig` restDayFrequency bug | Bug |
| **P3** | 30+ duplicate dialog patterns | Maintainability |
| **P3** | `quickguide` → `teaching` cross-feature import | Architecture |
