# Practice & Spaced Repetition

## Overview

The Practice feature is the adaptive question practice system. It combines multiple practice modes with a spaced repetition engine to optimize long-term retention. Students can practice questions, review mistakes, take exam simulations, and track mastery at both the question and topic level.

## Key Files

| Layer | Files |
|---|---|---|
| Services | `PracticeSessionService`, `ExamSessionService`, `SpacedRepetitionService`, `SpacedRepetitionEngine`, `MasteryRecorder`, `MistakeReviewService`, `PracticeDataService`, `ReadinessScorer`, `QuestionTypeLocalizer` |
| Repositories | `MasteryGraphRepository`, `QuestionEvaluationRepository`, `TopicDependencyRepository` |
| Models | `PracticeAnswerRecord`, `PracticeSessionResult`, `StudentAttempt`, `ScoredQuestion`, `MistakeEntry`, `ExamConfig`, `ExamQuestionResult`, `ExamResult`, `QuestionSRData`, `ReviewLogEntry`, `SM2Result` |
| Screens | `PracticeScreen`, `PracticeSessionScreen`, `ExamSessionScreen`, `PracticeResultsScreen`, `ReviewAnswersScreen` |
| Widgets | `PracticeModeCard`, `PracticeModeGrid`, `PracticeModeOption`, `PracticeModeSheet`, `PracticeSessionQuestionCard`, `PracticeEmptyState`, `PracticeFeedbackWidget`, `ConfidenceSelector`, `SubjectSelectionSheet`, `TopicSelectionSheet`, `WeakAreasSheet`, `SpacedRepetitionSheet`, `SourcePracticeSheet`, `MistakeReviewWidget`, `PracticeSessionNavButtons`, `PracticeSessionStatsBar`, `PracticeSheetTemplate`, `SubjectPracticeCard` |

## Core Services

### PracticeSessionService

Manages a practice session timer and auto-save:

- `startTimer()` — Start session timer with periodic elapsed time notification via `elapsedNotifier`
- `cancelTimer()` — Stop the timer
- `autoSaveSession(questionsAnswered, correctAnswers)` — Save a session record to `SessionRepository`
- `updateNextReview(questionId, isCorrect)` — *(Deprecated)* Use `MasteryRecorder.recordAttempt` instead

### SpacedRepetitionService / SpacedRepetitionEngine

The spaced repetition system (SM-2 inspired):

- **Engine:** `SpacedRepetitionEngine` implements the SM-2 algorithm with `scheduleReview()`, `migrateFromLegacy()`, `computeRecallProbability()`, `mapConfidenceToGrade()`
- **Service:** `SpacedRepetitionService` manages scheduling, due items, and review prompts:
  - `getQuestionsDueForReview(asOf?)` — Get questions due based on next_review date
  - `isQuestionDueForReview(question, asOf?)` — Check if a specific question is due
  - `getQuestionsDue(asOf?)` — Same as above with error handling for closed box
  - `updateNextReviewDate(questionId, masteryLevel)` — Update next review using SM-2
  - `getPracticeQuestions(subjectId)` — Get all practice questions for a subject
  - `getTopicTimeDue(topicId)` — Get all questions for a topic
  - `getSubjectDueCount(subjectId)` — Count due questions for a subject
- **Factors:** Question difficulty, student confidence (mapped to SM-2 grade), previous performance, time since last review
- **Output:** Recommended review intervals, next review dates, serialized SM-2 state (`QuestionSRData`)

### ExamSessionService

Manages exam simulation mode:

- `selectQuestions(pool, config)` — Select questions by subject, topic, difficulty distribution (easy/medium/hard counts)
- `startExam(config)` — Start timed exam with countdown via `timeRemainingNotifier`
- `isTimeUp()` — Check if time has expired
- `finishExam(config, questionResults, autoSubmitted?)` — End exam, save session and `ExamResult` to Hive
- `cancelExam()` — Cancel an active exam
- `getSavedExamResults()` — Static method to retrieve past exam results
- Timed sessions with configurable duration and question count
- Simulates exam conditions (no hints, sequential questions)
- Generates an exam score, topic breakdown, and average time per question

### MasteryRecorder

The single source of truth for recording practice attempts. Records and updates mastery state:

- `recordAttempt(studentId, questionId, subjectId, topicId, isCorrect, timeSpentMs, confidence, userAnswer)` — Records a full attempt: maps confidence to SM-2 grade, schedules next review via `SpacedRepetitionEngine`, creates a `StudentAttempt`, updates topic mastery via `MasteryGraphService`, updates question SM-2 state, and updates `QuestionMasteryState`
- Persists to `AttemptRepository`, `QuestionRepository`, `QuestionMasteryStateRepository`, and `MasteryGraphService`

### MistakeReviewService

Manages review of incorrect answers:

- `getMistakesFromSession(studentId, subjectId, after?)` — Get mistakes from a session period, deduplicated by question
- `getPendingMistakes(studentId, subjectId)` — Get mistakes where the last attempt was incorrect and no subsequent correct attempt exists
- `isQuestionCorrected(questionId)` — Check if a question has ever been answered correctly
- `extractRedoQuestions(mistakes)` — Extract `Question` list from `MistakeEntry` list for re-practice
- Each `MistakeEntry` contains the question, attempt, correct answer, and explanation

### ReadinessScorer

Pre-session readiness assessment:

- `scoreQuestions(questions)` — Scores a list of questions by urgency (40%), readiness inverse (30%), days since last attempt (20%), confidence gap (10%), and question difficulty (5%)
- Returns `List<ScoredQuestion>` sorted by descending score for optimal review ordering
- Loads topic and question mastery data lazily from `MasteryGraphService`

### PracticeDataService

Data aggregation for practice metrics:

- `fetchSubjects()` — Get all subjects
- `loadDueCounts(subjects)` — Load due review counts per subject
- `loadTopicsWithNames(questionRepo)` — Build topic ID → name map
- `loadTopicIds(questionRepo)` — Get all unique topic IDs from questions
- `loadWeakAreaQuestions(masteryService)` — Get questions from weak topics

### QuestionTypeLocalizer

An extension on `QuestionType` enum providing locale-aware labels:

- `localizedLabel(l10n)` — Returns translated label for each question type (multiple choice, multiple select, text answer, diagram, essay, step-by-step, math, graph, file upload, audio recording)

## Question Types

The practice system supports multiple input modes (defined by `QuestionType` enum):

| Type | Description |
|---|---|
| `singleChoice` | Single-selection multiple choice |
| `multiChoice` | Multi-selection multiple choice |
| `typedAnswer` | Typed text response |
| `canvas` | Hand-drawn/diagram responses |
| `essay` | Long-form written response |
| `stepByStep` | Step-by-step solution input |
| `mathExpression` | Mathematical expression input |
| `graphDrawing` | Graph plotting |
| `fileUpload` | Image/document upload |
| `audioRecording` | Spoken answer recording |

## Practice Modes

| Mode | Description |
|---|---|
| **Free Practice** | Random or topic-selected questions at student's pace |
| **Spaced Repetition** | Algorithmically scheduled review of past questions |
| **Exam Mode** | Timed, sequential exam simulation |
| **Weak Areas** | Targeted practice on identified weak topics |
| **Source Practice** | Questions linked to a specific study source |

## Mastery Model

Mastery is tracked at two levels:

1. **Question Level** (`QuestionMasteryState`):
   - Per-question confidence, ease factor, interval, review count, SM-2 state
   - Next review date for spaced repetition via `QuestionSRData` (repetitions, ease factor, previous interval, last review, review log)

2. **Topic Level** (`MasteryState`):
   - Aggregate mastery percentage for a topic with accuracy, review urgency, readiness score, mastery level, current streak
   - Based on performance across all questions in the topic via `MasteryGraphService`
   - Used for identifying weak areas and readiness scoring

## SM-2 Algorithm (`SpacedRepetitionEngine`)

- Grade 0-5 input (mapped from isCorrect + confidence via `mapConfidenceToGrade`)
- Initial interval: 1 day, second interval: 6 days
- Ease factor starts at 2.5, min 1.3
- Repetitions reset to 0 on grade < 3
- Full review log maintained per question via `ReviewLogEntry`
- `computeRecallProbability()` based on elapsed time and stability (retrievability)

## Workflow

1. **Start:** Student selects practice mode, subject, and topic/source via bottom sheets (`SubjectSelectionSheet`, `TopicSelectionSheet`, `WeakAreasSheet`, `SpacedRepetitionSheet`, `SourcePracticeSheet`)
2. **Session:** Questions are presented one at a time with appropriate input UI (`PracticeSessionQuestionCard`)
3. **Answer:** Student provides answer and rates confidence (`ConfidenceSelector`)
4. **Feedback:** Correct answer is shown with explanation via `PracticeFeedbackWidget`, including option to view detailed markscheme
5. **Mastery Update:** `MasteryRecorder.recordAttempt()` updates SM-2 state, topic mastery, question mastery, and creates attempt record
6. **Completion:** `PracticeResultsScreen` shows stats with topic breakdown and review option
7. **Review:** `ReviewAnswersScreen` for session review, `MistakeReviewWidget` for pending mistake review
