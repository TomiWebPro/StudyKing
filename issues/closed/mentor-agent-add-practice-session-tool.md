# Mentor Agent: Add Practice Session Initiation Tool

**Severity:** major
**Affected area:** Mentor Mode — Agent Toolset
**Reported by:** codebase audit

## Description

The mentor agent cannot initiate practice sessions. When a student says "I want to practice weak topics" or "Give me a quiz on calculus," the agent must respond with text alone — it cannot create practice sessions, select questions, or launch spaced repetition reviews.

The agent has a `search_questions` tool that can find questions by topic/keyword, but it returns question IDs and text as data — it doesn't create an actionable practice experience. The student must manually navigate to the Practice tab and set up their own session.

## Expected behavior

The mentor agent should be able to:
- Create a practice session with specific questions (by topic, difficulty, type)
- Launch a spaced repetition review of due questions
- Start a weak areas practice session
- Create a timed exam session with configurable parameters
- Set focus mode with inline practice for the current topic

## Actual behavior

The agent can only search questions (returning text data) and suggest study topics verbally. No session initiation capability exists.

## Code analysis

- `lib/features/practice/services/spaced_repetition_service.dart` — `getQuestionsDueForReview()`, `getPracticeQuestions()`
- `lib/features/practice/services/exam_session_service.dart` — `createExamSession()` with full configuration
- `lib/features/practice/presentation/screens/practice_screen.dart:353-435` — `_launchWeakAreasForSubject()` weak area practice flow
- `lib/features/practice/services/readiness_scorer.dart` — Scores and orders questions for optimal selection
- `lib/features/mentor/services/tools/search_questions_tool.dart` — Current tool only returns question data, doesn't create sessions

## Suggested approach

1. **Create a new `CreatePracticeSessionTool`** implementing `AgentTool`:
   ```dart
   class CreatePracticeSessionTool extends AgentTool {
     name: 'create_practice_session'
     description: 'Create and launch a practice session for the student.'
     parameters: {
       type: 'object',
       properties: {
         mode: {
           type: 'string',
           enum: ['spaced_repetition', 'weak_areas', 'topic_focus', 'at_risk', 'exam'],
           description: 'Type of practice session'
         },
         subjectId: {type: 'string'},
         topicId: {type: 'string'},
         questionCount: {type: 'integer', default: 10},
         durationMinutes: {type: 'integer'}, // for exam mode
         difficultyQuotas: { // for exam mode
           type: 'object',
           properties: {
             easyCount: {type: 'integer'},
             mediumCount: {type: 'integer'},
             hardCount: {type: 'integer'},
           }
         }
       },
       required: ['mode'],
     }
   }
   ```

2. **Return confirmation with session details**:
   ```json
   {
     "success": true,
     "sessionId": "practice_001",
     "questionCount": 10,
     "mode": "weak_areas",
     "estimatedDuration": "15 minutes",
     "topicsCovered": ["integration", "derivatives"]
   }
   ```

3. **Wire through existing practice services** — `SpacedRepetitionService`, `ExamSessionService`, `ReadinessScorer`

4. **Navigate the user to the practice screen** after session creation, or display an inline quick-practice within the mentor chat
