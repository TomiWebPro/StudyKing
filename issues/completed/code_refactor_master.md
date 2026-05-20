# Code Refactor Master & Quality Issue

> Generated: 2026-05-19
> Scope: Full codebase audit — dead code, circular deps, SRP violations, error handling inconsistencies, redundant abstractions, file placement, comments/log levels, hardcoded config, repeated patterns.

---

## BLOCKER — App crashes or user cannot proceed

### B1. Empty `catch (_) {}` blocks swallow critical errors

Three locations swallow exceptions silently with no logging, violating AGENTS.md: *"Empty catch (\_) {} blocks are forbidden. Every catch must log the error with a descriptive message."*

| File | Line | Impact |
|---|---|---|
| `lib/features/teaching/services/tutor_service.dart` | 472 | `_findExerciseQuestionFromMessages()` fails silently during lesson ending — student may see no exercise summary with no indication of failure |
| `lib/features/mentor/services/mentor_service.dart` | 123 | `LongTermMemory.init()` failure swallowed during `MentorService.initialize()` — mentor operates without LTM, no one knows |
| `lib/features/mentor/services/mentor_service.dart` | 358 | `_storeMentorSessionSummary()` failure swallowed — session summaries silently lost |

**Acceptance criteria:** Every `catch (_) {}` replaced with `catch (e) { _logger.w('descriptive message', e); }` or equivalent. At minimum `.w()` with the error object.

### B2. Public methods throw raw exceptions instead of returning `Result<T>`

| File | Line | Method |
|---|---|---|
| `lib/features/sessions/services/session_export_service.dart` | 197 | `writeCSVFile()` — throws `UnsupportedError` on web |
| `lib/features/sessions/services/session_export_service.dart` | 213 | `writeJSONFile()` — throws `UnsupportedError` on web |
| `lib/features/sessions/services/session_export_service.dart` | 230 | `writePDFFile()` — throws `UnsupportedError` on web |

**Impact:** Any caller on web that doesn't pre-guard with `kIsWeb` will crash. These should return `Result.failure(...)`.

**Acceptance criteria:** All three methods return `Result<String>` (or `Result<void>`) instead of throwing. Callers updated to handle the Result.

---

## MAJOR — Feature is broken or misleading

### M1. 15+ cross-cutting domain models/repos buried in feature folders (file placement violation)

The following types are used by **core services** but live inside `features/practice/` or `features/subjects/`:

| File | Used by |
|---|---|
| `lib/features/practice/data/models/mastery_state_model.dart` | `core/services/mastery_graph_service.dart`, `core/services/study_progress_tracker.dart`, `core/services/mastery_calculation_service.dart` |
| `lib/features/practice/data/models/question_mastery_state_model.dart` | Same three core services + `instrumentation_service.dart` |
| `lib/features/practice/data/models/mastery_improvement_metric_model.dart` | `core/services/instrumentation_service.dart` |
| `lib/features/practice/data/repositories/attempt_repository.dart` | `core/services/study_progress_tracker.dart`, `progress_export_service.dart`, multiple features |
| `lib/features/practice/data/repositories/mastery_state_repository.dart` | `core/services/mastery_graph_service.dart` |
| `lib/features/practice/data/repositories/question_mastery_state_repository.dart` | `core/services/mastery_graph_service.dart` |
| `lib/features/subjects/data/repositories/topic_repository.dart` | `core/services/`, `features/planner/` |
| `lib/features/sessions/data/repositories/session_repository.dart` | `core/services/engagement_scheduler.dart`, `study_progress_tracker.dart` |
| `lib/features/planner/data/repositories/engagement_nudge_repository.dart` | `core/services/engagement_scheduler.dart` |
| `lib/features/planner/data/repositories/plan_adherence_repository.dart` | `core/services/engagement_scheduler.dart` |

**Impact:** Creates bidirectional coupling — core depends on features, making it impossible to extract or test core independently. This is the root cause of latent circular-dependency risk.

**Acceptance criteria:** Move cross-cutting models to `lib/core/data/models/` and cross-cutting repositories to `lib/core/data/repositories/`. Update all imports. Verify no coupling cycles emerge.

### M2. Massive SRP violations — 6 god functions > 100 lines each

| Function | File | Lines | Distinct concerns |
|---|---|---|---|
| `TutorService.endLesson()` | `lib/features/teaching/services/tutor_service.dart` | 168 | 7+ (session save, mastery record, exercise persistence, plan adherence, lesson block, background task enqueue, state reset) |
| `ContentPipeline.processFullPipeline()` | `lib/features/ingestion/services/content_pipeline.dart` | 158 | 8+ (source creation, text extraction, topic class., summary gen., question gen., validation, lesson gen., callbacks) |
| `EngagementScheduler._sendNudgeNotifications()` | `lib/core/services/engagement_scheduler.dart` | 119 | 6 nearly-identical nudge blocks (overwork, revision, plan adj., weak topics, adherence, notification) |
| `MentorService._buildContextPrompt()` | `lib/features/mentor/services/mentor_service.dart` | 112 | Data fetching from 10+ sources **AND** LLM prompt formatting in one function |
| `MentorService._checkWellbeingInner()` | `lib/features/mentor/services/mentor_service.dart` | 112 | 5 distinct nudge types (overwork, late-night, revision, streak, inactivity) with persistence in each |
| `DocumentExtractor._extractPdfOrDocument()` | `lib/features/ingestion/services/document_extractor.dart` | 106 | 4+ file formats (PDF, DOCX, EPUB, XLSX) with fallback chains |

**Impact:** These functions are impossible to unit test exhaustively, impossible to reason about, and every bug fix risks regressions in unrelated concerns.

**Acceptance criteria:** Each function refactored so no single function exceeds 40 lines. Extract each distinct concern into its own private method or class. Nesting depth ≤ 3 in any remaining method.

### M3. Widespread return-type inconsistency — `Result<T>` mixed with raw types in same classes

| Class | File | Problem |
|---|---|---|
| `PlannerService` | `lib/features/planner/services/planner_service.dart` | 18 raw-type methods, 2 `Result<T>` methods |
| `StudyProgressTracker` | `lib/core/services/study_progress_tracker.dart` | 1 `Result<T>` method, 8 raw-type methods |
| `SpacedRepetitionService` | `lib/features/practice/services/spaced_repetition_service.dart` | 3 `Result<T>`, 2 raw |
| `StudyTimerService` | `lib/features/sessions/services/study_timer_service.dart` | 3 `Result<T>`, 8 raw |
| `SessionRepository` | `lib/features/sessions/data/repositories/session_repository.dart` | 18 `Result<T>`, 2 raw |
| `DashboardService` | `lib/features/dashboard/services/dashboard_service.dart` | 2 `Result<T>`, 5 raw |
| `BadgeService` | `lib/core/services/badge_service.dart` | 0 `Result<T>`, 7 raw |
| `MistakeReviewService` | `lib/features/practice/services/mistake_review_service.dart` | 0 `Result<T>`, 3 raw |
| `PracticeSessionService` | `lib/features/practice/services/practice_session_service.dart` | 0 `Result<T>`, 2 raw (`void`) |

**Impact:** Callers never know whether a method can fail. Some methods return `null` on error, others return `false`, others throw, others return `Result.failure()`. This makes robust error handling impossible without reading every callee.

**Acceptance criteria:** Every public repository and service method returns `Result<T>`. No raw `Future<T>` or `Future<void>` for data-access/service methods. Remove all `bool`-as-error-signal patterns.

### M4. `Feature/practice/` houses `SpacedRepetitionQueries` — redundant abstraction kept for tests

`lib/features/practice/services/spaced_repetition_service.dart` contains both `SpacedRepetitionQueries` (lines 23–63) and `SpacedRepetitionService` (lines 67–277) with duplicated logic for `getQuestionsDueForReview()` and `isQuestionDueForReview()`. The TODO at line 21 says: *"Remove after migrating test helpers"* — this migration is either incomplete or the dead code was never cleaned up.

**Acceptance criteria:** Remove `SpacedRepetitionQueries` class. Migrate any test imports to use `SpacedRepetitionService` directly. Delete the TODO comment.

### M5. `PlannerService` has 7+ thin delegation methods that add no value

| Method | Line | Delegates to | Lines |
|---|---|---|---|
| `suggestPlanRegeneration()` | 269 | `planOrchestrator.suggestRegeneration()` | 10 |
| `getAdherenceReport()` | 445 | `planOrchestrator.getAdherenceReport()` | 4 |
| `checkAdherence()` | 450 | `planOrchestrator.checkAdherence()` | 4 |
| `regeneratePlanFromAdherence()` | 455 | `planOrchestrator.suggestRegeneration()` | 4 |
| `redistributeWorkload()` | 509 | `planService.redistributeMissedWorkloadForStudent()` | 3 |
| `extendPlan()` | 513 | `planService.extendPlan()` | 3 |
| `linkDailyPlanToRoadmap()` | 517 | `planService.linkDailyPlanToRoadmap()` | 3 |

**Impact:** Inflates `PlannerService` to 551 lines. Every new feature needs to understand which layer does what. Callers could just as easily call the delegate directly.

**Acceptance criteria:** Remove delegation methods that contain zero additional logic. Update callers to inject the delegate directly or consolidate into a single orchestration layer.

### M6. 14 cross-feature methods swallow errors — return `void` or raw `bool`

These methods log the error but give callers no signal:

| File | Line | Method |
|---|---|---|
| `lib/features/practice/services/practice_session_service.dart` | 49 | `updateNextReview()` — `Future<void>` |
| `lib/features/practice/services/practice_session_service.dart` | 58 | `autoSaveSession()` — `Future<void>` |
| `lib/features/planner/services/planner_service.dart` | 404 | `dismissAllMissed()` — `Future<void>` |
| `lib/features/sessions/services/session_migration_service.dart` | 12 | `migrateIfNeeded()` — `Future<void>` |
| `lib/features/onboarding/services/onboarding_service.dart` | 28, 36 | `markCompleted()`, `markDontShowAgain()` — `Future<void>` |
| `lib/core/services/plan_adherence_orchestrator.dart` | 239 | `recordActivity()` — no try/catch at all |

**Acceptance criteria:** All return `Result<void>` or `Result<bool>`. Callers must handle the Result.

### M7. `MentorService` is a god class (838 lines, 17+ dependencies)

`lib/features/mentor/services/mentor_service.dart` — handles chat streaming, context building, schedule proposals, plan proposals, intent detection, wellbeing checks, nudge generation, progress reports, suggestion generation, rescheduling, session summaries, memory management, and locale-specific keyword extraction.

**Impact:** Every new mentor feature requires touching this single file. Test setup requires mocking 17+ dependencies.

**Acceptance criteria:** Split into focused collaborators (e.g., `MentorChatService`, `MentorWellbeingService`, `MentorContextBuilder`, `MentorScheduleHandler`). Each new class ≤ 200 lines with ≤ 5 dependencies.

### M8. `MasteryGraphService.recordAttempt()` combines topic + question mastery in one method

`lib/core/services/mastery_graph_service.dart` lines 37–82. If question mastery update succeeds but topic mastery update fails, the partial update is already committed with no rollback.

**Acceptance criteria:** Split into `recordTopicAttempt()` and `recordQuestionAttempt()`. Wrap in a transactional boundary or document the atomicity guarantee.

---

## MINOR — Code quality / UX friction

### m1. Hive box names hardcoded as string literals

| File | Line(s) | Raw string | Should use |
|---|---|---|---|
| `lib/main.dart` | 465, 600, 606 | `'settings'` | `HiveBoxNames.settings` |
| `lib/features/mentor/services/mentor_service.dart` | 442–443 | `'settings'` | `HiveBoxNames.settings` |
| `lib/core/services/engagement_scheduler.dart` | 148 | `'settings'` | `HiveBoxNames.settings` |
| `lib/core/providers/app_providers.dart` | 154–155 | `'profile'` | `HiveBoxNames.profile` |
| `lib/core/services/student_id_service.dart` | 8 | `'student_id'` | Add to `HiveBoxNames` |
| `lib/features/dashboard/providers/dashboard_layout_providers.dart` | 4 | `'dashboard_layout_prefs'` | Add to `HiveBoxNames` |
| `lib/core/data/database_migration.dart` | 7 | `'db_version'` | Add to `HiveBoxNames` |

**Acceptance criteria:** All Hive box references use named constants from `HiveBoxNames`. No raw string literals for box names.

### m2. `.normalized` extension not used — manual `.toLowerCase()` instead

| File | Line | Code |
|---|---|---|
| `lib/features/subjects/data/curriculum_seed_data.dart` | 539 | `.toLowerCase()` |
| `lib/features/mentor/services/mentor_service.dart` | 376, 605, 638, 663 | `.toLowerCase()` |

AGENTS.md specifies: *"Use the `.normalized` extension (from `lib/core/utils/string_extensions.dart`) instead of `.trim().toLowerCase()`."*

**Acceptance criteria:** All 5+ occurrences replaced with `.normalized`.

### m3. Inline `Logger` construction instead of `static final` class-level field

`lib/core/services/plan_adherence_orchestrator.dart` lines 234, 260:
```dart
const Logger('PlanAdherenceOrchestrator').w(...)
```

AGENTS.md: *"Inline `const Logger('Name').e(...)` is forbidden. All Logger instances must be `static final` at class level."*

**Acceptance criteria:** Add `static final _logger = Logger('PlanAdherenceOrchestrator');` and replace inline constructions.

### m4. Logger `.e()` calls without stack traces

`lib/core/errors/handlers.dart` line 140–141:
```dart
static void _logError(Object error, String context) {
    logger.e('[$context] Error: $error');  // no stack trace passed
}
```

**Acceptance criteria:** Pass `StackTrace.current` as second argument to `logger.e()`.

### m5. `Duration(hours: 1)` magic numbers repeated across 4+ files

| File | Line |
|---|---|
| `lib/features/sessions/presentation/session_history_screen.dart` | 502 |
| `lib/features/sessions/data/repositories/session_repository.dart` | 214 |
| `lib/features/planner/services/planner_service.dart` | 376 |
| `lib/features/planner/services/planner_service.dart` | 395 |

`lib/core/constants/timeouts.dart` defines `recentSessionWindow` but callers use literal `Duration(hours: 1)` instead.

**Acceptance criteria:** All four use `Timeouts.recentSessionWindow` constant.

### m6. Default lesson duration `45` duplicated across 3 files

| File | Line |
|---|---|
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | 81 |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | 88 |
| `lib/features/teaching/presentation/tutor_screen.dart` | 44 |

**Acceptance criteria:** Define `static const int defaultLessonDurationMinutes = 45` in a shared location (e.g., `lib/core/constants/`). Reference it everywhere.

### m7. `_logError` in `handlers.dart` omits stack trace, hindering debugging

`lib/core/errors/handlers.dart:140` — calls `logger.e('[$context] Error: $error')` without a stack trace parameter.

**Acceptance criteria:** Pass `StackTrace.current` as the second argument to `logger.e()`.

### m8. Hardcoded late-night threshold `22` (10 PM) in `mentor_service.dart`

Lines 314, 614: Hardcoded hour value for "late night study" detection. Should be a named constant.

**Acceptance criteria:** Extract to a named constant (e.g., `static const int _lateNightHour = 22`), or better, move to a configurable value.

### m9. Hardcoded nudge cap `5` per day in `mentor_service.dart` line 589

**Acceptance criteria:** Extract to named constant `static const int _maxNudgesPerDay = 5`.

### m10. Overwork threshold `4` hours duplicated

`lib/core/services/engagement_scheduler.dart` line 342 and `lib/features/mentor/services/mentor_service.dart` line 487 both check `totalHours > 4` independently.

**Acceptance criteria:** Extract to a shared constant (e.g., in `lib/core/constants/` or `HiveBoxNames`-style config file).

### m11. `SettingsRepository` (287 lines) has zero Logger calls

`lib/features/settings/data/repositories/settings_repository.dart` — all 11+ catch blocks construct `Result.failure(...)` with a string but never call `_logger.w(...)`.

**Acceptance criteria:** Add `static final _logger = Logger('SettingsRepository');` and log every caught exception with `.w()`.

### m12. API config has no environment-driven URL overrides

`lib/core/constants/app_api_config.dart` lines 57–62 defines `ollamaDefaultUrl` (`http://localhost:11434`) and `openAIDefaultUrl` as compile-time constants with no env-based override mechanism. `.env.example` shows `DEFAULT_OLLAMA_MODEL` but no URL override.

**Acceptance criteria:** Add env vars for API base URLs with compile-time constant fallbacks. Document in `.env.example`.

### m13. Answer normalization comparison triplicated

The pattern `userAnswer.normalized == correct.normalized` appears in:
- `lib/core/data/models/markscheme_model.dart` lines 55–61
- `lib/core/services/answer_validation_service.dart` lines 78–85
- `lib/features/questions/data/models/question_evaluation_model.dart` lines 137–143

**Acceptance criteria:** Extract to a utility method `AnswerComparator.areEquivalent(String user, String correct)` in `lib/core/utils/`.

### m14. Date formatting pattern `DateFormat.yMd(_localeName).add_Hm().format(...)` repeated 7+ times

In `mentor_service.dart` (lines 266, 283, 679, 680, 699, 829) and `mentor_screen.dart` (line 395).

**Acceptance criteria:** Extract to `String localizedDateTime(DateTime dt, String localeName)` utility in `lib/core/utils/date_utils.dart`.

### m15. `spaced_repetition_service.dart` TODO references unowned task

Line 21: `// TODO: Remove after migrating test helpers to use SpacedRepetitionService methods.` — no owner, no issue tracker reference.

**Acceptance criteria:** Either complete the migration (see M4) or add an issue reference.

### m16. `app_api_config.dart` TODO references `#arch-runtime-secrets` issue

Line 32: `// TODO: implement runtime secret injection (keystore/native layer) over compile-time embedding. Tracked in issue #arch-runtime-secrets.` — no evidence this issue exists.

**Acceptance criteria:** Create the tracking issue and update the reference, or remove the TODO if the decision is to stay with compile-time embedding.

### m17. 3 `SpacedRepetitionService` static/quasi-static methods access Hive box directly without protection

`lib/features/practice/services/spaced_repetition_service.dart` lines 83, 85, 96 — `getQuestionsDueForReview()` and `isQuestionDueForReview()` access `_questionRepo.box.values` directly. If the box is closed, this throws an unhandled exception.

**Acceptance criteria:** Wrap in try-catch or delegate through a safe accessor. Return empty list / false on failure with a `.w()` log.

### m18. `SessionRepository.hasSchedulingConflict()` and `getScheduledLessons()` return raw types with error swallowing

`lib/features/sessions/data/repositories/session_repository.dart` lines 112, 138 — catch errors and return `false` / `[]` with no log.

**Acceptance criteria:** Return `Result<bool>` and `Result<List<Session>>`. Log failures with `.w()`.

### m19. `OnboardingService` is a static wrapper around `OnboardingStorage` with nearly-identical methods

`lib/features/onboarding/services/onboarding_service.dart` — `isOnboardingNeeded()` and `isFirstLaunch()` (lines 17, 44) both read the same Hive key and return `!completed`. Static `setStorage()` is a testing anti-pattern.

**Acceptance criteria:** Merge `isOnboardingNeeded()` and `isFirstLaunch()` if they serve the same purpose. Replace `setStorage()` with constructor injection.

### m20. `DatabaseService` acts as a service locator (dependency bag)

`lib/core/data/database_service.dart` — 47 lines holding 8 repositories with `init()` that initializes all of them. This is a "service locator lite" pattern that hides dependencies.

**Acceptance criteria:** Remove `DatabaseService` and inject repositories individually where needed. Or, keep it only as an initialization coordinator but remove all getter access.

### m21. Duplicate overwork/revision checking logic between `EngagementScheduler` and `MentorService`

`EngagementScheduler.getRevisionNudges()` and `MentorService._checkWellbeingInner()` both check for topics needing review using different criteria and data sources.

**Acceptance criteria:** Unify into a single `WellbeingService` or audit utility. Ensure only one code path owns the "generate nudge" responsibility.

### m22. MentorService locale-specific keyword maps hardcoded in service code

Lines 361–373, 594–602: Hardcoded maps for keyword extraction in English, Spanish, French, German.

**Acceptance criteria:** Move to a locale configuration file or ARB extension. Keep service code language-agnostic.

---

## How to verify each fix

| # | Verification command / approach |
|---|---|
| B1 | `rg 'catch _' lib/ --include '*.dart'` should return 0 matches. |
| B2 | `rg 'throw UnsupportedError' lib/ --include '*.dart'` shows only non-public methods. |
| M1 | `rg 'import.*features/practice' lib/core/ --include '*.dart'` shows 0 results after move. |
| M2 | Count lines per function. Every public function ≤ 40 lines, nesting ≤ 3. |
| M3 | `rg 'Future<(List<|Map<|int|bool|String|void)>' lib/ --include '*.dart'` — no service/repository returns raw async types. |
| M4 | Verify `SpacedRepetitionQueries` class removed from `spaced_repetition_service.dart`. |
| M5 | `PlannerService` line count < 400 (removing thin delegates). |
| M6 | `rg 'Future<void>' lib/features/ --include '*.dart'` — no service method returns void. |
| M7 | `MentorService` < 300 lines, no single dependency-injected collaborator handles > 3 concerns. |
| M8 | `MasteryGraphService.recordAttempt()` calls separate `recordTopicAttempt` + `recordQuestionAttempt`. |
| m1 | `rg "'[a-z_]+'" lib/ --include '*.dart'` — no Hive box name literal matches what's in `HiveBoxNames`. |
| m2 | `rg '\.toLowerCase\(\)' lib/ --include '*.dart'` — 0 results (all use `.normalized`). |
| m3 | `rg "const Logger\('" lib/ --include '*.dart'` — 0 results for inline Logger. |
| m4, m7 | `_logError` passes `StackTrace.current`. |
| m5 | `rg 'Duration\(hours: 1\)' lib/ --include '*.dart'` — 0 results; all use `Timeouts.recentSessionWindow`. |
| m6 | `rg '\b45\b' lib/features/lessons/ lib/features/teaching/ --include '*.dart'` — 0 magic 45's for duration. |
| m13 | `rg '\.normalized\s*==\s*\S+\.normalized' lib/ --include '*.dart'` — 0 direct comparisons; all use `AnswerComparator`. |
| m14 | `rg 'DateFormat\.yMd.*add_Hm' lib/ --include '*.dart'` — 0 results; all use `localizedDateTime()`. |
| m18 | `SessionRepository.hasSchedulingConflict` returns `Result<bool>`. |
| m20 | No file imports `database_service.dart` except `main.dart` (init only). |
