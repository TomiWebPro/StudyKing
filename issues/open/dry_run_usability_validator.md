# Dry-Run Usability Validation: Adaptive Practice & Mastery Improvement

## Scenario

[`dry-run-test/scenario_adaptive_practice_mastery.md`](../scenario_adaptive_practice_mastery.md)

A returning student with ~150 practice questions across multiple subjects wants to systematically close weak areas using the app's adaptive practice features (Weak Areas mode, Spaced Repetition, Topic Focus, Exam Mode) and track mastery improvement over time.

---

## BLOCKER Findings

### B1: ReadinessScorer provider creates scorer with empty mastery data

**Files:** `lib/features/practice/providers/practice_providers.dart:94-96`, `lib/features/practice/services/readiness_scorer.dart:28-32`

**What's wrong:** The `readinessScorerProvider` instantiates `ReadinessScorer()` with no arguments. The constructor defaults to empty `_topicMasteryMap` and `_questionMasteryMap`. Every call to `scoreQuestions()` computes scores where all `topicMastery` and `questionMastery` lookups return `null`, resulting in identical default scores for every question. The sorting at `readiness_scorer.dart:55` is a no-op.

**Acceptance criteria:**
- `readinessScorerProvider` must fetch `MasteryState` and `QuestionMasteryState` data (via `MasteryGraphService` or directly from repositories) and pass it to the `ReadinessScorer` constructor
- `ReadinessScorer.scoreQuestions()` must produce differentiated scores based on actual topic/question mastery data
- Unit tests must verify that questions from weaker topics score higher than questions from stronger topics

### B2: Weak Areas mode discards ordered questions — session reloads and reshuffles

**Files:** `lib/features/practice/presentation/screens/practice_screen.dart:220-224`, `lib/features/practice/presentation/screens/practice_session_screen.dart:103-131`

**What's wrong:** The `_launchWeakAreasForSubject()` method at `practice_screen.dart:215-217` calls `ReadinessScorer.scoreQuestions()` and gets an ordered list. But at line 220-224, it only passes `subjectId` and `questionCount` to `PracticeSessionArgs`. No `topicId` is set, and the ordered question list is not passed. The session screen at line 105 calls `_questionRepo.getBySubject(subjectId)` — reloading ALL questions — then shuffles at line 120 and takes the first `questionCount`. The prioritization work is completely thrown away.

**Acceptance criteria:**
- `PracticeSessionArgs` must support a pre-ordered question list, OR the practice screen must pass the ordered question IDs so the session screen can filter and order accordingly
- The session screen must respect the pre-computed question ordering when it's provided (skip shuffling)
- The `topicId` argument should be populated in Weak Areas mode to avoid loading questions from non-weak topics
- Unit tests must verify that ordered questions from Weak Areas appear in the session in the correct priority order

### B3: Spaced Repetition mode shows random questions instead of due questions

**Files:** `lib/features/practice/presentation/screens/practice_screen.dart:234-257`, `lib/features/practice/presentation/screens/practice_session_screen.dart:103-131`, `lib/features/practice/data/repositories/spaced_repetition_repository.dart`

**What's wrong:** The `_startSpacedRepetitionSession()` at `practice_screen.dart:236` calls `_srRepo.getPracticeQuestions(subject.id)` which correctly identifies due questions via SM-2 `nextReview` dates. But it only uses the result to determine `questionCount`. The session screen at `practice_session_screen.dart:105` loads ALL subject questions from `_questionRepo.getBySubject()`, then shuffles and takes `questionCount`. The actual due questions identified by the SM-2 algorithm are never shown — the user gets random questions equal in number to the due count.

**Acceptance criteria:**
- The Spaced Repetition session must load ONLY the questions identified as due by the SM-2 algorithm
- The session must respect the SM-2 `nextReview` dates for question selection (not just count)
- Questions must appear in an order that respects their urgency (most overdue first)
- Unit tests must verify that non-due questions are excluded from SR sessions and that overdue questions are included

### B4: SM-2 schedule is computed correctly but never used for session construction

**Files:** `lib/features/practice/services/spaced_repetition_engine.dart:91-149`, `lib/features/practice/services/mastery_recorder.dart:55-61`, `lib/features/practice/presentation/screens/practice_session_screen.dart:103-131`

**What's wrong:** The SM-2 algorithm in `SpacedRepetitionEngine.scheduleReview()` correctly computes intervals based on grade (0-5) and updates `nextReview` on each question. The `MasteryRecorder.recordAttempt()` at line 55-61 correctly calls the engine and persists the updated schedule. However, the practice session never uses `nextReview` for question selection. The entire SM-2 pipeline produces correct data that is consumed by nobody.

**Acceptance criteria:**
- The session's question selection must use `Question.nextReview` to determine which questions are due
- After a session, the `dueCounts` badge on the Spaced Repetition card must update without manual refresh
- The card's "all caught up" state must be accurate
- Unit tests must verify that after answering questions with varying grades, only the appropriate questions appear as due

### B5: Spaced Repetition due count check uses 1-hour tolerance but session selection ignores it

**Files:** `lib/features/practice/services/spaced_repetition_service.dart:72-82`, `lib/features/practice/presentation/screens/practice_session_screen.dart`

**What's wrong:** The `getQuestionsDueForReview()` at `spaced_repetition_service.dart:74` subtracts 1 hour from the cutoff (`reviewDate.subtract(Timeouts.hour)`). The session screen uses `nextReview` fields but loads all questions without any date filter. Even if the filter were used, the 1-hour tolerance means questions due within the next hour aren't shown. Users who just practiced can't see questions that would be due "soon."

**Acceptance criteria:**
- The SR session must use a consistent due window that matches the badge count
- The 1-hour tolerance must be documented or exposed as a configurable threshold
- Questions due within the tolerance window should be clearly marked if excluded, or the tolerance should be removed

---

## MAJOR Findings

### M1: Dashboard weak topic "Practice" button doesn't use adaptive ordering

**Files:** `lib/features/subjects/presentation/widgets/dashboard_widgets.dart` (see dashboard weak areas card), `lib/features/practice/presentation/screens/practice_session_screen.dart:103-131`

**What's wrong:** Tapping "Practice" on a weak topic from the Dashboard navigates to `PracticeSessionScreen` with `subjectId` and `topicId`. The session loads and shuffles questions for that topic without any ReadinessScorer prioritization. The `ReadinessScorer` is only called from `_launchWeakAreasForSubject()` in the Practice screen — not from Dashboard entry points.

**Acceptance criteria:**
- All entry points that start practice from weak topics must use ReadinessScorer for question ordering
- The Dashboard's weak topic "Practice" button must pass the same data as the Practice screen's Weak Areas mode
- Or a shared utility function should be extracted to avoid code duplication

### M2: Mastery state has no history/tracking — users can't see improvement over time

**Files:** `lib/features/practice/data/models/mastery_state_model.dart`, `lib/core/services/mastery_calculation_service.dart`, `lib/core/services/study_progress_tracker.dart`

**What's wrong:** The `MasteryState` model stores only the current computed values (accuracy, streak, mastery level, etc.). `MasteryCalculationService.recordAttempt()` overwrites the state on every call. There is no snapshotting, versioning, or historical tracking of mastery states. The Dashboard's "Mastery Overview" shows a single point-in-time snapshot. Users can see that "Stoichiometry is at 65%" but cannot see that "Stoichiometry was at 40% last week and has improved."

**Acceptance criteria:**
- A `MasteryHistoryEntry` or `MasterySnapshot` model must capture periodic snapshots (daily or per-session)
- The Dashboard must show a trend line or per-topic history for accuracy over time
- The Study Progress Tracker's `getTopicProgress()` must include historical data
- Widget tests must verify the trend display renders correctly

### M3: DifficultyAdapter class and question difficulty field are both dead code

**Files:** `lib/features/practice/services/difficulty_adapter.dart`, `lib/features/practice/providers/practice_providers.dart:98-100`, `lib/core/data/models/question_model.dart` (difficulty field)

**What's wrong:** The `DifficultyAdapter` class is fully implemented with streak-based difficulty adjustment, but no screen or service ever reads from its provider. The `Question.difficulty` field (1-5) is stored on every question but never used for filtering, ordering, or any adaptive decision. No practice mode adjusts question selection based on user performance.

**Acceptance criteria:**
- `DifficultyAdapter` must be wired into at least one practice mode (e.g., Weak Areas or Quick Practice) so that question difficulty adjusts based on recent performance
- The session screen must be able to select questions with appropriate difficulty for the user's current level
- Unit tests must verify that the adapter's difficulty changes are reflected in question selection

### M4: At-risk question detection exists in data layer but has no UI

**Files:** `lib/core/services/mastery_graph_service.dart:105-111`, `lib/features/practice/data/repositories/question_mastery_state_repository.dart` (getAtRiskQuestions)

**What's wrong:** `MasteryGraphService.getAtRiskQuestions()` returns questions with `masteryLevel < 0.5`. This method is **never called from any screen or service**. Users cannot practice individual low-mastery questions — they can only practice entire weak topics (topic-level aggregation), which may hide individual struggling questions within otherwise-okay topics.

**Acceptance criteria:**
- A new practice mode, filter option, or card must surface at-risk questions
- OR existing Weak Areas mode must offer a per-question drill-down in addition to the topic-level view
- The at-risk threshold (0.5) must be documented or configurable

### M5: Exam mode difficulty tier selection exists in code but is not exposed to users

**Files:** `lib/features/practice/services/exam_session_service.dart:116-152`, `lib/features/practice/presentation/screens/exam_session_screen.dart`

**What's wrong:** `ExamSessionService.selectQuestions()` accepts `ExamConfig` with `easyCount`, `mediumCount`, `hardCount` fields and can construct a balanced difficulty mix. However, the `ExamSessionScreen`'s configuration UI only exposes duration and total question count sliders — never difficulty distribution. Users always get the default behavior (no tier selection), which falls through to loading all subject questions.

**Acceptance criteria:**
- Exam configuration must expose difficulty tier selection (e.g., sliders or segmented controls for Easy/Medium/Hard counts)
- The difficulty distribution must be validated to sum to the total question count
- Widget tests must verify the difficulty controls render and function
- Default behavior when all tiers are zero must be documented and sensible

### M6: PracticeScreen ignores session results returned via Navigator.pop

**Files:** `lib/features/practice/presentation/screens/practice_screen.dart:136-140, 155-160, 220-224, 243-248`, `lib/features/practice/presentation/screens/practice_session_screen.dart:326-337`

**What's wrong:** The session screen at `practice_session_screen.dart:330-335` calls `Navigator.pop(context, PracticeSessionResult(...))` which returns a `PracticeSessionResult` containing `questionsAnswered`, `correctAnswers`, and `topicBreakdown`. However, every entry point in `practice_screen.dart` calls `await Navigator.pushNamed(context, ...)` without capturing the return value. The result data is produced but never consumed. The Practice screen reloads due counts but doesn't use the result for any purpose.

**Acceptance criteria:**
- At minimum, the Practice screen must capture the `PracticeSessionResult` and pass it to `_loadDueCounts()` or use it to show a summary
- Ideally, the result should update the summary row (questions today, due counts) without a full reload
- Unit/widget tests must verify the result is consumed

---

## MINOR Findings

### m1: Topic Focus mode uses fragile string-based topic matching

**Files:** `lib/features/practice/presentation/screens/practice_screen.dart:142-169`

**What's wrong:** `_startTopicPractice()` at line 147 filters questions by `q.topic == topic` — an exact string match against the display name. If the topic display name has a typo, trailing whitespace, or formatting inconsistency, the filter silently returns zero questions and shows "No questions available." There's no fallback or approximate matching.

**Acceptance criteria:**
- Topic matching should use `topicId` instead of display string when available
- If string-based matching is the only option, trimming and case-insensitive comparison should be applied
- Empty results from Topic Focus should suggest nearby topic names

### m2: Weak Areas 10-attempt guard checks all-subjects total instead of per-subject

**Files:** `lib/features/practice/presentation/screens/practice_screen.dart:177-182`

**What's wrong:** The guard `allAttempts.length < 10` checks total attempts across ALL subjects. A user with 130 total attempts across Chemistry and Physics but only 3 in Biology would pass the guard for Biology, then reach `getWeakTopics()` which finds no data for Biology, and see "No weak areas found" — a misleading message. A new user with 9 total attempts sees "Practice at least 10 questions" with no explanation of why 10.

**Acceptance criteria:**
- The guard should check per-subject attempts, not all-subjects total
- The minimum threshold (10) should be documented as a constant with an explanatory comment
- Error messages should explain why the threshold exists and what the user should do

### m3: Weak Areas shows "No weak areas found" for both "you're strong" and "insufficient data"

**Files:** `lib/features/practice/presentation/screens/practice_screen.dart:189-193, 191-193`

**What's wrong:** The snackbar "No weak areas found" appears in two different scenarios: (1) when the user truly has no weak areas (all topics ≥ 70% accuracy), and (2) when there's insufficient data to determine weak areas. The message is ambiguous.

**Acceptance criteria:**
- Differentiate between "no weak areas" (you're doing great!) and "insufficient data" (practice more to identify weak areas)
- The two scenarios must use distinct localized strings
- When insufficient data, the message should guide the user to practice more

### m4: Quick Practice subtitle for low question counts shows localization key

**Files:** `lib/features/practice/presentation/widgets/practice_mode_grid.dart:89-91`

**What's wrong:** `l10n.questionsCount(totalQuestionCount)` is referenced but it resolves through the localization system. This is actually fine — the localization method `questionsCount(int)` exists in both ARB files and generates proper strings like "5 questions." No issue here.

**(Verdict changed: this is a PASS, not a FAIL. Removing from final report.)**

### m5: Space Repetition question count inconsistency — due count badge vs actual session

**Files:** `lib/features/practice/presentation/widgets/practice_mode_grid.dart:61-65` (badge), `lib/features/practice/presentation/screens/practice_screen.dart:234-257` (session launch), `lib/features/practice/presentation/screens/practice_session_screen.dart:103-131` (session loading)

**What's wrong:** The badge count shown on the Spaced Repetition card reflects correct SM-2 due calculations. But the session launched from tapping the card shows a different set of questions (random, not due). The badge tells the user "12 questions due" but the session shows 12 random questions — a misleading user experience.

This is a direct consequence of blocker B3. Fixing B3 will resolve this.

**Acceptance criteria:** (merged into B3's acceptance criteria)

---

## Finding Count Summary

| Severity | Count |
|----------|-------|
| **BLOCKER** | 5 |
| **MAJOR** | 6 |
| **MINOR** | 3 (2 after removing the false positive) |
| **PASS** | 2 |

## Related Files Summary

```
lib/features/practice/providers/practice_providers.dart          — B1 (ReadinessScorer empty data), M3 (DifficultyAdapter unused)
lib/features/practice/services/readiness_scorer.dart             — B1 (scores with empty data), M1 (not used from Dashboard)
lib/features/practice/presentation/screens/practice_screen.dart  — B2 (ordered questions discarded), B3 (SR ignores due filter), M6 (result not consumed), m2 (10-attempt guard), m3 (ambiguous message)
lib/features/practice/presentation/screens/practice_session_screen.dart — B2 (reloads and reshuffles), B3 (loads all questions), B4 (doesn't use nextReview), M1 (no ReadinessScorer in session)
lib/features/practice/services/spaced_repetition_engine.dart     — B4 (correct SM-2 computation, not consumed)
lib/features/practice/services/mastery_recorder.dart             — B4 (correct SR persistence, not consumed for selection)
lib/features/practice/data/repositories/spaced_repetition_repository.dart — B3 (getPracticeQuestions used for count only)
lib/features/practice/services/spaced_repetition_service.dart    — B5 (1-hour tolerance), B3 (due calculation correct but unused)
lib/core/services/mastery_graph_service.dart                     — M4 (getAtRiskQuestions never called)
lib/features/practice/services/difficulty_adapter.dart           — M3 (dead code)
lib/core/data/models/question_model.dart                          — M3 (difficulty field unused), B4 (nextReview unused for selection)
lib/features/practice/data/models/mastery_state_model.dart        — M2 (no history/tracking)
lib/core/services/mastery_calculation_service.dart                — M2 (overwrites state, no snapshots)
lib/features/practice/services/exam_session_service.dart          — M5 (difficulty tiers exist but not exposed)
lib/features/practice/presentation/screens/exam_session_screen.dart — M5 (no difficulty tier UI)
```
