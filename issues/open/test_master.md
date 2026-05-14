# Test Master: Coverage Gaps, Fragile Test Patterns, and Structural Issues

## Issue Overview

This issue documents high-value test improvements identified across the codebase. It covers: (1) a critical production bug hidden by missing test coverage, (2) fragile/excessively basic tests that give false confidence, (3) structural test file placement violations against `AGENTS.md`, and (4) missing edge-case scenarios in the teaching feature.

---

## 1. CRITICAL: `ConversationManager.toSession()` Throws `StateError` When Called With No Messages

**Affected file:** `lib/features/teaching/services/conversation_manager.dart:328`

```dart
startTime: _messages.first.timestamp,  // CRASH if _messages is empty
```

**Rationale:** `toSession()` is called by `TutorService.endLesson()` at `lib/features/teaching/services/tutor_service.dart:80`. If `endLesson()` is invoked before any messages have been exchanged (e.g., user immediately taps "End Lesson"), `_messages` is empty and `.first` throws `StateError`. No existing test exercises this path.

**Missing test scenario:** Calling `toSession()` on a freshly initialized manager (before any `sendMessage` calls).

**Severity:** High — causes an unhandled runtime crash.

**Acceptance criteria:**
- `toSession()` should handle `_messages.isEmpty` gracefully (return a session with a reasonable fallback start time, e.g. `DateTime.now()`).
- A new test in `conversation_manager_test.dart` should verify that `toSession()` does not throw when called before any messages are sent.
- A new test in `tutor_service_test.dart` should verify that `endLesson()` does not crash when the lesson ends before any messages are exchanged.

---

## 2. `_FakeTutorService` in Screen Tests Skips Critical Production Logic

**Affected file:** `test/features/teaching/presentation/tutor_screen_test.dart:53-95`

**Rationale:** The `_FakeTutorService` used in `TutorScreen` widget tests overrides `startLesson` to skip `manager.generateLessonPlan()` (line 72 in production `TutorService`), and `endLesson` is a no-op (line 94). This means:

1. The screen test never exercises the lesson plan generation flow that is part of normal `startLesson()`.
2. `endLesson()` in production saves conversation messages to the repository (`tutor_service.dart:83-85`), records mastery attempts (`tutor_service.dart:89-98`), and integrates with `SessionPlanIntegrationService` (`tutor_service.dart:100-106`) — none of this is tested in the screen test.
3. The `_endLesson` method on the screen calls `manager.generateSummary()` then `tutorService.endLesson()`, but the fake `endLesson()` does nothing, so this interactive flow is untested.

**Missing test scenarios:**
- Screen test that verifies `TutorService.endLesson()` is called when the End Lesson button is tapped.
- Screen test that verifies messages are persisted after lesson ends.

**Acceptance criteria:**
- `_FakeTutorService` should implement a realistic `endLesson()` that mimics the production flow (at minimum capturing that it was called and checking state changes).
- Add a spy or verification mechanism to confirm `endLesson()` was invoked by the screen.
- Add a test that exercises the full `startLesson → sendMessage → endLesson` cycle through the screen widget.

---

## 3. Fragile Keyword-Based Exercise Evaluation Lacks Edge-Case Coverage

**Affected files:**
- `lib/features/teaching/services/conversation_manager.dart:228-255` (`_evaluateExerciseResponse`)
- `test/features/teaching/services/conversation_manager_test.dart:193-318`

**Rationale:** Exercise evaluation uses naïve keyword matching. The test suite covers simple cases but misses:

1. **Overlapping keywords — both "correct" and "incorrect" keywords present:**
   - Input: `"I was wrong but now I understand it correctly"`
   - Both `correctKeywords.any()` and `incorrectKeywords.any()` return `true`.
   - Current logic: `isCorrect && !isIncorrect` → evaluates as incorrect (because `isIncorrect` is true).
   - No test documents this priority behavior.

2. **Empty string or whitespace-only content** passed to `_evaluateExerciseResponse`.

3. **Case sensitivity beyond simple lowercasing:** Unicode normalization, accented characters not tested.

4. **Neutral response that coincidentally contains a keyword:** E.g., "This is the right approach" → contains "right" which is in `correctKeywords`. This would incorrectly count as a correct answer.

5. **`_detectExerciseRequest` in `adaptiveReview` phase:** When `_phase == ConversationPhase.adaptiveReview` and user message does NOT contain exercise keywords, the phase transitions to `teaching`. Only one test covers this (`test at line 308`), but the transition behavior when `adaptiveReview` is reached from `feedback` with `consecutiveIncorrect >= 2` is convoluted and could be clearer.

**Acceptance criteria:**
- Add test cases for overlapping correct/incorrect keywords documenting priority behavior.
- Add test for empty/whitespace content.
- Add test for neutral phrases that contain words from the keyword lists.
- Add dedicated tests for each phase transition sequence through the state machine (`greeting → teaching → exercise → feedback → adaptiveReview → teaching/closing`).

---

## 4. `ConversationManager._buildTutorPrompt` and `_buildAdaptiveChunks` Have No Direct Test Coverage

**Affected file:** `lib/features/teaching/services/conversation_manager.dart:162-174, 191-226`

**Rationale:**
- `_buildTutorPrompt()` generates the system prompt for the LLM, which directly controls tutor behavior. The prompt templates for different `ConversationPhase` values and adaptive pace contexts are only tested indirectly through `sendMessage`, which tests the response content but not the prompt structure.
- `_buildAdaptiveChunks()` controls streaming chunk sizes based on `_adaptivePace` (chunk sizes: 3 for slow pace, 5 for normal, 10 for fast). This logic has zero direct test coverage.

**Missing test scenarios:**
- Verify that `_buildTutorPrompt()` includes the correct phase-specific instructions for each `ConversationPhase`.
- Verify that `_buildTutorPrompt()` includes pace-specific context when `adaptivePace > 1.2` or `< 0.8`.
- Verify that `_buildAdaptiveChunks` yields chunks of correct size for pace values 0.5, 1.0, and 1.5.
- Verify that `_buildAdaptiveChunks` at slow pace includes `Future.delayed`.

**Acceptance criteria:**
- Add unit tests for `_buildTutorPrompt()` that verify phase-specific content and pace context.
- Add unit tests for `_buildAdaptiveChunks()` that verify chunk size behavior at different pace values.
- Consider extracting these to be testable (package-private or `@visibleForTesting`).

---

## 5. `ConversationMemory` Integration With `ConversationManager` Not Tested

**Affected file:** `lib/core/services/llm/llm_chat_service.dart:15-58` (the `ConversationMemory` class)

**Rationale:** `ConversationManager` creates a `ConversationMemory(maxTurns: 30)` at `conversation_manager.dart:41` and uses it in `sendMessage` (calls `addUserMessage`, `addAssistantMessage`, and passes it to `llmService.chatStream` as `memory`). However:

1. No test verifies that `ConversationManager` properly populates the memory during `sendMessage`.
2. No test verifies that memory exceeding `maxTurns * 2` (60 messages) is trimmed.
3. The `fromConversationMessages` static method filters out streaming messages — no test covers this filtering behavior.
4. `ConversationMemory` itself (`lib/core/services/llm/llm_chat_service.dart`) has no dedicated test file at all (`test/core/services/llm/llm_chat_service_test.dart` does not exist).

**Acceptance criteria:**
- Add `ConversationMemory` unit tests in a new file at `test/core/services/llm/llm_chat_service_test.dart` covering: message addition, maxTurns trimming, `fromConversationMessages` streaming filter, `getRecent`, `clear`.
- Add a test in `conversation_manager_test.dart` that verifies memory is populated after `sendMessage`.

---

## 6. Test File Placement Violations Against `AGENTS.md`

### 6a. Orphaned Test File

**File:** `test/models/settings_model_test.dart`

**Rationale:** There is no `lib/models/` directory. This file tests `SettingsAPIKey`, `UsageRecord`, and `LLMSettingsModel` from `lib/features/settings/data/models/settings_model.dart` and `lib/core/data/models/llm_models.dart`. Both of these source locations already have corresponding test files:
- `test/features/settings/data/models/settings_model_test.dart` (duplicate tests for `SettingsAPIKey`)
- `test/core/data/models/llm_models_test.dart` (duplicate tests for `UsageRecord`, `LLMSettingsModel`)

This file is entirely redundant and should be removed.

### 6b. Misplaced Test File

**File:** `test/features/settings/data/models_test.dart`

**Rationale:** Per `AGENTS.md`, the convention is that a source file at `lib/features/*/data/models/*.dart` should have its test at `test/features/*/data/models/*_test.dart`. However, this file lives at `test/features/settings/data/models_test.dart` — one level up from where it should be. It sits *alongside* the `models/` directory rather than *inside* it. (Note: the test file itself tests `SettingsBox`, `UserProfile`, and their Hive adapters, which could be split into separate files matching the source structure.)

Additionally, this file **mixes unit tests and a widget test** in a single file (`testWidgets` on line 203), which violates the `AGENTS.md` directive "Keep unit tests and widget tests in separate files."

### 6c. Practice Model Test Path Mismatch

**File:** `test/features/practice/models/practice_models_test.dart`

**Rationale:** Source file `lib/features/practice/presentation/models/practice_models.dart` but test is at `test/features/practice/models/practice_models_test.dart`. Per convention, the test should mirror the source path: `test/features/practice/presentation/models/practice_models_test.dart`.

### 6d. Deprecated File Still Present

**File:** `test/features/subjects/models/subject_model_test.dart`

**Rationale:** This file contains only a deprecation notice saying the test moved to `test/core/data/models/subject_model_test.dart`. The new file exists, but the old stub remains. Should be removed to avoid confusion.

**Acceptance criteria:**
- Remove `test/models/settings_model_test.dart` (redundant/orphaned).
- Move `test/features/settings/data/models_test.dart` to `test/features/settings/data/models/*_test.dart` and split unit/widget tests.
- Move `test/features/practice/models/practice_models_test.dart` to `test/features/practice/presentation/models/practice_models_test.dart`.
- Remove `test/features/subjects/models/subject_model_test.dart` (deprecated stub).

---

## 7. Duplicated `FakeLlmService` Across Three Test Files

**Affected files:**
- `test/features/teaching/services/tutor_service_test.dart:66-96`
- `test/features/teaching/services/conversation_manager_test.dart:8-45`
- `test/features/teaching/presentation/tutor_screen_test.dart:21-51`

**Rationale:** The same `FakeLlmService` (extending `LlmService`) is defined three times with subtly different internal behavior. This violates DRY, increases maintenance burden when the `LlmService` interface changes, and risks behavioral drift between the fakes.

For example:
- `tutor_service_test.dart` fake always returns the same JSON lesson plan and yields `'Tutor response'`.
- `conversation_manager_test.dart` fake has configurable `chatResponse`, `streamResponse`, `summaryResponse` fields.
- `tutor_screen_test.dart` fake dynamically includes the input message in the stream response (`'Mock tutor response for: $message'`).

**Acceptance criteria:**
- Extract a single `FakeLlmService` into a shared test utility file (e.g., `test/helpers/fake_llm_service.dart`).
- Make behavior configurable (configurable response strings, ability to simulate errors).
- Update all three test files to import the shared fake.

---

## 8. `generateLessonPlan` No Validation of Malformed LLM Response

**Affected file:** `lib/features/teaching/services/conversation_manager.dart:63-93`

**Rationale:** `generateLessonPlan()` sends a prompt requesting JSON and returns the raw `String` from `_llmService.chat()`. The response is then passed to `TutorService.startLesson()` at `tutor_service.dart:69` where it's stored as `lessonPlanJson`. No validation ensures the response is valid JSON or contains the expected fields (`goals`, `sections`, `checkpoints`, `estimatedDifficulty`). A malformed response silently propagates as an opaque string.

**Missing test scenarios:**
- Test that `generateLessonPlan()` handles (or propagates) a non-JSON response.
- Test that a response with only partial fields still works at the storage layer.
- Consider adding validation and error handling in the production code.

**Acceptance criteria:**
- Add a test for `generateLessonPlan()` that returns an invalid JSON string and verifies the behavior (either error is thrown or the raw string is preserved).
- Add a test for the JSON parsing path in `TutorService.startLesson()` to document current behavior.

---

## 9. Planner Service Uncovered Public Methods

**Affected file:** `lib/features/planner/services/planner_service.dart`

**Uncovered methods:**
- `createRoadmapFromGoal()` (thin delegation to `createRoadmap()`)
- `regeneratePlanFromAdherence()` (delegates to `planAdapter.suggestRegeneration()`)

**Rationale:** Although these are thin wrappers, they are public API of `PlannerService`. Without tests, a refactor that changes their semantics could go undetected.

**Acceptance criteria:**
- Add unit tests for `createRoadmapFromGoal()` and `regeneratePlanFromAdherence()` in `planner_service_test.dart`.
- Each test should verify delegation behavior (correct arguments passed, correct return value forwarded).

---

## 10. Session Export Service Uncovered Share Methods

**Affected file:** `lib/features/sessions/services/session_export_service.dart`

**Uncovered methods:** `shareCSV()`, `shareJSON()`, `sharePDF()`

**Rationale:** These methods depend on `share_plus` (`Share.shareXFiles`) which makes unit testing difficult. However, they are public API and currently have zero coverage. Consider extracting the platform dependency behind an injectable interface so these can be unit-tested.

**Acceptance criteria:**
- (Optional/Stretch) Refactor `SessionExportService` to accept a `ShareService` interface, allowing the share methods to be unit-tested.
- At minimum, document in a comment that these three methods are not unit-tested because of the platform dependency.
