# Dry-Run Scenario: Practice Tab — Student Wants to Test Their Knowledge

## Persona

I'm a student who has just added **IB Chemistry** as a subject (I followed the steps in scenario 1). I haven't uploaded any materials yet — I just created the subject entry. Now I tap the **Practice** tab in the bottom navigation, eager to test my knowledge.

---

## Step 1: First Look at the Practice Tab — Empty State

I open the app and tap the **Practice** tab (second from the left in the bottom nav).

**What I expect:** Since I have a subject (IB Chemistry), I expect to see options to practice. Maybe a welcome message: "Start practicing IB Chemistry. Upload materials to generate practice questions." Or at least a clear indication that I need questions first.

**What I actually see:** Since I have one subject, I'm shown a `PracticeModeGrid` with 4 cards: **Quick Practice**, **Spaced Repetition**, **Topic Focus**, **Weak Areas**. Below that are **Exam Mode** and **Source Practice** cards. Further down, a **Subject Practice Card** for IB Chemistry. Everything looks ready to use.

**What I DON'T see:** Any indication that there are **zero questions** available. The Spaced Repetition card shows "No Reviews Scheduled" (which is accurate but doesn't say _why_ — the app doesn't tell me to upload materials first). The Weak Areas card is tappable. Quick Practice shows "10 random questions" as if they exist.

**Verdict (PARTIAL):** The Practice screen correctly shows subjects but doesn't proactively warn me that no questions are available. All modes appear functional until tapped.

---

## Step 2: Tapping Quick Practice — "No Questions Available"

I tap the **Quick Practice** card. Since I only have one subject, a bottom sheet (`PracticeModeSheet`) appears asking me to choose "Auto Select" for IB Chemistry. I tap it.

**What I expect:** The app starts a practice session with some questions about chemistry.

**What actually happens:** The `PracticeSessionScreen` loads and calls `_questionRepo.getBySubject(subjectId)`. Since there are no questions in the system (I never uploaded anything), the result is empty. A dialog appears: **"No Questions Available"** with the body **"No questions found for the selected subject."**

The dialog has no buttons — it's just a title and body text. I have to tap outside it to dismiss it. I'm back on the Practice screen with no further guidance.

**Verdict (FAIL):** The error dialog has no action buttons ("Upload materials to generate questions", "Go to Upload", etc.). It's a dead end. The user must independently know to go to the Upload screen.

---

## Step 3: Trying Topic Focus — Same Dead End

I tap **Topic Focus**. A `TopicSelectionSheet` bottom sheet appears with the label "No topics available" — actually, `_showTopicSelector` calls `_dataService.loadTopics()` which queries all questions for their `topic` field. Since there are zero questions, topics is empty. A SnackBar says **"No topics available"** and vanishes after a few seconds.

**Verdict (FAIL):** No guidance on how to create topics or questions.

---

## Step 4: Trying Weak Areas — Silent Failure

I tap **Weak Areas**. This calls `masteryService.getWeakTopics(studentId)`. Since I've never practiced anything, there's no mastery data. The result is empty. A SnackBar says **"No weak areas found"** — which could mean "you're a genius" rather than "you have no data yet."

**Verdict (FAIL):** Misleading message. "No weak areas found" sounds like a compliment, not a prompt to take action. Should say something like "Practice first to identify weak areas."

---

## Step 5: Uploading Content — The Hidden Question Generation Gap

I remember the Dashboard checklist mentioned "Upload Material." I go to the Upload screen and upload my IB Chemistry textbook PDF. The upload succeeds — the PDF is processed, text is extracted, and classified.

**What I expect:** After upload, I return to the Practice tab and now have questions available. The upload pipeline should generate practice questions from my textbook.

**What actually happens:** Nothing changes. The upload flow calls `processFullPipeline()` with `generateQuestions: false` (`upload_screen.dart:212`). Even if it were true, the pipeline passes `studentId: ''` and `modelId: ''` (lines 207-208), so the LLM call inside `_generateQuestions()` would fail.

**The question generation feature exists** (`ContentPipeline._generateQuestions()` at `content_pipeline.dart:307`) — the code is written, tested, and ready. But the upload screen explicitly turns it off. There is no user-facing control to enable it.

**Verdict (BLOCKER FAIL):** Uploading content does NOT create questions. The auto-generation pipeline exists in code but is disabled by the upload screen. The Practice tab remains empty forever — the only way to get questions is to attend an AI Tutor lesson.

---

## Step 6: Exam Mode — Configurable, But No Questions

I tap **Exam Mode**. Since I have one subject, it navigates to `ExamSessionScreen`. The screen shows **Exam Configuration** with duration and question count selectors. I set 15 minutes, 10 questions, and tap "Start Exam."

**What I expect:** The exam starts with 10 questions.

**What happens:** The `ExamSessionScreen._loadQuestions()` calls `_questionRepo.getBySubject(subjectId)`. Empty. A dialog: **"No questions available"** — same dead end as Step 2.

**Verdict (FAIL):** The exam configuration screen should proactively warn me before I configure everything: "No questions found for this subject. Please upload materials first."

---

## Step 7: Source Practice — Also Empty

I tap **Source Practice**, which opens `SourcePracticeSheet`. It groups questions by `sourceIds`. Since there are zero questions, the source map is empty. A SnackBar says **"No sources available"** — but I literally just uploaded a PDF source. The source exists in the system (it's stored as a `SourceModel`) but no questions are linked to it because no questions were generated.

**Verdict (FAIL):** "No sources available" is technically correct (no questions are linked to any sources) but misleading to the user who just uploaded a PDF.

---

## Step 8: The Only Way to Get Questions — Attend a Tutor Lesson

I go to the Planner, schedule a tutor lesson on "Atomic Structure," and attend it. The tutor asks me exercises during the conversation. After the lesson ends, the `TutorService._persistExercisesAsQuestions()` creates questions from the tutor's exercise interactions.

**What gets created:** `typedAnswer` questions with text like `"Tutor exercise: Atomic Structure"` and no `options` list — they have a correct answer from the markscheme but are rendered as typed-text fields.

I go back to the Practice tab. Now `_questionRepo.getBySubject()` finds these questions. I can finally practice!

**Problems:**
- These tutor-generated questions have **generic titles** ("Tutor exercise: Atomic Structure") rather than the actual question content
- They're all `typedAnswer` — no multiple choice, no variety
- The question text is the topic name, not the actual question the tutor asked
- I had to attend a full tutor lesson just to get any practice questions

**Verdict (MAJOR FAIL):** Tutor-generated questions are low-quality placeholders. The actual exercise questions the AI asked during the lesson are not captured — only a generic stub is stored.

---

## Step 9: Spaced Repetition — Finally Working

Now that I have questions, I try **Spaced Repetition**. The card shows a badge with the count of due questions. I tap it, select my subject, and the session starts with questions due for review.

This flow works correctly: questions are rendered, I answer them, get feedback, and after the session, a mistake review sheet appears if I got any wrong.

**Verdict (PASS):** Once questions exist, the spaced repetition flow works end-to-end.

---

## Step 10: Completing a Practice Session — Results and Navigation

I complete a practice session. I answered 7/10 correctly.

**What I expect:** The results screen shows: total questions, correct/incorrect breakdown, topic-by-topic analysis, and a clear path back to the Practice screen.

**What actually happens:** The `PracticeResultsScreen` shows:
- Total questions: 10
- Correct answers: 7/10
- Accuracy: 70%
- "Practice Again" button

**Problems:**
- No **topic breakdown** (unlike Exam mode which has a `topicBreakdown` section)
- No **incorrect answer review** on the results screen itself (only the mistake review bottom sheet before results)
- "Practice Again" restarts a new session but the results screen replaces the session screen in the navigator — tapping it pops back to the Practice screen
- The `PracticeSessionResult` is returned via `Navigator.pop(result)` but **nobody reads it** — the Practice screen's `_startPractice()` uses `pushNamed()` without `await`, so it never receives the result
- After returning to the Practice screen, **nothing refreshes** — the due counts are still from the pre-session state. Only a pull-to-refresh updates them

**Verdict (PARTIAL):** Results display is functional but lacks topic breakdown. Session results are lost on return to Practice screen (no data transfer). The screen must be manually refreshed.

---

## Step 11: Exiting Practice Mid-Session — Back Button Behavior

During a practice session, I press the system back button.

**What I expect:** A confirmation dialog: "Are you sure you want to exit? Your progress will be lost."

**What actually happens:** The screen immediately pops back to the Practice screen. The session is aborted. Any answers I submitted are already saved to the mastery graph (via `_masteryRecorder.recordAttempt()` in `_submitAnswer`), but the session is never auto-saved. The `_completeSession()` method (which calls `_sessionService.autoSaveSession()` and `_recordAdherence()`) is never called.

**Verdict (MAJOR FAIL):** Back button exits without warning and skips session finalization. Mastery data for individual answers is saved, but the session record and adherence tracking are lost.

---

## Step 12: Question Type Variety — Everything Is Single Choice

Now that I have questions from the pipeline (if it were enabled) or from the tutor, let me examine the variety.

**What the product vision says:** "questions should be organized, categorized, linked to sources/topics/syllabi, expanded through generated variants" — and the `QuestionType` enum defines **10 types**: singleChoice, multiChoice, typedAnswer, canvas, essay, stepByStep, mathExpression, graphDrawing, fileUpload, audioRecording.

**What actually exists:**
- Content pipeline generates only **singleChoice** (`content_pipeline.dart:345`: hardcodes `"type": "singleChoice"` in the prompt AND overrides the returned type)
- Tutor generates only **typedAnswer** with generic text
- Canvas and graphDrawing types have widgets (`CanvasDrawingWidget`) that work when a question of that type exists, but no questions of those types are ever generated
- The `question_type_localizer.dart` provides labels for all 10 types, but 8 are unused

**Verdict (MAJOR FAIL):** 8 of 10 question types are unreachable through any generation path. The canvas/math/fileUpload/audio types exist as UI widgets but are dead code.

---

## Step 13: Long-Term Practice — No Progress Feedback on Practice Screen

After practicing daily for a week, I open the Practice tab to see my progress.

**What I expect:** The Practice screen shows some indication of my activity: total questions answered, recent accuracy, streak, or at least that the spaced repetition due counts update automatically.

**What actually happens:** The Practice screen is static. It always shows the same mode grid and subject list. The only dynamic element is the spaced repetition badge count — but even that requires a manual pull-to-refresh to update after a practice session because the session result is not consumed. There is no recent activity summary, no accuracy trend, no "You practiced 30 questions yesterday" message.

The SessionSummaryCard exists on the FocusTimerScreen and the Dashboard has progress charts, but the Practice tab itself has zero progress information.

**Verdict (FAIL):** The Practice tab has no progress indicators. Users must navigate to the Dashboard to see their practice history.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Practice tab guides "no questions" user | Shows full mode grid with no warning about missing questions | FAIL (MAJOR) |
| "No Questions Available" dialog offers next steps | Dialog has no action buttons | FAIL (MAJOR) |
| Uploading content auto-generates questions | `generateQuestions: false` in UploadScreen | FAIL (BLOCKER) |
| Upload pipeline passes proper studentId/modelId | Both are empty strings | FAIL (BLOCKER) |
| Topic Focus handles empty state helpfully | SnackBar "No topics available" — no guidance | FAIL (MINOR) |
| Weak Areas message distinguishes "no data" from "strong" | Shows "No weak areas found" — misleading | FAIL (MINOR) |
| Tutor creates genuine questions from exercises | Generic stub "Tutor exercise: topic" — not the actual question | FAIL (MAJOR) |
| All 10 question types are reachable | Only singleChoice (pipeline) and typedAnswer (tutor) exist | FAIL (MAJOR) |
| Exam mode warns about empty question bank before configuring | Lets user configure, then fails with dialog | FAIL (MAJOR) |
| Session results feed back to Practice screen | `PracticeSessionResult` is pushed but never consumed | FAIL (MAJOR) |
| Back button confirms exit during practice | Immediate pop, no confirmation, session not saved | FAIL (MAJOR) |
| Practice tab shows recent activity/progress | Static — zero progress indicators | FAIL (MAJOR) |
| Source practice works after uploading a PDF | "No sources available" — questions never linked to sources | FAIL (BLOCKER) |
| Spaced repetition works with existing questions | Full flow works when questions exist | PASS |
| Results show topic breakdown | Regular practice: no topic breakdown (Exam mode: has it) | FAIL (MINOR) |
| Practice screen refreshes after session | Manual pull-to-refresh required | FAIL (MINOR) |
