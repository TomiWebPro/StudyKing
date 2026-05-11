# Issue: Build a Unified Mastery Graph and Personal Learning Plan Engine

## Why this matters
StudyKing already has the raw signals for adaptive learning (attempt history, topic progress, question review scheduling, confidence, and time-on-task), but those signals are split across multiple disconnected models and services. This makes personalization shallow and hard to scale into roadmap features like reliable study plans, prerequisite-aware sequencing, and teacher-grade analytics.

This issue proposes a high-leverage future functionality initiative: a **Unified Mastery Graph** that powers a **Personal Learning Plan Engine**.

## Current gaps observed in codebase
- Redundant/overlapping answer schema creates ambiguity around the source of truth for correctness and feedback.
  - `lib/core/data/models/question_model.dart` (inline `markscheme`, `correctAnswer`)
  - `lib/core/data/models/markscheme_model.dart` (Markscheme model)
  - `lib/features/questions/models/markscheme_model.dart` (second Markscheme model with different shape)
- Progress and adaptivity logic is fragmented across repositories/services with inconsistent granularity.
  - `lib/core/data/models/topic_progress_model.dart`
  - `lib/core/data/models/study_session_model.dart`
  - `lib/core/data/models/student_attempt_model.dart`
  - `lib/core/services/adaptive_practice_engine.dart` (in-memory `_questionStates`, not persisted)
  - `lib/core/data/repositories/spaced_repetition_repository.dart` (question-level due dates)
- Topic intelligence is under-modeled for roadmap features (no explicit prerequisite graph, dependency weighting, or mastery confidence intervals).
  - `lib/core/data/models/topic_model.dart`
- Analytics currently infer topic mapping from string patterns rather than stable relationships.
  - `lib/core/services/study_progress_tracker.dart` (e.g., `questionId` parsing/contains checks)

## Proposed functionality (future plan)
Create a **Mastery Graph domain** that normalizes learning state at student x topic x question level, then use it to generate dynamic study plans.

### Phase 1: Data contract unification
- Define canonical models for:
  - Question evaluation schema (single markscheme contract)
  - Mastery state per topic/question (accuracy, confidence trend, speed trend, forgetting risk)
  - Topic dependency metadata (prerequisites, downstream topics, syllabus weight)
- Introduce versioned DTO/adapters so existing data can still load during migration.

### Phase 2: Persisted mastery engine
- Replace ephemeral adaptivity state with persisted mastery snapshots updated after every attempt/session.
- Compute a stable readiness score per topic and a review urgency score per question.
- Keep both short-cycle signals (recent streak) and long-cycle signals (retention decay).

### Phase 3: Personal Learning Plan generation
- Generate a rolling 7-day plan with:
  - Daily targets (time + question count)
  - Priority topics (weakness + prerequisite pressure)
  - Review queue (due + at-risk items)
  - Stretch goals for high-performing learners
- Return explainable recommendations ("why this is next") for user trust.

### Phase 4: Product surfaces
- Student dashboard widgets: "Today’s Plan", "At Risk Topics", "Ready to Advance".
- Optional teacher/mentor view: cohort risk heatmap and intervention suggestions.

## Affected files/systems (expected)
- Models:
  - `lib/core/data/models/question_model.dart`
  - `lib/core/data/models/topic_model.dart`
  - `lib/core/data/models/topic_progress_model.dart`
  - `lib/core/data/models/student_attempt_model.dart`
  - `lib/core/data/models/study_session_model.dart`
  - `lib/core/data/models/markscheme_model.dart`
  - `lib/features/questions/models/markscheme_model.dart`
- Repositories/services:
  - `lib/core/data/repositories/attempt_repository.dart`
  - `lib/core/data/repositories/progress_repository.dart`
  - `lib/core/data/repositories/spaced_repetition_repository.dart`
  - `lib/core/services/adaptive_practice_engine.dart`
  - `lib/core/services/study_progress_tracker.dart`

## Acceptance criteria
- A single canonical markscheme/evaluation contract is defined and used by new logic; legacy format is supported via adapters.
- Mastery state is persisted (not only in memory) and updated on each attempt with deterministic rules.
- A topic dependency representation exists and is used when ranking what to study next.
- A plan-generation API/service returns a 7-day personal plan with explainability fields.
- Existing progress and spaced-repetition flows continue to function during migration (no data loss for existing users).
- At least one dashboard surface can consume and display the generated plan.
- Instrumentation is added for plan adherence and mastery improvement so impact can be measured.

## Rationale for prioritization
This is a roadmap-level multiplier: it consolidates confusing/redundant data paths and unlocks high-value future features (truly adaptive sequencing, credible progress guidance, better retention outcomes, and eventually cohort intelligence) without repeatedly patching isolated services.
