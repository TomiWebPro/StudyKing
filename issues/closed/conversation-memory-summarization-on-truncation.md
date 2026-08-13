# Conversation Memory: Add Summarization Strategy When History Exceeds Max Turns

**Severity:** critical
**Affected area:** Teaching Mode, Mentor Mode — Conversation Memory
**Reported by:** codebase audit

## Description

The `ConversationMemory` class (`lib/core/services/conversation_memory.dart`) has a max turns limit (default 20) and when the conversation exceeds `maxTurns * 2` messages, it **silently drops the oldest messages** with no semantic preservation. A system notification is injected saying "Conversation history trimmed..." but the actual content of those dropped messages is lost forever.

For the AI tutor and mentor, this means:
- After ~10 exchanges (20 messages), the AI starts forgetting earlier context
- The student cannot reference things they discussed earlier in the same session
- The AI may contradict itself because it doesn't remember earlier decisions
- The `LongTermMemory.generateAndStoreSummary()` method exists but is only called from `MentorService` after a session ends — it is never used for mid-session memory compression

This is a critical design gap because the entire value of an AI tutor depends on it remembering what was discussed earlier in the session.

## Steps to reproduce

1. Start a tutor session
2. Have a 10+ exchange conversation (covering topics, exercises, feedback)
3. Reference something the student said in exchange #3
4. Observe: the AI has no memory of it and responds generically

## Expected behavior

When conversation history approaches the max turns limit, the system should:
- Summarize older exchanges into a compressed "conversation context" message
- Use a sliding window: keep recent N turns verbatim + summarized history of older turns
- Optionally, recursively summarize (summarize summaries) for very long sessions

## Actual behavior

Old messages are simply discarded with a truncation notification. No semantic content is preserved.

## Code analysis

- `lib/core/services/conversation_memory.dart:47-72` — `_trim()` method: removes old messages when `messages.length > maxTurns * 2`, injects truncation notification
- `lib/core/services/conversation_memory.dart:16-19` — `maxTurns` defaults to 20
- `lib/core/services/long_term_memory.dart:55-89` — `generateAndStoreSummary()` exists but is not used by `ConversationMemory` internally
- `lib/features/teaching/services/conversation_manager.dart:38-42` — Uses `ConversationMemory` with default max turns, no custom compression
- `lib/features/mentor/services/mentor_service.dart:90-94` — Uses `ConversationMemory(maxTurns: 50)` but still no compression strategy

## Suggested approach

1. **Add a `summarizeAndCompress()` method to `ConversationMemory`** that:
   - Calls the LLM to produce a concise summary of the oldest N messages
   - Replaces those N messages with a single synthetic "system" message containing the summary
   - Preserves the most recent M turns verbatim for immediate context

2. **Make compression configurable**:
   ```dart
   class ConversationMemory {
     final int maxTurns;
     final CompressionStrategy compressionStrategy; // none, slidingWindow, recursive
     final int preserveRecentTurns; // how many recent turns to keep verbatim
   }
   ```

3. **Trigger compression automatically** when `messages.length > maxTurns * 0.8` (threshold, not hard limit)

4. **Optimize for cost** — Use a cheaper/faster model for summarization vs the main conversation model

5. **Add a summary message type** so the UI can optionally display compressed context to the user (e.g., "📝 Earlier we discussed integration by parts...")
