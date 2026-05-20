# Future Functionality Planner — Vision vs Implementation Gap Analysis

**Generated:** 2026-05-19
**Source:** `agent_must_read.md` (product vision) vs actual codebase audit
**Input from beta testers:** `issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`

---

## BLOCKER — App crashes or user cannot proceed (or feature is so broken it's unusable)

### B1. Lessons System is Fundamentally Broken — Full Rebuild Required

**Source:** Beta-tester `lessons.md` + vision audit
**Severity:** BLOCKER — the core teaching loop is unusable

**Problem:** The current lesson system has no calendar scheduling, no presentation/slide rendering, no LLM-driven lesson preparation, and no separation between lesson timing and lesson content. The `LessonAgentService` generates a flat list of `LessonBlock` items (text, quiz, exercise, etc.) but the UI (`lesson_detail_screen.dart`) renders them as a scrollable list with zero presentation structure. There is no slide deck, no LLM tutor delivering the lesson interactively (that lives in the separate Teaching/Tutor feature), and no calendar/Preply-like scheduling UI.

**Affected files:**
- `lib/features/lessons/` — entire feature (models, services, screens, providers)
- `lib/features/planner/services/planner_service.dart:288-400` — `scheduleLesson()` creates a Session, not a structured lesson plan
- `lib/features/dashboard/presentation/widgets/next_up_card.dart` — shows upcoming lessons
- `lib/core/services/engagement_scheduler.dart` — no lesson-prep scheduling

**What "fixed" looks like (Acceptance Criteria):**
- [ ] **Calendar scheduling UI:** A Preply-like calendar view in the Dashboard or Planner where students can see free time slots, pick lesson time & duration, and have lessons appear as calendar events.
- [ ] **Separate lesson timing from lesson content:** A `LessonSlot` model holds time/duration; a `LessonPlan` model holds the actual content plan. Scheduling is just setting a slot; the LLM agent fills the plan later.
- [ ] **Idle LLM preparation:** When the app is idle (`IdleExecutor` or a background service), the system uses an LLM agent to generate full lesson plans with slides, explanations, exercises, and presentation material for upcoming scheduled slots.
- [ ] **Slide/presentation rendering:** The lesson detail screen renders LLM-generated content as an interactive slide deck (not a flat scrollable list). Blocks become slides with navigation controls.
- [ ] **LLM agent memory:** The lesson-prep agent must have persistent memory (preferences, student level, past mistakes) to avoid starting fresh each time. Agent tools must be available.
- [ ] **Lesson blocks actually include presentation content:** The `LessonBlock` model gains a `presentationSlide` field (markdown/HTML content rendered as a slide), not just quiz/exercise/text blocks.

**Rationale:** Without this, "lessons" are a glorified reading list, not an interactive teaching experience. The vision demands *"conversational, adaptive, slide-like, interactive"* lessons. The current implementation provides none of that.

---

### B2. Focus Mode is a Useless Timer — Must Become Cross-Subject Practice Hub

**Source:** Beta-tester `focus_mode.md` + vision audit
**Severity:** BLOCKER — advertised feature is actively harmful to user experience

**Problem:** The current `FocusTimerScreen` (~1090 lines) is a Pomodoro timer that lets students answer a few due review questions during a break-structured session. The vision (agent_must_read.md:86-87) says *"adaptive practice should be a major component: the system should continuously test understanding, focus on weak areas, revisit old content intelligently."* The beta tester reports it as *"fucking useless"* — it should be a place where students practice questions from different subjects after lessons, not just a timer with incidental practice.

**Affected files:**
- `lib/features/focus_mode/` — entire feature
- `lib/features/focus_mode/services/focus_practice_service.dart` — 84 lines, thin wrapper
- `lib/features/focus_mode/presentation/screens/focus_timer_screen.dart` — timer-centric, not practice-centric

**What "fixed" looks like (Acceptance Criteria):**
- [ ] **Focus mode renamed/redesigned as "Post-Lesson Practice Hub"** — the primary purpose is cross-subject practice, not time tracking.
- [ ] **Smart question selection:** Automatically pulls due-for-review questions from ALL subjects with weak topics. Uses spaced repetition + mastery data to select the most impactful questions.
- [ ] **Adaptive difficulty:** Uses `DifficultyController` to adjust question difficulty in real-time based on performance during the session.
- [ ] **Session types:** Options for quick practice (10 questions), deep focus (30 questions), weak-area attack (all from bottom-5 topics), and exam simulation (timed random mix).
- [ ] **Post-session analytics:** Shows accuracy, topic breakdown, time per question, mastery delta after the session.
- [ ] **Timer is optional/background:** The Pomodoro timer becomes an optional overlay, not the main screen. Main view is a practice session.

**Rationale:** The current focus mode consumes screen space and user attention for a feature that doesn't serve the core study goal. The vision prioritizes *adaptive practice* and *weak area revisiting* as a primary interaction mode.

---

### B3. Mentor/Agent Agents Have No Persistent Long-Term Memory Across Sessions

**Source:** Beta-tester `lessons.md:9` (*"Agents must have long-term memory, not each new session is fresh now and toolless"*) + codebase audit
**Severity:** BLOCKER — the AI cannot build on prior knowledge of the student

**Problem:** `ConversationMemory` exists and persists messages to Hive via `ConversationRepository`, but it auto-trims to 20 turns (max 40 messages total). When a session ends, the memory is effectively lost. The mentor agent (`MentorService`) creates a new `LlmAgent` per session with no cross-session context about:
- What was discussed last time
- What action items were agreed upon and not yet completed
- Student preferences or complaints from prior sessions
- Which teaching approaches worked/didn't work

**Affected files:**
- `lib/core/services/conversation_memory.dart` — session-only, no cross-session persistence
- `lib/core/services/llm_agent/agent_loop.dart` — no long-term memory injection
- `lib/features/mentor/services/mentor_service.dart` — fresh context each session
- `lib/features/teaching/services/conversation_manager.dart` — fresh each lesson

**What "fixed" looks like (Acceptance Criteria):**
- [ ] **Student preference/summary store:** A `StudentProfile` or `StudentMemory` Hive box that stores cross-session facts: preferred difficulty, preferred teaching style, topics they've repeatedly struggled with, topics they've mastered.
- [ ] **Session summary injection:** Every conversation end triggers a summary (via LLM) that is persisted and injected as system context in the next session.
- [ ] **Memory retrieval:** `ConversationMemory` or a new `LongTermMemory` service retrieves relevant past summaries and profiles, injects them into the LLM context on session start.
- [ ] **Action item tracking:** Actions suggested by the mentor (e.g., "let's review stoichiometry next time") are persisted and presented as pending items in subsequent sessions.

**Rationale:** Without long-term memory, every interaction is a cold start. The mentor cannot build rapport, track action items, or adapt teaching style over time. This undermines the entire vision of *"a persistent mentor that understands the student's history, habits, preferences, and academic goals."*

---

## MAJOR — Feature is broken, misleading, or contradicts the vision

### M1. Planner is Entirely Deterministic — No LLM Involvement

**Vision reference:** agent_must_read.md:73-85 (*"Planning should be intelligent and long-term. The platform should estimate realistic workload, break long-term goals into manageable schedules, generate lesson pathways, assign practice, adapt plans as progress changes."*)
**Severity:** MAJOR

**Problem:** `PersonalLearningPlanService` (~986 lines), `SyllabusResolver` (~222 lines), and `PlannerService` all use deterministic algorithms (mastery scores, prerequisites, readiness scores, typical load estimates). No LLM is ever consulted for:
- Estimating realistic workload given the student's schedule
- Suggesting an optimal learning pathway
- Adapting the plan based on qualitative student feedback
- Generating creative lesson sequences or interdisciplinary connections

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart`
- `lib/features/planner/services/planner_service.dart`
- `lib/features/planner/services/syllabus_resolver.dart`

**What "fixed" looks like:**
- [ ] LLM agent is consulted during plan generation to estimate realistic workload, sequence topics optimally, and suggest study strategies
- [ ] LLM produces a structured plan outline that the deterministic engine then fills with specific questions/lessons
- [ ] Plan adaptation uses LLM to understand *why* the student is falling behind (overwhelmed vs busy vs bored) and suggests appropriate adjustments
- [ ] The `PersonalLearningPlanService` has an optional `llmAdvisor` that can override/refine deterministic decisions

**Rationale:** The vision explicitly describes planning as *intelligent* using AI. The current deterministic system is rigid and cannot account for the qualitative, contextual factors that make planning useful.

---

### M2. No Two-Way Voice Conversation in Teaching or Mentor Mode

**Vision reference:** agent_must_read.md:16-22 (*"voice conversation, speech-to-text, text-to-speech"*), line 29 (*"speak naturally with the AI tutor"*)
**Severity:** MAJOR

**Problem:** `VoiceService` exists (~201 lines), `TutorService` accepts a `VoiceService` instance, and `voice_bar.dart` is wired in. But the voice pipeline is incomplete:
- Speech-to-text transcribes but does NOT support turn-taking or interruption
- Text-to-speech speaks the tutor's response but has no conversation flow management
- No voice activity detection (VAD) to know when the student stops speaking
- Voice input in practice auto-submits partial transcriptions (reported as BLOCKER B1 in `dry_run_usability_validator.md`)
- No push-to-talk or tap-to-speak UX in the mentor chat

**Affected files:**
- `lib/core/services/voice_service.dart`
- `lib/features/teaching/presentation/widgets/voice_bar.dart`
- `lib/features/teaching/services/tutor_service.dart` (voice integration is partial)
- `lib/features/mentor/presentation/screens/mentor_screen.dart` (no voice button)

**What "fixed" looks like:**
- [ ] Voice bar in both Tutor and Mentor screens with a clear push-to-talk button
- [ ] Transcriptions are displayed in real-time for user review, not auto-submitted
- [ ] A silence timeout or "stop" button triggers submission
- [ ] TTS reads the AI's response with language-appropriate voice
- [ ] Interruption support: student can speak while TTS is playing to interrupt

**Rationale:** Voice interaction is listed as a primary interaction mode. Students studying while commuting, cooking, or with RSI (as the dry-run scenario highlights) need this to work.

---

### M3. No Handwriting/Drawing Recognition in Teaching Mode

**Vision reference:** agent_must_read.md:20 (*"handwritten/drawn responses on canvas"*), line 42 (*"interpret handwritten work"*)
**Severity:** MAJOR

**Problem:** A `CanvasDrawingWidget` exists in the question system and renders a drawing canvas. However:
- It's only available as a question answer type, not as a teaching mode input
- The AI tutor cannot receive and interpret drawn responses during a lesson
- There's no "show your working" canvas in the tutor chat
- The `processImage()` in `ConversationManager` exists but is not wired to the drawing canvas

**Affected files:**
- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart`
- `lib/features/teaching/services/conversation_manager.dart` (has `processImage()` but no drawing integration)
- `lib/features/teaching/services/tutor_service.dart`

**What "fixed" looks like:**
- [ ] Drawing canvas is available inline in tutor chat during lessons
- [ ] Student can draw (math working, diagrams, etc.) and submit to the AI tutor
- [ ] `processImage()` is called on the canvas output and the AI evaluates the drawing
- [ ] Handwriting recognition (via vision LLM or offline model) extracts text from drawn content

**Rationale:** The vision explicitly calls for *"interpret handwritten work"* and *"vision-based interpretation of student work"*. Without this, STEM teaching is severely limited — students can't show their working for math, physics, or chemistry problems.

---

### M4. No Proactive Notification/Engagement System — Mentor Only Reacts

**Vision reference:** agent_must_read.md:98 (*"proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement"*)
**Severity:** MAJOR

**Problem:** `EngagementScheduler` runs once per day at a configured hour to check well-being and generate nudges. The `MentorService.checkWellbeingAndGenerateNudges()` is called from the scheduler but:
- There is no push notification system for proactive outreach (notifications exist but aren't used for proactive engagement beyond reminders)
- No "idle student" detection (student hasn't studied in 2 days -> push notification)
- No lesson reminder 30 minutes before scheduled time
- No streak encouragement when student completes 3+ consecutive days
- No adaptive notification cadence (some students want daily, some weekly)
- The `NotificationService` exists but is not wired to `EngagementScheduler` for push notifications

**Affected files:**
- `lib/core/services/engagement_scheduler.dart`
- `lib/core/services/notification_service.dart`
- `lib/features/mentor/services/mentor_service.dart`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

**What "fixed" looks like:**
- [ ] Push notifications fire for: lesson reminders (T-30min), idle student (2+ days no study), streak milestones, missed practice, pending action items
- [ ] Notification cadence is configurable per student (daily / every 2 days / weekly / only urgent)
- [ ] Tapping a notification deep-links to the relevant screen (mentor for nudge, lesson for upcoming lesson, practice for due reviews)
- [ ] Notifications respect quiet hours (configurable in Settings)

**Rationale:** The vision emphasizes proactive engagement as a core feature. Without it, the app is passive — the student must initiate every interaction, which defeats the *"study companion"* goal.

---

### M5. No Video/Audio Content Ingestion Pipeline

**Vision reference:** agent_must_read.md:11 (*"video/audio, online website link, screenshots"*)
**Severity:** MAJOR

**Problem:** `DocumentExtractor` has audio/video transcription (line noted in exploration) but:
- No dedicated upload flow for video/audio files (current upload is document-centric)
- No YouTube/streaming link processing (URL ingestion exists but likely fails on video links)
- No visual content extraction from video frames
- No audio transcription pipeline that integrates with the ingestion system

**Affected files:**
- `lib/features/ingestion/services/document_extractor.dart` (partial audio/video)
- `lib/features/ingestion/services/content_pipeline.dart`
- `lib/features/ingestion/presentation/screens/upload_screen.dart`

**What "fixed" looks like:**
- [ ] "Upload Video/Audio" button in Content Library
- [ ] Supports: mp4, webm, mp3, wav, m4a + YouTube/streaming URLs
- [ ] Audio transcribed via speech-to-text (local or API)
- [ ] Video frames extracted and processed through vision LLM for diagram/slide content
- [ ] Transcription + visual content integrated into the knowledge system as study sources

**Rationale:** The vision explicitly lists video/audio as primary content sources. Students increasingly use video lectures (YouTube, Khan Academy, recorded classes) as study material.

---

### M6. LLM Task Manager is Built but Not Surfaced in User Workflow

**Vision reference:** agent_must_read.md:102 (*"track LLM token usage for different tasks and have a task manager-like portal to view actively running inferencing task"*)
**Severity:** MAJOR

**Problem:** `LlmTaskManager` and `LlmTaskManagerScreen` exist, but:
- The task manager screen is not linked from the main navigation (nowhere in bottom nav or drawer)
- Tokens/cost tracking works but is invisible to the user without navigating to a hidden screen
- There is no token budget per feature (e.g., "limit tutor to 50K tokens per session")
- No user-facing cost alerts or usage limits

**Affected files:**
- `lib/features/llm_tasks/presentation/screens/llm_task_manager_screen.dart` (exists but unlinked)
- `lib/features/llm_tasks/providers/llm_task_providers.dart`
- `lib/core/services/llm_task_manager.dart`
- `lib/core/routes/app_router.dart`

**What "fixed" looks like:**
- [ ] LLM Task Manager screen is accessible from Settings or a Developer menu
- [ ] Token usage is displayed per-feature in a simple dashboard card
- [ ] User can set daily/weekly token budgets per feature
- [ ] Notifications fire when approaching budget limits
- [ ] Active task count badge on mentor/tutor screens when they have LLM tasks running

**Rationale:** Students using their own API keys (OpenRouter/Ollama) need visibility into token consumption. Without this, unexpected costs can accumulate silently.

---

### M7. No Syllabus Database / Auto-Complete for Subject Creation

**Severity:** MAJOR

**Problem:** Users must manually type subject names, syllabus codes, topics, and descriptions. No pre-built syllabus database exists for common curricula (IB, A-Levels, AP, GCSE, etc.). This makes first-launch onboarding painful and creates inconsistency in topic naming.

**Affected files:**
- `lib/features/subjects/presentation/widgets/subject_form_widgets.dart` (plain TextFormField)
- `lib/features/onboarding/` (no syllabus selection step)

**What "fixed" looks like:**
- [ ] Subject creation offers auto-complete/search for common curricula
- [ ] Selecting a curriculum auto-populates topics/subtopics from seed JSON data
- [ ] Seed data ships with the app for IB, A-Level, AP, GCSE, and common national curricula
- [ ] Onboarding flow includes a "choose your curriculum" step

**Rationale:** Already noted in `dry_run_result_first_launch_ib_chemistry.md` as P1. The beta tester's complaint about lessons being "fucking useless" partly stems from the lack of structured syllabus content.

---

## MINOR — Code quality / UX friction / architectural debt

### m1. FocusPracticeService is Too Thin (84 Lines) — No Intelligent Retrieval

**Problem:** `FocusPracticeService.getDueQuestions()` retrieves all questions from the DB, separates unattempted/attempted, and takes the first 20. There is no spaced repetition priority, no weak-topic bias, no question-type diversity, no previous-performance weighting.

**Affected file:** `lib/features/focus_mode/services/focus_practice_service.dart`

**Fix:** After the main B2 focus mode rebuild, replace this service with one that uses `SpacedRepetitionService.getQuestionsDueForReview()`, weights by topic weakness from `MasteryGraphService.getWeakTopics()`, and diversifies question types.

---

### m2. CrossFeatureIntegrator Exists but Appears Unused

**Problem:** `CrossFeatureIntegrator` (~198 lines) exists in `lib/core/services/` and provides a unified timeline across sessions, practice, focus, and ingestion. But neither the Dashboard nor any screen appears to consume it — the Dashboard uses `DashboardService` which has its own aggregation logic.

**Affected file:** `lib/core/services/cross_feature_integrator.dart`

**Fix:** Either integrate it into the Dashboard data flow or remove it to reduce dead code.
**Rationale:** Dead code increases maintenance burden and confuses new developers.

---

### m3. WebScraper is Minimal (49 Lines) — No JS Rendering or Auth Support

**Problem:** The `WebScraper` does an HTTP GET and strips HTML tags. Many modern educational websites require JavaScript rendering, login sessions, or cookie handling. This makes the "website link" ingestion feature unreliable for most real-world URLs.

**Affected file:** `lib/features/ingestion/services/web_scraper.dart`

**Fix:** Consider using `flutter_html` or a headless browser API for JS-rendered content. Add cookie/session support for login-walled educational resources.

---

### m4. Planner Adherence and Plan Regeneration Not Exposed to User

**Problem:** `PlanAdherenceOrchestrator` checks adherence, detects absence, and suggests plan regeneration. But there is no visible UI indication when the plan has drifted significantly. The `DashboardScreen` has a `PlanAdherenceCard` but it's minimal.

**Affected files:**
- `lib/core/services/plan_adherence_orchestrator.dart`
- `lib/features/dashboard/presentation/widgets/plan_adherence_card.dart`

**Fix:** Show a prominent banner when the student's actual study hours deviate >30% from plan for 3+ consecutive days. Offer a one-click "Regenerate Plan" button that calls `PlannerService.extendPlan()` or `PlannerService.adjustPace()`.

---

### m5. Lesson Detail Screen is a Flat Scroll — No Slide Navigation

**Problem:** `lesson_detail_screen.dart` renders `LessonBlock` items as a vertical list. The vision calls for *"structured, visual, slide-like, or interactive"* lesson presentation.

**Affected file:** `lib/features/lessons/presentation/screens/lesson_detail_screen.dart`

**Fix:** After the main B1 rebuild, implement slide navigation (swipe or prev/next buttons) with proper presentation rendering (markdown, LaTeX, diagrams).

---

## Architecture & Infrastructure Gaps

### A1. No Background/Isolate Task Runner for Idle LLM Work

**Problem:** `IdleExecutor` exists (mentioned in `TutorService` for enqueuing post-lesson tasks like weak topic reanalysis) but there is no real background task runner. On mobile, the app goes to background and all enqueued work is lost. There's no WorkManager / Android foreground service integration.

**What's needed:**
- A `BackgroundTaskService` that uses `flutter_workmanager` or similar to run lesson preparation, nudge generation, and plan adherence checks even when the app is in background
- Respects battery/data constraints
- Cancellable by the user

**Rationale:** Without this, idle lesson preparation (B1) and proactive engagement (M4) cannot work reliably on mobile.

---

### A2. No Token Usage Metering at the User Level

**Problem:** Token tracking exists at the task level (per-LLM-call) but there's no abstraction for "how many tokens did this tutoring session use total" or per-student/per-day budgets.

**What's needed:**
- A `TokenBudgetService` that tracks rolling usage per day/per feature
- Configurable hard limits (e.g., "stop tutor after 100K tokens today")
- User-facing budget UI in Settings or LLM Task Manager

**Rationale:** Without metering, students with limited API budgets can accidentally exhaust their quota mid-session.

---

### A3. No Offline/Online Sync Layer

**Problem:** All data is stored in Hive locally. No cloud sync exists. Moving to a new device means losing all progress.

**What's needed:** This is a long-term item, not for immediate sprint. Document that the architecture needs eventual cloud sync support (Supabase or similar) for cross-device usage.

**Rationale:** Not a current priority but must be considered for any new data models.

---

## Execution Plan — Next Development Sprint

### Sprint Priority Order:

| Priority | Item | Type | Effort | Dependencies |
|---|---|---|---|---|
| P0 | **B1: Rebuild Lessons** with calendar scheduling, LLM agent prep, slide rendering | BLOCKER | 3-4 weeks | A1 (background tasks), B3 (agent memory) |
| P0 | **B2: Redesign Focus Mode** as cross-subject practice hub | BLOCKER | 2-3 weeks | None |
| P0 | **B3: Implement long-term agent memory** across sessions | BLOCKER | 1-2 weeks | None |
| P1 | **M1: Add LLM involvement to planner** | MAJOR | 1-2 weeks | B3 |
| P1 | **M4: Wire notification service for proactive engagement** | MAJOR | 1 week | A1 |
| P1 | **M6: Surface LLM task manager in navigation** | MAJOR | 2-3 days | None |
| P2 | **M2: Complete two-way voice conversation** | MAJOR | 2 weeks | None |
| P2 | **M3: Integrate drawing canvas into tutor chat** | MAJOR | 1 week | None |
| P2 | **M7: Add syllabus auto-complete / seed data** | MAJOR | 1-2 weeks | None |
| P2 | **M5: Add video/audio ingestion flow** | MAJOR | 2 weeks | None |
| P3 | **A1: Background task runner for idle LLM work** | ARCH | 2 weeks | None |
| P3 | **A2: Token usage metering + budgets** | ARCH | 1 week | M6 |
| P3 | **m1-m5: MINOR fixes** | MINOR | 3-5 days | Varies |

### When beta-tester issues are resolved:
- Delete `issues/further_issues/open/lessons.md` → move to `issues/further_issues/completed/lessons.md`
- Delete `issues/further_issues/open/focus_mode.md` → move to `issues/further_issues/completed/focus_mode.md`
- Acknowledge completion in the moved files with resolution date

---

## Summary

The codebase has a surprisingly solid foundation — real LLM integration, real SM-2, real agent architecture, real ingestion pipeline. The gaps are not from laziness but from the scope of the vision being genuinely ambitious. The three BLOCKER items (B1 lessons, B2 focus mode, B3 agent memory) represent the top complaints from beta testers and the biggest deviations from the vision. Fixing these will transform the app from "has a lot of components" to "works as a cohesive AI study companion."
