# LLM Service: Add Semantic Response Caching to Reduce Cost and Latency

**Severity:** major
**Affected area:** Core — LLM Service
**Reported by:** codebase audit

## Description

The `LlmService` makes a fresh API call to the LLM provider for **every** request, even when the same or semantically similar queries are made repeatedly. There is no caching layer at all. This has three significant problems:

1. **Wasted cost** — Identical queries (e.g., "Summarize this document" for the same document, or "Generate a lesson plan for Integration" for the same topic) trigger new API calls and incur full token costs each time
2. **Increased latency** — Every query must wait for a network round-trip to the LLM provider (500ms-5s) even when the exact same response could be served from cache in <10ms
3. **No offline resilience** — If the network is unavailable, previously cached responses cannot be served

Common examples of repeated queries:
- "What are my weak topics?" asked multiple times during a session
- "Summarize this content" for the same source document
- "Generate a lesson for topic X" where the student re-enters the lesson
- Classification of the same content during reprocessing

## Expected behavior

The LLM service should have a caching layer that:
- Caches responses keyed by (modelId, systemPrompt, message) with exact-match deduplication
- Optionally supports semantic caching (similar prompts return cached response)
- Has configurable TTL per feature (e.g., classification cached for 24h, chat responses for 5min)
- Works in degraded mode (serves cached responses when offline)

## Actual behavior

No caching. Every request incurs full API cost and latency.

## Code analysis

- `lib/core/services/llm/llm_chat_service.dart:120-220` — `LlmService.chat()` and `chatStream()` always call the provider, no cache check
- `lib/core/config/app_runtime_config.dart` — `CacheConfig` exists with `cacheExpiration: Duration(hours: 24)` but is unused by LLM service
- `lib/core/services/llm_task_manager.dart` — Tracks tasks but no result caching
- `lib/core/data/hive_box_names.dart` — No cache-specific Hive box defined

## Suggested approach

1. **Create an `LlmResponseCache` service** using a Hive box:
   ```dart
   class LlmResponseCache {
     Future<void> init(); // Open Hive box 'llm_response_cache'
     String? get(String modelId, String systemPrompt, String message);
     void set(String modelId, String systemPrompt, String message, String response, {Duration ttl});
     void invalidate(String modelId); // Clear per-model cache
     void clear(); // Clear all
   }
   ```

2. **Cache key design**:
   ```dart
   String _buildKey(String modelId, String systemPrompt, String message) {
     final hash = sha256.convert(utf8.encode('$modelId|$systemPrompt|$message'));
     return hash.toString();
   }
   ```

3. **Integrate with `LlmService.chat()`**:
   - Before API call: check cache (exact hash match)
   - On API success: store in cache
   - Optional: store with feature-specific TTL (classification: 24h, lesson plans: 1h, chat: 5min)

4. **Add semantic caching (Phase 2)** using the existing `EmbeddingService`:
   - Compute embedding of the query
   - Find semantically similar queries in cache (cosine similarity > 0.95)
   - Return cached response if a sufficiently similar query exists

5. **Add cache hit metrics** to the dashboard — show how many tokens were saved by cache hits

6. **Respect cache invalidation** — When content changes (new questions generated, plan modified), invalidate related cache entries
