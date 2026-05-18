# Test Coverage & Quality Audit

**Auditor:** Test Master  
**Date:** 2026-05-18  
**Scope:** All `lib/features/*/` and `lib/core/*/` vs. `test/` — cross-referenced against `AGENTS.md` conventions  

---

## Executive Summary

The StudyKing codebase has **exceptional breadth** of test coverage (~99.6% file-to-test mapping, ~268 test files across ~261 source files). However, **depth is inconsistent** — several test files are empty shells, provider tests miss behavioral assertions, and ~35 tests bypass the project's own faking conventions by calling `Hive.init()` / `Hive.openBox()` directly.

| Metric | Value |
|---|---|
| Source files requiring tests | ~261 |
| Test files | ~268 (including orphan/extra) |
| File-to-file coverage | ~99.6% |
| Mockito/mocktail usage | **0 files** (good) |
| Hand-written fakes usage | ~95% of tests (good) |
| `NavigatorObserver` in widget tests | Widespread (good) |
| Tests calling `Hive.*` directly | **35 files** (violates convention) |
| Construction-only no-op tests | **2** (`focus_practice_service_test`, `lesson_agent_service_test`) |
| Provider tests without behavioral assertions | **2** (`settings_providers_test`, `llm_task_providers_test`) |
| Source files with zero test coverage | **3** (`subject_topics_tab.dart`, `topic_dependency_dialog.dart`, `topic_edit_dialog.dart`) |

---

## BLOCKER — App crashes or user cannot proceed

*None identified.* Every service, repository, adapter, provider, presentation screen, and core utility has at least a construction test. No untested code paths that would crash the app on startup.

---

## MAJOR — Feature is broken or misleading

### M1. Two service tests are no-ops (construction-only)

**Files:**
- `test/features/focus_mode/services/focus_practice_service_test.dart`
- `test/features/lessons/services/lesson_agent_service_test.dart`

**Current content (identical pattern):**
```dart
test('can be constructed', () {
  expect(FooService, isNotNull);
});
```

**Rationale:** Checking `isNotNull` on a *Type* (`FocusPracticeService`, `LessonAgentService`) passes trivially — the class is loaded by the Dart VM. These tests verify nothing about construction, behaviour, or error handling. They provide **zero regression protection** and create a false sense of coverage. The comment in both reads "Full integration tests would require mocking these dependencies" — yet the MentorService test at 1030 lines proves hand-written fakes are feasible for the same complexity level.

**Acceptance criteria:**
- `FocusPracticeService` test must construct the class with fake `DatabaseService`, `SessionRepository`, `AttemptRepository` and exercise at least `getDueQuestions()` and `startPracticeSession()` with seeded data.
- `LessonAgentService` test must construct with fake `LlmService`, `LessonRepository`, `DatabaseService` and exercise at least lesson generation flow.
- Both must include error-state tests (e.g., repo throws → service handles gracefully).
- Remove the `isNotNull`-on-Type pattern entirely.

---

### M2. Two provider tests lack behavioral assertions

**AGENTS.md requirement:** "Every provider test file must include at least one behavioral assertion beyond construction checks (`isA<...>()` or `isNotNull`). Acceptable behavioral assertions include: Verifying dependency wiring via overrides, Testing fallback logic, Verifying singleton behavior, Testing error-state handling."

**File: `test/features/settings/providers/settings_providers_test.dart`** (33 lines)
- Tests: `isA<DataBackupService>()`, singleton identity, override wiring → `same(fakeService)`.
- **Violation:** The "override wiring" test only checks that `same(fakeService)` returns true — this is an identity/pointer check, not a behavioural assertion. No test verifies that the provider actually *uses* the overridden service for anything.
- Source `settings_providers.dart` only has one provider (`dataBackupServiceProvider`), so the file is at least complete in scope.

**Acceptance criteria (M2a):**
- If `DataBackupService` has any method that returns data, add a test that overrides it with a fake that returns specific data, reads the provider, and asserts the data flows through.
- If `DataBackupService` is truly passive (no methods to stub), add a test that overrides with a throwing fake and verifies the provider propagates the error.

**File: `test/features/llm_tasks/providers/llm_task_providers_test.dart`** (56 lines)
- Tests: `allTasksProvider` returns empty, `activeTasksProvider` returns empty, `totalTaskTokensProvider` returns 0, `totalTaskCostProvider` returns 0.0.
- **Violation:** All four tests check only *initial empty state*. There is no test with seeded data, no override wiring verification, no error-state test, no recovery test.
- Source has 7 providers (`llmTaskServiceProvider`, `allTasksProvider`, `activeTasksProvider`, `filteredTasksProvider`, `taskTokenUsageProvider`, `taskCostProvider`, `totalTaskTokensProvider`, `totalTaskCostProvider`) but only 4 are tested, all with empty state only.

**Acceptance criteria (M2b):**
- Create a fake `LlmTaskManager` that can be seeded with tasks, token usage, and cost data.
- Verify that `allTasksProvider`, `activeTasksProvider`, `taskTokenUsageProvider`, `taskCostProvider`, `totalTaskTokensProvider`, `totalTaskCostProvider` all return the seeded data through the provider chain.
- Test `filteredTasksProvider.family` with different filters.
- Test error propagation (e.g., manager throws → provider surfaces the error).
- Verify override wiring: override `llmTaskManagerProvider` → downstream providers reflect the change.

---

### M3. Three subject widget files have zero test coverage

**Files (source, no test exists):**
| Source | Expected test path |
|---|---|
| `lib/features/subjects/presentation/widgets/subject_topics_tab.dart` (405 lines) | `test/features/subjects/presentation/widgets/subject_topics_tab_test.dart` |
| `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart` (148 lines) | `test/features/subjects/presentation/dialogs/topic_dependency_dialog_test.dart` |
| `lib/features/subjects/presentation/dialogs/topic_edit_dialog.dart` (151 lines) | `test/features/subjects/presentation/dialogs/topic_edit_dialog_test.dart` |

**Rationale:** `subject_topics_tab.dart` is a 405-line `ConsumerStatefulWidget` with 9 methods (`_loadTopics`, `_addTopic`, `_editTopic`, `_editDependencies`, `_deleteTopic`, `_updateDownstreamDeps`, `_onReorder`, `_saveTopicOrder`, `build`), direct Hive I/O (`Hive.openBox(HiveBoxNames.topics)`), error handling, dialog launches, SnackBar feedback, and i18n. This is a **high-risk, untested surface** in the UI. The two dialogs are interactive `AlertDialog` subclasses with dropdowns, checkboxes, sliders, and form validation.

**Acceptance criteria:**
- `subject_topics_tab_test.dart`: Widget test using `ProviderScope` with overrides for `topicRepositoryProvider` and `subjectsRepositoryProvider` (hand-written fakes). Must test:
  - Loading state renders `CircularProgressIndicator`.
  - Empty state shows "no topics" message and "Add Topic" button.
  - Topics list renders topic cards with reorder drag handles, edit/dependency/delete popup menus.
  - `_addTopic` flow: tapping add button opens `TopicEditDialog`, saving creates topic via repo.
  - `_deleteTopic` flow: delete with confirmation → repo.delete called, SnackBar shown.
  - `_editDependencies` flow: opens `TopicDependencyDialog`.
  - Error state: repo throws → SnackBar with error message shown.
  - Use `NavigatorObserver` to verify navigation to/from dialogs.
- `topic_dependency_dialog_test.dart`: Widget test that verifies:
  - Prerequisite checkboxes toggle correctly.
  - Mastery threshold slider updates percentage display.
  - Required toggle switch works.
  - Save button returns a `TopicDependency` via `Navigator.pop`.
  - Cancel button pops without result.
- `topic_edit_dialog_test.dart`: Widget test that verifies:
  - Title/description/syllabus text fields accept input.
  - Form validation: empty title disables save.
  - Parent topic dropdown filters correctly.
  - Edit mode pre-fills existing topic data.
  - Save returns `Topic` via `Navigator.pop`.

---

## MINOR — Code quality / UX friction

### m1. Direct Hive I/O in tests (35 files)

**AGENTS.md:** "Use `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies." The same principle extends to all Hive-backed repos.

**Files calling `Hive.init()`, `Hive.registerAdapter()`, or `Hive.openBox()` directly in tests:**
<details>
<summary>Click to expand (35 files)</summary>

```
test/core/data/database_migration_test.dart
test/core/data/hive_initializer_test.dart
test/core/data/repository_test.dart
test/core/services/instrumentation_service_test.dart
test/core/services/plan_adapter_test.dart
test/core/services/student_id_service_test.dart
test/core/services/study_progress_tracker_test.dart
test/features/dashboard/data/repositories/badge_repository_test.dart
test/features/ingestion/data/repositories/source_repository_test.dart
test/features/lessons/data/repositories/lesson_repository_test.dart
test/features/planner/data/repositories/engagement_nudge_repository_test.dart
test/features/planner/data/repositories/pending_action_repository_test.dart
test/features/planner/data/repositories/plan_adherence_repository_test.dart
test/features/planner/data/repositories/plan_repository_test.dart
test/features/planner/data/repositories/roadmap_repository_test.dart
test/features/planner/data/repositories/student_availability_repository_test.dart
test/features/planner/providers/planner_providers_test.dart
test/features/planner/services/planner_service_test.dart
test/features/practice/data/repositories/attempt_repository_test.dart
test/features/practice/data/repositories/mastery_graph_repository_test.dart
test/features/practice/data/repositories/mastery_state_repository_test.dart
test/features/practice/data/repositories/question_evaluation_repository_test.dart
test/features/practice/data/repositories/question_mastery_state_repository_test.dart
test/features/practice/data/repositories/spaced_repetition_repository_test.dart
test/features/practice/data/repositories/topic_dependency_repository_test.dart
test/features/questions/data/repositories/question_repository_test.dart
test/features/sessions/data/repositories/session_repository_test.dart
test/features/sessions/services/session_migration_service_test.dart
test/features/subjects/data/repositories/subject_repository_test.dart
test/features/subjects/data/repositories/topic_repository_test.dart
test/features/subjects/providers/subjects_repository_provider_test.dart
test/features/subjects/providers/topic_repository_provider_test.dart
test/features/teaching/data/repositories/conversation_repository_test.dart
test/features/teaching/data/repositories/tutor_session_repository_test.dart
test/main_screen_test.dart
```
</details>

**Rationale:** Direct Hive I/O creates test brittleness (filesystem dependencies, adapter registration ordering, test isolation issues). The project already has a proven pattern — `_FakeStudentIdService`, `FakePlannerService`, etc. — that eliminates Hive from tests. The 35 files above bypass this convention, making tests slower and more fragile.

**Acceptance criteria:**
- Each Hive-backed repository must have a corresponding **in-memory fake** (e.g., `_FakeSessionRepository` extending `SessionRepository` with a `Map` field).
- Repository-level tests should use these in-memory fakes, not `Hive.init()`.
- Service-level tests that currently call `Hive.init()` should inject fakes for their repository dependencies.
- Provider-level tests should override with fakes, not real Hive-backed instances.
- Exception: `test/core/data/hive_initializer_test.dart` and `test/core/data/database_migration_test.dart` test Hive infrastructure itself and must use real Hive — these are acceptable.

---

### m2. Orphaned/misplaced test files (2 files)

**File: `test/features/practice/data/repositories/spaced_repetition_repository_test.dart`** (521 lines)
- Tests `SpacedRepetitionService` via fake repos (`_FakeQuestionRepo`, `_FakeAttemptRepo`), not a repository class.
- **No matching source** at `lib/features/practice/data/repositories/spaced_repetition_repository.dart`.
- **Fix:** Rename/move to `test/features/practice/services/spaced_repetition_service_fake_repo_test.dart` or merge the behavioral tests into the existing `test/features/practice/services/spaced_repetition_service_test.dart`.

**File: `test/core/services/question_pdf_generator_test.dart`**
- Source lives at `lib/core/services/pdf_generator/question_pdf_generator.dart` (subdirectory), but the AGENTS.md mapping expects `lib/core/services/question_pdf_generator.dart`.
- **Fix:** Either update AGENTS.md to document the subdirectory, or add a barrel export in `lib/core/services/` and note the convention. (Low priority — test and source are functionally paired.)

---

### m3. `subject_form_widgets_test.dart` lacks `NavigatorObserver`

**File:** `test/features/subjects/presentation/subject_form_widgets_test.dart`
- This file tests `subject_form_widgets.dart` which includes interactive form elements with navigation (dialog launches, form submission).
- No `NavigatorObserver` usage was detected in this file, while virtually all other screen/dialog tests use it per AGENTS.md convention.

**Acceptance criteria:**
- Add `NavigatorObserver` to `pumpWidget` calls.
- Verify navigation behavior for dialog returns and back-navigation.

**Note:** The companion files `subject_lessons_tab_test.dart` (adjacent widget in same feature) does use `NavigatorObserver` — inconsistency suggests it was simply overlooked.

---

### m4. Model directory convention mismatch in AGENTS.md

**AGENTS.md states:** `lib/features/*/models/*.dart → test/features/*/models/*_test.dart`

**Actual structure:** Models live at `lib/features/*/data/models/*.dart` with tests at `test/features/*/data/models/*_test.dart`.

No files exist at the documented `lib/features/*/models/` path. All 37 feature-level model files are under `data/models/`.

**Fix:** Update AGENTS.md to reflect the actual directory structure:
```
| `lib/features/*/data/models/*.dart` | `test/features/*/data/models/*_test.dart` |
```

---

## Integration Gaps

### i1. End-to-end flows without integration test coverage

The following cross-feature integration touchpoints lack dedicated integration tests:

| Integration point | Features involved | Risk |
|---|---|---|
| Focus practice → Session recording | `focus_mode` + `sessions` | User completes focus session → timer resets but session is lost |
| Planner → Mentor nudge generation | `planner` + `mentor` | Plan adherence drops → no nudge fired |
| Practice mastery → Dashboard stats | `practice` + `dashboard` | Mastery improvements invisible on dashboard |
| Teaching → Lesson history | `teaching` + `lessons` | Tutoring sessions not saved to lesson history |
| Ingestion → Question bank | `ingestion` + `questions` | Ingested content not available as practice questions |

The existing integration tests (`dashboard_planner_integration_test.dart`, `mentor_sessions_integration_test.dart`, `e2e_test.dart`) cover only a subset of these.

**Acceptance criteria:**
- Add integration tests for at least: focus→sessions data flow, planner→mentor nudge triggering, and practice→dashboard stats aggregation.
- Integration tests should use `ProviderScope` with overrides and hand-written fakes, not real Hive.

---

## Summary of Action Items

| ID | Severity | Action | ~Effort |
|---|---|---|---|
| M1 | MAJOR | Add behavioral tests for `FocusPracticeService` and `LessonAgentService` | 1–2 days |
| M2a | MAJOR | Add behavioral assertion to `settings_providers_test.dart` | 0.5 day |
| M2b | MAJOR | Add seeded-data & error tests to `llm_task_providers_test.dart` | 1 day |
| M3 | MAJOR | Add widget tests for `subject_topics_tab`, `topic_dependency_dialog`, `topic_edit_dialog` | 2–3 days |
| m1 | MINOR | Replace Hive I/O with in-memory fakes in 35 test files | 3–5 days |
| m2 | MINOR | Rename/move `spaced_repetition_repository_test.dart` | 0.5 day |
| m3 | MINOR | Add `NavigatorObserver` to `subject_form_widgets_test.dart` | 0.5 day |
| m4 | MINOR | Update model path in AGENTS.md | 0.1 day |
| i1 | MINOR | Add cross-feature integration tests for 3 gaps | 2–3 days |

**Total estimated effort: ~10–16 days**

---

*Generated by Test Master — cross-referenced against AGENTS.md conventions for test placement, behavioral assertions, fakes policy, NavigatorObserver usage, and unit/widget separation.*
