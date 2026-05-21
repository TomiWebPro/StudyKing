# Dry-Run Scenario: The AI Tutor Lesson Experience — From Scheduling to Post-Lesson Review

## Persona

I'm a student who has been using StudyKing for about a week. I've created my "IB Chemistry" subject (with auto-seeded topics), uploaded a textbook (content processed), practiced a few questions, and configured my OpenRouter API key. Now I want to attend my **first AI tutor lesson**. I've never used an AI tutor before. I don't know what to expect — will it be like a video call? A chat? A slideshow?

I expect the app to:
1. Make it obvious how to start a tutor lesson — I shouldn't hunt for it
2. Explain what's happening during lesson initialization (generating lesson plan, checking prerequisites)
3. Show me a clear, structured lesson interface once the tutor starts
4. Let me interact naturally — ask questions, get explanations, do exercises
5. Handle voice input and voice output if I want to use them
6. Handle errors gracefully (network drop, API timeout, model unavailability)
7. Let me end the lesson when I want, and show me a meaningful summary afterward
8. Not silently create side effects I didn't agree to (background actions, data persistence)
9. Resume an interrupted session if I accidentally close the app
10. Let me find and review my past lessons

---

## Step 1: Finding Where to Start a Tutor Lesson

I've completed my setup and I want my first tutoring session. I look around the app for a "Start Tutoring" or "AI Tutor" button.

**What I expect:** A prominent "Start AI Tutor" action on the Dashboard (my home screen) or a dedicated tutor tab in the bottom navigation. It should be the most obvious action — after all, AI tutoring is StudyKing's core feature.

**What actually happens:**

The bottom navigation has 6 tabs: Dashboard, Subjects, Practice, Mentor, Focus Mode, Settings. **There is no "Tutor" or "Teaching" tab.** I scan each screen:

- **Dashboard** — Shows plan adherence, mastery overview, weak areas, question bank card. No "Start Tutoring" action on the main Dashboard. There IS a "Schedule AI Tutor" in the initial setup checklist (`empty_dashboard_checklist.dart:53`), but once the checklist is completed/hidden, the only way to start tutoring is through:
  - Planner screen (tap the scheduled lesson card or daily plan card)
  - Lesson List screen (via a button)
  - Lesson Detail screen (via a button)

- **Planner → Study Plan tab** — I see my study plan cards. Each card has a "Start Tutoring" icon button. The Subjects tab has the daily plan grid. This works but requires navigating to the Planner first.

- **Practice tab** — No tutor entry at all. Six practice mode cards with no mention of AI tutoring.

- **Mentor tab** — Can suggest scheduling a lesson but has no direct "Start Now" button.

**Significant gap:** There's no persistent "AI Tutor" entry point from the Dashboard or bottom nav. The primary action the app is built for (teaching) requires 2+ navigational steps from the home screen. After the setup checklist disappears, new users may not know where tutoring lives.

**Verdict (MAJOR FAIL):** No persistent "Start AI Tutor" action on Dashboard or bottom navigation. Tutoring is accessible only through nested screens (Planner → daily plan cards, Lessons list, Lesson detail). A user who completes the setup checklist loses their one-click tutoring entry point.

---

## Step 2: Starting a Lesson from the Planner — Pre-Lesson Checks

I navigate to the Planner → Study Plan tab. I tap the "Start Tutoring" icon on my first daily plan card. The app begins initialization.

**What I expect:** A loading screen that explains what's happening: "Checking prerequisites...", "Generating lesson plan...", "Preparing your AI tutor...". Clear progress so I know the app hasn't frozen.

**What actually happens:**

1. **Prerequisite check** (tutor_screen.dart:99-118): The `PrerequisiteCheckService.checkPrerequisites()` runs. If prerequisites are unmet, a dialog appears listing the topics I need to master first.

2. **The dialog has a critical UX bug:** The dialog shows two buttons:
   - "Continue Anyway" → navigates back (returns `false`)
   - "Practice Prerequisites" → continues to the lesson (returns `true`)
   
   This is **reversed** from what a user expects. "Practice Prerequisites" should navigate to practice mode for those topics. Instead it starts the current lesson. "Continue Anyway" (which sounds like it would ignore prerequisites and start the lesson) navigates away. This is actively misleading (`prerequisite_check_service.dart:107-111`, `tutor_screen.dart:110-118`).

3. **Lesson plan generation** (conversation_manager.dart:116-158): An LLM call generates the lesson plan. During this time:
   - The screen is black/empty with a `CircularProgressIndicator` at `tutor_screen.dart:156`
   - The only visible text is from the l10n string `initializingTutor` (something like "Preparing your AI tutor...")
   - **No sub-stage progress** — the user sees one spinner for the entire duration (prerequisite check + session creation + LLM plan generation + block parsing). On a slow model, this can take 10-30 seconds with zero granularity.
   - **No estimated wait time** — the user doesn't know if it'll be 5 seconds or 30 seconds.

4. **If the LLM fails to generate a lesson plan** (line 132): `buildDefaultPlan()` creates a hardcoded 3-section plan (intro 5min, main content, practice 10min). **No user-facing notification** that the AI-generated plan failed and a generic one was substituted. The user sees the same "Preparing your AI tutor..." spinner and never knows the plan was downgraded.

5. **If initialization fails entirely** (tutor_screen.dart:167): An error card appears with `l10n.tutorInitFailed('')` — **the error message parameter is empty** in the first failure case. The specific error is silently lost. The card offers "Go to Settings" and "Retry" buttons but no explanation of what went wrong.

**Verdict (MAJOR FAIL — multiple sub-issues):**
- (A) Button semantics reversed in prerequisite dialog: "Practice Prerequisites" starts the lesson, "Continue Anyway" navigates back.
- (B) Initialization has no sub-stage progress — single spinner for potentially 30+ seconds.
- (C) Silent fallback to generic plan when LLM fails — user never knows.
- (D) Init error card has empty error description on first failure path.

---

## Step 3: The Lesson Interface — First Impression

The spinner disappears. I see the tutor lesson interface for the first time.

**What I expect:** A welcoming interface that clearly identifies this as a tutoring session. The tutor introduces itself. I see the topic, the lesson goals, and some indicator of the lesson structure (sections, duration, what I'll learn).

**What I actually see:**

The `TutorScreen` renders with:
- **Top app bar**: topic title, elapsed/remaining timer, "End Lesson" overflow menu
- **Progress bar** (`LessonProgressBar`): Shows elapsed/remaining time, a section timeline (colored segments for each section type: explanation, exercise, review, summary)
- **Main area**: Chat message list (scrollable)
- **Bottom bar**: Text input with send button, mic button, image/camera attachment button, canvas button
- **Slides toggle button**: Switches between chat view and slides view

**The first message** (sent by `_sendInitialGreeting()`, tutor_screen.dart:172): A system-generated greeting like "Ready to learn about [Topic]?" or similar. The `ConversationPhase` is `greeting`.

**Issues I notice immediately:**

1. **No lesson plan preview:** The lesson goals, checkpoints, and estimated difficulty from the `LessonPlan` model are **never shown to the user**. The `LessonPlan.goals` (List<String>) is parsed by the LLM but only the `LessonProgressBar` renders the section timeline. The educational goals — why I'm taking this lesson, what I'll achieve — are invisible. I'm greeted by the tutor but I don't know what we're covering or what the learning objectives are.

2. **The section timeline is cryptic:** The `LessonProgressBar` shows colored segments for each section type, but there's no tooltip or label explaining what "blue = explanation" or "green = exercise" means. A new user sees a colored progress bar with no legend.

3. **"End Lesson" is in the overflow menu** (three dots, top-right). For a first-time user, the most critical action (ending the session) is hidden. The back button intercept works (`PopScope`), but the explicit "End Lesson" option is not prominent.

4. **Voice output is off by default** (tutor_screen.dart:72: `_voiceOutputEnabled = false`). The TTS toggle icon is small and in the app bar. A user who wants voice interaction must discover and enable it.

**Verdict (MAJOR FAIL):** Lesson goals and learning objectives from the lesson plan are never shown to the user. The section timeline has no legend explaining its colors. "End Lesson" is hidden in an overflow menu.

---

## Step 4: The Conversation — Teaching, Exercises, and Feedback

The tutor sends its greeting. The phase transitions to `teaching`. I start interacting.

**What I expect:** A natural conversation where the tutor teaches the topic, I can ask follow-up questions, the tutor assigns exercises, evaluates my answers, and provides feedback. The phase transitions should feel smooth and natural.

**What actually happens (based on code analysis):**

**4a. Phase transitions** (conversation_manager.dart:165-203):
- `greeting → teaching`: On my first message
- `teaching → exercise`: When I say keywords like "exercise", "practice", "quiz" (detected by `_detectExerciseRequest()`)
- `exercise → feedback`: After evaluation
- `feedback → teaching`: If correct; `feedback → adaptiveReview`: If 2+ consecutive incorrect
- `adaptiveReview → teaching`: If I say I understand (keyword match) or after 3 exchanges maximum

**4b. Exercise detection** (conversation_manager.dart:365-385):
- English keywords: `['exercise', 'practice', 'quiz']`
- Spanish keywords: `['ejercicio', 'práctica', 'practica']`
- **Only supports `en` and `es`** — for all other locales, the English keywords are used, which may not match what a French/German/etc. user types
- Keyword matching is case-insensitive but **not language-aware** — a French user typing "exercice" won't trigger detection

**4c. Exercise evaluation** (exercise_evaluator.dart):
- After the student submits an exercise answer, the LLM evaluates it
- Returns a score (0.0-1.0) and feedback
- On LLM failure: **silently returns score 0.5** (neutral) — the student never knows the evaluation failed
- Evaluation result is shown as a `ChatBubble` event with score and progress bar

**4d. Adaptive pacing** (conversation_manager.dart:300-320):
- Pace is adjusted by 0.15 increments based on exercise performance
- Chunk sizes: 10 chars (fast), 5 (normal), 3 (slow)
- Pace value is 0.5-1.5 range
- Pace is shown in the summary dialog but **never visible during the lesson** — I don't know if the tutor is speeding up or slowing down for me

**4e. Streaming responses** (conversation_manager.dart:221-285):
- The AI's response streams in as typing animation via `_buildAdaptiveChunks()`
- **The entire message must complete before exercise detection runs** — there's a subtle bug at line 193-203 where `_detectExerciseRequest()` is called on the `completeMessage`, but if the phase transition was already triggered by keywords in the user message (lines 165-170), the LLM response is treated as the exercise, not as teaching content. This means the LLM's teaching explanation is skipped for that turn.

**Issues:**

1. **Exercise keyword detection is not localized** for most languages. Only English and Spanish keywords are supported. French, German, Portuguese, Japanese, etc. users must use English words to trigger exercises.

2. **`_adaptiveReviewExchanges` counter is not reset** when scoring above threshold during adaptive review (line 341-343). The counter continues incrementing even after the student demonstrates understanding. This can cause premature exit from adaptive review (max 3 exchanges, even if the student needs more practice on subsequent topics).

3. **Exercise evaluation failures are silent** — the student sees score 0.5 with no indication the AI evaluator failed.

4. **Phase transitions can skip the teaching explanation**: If the user's message contains exercise keywords, the code transitions to `exercise` phase before the LLM's teaching response is even streamed. The LLM's response (which was going to be teaching content) gets labeled as exercise content, and its educational value is lost.

**Verdict (MAJOR FAIL — multiple sub-issues):**
- (A) Exercise detection keywords only localized for `en` and `es`.
- (B) `_adaptiveReviewExchanges` counter not reset on correct answer during adaptive review.
- (C) Exercise evaluation silently fails (returns 0.5 with no user notification).
- (D) Phase transitions can preempt and discard the LLM's teaching response.

---

## Step 5: Using Voice During the Lesson

I want to speak to the tutor instead of typing. The bottom bar shows a microphone icon.

**What I expect:** I tap the mic, speak, my words get transcribed and sent as a message. The tutor's response is read aloud to me. Voice works seamlessly without complex setup.

**What actually happens:**

**5a. Voice input** (voice_bar.dart):
1. I tap the mic button
2. Permission dialog appears (first time) — "Microphone permission needed"
3. After granting, the mic toggles to listening state with waveform animation
4. I speak. My words appear as live transcription.
5. I tap the stop button. A 2-second review window shows the transcription with a cancel option.
6. If I don't cancel, the text auto-submits as a message.

**This workflow is well-designed.** The review overlay prevents accidental sends.

**But there are issues:**

1. **Voice input is not available on web**: `VoiceService._init()` (voice_service.dart:33) returns early on `kIsWeb`. The mic button is still visible on web but tapping it... what happens? The `_showPermissionDeniedDialog()` would show "Speech recognition not available on this platform" — but the button should probably be hidden on web.

2. **Locale mapping is fragile**: `_localeForSpeech()` (voice_service.dart:139-147) maps language codes to locale strings (`es` → `es_ES`). If a user has a locale not in the mapping (e.g., `ko`, `ar`, `hi`), it falls back to `en_US`. The user's language setting is ignored for voice input.

3. **No push-to-talk mode**: The mic is toggle-only (tap to start, tap to stop). No press-and-hold mode for brief utterances.

**5b. Voice output (TTS)**: The speaker icon toggle in the app bar is off by default. I tap it to enable. Now the tutor's responses are spoken aloud.

**Wait, but there's a timing issue:** The `_speakResponse()` method (conversation_manager.dart:250) is called at the END of `sendMessage()` (line 285) — after the full response has streamed into the UI. The TTS starts speaking only after the entire message is displayed. This creates a disjointed experience: the text appears quickly (streamed), then after a delay the TTS starts. The user reads along faster than the TTS speaks, losing the audio benefit.

**5c. Per-message read-aloud**: The `ChatBubble` has a speaker icon that calls `onSpeak` (tutor_screen.dart:1051). This lets me re-read any previous tutor message. This is good for review.

**5d. Voice during exercise**: When the tutor asks an exercise question, I can use voice to answer. The answer is transcribed and sent as text. The LLM evaluates it. This works, but the evaluation is text-based — the app doesn't attempt to evaluate the tone, hesitation, or confidence in my voice.

**5e. Voice bar on desktop/web**: The `VoiceBar` widget is present on all platforms but the `VoiceService` will silently fail on web. There's no platform check in the UI to hide or disable the mic button on web.

**Verdict (PARTIAL — multiple issues):**
- (A) Mic button visible on web but non-functional (no platform check in UI). (MINOR)
- (B) TTS starts only after full response is displayed, not during streaming — disjointed audio experience. (MAJOR)
- (C) Locale mapping for STT is incomplete — unsupported locales fall back to en_US silently. (MINOR)
- (D) Voice input well-designed with review overlay. (PASS)
- (E) Per-message read-aloud via ChatBubble speaker icon. (PASS)

---

## Step 6: Error During the Lesson — Network Drop

Mid-lesson, my internet connection drops briefly. The API call times out.

**What I expect:** A clear error message: "Connection lost. Your lesson is paused. Tap Retry to continue when you're back online." I should NOT lose my lesson progress. The conversation history should be preserved.

**What actually happens** (tutor_screen.dart:219-250):

1. `_sendText()` catches the timeout/socket exception from `_manager!.sendMessage()`
2. A retry banner appears at the top of the chat with:
   - Error icon
   - Provider-specific error message (`${providerName} timed out` or `${providerName} connection failed`)
   - "Retry" button → calls `_retryLastMessage()` (line 212)
   - "Dismiss" button → clears the error, my unsent message is lost
3. The conversation history is preserved (messages are persisted to Hive)

**Issues:**

1. **No infinite retry protection**: A user can tap "Retry" indefinitely. Each tap creates a new LLM call. If the network is still down, they just accumulate errors. No backoff or "still trying..." feedback.

2. **Error messages are provider-specific but not helpful**: Saying "OpenRouter timed out" tells me the provider, but not what to DO about it. Compare: "The AI service is taking too long. Check your internet connection or try again later."

3. **Dismissing loses my message**: The draft I was typing is not saved anywhere. If I type a long question, network drops, error shows, I tap Dismiss, my text is gone. The input field is empty.

4. **No lesson state preservation on catastrophic failure**: If the app crashes during this error state (OOM, background kill), the lesson session remains `inProgress` in Hive. On next launch, `_checkOrphanedSessions()` (main.dart:578-617) detects it and shows a dialog: "Your last lesson was interrupted. What would you like to do?" with options to dismiss or discard. **This recovery flow exists and works correctly.**

**Verdict (MAJOR FAIL — but recovery flow is a PASS):**
- (A) No retry backoff — user can spam "Retry" on a down network.
- (B) Error messages not actionable — tell the user what broke but not what to do.
- (C) Dismissing error loses the user's draft text.
- (D) Orphaned session recovery on app restart works correctly. (PASS)

---

## Step 7: The Over-Request Problem — Silent Side Effects

I finish my lesson. After `_endLesson()` completes, several background tasks fire without my knowledge or consent.

**What the code does** (tutor_service.dart:326-393):

`_enqueueBackgroundTasks()` runs **after** the summary dialog is already shown. The user has no idea these are happening:
1. **Adherence check** — records plan adherence silently
2. **Weak topic reanalysis** — triggers a graph algorithm to re-identify weak areas
3. **Next topic pre-generation** (`_enqueueNextTopicPrep`, line 359): **Silently creates a pre-generated lesson for a weak topic** without asking me. This generates an LLM call (costing tokens) and saves a `Lesson` object to Hive — all without my explicit consent.

**The next topic prep is especially problematic:**
- It calls `_syllabusResolver.getNextTopics(subjectId, topicId)` to find "weak" topics
- Then calls `conversationManager.generateLessonPlan()` on the next weak topic
- Stores the result as a pre-generated `Lesson`
- This uses my API credits without my knowledge
- The LLM generates content for a topic I might not want to study next
- There's no way to opt out, review, or delete the pre-generated lesson

**Verdict (MAJOR FAIL):** Background tasks fire without user consent, consuming API credits and generating content the user didn't ask for. The next-topic pre-generation is especially problematic as it costs money without transparency.

---

## Step 8: Ending the Lesson — Summary Dialog

I tap the overflow menu → "End Lesson". A confirmation dialog appears: "Are you sure you want to end this lesson?" with "Save and Exit" and "Discard and Exit" options. I tap "Save and Exit".

**What I expect:** A summary screen showing what I learned, my performance on exercises, key concepts covered, and suggestions for what to study next. Maybe a "Continue where you left off" option if there's remaining time.

**What actually happens:**

After saving, `_showSummaryDialog()` (tutor_screen.dart:549) appears:

1. **Title**: "Lesson Complete"
2. **Stats chips** (line 613-643):
   - Clock icon: elapsed minutes
   - Checklist icon: exercise count (or "—" if none)
   - Check circle icon: correct count (or "—")
   - Speed icon: adaptive pace percentage — **rendered as `(manager.adaptivePace * 100).round()` which violates the i18n convention** (`number_format_utils.dart:formatPercent` should be used for locale-aware formatting)
3. **Lesson plan goals and checkpoints**: **NOT shown** — even though the `LessonPlan` has `goals`, `checkpoints`, and `sections`, none of these appear in the summary. I see my stats but don't know if I achieved the lesson's goals.
4. **Action buttons**:
   - "Quick Practice (15 min)" → Focus Timer mode, 15 minutes
   - "Practice Mode (30 min, 20 questions)" → Focus Timer mode, 30 minutes  
   - "Done" → back to previous screen

**Issues:**

1. **i18n violation**: `(manager.adaptivePace * 100).round()` at line 630 — uses `toStringAsFixed` implicitly (since `.round()` produces an int, then `$speed%` format). Should use `formatPercent` from `number_format_utils.dart`.

2. **No goal achievement review**: The lesson's learning goals are known (from `LessonPlan.goals`) but not displayed. I can't tell if I successfully achieved the goals set at the beginning.

3. **No "Continue Lesson" option**: If I end the lesson early (before `durationMinutes` expires), there's no option to resume. The "Done" button pops the screen permanently. The only way to continue is to navigate back and start a new lesson (which regenerates the plan and costs another LLM call).

4. **Post-lesson navigation goes to Focus Mode, not Practice**: The "Quick Practice" and "Practice Mode" buttons navigate to Focus Timer screen, not to the Practice tab. This seems odd — a user wanting to practice after a lesson would expect to go to the Practice tab with their subject pre-selected, not to a timer screen.

5. **No "View Lesson Notes" option**: The `TutorMetadata` includes `tutorNotes` and the `Lesson` record stores the full lesson content. But the summary dialog doesn't offer a way to review the lesson content. Once dismissed, the only way to see lesson notes is through `TutorSessionRepository` — there's no "Past Lessons" review screen.

**Verdict (MAJOR FAIL — multiple issues):**
- (A) i18n violation in adaptive pace display.
- (B) Lesson goals and checkpoints from the plan are not shown in summary.
- (C) No "Continue Lesson" option after early exit.
- (D) Post-lesson practice links to Focus Timer, not Practice tab.
- (E) No lesson notes review option after summary dismissal.

---

## Step 9: Time Expiry — Automatic Lesson End

My lesson was set for 30 minutes. At 27 minutes, the progress bar shows 90% complete. The tutor phase transitions to `closing`.

**What I expect:** A gentle notification: "We have about 3 minutes left. Let's wrap up with a summary." Then at 30:00, a closing message, and the summary dialog appears. I can optionally extend if I want.

**What actually happens** (tutor_screen.dart:140-515):

1. At `elapsedMinutes >= durationMinutes`: `_manager!.transitionToClosing()` fires (line 144-148)
2. A 3-minute grace period starts (`_startClosingGraceTimer()`, line 505)
3. During the grace period, phase is `closing`. The tutor can continue the conversation, but the timer is ticking.
4. After grace period expires: `_endLessonInternal()` fires automatically → summary dialog appears (line 509-512)

**Issues:**

1. **No visual countdown or warning**: There's no "3 minutes remaining" banner that's visually distinct from the normal progress bar. The only indication is the section timeline advancing toward the end.

2. **No extend option**: When the grace period starts, there's no "I need more time" button. The user is forced to end within 3 minutes or have the lesson auto-terminate. If the student is in the middle of an important explanation, the lesson auto-ends.

3. **`.then()` on async void in auto-close path** (line 510-512): `_endLessonInternal().then((_) { ... })` — using `.then()` on a `Future<void>` is fragile. If `_endLessonInternal()` throws, the `.then()` never fires, and the user sees... nothing? The summary dialog never appears, and the lesson silently ends.

4. **Auto-close cannot be cancelled**: Once the grace period timer fires, the lesson auto-ends. The user cannot say "wait, I'm not done."

**Verdict (MAJOR FAIL):** Auto-end on time expiry offers no extend option. No explicit countdown warning. `.then()` pattern on auto-close path is fragile — if the end-lesson chain throws, the user gets no summary dialog.

---

## Step 10: Background Lesson End Without User Initiation

I close the app mid-lesson (swipe from recent apps). The lesson session is in `inProgress` state.

**What happens on next launch** (main.dart:578-617):

`_checkOrphanedSessions()` runs as a post-frame callback:
1. Queries `TutorSessionRepository` for sessions with `status == SessionStatus.inProgress`
2. If found, shows a dialog: "Your last lesson was interrupted. What would you like to do?"
3. Options: "Dismiss" (ignore) or "Discard Session" (delete the session record)
4. If the user dismisses, the session remains `inProgress` in the database — a zombie session

**Issues:**

1. **No "Resume Lesson" option**: The recovery dialog only offers to dismiss or discard. A user who was in the middle of a lesson cannot resume it. They must start a new lesson (costing another API call for plan generation).

2. **"Dismiss" creates zombie sessions**: If I accidentally dismiss, the `inProgress` session stays in Hive forever. It never transitions to `completed` or `cancelled`. On future app starts, `_checkOrphanedSessions()` re-detects it and shows the dialog again. Every. Single. Launch.

3. **No auto-recovery**: If the lesson's `elapsedMinutes` is close to `durationMinutes`, a better UX would auto-complete the session instead of showing an interruption dialog.

**Verdict (MAJOR FAIL — multiple issues):**
- (A) No "Resume Lesson" option after app crash/close.
- (B) "Dismiss" creates zombie sessions that re-prompt on every app launch.
- (C) No auto-recovery for nearly-complete sessions.

---

## Step 11: Reviewing Past Lessons

After a few days of tutoring, I want to review what I learned in my first lesson.

**What I expect:** A "Lesson History" screen. Maybe in the Planner (since lessons are part of the plan) or the Subjects tab (since lessons are per-subject). I tap a past lesson and see the conversation, tutor notes, exercises I did, and my performance.

**What actually happens:**

There is **no lesson history review screen in the entire app.** The data exists:
- `TutorSession` records are persisted in Hive (tutor_session_model.dart)
- Conversation messages are persisted in Hive (conversation_message_model.dart)
- `Lesson` records with blocks are persisted in Hive (lesson_model.dart)
- `Session` records with `TutorMetadata` are persisted (session_model.dart)

But there's no UI that surfaces any of this to the user:

- **Planner** → Shows only future/adherence, no past lesson reviews
- **Subjects tab** → Subject detail has a "History" tab that shows `Session` records for all history — but these are bare-bones entries with no "View Details" option. A `Session` with `TutorMetadata` is listed but not expandable. Tapping it does nothing.
- **Dashboard** → Shows stats (total sessions, hours) but no drill-down into individual lessons
- **No "My Lessons" screen** anywhere in the navigation

The `TutorSessionRepository.getAll()` and `ConversationRepository.getBySession()` could load past sessions, but no screen calls them for display purposes.

**Verdict (BLOCKER FAIL):** Past lessons are saved but cannot be reviewed through any UI. The data is stored (conversation, tutor notes, exercises, scores) but completely inaccessible to the user after the summary dialog is dismissed.

---

## Step 12: Starting a Second Lesson — Singleton TutorService

I finish my first lesson (summary dialog, tap "Done"). I navigate back to the Planner and start a second lesson on a different topic.

**What I expect:** A fresh, clean lesson starts. No state from the previous lesson leaks in.

**What actually happens:**

`TutorService` is a **singleton** (teaching_providers.dart:29 — `Provider<TutorService>`). When I start the second lesson:
1. `_initializeTutor()` (tutor_screen.dart:89) calls `_tutorService.startLesson()` which creates a new `ConversationManager` and new session
2. The `_TutorScreenState` is fresh because the widget was disposed and recreated (Navigator push creates a new instance)

But the singleton `TutorService` still holds references from the previous lesson:
- `_currentManager` is overwritten by the new `startLesson()` call
- Background tasks from the previous lesson (`_enqueueBackgroundTasks()` fire-and-forget) may still be running
- `_llmAgent` was set imperatively on the previous `_initializeTutor()` call — the new lesson sets a new `llmAgent`, but if the old one is still completing a streaming response, there could be resource leaks

The singleton pattern itself is not the main issue (since widget recreation handles UI state), but the `_llmAgent` imperative assignment and fire-and-forget background tasks create potential for overlapping state. If a user rapidly starts and ends lessons, the background tasks from previous lessons pile up.

**Verdict (MINOR FAIL):** `TutorService` singleton creates potential for overlapping background tasks. Imperative `llmAgent` assignment is fragile.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | "Start AI Tutor" is prominent from Dashboard/bottom nav | No tutor tab; no Dashboard entry; only through Planner/Lessons screens | **MAJOR FAIL** |
| 2 | Prerequisite dialog has clear button semantics | "Practice Prerequisites" starts the lesson, "Continue Anyway" navigates back — **reversed logic** | **BUG — MAJOR** |
| 3 | Initialization shows sub-stage progress | Single spinner for entire 10-30s init; no sub-stage labels; no estimated wait | **MAJOR FAIL** |
| 4 | LLM plan generation failure is communicated to user | Silent fallback to generic `buildDefaultPlan()` — user never knows | **MAJOR FAIL** |
| 5 | Init error shows specific failure reason | First failure path passes empty string: `tutorInitFailed('')` — error lost | **MAJOR FAIL** |
| 6 | Lesson goals and objectives are shown at start | `LessonPlan.goals`, `checkpoints` parsed but never displayed to user | **MAJOR FAIL** |
| 7 | Section timeline is self-explanatory | Colored segments with no legend — user doesn't know what colors mean | **MINOR FAIL** |
| 8 | "End Lesson" button is prominent | Hidden in overflow menu (three dots, top-right) | **MINOR FAIL** |
| 9 | Exercise detection works for all locales | Only supports `en` and `es` keywords — French/German/etc. users must use English | **MAJOR FAIL** |
| 10 | `adaptiveReview` counter resets on correct answer | Counter NOT reset when scoring above threshold — may exit prematurely | **BUG — MAJOR** |
| 11 | Exercise evaluation failures are surfaced to user | Returns score 0.5 silently — no "evaluation failed" indicator | **MAJOR FAIL** |
| 12 | Phase transitions don't discard teaching content | Exercise keyword in user message can preempt and discard LLM's teaching response | **BUG — MAJOR** |
| 13 | TTS during streaming (reads aloud as text appears) | TTS only starts after full response displayed — disjointed experience | **MAJOR FAIL** |
| 14 | Mic button hidden on web (where STT unavailable) | Mic button visible on web but non-functional | **MINOR FAIL** |
| 15 | Retry has backoff/limit for network errors | No backoff, no cap — user can spam Retry indefinitely | **MAJOR FAIL** |
| 16 | Error messages are actionable (tell user what to do) | Provider-specific but not actionable: "OpenRouter timed out" with no suggested action | **MINOR FAIL** |
| 17 | Dismissing error preserves user's draft | Draft text is lost when error is dismissed | **MAJOR FAIL** |
| 18 | Background tasks require user consent | Next-topic pre-generation runs silently, using API credits without asking | **MAJOR FAIL** |
| 19 | Summary shows lesson goals and checkpoints | Only basic stats shown (minutes, exercises, correct, pace) — goals invisible | **MAJOR FAIL** |
| 20 | Adaptive pace uses locale-aware formatting | `(adaptivePace * 100).round()` — i18n convention violation | **MINOR FAIL** |
| 21 | "Continue Lesson" if early exit | No resume option — must start new lesson (new LLM call) | **MAJOR FAIL** |
| 22 | Post-lesson practice goes to Practice tab | Goes to Focus Timer screen instead | **MINOR FAIL** |
| 23 | Lesson notes are reviewable after summary | No "Past Lessons" review screen anywhere | **BLOCKER FAIL** |
| 24 | Extend option when time runs out | No extend option; auto-end forces 3-min grace period, then hard stop | **MAJOR FAIL** |
| 25 | `.then()` pattern safe for auto-close | Fragile — if `_endLessonInternal()` throws, summary dialog never appears | **MAJOR FAIL** |
| 26 | "Resume Lesson" after app crash/interruption | Only "Dismiss" or "Discard" — no resume; Dismiss creates zombie sessions | **MAJOR FAIL** |
| 27 | Orphaned sessions auto-complete if nearly done | No auto-recovery — always shows interruption dialog | **MINOR FAIL** |
| 28 | Past lessons reviewable | All lesson data stored but no review UI exists | **BLOCKER FAIL** |
| 29 | Background tasks don't overlap across lessons | Singleton TutorService + fire-and-forget tasks can pile up | **MINOR FAIL** |

---

## Summary

| Severity | Count | Items |
|---|---|---|
| **BLOCKER** | 2 | #23 (no past lesson review), #28 (past lessons inaccessible) |
| **BUG** | 3 | #2 (reversed prerequisite button), #10 (adaptiveReview counter), #12 (phase transition discards content) |
| **MAJOR** | 15 | #1, #3, #4, #5, #6, #9, #11, #13, #15, #17, #18, #19, #21, #24, #26 |
| **MINOR** | 7 | #7, #8, #14, #16, #20, #22, #27, #29 |

The AI tutor lesson experience is the core feature of StudyKing, yet it has several critical usability gaps: no persistent entry point from the home screen, no way to review past lessons (despite all data being stored), silent side effects consuming API credits without consent, and multiple bugs in the conversation phase management. The lesson summary lacks educational context (goals, checkpoints) and the auto-close path is fragile.
