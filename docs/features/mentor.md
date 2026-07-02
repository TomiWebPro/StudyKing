# Mentor Mode

## Overview

Mentor Mode is the non-teaching AI companion available outside of lessons. It functions like an intelligent academic mentor — helping with scheduling, planning, motivation, wellbeing, and accountability. The mentor is **proactive**, not just reactive, and sends engagement nudges based on student behavior.

## Key Files

| Layer | Files |
|---|---|---|
| Services | `MentorService`, `MentorContextBuilder`, `MentorScheduleHandler`, `MentorWellbeingService` |
| Tools | `CreatePlanTool`, `GenerateLessonBlocksTool`, `GetStudentStatsTool`, `GetWeakTopicsTool`, `ScheduleLessonTool`, `SearchQuestionsTool` |
| Models | `ChatMessageData`, `MentorAction`, `ProgressReport` |
| Screens | `MentorScreen` |
| Keywords | `MentorKeywords` (intent routing via keyword matching with locale support) |
| Providers | `mentorServiceProvider`, `mentorSessionRepositoryProvider`, `mentorEngagementNudgeRepoProvider`, `mentorProgressTrackerProvider`, `mentorModelIdProvider`, `mentorAttemptRepositoryProvider` |

## Core Services

### MentorService

The central mentor service orchestrating all mentor interactions:

- `initialize()` — Load persisted conversation history and init repos
- `chat(message)` — Streams AI response, uses LLM agent for tool-based interactions, handles planning/scheduling intents
- `checkWellbeingAndGenerateNudges()` — Proactive wellbeing check, returns nudge messages
- `getProgressReport()` — Returns `ProgressReport` with stats, weak topics, badges, recommendations
- `suggestNextAction()` — Returns a suggested `MentorAction` based on recommendations
- `confirmSchedule(proposal)` — Confirm and execute a schedule proposal
- `suggestReschedule(sessionId)` — Suggest a reschedule with pending action creation
- `getRecentNudges(limit?)` — Get recent engagement nudges
- `getUpcomingLessons()` — Get upcoming scheduled lessons
- `hasMeaningfulData()` — Check if student has practice data or subjects
- `planDaysMessage(days)` — Generate plan prompt message
- Uses the LLM agent system for complex multi-step interactions

### MentorContextBuilder

Builds a comprehensive context snapshot for the mentor AI:

- `buildContextPrompt()` — Returns a formatted string with: stats (total attempts, accuracy, study time), plan adherence, days since last activity, missed lessons, active roadmaps with milestones, pending actions, upcoming lessons, weak topics, today's study minutes with daily cap, study streak, late-night sessions
- `loadUpcomingLessons()` — Loads scheduled lessons from planner

### MentorScheduleHandler

Handles scheduling-specific intents:

- `extractScheduleProposal(topicTitle, durationMinutes)` — Create `ScheduleProposal` with proposed time
- `confirmSchedule(proposal)` — Confirm schedule: resolve topic, check conflicts, book via planner
- `suggestReschedule(sessionId)` — Find next free slot and create a pending reschedule action

### MentorWellbeingService

Proactive wellbeing monitoring:

- `checkWellbeingAndGenerateNudges()` — Checks overwork (daily cap exceeded), late-night sessions, revision needed (at-risk questions ≥3), and study streak (inactivity after 48h/7d/14d/30d)
- Generates nudges stored in `EngagementNudgeRepository` with type (`overwork`, `revision`, `planAdjustment`) and severity (`low`, `medium`, `high`)
- Limited to `_maxNudgesPerDay` (5) per day

### Mentor Keywords

`MentorKeywords` provides locale-aware intent routing via keyword matching, allowing the system to detect student intents and route to appropriate handlers. Supports English, Spanish, French, and German keywords for:
- `extractKeywordsByLocale` — Topic extraction ("about ", "for ", "study ", etc.)
- `extractTopicKeywordsByLocale` — Topic entity keywords ("topic ", "subject ", "lesson ")
- `scheduleKeywordsByLocale` — Scheduling intent ("schedule", "programar")
- `rescheduleKeywordsByLocale` — Rescheduling intent ("reschedule", "reprogramar")
- `planKeywordsByLocale` — Plan/roadmap intent ("plan", "roadmap", "milestone")

## Tools

The mentor uses an agent-based tool system for executing actions:

| Tool | Trigger | Action |
|---|---|---|
| `CreatePlanTool` | "Create a study plan" | Generates a new `PersonalLearningPlan` |
| `GenerateLessonBlocksTool` | "Generate lesson content" | Creates lesson content blocks |
| `GetStudentStatsTool` | "How am I doing?" | Returns performance statistics |
| `GetWeakTopicsTool` | "What should I improve?" | Lists weak topics and at-risk questions |
| `ScheduleLessonTool` | "Book a lesson" | Schedules a new lesson |
| `SearchQuestionsTool` | "Find questions about..." | Searches the question bank |

## Engagement Nudges

The mentor proactively engages students through `MentorWellbeingService.checkWellbeingAndGenerateNudges()`:

- **Overwork nudges:** Suggest breaks when daily cap is exceeded
- **Late-night nudges:** Warn about late study sessions
- **Revision nudges:** Prompt review when at-risk questions ≥3
- **Inactivity nudges:** Reach out after 48h (medium), 7d (medium), 14d (high), or 30d (high) of inactivity
- **Streak nudges:** Congratulate after 7+ consecutive study days

Nudges are stored in the `EngagementNudgeRepository` and tracked by date to limit to 5 per day per student.

## Conversation Flow

1. Student sends a message to the mentor
2. `MentorService` checks `hasMeaningfulData()` (redirects if no subjects/attempts)
3. Context is built via `MentorContextBuilder.buildContextPrompt()` and long-term memory
4. If LLM agent is available: agent chat with tool execution (CreatePlan, ScheduleLesson, etc.)
5. If no agent: direct LLM streaming response with conversation memory
6. Post-chat intent handling: scheduling proposals (with confirmation dialog), plan proposals (with roadmap creation dialog), rescheduling, and wellbeing nudge generation
7. Response is streamed to the student with tool call results appended

## Proactive Engagement

`MentorService.checkWellbeingAndGenerateNudges()` is called automatically after each chat interaction and can also be called independently to:

- Detect unusually long study sessions and suggest breaks
- Detect prolonged absence and send re-engagement messages
- Identify late-night study sessions
- Prompt for reviews when spaced repetition items are at risk
- Congratulate on study streaks
