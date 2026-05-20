# Dry-Run Validation: AI Provider Failures & Error Recovery

**Overall completion: 70.8% (8.5/12)** — below 80% threshold. Issues remain in 6 steps.

---

## Step 1: Tutor Timeout Detection (PARTIAL)

**Status:** PARTIAL — 4 outstanding issues.

| # | Issue | Location | Severity |
|---|---|---|---|
| 1.1 | No `.timeout()` wired to any `http.post()` or `http.send()` call in `LlmService`. `Timeouts.openRouterTimeoutProduction` (45s) defined but never applied. | `lib/core/services/llm/llm_chat_service.dart:387,443,508,563` — none use `.timeout()` | High |
| 1.2 | Provider-specific context lost at UI — `_sendText()` catch block shows generic `l10n.errorWithResponse` instead of e.g. "OpenRouter timed out" | `lib/features/teaching/presentation/tutor_screen.dart:218-227` | Medium |
| 1.3 | `_sendInitialGreeting()` silently swallows stream errors (empty catch) | `lib/features/teaching/presentation/tutor_screen.dart:186-188` | High |
| 1.4 | `_pickImage()` has no try-catch around `processImage()` — crashes widget tree on stream failure | `lib/features/teaching/presentation/tutor_screen.dart:280-283` | High |

**Fix requirements:**
- Add `.timeout(Timeouts.openRouterTimeoutProduction)` to all `http.post()` and `http.Client.send()` calls in `llm_chat_service.dart`
- Change `_sendText()` error handling to propagate provider name/error type to the user-visible message
- Add error handling in `_sendInitialGreeting()` — show error state instead of silent swallow
- Wrap `_manager!.processImage()` stream in try-catch in `_pickImage()`

---

## Step 7: Recovery/Retry of Failed Operations (PARTIAL)

**Status:** PARTIAL — 3 outstanding issues.

| # | Issue | Location | Severity |
|---|---|---|---|
| 7.1 | Session status changed to `SessionStatus.inProgress` BEFORE LLM call in `startLesson()`. On LLM failure, no rollback — `cancelActiveSession()` only called on explicit "Discard and Exit", not on error. | `lib/features/teaching/services/tutor_service.dart:114-118` marks `inProgress`, lines 151-153 generate lesson plan | High |
| 7.2 | No way to dismiss/clear individual failed mentor chat bubbles — only `clearConversation()` which wipes everything | `lib/features/mentor/presentation/mentor_screen.dart` (no dismiss action on failed bubbles) | Low |
| 7.3 | Retry works but leaves corrupted session behind if user navigates away after a failed tutor init | `lib/features/teaching/services/tutor_service.dart` (no cleanup on navigation after error) | Medium |

**Fix requirements:**
- Add rollback in `startLesson()`: if lesson plan generation or LLM init fails, restore scheduled session to `planned` status and remove the orphaned `inProgress` tutor session
- Add a dismiss button (X) next to failed mentor chat bubbles that removes the failed message
- Hook into `PopScope` / `_handleBackNavigation` to clean up failed sessions when user exits after error

---

## Step 8: Mid-Stream Failures (PARTIAL)

**Status:** PARTIAL — 3 outstanding issues.

| # | Issue | Location | Severity |
|---|---|---|---|
| 8.1 | `processImage()` has NO try-catch — any stream failure crashes the widget tree | `lib/features/teaching/services/conversation_manager.dart:240-269` | High |
| 8.2 | No explicit "Response interrupted" message — shows generic `errorWithResponse` instead | `lib/features/teaching/presentation/tutor_screen.dart:221-222` | Medium |
| 8.3 | No Cancel option for mid-stream failures — only Retry button available | `lib/features/teaching/presentation/tutor_screen.dart:202-207` (retry only) | Low |

**Fix requirements:**
- Add try-catch around `processImage()` stream in `conversation_manager.dart`
- Show "Response interrupted — [Retry] [Cancel]" instead of generic error text
- Add a Cancel action alongside Retry in the error banner

---

## Step 9: Rate Limiting (PARTIAL)

**Status:** PARTIAL — 3 outstanding issues.

| # | Issue | Location | Severity |
|---|---|---|---|
| 9.1 | No user-facing feedback when client-side throttle (`_throttle()`) delays the request — silently waits 500ms | `lib/core/services/llm/llm_chat_service.dart:103-109` | Low |
| 9.2 | No per-user quota tracking — all users share the same throttle interval | Not implemented anywhere | Medium |
| 9.3 | No token-bucket / sliding-window RateLimiter — just a simple `_minCallInterval` timestamp check | `lib/core/services/llm/llm_chat_service.dart:76-77` | Low |

**Fix requirements:**
- Show a subtle indicator ("Please wait...") when client-side throttle is active
- Add per-user quota tracking with configurable limits (or remove the expectation since 500ms throttle is reasonable)
- Consider replacing simple throttle with a proper token-bucket algorithm

---

## Step 10: Config Persistence / Race Condition (PARTIAL)

**Status:** PARTIAL — 2 outstanding issues.

| # | Issue | Location | Severity |
|---|---|---|---|
| 10.1 | **Race condition:** `llmServiceProvider` initializes with `apiKey=''`, `llmProvider=openRouter`, `selectedModel=''`. Values synced from Hive via `addPostFrameCallback` AFTER first frame. Any AI screen mounted before the callback sees stale/empty config. | `lib/core/providers/llm_providers.dart:19-34` (defaults); `lib/main.dart:314-328` (async restore) | High |
| 10.2 | API key stored in plain text Hive (`SettingsBox.apiKey`, field 0) — no secure storage (flutter_secure_storage or similar) | `lib/features/settings/data/models/settings_box.dart:15-16` | Medium |

**Fix requirements:**
- Move provider config initialization from `addPostFrameCallback` to `ProviderScope` overrides or use `FutureProvider` so that AI-dependent providers resolve AFTER config is loaded
- Migrate API key to flutter_secure_storage (or encrypt in Hive)

---

## Step 12: Provider Fallback / Failover (NOT_COMPLETED)

**Status:** NOT_COMPLETED — 5 dead-code issues. This is the most significant gap.

| # | Issue | Location | Severity |
|---|---|---|---|
| 12.1 | `LlmService` has backup fields (`backupProvider`, `backupApiKey`, `backupBaseUrl`, `backupModel`) and methods (`_streamWithFallback()`, `_callWithFallback()`) but **no production code populates them** | `lib/core/services/llm/llm_chat_service.dart:23-38, 112-245` | High |
| 12.2 | `llmServiceProvider` creates `LlmConfiguration` with **zero backup fields** — only `provider`, `apiKey`, `baseUrl` are set | `lib/core/providers/llm_providers.dart:26-30` | High |
| 12.3 | No UI anywhere to configure a backup provider — `api_config_screen.dart` has no backup section | `lib/features/settings/presentation/api_config_screen.dart` (entire file) | High |
| 12.4 | No persistence for backup config in `SettingsBox` — no Hive fields for backup provider/key/url/model | `lib/features/settings/data/models/settings_box.dart` (all fields) | High |
| 12.5 | `copyWithBackup()` is never called anywhere in the codebase | `lib/core/services/llm/llm_chat_service.dart:44-61` | High |

**Fix requirements:**
- Add Hive fields for backup config in `SettingsBox` (`backupLlmProviderName`, `backupApiKey`, `backupBaseUrl`, `backupModel`)
- Add backup provider section in `api_config_screen.dart` with dropdown, API key field, base URL field, model field
- Populate backup fields in `llmServiceProvider` when creating `LlmConfiguration`
- Add Riverpod provider(s) for backup config
- Test `_streamWithFallback()` and `_callWithFallback()` with actual backup config

---

## Summary

| Metric | Value |
|---|---|
| Steps COMPLETED | 6/12 (50%) |
| Steps PARTIAL | 5/12 (42%) |
| Steps NOT_COMPLETED | 1/12 (8%) |
| **Overall score** | **70.8%** |
| **Hardest gaps** | Provider fallback (dead code), race condition on startup, missing timeouts on all HTTP calls |
