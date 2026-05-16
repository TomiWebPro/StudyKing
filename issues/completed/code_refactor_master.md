# Teaching Feature: Presentation-Layer Service Construction, Hardcoded Configuration, and Missing Provider Abstraction

## Context

The `teaching` feature (13 files, ~1700 lines) has significant architectural debt that undermines testability, configurability, and separation of concerns. Three interconnected problems exist: (1) the presentation layer (`tutor_screen.dart`) constructs heavyweight services inline with `new` and embeds a hardcoded model ID, (2) the feature completely lacks a `providers/` layer (the only feature among 8 that have one), forcing the UI screen to manage service lifecycle directly, and (3) `ConversationManager` embeds 100+ lines of LLM system prompts as raw multi-line strings inside business logic, making them untestable, unversionable, and impossible to tune without code changes.

## Affected Files

| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | 59–76 | `_initializeTutor()` constructs `MasteryGraphService()` inline via `new` and hardcodes `modelId: 'openai/gpt-4o-mini'` |
| `lib/features/teaching/services/conversation_manager.dart` | 108–138, 189–223, 286–303 | Three LLM system prompts embedded as raw multi-line strings in `generateLessonPlan()`, `_buildTutorPrompt()`, and `generateSummary()` |
| `lib/features/teaching/services/conversation_manager.dart` | 58–78 | `get messages` getter reconstructs `ConversationMessage` objects from raw `Map<String, dynamic>` instead of propagating typed objects through the memory layer |
| `lib/features/teaching/services/tutor_service.dart` | 65 | `manager.initialize(...)` called without `await` — unawaited future means initialization may race with `generateLessonPlan()` on line 72 |
| *(missing)* `lib/features/teaching/providers/` | — | Feature has no `providers/` directory; 8 of 14 features in the project have one |

## Detailed Findings

### 1. Inline Service Construction in Presentation Layer

`lib/features/teaching/presentation/tutor_screen.dart:59-76`:

```dart
void _initializeTutor() {
  if (widget.tutorService != null) {
    _tutorService = widget.tutorService!;
  } else {
    final llmService = ref.read(llmServiceProvider);
    final masteryService = MasteryGraphService();    // ← `new` — no DI
    final modelId = 'openai/gpt-4o-mini';            // ← hardcoded string

    _tutorService = TutorService(
      database: database,
      llmService: llmService,
      masteryService: masteryService,
      modelId: modelId,
    );
  }
  _startLesson();
}
```

**Problems:**
- **`MasteryGraphService()` called with `new` directly in the UI layer.** This service depends on Hive boxes and database initialization. The presentation layer should not know how to construct infrastructure services.
- **Untestable.** Widget tests cannot stub `MasteryGraphService` because it is hard-constructed. The `widget.tutorService` parameter provides an escape hatch, but only if *every* caller passes it — currently no caller does, meaning production code always hits the `else` branch.
- **Hardcoded model ID.** `'openai/gpt-4o-mini'` is embedded in presentation code. Changing the model (per user preference, per environment, per A/B test) requires editing source code. The settings feature already has an `LLMSettingsModel` for managing model selection — this hardcoded value bypasses that entirely.

### 2. Missing Provider Layer

`lib/features/teaching/` has no `providers/` subdirectory. The `TutorScreen` is a `ConsumerStatefulWidget` but uses `ref.read` only for `llmServiceProvider` and `database` (both core/global providers). There is no Riverpod provider encapsulating:

- `TutorService` lifecycle (it is created and stored on `_TutorServiceState`)
- `ConversationManager` state (stored as `_manager` on the state)
- Lesson summary / stats (computed inline in `_buildSummaryStats`)

This forces all business orchestration into the screen's state class, contributing to its 354-line size and making it impossible to test tutoring logic without widget tests.

### 3. Embedded LLM Prompts in ConversationManager

`lib/features/teaching/services/conversation_manager.dart` contains **three large prompt templates** as raw multi-line strings:

| Method | Lines | Purpose |
|---|---|---|
| `generateLessonPlan()` | 108–138 | 31-line JSON-format lesson plan prompt |
| `_buildTutorPrompt()` | 189–223 | 35-line tutor system prompt with phase/pace branching |
| `generateSummary()` | 286–303 | 18-line lesson summary prompt |

**Problems:**
- **Not testable.** Prompts cannot be unit-tested independently. Changing a prompt requires editing production code, and there is no way to verify prompt correctness without running the full LLM integration.
- **Not configurable/versionable.** Prompts cannot be swapped per model, locale, or experiment. They are baked into the binary.
- **Scattered control logic.** The `_buildTutorPrompt()` method contains branch logic (`switch (_adaptivePace)`, `switch (_phase)`) that mixes prompt engineering with conversation flow control. Changing the prompt structure requires understanding the surrounding state machine.

### 4. Raw Map Typing in Memory Layer

`conversation_manager.dart:58-78`:

```dart
List<ConversationMessage> get messages {
  final history = _memory.getHistory();  // returns List<Map<String, String>>
  final result = <ConversationMessage>[];
  for (int i = 0; i < history.length; i++) {
    final msg = history[i];
    final role = msg['role'] == 'assistant'
        ? MessageRole.tutor
        : msg['role'] == 'system'
            ? MessageRole.system
            : MessageRole.student;
    result.add(ConversationMessage(
      id: '${sessionId}_msg_$i',
      sessionId: sessionId,
      role: role,
      type: MessageType.text,
      content: msg['content'] ?? '',
      timestamp: _sessionStartTime.add(Duration(seconds: i)),
    ));
  }
  return result;
}
```

The `ConversationMemory` class stores messages as `List<Map<String, String>>` instead of typed `ConversationMessage` objects. Each read requires manual reconstruction with string-based role parsing (`'assistant'`, `'system'`, `'student'`). This is error-prone (typo in `'assistant'`?), loses type safety, and duplicates the serialization logic already present in `ConversationMessageModel`.

### 5. Unawaited Future in `tutor_service.dart`

`lib/features/teaching/services/tutor_service.dart:65`:

```dart
manager.initialize(       // ← no await
  studentId: studentId,
  topicTitle: topicTitle,
  subjectId: subjectId,
  topicId: topicId,
);

final lessonPlan = await manager.generateLessonPlan(...);  // line 72
```

`initialize()` is a `Future<void>` method (defined at `conversation_manager.dart:86`), but `startLesson()` does not `await` it. If the async initialization in `_loadPersistedMessages()` takes longer than a microtask, `generateLessonPlan()` may execute before initialization completes, producing a race condition.

## Rationale

1. **Testability.** The tutor screen cannot be unit-tested for tutoring logic — every test must be a widget integration test. Extracting providers allows pure-logic testing of the tutoring state machine.

2. **Configurability.** The hardcoded `'openai/gpt-4o-mini'` model ID prevents per-user model selection. The settings feature already manages model preferences; this bypasses that system entirely.

3. **Prompt maintainability.** Embedding 84 lines of LLM prompts inside Dart business logic creates a tight coupling between prompt content and code structure. Prompts should be extractable to dedicated files or configuration, enabling independent iteration without touching service code.

4. **Type safety.** Reconstructing typed `ConversationMessage` objects from `Map<String, dynamic>` on every read is fragile, duplicates serialization logic, and discards the compiler's ability to catch errors.

5. **Race condition.** The unawaited `initialize()` future in `tutor_service.dart` is a latent bug that may cause the first lesson prompt to execute before persisted messages are loaded.

## Acceptance Criteria

- [ ] **AC1 — Provider layer created:** Add `lib/features/teaching/providers/` with Riverpod providers for `TutorService` and `ConversationManager` lifecycle, so the screen uses `ref.watch`/`ref.read` instead of storing services on `State`.

- [ ] **AC2 — No `new MasteryGraphService()` in presentation:** Remove the inline `MasteryGraphService()` construction from `tutor_screen.dart:_initializeTutor()`. Pass it through the provider layer or as a constructor parameter. The screen should accept dependencies, not construct them.

- [ ] **AC3 — Model ID is configurable, not hardcoded:** Remove the hardcoded `'openai/gpt-4o-mini'` string from `tutor_screen.dart`. The model ID should come from settings (via `LLMSettingsModel`) or be injected via provider, not embedded in UI code.

- [ ] **AC4 — LLM prompts extracted from ConversationManager:** Move the three embedded prompt strings (`generateLessonPlan`, `_buildTutorPrompt`, `generateSummary`) out of `conversation_manager.dart` into dedicated prompt files (e.g., `lib/features/teaching/services/prompts/`) or a configuration object. `ConversationManager` should receive prompts as injected dependencies.

- [ ] **AC5 — ConversationMemory uses typed messages:** Refactor `ConversationMemory.getHistory()` to return `List<ConversationMessage>` instead of `List<Map<String, String>>`, eliminating the manual map-to-object reconstruction in `ConversationManager.messages`.

- [ ] **AC6 — `initialize()` is awaited:** Add `await` before `manager.initialize(...)` in `tutor_service.dart:65` to eliminate the race condition.

- [ ] **AC7 — Existing tests pass:** All existing tests in `test/features/teaching/` continue to pass after the refactor. No regressions.
