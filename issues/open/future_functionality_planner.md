# [F] Adaptive Practice Engine & Cross-Feature Learning Integration

## Context

The `agent_must_read.md` describes the question system and adaptive practice as **central to the product vision**:

> "Questions should be organized, categorized, linked to sources/topics/syllabi, expanded through generated variants, and used to measure understanding, identify weak areas, and drive adaptive revision."

> "Adaptive practice should be a major component: the system should continuously test understanding, focus on weak areas, revisit old content intelligently, and optimize for retention and mastery rather than simple completion."

The current implementation reveals four critical, interlocking deficiencies that prevent the system from delivering on this vision:

### Deficiency 1: No Scientifically Valid Spaced Repetition Algorithm

The app has **two parallel, unsynchronized** "next review" data sources (`Question.nextReview` at `lib/core/data/models/question_model.dart` and `QuestionMasteryState.nextReview` at `lib/features/practice/data/models/question_mastery_state.dart`), both using a primitive threshold-based interval system (`30min/12h/1d/3d/7d`).

**Neither implements SM-2, FSRS, or any scientifically validated algorithm.** Key gaps:

| Feature | Current State | Standard Practice (SM-2/FSRS) |
|---|---|---|
| Ease factor | Not tracked | Core to SM-2; adjusts per-card difficulty |
| Recall probability | Not computed | Core to FSRS; drives optimal scheduling |
| Confidence grading | `StudentAttempt.confidence` (1-5) collected but unused by SR | Used to adjust intervals |
| Exponential spacing | Linear threshold bands | SM-2: geometric; FSRS: power-law |
| Forgetting curve model | None (rule-based thresholds) | FSRS: DSR (Difficulty, Stability, Retrievability) model |
| Inter-session spacing | Not considered | Spacing effect well-established in learning science |

The `MasteryCalculationService` at `lib/core/services/mastery_calculation_service.dart` computes `readinessScore` and `reviewUrgency` with sensible formulas (recency decay, streak normalization), but these are **never used to drive question selection** in practice sessions — they exist only as computed metadata on `MasteryState`.

### Deficiency 2: Practice Sessions Don't Record Mastery

`PracticeSessionScreen` at `lib/features/practice/presentation/practice_session_screen.dart` validates answers, provides feedback, and saves sessions, but **never calls `MasteryGraphService.recordAttempt()`**. The mastery graph records happen through a separate, untraced pathway:

```
PracticeSessionScreen
  → PracticeSessionService.updateNextReview()  // updates Question.nextReview only
  → PracticeSessionService.autoSaveSession()    // saves Session model
  → PracticeSessionScreen._recordAdherence()    // records plan adherence
  ⚠ NEVER calls MasteryGraphService.recordAttempt()
```

This means:
- Topic-level `MasteryState.accuracy`, `confidenceTrend`, `forgettingRisk`, etc. are **never updated from practice sessions**.
- The dashboard's weak topics, mastery snapshot, and recommendations are based on **stale or missing data**.
- The planner's plan generation reads `MasteryState` readiness scores, which are **not being updated by actual practice**.

There are **two broken things** here: (1) `recordAttempt()` is not called from the practice session flow, and (2) even if it were, `MasteryStateRepository` writes update the Hive box, but `StudyProgressTracker` (used by dashboard and mentor) creates its **own** `AttemptRepository` instance (`dashboard_providers.dart:17-20`), which may be backed by a different Hive box or instance.

### Deficiency 3: Three Overlapping "Session" Concepts — No Coherent Learning Record

The codebase has three separate session-tracking models:

| Model | Feature | Fields | Purpose |
|---|---|---|---|
| `Session` | `core/data/models/session_model.dart` | `id, studentId, subjectId, type (practice/focus/tutoring/manual), startTime, endTime, actualDurationMs, questionsAnswered, correctAnswers, completed` | Generic time tracking |
| `TutorSession` | `teaching/data/repositories/tutor_session_repository.dart` | `id, studentId, topicId, subjectId, status, messages, lessonPlanJson, startTime, endTime, durationMinutes, planAdherenceScore` | AI tutoring sessions |
| `Lesson` | `lessons/data/models/lesson_model.dart` | `id, subjectId, topicId, title, difficulty, blocks[], markscheme, generatedBy` | Static content bundles |

These models are **never cross-referenced**:

- When a practice session completes, it creates a `Session(type: practice)` but does not link to the `TutorSession` that generated the practice material or the `Lesson` that taught the concept.
- When a tutor session completes, it creates a `TutorSession` but **not** a `Session`. The planner/adherence system cannot track tutor time as "study time."
- The `Lesson` model is purely static content with no creation flow — it exists as a displayable artifact but is neither generated by AI nor created by users nor linked to practice.
- `Session.sourceId` exists on the model but is never populated by any caller.

### Deficiency 4: No Exam/Quiz Mode, No Review-of-Mistakes Flow, No Source-Linked Practice

The practice feature has a "weak areas" mode that loads all questions from topics with `accuracy < 0.7`, but:

- Questions are shuffled randomly within the pool — no prioritization of most-at-risk questions.
- There is no timed exam simulation mode.
- There is no "review mistakes" flow at the end of a session showing correct answers.
- There is no "redo incorrect" flow that automatically re-shows missed questions.
- Questions generated by the `ContentPipeline` during ingestion (`Source.generatedQuestionIds`) are created but **never practiced** — there is no flow to practice questions from an ingested source.
- Tutor-session exercises that get persisted as `Question` objects have no review path in the practice feature.

### Additional Cross-Cutting Issues

| Finding | Location | Severity |
|---|---|---|
| `PracticeSessionService.updateNextReview()` updates `Question.nextReview` directly but does NOT update `QuestionMasteryState.nextReview` — the two SR fields diverge | `practice/services/practice_session_service.dart:53-63` | High |
| `SpacedRepetitionRepository.getPracticeQuestions()` queries `Question.nextReview` while `QuestionMasteryStateRepository.getDueQuestions()` queries `QuestionMasteryState.nextReview` — different data sources return different due sets | Dual SR paths | High |
| `MasteryCalculationService` computes `readinessScore` and `reviewUrgency` but no session selector uses these for question ordering | `core/services/mastery_calculation_service.dart` | High |
| `Question.sourceIds` (list of source documents) is populated by `ContentPipeline` but never used for filtering/attribution in practice | `core/data/models/question_model.dart:119` | Medium |
| `PracticeSessionScreen._recordAdherence()` imports `PlanAdapter` inline (`practice_session_screen.dart:72`) instead of dependency injection | Tight coupling | Medium |
| `StudentAttempt.confidence` (1-5 scale) is collected in `PracticeSessionQuestionCard` but never passed to `MasteryGraphService.recordAttempt()` or `SpacedRepetitionService.updateNextReview()` | `practice/data/models/student_attempt.dart` | Medium |
| `PracticeScreen._launchWeakAreasForSubject()` loads ALL questions from weak topics without ordering by mastery level | `practice/presentation/practice_screen.dart:210` | Medium |
| `TutorService.endLesson()` saves exercises as `Question` objects with `source: tutor_session` but there is no practice mode filter for "questions from my tutor sessions" | `teaching/services/tutor_service.dart:95-120` | Medium |
| `DashboardDataLoader` at `dashboard/services/dashboard_data_loader.dart` is completely unused — all data loading is inline in providers | Dead code | Low |

## Impact

| Area | Current State | Target State |
|---|---|---|
| Spaced repetition | Dual unsynchronized fields; 6-band linear thresholds | Single SSOT with SM-2 or FSRS; exponential spacing; ease factor; recall probability |
| Mastery tracking | `recordAttempt()` not called from practice sessions | Every practice answer updates topic mastery + question mastery + spaced repetition |
| Session model | 3 overlapping models with no cross-references | `TutorSession` → creates `Session` for time tracking; `PracticeSession` links to `TutorSession` and `Source` |
| Question selection | Random shuffle + flat pool from weak topics | Prioritized by `readinessScore`, `reviewUrgency`, confidence gaps; AI-difficulty-adaptive |
| Exam/quiz mode | Not available | Timed exam simulation with configurable duration, question count, difficulty mix |
| Mistake review | Not available | End-of-session review with correct answers, explanations, "redo incorrect" |
| Source-linked practice | Source-generated questions exist but unreachable | "Practice from source" flow browsing sources and practicing their generated questions |
| Tutor exercise review | Tutor exercises create `Question` objects but no practice path | "Review tutor exercises" filter in practice mode |
| Essay/canvas evaluation | Length-based (essay) / presence-based (canvas) | AI-evaluated with rubric, partial credit, and concept-level feedback |
| Learning record | `TutorSession` (teaching) and `Session` (practice/focus) in separate tables | Unified learning timeline showing all types of study activity |

## Proposed Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PRACTICE 2.0 ECOSYSTEM                          │
│                                                                     │
│  ┌─────────────────────┐    ┌──────────────────────────────────┐   │
│  │   Learning Science   │    │     Question Selection Engine    │   │
│  │       Engine         │    │                                  │   │
│  │                      │    │  ┌────────────────────────────┐  │   │
│  │  ┌────────────────┐  │    │  │ ReadinessScorer           │  │   │
│  │  │ SpacedRepetition│  │    │  │  - readinessScore → order │  │   │
│  │  │    Engine       │  │    │  │  - reviewUrgency → boost  │  │   │
│  │  │  (NEW)          │  │    │  │  - confidenceGap → select │  │   │
│  │  │  - SM-2 or FSRS │  │    │  └────────────────────────────┘  │   │
│  │  │  - ease factor  │  │    │                                  │   │
│  │  │  - recall prob  │  │    │  ┌────────────────────────────┐  │   │
│  │  │  - log of all   │  │    │  │ SourceLinkedFilter (NEW)   │  │   │
│  │  │   reviews       │  │    │  │  - practice by source      │  │   │
│  │  └────────────────┘  │    │  │  - practice tutor exercises │  │   │
│  │                      │    │  └────────────────────────────┘  │   │
│  │  ┌────────────────┐  │    │                                  │   │
│  │  │ MasteryRecorder │  │    │  ┌────────────────────────────┐  │   │
│  │  │  (NEW)          │  │    │  │ DifficultyAdapter (NEW)    │  │   │
│  │  │  - called from  │  │    │  │  - adaptive difficulty     │  │   │
│  │  │   every practice│  │    │  │  - performance-based       │  │   │
│  │  │  - updates topic│  │    │  │   ordering within session  │  │   │
│  │  │   + question    │  │    │  └────────────────────────────┘  │   │
│  │  │   + next review │  │    └──────────────────────────────────┘   │
│  │  └────────────────┘  │                                          │
│  └─────────────────────┘                                            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Cross-Feature Integrator (NEW)              │   │
│  │                                                              │   │
│  │  TutorSession → creates Session (time tracking)              │   │
│  │  PracticeSession → links to TutorSession / Source            │   │
│  │  Adherence → records from ALL session types uniformly        │   │
│  │  LearningTimelineProvider (NEW) → unified activity feed      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │               Practice Mode Additions                        │   │
│  │                                                              │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐  │   │
│  │  │ Exam Mode      │  │ Mistake Review │  │ Source Practice│  │   │
│  │  │ (timed quiz)   │  │ (redo + show)  │  │ (by source)    │  │   │
│  │  └────────────────┘  └────────────────┘  └────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### New/Refactored Components

1. **`SpacedRepetitionEngine`** — Replaces `SpacedRepetitionService` and `QuestionMasteryState._calculateNextReview()` with a unified algorithm. Implements SM-2 (ease factor, graded recall) with option to swap to FSRS. Single source of truth for `nextReview` calculation. Stores review log entries for full history.

2. **`MasteryRecorder`** — Dedicated service called at the end of every practice/tutor exercise evaluation. Accepts `(studentId, questionId, isCorrect, timeSpentMs, confidence)` and coordinates three updates atomically:
   - `MasteryGraphService.recordAttempt()` for topic + question mastery
   - `SpacedRepetitionEngine.scheduleReview()` for next review date
   - `StudentAttempt` persistence for history

3. **`ReadinessScorer`** — Pure function that takes a set of candidate questions with their `MasteryState`, `QuestionMasteryState`, and `SpacedRepetition` data, and returns them ordered by optimal learning benefit. Factors: `reviewUrgency`, `readinessScore`, days since last attempt, confidence gap, difficulty mismatch.

4. **`DifficultyAdapter`** — Optional mid-session adapter that selects the next question's difficulty based on the student's recent performance streak within the session (e.g., 3 correct → harder; 2 incorrect → easier).

5. **`CrossFeatureIntegrator`** — Single orchestration point that:
   - When a `TutorSession` completes: creates a `Session(type: tutoring)` for time tracking
   - When a practice session completes: links it to the source `TutorSession` or `Source` if applicable
   - Provides unified learning timeline queries

6. **`SessionLearningRecord`** (NEW model) or enhanced `Session` — Adds `lessonIds`, `tutorSessionId`, `sourceIds` fields to `Session` so a unified learning timeline can be rendered.

7. **`ExamSessionService`** — Manages timed exam sessions with configurable parameters: duration, question count per topic/difficulty, subject coverage. Auto-submits on timeout. Returns detailed breakdown by topic.

8. **`MistakeReviewService`** — After a practice/exam session, collects all incorrect questions and presents them with correct answers, explanations, and a "redo" flow.

### SM-2 Algorithm Integration Detail

```
SpacedRepetitionEngine.scheduleReview(
  questionId,
  grade: 0-5 (SM-2 scale mapped from correctness + confidence)
):
  // SM-2 constants
  if grade >= 3:
    if repetitions == 0:
      interval = 1 day
    elif repetitions == 1:
      interval = 6 days
    else:
      interval = round(previousInterval * easeFactor)
    repetitions++
  else:
    repetitions = 0
    interval = 1 day

  easeFactor = easeFactor + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))
  easeFactor = max(1.3, easeFactor)

  nextReview = now + interval

  // If FSRS mode:
  // Use DSR model: stability = f(grade, previousStability, difficulty)
  // Retrievability = exp(-timeElapsed / stability)
  // nextReview when retrievability < targetRetention (e.g., 0.9)
```

### Mastery Recording Flow (Fixed)

```
PracticeSessionScreen._submitAnswer():
  → AnswerValidationService.validate(question, answer)
  → // Display feedback immediately
  → MasteryRecorder.recordAttempt(
      questionId: q.id,
      isCorrect: result.isCorrect,
      timeSpentMs: _timer.elapsedMs,
      confidence: _confidenceRating,  // now collected and passed
    )
      → MasteryGraphService.recordAttempt(...)
        → MasteryStateRepository.updateMastery()   // topic level
        → QuestionMasteryStateRepository.recordAttempt(...)  // question level
      → SpacedRepetitionEngine.scheduleReview(questionId, grade)
        → updates Question.nextReview (single SSOT)
      → AttemptRepository.save(studentAttempt)
  → PlanAdapter.recordFromPracticeSession(...)
  → PracticeSessionService.autoSaveSession()
  → // If mistakes: save for review flow
```

## Affected Files

| File | Role | Required Change |
|---|---|---|
| `lib/features/practice/services/spaced_repetition_service.dart` | Current SR logic | Rewrite to `SpacedRepetitionEngine` with SM-2/FSRS; remove threshold-based intervals; add ease factor, review log |
| `lib/features/practice/data/models/question_mastery_state.dart` | Per-question mastery | Remove `_calculateNextReview()` and `_updateMasteryLevel()` — delegate to `SpacedRepetitionEngine` and `MasteryRecorder`; keep as data-only model |
| `lib/features/practice/services/practice_session_service.dart` | Session orchestration | Delegate `updateNextReview()` to `MasteryRecorder` instead of directly updating `Question.nextReview` |
| `lib/features/practice/presentation/practice_session_screen.dart` | Main practice UI | Call `MasteryRecorder.recordAttempt()` after each answer; collect and pass `confidence`; add end-of-session review flow |
| `lib/features/practice/presentation/practice_screen.dart` | Practice hub | Add "Exam Mode" and "Source Practice" mode cards; wire `ReadinessScorer` for weak-areas ordering |
| `lib/features/practice/services/practice_data_service.dart` | Data orchestration | Add `ReadinessScorer`-based question ordering; add `getSourceLinkedQuestions()` |
| `lib/features/practice/providers/practice_providers.dart` | DI wiring | Add `spacedRepetitionEngineProvider`, `masteryRecorderProvider`, `readinessScorerProvider`, `examSessionServiceProvider`, `mistakeReviewServiceProvider` |
| `lib/features/practice/presentation/practice_session_screen.dart` | Session UI | Add end-of-session review widget showing mistakes with correct answers and redo button |
| `lib/core/services/mastery_graph_service.dart` | Mastery coordination | Ensure `recordAttempt()` is idempotent and safe for concurrent calls from practice and tutor |
| `lib/core/services/mastery_calculation_service.dart` | Mastery metrics | Keep as pure computation; wire into `ReadinessScorer` for question ordering |
| `lib/core/data/models/question_model.dart` | Question model | Remove `nextReview` field from here (move to `SpacedRepetitionEngine`-managed storage) OR synchronize properly |
| `lib/features/sessions/services/study_timer_service.dart` | Timer service | Ensure practice sessions use this for consistency (vs. inline timers) |
| `lib/features/sessions/data/repositories/session_repository.dart` | Session persistence | Enable cross-referencing by `tutorSessionId`, `sourceIds` |
| `lib/features/teaching/services/tutor_service.dart` | Tutor orchestration | On `endLesson()`, also create a `Session(type: tutoring)` for time tracking via `CrossFeatureIntegrator` |
| `lib/features/ingestion/services/content_pipeline.dart` | Question generation | Ensure generated questions are tagged with `sourceId` and retrievable via `SourceRepository` |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | Dashboard data | Fix `AttemptRepository` instance isolation — use shared provider from practice feature |
| `lib/features/dashboard/services/dashboard_data_loader.dart` | Dashboard data aggregation | Either wire into providers or delete as dead code |
| `lib/features/planner/services/planner_service.dart` | Plan generation | Use updated `MasteryState` data (now correctly updated from practice) for readiness-based planning |
| `lib/features/mentor/services/mentor_service.dart` | Mentor context | Fix `completedLessons: 0` hardcode; use cross-feature integrator to count unified sessions |
| `lib/features/practice/presentation/widgets/practice_session_question_card.dart` | Question card during session | Add confidence rating slider/buttons after each answer |
| `lib/features/practice/presentation/screens/exam_session_screen.dart` | **NEW** | Timed exam mode with configurable duration, question pool selection, auto-submit |
| `lib/features/practice/presentation/widgets/mistake_review_widget.dart` | **NEW** | Shows all incorrect answers with correct answer, explanation, and "try again" button |
| `lib/features/practice/presentation/widgets/source_practice_sheet.dart` | **NEW** | Bottom sheet to browse sources and practice their linked questions |
| `lib/features/practice/services/spaced_repetition_engine.dart` | **NEW** | SM-2/FSRS implementation with ease factor, graded recall, review log; single SSOT for `nextReview` |
| `lib/features/practice/services/mastery_recorder.dart` | **NEW** | Coordinates attempt recording across mastery graph, SR engine, and attempt history |
| `lib/features/practice/services/readiness_scorer.dart` | **NEW** | Ordering function for question selection based on multiple readiness signals |
| `lib/features/practice/services/difficulty_adapter.dart` | **NEW** | Mid-session difficulty adjustment based on streak performance |
| `lib/features/practice/services/exam_session_service.dart` | **NEW** | Exam lifecycle: configuration → timed delivery → auto-submit → breakdown results |
| `lib/features/practice/services/mistake_review_service.dart` | **NEW** | Collects incorrect questions from a session, presents with correct answers |
| `lib/core/services/cross_feature_integrator.dart` | **NEW** | Unified session creation: tutor + practice sessions create `Session` records for time tracking |
| `lib/core/data/models/unified_session_model.dart` or update `Session` | **NEW/Update** | Add `tutorSessionId`, `sourceIds`, `lessonIds` linking fields |

## Rationale

1. **Learning science credibility**: SM-2 and FSRS are the most widely validated spaced repetition algorithms. The current 6-threshold-band system has no scientific basis and will produce suboptimal retention. Without credible SR, StudyKing cannot compete with dedicated SRS tools (Anki, SuperMemo) and loses its "scientifically optimized" value proposition.

2. **Mastery tracking is currently a no-op**: The fact that `MasteryGraphService.recordAttempt()` is never called from practice sessions means the entire mastery system (dashboard weak topics, planner readiness scores, mentor progress reports) is operating on **stale or default data**. This is a silent data quality bug that undermines every feature that reads mastery state.

3. **Session model fragmentation creates blind spots**: A student could spend 2 hours in tutor sessions and 1 hour in practice sessions, but the dashboard/weekly trends show only practice time (since `TutorSession` never creates `Session` records). The planner's adherence tracking misses tutor time. This is a data integrity issue that affects student progress visibility.

4. **Exam mode is a table-stakes feature**: Every competing learning platform (Khan Academy, Quizlet, Anki) offers timed exam/quiz modes. Its absence is a visible gap that users notice immediately.

5. **Mistake review drives learning**: Educational research consistently shows that reviewing incorrect answers with correct solutions is one of the most effective learning interventions. The current flow shows correct/incorrect and moves on — no review, no redo, no spaced repetition of mistakes.

6. **Source-generated questions are wasted**: The ingestion pipeline can generate questions from textbooks, PDFs, and other sources (`ContentPipeline.processFullPipeline()`), but these questions have no practice path. This represents wasted AI effort and missed learning opportunities.

7. **Tutor exercise-review loop closes the teaching↔practice gap**: The vision describes tutor sessions that "assign exercises" and practice that "revisit[s] old content." Currently, tutor exercises are saved as `Question` objects but have no practice-mode visibility. Fixing this creates the desired teaching↔practice feedback loop.

8. **Architectural simplification**: Fixing the dual-SR data source (`Question.nextReview` vs `QuestionMasteryState.nextReview`) by creating a single `SpacedRepetitionEngine` SSOT simplifies the entire data model and eliminates a class of subtle bugs where the two sources diverge.

## Acceptance Criteria

### Spaced Repetition Engine
- [ ] `SpacedRepetitionEngine` implements SM-2 algorithm with ease factor, repetition count, and graded recall (0-5).
- [ ] FSRS mode available as optional drop-in replacement via configuration flag.
- [ ] Single source of truth for `nextReview` — `Question.nextReview` field removed or synchronized; `QuestionMasteryState._calculateNextReview()` removed; all review scheduling goes through engine.
- [ ] Review log stored (questionId, timestamp, grade, easeFactor, interval, nextReview) for analytics.
- [ ] Migration path exists for existing `Question.nextReview` and `QuestionMasteryState.nextReview` values (convert to SM-2 initial parameters).
- [ ] Engine handles edge cases: new questions (no history), grade=0 (complete reset), ease factor floor at 1.3.

### Mastery Recording
- [ ] `MasteryRecorder` exists and is called from `PracticeSessionScreen._submitAnswer()` for every answered question.
- [ ] `MasteryRecorder.recordAttempt()` atomically calls `MasteryGraphService.recordAttempt()` + `SpacedRepetitionEngine.scheduleReview()` + `AttemptRepository.save()`.
- [ ] `StudentAttempt.confidence` (1-5) is collected in the practice session UI and passed to `recordAttempt()`.
- [ ] Topic-level `MasteryState.accuracy`, `confidenceTrend`, `forgettingRisk`, `reviewUrgency` update correctly after practice.
- [ ] `MasteryGraphService.recordAttempt()` is idempotent (safe to call multiple times for same attempt).
- [ ] Dashboard weak topics, mentor progress reports, and planner readiness scores reflect up-to-date data from practice.

### Unified Session Model
- [ ] `TutorService.endLesson()` creates a `Session(type: tutoring)` with `actualDurationMs` matching the tutor session duration.
- [ ] `PracticeSessionService.autoSaveSession()` links the `Session` to the originating `TutorSession` or `Source` when applicable (populates `tutorSessionId`/`sourceIds`).
- [ ] `CrossFeatureIntegrator` provides `getUnifiedTimeline(studentId, limit, offset)` returning chronologically-merged sessions of all types.
- [ ] Dashboard weekly trends include tutor session time in study duration calculations.
- [ ] Planner adherence tracking records time from tutor + focus + practice + manual sessions uniformly.
- [ ] Mentor `completedLessons` count uses unified session data instead of hardcoded 0.

### Question Selection & Readiness Scoring
- [ ] `ReadinessScorer` function exists and is used by all practice modes that select multiple questions (quick practice, weak areas, spaced repetition, exam mode).
- [ ] `ReadinessScorer` factors: `reviewUrgency` (weight 0.4), `readinessScore` inverse (weight 0.3), days since last attempt (weight 0.2), confidence gap (weight 0.1).
- [ ] Weak areas mode sorts questions by `ReadinessScorer` priority instead of random shuffle.
- [ ] `DifficultyAdapter` optionally adjusts next question difficulty based on current-session streak (configurable, default off).

### Exam Mode
- [ ] `ExamSessionScreen` allows configuration: duration (15/30/45/60 min), question count, difficulty mix, topics/subjects.
- [ ] Timer counts down; auto-submits remaining questions on expiration.
- [ ] Results screen shows per-topic breakdown, accuracy, time per question, and a "review mistakes" button.
- [ ] Exam sessions are persisted as `Session(type: practice)` with exam metadata.

### Mistake Review
- [ ] After any practice/exam session, incorrect questions are collected and shown in a `MistakeReviewWidget`.
- [ ] Mistake review shows: student's answer, correct answer, explanation (from `Question.explanation` or `Markscheme.explanation`), and a "Redo" button.
- [ ] Redo launches a mini-session with only the previously-incorrect questions.
- [ ] Questions remain in mistake-review pool until answered correctly at least once.

### Source-Linked Practice
- [ ] `SourcePracticeSheet` lists all sources with `generatedQuestionIds.isNotEmpty`.
- [ ] Tapping a source launches a practice session filtered to that source's generated questions.
- [ ] "Practice from tutor exercises" filter available to practice questions with `source: tutor_session`.

### Evaluation Improvements
- [ ] Essay answers evaluated via AI (delegates to `LlmService`) with rubric-based scoring instead of length-based.
- [ ] Canvas drawing answers evaluated for content presence + basic shape detection or AI vision interpretation.
- [ ] `AnswerValidationService` handles new evaluation types without breaking existing MCQ/text evaluation.

### Testing
- [ ] `SpacedRepetitionEngine` unit tests: SM-2 algorithm correctness, ease factor adjustment, interval calculation, grade boundary cases, FSRS mode, migration path.
- [ ] `MasteryRecorder` unit tests with fake `MasteryGraphService`, fake `SpacedRepetitionEngine`, fake `AttemptRepository`.
- [ ] `ReadinessScorer` unit tests verifying ordering weights and edge cases (empty pool, single question, all-zeros).
- [ ] `ExamSessionService` unit tests: timed auto-submit, configuration validation, result breakdown.
- [ ] `MistakeReviewService` unit tests: question collection, answer comparison, redo session creation.
- [ ] `CrossFeatureIntegrator` unit tests: `TutorSession` → `Session` creation, timeline merging, correct type attribution.
- [ ] Widget tests for `ExamSessionScreen`, `MistakeReviewWidget`, `SourcePracticeSheet`.
- [ ] Existing practice feature tests continue to pass (with updates for refactored dependencies).

### Zero Regressions
- [ ] Zero analysis warnings introduced.
- [ ] All existing unit and widget tests pass.
- [ ] No Hive migration issues for existing `Question.nextReview` values (migration path defined and tested).

## Out of Scope

- Full FSRS parameter optimization (requires large review history dataset — can be added later)
- Multi-player / collaborative practice
- Peer-reviewed answers and community question banks
- Real-time multiplayer quiz competitions
- Video-based practice (watching video then answering questions)
- "Explain like I'm 5" AI-generated rephrasing of questions
