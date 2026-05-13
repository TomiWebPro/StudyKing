# Critical Test Coverage Gaps & Improvements for Teaching Feature

## Context

The `lib/features/teaching/` module implements an AI-powered tutor with LLM streaming, adaptive conversation pacing, exercise evaluation, and lesson lifecycle management. It is one of the most complex modules in the project (5 source files, ~1000+ lines total), yet it has **zero test coverage**. Meanwhile, some other feature tests (e.g. `lesson_presentation_test.dart`, `topic_list_screen_test.dart`) test raw Flutter primitives rather than actual application widgets.

## Affected Files

1. **`lib/features/teaching/presentation/tutor_screen.dart`** — StatefulWidget with timer, LLM streaming, lesson lifecycle
2. **`lib/features/teaching/presentation/widgets/chat_bubble.dart`** — Chat bubble with role-based styling, streaming dots
3. **`lib/features/teaching/presentation/widgets/lesson_progress_bar.dart`** — Progress bar with color-coded time states
4. **`lib/features/teaching/services/conversation_manager.dart`** — State machine (6 phases), adaptive pacing, exercise evaluation
5. **`lib/features/teaching/services/tutor_service.dart`** — Orchestrates lesson start/end, persistence, mastery recording

## Rationale

### Gap 1: Zero coverage for the teaching feature

Every other feature module has at least some tests. Teaching has none. This is especially problematic because:

- **`ConversationManager._evaluateExerciseResponse`** (`conversation_manager.dart:228-255`) uses fragile keyword-matching to determine if the student's free-text response is correct/incorrect. A response like "That doesn't sound right" would be counted as **correct** (contains "right"). A response like "No, I don't understand" containing "no" would be counted as **incorrect** even if the student's actual answer was correct. There are no tests for the keyword lists, confidence ratings, or adaptive pace adjustments.

- **`TutorService.startLesson/endLesson`** (`tutor_service.dart:28-100`) orchestrates database persistence, lesson plan generation via LLM, and mastery graph recording. Zero tests for: correct session creation, message persistence on end-lesson, mastery recording conditions (only records if `questionsAsked > 0`), edge cases (empty messages, duplicate saves).

- **`TutorScreen._initializeTutor`** (`tutor_screen.dart:52-68`) hardcodes `LlmService` with an empty `apiKey: ''` and `MasteryGraphService`. This makes the screen untestable — there is no way to inject fake dependencies. This is a design flaw that blocks widget-level testing.

- **`LessonProgressBar`** (`lesson_progress_bar.dart`) has three visual states: normal (blue), warning (orange, <=5 min remaining), and overtime (red). None are tested.

- **`ChatBubble`** (`chat_bubble.dart`) has conditional rendering for streaming vs. streaming-complete states, role-based alignment, and sender label visibility. None tested.

### Gap 2: Tests that test Flutter framework, not application code

Files like `lesson_presentation_test.dart` and `topic_list_screen_test.dart` contain tests that re-implement widget trees inline with raw `CircularProgressIndicator`, `ListView`, `Card`, etc. rather than importing and testing the actual `TopicListScreen`, `LessonListScreen`, etc. widgets from `lib/features/lessons/presentation/`. For example:

- `lesson_presentation_test.dart:148-158` wraps a `CircularProgressIndicator` in a `MaterialApp` — this tests Flutter's built-in widget, not any application code.
- `topic_list_screen_test.dart:113-122` does the same pattern.

These tests provide near-zero regression value and create maintenance burden.

### Gap 3: Orphaned test files outside feature structure

Several test files live outside the `test/features/` hierarchy:
- `test/validation/answer_test.dart` — should be `test/features/questions/services/`
- `test/repository/repository_test.dart` — should be `test/features/subjects/data/repositories/` or similar
- `test/screens/practice_test.dart` — should be `test/features/practice/`
- `test/models/llm_models_test.dart` — should be under appropriate feature

This makes it harder to assess feature-level coverage and maintain test placement conventions.

### Gap 4: ConversationManager adaptive chunking bug

`ConversationManager._buildAdaptiveChunks` (`conversation_manager.dart:162-174`) yields progressively larger chunks of the **entire accumulated buffer** on each iteration, not just the new content. This means the consuming stream receives repeated content. This is likely a bug and has no test coverage.

## Acceptance Criteria

1. **Add unit tests for `ConversationManager`:**
   - Test all 6 conversation phases and transitions
   - Test `_evaluateExerciseResponse` with controlled inputs covering correct, incorrect, and ambiguous student responses
   - Test `confidenceRating` calculation at various exercise counts and correct/incorrect ratios
   - Test `adaptivePace` adjustments (bounds clamping at 0.5/1.5, increment/decrement by 0.15)
   - Test `_buildAdaptiveChunks` to verify only new content is yielded (regression for the chunking bug)
   - Test `generateLessonPlan` and `generateSummary` with mock `LlmService`

2. **Add widget tests for `ChatBubble`:**
   - Test rendering for `MessageRole.student` vs `MessageRole.tutor`
   - Test streaming state (animated dots visible when `isStreaming` and content is empty)
   - Test sender label visibility via `showSender` parameter
   - Test theme-aware colors applied correctly

3. **Add widget tests for `LessonProgressBar`:**
   - Test normal state (elapsed < planned)
   - Test warning state (remaining <= 5 minutes) — orange bar
   - Test overtime state (elapsed > planned) — red bar
   - Test color-coded text for remaining time

4. **Refactor `TutorScreen` for testability:**
   - Inject `TutorService` (and its dependencies) via constructor or provider rather than hardcoding in `_initializeTutor`
   - Add widget tests verifying loading state, progress bar visibility, message list population, and end-lesson dialog

5. **Add unit tests for `TutorService`:**
   - Test `startLesson` creates session, initializes manager, generates lesson plan
   - Test `endLesson` saves messages, saves final session, records mastery (only when questions asked)
   - Test `getLessonHistory`, `getSessionMessages`, `getStats` delegation to repositories
   - Test edge cases: `endLesson` with no manager, empty messages list, `questionsAsked == 0`

6. **Relocate orphaned tests:**
   - Move `test/validation/answer_test.dart` → `test/features/questions/services/`
   - Move `test/repository/repository_test.dart` → appropriate feature
   - Move `test/screens/practice_test.dart` → `test/features/practice/`
   - Move `test/models/llm_models_test.dart` → appropriate feature

7. **Remove or replace low-value tests in `lesson_presentation_test.dart` and `topic_list_screen_test.dart`** that test Flutter built-in widgets rather than application code — replace with actual widget-level tests that import and exercise the real screen widgets.
