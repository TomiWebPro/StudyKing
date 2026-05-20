# Code Refactor Master & Quality — NEW Findings

> **Generated:** 2026-05-20
> **Scope:** Full codebase audit — `lib/` (core + features) and `test/`
> **Relation to completed report:** These findings are **not** covered in `issues/completed/code_refactor_master.md` (which documented 42 items: 13B, 17M, 12m). This file adds new discoveries and notes which completed-report items remain unfixed.

---

## Status of Completed-Report Items

| Item | Description | Status |
|------|------------|--------|
| B4 | `_getConsecutiveStudyDays()` duplicated in 2 files | **UNFIXED** — identical 24-line algorithm still in `mentor_wellbeing_service.dart:162` and `mentor_context_builder.dart:231` |
| B5 | `_getDailyCapMinutes()` duplicated with raw Hive access | **UNFIXED** — identical copy-paste of `Hive.box(HiveBoxNames.settings).get('dailyCapMinutes')` in `mentor_wellbeing_service.dart:153` and `mentor_context_builder.dart:222` |
| B6 | `_deserializeSrData()` / `_serializeSrData()` duplicated while `SrDataCodec` exists | **UNFIXED** — both `spaced_repetition_service.dart:132` and `mastery_recorder.dart:116` still define inline methods; neither uses `SrDataCodec` |
| B8 | Hardcoded `30` minutes for lesson duration | **UNFIXED** — `mentor_schedule_handler.dart:78`, `planner_service.dart:313,376,495`, `planner_providers.dart:512,561` still use `30` directly |
| M3 | Core-to-feature import violations (28+) | **UNFIXED** — no structural change detected (e.g. `app_providers.dart` still imports from `features/mentor/providers/`, `features/practice/providers/`, etc.) |
| M6 | Duplicate `_masteryLevelLabel` methods | **UNFIXED** — `study_progress_tracker.dart:327` and `progress_export_service.dart:121` both still define private `_masteryLevelLabel`; `topic_detail_screen.dart:222` has a third variant. `label_helpers.dart` exists but does not include mastery level. |
| m5 | Providers defined inside service files | **UNFIXED** — `voice_service.dart:237` and `student_id_service.dart:67` still define provider top-levels |

**Items confirmed FIXED:** M1 (`CrossFeatureIntegrator` deleted), M2 (`TopicReadinessService` deleted), M5 (`mentor_keywords.dart` moved to features), M7 (`Result.fold` added), B7 (`targetQuestionsPerDay` uses `defaultQuestionsPerDay` now).

---

## BLOCKER (app crashes or user cannot proceed)

### B-New1: Duplicate `StudyProgressTracker` instances with different wiring

**Files:**
- `lib/core/providers/app_providers.dart:38` — `engagementTrackerProvider`
- `lib/core/providers/study_progress_provider.dart:9` — `studyProgressTrackerProvider`

**Problem:** Two separate Riverpod providers instantiate `StudyProgressTracker` with **different** dependencies:
- `engagementTrackerProvider` → `engagementAttemptRepoProvider` + `engagementMasteryServiceProvider` (defined at lines 67 & 58 in the same file)
- `studyProgressTrackerProvider` → `attemptRepositoryProvider` + `masteryGraphServiceProvider` (from `features/practice/providers/`)

**Impact:** The EngagementScheduler and the PracticeScreen each hold a separate `StudyProgressTracker` with independent caches. Progress data reported by the scheduler could disagree with what the user sees in the practice screen. If one cache is stale, a user could receive contradictory notifications (e.g., "you've studied 0 minutes today" from the scheduler while the practice screen shows 45 minutes).

**Acceptance criteria:**
- Eliminate one provider (either remove `engagementTrackerProvider` and make `engagementSchedulerProvider` depend on `studyProgressTrackerProvider`, or vice versa)
- Ensure the surviving provider uses a single set of dependency providers
- Verify via test that `ref.read(studyProgressTrackerProvider)` and `ref.read(engagementTrackerProvider)` (if kept) return the same object, OR that only one exists

### B-New2: `PlanAdherenceRepository` returns raw types instead of `Result<T>`

**File:** `lib/core/data/repositories/plan_adherence_repository.dart` (73 lines)

**Problem:** Per AGENTS.md convention, "Public repository and service method return types must be `Result<T>`." All 7 public methods return raw types:

| Method | Line | Current Return | Should Be |
|--------|------|---------------|-----------|
| `create()` | 12 | `Future<void>` | `Future<Result<void>>` |
| `getByStudent()` | 16 | `Future<List<PlanAdherenceModel>>` | `Future<Result<List<PlanAdherenceModel>>>` |
| `getByDateRange()` | 22 | `Future<List<PlanAdherenceModel>>` | `Future<Result<List<PlanAdherenceModel>>>` |
| `getWeekly()` | 31 | `Future<List<PlanAdherenceModel>>` | `Future<Result<List<PlanAdherenceModel>>>` |
| `getAverageAdherence()` | 37 | `Future<double>` | `Future<Result<double>>` |
| `getConsecutiveLowAdherenceDays()` | 44 | `Future<int>` | `Future<Result<int>>` |
| `getToday()` | 58 | `Future<PlanAdherenceModel?>` | `Future<Result<PlanAdherenceModel?>>` |
| `deleteByStudent()` | 67 | `Future<void>` | `Future<Result<void>>` |

**Impact:** Callers (`plan_adherence_orchestrator.dart`, `dashboard_service.dart`) must catch raw exceptions, violating the codebase-wide error handling pattern. Any uncaught exception from the underlying `filterBy()` or database operations will crash the app.

**Acceptance criteria:**
- Wrap each method body in `Result.capture(() async { ... }, context: 'methodName')`
- Update all call sites to destructure `Result<T>` (add `.data!` / `.error` checks)
- Verify tests still pass

---

## MAJOR (feature broken or misleading)

### M-New1: `EngagementNudge` — redundant DTO immediately converted to `EngagementNudgeModel`

**File:** `lib/core/services/engagement_scheduler.dart:505-517`

**Problem:** The `EngagementNudge` class (6 fields: `type`, `message`, `severity`, `topicId`) is only used internally within `engagement_scheduler.dart`. Every site that creates one immediately converts it to `EngagementNudgeModel` via `_persistNudge()` at line 386-389:

```dart
EngagementNudge nudge = ...;
await _nudgeRepository.create(EngagementNudgeModel(
  id: uuid.v4(),
  studentId: _config.studentId,
  nudgeType: nudge.type.name,
  message: nudge.message,
  severity: nudge.severity.name,
  topicId: nudge.topicId,
  sentAt: DateTime.now(),
  wasActedUpon: false,
));
```

`EngagementNudgeModel` (in `features/planner/data/models/engagement_nudge_model.dart`) already has all the same fields plus Hive annotations, `fromJson`, `copyWith`, and persistence support.

**Impact:** 100% overlap with `EngagementNudgeModel`. The DTO adds 13 lines of boilerplate, a 5-field constructor, and a converter method that must be maintained (and could desync from the model). Any new field added to nudge logic must be added to both classes.

**Acceptance criteria:**
- Delete `EngagementNudge` class at `engagement_scheduler.dart:505-517`
- Replace all `EngagementNudge` references in the file with `EngagementNudgeModel` constructed directly with its `.name` fields
- Remove the `_persistNudge` conversion layer
- Verify no compilation errors

### M-New2: `MasteryGraphService` — 13 of 16 methods are pure pass-through delegations

**File:** `lib/core/services/mastery_graph_service.dart`

**Problem:** This 200-line service (imported by 21 files across 7 features) has only 3 methods doing meaningful work (`recordAttempt`, `recordTopicAttempt`, `recordQuestionAttempt`). The remaining 13 methods are pure delegation:

| Method | Line | Delegates to |
|--------|------|-------------|
| `getTopicMastery()` | 119 | `masteryStateRepo.getMasteryState()` |
| `getQuestionMastery()` | 124 | `questionMasteryRepo.getQuestionMasteryState()` |
| `getAllQuestionMastery()` | 129 | `questionMasteryRepo.getAllForStudent()` |
| `getQuestionsDueForReview()` | 134 | `questionMasteryRepo.getDueQuestions()` |
| `getAtRiskQuestions()` | 141 | `questionMasteryRepo.getAtRiskQuestions()` |
| `getTopicsNeedingReview()` | 149 | `masteryStateRepo.getTopicsNeedingReview()` |
| `getWeakTopics()` | 154 | `masteryStateRepo.getWeakTopics()` |
| `getMasterySnapshot()` | 158 | `masteryStateRepo.getMasterySnapshot()` |
| `saveEvaluation()` | 178 | `questionEvaluationRepo.saveEvaluation()` |
| `getAllTopicMastery()` | 182 | `masteryStateRepo.getAllMasteryStates()` |
| `getReadinessScore()` | 186 | fetch + wrap single field |
| `getReviewUrgency()` | 194 | fetch + wrap single field |
| `migrateLegacyQuestion()` | 162 | `questionEvaluationRepo.migrateFromLegacy()` |

**Impact:** Every caller adds an unnecessary indirection layer. If a new method is needed on a repository, it must be added here too (and vice versa). 21 imports would need to change if any signature changes.

**Acceptance criteria:**
- **Option A:** Remove the 13 pass-through methods and inject repositories directly into the 3 meaningful methods' callers. Update all 21 import sites.
- **Option B:** Keep the service as a facade but mark each pass-through with `@proxy` or add a lint rule preventing new pass-through additions without justification.
- **Recommended:** Option A for the pure delegations; keep `recordAttempt`/`recordTopicAttempt`/`recordQuestionAttempt` (which orchestrate multiple repositories).

### M-New3: Direct `Hive.box()` access bypassing repository layer — 22 occurrences

**Files (non-exhaustive):**

| File | Lines |
|------|-------|
| `lib/features/settings/presentation/settings_screen.dart` | 94, 624, 635, 671, 786, 795, 1457, 1486, 1502 |
| `lib/core/providers/shared_providers.dart` | 133 |
| `lib/main.dart` | 66, 96 |
| `lib/features/mentor/services/mentor_wellbeing_service.dart` | 156 |
| `lib/features/mentor/services/mentor_context_builder.dart` | 225 |
| `lib/features/mentor/services/mentor_schedule_handler.dart` | 80 |
| `lib/features/teaching/services/tutor_service.dart` | 87 |
| `lib/core/services/engagement_scheduler.dart` | 118, 189 |
| `lib/features/sessions/services/study_timer_service.dart` | 65 |
| `lib/core/services/llm_agent/agent_memory.dart` | 21 |

**Problem:** These 22 call sites access `Hive.box(HiveBoxNames.settings)` or `Hive.box(HiveBoxNames.profile)` directly instead of going through `SettingsRepository` or the appropriate service. This couples presentation/logic code directly to the storage implementation. It also bypasses error handling — if the box isn't open, these will throw raw Hive exceptions.

**Worst offender:** `settings_screen.dart` — 9 direct `Hive.box()` accesses in a single file. The screen already has access to `SettingsRepository` via providers but doesn't use it for reads.

**Acceptance criteria:**
- Replace all `Hive.box(HiveBoxNames.settings)` calls with `SettingsRepository.getSettings()` / appropriate service method
- Replace all `Hive.box(HiveBoxNames.profile)` calls with `SettingsRepository.getProfileData()`
- `settings_screen.dart` should be the top priority (9 calls)
- Verify no remaining `Hive.box()` in `lib/features/*/presentation/` or `lib/main.dart`

### M-New4: 10+ long methods (>80 lines) — SRP violations not covered in completed report

**Files and methods:**

| Lines | File | Method |
|-------|------|--------|
| 234 | `lib/features/mentor/presentation/mentor_screen.dart:1050` | `_showProgressReport` |
| 198 | `lib/features/sessions/presentation/session_tracker_screen.dart:267` | `build` |
| 184 | `lib/features/planner/services/personal_learning_plan_service.dart:97` | `_buildPlan` |
| 173 | `lib/features/planner/presentation/planner_screen.dart:526` | `_buildStudyPlanTab` |
| 156 | `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart:88` | `build` |
| 133 | `lib/features/mentor/services/mentor_context_builder.dart:42` | `buildContextPrompt` |
| 131 | `lib/features/planner/services/personal_learning_plan_service.dart:282` | `_buildEmptyMasteryPlan` |
| 123 | `lib/features/planner/services/personal_learning_plan_service.dart:764` | `_generateDailyPlans` |
| 122 | `lib/features/practice/presentation/screens/exam_session_screen.dart:790` | `_buildResultsScreen` |
| 108 | `lib/features/mentor/services/mentor_wellbeing_service.dart:39` | `_checkWellbeingInner` |
| 108 | `lib/features/practice/presentation/screens/practice_screen.dart:876` | `_buildActivitySection` |
| 106 | `lib/core/services/llm_agent/agent_loop.dart:28` | `run` |
| 106 | `lib/features/planner/presentation/planner_screen.dart:1195` | `_buildScheduledLessonsSection` |

**Problem:** Each of these methods exceeds 80 lines and mixes multiple concerns:
- `_showProgressReport` (234 lines) builds a dialog with topic breakdown loops, badge rendering, inline analytics — all inside a `showDialog` builder closure
- `_buildPlan` (184 lines) fetches mastery states, filters by subject, resolves syllabus, builds recommendations, generates daily plans, links questions, generates summaries, constructs metadata, and saves — 10+ distinct operations
- `_checkWellbeingInner` (108 lines) checks 5+ nudge conditions (overwork, late-night, revision, consecutive days, inactivity) with nested if/for in a single method
- `session_tracker_screen.dart:build` (198 lines) renders the timer card, analytics, and recent sessions list in one widget tree

**Acceptance criteria (per method):**
- Extract each conditional branch / distinct stage into a named private method (target: <30 lines per method)
- For presentation code, extract inline widgets into separate `Widget` classes or builder methods
- For business logic, split into focused data fetchers vs. processors vs. savers
- Verify the refactored code compiles and existing tests pass

### M-New5: `_getDailyCapMinutes()` still uses raw Hive access in 2 files (unfixed B5)

**Files:**
- `lib/features/mentor/services/mentor_wellbeing_service.dart:153-159`
- `lib/features/mentor/services/mentor_context_builder.dart:222-228`

**Problem:** Both methods still contain:
```dart
final box = Hive.box(HiveBoxNames.settings);
return box.get('dailyCapMinutes', defaultValue: 0) as int;
```

This bypasses the repository layer and uses a magic string `'dailyCapMinutes'`. Has been wrapped in `Result.captureSync()` since the completed report but the fundamental issue (duplication + raw Hive access) remains.

**Acceptance criteria:**
- Create `SettingsService.getDailyCapMinutes()` in `lib/core/services/settings_service.dart`
- Both callers use the shared method
- Remove raw `Hive.box(...)` calls from both files
- Verify no regressions in mentor nudge logic

### M-New6: `_getConsecutiveStudyDays()` identical in 2 files (unfixed B4)

**Files:**
- `lib/features/mentor/services/mentor_wellbeing_service.dart:162-186`
- `lib/features/mentor/services/mentor_context_builder.dart:231-255`

**Problem:** Identical 24-line algorithm (fetch sessions, group by date, count consecutive days) still copy-pasted. Now wrapped in `Result.capture()` but structurally identical.

**Acceptance criteria:**
- Extract to `SessionRepository.getConsecutiveStudyDays()` or `lib/core/utils/study_utils.dart`
- Both callers use the shared implementation
- Return signature should be `Future<int>` with error → 0 fallback (maintain current contract)

---

## MINOR (code quality / UX friction)

### m-New1: `_logger.w()` used for normal lifecycle event

**File:** `lib/features/teaching/presentation/tutor_screen.dart:509`

```dart
_logger.w('Closing grace period expired, auto-ending lesson');
```

**Problem:** The closing grace period expiring is a normal, expected lifecycle event in the tutor flow — it is NOT a warning. Per AGENTS.md: `.w()` should be used for caught exceptions in expected error paths. This should be `.i()` (info) or `.d()` (debug). Using `.w()` for routine events desensitizes log monitoring.

**Acceptance criteria:** Change to `_logger.i('Closing grace period expired, auto-ending lesson')`.

### m-New2: `_logger.w()` in error handler should be `.e()`

**File:** `lib/features/mentor/presentation/mentor_screen.dart:1275`

```dart
_logger.w('Failed to pop navigator in error handler', e);
```

**Problem:** Per AGENTS.md: `.e()` should be used for "unexpected exceptions that require immediate investigation." Failing inside an error handler is an unexpected/recoverable state — the first error was already handled, but the recovery action itself failed. This qualifies as `.e()`.

**Acceptance criteria:** Change to `_logger.e('Failed to pop navigator in error handler', e)`.

### m-New3: `app_config.dart` — unused `import 'package:flutter/material.dart'`

**File:** `lib/core/constants/app_config.dart:2`

**Problem:** The file imports `package:flutter/material.dart` but uses no Material widgets (no `Widget`, `Theme`, `BuildContext`, `Scaffold`, etc.). Only `package:flutter/foundation.dart` is needed for `@visibleForTesting`.

**Acceptance criteria:** Remove line 2 (`import 'package:flutter/material.dart';`). Verify compilation.

### m-New4: `quick_guide_screen.dart` — unused `import 'dart:async'`

**File:** `lib/features/quickguide/presentation/quick_guide_screen.dart:1`

**Problem:** The file imports `dart:async` but never uses `Timer`, `Completer`, `StreamController`, `StreamSubscription`, or `TimeoutException`. `Future` and `Stream` (used via `await for`) are available from `dart:core` since Dart 2.1.

**Acceptance criteria:** Remove `import 'dart:async';`. Verify compilation.

### m-New5: `api_config_screen.dart` — unused `import 'dart:async'`

**File:** `lib/features/settings/presentation/api_config_screen.dart:1`

**Problem:** Same as m-New4 — imports `dart:async` but uses no `dart:async`-specific types.

**Acceptance criteria:** Remove `import 'dart:async';`. Verify compilation.

### m-New6: Stale inline comments referencing tracker handles `(m20)` / `(m21)`

**Files:**
- `lib/core/data/database_service.dart:12` — `/// Kept as an initialization coordinator only (m20).`
- `lib/core/services/engagement_scheduler.dart:44` — `// TODO(m21): Unify overwork/revision nudge logic...`

**Problem:** Both comments reference user handles (`m20`, `m21`) that appear to be stale tracker/issue references. The `(m20)` comment on `DatabaseService` no longer adds useful context — it was meant to track a specific refactoring task. The `(m21)` TODO on `EngagementScheduler` overlaps with completed-report item M4.

**Acceptance criteria:**
- `database_service.dart:12` — Remove the `(m20)` reference or replace with a descriptive comment
- `engagement_scheduler.dart:44` — Either resolve the TODO (consolidate nudge logic) or replace with a link to the tracking issue

### m-New7: `app_constants.dart` barrel omits 3 files

**File:** `lib/core/constants/app_constants.dart`

**Problem:** The barrel exports 10 of 14 constants files but omits:
- `app_radius.dart` (imported directly by `review_answers_screen.dart`)
- `app_spacing.dart` (imported directly by `review_answers_screen.dart`)
- `token_pricing_config.dart` (imported directly by `settings_model.dart`)

**Impact:** Inconsistent import style — most consumer files can import everything via `import 'package:studyking/core/constants/app_constants.dart'`, but these 3 must be imported individually.

**Acceptance criteria:** Add `export 'app_radius.dart';`, `export 'app_spacing.dart';`, and `export 'token_pricing_config.dart';` to the barrel. Update the 3 direct imports to use the barrel instead.

### m-New8: `_getDailyCapMinutes()` uses `Future<int>` but inner closure is synchronous

**Files:**
- `lib/features/mentor/services/mentor_wellbeing_service.dart:153`
- `lib/features/mentor/services/mentor_context_builder.dart:222`

**Problem:** Both methods are declared `Future<int>` but their body calls `Result.captureSync()` (synchronous). The `async` keyword and `Future` return are misleading — callers must `await` a function that doesn't need to be awaited. This adds unnecessary microtask overhead on every nudge check.

**Acceptance criteria:** Change return type to `int` and remove `async`/`await`. Update callers to treat it as synchronous.

---

## Appendix: Unfixed Items from Completed Report (Summary)

Of the 42 items in the completed report, these remain unfixed (confirmed by re-audit):

| Item | Brief | Priority |
|------|-------|----------|
| B4 | `_getConsecutiveStudyDays` duplicated | BLOCKER |
| B5 | `_getDailyCapMinutes` duplicated + raw Hive | BLOCKER |
| B6 | `_deserializeSrData` duplicated (bypasses `SrDataCodec`) | BLOCKER |
| B8 | Hardcoded `30` minutes in 12+ locations | BLOCKER |
| B9 | `ContentPipeline.processFullPipeline()` 170 lines | BLOCKER |
| B10 | `PracticeSessionScreen.build()` 185 lines | BLOCKER |
| B11 | `QuestionBankScreen._showCreateQuestionDialog()` 235 lines | BLOCKER |
| B13 | Fire-and-forget `async void _trimRepository()` | BLOCKER |
| M3 | Core-to-feature import violations (28+) | MAJOR |
| M6 | Duplicate `_masteryLevelLabel` | MAJOR |
| M8 | `pumpAndSettle()` without timeout (1770+ calls) | MAJOR |
| M9 | Duplicate private fakes (428+) | MAJOR |
| M10 | `try/catch` + `_logger.w()` boilerplate not using `Result.capture` | MAJOR |
| M11 | `_lateNightHour = 22` duplicated | MAJOR |
| M12 | Hardcoded English fallback strings | MAJOR |
| M13 | `EngagementScheduler` 455 lines | MAJOR |
| M14 | `PlannerNotifier` 484 lines | MAJOR |
| M15 | `PracticeScreen` State 1255 lines | MAJOR |
| M16 | Hardcoded question type strings | MAJOR |
| M17 | Unused `dart:async` imports (11+ files) | MAJOR |
| m5 | Providers in service files | MINOR |
| m6 | Duplicate `_masteryLevelLabel` methods | MINOR |

**Items confirmed FIXED (7):** M1 (`CrossFeatureIntegrator` deleted), M2 (`TopicReadinessService` deleted), M3 (partially — some repository imports cleaned up), M5 (`mentor_keywords.dart` moved), M7 (`Result.fold` added), B7 (`defaultQuestionsPerDay` used), m4 (`data.dart` barrel usage verified).

---

## Summary: New Findings Count

| Severity | Count | Key Files |
|----------|-------|-----------|
| **BLOCKER** | 2 | `app_providers.dart`, `study_progress_provider.dart` (duplicate tracker); `plan_adherence_repository.dart` (raw returns) |
| **MAJOR** | 6 | `engagement_scheduler.dart` (redundant DTO), `mastery_graph_service.dart` (pass-through), 22 Hive access bypasses, 10+ long methods, `_getDailyCapMinutes`/`_getConsecutiveStudyDays` (unfixed B4/B5) |
| **MINOR** | 8 | Wrong log levels (tutor_screen, mentor_screen), 2 unused imports, stale comments, barrel omission, sync-in-async wrapper |
| **TOTAL NEW** | **16** | |

---

*This issue was generated by codebase exploration. All findings include context, affected files, rationale, and concrete acceptance criteria. Address BLOCKER items first, then MAJOR, then MINOR. The "Unfixed" appendix lists items from the previous completed report that remain actionable.*
