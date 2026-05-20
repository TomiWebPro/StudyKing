# Dry-Run Issue: Adaptive Practice & Mastery Improvement — Remaining Gaps

Generated: 2026-05-19
Source: `dry-run-test/scenario_adaptive_practice_mastery.md`
Validator: Dry-Run Result Validator

---

## Issue 1: Dashboard Individual Weak Topic "Practice" Button Ignores ReadinessScorer

**File:** `lib/features/dashboard/presentation/widgets/weak_areas_card.dart:103-113`

The individual "Practice" button on each weak topic in the Dashboard's WeakAreasCard navigates to `PracticeSessionScreen` with only `subjectId: ''` and `topicId: topicId`. It does **not** use the `ReadinessScorer` to prioritize questions within the topic.

The "Practice All Weak Areas" button (`weak_areas_card.dart:134-147`) **does** use ReadinessScorer correctly — the inconsistency should be fixed by making the individual button also pass ordered question IDs.

**Fix:** In `_practiceWeakArea()`, fetch questions for the topic, call `ref.read(readinessScorerProvider).scoreQuestions()`, and pass `orderedQuestionIds` in `PracticeSessionArgs`.

---

## Issue 2: No Mastery Trend/History Visualization

**Files:**
- `lib/features/practice/data/models/mastery_state_model.dart` (MasteryState model)
- `lib/core/services/mastery_calculation_service.dart` (calculation service)
- `lib/features/dashboard/data/models/dashboard_models.dart` (MasterySnapshot)

The system tracks `recentAccuracy` (last 20 attempts, sliding window) on `MasteryState`, but:
1. There is no long-term snapshot versioning of mastery states over time
2. There is no UI component anywhere showing accuracy/trend progression per topic
3. `MasterySnapshot` is a single-point-in-time aggregate with no history
4. Dashboard "Weekly Activity" shows question **volume**, not accuracy **trend**

**Fix options:**
- **Option A (minimal):** Create a chart widget that reads `recentAccuracy` from `MasteryState` and renders a trend line per topic on the Dashboard.
- **Option B (full):** Implement mastery state snapshotting — save a `MasteryState` snapshot at intervals (daily or per-session) to enable long-term trend data. Then build a trend chart component.

---

## Issue 3: DifficultyController Output Not Applied to Question Selection

**File:** `lib/features/practice/presentation/screens/practice_session_screen.dart:84,215-216`
**File:** `lib/features/practice/services/difficulty_controller.dart`

`DifficultyController` is instantiated and its methods (`recordResult()`, `suggestNextDifficulty()`) are called on every answer submission. However, the return value of `suggestNextDifficulty()` is **never used** to filter, order, or select questions. The practice session always loads and shuffles from the full pool.

Exam mode has its own difficulty controls (separate from `DifficultyController`).

**Fix:** After each answer, use `_difficultyAdapter.currentDifficulty` to filter remaining/unanswered questions, preferring questions matching the current difficulty level.

---

## Issue 4: Topic Focus Mode Missing ReadinessScorer

**File:** `lib/features/practice/presentation/screens/practice_screen.dart:142-170`

`_startTopicPractice()` filters by topic but does **not** use the `ReadinessScorer` to order questions by urgency within the topic. Questions within the topic appear in their original order from the repository.

**Fix:** After filtering questions by topic, call `ref.read(readinessScorerProvider).scoreQuestions(topicQuestions)` and pass the resulting ordered IDs in `PracticeSessionArgs`.

---

## Issue 5: Dashboard Lacks Dedicated Per-Topic Drill-Down Screen

**Files:**
- `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` (has practice buttons but no stats detail)
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart` (shows accuracy bars but no detail view)

There is no screen that shows comprehensive per-topic statistics when tapping a mastery chip or topic name on the Dashboard. Users see current accuracy and level labels but cannot drill into a topic to see: accuracy history, attempt timeline, next review date, confidence trend, etc.

**Fix:** Create a `TopicDetailScreen` that shows full stats for a given `topicId`, including recent accuracy trend, total attempts, next review date (from `nextReview`), confidence history, and a "Practice This Topic" button. Wire it from the Dashboard's mastery chips and WeakAreasCard topic labels.

---

## Issue 6: 10-Attempt Guard Threshold Is an Unexplained Magic Number

**File:** `lib/features/practice/presentation/screens/practice_screen.dart:287`
**Localization:** `l10n.practiceAtLeastTen`

The `_minAttemptsForWeakAreas = 10` threshold is arbitrary. The guard now correctly checks per-subject (fixed), but the error message `l10n.practiceAtLeastTen` does not explain why 10 was chosen.

**Fix:** Either:
- Make the threshold data-driven (compute from question count per topic), or
- Improve the localization message to explain the rationale, or
- Replace the fixed threshold with a percentage-based check (e.g., "you need to have attempted at least 30% of questions in this subject").

---

## Issue 7: Topic Focus Matching Still Uses String Fallback

**File:** `lib/features/practice/presentation/screens/practice_screen.dart:149-157`

Topic matching has been improved to use `topicId` first, but still falls back to `topic!.normalized == trimmedTopic.toLowerCase()` (string comparison against display name). This fallback is fragile if display names contain formatting differences or typos.

**Fix:** Remove the string-based fallback entirely and rely exclusively on `topicId` matching. Ensure all callers pass the `topicId` (not the display name) when invoking `_startTopicPractice()`.

---

## Issue 8: `_startAtRiskPractice` Does Not Capture Session Result

**File:** `lib/features/practice/presentation/screens/practice_screen.dart:448`

`_startAtRiskPractice()` navigates to the practice session but does **not** capture the `PracticeSessionResult` returned by `Navigator.pushNamed()`. All other practice entry points (`_startPractice`, `_startTopicPractice`, `_launchWeakAreasForSubject`, `_startSpacedRepetitionSession`) correctly capture it.

**Fix:** Add `as PracticeSessionResult?` after `Navigator.pushNamed()` and pass the result to `_onSessionResult()`.
