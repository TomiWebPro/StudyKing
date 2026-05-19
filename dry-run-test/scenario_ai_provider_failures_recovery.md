# Dry-Run Scenario: AI Provider Failures & Error Recovery — When the LLM Goes Down

## Persona

I'm a student who has been using StudyKing for about two weeks. I have an API key configured for OpenRouter, I've attended a few tutor lessons, used the Mentor, and practiced questions. Today, OpenRouter is having an outage. I need to understand what's happening, switch to a backup provider (Ollama local), and recover from failed operations. I also want to know how the app handles rate limits, invalid API keys, and provider incompatibilities.

I expect the app to:
1. Detect and clearly report AI service failures (not silently fail)
2. Help me diagnose the problem (is it my key, the provider, or the model?)
3. Let me easily switch to a different provider/backup
4. Preserve any work/data from the failed operation
5. Recover gracefully when the service comes back

---

## Step 1: I Open the App and Something Is Wrong — AI Features Are Broken

I open the app to attend my scheduled tutor lesson. I tap "Start Tutoring" on my daily plan card (Atomic Structure). The TutorScreen starts loading... and the `CircularProgressIndicator` spins. After 30+ seconds, I see one of two things:
- A timeout error message, OR
- The lesson never loads and I'm stuck on a spinner

**What I expect:** Within a few seconds, the app should either:
- Show a clear error: "Unable to connect to AI service. [Provider Name] appears to be down. Check Settings → AI Configuration to troubleshoot."
- Time out gracefully with a "Retry" or "Cancel" button

**What might happen (depending on implementation):**
- The `LlmService.chatStream()` has no timeout — it relies on the HTTP client's default timeout, which for OpenRouter could be 60+ seconds. If the connection hangs (no response, no error), the user stares at a spinner for a long time.
- The tutor screen shows an error toast/dialog — but does it explain WHY? "An error occurred" vs "OpenRouter API timed out" are very different messages.
- The `ConversationManager._streamResponse()` yields error events, but the final error state may just show "Failed to get response" in the chat bubble.

**Questions to answer in the code:**
1. Does the TutorScreen have a timeout?
2. Are LLM errors propagated with provider-specific context?
3. Can I retry without restarting the whole screen?

---

## Step 2: Trying the Mentor Instead — Another Failure Mode

I give up on the tutor lesson and try the Mentor tab. I type: "What should I study today?" and send it.

**What I expect:** If the Mentor also can't reach OpenRouter, I expect a similar clear error. Maybe the Mentor knows why the tutor failed and explains it.

**What might happen:** The Mentor screen has a more sophisticated error handling path:
- `_sendMessage()` at `mentor_screen.dart:126` calls `_mentorService.chat(text)`
- Inside `chat()`, if `_llmService.chatStream(apiKey: config.apiKey)` fails:
  - Does it catch the error?
  - Does the error bubble up to a user-visible message in the chat UI?
  - Or does it silently produce an empty response?

If the Mentor silently shows an empty response (as noted in `scenario_mentor_study_companion.md` for the missing API key case), the user will be doubly frustrated — the tutor timed out, and the mentor said nothing.

---

## Step 3: Diagnosing the Problem — Finding the Settings Screen

I want to check my AI configuration. I remember there was a Settings tab.

**What I expect:** A clear path: Settings → AI Configuration → see the provider status, test the connection, maybe see error logs.

**What I find:** The Settings screen has an "AI Model" section with the current provider name and model displayed. Tapping it opens a dialog where I can change models. But:
- Is there a "Test Connection" button?
- Does it show the last error from this provider?
- Can I see provider-specific documentation (API endpoint URL)?

---

## Step 4: Switching Providers — From OpenRouter to Ollama (Local)

I have Ollama running on my laptop with llama3. I want to switch from OpenRouter to Ollama.

**What I expect:** I go to Settings → AI Configuration → select a different provider. I enter the Ollama endpoint URL (http://192.168.1.100:11434), change the model name, and test the connection.

**What actually happens (I need to trace the code):**
- The provider selection is likely a dropdown or radio group
- Different providers may have different configuration fields (base URL for Ollama vs. API key for OpenRouter)
- Does the app remember multiple provider configurations, or is it one at a time?
- Does switching providers clear my configured model, or does the model persist?
- Is there a "Test Connection" flow that actually sends a test prompt?

---

## Step 5: Testing the New Provider — Does "Test Connection" Work?

I configure Ollama and tap "Test Connection."

**What I expect:** A spinner, then either "Connection successful! Model: llama3" or "Connection failed: Could not reach http://192.168.1.100:11434"

**What I need to trace:**
- The `LlmService.testConnection()` method exists at `llm_service.dart:72-80` — what does it actually test? Does it just check reachability or does it send a real inference request?
- Does the test result include timing information?
- What happens if the model name is wrong (e.g., "llama3" doesn't exist on the Ollama server)?

---

## Step 6: The Error Is My API Key — Invalid Key Handling

Turns out my OpenRouter API key expired. I want the app to tell me this — not just say "connection failed."

**What I expect:** The app distinguishes between:
- "Invalid API key (401 Unauthorized)" vs
- "Provider unavailable (connection refused/timeout)" vs
- "Model not found (404)" vs
- "Rate limited (429 Too Many Requests)"

Each should have a different user-facing message and suggested action.

**What I need to trace:**
- Does `LlmService` or `LlmClient` parse HTTP status codes?
- Are there error-type-specific messages?
- On 401, does it prompt the user to update their API key?
- On 429, does it suggest waiting or changing to a less busy model?

---

## Step 7: Recovery — Retrying Failed Operations

I fixed my API key and switched to a working model. Now I want to retry the operations that failed earlier.

**For the Tutor lesson that timed out:**
- I go to Planner → my scheduled lesson is still there with status "planned"
- I tap "Start Tutoring" again — does it work now? If not, what error do I see?
- Does the tutor remember I was trying to learn "Atomic Structure"?

**For the Mentor conversation:**
- I open the Mentor tab. My previous message "What should I study today?" is still visible
- But the empty/error response is also visible — an empty bubble with no content
- I can send a new message, but the empty bubble from the failed attempt is distracting

**What I need to trace:**
- Can failed mentor responses be retried or dismissed?
- Is there a way to clear failed messages from the chat UI?
- Does the planner lesson survive a failed tutor attempt without corruption?

---

## Step 8: Partial Failures — Mentor Response Starts Then Fails Mid-Stream

The LLM starts responding but fails halfway through (network issue, provider error, token limit exceeded).

**What I expect:** The partial response is shown (what we got so far), and a message says "Response interrupted. [Retry] [Cancel]"

**What I need to trace:**
- Does `_streamResponse()` in `conversation_manager.dart` handle mid-stream errors gracefully?
- Is the partial response preserved in the chat UI?
- Is there a retry mechanism for mid-stream failures?

---

## Step 9: Rate Limiting — I Sent Too Many Messages

I've been chatting with the Mentor aggressively, sending 20+ messages in quick succession. The provider rate-limits me.

**What I expect:** A clear message: "You're sending messages too quickly. Please wait a moment." or "API rate limit exceeded. Your plan allows X requests per minute."

**What I need to trace:**
- Does the app implement client-side rate limiting?
- Does the provider return 429, and if so, is it handled?
- Are there per-user quotas tracked anywhere?

---

## Step 10: Configuration Persistence — Does My Provider Choice Survive a Restart?

I switch to Ollama and verify it works. I close the app fully and reopen it.

**What I expect:** The app still uses Ollama. My provider config is not lost.

**What I need to trace:**
- Where is the provider/API config stored? Hive? Secure storage?
- What happens on app restart: is the saved config loaded before any AI calls are made?
- Is there a race condition where the app tries to use the old provider before loading the new config?

---

## Step 11: Mixed Providers — Different Features on Different Providers

I want to use OpenRouter (remote, powerful) for tutor lessons and Ollama (local, fast) for the Mentor chat. Can I configure different providers per feature?

**What I expect:** Either a per-feature provider selector, or the app uses one provider for everything and I accept the tradeoff.

**What I need to trace:**
- Is there a single `LlmConfig` for the whole app, or per-feature configs?
- Do the Tutor and Mentor use the same `llmServiceProvider` or different instances?
- Can the user set multiple provider configurations?

---

## Step 12: Provider Fallback — Automatic Failover

My Ollama server goes down mid-session. The tutor lesson is interrupted.

**What I expect:** The app detects the failure and asks: "The AI service is unavailable. Would you like to switch to your backup provider (OpenRouter) and continue?" Or at minimum, it shows a clear error with instructions to switch providers.

**What I need to trace:**
- Is there any fallback/failover mechanism?
- Does the app have a "backup provider" concept?
- On connection failure, does it try the current provider again, or does it surface the error immediately?

---

## Summary of Expectations

| Expectation | Description |
|---|---|
| 1 | AI service timeouts have a reasonable limit and show clear error messages |
| 2 | LLM errors are propagated with provider-specific context (not generic "error") |
| 3 | Mentor and Tutor failures are consistent in their error reporting |
| 4 | Provider switching UI exists with per-provider configuration fields |
| 5 | "Test Connection" actually tests the LLM and reports detailed results |
| 6 | HTTP status codes (401, 429, 404) are parsed into user-meaningful messages |
| 7 | Failed operations can be retried without data loss |
| 8 | Mid-stream failures preserve partial responses and offer retry |
| 9 | Rate limiting is handled on client side with user feedback |
| 10 | Provider config persists correctly across app restarts, no race conditions |
| 11 | Different providers can be configured per feature (optional) |
| 12 | Automatic failover to backup provider on connection failure |
