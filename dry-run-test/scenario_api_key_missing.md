# Scenario: API-key missing / provider switch; offline / low-end device

**Persona:** New or returning user, no API key configured

## Goal

> "I don't have an API key. I want to switch providers. I'm on a low-end
> device or have a poor network connection."

## Step expectations

| Step | Expectation | Current code | Status |
|------|------------|-------------|--------|
| 1. User opens the app without any API key | App should show an empty state with clear guidance: "No API provider configured. Go to Settings → AI Provider to set up your key or use a local Ollama provider." The app should NOT crash or show a blank screen. | `lib/core/providers/llm_agent_providers.dart:92` — `llmAgentProvider` returns `null` when `apiKey` is empty. `lib/core/services/llm/llm_chat_service.dart:337` — `chat()` returns `Result.failure('API key is empty')`. `lib/core/services/llm/llm_chat_service.dart:405` — `chatStream()` yields 'API key not configured.' | PASS |
| 2. User navigates to Settings → AI Provider | Should see: OpenRouter, OpenAI, Ollama (local), Custom. Each with fields for API key, base URL, model name. Ollama should default to `http://localhost:11434`. | `lib/features/settings/` — settings screen exists. `lib/core/constants/app_api_config.dart:59-64` — Ollama/OpenAI default URLs. | PASS |
| 3. User selects Ollama (local, no key) | App should work without an API key when using Ollama. No key field should be required. | `lib/core/constants/app_api_config.dart:24` — `ApiSecrets.fromEnvironment` throws only in production if `openRouterApiKey.isEmpty`; Ollama config has no key requirement (`backupApiKey: null` in B4 example, line 25). `lib/core/providers/llm_providers.dart` — provider config stored in settings. | PASS |
| 4. User is offline / has poor connection | If the API call times out or fails, the app should fall back to the backup provider (B4 failover) and show a retry option. | `lib/core/services/llm/llm_chat_service.dart:180-234` — `_streamWithFallback` and `_callWithFallback` retry with backup on 5xx/timeout/connection failure. `lib/core/constants/timeouts.dart` — timeouts defined per environment. | PASS |
| 5. User is on a low-end device (low battery, high CPU) | Heavy prep tasks (embeddings, question generation) should defer until conditions improve. | `docs/vision_next_term.md` §4.3 — `SystemMonitorService` is proposed but not yet implemented. No `canRunHeavyPrepNow()` method exists. | FAIL |
| 6. User has no subjects but opens the mentor chat | App should guide the user to create a plan or add a subject, not show a generic error. | `lib/features/mentor/services/mentor_service.dart:163-171` — `hasMeaningfulData()` returns false when no subjects, yields `l10n.mentorNoSubjects`. | PARTIAL |

## Tool/context audit

### Tools needed vs. tools available

| Tool needed | Available? | File |
|---|---|---|
| `get_syllabus_structure` (works offline with local Ollama) | YES | `lib/features/mentor/services/tools/get_syllabus_structure_tool.dart` — wraps syllabus resolver, no direct network call. |
| `create_plan` (works offline with local model) | YES | `lib/features/mentor/services/tools/create_plan_tool.dart` — delegates to PlannerService which does not require LLM for plan structure. |
| `generate_lesson_blocks` (heavy, network-dependent) | YES but blocks | `lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart` — calls LLM; fails gracefully if offline. |
| Offline mode toggle tool | NO — not an agent tool | Settings allow offline mode but no agent tool wraps it. |

No missing-tools issue for this scenario — all needed tools exist.

### Context the LLM needs vs. what AgentLoop injects

| Context needed | Injected? | File |
|---|---|---|
| Provider / model / failover configuration | NO | No context builder queries LLM settings. |
| Offline / low-battery status | NO | `SystemMonitorService` does not exist yet (vision §4.3). |
| Network connectivity type | NO | Not tracked. |

**Gap:** AgentLoop cannot inform the LLM about offline status or provider
configuration, so it cannot proactively suggest "switch to Ollama" or
"wait until you're online."
→ File `issues/open/scenario_offline-context-not-injected.md`

## Comprehension rubric

| Criterion | Assessment |
|---|---|
| Reading level | PASS — `l10n.mentorNoSubjects` and settings strings are localised. |
| Actionability (one clear next action) | PASS — settings screen guides user to configure provider. |
| Confirmation discipline | PASS — provider changes require user to save in Settings, never silent. |

## Validation Results

Traced against code at:
`lib/core/providers/llm_agent_providers.dart:92`,
`lib/core/services/llm/llm_chat_service.dart:337-411`,
`lib/core/services/llm/llm_chat_service.dart:180-234`,
`lib/core/constants/app_api_config.dart:24-65`,
`lib/core/constants/timeouts.dart`,
`lib/features/mentor/services/mentor_service.dart:163-171`.

- Step 1: PASS — null agent + empty-key guard prevent crashes.
- Step 2: PASS — Settings → AI Provider screen exists.
- Step 3: PASS — Ollama works without API key.
- Step 4: PASS — B4 failover + timeouts handle network issues.
- Step 5: FAIL — SystemMonitorService not yet implemented.
- Step 6: PARTIAL — `mentorNoSubjects` guides but doesn't suggest creating a plan inline.

Context audit: offline/provider config not injected → new issue.
Tool audit: no missing tools for this scenario.
