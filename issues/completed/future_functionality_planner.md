# [F] Redesign AI Tutor (Teaching Mode) with Voice Integration, Structured Lesson Plans, and AI-Based Exercise Evaluation

## Context

The `agent_must_read.md` envisions Teaching Mode as:

> "The active learning environment where AI functions as a true tutor... conversational, not static. The student should be able to speak naturally with the AI tutor, ask follow-up questions, interrupt explanations, request clarification, and engage in real-time back-and-forth discussion through both text and voice."

The current implementation (`lib/features/teaching/`) falls significantly short of this vision. Three major deficiencies exist:

### Deficiency 1: Exercise Evaluation Uses Keyword Matching, Not AI

`ConversationManager._evaluateExerciseResponse()` at `lib/features/teaching/services/conversation_manager.dart:159-178` evaluates student answers by checking whether the response string contains any keyword from `_correctKeywords` or `_incorrectKeywords`. This is fundamentally broken for any subject requiring reasoning, explanation, or multi-step answers:

```dart
void _evaluateExerciseResponse(String content) {
  _exerciseCount++;
  final lower = content.toLowerCase();

  final isCorrect = _correctKeywords.any((k) => lower.contains(k));
  final isIncorrect = _incorrectKeywords.any((k) => lower.contains(k));
  // ...
}
```

- A student who writes "The mitochondria is NOT the powerhouse" would be marked correct if "powerhouse" is a correct keyword.
- A student who writes a correct physics derivation but uses different terminology would be marked incorrect.
- There is no understanding of mathematical/chemical notation, diagrams, or code.

### Deficiency 2: Lesson Plans Are Unstructured Raw LLM Output

`ConversationManager.generateLessonPlan()` at line 85-103 calls the LLM with a prompt asking for JSON, but the result is stored as a raw `String` in `TutorSession.lessonPlanJson`. The system never parses, validates, or acts on the plan structure. The `TutorScreen` has no visual representation of the lesson plan (sections, time remaining, goals, checkpoints).

The `LessonProgressBar` widget exists but appears disconnected from actual lesson plan data.

### Deficiency 3: No Voice/Audio Support

The `TutorScreen` at line 43 declares `bool _isVoiceListening = false;` but no microphone integration, speech-to-text, or text-to-speech code exists anywhere in the codebase. The vision requires:

> "typed input, voice conversation, speech-to-text and text-to-speech, multiple choice responses, handwritten/drawn responses on canvas, vision-based interpretation of student work"

None of these input modalities exist in the teaching mode.

### Additional Findings

| Finding | Location | Severity |
|---|---|---|
| `tutor_service.dart:65` — `await manager.initialize()` is unawaited | `lib/features/teaching/services/tutor_service.dart:65` | Critical |
| Prompts still embedded in `conversation_manager.dart` despite `prompts/prompts.dart` existing | `conversation_manager.dart:108-138, 189-223` | Moderate |
| `DateTime.now()` called in 4 places — untestable | `conversation_manager.dart:31,74`, `tutor_service.dart:42,51` | Moderate |
| `StudentIdService()` used as global service locator | `tutor_screen.dart:4, 126, 134` | Moderate |
| No questions integration — tutor exercises don't create `Question` objects | Entire teaching feature | Major |
| `ConversationManager` has 15 mutable fields — breaks immutability pattern | Full class | Major |
| No lesson plan validation — malformed LLM JSON crashes implicitly | `generateLessonPlan()` returns raw | Moderate |
| `TutorService.startLesson()` uses `DateTime.now()` for session IDs — collision risk | `tutor_service.dart:42` | Low |

## Impact

| Area | Current State | Target State |
|---|---|---|
| Exercise evaluation | Keyword containment heuristic | AI-evaluated responses with semantic understanding, partial credit, and detailed feedback |
| Lesson plans | Raw JSON string, never parsed or visualized | Structured plan with sections, timing, goals, and checkpoints; progress tracked visually in UI |
| Input modalities | Text only | Text + voice (STT input, TTS output), with slots for canvas/handwriting/vision |
| Voice infrastructure | `_isVoiceListening` dead flag | `speech_to_text` + `flutter_tts` integration with `Record`/`Stop` toggle + waveform indicator |
| Prompt architecture | Mixed between `conversation_manager.dart` and `prompts/prompts.dart` | All prompts in `prompts/prompts.dart`, versionable, localizable, overridable per subject |
| Testability | `DateTime.now()` in 4 places, `StudentIdService()` locator, no fake LLM | All time dependencies injected via `Clock` abstraction; `LlmService` injectable; `StudentId` injected via provider |
| Question integration | Tutor exercises produce no persisted `Question` objects | Each tutor exercise creates/links a `Question`, so practice mode can revisit weak points from lessons |
| Session correctness | `initialize()` race condition on line 65 | Future properly awaited, error handling on init failure |

## Proposed Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    TutorScreen                            │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ VoiceBar   │  │ ChatArea     │  │ LessonProgress   │  │
│  │ (STT/TTS)  │  │ (bubbles)    │  │ (plan timeline)  │  │
│  └─────┬──────┘  └──────┬───────┘  └────────┬─────────┘  │
│        │                │                    │            │
└────────┼────────────────┼────────────────────┼────────────┘
         │                │                    │
         ▼                ▼                    ▼
┌──────────────────────────────────────────────────────────┐
│                    TutorService                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │            ConversationManager                    │    │
│  │  ┌─────────┐  ┌──────────┐  ┌────────────────┐  │    │
│  │  │ Prompts │  │ Phase    │  │ LessonPlan     │  │    │
│  │  │ (extract│  │ Machine  │  │ (typed model)  │  │    │
│  │  │  +local)│  │          │  │                │  │    │
│  │  └─────────┘  └──────────┘  └────────────────┘  │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │          ExerciseEvaluator (NEW)                  │    │
│  │  - Delegates to LlmService for semantic eval      │    │
│  │  - Returns score + explanation + partial credit   │    │
│  │  - Creates/linked to Question objects             │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │          VoiceController (NEW)                    │    │
│  │  - speech_to_text plugin for STT                  │    │
│  │  - flutter_tts for TTS                            │    │
│  │  - Streams transcribed text to ChatInput          │    │
│  │  - Reads AI responses aloud                       │    │
│  └──────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### New/Refactored Components

1. **`LessonPlan` typed model** — replaces raw JSON string. Fields: `goals`, `sections` (with title, duration, type), `checkpoints`, `estimatedDifficulty`. Validated on instantiation.

2. **`ExerciseEvaluator`** — new class injected into `ConversationManager`. Uses `LlmService` to evaluate free-text answers. Returns `EvaluationResult { score, explanation, partialCredit, conceptBreakdown }`. Links evaluation to `QuestionRepository` to persist exercises as `Question` objects for later practice.

3. **`VoiceController`** — new class managing `speech_to_text` and `flutter_tts` plugins. Exposes `Stream<String> transcribedText` and `Future<void> speak(String text)`. Integrates with `TutorScreen` via a `VoiceBar` widget.

4. **`ConversationPromptSet`** — replace `PromptTemplates` simple record with a versioned, localizable prompt repository. Each phase has a dedicated prompt function returning a `PromptEntry` (system + user prompt strings). Supports locale overrides from `AppLocalizations`.

5. **`StructuredLessonPlanNotifier`** — Riverpod `Notifier` that watches the current lesson plan, exposes current section index, remaining time, completed checkpoints, so `LessonProgressBar` can render a meaningful timeline.

## Affected Files

| File | Role | Required Change |
|---|---|---|
| `lib/features/teaching/services/conversation_manager.dart` | Core tutor logic | Extract all embedded prompts to `prompts/prompts.dart`; inject `ExerciseEvaluator`; use typed `LessonPlan` instead of raw JSON string; make fields final; inject `Clock` for time |
| `lib/features/teaching/services/tutor_service.dart` | Session orchestration | Fix unawaited `initialize()` at line 65; inject `Clock` and `ExerciseEvaluator`; link exercises to `QuestionRepository` |
| `lib/features/teaching/services/prompts/prompts.dart` | Prompt templates | Refactor to `ConversationPromptSet` with versioned, localizable prompt functions; split into separate files per phase |
| `lib/features/teaching/services/tutor_service.dart` | Service | Change `startLesson()` to await `manager.initialize()` properly; add error handling |
| `lib/features/teaching/models/lesson_plan_model.dart` | **NEW** | Typed `LessonPlan` model with `goals`, `sections`, `checkpoints`, `estimatedDifficulty`; JSON serialization; validation |
| `lib/features/teaching/models/evaluation_result.dart` | **NEW** | `EvaluationResult` sealed class with `score`, `explanation`, `partialCredit`, `conceptBreakdown` |
| `lib/features/teaching/services/exercise_evaluator.dart` | **NEW** | Injects `LlmService`; calls LLM with subject-specific evaluation prompt; returns structured `EvaluationResult` |
| `lib/features/teaching/services/voice_controller.dart` | **NEW** | Wraps `speech_to_text` + `flutter_tts`; exposes `Stream<String>` for STT; `speak()` for TTS |
| `lib/features/teaching/presentation/tutor_screen.dart` | Main tutor UI | Add `VoiceBar` widget; display lesson plan timeline via `LessonProgressBar`; remove `_isVoiceListening` dead flag |
| `lib/features/teaching/presentation/widgets/voice_bar.dart` | **NEW** | Mic toggle button, waveform animation, recording indicator, TTS toggle |
| `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` | Existing widget | Rewrite to consume `StructuredLessonPlanNotifier`; show section list, checkpoints, time remaining |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | Existing widget | Add optional "evaluation" display (score, partial credit bar, explanation) for exercise responses |
| `lib/features/teaching/providers/teaching_providers.dart` | DI wiring | Add `exerciseEvaluatorProvider`, `voiceControllerProvider`, `lessonPlanProvider`; inject `Clock` provider |
| `lib/features/questions/data/repositories/question_repository.dart` | Question persistence | Ensure `create` is usable from `ExerciseEvaluator` for persisting tutor exercises |
| `lib/features/questions/data/models/question_model.dart` | Question model | Verify compatibility with tutor exercise data (may need `source` field for `tutor_session` origin) |
| `lib/core/services/student_id_service.dart` | Service locator | Replace service locator calls with Riverpod `studentIdProvider` |
| `lib/core/providers/app_providers.dart` | DI wiring | Add `clockProvider` (injectable `Clock`), `studentIdProvider` |
| `pubspec.yaml` | Dependencies | Add `speech_to_text`, `flutter_tts` |

## Rationale

1. **Core product differentiator**: The AI tutor is the flagship feature of StudyKing. A keyword-matching evaluator and unstructured lesson plan undermine the entire value proposition. Students need real AI-powered teaching, not keyword detection that a 1990s chatbot could do.

2. **Direct vision requirement**: The `agent_must_read.md` explicitly requires voice conversation, speech-to-text, text-to-speech, and multiple interaction modalities. Zero of these are implemented.

3. **Bug amplification**: The unawaited `initialize()` at `tutor_service.dart:65` means lesson plans can be generated before the manager is fully initialized, leading to undefined behavior in `_studentId`, `_topicTitle` etc. This is a latent production bug.

4. **Feature synergy**: AI-evaluated exercises that create persisted `Question` objects would bridge the teaching and practice features. Today, a student struggles with a concept during a lesson, but has no way to review those specific exercises later in practice mode.

5. **Prompt maintainability**: Currently prompts are split between `conversation_manager.dart` (lines 108-138, 189-223, 286-303) and `prompts/prompts.dart`. This makes prompt iteration, A/B testing, and localization impossible. A unified `ConversationPromptSet` with versioning would enable prompt engineering without touching core logic.

6. **Testability**: The `DateTime.now()` calls (4 locations), `StudentIdService()` locator (2 locations), and direct `LlmService` calls (3 locations) make the teaching feature effectively untestable. The `code_refactor_master.md` issue already addresses similar patterns in `practice/` — the teaching feature has the same problems.

7. **Market readiness**: Without voice conversation, the app cannot compete with modern AI tutoring products (e.g., Khanmigo, Quizlet Q-Chat) that offer natural voice interaction.

## Acceptance Criteria

### Lesson Plan & Progress
- [ ] `LessonPlan` typed model exists with `goals`, `sections` (typed `LessonSection` with `title`, `durationMinutes`, `type` enum), `checkpoints`, `estimatedDifficulty`. Validates on construction (rejects empty goals, zero-duration sections).
- [ ] `ConversationManager.generateLessonPlan()` returns `LessonPlan` instead of `String`. Parses LLM JSON response into typed model. Falls back gracefully on parse failure (uses default plan).
- [ ] `StructuredLessonPlanNotifier` exposes current section, elapsed/total time, completed checkpoints. Updates as the lesson progresses.
- [ ] `LessonProgressBar` renders a time-based timeline showing sections, markers for checkpoints, and current position. Updates in real-time.
- [ ] `TutorScreen` displays the lesson plan (collapsible) showing goals, sections with remaining time, and checkpoint completion status.

### Exercise Evaluation
- [ ] `ExerciseEvaluator` class exists and is injected into `ConversationManager`. It calls `LlmService` with a structured prompt including the question, student answer, and evaluation rubric.
- [ ] `EvaluationResult` sealed class has `score` (0.0–1.0), `explanation` (string), optional `partialCredit` fields, and `conceptBreakdown`.
- [ ] `ConversationManager._evaluateExerciseResponse()` delegates to `ExerciseEvaluator` instead of keyword matching. The keyword lists `_correctKeywords` and `_incorrectKeywords` are removed.
- [ ] Each evaluated exercise creates a `Question` object (via `QuestionRepository`) linked to the tutor session, so the question appears in practice mode.
- [ ] `ChatBubble` displays evaluation results: score bar, explanation, and concept breakdown for exercise responses.

### Voice Integration
- [ ] `VoiceController` class wraps `speech_to_text` and `flutter_tts`. Initializes lazily, handles permission requests, reports availability status.
- [ ] `VoiceBar` widget renders a mic toggle button. While recording, shows a waveform indicator and transcription progress text. Tapping stop submits the transcribed text.
- [ ] TTS toggle in settings (or per-session) enables the AI tutor's responses to be read aloud. Respects the user's locale.
- [ ] `TutorScreen._isVoiceListening` is removed; all voice state is managed by `VoiceController`.
- [ ] `VoiceController` works offline gracefully (falls back to text-only if plugins unavailable).

### Prompt Architecture
- [ ] All prompts are extracted from `conversation_manager.dart` to `prompts/prompts.dart`. Zero prompt strings remain in `conversation_manager.dart`.
- [ ] `ConversationPromptSet` has versioned prompt functions, each returning a `PromptEntry(systemPrompt, userPrompt)`.
- [ ] Prompts support locale-based overrides via `AppLocalizations` (e.g., Spanish prompts for Spanish-speaking students).
- [ ] The `prompts/` directory is structured by phase (e.g., `prompts/lesson_plan_prompts.dart`, `prompts/tutor_prompts.dart`, `prompts/evaluation_prompts.dart`).

### Time & Dependency Injection
- [ ] `DateTime.now()` is removed from all 4 locations in `conversation_manager.dart` and `tutor_service.dart`. Instead, a `Clock` abstraction is injected, defaulting to `Clock.system()`.
- [ ] `StudentIdService()` calls in `tutor_screen.dart` are replaced with a Riverpod `studentIdProvider`.
- [ ] `tutor_service.dart:65` properly awaits `manager.initialize()` with error handling.
- [ ] `ConversationManager` fields that can be final are made final (currently 5 mutable fields: `_studentId`, `_topicTitle`, `_subjectId`, `_topicId`, `_phase` — `_phase` can remain mutable).

### Testing
- [ ] `ExerciseEvaluator` has unit tests with a fake `LlmService` returning controlled `EvaluationResult` values.
- [ ] `ConversationManager` tests use fake `Clock`, fake `ExerciseEvaluator`, and injectable `PromptTemplates`.
- [ ] `TutorService` tests verify that `initialize()` is awaited before `generateLessonPlan()` is called.
- [ ] `VoiceController` has widget tests verifying mic toggle, transcription stream consumption, and TTS invocation.
- [ ] `LessonPlan` model has tests for JSON parsing, validation, and edge cases (malformed input, missing fields).
- [ ] All existing tests for `teaching/` continue to pass.

### Zero Regressions
- [ ] Zero analysis warnings introduced.
- [ ] All existing unit and widget tests pass.

## Out of Scope

- Canvas/handwriting input (requires `CanvasDrawingWidget` integration — can be added separately)
- Vision-based interpretation of student work (requires camera ML pipeline)
- Video lesson recording/playback (requires media infrastructure)
- Multi-student/classroom mode (future expansion)
