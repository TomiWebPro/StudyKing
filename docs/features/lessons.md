# Lessons Feature

## Overview

The Lessons feature provides structured, AI-generated learning content organized by topic. Each lesson is composed of typed blocks (text, slides, quizzes, exercises, examples, summaries) that form an interactive learning session. Lessons can be generated from source content via the ingestion pipeline, created manually, or generated on-demand from a topic. The feature also tracks tutoring session status and integrates with the AI tutor.

## Key Files

| Layer | Files |
|---|---|
| Services | `SessionQueryService`, `LessonAgentService` |
| Repositories | `LessonRepository` |
| Models | `Lesson`, `LessonBlock` |
| Screens | `TopicListScreen`, `LessonListScreen`, `LessonDetailScreen` |
| Widgets | `LessonListItem`, `LessonBlockCard` |
| Providers | `lessonRepositoryProvider`, `lessonServiceProvider`, `lessonAgentServiceProvider`, `tutorSessionRepositoryProvider` |

## Core Services

### SessionQueryService

Queries lesson-related sessions and computes progress metrics:

- `getLessonsForStudent(studentId)` — Get all sessions for a student
- `getLessonsByTopic(studentId, topicId)` — Filter sessions by topic
- `getTopicsWithLessons(studentId)` — Get distinct topics that have associated sessions
- `getLessonCountBySubject(studentId)` — Count sessions grouped by subject
- `getCompletionRate(studentId)` — Ratio of completed to total sessions
- `getTotalStudyMinutes(studentId)` — Sum of all session durations
- `getRemainingLessonCount(studentId, subjectId)` — Count of incomplete sessions for a subject
- `getProgressBySubject(studentId)` — Per-subject completion percentages
- `getRecentLessons(studentId, limit)` — Most recent sessions
- `getUpcomingLessons(studentId)` — Scheduled but not yet started sessions

### LessonAgentService

Generates structured lessons using an LLM:

- `generateLesson(subjectId, topicId, topicTitle, localeName)` — Generate a full lesson with blocks via LLM, persist to repository
- `generateLessonFromSource(subjectId, topicId, topicTitle, sourceContent, localeName)` — Generate a lesson from ingested source content
- Internally calls `_generateLessonBlocks` which prompts the LLM with a structured system prompt
- Parses the LLM response into `LessonBlock` objects from JSON or markdown-style text with block markers (`#slide`, `#quiz`, `#exercise`, `#summary`, `#example`)
- Falls back to simple text blocks if LLM parsing fails

## Key Models

| Model | Purpose |
|---|---|
| `Lesson` | A structured learning unit with blocks, difficulty, generation source (AI/manual), and creation timestamp |
| `LessonBlock` | A single content block within a lesson, typed as `slide`, `quiz`, `exercise`, `example`, `summary`, or `text`, with content and optional answer key |

### LessonBlockType

| Block Type | Purpose |
|---|---|
| `slide` | Presentation-style content with full-screen viewer |
| `quiz` | Interactive question with answer validation |
| `exercise` | Open-ended practice with text input |
| `example` | Illustrated concept with highlighted styling |
| `summary` | Key takeaways with distinct styling |
| `text` | Plain explanatory content |

## Lesson Lifecycle

1. **Generation** — Lessons are created either by `LessonAgentService.generateLesson()` (on-demand from a topic) or by `ContentPipeline.processFullPipeline()` (from ingested source content)
2. **Persist** — The lesson (with all blocks) is saved to the `LessonRepository` Hive box
3. **Browse** — `TopicListScreen` displays all topics; tapping one opens `LessonListScreen` filtered to that topic
4. **View** — `LessonDetailScreen` loads the lesson and displays blocks in a scrollable list
5. **Interact** — Quiz blocks accept answers with client-side validation; exercise blocks accept free-text input; slide blocks offer a full-screen page viewer
6. **AI Tutor** — Users can open the AI tutor from the lesson detail screen, passing the topic context

## Topic Browsing

- `TopicListScreen` loads all topics from the topic repository and presents them as a list
- Each topic card navigates to `LessonListScreen` with the topic ID
- `LessonListScreen` loads lessons for the topic, fetches `LessonRepository.getByTopic(topicId)`, and concurrently loads tutor session statuses to show completion badges
- If no lessons exist, the screen displays an empty state with a prompt to start AI tutoring

## UI Description

- **LessonListItem** — Card showing lesson title, block count, and status chip (completed/in progress/not started) with play icon
- **LessonBlockCard** — Renders each block type with appropriate styling:
  - Slides: Gradient background, full-screen page viewer with page indicators
  - Quizzes: Answer input with client-side validation against answer key, correct/incorrect feedback
  - Exercises: Multi-line text input with submit, displays submitted answer
  - Examples: Tertiary container background with lightbulb icon
  - Summaries: Primary container background with checklist icon
  - Text: Plain card with description icon
- **LessonDetailScreen** — Bottom app bar with elapsed timer and AI tutor launch button; back-press protection when timer is active
