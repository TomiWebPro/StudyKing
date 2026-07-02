# ConversationMessage evaluation parsing fires on every message, cluttering logs

**Severity:** minor
**Affected area:** Teaching — ConversationMessage model
**Reported by:** user

## Description

Every time a `ConversationMessage` is constructed (for every chat message in the teaching/mentor features), the constructor calls `_computeIsEvaluation(content)` which attempts to `jsonDecode` the message content. For the vast majority of messages (plain text like "Hello!", "Explain photosynthesis", "Please configure your API key first."), `jsonDecode` throws a `FormatException`, which is caught and logged at warning level: `Failed to parse evaluation content`. This produces excessive noise in the runtime logs, making it harder to spot real issues.

## Steps to reproduce

1. Open the app and navigate to AI Mentor / Quick Guide
2. Send any text message (e.g., "Hello")
3. Check the runtime logs
4. Observe: `[W][ConversationMessage] Failed to parse evaluation content` followed by a `FormatException`

## Expected behavior

Non-JSON message content should not trigger any parsing attempt or warning log. The `isEvaluation` flag should simply be `false` for plain-text messages without any log output.

## Actual behavior

Every non-evaluation message produces a warning-level log entry:
```
[2026-07-03T04:52:43.916200][W][ConversationMessage] Failed to parse evaluation content
Error: FormatException: Unexpected character (at character 1)
Hello! I'm StudyKing's Quick Guide. Ask me anything about your studies!
^
```

## Code analysis

- `lib/features/teaching/data/models/conversation_message_model.dart:67` — The constructor unconditionally calls `_computeIsEvaluation(content)`:
  ```dart
  }) : isEvaluation = isEvaluation ?? _computeIsEvaluation(content);
  ```

- `lib/features/teaching/data/models/conversation_message_model.dart:71-79` — The static method parses every content string as JSON:
  ```dart
  static bool _computeIsEvaluation(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data['type'] == 'evaluation';
    } catch (e) {
      _logger.w('Failed to parse evaluation content', e);
      return false;
    }
  }
  ```

- The `MessageType` enum (`conversation_message_model.dart:7`) includes a `feedback` type, which could potentially carry evaluation content. But the `type` field is available before `_computeIsEvaluation` is called, meaning we could use it as a pre-filter.

- The producer code in `lib/features/teaching/services/conversation_manager.dart:170-180` creates evaluation messages with `type` set to some value and `content` as a JSON string with `'type': 'evaluation'`.

## Suggested approach

Add a quick content-type guard before attempting JSON parsing, to avoid throwing on plain text messages:

**Option A (content heuristic):** Check if content starts with `{` before parsing:

```dart
static bool _computeIsEvaluation(String content) {
  if (content.isEmpty || content[0] != '{') return false;
  try {
    final data = jsonDecode(content) as Map<String, dynamic>;
    return data['type'] == 'evaluation';
  } catch (e) {
    _logger.w('Failed to parse evaluation content', e);
    return false;
  }
}
```

This eliminates the `FormatException` for ~99% of messages while still catching genuinely malformed JSON in evaluation messages.

**Option B (MessageType filter):** Only attempt parsing when `type == MessageType.feedback` (or another relevant type). This requires passing `type` to `_computeIsEvaluation` as well.

**Option C (reduce log level):** Change `_logger.w(...)` to `_logger.d(...)` (debug) so the message is still available during development but not shown in production. However, this violates the convention that `.w()` is for "caught exceptions in expected error paths" — though this path fires so frequently it arguably should not be a warning.

Option A is the simplest and most effective fix with minimal code change.
