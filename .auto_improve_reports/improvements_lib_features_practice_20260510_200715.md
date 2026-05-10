# Improvement Report: `lib/features/practice`

**Generated:** 2026-05-10 20:07:15  
**Scope:** All files under `lib/features/practice/`  
**Files analyzed:** 4 files (614 + 647 + 20 + 2 = 1283 total lines)

---

## Summary

| Severity | Count |
|----------|-------|
| 🔴 Bug | 12 |
| 🟠 Performance | 3 |
| 🟡 Code Style / Maintainability | 14 |
| 🔵 Enhancement | 14 |
| **Total** | **43** |

---

## 🔴 Bugs

### BUG-01: Loading state indistinguishable from empty state
- **File:** `presentation/practice_screen.dart:98-100`
- **Description:** `_buildBody()` checks `_subjects.isEmpty` to decide whether to show the empty state. During loading, `_subjects` is still `[]` (initial value), so the empty-state UI (large icon, "No Practice Sessions Yet") is shown while data is loading. The `_isLoading` field exists (line 19) but is never consulted in `_buildBody()`.
- **Severity:** High
- **Suggested fix:** Rename `_isLoading` to `_isLoaded` (inverting logic), or check `_isLoading` in `_buildBody()` to show a `CircularProgressIndicator` while loading:
  ```dart
  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_subjects.isEmpty) return _buildEmptyState();
    // ...
  }
  ```

### BUG-02: Empty onPressed callback in empty-state button
- **File:** `presentation/practice_screen.dart:145-148`
- **Description:** The "Add Subject" button in the empty state has `onPressed: () {}` (empty closure). It does nothing when tapped but appears active. This is likely placeholder code that was never wired up.
- **Severity:** Medium
- **Suggested fix:** Wire the button to navigate to the subject creation flow, or show a SnackBar, or set `onPressed: null` to visually disable it.

### BUG-03: `_initializeSession()` called unconditionally after `_loadQuestions()` error
- **File:** `presentation/practice_session_screen.dart:134-136`
- **Description:** `_initializeSession()` is called after the `try-catch` block in `_loadQuestions()`, regardless of whether an exception was caught. If the repository call fails (network error, box not open), `_questions` is still `[]` and `_initializeSession()` shows "No Questions Available" dialog — misleading the user into thinking there are no questions when the real issue is a load failure.
- **Severity:** High
- **Suggested fix:** Move `_initializeSession()` inside the `try` block, after the successful load, or add an `else` branch that only calls it on success. Add early return in the catch block.

### BUG-04: Async fire-and-forget in `initState` with no error boundary
- **File:** `presentation/practice_session_screen.dart:68-70`
- **Description:** `_loadQuestions()` is an async method called without `await` in `initState`. Unhandled exceptions from the async gap are silently swallowed (the `catch` inside handles repository errors, but the `_initializeSession()` at line 134 runs regardless).
- **Severity:** Medium
- **Suggested fix:** Use a `.then().catchError()` pattern, or extract to a named method that handles the result properly. Alternatively, use a `WidgetsBinding.instance.addPostFrameCallback` and manage state with a loading flag.

### BUG-05: `Future.delayed` race condition on session navigation
- **File:** `presentation/practice_session_screen.dart:247-258`
- **Description:** `_completeSession()` uses `Future.delayed(const Duration(milliseconds: 500))` before navigating. If the user dismisses the screen during this 500 ms window (e.g., pressing back), the delayed callback's `mounted` check may not prevent the subsequent `Navigator.push()` from running on a disposed state, potentially causing a `ScopedQuery.refresh() was called after the widget was disposed` error or navigation on a disposed context.
- **Severity:** High
- **Suggested fix:** Remove the arbitrary delay. Use `Navigator.pushReplacement` or `pushAndRemoveUntil` directly inside `setState`, or animate the results screen inline without navigation delay.

### BUG-06: Duplicate `PracticeScreen` in navigation stack
- **File:** `presentation/practice_session_screen.dart:249-256`
- **Description:** `_completeSession()` calls `Navigator.pop(context)` then `Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeScreen()))`. This pops the current session screen, then pushes a fresh PracticeScreen on top — meaning the back button from the new PracticeScreen would go to the previous PracticeScreen (duplicate in stack). Should use `pushReplacement` or `popUntil`.
- **Severity:** Medium
- **Suggested fix:** Use `Navigator.pushReplacement` instead of `pop()` + `push()`, or use `Navigator.popUntil` to get back to the original PracticeScreen.

### BUG-07: Hardcoded fallback options do not match correct answer
- **File:** `presentation/practice_session_screen.dart:432-435`
- **Description:** When `question.options` is empty for MCQ types, the code falls back to `['Option A', 'Option B', 'Option C', 'Option D']`. However, the `correctAnswer` passed to `SingleAnswerWidget` still comes from `question.markscheme`. The correct answer (e.g., "42") will never match any of the fallback options, so all answers are marked wrong.
- **Severity:** High
- **Suggested fix:** If `options` is empty, either skip the question, generate options from the markscheme, or show an error state. Fallback options should be derived from actual data, not hardcoded strings.

### BUG-08: Canvas drawing data permanently lost
- **File:** `presentation/practice_session_screen.dart:456-458`
- **Description:** The canvas widget's `onDrawingComplete` callback passes the hardcoded string `'Drawing submitted'` to `_onAnswerSelected`. The actual drawing data from the canvas is discarded. This means all canvas submissions are treated as identical text "Drawing submitted", making answer validation impossible.
- **Severity:** High
- **Suggested fix:** Capture the actual canvas drawing data (the `data` parameter) instead of ignoring it:
  ```dart
  onDrawingComplete: (data) => _onAnswerSelected(data.toString()),
  ```

### BUG-09: Null assertion crash on `subject.code!`
- **File:** `presentation/practice_screen.dart:324`, `406`
- **Description:** `subject.code!` uses a null assertion on a nullable `String?` field. If a subject has no code, this throws a runtime `NullError`. While `code != null` is checked on line 323, the `!` assertion is unnecessary and dangerous if the guard is ever removed or refactored.
- **Severity:** Medium
- **Suggested fix:** Use `subject.code ?? ''` instead of `subject.code!` even when guarded by the null check.

### BUG-10: No bounds checking on `_questions[_currentIndex]`
- **File:** `presentation/practice_session_screen.dart:297`
- **Description:** Direct list index access without bounds checking. If `_currentIndex` ever equals or exceeds `_questions.length` (e.g., due to a race in `_nextQuestion`), this throws a `RangeError`.
- **Severity:** Medium
- **Suggested fix:** Guard the access:
  ```dart
  final question = _currentIndex < _questions.length ? _questions[_currentIndex] : null;
  if (question == null) return const SizedBox.shrink();
  ```

### BUG-11: Markscheme created with empty string for null markscheme
- **File:** `presentation/practice_session_screen.dart:175`
- **Description:** `question.markscheme ?? ''` defaults to empty string when the markscheme is null. A markscheme with an empty `correctAnswer` means validation against `trim().toLowerCase()` will match any empty/whitespace answer, leading to false positives.
- **Severity:** High
- **Suggested fix:** If `question.markscheme` is null, skip validation entirely or show a "No answer key available" state. Return early from `_validateAnswer()`:
  ```dart
  if (question.markscheme == null || question.markscheme!.isEmpty) {
    // show "not available" feedback
    return false;
  }
  ```

### BUG-12: Score stat shows division by zero on first question
- **File:** `presentation/practice_session_screen.dart:328-330`
- **Description:** At start (`_currentIndex == 0`), the score stat computes `_correctAnswers / (_currentIndex + 1)` = `0 / 1 = 0%`. This is correct. However, `_getColorForScore` receives `_correctAnswers / (_currentIndex + 1)` = `0.0` which returns `Colors.red` — showing "0%" in red, which is alarming to the user before they've answered anything.
- **Severity:** Low
- **Suggested fix:** Show `'-'` instead of `'0%'` when no questions have been answered, or use a neutral color for zero.

---

## 🟠 Performance Issues

### PERF-01: Timer rebuilds entire widget every second
- **File:** `presentation/practice_session_screen.dart:73-85`
- **Description:** `Timer.periodic` runs every 1 second calling `setState`, which triggers a full rebuild of the entire widget tree — including the question card, feedback, navigation, etc. Only the elapsed time display actually changes.
- **Severity:** Medium
- **Suggested fix:** Extract the timer display into a separate `StatefulWidget` or use a `ValueListenableBuilder` / `StreamBuilder` that only rebuilds the time label:
  ```dart
  class _TimerDisplay extends StatefulWidget { ... }
  ```

### PERF-02: New Markscheme/Validator created on every answer validation
- **File:** `presentation/practice_session_screen.dart:173-190`
- **Description:** `_validateAnswer()` creates a new `Markscheme` and `AnswerValidationService` + `QuestionAnswerValidator` every time an answer is submitted. These objects could be created once per question (or once per session) and reused.
- **Severity:** Low
- **Suggested fix:** Cache the `Markscheme` and validator per question:
  ```dart
  final Map<String, AnswerValidationService> _validators = {};
  ```

### PERF-03: Unnecessary `_elapsedTime` string updated every second (never read)
- **File:** `presentation/practice_session_screen.dart:78-79`
- **Description:** `_elapsedTime` is computed and stored in state every second via `elapsed.toString()`, but the field is never read anywhere in the UI or logic. This is dead computation.
- **Severity:** Low
- **Suggested fix:** Remove `_elapsedTime` entirely. Keep only `_elapsedTimeFormatted`.

---

## 🟡 Code Style / Maintainability

### STYLE-01: Inconsistent import style (relative vs. package)
- **File:** `presentation/practice_screen.dart:3`
- **Description:** Line 3 uses a relative import (`'practice_session_screen.dart'`) while lines 2, 4, 6 use package imports. Mixed styles are confusing and can cause ambiguity in larger projects.
- **Severity:** Low
- **Suggested fix:** Use package imports consistently:
  ```dart
  import 'package:studyking/features/practice/presentation/practice_session_screen.dart';
  ```

### STYLE-02: Import from `main.dart` creates tight coupling
- **File:** `presentation/practice_screen.dart:6`
- **Description:** Imports `database` from `package:studyking/main.dart`. This is an architectural anti-pattern — importing from `main.dart` into feature code creates a circular dependency risk and couples the feature to the app's entry point.
- **Severity:** High
- **Suggested fix:** Expose `database` through a Riverpod provider or a dedicated service locator. Access it via `ref.read(databaseProvider)` instead of a global from `main.dart`.

### STYLE-03: Unused field with `// ignore: unused_field`
- **File:** `presentation/practice_screen.dart:18-19`
- **Description:** `_isLoading` is set but never read in `build()`. The ignore comment masks a warning that points to an actual design gap (see BUG-01).
- **Severity:** Medium
- **Suggested fix:** Either use the field to gate the loading state, or remove it entirely.

### STYLE-04: `BuildContext` passed as widget parameter (anti-pattern)
- **File:** `presentation/practice_screen.dart:176`, `484-500`
- **Description:** `_PracticeModeCard` takes a `BuildContext context` as a required constructor parameter. This is an anti-pattern — `BuildContext` should not be stored in widgets. The card should obtain context from its own `build(BuildContext context)` method instead.
- **Severity:** Medium
- **Suggested fix:** Remove the `context` parameter from `_PracticeModeCard`. Use `Theme.of(context)` and other context-dependent calls inside the `build` method where `context` is already available.

### STYLE-05: Multiple unused fields with `// ignore` comments
- **File:** `presentation/practice_session_screen.dart:47-63`
- **Description:** Seven fields with `// ignore: unused_field`: `_elapsedTime` (line 48), `_sessionEndTime` (line 50), `_feedbackExplanation` (line 59), `_feedbackScore` (line 61), `_feedbackDetails` (line 63). These were apparently intended for future use but clutter state. Their presence signals incomplete features.
- **Severity:** Medium
- **Suggested fix:** Remove unused fields and their assignments. Re-add when the features are actually implemented.

### STYLE-06: Complex inline ternary in options assignment
- **File:** `presentation/practice_session_screen.dart:433-435`
- **Description:** The `options` variable is assigned via a deeply nested ternary that checks `question.type` and `question.options.isEmpty` twice. This is hard to read and maintain.
- **Severity:** Low
- **Suggested fix:** Extract to a helper method:
  ```dart
  List<String> _getOptionsForQuestion(Question question) {
    if (question.options.isNotEmpty) return question.options;
    // Show error state or log warning
    return [];
  }
  ```

### STYLE-07: Navigation buttons in column (unusual UX)
- **File:** `presentation/practice_session_screen.dart:546-562`
- **Description:** Previous and Next buttons are stacked vertically in a `Column`. Typical practice is side-by-side (Previous left, Next right, or only Next). The vertical stack wastes vertical space.
- **Severity:** Low
- **Suggested fix:** Use a `Row` with `MainAxisAlignment.spaceBetween`, placing Previous on the left and Next on the right.

### STYLE-08: Direct instantiation of QuestionRepository (no DI)
- **File:** `presentation/practice_session_screen.dart:68`
- **Description:** `_questionRepo = QuestionRepository()` uses the default constructor directly, not through dependency injection. Despite being a `ConsumerStatefulWidget`, the `ref` object is never used. This makes testing difficult and violates Riverpod patterns.
- **Severity:** Medium
- **Suggested fix:** Create a Riverpod provider for `QuestionRepository` and access it via `ref.read(questionRepositoryProvider)`.

### STYLE-09: Importing PracticeScreen from PracticeSessionScreen
- **File:** `presentation/practice_session_screen.dart:13`
- **Description:** practice_session_screen.dart imports practice_screen.dart (to navigate back via `const PracticeScreen()`). practice_screen.dart imports practice_session_screen.dart (to navigate to it). This is a circular dependency at the widget level.
- **Severity:** Low
- **Suggested fix:** Use a callback, a route name string, or a navigator key to navigate back without importing the concrete screen widget.

### STYLE-10: AnswerValidationService is a thin wrapper (YAGNI)
- **File:** `services/answer_validation_service.dart:6-20`
- **Description:** `AnswerValidationService` simply delegates to `QuestionAnswerValidator`'s existing methods. It adds no additional logic, caching, or transformation. The class violates YAGNI — it was apparently introduced in anticipation of future complexity but currently adds only indirection.
- **Severity:** Low
- **Suggested fix:** Either remove the service and call `QuestionAnswerValidator` directly, or add real value (caching, logging, analytics, etc.) to justify its existence.

### STYLE-11: Barrel file missing public API exports
- **File:** `practice.dart:2`
- **Description:** The barrel file only exports `PracticeScreen`. Consumers importing this barrel cannot access `PracticeSessionScreen`, `PracticeAnswerRecord`, or `AnswerValidationService`. These are part of the module's public API and should be exported for proper encapsulation.
- **Severity:** Low
- **Suggested fix:** Add missing exports:
  ```dart
  export 'presentation/practice_screen.dart';
  export 'presentation/practice_session_screen.dart';
  export 'services/answer_validation_service.dart';
  ```

### STYLE-12: `timeSpent` always `Duration.zero` — stale TODO comment
- **File:** `presentation/practice_session_screen.dart:206`
- **Description:** The `timeSpent: const Duration(seconds: 0)` is accompanied by a comment `// Will track actual time`. This was planned but never implemented. Per-question timing is not tracked, making `PracticeAnswerRecord.timeSpent` meaningless.
- **Severity:** Medium
- **Suggested fix:** Implement actual per-question timing (record `DateTime` when question is shown, compute difference on submit), or remove the field from the model.

### STYLE-13: hashCode-based color selection not guaranteed stable
- **File:** `presentation/practice_screen.dart:364-376`
- **Description:** `_getSubjectColor` uses `name.hashCode % colors.length`. Dart's `hashCode` for strings is not guaranteed to be consistent across runs (it's implementation-dependent and could change between platforms or Dart versions). This means the same subject could get different colors on different app launches.
- **Severity:** Low
- **Suggested fix:** Use a deterministic hash like `name.codeUnits.fold(0, (h, c) => h * 31 + c)` or store the color preference per subject.

### STYLE-14: Context parameter shadowing in bottom sheet builders
- **File:** `presentation/practice_screen.dart:380-416`, `420-474`
- **Description:** Both `_showSubjectSelector()` and `_showPracticeModeDialog()` use `builder: (context) =>` where the parameter `context` shadows the outer state's `context`. While not a bug because `Theme.of(context)` correctly uses the builder's context, it's confusing for code readers.
- **Severity:** Low
- **Suggested fix:** Rename the builder parameter to `_` or `sheetContext` to avoid shadowing.

---

## 🔵 Enhancement Suggestions

### ENH-01: Leverage Riverpod providers (ConsumerStatefulWidget unused)
- **File:** `presentation/practice_session_screen.dart:34`
- **Description:** Both screens are `ConsumerStatefulWidget`/`ConsumerState` but neither ever accesses `ref`. `PracticeSessionScreen` creates a `QuestionRepository` directly instead of using a provider. The entire Riverpod integration is unused in this feature.
- **Suggestion:** Define typed providers for repositories and services. Access them via `ref.read()`/`ref.watch()`. This enables proper testing with provider overrides, state persistence, and widget rebuild granularity.

### ENH-02: Implement actual per-question time tracking
- **File:** `presentation/practice_session_screen.dart:202-208`
- **Description:** `PracticeAnswerRecord.timeSpent` is always `Duration.zero` with a stale TODO comment. Per-question timing is crucial for analytics (identifying which questions take longest, weak areas).
- **Suggestion:** Store the `DateTime` when each question is first displayed. On submit, calculate elapsed time and store it in the record.

### ENH-03: Add session persistence and results history
- **File:** `presentation/practice_session_screen.dart` (entire results logic)
- **Description:** Session results are displayed inline but never saved. The user cannot review past practice sessions or track progress over time.
- **Suggestion:** Create a `PracticeSession` model and repository. Save completed sessions (date, subject, questions, answers, score, time) to a Hive box. Add a history view.

### ENH-04: Add skeleton/loading states
- **File:** `presentation/practice_screen.dart:98-113`, `presentation/practice_session_screen.dart:285-290`
- **Description:** Loading states use a basic `CircularProgressIndicator` or show the empty state prematurely. No shimmer/skeleton loading is implemented.
- **Suggestion:** Add shimmer/skeleton widgets for initial load states to improve perceived performance and UX.

### ENH-05: Shuffle / randomize questions
- **File:** `presentation/practice_session_screen.dart:114-120`
- **Description:** Questions are taken in insertion order with no randomization. A "quick practice" mode should randomize question order to prevent order memorization.
- **Suggestion:** Add `_questions.shuffle()` before taking the subset:
  ```dart
  final shuffled = List<Question>.from(filteredQuestions)..shuffle();
  _questions = shuffled.take(count).toList();
  ```

### ENH-06: Answer history review in results screen
- **File:** `presentation/practice_session_screen.dart:596-629`
- **Description:** The results screen only shows aggregate stats (total, correct, accuracy). The `_answerRecords` list is populated but never displayed. Users cannot review which specific questions they got right/wrong.
- **Suggestion:** Add an expandable list of answers showing each question, the user's answer, the correct answer, and the outcome.

### ENH-07: Proper canvas drawing data validation
- **File:** `presentation/practice_session_screen.dart:453-458`
- **Description:** Canvas question type captures no actual drawing data (see BUG-08). The `AnswerValidator.validateCanvasDrawing` expects structured data but receives `'Drawing submitted'` string.
- **Suggestion:** Pass actual canvas drawing data, serialize it, and use `validateCanvasDrawing` or a custom validation for canvas content.

### ENH-08: Implement proper essay answer grading (not placeholder)
- **File:** `presentation/practice_session_screen.dart:486-499`
- **Description:** Essay questions are just text fields with character counting. The validator's `validateEssayAnswer` is a placeholder (checks length only). Real essay grading requires AI or rubric-based scoring.
- **Suggestion:** Integrate with an AI grading service or rubric-based evaluation for essay answers. Show a meaningful feedback message indicating "awaiting AI grading" if not yet implemented.

### ENH-09: Add accessibility (semantics, labels)
- **Files:** Both screen files
- **Description:** No `Semantics` widgets, `tooltip`s are minimal, and the screen has no accessibility labels for screen readers.
- **Suggestion:** Add `Semantics` to key interactive elements, provide meaningful `label` parameters, and ensure sufficient color contrast in feedback indicators.

### ENH-10: Extract bottom sheets to reusable widgets
- **File:** `presentation/practice_screen.dart:378-475`
- **Description:** `_showSubjectSelector` and `_showPracticeModeDialog` are large inline methods with significant code duplication (bottom sheet setup, layout structure, styling).
- **Suggestion:** Create a reusable `SubjectSelectorSheet` widget and a `PracticeModeSheet` widget that can be tested independently and reused elsewhere.

### ENH-11: Add proper error boundaries
- **File:** Both screen files
- **Description:** Error handling uses `AppErrorHandler.handleError` which shows a generic error dialog. There are no `FlutterError.onError` or `ErrorWidget.builder` boundaries specific to this feature.
- **Suggestion:** Wrap each screen with a `FlutterErrorBoundary` widget to catch rendering errors without crashing the entire app. Use `runZonedGuarded` for async errors.

### ENH-12: Add question count indicator and navigation
- **File:** `presentation/practice_session_screen.dart:299-307`
- **Description:** The AppBar shows progress via `LinearProgressIndicator` but does not show "Question 3 of 10" text. Users lack a clear sense of position.
- **Suggestion:** Add a text label "Question ${_currentIndex + 1} of ${_questions.length}" in the AppBar title or subtitle.

### ENH-13: Add animated transitions between questions
- **File:** `presentation/practice_session_screen.dart:216-227`
- **Description:** `_nextQuestion()` and `_previousQuestion()` update state synchronously with no animation. The question content abruptly replaces.
- **Suggestion:** Use `AnimatedSwitcher` or `PageView` with a unique `ValueKey(question.id)` on the question widget for smooth slide/fade transitions between questions.

### ENH-14: Use a state machine pattern for session state
- **File:** `presentation/practice_session_screen.dart:34-63`
- **Description:** Session state is managed via 7+ boolean/string fields (`_isSubmitted`, `_isFeedbackVisible`, `_isSessionComplete`, etc.). This is fragile and doesn't prevent invalid state combinations (e.g., `_isSubmitted = true` and `_isSessionComplete = true` at the same time).
- **Suggestion:** Use an enum or sealed class to represent session stages (`SessionStage.loading`, `SessionStage.answering`, `SessionStage.feedback`, `SessionStage.complete`). Replace multiple boolean flags with a single state value and transition rules.

---

## Per-File Summary

### `practice.dart` (2 lines)
| Issue | Line | Severity |
|-------|------|----------|
| STYLE-11: Missing barrel exports | 2 | Low |

### `presentation/practice_screen.dart` (614 lines)
| Issue | Line | Severity |
|-------|------|----------|
| BUG-01: Loading/empty state conflict | 98-100 | High |
| BUG-02: Empty button callback | 145-148 | Medium |
| BUG-09: Null assertion on `code!` | 324, 406 | Medium |
| BUG-12: Score stat in red on start | 328-330 | Low |
| PERF-(none) | — | — |
| STYLE-01: Inconsistent imports | 3 | Low |
| STYLE-02: Import from main.dart | 6 | High |
| STYLE-03: Unused `_isLoading` | 18-19 | Medium |
| STYLE-04: BuildContext as parameter | 176, 484-500 | Medium |
| STYLE-13: Unstable hashCode color | 364-376 | Low |
| STYLE-14: Context shadowing | 380, 421 | Low |
| ENH-01: Riverpod unused | (entire file) | — |
| ENH-04: No skeleton loading | 98-113 | — |
| ENH-09: No accessibility | (entire file) | — |
| ENH-10: Extract bottom sheets | 378-475 | — |
| ENH-11: Error boundaries | (entire file) | — |

### `presentation/practice_session_screen.dart` (647 lines)
| Issue | Line | Severity |
|-------|------|----------|
| BUG-03: `_initializeSession` after error | 134-136 | High |
| BUG-04: Async fire-and-forget in initState | 68-70 | Medium |
| BUG-05: Future.delayed race condition | 247-258 | High |
| BUG-06: Duplicate screen in stack | 249-256 | Medium |
| BUG-07: Fallback options mismatch | 432-435 | High |
| BUG-08: Canvas data lost | 456-458 | High |
| BUG-10: No bounds checking | 297 | Medium |
| BUG-11: Empty markscheme validation | 175 | High |
| BUG-12: Score stat red at 0 | 328-330 | Low |
| PERF-01: Timer rebuilds entire widget | 73-85 | Medium |
| PERF-02: Validator recreated per answer | 173-190 | Low |
| PERF-03: Unused `_elapsedTime` | 78-79 | Low |
| STYLE-05: 5 unused fields with ignores | 47-63 | Medium |
| STYLE-06: Complex ternary | 433-435 | Low |
| STYLE-07: Column nav buttons | 546-562 | Low |
| STYLE-08: Direct QuestionRepository | 68 | Medium |
| STYLE-09: Circular import risk | 13 | Low |
| STYLE-12: Stale TODO, no per-question timing | 206 | Medium |
| ENH-01: Riverpod unused | 34 | — |
| ENH-02: Per-question timing | 202-208 | — |
| ENH-03: Session persistence | (entire file) | — |
| ENH-05: Question shuffle | 114-120 | — |
| ENH-06: Answer history in results | 596-629 | — |
| ENH-07: Canvas validation | 453-458 | — |
| ENH-08: Essay grading | 486-499 | — |
| ENH-12: Question position indicator | 299-307 | — |
| ENH-13: Animated transitions | 216-227 | — |
| ENH-14: State machine pattern | 34-63 | — |

### `services/answer_validation_service.dart` (20 lines)
| Issue | Line | Severity |
|-------|------|----------|
| STYLE-10: Thin wrapper (YAGNI) | 6-20 | Low |

---

## Cross-Cutting Concerns

| Concern | Description |
|---------|-------------|
| **Testing** | No unit tests exist for `_validateAnswer`, `_onAnswerSelected`, or `_submitAnswer` logic. The `AnswerValidationService` tests reference the class name but may not cover the thin wrapper layer. |
| **Dependency Injection** | Both screens use global/direct instantiation (`database` from main.dart, `QuestionRepository()` constructor) instead of provider-based injection. |
| **Error Messages** | Error messages mix user-facing strings (e.g., `'Questions Load'` in `AppErrorHandler`) with developer-facing strings. The exact format shown to users is unclear. |
| **Unused Riverpod** | Despite using `ConsumerStatefulWidget`, no Riverpod feature (providers, ref, state management) is utilized. The widget could be a plain `StatefulWidget`. |
| **Magic Numbers** | Many hardcoded values (padding `16.0`, `12.0`, `24.0`; question count `10`; `0.05` shadow opacity; `500ms` delay) with no named constants. |
