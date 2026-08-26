# Questions: Implement Active Question Variant Generation Pipeline

**Severity:** minor
**Affected area:** Questions — Question Variants
**Reported by:** codebase audit

## Description

The `Question` model has a `variantIds` field (`List<String>`) designed to store links to variant questions, and the vision document states questions should be "expanded through generated variants." However, **no code exists that actually generates question variants**. The variant infrastructure is structural scaffolding only — there is no pipeline to create variants, no AI prompts to generate them, and no UI to manage them.

Question variants are essential for the adaptive practice vision:
- A student who answers a question incorrectly should be shown a variant (same concept, different numbers/values) for retesting
- Variants prevent memorization of answers rather than understanding of concepts
- Spaced repetition is more effective when each review presents a slightly different version of the question

## Expected behavior

The system should:
- Automatically generate 3-5 variants when a question is created (or on demand)
- Present variant questions when a student needs retesting on a concept they struggled with
- Track variant-specific and base-question-level mastery separately
- Allow the AI tutor to request variants during a lesson for additional practice
- Show variant relationships in the question bank UI

## Actual behavior

`variantIds` field exists on `Question` but is never populated. No variant generation logic exists anywhere in the codebase.

## Code analysis

- `lib/core/data/models/question_model.dart:17` — `List<String> variantIds` field exists
- `lib/features/questions/data/repositories/question_repository.dart` — CRUD operations but no variant-specific methods
- `lib/features/practice/services/spaced_repetition_engine.dart` — SM-2 engine works on individual questions, no variant awareness
- `lib/features/practice/services/readiness_scorer.dart` — No variant deduplication in scoring
- `lib/features/ingestion/services/content_pipeline.dart:274-319` — Question generation creates standalone questions, not variant families

## Suggested approach

1. **Create a `QuestionVariantGenerator` service** that:
   - Takes a base `Question` and uses the LLM to generate variants (change numeric values, rephrase, swap examples)
   - Validates variants are functionally equivalent (same concept being tested)
   - Stores variants with a `variantGroupId` linking them to the base question
   - Handles different question types appropriately (MCQ variants get different distractors, typed-answer variants get different values)

2. **LLM prompt for variant generation**:
   ```
   Generate 3 variants of this question that test the same concept but with different values/wording.
   Original: {question text}
   Original answer: {correctAnswer}
   
   For each variant, provide:
   1. The variant question text
   2. The correct answer
   3. (For MCQ) New distractors
   
   Ensure variants are pedagogically equivalent — same difficulty, same concept, different surface form.
   ```

3. **Update the mastery system** — Variant mastery should contribute to base-question mastery:
   - Getting a variant correct counts toward the base question's mastery
   - The system should ensure the student sees at least 2 different variants before marking a question as "mastered"

4. **Update the readiness scorer** — When scoring questions for practice, give preference to showing variants of questions the student previously got wrong

5. **Add variant management to the question bank UI** — Show variant groups, allow manual creation/editing of variants, mark base question vs variant in the list
