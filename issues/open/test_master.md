# Test Coverage & Convention Audit

**Date:** 2026-05-17
**Scope:** Full cross-reference of AGENTS.md conventions against source/test tree in `lib/` and `test/`.
**Method:** Manual diff of every source file in `lib/features/*/` and `lib/core/*/` against its expected test mirror, plus content review of every provider and widget test file.

---

## BLOCKER: Widget Tests Without NavigatorObserver

**Convention:** AGENTS.md §Test Patterns — *"Use `NavigatorObserver` for verifying navigation behavior."*

31 widget/screen test files use `tester.pumpWidget` / `tester.pumpAndSettle` but **never** install a `NavigatorObserver`. These tests cannot verify that taps, swipes, or programmatic navigation actually trigger the correct route changes.

### Affected files

| Test file | Screen/widget under test |
|---|---|
| `test/features/dashboard/presentation/dashboard_screen_test.dart` | DashboardScreen |
| `test/features/lessons/presentation/lesson_list_screen_test.dart` | LessonListScreen |
| `test/features/lessons/presentation/lesson_detail_screen_test.dart` | LessonDetailScreen |
| `test/features/lessons/presentation/topic_list_screen_test.dart` | TopicListScreen |
| `test/features/focus_mode/presentation/focus_timer_screen_test.dart` | FocusTimerScreen |
| `test/features/focus_mode/presentation/widgets/focus_timer_widget_test.dart` | FocusTimerWidget |
| `test/features/ingestion/presentation/upload_screen_test.dart` | UploadScreen |
| `test/features/llm_tasks/presentation/llm_task_manager_screen_test.dart` | LlmTaskManagerScreen |
| `test/features/mentor/presentation/mentor_screen_test.dart` | MentorScreen |
| `test/features/teaching/presentation/tutor_screen_test.dart` | TutorScreen |
| `test/features/settings/presentation/settings_screen_test.dart` | SettingsScreen |
| `test/features/settings/presentation/profile_screen_test.dart` | ProfileScreen |
| `test/features/settings/presentation/api_config_screen_test.dart` | ApiConfigScreen |
| `test/features/sessions/presentation/session_tracker_screen_test.dart` | SessionTrackerScreen |
| `test/features/sessions/presentation/session_history_screen_test.dart` | SessionHistoryScreen |
| `test/features/subjects/presentation/subject_list_screen_test.dart` | SubjectListScreen |
| `test/features/subjects/presentation/subject_selection_screen_test.dart` | SubjectSelectionScreen |
| `test/features/practice/presentation/screens/exam_session_screen_test.dart` | ExamSessionScreen |
| `test/features/practice/presentation/screens/practice_results_screen_test.dart` | PracticeResultsScreen |
| `test/features/practice/presentation/widgets/mistake_review_widget_test.dart` | MistakeReviewWidget |
| `test/features/practice/presentation/widgets/practice_feedback_widget_test.dart` | PracticeFeedbackWidget |
| `test/features/quickguide/presentation/widgets/suggested_prompts_widget_test.dart` | SuggestedPromptsWidget |
| `test/features/quickguide/presentation/widgets/message_list_widget_test.dart` | MessageListWidget |
| `test/features/planner/presentation/widgets/progress_overlay_widget_test.dart` | ProgressOverlayWidget |
| `test/features/planner/presentation/widgets/calendar_view_widget_test.dart` | CalendarViewWidget |
| `test/features/questions/presentation/widgets/question_card_widget_test.dart` | QuestionCardWidget |
| `test/features/questions/presentation/widgets/canvas_drawing_widget_test.dart` | CanvasDrawingWidget |
| `test/features/questions/presentation/widgets/math_expression_widget_test.dart` | MathExpressionWidget |
| `test/features/questions/presentation/widgets/single_answer_widget_test.dart` | SingleAnswerWidget |
| `test/main_screen_test.dart` | MainScreen |
| `test/core/errors/handlers_widget_test.dart` | Error handlers |

**Rationale:** Without `NavigatorObserver`, a broken route push — e.g., pushing `/wrong-route` instead of `/correct-route` — silently passes CI. Every `pumpWidget` call that renders a screen with navigable elements should wrap the app in a `MaterialApp` with a `navigatorObservers: [observer]` and assert the pushed route name.

**Acceptance criteria:**
1. Every file above wraps its test app in `MaterialApp` with `navigatorObservers: [observer]`.
2. At least one test per file asserts the expected route after a navigation-triggering interaction (e.g., tap on a list item, button press).
3. Shared helpers (`shared_test_helpers.dart`, etc.) expose a reusable `TestNavigatorObserver`.

---

## BLOCKER: Real Hive I/O in Tests (Flakiness Risk)

**Convention:** AGENTS.md §Test Patterns — *"Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies."*

Several test files call `Hive.init()` + `Hive.openBox()` directly, creating real temp directories and disk-backed boxes. This introduces flakiness from filesystem race conditions, leftover temp directories, and adapter-registration conflicts.

### Affected files

- `test/features/onboarding/presentation/onboarding_dialog_test.dart` — `Hive.init()` in setUp, `Hive.openBox()` in test body
- `test/features/mentor/services/mentor_service_test.dart` — `Hive.init()` in setUp (line 343)
- `test/features/mentor/presentation/mentor_screen_test.dart` — `Hive.init()` (line 219)
- `test/features/dashboard/providers/dashboard_data_providers_test.dart` — imports `hive_flutter`, Hive box ops (line 5)
- `test/features/dashboard/providers/dashboard_layout_providers_test.dart` — imports `hive_flutter`, Hive box ops (line 5)
- `test/features/planner/providers/planner_providers_test.dart` — imports `hive_flutter` (line 4)
- `test/features/teaching/data/repositories/conversation_repository_test.dart` — `Hive.init()` in setUp
- `test/features/subjects/data/repositories/topic_repository_test.dart` — `Hive.init()` in setUp
- `test/features/subjects/providers/subjects_repository_provider_test.dart` — imports `hive/hive.dart` (line 3), mocks `Box<Subject>`

**Rationale:** Hive I/O tests are inherently slower, depend on filesystem state, can leave orphan temp directories, and require tearDown cleanup that may not run if a test fails early. They also require adapter registration that can conflict across test files.

**Acceptance criteria:**
1. All widget tests replace `Hive.init()` with hand-written fakes / in-memory boxes.
2. Repository tests that exercise real Hive serialization are moved to a dedicated `test/features/*/data/repositories/hive_*_test.dart` file and excluded from `--exclude-tags=hive` runs, or refactored to use fake Hive boxes.
3. Service tests that inject `StudentIdService` switch to `fixedStudentId` parameter.
4. CI adds a `flutter test --exclude-tags=hive` run for fast feedback.

---

## MAJOR: Provider Wiring Tests That Don't Verify Wiring

**Convention:** AGENTS.md §Provider Test Coverage Bar — *"Verifying dependency wiring via overrides (e.g., a fake repo injected through a provider is used by a downstream service)."*

Several provider files claim to test "X is wired to Y" but only assert `isA<ResultType>()` after overriding Y. This is a **tautology**: if the override didn't propagate, the test would still pass because the default factory also creates the same type.

### 1. `test/features/lessons/providers/lesson_providers_test.dart`

```dart
// Lines 75-85 — "is wired to lessonRepositoryProvider"
final fakeRepo = LessonRepository();
container = ProviderContainer(overrides: [lessonRepositoryProvider.overrideWithValue(fakeRepo)]);
final service = container.read(lessonServiceProvider);
expect(service, isA<LessonService>());  // ← passes even if fakeRepo was NOT injected
```

Same pattern at lines 87-97 (tutorSessionRepository wiring) and 99-109 (sessionRepository wiring). None check that `service.repository` is the overridden instance.

### 2. `test/features/teaching/providers/teaching_providers_test.dart`

```dart
// Lines 47-59 — "is wired to llmServiceProvider"
final fakeService = LlmService(...);
container = ProviderContainer(overrides: [llmServiceProvider.overrideWithValue(fakeService)]);
final evaluator = container.read(exerciseEvaluatorProvider);
expect(evaluator, isA<ExerciseEvaluator>());  // ← passes even if fake was NOT used
```

Same pattern at lines 110-121 (tutorService wired to llmService), lines 124-139 (tutorService wired to exerciseEvaluator).

### 3. `test/features/ingestion/providers/ingestion_providers_test.dart`

Lines 211-248 — three "wired to" / "uses llmService from overridden provider" tests that end with `expect(pipeline, isA<ContentPipeline>())` instead of checking `pipeline.llmService` is `same(fakeService)`.

### Contrast with correct pattern

`test/features/focus_mode/providers/focus_mode_providers_test.dart:18-28`:
```dart
final service = container.read(studyTimerServiceProvider);
expect(service.repository, same(overrideRepo));  // ✓ verifies concrete wiring
```

`test/features/sessions/providers/session_providers_test.dart:237-257`:
```dart
final result = await container.read(allSessionsProvider.future);
expect(result.data![0].id, 'wired-1');  // ✓ verifies override data flows through
```

**Acceptance criteria:**
1. Every "is wired to" assertion in the three files above is replaced with a concrete check that the overridden dependency was injected (e.g., `expect(service.someField, same(fakeRepo))` or `expect(result, contains(overrideData))`).
2. No wiring test uses `isA<ResultType>()` as its sole assertion after an override.

---

## MAJOR: Missing Error-State Tests in Providers

**Convention:** AGENTS.md §Provider Test Coverage Bar — *"Testing that error states are handled gracefully."*

| Provider test file | Missing error coverage |
|---|---|
| `test/features/lessons/providers/lesson_providers_test.dart` | Zero error-state tests. What happens when `LessonRepository.save()` throws? |
| `test/features/teaching/providers/teaching_providers_test.dart` | No error state (only `teachingModelIdProvider` has fallback logic). What happens when `llmServiceProvider` throws during `exerciseEvaluatorProvider` construction? |
| `test/features/focus_mode/providers/focus_mode_providers_test.dart` | No error-state tests. What happens when `SessionRepository.getByDate()` throws? |
| `test/features/ingestion/providers/ingestion_providers_test.dart` | No error-state tests. What happens when `documentExtractorProvider`'s LLM service fails? |

For contrast, these provider files do have error coverage:
- `dashboard_data_providers_test.dart` — tests `throwsA(isA<Exception>())` when service init fails (line 618)
- `subjects_repository_provider_test.dart` — tests `hasError` on AsyncValue after build failure (line 210)
- `planner_providers_test.dart` — multiple error-path assertions throughout (lines 837, etc.)

**Acceptance criteria:**
1. Each of the four files above adds at least one test where a dependency throws and the provider handles it gracefully (returns an error async value, falls back to empty/default, or propagates in a controlled way).
2. Tests verify both the error state AND that subsequent reads still work (provider recovers).

---

## MAJOR: Orphan Test Files (No Corresponding Source)

The following test files have no matching source file under their expected path:

| Orphan test file | Possible source | Status |
|---|---|---|
| `test/core/services/ai_model_service_test.dart` | No `lib/core/services/ai_model_service.dart` | Orphan — tests removed/renamed code? |
| `test/core/services/llm_service_test.dart` | `LlmService` is in `lib/core/services/llm/llm_chat_service.dart`, not at root services path | Mismatched path — likely should be merged into `llm/llm_chat_service_test.dart` or removed |
| `test/core/providers/settings_controller_test.dart` | No `lib/core/providers/settings_controller.dart` | Orphan — `SettingsController` lives in `app_providers.dart` |
| `test/core/constants/app_encryption_config_test.dart` | No `lib/core/constants/app_encryption_config.dart` | Orphan |
| `test/core/constants/app_production_config_test.dart` | No `lib/core/constants/app_production_config.dart` | Orphan |

**Acceptance criteria:**
1. Each orphan is either: (a) relocated to match an existing source file, (b) merged into the correct existing test, or (c) deleted if the tested code was removed.
2. CI adds a check: for every `*_test.dart` in `test/`, the corresponding source path must exist (or be a documented exception like barrel tests).

---

## MAJOR: Source Files With No Test Coverage

The following source files have no corresponding test file per the AGENTS.md mapping:

| Source file | Missing test |
|---|---|
| `lib/features/mentor/data/models/chat_message_data.dart` | `test/features/mentor/data/models/chat_message_data_test.dart` exists ✓ |
| `lib/core/data/hive_type_ids.dart` | `test/core/data/hive_type_ids_test.dart` exists ✓ |

Wait — re-verified: all source files in `lib/features/*/` have corresponding test files. The crate is fully mapped. This is good.

However, **coverage quality** varies wildly. The practice feature (37 source files, 53 test files) has extensive coverage, while teaching and lessons providers have shallow tests as noted above.

**Rationale:** While every file has a test, several tests consist of a single `expect(x, isA<X>())` construction check with zero behavioral assertions, which provides near-zero regression protection.

---

## MINOR: Hive Object Mock in Subject Repository Provider Test

`test/features/subjects/providers/subjects_repository_provider_test.dart` (line 8) implements `MockSubjectBox implements Box<Subject>`. This class overrides 8 methods but delegates to `noSuchMethod` for dozens of others. This pattern:
- Silently passes if any unimplemented `Box` method is called at runtime
- Is brittle (Hive API changes break the mock without warning)
- Defeats compile-time safety

Per AGENTS.md §Test Patterns — *"Use hand-written fake classes (not `mockito`/`mocktail`) for dependency stubbing."* While this isn't mockito, it's an incomplete fake that inherits the same risk.

**Acceptance criteria:** Replace `MockSubjectBox` with a complete `FakeSubjectBox` that explicitly implements all required `Box` methods, or refactor the test to use a `FakeSubjectRepository` instead of mocking `Box<Subject>`.

---

## MINOR: Provider Tests With Only `isNotNull` / `isA` Checks

The following provider tests contain ONLY construction checks (`isNotNull`, `isA`) without any behavioral assertion:

| File | Lines | Issue |
|---|---|---|
| `test/features/lessons/providers/lesson_providers_test.dart` | 11-15 | `lessonRepositoryProvider` test: only `expect(repo, isA<LessonRepository>())` |
| `test/features/lessons/providers/lesson_providers_test.dart` | 47-53 | `tutorSessionRepositoryProvider` test: only `isA<TutorSessionRepository>()` |
| `test/features/focus_mode/providers/focus_mode_providers_test.dart` | 10-16 | `sessionRepositoryProvider` test: only `isA<SessionRepository>()` |
| `test/features/focus_mode/providers/focus_mode_providers_test.dart` | 31-37 | `studyTimerServiceProvider` test: only `isA<StudyTimerService>()` |

These pass even if the provider's `build()` method returns a `null` that happens to be non-null — they provide zero behavioral coverage.

**Acceptance criteria:** Each bare `isA<T>()` assertion is paired with a behavioral check: at minimum, verify the instance is a singleton across reads (e.g., `expect(repo1, same(repo2))`) or test a concrete method call.

---

## MINOR: Service Error-Path Coverage Gaps

Services with no error-path tests (repository throws, network fails, LLM times out):

| Service source | Test file | Missing error coverage |
|---|---|---|
| `lib/features/ingestion/services/document_extractor.dart` | `test/features/ingestion/services/document_extractor_test.dart` | No test for LLM call failure |
| `lib/features/ingestion/services/web_scraper.dart` | `test/features/ingestion/services/web_scraper_test.dart` | No test for network failure |
| `lib/features/ingestion/services/content_pipeline.dart` | `test/features/ingestion/services/content_pipeline_test.dart` | No test for extractor/scraper failure |
| `lib/features/lessons/services/lesson_service.dart` | `test/features/lessons/services/lesson_service_test.dart` | Check if error states exist |

**Acceptance criteria:** Each service listed has at least one test where a dependency throws and the service handles it (returns error result, returns fallback data, or propagates with context).

---

## Summary Counts

| Severity | Count | Category |
|---|---|---|
| **BLOCKER** | 31 | Widget tests missing `NavigatorObserver` |
| **BLOCKER** | 9 | Tests using real Hive I/O instead of fakes |
| **MAJOR** | 3 | Provider test files with `isA`-only wiring verification |
| **MAJOR** | 4 | Provider test files with no error-state tests |
| **MAJOR** | 5 | Orphan test files (no matching source) |
| **MINOR** | 4 | Provider tests with only construction checks |
| **MINOR** | 1 | Incomplete Hive box mock |
| **MINOR** | 3+ | Service files with error-path coverage gaps |

---

## Quick Wins (Can Fix in <30 min Each)

1. Add `NavigatorObserver` to the top 3 screen tests (dashboard_screen, lesson_list_screen, settings_screen) — shared helper already exists in `test/helpers/navigator_observer_helper.dart`.
2. Remove the 5 orphan test files after verifying their content is covered elsewhere.
3. Convert the 4 bare `isA` provider assertions to singleton checks (`same(instance)`).
