# Dry-Run Scenario: Adaptive Practice & Mastery Improvement — Closing My Weak Areas

## Persona

I'm a student who has been using StudyKing for several weeks. I've completed about 150 practice questions across IB Chemistry and IB Physics. I've attended 4 AI tutor lessons. I know which topics I'm struggling with because I saw them on the Dashboard. Now I want to use the app's adaptive practice features to **systematically close my weak areas**, track my improvement over time, and have the app intelligently adjust to my changing performance.

---

## Step 1: Identifying My Weak Areas — Checking the Dashboard

I open the app and tap the Dashboard button (FAB). I scroll down to find where my weak areas are listed.

**What I expect:** A clear "Weak Areas" section showing topics where my accuracy is below 70%, sorted from worst to best. Tapping a topic lets me practice it immediately.

**What I see:** The Dashboard has a "Mastery Overview" card showing colorful chips per topic with labels like "Proficient", "Developing", "Browsing". There's also a "Weak Areas" card listing topics that need attention. Each weak topic has a tappable "Practice" button.

**But here's the problem:** I tap "Practice" on "Stoichiometry" (my weakest Chemistry topic — 40% accuracy). The navigation pushes to `PracticeSessionScreen` with just `subjectId` and `topicId`. The questions for Stoichiometry load but are **randomly shuffled**. The `ReadinessScorer` that should prioritize high-urgency questions within this topic is **never used** at this entry point. It's only used in the "Weak Areas" grid mode — and even there, it doesn't work properly (see Step 3).

**Verdict (MAJOR FAIL):** The Dashboard's weak topic "Practice" button doesn't use the ReadinessScorer to prioritize questions within the topic. Questions are randomly ordered regardless of their individual urgency levels.

---

## Step 2: Using the "Weak Areas" Practice Mode from the Practice Tab

I go to the Practice tab and tap the **Weak Areas** card (the red one with the bar chart icon).

**What I expect:** The app identifies my weak topics across all subjects, prioritizes the questions I most need to practice, and presents them in a meaningful order — weakest questions first, highest-urgency items at the top.

**What actually happens in the code:**

1. I select IB Chemistry from the Weak Areas subject selector.
2. `_launchWeakAreasForSubject()` runs (practice_screen.dart:171-232):
   - **Guard:** It requires at least 10 total attempts across ALL subjects (`allAttempts.length < 10`). If I have 8 Physics attempts and 5 Chemistry attempts, the guard passes because total is 13. But why 10? This guard is arbitrary and not explained to the user.
   - **Get weak topics:** Calls `masteryService.getWeakTopics(studentId)` which returns topics with `accuracy < 0.7`.
   - **Find matching questions:** Filters ALL questions by weak topic IDs.
   - **Score and order:** Creates `ReadinessScorer` via the provider.
   - **Navigate:** Pushes to `PracticeSessionScreen` with only `subjectId` and `questionCount`.

**Critical defect — ReadinessScorer has no data:**

The `readinessScorerProvider` (practice_providers.dart:94-96) creates `ReadinessScorer()` with **empty maps**:

```dart
final readinessScorerProvider = Provider<ReadinessScorer>((ref) {
  return ReadinessScorer();
});
```

Inside `scoreQuestions()`, every lookup of `_topicMasteryMap[q.topicId]` and `_questionMasteryMap[q.id]` returns **null** because the maps are empty. Every question gets the same default score: `0.47 + 0.19 + difficulty*0.05`. The sorting at line 55 (`scored.sort((a, b) => b.score.compareTo(a.score))`) is effectively a no-op — all scores are near-identical, so the "ordered" questions are in their original iteration order from the repository.

**Critical defect — ordering is thrown away anyway:**

Even if ReadinessScorer had data and correctly ordered questions, look at the args (practice_screen.dart:220-224):

```dart
await Navigator.pushNamed(context, AppRoutes.practiceSession,
    arguments: PracticeSessionArgs(
      subjectId: subject.id,
      questionCount: orderedQuestions.length,
    ));
```

No `topicId` is passed! The session loads **ALL questions for the subject** (practice_session_screen.dart:105), then **shuffles them** (line 120):

```dart
final shuffled = List<Question>.from(filteredQuestions)..shuffle();
```

The `orderedQuestions` list computed by the practice screen is **completely discarded**. The session screen re-fetches and re-shuffles.

**Additionally**, the `Weak Areas` mode doesn't pass `isSpacedRepetition: true`, so even the SM-2 spaced repetition scheduling won't be applied during this session. The mastery recording (`MasteryRecorder.recordAttempt`) always runs regardless of the flag — but the `isSpacedRepetition` flag in `_submitAnswer()` (line 218) controls whether `_updateNextReview()` is called, which explicitly persists the SM-2 `nextReview` date on the question. Without this, the SR scheduling still happens inside `MasteryRecorder.recordAttempt()` (mastery_recorder.dart:55-61) and updates the question's `nextReview` field at line 88-92. Actually, wait — `MasteryRecorder.recordAttempt()` always runs (line 207), and it always calls `_srEngine.scheduleReview()` and saves the updated `nextReview` on the question. So the flag specifically controls the `_updateNextReview()` call in the session screen... which calls `_sessionService.updateNextReview()`. Let me check what that does.

Actually, `_updateNextReview` in the session screen calls `_sessionService.updateNextReview(questionId, isCorrect)` — presumably this does SEPARATE SR logic from `MasteryRecorder.recordAttempt()`. If `MasteryRecorder` already handles this, then the flag is redundant. But if the two paths conflict, there could be inconsistent SR state.

Looking at `PracticeSessionService.updateNextReview()` — I need to check if this duplicates the work already done by `MasteryRecorder.recordAttempt()` or if it adds something. In either case, the `isSpacedRepetition` flag creates a confusing code path.

**Verdict (BLOCKER FAIL):** The "Weak Areas" practice mode has two compounding defects: (1) The ReadinessScorer provider creates the scorer with empty mastery data, making all questions score identically. (2) The ordered questions list is discarded because the session screen reloads and shuffles questions from scratch. The entire adaptive prioritization pipeline is non-functional.

---

## Step 3: Spaced Repetition Practice — Reviewing Due Questions

I tap the **Spaced Repetition** card (clock icon). It shows a badge of 12 due questions. I tap it, select IB Chemistry, and start the session.

**What I expect:** The 12 questions due for review appear first. As I answer, the SM-2 algorithm updates each question's next review date based on my performance. After the session, due counts update automatically.

**What actually happens:**

1. `_startSpacedRepetitionSession()` (practice_screen.dart:234-257) calls `_srRepo.getPracticeQuestions(subject.id)` which fetches questions where `nextReview` is before `now - 1 hour`.
2. It navigates with `isSpacedRepetition: true` and `questionCount: result.data!.length`.
3. The session loads ALL subject questions from the repo (line 105), not just the due ones!
4. Then it shuffles them (line 120) and takes `questionCount` items.

Wait — this means the session includes questions that were NOT due! Let me trace more carefully:

`_startSpacedRepetitionSession()` passes `questionCount: result.data!.length`. This is the count of DUE questions. But the session screen loads `getBySubject(subjectId)` which returns ALL questions for the subject, not just the due ones. Then it takes `questionCount` items after shuffling. So if the subject has 50 total questions and 12 are due, the session shows 12 questions — but they're 12 **random** questions, not the 12 due ones!

Unless `getPracticeQuestions` in `SpacedRepetitionRepository` does something special... Let me check what `getPracticeQuestions` returns.

Actually, I didn't read `spaced_repetition_repository.dart`. But the session screen loads `getBySubject()` independently, which ignores the SR repository's filtered set. The `isSpacedRepetition` flag only adds `_updateNextReview()` on each answer. The actual question set does NOT respect the SR due filter!

Wait — actually, `questionCount` is passed as an argument and the session screen takes `shuffled.take(count).toList()`. So if 12 questions are due and the subject has 50 total questions, the session takes the first 12 from the shuffled 50. These 12 are random — they're NOT the 12 due questions. The SR filtering only happened to determine the count, not the actual questions!

THIS is a defect. The Spaced Repetition session shows random questions up to the due count instead of showing the actual due questions.

**Verdict (MAJOR FAIL):** The "Spaced Repetition" mode calculates the correct `questionCount` from the SR repository, but the session screen loads ALL subject questions and takes a random subset. The actual due questions identified by the SM-2 algorithm are ignored. The session shows random questions instead of the ones due for review.

---

## Step 4: Session Results — Checking My Topic Breakdown

I complete a practice session and see the results screen.

**What I expect:** The results show: total questions, correct/incorrect, accuracy %, and a **topic-by-topic breakdown** so I can see which topics I did well or poorly on.

**What actually happens:** The `PracticeResultsScreen` (practice_results_screen.dart) shows:
- Total questions
- Correct answers
- Accuracy %
- Topic breakdown (if `topicBreakdown.isNotEmpty`)

The topic breakdown IS computed by `_computeTopicBreakdown()` (practice_session_screen.dart:307-324) and passed to the results screen. This works. ✓

**But the results screen is NOT consumed by the Practice screen.** The session result is pushed via `Navigator.pop(context, PracticeSessionResult(...))`, but the `_startPractice()` method (practice_screen.dart:136-140) uses `pushNamed()` without `await`, so it never receives the result:

```dart
Future<void> _startPractice(Subject subject) async {
  await Navigator.pushNamed(context, AppRoutes.practiceSession, ...);
  _loadDueCounts();
}
```

Wait — it does have `await`. Let me re-check... Actually `_startPractice` does `await` on the navigation, and calls `_loadDueCounts()` after. But it doesn't capture the return value. Same with `_launchWeakAreasForSubject` and `_startSpacedRepetitionSession` — all use `await` on `pushNamed` but don't capture the `PracticeSessionResult` that's passed via `Navigator.pop()`. The result is produced but never consumed.

**Verdict (MINOR FAIL):** Topic breakdown is computed and displayed, but session results are not consumed by the parent Practice screen. The due counts are reloaded, but no result data is used.

---

## Step 5: Tracking Mastery Improvement Over Time

After a week of using Weak Areas and Spaced Repetition, I want to see if my Stoichiometry mastery has improved.

**What I expect:** The Dashboard shows my Stoichiometry mastery was 40% last week and is now 65% (or whatever it is). I can see a trend line showing improvement.

**What actually happens:**

The Dashboard's "Mastery Overview" card shows current mastery levels per topic but has **no trend/history**. The `MasteryState` model only stores the CURRENT computed state — it doesn't keep a history of previous states. `MasterySnapshot.getAllMasteryStates()` returns only the latest values.

The Dashboard has a "Weekly Activity" chart (questions per day over 8 weeks) which shows volume but NOT mastery improvement.

The Planner's Dashboard Adherence card shows plan adherence trends. The Session History screen shows past sessions. But **nowhere in the app** can a user see "my Stoichiometry accuracy was 40% on Monday and now it's 65% on Friday."

The `MasteryCalculationService` recomputes mastery states on every `recordAttempt()` call but overwrites the previous state — there's no snapshotting or versioning of mastery states over time.

**Verdict (MAJOR FAIL):** Mastery state has no history/tracking. Users cannot see how their topic mastery has changed over time. The Dashboard's "Mastery Overview" is a single-point-in-time snapshot with no trend information.

---

## Step 6: The Difficulty Adapter — Does the App Adjust to My Skill Level?

After practicing for a while, I notice the questions seem either too easy or too hard. I expect the app to adjust question difficulty based on my recent performance.

**What the code shows:**

The `DifficultyAdapter` class (difficulty_adapter.dart) exists with a streak-based difficulty adjustment mechanism:
- 3 consecutive correct → increase difficulty
- 2 consecutive incorrect → decrease difficulty

**But this class is NEVER used.** The `difficultyAdapterProvider` is defined in `practice_providers.dart:98-99` but no screen or service ever reads it. No practice mode calls `DifficultyAdapter` methods.

The `PracticeSessionScreen` always shuffles questions from the available pool without any difficulty filtering or ordering. The only difficulty-related field on a `Question` is `difficulty` (1-5 integer), but it's never used for question selection or ordering — it only contributes 5% to the (broken) ReadinessScorer score.

**Verdict (MAJOR FAIL):** The `DifficultyAdapter` class and the question difficulty field are both dead code. No practice mode adjusts question difficulty based on user performance.

---

## Step 7: Quick Practice — What Does "Quick" Mean?

I tap the **Quick Practice** card (the flash icon). A bottom sheet appears asking me to select a subject. I select IB Chemistry.

**What I expect:** A quick session with 10 random questions from across all my Chemistry topics, giving me a broad temperature check.

**What happens:** The session loads all Chemistry questions, takes the first 10 after shuffling, and proceeds normally. This matches my expectation of "10 random questions."

But the card subtitle says "10 random questions" only if `totalQuestionCount >= 10`. If I have fewer than 10 questions, it says "questionsCount(totalQuestionCount)" — which is a localization key, not a user-facing string. Wait, let me check — `practice_mode_grid.dart:89-91`:

```dart
String _getQuickPracticeSubtitle(AppLocalizations l10n) {
  if (totalQuestionCount == 0) return l10n.uploadMaterialsToCreateQuestions;
  if (totalQuestionCount < 10) return l10n.questionsCount(totalQuestionCount);
  return l10n.randomQuestions(10);
}
```

`l10n.questionsCount(totalQuestionCount)` is a localization method that should produce something like "5 questions" — that's fine. OK, this works correctly.

The Quick Practice card is disabled when `totalQuestionCount == 0` with the subtitle "Upload materials to create questions." ✓

**Verdict (PASS):** Quick Practice works as advertised. The card appropriately enables/disables based on question availability.

---

## Step 8: Topic Focus — Can I Practice a Specific Weak Topic?

I tap **Topic Focus** (the category icon). A bottom sheet lists all my topics. I select "Stoichiometry".

**What I expect:** I get questions only about Stoichiometry, the topic I'm weak in (40% accuracy). These questions should help me improve this specific area.

**What happens:** The session loads ALL subject questions, filters by the selected topic string, and presents them shuffled. This works for getting topic-specific practice.

**But there's a problem:** The `_startTopicPractice` (practice_screen.dart:142-169) identifies questions by matching `q.topic == topic` (string comparison against the topic display name). This is fragile — if the display name has a typo or formatting difference, the filter silently returns zero questions and shows a "No questions available" snackbar.

Also, **no ReadinessScorer is applied** during Topic Focus mode either, so questions within a topic are randomly ordered regardless of their urgency.

**Verdict (PARTIAL):** Topic Focus works for filtering by topic, but uses fragile string-based matching and doesn't prioritize high-urgency questions within the topic.

---

## Step 9: Exam Mode — Configuring a Test

I tap **Exam Mode**. I configure 15 minutes and 10 questions. I tap "Start Exam."

**What I expect:** The exam selects questions appropriate for my current level — maybe some easy, some medium, some hard — and times me. After the exam, I get a detailed breakdown including topic-by-topic results.

**What actually happens:**

The `ExamSessionService.selectQuestions()` (exam_session_service.dart) supports `easyCount`, `mediumCount`, `hardCount` in `ExamConfig` — but the configuration UI **never exposes these controls**. The `ExamSessionScreen` only shows duration and total question count sliders (`_buildConfigView` — I need to verify this). The actual question selection falls through to the default path which loads all questions for the subject and takes the configured count — same as regular practice.

The exam results DO show a `topicBreakdown` section with per-topic accuracy. This is better than the regular practice results. ✓

The timer IS used in exam mode — when time expires, the exam auto-submits. ✓

**But question difficulty tiers are not exposed to the user**, which means the `ExamConfig.easyCount/mediumCount/hardCount` feature is dead for users — only a programmer who modifies code could use it.

**Verdict (PARTIAL):** Exam mode timer and topic breakdown work. But difficulty tier selection is hidden from users, and the question selection is identical to regular practice.

---

## Step 10: After a Week — Did the Spaced Repetition Schedule Adapt?

I've been practicing daily for a week. Today I open the Spaced Repetition mode again.

**What I expect:** Questions I got correct multiple times in a row should have longer intervals (days or weeks between review). Questions I keep getting wrong should appear daily. The badge count should reflect this.

**What actually happens (tracing the code):**

The SM-2 engine correctly updates intervals:
- First correct → 1 day
- Second consecutive correct → 6 days  
- Subsequent correct → previous interval × ease factor (starts at 2.5)

Questions I get wrong → interval resets to 1 day.

The `SpacedRepetitionService.getQuestionsDueForReview()` correctly computes `dueCounts` for the badge. ✓

But as discovered in Step 3, the *actual session* doesn't use the due questions — it loads ALL questions and takes a random subset. So even though the SM-2 scheduling is correct in data, **the user's practice experience does not respect the schedule**. The adaptive scheduling is stored but never used for session construction.

**Verdict (BLOCKER FAIL):** The SM-2 algorithm correctly computes and stores review schedules, but the Spaced Repetition practice mode ignores them. Users experience random questions instead of algorithmically-scheduled reviews. The entire adaptive scheduling pipeline produces correct data that is never consumed.

---

## Step 11: At-Risk Questions — The Hidden Feature

The `MasteryGraphService.getAtRiskQuestions()` method returns questions with `masteryLevel < 0.5`. These are the questions I'm most likely to get wrong.

**What I expect:** There should be a practice mode or a filter for "at-risk questions" — questions I've repeatedly answered incorrectly.

**What actually happens:** `getAtRiskQuestions()` is NEVER called from any screen. It exists in the service layer but no practice mode uses it. The data about which questions I'm struggling with individually (not just at the topic level) is collected and stored but never surfaced.

The `Weak Areas` mode operates at the TOPIC level (accuracy < 70%), not at the individual QUESTION level. So even if a topic is at 75% accuracy (above the 70% threshold), individual questions within it might have masteryLevel < 0.3 — but those questions won't be surfaced.

**Verdict (MAJOR FAIL):** Question-level at-risk detection exists in the data layer but has no UI. Individual struggling questions are hidden behind topic-level aggregates.

---

## Step 12: Dashboard Progress — The Mastery Snapshot Gap

After all my practice, I check the Dashboard's Mastery Overview.

**What I expect:** The overview shows my current mastery levels, plus I can drill into each topic to see detailed stats (attempts, accuracy trend, streak, next review date).

**What actually happens:** The Dashboard shows mastery chips with colored labels (Proficient, Developing, Browsing, etc.) based on the `MasteryLevel` enum. Tapping a chip... I'm not sure if it navigates anywhere. Let me check what the topic chip tap does on the Dashboard.

The `MasteryOverview` card or `TopicBreakdownCard` — I need to check what these widgets actually do with their tap handlers. Based on the exploration, the Dashboard has several cards including Mastery Overview and Weak Areas. If I tap a mastery chip, it may or may not navigate to a detail view.

The `SubjectDetailScreen` has a "Stats" tab that shows per-topic progress. But there's no direct "poor tutoring" on this from the Dashboard's mastery chips.

Actually, I don't have the full Dashboard source. Let me note what I know: The `StudyProgressTracker.getOverallStats()` returns aggregate stats, and `getTopicProgress()` returns per-topic data. But whether the UI surfaces per-topic drilldowns from the Dashboard's mastery chips is something I need to verify.

Actually, I already know from the existing scenario 2 that the Dashboard has a Mastery Overview card with topic breakdown. Let me rely on what I know from that exploration.

**Verdict (PARTIAL):** Mastery labels are shown but drill-down capability from Dashboard chips is uncertain.

---

## Step 13: The 10-Attempt Guard — Why Does Weak Areas Require 10?

I tap **Weak Areas** for a new subject I just created (IB Biology) where I've only answered 3 questions.

**What I expect:** The app should tell me "You haven't practiced enough Biology to identify weak areas. Practice more first!" or similar.

**What happens:** The guard at `_launchWeakAreasForSubject` lines 177-182 checks `allAttempts.length < 10`. Since I've done 130+ total attempts across Chemistry and Physics, this passes. But I've only done 3 Biology attempts — the guard checks **total across ALL subjects**, not per-subject. The Weak Areas module would load weak topics for Biology, find insufficient data, and show "No weak areas found" — which is misleading because the real issue is insufficient Biology-specific practice, not absence of weak areas.

Also, if I'm a brand new user with 9 total attempts across any subject, the guard blocks me with a snackbar: "Practice at least 10 questions to start Weak Areas mode." This is an unexplained magic number — why 10 and not 5 or 15?

**Verdict (MINOR FAIL):** The 10-attempt guard is arbitrary, checks across all subjects instead of per-subject, and the error message doesn't explain why 10 was chosen.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Dashboard weak topic "Practice" button uses adaptive ordering inside topic | Questions randomly shuffled — no ReadinessScorer applied from this entry point | FAIL (MAJOR) |
| Weak Areas mode prioritizes high-urgency questions | ReadinessScorer created with empty data — all questions score identically | FAIL (BLOCKER) |
| Weak Areas mode passes ordered questions to session | Ordered questions list discarded — session reloads and shuffles from scratch | FAIL (BLOCKER) |
| Spaced Repetition shows due questions from SM-2 schedule | Session loads ALL subject questions, not just due ones | FAIL (MAJOR) |
| Session results are consumed by Practice screen | `PracticeSessionResult` is never captured after Navigator.pop() | FAIL (MINOR) |
| Topic breakdown is shown in results | Breakdown is computed and displayed correctly | PASS |
| Mastery states show improvement over time | No history or trend data — single-point snapshots only | FAIL (MAJOR) |
| DifficultyAdapter adjusts question difficulty based on performance | `DifficultyAdapter` class exists but is never called by any screen | FAIL (MAJOR) |
| Question difficulty field is used for selection | `Question.difficulty` never used for filtering or ordering in any mode | FAIL (MAJOR) |
| Quick Practice provides random questions | Works correctly with appropriate enable/disable logic | PASS |
| Topic Focus uses robust topic matching | Fragile string-based matching against display name | FAIL (MINOR) |
| Exam mode supports difficulty tier selection | `easyCount/mediumCount/hardCount` in code but no UI controls | FAIL (MAJOR) |
| SM-2 schedule correctly adapts to performance | Correct scheduling in data layer; not used for session question selection | FAIL (BLOCKER) |
| At-risk questions (mastery < 50%) have a practice mode | `getAtRiskQuestions()` exists but is never called from any screen | FAIL (MAJOR) |
| 10-attempt Weak Areas guard is per-subject | Checks all-subjects total; magic number with no explanation | FAIL (MINOR) |
| Weak Areas shows clear message for insufficient subject data | Shows "No weak areas found" — misleading when data is insufficient | FAIL (MINOR) |

---

## Dry-Run Validation Results (2026-05-19)

Validation performed against production source code. The analysis below reconciles the scenario's claims with the actual codebase.

### Step 1: Dashboard Weak Topic "Practice" Button
**Assessment: NOT_COMPLETED** *(claimed MAJOR FAIL — confirmed for individual button)*

| Claim | Actual |
|---|---|
| Individual topic "Practice" button doesn't use ReadinessScorer | **Confirmed.** `WeakAreasCard._practiceWeakArea()` at `weak_areas_card.dart:103-113` navigates with only `subjectId: ''` and `topicId`. No scorer. |
| "Practice All Weak Areas" doesn't use ReadinessScorer | **Incorrect for current code.** `WeakAreasCard._practiceAllWeakAreas()` at `weak_areas_card.dart:134-147` DOES use `ref.read(readinessScorerProvider)` and passes `orderedQuestionIds`. |

**Still missing:** Individual topic practice button on Dashboard WeakAreasCard should use ReadinessScorer for question prioritization within topic.

### Step 2: Weak Areas Mode from Practice Tab
**Assessment: COMPLETED** *(both BLOCKER FAIL claims resolved)*

| Claim | Actual |
|---|---|
| ReadinessScorer created with empty maps | **Incorrect.** `readinessScorerProvider` at `practice_providers.dart:77-84` injects `masteryService` and `studentIdService`. `ReadinessScorer._ensureDataLoaded()` at `readiness_scorer.dart:53-79` loads actual topic and question mastery data from repositories. |
| Ordered questions list discarded; session reloads and shuffles | **Incorrect.** `_launchWeakAreasForSubject()` at `practice_screen.dart:330-345` passes `orderedQuestionIds`. Session screen's `_loadQuestions()` at `practice_session_screen.dart:114-118` checks for `orderedQuestionIds` first and calls `_loadOrderedQuestions()` which preserves the order. |

### Step 3: Spaced Repetition Due Questions
**Assessment: COMPLETED** *(claimed MAJOR FAIL — fixed in current code)*

| Claim | Actual |
|---|---|
| Session loads ALL subject questions not just due ones | **Incorrect.** `_startSpacedRepetitionSession()` at `practice_screen.dart:234-257` calls `_srService.getPracticeQuestions()` to get due questions, collects their IDs, and passes them as `orderedQuestionIds`. Session screen respects the ordered IDs. |

### Step 4: Session Results Consumption
**Assessment: COMPLETED** *(claimed MINOR FAIL — fixed)*

| Claim | Actual |
|---|---|
| `PracticeSessionResult` never captured | **Incorrect.** `_startPractice()`, `_startTopicPractice()`, `_launchWeakAreasForSubject()`, `_startSpacedRepetitionSession()` all capture the return value via `as PracticeSessionResult?` and pass to `_onSessionResult()`. |
| Result partially unused | **Minor caveat:** `_startAtRiskPractice()` at `practice_screen.dart:448` does NOT capture the result — only calls `_loadDueCounts()`. `_onSessionResult()` only uses result for `_questionsToday` counter and `_loadDueCounts()`. |

### Step 5: Mastery Improvement Over Time
**Assessment: NOT_COMPLETED** *(claimed MAJOR FAIL — confirmed)*

| Claim | Actual |
|---|---|
| No trend/history of mastery states | **Confirmed.** `MasteryState` at `mastery_state_model.dart:12-192` stores `recentAccuracy` (last 20 values sliding window) — a limited recent history. No long-term snapshot history exists. |
| No UI for trend visualization | **Confirmed.** Dashboard's "Weekly Activity" chart shows question volume per day, not accuracy trends. `MasterySnapshot` is single-point-in-time. There is no "accuracy over time" chart anywhere in the app. |

**Still missing:** A trend/history chart showing accuracy progression per topic over time. Need either snapshot versioning of mastery states or a chart component that reads recentAccuracy / attempt history.

### Step 6: DifficultyAdapter / DifficultyController
**Assessment: PARTIAL** *(claimed MAJOR FAIL — partially addressed)*

| Claim | Actual |
|---|---|
| DifficultyAdapter never called by any screen | **Incorrect for current code.** `DifficultyController` (not `DifficultyAdapter`) IS instantiated at `practice_session_screen.dart:84` and its methods ARE called at lines 215-216: `_difficultyAdapter.recordResult(isCorrect)` and `_difficultyAdapter.suggestNextDifficulty()`. |
| Question.difficulty never used for filtering | **Partially incorrect.** Exam mode DOES expose difficulty sliders (`exam_session_screen.dart:549-622`) and `ExamSessionService.selectQuestions()` (`exam_session_service.dart:116-155`) DOES use easyCount/mediumCount/hardCount for difficulty-tier selection. |
| Output of suggestNextDifficulty() unused | **Confirmed.** The return value of `suggestNextDifficulty()` is never used to filter or order questions in practice sessions. The method is called but the result is thrown away. |

**Still missing:** Practice session should use DifficultyController.currentDifficulty to filter questions at the appropriate difficulty level. Currently it's called but its output has no effect on question selection.

### Step 7: Quick Practice
**Assessment: COMPLETED** *(PASS confirmed)*

Quick Practice works correctly — 10 random questions, appropriate enable/disable logic.

### Step 8: Topic Focus
**Assessment: PARTIAL** *(claimed PARTIAL — improved but still incomplete)*

| Claim | Actual |
|---|---|
| Fragile string-based matching | **Partially addressed.** `_startTopicPractice()` at `practice_screen.dart:149-157` now uses `q.topicId == trimmedTopic` first (ID-based), falling back to `q.topic!.normalized == trimmedTopic.toLowerCase()` (string-based). This is more robust than pure string matching. |
| No ReadinessScorer applied | **Confirmed.** Topic Focus mode does not use ReadinessScorer for question ordering within the topic. |

**Still missing:** Topic Focus should apply ReadinessScorer to order questions by urgency within the selected topic.

### Step 9: Exam Mode
**Assessment: COMPLETED** *(claimed PARTIAL — resolved)*

| Claim | Actual |
|---|---|
| Difficulty tiers hidden from users | **Incorrect.** `exam_session_screen.dart:549-622` now has `_buildDifficultySelector()` with Easy/Medium/Hard sliders exposed in the configuration UI. |
| Question selection identical to regular practice | **Incorrect.** `ExamSessionService.selectQuestions()` at `exam_session_service.dart:116-155` uses difficulty-tier filtering when config has difficulty counts. |

### Step 10: SM-2 Schedule Adaptation
**Assessment: COMPLETED** *(claimed BLOCKER FAIL — fixed)*

| Claim | Actual |
|---|---|
| SR schedule not used for session construction | **Incorrect.** `_startSpacedRepetitionSession()` at `practice_screen.dart:234-257` collects due question IDs and passes them as `orderedQuestionIds`. The session respects these via `_loadOrderedQuestions()`. |
| Users experience random questions instead of scheduled | **Incorrect.** Due questions from SM-2 scheduling are now correctly used for the session. |

### Step 11: At-Risk Questions
**Assessment: COMPLETED** *(claimed MAJOR FAIL — resolved)*

| Claim | Actual |
|---|---|
| getAtRiskQuestions() never called from any screen | **Incorrect.** `_startAtRiskPractice()` at `practice_screen.dart:428-453` calls `masteryService.getAtRiskQuestions(studentId)`, uses ReadinessScorer, and navigates to practice session. UI entry point exists in `_buildExtraModes()` at `practice_screen.dart:399-403`. |

### Step 12: Dashboard Drill-Down
**Assessment: PARTIAL** *(claimed PARTIAL — confirmed)*

| Claim | Actual |
|---|---|
| Mastery chips navigability uncertain | **Partially resolved.** WeakAreasCard has per-topic "Practice" buttons (`weak_areas_card.dart:77-81`) that navigate to a filtered practice session. TopicBreakdownCard shows per-topic accuracy bars with labels. |
| No dedicated drill-down screen | **Confirmed.** There is no per-topic detail screen that shows comprehensive stats (accuracy history, attempt timeline, next review date, etc.) accessible from the Dashboard's mastery chips. |

**Still missing:** A topic detail screen accessible from the Dashboard that shows comprehensive stats for a selected topic.

### Step 13: The 10-Attempt Guard
**Assessment: PARTIAL** *(claimed MINOR FAIL — partially addressed)*

| Claim | Actual |
|---|---|
| Checks all-subjects total | **Incorrect.** `_launchWeakAreasForSubject()` at `practice_screen.dart:296-305` now checks `subjectAttempts.length < _minAttemptsForWeakAreas` — per-subject filtering. |
| Magic number with no explanation | **Confirmed.** `_minAttemptsForWeakAreas = 10` on line 287 is still arbitrary with no explanation to the user. The error message uses `l10n.practiceAtLeastTen` which doesn't explain the rationale. |

**Still missing:** Either make the threshold configurable, derive it from data, or improve the error message to explain the requirement.

---

### Summary Table

| # | Expectation | Scenario Verdict | Validation Result |
|---|---|---|---|
| 1 | Dashboard weak topic button uses adaptive ordering | FAIL (MAJOR) | **NOT_COMPLETED** |
| 2a | Weak Areas uses ReadinessScorer with data | FAIL (BLOCKER) | **COMPLETED** |
| 2b | Weak Areas passes ordered questions to session | FAIL (BLOCKER) | **COMPLETED** |
| 3 | Spaced Repetition shows due questions | FAIL (MAJOR) | **COMPLETED** |
| 4 | Session results consumed by Practice screen | FAIL (MINOR) | **COMPLETED** |
| 5 | Mastery states show improvement over time | FAIL (MAJOR) | **NOT_COMPLETED** |
| 6a | DifficultyAdapter adjusts difficulty | FAIL (MAJOR) | **PARTIAL** |
| 6b | Question difficulty used for selection | FAIL (MAJOR) | **PARTIAL** |
| 7 | Quick Practice provides random questions | PASS | **COMPLETED** |
| 8a | Topic Focus uses robust topic matching | FAIL (MINOR) | **PARTIAL** |
| 8b | Topic Focus uses ReadinessScorer | — (not explicitly listed) | **NOT_COMPLETED** |
| 9 | Exam mode supports difficulty tier selection | FAIL (MAJOR) | **COMPLETED** |
| 10 | SM-2 schedule correctly used for sessions | FAIL (BLOCKER) | **COMPLETED** |
| 11 | At-risk questions have a practice mode | FAIL (MAJOR) | **COMPLETED** |
| 12 | Dashboard mastery chips have drill-down | PARTIAL | **PARTIAL** |
| 13a | 10-attempt guard is per-subject | FAIL (MINOR) | **COMPLETED** |
| 13b | Error message explains magic number | FAIL (MINOR) | **PARTIAL** |

**Overall completion rate: 7/17 items fully COMPLETED (41%).** Including partial completions: ~71%. Below 80% threshold — scenario file retained, issue file created.
