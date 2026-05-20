# Future Functionality Planner — Vision vs Implementation Gap Analysis

**Generated:** 2026-05-19  
**Source:** `agent_must_read.md` (product vision) vs actual codebase audit  
**Input from beta testers:** `issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`  
**Previous analysis:** `issues/completed/future_functionality_planner.md` (reviewed, many items resolved)

---

## BLOCKER — App crashes or user cannot proceed (or feature is so broken it's unusable)

### B1. Lessons System Lacks Calendar Scheduling, LLM Preparation, and Presentation — Full Rebuild Required

**Source:** Beta-tester `lessons.md` + vision audit  
**Severity:** BLOCKER — the core teaching loop is unusable

**Problem:** The current lesson system has:
- No calendar scheduling (Preply-like time-slot booking on a calendar)
- No separation between *lesson timing* (when the lesson happens) and *lesson content* (what is taught)
- No LLM-driven *preparation* of lesson plans in advance (idle/background LLM agent generates structured materials before class)
- Lesson blocks are rendered as a flat scrollable list, not as an interactive slide deck
- The `PlannerService.scheduleLesson()` creates a bare `Session` record, not a structured `LessonPlan` with presentation material, exercises, goals
- Agents are "toolless" — the lesson generation agent doesn't execute tools to help with scheduling, content retrieval, or student context

**Affected files:**
- `lib/features/lessons/` — entire feature (models: `lesson_model.dart`, `lesson_block_model.dart`; services: `lesson_service.dart`, `lesson_agent_service.dart`; screens: `lesson_list_screen.dart`, `lesson_detail_screen.dart`, `topic_list_screen.dart`; widget: `lesson_block_card.dart`)
- `lib/features/planner/services/planner_service.dart:288-400` — `scheduleLesson()` creates a bare `Session`, not a structured lesson plan
- `lib/features/dashboard/presentation/widgets/next_up_card.dart` — shows upcoming lessons from sessions, not from lesson plans
- `lib/core/services/engagement_scheduler.dart` — no lesson-prep scheduling or idle prep triggering
- `lib/core/services/llm_agent/idle_executor.dart` — exists (109 lines) but not wired for lesson preparation

**What "fixed" looks like (Acceptance Criteria):**
- [ ] **Calendar scheduling UI:** A Preply-like calendar view in Dashboard or Planner where students see available time slots, pick lesson time & duration, and have lessons appear as calendar events
- [ ] **Separate lesson timing from lesson content:** A `LessonSlot` model holds time/duration; a `LessonPlan` model holds the actual content. Scheduling is setting a slot; the LLM agent fills the plan later.
- [ ] **Idle LLM preparation:** When the app is idle, `IdleExecutor` or a background service triggers an LLM agent to generate structured lesson plans (slides, explanations, exercises, presentation material) for upcoming scheduled slots
- [ ] **Slide/presentation rendering:** The lesson detail screen renders LLM-generated content as an interactive slide deck (swipe navigation, page counter, full-screen mode) — not a flat scrollable list
- [ ] **Agent tool integration:** The lesson-prep agent has access to tools: `getStudentStats`, `getWeakTopics`, `searchQuestions`, `createPlan`, `getSyllabusProgress`. Tools are actually executed.
- [ ] **Agent memory persistence:** The lesson-prep agent uses `LongTermMemory.buildMemoryContext()` to inject student profile, past session summaries, and pending action items into every session
- [ ] **`LessonBlock` model gains a `presentationSlide` field** for rich markdown/LaTeX slide content (diagrams, equations, code blocks)
- [ ] **Existing `lesson_model.dart` `LessonStatus` enum** (scheduled, inProgress, completed, cancelled) is used correctly through the lifecycle

**Rationale:** Without this, "lessons" are a glorified reading list, not an interactive teaching experience. The vision demands *"conversational, adaptive, slide-like, interactive"* lessons and *"lessons must have presentation and LLM explanations."* The beta tester explicitly calls them "fucking useless."

---

### B2. Focus Mode is a Pomodoro Timer with Incidental Practice — Must Become a Cross-Subject Practice Hub

**Source:** Beta-tester `focus_mode.md` + vision audit  
**Severity:** BLOCKER — advertised feature is actively harmful to user experience

**Problem:** The current `FocusTimerScreen` (~1092 lines) is a Pomodoro-style timer where practice is an overlay. The beta tester reports it as *"fucking useless"* — it should be a place where students practice questions from different subjects after lessons, not just a timer with incidental practice. The vision calls for *"adaptive practice: continuously test understanding, focus on weak areas, revisit old content intelligently."*

**What DOES exist** (surviving features to retain):
- `InlinePracticeWidget` with per-subject quick practice (10 questions)
- `_startSpacedRepetition()` launches full `PracticeSession` with due questions
- `_startWeakAreasPractice()` fetches weak topics, filters questions
- Subject picker with due counts per subject
- Daily cap enforcement, break timer, adherence recording, badge checking
- Background time reconciliation

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — timer-centric, needs re-architecture
- `lib/features/focus_mode/services/focus_practice_service.dart` — 84 lines, thin wrapper with `getDueQuestions()` that just takes first 20 from DB with no spaced repetition priority
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` — works but is an add-on, not the main event
- `lib/features/focus_mode/providers/focus_mode_providers.dart` — minimal (10 lines)
- `lib/features/practice/services/spaced_repetition_service.dart` — `getQuestionsDueForReview()` exists but focus mode doesn't use it
- `lib/core/services/mastery_graph_service.dart` — `getWeakTopics()` exists but focus mode uses its own logic

**What "fixed" looks like (Acceptance Criteria):**
- [ ] **Focus mode renamed/redesigned to "Practice Hub"** — the primary purpose is cross-subject practice, not time tracking. Timer is an optional overlay.
- [ ] **Smart question selection uses** `SpacedRepetitionService.getQuestionsDueForReview()` with weighting by topic weakness from `MasteryGraphService.getWeakTopics()` and question-type diversity
- [ ] **Session types exposed at top level:**
  - "Quick Practice" (10 mixed questions)
  - "Deep Focus" (30 questions, timer optional)
  - "Weak Area Attack" (all from bottom-5 topics)
  - "Exam Simulation" (timed random mix)
- [ ] **Post-session analytics** shows accuracy, topic breakdown, time per question, mastery delta
- [ ] **Timer is secondary** — optional Pomodoro with configurable work/break durations, shown as a small overlay bar, not the main screen
- [ ] **`FocusPracticeService` rewritten** to delegate to `SpacedRepetitionService`, `MasteryGraphService`, and `DifficultyController` instead of doing its own naive retrieval

**Rationale:** The beta tester is unambiguous. The vision prioritizes *adaptive practice* and *weak area revisiting*. The current implementation burns screen real estate on a timer when the value is in the practice engine.

---

## MAJOR — Feature is broken, misleading, or contradicts the vision

### M1. Planner is Entirely Deterministic — No LLM Involvement in Study Planning

**Vision reference:** agent_must_read.md:73-85 (*"Planning should be intelligent and long-term. The platform should estimate realistic workload, break long-term goals into manageable schedules, generate lesson pathways, assign practice, adapt plans as progress changes."*)  
**Severity:** MAJOR

**Problem:** `PersonalLearningPlanService` (~1018 lines), `SyllabusResolver`, and `PlannerService` all use deterministic algorithms (mastery scores, prerequisites, readiness, typical load estimates). No LLM is consulted for:
- Estimating realistic workload given the student's actual schedule/demands
- Suggesting optimal learning pathways
- Adapting plans based on qualitative student feedback
- Generating creative or interdisciplinary sequences

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart` — full rewrite of plan generation to accept LLM advisor
- `lib/features/planner/services/planner_service.dart` — scheduleLesson/createPlan need LLM pathway
- `lib/features/planner/services/syllabus_resolver.dart` — prerequisite ordering could be LLM-guided

**What "fixed" looks like:**
- [ ] LLM agent is consulted during plan generation: receives student stats, study history, goals; returns a structured plan outline
- [ ] Deterministic engine fills the outline with specific questions/lessons
- [ ] Plan adaptation uses LLM to understand *why* the student is falling behind (overwhelmed vs busy vs bored) and suggests adjustments
- [ ] `PersonalLearningPlanService` has an optional `llmAdvisor` strategy

**Rationale:** The vision explicitly describes planning as *intelligent* using AI. The current deterministic system cannot account for qualitative, contextual factors.

---

### M2. Two-Way Voice Conversation is Built but Unfinished

**Vision reference:** agent_must_read.md:16-22 (*"voice conversation, speech-to-text, text-to-speech"*), line 29 (*"speak naturally with the AI tutor"*)  
**Severity:** MAJOR

**Problem:** `VoiceService` (~239 lines) exists and both tutor and mentor screens have voice buttons. But the pipeline is incomplete:
- No turn-taking support — user must manually tap to start/stop listening
- No voice activity detection (VAD) to know when the student stops speaking
- No interruption support — student can't speak while TTS is playing
- No TTS voice selection per locale (uses default only)
- Voice input in practice auto-submits partial transcriptions without user review

**Affected files:**
- `lib/core/services/voice_service.dart` — needs VAD, interruption, voice selection
- `lib/features/teaching/presentation/widgets/voice_bar.dart` — needs turn-taking UX
- `lib/features/mentor/presentation/mentor_screen.dart` — voice button exists but no conversation flow
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — auto-submits transcribed text

**What "fixed" looks like:**
- [ ] Push-to-talk button with clear state: idle → listening → processing → done
- [ ] Transcriptions displayed in real-time for user review, NOT auto-submitted
- [ ] Silence timeout (2s) triggers submission OR user taps stop
- [ ] TTS reads AI response with locale-appropriate voice (per-locale voice from `flutter_tts`)
- [ ] Speaking while TTS is playing pauses TTS (interruption)
- [ ] Works in both Tutor and Mentor screens consistently

**Rationale:** Voice interaction is listed as a primary interaction mode. Students studying while commuting, cooking, or with accessibility needs depend on this.

---

### M3. No Handwriting Recognition or Inline Drawing Canvas in Tutor Chat

**Vision reference:** agent_must_read.md:20 (*"handwritten/drawn responses on canvas"*), line 42 (*"interpret handwritten work"*)  
**Severity:** MAJOR

**Problem:** A `CanvasDrawingWidget` (~289 lines) exists for `QuestionType.canvas` answers but:
- It's only available as a question answer type, NOT as a tutor chat input
- The AI tutor cannot receive and interpret drawn responses during a lesson
- There's no "show your working" canvas inline in tutor chat
- No handwriting-to-text conversion exists (for extracting math equations, diagrams, etc.)
- `QuestionType.graphDrawing` exists in the enum and i18n strings exist for "GraphCanvas" but NO widget implements it

**Affected files:**
- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` — only freehand, no shapes/text/graph tools despite i18n strings existing
- `lib/features/questions/presentation/painters/drawing_painter.dart` — renders strokes but doesn't support shape recognition
- `lib/features/questions/presentation/painters/grid_painter.dart` — grid background only
- `lib/features/teaching/services/conversation_manager.dart` — `processImage()` exists but needs drawing source
- `lib/features/teaching/presentation/tutor_screen.dart` — no inline drawing canvas widget
- `lib/features/questions/data/models/drawing_models.dart` — `pressure` field exists but never populated

**What "fixed" looks like:**
- [ ] Drawing canvas available inline in tutor chat during lessons (as an attachment button alongside camera/image picker)
- [ ] Student can draw (math working, diagrams, graphs, etc.) and submit to the AI tutor
- [ ] `ConversationManager.processImage()` called on canvas output; AI evaluates the drawing
- [ ] Handwriting recognition (via vision LLM or future offline model) extracts text from drawn content
- [ ] Graph drawing widget exists for `QuestionType.graphDrawing` with coordinate axes, plot points
- [ ] Drawing widget gains: stroke width selector, color picker, undo/redo support

**Rationale:** Without inline drawing, STEM teaching is severely limited — students can't show their working for math, physics, or chemistry problems. The vision explicitly calls for *"interpret handwritten work"* and *"vision-based interpretation of student work."*

---

### M4. No Persistent Background Task Runner for Idle LLM Work

**Vision reference:** agent_must_read.md:98 (*"proactively engage students with reminders, prompts, revision nudges, lesson notifications"*), line 102 (*"task manager-like portal to view actively running inferencing tasks"*)  
**Severity:** MAJOR

**Problem:** `IdleExecutor` (~109 lines) exists and is called from `TutorService` for enqueuing post-lesson tasks (adherence check, weak-topic reanalysis, next-topic prep). But:
- `IdleExecutor` runs only while the app is in the foreground
- On mobile, when the app goes to background, all enqueued work is lost
- No WorkManager / Android foreground service integration exists
- `EngagementScheduler` relies on a Dart `Timer`, not persistent OS scheduling — killed when app is killed
- No periodic background lesson preparation, nudge checking, or adherence tracking

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart` — foreground-only, no persistence
- `lib/core/services/engagement_scheduler.dart` — Dart timer, not persistent
- `lib/core/services/notification_service.dart` — notifications exist but scheduling across restarts is minimal
- `lib/features/lessons/services/lesson_agent_service.dart` — no background prep trigger
- `pubspec.yaml` — no `flutter_workmanager` dependency

**What "fixed" looks like:**
- [ ] `flutter_workmanager` (or equivalent) integrated for background task scheduling
- [ ] Background tasks registered: lesson prep (for upcoming scheduled lessons), nudge generation (daily check), plan adherence (periodic)
- [ ] `EngagementScheduler` uses `workmanager` periodic task for daily nudge checks instead of Dart `Timer`
- [ ] Background tasks respect battery/data constraints and are cancellable from Settings
- [ ] Scheduled notifications survive app restart (use `flutter_local_notifications` `periodicallyShow` for daily reminders, `ZonedSchedule` for lesson reminders)

**Rationale:** Without persistent background tasks, lesson preparation (B1), proactive engagement (vision:98), and plan adherence monitoring cannot work reliably on mobile. The vision expects the system to engage proactively, not only when the app is open.

---

### M5. CrossFeatureIntegrator Exists but is Orphaned Dead Code

**Severity:** MAJOR (dead code)

**Problem:** `CrossFeatureIntegrator` (~198 lines) in `lib/core/services/` provides a unified timeline across sessions, practice, focus, and ingestion. But no screen consumes it — the Dashboard uses `DashboardService` with its own aggregation. The integrator creates an unused abstraction layer.

**Affected files:**
- `lib/core/services/cross_feature_integrator.dart` — entire file, 198 lines of dead code
- `lib/features/dashboard/services/dashboard_service.dart` — has its own aggregation, doesn't use integrator

**What "fixed" looks like:**
- **Either:** Integrate it into the Dashboard data flow (e.g., DashboardService delegates to CrossFeatureIntegrator for timeline queries)
- **Or:** Remove the file entirely

**Rationale:** Dead code increases maintenance burden and confuses new developers.

---

### M6. LLM Task Manager is Built but Token Budget/Metering is Missing

**Vision reference:** agent_must_read.md:102 (*"track LLM token usage for different tasks and have a task manager-like portal"*)  
**Severity:** MAJOR

**Problem:** `LlmTaskManager` (~238 lines), `LlmUsageMeter` (~142 lines), and `LlmTaskManagerScreen` (~415 lines) exist. But:
- No per-feature token budget or daily/weekly spending limits
- No user-facing cost alerts or throttling when approaching budget
- No cost-per-model configuration (uses hardcoded pricing, not OpenRouter's per-model rates)
- Token counting for streaming is approximate (`content.length ~/ 4`)
- System prompt tokens are not counted
- No way for the user to set caps like "stop tutor after 50K tokens today"

**Affected files:**
- `lib/core/services/llm_usage_meter.dart` — lacks budget enforcement
- `lib/core/services/llm_task_manager.dart` — lacks budget checking on task creation
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — no budget UI
- `lib/features/settings/presentation/settings_screen.dart` — shows usage but no budget controls
- `lib/core/services/llm/llm_chat_service.dart` — streaming token estimation is approximate

**What "fixed" looks like:**
- [ ] `TokenBudgetService` tracks rolling usage per-day/per-feature with configurable hard limits
- [ ] Settings screen has per-feature token budget controls (text field + slider)
- [ ] Notifications fire when approaching 80%/100% of budget
- [ ] LLM service rejects calls that would exceed budget
- [ ] Per-model pricing configurable (map of model ID → cost per 1K tokens)
- [ ] System prompt tokens included in input token count

**Rationale:** Students using their own API keys need cost visibility and control. Without budgets, unexpected costs accumulate silently.

---

### M7. Real PDF Extraction Needs a Proper PDF Library

**Severity:** MAJOR

**Problem:** `PdfExtractor` (`lib/core/data/extraction/pdf_extractor.dart`, ~152 lines) uses regex-based text extraction from raw PDF bytes. This will fail on:
- Scanned PDFs (no OCR pipeline)
- PDFs with compressed content streams
- PDFs with non-standard encoding
- Any PDF where text isn't stored as simple PDF text objects

**Affected files:**
- `lib/core/data/extraction/pdf_extractor.dart` — regex-based, fragile
- `lib/features/ingestion/services/document_extractor.dart` — delegates to PdfExtractor

**What "fixed" looks like:**
- [ ] Add a proper PDF library (`pdfium` or `syncfusion_flutter_pdfviewer` or `advance_pdf_viewer2`)
- [ ] Text extraction uses the library's text extraction API, not regex
- [ ] For scanned PDFs: integrate ML Kit OCR or Tesseract as a fallback
- [ ] Preserve page structure, headings, order

**Rationale:** PDFs are the #1 content format for student materials (textbooks, worksheets, past papers). The current regex-based approach makes the "upload materials" feature unreliable for most real-world PDFs.

---

### M8. OCR is LLM-Only — No Local OCR Engine

**Severity:** MAJOR

**Problem:** `OcrExtractor` (`lib/core/data/extraction/ocr_extractor.dart`, ~185 lines) base64-encodes images and sends them to an LLM with a vision prompt. There is no:
- Tesseract integration
- ML Kit text recognition
- Any offline OCR engine
- OCR confidence metrics (hardcoded to 0.7)
- Performance optimization (every image incurs LLM cost + latency)

**Affected files:**
- `lib/core/data/extraction/ocr_extractor.dart` — LLM-only
- `pubspec.yaml` — no `google_mlkit_text_recognition` or `tesseract_ocr`

**What "fixed" looks like:**
- [ ] Primary OCR: `google_mlkit_text_recognition` (free, on-device, fast)
- [ ] LLM OCR as fallback: when ML Kit confidence is low or the text is complex (diagrams, equations)
- [ ] Per-image confidence scores stored with extraction results
- [ ] OCR result used for question generation from images (e.g., screenshot of a textbook page)

**Rationale:** Every image requiring an LLM call is slow (3-10s) and expensive ($0.01-0.05/image). For students uploading multiple screenshots, this is prohibitive.

---

### M9. No Video/Audio File Speech-to-Text Pipeline

**Vision reference:** agent_must_read.md:11 (*"video/audio"*)  
**Severity:** MAJOR

**Problem:** The ingestion pipeline handles video/audio files by base64-encoding and sending to an LLM. There is no:
- Whisper integration (local or API)
- FFMpeg for media processing
- YouTube Data API v3 integration (uses third-party `youtubetranscript.com`)
- Media playback UI or media metadata extraction (duration, codec, sample rate)
- Frame extraction from video for visual content processing

**Affected files:**
- `lib/core/data/extraction/transcription_extractor.dart` (~358 lines) — no proper STT engine
- `lib/features/ingestion/services/document_extractor.dart` — audio/video methods use LLM passthrough
- `lib/features/ingestion/presentation/upload_screen.dart` — accepts video/audio files but processing is unreliable

**What "fixed" looks like:**
- [ ] Speech-to-text via OpenAI Whisper API or local Whisper.cpp for media files
- [ ] YouTube Data API v3 captions endpoint integration (config exists in `app_api_config.dart` but unused)
- [ ] FFMpeg for media inspection (duration, codec, bitrate) and frame extraction
- [ ] Uploaded media shows processing progress: transcribing → generating content → complete
- [ ] Transcription text integrated into knowledge system as a study source

**Rationale:** Students increasingly use video lectures (YouTube, Khan Academy, recorded classes). The current LLM-passthrough approach is unreliable and expensive.

---

## MINOR — Code quality / UX friction / architectural debt

### m1. NoScreenshot/widget Testing for Critical Flows

**Problem:** Despite 405 test files in `test/`, there are no screenshot or widget integration tests for critical flows: onboarding, lesson viewing, focus mode, tutor chat. Tests are primarily unit tests for services/repositories with fakes.

**Affected:** Entire test suite (unit-only focus)
**Fix:** Add widget tests for: onboarding flow completes → subject selection screen renders; focus mode shows practice hub with topics; tutor screen shows chat + slides toggle

---

### m2. WebScraper is Too Minimal for Modern Websites

**Problem:** `WebScraper` (49 lines) does an HTTP GET and strips HTML tags. Many educational websites require JavaScript rendering, login sessions, or cookie handling. The "website link" ingestion is unreliable for most real URLs.

**Affected file:** `lib/features/ingestion/services/web_scraper.dart`
**Fix:** Consider headless browser API for JS-rendered content; add cookie/session support for login-walled resources.

---

### m3. Agent Loop Tools Exist in Mentor but Missing in Lesson/Planner Agents

**Problem:** Mentor has 7 tools (schedule lesson, create plan, get weak topics, get stats, search questions, generate blocks, get syllabus). But the lesson generation agent (`LessonAgentService`) and planner service have NO tool access — they're plain LLM calls without the agent loop.

**Affected files:**
- `lib/features/lessons/services/lesson_agent_service.dart` — uses `LlmService.chatStream()` directly, no agent
- `lib/features/planner/services/personal_learning_plan_service.dart` — entirely deterministic
**Fix:** Use `LlmAgent` pattern (agent loop + tools) for lesson prep and plan generation, same as mentor.

---

### m4. Configuration System is Only Locale — No Environment/API Config Abstraction

**Problem:** `lib/core/config/` has only `locale_config.dart` (31 lines). No dev/staging/prod environment config, no API URL abstraction beyond constants in `app_api_config.dart`, no feature flags.

**Affected files:**
- `lib/core/config/` — only locale_config.dart
- `lib/core/constants/app_api_config.dart` — has `// TODO: implement runtime secret injection` at line 32
**Fix:** Implement environment-aware config (dev/staging/prod) with overridable API endpoints, feature flags, and secret injection.

---

## Execution Plan — Next Development Sprint

### Priority Order (Beta Tester Issues First):

| Priority | Item | Type | Effort | Dependencies |
|---|---|---|---|---|
| **P0** | **B1: Lessons overhaul** — calendar scheduling, LLM prep, slide rendering, agent tools, memory | BLOCKER | 3-4 weeks | M4 (background tasks), m3 (agent tools) |
| **P0** | **B2: Focus mode → Practice Hub** — cross-subject practice, smart selection, session types | BLOCKER | 2-3 weeks | None (uses existing SpacedRepetitionService) |
| **P1** | **M4: Background task runner** — WorkManager integration for persistent scheduling | MAJOR | 2 weeks | None |
| **P1** | **M6: Token budget/metering** — per-feature budgets, cost alerts | MAJOR | 1 week | None |
| **P2** | **M1: LLM involvement in planner** — LLM advisor for plan generation | MAJOR | 1-2 weeks | m3 (agent tools for planner) |
| **P2** | **M2: Complete two-way voice** — VAD, interruption, TTS voice selection | MAJOR | 1-2 weeks | None |
| **P2** | **M3: Inline drawing canvas in tutor chat** + graph canvas widget | MAJOR | 1 week | None |
| **P2** | **M7: Proper PDF extraction** with pdfium/syncfusion | MAJOR | 1 week | None |
| **P2** | **M8: Local OCR engine** (ML Kit) with LLM fallback | MAJOR | 1 week | None |
| **P2** | **M9: Real STT for media files** (Whisper API) + YouTube Data API | MAJOR | 1-2 weeks | None |
| **P3** | **M5: Delete or integrate CrossFeatureIntegrator** | MAJOR | 2 days | None |
| **P3** | **m1: Widget tests for critical flows** | MINOR | 3-5 days | M4, B1, B2 |
| **P3** | **m2: WebScraper improvements** | MINOR | 2-3 days | None |
| **P3** | **m3: Agent tools for lesson/planner agents** | MINOR | 3-5 days | None |
| **P3** | **m4: Environment config abstraction** | MINOR | 2-3 days | None |

### Notes:
- Items B1 and B2 are the beta testers' top complaints AND the biggest deviations from the product vision
- M4 (background tasks) is a hard dependency for B1 (idle LLM preparation must survive app backgrounding)
- M3 (agent tools) should be extended to non-mentor agents during B1 implementation
- All M items (MAJOR) are ordered by impact on the daily student experience

### When beta-tester issues are resolved:
- Delete `issues/further_issues/open/lessons.md` → move to `issues/further_issues/completed/lessons.md`
- Delete `issues/further_issues/open/focus_mode.md` → move to `issues/further_issues/completed/focus_mode.md`
- Acknowledge completion in the moved files with resolution date

---

## Architectural Notes for Future

These are long-term items that don't block the current sprint but must inform architectural decisions:

1. **Cloud sync** — All data is local Hive. No cross-device sync exists. Consider Supabase or similar for future multi-device support.
2. **Scalable PDF/image extraction** — Current per-file LLM processing doesn't scale. For a student uploading a 300-page textbook, batch processing with page-level chunking is needed.
3. **Offline-first** — Everything is already offline (local Hive + local Ollama support), which is good. The LLM task/TTS/STT dependency on APIs reduces offline capability when using OpenRouter.
4. **Multi-tenancy** — Single-student architecture. No parent/teacher dashboard, no class management.
