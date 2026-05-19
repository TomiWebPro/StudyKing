# Dry-Run Usability Validation Report

**Generated:** 2026-05-19
**Scenario:** `scenario_ai_provider_failures_recovery.md`
**Persona:** A student with two weeks of usage whose AI provider (OpenRouter) goes down. Needs to diagnose failures, switch to a backup provider (Ollama), and recover from failed operations.

---

## Summary of Findings

| Step | Scenario Expectation | Status | Severity |
|---|---|---|---|
| 1 | Tutor timeouts with clear error when provider down | Tutor streaming errors NOT caught — unhandled exception locks UI | BLOCKER |
| 6 | HTTP status codes (401, 429, 404) produce specific user messages | No HTTP status code parsing anywhere; `ExceptionType` enum is dead code | BLOCKER |
| 9 | Rate limiting is detected and handled | No client-side rate limiting; 429 not parsed — only 403 string matched | BLOCKER |
| 12 | Automatic failover to backup provider on connection failure | No fallback/backup provider concept exists | BLOCKER |
| 2 | Mentor shows clear error with retry option when provider down | Error caught and displayed, but NO retry button for failed messages | MAJOR |
| 4 | Provider switching auto-confirms and preserves model selection | Model only cleared on save, no confirmation dialog, shallow test | MAJOR |
| 5 | Test Connection verifies chat completions and model availability | Only tests `/models` endpoint, not actual chat; doesn't verify model name | MAJOR |
| 7 | Failed operations can be retried without data loss | Tutor: no retry, `_isSending` stuck. Mentor: must retype. Task retry loses context | MAJOR |
| 8 | Mid-stream errors preserve partial responses | Partial content NOT saved to memory on failure; lost on error | MAJOR |
| 11 | Different providers per feature | Single global `LlmService` — no per-feature provider config | MAJOR |
| 10 | Provider config survives restart (no race conditions) | In-memory providers reset to defaults on cold restart; depends on init order | PARTIAL |
| 3 | Settings tiles show error history and provider health | No "last error" or health status on AI config tiles | PARTIAL |

---

## BLOCKER Findings

### B1: Tutor Streaming Errors Crash Silently — UI Locks Up

**Files:** `lib/features/teaching/presentation/tutor_screen.dart:180-197`

**What happens:** The `_sendMessage()` method uses `await for (final chunk in _manager!.sendMessage(text))` with NO try-catch block. If the LLM stream throws (timeout, network error, provider down), the exception propagates unhandled. `_isSending` stays `true` permanently, disabling the input. The user cannot send another message, retry, or interact with the tutor screen. They must pop the screen and restart.

Compare to the Mentor screen (`lib/features/mentor/presentation/mentor_screen.dart:249-262`) which DOES catch the error, replace the message with error text, and re-enable input.

**Acceptance criteria:**
- `_sendMessage()` in `tutor_screen.dart` must wrap the stream iteration in try-catch
- On catch: replace the incomplete assistant message with a localized error string (e.g., `l10n.errorWithResponse`)
- Set `_isSending = false` so the user can retry
- Show a retry action (button or inline chip) for the failed message
- Log the error for debugging

---

### B2: No HTTP Status Code Parsing — All Errors Are Generic

**Files:**
- `lib/core/services/llm/llm_chat_service.dart:210-248` (`_streamOpenRouter`), `321-354` (`_streamOllama`), `425-463` (`_streamOpenAI`)
- `lib/core/services/llm/llm_chat_service.dart:170` (`_callOpenRouter`), `278` (`_callOllama`), `386` (`_callOpenAI`)
- `lib/core/errors/exceptions.dart:6` (`ExceptionType` enum)

**What happens:** The streaming methods have NO HTTP status code checking whatsoever — they directly read the response stream and any HTTP error manifests as a generic exception. Non-streaming methods only check `statusCode == 200` vs everything else, returning `Result.failure('ProviderName API Error: ${response.body}')`.

The `ExceptionType` enum (line 6 of `exceptions.dart`) defines `apiAuth`, `apiRateLimit`, `apiNotFound`, `apiInternalServer`, but NOT ONE of these types is ever set by the LLM service. The error classification system is completely disconnected from the actual error-producing code.

**Specific failures:**
- 401 Unauthorized (expired/invalid key) → generic "API Error" → no "update your API key" prompt
- 429 Too Many Requests (rate limited) → generic "API Error" → no backoff suggestion
- 404 Model Not Found → generic "API Error" → no "check model name" guidance
- 5xx Server Error → generic "API Error" → no "provider down, try again later"

**Acceptance criteria:**
- `LlmService` must parse HTTP status codes from non-streaming responses and yield typed errors
- Streaming methods must check the initial HTTP response status before reading the stream
- Map 401 → `ExceptionType.apiAuth` with message "API key is invalid or expired. Update in Settings."
- Map 429 → `ExceptionType.apiRateLimit` with message "Too many requests. Wait and try again."
- Map 404 → `ExceptionType.apiNotFound` with message "Model not found. Check model name in Settings."
- Map 5xx → `ExceptionType.apiInternalServer` with message "Provider experiencing issues. Try again later or switch providers."
- All other errors → `ExceptionType.apiError` with the raw message

---

### B3: No Rate Limiting Detection or Handling — 429 Invisible

**Files:**
- `lib/core/services/llm/llm_chat_service.dart` (entire file — no 429 handling)
- `lib/core/errors/handlers.dart:168-174` (rate limit detection maps "403"/"forbidden", NOT 429)
- No client-side rate limiting anywhere

**What happens:** HTTP 429 (Too Many Requests) is the standard rate limit response from OpenRouter, OpenAI, and most API providers. The app has zero handling for this status code:
1. No client-side throttling (no request queue, no leaky bucket, no minimum interval enforcement)
2. The error classification maps "403" and "forbidden" (incorrectly) to `apiRateLimit` but completely misses "429"
3. A real 429 response falls through to the generic error path
4. Users can hammer the API as fast as they can type, triggering server-side rate limits with no warning

**Acceptance criteria:**
- Add client-side request throttling: minimum 500ms between chat requests from the same screen
- Parse 429 status code in `LlmService` → `ExceptionType.apiRateLimit`
- Show `errorApiRateLimit` message with `retryAfterWait` action
- Extract `Retry-After` header from 429 response and display countdown if available
- Remove the incorrect 403→rateLimit mapping, or keep it as a secondary check alongside proper 429 handling

---

### B4: No Provider Fallback / Failover Mechanism

**Files:**  
- `lib/core/providers/llm_providers.dart:19-34` (single `LlmService`, single `LlmConfiguration`)
- `lib/features/settings/presentation/api_config_screen.dart` (no backup/secondary provider UI)
- No "backup provider" concept in any model, provider, or service

**What happens:** The app has a single `LlmService` with a single `LlmConfiguration`. When the provider fails, there is zero fallback behavior:
- No automatic retry with a different provider
- No prompt: "Your provider is down. Switch to Ollama (local)?"
- No "backup provider" configuration field
- User must manually go to Settings, change provider, enter new config, test, and return

For a student mid-lesson, this is catastrophic — the tutor session is aborted with no recovery path.

**Acceptance criteria:**
- Add `backupProvider`, `backupApiKey`, `backupBaseUrl`, `backupModel` fields to configuration
- Add backup provider UI in `ApiConfigScreen` (e.g., "Fallback Provider" section with same dropdown+fields)
- On streaming failure in Tutor/Mentor, show dialog: "Primary provider failed. Switch to [backup]?"
- Automatic failover: on 5xx/timeout, try backup provider with a status indicator
- Persist backup config in Hive alongside primary config

---

## MAJOR Findings

### M1: Mentor Failed Messages Have No Retry Button

**Files:** `lib/features/mentor/presentation/mentor_screen.dart:249-262`

**What happens:** When `_sendMessage()` catches a streaming error, it replaces the incomplete message with `l10n.errorWithResponse`. The input is re-enabled so the user can type a new message. But there's no retry button on the failed message — the user has to manually re-type their question.

**Acceptance criteria:**
- Add a "Retry" button (icon or chip) to failed mentor messages
- Tapping retry calls `_sendMessage()` with the original user message text
- Failed messages show a distinguishing style (e.g., red-tinted background, error icon)

---

### M2: Test Connection Only Tests `/models` Endpoint, Not Chat

**Files:** `lib/features/settings/presentation/api_config_screen.dart:111-164`

**What happens:** `_testConnection()` makes a GET request to `<baseUrl>/models` with the API key. A 200 response only proves that the endpoint is reachable and the key has read access. It does NOT verify:
1. The selected model exists on this provider
2. The model supports chat completions
3. The provider can actually generate responses
4. The API key has write/chat permissions (some keys may be read-only)

A connection test could succeed but the first chat request could fail.

**Acceptance criteria:**
- Send an actual lightweight chat completion request (e.g., "Reply with OK") instead of or in addition to the `/models` check
- Verify that the selected model name returns a valid response
- Show the model's response time and first-token latency
- If the model name is empty when testing, prompt user to select one first

---

### M3: Provider Switching Doesn't Clear Model — Stale Model Survives

**Files:** `lib/features/settings/presentation/api_config_screen.dart:321-336`

**What happens:** When the user switches from `openRouter` to `ollama` in the provider dropdown, the base URL auto-populates with the new default. But the `selectedModel` field is NOT cleared — it retains the previous model name (e.g., `chatgpt-4o-latest`). The user would need to manually notice and change it. The model IS cleared on save (`_saveKeys()` sets it to `''` at line 75), but not on the visual dropdpown switch.

**Acceptance criteria:**
- Clear `selectedModel` when the provider dropdown is changed by the user
- Show a hint: "Model will be cleared when provider changes. Select a model for [new provider]."
- OR: Fetch available models automatically on provider switch (already exists as `_showAiModelSelection`)

---

### M4: No Per-Feature Provider Configuration

**Files:** `lib/core/providers/llm_providers.dart:19-34`

**What happens:** All AI features (Tutor, Mentor, exercise evaluator, lesson planner, summary generator, content pipeline) share a single `LlmService` with one `LlmConfiguration`. The user cannot, for example, use OpenRouter (powerful, cloud) for tutor lessons and Ollama (fast, local) for Mentor chat. This limits flexibility and optimization.

**Acceptance criteria (optional enhancement):**
- Allow per-feature provider override (e.g., "Tutor uses: OpenRouter", "Mentor uses: Ollama")
- Default to the global provider with per-feature opt-out
- Store per-feature overrides in Hive `settings` box

---

### M5: Partial Responses Lost on Mid-Stream Error

**Files:**
- `lib/features/teaching/services/conversation_manager.dart:170-200` (buffer not saved on error)
- `lib/features/mentor/services/mentor_service.dart:129-189` (context not preserved on error)

**What happens:** During streaming, chunks are accumulated in a `buffer` and yielded to the UI in real-time. But `addAssistantMessage(buffer.toString())` is only called AFTER the stream completes successfully (conversation_manager.dart:192). If the stream fails mid-way:
- The accumulated buffer is lost — it was rendered in UI but never saved to memory
- The user sees partial text, then an error, then the partial text disappears
- On next message, the conversation includes the user's original message but not the partial assistant response
- Mentor: error message replaces partial content entirely

**Acceptance criteria:**
- On mid-stream error, save the accumulated partial response to conversation memory before showing the error
- Preserve partial content in the chat bubble (show what was received, append error indicator)
- Add a visual indicator: 🤖 "Response interrupted after [N] characters"

---

### M6: Task Retry Loses All Context

**Files:** `lib/core/services/llm_task_manager.dart:209-214`

**What happens:** `retryTask(taskId)` creates a brand new task with the same `feature` and `modelId` but carries over NO data, context, messages, or payload from the original failed task. The old task remains in the list with `failed` status. The new task starts as `queued`. So retrying a "generate lesson plan" task creates a new "generate lesson plan" task, but with no knowledge of WHICH subject, topic, or what the original request was.

**Acceptance criteria:**
- `retryTask()` should accept an optional `context` parameter (payload/messages from original request)
- OR: tasks should store their input payload/context so retry can reproduce it
- Show "Retrying task [name]" progress in the task manager UI

---

## PARTIAL Findings

### P1: Configuration Persistence Depends on Initialization Order

**Files:**
- `lib/core/providers/app_providers.dart:129-135` (in-memory providers with defaults)
- `lib/core/providers/llm_providers.dart:19-34` (watches in-memory providers)
- `lib/features/settings/presentation/settings_screen.dart` (reads `settingsProvider` for display)

**What happens:** The `apiKeyProvider`, `apiBaseUrlProvider`, `selectedModelProvider`, and `llmProviderProvider` are simple `StateProvider`s initialized with defaults (empty key, `openRouter`, default URL, empty model). They get their actual persisted values when a screen explicitly reads from `settingsProvider` and writes to them. If `llmServiceProvider` is read (and thus the `LlmService` created) before the persisted settings have been loaded into these state providers, the service starts with defaults (empty key, wrong URL, wrong model). The API config screen then corrects this on its first build.

**Acceptance criteria:**
- Initialize providers from persisted settings eagerly (at app startup in `main.dart`, before any screen renders)
- Add a provider like `ref.onInit(...)` or use `ProviderScope` with overrides from persisted settings
- Ensure `llmServiceProvider` is never constructed with empty/default config before settings are loaded

---

### P2: Settings Tiles Don't Show Error History or Health Status

**Files:** `lib/features/settings/presentation/settings_screen.dart:179-187`

**What happens:** The AI Configuration section shows:
- "API Keys: Configured" (just presence check, not validity)
- "AI Model: [model name]" (no indication if the model is working)
- "Request Timeout: [seconds]" (just the configured value)
- "AI Task Monitor: [count]" (only count, no health status)

There is no "Last Error" field, no "Provider Health" indicator, no way to see if the current configuration has been tested recently or has been failing.

**Acceptance criteria:**
- Show a health indicator (green/yellow/red dot) next to the provider name based on recent success/failure ratio
- Show "Last tested: [timestamp]" for the connection test
- Show "Last error: [message]" if the last LLM call failed
- Store LLM health metrics in Hive for persistence across restarts

---

## Code Map

| File | Lines | Relevance |
|---|---|---|
| `lib/core/services/llm/llm_chat_service.dart` | 1-493 | Core LLM streaming, no timeouts, no status parsing |
| `lib/features/teaching/services/conversation_manager.dart` | 170-200 | No try-catch on stream, partial content lost on error |
| `lib/features/teaching/presentation/tutor_screen.dart` | 180-197 | NO error handling — UI locks up on stream failure |
| `lib/features/mentor/presentation/mentor_screen.dart` | 249-262 | Error caught, message replaced, NO retry button |
| `lib/features/mentor/services/mentor_service.dart` | 129-189 | No try-catch on chat stream |
| `lib/features/settings/presentation/api_config_screen.dart` | 111-164 | Test connects to `/models` only, not chat endpoints |
| `lib/features/settings/presentation/api_config_screen.dart` | 298-346 | Provider dropdown, model NOT cleared on switch |
| `lib/features/settings/presentation/settings_screen.dart` | 179-187 | AI Config tiles — no health/error display |
| `lib/core/providers/llm_providers.dart` | 19-34 | Single `LlmService`, single global config |
| `lib/core/providers/app_providers.dart` | 129-135 | In-memory providers, defaults risk race condition |
| `lib/core/errors/exceptions.dart` | 6 | `ExceptionType` enum — dead code, never set by LlmService |
| `lib/core/errors/handlers.dart` | 168-174 | Rate limit maps 403/forbidden, misses 429 |
| `lib/core/constants/timeouts.dart` | 12-17 | Timeout constants defined but never wired into HTTP calls |
| `lib/core/services/llm_task_manager.dart` | 209-214 | `retryTask()` loses all payload/context |

---

## Conclusion

The AI provider failure handling has **4 BLOCKER** issues that would prevent a user from recovering when their provider goes down. The most critical is B1 (tutor streaming errors crash silently), followed by B2 (no HTTP status code parsing = all errors are generic), B3 (no rate limiting handling), and B4 (no provider fallback).

The codebase has the right architectural pieces (`ExceptionType` enum, `ErrorHandler` UI, `LlmTaskManager`, localization strings) but they are disconnected from each other. The `LlmService` produces raw exceptions, the `ErrorHandler` expects typed `AppException`s, and the bridge (`convertToAppException`) only matches string patterns for 403 — missing 401, 429, 404, and 5xx entirely.
