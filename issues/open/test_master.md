# Test Quality and Coverage Gaps — Lessons Feature and Beyond

## Summary

A comprehensive audit of the test suite reveals several high-value improvement opportunities: critical logic paths (error handling, navigation) go untested in lessons screen tests, the pattern for dependency injection in those tests is inconsistent with the rest of the project, a test is broken (no-op assertions), and a file is duplicated. Additionally, two model files in the `mentor` feature have zero test coverage.

---

## Issue 1: Error-handling code paths are untested in all lessons screen tests

**Context:** Every `_Fake*Repository` in the lessons presentation tests defines a `shouldThrow` flag and a throw path in its overridden methods, yet **not a single test sets `shouldThrow = true` and asserts the resulting error UI**.

| File | `shouldThrow` defined? | Error state tested? |
|---|---|---|
| `topic_list_screen_test.dart` | Yes | **Broken** — sets `shouldThrow = true`, then never asserts a snackbar, error text, or any error indicator. The test name promises `'shows error snackbar with retry when load fails'` but ends without a single `expect` call related to errors. |
| `lesson_detail_screen_test.dart` | Yes | **Never** used in any test. |
| `lesson_list_screen_test.dart` | Yes | **Never** used in any test. |

**Rationale:** Error states are user-facing (snackbars, retry buttons, fallback UI). If repository throws, users see either a perpetual loading spinner or an unhandled exception. Neither is acceptable, and neither is tested.

**Affected files:**
- `test/features/lessons/presentation/topic_list_screen_test.dart` (line 91-106)
- `test/features/lessons/presentation/lesson_detail_screen_test.dart` (lines 11-31)
- `test/features/lessons/presentation/lesson_list_screen_test.dart` (lines 13-36)

**Acceptance criteria:**
- Each screen test file adds at least one test that sets `shouldThrow = true` and verifies the error UI (snackbar, error widget, or retry button) is displayed.
- The existing broken error test in `topic_list_screen_test.dart` is fixed to actually assert error behavior.

---

## Issue 2: Navigation is never verified in lessons screen tests

**Context:** `AGENTS.md` recommends using `NavigatorObserver` for verifying navigation. The practice feature follows this convention (`practice_test.dart`, `practice_session_screen_test.dart`). The lessons feature does not — screen tests tap items but never assert that a route was pushed.

| File | Tap action | Navigation verified? |
|---|---|---|
| `topic_list_screen_test.dart` | Taps topic | No assert — just `pumpAndSettle` (line 118-119) |
| `lesson_list_screen_test.dart` | Taps lesson | No assert — just `pumpAndSettle` (lines 240-241) |
| `lesson_detail_screen_test.dart` | Teaching-mode buttons exist but are never tapped | No test for `_openTutorMode` navigation at all |

**Affected files:**
- `test/features/lessons/presentation/topic_list_screen_test.dart`
- `test/features/lessons/presentation/lesson_list_screen_test.dart`
- `test/features/lessons/presentation/lesson_detail_screen_test.dart`

**Acceptance criteria:**
- Each screen test that triggers navigation injects a `NavigatorObserver` and asserts the correct route was pushed.
- `lesson_detail_screen_test.dart` adds tests that tap the teaching-mode buttons (both AppBar and bottom bar) and verify navigation to the tutor route.

---

## Issue 3: Inconsistent dependency injection pattern in lessons presentation tests

**Context:** Lessons screen tests inject dependencies via **constructor parameters** (e.g., `LessonDetailScreen(lessonRepository: _FakeLessonRepository(...))`), while the rest of the project — especially the practice feature — consistently uses `ProviderScope` with `overrides`. This creates two problems:
1. New contributors must learn two patterns.
2. The screens cannot be tested in a Riverpod-native way, meaning changes to provider wiring (e.g., refactoring a `Provider` into a `FutureProvider`) may not be caught.

**Evidence:**
- `test/features/lessons/presentation/lesson_detail_screen_test.dart` — constructor injection throughout
- `test/features/lessons/presentation/lesson_list_screen_test.dart` — constructor injection throughout
- `test/features/lessons/presentation/topic_list_screen_test.dart` — constructor injection throughout
- `test/features/practice/presentation/practice_screen_test.dart` — `ProviderScope` with overrides (reference pattern)
- `test/features/lessons/providers/lesson_providers_test.dart` — `ProviderContainer` with overrides (correct)

**Affected files:**
- `test/features/lessons/presentation/lesson_detail_screen_test.dart`
- `test/features/lessons/presentation/lesson_list_screen_test.dart`
- `test/features/lessons/presentation/topic_list_screen_test.dart`

**Acceptance criteria:**
- Lessons presentation tests are refactored to use `ProviderScope` with `overrides`, matching the convention established by the practice feature and `AGENTS.md`.

---

## Issue 4: No-op test in `topic_list_screen_test.dart`

**Context:** The test `'uses default database repository when none injected'` (lines 122-124) pumps a widget with zero assertions. It provides no value.

```dart
testWidgets('uses default database repository when none injected', (tester) async {
  await tester.pumpWidget(_buildTestApp(const TopicListScreen()));
});
```

**Affected file:**
- `test/features/lessons/presentation/topic_list_screen_test.dart`, lines 122-124

**Acceptance criteria:**
- The test is either removed or converted into a meaningful assertion (e.g., verifying that the default repository does not throw during init and loading).

---

## Issue 5: Duplicate test file for `PracticeScreen`

**Context:** Two files test the same `PracticeScreen` widget:

| File | Lines | Description |
|---|---|---|
| `test/features/practice/presentation/practice_screen_test.dart` | 436 | Thorough, 18 tests, uses `ProviderScope` |
| `test/features/practice/presentation/practice_test.dart` | 94 | 3 tests, older/overlapping |

The second file tests loading, empty state, and FAB navigation — all covered (or should be covered) by the first. Maintaining two files risks drift and confusion.

**Affected files:**
- `test/features/practice/presentation/practice_test.dart`
- `test/features/practice/presentation/practice_screen_test.dart`

**Acceptance criteria:**
- Tests in `practice_test.dart` are assessed for unique coverage (e.g., the `NavigatorObserver` FAB test). Any unique scenarios are merged into `practice_screen_test.dart`, then `practice_test.dart` is removed.

---

## Issue 6: `lib/features/mentor/models/` has zero test coverage

**Context:** Two model files in the mentor feature lack any test file:

| Source file | Test file | Status |
|---|---|---|
| `lib/features/mentor/models/mentor_action.dart` | — | **Missing** |
| `lib/features/mentor/models/progress_report.dart` | — | **Missing** |

The convention (`AGENTS.md`) requires `lib/features/*/models/*.dart` → `test/features/*/models/*_test.dart`. The directory `test/features/mentor/models/` does not exist.

**Affected files:**
- `lib/features/mentor/models/mentor_action.dart`
- `lib/features/mentor/models/progress_report.dart`

**Acceptance criteria:**
- Model tests are added for `mentor_action.dart` and `progress_report.dart`, placed in `test/features/mentor/models/`.
- Tests cover serialization (`fromJson`/`toJson`), equality, and any computed properties.

---

## File structure

```
issues/open/test_master.md
```
