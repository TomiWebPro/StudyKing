# AI Provider Failures & Error Recovery — Remaining Issues

**Source:** `dry-run-test/scenario_ai_provider_failures_recovery.md` (deleted — 91.7% complete)

**Validator:** Third-party independent code trace (2026-05-20)

**Decision:** Scenario deleted (>80% threshold). Two PARTIAL items remain.

---

## Remaining Issues

### Issue 1: Rate-limiting throttle has no user-facing feedback

**Step:** 9 (Rate limiting)

**Status:** PARTIAL

**What's done:**
- `TokenBucket` class with per-user buckets (`llm_chat_service.dart:64-95`)
- `_throttle()` sets `_lastThrottleWasActive`, exposed via `wasThrottleActive` getter (`llm_chat_service.dart:129`)
- `conversation_input.dart:41-48` UI-side 100ms debounce

**What's missing:**
- `wasThrottleActive` is exposed from `ConversationManager` (`conversation_manager.dart:285`) but **never consumed by any UI widget**
- No "Please wait..." or rate-limit indicator shown to the user when the client-side throttle is active
- User sends messages and they're silently delayed without explanation

**Fix required:**
Expose `wasThrottleActive` to the UI (e.g., via a state variable in `TutorScreen`/`MentorScreen`) and show a transient indicator (e.g., small text or icon) when messages are being throttled.

---

### Issue 2: Race condition on startup + plain-text API key storage

**Step:** 10 (Config persistence)

**Status:** PARTIAL

**What's done:**
- Hive fields in `SettingsBox` for `apiKey`(0), `llmProviderName`(23), backup fields (27-30)
- `main.dart:319-348` `addPostFrameCallback` restores provider + backup config
- `llm_providers.dart:27-50` creates `LlmConfiguration` with all fields including backup

**What's missing:**

1. **Race condition** — `app_providers.dart:136-142` initializes providers with default/empty values:
   ```dart
   final apiKeyProvider = StateProvider<String>((ref) => '');
   final llmProviderProvider = StateProvider<LlmProvider>((ref) => LlmProvider.openRouter);
   ```
   Values are synced in `main.dart:323-348` inside `addPostFrameCallback` which runs AFTER the first frame. Any AI screen mounted before this callback sees stale/empty config — e.g., `apiKey=''`, `llmProvider=openRouter`. This creates a transient window where AI calls could fail with "API key is empty".

2. **Plain-text API key storage** — `SettingsBox.apiKey` (Hive field 0) stores the API key as plain text. No `flutter_secure_storage` or platform-level encryption (`Keychain`/`Keystore`) is used.

**Fix required:**
- Add an async initialization gate: e.g., a `FutureProvider` that resolves after the Hive config is loaded into Riverpod providers. All AI-dependent screens should `ref.watch` this provider and show a loading state until config is ready.
- Migrate API key storage to `flutter_secure_storage` or at minimum use Hive's encryption (AES key from platform keystore). Wire the secure storage read into the provider initialization chain.

---

## Deleted Scenario Summary

| Metric | Value |
|---|---|
| Steps COMPLETED | 10/12 (83%) |
| Steps PARTIAL | 2/12 (17%) |
| Steps NOT_COMPLETED | 0/12 (0%) |
| **Overall score** | **91.7%** |
| **Decision** | Scenario deleted (>80% complete) |
