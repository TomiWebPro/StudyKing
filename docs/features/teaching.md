# Teaching / Tutor Mode

## Overview

Teaching Mode provides an interactive AI-powered tutor within structured lessons. It is the primary active learning environment where the AI functions as a real tutor — explaining concepts, assigning exercises, reviewing answers, and adapting to the student's understanding level.

## Key Files

| Layer | Files |
|---|---|---|
| Services | `TutorService`, `ConversationManager`, `ExerciseEvaluator`, `ConversationPhase` |
| Repositories | `ConversationRepository`, `TutorSessionRepository` |
| Models | `TutorSession`, `ConversationMessage`, `LessonPlan`, `EvaluationResult`, `LessonSection` |
| Screens | `TutorScreen` |
| Widgets | `ChatBubble`, `LessonProgressBar`, `VoiceBar` |
| Prompts | `prompts.dart` (system prompts for the tutor AI) |
| Adapters | `ConversationMessageAdapter`, `TutorSessionAdapter` |

## Core Services

### TutorService

Manages the tutoring session lifecycle:

- `startLesson(studentId, subjectId, topicId, topicTitle, durationMinutes, scheduledSessionId?, localeName)` — Begin a new tutoring session, create lesson plan, and persist blocks
- `endLesson()` — End the current session, save to repo, record mastery, persist exercises, generate summary
- `cancelActiveSession()` — Cancel/discard the current session without saving
- `getActiveSession()` — Check for orphaned/incomplete sessions
- `getLessonHistory(studentId)` — Load past lesson sessions
- `getSessionMessages(sessionId)` — Get messages for a session
- `getStats(studentId)` — Get aggregated session stats

### ConversationManager

Manages the conversational flow during a tutoring session:

- Maintains conversation history using `ConversationMemory` (max 20 turns)
- Determines conversation phase and handles phase transitions
- `sendMessage(content)` — Streams AI response with adaptive chunk pacing
- `processImage(base64Image)` — Streams AI analysis of submitted images
- `generateLessonPlan(durationMinutes)` — Generates lesson plan via LLM with fallback
- `generateSummary()` — Generates session summary via LLM
- Tracks exercise count, correct count, consecutive incorrect answers, adaptive pace
- `toSession()` — Converts current state to `TutorSession`

### ConversationPhase

An enum representing the current phase of a tutoring conversation:

- `greeting` — Initial greeting and lesson start
- `teaching` — Active concept explanation and Q&A
- `exercise` — Practice and application exercises
- `feedback` — Reviewing exercise responses and providing feedback
- `adaptiveReview` — Deeper review after consecutive incorrect answers (≥2)
- `closing` — Summary and wrap-up when time expires or student ends

### ExerciseEvaluator

Evaluates student answers to exercises during lessons using LLM-based evaluation:

- `evaluate(question, studentAnswer, subjectId, topicTitle)` — Evaluates answer and returns `EvaluationResult` with score (0-1), explanation, optional partial credit, concept breakdown, correct answer, and exercise type
- Supports custom system/user prompts for specialized evaluation scenarios

## Key Models

| Model | Purpose |
|---|---|
| `TutorSession` | Active tutoring session with status, timing, progress, confidence rating, lesson plan |
| `ConversationMessage` | Individual chat message with role, type, content, timestamp, tool call metadata |
| `LessonPlan` | AI-generated lesson plan with goals, sections (explanation/exercise/review/summary/quiz), checkpoints |
| `EvaluationResult` | Exercise evaluation with score, explanation, partial credit, concept breakdown, correct answer |
| `LessonSection` | A section within a lesson plan with title, duration, and type |

## User Interface

- **Chat-based interface** with AI tutor (similar to messaging apps)
- **Lesson progress bar** showing time remaining and content coverage
- **Phase indicator** showing current conversation phase (greeting, teaching, exercise, feedback, adaptiveReview, closing)
- **Voice input** support for natural spoken interaction
- **Image capture** from camera or gallery for visual Q&A
- **Drawing canvas** for submitting hand-drawn responses
- **Slides view** toggle for inline lesson block slideshow
- **Rich content rendering** for math expressions, code, and diagrams
- **Voice output** toggle for AI tutor spoken responses
- **End-of-lesson summary** dialog with stats and follow-up practice options
- **Retry banner** for failed messages with reconnection support

## Session Lifecycle

1. **Start:** Student selects topic, lesson initializes, prerequisites are checked
2. **Plan:** AI generates a lesson plan with sections, goals, and checkpoints
3. **Greet:** AI sends a greeting (contextual for scheduled vs. ad-hoc lessons)
4. **Teach:** Interactive teaching with adaptive phase transitions (teaching ↔ exercise ↔ feedback ↔ adaptiveReview)
5. **Closing:** Transitioned automatically when time runs out or explicitly by user, with a 3-minute grace period
6. **Save:** Session is saved to history, mastery is recorded, exercises are persisted as questions, lesson blocks are updated, long-term memory summary is generated
7. **Wrap-up Dialog:** Shows session duration, exercise count, correct count, adaptive pace; offers practice follow-up actions

## Background Tasks

After a lesson ends, the tutor enqueues background tasks via `LlmAgent`:
- Adherence check update
- Weak topic re-analysis
- Next topic lesson pre-generation

## Orphaned Session Detection

`TutorService.getActiveSession()` checks for active but incomplete tutor sessions. If found, the student is prompted to either save, discard, or continue the orphaned session.
