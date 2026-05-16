# Structural Deficiencies in Test File Placement and Coverage Gaps Across Feature Model Tests

## Context

The project defines strict test file placement conventions in `AGENTS.md` requiring every source file under `lib/features/*/` to have a corresponding test file at the mirrored path under `test/features/*/`. Audit of the lessons feature (and cross-feature analysis) reveals three structural categories of deficiencies: **misplaced tests**, **entirely untested models**, and **missing barrel/structural tests**.

---

## Issue 1: Misplaced Feature Model Tests in `test/core/`

**Problem:** `Lesson` and `LessonBlock` models live in `lib/features/lessons/data/models/` but their dedicated unit tests reside in `test/core/data/models/` instead of `test/features/lessons/data/models/`. This violates the AGENTS.md convention and creates a discoverability problem.

**Affected files:**
- `test/core/data/models/lesson_model_test.dart` — tests `lib/features/lessons/data/models/lesson_model.dart`
- `test/core/data/models/lesson_block_model_test.dart` — tests `lib/features/lessons/data/models/lesson_block_model.dart`

**Rationale:** The AGENTS.md table mandates `lib/features/*/models/*.dart` → `test/features/*/models/*_test.dart` (data models at `test/features/*/data/models/*_test.dart`). Placing feature-specific model tests under `test/core/` breaks the mirror convention, confuses developers, and is inconsistent with how every other feature places its tests.

---

## Issue 2: Entirely Missing Dedicated Model Tests Across Five Features

**Problem:** Twenty-two data model files across five features have zero dedicated unit tests. These models define core business objects with JSON serialization, Hive annotations, `copyWith`, and edge case handling — all untested in isolation. They are only exercised incidentally as dependencies of repository/service tests, meaning model-specific behaviors (null fallbacks, serialization roundtrips, edge cases) are not validated.

**Affected files:**

| Feature | Untested Model Files (source) |
|---|---|
| **planner** (8 models) | `engagement_nudge_model.dart`, `task_model.dart`, `student_availability_model.dart`, `roadmap_model.dart`, `plan_adherence_model.dart`, `pending_action_model.dart`, `plan_adherence_metric_model.dart`, `personal_learning_plan_model.dart` |
| **questions** (2 models) | `markscheme_model.dart`, `question_evaluation_model.dart` |
| **teaching** (2 models) | `conversation_message_model.dart`, `tutor_session_model.dart` |
| **subjects** (2 models) | `topic_progress_model.dart`, `topic_dependency_model.dart` |
| **ingestion** (1 model) | `source_model.dart` |

**Rationale:** Each of these models has nontrivial fields, JSON serialization, Hive type adapters, `copyWith` methods, and nullable field fallbacks. Without dedicated unit tests:
- Regressions in serialization format go undetected.
- Null field / missing key edge cases are unchecked.
- Hive adapter registration breaks silently.
- `copyWith` field omissions or bugs are not caught.

Well-tested peer models (e.g. the practice feature's 6 model files with 6 dedicated test files at `test/features/practice/data/models/`) demonstrate the expected pattern.

---

## Issue 3: Missing Barrel / Structural Tests for 10 of 14 Features

**Problem:** Only 4 of 14 features have a barrel test at the feature root (e.g. `test/features/dashboard/dashboard_barrel_test.dart`). The remaining 10 features lack any test verifying that their barrel export file loads without error.

**Features missing barrel tests:**
`focus_mode`, `ingestion`, `lessons`, `llm_tasks`, `mentor`, `planner`, `sessions`, `settings`, `subjects`, `teaching`

**Rationale:** A barrel test (typically named `<feature>_test.dart` or `<feature>_barrel_test.dart`) validates that all exports resolve, preventing accidental broken imports when refactoring. Features that already have one (`dashboard`, `practice`, `questions`, `quickguide`) show this is a lightweight, high-value practice.

---

## Issue 4: Stale Deprecated Test File in Subjects

**Problem:** `test/features/subjects/models/subject_model_test.dart` contains only a deprecation notice ("moved to `test/core/data/models/subject_model_test.dart`") and has been left as dead code. This file should be removed.

**Affected file:**
- `test/features/subjects/models/subject_model_test.dart`

**Rationale:** Dead test files waste developer attention, produce misleading test counts, and can cause confusion about where tests actually live.

---

## Acceptance Criteria

1. **Lesson model tests moved:** Create `test/features/lessons/data/models/lesson_model_test.dart` and `test/features/lessons/data/models/lesson_block_model_test.dart` (relocated from `test/core/data/models/`). The originals at `test/core/data/models/` may remain if they still test core models, but must not test feature models.

2. **New model tests added:** For each of the 15 untested model files in planner (8), questions (2), teaching (2), subjects (2), and ingestion (1), add a dedicated unit test file at `test/features/<feature>/data/models/<model>_test.dart` covering at minimum:
   - Constructor with required fields
   - Constructor with all fields
   - `toJson` serialization
   - `fromJson` deserialization (including missing keys)
   - Serialization roundtrip (`toJson` → `fromJson`)
   - `copyWith` (identity and field updates)
   - Null/missing field edge cases
   - Equality / hashCode

3. **Barrel tests added:** Create barrel test files (`test/features/<feature>/<feature>_test.dart` or `<feature>_barrel_test.dart`) for each of the 10 missing features, verifying all exports resolve without error.

4. **Stale file removed:** Delete `test/features/subjects/models/subject_model_test.dart`.

5. **Verification:** Run `flutter test` and confirm all existing tests continue to pass, and new tests execute successfully.
