# LLM Integration

## Overview

StudyKing is **model-agnostic** and supports multiple AI providers. The LLM layer handles chat completions, streaming, agent-based tool use, token tracking, and task management.

## Supported Providers

| Provider | Type | Streaming | Backup Failover |
|---|---|---|---|
| **OpenRouter** | Remote (recommended) | Yes | Yes |
| **OpenAI** | Remote (direct) | Yes | Yes |
| **Ollama** | Local | Yes | Yes |
| **Custom** | OpenAI-compatible API | Yes | Yes |

### Fallback / Failover (B4)

Each `LlmConfiguration` supports a backup provider. If the primary provider returns a server error (5xx, timeout, connection failure), the system automatically retries using the backup configuration.

```dart
final config = LlmConfiguration(
  provider: LlmProvider.openRouter,
  apiKey: primaryKey,
  backupProvider: LlmProvider.ollama,
  backupApiKey: null,          // Local, no key needed
  backupBaseUrl: 'http://localhost:11434',
  backupModel: 'llama3',
);
```

## Core Services

### LlmService (`lib/core/services/llm/llm_chat_service.dart`)

The central LLM communication service. Supports both streaming and non-streaming chat.

- **Rate limiting:** Token-bucket per-user (20 tokens/sec) + 500ms minimum interval
- **Error mapping:** HTTP status codes → user-friendly error messages
- **Task tracking:** Integrates with `LlmTaskManager` for visibility
- **Usage metering:** Records token usage via `LlmUsageMeter`

```dart
// Stream a response
final stream = llmService.chatStream(
  message: 'Explain Newton\'s laws',
  modelId: 'gpt-4o',
  systemPrompt: 'You are a physics tutor...',
  feature: 'teaching',
);

// Non-streaming
final result = await llmService.chat(
  message: 'Summarize this topic',
  modelId: 'claude-3-haiku',
  feature: 'mentor',
);
```

### LlmTaskManager (`lib/core/services/llm_task_manager.dart`)

Provides visibility into active LLM operations. Used by the **LLM Task Manager Screen** to display running tasks, completed tasks, and failures.

- `createTask(feature, modelId)` → unique task ID
- `startTask(taskId)`, `completeTask(...)`, `failTask(...)` → lifecycle tracking

### LlmUsageMeter (`lib/core/services/llm_usage_meter.dart`)

Records token consumption per feature, model, and timestamp. Useful for cost tracking and analytics.

### EmbeddingService (`lib/core/services/llm/llm_embeddings_service.dart`)

Generates vector embeddings from text using any supported provider. Useful for semantic search and RAG.

```dart
// Generate embedding for a text
final result = await embeddingService.embed(
  text: 'What is Newton\'s first law?',
  modelId: 'text-embedding-3-small',
);
```

### ModelListingService (`lib/core/services/llm/llm_model_service.dart`)

Fetches available models from the configured provider. Supports OpenRouter, OpenAI, and Ollama model listing endpoints.

```dart
final result = await modelService.fetchAvailableModels();
final model = modelService.getModelById('gpt-4o', models);
```

## Agent System (`lib/core/services/llm_agent/`)

For complex multi-step AI interactions, StudyKing uses an agent pattern:

| Component | File | Purpose |
|---|---|---|
| `LlmAgent` | `llm_agent.dart` | Top-level agent orchestrator with loop control |
| `AgentLoop` | `agent_loop.dart` | Main execution loop: think → act → observe |
| `AgentTool` | `agent_tool.dart` | Abstract tool definition (name, description, execute) |
| `AgentMemoryStore` | `agent_memory.dart` | Persistent key-value store for student facts, session summaries, and student profiles |
| `IdleExecutor` | `idle_executor.dart` | Proactive agent triggers without user input |

### Mentor Tools (`lib/features/mentor/services/tools/`)

The mentor mode uses concrete tool implementations:

| Tool | Purpose |
|---|---|
| `CreatePlanTool` | Create or modify study plans |
| `GenerateLessonBlocksTool` | Generate lesson content blocks |
| `GetStudentStatsTool` | Retrieve student performance stats |
| `GetWeakTopicsTool` | Identify topics needing attention |
| `ScheduleLessonTool` | Book or reschedule lessons |
| `SearchQuestionsTool` | Search the question bank |

## Configuration

AI configuration flows through Riverpod providers (`lib/core/providers/llm_providers.dart`):

- `apiKeyProvider` — Primary API key
- `apiBaseUrlProvider` — Custom base URL
- `selectedModelProvider` — Active model ID
- `llmProviderProvider` — Active provider enum
- `backupLlmProviderProvider` — Backup provider enum
- `backupApiKeyProvider` / `backupBaseUrlProvider` / `backupModelProvider` — Backup config

These are populated from saved settings during app initialization and writable through the Settings > API Config screen.
