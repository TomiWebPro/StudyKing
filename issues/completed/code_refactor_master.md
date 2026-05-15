# Repository Layer Architectural Refactor

## Context

All 19 repositories in `lib/core/data/repositories/` manage data for specific features (planner, practice, questions, subjects, sessions, mentor, ingestion, etc.) — not shared core infrastructure. Yet they live in `core/data/` with no base class, no consistent interface, and no uniform error handling. This has produced a layer with **3 CRUD naming conventions**, **2 Hive initialization patterns**, **3 distinct error-handling strategies**, **~40 repetitions of the same filter-by-ID boilerplate**, and a **confirmed data-loss bug**.

Meanwhile, `focus_mode` and `settings` already follow the correct pattern — they place their repositories in `lib/features/*/data/repositories/`. The `focus_mode` feature lacks a barrel file and is the only feature not exported from `lib/features/features.dart`.

## Affected Files

### Repositories to relocate from `core/data/repositories/` to feature directories

| Current Location | Target Feature | Rationale |
|---|---|---|
| `lib/core/data/repositories/answer_repository.dart` | `lib/features/practice/data/repositories/` | Answers are practice-domain |
| `lib/core/data/repositories/attempt_repository.dart` | `lib/features/practice/data/repositories/` | Attempts are practice-domain |
| `lib/core/data/repositories/badge_repository.dart` | `lib/features/dashboard/data/repositories/` | Badges are dashboard/achievement-domain |
| `lib/core/data/repositories/conversation_repository.dart` | `lib/features/teaching/data/repositories/` | Conversation is tutor/teaching-domain |
| `lib/core/data/repositories/engagement_nudge_repository.dart` | `lib/features/planner/data/repositories/` | Nudges are planner/engagement-domain |
| `lib/core/data/repositories/lesson_repository.dart` | `lib/features/lessons/data/repositories/` | Lessons feature already exists |
| `lib/core/data/repositories/mastery_graph_repository.dart` | `lib/features/practice/data/repositories/` | Mastery is practice/analytics-domain |
| `lib/core/data/repositories/pending_action_repository.dart` | `lib/features/planner/data/repositories/` | Pending actions are planner-domain |
| `lib/core/data/repositories/plan_adherence_repository.dart` | `lib/features/planner/data/repositories/` | Plan adherence is planner-domain |
| `lib/core/data/repositories/plan_repository.dart` | `lib/features/planner/data/repositories/` | Learning plans are planner-domain |
| `lib/core/data/repositories/progress_repository.dart` | `lib/features/subjects/data/repositories/` | Topic progress is subjects-domain |
| `lib/core/data/repositories/question_repository.dart` | `lib/features/questions/data/repositories/` | Questions feature already exists |
| `lib/core/data/repositories/roadmap_repository.dart` | `lib/features/planner/data/repositories/` | Roadmaps are planner-domain |
| `lib/core/data/repositories/source_repository.dart` | `lib/features/ingestion/data/repositories/` | Sources are ingestion-domain |
| `lib/core/data/repositories/spaced_repetition_repository.dart` | `lib/features/practice/data/repositories/` | SR is practice-domain |
| `lib/core/data/repositories/study_session_repository.dart` | `lib/features/sessions/data/repositories/` | Sessions feature already exists |
| `lib/core/data/repositories/subject_repository.dart` | `lib/features/subjects/data/repositories/` | Subjects feature already exists |
| `lib/core/data/repositories/topic_repository.dart` | `lib/features/subjects/data/repositories/` | Topics belong with subjects |
| `lib/core/data/repositories/tutor_session_repository.dart` | `lib/features/teaching/data/repositories/` | Tutor sessions are teaching-domain |

### Additional files requiring updates (66 import sites + barrel files)

All files that import from `package:studyking/core/data/repositories/*` need their import paths updated. Key barrel files:

| File | Required Change |
|---|---|
| `lib/core/data/data.dart:15-25` | Remove 9 repository exports from core barrel |
| `lib/features/features.dart` | Add `export 'focus_mode/focus_mode.dart'` |
| `lib/features/practice/practice.dart` | Add data repo exports if not already present |
| `lib/features/lessons/lessons.dart` | Add data repo exports |
| `lib/features/subjects/subject_feature.dart` | Add data repo exports |
| `lib/features/sessions/sessions.dart` | Add data repo exports |
| `lib/features/planner/planner.dart` | Barrels for non-existent data/ directories |
| `lib/features/teaching/teaching.dart` | Barrels for non-existent data/ directories |
| `lib/features/dashboard/dashboard.dart` | Barrels for non-existent data/ directories |
| `lib/features/ingestion/ingestion.dart` | Barrels for non-existent data/ directories |
| `lib/features/questions/questions_feature.dart` | Barrels for non-existent data/ directories |

## Rationale

### Architectural Drift

The codebase professes a feature-first architecture, but 14 of 16 features have zero data layer — all repositories live in a monolithic `core/data/repositories/` bucket. The two features that _do_ follow the pattern (`focus_mode`, `settings`) confirm the intended design. The remaining 12 features' data access is orphaned in core, making it unclear which feature "owns" which repository and creating an artificial barrier to introducing feature-specific abstractions.

### Inconsistency Triad

Because the repos have no shared base class, each one independently invented its own conventions:

| Dimension | Variant A | Variant B | Variant C |
|---|---|---|---|
| **Create method** | `create(item)` (7 repos) | `save(item)` (5 repos) | `savePlan(item)`, `saveMessage(item)`, etc. (4 repos) |
| **Hive init** | `Hive.box<T>(name)` — assumes pre-opened (12 repos) | `await Hive.openBox<T>(name)` — lazy opens (7 repos) | — |
| **Error handling** | `Result<T>` wrapping (3 repos: mastery_graph, question, spaced_repetition) | Raw `void`/`T?` returns — uncaught exceptions (16 repos) | Silent swallowing (`plan_adherence_repository` init failures invisible) |

### Boilerplate Duplication

The pattern `_box.values.toList().where((e) => e.someId == id).toList()` appears ~40 times across the repos. A single generic filter method on a base class would eliminate all of them.

24 hardcoded Hive box name strings (e.g. `'questions'`, `'attempts'`, `'sessions'`) are scattered across files, with `'questions'` and `'attempts'` each duplicated in 2 different repositories.

### Confirmed Bug

`lib/core/data/repositories/topic_repository.dart:45`:
```dart
topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
await create(topic);
```
The `copyWith` return value is discarded. The original unmodified `topic` is saved. This is a data-loss bug: topics created via `addParent` lose their parent linkage.

### Dead Code

`SpacedRepetitionQueries` in `spaced_repetition_repository.dart` contains two trivial methods:
- `questionsToBoxSafe(List<Question>? questions)` — just returns `questions ?? []`
- `countAllQuestions(Box<Question> box)` — just returns `box.values.length`

These add zero value and should be removed.

### Duplicate Logger

`lib/core/services/llm_usage_meter.dart:93-98` defines a second `Logger` class that bypasses the canonical `Logger` from `lib/core/utils/logger.dart`. It lacks level filtering, timestamps, and prefixes — always prints via `debugPrint`.

### `focus_mode` Is Missing a Barrel File

`lib/features/focus_mode/` has no `focus_mode.dart` barrel file and is not exported from `lib/features/features.dart`. It is imported via deep paths from 6+ files. Every other feature has a barrel file.

## Acceptance Criteria

1. All 19 repositories are relocated to their respective `lib/features/*/data/repositories/` directories, with `data/` directories created for features that lack them.

2. Every relocated repository defines Hive box name strings as constants (e.g. in a feature-level constants file or a single shared `HiveBoxNames` constant class) rather than inline string literals.

3. All 19 repositories share a common base class `Repository<T>` (or mixin) providing:
   - `late Box<T> _box` field
   - `Future<void> init(String boxName)` method
   - Generic passthrough methods: `get(String id)`, `getAll()`, `save(T item)`, `delete(String id)`
   - A protected `_filterBy<K>(K Function(T) getter, K value)` utility

4. `topic_repository.dart` bug at line 45 is fixed:
   ```dart
   final updated = topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
   await create(updated);
   ```

5. `spaced_repetition_repository.dart` dead methods (`questionsToBoxSafe`, `countAllQuestions`) are removed.

6. `llm_usage_meter.dart`'s duplicate `Logger` class is replaced with imports of `package:studyking/core/utils/logger.dart`.

7. `lib/features/focus_mode/focus_mode.dart` barrel file is created and exported from `lib/features/features.dart`.

8. All 66 import sites across `lib/` are updated to point to the new feature-local paths.

9. All repository tests in `test/core/data/repositories/` are relocated to `test/features/*/data/repositories/` matching the new structure.

10. The trivial non-repository test `test/core/data/repositories/repository_test.dart` is removed.

11. `flutter test` passes with no regressions.
