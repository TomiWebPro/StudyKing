# Issue: Critical Test Coverage Gaps — Provider Tests with False Confidence, Untested Business Logic, Orphaned Tests

## Summary

Significant gaps exist in the test suite: (1) two provider test files assert `isNotNull` outside a Riverpod container, providing near-zero behavioural coverage; (2) the **Planner** and **Lessons** features — which contain the most complex `StateNotifier`/`FutureProvider.family` logic and arithmetic-heavy services — have **zero tests**; (3) five `SubjectRepository` test files are structurally orphaned in `test/features/subjects/` while the source lives in `lib/core/`.

---

## 1. Provider Tests with False Confidence

### `test/features/dashboard/providers/dashboard_providers_test.dart` (30 lines)

Every test follows the pattern:
```dart
test('... creates X', () {
  expect(dashboardTopicRepositoryProvider, isNotNull);
});
```

- Never uses `ProviderContainer` or a `ProviderScope`.
- Merely checks that the top-level `Provider` variable reference is non-null — **always passes if the file compiles**.
- Never verifies Riverpod dependency wiring (e.g. `dashboardStudyProgressTrackerProvider` depends on `dashboardAttemptRepositoryProvider` — never tested).
- Never instantiates the actual objects; never tests error paths or real resolution.

### `test/features/practice/providers/practice_providers_test.dart` (43 lines)

Uses `ProviderContainer` (good) but only asserts `isA<Type>()` and never overrides/stubs real Hive-backed repositories. Provides no verification that dependencies are correctly wired or that any method works.

**Fix**: Replace with tests that use `ProviderContainer` + hand-written fakes, verifying:
- Each provider resolves to a non-null instance of the expected type within a container.
- Dependency overrides are properly respected (override `dashboardAttemptRepositoryProvider` and verify `dashboardStudyProgressTrackerProvider` uses the overridden instance).
- Error states are handled (e.g. repository constructor throws).

**Affected files**:
- `test/features/dashboard/providers/dashboard_providers_test.dart` (rewrite)
- `test/features/practice/providers/practice_providers_test.dart` (rewrite)

---

## 2. Critical Untested Business Logic — Planner & Lessons Features

### `lib/features/planner/providers/planner_providers.dart` (139 lines)

Contains `PlannerState` (6 fields + `copyWith` + `clearMessages`) and `PlannerNotifier extends StateNotifier<PlannerState>` with a complex async state machine:

| Method | State transitions to test |
|---|---|
| `loadInitialData` | Calls `loadExistingPlan` + `loadRoadmaps` sequentially |
| `loadExistingPlan` | Plan found → state updated; plan null → no-op; exception → silently caught |
| `loadRoadmaps` | Loading flag set → roadmaps loaded → flag cleared; exception → flag cleared |
| `generatePlan` | 3 paths: success, null-result error, exception error |
| `createRoadmap` | Success → roadmaps refreshed + message set; failure → error set |
| `clearMessages` | Both error and success cleared |

**Total: 0 tests.**

### `lib/features/planner/services/planner_service.dart` (122 lines)

Contains `PlannerService` with 5+ dependencies and arithmetic logic for plan duration/config (`hoursValue * 60`), milestone distribution (`(days / 7).ceil().clamp(1, 52)`, `(i + 1) * days / numMilestones`).

**Total: 0 tests.**

### `lib/features/lessons/providers/lesson_providers.dart` (67 lines)

Contains 6 `FutureProvider.family` definitions + a fallback-override pattern (`llmServiceProviderForLesson` / `llmServiceProviderFallback`). Services throw `UnimplementedError` when not overridden — the override mechanism itself is untested.

**Total: 0 tests.**

### `lib/features/lessons/services/lesson_service.dart` (116 lines)

Contains arithmetic logic in `getTotalStudyMinutes`, `getCompletionRate`, `getRemainingLessonCount`, `getProgressBySubject`. Date filtering logic in `getUpcomingLessons` and `getRecentLessons`. Topic deduplication in `getTopicsWithLessons`.

**Total: 0 tests.**

**Fix**: Create four new test files:
- `test/features/planner/providers/planner_providers_test.dart`
- `test/features/planner/services/planner_service_test.dart`
- `test/features/lessons/providers/lesson_providers_test.dart`
- `test/features/lessons/services/lesson_service_test.dart`

Each should use hand-written fakes (per project convention — no mockito), `ProviderContainer`/`ProviderScope` for provider tests, and cover: data states, loading states, error states, empty/null edge cases, dependency wiring verification.

---

## 3. Orphaned Subject Repository Test Files

Five test files live under `test/features/subjects/data/repositories/`:

```
test/features/subjects/data/repositories/
  subject_repository_test.dart
  subject_repository_comprehensive_test.dart
  subject_repository_error_test.dart
  subject_repository_init_test.dart
  subject_repository_extra_edge_cases_test.dart
```

But the source class `SubjectRepository` is defined at:
```
lib/core/data/repositories/subject_repository.dart
```

These tests violate the AGENTS.md convention that test location should mirror source location. They should live under `test/core/data/repositories/`.

**Fix**: Move the five files to `test/core/data/repositories/` and update any import paths.

---

## 4. Missing Test Scenarios in Existing Service Tests

### `test/features/ingestion/services/content_pipeline_test.dart`

- `processAndClassify()` is completely untested. This method contains topic classification logic that is distinct from `processUpload`.

### `test/features/sessions/services/session_export_test.dart`

- `shareCSV()`, `shareJSON()`, `sharePDF()` are untested. These involve file I/O and platform channel calls. At minimum, verify they produce the correct payload format without actually triggering the platform share.

---

## Acceptance Criteria

- [ ] **A1**: `dashboard_providers_test.dart` is rewritten to use `ProviderContainer` + overrides, verifying wiring and error handling.
- [ ] **A2**: `practice_providers_test.dart` is rewritten to use fakes + `ProviderContainer` with overrides.
- [ ] **A3**: `test/features/planner/providers/planner_providers_test.dart` exists and covers all 6+ state transitions in `PlannerNotifier` (loading, generating, success, null-result error, exception, clearMessages, idle).
- [ ] **A4**: `test/features/planner/services/planner_service_test.dart` exists and covers `generatePlan` (null/valid), `createRoadmap` (milestone distribution, date arithmetic), `loadExistingPlan`, `loadRoadmaps`, and studentId resolution.
- [ ] **A5**: `test/features/lessons/providers/lesson_providers_test.dart` exists and verifies each `FutureProvider.family` resolves with data/error, plus the override fallback pattern.
- [ ] **A6**: `test/features/lessons/services/lesson_service_test.dart` exists and covers all arithmetic methods (`getCompletionRate`, `getTotalStudyMinutes`, `getRemainingLessonCount`, `getProgressBySubject`) with edge cases (empty lessons, all completed, none completed, zero division).
- [ ] **A7**: Five `subject_repository_*_test.dart` files moved to `test/core/data/repositories/` with corrected imports.
- [ ] **A8**: `content_pipeline_test.dart` adds tests for `processAndClassify()`.
- [ ] **A9**: `session_export_test.dart` adds tests for `shareCSV`/`shareJSON`/`sharePDF` payload generation.
