# Future Functionality Plan: Dual-Model Resolution & Data Architecture Unification

## Context

Deep audit of the StudyKing codebase reveals a fundamental architectural anti-pattern: **semantically identical domain concepts are modeled multiple times** across different features, with different serialization strategies, different immutability contracts, and no synchronization between them. This causes silent data corruption (a write to one model is invisible to readers of the other) and makes the codebase extremely difficult to reason about.

The previously completed issue (`issues/completed/future_functionality_planner.md`) addressed service-level fragmentation (timer, SR-engine, nudge consolidation). This issue addresses the **data-model-level fragmentation** — a more foundational problem.

---

## Phase 1 — Critical Dual-Model Resolution

### 1.1 Consolidate Session Models: `Session` ⟷ `TutorSession`

**Current state:** Two independent session models exist with overlapping semantics:

| Aspect | `Session` (core/data) | `TutorSession` (teaching/data) |
|---|---|---|
| File | `lib/core/data/models/session_model.dart` | `lib/features/teaching/data/models/tutor_session_model.dart` |
| Hive typeId | Stored as JSON string in `Box<String>` | typeId 28 (native Hive) |
| Repository | `SessionRepository` (JSON encode/decode) | `TutorSessionRepository` (extends `Repository<TutorSession>`) |
| Key fields | `id`, `studentId`, `subjectId`, `topicId`, `type` (enum), `startTime`, `endTime`, `actualDurationMs`, `completed`, `plannedDurationMinutes`, `questionsAnswered`, `correctAnswers` | `id`, `studentId`, `subjectId`, `topicId`, `topicTitle`, `status` (different enum: `SessionStatus`), `startTime`, `endTime`, `plannedDurationMinutes`, `lessonPlanJson`, `questionsAsked` (≠ `questionsAnswered`), `questionsCorrect` (≠ `correctAnswers`), `confidenceRating`, `tutorNotes`, `topicsCovered`, `totalMessages`, `totalTokensUsed` |

**Key problems:**

1. **Naming collision:** `Session` and `TutorSession` are both "sessions" but with different field names for the same concept (`questionsAsked` vs `questionsAnswered`, `questionsCorrect` vs `correctAnswers`). Developers must constantly check which model they're working with.

2. **Data duplication:** `TutorService.endLesson()` creates BOTH a `TutorSession` record (into `TutorSessionRepository`) AND a `Session` record (into `SessionRepository`) for the same lesson. These can diverge silently.

3. **`Session` stored as JSON string:** `SessionRepository` uses `Box<String>` and manually calls `jsonEncode`/`jsonDecode` — losing all Hive type safety, indexing, and query optimization. Every `getAll()` iterates ALL sessions and decodes each one.

4. **`PlannerService.scheduleLesson()` creates `TutorSession` objects for scheduling**, but the session history views query `SessionRepository`. Scheduled lessons may not appear where users expect them.

**Proposed resolution:**

- [ ] Merge the two models into a single `Session` model (core) with an optional `tutorMetadata` field containing teaching-specific data (lessonPlanJson, confidenceRating, tutorNotes, topicsCovered, totalMessages, totalTokensUsed).
- [ ] Unify field naming: use `questionsAnswered` and `correctAnswers` consistently.
- [ ] Migrate `SessionRepository` from `Box<String>` to a proper `Box<Session>` with a Hive TypeAdapter.
- [ ] Eliminate `TutorSessionRepository` — all session storage goes through the unified `SessionRepository`.
- [ ] Add a migration script that reads all existing JSON-serialized sessions and all existing `TutorSession` Hive records into the new unified box.

**Affected files:**
| File | Change |
|---|---|
| `lib/core/data/models/session_model.dart` | Add `tutorMetadata`, rename fields for consistency |
| `lib/features/teaching/data/models/tutor_session_model.dart` | Delete (merge into Session) |
| `lib/core/data/repositories/` → create `session_adapter.dart` | New Hive TypeAdapter for Session |
| `lib/features/sessions/data/repositories/session_repository.dart` | Rewrite: `Box<Session>` instead of `Box<String>` |
| `lib/features/teaching/data/repositories/tutor_session_repository.dart` | Delete |
| `lib/features/teaching/services/tutor_service.dart` | Removes redundant `Session` creation in `endLesson()` |
| `lib/features/planner/services/planner_service.dart` | Uses `SessionRepository` for scheduling lessons |
| `lib/features/sessions/services/session_export_service.dart` | Uses unified model |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | Uses unified model |

---

### 1.2 Consolidate Progress Tracking Models: `TopicProgress` ⟷ `MasteryState`

**Current state:** Two models track per-topic student progress, with different longevity expectations:

| Aspect | `TopicProgress` | `MasteryState` |
|---|---|---|
| Location | `lib/features/subjects/data/models/topic_progress_model.dart` | `lib/features/practice/data/models/mastery_state_model.dart` |
| Hive typeId | 1 | 16 |
| Mutability | **Mutable** (non-final fields `questionsAnswered`, `correctAnswers`, `averageTimeMs`, `lastUpdated`) | **Immutable** (all fields final, `copyWith` for updates) |
| Fields | `topicId`, `questionsAnswered`, `correctAnswers`, `averageTimeMs`, `lastUpdated` | `studentId`, `topicId`, `accuracy`, `confidenceTrend`, `speedTrend`, `forgettingRisk`, `totalAttempts`, `correctAttempts`, `averageTimeMs`, `lastAttempt`, `lastUpdated`, `currentStreak`, `bestStreak`, `recentConfidence`, `recentAccuracy`, `masteryLevel`, `readinessScore`, `reviewUrgency`, `weakSubtopics` |

**Key problems:**

1. **Mutable fields violate the codebase convention.** Every other Hive model in the codebase uses immutable fields with `copyWith`. `TopicProgress` is the only model with non-final public fields. This is a maintenance hazard — any code can silently mutate a stored Hive object without calling `save()`.

2. **Semantic overlap:** Both track `questionsAnswered`/`totalAttempts`, `correctAnswers`/`correctAttempts`, `averageTimeMs`, and `lastUpdated`. `ProgressRepository.recordAttempt()` updates `TopicProgress` independently of `MasteryRecorder.recordAttempt()` which updates `MasteryState`. The same student attempt is recorded in two places with no synchronization.

3. **`ProgressRepository` is orphaned:** The `ProgressRepository` in `lib/features/subjects/data/repositories/progress_repository.dart` is never used by any other feature — it is only imported by its barrel file. Meanwhile `MasteryStateRepository` is actively used by `MasteryGraphService`, `MasteryRecorder`, and the dashboard.

**Proposed resolution:**

- [ ] Deprecate `TopicProgress` model and `ProgressRepository` with `@Deprecated('Use MasteryState and MasteryStateRepository instead')`.
- [ ] Migrate any consumers of `TopicProgress` to `MasteryState` (the dashboard's `OverallStats` already uses `MasterySnapshot` from `MasteryState` data, so there likely are no downstream consumers).
- [ ] Keep the model file for data migration only (existing Hive boxes with typeId 1), with a one-time migration script.

**Affected files:**
| File | Change |
|---|---|
| `lib/features/subjects/data/models/topic_progress_model.dart` | Add `@Deprecated` annotation, remove mutability warnings |
| `lib/features/subjects/data/repositories/progress_repository.dart` | Add `@Deprecated`, delegate to `MasteryStateRepository` |
| `lib/features/subjects/providers/` (if exists) | Remove references to `ProgressRepository` |

---

### 1.3 Consolidate Adherence Models: `PlanAdherenceMetric` ⟷ `PlanAdherenceModel`

**Current state:** Two nearly identical classes track plan adherence:

| Aspect | `PlanAdherenceMetric` | `PlanAdherenceModel` |
|---|---|---|
| File | `lib/features/planner/data/models/plan_adherence_metric_model.dart` | `lib/features/planner/data/models/plan_adherence_model.dart` |
| Hive typeId | 30 (adapter) | 33 (native `@HiveType`) |
| Extends `HiveObject` | No (plain class) | Yes |
| Fields | `date`, `studentId`, `plannedQuestions`, `actualQuestions`, `plannedMinutes`, `actualMinutes`, `adherenceScore`, `metadata` | `id`, `studentId`, `date`, `plannedQuestions`, `actualQuestions`, `plannedMinutes`, `actualMinutes`, `adherenceScore`, `planId`, `metadata` |
| Repository | Adapter registered but no dedicated repository | `PlanAdherenceRepository` |

`PlanAdherenceMetric` has no `id` field — it cannot be uniquely identified or deleted. `PlanAdherenceModel` does have an `id`. The `InstrumentationService` internally creates `PlanAdherenceMetric` records (via an inline `PlanAdherenceTracker`), while `PlannerService` creates `PlanAdherenceModel` records. These two data sources never reconcile, so adherence reports can show different numbers depending on which table is queried.

**Proposed resolution:**

- [ ] Delete `PlanAdherenceMetric` model and its adapter (typeId 30).
- [ ] `InstrumentationService` delegates to `PlanAdherenceRepository` instead of its internal tracker.
- [ ] Migration script reads all `PlanAdherenceMetric` records from the old box and writes `PlanAdherenceModel` records.

**Affected files:**
| File | Change |
|---|---|
| `lib/features/planner/data/models/plan_adherence_metric_model.dart` | Delete |
| `lib/features/planner/data/adapters/plan_adherence_adapter.dart` | Delete |
| `lib/features/planner/data/adapters.dart` | Remove adapter registration for typeId 30 |
| `lib/core/services/instrumentation_service.dart` | Use `PlanAdherenceRepository` instead of `PlanAdherenceMetric` |

---

### 1.4 Consolidate Subject Progress Model: `TopicProgress` (subjects) ⟷ `TopicDependency` (subjects) — Missing Link

The `TopicDependency` model already has an `isReady()` method and `calculatePriority()` that use `masteryThreshold` and downstream topic analysis to determine topic readiness. However, there is **no runtime bridge** between `TopicDependency` and `MasteryState`. The planner's `SyllabusResolver` manually fetches both and builds `SyllabusTopicNode` objects, but there is no reusable service that says "is topic X ready to be studied given the student's current mastery states and topic dependencies."

**Proposed resolution:**

- [ ] Create a `TopicReadinessService` that combines `TopicDependency` data with `MasteryState` data to answer: "Which topics is the student ready to study next?"
- [ ] This service would be used by `PlannerService` (for plan generation), `MentorService` (for study recommendations), and the dashboard (for "ready to learn" suggestions).
- [ ] Replace the ad-hoc readiness logic in `SyllabusResolver.resolveSyllabus()` with calls to this service.

**Affected files:**
| File | Change |
|---|---|
| New: `lib/core/services/topic_readiness_service.dart` | New service |
| `lib/features/planner/services/syllabus_resolver.dart` | Delegate to `TopicReadinessService` |
| `lib/features/mentor/services/mentor_service.dart` | Add topic readiness to recommendations |

---

## Phase 2 — Repository Pattern Standardization

### 2.1 Eliminate Direct Hive Box Access

**Current state:** Repository implementations follow two incompatible patterns:

| Pattern | Examples | Characteristics |
|---|---|---|
| Extends `Repository<T>` | `MasteryStateRepository`, `AttemptRepository`, `PlanRepository`, `TopicRepository`, `QuestionRepository`, `SourceRepository`, `ConversationRepository`, `TutorSessionRepository` | Has `init()` calling `openBox()`, uses `filterBy()`, `save()`, `get()`, `getAll()`, `delete()` from base class |
| Direct Hive box access | `SessionRepository`, `QuestionMasteryStateRepository`, `QuestionEvaluationRepository` | Manually calls `Hive.box<T>()`, manual iteration over values, no base class methods |

The second pattern is particularly problematic in `SessionRepository` which stores JSON strings instead of typed Hive objects, and `QuestionMasteryStateRepository` which has its own `_box` field instead of using the base class.

**Proposed resolution:**
- [ ] `SessionRepository` — convert to `Box<Session>` with a proper `SessionAdapter` (see 1.1), extend `Repository<Session>`.
- [ ] `QuestionMasteryStateRepository` — extend `Repository<QuestionMasteryState>`, remove manual `_box` field.
- [ ] `QuestionEvaluationRepository` — extend `Repository<QuestionEvaluation>`, remove manual `_box` field.

**Affected files:**
| File | Change |
|---|---|
| `lib/features/sessions/data/repositories/session_repository.dart` | Extend `Repository<Session>`, add Hive adapter |
| `lib/features/practice/data/repositories/question_mastery_state_repository.dart` | Extend `Repository<QuestionMasteryState>` |
| `lib/features/practice/data/repositories/question_evaluation_repository.dart` | Extend `Repository<QuestionEvaluation>` |

---

### 2.2 Eliminate Manual Box Passing in `MasteryGraphRepository`

`MasteryGraphRepository` has a `.test()` factory that takes 4 separate `Box` parameters and manually calls `attachBox()` on sub-repositories. This is fragile and bypasses the normal `init()` lifecycle. The `.test()` factory should be removed and the test infrastructure should use the real `init()` path or a properly designed test injection mechanism.

- [ ] Remove `MasteryGraphRepository.test()` — tests should call the real `init()` path.
- [ ] Add an `initForTest()` method or mockable box factory on `Repository<T>` base class.

---

## Phase 3 — Missing High-Value Features

### 3.1 Data Export/Backup Mechanism

**Current state:** The only export functionality is `SessionExportService` which exports session data to CSV/JSON/PDF for sharing. There is **no general mechanism** to:
- Export all user data (sources, questions, attempts, plans, mastery states) as a portable backup
- Import data from a backup
- Transfer data between devices
- Recover from Hive corruption

The entire learning history (thousands of question attempts, months of mastery data) is stored in local Hive boxes with no redundancy.

**Proposed resolution:**
- [ ] Implement a `DataBackupService` that serializes all Hive boxes to a single portable file (e.g., JSON or SQLite).
- [ ] Implement a `DataRestoreService` that can import a backup file and restore all boxes.
- [ ] Add a "Backup & Restore" section to the Settings screen.
- [ ] Consider automatic periodic backups.

---

### 3.2 Offline-First Sync Architecture (Roadmap)

While local-first storage is correct for this app, the complete absence of any sync strategy means users WILL lose data on device failure, app cache clear, or Hive corruption. This is a roadmap item:

- [ ] Design a sync layer that supports: local-only (current), manual file-based backup (3.1), and optionally cloud sync.
- [ ] Each Hive model must have a `syncStrategy` (last-write-wins, merge, or no-sync).
- [ ] The `Result<T>` error handling pattern should be extended to support conflict resolution.

---

### 3.3 Dashboard Business Logic Layer

`lib/features/dashboard/services/` exists but is **empty**. The dashboard providers (`dashboard_data_providers.dart`) call repositories directly from providers, mixing data fetching and transformation in the provider layer. A dedicated `DashboardService` should encapsulate:
- Aggregating data from multiple repositories (mastery, adherence, focus, sessions)
- Computing derived stats (weekly trends, streak calculations, badge eligibility)
- Caching intermediate results

- [ ] Create `DashboardService` in `lib/features/dashboard/services/`.
- [ ] Move aggregation logic from `dashboard_data_providers.dart` into the service.
- [ ] Providers become thin wrappers that call the service.

---

## Phase 4 — Future Vision Features

### 4.1 Multi-Syllabus Simultaneous Learning

The product vision states: "The system should allow a student to learn and track from multiple syllabi simultaneously." The current architecture assumes a single syllabus per plan (`PersonalLearningPlan` has `syllabusGoals` but `SyllabusGoal` is not a Hive type and `PlannerService.generatePlan()` takes only a single `course` string). To support multi-syllabus:

- [ ] `PersonalLearningPlan` should natively support multiple `SyllabusGoal` objects with independent progress tracking.
- [ ] Dashboard should show per-syllabus and combined stats.
- [ ] Planner should generate plans that interleave topics from multiple syllabi based on priority and due dates.
- [ ] `LessonScreen` should indicate which syllabus a lesson belongs to.

### 4.2 Relative Remaining Lesson Count

The vision says: "A relative remaining lesson count should be given by the system towards mastery, so not all lessons must be planned at once." Currently, there is no calculation of "lessons remaining to mastery." This requires:

- [ ] Mastery threshold definitions per topic/syllabus.
- [ ] Historical lesson-to-mastery-improvement ratio (how many lessons does it typically take to move from `developing` to `proficient`?).
- [ ] A `RemainingWorkloadEstimator` service that computes remaining lessons based on current mastery state, target mastery, and historical improvement rate.

### 4.3 Proactive Engagement Scheduling

The `EngagementScheduler` exists (`lib/core/services/engagement_scheduler.dart`) but is not wired into the app's startup lifecycle. There is no service that runs:
- Daily nudge checks at appropriate times
- Lesson reminders before scheduled sessions
- Overwork alerts after long study sessions
- Inactivity nudges after N days without activity

Resolution:
- [ ] Wire `EngagementScheduler` into app lifecycle (post-frame callback after Hive init).
- [ ] Implement platform-specific notification scheduling (Android notification channels, iOS notification requests) for when the app is in the background.

---

## Files Summary

### Phase 1 — Dual-Model Resolution
| Issue | Primary files to modify |
|---|---|
| 1.1 Session consolidation | `session_model.dart`, `tutor_session_model.dart` (delete), `session_repository.dart` (rewrite), `tutor_session_repository.dart` (delete), `tutor_service.dart`, `planner_service.dart` |
| 1.2 Progress model consolidation | `topic_progress_model.dart` (deprecate), `progress_repository.dart` (deprecate) |
| 1.3 Adherence model consolidation | `plan_adherence_metric_model.dart` (delete), `plan_adherence_adapter.dart` (delete), `instrumentation_service.dart` |
| 1.4 Topic readiness service | New: `topic_readiness_service.dart`; Update: `syllabus_resolver.dart`, `mentor_service.dart` |

### Phase 2 — Repository Standardization
| Issue | Files |
|---|---|
| 2.1 Direct Hive access | `session_repository.dart`, `question_mastery_state_repository.dart`, `question_evaluation_repository.dart` |
| 2.2 Manual box passing | `mastery_graph_repository.dart`, `repository.dart` (base class) |

### Phase 3 — Missing Features
| Issue | New / modified files |
|---|---|
| 3.1 Data backup/restore | New: `data_backup_service.dart`, `data_restore_service.dart`; Settings screen |
| 3.2 Sync architecture | Design doc; model annotations |
| 3.3 Dashboard service | New: `lib/features/dashboard/services/dashboard_service.dart`; Update: `dashboard_data_providers.dart` |

### Phase 4 — Vision Features
| Issue | New files |
|---|---|
| 4.1 Multi-syllabus | `PersonalLearningPlan` changes, dashboard stats, planner changes |
| 4.2 Remaining lesson count | New: `remaining_workload_estimator.dart` |
| 4.3 Engagement scheduling | `engagement_scheduler.dart` lifecycle wiring, notification service |

---

## Dependencies & Ordering

```
Phase 1 (Dual-Model Resolution)
  ├── 1.1 Session consolidation ───────── blocks → Dashboard focus stats (uses unified Session)
  ├── 1.2 Progress consolidation ──────── blocks → Topic readiness service (1.4)
  ├── 1.3 Adherence consolidation ─────── blocks → Planner reliability
  └── 1.4 Topic readiness service ─────── depends on: 1.2

Phase 2 (Repository Standardization)
  ├── 2.1 Direct Hive elimination ─────── depends on: 1.1 (Session repo rewrite)
  └── 2.2 Manual box passing ──────────── independent

Phase 3 (Missing Features)
  ├── 3.1 Data backup ─────────────────── independent
  ├── 3.2 Sync architecture ───────────── depends on: 3.1
  └── 3.3 Dashboard service ───────────── depends on: 1.1, 1.2

Phase 4 (Vision Features)
  ├── 4.1 Multi-syllabus ──────────────── depends on: 1.4
  ├── 4.2 Remaining lesson count ──────── depends on: 1.4
  └── 4.3 Engagement scheduling ───────── depends on: 1.3, 1.1
```

## Rationale Summary

The codebase has excellent local patterns (immutability, barrel files, Riverpod, `Result<T>`, ARB localization). The critical weakness is **data-model fragmentation** — the same real-world concepts (sessions, progress, adherence) are independently modeled 2–3 times each with incompatible serialization, different field names, and no synchronization. This is a more foundational issue than the service-level fragmentation addressed in the previous planner issue because:

1. **Data integrity risk:** Dual models with independent write paths guarantee silent divergence. A student's progress, session history, and plan adherence will differ depending on which model you query.

2. **Cognitive load:** Developers must remember which of 3 progress models to update, which of 2 session models to query, and which field naming convention to use. This slows down every feature addition.

3. **Test fragility:** Every new feature must mock 2–3 redundant models, making tests brittle and harder to write.

4. **Migration cost grows with time:** Every day the dual models exist, more data accumulates in both, making eventual consolidation more expensive.

Phase 1 should be prioritized above all other work, including the previously identified service consolidations, because data-model fragmentation makes the service fragmentation impossible to fix correctly — you cannot consolidate services if their underlying data models are contradictory.
