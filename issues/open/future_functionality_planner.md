# Future Functionality: Architecture Gaps, Redundancies, and High-Value Roadmap Opportunities

## Context

This issue identifies five high-value future functionality problems discovered during a codebase-wide inspection. These are not surface-level bugs — each represents a missing architectural capability, a design flaw that prevents scaling, or a redundant component that undermines the product vision from `agent_must_read.md`. The affected features span the QuickGuide, Teaching, Mentor, Practice, LLM integration, and Engagement systems.

---

## Issue 1: QuickGuide Is a Redundant Chat Shell — Should Be a Mode Launcher Only

### Summary

`lib/features/quickguide/presentation/quick_guide_screen.dart` (314 lines) is a **full-featured AI chat screen** with streaming, conversation memory, message list, input bar, suggested prompts, and clear-conversation. It is structurally **identical** to `mentor_screen.dart` (329 lines) and nearly identical to `tutor_screen.dart` (348 lines) — all three manage their own `List<ConversationMessage>`, `ScrollController`, `TextEditingController`, streaming state, and message rendering.

The only difference in QuickGuide is that it optionally renders a `ModeNavigationWidget` at the top, which contains buttons to navigate to the AI Tutor (`/tutor`) and Mentor (`/mentor`) routes. The chat below this navigation is a **generic AI chat** that duplicates the exact behavior of Mentor.

**The QuickGuide screen should be a thin landing/launcher that explains the app's modes and routes to them — not a full chat interface.**

### Evidence

| Component | QuickGuide | Mentor | Tutor |
|---|---|---|---|
| `TextEditingController` | `_textController` | `_textController` | `_textController` |
| `ScrollController` | `_scrollController` | `_scrollController` | `_scrollController` |
| `FocusNode` | `_inputFocusNode` | `_inputFocusNode` | `_inputFocusNode` |
| Message list state | `List<ConversationMessage> _messages` | `List<_ChatMessage> _messages` (wraps same model) | `manager!.messages` via `ConversationManager` |
| Streaming pattern | `buffer.write(chunk)` + `setState` replace placeholder | `buffer.write(chunk)` + `setState` replace placeholder | `buffer.write(chunk)` + `setState` replace placeholder (through manager) |
| Scroll to bottom | `_scrollToBottom()` (identical code) | `_scrollToBottom()` (identical code) | `_scrollToBottom()` (identical code) |
| Clear conversation | `_clearConversation()` | N/A (no clear) | N/A (lesson ends) |
| Suggested prompts | Yes (top 3) | No | No |
| Mode navigation | Yes (`ModeNavigationWidget`) | No | No |
| Voice/image input | No | No | Placeholder buttons with "Coming soon" |

The QuickGuide creates its own `ConversationMemory` and streams directly through `llmService.chatStream`. The Mentor screen does the same through `MentorService.chat()`. The Tutor screen does it through `ConversationManager.sendMessage()` — which itself wraps the same `llmService.chatStream`.

Three separate implementations of the same streaming chat pattern, each with its own state management.

### Architectural Impact

- **QuickGuide cannot route to Mentor** in a clean way — since both are full-screen chats, navigating to Mentor from QuickGuide means pushing a second chat screen on top of the first. The user ends up in a nested chat conversation.
- **Duplicate code**: All three screens have separate implementations of streaming message rendering (`ChatBubble` reuse is the only shared component), input handling, scroll management, and error handling.
- **Conceptual confusion**: New contributors must understand three different patterns for what is fundamentally "stream AI response into a chat bubble list."

### Recommendation

Strip QuickGuide down to a **mode-selection landing page** with the `ModeNavigationWidget` prominently displayed, quick-start cards for each mode (AI Tutor, Mentor, Practice, Planner), and optionally a small "try it out" single-turn input box. Remove the persistent chat history, stream management, and full `ConversationMemory`. If a lightweight chat is desired on the landing page, make it ephemeral (single Q&A, not a saved conversation) and reuse the shared chat widget pattern (see below).

### Affected Files

| File | Lines | Role |
|---|---|---|
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | 18–314 (entire screen) | Remove full chat — keep launcher UI |
| `lib/features/quickguide/presentation/widgets/mode_navigation_widget.dart` | 1–131 | Keep (mode cards) — move to shared widget library |
| `lib/features/quickguide/presentation/widgets/message_list_widget.dart` | 1–33 | Remove (duplicate of Tutor's chat bubble list) |
| `lib/features/quickguide/presentation/widgets/suggested_prompts_widget.dart` | 1–60 | Optionally keep for launcher |
| `lib/features/mentor/presentation/mentor_screen.dart` | 24–329 | Refactor to use shared chat widget |
| `lib/features/teaching/presentation/tutor_screen.dart` | 36–348 | Refactor ConversationManager to share chat widget |
| `lib/core/widgets/` | — | Add shared `ConversationView` widget (reusable chat + input + scroll) |

### Acceptance Criteria

1. QuickGuide screen is `<150 lines` — it primarily renders mode cards and app entry points, not a full chat conversation.
2. A shared `ConversationView` widget (or equivalent) lives in `lib/core/widgets/` and is used by both Mentor and Tutor screens, eliminating duplicated scroll/input/stream state management.
3. Removing QuickGuide's chat does not break any test that validates QuickGuide's core behavior (mode navigation, suggested prompts).
4. `dart analyze` passes with zero errors.

---

## Issue 2: LLM Service Has No Provider Abstraction — Model-Agnostic Vision Is Unreachable

### Summary

The `agent_must_read.md` (line 103) explicitly requires: *"The platform should support both local and remote AI providers, including systems such as OpenRouter, Ollama, and other compatible providers. It should remain model-agnostic."*

Current reality: `lib/core/services/llm/llm_chat_service.dart` defines `LlmService` which directly calls **one** HTTP-based chat completions API. The `modelId` parameter is an opaque string (always `'openai/gpt-4o-mini'` hardcoded everywhere). There is no:
- Provider registry or factory
- Provider-specific configuration (API URL, auth method, rate limits)
- Fallback chain (try provider A, fall back to B)
- Local model support (Ollama runs on localhost:11434, not OpenAI-compatible by default without a different client)
- Structured output parsing (response is raw `String`)
- Consistent error type hierarchy (HTTP errors, auth errors, rate limits, timeout — all swallowed)

The `llm_chat_service.dart` is a single file with ~300 lines. The `llm_model_service.dart` and `llm_embeddings_service.dart` are separate files that also instantiate their own HTTP clients. If a user wants to use Ollama for chat but OpenAI for embeddings, there is no shared configuration.

### Hardcoded `modelId` Locations

| File | Line | Value |
|---|---|---|
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | 27 | `'openai/gpt-4o-mini'` |
| `lib/features/teaching/services/tutor_service.dart` | 63 | `'openai/gpt-4o-mini'` |
| `lib/features/mentor/services/mentor_service.dart` | 67 | `'openai/gpt-4o-mini'` |
| `lib/features/lessons/providers/lesson_providers.dart` | 13 | `'openai/gpt-4o-mini'` |
| `lib/features/ingestion/services/content_pipeline.dart` | 63 | passed as parameter, no default config |
| `lib/core/services/question_generation_service.dart` | 68 (approx) | passed as parameter |
| `lib/features/practice/services/question_type_localizer.dart` | varies | passed as parameter |

### Impact

- **Every feature** that uses the LLM must be updated when adding a new provider
- No centralized cost tracking or token usage monitoring (the `LlmTaskManager` exists but is not connected to the actual streaming calls)
- No rate limiting — a burst of practice session question generations could hit API limits
- No offline fallback — if the network is down, every LLM feature silently returns an error
- The `api_config_screen.dart` allows configuring API keys but has no effect on provider selection at the service level

### Recommendation

Introduce an `LlmProvider` abstraction layer:

```
LlmProvider (abstract interface)
  ├── OpenAiProvider (handles OpenAI / OpenRouter)
  ├── OllamaProvider (handles local Ollama, different endpoint + format)
  └── FallbackProvider (wraps two+ providers, chains on failure)
```

`LlmService` becomes a facade that delegates to a configured `LlmProvider`. Each provider handles its own:
- Endpoint URL construction
- Auth header format
- Request/response schema
- Error handling (HTTP vs timeout vs auth)
- Streaming vs non-streaming

The `SettingsScreen` / `ApiConfigScreen` selects the active provider (with provider-specific config fields), not just a model ID string.

### Acceptance Criteria

1. `LlmProvider` abstract class defined in `lib/core/services/llm/providers/provider_interface.dart` with at minimum `chat()`, `chatStream()`, `embed()` methods.
2. `OpenAiProvider` implementation supporting the current OpenAI/OpenRouter API.
3. `OllamaProvider` implementation supporting local Ollama (localhost:11434 by default, configurable).
4. `LlmService` refactored to accept an `LlmProvider` via constructor injection (or Riverpod provider), not hardcoded HTTP calls.
5. All places that hardcode `'openai/gpt-4o-mini'` read the model ID from a central settings provider.
6. `LlmTaskManager` is integrated into the provider layer so every LLM call is tracked.
7. `dart analyze` passes; existing tests continue to pass (or are updated for the new interface).

---

## Issue 3: Tutor's `ConversationManager` Phase Machine Is Heuristic — Exercises Use Keyword Matching, Not AI Evaluation

### Summary

`lib/features/teaching/services/conversation_manager.dart` implements a phase-based state machine (`ConversationPhase`) that uses **naive keyword matching** to:
1. Detect when the LLM has given an exercise (`_detectExerciseRequest` — lines 257–271)
2. Evaluate whether the student's response was correct (`_evaluateExerciseResponse` — lines 228–255)
3. Adjust adaptive pace (lines 243–252)

**The LLM generates the exercise text, but keyword matching determines whether the answer was right.** This is a fundamental architectural flaw:

- **False positives**: "This is the **right** approach" contains `"right"` from `correctKeywords` → counted as correct
- **False negatives**: "I was **wrong** but now I understand it **correctly**" contains both → evaluated as incorrect because `isCorrect && !isIncorrect` fails
- **Silent default**: If the student responds "42", none of the ~20 keywords match → falls through to `_consecutiveIncorrect = 0` (treated as success)
- **LLM doesn't evaluate**: The LLM generates the exercise and then a separate heuristic evaluates it. The LLM could have explained why "42" is wrong in its response, but the keyword check overrides this.

The `agent_must_read.md` (line 42) says: *"guide problem solving rather than simply giving answers"* — keyword matching cannot distinguish between "I don't know" (help-seeking) and "I don't know" (genuine confusion). Both give an incorrect eval.

### Compare With Practice Session

The Practice feature (`lib/features/practice/presentation/practice_session_screen.dart`) uses `AnswerValidationService` from `lib/core/services/answer_validation_service.dart` — a proper comparison-based evaluator. The Tutor's exercise evaluation is orders of magnitude weaker despite being the same conceptual feature (ask question → evaluate answer).

### Recommendation

Replace the keyword-based `_evaluateExerciseResponse` with:
1. **LLM-based evaluation**: Pass the student's answer + the exercise question + markscheme (if available) to the LLM with a structured prompt asking it to evaluate correctness. Parse the structured output (e.g., `{"correct": true, "confidence": 0.9, "explanation": "..."}`).
2. **Phase transitions driven by LLM output**, not keyword matching. The `_buildTutorPrompt` already tells the LLM "Give the student a practice question" when in `exercise` phase — the LLM should also tell *us* what phase to transition to next.
3. **Remove keyword-based correctness tracking** from `ConversationManager`. Move to a structured output protocol: every tutor response includes a metadata field indicating exercise correctness, requested transition, etc.

Alternatively, at minimum: use the `AnswerValidationService` that the Practice feature already uses, instead of ad-hoc keyword matching.

### Affected Files

| File | Lines | Role |
|---|---|---|
| `lib/features/teaching/services/conversation_manager.dart` | 228–271 | `_evaluateExerciseResponse`, `_detectExerciseRequest` — replace both |
| `lib/features/teaching/services/conversation_manager.dart` | 36–41, 191–226 | Phase tracking in constructor + `_buildTutorPrompt` — extend with structured output |
| `lib/features/teaching/services/tutor_service.dart` | 88–98 | Mastery recording uses heuristic correctness — should use evaluated result |
| `test/features/teaching/services/conversation_manager_test.dart` | 193–318 | Keyword-based test cases — rewrite for structured evaluation |

### Acceptance Criteria

1. `_evaluateExerciseResponse` no longer uses keyword matching. Evaluation uses either (a) LLM-based structured output evaluation or (b) the canonical `AnswerValidationService`.
2. Phase transitions (`exercise → feedback → adaptiveReview/teaching`) are driven by evaluation result, not by coincidental keyword presence in student text.
3. No false-positive/negative evaluation for edge cases (a response containing both correct and incorrect keywords, a neutral answer, a numbers-only answer).
4. `adaptivePace` adjustments are based on actual evaluation accuracy, not keyword heuristics.
5. All existing tests pass; new tests cover the structured evaluation path.

---

## Issue 4: No Offline-First Architecture — Data Loss Risk and Poor UX Without Network

### Summary

StudyKing stores user data locally in Hive but **all high-value features require network access**:
- AI Tutor/Mentor streaming → requires LLM API endpoint
- Question generation → requires LLM API
- Content ingestion classification → requires LLM API
- Plan generation → requires LLM API

When the network is unavailable:
- QuickGuide, Mentor, and Tutor screens show `_fallbackResponse()` — a generic localized string
- Question generation silently fails
- The app has no "offline mode" indication
- No queue/retry mechanism for failed LLM calls

Additionally, StudyKing data is **only stored locally in Hive**. There is no:
- Cloud backup or sync
- Export/import of all data (the existing export only handles `StudySession`)
- Cross-device continuity

The `agent_must_read.md` (line 108) says: *"exportable progress"* — the current implementation exports only `StudySession` data (CSV/JSON/PDF). No export exists for subjects, topics, questions, mastery states, plans, roadmaps, or settings.

### Affected Workflows

| Workflow | Offline Behavior | Impact |
|---|---|---|
| AI Tutor lesson | Shows error message | Lesson cannot proceed |
| Mentor chat | Shows error message | No guidance available |
| Practice session | Works (questions are local) | ✅ Works offline |
| Content ingestion | Upload works; classification fails | Content stored but unclassified |
| Plan generation | Fails silently | No plan created |
| Question generation | Fails silently | No questions created |
| Data export | CSV/JSON/PDF work (local files) | ✅ Works offline |

### Recommendation

1. **Connectivity-aware UI**: Show a persistent banner when offline. Disable LLM-dependent features with a clear explanation ("Connect to the internet to start a lesson").
2. **Offline queue**: Add a `PendingLlmCall` repository (similar to `PendingActionRepository`) that queues LLM requests when offline and replays them when connectivity returns. Queue items appear in a "pending sync" section.
3. **Full data export**: Extend `SessionExportService` (or create `DataExportService`) to export all user data: subjects, topics, questions, mastery states, study plans, roadmaps, settings, and conversation history — as a single JSON archive. Support import for restore/migration.
4. **Graceful degradation**: Practice sessions and local question review should remain fully functional offline. The app should highlight what is available ("Practice your saved questions offline").
5. **Sync architecture** (future): Define a sync contract (last-modified timestamps on all Hive models, conflict resolution strategy) to support future cloud backup.

### Acceptance Criteria

1. A `ConnectivityService` (or `ref.watch(connectivityProvider)`) exposes network state to all features.
2. LLM-dependent features show clear "offline" state with explanation and disable interactive elements.
3. An offline queue persists pending LLM calls in Hive (`lib/core/data/models/pending_llm_call_model.dart`), with UI visibility in the LLM Task Manager screen.
4. `DataExportService` exports all user data as a single importable JSON archive.
5. Existing tests pass; new tests cover connectivity-aware UI rendering.
6. `dart analyze` passes.

---

## Issue 5: Engagement Scheduler Is Defined but Never Started — Proactive Nudges Are Dead Code

### Summary

`lib/core/services/engagement_scheduler.dart` (273 lines) defines a complete daily engagement system with:
- Overwork detection (nudge if >4 hours studied)
- Revision nudges (nudge if topic not practiced in 3+ days)
- Plan adjustment nudges (nudge if 3+ consecutive low-adherence days)
- Low-mastery warnings
- Weekly digest generation
- Nudge history storage in Hive

**This code is never instantiated or started anywhere in the app.** The `EngagementScheduler.init()` method, which sets up the daily timer, is never called. The `_sendNudgeNotifications()` method, which triggers local notifications, is never executed. The `EngagementNudgeRepository` stores nudges that are never created.

The `agent_must_read.md` (line 98) demands: *"The system should proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement."* — but this entire subsystem is dead code.

Additionally, `NotificationService` (`lib/core/services/notification_service.dart`) is defined but it is unclear if local notification permissions are ever requested or if notification channels are configured.

### Why This Exists

The `EngagementScheduler` requires `StudyProgressTracker`, `MasteryGraphService`, `PlanAdapter`, `FocusSessionService` — all of which have their own initialization dependencies. A circular or deferred initialization problem likely prevented it from being integrated. However, the `init()` method accepts these via constructor injection, so no circular dependency exists — it simply was never wired into the app's startup flow.

### Recommendation

1. **Wire `EngagementScheduler` into app startup**: Initialize it in `main.dart` or in a `ProviderScope.overrides` provider that starts the daily timer after all repositories are ready.
2. **Gate with settings**: Add a "Proactive nudges" toggle in Settings (default on) that controls whether the scheduler runs. Respect notification permission status.
3. **Add nudge history UI**: Create a small section in the notification drawer or dashboard that shows recent nudges from `EngagementNudgeRepository`.
4. **Test the scheduler**: Add an integration test that verifies `_sendNudgeNotifications` produces correct `EngagementNudgeModel` entries for a mock student with >4 hours of study, 3+ consecutive low-adherence days, and topics not practiced in 7+ days.

### Affected Files

| File | Lines | Role |
|---|---|---|
| `lib/core/services/engagement_scheduler.dart` | 1–273 (entire file) | Dead code — wire into startup |
| `lib/main.dart` | — | Add `EngagementScheduler.init()` call |
| `lib/core/services/notification_service.dart` | — | Verify notification permissions requested at startup |
| `lib/features/settings/presentation/settings_screen.dart` | — | Add "Proactive nudges" toggle |
| `test/core/services/engagement_scheduler_test.dart` | (new) | Integration tests for nudge generation |

### Acceptance Criteria

1. `EngagementScheduler.init()` is called during app startup (after repositories are initialized).
2. Daily nudges are actually shown (local notifications appear, nudge models are persisted).
3. Settings screen has a toggle to enable/disable proactive nudges.
4. Notification permissions are requested on first launch.
5. A test verifies that a student with >4 study hours receives an overwork nudge, a student with 3+ low-adherence days receives an adherence nudge, and a student with unpracticed topics receives a revision nudge.

---

## Summary of Impact and Priority

| Issue | Severity | Effort | Scope | Why Now |
|---|---|---|---|---|
| **1. QuickGuide/Mentor/Tutor chat redundancy** | Medium | Medium | 3 screens + new shared widget | Reduces 900+ lines, fixes confusing user entry flow |
| **2. LLM provider abstraction missing** | High | Large | Core LLM layer + all callers | Blocks every future LLM-dependent feature; required by product vision |
| **3. Heuristic keyword exercise evaluation** | High | Medium | ConversationManager + tests | Directly impacts teaching quality; students get wrong feedback |
| **4. No offline-first / no full export** | Medium | Large | Connectivity layer + queue + export | Data portability is a stated requirement; offline UX is broken |
| **5. Engagement scheduler is dead code** | Medium | Small | Startup wiring + settings toggle | Proactive engagement is a stated requirement; 273 lines doing nothing |

These five issues are independent and can be worked in parallel. Issue 2 (LLM provider abstraction) is the highest priority because it blocks support for Ollama/local models and is a prerequisite for any future AI feature work. Issue 3 (keyword evaluation) is the most user-facing — it directly degrades the core teaching experience for every student.
