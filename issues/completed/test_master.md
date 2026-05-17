# Test Coverage & Convention Audit

**Date:** 2026-05-17
**Scope:** All `lib/features/*/` and `test/` directories cross-referenced against `AGENTS.md`

---

## How to Read This Issue

Each finding is grouped by severity and includes:
- **Affected files** with concrete line references
- **Rationale** — why it violates the AGENTS.md convention
- **Acceptance criteria** — what "fixed" looks like (verifiable actions, not vague goals)

---

## MAJOR

### M1. Missing test file for `session_utils.dart`

**Affected files:**
- `lib/features/sessions/data/repositories/session_utils.dart` (28 lines, exports `sessionIcon()` and `sessionColor()`)
- Expected path: `test/features/sessions/data/repositories/session_utils_test.dart` — **does not exist**

**Rationale:** AGENTS.md mandates a 1:1 mapping: every source file in `lib/features/*/data/repositories/*.dart` must have `test/features/*/data/repositories/*_test.dart`. This file contains two UI-facing mapping functions (`SessionType` → `IconData`/`Color`) that are referenced in presentation-layer widgets. Zero test coverage means regressions (e.g., a new `SessionType` enum value added without updating `sessionIcon`) will not be caught.

**Acceptance criteria:**
1. File `test/features/sessions/data/repositories/session_utils_test.dart` exists
2. Tests verify that each `SessionType` value maps to a non-null `IconData`
3. Tests verify that each `SessionType` value maps to a non-null `Color`
4. Tests verify correct mapping for all 4 existing types: `focus`, `practice`, `tutoring`, `manual`
5. A regression test exists: if a new `SessionType` is added without updating `sessionIcon`, the test fails at compile time (enforce exhaustive switch via `// ignore: no_default_case` or similar)

---

### M2. `data_backup_service_test.dart` contains only construction checks — no behavioral assertions

**Affected files:**
- `test/core/services/data_backup_service_test.dart` (entire file, 17 lines)

```dart
test('can be instantiated', () {
  final service = DataBackupService();
  expect(service, isA<DataBackupService>());         // construction check
});
test('methods have correct signatures', () async {
  final service = DataBackupService();
  expect(service.exportAllData, isA<Function>());     // construction check
  expect(service.exportSingleBox, isA<Function>());   // construction check
});
```

**Rationale:** AGENTS.md "Provider Test Coverage Bar" rule says every test file must include at least one **behavioral assertion** beyond `isA<...>()` or `isNotNull`. This applies to services too. The current tests verify the type exists but never call any method and verify its behavior (e.g., calling `exportAllData` returns a `Result`, or that an empty export produces a valid empty map).

**Acceptance criteria:**
1. At least one test calls `exportAllData()` or `exportSingleBox()` and asserts on the returned value
2. At least one test verifies an error path (e.g., `exportSingleBox` with a non-existent box name)
3. All existing `isA<...>()` checks may stay, but must be supplemented with behavioral assertions

---

### M3. Ingestion provider tests verify construction, not dependency wiring

**Affected files:**
- `test/features/ingestion/providers/ingestion_providers_test.dart` lines 15–298

**Deficient groups:**
| Group | Lines | Pattern | Missing |
|---|---|---|---|
| `documentExtractorProvider` | 16–65 | `isA<DocumentExtractor>()`, `same(fakeExtractor)` | Does not verify that an overridden `llmServiceProvider` actually reaches the `DocumentExtractor`'s internal service |
| `webScraperProvider` | 67–97 | `isA<WebScraper>()`, `same(a)` | No behavioral assertion at all |
| `ingestionSourceRepositoryProvider` | 99–129 | `isA<SourceRepository>()`, `same(fakeRepo)` | No behavioral assertion |
| `ingestionTopicRepositoryProvider` | 131–161 | `isA<TopicRepository>()`, `same(fakeRepo)` | No behavioral assertion |
| `ingestionQuestionRepositoryProvider` | 163–193 | `isA<QuestionRepository>()`, `same(fakeRepo)` | No behavioral assertion |
| `contentPipelineProvider` | 195–299 | Lines 239–276 claim to test "wiring" but only assert `isA<ContentPipeline>()` | Does not verify that overridden `llmServiceProvider` or `ingestionSourceRepositoryProvider` value propagates into the pipeline's internal fields |

**Rationale:** AGENTS.md "Provider Test Coverage Bar" requires "Verifying dependency wiring via overrides (e.g., a fake repo injected through a provider is used by a downstream service)." Every provider group here fails this — the override is verified to exist (via `same(fakeRepo)`) but no downstream consumer is tested with the override in place.

**Acceptance criteria:**
1. `contentPipelineProvider` tests add a fake `SourceRepository` with known state via override, then read the pipeline and verify that calling `pipeline.sourceRepository` returns the same fake instance
2. `documentExtractorProvider` tests verify that an overridden `llmServiceProvider` with a specific `modelId` results in a `DocumentExtractor` whose `modelId` matches
3. Each remaining provider group adds at least one test that injects a stateful fake and asserts on the resulting behavior

---

### M4. Lesson provider initial tests lack behavioral assertions

**Affected files:**
- `test/features/lessons/providers/lesson_providers_test.dart` lines 19–48

```dart
group('lessonRepositoryProvider', () {
  test('creates a LessonRepository and is singleton', () { ... isA<LessonRepository>() ... same(repo2) ... });
  test('can be overridden with custom repository', () { ... same(fakeRepo) ... });
  test('resolves without throwing', () { ... returnsNormally ... });
});
group('tutorSessionRepositoryProvider', () {
  // Same pattern: isA<TutorSessionRepository>(), same(repo2), same(fakeRepo), returnsNormally
});
```

**Rationale:** The `lessonServiceProvider` group (lines 72–139) does have proper behavioral assertions (wiring + error handling), so this is a partial gap. But the `lessonRepositoryProvider` and `tutorSessionRepositoryProvider` groups only verify construction and singleton semantics — no test verifies that an injected fake repository's data is actually readable through the provider.

**Acceptance criteria:**
1. `lessonRepositoryProvider` adds a test that overrides with a `FakeLessonRepository` pre-seeded with a known `Lesson`, reads the provider, then calls `getAll()` and asserts the seeded lesson is returned
2. `tutorSessionRepositoryProvider` adds a similar behavioral wiring test

---

### M5. Screen tests missing `NavigatorObserver` — navigation behavior unverified

**Affected files (10 screen tests):**
| File | Lines | Navigation present but unchecked |
|---|---|---|
| `test/features/lessons/presentation/lesson_list_screen_test.dart` | 57–91 | Uses `onGenerateRoute` for `/lesson-detail` but no observer |
| `test/features/lessons/presentation/lesson_detail_screen_test.dart` | 40–66 | Uses `onGenerateRoute` for `/tutor` but no observer |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | — | No `NavigatorObserver` or `TestNavigatorObserver` anywhere in file |
| `test/features/sessions/presentation/session_history_screen_test.dart` | — | No observer |
| `test/features/mentor/presentation/mentor_screen_test.dart` | — | No observer |
| `test/features/teaching/presentation/tutor_screen_test.dart` | — | No observer |
| `test/features/focus_mode/presentation/focus_timer_screen_test.dart` | — | No observer |
| `test/features/ingestion/presentation/upload_screen_test.dart` | — | No observer |
| `test/features/subjects/presentation/subject_list_screen_test.dart` | 35–50 | No observer (`SubjectListScreen` navigates to subject detail) |
| `test/features/subjects/presentation/subject_selection_screen_test.dart` | — | No observer |

**Also checked (these DO use NavigatorObserver ✓):** `planner_screen_test`, `practice_screen_test`, `practice_session_screen_test`, `subject_detail_screen_test`, `onboarding_dialog_widget_test`, `quick_guide_screen_test`, `lesson_booking_sheet_test`, `subject_lessons_tab_test`, `mode_navigation_widget_test`

**Rationale:** AGENTS.md says "Use `NavigatorObserver` for verifying navigation behavior." Without it, a broken route or a button that silently fails to navigate will not be caught by any test. Each screen above has at least one navigation action (tapping a lesson list item, starting a session, opening a detail page, etc.) that should be verified.

**Acceptance criteria:**
1. Each affected file adds a `TestNavigatorObserver` from `test/helpers/navigator_observer_helper.dart`
2. At least one test per screen taps a navigable UI element and asserts the observer received the expected `push` with the correct route name
3. At least one test per screen verifies that a back-navigation (`pop`) removes the route

---

### M6. Widget screen tests using real Hive I/O instead of fake repositories

**Affected files:**
| File | What it opens/stores in Hive | Lines |
|---|---|---|
| `test/features/planner/presentation/planner_screen_test.dart` | `Hive.init(...)`, `fixedStudentId` mixed with real Hive setup | 270 |
| `test/features/practice/presentation/screens/practice_session_screen_test.dart` | `Hive.init(...)` in setUp | 594, 961 |
| `test/features/ingestion/presentation/upload_screen_test.dart` | `Hive.init(...)`, opens `subjects` and `sources` boxes | 315–324 |
| `test/features/settings/presentation/profile_screen_test.dart` | `Hive.init(...)`, registers adapters, opens `settings` and `profile` boxes | 17–26 |
| `test/features/onboarding/presentation/onboarding_dialog_persistence_test.dart` | `Hive.init(...)`, opens `settings` box | 23–39 |

**Rationale:** AGENTS.md: "Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies." Real Hive I/O introduces:
- Test ordering sensitivity (leftover state from a previous test if teardown fails)
- File-system dependency (temp dir creation, permission issues on CI)
- Slower test execution (disk writes for every test run)

The `planner_screen_test.dart` already uses `fixedStudentId` (good) but still calls `Hive.init()` — the Hive dependency should be eliminated entirely by converting remaining real-repo dependencies to hand-written fakes.

**Acceptance criteria:**
1. Every `Hive.init()` call in widget test files (under `test/features/*/presentation/`) is removed
2. All repository dependencies in these screen tests are supplied via hand-written fakes through `ProviderScope` overrides — no real Hive-backed repository is instantiated
3. `upload_screen_test.dart` removes real Hive box opens and uses `FakeSubjectRepository` / `FakeSourceRepository` instead
4. `profile_screen_test.dart` replaces real `settingsRepository.init()` with a fake settings repository
5. Each fix is validated by running the affected test file in isolation (`flutter test <file>`)

---

### M7. Provider unit tests using real Hive I/O

**Affected files:**
- `test/features/dashboard/providers/dashboard_layout_providers_test.dart` lines 168–238 — initializes Hive, opens `dashboard_layout_prefs` box
- `test/features/dashboard/providers/dashboard_data_providers_test.dart` lines 326–368 — same Hive setup for layout prefs

**Rationale:** These are **provider unit tests** (no `testWidgets`, pure `ProviderContainer`), not widget tests. Unit tests should never depend on Hive I/O — the `DashboardLayoutNotifier.init()` method should be testable with a mock/stub storage layer. Using real Hive makes these tests sensitive to file-system state and slower than necessary.

**Acceptance criteria:**
1. The `DashboardLayoutNotifier` gains an injectable storage interface (or the `init()` method accepts an optional box parameter in tests)
2. Hive `init`/`openBox` calls in `dashboard_layout_providers_test.dart` and `dashboard_data_providers_test.dart` are replaced with in-memory storage
3. All existing behavioral coverage (load saved cards, keep empty set, persist toggle, persist toggle-and-untoggle) is preserved

---

## MINOR

### m1. Focus mode provider test has weak "error handling" test

**Affected files:**
- `test/features/focus_mode/providers/focus_mode_providers_test.dart` lines 68–82

```dart
test('handles error from session repository gracefully', () async {
  final repo = SessionRepository();
  final container = ProviderContainer(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(repo),
    ],
  );
  ...
  final service = container.read(studyTimerServiceProvider);
  final sessions = await service.repository.getByDate(now);
  expect(sessions.isSuccess, true);   // tests success path, not error path
  expect(sessions.data, isEmpty);
});
```

**Rationale:** The test name says "error handling" but the implementation uses a real (unconfigured) `SessionRepository` and asserts the success path returns an empty list. An actual error scenario (e.g., a repository that throws `Exception`) is not tested.

**Acceptance criteria:**
1. A `_FailingSessionRepository` (or an error flag on the existing fake) is added
2. The error-handling test is updated so the fake throws on `getByDate`, and the test asserts the service returns a `Result.failure` or handles the error gracefully

---

### m2. No error-state tests for services that only have happy-path coverage

**Affected files (services without error-path tests):**
- `test/features/ingestion/services/web_scraper_test.dart`
- `test/features/ingestion/services/document_extractor_test.dart`
- `test/features/lessons/services/lesson_service_test.dart` — needs verification (the integration test `coverage_gaps_integration_test.dart` may cover some)

**Rationale:** AGENTS.md mentions "Missing error-state tests (what happens when a service throws?)" as a category to audit. Several service test files only test the happy path (e.g., document extractor with valid input, web scraper with a valid URL). A single regression test for a network timeout, invalid document format, or database error is missing.

**Acceptance criteria:**
1. Each identified service test file gains at least one test where the injected fake throws or returns a `Result.failure`
2. The test asserts the service propagates the error correctly (returns `Result.failure`, returns a fallback value, or re-throws in a documented fashion)

---

### m3. `subjects_repository_provider_test.dart` tests repository CRUD, not provider wiring

**Affected files:**
- `test/features/subjects/providers/subjects_repository_provider_test.dart` (467 lines)

**Rationale:** This file has 60+ tests but the vast majority test `FakeSubjectRepository` CRUD operations (get, save, delete, filter by topics, add/remove topics) rather than the provider's dependency wiring. Only ~6 tests exercise the provider itself (lines 155–205). Per AGENTS.md, provider tests should focus on "dependency wiring via overrides" and "singleton behavior" — the CRUD tests belong in the repository test file.

**Acceptance criteria:**
1. CRUD operation tests (get all, get by id, save, delete, getWithTopics, getByCode, addTopicToSubject, removeTopicFromSubject) are moved to `test/features/subjects/data/repositories/subject_repository_test.dart`
2. The provider test file is reduced to ~50–80 lines focused solely on provider resolution, override propagation, singleton behavior, and error states

---

## Summary Table

| ID | Severity | Category | Files Affected |
|---|---|---|---|
| M1 | MAJOR | Missing test file | `session_utils.dart` |
| M2 | MAJOR | Construction-only checks | `data_backup_service_test.dart` |
| M3 | MAJOR | No wiring verification | `ingestion_providers_test.dart` |
| M4 | MAJOR | No wiring verification | `lesson_providers_test.dart` |
| M5 | MAJOR | Missing NavigatorObserver | 10 screen test files |
| M6 | MAJOR | Real Hive I/O in widget tests | 5 screen test files |
| M7 | MAJOR | Real Hive I/O in provider tests | 2 provider test files |
| m1 | MINOR | Weak error handling | `focus_mode_providers_test.dart` |
| m2 | MINOR | Missing error-state coverage | 3 service test files |
| m3 | MINOR | Test scope mismatch | `subjects_repository_provider_test.dart` |

---

## Things That Passed Audit ✓

- **No mockito/mocktail usage anywhere** — all fakes are hand-written (AGENTS.md convention upheld)
- **No mixed unit/widget tests** in the same file — barrel exports, widget tests, and unit tests are always separate
- **`fixedStudentId` convention** is correctly used in all planner screen tests and integration tests
- **`TestNavigatorObserver` helper** exists and is used correctly by 9 screen tests
- **Hand-written fakes** are preferred everywhere — zero `Mock` class definitions
- **`Result<T>` pattern** is consistently used for error propagation in services and fakes
- **Barrel export tests** exist for every feature module (good structural coverage baseline)
