# Scenario: Student on low-end device, low battery, intermittent network

**Persona:** Student with constrained device / network

## Goal

> "I'm on an old phone with 15% battery and a spotty connection. When I open
> the app, it tells me it's deferring background prep because my battery is
> low. When I ask the mentor a question and the API times out, it retries
> before failing over to Ollama (local). If I'm completely offline, it tells me
> I can still use Ollama but heavy prep is paused."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. Student has <20% battery, not charging | Heavy prep tasks (embeddings, question variants, lesson generation) should defer until charging or battery improves. | `lib/core/services/system_monitor_service.dart:20` — `SystemMonitorService.canRunHeavyPrepNow` checks battery + CPU + saver. `lib/core/services/llm_agent/idle_executor.dart:43` — `IdleExecutor` consults `systemMonitor` before heavy tasks. Wired at `lib/core/providers/llm_providers.dart:28`. | PASS |
| 2. Student is on a poor/unstable network | When an LLM call times out or gets a 503, the system should retry with exponential backoff on the SAME provider before failing over to backup. | `lib/core/services/llm/llm_chat_service.dart:67-103` — `LlmRetryConfig` class exists with default max 3 attempts, 1s→2s→4s backoff. `lib/core/services/llm/llm_chat_service.dart:247-351` — `_streamWithFallback` and `_callWithFallback` retry transient errors (`_isTransientError`) with `_computeBackoffDelay`. | PASS |
| 3. Student is completely offline with Ollama configured as backup | The app should still function using the local Ollama provider; heavy prep defers, but light chat works. | `lib/core/constants/app_api_config.dart:24` — Ollama config requires no API key (`backupApiKey: null` in B4 example, line 25). `llm_chat_service.dart:180-234` — B4 failover to backup. `agent_must_read.md` §2: "supports both local and remote AI providers." | PASS |
| 4. Student switches to offline mode mid-conversation | The mentor should inform the student: "You're offline — I'll switch to local Ollama. Heavy prep is paused." | `lib/features/mentor/services/mentor_context_builder.dart:211-234` — `_buildDeviceStatusLine` injects device status (battery, CPU, network) into the mentor context. Provider config also injected at `mentor_context_builder.dart:358-366` (`_buildProviderStatusLine`). `system_monitor_service.dart:41` — `networkType` reports 'wifi', 'cellular', or `null`. | PASS |
| 5. Student on low-end device tries to upload a large PDF | The system should warn about large files on constrained devices and offer chunked/queued ingestion. | `lib/features/ingestion/` — ingestion exists. No device-aware file-size ceiling check. No open issue filed for this specific gap. No device-aware ingestion guidance. | FAIL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| No specific offline tool needed — system handles it via config | N/A | Ollama backup provider configured in `LlmConfiguration`. |
| `ingest_pdf_to_kb` (handles large files with device awareness) | YES but not device-aware | `ingest_pdf_to_kb_tool.dart:9` — registered. No device constraints check. |

**Tool audit result:** No missing agent tools — all needed functionality is handled by system-level config + context injection, not agent tools.

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Offline / low-battery / CPU status | YES | `mentor_context_builder.dart:211-234` — `_buildDeviceStatusLine` injects device status line. `system_monitor_service.dart:20` provides `canRunHeavyPrepNow`, `batteryLevel`, `cpuLoad`, `networkType`. |
| Provider configuration (OpenRouter vs Ollama) | YES | `lib/features/mentor/services/mentor_context_builder.dart:358-366` — `_buildProviderStatusLine` injects provider config into mentor context. |
| File-size ceiling awareness | NO | No ingestion tool checks file size against device constraints. No open issue filed for this specific gap. |

**Gap:** Provider configuration is now injected into the mentor context
(`mentor_context_builder.dart:358-366`), and device status is injected
(`mentor_context_builder.dart:211-234`). The remaining gap is file-size
ceiling awareness — no agent tool checks file size against device constraints.
(no open issue filed for this specific gap)

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — device status messages use `l10n` strings. |
| Actionability (one clear next action) | PARTIAL — offline mode informs but does not offer one clear next action (switch to Ollama vs. wait vs. use cached). |
| Confirmation discipline | PASS — provider switches require explicit Settings confirmation, never silent. |

## Validation Results

Traced against code at:
`lib/core/services/system_monitor_service.dart:20-55`,
`lib/core/services/llm_agent/idle_executor.dart:43-80`,
`lib/core/services/llm/llm_chat_service.dart:67-103,247-351`,
`lib/features/mentor/services/mentor_context_builder.dart:211-234,358-366`,
`lib/core/constants/app_api_config.dart:24-29`.

- Step 1: PASS — `SystemMonitorService.canRunHeavyPrepNow` + `IdleExecutor` deferral wired.
- Step 2: PASS — `LlmRetryConfig` + `_isTransientError` + backoff retry implemented.
- Step 3: PASS — Ollama backup works without API key (B4 failover).
- Step 4: PASS — device status + provider config injected into mentor context (mentor_context_builder.dart:211-234,358-366).
- Step 5: FAIL — no file-size ceiling or device-aware ingestion guidance.

Tool audit: no missing agent tools for this scenario.
RESULT: all needed tools available (0 missing).
Context audit: provider config + device status now injected (resolved); file-size ceiling awareness still NO (no open issue filed for this specific gap).
**Last re-traced:** 2026-10-20 against commit `dc19534` (`scenario_validation_test.dart` Steps 1–5, `system_monitor_service.dart:20`, `mentor_context_builder.dart:211-234,358-366`).
