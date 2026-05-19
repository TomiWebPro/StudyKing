# Test Coverage & Quality Issue

## Severity Legend

| Label | Meaning |
|---|---|
| BLOCKER | App crashes or user cannot proceed |
| MAJOR | Feature is broken or misleading |
| MINOR | Code quality / UX friction |

---

## MAJOR

### M1. Misplaced & Duplicate test: voice_controller_test.dart

`test/features/teaching/services/voice_controller_test.dart` tests `VoiceService` from `lib/core/services/voice_service.dart` but lives under the teaching feature directory. A correct, nearly identical test already exists at `test/core/services/voice_service_test.dart`.

**Rationale:** Duplicate maintenance burden; mislocation violates the AGENTS.md mapping (`lib/core/services/*` → `test/core/services/*`). If only one copy is updated, the discrepancy silently rots.

**Affected files:**
- `test/features/teaching/services/voice_controller_test.dart` (remove — duplicate)
- `test/core/services/voice_service_test.dart` (keep, may be enhanced to fill gaps in the orphaned file)

**Acceptance criteria:**
- [ ] `test/features/teaching/services/voice_controller_test.dart` is deleted.
- [ ] If any test coverage lived only in the removed file, it is migrated to `test/core/services/voice_service_test.dart`.

---

### M2. Misnamed test: subject_form_widgets_test.dart tests ColorUtils, not SubjectFormWidgets

`test/features/subjects/presentation/subject_form_widgets_test.dart` contains only `ColorUtils` tests (a core utility), but the file name implies it tests `lib/features/subjects/presentation/subject_form_widgets.dart`. The actual widget test lives in `subject_form_widgets_widget_test.dart`.

**Rationale:** The naming violates the AGENTS.md mapping and misleads developers. A future PR adding a `SubjectFormWidgets` feature may falsely assume coverage exists.

**Affected files:**
- `test/features/subjects/presentation/subject_form_widgets_test.dart`

**Acceptance criteria:**
- [ ] The ColorUtils tests are moved to `test/core/utils/color_utils_test.dart` (which already has a `color_utils_test.dart` — merge or remove).
- [ ] A proper test for `subject_form_widgets.dart` is added, or the file is removed to prevent confusion.

---

### M3. Missing error-state tests in onboarding providers

`test/features/onboarding/providers/onboarding_providers_test.dart` has zero exception-path tests. When `OnboardingService.setStorage()` or `onboardingNeededProvider` / `isFirstLaunchProvider` encounters a throwing storage backend, the provider behavior is completely untested.

**Rationale:** A crash in onboarding blocks the user from entering the app (BLOCKER-level impact in production), yet the error path is invisible to tests.

**Affected files:**
- `test/features/onboarding/providers/onboarding_providers_test.dart`

**Acceptance criteria:**
- [ ] A throwing fake storage (e.g. `_ThrowingOnboardingStorage`) is added.
- [ ] `onboardingNeededProvider` returns `true` (safe default) when storage throws.
- [ ] `isFirstLaunchProvider` returns `true` (safe default) when storage throws.
- [ ] The `tearDown` restores `HiveOnboardingStorage` even after a thrown exception.

---

### M4. Direct `StudentIdService()` instantiation in exam_session_service_test

`test/features/practice/services/exam_session_service_test.dart` lines 281, 312, 324 directly call `StudentIdService()` (a real Hive-backed class) instead of injecting `FakeStudentIdService`. This introduces an implicit Hive I/O dependency into a unit test.

**Rationale:** Violates AGENTS.md: "Use `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies." Although the test file is a service test (not a widget test), the same principle applies — direct Hive dependency can cause CI failures when Hive is not initialized, and creates hidden coupling.

**Affected files:**
- `test/features/practice/services/exam_session_service_test.dart`

**Acceptance criteria:**
- [ ] All three `StudentIdService()` instantiations are replaced with `FakeStudentIdService`.
- [ ] No `import 'package:hive/…'` remains in the test file (if present).

---

### M5. Minimal/"toy" test files with zero behavioral assertions

Three test files contain only barrel-export or construction checks (`isNotNull`, `isA<Type>()`, field access) with no behavioral assertions. These provide near-zero regression protection.

**Affected files:**

| File | Content |
|---|---|
| `test/features/onboarding/presentation/onboarding_dialog_test.dart` | Single `expect(OnboardingDialog, isA<Type>())` |
| `test/features/planner/data/planner_data_test.dart` | 2 construction checks + 1 field read |
| `test/core/data/data_test.dart` | Barrel export + `isA<Type>()` checks |

**Rationale:** These files create an illusion of coverage. A broken `OnboardingDialog` constructor parameter, for example, would still pass the `isA<Type>()` check. Per AGENTS.md "every test file must include at least one behavioral assertion beyond construction checks."

**Acceptance criteria:**
- [ ] `onboarding_dialog_test.dart` is either removed or replaced with a real behavioral test (e.g. widget rendering test in `onboarding_dialog_widget_test.dart`).
- [ ] `planner_data_test.dart` is either removed or at least one behavioral assertion is added (e.g., verifies that an adapter round-trips correctly).
- [ ] `data_test.dart` is removed (barrel exports are implicitly tested by every other test that imports `data.dart`).

---

## MINOR

### m1. Missing error-state tests across repositories

Several planner repositories lack error-path coverage. None test what happens when Hive operations throw.

**Affected files:**
- `test/features/planner/data/repositories/roadmap_repository_test.dart`
- `test/features/planner/data/repositories/pending_action_repository_test.dart`
- `test/features/planner/data/repositories/plan_adherence_repository_test.dart`
- `test/features/planner/data/repositories/student_availability_repository_test.dart`
- `test/features/planner/services/action_executor_test.dart`

**Rationale:** A Hive write failure or corrupt data in any of these repositories silently produces empty results or crashes without test visibility.

**Acceptance criteria:**
- [ ] Each mentioned test file has at least one test where the underlying Hive `Box` throws (via a fake box), and the repository returns a `Result.failure` or safe default instead of propagating the exception.

---

### m2. Direct MethodChannel dependency in tests

Two test files set up platform `MethodChannel` mock handlers. These channels require manual `setMockMethodCallHandler` and can fail if the channel name changes or if the test runs in a non-standard Flutter test environment.

**Affected files:**
- `test/features/settings/services/data_backup_service_test.dart` — `MethodChannel('plugins.flutter.io/path_provider')`
- `test/features/dashboard/presentation/dashboard_screen_test.dart` — `MethodChannel('dev.fluttercommunity.plus/share')`

**Rationale:** Fragile — any future Flutter/plugin upgrade that changes the channel name or removes the channel silently breaks the test.

**Acceptance criteria:**
- [ ] The channel handlers are wrapped in a `setUp`/`tearDown` pair that always restores the default handler.
- [ ] A comment explains which plugin version is expected (or the dependency is abstracted behind a fake service).

---

### m3. `action_executor_test.dart` missing service-level exception coverage

While `action_executor_test.dart` tests invalid/malformed action payloads, it never verifies behavior when `PlannerService` methods throw unexpected exceptions (not just return `false`).

**Rationale:** The `FakePlannerService` only returns `false` for failures; real-world `PlannerService` may throw `Exception` (e.g. Hive write failure, network timeout). The `ActionExecutor` may crash or leave dangling state.

**Acceptance criteria:**
- [ ] A throwing variant of `FakePlannerService` (or a `setThrowOnX` flag) is added.
- [ ] Tests verify that `ActionExecutor.execute` (or the relevant method) catches the exception and returns a failure result without crashing.

---

## POSITIVE FINDINGS (no action needed)

| Area | Status |
|---|---|
| **All source files have tests** | Every `lib/features/*/` source file has a corresponding `test/` file. |
| **No mockito/mocktail** | 100% hand-written fakes per AGENTS.md. |
| **No mixed unit/widget tests** | Always separate files. |
| **Provider dependency wiring** | All 8 provider test files override with fakes and verify behavioral assertions. |
| **NavigatorObserver usage** | 123+ references across widget tests; all navigation-significant screens verify via observer. |
| **fixedStudentId convention** | Widely used in planner tests; `FakeStudentIdService` used in practice tests. |

---

## Summary

| Severity | Count | Key fix |
|---|---|---|
| MAJOR | 5 | Remove duplicate file, fix misnamed test, add error-path coverage to onboarding providers, replace `StudentIdService()` with fake, eliminate toy tests |
| MINOR | 3 | Add error-state tests to 5 repositories, stabilize MethodChannel setup, add throwing-fake coverage to action executor |
