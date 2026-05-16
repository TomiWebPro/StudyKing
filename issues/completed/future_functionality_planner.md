# Future Functionality Plan: Service Consolidation & Architectural Unification

## Context

After a deep audit of the StudyKing codebase (13 feature modules, ~50+ service files, 20+ Hive models), the most critical finding is **fragmented service architecture**: core functionalities are implemented in 2–3 redundant, incompatible, or disconnected ways across different features. This fragmentation causes silent data inconsistencies (e.g., two incompatible spaced repetition interval calculations, parallel nudge generation without dedup) and makes the codebase harder to extend, test, and maintain.

Additionally, several areas in the product vision (`agent_must_read.md`) have only partial or stub implementations: voice/speech interaction, vision-based student work interpretation, lesson generation, lesson duration tracking, question variant generation, and multi-syllabus support.

This issue proposes a phased consolidation plan to unify the architecture and close the gap between vision and implementation.

---

## Phase 1 — High-Impact Service Consolidation

### 1.1 Unify Timer Implementations (3 → 1)

**Current state:** Three independent `Timer.periodic(1s)` implementations:

| Class | File | Used by |
|---|---|---|
| `StudyTimerService` | `lib/features/sessions/services/study_timer_service.dart` | Focus Mode only |
| `ExamSessionService` | `lib/features/practice/services/exam_session_service.dart` | Exam sessions |
| `PracticeSessionService` | `lib/features/practice/services/practice_session_service.dart` | Practice sessions |

All three track elapsed/remaining time with `Timer.periodic`. `StudyTimerService` has the most complete lifecycle (start/pause/resume/complete/cancel + daily cap + today stats). `ExamSessionService` and `PracticeSessionService` duplicate this logic.

**Rationale:** A single unified `StudyTimerService` (renamed to `SessionTimerService`) eliminates 200+ lines of duplicated timer logic, ensures consistent daily cap enforcement, and simplifies testing.

**Acceptance criteria:**

- [ ] `ExamSessionService` and `PracticeSessionService` delegate to `SessionTimerService` for all timer functionality.
- [ ] Original timer fields (`Timer? _timer`, `_elapsedMs`, `_isPaused`) removed from both services.
- [ ] All existing tests for all three services pass without modification (test for delegation only).

---

### 1.2 Consolidate Spaced Repetition (5+ classes → 1 canonical path)

**Current state:** Three independent, incompatible interval calculation paths:

| Path | Location | Algorithm |
|---|---|---|
| `SpacedRepetitionEngine.scheduleReview()` | `lib/features/practice/services/spaced_repetition_engine.dart` | Proper SM-2 (ease factor, repetition count) |
| `SpacedRepetitionService.updateNextReviewDate()` | `lib/features/practice/services/spaced_repetition_service.dart` | Fixed thresholds (30min/12h/1d/3d/7d based on masteryLevel) |
| `QuestionMasteryState` (via `_calculateNextReview`) | `lib/features/practice/data/models/` | Mastery-level-based multipliers |

Additionally, `MasteryRecorder.recordAttempt()` calls both `SpacedRepetitionEngine.scheduleReview()` AND `MasteryGraphService.recordAttempt()` which independently updates question mastery state. `MasteryIntegrationService.calculateSpacedRepetitionInterval()` creates a fourth independent interval calculation.

**Rationale:** With three incompatible interval algorithms, the same student answering the same question correctly will get three different next-review dates depending on which code path executes. This breaks the core value proposition of adaptive spaced repetition.

**Affected files:**
- `lib/features/practice/services/spaced_repetition_engine.dart`
- `lib/features/practice/services/spaced_repetition_service.dart`
- `lib/features/practice/services/mastery_recorder.dart`
- `lib/core/services/mastery_integration_service.dart`
- `lib/features/practice/data/models/question_mastery_state.dart` (or wherever `_calculateNextReview` lives)

**Acceptance criteria:**

- [ ] `SpacedRepetitionService.updateNextReviewDate()` uses `SpacedRepetitionEngine.scheduleReview()` (SM-2) as its sole interval calculation method.
- [ ] `MasteryRecorder.recordAttempt()` is the **only** method that records attempts and updates next-review dates. All other code paths that independently set `nextReview` are removed.
- [ ] `MasteryIntegrationService.calculateSpacedRepetitionInterval()` is removed; callers delegate to `SpacedRepetitionEngine`.
- [ ] `SpacedRepetitionRepository` (labeled "legacy") is either removed or explicitly deprecated with a lint warning.
- [ ] All spaced repetition tests are updated/added to verify SM-2-based scheduling from the service layer.

---

### 1.3 Consolidate Nudge Generation (2 → 1)

**Current state:** Two independent services generate `EngagementNudgeModel` records:

| Service | File | Triggers |
|---|---|---|
| `EngagementScheduler` | `lib/core/services/engagement_scheduler.dart` | Timer-driven daily checks |
| `MentorService.checkWellbeingAndGenerateNudges()` | `lib/features/mentor/services/mentor_service.dart` | On chat interaction |

Both check overwork, revision needs, and inactivity. No deduplication guard exists between them.

**Rationale:** Without dedup, the same student can receive the same "you've been studying too much" nudge from both paths on the same day. The nudge system must have a single source of truth for what was already sent.

**Acceptance criteria:**

- [ ] Nudge generation logic is extracted into a shared `NudgeEngine` (or similar) that both `EngagementScheduler` and `MentorService` call.
- [ ] Rate-limiting / dedup check (`getTodayCount`) is enforced at the shared layer, not in each caller.
- [ ] No duplicate `EngagementNudgeModel` records are created for the same condition within the same dedup window.

---

### 1.4 Consolidate Evaluation Models (2 → 1)

**Current state:** Two parallel answer evaluation structures:

| Model | Hive typeId | Features |
|---|---|---|
| `Markscheme` + `MarkSchemeStep` | 12, 13 | Simpler, fewer fields |
| `QuestionEvaluation` + `EvaluationStep` | 14, 15 | Richer (versioning, metadata, partialCredit) |

Both have their own `isMatch()` implementations with slightly different logic.

**Rationale:** Two models with the same purpose cause confusion about which one to use when adding new features. The richer `QuestionEvaluation` should become the canonical model.

**Affected files:**
- `lib/features/questions/data/models/markscheme_model.dart`
- `lib/features/questions/data/models/question_evaluation_model.dart`
- `lib/features/questions/data/adapters/markscheme_adapter.dart`
- `lib/features/questions/data/adapters/question_evaluation_adapter.dart`

**Acceptance criteria:**

- [ ] `QuestionEvaluation` is the canonical evaluation model. `Markscheme` is deprecated with a `@Deprecated` annotation pointing to `QuestionEvaluation`.
- [ ] A migration path exists for existing Hive data (read `Markscheme` stores and convert on write).
- [ ] `Question.text` and `Question.markscheme` field references throughout the codebase are updated to use `QuestionEvaluation` where applicable.

---

## Phase 2 — Vision Gap Closure

### 2.1 Voice & Speech Interaction Integration

**Current state:** The `api_config.dart` has a `WhisperApiKey` and `TeachingService` references a `VoiceController`, but:
- Speech-to-text: Not integrated into any interactive workflow beyond basic wiring.
- Text-to-speech: Dependency `flutter_tts` exists in `pubspec.yaml` but no usage found outside `voice_controller.dart` in teaching.
- Voice conversation loop: No end-to-end voice interaction in practice, mentor, or lesson modes.

**Per vision:** "The platform should support voice conversation, speech-to-text and text-to-speech throughout."

**Acceptance criteria:**

- [ ] Mentor chat supports voice input (STT) and voice output (TTS) via a toggle.
- [ ] Practice session answer input supports voice dictation.
- [ ] Focus timer supports voice commands ("start focus", "pause", "stop").
- [ ] Lesson mode STT/TTS works with the active conversation phase state machine.

---

### 2.2 Lesson Generation & Scheduling

**Current state:**
- `LessonService` (`lib/features/lessons/services/lesson_service.dart`) is **misnamed**: it operates on `TutorSession` objects, not `Lesson` objects. It is effectively a `TutorSessionService` which aliases teaching sessions.
- There is **no service** that generates `Lesson` / `LessonBlock` objects from syllabus content.
- The `Lesson` model has no `duration` field (per vision: "Lesson time and duration can be dynamically specified by the student").
- The `Lesson` model's `markscheme` field is `String?` instead of the structured `Markscheme` / `QuestionEvaluation` type.

**Rationale:** Without lesson generation, the system cannot produce structured, visual, slide-like lessons from uploaded content or syllabi. The vision explicitly calls for dynamically generated lesson plans.

**Acceptance criteria:**

- [ ] `LessonService` is renamed to `TutorSessionQueryService` and its public API is updated to make clear it queries tutor sessions.
- [ ] A new `LessonGenerationService` exists that can generate `Lesson` + `LessonBlock` objects from syllabus content, study material, or topic specifications.
- [ ] `Lesson` model gains a `durationMinutes` field.
- [ ] `Lesson.markscheme` is changed from `String?` to `QuestionEvaluation?`.
- [ ] Lesson generation is accessible from the topic detail screen and the planner.

---

### 2.3 Question Variant Generation

**Current state:** The `Question` model has a `variantIds: List<String>` field, but there is no service that generates or manages variants.

**Per vision:** "Questions should be expanded through generated variants, and used to measure understanding, identify weak areas, and drive adaptive revision."

**Acceptance criteria:**

- [ ] A `QuestionVariantGenerationService` exists that can produce 3–5 variants of a given question (different numeric values, reworded stems, different wrong options for MCQs).
- [ ] Variants are linked to the parent question via `variantIds`.
- [ ] Variants are automatically generated for new questions during content ingestion.
- [ ] Practice sessions can optionally include variants of previously seen questions.

---

### 2.4 Vision-Based Student Work Interpretation

**Current state:** A `CanvasDrawingWidget` exists for freehand answer input, but there is no OCR, no image analysis, no handwritten answer interpretation.

**Per vision:** "The platform should support vision-based interpretation of student work and handwritten/drawn responses on canvas."

**Acceptance criteria:**

- [ ] A canvas answer submission can be sent to an LLM with vision capability (via the LLM service) for interpretation and comparison against the markscheme.
- [ ] The practice/exam session flow supports "draw your answer" as a first-class input method.
- [ ] Interpreted answers from canvas are stored alongside typed answers in the `StudentAttempt` model.

---

## Phase 3 — Architectural Cleanup

### 3.1 Fix Content Pipeline Error Handling

**Current bug:** In `lib/features/ingestion/services/content_pipeline.dart`, when the pipeline catches an error during processing, it returns `Result.success(failed)` wrapping the failed source. Callers checking `isSuccess` will think the pipeline completed successfully.

**Acceptance criteria:**

- [ ] Error branches return `Result.failure(...)` with appropriate error details.
- [ ] Upper layers (upload screen, background task runner) handle `Result.failure` correctly.

---

### 3.2 Fix StudyProgressTracker Locale Bug

Per AGENTS.md: "Never use `toStringAsFixed()` for user-facing numeric displays." The `StudyProgressTracker` uses `toStringAsFixed(1)` on line ~51 for the accuracy percentage.

**Acceptance criteria:**

- [ ] All user-facing numeric formatting in `StudyProgressTracker` uses locale-aware helpers from `lib/core/utils/number_format_utils.dart`.
- [ ] CSV export methods remain in invariant `en` format.
- [ ] The accuracy percentage in `getOverallStats` and related methods uses `formatPercent` or similar.

---

### 3.3 Create Ingestion Providers Directory

**Current state:** `lib/features/ingestion/` has no `providers/` directory. Every other feature does. `ContentPipeline` and `DocumentExtractor` must be manually constructed everywhere they are used.

**Acceptance criteria:**

- [ ] `lib/features/ingestion/providers/` exists with Riverpod providers for `ContentPipeline`, `DocumentExtractor`, and `WebScraper`.
- [ ] Existing code that manually constructs these classes is updated to use the providers.

---

### 3.4 Fix Plan Adherence Dual Tracking

**Current state:** `InstrumentationService` has an internal `PlanAdherenceTracker` using `PlanAdherenceMetric` model, while `PlanAdherenceRepository` uses `PlanAdherenceModel`. Both track the same concept with no synchronization.

**Acceptance criteria:**

- [ ] `InstrumentationService`'s `PlanAdherenceTracker` is removed; `InstrumentationService` delegates to `PlanAdherenceRepository` instead.
- [ ] No data loss for existing `PlanAdherenceMetric` records — migration script reads old box and writes to `PlanAdherenceRepository`.

---

### 3.5 Fix `MentorService` Hardcoded Values

**Current:** `completedLessons: 0` in `getProgressReport()` — never computed from actual data.

**Acceptance criteria:**

- [ ] `completedLessons` is queried from `TutorSessionRepository` (count of completed tutor sessions for the student).
- [ ] The field is included in integration/widget tests for the progress report.

---

## Files Summary

### Phase 1 — Consolidation
| Issue | Primary files to modify |
|---|---|
| Timer unification | `study_timer_service.dart`, `exam_session_service.dart`, `practice_session_service.dart`, `focus_mode_providers.dart` |
| SR consolidation | `spaced_repetition_engine.dart`, `spaced_repetition_service.dart`, `mastery_recorder.dart`, `mastery_integration_service.dart`, `question_mastery_state.dart` |
| Nudge consolidation | `engagement_scheduler.dart`, `mentor_service.dart`, nudge repo |
| Evaluation models | `markscheme_model.dart`, `question_evaluation_model.dart`, adapters |

### Phase 2 — Vision Gaps
| Feature | New / modified files |
|---|---|
| Voice integration | `voice_controller.dart`, mentor + practice + focus screens |
| Lesson generation | `lesson_service.dart` (rename) → new `lesson_generation_service.dart`, `lesson_model.dart` |
| Variant generation | New `question_variant_generation_service.dart`, `Question.variantIds` wiring |
| Vision interpretation | `canvas_drawing_widget.dart`, practice session flow, `StudentAttempt` model |

### Phase 3 — Cleanup
| Issue | Files |
|---|---|
| Pipeline error handling | `content_pipeline.dart` |
| Locale formatting | `study_progress_tracker.dart` |
| Ingestion providers | New `lib/features/ingestion/providers/` dir |
| Adherence tracking | `instrumentation_service.dart`, `plan_adherence_repository.dart` |
| Mentor hardcoded value | `mentor_service.dart` |

---

## Dependencies & Ordering

```
Phase 1 (Consolidation)
  └── 1.1 Timer unification ──────────────────── blocks → Practice exam timer fix
  └── 1.2 SR consolidation ───────────────────── blocks → Adaptive practice improvements
  └── 1.3 Nudge consolidation ────────────────── blocks → Mentor proactive features
  └── 1.4 Evaluation model consolidation ─────── blocks → Question variant generation (2.3)

Phase 2 (Vision Gaps)
  └── 2.1 Voice integration ─────────────────── depends on: 1.3 (mentor consolidation)
  └── 2.2 Lesson generation ─────────────────── depends on: 1.4 (evaluation model)
  └── 2.3 Variant generation ────────────────── depends on: 1.4 (evaluation model)
  └── 2.4 Vision interpretation ─────────────── independent

Phase 3 (Cleanup)
  └── 3.1–3.5 ───────────────────────────────── independent of Phases 1–2 (can run in parallel)
```

---

## Rationale Summary

The codebase has strong local patterns (immutable models, `Result<T>` error handling, barrel exports, Riverpod providers, comprehensive ARB localization). The core weakness is **horizontal fragmentation** — the same concept (timers, SR, nudges, evaluation) is independently re-implemented across features. Fixing this is the highest-leverage investment because:

1. **Correctness:** Three incompatible SR algorithms means the spaced repetition system cannot function as intended.
2. **Maintainability:** Every new feature that needs a timer or nudge either duplicates code or picks the wrong existing implementation.
3. **Velocity:** 1.1–1.4 directly unblock the vision features in Phase 2 (voice, lessons, variants, vision).
4. **Test surface:** Consolidation reduces total test files and eliminates cross-feature test duplication.
