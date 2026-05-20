# Dry-Run Result: Attending an AI Tutor Lesson

**Scenario file:** `dry-run-test/scenario_attending_tutor_lesson.md` (deleted — 87.5% complete)

**Validation date:** 2026-05-19

**Overall: 10/12 claims COMPLETED, 1 PARTIAL, 1 NOT_COMPLETED (87.5%)**

---

## Remaining Issues

### Issue 1: Summary dialog double-pop (PARTIAL)

**File:** `lib/features/teaching/presentation/tutor_screen.dart:476-481`

**Problem:**
The "Done" button in the summary dialog uses a cascade double-pop:
```dart
Navigator.of(context)..pop()..pop();
```
This pops both the dialog and the tutor screen in the same frame. While functionally correct, the user may briefly see the tutor screen flash before being returned to the previous screen.

**Fix:**
Pop the tutor screen from the dialog's `Navigator.pop(ctx)` callback (using the dialog's context `ctx` to pop just the dialog), then let the user land naturally on the tutor screen. Alternatively, use `Navigator.of(context).pop()` for the dialog, then `Navigator.of(context).pop()` for the tutor screen in a post-frame callback to allow the dialog close animation to settle.

**Acceptance criteria:**
- Tapping "Done" closes the dialog smoothly, then navigates back to the previous screen without visual glitch.

---

### Issue 2: Scheduled session context missing from LLM prompts (NOT_COMPLETED)

**Files:**
- `lib/features/teaching/services/conversation_manager.dart:190-195`
- `lib/features/teaching/services/prompts/prompts.dart:42-65`
- `lib/features/teaching/presentation/tutor_screen.dart:176-179`

**Problem:**
When a lesson is started from a scheduled session, the tutor has no awareness of this context:
1. **Greeting** (`tutor_screen.dart:178-179`): Always says `"Ready to learn about [topic]?"` regardless of whether this is a scheduled lesson.
2. **Tutor prompt** (`conversation_manager.dart:190-195` → `prompts.dart:42-65`): The `tutorMessage` prompt receives no `scheduledSessionId` or `isScheduledLesson` flag. The LLM cannot tailor its behavior (e.g., "Welcome to your scheduled lesson on Atomic Structure. We have 30 minutes together today.").

**Fix:**
- Add an optional `isScheduledLesson` or `scheduledSessionId` parameter to `ConversationPromptSet.tutorMessage()`.
- Add a locale-aware scheduled-lesson greeting string (e.g., `scheduledLessonGreeting(topicTitle)`) in the l10n files.
- Pass the flag from `TutorScreen` / `TutorArgs` through to `ConversationManager` and then to the prompt builder.
- Include the scheduled context in the system prompt so the AI knows it's part of a pre-planned session with a fixed duration.

**Acceptance criteria:**
- When `scheduledSessionId` is provided, the tutor greets the student with a scheduled-lesson-aware message (e.g., "Welcome to your scheduled lesson on Atomic Structure").
- The LLM system prompt includes a note that this is a scheduled session so the AI can reference it appropriately.
- When no `scheduledSessionId` is provided, the generic greeting is used as before.
