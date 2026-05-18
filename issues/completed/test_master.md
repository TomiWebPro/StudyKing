# Test Master — Coverage & Quality Audit

**Audit Date:** 2026-05-18  
**Scope:** All `test/` files vs `lib/` source files, cross-referenced against `AGENTS.md` conventions  
**Total source files in `lib/`:** 313 (229 feature + 84 core)  
**Total test files found:** 218  
**Overall coverage by file count:** ~70% (218 / 313)  

---

## BLOCKER — App crashes or user cannot proceed

*None identified.* Every feature has at least a barrel test file. No source file in a critical UI path is completely untested.

---

## MAJOR — Feature is broken, misleading, or convention-violating

### M1 — Missing provider test: `settings_providers.dart`

| Source | Expected test | Status |
|---|---|---|
| `lib/features/settings/providers/settings_providers.dart` | `test/features/settings/providers/settings_providers_test.dart` | ❌ Does not exist |

**Rationale:** This is the only provider file in the entire `lib/features/*/providers/` tree with zero test coverage. Every other feature has a `providers/*_test.dart`. The settings providers control API key management, theme, font size, and study reminder config — all user-facing settings. A regression here would silently corrupt user preferences.

**Acceptance criteria:**
- Create `test/features/settings/providers/settings_providers_test.dart`
- Include at least one behavioral assertion (dependency wiring via override, fallback logic, or error-state handling) per AGENTS.md §Provider Test Coverage Bar
- Cover the same patterns as `test/core/providers/app_providers_test.dart` (error handling, default fallbacks, override propagation)

---

### M2 — Orphan/misnamed core service test files

#### M2a — `localization_service_test.dart` is a redirect shim

| File | Problem |
|---|---|
| `test/core/services/localization_service_test.dart` | Contains only `export '../utils/localization_helpers_test.dart';` |
| Corresponding source | `lib/core/services/localization_service.dart` does **not exist** |

**Rationale:** This file is a stale redirect that was left behind after a refactor. It does not test anything and will confuse developers who grep for test coverage.

**Acceptance criteria:**
- Delete `test/core/services/localization_service_test.dart` (the real tests live at `test/core/utils/localization_helpers_test.dart`)

#### M2b — `llm_service_test.dart` does not match any source file

| File | Problem |
|---|---|
| `test/core/services/llm_service_test.dart` | Tests `LlmService` defined in `lib/core/services/llm/llm_chat_service.dart` |
| Expected match | `test/core/services/llm/llm_chat_service_test.dart` |

**Rationale:** Per AGENTS.md test-placement conventions, the test file name should mirror the source file name. `llm_service_test.dart` does not match any `lib/core/services/llm_service.dart` source. This makes it hard to discover which source file this test belongs to.

**Acceptance criteria:**
- Rename/move `test/core/services/llm_service_test.dart` → `test/core/services/llm/llm_chat_service_test.dart`
- Update any import paths inside the file if needed

---

### M3 — 18 barrel test files with ZERO behavioral assertions (isNotNull / isA only)

These files only verify that barrel exports resolve to non-null values or correct types. Per the spirit of AGENTS.md §Provider Test Coverage Bar (and by extension, all tests), `isNotNull` and `isA` alone do not constitute meaningful coverage.

| # | File | `test()` count | Assertion type | Waste |
|---|---|---|---|---|
| 1 | `test/features/planner/planner_test.dart` | 21 | All `isNotNull` | High |
| 2 | `test/features/practice/practice_test.dart` | 16 | All `isNotNull` | High |
| 3 | `test/features/teaching/teaching_test.dart` | 16 | All `isA<Type>()` | High |
| 4 | `test/features/dashboard/dashboard_test.dart` | 11 | All `isNotNull` | Medium |
| 5 | `test/features/subjects/subjects_test.dart` | 10 | All `isA<Type>()` | Medium |
| 6 | `test/features/sessions/sessions_test.dart` | 10 | All `isNotNull/isA` | Medium |
| 7 | `test/features/settings/settings_test.dart` | 8 | All `isNotNull` | Medium |
| 8 | `test/features/lessons/lessons_test.dart` | 8 | All `isNotNull` | Medium |
| 9 | `test/features/quickguide/quickguide_test.dart` | 5 | All `isA/isA<Function>` | Low |
| 10 | `test/features/mentor/mentor_test.dart` | 5 | All `isNotNull` | Low |
| 11 | `test/features/focus_mode/focus_mode_test.dart` | 4 | All `isA/isNotNull` | Low |
| 12 | `test/features/onboarding/onboarding_test.dart` | 4 | 3x isA + 1x behavioral | Low |
| 13 | `test/features/ingestion/ingestion_test.dart` | 3 | All `isNotNull` | Low |
| 14 | `test/features/llm_tasks/llm_tasks_test.dart` | 1 | `isA` | Low |
| 15 | `test/features/planner/data/planner_data_test.dart` | 2 | All `isNotNull` | Low |
| 16 | `test/features/practice/data/practice_data_test.dart` | 3 | All `isNotNull` | Low |
| 17 | `test/features/subjects/data/subjects_data_test.dart` | 2 | All `isNotNull` | Low |
| 18 | `test/features/teaching/data/teaching_data_test.dart` | 3 | All `isNotNull` | Low |
| 19 | `test/features/questions/data/questions_data_test.dart` | 2 | All `isNotNull` | Low |

**Total: 19 files, ~134 test() calls, 0 behavioral assertions.** These tests add runtime overhead (~5-10 seconds aggregate on a cold run) with zero regression-detection value.

**Rationale:** A barrel export that fails to resolve would cause an import-time crash caught at compile/analysis time. These tests catch nothing that the Dart static analyzer does not already guarantee. They should either be removed or converted to meaningful integration smoke tests.

**Acceptance criteria:**
- **Option A (preferred):** Delete all 19 files — the compile-time check is sufficient.
- **Option B (if barrel test policy is desired):** Replace `isNotNull`/`isA` with a single `test('barrel exports resolve', () { ... })` per feature that actually constructs or calls each export symbol.

---

### M4 — Mixed unit + widget tests in 3 files

Per AGENTS.md §Unit vs Widget Tests: *"Keep unit tests and widget tests in separate files — never mix them in the same file."*

| File | Unit tests (`test()`) | Widget tests (`testWidgets()`) | Violation |
|---|---|---|---|
| `test/features/practice/presentation/screens/practice_session_screen_test.dart` | 1 (`PracticeAnswerRecord` group, ~line 1051) | ~55 | ❌ Mixed |
| `test/features/practice/presentation/screens/exam_session_screen_test.dart` | 17 (`ExamResult`, `ExamConfig`, `ExamQuestionResult` groups) | ~41 | ❌ Mixed |
| `test/features/quickguide/presentation/quick_guide_screen_test.dart` | 5 (constructor defaults group, ~line 624) | ~81 | ❌ Mixed |

**Rationale:** Mixing unit and widget tests creates confusion about test environment setup (widget tests need `pumpWidget`, `pumpAndSettle`, `MediaQuery`, etc. that unit tests do not). It also makes it harder to run unit tests in isolation (faster) vs widget tests (slower).

**Acceptance criteria:**
- Extract unit test groups into separate files:
  - `practice_session_screen_test.dart` → extract `PracticeAnswerRecord` tests to `test/features/practice/data/models/practice_answer_record_test.dart` (or similar)
  - `exam_session_screen_test.dart` → extract `ExamResult`, `ExamConfig`, `ExamQuestionResult` tests to `test/features/practice/data/models/exam_result_test.dart` (or similar)
  - `quick_guide_screen_test.dart` → extract constructor defaults test into the appropriate model test file

---

### M5 — Direct Hive I/O in widget test

| File | Problem |
|---|---|
| `test/features/focus_mode/presentation/focus_timer_screen_study_hub_test.dart` | Imports `package:hive/hive.dart`; calls `Hive.init()` and `Hive.close()` directly |

**Rationale:** AGENTS.md §Test Patterns: *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."* Direct Hive I/O in widget tests introduces flakiness from temp files, path collisions, and state leakage between test runs. It also couples the widget test to a specific storage backend.

**Acceptance criteria:**
- Remove `import 'package:hive/hive.dart'` from the test file
- Replace any StudentIdService/provider usage with `fixedStudentId` parameter injection
- Use `ProviderScope` with overrides for any remaining Hive-backed providers instead of raw `Hive.init()`/`Hive.close()`

---

### M6 — Incomplete error-state coverage in provider/service tests

The following provider/service test files have NO error-state tests:
- `test/features/onboarding/onboarding_store_test.dart` — no throwing scenarios tested
- `test/features/dashboard/providers/dashboard_layout_providers_test.dart` — no error/edge-case tests
- `test/features/questions/providers/question_providers_test.dart` — no error scenarios
- `test/features/subjects/providers/topic_repository_provider_widget_test.dart` — no error state tested

The following have only partial error coverage:
- `test/features/mentor/providers/mentor_providers_test.dart` — tests empty-data scenario but not thrown exceptions
- `test/features/teaching/providers/teaching_providers_test.dart` — tests missing model ID but not service-layer exceptions

**Rationale:** AGENTS.md §Provider Test Coverage Bar specifically mentions *"Testing that error states are handled gracefully"* as an acceptable behavioral assertion. Tests that only cover the happy path miss the most dangerous class of bugs — silent failures, uncaught exceptions, and corrupted state after errors.

**Acceptance criteria (per affected file):**
- Add at least one test where the underlying repository/service throws an exception
- Verify the provider transitions to an error state or returns a `Result.failure`
- Verify that subsequent reads can recover (invalidation / retry)

---

### M7 — Missing NavigatorObserver in 4 screen/widget test files

| File | Uses NavigatorObserver? |
|---|---|
| `test/features/practice/presentation/screens/practice_results_screen_test.dart` | ❌ No |
| `test/features/llm_tasks/presentation/llm_task_manager_screen_test.dart` | ❌ No |
| `test/features/focus_mode/presentation/widgets/focus_timer_widget_test.dart` | ❌ No |
| `test/features/focus_mode/presentation/widgets/session_summary_card_test.dart` | ❌ No |

**Rationale:** AGENTS.md §Test Patterns: *"Use `NavigatorObserver` for verifying navigation behavior."* The two screen files (`practice_results_screen`, `llm_task_manager_screen`) may contain navigable buttons or tap targets whose navigation is untested. The two widget files (`focus_timer_widget`, `session_summary_card`) are simpler rendering tests where NavigatorObserver may not be needed, but the convention still recommends it.

**Acceptance criteria:**
- Add `TestNavigatorObserver` to all four files
- For screen files, verify that any `Navigator.push`/`pop` calls are intercepted and asserted
- For widget files, add `TestNavigatorObserver` even if no navigation is expected (defense-in-depth)

---

## MINOR — Code quality / UX friction

### m1 — Uses `MockClient` from `package:http/testing.dart` instead of hand-written fakes

3 files use `MockClient`, totaling 47 invocations:

| File | `MockClient` usages |
|---|---|
| `test/core/services/llm_service_test.dart` | 36 |
| `test/core/services/llm/llm_embeddings_service_test.dart` | 8 |
| `test/core/services/llm/llm_model_service_test.dart` | 3 |

**Rationale:** AGENTS.md §Test Patterns says *"Use hand-written fake classes (not `mockito`/`mocktail`) for dependency stubbing."* While `MockClient` is part of the `http` package's own test utilities (not an external mocking framework), it is still a pre-written mock rather than a hand-written fake. This is a minor inconsistency.

**Acceptance criteria:**
- Replace `MockClient` with hand-written `FakeHttpClient` classes that implement `BaseClient` (keep the inline callback pattern but own the fake class in the project)
- Ensure all existing test scenarios (success, error, streaming) still pass

---

### m2 — `test/core/services/llm_service_test.dart` expects tests but is duplicated across `llm/` subdirectory

The tests for `LlmService.chat()` and `LlmService.chatStream()` live in `test/core/services/llm_service_test.dart`, while tests for `llm_chat_service.dart` model config classes also exist in separate files under `test/core/services/llm/`. This creates ambiguity about which file covers which `LlmService` functionality.

**Rationale:** Moving `llm_service_test.dart` to `test/core/services/llm/llm_chat_service_test.dart` (see M2b) will resolve this naturally by aligning file names with source paths.

**Acceptance criteria:** Same as M2b.

---

### m3 — 6 provider test files lack error-state tests (duplicates M6)

See M6 for details. Listed here as a severity reminder:
- `dashboard_layout_providers_test.dart`
- `onboarding_store_test.dart`
- `question_providers_test.dart`
- `topic_repository_provider_widget_test.dart`
- `mentor_providers_test.dart` (partial)
- `teaching_providers_test.dart` (partial)

---

### m4 — `test/core/services/notification_service_test.dart` test count unknown

This test file was not analyzed in this batch. Notification service tests commonly require platform channels and are often skipped. Verify this file exists and contains meaningful behavioral tests.

---

## Integration Gaps

| Feature | Integration test exists? | Coverage |
|---|---|---|
| Dashboard + Planner | `test/integration/dashboard_planner_integration_test.dart` | ✅ |
| Mentor + Sessions | `test/integration/mentor_sessions_integration_test.dart` | ✅ |
| Practice + Teaching | `test/integration/practice_teaching_integration_test.dart` | ✅ |
| Onboarding app flow | `test/integration/onboarding_app_flow_test.dart` | ✅ |
| End-to-end | `test/integration/e2e_test.dart` | ✅ |
| Ingestion → Lessons | ❌ Missing | No integration test covering the ingestion-to-lesson pipeline |
| Focus Mode → Sessions | ❌ Missing | No integration test covering focus timer completion feeding into session history |
| Planner → Mentor nudges | ❌ Missing | No integration test covering planner adherence triggering mentor nudges |
| Teaching → Practice (mistake review) | ❌ Missing | No integration test covering tutor session generating practice review items |
| Settings → LLM providers | ❌ Missing | No integration test covering API key/config changes propagating to LLM service |

**Rationale:** Integration tests catch cross-feature regressions that unit tests miss. The 5 existing integration tests cover the core flows, but several important cross-cutting paths are untested.

**Acceptance criteria (per missing integration test):**
- Write or plan an integration test for each of the 5 gaps
- Each integration test should cover at least one successful end-to-end data flow and one failure/error path

---

## Raw Data Summary

```
Metric                              Value
─────────────────────────────────────────────
Total lib/ source files              313
Total test files                     218
File-level coverage rate            ~70%
Source files with NO test              1  (settings/providers/settings_providers.dart)
Barrel files with 0 behavioral        19
Files with mixed unit+widget            3
Files with direct Hive I/O              1
Files using MockClient (borderline)     3
Missing integration test flows          5
```
