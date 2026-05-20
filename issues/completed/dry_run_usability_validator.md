# Dry-Run Usability Validation: Exam Mode & Spaced Repetition

**Scenario:** `dry-run-test/scenario_exam_mode_spaced_repetition.md`
**Validator Date:** 2026-05-19
**Validator:** Dry-Run Usability Validator

**Scenario Summary:**
A student preparing for their IB Chemistry exam wants to use timed exam simulations and spaced repetition for test readiness. The student expects to discover spaced repetition on the Practice tab, take timed exams with realistic constraints, have SM-2 scheduling automatically updated after practice, and see how the system prioritizes their weak areas. Over 17 expectations are evaluated against actual implementation.

---

## BLOCKER findings (app crashes or user cannot proceed)

### B-001: Back-button exit during active exam discards unanswered questions without recording them

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart:424-452` (`_onWillPop()`)
- `lib/features/practice/presentation/screens/exam_session_screen.dart:256-279` (`_autoSubmitExam()`)

**Rationale:**
When a user presses the back button during an active exam, `_onWillPop()` is called. The method:
1. Shows a confirmation dialog (correct behaviour ✓)
2. If user taps "Exit" with a current answer: calls `_submitAnswer()` for the CURRENT question only (line 446)
3. Calls `_finishExam()` (line 448) — which processes only the already-submitted `_results` list

**Critical bug:** Unlike `_autoSubmitExam()` (lines 256-279) which correctly iterates ALL remaining questions (`_questions.skip(_currentIndex)`) and marks them as `wasSkipped: true, isCorrect: false`, the `_onWillPop()` path NEVER iterates the remaining unanswered questions. Questions at indices > `_currentIndex` are silently discarded.

**Impact:** If a user exits an exam of 20 questions at question 12, only 12 results are recorded. The exam displays "12 of 12 correct (100%)" — a misleadingly perfect score that ignores 8 unanswered questions. The user sees inflated accuracy and the SM-2 system doesn't schedule the unsubmitted questions for appropriate review.

**Acceptance criteria:**
- [ ] `_onWillPop()` must iterate all unanswered questions and mark them as skipped (same logic as `_autoSubmitExam()`)
- [ ] The exam result must accurately reflect the total configured question count with skipped questions properly counted
- [ ] The results screen must show the total number of skipped questions when an early exit occurs

---

### B-002: No user-facing spaced repetition configuration exists anywhere in the app

**Affected files:**
- `lib/features/practice/services/spaced_repetition_engine.dart:82` (`useFSRS` dead code flag)
- `lib/features/practice/services/spaced_repetition_service.dart:82-84` (`getQuestionsDueForReview()` hardcoded tolerance)
- `lib/features/practice/presentation/screens/practice_session_screen.dart:584-618` (SR results shown but no config)
- `lib/features/settings/presentation/settings_screen.dart` (no SR section)

**Rationale:**
The spaced repetition system uses a fully implemented SM-2 algorithm with parameters that affect every user's review schedule (ease factor minimum of 1.3, interval multipliers, due window tolerances). However:

- No settings screen or dialog allows users to view or modify any SR parameter
- Users cannot set a daily review limit — `getPracticeQuestions()` returns ALL due questions without pagination
- Users cannot view the SM-2 state of individual questions (repetition count, ease factor, next review date)
- Users cannot reset SR data for specific questions
- The `useFSRS` flag exists in the engine (line 82) but is never read — dead code

**Impact:** Users have zero control over their spaced repetition experience. If intervals are too aggressive or too relaxed, there is no recourse. Advanced users who understand SM-2 cannot fine-tune the system. The `useFSRS` dead code clutters the codebase.

**Acceptance criteria:**
- [ ] A "Spaced Repetition" section exists in Settings with configurable parameters (minimum interval, maximum interval, daily review limit, ease factor sensitivity)
- [ ] Users can view a question's SM-2 state (repetitions, ease factor, next review date) from the Question Bank or a dedicated SR management screen
- [ ] Users can reset SR data for individual questions or topics
- [ ] The `useFSRS` flag is either used or removed

---

### B-003: Exam results are never persisted — no exam history exists

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:395-404` (`_navigateToExam()` discards return value)
- `lib/features/practice/services/exam_session_service.dart:47-67` (`ExamResult` has no persistence)
- No `ExamRepository` exists in the codebase

**Rationale:**
When the `ExamSessionScreen` pops via `_navigateToExam()`, the return value (which would contain `ExamResult`) is discarded — `Navigator.pushNamed` is called without `await` (line 396). There is:

- No repository or storage layer for exam results (`ExamResult` objects created in memory only)
- No exam history screen or section anywhere in the app
- The `ExamResult.scoreHistory` field (declared at exam_session_service.dart:47) is declared but never populated — dead data

**Impact:** Every exam is a one-off event. A student cannot track whether their exam performance is improving over time, cannot compare results across weeks, and cannot see trend data. The exam feature provides no long-term value.

**Acceptance criteria:**
- [ ] Implement an `ExamRepository` (Hive-backed) that stores `ExamResult` objects
- [ ] `_navigateToExam()` awaits the result and persists it
- [ ] An exam history view exists (accessible from Practice tab or Dashboard) showing past exams with scores, dates, durations, and topic breakdowns
- [ ] The `scoreHistory` field is either populated or removed

---

## MAJOR findings (feature is broken or misleading)

### M-001: Spaced Repetition mode overwrites accurate MasteryRecorder SM-2 data with binary correct/incorrect calculation

**Affected files:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart:283-298` (dual update path)
- `lib/features/practice/services/practice_session_service.dart:52` (`updateNextReview()` calls SR service)
- `lib/features/practice/services/spaced_repetition_service.dart:128-150` (`_masteryLevelToGrade()` maps 0.2/0.8)

**Rationale:**
In Spaced Repetition mode, each answer triggers TWO SM-2 updates:

1. **Line 283** `_masteryRecorder.recordAttempt(...)` — uses the user's actual confidence rating (1-5) + correctness, maps to SM-2 grade via `SpacedRepetitionEngine.mapConfidenceToGrade()`. This is the accurate path.

2. **Line 297-298** `_updateNextReview(question.id, isCorrect)` — calls `SpacedRepetitionService.updateNextReviewDate()` which converts `isCorrect` to a crude `masteryLevel` (0.8 or 0.2) via `_masteryLevelToGrade()`. This uses only BINARY correct/incorrect, ignoring the user's confidence.

Since line 298 runs AFTER line 283, the second call OVERWRITES the first. The user's confidence rating is discarded. The SM-2 system operates on a simplified pass/fail basis in SR mode.

**Impact:** The core purpose of SM-2's 6-grade scale (0-5) is defeated. A question answered correctly with "very sure" (confidence 5) gets the same schedule as one answered correctly with "unsure" (confidence 3). Users who carefully rate their confidence are wasting effort — only their final right/wrong matters.

**Acceptance criteria:**
- [ ] Remove the redundant `_updateNextReview()` call at line 297-298, or refactor so `MasteryRecorder.recordAttempt()` is the single source of truth for SM-2 updates
- [ ] Ensure the confidence rating from the user is preserved through to the `SpacedRepetitionEngine.scheduleReview()` call
- [ ] The `_masteryLevelToGrade()` method should be removed or deprecated (it only serves the redundant path)

---

### M-002: Practice results screen shows no spaced repetition scheduling information

**Affected files:**
- `lib/features/practice/presentation/screens/practice_session_screen.dart:593-660` (`_buildResultsContent()`)
- `lib/features/practice/presentation/screens/practice_session_screen.dart:277-278` (`PracticeSessionResult` carries only count + accuracy)

**Rationale:**
After completing a Spaced Repetition session, the results screen shows standard metrics (total questions, correct count, accuracy, topic breakdown) but ZERO spaced repetition-specific information. The user cannot see:

- How many questions were rescheduled and to what dates
- Which questions had their intervals changed
- Their current ease factors or repetition counts
- Whether their next review load increased or decreased

The `PracticeSessionResult` object (returned via `Navigator.pop()`) contains only `questionsAnswered` and `accuracy` — no SM-2 state diff.

**Impact:** Spaced Repetition mode is functionally invisible to the user. They experience it as "some questions, maybe ordered differently" with no feedback on the scheduling adjustments being made. The feature becomes a confusing variant of regular practice rather than an understandable learning tool.

**Acceptance criteria:**
- [ ] The results screen shows at minimum: number of questions rescheduled, next review date range (earliest-latest), count of questions at each interval tier
- [ ] `PracticeSessionResult` carries SR summary data (questions rescheduled, total interval change)
- [ ] An "SR Details" expandable section shows per-question next review dates

---

### M-003: Exam mode hardcodes confidence to 4 (correct) or 2 (incorrect) with no user input

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart:217` (`confidence: isCorrect ? 4 : 2`)

**Rationale:**
In `_submitAnswer()` (exam_session_screen.dart:195-237), the confidence is hardcoded:
```dart
confidence: isCorrect ? 4 : 2,
```
Every correct answer gets confidence 4. Every incorrect answer gets confidence 2. There is no confidence selector in exam mode.

This means correct lucky guesses (which should get low confidence) are treated as confident knowledge, and incorrect answers where the user was very sure are treated as "unsure." The SM-2 algorithm cannot distinguish between a lucky guess and solid knowledge.

**Impact:** Exam mode produces less accurate SM-2 scheduling than regular practice. The auto-submitted questions (from time-out) also get confidence 2 (since `isCorrect: false, wasSkipped: true`), so skipped questions are scheduled for immediate review — which might be appropriate but uses the wrong reasoning.

**Acceptance criteria:**
- [ ] Add a confidence/confidence rating UI element in the exam answer flow (similar to regular practice mode)
- [ ] After each answer, the user rates their confidence before proceeding to the next question
- [ ] The hardcoded confidence fallback is only used for auto-submitted (skipped) questions

---

### M-004: Dual "next review" tracking systems can diverge, producing inconsistent due counts

**Affected files:**
- `lib/features/practice/services/mastery_recorder.dart:94-107` (updates `QuestionMasteryState.nextReview` via heuristic)
- `lib/features/practice/services/spaced_repetition_service.dart:82-91` (`getQuestionsDueForReview()` uses `Question.nextReview`)
- `lib/core/data/models/question_mastery_state.dart:209-225` (`_calculateNextReview()` heuristic formula)

**Rationale:**
Two systems track "next review":

1. **`Question.nextReview`** — managed by SM-2 via `MasteryRecorder.recordAttempt()`. Stores SM-2 params in `srDataJson`. Queried by `getSubjectDueCount()` for the badge.

2. **`QuestionMasteryState.nextReview`** — updated in the SAME `recordAttempt()` call (line 94-107) but uses a different formula: `nextReview = now + Duration(days: (1.0 / accuracy).round())`. This is a simple heuristic unrelated to SM-2.

The `QuestionMasteryStateRepository.getDueQuestions()` queries System 2, but the actual practice mode uses System 1. Code paths that use the wrong system will see inconsistent due counts.

**Impact:** A student might see "5 questions due" on the Spaced Repetition badge (from System 1) but the Focus Mode Study Hub or a non-standard query might report different counts (from System 2). Due counts are inconsistent.

**Acceptance criteria:**
- [ ] Eliminate one of the two systems. Either `Question.nextReview` (SM-2) should be the single source of truth, or `QuestionMasteryState.nextReview` should be replaced with a direct read from `Question.nextReview`
- [ ] `QuestionMasteryState._calculateNextReview()` should be removed or aligned with SM-2 intervals

---

### M-005: ReadinessScorer provider creates instance with empty data — scoring is a no-op

**Affected files:**
- `lib/features/practice/providers/practice_providers.dart:94-96` (`readinessScorerProvider`)
- `lib/features/practice/services/readiness_scorer.dart` (entire file)

**Rationale:**
The `readinessScorerProvider` creates `ReadinessScorer()` with no arguments, which means the internal `_topicMasteryMap` and `_questionMasteryMap` are empty. Inside `scoreQuestions()`, every lookup returns null, and every question falls through to the default score: `0.47 + 0.19 + difficulty * 0.05`. Since all scores are near-identical, the subsequent sort is effectively random.

This affects the Weak Areas mode (practice_screen.dart:274-276) and At Risk mode (practice_screen.dart:377-378), which pass questions through this scorer expecting priority ordering.

**Impact:** The Weak Areas and At Risk modes claim to prioritize high-urgency questions but deliver random ordering. The sophisticated `ReadinessScorer` is wasted infrastructure that never receives real data.

**Acceptance criteria:**
- [ ] `readinessScorerProvider` must populate the scorer with actual mastery data (topic mastery map + question mastery map from `MasteryGraphService`)
- [ ] Add test coverage verifying that `scoreQuestions()` returns non-trivial ordering with real data

---

### M-006: Exam results show no SR scheduling impact, no per-question timing, no historical comparison

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart:651-727` (`_buildResultsScreen()`)

**Rationale:**
The exam results screen shows score, accuracy, topic breakdown, and duration. Missing:
- No impact summary: "These results will affect your spaced repetition schedule for 15 questions"
- No per-question timing analysis: "You spent the most time on question 7 (3:20)"
- No historical comparison: no previous exam scores shown (because none are persisted — see B-003)

The results screen is adequate for a one-off quiz but insufficient as a diagnostic tool for exam preparation.

**Acceptance criteria:**
- [ ] Add a "Questions at a glance" section showing per-question time spent
- [ ] If exam history exists (B-003), add a comparison card showing previous exam scores
- [ ] Add a note about SR scheduling impact

---

### M-007: `_navigateToExam()` discards the screen's return value

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:395-404`

**Rationale:**
The method calls `Navigator.pushNamed(context, AppRoutes.examSession, arguments: ...)` but does NOT capture the return value. Even though `ExamSessionScreen` could `pop()` with meaningful data (e.g., `ExamResult`), the caller ignores it. The Void suffix in `_navigateToExam()` confirms it's fire-and-forget.

**Impact:** Even if exam results were persisted (B-003), the practice screen can never act on the result for post-exam actions (e.g., recommending revision topics, updating due counts).
This is likely the original source of the results-discarding bug B-003.

**Acceptance criteria:**
- [ ] Change `_navigateToExam()` to `async` and capture the return value
- [ ] Process the return value to update state (refresh due counts, show post-exam recommendations)

---

### M-008: "At Risk" practice mode may be inaccessible from the UI grid

**Affected files:**
- `lib/features/practice/presentation/screens/practice_screen.dart:347-393` (`_startAtRiskPractice()`)
- `lib/features/practice/presentation/widgets/practice_mode_grid.dart` (mode grid rendering)

**Rationale:**
The `_startAtRiskPractice()` method exists and is functional, but the mode grid in `PracticeModeGrid` renders only 6 modes (Quick Practice, Spaced Repetition, Topic Focus, Weak Areas, Exam Mode, Source Practice). The "At Risk" card may not be present in the grid at all, making the method unreachable through any UI path.

**Impact:** A completed feature with dead code path. Users cannot access At Risk practice despite the implementation being complete.

**Acceptance criteria:**
- [ ] Verify whether "At Risk" is rendered in the mode grid. If not, either add it to the grid or remove the dead code.

---

## MINOR findings (UX friction)

### m-001: Exam difficulty sliders default to 0 and are independent of question count — confusing UX

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart:454-640` (`_buildConfigScreen()`)

**Rationale:**
The exam config screen has sliders for Easy (0-10), Medium (0-10), and Hard (0-10) that default to 0. A value of 0 means "no questions of this difficulty," not "any." The sliders add up independently of the separate question count selector (5/10/15/20/30). A user might set Easy=5 expecting 5 easy questions without understanding they need to manually adjust Medium and Hard to reach the question count.

**Impact:** Confusing first-use experience. Users may end up with fewer questions than expected or a different difficulty mix than intended.

**Acceptance criteria:**
- [ ] Auto-distribute difficulty proportionally when sliders are left at 0
- [ ] Show a visual indicator that difficulty values should sum to the question count (e.g., a bar or a "remaining" counter)
- [ ] Or replace sliders with a percentage-based distribution that automatically sums to 100%

---

### m-002: `useFSRS` dead code flag in SpacedRepetitionEngine

**Affected files:**
- `lib/features/practice/services/spaced_repetition_engine.dart:82` (flag declaration)
- `lib/features/practice/services/spaced_repetition_engine.dart:89` (constructor parameter)

**Rationale:**
The `useFSRS` boolean flag is declared as a field and accepted as a constructor parameter, but is never read anywhere in the engine or any caller. Searching the codebase confirms zero reads of `this.useFSRS` or `widget.useFSRS`.

**Acceptance criteria:**
- [ ] Remove the `useFSRS` flag if FSRS support is not planned, or implement the conditional branch if it is

---

### m-003: No per-question timing breakdown in exam results

**Affected files:**
- `lib/features/practice/presentation/screens/exam_session_screen.dart:651-727`

**Rationale:**
The `ExamQuestionResult` model stores `timeSpentMs` per question, but the results screen does not display it. A student cannot identify which questions they spent too long on — a critical insight for exam strategy improvement.

**Acceptance criteria:**
- [ ] In the Review Mistakes dialog (or a new "Exam Analysis" section), show time spent per question
- [ ] Highlight questions where time spent significantly exceeded the average

---

## Findings Summary

| Severity | Count | Issue IDs |
|---|---|---|
| **BLOCKER** | 3 | B-001, B-002, B-003 |
| **MAJOR** | 8 | M-001, M-002, M-003, M-004, M-005, M-006, M-007, M-008 |
| **MINOR** | 3 | m-001, m-002, m-003 |
| **Total** | 14 | |
