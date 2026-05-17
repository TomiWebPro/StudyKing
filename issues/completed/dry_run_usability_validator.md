# Dry-Run Usability Validation: Mentor as AI Study Companion

> Scenario file: `dry-run-test/scenario_mentor_study_companion.md`
> Validated against codebase commit: current HEAD

---

## Scenario Summary

A returning student opens the **Mentor tab** for the first time, expecting an AI study companion that knows their context, can review progress, schedule lessons conversationally, and proactively help manage their study habits. The scenario traces: first-time welcome, context-aware Q&A, progress report, conversational scheduling, cross-session persistence, wellbeing checking, next-action suggestions, API error handling, plan intent detection, tab-state preservation, and long-conversation memory management.

---

## BLOCKER Findings (app crashes or user cannot proceed)

### B-1: Conversational scheduling runs with zero user confirmation

The `_handleScheduleIntent()` method (`lib/features/mentor/services/mentor_service.dart:446-512`) detects scheduling keywords in user chat and immediately schedules a lesson at the next free hour. The user is never asked to confirm the time, date, duration, or subject. The only "feedback" is a system message added to `ConversationMemory`, which is **invisible in the chat UI** (the UI filters to `MessageRole.mentor` and `MessageRole.student` only — see `mentor_screen.dart:82`).

Additionally, the LLM streaming response completes *before* `_checkAndHandlePlanningIntent()` fires, so the LLM's visible reply cannot reference the scheduling outcome. The user sees a generic "I'll help you schedule" but never knows whether the lesson was actually booked.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:420-512` (`_checkAndHandlePlanningIntent`, `_handleScheduleIntent`)
- `lib/features/mentor/presentation/mentor_screen.dart:80-94` (message loading filters out `system` role messages)

**Acceptance criteria:**
- Scheduling through chat MUST show a confirmation dialog (time, date, duration, topic) before calling `scheduleLesson()`
- The confirmation MUST allow the user to cancel or modify the proposed schedule
- After confirmation, the scheduling result MUST appear as a visible mentor message in the chat

### B-2: Progress report "Practice weak topic" navigates with empty subjectId

Each weak topic `ListTile` in the progress report dialog (`mentor_screen.dart:484-491`) calls:
```dart
Navigator.pushNamed(context, AppRoutes.practiceSession, arguments:
  PracticeSessionArgs(subjectId: '', topicId: topic.topicId));
```
The `subjectId` is hardcoded to empty string `''`. The `MasteryState.topicId` does not carry subject information, so the dialog passes `subjectId: ''` unconditionally. The practice session screen requires a valid subjectId to load questions — with an empty one, it will either show zero questions or crash.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart:484-491` (passes empty `subjectId`)
- `lib/features/mentor/data/models/progress_report.dart:1-27` (`ProgressReport` lacks subject info on weak topics)

**Acceptance criteria:**
- `ProgressReport.weakTopics` must include `subjectId` for each weak topic
- The navigation action in `_showProgressReport()` must pass the correct `subjectId`
- OR: the practice session screen must handle empty `subjectId` gracefully with an error message

### B-3: Conversational scheduling result is invisible in chat UI

When `_handleScheduleIntent()` completes, it calls `_memory.addSystemMessage()` to record the outcome (success, conflict, or failure). However, `_initializeMentor()` at `mentor_screen.dart:80-84` filters loaded messages to only `MessageRole.mentor` and `MessageRole.student`. System messages are excluded. The scheduling outcome is stored in Hive but never rendered.

This also applies to `_handlePlanIntent()` (line 540) which adds system messages that never appear.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart:80-84` (filter excludes `system` role)
- `lib/features/mentor/services/mentor_service.dart:497-508` (scheduling result as system message)
- `lib/features/mentor/services/mentor_service.dart:540-542` (plan result as system message)

**Acceptance criteria:**
- Scheduling/planning outcomes must appear as visible mentor chat messages (role `mentor`), not system messages
- The chat must re-render to show the outcome immediately after scheduling completes

---

## MAJOR Findings (feature is broken or misleading)

### M-1: `checkWellbeingAndGenerateNudges()` never called from MentorScreen

The `MentorService.checkWellbeingAndGenerateNudges()` method (`mentor_service.dart:343-418`) contains comprehensive logic for detecting overwork, late-night study, revision needs, streaks, and inactivity. However, this method is **never called** during `_initializeMentor()`, `chat()`, or any other MentorScreen lifecycle method. The only wellbeing signal reaching the user depends on whether the LLM chooses to respond to the `"WARNING: daily cap exceeded"` text in the context prompt — which is unreliable.

The context prompt does include wellbeing-relevant data (lines 174-198), but the explicit nudge-generation logic (creating EngagementNudgeModel records) is dead code in the context of the Mentor tab.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:343-418` (method defined but unreachable from MentorScreen)

**Acceptance criteria:**
- `checkWellbeingAndGenerateNudges()` must be called at appropriate points: after initialization, after each chat turn, or on a periodic timer within the MentorScreen
- Overwork/nudges must be surfaced as visible chat messages, not just context-prompt warnings

### M-2: `suggestNextAction()` and `suggestReschedule()` are dead code

Both methods are fully implemented in `MentorService`:
- `suggestNextAction()` (`mentor_service.dart:576-599`) — returns a `MentorAction` with next-step recommendation
- `suggestReschedule(String sessionId)` (`mentor_service.dart:601-647`) — finds next free slot, creates a PendingActionModel

Neither method is called from `MentorScreen` or any other widget. The `MentorAction` model (`lib/features/mentor/data/models/mentor_action.dart:1-9`) is defined but never displayed. The `PendingActionRepository` is never populated by the mentor flow.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:576-647` (both methods unreachable)
- `lib/features/mentor/data/models/mentor_action.dart:1-9` (model defined but unused)

**Acceptance criteria:**
- The MentorScreen must display a "Suggested next action" area (chip, card, or inline) that calls `suggestNextAction()` and renders the `MentorAction`
- OR: the `chat()` method must call `suggestNextAction()` and inject the recommendation into the conversation

### M-3: Missing API key causes silent empty response instead of clear error

When no API key is configured, `LlmService.chatStream()` returns an empty stream (yields nothing, completes normally — no exception). The MentorScreen's `_sendMessage()` method completes its `await for` loop with an empty buffer, sets the message content to `''`, and marks it as complete. The user sees a loading spinner, then an empty bubble. The error catch block at line 186 never fires because the stream completed without throwing.

The `ApiKeyBanner` on the main screen (main.dart:371-374) provides some warning, but within the Mentor tab itself, the experience is a silent failure.

**Affected files:**
- `lib/core/services/llm/llm_chat_service.dart:79-81` (empty key returns empty stream without error)
- `lib/features/mentor/presentation/mentor_screen.dart:159-199` (catch block never reached for empty stream)

**Acceptance criteria:**
- When API key is empty, the mentor chat must show a clear inline error message: "AI service not configured. Go to Settings to add an API key."
- A "Go to Settings" button or inline link must be provided in the error message

### M-4: Plan intent handling produces invisible output

`_handlePlanIntent()` (`mentor_service.dart:535-546`) extracts the number of days using regex and adds a system message with the `mentorPlanDaysPrompt` localized string. This system message is invisible in the chat UI (same issue as B-3). The only visible output is whatever the LLM decided to say in its initial response — which runs before the intent handler.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:535-546` (plan intent result hidden as system message)

**Acceptance criteria:**
- Plan intent results must appear as visible mentor chat messages
- The LLM response should be integrated with the plan intent result (or the intent handler should run before the LLM's response is finalized)

### M-5: Conversational scheduling hardcodes 30-minute duration

`_handleScheduleIntent()` (`mentor_service.dart:489-495`) calls `_plannerService.scheduleLesson()` with `durationMinutes: 30` hardcoded. The user has no way to specify a different duration through conversation. The `LessonBookingSheet` in the Planner UI supports configurable duration (15-90 min), but the conversational path bypasses this entirely.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:494` (hardcoded `durationMinutes: 30`)

**Acceptance criteria:**
- The mentor must either ask the user for the desired duration during scheduling, or use a configurable default from settings
- At minimum, the duration used must be displayed in the confirmation dialog (see B-1)

---

## MINOR Findings (UX friction)

### m-1: New/empty user receives generic advice instead of setup guidance

If a user opens the Mentor tab with no subjects, no practice data, and no plan, the `_buildContextPrompt()` returns a context string with all zeros/empty. The LLM receives no meaningful context and responds generically. There is no special-casing in the MentorScreen or `chat()` like: "You haven't set up any subjects yet. Go to the Subjects tab to get started!"

The `suggestNextAction()` method does handle this case (returns a `mentorNoSubjects` message), but it's never called (M-2).

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart:103-202` (no empty-state special handling)
- `lib/features/mentor/presentation/mentor_screen.dart:58-105` (no empty-state check besides history-loaded check)

**Acceptance criteria:**
- Before sending the context to the LLM, check if the student has meaningful data
- If data is empty/zero, display a local guidance message instead of invoking the LLM

### m-2: Conversation memory Hive records grow unboundedly

`ConversationMemory` truncates in-memory messages at `maxTurns * 2` (100 messages for mentor), but Hive records are never cleaned up. `conversation_memory.dart:29-31` removes old messages from the in-memory list only. Over months of use, the Hive-backed `ConversationRepository` accumulates thousands of records for the `'mentor_$studentId'` session key with no cleanup mechanism.

**Affected files:**
- `lib/core/services/conversation_memory.dart:29-31` (only in-memory trim, no Hive cleanup)
- `lib/features/teaching/data/repositories/conversation_repository.dart` (no age-based or count-based eviction)

**Acceptance criteria:**
- Hive records older than `maxTurns * 2` should be deleted when new messages are persisted
- OR: a periodic cleanup mechanism should trim old messages

### m-3: No memory truncation notification

When the in-memory conversation is truncated (oldest messages removed to stay under `maxTurns`), the user receives no indication. The UI still renders all messages loaded from Hive, but the LLM no longer sees the oldest ones. This can make the mentor appear to "forget" earlier parts of the conversation without explanation.

**Affected files:**
- `lib/core/services/conversation_memory.dart:29-31` (no user-facing truncation notification)

**Acceptance criteria:**
- When memory truncation occurs, a system message should be added (and rendered?) explaining that older context has been trimmed

---

## Cross-Scenario: Note on Content Library Findings

The existing scenario `scenario_managing_content_library.md` (dry-run-test) reports several BLOCKER failures about content library browsing, deletion, status display, and question bank access. However, the current codebase now has:

- `lib/features/ingestion/presentation/content_library_screen.dart` (581 lines) — full source browsing with filtering, sorting, swipe-to-delete, and navigation to source detail
- `lib/features/ingestion/presentation/source_detail_screen.dart` (565 lines) — per-source detail showing status, topic classification, summary, extracted text, generated questions, reprocess, and delete
- `lib/features/questions/presentation/question_bank_screen.dart` (539 lines) — question browsing, search, filter by subject/type/source, edit question text, delete single/bulk, multi-select
- Settings screen (`settings_screen.dart:74-80`) has "Content Management" section with "My Uploads", "Question Bank", and "Failed Uploads" entries

These screens were apparently added after the existing scenario was written. The existing scenario's findings for content library BLOCKER failures (no browsing, no deletion, no status, etc.) are now **partially or fully resolved**. A re-validation of that scenario against the current codebase would likely convert several BLOCKERs to PASS.

---

## Summary

| Severity | Count | Key Areas |
|----------|-------|-----------|
| BLOCKER  | 3 | No-confirmation scheduling, empty subjectId in progress report, invisible scheduling results |
| MAJOR    | 5 | Wellbeing nudges dead code, suggestNextAction/suggestReschedule dead code, silent API key failure, invisible plan intent output, hardcoded 30-min scheduling |
| MINOR    | 3 | Empty user gets no guidance, unbounded Hive growth, no truncation notification |

The Mentor tab has a solid foundation (rich context prompt, persistent conversation, tab-state preservation) but critical UX gaps in conversational scheduling (no confirmation, no feedback), unreachable service methods, and silent failures make the experience unreliable for users who rely on the Mentor as their primary study companion.
