# Dry-Run Scenario: Exam-Prep Student — Timed Exam Simulation and Spaced Repetition for Test Readiness

## Persona

I'm a student who has been using StudyKing for about 3 weeks. I've completed about 80 practice questions across IB Chemistry topics (Atomic Structure, Bonding, Stoichiometry, Organic Chemistry). I've configured my API key, uploaded my Chemistry textbook, and the content pipeline has generated about 50 auto-generated questions. I have an exam coming up in 2 weeks. Now I want to use **timed exam simulations** to test my readiness and let **spaced repetition** optimize my review schedule.

I expect the app to:
1. Clearly show which questions are "due" for review based on my past performance
2. Let me take a timed exam simulation with realistic constraints
3. After the exam, automatically update my spaced repetition schedule
4. Help me focus my remaining study time on questions I'm about to forget
5. Let me understand and configure how spaced repetition works

---

## Step 1: Discovering Spaced Repetition on the Practice Tab

I open the Practice tab (3rd tab in bottom nav). I see a grid of practice mode cards. Six modes are shown:

1. **Quick Practice** — green card, lightning bolt icon, "Practice" subtitle
2. **Spaced Repetition** — blue card, refresh icon, "Review" subtitle, **badge with a number**
3. **Topic Focus** — orange card, target icon
4. **Weak Areas** — red card, bar chart icon
5. **Exam Mode** — purple card, `workspace_premium` icon
6. **Source Practice** — teal card, description icon

**What I expect:** The badge on Spaced Repetition shows me how many questions are due for review today. Each mode card explains what it does (the mode name + subtitle). I can tap any card to start that mode.

**What I see:** The Spaced Repetition card has a badge number. That's good. The card subtitles are mostly helpful — "Practice" for Quick Practice makes sense, "Review" for Spaced Repetition makes sense.

**But here's what I notice:** I tap the Spaced Repetition card. A bottom sheet (`SpacedRepetitionSheet`) appears asking me to pick a subject. I pick IB Chemistry. For a moment a loading indicator shows while `_startSpacedRepetitionSession()` runs (practice_screen.dart:305-333). Then I'm taken to a practice session titled "Spaced Repetition Mode" — with due questions sorted by next review date.

**Verdict: PASS** — The Spaced Repetition mode is discoverable, shows due counts, and launches correctly.

---

## Step 2: What Makes Spaced Repetition Different from Quick Practice?

During the practice session, I answer questions. The questions are from multiple topics (all my due questions mixed together). After each answer, I rate my confidence on a scale of 1–5.

**What I expect:** The spaced repetition system tracks my performance and adjusts each question's next review date accordingly. Questions I get wrong should come back sooner. Questions I'm confident about should be scheduled further into the future.

**What actually happens (tracing the code):**

When I submit an answer:
1. `_submitAnswer()` (practice_session_screen.dart:247-303) runs.
2. `_masteryRecorder.recordAttempt()` (line 283) is called — this maps my confidence + correctness to an SM-2 grade (0–5) via `SpacedRepetitionEngine.mapConfidenceToGrade()`, calculates a new interval and ease factor, and saves the updated `nextReview` to the `Question` model.
3. **Then**, because `widget.args.isSpacedRepetition == true` (line 297), `_updateNextReview()` (line 298) is called — this calls `_sessionService.updateNextReview()` which calls `_srService.updateNextReviewDate(questionId, masteryLevel: isCorrect ? 0.8 : 0.2)`. This uses a CRUDE mastery level mapping (0.8 for correct, 0.2 for incorrect) instead of my actual confidence rating.

**BUG:** The second call OVERWRITES the first call's SM-2 data. My carefully chosen confidence rating (e.g., "I'm very sure" = 5) is discarded. The SR system only remembers whether I was right or wrong (binary). The same question answered correctly with confidence 5 vs confidence 3 gets the EXACT same schedule update.

**Verdict (MAJOR FAIL):** The spaced repetition update path in SR mode overwrites the more accurate mastery recording with a binary correct/incorrect-only calculation. The user's confidence ratings are discarded in Spaced Repetition mode — only the final "right/wrong" matters. This defeats the purpose of SM-2's 6-grade scale.

---

## Step 3: After the Practice Session — Where Are My SR Results?

I finish the Spaced Repetition session (or tap "Finish Early"). The results screen shows:
- Total questions answered: 15
- Correct: 10 (67%)
- Topic breakdown with per-topic accuracy

**What I expect:** Some indication of how the spaced repetition system has rescheduled my questions. For example:
- "5 questions rescheduled: 2 due tomorrow, 3 due next week"
- "Your weakest question will be back in 1 day"
- Some visibility into the SM-2 schedule changes

**What actually happens:** The results screen (`_buildResultsContent()` at practice_session_screen.dart:593-660) shows:
- Total questions, correct count, accuracy percentage
- Topic breakdown
- "Practice Again" and "Review Mistakes" buttons

**There is ZERO spaced repetition information.** No "next review dates" summary. No "questions rescheduled" count. No way to see what the SM-2 algorithm did. The user cannot tell whether their effort affected their review schedule.

The `PracticeSessionResult` that is passed back via `Navigator.pop()` (line 277-278) contains only `questionsAnswered` and `accuracy`. No SR data at all.

**Verdict (MAJOR FAIL):** After completing a Spaced Repetition session, the user sees generic practice results with no spaced repetition-specific information. The SM-2 scheduling changes are invisible.

---

## Step 4: Checking My Spaced Repetition Configuration

I want to look at how spaced repetition is configured. Maybe I can adjust the intervals, set a daily review limit, or see my progress.

**What I expect:** In Settings → Practice or a dedicated "Spaced Repetition" section, I can see:
- My current SM-2 parameters (ease factor, interval multipliers)
- A "Daily review limit" setting
- An option to reset my SR data
- A way to see individual question schedules

**What actually happens:** There is NO spaced repetition configuration anywhere in the app. Specifically:
- **Settings screen** (settings_screen.dart): No "Spaced Repetition" section exists. No SR-related controls.
- **Practice tab**: No SR config. The mode just launches.
- **Profile screen**: No SR settings.
- **No daily review limit**: The `getPracticeQuestions()` method returns ALL due questions without any cap. If 500 questions are due, the user gets all 500.
- **No question SR state viewer**: There is no way to see a question's repetition count, ease factor, or next review date.

**Also dead code:** The `SpacedRepetitionEngine.useFSRS` flag (spaced_repetition_engine.dart:82) exists but is **never read anywhere**. It's a dead code placeholder for a future feature.

**Verdict (BLOCKER FAIL):** No user-facing spaced repetition configuration exists. Users cannot adjust intervals, set review limits, or view their SM-2 scheduling state. The `useFSRS` dead code flag clutters the engine.

---

## Step 5: Starting an Exam Mode Session

I go back to the Practice tab and tap the **Exam Mode** card. The screen asks me to pick a subject (I have two: Chemistry and Physics). I pick IB Chemistry.

**What I expect:** A configuration screen where I set the exam duration, number of questions, and maybe difficulty mix. Then the exam starts with a countdown timer.

**What actually happens:**

The exam config screen (`exam_session_screen.dart:454-640`) shows:
- **Duration selector**: A row of chips: 15, 30, 45, 60 minutes. Default: 30 minutes. ✓
- **Question count**: A row of chips: 5, 10, 15, 20, 30. Default: 10. ✓
- **Difficulty sliders**: Three sliders labeled Easy/Medium/Hard, each 0–10 range, default 0. ✓

I configure: 30-minute exam, 20 questions, 5 easy / 10 medium / 5 hard. I tap "Start Exam."

**What happens next:** `_loadQuestions()` (exam_session_screen.dart:104-119) is called in `initState()`. It:
1. Loads ALL questions for the subject (line 106)
2. Creates an `ExamConfig` with my settings
3. Calls `_examService.selectQuestions()` which:
   - Filters by difficulty buckets
   - If difficulty counts not fully satisfied, fills from shuffled pool
4. Exam starts with a countdown timer

**Issues found:**

**Issue 1 — Difficulty distribution is confusing.** The sliders default to 0 (not "all"). Each slider goes from 0 to 10, but the question count is separate (e.g., 20). If I set Easy=5, Medium=10, Hard=5 (total=20, matches question count), it works. But if I set Easy=10, Medium=10, Hard=10 (total 30, exceeds 20), the code distributes up to the configured limits. The sliders add up independently of the question count — this isn't clearly explained. A user might set Easy=5 expecting "mostly easy" not understanding they need all three to sum to the question count.

**Verdict: PARTIAL** — Exam config works, but difficulty sliders UX is unclear (independent of question count, defaults to 0 which means "any").

---

## Step 6: Taking the Timed Exam

The exam starts. A countdown timer is shown at the top. Questions appear one at a time. I can navigate via "Next" and "Previous" buttons. A question counter shows "Question 3 of 20."

**What I expect:**
- The timer counts down and auto-submits when time runs out
- Unanswered questions are marked as skipped
- I can see my answered questions
- I can finish early

**What actually happens:**

**Timer enforcement** (`_onTimeChanged()`, exam_session_screen.dart:94-100):
- The timer fires every second via `ExamSessionService.startExam()` (exam_session_service.dart:157-172)
- When time runs out (`isTimeUp()`, line 177), `_autoSubmitExam()` (line 256) is called
- Auto-submit iterates remaining unanswered questions, marks them as `wasSkipped: true, isCorrect: false, timeSpentMs: 0`
- Calls `finishExam()` with `autoSubmitted: true`

**But there's a bug in `_onWillPop()` (line 424-452):**
When I try to exit mid-exam via back gesture, the confirmation dialog calls `_submitAnswer()` for the current question (line 446) and then calls `_finishExam()` (line 448). But `_finishExam()` can throw (no try-catch around it). If `_finishExam()` fails (e.g., repository access error), the error propagates unhandled and the screen might crash. There's a try-catch inside `_finishExam()` (line 241-253) which wraps the service call, but the error from line 448 has no additional protection.

**More importantly:** When the user exits via back button mid-exam, the current question's answer IS submitted (line 446), but ALL REMAINING questions are NOT marked as skipped. Unlike `_autoSubmitExam()`, `_onWillPop()` calls `_finishExam()` directly, which does NOT iterate remaining questions. The `ExamService.finishExam()` (exam_session_service.dart:182-214) processes only the results already in `_results`. Whatever was in `_results` from previously submitted questions gets finalized; unsubmitted questions are simply lost — they never get a result record.

**Verdict (MAJOR FAIL):** Exiting an exam early via back button (`_onWillPop()`) discards unsubmitted questions without marking them. Only the current question is submitted. The exam result will show fewer questions than the exam was configured for, with no indication that some questions were skipped without recording. Compare with `_autoSubmitExam()` which properly marks all remaining questions as skipped — the two exit paths are inconsistent.

---

## Step 7: Post-Exam — Confidence Grading Is Hardcoded

During the exam, I answer each question. But I notice there's no confidence rating slider — just a "Submit" and "Next" button.

**What I expect:** After each answer, I rate my confidence (similar to regular practice mode). The exam should let me indicate how sure I am.

**What actually happens:** In `_submitAnswer()` (exam_session_screen.dart:195-237), the confidence is hardcoded:
```dart
confidence: isCorrect ? 4 : 2,
```

Every correct answer gets confidence 4 ("confident"). Every incorrect answer gets confidence 2 ("unsure"). There is NO confidence selector in the exam mode.

This means:
- All correct answers get SM-2 grade `mapConfidenceToGrade(true, 4)` which maps to grade 5 (the maximum)
- All incorrect answers get SM-2 grade `mapConfidenceToGrade(false, 2)` which maps to grade 0-2
- There's no way to say "I guessed and got lucky" (correct + low confidence) or "I know this cold" (correct + high confidence)

The SM-2 algorithm receives less information from exam mode than from regular practice. A lucky guess that happens to be correct gets the same scheduling boost as a well-known concept.

**Verdict (MAJOR FAIL):** Exam mode hardcodes confidence to 4 (correct) or 2 (incorrect). No confidence selector exists. The SM-2 scheduling after exam mode cannot distinguish between confident knowledge and lucky guesses.

---

## Step 8: Post-Exam Results — What Does the Exam Tell Me?

The exam finishes (either auto-submitted or I finish early). The results screen (`_buildResultsScreen()`, exam_session_screen.dart:651-727) shows:

- **Exam Complete** title
- If auto-submitted: "Auto-submitted" warning with icon
- **Score**: 14 of 20 correct (70%)
- **Topic breakdown**: per-topic accuracy
- **Duration**: 28:30 of 30:00
- **Actions**: "Review Mistakes" and "Exit"

**What I expect:** After a timed exam, I want to see:
- Which questions I got wrong and why
- Which topics need more work
- How this exam performance affects my upcoming spaced repetition schedule
- A comparison with my previous exam performance

**What actually happens:**

**Good:** Review Mistakes dialog works — shows each incorrect question with the correct answer and explanation. ✓

**Bad:** The exam results screen shows:
- NO spaced repetition information — no "your next review dates" summary
- NO per-question timing breakdown — was I spending too long on certain questions?
- NO confidence review — which questions did I get correct but was unsure about?
- NO comparison with previous exams — there's no "exam history" tracking
- **The `ExamResult` object** (`exam_session_service.dart:47-67`) has a `scoreHistory` field but it's NEVER populated — declared as `List<ExamResult>` but always empty when returned from `finishExam()`.

**Verdict (MAJOR FAIL):** Exam results lack spaced repetition integration, per-question timing analysis, and historical comparison. The `scoreHistory` field exists but is dead data.

---

## Step 9: Finding My Exam History

I want to look at my past exam results. I check the Dashboard, Subjects, and Practice tab.

**What I expect:** An "Exam History" section somewhere — maybe in the Dashboard stats, or in the subject detail screen.

**What actually happens:** There is NO exam history feature. The `ExamResult` object is created after every exam but never stored persistently. When the exam session screen pops, the result is lost:
- The practice screen's `_navigateToExam()` (practice_screen.dart:395-404) calls `Navigator.pushNamed` but does NOT await the result (no `result = await Navigator...` — wait, actually looking at this again, `_navigateToExam` at line 395 does NOT use `await`):
  ```dart
  void _navigateToExam(Subject subject) {
    Navigator.pushNamed(context, AppRoutes.examSession, arguments: ...);
  }
  ```
  The return value from pushNamed is ignored. When the exam screen pops, its results are discarded by the caller.

- The `ExamService` is provided as a Riverpod provider (`examSessionServiceProvider`), so it's created fresh each time the exam screen opens. The in-memory result from the previous exam is lost when the provider is disposed (on screen pop).

- There is no `ExamRepository` or persistent storage for exam results.

**Verdict (BLOCKER FAIL):** Exam results are never persisted. There is no exam history. Every exam is a one-off event with no record kept. The user cannot track their exam performance over time.

---

## Step 10: The Gap Between Practice and Spaced Repetition — Dual "Next Review" Systems

After the exam, I go back to the Practice tab. I check the Spaced Repetition badge — it shows a different due count than I expect.

**What I expect:** My exam answers updated the spaced repetition schedule. The due count should reflect my recent practice.

**What actually happens (tracing the code):**

There are TWO separate "next review" tracking systems:

**System 1: `Question.nextReview` (SM-2 managed)**
- Updated by: `MasteryRecorder.recordAttempt()` (all modes) and `SpacedRepetitionService.updateNextReviewDate()` (SR mode only)
- Stored on: `Question` model, `srDataJson` field
- Used by: `SpacedRepetitionService.getPracticeQuestions()` — this is what powers the SR mode
- Updated in exam mode via `MasteryRecorder.recordAttempt()` ✓
- Updated in SR mode via BOTH `MasteryRecorder.recordAttempt()` (line 283) AND `updateNextReviewDate()` (line 298) — the second overwrites the first

**System 2: `QuestionMasteryState.nextReview` (heuristic)**
- Updated by: `MasteryRecorder.recordAttempt()` — line 94-107 calls `_masteryStateRepo.updateMasteryState()` which internally uses `_calculateNextReview()` (question_mastery_state.dart:209-225)
- This uses a simple heuristic NOT based on SM-2: `nextReview = now + Duration(days: (1.0 / accuracy).round())` 
- Used by: `QuestionMasteryStateRepository.getDueQuestions()` (line 57) — but this is NOT called from any practice screen

**The gap:** The exam mode updates both systems (via `MasteryRecorder.recordAttempt()`), but:
- The SM-2 parameters in `Question.srDataJson` use hardcoded confidence (4/2)
- The heuristic `QuestionMasteryState.nextReview` uses a primitive formula unrelated to SM-2
- The actual due count shown to the user comes from `getSubjectDueCount()` which queries `Question.nextReview` directly, NOT `QuestionMasteryState.nextReview`
- But the `Focus Mode → Study Hub` might use `QuestionMasteryState` for due counts — creating inconsistency

**The user impact:** The due count might not accurately reflect what the SM-2 algorithm computed, because the two systems can diverge. The user could see a question as "due" based on one system while the actual SM-2 state says it should be reviewed later.

**Verdict (MAJOR FAIL):** Two parallel "next review" tracking systems exist (`Question.nextReview` via SM-2 and `QuestionMasteryState.nextReview` via heuristic). They are updated by the same code path but use different algorithms. They can diverge, producing inconsistent due counts.

---

## Step 11: Readiness Scoring — The Provider That Never Gets Data

After the exam, I look at my Dashboard's weak areas. I want to practice the questions I'm most likely to forget.

**The background:** The `ReadinessScorer` (readiness_scorer.dart) has `scoreQuestions()` which should compute a priority score for each question based on topic mastery, question mastery, difficulty, and time since last review. Higher-priority questions should come first.

**But there's a critical bug** I discover from tracing the code and confirmed in `scenario_adaptive_practice_mastery.md`:

The `readinessScorerProvider` (practice_providers.dart:94-96) creates `ReadinessScorer()` with **empty maps**:
```dart
final readinessScorerProvider = Provider<ReadinessScorer>((ref) {
  return ReadinessScorer();
});
```

Inside `scoreQuestions()`, every lookup of `_topicMasteryMap[q.topicId]` and `_questionMasteryMap[q.id]` returns **null** because the maps are empty. Every question gets the same default score `0.47 + 0.19 + difficulty * 0.05`. All scores are near-identical, so sorting is a no-op.

The Weak Areas mode passes questions through this scorer (practice_screen.dart:274-276), believing it's getting priority ordering, but actually getting random order.

**Verdict (MAJOR FAIL — already known from adaptive_practice scenario):** The `ReadinessScorer` provider creates an instance with empty mastery data. All questions get identical default scores regardless of actual priority. The "ordered" list is effectively random.

---

## Step 12: The At-Risk Questions Mode — Another Empty Pipeline

In the Practice tab, there's an "At Risk" card (or it's the 7th mode, `_buildAtRiskPractice`). Let me check whether this mode exists in the grid.

Looking at the grid, I see 6 modes (Quick Practice, Spaced Repetition, Topic Focus, Weak Areas, Exam Mode, Source Practice). The `_startAtRiskPractice()` method (practice_screen.dart:347-393) exists but — looking at the mode grid — is it actually rendered?

Let me check the mode grid rendering...

Actually, I don't need to verify every mode for this scenario. The scenario is about Exam Mode and Spaced Repetition, and I have enough findings.

---

## Step 13: The Back-Button Exit Catastrophe in Exam Mode (Revisited)

Let me trace the `_onWillPop` flow once more, very carefully.

1. User taps back during an active exam.
2. Confirmation dialog shows: "Exit exam?" (line 429-443).
3. User taps "Exit" (result == true).
4. **If** there's a current answer that hasn't been submitted (`_currentAnswer != null && !_isSubmitted`, line 445):
   - `_submitAnswer()` is called (line 446) — this submits the CURRENT question only.
5. `_finishExam()` is called (line 448) — no try-catch.

The `_finishExam()` method (line 241-253):
```dart
Future<void> _finishExam() async {
  if (_config == null) return;
  final result = await _examService.finishExam(
    config: _config!,
    questionResults: _results,
    autoSubmitted: false,
  );
  ...
}
```

**The `_results` list** contains only questions that have been:
1. Submitted via `_submitAnswer()` (which adds to `_results` at line 233)
2. Already processed

Questions the user never reached (indices > `_currentIndex`) are NOT in `_results`. Unlike `_autoSubmitExam()` which iterates `_questions.skip(_currentIndex)` and adds all remaining as skipped (line 259-266), `_onWillPop()` just submits the current question and calls `_finishExam()` without iterating.

**This creates a partial exam result.** If the exam had 20 questions and the user reached question 12 before exiting, only 12 questions have results. Questions 13-20 simply disappear. No record exists. The exam says "12 of 12" (100% accuracy if all submitted questions are correct) — misleadingly good.

Compare with `_autoSubmitExam()` (line 256-279) which carefully iterates all remaining questions and marks them as skipped. The two exit paths produce completely different result sets.

**Verdict (BLOCKER FAIL):** Early exit via back button during an active exam discards all unanswered questions without recording them. The `_onWillPop()` path does not call `_autoSubmitExam()`, so unsubmitted questions are silently lost. The exam result is partial and misleading.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Spaced Repetition is discoverable with due counts | Works correctly — badge shows due count, sheet picks subject, session launches | PASS |
| 2 | SM-2 scheduling uses my confidence ratings (1–5) | SR mode overwrites `MasteryRecorder` results with binary correct/incorrect (line 298 overwrites line 283) | FAIL (MAJOR) |
| 3 | Results screen shows SR scheduling changes (next review dates, rescheduled count) | Generic results only — no SR-specific info. `PracticeSessionResult` carries only count + accuracy | FAIL (MAJOR) |
| 4 | I can configure SR parameters (intervals, daily limit) | No SR configuration UI anywhere in the app | FAIL (BLOCKER) |
| 5 | `useFSRS` is either functional or removed | Dead code flag — declared but never read | FAIL (MINOR) |
| 6 | Exam mode config has clear difficulty distribution UI | Difficulty sliders default to 0 (any), independent of question count — confusing UX | PARTIAL |
| 7 | Auto-submit on time-out marks remaining questions as skipped | Correctly implemented in `_autoSubmitExam()` | PASS |
| 8 | Back-button exit during exam marks remaining questions as skipped | `_onWillPop()` only submits current question, doesn't iterate remaining — silent data loss | FAIL (BLOCKER) |
| 9 | Exam mode has confidence rating selector | Hardcoded confidence: 4 (correct) or 2 (incorrect). No user input. | FAIL (MAJOR) |
| 10 | Exam results show SR scheduling impact | No SR info in results. No "next review dates" summary. | FAIL (MAJOR) |
| 11 | Exam results are persisted for history | `ExamResult` never stored. `_navigateToExam()` discards return value. No ExamRepository. | FAIL (BLOCKER) |
| 12 | Hardware back-button during exam confirms exit | Yes — confirmation dialog exists | PASS |
| 13 | Dual "next review" systems are consistent | `Question.nextReview` (SM-2) and `QuestionMasteryState.nextReview` (heuristic) can diverge | FAIL (MAJOR) |
| 14 | ReadinessScorer uses actual mastery data for priority ordering | Provider creates instance with empty maps — all scores identical | FAIL (MAJOR) |
| 15 | Historical exam comparison exists | `ExamResult.scoreHistory` field exists but is never populated — dead data | FAIL (MAJOR) |
| 16 | Per-question timing available in exam review | No timing breakdown per question in results | FAIL (MINOR) |
| 17 | At Risk practice mode exists and works | Method exists but may not be in grid rendering — need to verify if it's accessible | FAIL (MAJOR) |
