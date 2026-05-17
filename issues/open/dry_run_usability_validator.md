# Dry-Run Usability Validation: Attending an AI Tutor Lesson

**Scenario:** `dry-run-test/scenario_attending_tutor_lesson.md`
**Date:** 2026-05-17

A returning user who has a scheduled 30-minute IB Chemistry lesson on "Atomic Structure" tries to attend it, interact with the AI tutor, answer exercises, end the session, and verify the results in the dashboard.

---

## BLOCKER (app crashes or user cannot proceed)

### B1. Back-Button Exits Tutor Without Saving — Lesson Data Lost

**Files:**
- `lib/features/teaching/presentation/tutor_screen.dart` (no `PopScope` / `WillPopScope`)

**Rationale:** The `TutorScreen` has no `PopScope` wrapper. If the user presses the system back button (Android) or gesture-navigates back, the screen pops without calling `_endLesson()`. This means:
- The `TutorSession` remains `inProgress` forever
- None of the conversation messages are persisted
- Mastery data is not recorded
- Plan adherence is not recorded
- The timer keeps running until the widget is garbage-collected

**Acceptance Criteria:**
- `TutorScreen` must wrap its scaffold in a `PopScope` that intercepts back navigation
- Intercepted back-navigation should show a confirmation dialog: "End lesson and save progress?" with options "Cancel" (stays in lesson), "Save and Exit" (calls `_endLesson()` and then pops), "Discard and Exit" (marks session as cancelled and pops without saving)

---

## MAJOR (feature is broken or misleading)

### M1. "Scheduled Lesson" Card Has No "Join" / "Start" Button

**Files:**
- `lib/features/planner/presentation/planner_screen.dart` lines 513-580 (`_buildScheduledLessonsSection`)

**Rationale:** The scheduled lessons section shows cancel and reschedule buttons, but no way to actually START the lesson the user scheduled. The user must navigate through a completely separate path (daily plan card → smart_toy icon) to begin tutoring. This is the single most important action a user wants to take from a scheduled lesson — attending it.

**Acceptance Criteria:**
- Each scheduled lesson card must include a "Join Now" or "Start Lesson" button (primary color, prominent)
- Tapping it should navigate to `TutorScreen` with the correct `topicId`, `topicTitle`, `subjectId` **and** the `plannedDurationMinutes` from the scheduled `Session`
- Bonus: the scheduled `Session` should be passed somehow so the tutor screen can mark it as attended on completion

### M2. Scheduled Lesson Duration Not Forwarded to TutorScreen

**Files:**
- `lib/core/routes/app_router.dart` (`TutorArgs` has no scheduled-session reference)
- All four entry points to `TutorScreen`:
  - `lib/features/planner/presentation/planner_screen.dart:55-67` (`_openTutorMode`)
  - `lib/features/planner/presentation/widgets/daily_plan_card.dart:99-106`
  - `lib/features/lessons/presentation/lesson_detail_screen.dart:78-91`
  - `lib/features/lessons/presentation/lesson_list_screen.dart:79`

**Rationale:** `TutorArgs` accepts `durationMinutes` with default 45. The `LessonBookingSheet` lets the user choose a duration and saves it as `plannedDurationMinutes` on the `Session` record. But NONE of the entry points read this value and pass it to `TutorArgs`. So every tutor session defaults to 45 minutes regardless of what was scheduled.

**Acceptance Criteria:**
- Add a `tutorSessionId` field to `TutorArgs` (the scheduled session ID)
- When navigating from a scheduled lesson context, pass the `plannedDurationMinutes` as `durationMinutes`
- The `TutorScreen` should display the correct planned duration in the progress bar

### M3. Scheduled Session Never Transitions to "Attended"

**Files:**
- `lib/features/teaching/services/tutor_service.dart` (no reference to scheduled `Session` records)

**Rationale:** The TutorScreen creates a completely new `TutorSession` with ID `tutor_<timestamp>`. The scheduled `Session` (created by `LessonBookingSheet`) has status `SessionStatus.planned` and is stored separately. There is no code that links the two: when a tutor session ends, the corresponding scheduled session (if any) is never updated to `completed` or `inProgress`.

**Acceptance Criteria:**
- Either `TutorService.endLesson()` should accept an optional `scheduledSessionId` and update the corresponding `Session` to `completed` status
- Or the scheduled `Session` status should transition to `inProgress` when the user starts the tutor and `completed` when the tutor session ends
- The `PlannerScreen` should stop showing completed/attended lessons in the scheduled section

### M4. Exercise Evaluation Lacks Question Context

**Files:**
- `lib/features/teaching/services/conversation_manager.dart` line 174

**Rationale:** When the user answers an exercise question, `_evaluateExerciseResponse()` calls:
```dart
final result = await _exerciseEvaluator.evaluate(
  question: '',  // Empty — the actual question is lost
  studentAnswer: content,
  subjectId: subjectId,
  topicTitle: topicTitle,
);
```

The evaluator only receives the subject name and topic title, and must infer what question was asked from the student's answer alone. This dramatically reduces evaluation accuracy, especially for partially correct answers where understanding the exact question is critical.

**Acceptance Criteria:**
- The `ConversationManager` must track the last exercise question asked by the AI (the last assistant message in `exercise` phase)
- `_evaluateExerciseResponse()` must pass this actual question text instead of an empty string
- Bonus: include the evaluation rubric or expected answer components in the prompt if the lesson plan defines them

### M5. Mid-Lesson Crash Loses All Conversation Data

**Files:**
- `lib/features/teaching/services/conversation_manager.dart` line 60-64 — `ConversationMemory` created without `persistenceRepo`
- `lib/features/teaching/services/tutor_service.dart` line 65-75 — `ConversationManager` instantiated without `persistenceRepo`

**Rationale:** The `ConversationManager` is created with `persistenceRepo: null` (the optional parameter is never passed by `TutorService`). This means `ConversationMemory._persistMessage()` is a no-op throughout the entire lesson. ALL conversation messages are saved in one batch at `endLesson()`. If the app crashes, the system kills the process, or the user force-quits, every message is lost. The `TutorSession` record (which was saved at `startLesson()`) remains as an orphaned `inProgress` entry.

**Acceptance Criteria:**
- Inject `ConversationRepository` into `TutorService` and pass it to `ConversationManager`
- Each message should be persisted individually as it's added (both user and assistant messages)
- On app restart, check for orphaned `inProgress` sessions and offer to resume or discard them

### M6. Confidence Rating Calculation Overflow Bug

**Files:**
- `lib/features/teaching/services/tutor_service.dart` line 109

**Rationale:**
```dart
confidence: (session.confidenceRating * 20).clamp(0, 5).round(),
```

`session.confidenceRating` is already in 0-5 range (computed in `ConversationManager.toSession()` as `(confidenceRating * 5).round()` where `confidenceRating` is 0.0-1.0). Multiplying by 20 produces 0-100, then `clamp(0, 5)` maps everything >= 5 to 5. This means for any non-zero session confidence, the stored confidence is always 5 (maximum). The mastery system receives inflated confidence values, skewing mastery calculations.

Example trace:
- Real confidence = 0.4 (40% correct, below average)
- `toSession()` → `(0.4 * 5).round() = 2`
- endLesson() → `(2 * 20).clamp(0, 5).round() = 5` (max!)
- Mastery system records confidence = 5/5 (excellent), which is wrong

**Acceptance Criteria:**
- Fix the formula to `session.confidenceRating` (no multiplication) or `(session.confidenceRating / 5 * 5).round()` (no-op identity)
- Add a test that verifies confidence is preserved correctly end-to-end

---

## MINOR (UX friction)

### m1. First 1-2 Characters of Streaming Responses Clipped

**Files:**
- `lib/features/teaching/services/conversation_manager.dart` line 147

**Rationale:**
```dart
if (buffer.length > 2) {
  yield* _buildAdaptiveChunks(buffer.toString());
}
```

The condition `buffer.length > 2` means the first 1-2 characters of every LLM response are never sent to the UI stream. Short responses like "OK", "Hi", or "No" may never render at all. The user sees responses starting mid-word, which looks broken.

**Acceptance Criteria:**
- Remove the length guard entirely, or change it to `buffer.isNotEmpty` (yield immediately with first character)
- The `_buildAdaptiveChunks` method should handle single-character chunks gracefully (it currently chunks by adaptive pace, which will work with 1-char input)

### m2. "End Lesson" Button Has No Confirmation Dialog

**Files:**
- `lib/features/teaching/presentation/tutor_screen.dart` line 267-271 (`TextButton.icon` calls `_endLesson` directly)
- `lib/features/teaching/presentation/tutor_screen.dart` line 144-178 (`_endLesson` method)

**Rationale:** Tapping "End Lesson" immediately terminates the session, generates a summary, and shows the dialog. There is no confirmation step. An accidental tap (especially on mobile where buttons are small) means the user loses their current lesson context with no way to cancel.

**Acceptance Criteria:**
- Before calling `_endLesson()`, show an `AlertDialog` with: "End your lesson? Your progress will be saved."
- Buttons: "Continue Lesson" (dismisses dialog, stays in lesson) and "End Lesson" (proceeds with `_endLesson()`)

### m3. Summary Dialog Pops Two Screens Disorientingly

**Files:**
- `lib/features/teaching/presentation/tutor_screen.dart` lines 167-171

**Rationale:**
```dart
onPressed: () {
  Navigator.of(ctx).pop();     // pop the dialog
  Navigator.of(context).pop(); // pop the tutor screen
}
```

Tapping "Done" on the summary dialog pops the dialog AND then immediately pops the tutor screen. This double-pop can be disorienting — the user goes from summary → Planner/Dashboard in one tap with no visual transition between the dialog being dismissed and the screen being popped.

**Acceptance Criteria:**
- After popping the dialog, add a short delay (e.g., 200ms) before popping the tutor screen so the user sees the underlying screen briefly before transitioning
- Or replace the AlertDialog with a bottom-sheet or full-screen summary that has a more gradual dismissal
- Or keep the user on the tutor screen but in a "completed" state, with a "Back to Planner" button

### m4. Errors in Satellite Persistence Are Silently Swallowed

**Files:**
- `lib/features/teaching/services/tutor_service.dart` lines 116-121 and 123-148

**Rationale:**
```dart
try {
  await _planAdapter.recordFromTutorSession(...);
} catch (_) {}

try {
  await _database.sessionRepository.save(...);
} catch (_) {}
```

Failures in plan adherence recording and session repository persistence are completely silenced. The user has no way to know that adherence data or session history was not saved. This leads to confusing dashboard inconsistencies (lesson done but dashboard doesn't reflect it).

**Acceptance Criteria:**
- Log the error details instead of silently swallowing
- Consider showing a non-blocking snackbar: "Lesson saved, but some stats couldn't be synced"
- At minimum, collect these failures and report them in a single error message at the end

### m5. Voice Input Locale Hardcoded to en_US

**Files:**
- `lib/features/teaching/services/voice_controller.dart`

**Rationale:** Speech-to-text is hardcoded to `en_US` locale, and TTS is hardcoded to `en-US`. For users with Spanish, French, German, or other system languages, voice input produces gibberish because the speech recognizer is expecting English phonemes. There's no microphone permission handling in the UI — `requestPermission()` exists but is never called from `VoiceBar`.

**Acceptance Criteria:**
- Read the STT locale from the app's current locale setting or system locale
- Read the TTS locale from the same source
- Proactively request microphone permission when the VoiceBar is first shown (not on first mic tap)
- Handle denial gracefully with an explanation

### m6. Lesson-Time-Ended Warning Is Disconnected from Chat State

**Files:**
- `lib/features/teaching/presentation/tutor_screen.dart` lines 258-259, 320-346

**Rationale:** When `remaining <= 0`, the message list shows an "invisible" info message "Lesson time has ended" at the bottom of the list (it's a text widget inserted after the messages). But the user can continue typing indefinitely. The LLM is NOT informed that the lesson should be wrapping up — it continues teaching as normal. The time-end warning is purely cosmetic and disconnected from the actual conversation flow.

**Acceptance Criteria:**
- When planned time expires, inject a system message into the conversation (e.g., "The lesson time has ended. Please wrap up and end the session.") so the LLM can transition to closing phase
- Consider auto-triggering `transitionToClosing()` on the `ConversationManager`
- The "Lesson time has ended" text should be more prominent (a banner, not a line item in the chat)

### m7. No Auto-Locale for Conversation Prompts

**Files:**
- `lib/features/teaching/services/prompts/prompts.dart` (tutor prompts)

**Rationale:** LLM prompts for the tutor, lesson plan generation, and summary are all in English. There is no localization mechanism for prompting the LLM in the user's language. A Spanish-speaking user gets English lesson plans, English teaching, and English summaries.

**Acceptance Criteria:**
- Add a `localeName` parameter to `TutorScreen` / `ConversationManager` / `ConversationPromptSet`
- System prompts should include "Respond in the same language as the student" or inject the user's locale explicitly when generating prompts
- This is already partially tracked in `issues/open/internationalisation_master.md` — link to that issue

---

## Previous Scenario Findings (Cross-Reference)

The following findings from `scenario_first_launch_ib_chemistry.md` and `scenario_existing_user_pace_subjects_provider.md` remain unaddressed:

| Scenario | Finding | Status | Severity |
|---|---|---|---|
| `first_launch` | No onboarding tour; dropped into 5-tab shell | Unresolved | FAIL |
| `first_launch` | Dashboard checklist items not tappable (add subject works, others questionable) | Partially fixed (add subject works) | MAJOR |
| `first_launch` | "Learn IB Chemistry in 90 days" — course input ignored by plan engine | Unresolved | FAIL |
| `first_launch` | API key setup not prompted on first AI use; silent fallback | Unresolved | MAJOR |
| `first_launch` | Adding subject does not prompt for materials | Unresolved | MINOR |
| `existing_user` | No pace adjustment slider — must regenerate entire plan | Unresolved | PARTIAL |
| `existing_user` | Switching providers preserves old model ID | Unresolved | MAJOR |
| `existing_user` | Editing subject not available in subject menu | Unresolved | MAJOR |
| `existing_user` | Deleting subject doesn't actually delete | Unresolved | BLOCKER |
| `existing_user` | Cancel/reschedule scheduled lessons | **RESOLVED** — buttons now exist | Fixed |
| `existing_user` | Planner doesn't support multi-subject plans via UI | Unresolved | PARTIAL |
| `existing_user` | Export section buried at bottom of dashboard | Unresolved | MINOR |
