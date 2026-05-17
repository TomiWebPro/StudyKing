# Dry-Run Scenario: Using the Mentor as an AI Study Companion

## Persona

I'm a student who has been using StudyKing for about a week. I've added **IB Physics** as a subject, uploaded a textbook PDF, created a study plan, and attended a couple of AI tutor lessons. Now I want to use the **Mentor** tab — the AI study companion — to get help, check my progress, schedule lessons, and stay motivated. I expect the Mentor to know who I am and understand my study context.

---

## Step 1: Opening the Mentor Tab for the First Time

I tap the **Mentor** tab (the sparkle icon, 4th tab in the bottom nav).

**What I expect:** A warm welcome that explains what the Mentor can do for me. A list of capabilities: "I can help you review your progress, schedule lessons, create study plans, and answer your questions."

**What I see:**
1. A brief loading spinner (CircularProgressIndicator) while `_initializeMentor()` runs
2. The screen transitions to show a welcome message from the AI Mentor listing its capabilities
3. A chat input at the bottom with "Ask the mentor anything..." placeholder

The welcome message (`mentor_screen.dart:109-124`) includes the mentor's name and a body listing capabilities. This is a static local message — it's NOT persisted to conversation memory (no `_memory.addAssistantMessage()` call), so it won't appear after app restart. But for first use, it's sufficient.

**Verdict (PASS):** The welcome message appears, clearly listing capabilities. The input is enabled. The first-time experience is adequate.

However, the empty state shown during initial load (`_buildEmptyState()`, lines 337-365) shows only a sparkle icon, the greeting, and a subtitle — this is visible only before the welcome message renders. It's appropriate.

---

## Step 2: Asking the Mentor a Question — Does It Know Who I Am?

I type: "How am I doing in my studies?" and send the message.

**What I expect:** The Mentor knows about my IB Physics subject, my study plan, my tutor lessons, my practice accuracy. It gives me a personalized summary.

**What actually happens:**

1. `_sendMessage()` (line 126) calls `_mentorService.chat("How am I doing in my studies?")`
2. Inside `chat()` (line 80), `_buildContextPrompt()` is called — this assembles a rich context string with 10+ data sources:
   - Total attempts, correct attempts, accuracy % (from `StudyProgressTracker.getOverallStats()`)
   - Topics studied, weekly activity, study time
   - Learning plan day/phase with adherence % (from `PlannerService`)
   - Active roadmaps with milestone progress
   - Pending actions awaiting decision
   - Upcoming lessons (next 3)
   - Weak topics needing attention (from `MasteryGraphService`)
   - Today's study minutes vs daily cap
   - Consecutive study days streak
   - Today's session count + late-night warnings

3. The context is prepended to the user message: `"Current student context:\n- Total attempts: 47\n- Correct attempts: 32\n..."` etc.
4. The LLM receives this context plus the mentor system prompt and the conversation history
5. The response streams back character by character

**Verdict (PASS/FALLBACK DISCUSSION):** The context prompt is comprehensive. The Mentor knows about my subjects, progress, plan, schedule, and weak areas. However, the context is only as current as the data at query time — it doesn't always reflect the very latest session if Hive hasn't synced.

**But there's a problem:** If I have NO data (new user, no subjects, no practice), the context is all zeros/empty. The mentor's response will be generic. There's no special handling for the "empty student" case — no guidance like "You haven't added any subjects yet. Go to the Subjects tab to get started!"

**Verdict (MINOR FAIL):** No "empty profile" handling. A new user who immediately goes to the Mentor tab will get generic advice rather than a clear "set up your profile first" prompt.

---

## Step 3: Getting a Progress Report

I tap the analytics icon (chart icon) in the app bar.

**What I expect:** A comprehensive progress report pops up showing my accuracy, study time, weak topics, badges, and recommendations.

**What actually happens:**

1. `_showProgressReport()` (line 380) calls `_mentorService.getProgressReport()`
2. `getProgressReport()` (mentor_service.dart:548-574) fetches:
   - Overall stats (attempts, accuracy, study time, weekly activity, topics studied)
   - Weak topics from mastery service
   - Recommendations from progress tracker
   - Badges from progress tracker
   - Completed lessons from tutor session repository

3. An `AlertDialog` appears with:
   - Accuracy progress bar (color-coded: green ≥70%, amber ≥40%, red <40%)
   - Total study time, weekly activity, completed lessons, topics studied
   - Weak topics (up to 3, with tappable buttons to navigate to practice)
   - Badges displayed as chips
   - Recommendations (up to 3)

**Problems:**

- **Weak topic navigation has empty subjectId:** Each weak topic `ListTile` has `onTap` that calls `Navigator.pushNamed(context, AppRoutes.practiceSession, arguments: PracticeSessionArgs(subjectId: '', topicId: topic.topicId))`. The `subjectId` is **always empty** (`''`). This means tapping a weak topic from the progress report navigates to a practice session with no subject — which will likely fail or show no questions.

- **No topic counts on stats:** The progress report shows `topicsStudied` as a number but the underlying data from `getOverallStats()` has `topicsStudied` — but there's no topic-by-topic breakdown (unlike the Dashboard which has `TopicBreakdownCard`).

- **Badges `getBadges()` returns `List<Map<String, dynamic>>`** — the structure depends on the tracker implementation. If the badge data structure is inconsistent, the chip display may show empty or malformed badge names.

**Verdict (MAJOR FAIL):** The "Practice weak topic" action in the progress report always passes empty `subjectId`, which will cause a broken practice session. The progress report is otherwise functional.

---

## Step 4: Scheduling a Lesson Through Conversation

Instead of going to the Planner, I type: "Can you schedule a physics lesson about forces for me?"

**What I expect:** The Mentor understands my intent, asks me to confirm the time, and schedules it. After confirming, I see the lesson in my schedule.

**What actually happens:**

1. My message "Can you schedule a physics lesson about forces for me?" is sent to `chat()`
2. The LLM generates a conversational response (something like "Sure! I'd be happy to schedule that for you.")
3. After streaming finishes, `_checkAndHandlePlanningIntent()` runs (line 420)
4. It detects the keyword "schedule" → calls `_handleScheduleIntent()`
5. Inside `_handleScheduleIntent()` (line 446):
   - `_extractTopic("Can you schedule a physics lesson about forces for me?")` extracts "forces" as the topic
   - Looks up "forces" in the topic repository (naive `contains` match)
   - **If a match is found:** Sets `topicId` and `subjectId`
   - **Proposes next-hour slot:** `DateTime.now().add(1 hour)` rounded to the hour
   - **Duration is hardcoded to 30 minutes**
   - Checks for scheduling conflicts
   - If no conflict: **Schedules the lesson immediately with NO user confirmation**
   - If conflict: Suggests the next free slot (but still no confirmation — it's a system message, not an interactive prompt)
   - Calls `_plannerService.scheduleLesson()` with the proposed time

6. The scheduling result is saved as a **system message** (invisible to the user in the current conversation) via `_memory.addSystemMessage()`

**Critical issues:**

- **No confirmation dialog:** The lesson is scheduled silently. The user never confirms the time or duration.
- **Hardcoded 30 minutes:** The scheduled duration is always 30 min, regardless of what the user might want.
- **Result is invisible:** The system message confirming the schedule is NOT shown in the chat UI because the UI filters to only `mentor` and `student` role messages. The user sees the LLM's conversational response ("Sure, let me help with that!") but NOT the scheduling result. They'd only discover the lesson was scheduled by checking the Planner.
- **The LLM response is generated BEFORE the scheduling happens:** The `chat()` stream yields the LLM response first, THEN `_checkAndHandlePlanningIntent()` runs. So the LLM's response cannot reference the scheduling outcome (whether it succeeded or failed). The user sees a generic "I'll help you schedule that" without any actual result.

**Verdict (BLOCKER FAIL):** Scheduling through conversation happens silently without user confirmation. The scheduled lesson duration is always 30 min (unconfigurable). The scheduling result is invisible in the chat UI. The LLM response is decoupled from the scheduling outcome, so the user gets a generic "I'll help" message but no actual feedback.

---

## Step 5: Checking If My Mentor Conversation Persists

I close the app and reopen it, then navigate to the Mentor tab.

**What I expect:** My previous conversation is restored. I see the messages I exchanged with the Mentor yesterday.

**What actually happens:**
1. `_initializeMentor()` runs again
2. `_memory.loadFromRepository()` loads all stored messages for key `'mentor_$studentId'` from Hive
3. The history is filtered for `mentor` and `student` roles only
4. Since the history is non-empty (from yesterday's conversation), `_sendWelcomeMessage()` is skipped
5. My previous messages are displayed

The welcome message from Step 1 is NOT restored (it was never persisted). But my actual conversation history persists correctly.

**Verdict (PASS):** Conversation history persists across app restarts. The welcome message is correctly shown only on first use.

---

## Step 6: The Mentor's Wellbeing Check — Does It Notice I'm Overworking?

I've been studying for 5 hours straight today. I open the Mentor tab.

**What I expect:** The Mentor notices my overwork and suggests I take a break. Maybe a warning message or a nudge.

**What actually happens:**

The `checkWellbeingAndGenerateNudges()` method (mentor_service.dart:343-418) exists and:
- Checks if daily study minutes exceed the daily cap
- Detects late-night study sessions
- Checks for at-risk questions needing revision
- Celebrates study streaks
- Detects inactivity (48h+)

**But this method is NEVER called from the MentorScreen.** It's not part of the initialization flow or the chat flow. The only way it would fire is if called externally (e.g., by the `EngagementScheduler`).

However, `_buildContextPrompt()` (line 103) does include wellbeing-relevant data in the context fed to the LLM:
- If daily cap exceeded: adds `"WARNING: Daily study cap exceeded"` (line 176-177)
- If late-night sessions detected: adds `"WARNING: late-night study detected"` (line 195-197)
- If 7+ day streak: adds congratulations (line 183-184)

So the LLM *could* respond to overwork based on the context prompt — but it depends entirely on whether the LLM chooses to mention it. There's no guarantee the LLM will proactively address overwork.

**Verdict (MAJOR FAIL):** The dedicated `checkWellbeingAndGenerateNudges()` method with proper nudge generation logic is completely disconnected from the Mentor tab. The only wellbeing signal reaching the user depends on the LLM's discretion via the context prompt. Nudge records are never created during normal mentor usage.

---

## Step 7: Suggesting My Next Study Action — The Hidden Feature

After chatting, I expect the Mentor to suggest what I should do next — "You should review weak topics in Physics" or "Time for your scheduled lesson."

**What I expect:** A "suggested next action" chip or card prominently displayed.

**What actually happens:**

The `suggestNextAction()` method (mentor_service.dart:576-599) exists and returns a `MentorAction` with a recommendation based on progress data. It handles three cases:
- Has recommendations: returns the first recommendation
- No subjects: prompts to set up
- Otherwise: generic encouragement

**But `suggestNextAction()` is NEVER called from the MentorScreen.** The `MentorAction` model is defined but the UI has no component that displays it. The method is dead code — fully implemented but unreachable.

The `suggestReschedule()` method (line 601-647) similarly exists but is never called from the screen.

**Verdict (MAJOR FAIL):** `suggestNextAction()` and `suggestReschedule()` are fully implemented in the service layer but have zero UI connections on the Mentor screen. Dead code.

---

## Step 8: Chatting with No Configured API Key

I clear my API key in Settings and open the Mentor tab.

**What I expect:** A clear error message saying the AI service isn't configured, with a direct path to fix it.

**What actually happens:**

1. `_initializeMentor()` runs
2. `ref.read(llmServiceProvider)` succeeds (the provider doesn't fail even with empty key)
3. `MentorService(...)` construction succeeds
4. `_mentorService.initialize()` succeeds
5. `_isInitialized = true` — the input is **enabled**
6. I type a message and send it
7. `_mentorService.chat(text)` → `_llmService.chatStream()` is called
8. Inside `LlmService.chatStream()`, if `config.apiKey.isEmpty`, the stream yields nothing and returns — **no error, no data**
9. `buffer.toString()` is empty
10. The chat bubble shows an **empty mentor response** — just nothing visible
11. The catch block at line 186 doesn't fire because the stream completed without error

So the UX is: I send a message, the loading spinner shows briefly, and then... empty bubble. No error. No guidance. Just silence.

The `ApiKeyBanner` (main.dart:371-374) shows at the top of the entire app if the API key is missing. But within the Mentor tab, the experience of a missing API key is a silent empty response.

**Verdict (MAJOR FAIL):** When the API key is missing, the mentor chat silently produces empty responses with no user-visible error. The catch block doesn't fire because the empty stream completes "successfully."

---

## Step 9: The Plan Intent — Mentor Suggesting a Study Plan

I type: "I want to create a 90-day study plan for IB Chemistry."

**What I expect:** The Mentor helps me create a study plan, or at least guides me to the Planner.

**What actually happens:**

1. `_checkAndHandlePlanningIntent()` detects "plan" keyword
2. `_handlePlanIntent()` (line 535) fires
3. It parses the days with regex: `RegExp(r'(\d+)\s*days?')` → extracts "90"
4. It adds a system message: `l10n.mentorPlanDaysPrompt(90)` — a localized prompt telling the user how to create a plan
5. But this system message is INVISIBLE to the user (same problem as Step 4 — system messages don't render in the chat UI)

The LLM response that already streamed probably handled the plan request conversationally. But the Mentor-specific plan handling (days extraction, system message) happens after and is invisible.

**Verdict (MAJOR FAIL):** Plan intent handling results are invisible. The system message with plan instructions is never shown to the user. The only visible output is whatever the LLM decided to say in its initial response.

---

## Step 10: Cross-Tab State — Does the Mentor Update When I Change Tabs?

I'm on the Mentor tab, switch to the Dashboard to check something, then switch back.

**What I expect:** The Mentor tab preserves its state (messages, scroll position).

**What actually happens:** The `MainScreen` uses separate `TabNavigator` instances per tab (main.dart). Each tab maintains its own navigation stack. The Mentor widget is preserved via `Offstage` + `TickerMode` — it's hidden but not destroyed when I switch tabs. The conversation state, scroll position, and messages are all preserved.

**Verdict (PASS):** Tab state preservation works correctly for the Mentor screen.

---

## Step 11: Long Conversations — Memory Truncation Behavior

I've been chatting with the Mentor for a while. Well past 50 exchanges.

**What I expect:** The Mentor remembers recent context but older messages are summarized or removed gracefully.

**What actually happens:** `ConversationMemory` has `maxTurns: 50` (mentor_service.dart:68). When messages exceed `50 * 2 = 100`, the oldest are removed from the in-memory list (conversation_memory.dart:29-31). **But Hive records are not cleaned up** — the repository retains all messages forever. The memory truncation only affects what's sent to the LLM, not what's stored.

In the UI, `_initializeMentor()` loads ALL messages from Hive (line 80-84). If a user has been chatting for months, the entire history is loaded and displayed, but only the most recent 50 turns are fed to the LLM for context.

There's no UI indication that memory truncation has occurred — no "Conversation history trimmed" message or summary of what was removed.

**Verdict (MINOR FAIL):** Hive records grow unboundedly. Old messages are hidden from the LLM but still loaded and displayed in the UI. No user-facing indication of truncation.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Welcome message introduces Mentor capabilities | Static welcome with capabilities listed | PASS |
| Mentor knows my context and gives personalized advice | 10+ data sources in context prompt — comprehensive | PASS |
| Empty/new user gets guidance to set up profile | Context is all zeros; no special "empty profile" handling | FAIL (MINOR) |
| Progress report's "Practice weak topic" navigates correctly | subjectId is always empty string — broken navigation | FAIL (MAJOR) |
| Scheduling through conversation asks for confirmation | Lesson scheduled silently — no user confirmation dialog | FAIL (BLOCKER) |
| Scheduled duration is configurable through chat | Hardcoded 30 minutes regardless of user intent | FAIL (MAJOR) |
| Scheduling result appears in chat | System message invisible — user never sees confirmation | FAIL (BLOCKER) |
| Wellbeing nudges fire during mentor interaction | `checkWellbeingAndGenerateNudges()` never called from MentorScreen | FAIL (MAJOR) |
| Next action suggestion is shown in UI | `suggestNextAction()` implemented but never called | FAIL (MAJOR) |
| `suggestReschedule()` available through mentor UI | Implemented in service but no UI connection | FAIL (MAJOR) |
| Missing API key shows clear error in mentor chat | Empty response — silent failure, no visible error | FAIL (MAJOR) |
| Plan intent handling provides visible guidance | System message with plan prompt invisible to user | FAIL (MAJOR) |
| Conversation persists across app restart | Persisted to Hive correctly | PASS |
| Tab switching preserves mentor state | `Offstage` + TabNavigator preserves state | PASS |
| Memory truncation is communicated to user | Old messages hidden from LLM but no user notification | FAIL (MINOR) |
| Hive records are cleaned up for old conversations | Hive retains all messages forever — unbounded growth | FAIL (MINOR) |
