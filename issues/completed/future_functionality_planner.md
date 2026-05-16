# Build a Configurable Runtime AI Provider Switching System

## Context

The codebase implements three AI providers (OpenRouter, Ollama, OpenAI) in `lib/core/services/llm/llm_chat_service.dart` — all three have complete `chat()` and `chatStream()` implementations. The settings UI (`lib/features/settings/presentation/api_config_screen.dart`) already exposes provider selection, base URL, and model name fields. However, `lib/core/providers/llm_providers.dart:20-22` **hardcodes** `LlmProvider.openRouter` and ignores the user's configured `apiBaseUrl` entirely:

```dart
final llmServiceProvider = Provider<LlmService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  ...
  return LlmService(
    config: LlmConfiguration(
      provider: LlmProvider.openRouter,  // <-- hardcoded
      apiKey: apiKey,
    ),
    ...
  );
});
```

This means:
- A user who configures Ollama (running at `http://localhost:11434`) or OpenAI in settings will select a provider and enter a base URL, but the actual LLM service will always call OpenRouter.
- The `apiBaseUrlProvider` and `selectedModelProvider` are defined in `lib/core/providers/app_providers.dart:206-208` but never consumed by `llmServiceProvider`.
- Eight LLM-consuming features (mentor, teaching/tutor, quickguide, question generation, planner, etc.) are all affected.

## Impact

| Area | Current State | Target State |
|---|---|---|
| Settings UX | User can select provider + URL + model | User selection is respected at runtime |
| Ollama users | Always broken (calls OpenRouter URL) | Works with local/remote Ollama |
| OpenAI API-key users | Always broken (uses OpenRouter) | Works with native OpenAI endpoints |
| Developer experience | Cannot test locally without OpenRouter key | Can test with Ollama on localhost |
| Testability | All LLM tests depend on OpenRouter | Tests can use Ollama or a mock provider |

## Affected Files

| File | Role |
|---|---|
| `lib/core/providers/llm_providers.dart:15-27` | **Root cause** — hardcoded provider, ignores `apiBaseUrlProvider` |
| `lib/core/providers/app_providers.dart:206-208` | Defines `apiBaseUrlProvider` + `selectedModelProvider` — defined but unused by `llmServiceProvider` |
| `lib/core/services/llm/llm_chat_service.dart:10-12` | `LlmProvider` enum — correct, needs no changes |
| `lib/core/services/llm/llm_chat_service.dart:12-24` | `LlmConfiguration` — has `baseUrl` field, currently unused by provider wiring |
| `lib/features/settings/presentation/api_config_screen.dart` | Provider/base-url/model selection UI — wiring is correct on UI side |
| `lib/features/teaching/services/tutor_service.dart:64` | Hardcodes `openai/gpt-4o-mini` model — should use the user's selected model |
| `lib/features/teaching/presentation/tutor_screen.dart:65-66` | Also hardcodes model string |
| `lib/features/mentor/providers/mentor_providers.dart` | Likely has similar hardcoding |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | Likely has similar hardcoding |

## Rationale

1. **Local-first development requirement** (from `agent_must_read.md`): "The platform should support both local and remote AI providers, including systems such as OpenRouter, Ollama, and other compatible providers. It should remain model-agnostic."

2. **Engineering quality**: The three provider implementations represent significant work. Leaving them unreachable behind a hardcoded constant wastes that investment and creates a misleading UX where settings appear functional but are silently ignored.

3. **Developer experience**: Currently, every developer needs an OpenRouter API key to run any LLM-dependent feature. Supporting Ollama locally would eliminate this barrier and make the app fully functional offline.

4. **Test isolation**: With provider selection, tests can inject a test-only provider or Ollama endpoint without mocking network calls, aligning with the existing "hand-written fakes" convention from `AGENTS.md`.

## Acceptance Criteria

1. `llmServiceProvider` reads `apiKeyProvider`, `apiBaseUrlProvider`, and a **new `llmProviderConfigProvider`** (or reused `selectedModelProvider`) to construct `LlmConfiguration` with the user's chosen provider, base URL, and model ID.

2. When no provider is selected in settings, the system defaults to `LlmProvider.openRouter` with `openRouterBaseUrlString` (backward-compatible).

3. All existing LLM consumers (mentor, tutor, quickguide, question generation) use `llmServiceProvider` from the ref rather than constructing their own `LlmService` or hardcoding model IDs.

4. A settings UI integration test verifies that toggling provider → Ollama + URL → `http://localhost:11434` is reflected in the `LlmService` instance obtained from the provider.

5. The model ID hardcoded in `lib/features/teaching/presentation/tutor_screen.dart:65` (`'openai/gpt-4o-mini'`) is replaced by `ref.watch(selectedModelProvider)` with a fallback to a sensible default.

6. Hive migration: if a user has no `selectedModel` saved, the system should provide a reasonable default per provider (e.g. `gemini-2.0-flash` for OpenRouter, `llama3` for Ollama, `gpt-4o-mini` for OpenAI).

7. Zero analysis warnings are introduced by this change.

## Additional Considerations

- **Token usage tracking** (`lib/core/services/llm_usage_meter.dart`) already works per provider — no changes needed.
- **Error reporting** should distinguish "provider not configured" (no API key for OpenRouter/OpenAI) from "network error" to give users clear guidance.
- **Future-proofing**: The provider selection model should be extensible (e.g., via a registry pattern) so that new providers (Anthropic, Groq, etc.) can be added without modifying the selection switch.
