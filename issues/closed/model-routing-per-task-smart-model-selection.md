# LLM Configuration: Add Task-Specific Model Routing for Cost and Performance Optimization

**Severity:** major
**Affected area:** Core — LLM Service / Configuration
**Reported by:** codebase audit

## Description

StudyKing currently uses a **single model ID** for all AI tasks. The same model is used for:
- Real-time tutor chat (needs low latency, good instruction following)
- Content summarization (needs large context window, cheaper since async)
- Question generation (needs high reasoning capability)
- OCR and transcription (needs multimodal/audio support)
- Classification (simple task, could use a cheap model)
- Mentor chat (needs good conversational ability)
- Exercise evaluation (needs careful grading capability)

This is both **wasteful and limiting**:
1. **Cost waste** — Using GPT-4 or Claude Opus for simple classification tasks costs 10-30x more than using Haiku or Llama 3.1 8B
2. **Latency waste** — A fast model (e.g., GPT-4o-mini, Llama 3.1 8B) could handle real-time chat while a slower, more capable model handles background processing
3. **Capability mismatch** — A text-only model cannot do OCR/transcription. The system should route multimodal tasks to multimodal models
4. **No offline adaptation** — Local models (Ollama) are slower but free. Remote models are faster but cost money. The optimal routing depends on the task and connectivity

## Expected behavior

The system should support task-specific model configuration:
- Tutor chat: fast, low-latency model
- Mentor chat: conversational model (may differ from tutor)
- Content classification: cheap, fast model
- Question generation: capable, high-reasoning model
- OCR/transcription: multimodal model only
- Summarization: large context window model
- Evaluation: balanced capability model
- Background tasks: cheapest acceptable model

## Actual behavior

A single model ID from Settings is used for everything. No task-specific routing exists.

## Code analysis

- `lib/core/providers/llm_providers.dart:15-50` — Single `selectedModelProvider` used for all features
- `lib/core/providers/llm_providers.dart:85-120` — `llmServiceProvider` creates single `LlmConfiguration` with one model
- `lib/features/mentor/providers/mentor_providers.dart:12-18` — `mentorModelIdProvider` just reads the global model
- `lib/features/teaching/providers/teaching_providers.dart:10-16` — Tutor reads the global model
- `lib/features/ingestion/services/content_pipeline.dart:195` — Pipeline reads `modelId` parameter (passed from global)
- `lib/core/services/llm/llm_chat_service.dart` — `LlmService` takes config with one model

## Suggested approach

1. **Create a `TaskModelConfig` data model**:
   ```dart
   class TaskModelConfig {
     String tutorModelId;      // Real-time teaching
     String mentorModelId;     // Mentor conversations
     String classificationModelId; // Topic classification (cheap)
     String generationModelId; // Question/lesson generation (capable)
     String summarizationModelId; // Content summarization (large context)
     String evaluationModelId; // Exercise grading
     String transcriptionModelId; // Audio/video (multimodal)
     bool useLocalForBackground; // Use Ollama for background tasks
   }
   ```

2. **Add a model routing UI in Settings** — A table or list where users can configure which model to use for each task, with smart defaults:
   - Tutor: `selectedModel` (the main model)
   - Mentor: `selectedModel`
   - Classification: auto-pick cheapest available
   - Background: `ollama/llama3.2` (if Ollama configured)
   - Transcription: auto-pick multimodal model

3. **Create a `modelRouterProvider`** that maps feature strings to model IDs:
   ```dart
   final modelRouterProvider = Provider<ModelRouter>((ref) {
     return ModelRouter(ref.watch(taskModelConfigProvider));
   });
   ```

4. **Update all consumers** to request model by task type instead of using a global model ID

5. **Add cost-per-task tracking** to `LlmUsageMeter` so users can see how much each task type costs

6. **Smart fallback** — If the configured model for a task doesn't support the required capability (e.g., no vision for OCR), fall back to the main model with a warning
