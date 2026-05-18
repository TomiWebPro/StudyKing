# Future Functionality Planner — Vision Gap Analysis & Next Phase Roadmap

**Generated:** 2026-05-18
**Source:** Comparison of `agent_must_read.md` product vision against `lib/` implementation reality + beta test feedback from `issues/further_issues/open/`
**Severity:** BLOCKER / MAJOR / MINOR

---

## BLOCKER — App crashes or user cannot proceed

### B1. Lesson System is a read-only shell — LLM agents must drive lesson creation

**Context:** The vision describes lessons as "structured, visual, slide-like, or interactive, but should always remain conversational and adaptive" with LLM agents preparing materials. The current `lessons/` feature has `Lesson`/`LessonBlock` models and a `LessonSessionService` (114 lines) that is purely a **query layer over Session objects** — no lesson creation, no LLM-driven materials, no presentations.

| Aspect | Vision | Current Reality |
|--------|--------|----------------|
| Lesson content creation | LLM agents generate plans, slides, exercises | `TutorService.startLesson()` in `teaching/` creates unscheduled tutor sessions (no Lesson model integration) |
| Presentations/slides | Slide-like structured lessons | `LessonBlock` has types (text, example, exercise, slide, quiz, summary) but only rendered as plain cards in `lesson_detail_screen.dart` |
| Scheduling | Calendar-based scheduling with time slots | No calendar view; `PlannerService.scheduleLesson()` just creates a `Session` with start/end time |
| Agent-driven prep | LLM agents prepare materials in background | No background LLM task for lesson preparation exists |
| Lesson ≠ Session | Separate scheduling time from lesson plan | `Lesson` and `Session` are conflated — LessonSessionService treats Sessions as lessons |

**Beta user complaint** (from `issues/further_issues/open/lessons.md`):
> *"Make the lessons like preply where you can plan lesson with subjects on the dashboard with a calendar view (time) and make sure the helpers are actually useful can execute tools to help making lesson scheduling. Basically, when the app is idle, use the api to make lesson plan. And lessons are prepared from llm agents, llm is not just a fucking chatbot."*
> *"Separate scheduling lesson time and lesson plan. Lesson must have presentation and llm explanations. Current lesson is fucking useless."*

**Affected files:**
- `lib/features/lessons/services/lesson_service.dart` — query-only, no creation
- `lib/features/lessons/presentation/lesson_list_screen.dart` — reads from LessonRepository but shows Sessions
- `lib/features/lessons/presentation/lesson_detail_screen.dart` — renders LessonBlocks as static cards; "AI Tutor" button just navigates to TutorScreen with no lesson plan continuity
- `lib/features/lessons/data/models/lesson_model.dart` / `lesson_block_model.dart` — models exist but no service creates them
- `lib/features/planner/services/planner_service.dart:scheduleLesson()` — creates Sessions, not Lessons

**Acceptance criteria:**
1. New `LessonAgentService` (or extend `PlannerService`) creates `Lesson` objects with LLM-generated `LessonBlock` content (text, slides, exercises, summary) when a lesson is scheduled
2. Background LLM task (via `LlmTaskManager`) generates lesson materials before the scheduled time
3. `lesson_detail_screen.dart` renders blocks properly: slide blocks show presentation-style full-screen view, quiz blocks show interactive questions, text blocks show formatted content
4. A calendar view (on dashboard or planner) shows scheduled lessons with time slots, subject colors, and status (preparing/ready/completed)
5. `Lesson` and `Session` are decoupled: `Lesson` holds pedagogical content, `Session` holds timing/attendance metadata
6. When app is idle (no active user interaction), background lesson preparation tasks queued via `LlmTaskManager`

---

### B2. Focus Mode is a glorified timer — must become a cross-subject practice hub

**Context:** The vision describes practice as "continuously test understanding, focus on weak areas, revisit old content intelligently." The beta user specifically says the focus mode is useless. Currently `focus_mode/` has empty `data/` and `services/` directories — it's merely a UI wrapper around `StudyTimerService` from sessions.

**Beta user complaint** (from `issues/further_issues/open/focus_mode.md`):
> *"The current focus mode is fucking useless, I wanted it to be a place where student can practice questions from different subjects after lessons."*

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — 841 lines of timer+summary UI, zero question integration
- `lib/features/focus_mode/providers/focus_mode_providers.dart` — 10 lines, just creates StudyTimerService
- `lib/features/focus_mode/` — `data/` and `services/` are empty directories

**Acceptance criteria:**
1. Focus Mode becomes a **multi-subject practice hub**: student selects 1-N subjects/topics, then enters a timed practice session drawing from due/review questions across those subjects
2. `PracticeDataService` or new `FocusPracticeService` aggregates due questions from `SpacedRepetitionService` across selected subjects
3. Session timer persists but is secondary — focus is on answering questions, not watching a clock
4. Session summary shows: questions answered, accuracy, time spent, mastery changes per subject
5. Empty directories (`data/`, `services/`) are populated or the feature is restructured

---

### B3. No background LLM agent system — agents lack tools, memory, and idle-time execution

**Context:** The vision says LLM should be used heavily ("System should heavily use llm instead of deterministic bullshiting"). Beta user explicitly demands agents with tools and long-term memory. Currently:
- `MentorService` is a single-turn chat completion with context building — not an agent
- `ConversationManager` is a phase state machine — not a tool-using agent
- No agent can execute tools (search questions, schedule lessons, create plans) autonomously
- `ConversationMemory` persists 50 turns — no long-term memory across sessions
- No idle-time execution pipeline ("when the app is idle, use the api to make lesson plan")

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart` — chat completion, no tool-use loop
- `lib/features/teaching/services/conversation_manager.dart` — phase machine, no tool-use loop
- `lib/features/mentor/data/models/chat_message_data.dart` — flat message model, no tool_call/tool_result structure
- `lib/core/services/conversation_memory.dart` — 50-turn window, no cross-session memory
- `lib/features/llm_tasks/services/` — empty directory, no agent task abstraction

**Acceptance criteria:**
1. New `LlmAgent` abstraction in `lib/core/services/llm_agent/` with:
   - Tool registry (tools can be called by LLM: `searchQuestions`, `scheduleLesson`, `createPlan`, `getStudentStats`, `generateLessonBlocks`)
   - Agent loop: `user message → LLM call → tool calls → execute tools → LLM call with results → respond`
   - Long-term memory store (Hive-backed, storing summaries/goals/outcomes per session)
   - Idle execution queue (check post-lesson, generate next lesson materials)
2. `MentorService` and `ConversationManager` refactored to use `LlmAgent` internally
3. All LLM interactions across the app go through the agent system (mentor, teaching, planner, ingestion)
4. Agent memory persists key facts: "Student struggled with stoichiometry", "Student prefers example-first explanations"

---

## MAJOR — Feature is broken or misleading

### M1. Lesson calendar/scheduling UI is missing — no time-slot booking, no schedule visualization

**Context:** Vision says "Students should be able to... plan lesson with subjects on the dashboard with a calendar view (time)." Beta user explicitly demands Preply-like scheduling. The planner has a `calendar_view_widget.dart` but it's purely layout — no booking flow, no conflict detection in the UI, no drag-to-reschedule.

**Affected files:**
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` — check what it actually renders
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — likely a bottom sheet, not a full calendar view
- `lib/features/planner/services/planner_service.dart:scheduleLesson()` — backend exists but no date/time picker UX
- `lib/features/dashboard/presentation/dashboard_screen.dart` — no calendar widget shown

**Acceptance criteria:**
1. Dashboard shows a weekly calendar view with scheduled lessons, practice sessions, and free slots
2. Tapping a free slot opens a lesson booking sheet: select subject/topic → pick duration → confirm
3. `PlannerService.hasSchedulingConflict()` is exposed as a Riverpod provider for real-time conflict preview
4. Drag-and-drop reschedule on calendar view
5. Calendar syncs with `StudentAvailabilityRepository` for recurring availability

---

### M2. Voice interaction is siloed in teaching — must be available in mentor and across the app

**Context:** Vision says "voice conversation, speech-to-text and text-to-speech" are core interaction modes. `VoiceController` (195 lines) exists in `teaching/` but is not used by `MentorService`, not available in practice/question screens, and is disabled on web.

**Affected files:**
- `lib/features/teaching/services/voice_controller.dart` — teaching-only, hardcoded locale mapping
- `lib/features/mentor/presentation/mentor_screen.dart` — no voice input/output
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — no voice input for answers
- `lib/features/questions/presentation/widgets/` — no voice answer widget

**Acceptance criteria:**
1. `VoiceController` extracted to `lib/core/services/voice_service.dart` as a singleton provider
2. Mentor screen has a voice button that STT-transcribes questions and TTS-speaks responses
3. Practice session screen has optional voice input for typed-answer questions
4. Web fallback: show voice button with "not available" tooltip instead of crashing

---

### M3. Topic management UI is completely missing — no create/edit/dependency UI for topics

**Context:** Already documented in `dry_run_usability_validator.md` B1-B4 but bears repeating: syllabus upload doesn't create topics, `TopicDependency` has no editor, `TopicRepository.create()` is dead code. This blocks syllabus-driven planning from working.

**Affected files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart` — no topic management tab
- `lib/features/subjects/presentation/subject_form_widgets.dart` — no topic sub-form
- `lib/features/subjects/data/repositories/topic_repository.dart` — `create()`/`update()`/`delete()` are dead code
- `lib/features/ingestion/presentation/upload_screen.dart:240` — passes `possibleTopics: []`

**Acceptance criteria:**
1. Subject Detail screen has a "Topics" tab listing all topics for the subject
2. "Add Topic" form with: title, description, prerequisite selector, syllabus weight, mastery threshold
3. Default topics auto-created when a syllabus PDF is uploaded (linked to B1 in dry_run_usability_validator)
4. Topic dependency graph visualizer (simple directed graph or list with prerequisite checkboxes)

---

### M4. `llm_tasks/` feature folder is a shell — data/services/providers directories empty

**Context:** The vision describes "a task manager-like portal to view actively running inferencing task and for what purpose." The `LlmTaskManagerScreen` (391 lines) and core `LlmTaskManager` (226 lines) exist, but the `llm_tasks/` feature folder has empty `data/`, `services/`, and `providers/` subdirectories. The screen reads `LlmTaskManager` directly from core. This breaks the feature isolation pattern.

**Affected files:**
- `lib/features/llm_tasks/` — empty subdirectories
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — reads core directly
- `lib/core/services/llm_task_manager.dart` — core logic is sound but feature-layer integration is missing

**Acceptance criteria:**
1. `llm_tasks/` gets proper `services/llm_task_service.dart` that wraps `LlmTaskManager`
2. `llm_tasks/providers/llm_task_providers.dart` exposes providers
3. Token usage and estimated cost displayed per-task in the task manager screen
4. Tasks are filterable by feature (ingestion, teaching, mentor, planner)

---

### M5. Engagement scheduler dependencies are hard-wired — no overrides, untestable

**Context:** Already documented in `code_refactor_master.md` B2. `engagementSchedulerProvider` creates all dependencies via `new` constructors. This means no Riverpod override works, making the proactive engagement system untestable in isolation.

**Affected file:**
- `lib/core/providers/app_providers.dart:295-313`

**Acceptance criteria:**
1. `engagementSchedulerProvider` reads every dependency from its Riverpod provider
2. A widget test overrides one dependency (e.g., fake `NudgeRepository`) and proves the scheduler uses it
3. All `new` constructor calls removed from provider body

---

### M6. `duplicate sessionRepositoryProvider` causes divergent session instances across features

**Context:** Already documented in `code_refactor_master.md` B1. Two competing declarations of `sessionRepositoryProvider` — one in `sessions/providers/` (bare), one in `lessons/providers/` (database-backed). Consumers are split.

**Acceptance criteria (from code_refactor_master.md):**
1. Eliminate one declaration
2. All consumers pick up the same instance
3. Widget tests verify override propagation

---

## MINOR — Code quality, UX friction, incomplete polish

### m1. Focus mode empty directories removed or populated

`focus_mode/data/` and `focus_mode/services/` are empty. Either remove them or implement feature-specific models/services. (Addressed in B2 above.)

### m2. `llm_tasks/services/` and `llm_tasks/data/` empty directories

Same pattern as focus_mode. Populate or remove.

### m3. No lesson creation pipeline from ingestion

When a source document (PDF, video) is ingested via `ContentPipeline`, no `Lesson` is created from the summarized/extracted content. The pipeline's `generateQuestions` stage produces questions but no lesson blocks.

**Acceptance criteria:**
1. Post-ingestion, `ContentPipeline` optionally calls a lesson generation service to create `Lesson` with blocks from the summarized content
2. User sees "Generate lesson from this material" toggle in upload screen

### m4. `TutorService` creates tutor sessions directly — no integration with `Lesson` model

`TutorService.startLesson()` creates a `TutorSession` and `Session`, but not a `Lesson`. The `lessons/` feature remains disconnected from the actual teaching activity.

**Acceptance criteria:**
1. When `TutorService` starts a lesson, it creates/updates a `Lesson` record with the generated lesson plan
2. `lesson_detail_screen.dart` shows the live tutor session when a lesson is in progress
3. Completed tutor sessions update `Lesson` with the session recording

### m5. No hint in dashboard about what to do next for new users

The vision describes a system that helps students decide "what to study next." The `empty_dashboard_checklist.dart` widget exists but for returning users with existing data, there's no "Recommended next action" card. The `ReadinessScorer` exists in practice but isn't surfaced on the dashboard.

**Acceptance criteria:**
1. Dashboard has a "Next Up" card showing: upcoming scheduled lessons, due reviews count, recommended topic to study
2. Recommendations use `ReadinessScorer` + `RemainingWorkloadEstimator` data

---

## Immediate Priority Order (Next Development Phase)

Based on impact on student experience + beta user urgency:

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| P0 | **B1+B3: Fix Lessons with LLM agents** — agents with tools + memory that create lesson materials, calendar scheduling | High | Transformative |
| P1 | **B2: Fix Focus Mode** — make it a cross-subject practice hub | Medium | High (blocking beta user) |
| P2 | **M1: Calendar scheduling UI** — weekly/daily view on dashboard | Medium | High |
| P3 | **M3: Topic management UI** — create/edit/dependency editor for topics | Medium | High (blocks syllabus flow) |
| P4 | **M2: Voice everywhere** — extract VoiceController to core, add to mentor | Low | Medium |
| P5 | **M4-M6: Architectural cleanup** — llm_tasks folders, scheduler dependency fix, session repo dedup | Low-Medium | Medium |
| P6 | **m3-m5: Integration polish** — ingestion→lessons pipeline, dashboard recommendations | Low | Medium |

---

## Cross-References

- `issues/further_issues/open/lessons.md` — beta user lesson complaint (P0)
- `issues/further_issues/open/focus_mode.md` — beta user focus mode complaint (P1)
- `issues/open/code_refactor_master.md` — duplicate session repo (B1), hard-wired scheduler (B2), dead code (M1-M3)
- `issues/open/dry_run_usability_validator.md` — syllabus→topic pipeline (B1-B4), prerequisite enforcement (M7-M8)
- `issues/open/internationalisation_master.md` — enum names displayed raw (M-1)
- `issues/open/test_master.md` — missing behavioral assertions (M1)
- `issues/open/ui_ux_master.md` — empty questions no exit (B1), submit disabled for null answer (B2), error consistency (M1)
