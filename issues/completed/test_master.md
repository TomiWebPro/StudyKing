# Issue: Critical Test Coverage Gaps — Shallow Widget Tests Mask Untested Core Behavior

## Context

The project has 99 test files but coverage quality is sharply bimodal. Features like **Subjects**, **Settings**, **Teaching**, **Practice**, and **Questions** have deep, well-structured tests (proper mocks, error/edge cases, full lifecycle coverage). In contrast, **QuickGuide**, **Lessons**, **Planner**, and **Integration** tests are either shallow, misplaced, or test the wrong code entirely. This creates a false sense of coverage and leaves critical bugs undiscoverable.

## Primary Findings

### 1. QuickGuide — 116-line test for a 680-line screen (17% coverage)

`test/features/quickguide/presentation/quick_guide_screen_test.dart` covers only 6 basic scenarios (rendering, empty-message rejection, 3 fallback keyword paths, keyboard submit). The following are **completely untested**:

| Missing Scenario | Source Lines | Risk |
|---|---|---|
| Suggested prompt chips (ActionChip tap, `_selectPrompt` flow) | `quick_guide_screen.dart:490–531` | User-facing feature with no test |
| Mode navigation cards (AI Tutor / Mentor tap, Navigator.push/pushNamed) | `quick_guide_screen.dart:281–343` | Navigation is broken without test |
| Help dialog (`_showHelpDialog`, AlertDialog content, dismiss) | `quick_guide_screen.dart:664–679` | Dialog may fail to render |
| Clear conversation (refresh button, `_clearConversation`, state reset) | `quick_guide_screen.dart:201–218, 237–246` | State corruption on reset |
| Error handling — LLM service exception path | `quick_guide_screen.dart:151–154` | Silent failures |
| LLM service injection — `llmService` param null vs non-null | `quick_guide_screen.dart:69–77` | Wrong service instantiation |
| Streaming state — `_isStreaming` blocks re-send, disables button | `quick_guide_screen.dart:80–81, 637–648` | Double-send bug |
| Typing indicator visibility toggle | `quick_guide_screen.dart:534–565` | Accessibility live region not tested |
| Empty state rendering | `quick_guide_screen.dart:396–421` | Initial view regression |
| `_hasInteracted` / `_showSuggestions` state transitions | `quick_guide_screen.dart:83–86, 261, 269` | UI state machine broken |
| `ConversationMemory` interaction (addUserMessage, addAssistantMessage) | `quick_guide_screen.dart:105, 167` | Memory corruption |
| Semantics/accessibility labels declared but never asserted | `quick_guide_screen.dart` (many) | Accessibility regressions |

**Root cause**: The test uses the widget's own `_fallbackResponse` path (no `LlmService` mock injected), so it only tests a private string-switch helper and not the real conversation flow. No `LlmService` fake exists.

### 2. Lessons — Tests Test Fake Widgets, Not Production Code

Three test files under `test/features/lessons/presentation/` contain **zero references** to the actual production screens (`lesson_list_screen.dart`, `topic_list_screen.dart`, `lesson_detail_screen.dart`):

| Test File | What It Actually Tests |
|---|---|
| `presentation_widget_integration_test.dart` (657 lines) | Self-defined `TestableTopicListView`, `TestableLessonListView`, `TestableLessonDetailView` + duplicated `getBlockIcon`/`getBlockTitle` helpers + duplicated model tests |
| `lesson_presentation_test.dart` (303 lines) | Identical `getBlockIcon`/`getBlockTitle` helpers + duplicated model serialization tests |
| `topic_list_screen_test.dart` (218 lines) | Duplicated model serialization tests |

- The actual `TopicListScreen` uses `database.topicRepository.getAll()` (a global singleton) + `AppErrorHandler` with retry on failure — **neither path has a single test**.
- The actual `LessonListScreen` uses `database.lessonRepository.getAll()` + `database.tutorSessionRepository.getStudentSessions()` + `StudentIdService` + live `StreamSubscription` — **completely untested**.
- The actual `LessonDetailScreen` has a live `Timer.periodic` that ticks every second — **no test verifies timer behavior or disposal**.
- The `getBlockIcon`/`getBlockTitle` helpers are duplicated across 3 files (each identical copy tests the same switch-statement), while the production code uses localized strings (`l10n.blockTypeExplanation`) that differ from the hardcoded English titles in the test helpers.

### 3. Planner — 79-line Smoke Test

`test/features/planner/presentation/planner_screen_test.dart` verifies only that 3 TextFields and a button render. The core feature — plan generation logic, API calls, schedule display — has **zero tests**. The "Generate Plan" button tap test only checks the empty-field snackbar, never tests plan creation with valid data.

### 4. Integration Test — Placeholder

`test/integration/e2e_test.dart` (95 lines) contains disconnected unit-style assertions (sorting dates, `Timer.periodic` cancellation, unrelated widget rendering) and does NOT test any real app navigation, data flow, or cross-feature integration. It provides no safety net for regressions across the system.

### 5. Structural Inconsistency in Test File Placement

| Feature | Test Structure | Problem |
|---|---|---|
| `sessions/` | Flat: `session_tracker_screen_test.dart`, `tracker_test.dart`, `history_test.dart` + ... | Redundant: same screen tested by 2 files each. Also inconsistent with other features that use `presentation/` subdirectory. |
| `quickguide/` | `presentation/quick_guide_screen_test.dart` | Uses subdirectory — consistent |
| `questions/` | `services/`, `ui/widgets/`, `models/` | Consistent |
| `lessons/` | `presentation/` | Subdirectory exists but files inside don't test presentation code |

The `tracker_test.dart` + `session_tracker_screen_test.dart` files test the same `SessionTrackerScreen` with largely identical assertions. Ditto `history_test.dart` + `session_history_screen_test.dart`. These should be consolidated.

## Affected Files

```
# QuickGuide — shallow coverage
test/features/quickguide/presentation/quick_guide_screen_test.dart
lib/features/quickguide/presentation/quick_guide_screen.dart

# Lessons — tests fake widgets, not production code
test/features/lessons/presentation/presentation_widget_integration_test.dart
test/features/lessons/presentation/lesson_presentation_test.dart
test/features/lessons/presentation/topic_list_screen_test.dart
lib/features/lessons/presentation/lesson_list_screen.dart
lib/features/lessons/presentation/topic_list_screen.dart
lib/features/lessons/presentation/lesson_detail_screen.dart

# Planner — basic smoke test
test/features/planner/presentation/planner_screen_test.dart
lib/features/planner/presentation/planner_screen.dart

# Integration — placeholder
test/integration/e2e_test.dart

# Structural issues
test/features/sessions/tracker_test.dart
test/features/sessions/session_tracker_screen_test.dart
test/features/sessions/history_test.dart
test/features/sessions/session_history_screen_test.dart
```

## Rationale

1. **False green**: The existing quickguide and planner tests pass despite exercising only trivially rendered UI. They provide no regression protection for the actual business logic (fallback routing, conversation memory, navigation, error handling).
2. **Wasted test effort in lessons**: 1,178 lines of test code that test duplicated helpers and fake widgets instead of the real screens. The real `LessonDetailScreen` timer, `TopicListScreen` error/retry flow, and `LessonListScreen` tutor-session status loading are completely uncovered.
3. **Maintenance drag**: Duplicated test code (model serialization tested in 3 files, `getBlockIcon`/`getBlockTitle` defined in 2 files) increases change cost — updating a model's JSON shape requires touching multiple test files.
4. **No integration safety net**: Without real e2e tests, cross-feature changes (e.g., changing `database` provider shape, altering `StudentIdService` behavior) can silently break multiple screens.
5. **Inconsistent conventions make it harder to know where tests should live**: Some features use flat test files, some use `presentation/` subdirectories, and sessions has redundant files.

## Acceptance Criteria

1. **QuickGuide**: Add tests for ALL of the following:
   - Suggested prompt chips render with correct labels and trigger `_sendMessage` on tap
   - Mode navigation "AI Tutor" card navigates to `TutorScreen` with empty params
   - Mode navigation "Mentor" card calls `Navigator.pushNamed('/mentor')`
   - Help dialog opens, displays title/content, dismisses on "Got it" tap
   - Clear conversation (refresh button appears after interaction, resets messages and state)
   - Send button is disabled while `_isStreaming` is true (simulated via mocked `LlmService`)
   - Typing indicator is visible during streaming and hidden after
   - `LlmService` exception is caught, fallback response is shown, streaming stops
   - Empty state renders when no messages exist
   - At minimum, verify key Semantics labels are present (accessibility)
   - Mock `LlmService` (hand-written fake) must be used — not the widget's own fallback path

2. **Lessons**: Rewrite tests to test the actual production screens:
   - `TopicListScreen`: test loading state, topic list rendering, empty state (`l10n.noTopicsYetAddSome`), error state with `AppErrorHandler` retry
   - `LessonListScreen`: test loading, lesson list rendering, empty state with "Start AI Tutoring" button, status cache (completed/inProgress icons and chips), tutor mode navigation
   - `LessonDetailScreen`: test loading, block rendering with correct localized titles and icons, timer display/formatting, dispose cancels timer
   - Remove duplicated `getBlockIcon`/`getBlockTitle` helper tests — these are private methods in the production code and should be removed from tests
   - Remove duplicated model serialization tests (model tests already exist in `test/core/`)

3. **Planner**: Extend tests to cover:
   - Form field input and state updates
   - "Generate Plan" with valid data (mock the plan creation service/future)
   - Schedule display after generation
   - Error handling when plan creation fails

4. **Integration**: Replace the placeholder with at least one meaningful end-to-end test:
   - Navigate the full app: home → subject selection → topic list → lesson detail → tutor session
   - Or: home → quick guide → send message → receive response

5. **Structural cleanup**:
   - Consolidate `tracker_test.dart` + `session_tracker_screen_test.dart` into the latter
   - Consolidate `history_test.dart` + `session_history_screen_test.dart` into the latter
   - Enforce consistent `presentation/` subdirectory for all screen-level widget tests across features
