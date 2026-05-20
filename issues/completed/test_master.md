# Test Coverage & Quality Issue (Round 2)

## Severity Legend

| Label | Meaning |
|---|---|
| BLOCKER | App crashes or user cannot proceed |
| MAJOR | Feature is broken or misleading |
| MINOR | Code quality / UX friction |

---

## MAJOR

### M1. Misplaced test files violating AGENTS.md mapping

Five test files exist at wrong locations per the AGENTS.md mapping table. Each violates the convention that `lib/features/*/X/*.dart` → `test/features/*/X/*_test.dart`.

| Source | Current test location | Correct location |
|---|---|---|
| `lib/features/ingestion/data/adapters/source_adapter.dart` | `test/core/data/source_adapter_test.dart` | `test/features/ingestion/data/adapters/source_adapter_test.dart` |
| `lib/features/sessions/data/adapters/session_adapter.dart` | `test/core/data/session_adapter_test.dart` | `test/features/sessions/data/adapters/session_adapter_test.dart` |
| `lib/features/planner/services/personal_learning_plan_service.dart` | `test/core/services/personal_learning_plan_service_test.dart` | `test/features/planner/services/personal_learning_plan_service_test.dart` |
| `lib/features/onboarding/data/models/onboarding_state.dart` | `test/features/onboarding/data/onboarding_state_test.dart` | `test/features/onboarding/data/models/onboarding_state_test.dart` |
| `lib/features/focus_mode/data/models/focus_session_model.dart` | `test/features/focus_mode/data/focus_session_model_test.dart` | `test/features/focus_mode/data/models/focus_session_model_test.dart` |

**Rationale:** Misplaced tests are invisible to convention-enforcing tooling and confuse developers. Future refactors may miss these files entirely. The first three already have their own `test/core/` mirror which creates confusion about where the "canonical" test lives.

**Acceptance criteria:**
- [ ] Each file is moved to its correct `test/features/*/` location.
- [ ] The old file is deleted (not kept as a duplicate).
- [ ] Imports in the moved file are verified to resolve correctly.
- [ ] Any file that imported the old path is updated.

---

### M2. Source files with zero test coverage

Three source files have no dedicated test file anywhere in the project:

| Source file | What's untested |
|---|---|
| `lib/features/teaching/data/adapters/tutor_session_adapter.dart` | `TutorSessionAdapter` (Hive TypeAdapter, serialization) — only transitively exercised by `conversation_message_adapter_test.dart` |
| `lib/features/ingestion/data/adapters/adapters.dart` | `registerIngestionAdapters()` — the registration call is never tested |
| `lib/features/sessions/data/adapters/adapters.dart` | `registerSessionAdapters()` — the registration call is never tested |

**Rationale:** `TutorSessionAdapter` serializes `TutorSession` with nullable fields and nested enums — any serialization regression would go undetected. The `register*Adapters()` functions are trivial but represent a gap: if Hive adapter registration fails silently, the app stores data with wrong type IDs.

**Affected files:**
- `test/features/teaching/data/adapters/tutor_session_adapter_test.dart` — needs to be created
- `test/features/ingestion/data/adapters/adapters_test.dart` — needs to be created
- `test/features/sessions/data/adapters/adapters_test.dart` — needs to be created

**Acceptance criteria:**
- [ ] `tutor_session_adapter_test.dart` covers read/write round-trip of `TutorSession` with all field variants (null, empty, populated).
- [ ] `adapters_test.dart` (ingestion) verifies `registerIngestionAdapters` registers `SourceAdapter` with correct `typeId`.
- [ ] `adapters_test.dart` (sessions) verifies `registerSessionAdapters` registers `SessionAdapter` with correct `typeId`.

---

### M3. Widget tests verifying navigation by text instead of NavigatorObserver

Per AGENTS.md: "Use `NavigatorObserver` for verifying navigation behavior." Two widget tests verify route navigation by asserting on destination page content rather than using the `TestNavigatorObserver` helper at `test/helpers/navigator_observer_helper.dart`.

| Test file | Test name | Current assertion |
|---|---|---|
| `test/features/dashboard/presentation/widgets/next_up_card_test.dart:169` | "navigates to planner when lesson tile is tapped" | `expect(find.text('Planner Page'), findsOneWidget)` |
| `test/features/dashboard/presentation/widgets/weak_areas_card_test.dart:164` | "tapping practice icon navigates to practice session" | `expect(find.text('Practice Session'), findsOneWidget)` |
| `test/features/dashboard/presentation/widgets/weak_areas_card_test.dart:181` | "tapping practice all button navigates to practice session" | `expect(find.text('Practice Session'), findsOneWidget)` |

**Rationale:** Text-based assertions are fragile (a future rename of the destination page breaks the test) and only indirectly verify that the correct route was pushed. `NavigatorObserver` directly confirms the route `RouteSettings.name` matches `AppRoutes.xxx`.

**Acceptance criteria:**
- [ ] `next_up_card_test.dart` uses `TestNavigatorObserver` and verifies `pushedRoutes.last.settings.name == AppRoutes.planner`.
- [ ] `weak_areas_card_test.dart` uses `TestNavigatorObserver` and verifies `pushedRoutes.last.settings.name == AppRoutes.practiceSession` (or equivalent).
- [ ] Text-based destination assertions are removed (the destination page content is not the widget under test).

---

### M4. Missing error-state tests in provider/repository tests

Two test files lack coverage for Hive operation failures.

| File | Missing coverage |
|---|---|
| `test/features/dashboard/providers/dashboard_layout_providers_test.dart` | `DashboardLayoutNotifier.init()` calls `Hive.openBox()` and `_box?.get()`. When Hive throws (e.g. corrupt box), the notifier should handle gracefully. No test covers this path. |
| `test/features/dashboard/data/repositories/badge_repository_test.dart` | Uses `_FakeBadgeBox` that never throws. No test covers Hive `put`/`get`/`delete` failures. |

**Rationale:** Per AGENTS.md "every provider test file must include at least one behavioral assertion" — the `dashboard_layout_providers_test.dart` passes behavioral checks but has zero error-path coverage. A crash in `DashboardLayoutNotifier.init()` leaves the dashboard in a broken state.

**Acceptance criteria:**
- [ ] `dashboard_layout_providers_test.dart` adds a throwing fake box or mock and verifies `init()` returns a safe default state when `Hive.openBox()` throws.
- [ ] `badge_repository_test.dart` adds a throwing variant of `_FakeBadgeBox` and verifies repository methods return `Result.failure` instead of crashing.

---

### M5. Construction-only barrel test: `lessons_test.dart`

`test/features/lessons/lessons_test.dart` (23 lines) contains only `isNotNull` / `isA<Type>()` assertions. It provides zero regression protection — every assertion would pass even if the exported classes had broken constructors or missing methods.

**Affected file:** `test/features/lessons/lessons_test.dart`

**Rationale:** This file creates an illusion of coverage. Per precedent in the previously completed `test_master.md` (M5), construction-only barrel tests are considered MAJOR.

**Acceptance criteria:**
- [ ] The file is either removed (barrel exports are implicitly tested by all other tests that import `lessons.dart`) or enhanced with at least one behavioral assertion (e.g. verifying `LessonRepository` round-trips a lesson, or `lessonServiceProvider` resolves to a non-null value in a `ProviderContainer`).

---

## MINOR

### m1. Hive I/O in presentation/widget tests

Three screen-level widget tests call `Hive.init()` / `Hive.openBox()` / `Hive.deleteBoxFromDisk()` in their `setUp`/`tearDown`, coupling themselves to real disk I/O. They should use fake repositories injected via `ProviderScope` overrides.

| File | Hive usage |
|---|---|
| `test/features/llm_tasks/presentation/llm_task_manager_screen_test.dart` | `Hive.init()` + `Hive.openBox()` + `Hive.deleteBoxFromDisk()` |
| `test/features/practice/presentation/screens/practice_screen_additional_test.dart` | `hive_package.Hive.init()` |
| `test/features/practice/presentation/screens/practice_session_screen_additional_test.dart` | `Hive.init()` + `Hive.deleteBoxFromDisk()` |

**Rationale:** Real Hive I/O in widget tests introduces flakiness (temp directory cleanup failures, leftover boxes), violates the "fakes over real infrastructure" convention, and slows down test execution. If the Hive box schema changes, these tests fail with cryptic serialization errors.

**Acceptance criteria:**
- [ ] Each file replaces real Hive init with fake repository overrides in `ProviderScope`.
- [ ] No `import 'package:hive/…'` remains in any of the three files.
- [ ] All `tearDown` cleanup for temp directories and box deletion is removed.

---

### m2. Hive.init() in service/provider unit tests

Four unit tests call `Hive.init()` to support internal adapter registration, even though they use fake repositories for most logic. This indicates an incomplete fake boundary.

| File | Line |
|---|---|
| `test/features/planner/services/planner_service_test.dart` | 402 |
| `test/features/planner/providers/planner_providers_test.dart` | 436 |
| `test/features/subjects/providers/topic_repository_provider_test.dart` | 372 |
| `test/features/subjects/providers/subjects_repository_provider_test.dart` | 262 |

**Rationale:** `Hive.init()` in a unit test is a red flag — it means some part of the code under test calls real Hive APIs instead of being faked out. This can cause CI failures in environments without temp directory write access and creates hidden coupling between the test and Hive's initialization state.

**Acceptance criteria:**
- [ ] Each file identifies why Hive.init() is needed and either (a) adds a fake for the component that requires it, or (b) documents the reason in a comment if unavoidable.
- [ ] `Hive.init()` is moved to the outermost `setUpAll` and paired with `Hive.deleteFromDisk()` cleanup to avoid cross-test pollution.

---

### m3. `studentIdValueProvider.overrideWith` instead of `fixedStudentId`

Three widget tests use `studentIdValueProvider.overrideWith((ref) => 'test-student')` instead of the `fixedStudentId` constructor parameter pattern recommended by AGENTS.md.

| File | Line |
|---|---|
| `test/features/lessons/presentation/lesson_list_screen_test.dart` | 76, 311 |
| `test/features/teaching/presentation/tutor_screen_test.dart` | 172 |
| `test/features/focus_mode/presentation/focus_timer_screen_study_hub_test.dart` | 306 |

**Rationale:** While functionally correct (no Hive I/O is triggered), the `fixedStudentId` pattern is preferred per AGENTS.md because it makes the dependency visible at the widget boundary and avoids importing `StudentIdService` in test files. The `tutor_screen_test.dart` also imports the full `student_id_service.dart` file (line 22) rather than just `studentIdValueProvider`.

**Acceptance criteria:**
- [ ] Each screen that accepts a `fixedStudentId` constructor parameter uses it directly in the test instead of `studentIdValueProvider.overrideWith`.
- [ ] Screens that don't accept `fixedStudentId` are left as-is (override is acceptable), but the import is narrowed to `show studentIdValueProvider` only.

---

## POSITIVE FINDINGS (no action needed)

| Area | Status |
|---|---|
| **No mockito/mocktail** | 100% hand-written fakes per AGENTS.md. |
| **No mixed unit/widget tests** | Always separate files. |
| **Provider override verification** | All provider tests verify override was used via behavioral assertions. |
| **Integration test coverage** | All 15 features are covered by at least one integration test. |
| **Error-state coverage in planner tests** | `planner_providers_test.dart`, `planner_service_test.dart`, and `action_executor_test.dart` have thorough error-path coverage. |
| **NavigatorObserver in most widget tests** | 109+ widget tests use `TestNavigatorObserver` correctly. |
| **`fixedStudentId` in planner tests** | 90+ references across planner test files. |

---

## Summary

| Severity | Count | Key fix |
|---|---|---|
| MAJOR | 5 groups (12 files) | Move 5 misplaced files, create 3 missing test files, replace text-based nav assertions with NavigatorObserver, add error-path tests to 2 provider/repo files, remove or enhance barrel test |
| MINOR | 3 groups (10 files) | Eliminate Hive I/O from 3 screen tests, reduce Hive.init() in 4 unit tests, migrate 3 widget tests to `fixedStudentId` |
