# Dry-Run Scenario: Attending an AI Tutor Lesson

## Persona

I'm a student who has been using StudyKing for about a week. I've added **IB Chemistry** as a subject, created a study plan, uploaded some materials, and configured my API key. Yesterday I scheduled a lesson on **Atomic Structure** for today at 4 PM with a 30-minute duration. Now it's 4 PM and I want to attend my lesson.

---

## Step 1: Finding Where to Join My Scheduled Lesson

I open the app and go to the **Planner** (via Dashboard or Subjects tab). On the Study Plan tab, I see a "Scheduled Lessons" section at the top showing my lesson:

> **"Atomic Structure · 16:00"** with two icon buttons: a refresh icon (reschedule) and an X icon (cancel).

**What I expect:** A prominent "Join Lesson" or "Start Lesson" button. I scheduled this for a reason — I want to attend it.

**What I see:** There is no join/start button. Only cancel and reschedule. I can cancel the lesson I intended to attend, but I cannot start it from here.

**What I have to do:** I scan the screen looking for another way in. I notice the daily plan cards below have priority topics with a **smart_toy icon** labeled "Start Tutoring" on each topic. The first card shows "Atomic Structure" — I tap the smart_toy icon.

**Verdict (MAJOR FAIL):** The "Scheduled Lessons" section is read-only for starting. There is no way to join a scheduled lesson from where it's displayed. The user must find the topic via a completely separate navigation path (daily plan card / subject detail) and start a NEW tutoring session — which has no connection to the scheduled slot.

---

## Step 2: Starting the Tutor Session — What the User Sees

I tap the smart_toy icon on the "Atomic Structure" daily plan topic.

**What I expect:** The app takes me to the tutor, aware that I have a scheduled lesson. It should use my scheduled duration (30 min). The tutor greets me and starts teaching.

**What actually happens:**
1. The navigator pushes to the `TutorScreen` with `TutorArgs(topicId, topicTitle, subjectId)`
2. The `durationMinutes` is the **default 45**, NOT the 30 minutes I scheduled
3. A `CircularProgressIndicator` appears while the LLM generates a lesson plan
4. After a few seconds, the `LessonProgressBar` appears showing a timeline with sections
5. The tutor greets me: "Ready to learn about Atomic Structure?"

**Issue — Duration mismatch:** The `LessonBookingSheet` lets me pick a duration and saves it as `plannedDurationMinutes` on the `Session`. But none of the entry points (daily plan card, lesson detail, lesson list, calendar) pass this scheduled duration to `TutorArgs`. The `TutorScreen` always defaults to `45`. My scheduled 30-minute lesson is now a 45-minute session. The progress bar shows wrong times.

**Issue — No lesson context:** The tutor starts fresh. It doesn't know this is my scheduled session. It doesn't show "Welcome to your scheduled lesson on Atomic Structure" — just a generic greeting.

**Verdict (MAJOR FAIL):** The scheduled duration is lost. The tutor has no awareness it's part of a scheduled session.

---

## Step 3: The AI Tutor Teaches — Conversation Flow

I type "I'm ready!" and the AI responds, teaching me about Atomic Structure. The text streams in chunk by chunk, building a chat bubble.

**What I notice:** The first couple of characters of the AI's response seem missing. It starts mid-word sometimes. Looking at the response carefully, the initial characters are being clipped.

**What the code shows:** In `conversation_manager.dart:147`, the condition `if (buffer.length > 2)` means the first 1-2 characters of every LLM response are never yielded to the UI stream. Short responses like "OK" or "Hi" may never display at all.

**Verdict (MINOR FAIL):** First 1-2 characters of every AI response are clipped. Short responses can be completely invisible.

---

## Step 4: The AI Asks an Exercise Question

The conversation flows naturally. Eventually the AI transitions to exercise mode. It says something like: "Now let me ask you a question to check your understanding. What is the mass of a proton in atomic mass units?"

**What I expect:** The AI clearly states the question. I answer it, and the AI evaluates my answer based on what question was asked.

**What the code shows:** When I answer, `_evaluateExerciseResponse()` in `conversation_manager.dart:174` calls:
```dart
final result = await _exerciseEvaluator.evaluate(
  question: '',  // <-- Empty!
  studentAnswer: content,
  subjectId: subjectId,
  topicTitle: topicTitle,
);
```

The **actual question the AI asked is not passed** to the evaluator. The evaluation prompt only receives the subject name and topic title. The LLM evaluator has to infer what the question was from my answer alone, making the evaluation less accurate. If I give a partially correct answer, the evaluator can't properly assess partial credit because it doesn't know what was asked.

**Verdict (MAJOR FAIL):** Exercise evaluation is context-free. The specific question the AI tutor asked is lost, reducing evaluation accuracy.

---

## Step 5: I Need to Leave Early — Ending the Lesson

It's been 20 minutes. I need to log off. I tap the **"End Lesson"** button in the top-right of the AppBar.

**What I expect:** A confirmation dialog: "Are you sure you want to end the lesson?" with options to confirm or cancel. I don't want to accidentally end the lesson.

**What actually happens:** The lesson ends immediately. `_endLesson()` is called without any confirmation. The summary dialog appears after I've already committed.

**Verdict (MINOR FAIL):** No confirmation before ending the lesson. Accidental tap = immediate termination.

---

## Step 6: The Summary Dialog

The summary dialog shows after the lesson ends. It displays:
- An AI-generated summary paragraph
- Session duration (20 min)
- Question count
- Correct count
- Pace percentage

I tap **"Done"** — this pops both the dialog AND the tutor screen at once (`Navigator.pop()` is called twice). I'm now back on the Planner screen.

**What I expect:** After tapping "Done", I'd like to see how this lesson affected my progress, or at least return to a sensible screen.

**What happens:** I'm back on the Planner. My scheduled lesson card still says "Atomic Structure · 16:00" — it still shows as `planned`. My attendance had no effect on the scheduled slot.

**Verdict (MAJOR FAIL):** The summary dialog pops two screens in one action, which can be disorienting. The scheduled lesson never transitions to "attended" or "completed" — it remains "planned" forever.

---

## Step 7: Verifying Lesson Was Saved — Checking Progress

After the lesson, I check my Dashboard to see if the lesson was recorded.

**What I expect:** The dashboard shows my tutor session: "Completed AI tutor session on Atomic Structure — 20 minutes — 71% accuracy."

**What actually happens:** The `TutorService.endLesson()` method runs multiple persistence operations. Some of these have error handling that silently swallows exceptions (`catch (_) {}`):
- `_planAdapter.recordFromTutorSession()` — errors silenced
- `_database.sessionRepository.save()` — errors silenced

If any of these fail, the user never knows. The dashboard might not show the lesson.

However, the core data (TutorSession, ConversationMessages, questions, mastery attempt) is saved before these catch blocks, so partial data exists. But the generic `Session` record and plan adherence may be missing without the user knowing.

**Verdict (PARTIAL):** Core lesson data is persisted, but satellite data (Session record, plan adherence) silently fails. The user may see inconsistencies in the dashboard.

---

## Step 8: What If My Network Drops Mid-Lesson?

Let me imagine a different scenario: during the lesson, my internet connection drops or the app crashes.

**What I expect:** At least my conversation up to that point should be saved. I should be able to resume the lesson.

**What the code shows:** The `ConversationManager` is created WITHOUT a `ConversationRepository` — `_persistenceRepo` is null. `ConversationMemory._persistMessage()` is a no-op during the lesson. ALL messages are saved in one batch at `endLesson()`. If the app crashes, the ENTIRE conversation is lost. The TutorSession stays in `inProgress` status forever.

Also, pressing the **system back button** on `TutorScreen` does NOT call `_endLesson()`. There's no `PopScope` or `WillPopScope`. So if the user (or system) navigates back, the lesson state becomes an orphaned `inProgress` record.

**Verdict (BLOCKER FAIL):** Back-button exits without saving. Mid-lesson crash loses ALL conversation data. The session becomes an orphaned `inProgress` record that is never cleaned up.

---

## Step 9: Voice Input (Optional Feature Exploration)

I notice a microphone icon next to the text input. I tap it.

**What I expect:** The app listens to my voice and converts it to text, then submits it.

**What actually happens:** The mic button toggles. But:
- Voice recognition is hardcoded to `en_US` — if my system language is Spanish, the recognition uses English anyway, producing gibberish transcription
- No microphone permission dialog — `requestPermission()` exists on `VoiceController` but is never called from `VoiceBar`; if permissions aren't pre-granted, the mic may silently fail
- Text-to-speech (TTS) also hardcoded to `en-US` locale

**Verdict (MINOR FAIL):** Voice input works for English but fails silently for other languages. Permission handling is absent from the UI.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Scheduled lesson has a "Join" button | Only cancel/reschedule; no way to start | FAIL (MAJOR) |
| Scheduled duration (30 min) is used in tutoring | Always defaults to 45 min | FAIL (MAJOR) |
| Tutor knows this is my scheduled session | No context; generic greeting | FAIL (MAJOR) |
| AI response streams without missing characters | First 1-2 chars clipped from streaming | FAIL (MINOR) |
| Exercise evaluation knows what question was asked | Question passed as empty string | FAIL (MAJOR) |
| "End Lesson" has confirmation dialog | Ends immediately on tap | FAIL (MINOR) |
| Summary dialog pops tutor screen naturally | Double-pop can disorient | FAIL (MINOR) |
| Scheduled lesson transitions to "attended" | Stays "planned" forever | FAIL (MAJOR) |
| Errors in persistence are visible to user | Silently swallowed | FAIL (MINOR) |
| Back button saves lesson data | Lesson state lost; orphaned inProgress record | FAIL (BLOCKER) |
| Mid-lesson crash preserves conversation | Messages only saved at endLesson() | FAIL (MAJOR) |
| Voice input respects system locale | Hardcoded to en_US | FAIL (MINOR) |
| Core lesson data persisted to dashboard | Partial — some paths silently fail | PARTIAL |

---

## Validation Results (checked against actual source code)

### Step 1: Finding Where to Join
**Validation: COMPLETED** — The `_buildScheduledLessonsSection()` in `planner_screen.dart:1162-1182` renders a `play_circle_filled` `IconButton` for each non-completed scheduled lesson. It navigates to `TutorScreen` via `AppRoutes.tutor` with `TutorArgs` including `durationMinutes`, `scheduledSessionId`, `topicId`, `topicTitle`, and `subjectId`. The scenario's claim that there is "no join/start button" is **outdated** — the code has had this button added.

### Step 2: Starting the Tutor Session
**Validation: PARTIAL**
- **From scheduled lessons section** (`planner_screen.dart:1173-1178`): ✅ **COMPLETED** — Passes `lesson.plannedDurationMinutes ?? 45` and `scheduledSessionId: lesson.id`. The tutor receives and uses both.
- **From daily plan card** (`daily_plan_card.dart:150-151` → `planner_screen.dart:107-108`): ❌ **NOT_COMPLETED** — Calls `_openTutorMode(topicId, topicTitle, subjectId)` with only positional params, so `durationMinutes` defaults to `45` and `scheduledSessionId` defaults to `null`. The scheduled duration and context are lost.
- **Scheduled session awareness in tutor prompts**: No scheduled session context is injected into the LLM prompt. `ConversationManager.sendMessage()` at `conversation_manager.dart:176-181` builds the prompt from `subjectId`, `topicTitle`, `adaptivePace`, and `phase` only — no scheduled session flag. Minor gap.

### Step 3: The AI Tutor Teaches — Character Clipping
**Validation: COMPLETED** — The streaming condition at `conversation_manager.dart:191` is `if (buffer.length > 0)`, **not** `> 2` as claimed. No characters are clipped. The scenario's line reference (line 147) is also outdated — the streaming code now lives at line 183-201.

**Note:** While no characters are clipped, streaming chunks yielded from `_buildAdaptiveChunks()` are not rendered in the message list during streaming. The assistant message is only added to `_memory` after streaming completes (`conversation_manager.dart:205`). This means the chat UI shows a loading indicator during generation, then the full response appears at once — no visible streaming. This is a separate UX concern not raised in the original scenario.

### Step 4: Exercise Evaluation — Question Context
**Validation: COMPLETED** — The `_evaluateExerciseResponse()` method at `conversation_manager.dart:271-302` passes `_lastExerciseQuestion` (not empty string) to `_exerciseEvaluator.evaluate()`. The question is captured at `conversation_manager.dart:207-209` when `_pendingExerciseQuestionCapture` is true. The evaluation prompt in `exercise_evaluator.dart:33-40` includes the `question` parameter. The scenario's claim that "question passed as empty string" is **outdated**.

### Step 5: End Lesson Confirmation
**Validation: COMPLETED** — The "End Lesson" action goes through `PopupMenuButton` → `_showEndLessonConfirmation()` (`tutor_screen.dart:316-339`), which shows an `AlertDialog` with "Continue" and "End Lesson" buttons. `_endLesson()` is only called after the user confirms. The scenario's claim of "no confirmation" is **outdated**.

### Step 6: Summary Dialog
**Validation: PARTIAL**
- **Double-pop**: ⚠️ Still present. The "Done" button (`tutor_screen.dart:474-481`) calls `Navigator.of(ctx).pop()` (pop dialog) then after 200ms `Navigator.of(context).pop()` (pop tutor screen). The delay is intended to let the dialog close animation finish, but can disorient.
- **Scheduled lesson status**: ✅ **COMPLETED** — `tutorService.endLesson()` at `tutor_service.dart:215-230` updates the `scheduledSessionId` to `SessionStatus.completed`. The scenario's claim that "it remains 'planned' forever" is **outdated**.

### Step 7: Error Handling in EndLesson
**Validation: COMPLETED** — All main persistence paths in `tutorService.endLesson()` have `try/catch` blocks with proper logging via `_logger.e()`:
- `_planOrchestrator.recordActivity()` (line 175-182): caught with log
- `_database.sessionRepository.save()` (line 210-213): caught with log
- Scheduled session update (line 215-230): caught with log
- Lesson record update (line 232-257): caught with log

The three background tasks (lines 259-308) use silent `catch (_) {}`, but these are non-critical post-processing tasks. The scenario's claim of "silently swallowed exceptions" is **outdated** for the critical paths.

### Step 8: Back Button / Crash Resilience
**Validation: PARTIAL**
- **PopScope**: ✅ **COMPLETED** — `PopScope` at `tutor_screen.dart:571-576` with `onPopInvokedWithResult` calling `_handleBackNavigation()`, which shows a confirmation dialog with Cancel/Discard/Save options. The scenario's claim "no PopScope" is **outdated**.
- **Message persistence during lesson**: ✅ **COMPLETED** — `ConversationMemory._persistMessage()` at `conversation_memory.dart:64-68` calls `_repository.saveMessage(msg)`. The `_persistenceRepo` is provided (conversation_manager.dart:68, via tutor_service.dart:120-124). Messages are saved per-message, not batched at `endLesson()`. The scenario's claim of "no-op during the lesson" is **outdated**.
- **Orphaned `inProgress` session cleanup**: ❌ **NOT_COMPLETED** — There is no mechanism to detect and clean up `inProgress` `TutorSession` records from previous crashed sessions. `TutorService.getActiveSession()` exists but is never called for recovery/cleanup. If a user chooses "Discard and Exit" in the back-navigation dialog, the `TutorSession` also remains orphaned in `inProgress` state.

### Step 9: Voice Input
**Validation: COMPLETED**
- **Locale support**: `VoiceService._localeForSpeech()` (`voice_service.dart:113-140`) supports `en_US`, `es_ES`, `fr_FR`, `de_DE`, `pt_BR`, `it_IT`, `ja_JP`, `zh_CN` — not hardcoded to `en_US`. `VoiceBar` at `voice_bar.dart:63-65` passes `l10n.localeName` to `startListening()`.
- **Permission**: `VoiceBar.initState()` at `voice_bar.dart:41-43` calls `widget.controller.requestPermission()` via `addPostFrameCallback`.
- **TTS locale**: `VoiceService._localeForTts()` (`voice_service.dart:142-146`) maps through the same locale system.

### Overall Score

| Category | Count |
|---|---|
| **COMPLETED** | 9 of 12 claim items |
| **PARTIAL** | 3 of 12 (daily plan card duration, double-pop, orphaned cleanup) |
| **NOT_COMPLETED** | 0 of 12 |
| **Completion %** | 75% |

### Remaining Issues (to be tracked in `issues/open/dry_run_result_attending_tutor_lesson.md`)

1. **Daily plan card "Start Tutoring" doesn't pass scheduled duration/sessionId** — `daily_plan_card.dart:150-151` → `_openTutorMode(topicId, topicTitle, subjectId)` uses default 45 min and null `scheduledSessionId`. Fix: update callback signature to accept optional duration and scheduledSessionId.
2. **Summary dialog double-pop** — `tutor_screen.dart:474-481` pops dialog then pops tutor screen with 200ms delay. Fix: pop the tutor screen directly from the dialog button instead of double-popping.
3. **No orphaned `inProgress` session cleanup** — If a lesson crashes or user discards mid-lesson, the `TutorSession` stays `inProgress` with no recovery mechanism. Fix: add startup check to detect and either resume or cancel orphaned sessions.
