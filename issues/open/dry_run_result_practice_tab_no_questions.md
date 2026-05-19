# Issue: Remaining PARTIAL Items from Practice Tab Dry-Run

Source: `dry-run-test/scenario_practice_tab_no_questions.md` (deleted — >80% resolved)

---

## Issue 1: Tutor-Generated Questions Are Low Quality (`tutor_service.dart:383-408`)

**Verdict:** PARTIAL (originally FAIL MAJOR)

**What's fixed:** The upload pipeline now generates questions (Step 5 fixed), so the tutor is no longer the only path to get questions.

**What remains:**

| Problem | Location | Fix Needed |
|---|---|---|
| Hardcoded `QuestionType.typedAnswer` | `tutor_service.dart:397` | Use the actual exercise type (multiple choice, typed answer, etc.) from the tutor manager's exercise data. Generate varied question types. |
| No `markscheme` set (null) | `tutor_service.dart:394-405` | Set `markscheme` with `correctAnswer` from the exercise's evaluation. Currently only `explanation` is saved. |
| Generic fallback text | `tutor_service.dart:391-393` | `capturedExerciseQuestion` may be empty; fallback `'Tutor exercise: ${session.topicTitle}'` is uninformative. Ensure the actual exercise question text is always captured. |
| No `options` list | `tutor_service.dart:394-405` | For multi-choice questions, populate `options` from the exercise's answer choices so the question can be rendered as a choice widget. |

**Priority:** Medium (upload pipeline provides primary question source; tutor is supplementary)

---

## Issue 2: 5 of 10 Question Types Unreachable (`content_pipeline.dart:397-403`)

**Verdict:** PARTIAL (originally FAIL MAJOR)

**What's fixed:** The pipeline now generates 5 types (singleChoice, multiChoice, typedAnswer, mathExpression, essay) instead of just 1.

**What remains:**

| Question Type | Reachable? | Problem |
|---|---|---|
| `canvas` | NO | Not in `_defaultAllowedTypes` (`content_pipeline.dart:397-403`). No generator produces it. Widget exists (`CanvasDrawingWidget`) but is dead code. |
| `graphDrawing` | NO | Same — not in default allowed types. |
| `stepByStep` | NO | Not in default allowed types. |
| `fileUpload` | NO | Not in default allowed types. No upload widget for practice answers. |
| `audioRecording` | NO | Not in default allowed types. No audio recording widget in practice flow. |

**Two approaches to fix:**
1. **Pipeline expansion** — Add `canvas`, `graphDrawing`, `stepByStep` to `_defaultAllowedTypes` and update the LLM prompt to generate them. The validation logic in `_isValidGeneratedQuestion()` (lines 472-516) already has empty switch cases for these types, so they pass validation with minimal checks.
2. **Tutor expansion** — Update `tutor_service._persistExercisesAsQuestions()` to detect the exercise type and create matching question types (not just `typedAnswer`).

Also need to verify that the rendering widgets for these types work correctly in the practice session flow.

**Priority:** Low (5 types cover most practice needs; canvas/audio/graph are specialized features)

---

## Issue 3: Practice Tab Has Minimal Progress Feedback (`practice_screen.dart:626-639`)

**Verdict:** PARTIAL (originally FAIL MAJOR)

**What's fixed:** Summary row now shows "Questions Today", "Due for Review", "Subjects" counters (line 626-639). Counts update after session completes via `_onSessionResult()`.

**What remains:**

| Missing Feature | Expected Behavior |
|---|---|
| Accuracy trend | Show recent accuracy across sessions (e.g., "85% accuracy this week") |
| Practice streak | Consecutive days with practice activity |
| Activity history | "You answered 30 questions yesterday" / "45 questions this week" |
| Topic mastery breakdown | Show weak/medium/strong topic counts at a glance |
| Session history summary | List of recent practice sessions with score and date |

**Where to add:** The summary row in `_buildSummaryRow()` (line 626) is the natural place. Alternatively, add a dedicated "Activity" section between the summary row and the practice modes.

**Priority:** Low (functional — counters work; richer display is UI polish)

---

## Overall Tracking

| Issue | Priority | Status |
|---|---|---|
| 1. Tutor question quality | Medium | OPEN |
| 2. Question type variety | Low | OPEN |
| 3. Progress feedback on Practice tab | Low | OPEN |
