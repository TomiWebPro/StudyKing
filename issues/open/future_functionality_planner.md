# Future Functionality: Conversational AI Tutor Teaching Mode & Mentor Mode

## Summary

The current lesson system (`lib/features/lessons/`) is a read-only content viewer — it displays pre-existing lesson blocks with no AI interactivity. The Planner screen (`lib/features/planner/`) generates static, trivial schedules with hardcoded topic cycling. Neither the conversational AI tutor (Teaching Mode) nor the persistent AI mentor (Assistant/Mentor Mode) described in the vision exist.

This issue tracks the implementation of both AI interaction modes, which are the core value proposition of StudyKing.

---

## Context

### Current State

- **LessonDetailScreen** (`lib/features/lessons/presentation/lesson_detail_screen.dart:93-128`): Static `ListView` of pre-saved `LessonBlock` cards. Timer counts elapsed seconds but does nothing else. No AI interaction, no adaptive pacing, no conversational interface.
- **LessonListScreen** (`lib/features/lessons/presentation/lesson_list_screen.dart`): Simple CRUD list of lessons by topic ID.
- **PlannerScreen** (`lib/features/planner/presentation/planner_screen.dart:57-105`): Asks user for course name, days, hours. Fetches up to 7 matching topic titles from the database, then cycles them equally across days. No LLM-based plan generation, no mastery-awareness, no persistent schedule.
- **LlmService** (`lib/core/services/llm_service.dart`): Has mock methods with hardcoded responses for chat, question generation, lesson generation, answer validation, and study plan generation. Falls back to mocks on any error or when API key is empty. No streaming support. No conversation memory.
- **PersonalLearningPlanService** (`lib/core/services/personal_learning_plan_service.dart`): Generates plans based solely on topic mastery data with a simple priority-ordered static algorithm. No LLM involvement, no student preference modeling, no adaptive rescheduling.
- **StudyProgressTracker** (`lib/core/services/study_progress_tracker.dart`): Tracks attempts and produces basic stats but has **no UI dashboard** displaying trends, weak areas, or recommendations. `getTopicMasteryLevel()` returns `'Browsing'` for every topic — the real logic is never implemented.

### Vision Gap

The vision document (`agent_must_read.md`) describes:

> *"Teaching mode should be conversational, not static. The student should be able to speak naturally with the AI tutor, ask follow-up questions, interrupt explanations, request clarification, and engage in real-time back-and-forth discussion through both text and voice."*

> *"The AI tutor should: dynamically generate the lesson plans and goals beforehand, teach concepts interactively, explain ideas step-by-step, adapt explanations to student understanding, provide examples, assign exercises and homework during and after class, review student answers, interpret handwritten work, provide immediate corrective feedback, guide problem solving rather than simply giving answers, provide encouragement during lesson time, respect the requested class hour, keep a record of how the class went."*

> *"Assistant/Mentor Mode: scheduling lessons, rescheduling classes, planning long-term study goals, creating or modifying study roadmaps, motivation and encouragement, accountability, wellbeing support, helping decide what to study next, receiving student suggestions or feedback about lessons, adjusting study pacing, creating new courses or subject plans, modifying learning objectives."*

**None of this exists in the codebase. The gap is essentially 100%.**

---

## Affected Files

### Core files to modify/extend:

| File | Role | Change Required |
|---|---|---|
| `lib/core/services/llm_service.dart` | LLM interaction layer | Add streaming support (`Stream<String>`), conversation memory, structured output parsing, token usage tracking |
| `lib/core/data/models/` | Data models | Add `ConversationMessage`, `LessonSession`, `TutorAction`, `MentorAction` models |
| `lib/core/data/repositories/` | Persistence | Add `conversation_repository.dart`, `lesson_session_repository.dart` |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | Current lesson UI | Complete rewrite into conversational tutor interface |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | Lesson list | Add lesson status indicators (planned, in-progress, completed) |
| `lib/features/lessons/services/services.dart` | Lesson services | Add `TutorService`, `LessonPlanGenerator` |
| `lib/features/planner/presentation/planner_screen.dart` | Planner UI | Replace static schedule with LLM-generated adaptive plan with rescheduling |
| `lib/core/services/personal_learning_plan_service.dart` | Plan generation | Integrate LLM for dynamic plans respecting student history, preferences |
| `lib/core/services/study_progress_tracker.dart` | Progress tracking | Implement `getTopicMasteryLevel()` with real data, add dashboard-ready metrics |
| `lib/providers/llm_engine_provider.dart` | Legacy provider | Migrate to Riverpod or consolidate into new tutor provider |

### New files needed:

| File | Purpose |
|---|---|
| `lib/features/teaching/` | New feature module for Teaching Mode |
| `lib/features/mentor/` | New feature module for Mentor/Assistant Mode |
| `lib/features/teaching/presentation/tutor_screen.dart` | Main conversational tutor interface |
| `lib/features/teaching/presentation/widgets/chat_bubble.dart` | Tutor/student message widgets |
| `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` | Visual lesson timeline |
| `lib/features/teaching/services/tutor_service.dart` | Orchestrates lesson flow: plan → teach → quiz → review |
| `lib/features/teaching/services/conversation_manager.dart` | Manages conversation state, context window, follow-ups |
| `lib/features/mentor/presentation/mentor_screen.dart` | Mentor chat interface |
| `lib/features/mentor/services/mentor_service.dart` | Scheduling, planning, motivation actions |
| `lib/core/widgets/conversation_input.dart` | Reusable input bar with voice, text, canvas support |

---

## Proposed Architecture

### Teaching Mode Flow

```
Student opens lesson
        │
        ▼
TutorService.generatePlan()
  ├─ Queries LLM for lesson goals & structure
  ├─ Adapts to student's prior mastery from MasteryGraphService
  └─ Returns structured lesson plan with checkpoints
        │
        ▼
Conversation begins — TutorService streams LLM responses
  ├─ LessonBlock content delivered conversationally (not static cards)
  ├─ Student can interrupt, ask follow-ups
  ├─ Tutor detects confusion, adapts in real-time
  ├─ Assigns inline exercises, evaluates answers
  └─ Tracks elapsed time vs. planned lesson hour
        │
        ▼
Lesson ends — TutorService.saveSession()
  ├─ Saves lesson_record (what was covered, student engagement)
  ├─ Updates mastery graph with lesson performance
  └─ Schedules next lesson based on remaining syllabus
```

### Mentor Mode Architecture

```
MentorScreen (persistent companion)
  │
  ├─ Chat interface using LlmService.conversationStream()
  ├─ Tool-calling system (execute actions like schedule/reschedule)
  ├─ Context-aware: knows student's subjects, pending lessons, weak areas
  ├─ Proactive nudges: "You haven't studied Physics in 3 days"
  └─ Confirmation gate: never alters schedules without explicit approval
```

---

## Rationale

1. **Core differentiator**: The conversational AI tutor is what makes StudyKing an "AI-native learning platform" rather than a basic flashcard/tracker app. Without it, the app is just a CRUD interface for subjects and questions.

2. **Existing scaffolding can be leveraged**: `LlmService` already has method signatures for chat, lesson generation, and answer validation. `AnswerValidationService` has validation logic. `MasteryGraphService` tracks topic-level performance. The data layer is ready — only the interactive layer is missing.

3. **Planner is currently misleading**: The `PlannerScreen` claims to generate study plans but only cycles hardcoded topic titles. This creates a poor first impression. A real LLM-backed planner that respects the student's actual syllabus, mastery data, and time constraints is essential.

4. **Progress tracking has no value without a dashboard**: `StudyProgressTracker` computes stats that are never visualized. A dashboard showing trends, weak areas, streaks, and recommendations would provide immediate motivation.

---

## Acceptance Criteria

### Teaching Mode (Phase 1 — MVP)

- [ ] **Conversational lesson delivery**: Student opens a topic and enters a real-time chat with the AI tutor. The tutor explains concepts interactively rather than displaying static blocks.
- [ ] **Lesson plan generation**: Before teaching, the tutor generates a structured plan with goals, estimated duration, and checkpoints, tailored to the student's mastery level.
- [ ] **In-line exercises**: Tutor can insert practice questions mid-lesson, evaluate typed answers, and provide corrective feedback without leaving the conversation.
- [ ] **Adaptive pacing**: If the student answers correctly, tutor accelerates. If struggling, tutor offers simpler explanations or prerequisite review.
- [ ] **Lesson recording**: After each lesson, a `LessonSession` record is saved with: topics covered, questions asked/answered, student confidence, and tutor notes.
- [ ] **Time respect**: Tutor shows a remaining-time indicator and wraps up when the lesson hour is approaching.

### Teaching Mode (Phase 2 — Enhanced)

- [ ] **Streaming responses**: LLM responses stream token-by-token for low-latency feel (not waiting for full response).
- [ ] **Voice input**: Speech-to-text for student answers (via `speech_to_text` package).
- [ ] **Handwriting/canvas**: Student can draw on a canvas; tutor interprets via vision API or LLM.
- [ ] **Follow-up questions**: Student can ask follow-ups mid-explanation; tutor maintains conversational context.
- [ ] **Slide rendering**: Tutor can present structured slides with diagrams within the conversation.
- [ ] **Confidence tracking**: After each topic segment, student rates understanding; tutor adjusts remaining lesson accordingly.

### Mentor Mode (Phase 1 — MVP)

- [ ] **Chat interface**: Persistent chat screen where student can ask scheduling, planning, and motivational questions.
- [ ] **Schedule awareness**: Mentor reads upcoming lessons from `StudySessionRepository` and can report what's planned.
- [ ] **Rescheduling with confirmation**: Mentor can propose schedule changes but requires explicit user confirmation ("I see you have a Physics lesson tomorrow. Would you like to reschedule?").
- [ ] **Progress reporting**: Mentor can answer "How am I doing in Math?" by querying `StudyProgressTracker` / `MasteryGraphService`.
- [ ] **Proactive reminders**: Mentor detects inactivity (no sessions in 3+ days) and sends an encouraging nudge.

### Mentor Mode (Phase 2 — Enhanced)

- [ ] **Long-term goal planning**: "I want to finish IB Physics in 180 days" — mentor breaks into weekly plans, adapts as progress changes.
- [ ] **Motivation & accountability**: Mentor tracks streaks, celebrates milestones, and intervenes when patterns slip.
- [ ] **Wellbeing awareness**: Mentor avoids over-scheduling, encourages breaks, respects the student's stated workload limits.
- [ ] **Feedback loop**: Student can rate lessons and provide feedback; mentor adjusts future recommendations accordingly.

### Analytics Dashboard (Phase 1)

- [ ] **Dashboard screen** showing: total study hours (by subject), weekly trend chart, accuracy over time, weak/strong topic areas.
- [ ] **Topic mastery visualization**: Per-topic progress bars or heatmap showing mastery levels (Novice → Expert).
- [ ] **Session history with insights**: Trends showing study consistency, best study times, improving/declining subjects.
- [ ] **Exportable progress**: CSV/PDF export of study history, as partially scaffolded in `StudyProgressTracker.exportProgressCSV()`.

---

## Dependencies

- Add `speech_to_text` and `text_to_speech` for voice support (Mentor/Teaching Phase 2)
- Add `flutter_markdown` or similar for rich rendering of LLM responses (diagrams, math)
- Add `fl_chart` or `syncfusion_flutter_charts` for the analytics dashboard
- LlmService must support streaming before Teaching Mode Phase 2 can ship
