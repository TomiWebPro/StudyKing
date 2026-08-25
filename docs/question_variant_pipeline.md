# Question Variant Pipeline

Variants let StudyKing re-test the *same concept* with different values so students
build real understanding instead of memorising a fixed answer. This supports adaptive
practice and spaced repetition (see `agent_must_read.md`).

## Flow

1. **Trigger** — A caller (e.g. the question bank UI or a bulk pipeline) requests
   variants for a source `Question`.
2. **Generation** — `QuestionVariantService.generateVariants` sends the source
   question to the LLM using the prompt in
   `lib/features/questions/services/question_variant_prompts.dart`. The prompt asks
   for `N` concept-preserving, value-varying variants as a JSON array
   (`text`, `options`, `correctAnswer`, `explanation`).
3. **Persistence & linking** — Each variant is saved as a new `Question`. The source
   and every variant are cross-linked via `Question.variantIds`:
   - `source.variantIds` lists all generated variant ids.
   - each variant's `variantIds` lists the source id and its sibling variant ids.
   This bidirectional linkage lets the system navigate the "family" of a question.
4. **Adaptive retry** — During practice, when a question is answered incorrectly,
   `QuestionVariantService.selectVariantForRetry` picks one of the *already generated*
   variants (no inline LLM call) and the practice session queues it immediately after
   the current question, so the student retries the concept with fresh values.

## Conventions

- All public methods return `Result<T>` (`core/errors/result.dart`).
- LLM errors and parse failures are logged via a `static final` `Logger` and surfaced
  as `Result.failure`; the service never throws.
- Variant generation is a deliberate, on-demand (or bulk) operation. Live retry only
  reuses persisted variants to keep practice responsive and offline-safe.
