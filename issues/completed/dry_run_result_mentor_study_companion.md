# Dry-Run Result: Mentor as Study Companion

**Status:** ~90% complete. Scenario file deleted (threshold met). 2 PARTIAL steps remain.

---

## Remaining Issues

### Issue 1: Step 4 — Scheduling Duration Hardcoded to 30 Minutes

**Location:** `lib/features/mentor/services/mentor_service.dart:628-631`

```dart
ScheduleProposal(
  topicTitle: topicTitle,
  proposedTime: nextHour,
  durationMinutes: 30,  // <-- hardcoded
);
```

**What's wrong:** When scheduling through conversation, the duration is always 30 minutes. The confirmation dialog shows this duration but the user cannot adjust it. The UX expectation is that the Mentor would either:
- Ask the user "How long should the lesson be?" and extract the duration from their reply
- Or let the user edit the duration in the confirmation dialog
- Or default to a configurable value from settings

**Note:** The `ScheduleLessonTool` (`lib/features/mentor/services/tools/schedule_lesson_tool.dart`) accepts `durationMinutes` as a parameter. For the **agent execution path**, the LLM can set custom duration. But the **keyword extraction path** (non-agent) is hardcoded.

**Suggested fix:** Either:
1. Extract duration from user message via regex (e.g., "30 min", "1 hour") — add to `_extractScheduleProposal()`
2. Or make the confirmation dialog editable for duration
3. Or read a default from user settings

---

### Issue 2: Step 4 — LLM Response Decoupled from Scheduling Outcome

**Location:** `lib/features/mentor/services/mentor_service.dart:136-208` (chat stream) and `lib/features/mentor/presentation/mentor_screen.dart:320-321` (post-chat intents)

**What's wrong:** The LLM response streams **before** the scheduling confirmation dialog appears. The LLM cannot reference the actual scheduling outcome in its response. If scheduling fails or the user cancels, the LLM's initial response may be misleading (e.g., "I've scheduled that for you!" when the user then cancels).

**Note:** The current UX flow is:
1. LLM streams conversational response (acknowledges request)
2. Confirmation dialog appears
3. Scheduling happens (or not)
4. Result message appears

The LLM response should ideally be aware that a confirmation dialog will follow and should phrase its response conditionally ("I can help with that! Let me check availability...") rather than committing to an outcome.

**Suggested fix:** Update `_mentorSystemPrompt()` to instruct the LLM to treat scheduling and plan-creation requests as proposals requiring user confirmation, and to use conditional language in responses.

---

### Issue 3: Step 7 — `suggestReschedule()` Has No UI Connection

**Location:** `lib/features/mentor/services/mentor_service.dart:781-828`

**What's wrong:** `suggestReschedule()` is fully implemented:
- Finds the next free slot for a given session
- Creates a `PendingActionModel` for the reschedule
- Adds system message with reschedule proposal

But it is **never called** from the MentorScreen (or anywhere in the UI). There's no button, menu item, or gesture to trigger a reschedule suggestion.

**Suggested fix:** Either:
1. Add a "Suggest reschedule" action to the lesson list in the planner
2. Or add a quick-action chip in the mentor screen that offers rescheduling for upcoming lessons
3. Or integrate with `_handlePostChatIntents()` when reschedule intent is detected
