# Future Functionality Planner — Vision Gap Analysis (Round 2)

**Generated:** 2026-05-18
**Source:** Re-analysis of `agent_must_read.md` vision against current `lib/` implementation, validating/completing the previous analysis at `issues/completed/future_functionality_planner.md`

> **IMPORTANT**: The previous analysis (Round 1, completed) contained several inaccurate claims because the codebase had already been improved. This Round 2 reflects the *actual* current state after cross-checking every claimed gap against real file contents.

---

## BLOCKER — App crashes or user cannot proceed

### B1. Lesson system has no content creation pipeline — LLM must drive lesson materials

**Context:** The vision describes lessons as "structured, visual, slide-like, or interactive" with LLM agents preparing materials. The current state:

| Aspect | Current Reality | Gap |
|--------|----------------|-----|
| **Lesson models** (`lesson_model.dart`, `lesson_block_model.dart`) | Full data models with 6 block types (text, example, exercise, slide, quiz, summary) | ✅ Complete |
| **Lesson rendering** (`lesson_block_card.dart`) | Plain `Card` with icon + title + content text for ALL block types | ❌ Slides not full-screen, quizzes not interactive, exercises not runnable |
| **Lesson creation** | No service creates `Lesson` objects with blocks | ❌ `TutorService.startLesson()` creates `TutorSession` + `Session` but not a `Lesson` |
| **LessonSessionService** | Query-only (114 lines): getLessons, getCompletionRate, getProgressBySubject | ❌ No lesson content creation |
| **Lesson ↔ Session decoupling** | `Lesson` model has blocks/content; `Session` has timing — but no code bridges them | ❌ `scheduleLesson()` creates Sessions only |
| **Background lesson prep** | `IdleExecutor` exists (104 lines) but unused | ❌ No queued background generation |
| **Calendar scheduling UI** | `calendar_view_widget.dart` (219 lines, month grid) + `lesson_booking_sheet.dart` (299 lines, date/time/conflict checks) exist | ✅ Calendar present but not on dashboard — only via planner nav |

**Affected files:**
- `lib/features/lessons/services/lesson_service.dart` — query-only, no creation
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — renders all block types as plain text cards
- `lib/features/lessons/presentation/lesson_detail_screen.dart` — static display, "AI Tutor" button navigates to TutorScreen without lesson plan continuity
- `lib/features/teaching/services/tutor_service.dart` — creates `TutorSession` not `Lesson`
- `lib/features/planner/services/planner_service.dart:scheduleLesson()` — creates Sessions, not Lessons
- `lib/core/services/llm_agent/idle_executor.dart` — exists but no task ever enqueued

**Acceptance criteria:**
1. New `LessonTemplateService` (or extend `PlannerService`) creates `Lesson` objects with LLM-generated `LessonBlock` content when requested
2. Lesson blocks render differently per type: slide blocks show presentation-style full-screen, quiz blocks show interactive questions, exercise blocks show input area with LLM evaluation
3. Background LLM task (via `IdleExecutor`) generates lesson materials ahead of scheduled time
4. Dashboard shows upcoming scheduled lessons (from planner nav or inline mini-calendar)
5. `TutorService.startLesson()` creates/links to a `Lesson` record; completed tutor sessions update `Lesson` blocks with session recording

---

### B2. LLM Agent framework is architecturally complete but zero tools are implemented — agent system is dead code

**Context:** The vision requires agents with tools, memory, and idle-time execution. The beta user explicitly demands "agents must have long term memory not each new session is fresh now and toolless."

| Component | Location | Status |
|-----------|----------|--------|
| `LlmAgent` class | `lib/core/services/llm_agent/llm_agent.dart` (97 lines) | ✅ Implemented |
| `AgentLoop` (ReAct loop) | `lib/core/services/llm_agent/agent_loop.dart` (181 lines) | ✅ Implemented — 10-iteration loop, parses `TOOL_CALL:` / `ARGUMENTS:` text protocol |
| `ToolRegistry` | `lib/core/services/llm_agent/agent_tool.dart` (27 lines) | ✅ Implemented |
| `AgentMemoryStore` | `lib/core/services/llm_agent/agent_memory.dart` (78 lines) | ✅ Hive-backed, cross-session facts, 100-summary cap |
| `IdleExecutor` | `lib/core/services/llm_agent/idle_executor.dart` (104 lines) | ✅ Background task queue, idle monitoring (30s interval) |
| `AgentFactory.create()` | `lib/core/services/llm_agent/llm_agent.dart` (61-97) | ✅ Assembles all sub-components |
| **Concrete AgentTool implementations** | ANYWHERE in `lib/` | ❌ **ZERO** — only `_SearchTool` and `_TestTool` exist in `test/` |
| **Feature using LlmAgent** | ANY `lib/` file | ❌ **ZERO** — `grep "LlmAgent\|AgentFactory" lib/` only matches the definition itself |

The framework is ready to go but completely disconnected from the rest of the codebase:

- `MentorService` (693 lines) builds its own context and does single-turn chat via raw `LlmService.chatStream()` — no agent loop, no tools, no cross-session memory (`ConversationMemory` is a turn buffer, not agent memory)
- `ConversationManager` (374 lines) is a phase state machine for teaching — no tool use
- `TutorService` (259 lines) orchestrates lessons directly — no agent abstraction
- No feature registers tools, creates an agent, or calls `AgentFactory.create()`
- The `IdleExecutor` queue is always empty because nobody calls `enqueueBackgroundTask()`

**Acceptance criteria:**
1. Implement 4-6 production `AgentTool` subclasses: `ScheduleLessonTool`, `SearchQuestionsTool`, `GetStudentStatsTool`, `GenerateLessonBlocksTool`, `CreatePlanTool`, `GetWeakTopicsTool`
2. Register tools with `ToolRegistry` via a new `llmAgentProvider` in core providers
3. Refactor `MentorService` to use `LlmAgent` internally (keep existing API surface for backward compatibility)
4. Refactor `ConversationManager` to optionally use `LlmAgent` (teaching can skip tools but mentor cannot)
5. Wire `IdleExecutor` to background tasks: post-lesson plan adherence update, next-lesson material pre-generation
6. Integration test proves: user message → LLM → tool call → tool execution → follow-up LLM response

---

## MAJOR — Feature is broken or misleading

### M1. Voice interaction is siloed in teaching — must be available in mentor and across the app

**Context:** Vision says "voice conversation, speech-to-text and text-to-speech" are core interaction modes. Verified: `VoiceController` (196 lines) + `VoiceBar` (154 lines widget + CustomPaint waveform) exist only in `teaching/`. Mentor screen, practice sessions, and question screens have no voice input.

**Affected files:**
- `lib/features/teaching/services/voice_controller.dart` — teaching-only (196 lines, locale-aware STT/TTS)
- `lib/features/teaching/presentation/widgets/voice_bar.dart` — only in tutor screen
- `lib/features/mentor/presentation/mentor_screen.dart` — no voice button
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — no voice input for typed answers

**Acceptance criteria:**
1. Extract `VoiceController` to `lib/core/services/voice_service.dart` as a singleton provider
2. Mentor screen gets a mic button for STT question input and TTS response reading
3. Practice session screen gets optional voice answer input for typed/text questions
4. Web: voice button shows with "not available" tooltip instead of crashing (already handled in VoiceController? check)

---

### M2. Engagement scheduler has hard-wired dependencies that block test overrides

**Context:** `engagementSchedulerProvider` (`app_providers.dart:329-344`) injects most dependencies via `ref.watch(...)` but some sub-providers create instances via `new`:

| Dependency | Provider | Pattern |
|-----------|----------|---------|
| `tracker` | `engagementTrackerProvider` | ✅ `ref.watch()` |
| `masteryService` | `engagementMasteryServiceProvider` | ❌ `MasteryGraphService()` (new) |
| `notificationService` | `notificationServiceProvider` | ✅ `ref.watch()` |
| `nudgeRepository` | `engagementNudgeRepoProvider` | ❌ `EngagementNudgeRepository()` (new) |
| `adherenceRepository` | `engagementAdherenceRepoProvider` | ❌ `PlanAdherenceRepository()` (new) |
| `planAdapter` | `planAdapterProvider` | ❌ `PlanAdapter()` (new) |
| `sessionRepository` | `databaseProvider.sessionRepository` | ✅ `ref.watch()` |
| `plannerService` | `engagementPlannerServiceProvider` | ❌ `PlannerService()` (new) |

Five sub-providers use `Type()` `new` constructors, making them un-overridable in `ProviderScope` tests. Also `engagementTrackerProvider`'s `StudyProgressTracker` has similar pattern.

**Affected file:**
- `lib/core/providers/app_providers.dart:301-344`

**Acceptance criteria:**
1. All 5 sub-providers inject their own dependencies through Riverpod providers instead of `new`
2. A widget test overrides `engagementNudgeRepoProvider` with `FakeEngagementNudgeRepository` and proves `EngagementScheduler` uses it
3. Similarly for `StudyProgressTracker` deps

---

### M3. Focus mode is a split timer/practice hub — practice integration is thin (navigates away, no inline Q&A)

**Context:** The beta user complained "current focus mode is fucking useless, wanted a place to practice questions from different subjects." This was **partially addressed** — the screen now has:
- Subject practice cards with due question counts ✅
- Quick Practice (navigates to `PracticeSessionScreen`) ✅  
- Weak Areas Practice (fetches weak topics → navigates) ✅
- Spaced Repetition practice ✅
- Subject selection and due count display ✅
- `FocusPracticeService` with `getDueQuestions()` ✅
- `FocusSessionModel` ✅

BUT the core experience is still a **timer app that navigates away** for actual question practice. `PracticeSessionScreen` is a separate screen — focus mode doesn't provide inline Q&A. The timer persists during practice but the questions are answered in a different context. There's no continuity (questions answered/accuracy tracking doesn't flow back into focus session).

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (829 lines) — practice hub UI exists but all practice actions `Navigator.push` away
- `lib/features/focus_mode/services/focus_practice_service.dart` (84 lines) — basic due-question query but used only to show counts, not to drive inline Q&A
- Focus session doesn't track per-question accuracy from PracticeSessionScreen

**Acceptance criteria:**
1. Focus Mode offers an optional **inline practice mode** where questions appear directly in the focus screen (not just navigating away)
2. When a question is answered inline, the session timer continues, accuracy is tracked per-subject
3. Session summary shows: questions answered, accuracy, time spent, mastery deltas per subject
4. The existing "navigate to PracticeSession" remains as alternative for full practice experience

---

### M4. No topic dependency visualizer — prerequisite management is hidden in dialog UI

**Context:** `subject_topics_tab.dart` (405 lines) has full CRUD for topics including prerequisite selection. But there's no visual graph/flow showing how topics connect. Vision mentions "prerequisite enforcement" — currently you can set prerequisites in the edit dialog but there's no visualization of topic dependencies or topological ordering.

**Affected files:**
- `lib/features/subjects/presentation/widgets/subject_topics_tab.dart` — dependency management via dialog selectors only
- `lib/features/subjects/presentation/dialogs/topic_edit_dialog.dart` — prerequisite picker (list, not graph)
- `lib/features/subjects/data/repositories/topic_repository.dart` — has `getRootTopics()`, `addParent()` but no topological query

**Acceptance criteria:**
1. Topic list shows dependency arrows or indentation indicating prerequisite chains
2. Simple directed-graph visualization (or tree view) accessible from subject detail
3. When deleting a topic, warn if downstream topics depend on it
4. Topic ordering respects prerequisites for practice/lesson flows

---

### M5. `LlmTaskManagerScreen` bypasses feature-layer `llmTaskServiceProvider` — reads core directly

**Context:** The `llm_task_tasks/` feature has a proper `LlmTaskService` and `llm_task_providers.dart`, but the screen reads `llmTaskManagerProvider` directly from core (`lib/core/providers/llm_providers.dart`) instead of using `llmTaskServiceProvider`. Also `llm_tasks/data/` directory is empty (no feature-specific task model).

**Affected files:**
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart:25,39` — reads `llmTaskManagerProvider` directly
- `lib/features/llm_tasks/data/` — empty directory

**Acceptance criteria:**
1. Screen reads from `llmTaskServiceProvider` instead of `llmTaskManagerProvider`
2. Empty `data/` directory either populated or removed

---

## MINOR — Code quality, UX friction, incomplete polish

### m1. Dashboard has no "Next Up" / recommended action card for returning users

The `empty_dashboard_checklist.dart` widget guides new users, but for returning users there's no "Recommended next action" card. The `ReadinessScorer` (148 lines) and `RemainingWorkloadEstimator` exist but aren't surfaced on the dashboard.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart` (475 lines) — no "Next Up" card
- `lib/features/practice/services/readiness_scorer.dart` — exists but not used on dashboard

**Acceptance criteria:**
1. Dashboard shows a "Next Up" card with: upcoming scheduled lesson, due reviews count, recommended weak-area topic
2. Uses `ReadinessScorer` data when available

### m2. `TutorService.startLesson()` doesn't create a `Lesson` record

When `TutorService` starts a lesson, it creates `TutorSession` and `Session` but not a `Lesson` model. The `lessons/` feature remains disconnected from actual teaching. After completion, blocks aren't saved as `Lesson` content.

**Acceptance criteria:**
1. When `TutorService` starts a lesson, it creates/updates a `Lesson` record with the generated lesson plan blocks
2. `lesson_detail_screen.dart` shows live tutor session link when lesson is in progress
3. Completed tutor sessions update `Lesson` blocks from the lesson recording

### m3. No post-ingestion lesson generation

When a source document is ingested via `ContentPipeline`, no `Lesson` is created from the summarized/extracted content. The pipeline generates questions but not lesson blocks.

**Acceptance criteria:**
1. Post-ingestion, `ContentPipeline` optionally calls a lesson generation service to create `Lesson` with blocks
2. User sees "Generate lesson from this material" toggle in upload screen

### m4. No handwriting/ink recognition — canvas is pure input with no interpretation

The canvas drawing widget (`canvas_drawing_widget.dart`, 289 lines) exists for typed-input questions only (drawing answers). There's no handwriting recognition, no ink-to-text, no LLM-based interpretation of handwritten work outside of the `TutorScreen.processImage()` method which sends base64 images to the LLM.

### m5. No video/audio dedicated ASR — transcription relies on LLM capabilities

The ingestion pipeline accepts video/audio files and routes them through `TranscriptionExtractor` which wraps `LlmService`. There's no dedicated ASR engine (Whisper, Google Speech, etc.). Content is stored but real audio/video-to-text conversion depends entirely on the LLM's multimodal capabilities.

---

## Beta User Issue Resolution Tracking

The following files in `issues/further_issues/open/` represent real user complaints raised during beta testing. They must be **resolved and moved** to `issues/further_issues/completed/`:

| File | Priority | Status | Notes |
|------|----------|--------|-------|
| `issues/further_issues/open/lessons.md` | P0 | Open | Addressed by B1 + B2 above — agents with tools + memory, lesson content pipeline, calendar scheduling, background prep |
| `issues/further_issues/open/focus_mode.md` | P1 | Partially addressed | Addressed by M3 above — practice hub exists via navigation, but inline Q&A still missing |

**Process:**
1. Implement the acceptance criteria in this document
2. When `lessons.md` criteria are met → move to `issues/further_issues/completed/lessons.md`
3. When `focus_mode.md` criteria are met → move to `issues/further_issues/completed/focus_mode.md`

---

## Immediate Priority Order (Next Development Phase)

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| P0 | **B2: Implement 4-6 concrete AgentTool classes + wire LlmAgent into MentorService** — makes the existing agent framework actually useful | High | Transformative (unblocks everything) |
| P1 | **B1: Lesson content creation pipeline** — generate Lesson objects with LLM blocks, proper per-type rendering, background prep via IdleExecutor | High | High (beta user demand) |
| P2 | **M1: Voice everywhere** — extract VoiceController to core, add to mentor and practice | Medium | Medium |
| P3 | **M3: Focus Mode inline Q&A** — add inline practice directly in focus screen, keep timer, track accuracy | Medium | High (beta user demand) |
| P4 | **M2: Engagement scheduler dependency wiring** — make all sub-providers testable | Low | Medium |
| P5 | **M4: Topic dependency visualizer** — prerequisite graph/view on subject detail | Low | Medium |
| P6 | **m1-m3: Dashboard recommendations, Lesson↔Tutor integration, ingestion→lesson pipeline** | Low-Medium | Medium |

---

## Cross-References

- `issues/further_issues/open/lessons.md` — beta user lesson complaint (P0-P1)
- `issues/further_issues/open/focus_mode.md` — beta user focus mode complaint (P3)
- `issues/open/code_refactor_master.md` — hard-wired scheduler (B2), session analytics
- `issues/open/dry_run_usability_validator.md` — syllabus→topic pipeline, prerequisite enforcement
- `issues/open/test_master.md` — missing behavioral assertions
- `issues/open/ui_ux_master.md` — accessibility, error states
