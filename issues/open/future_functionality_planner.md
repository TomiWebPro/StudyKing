# Future Functionality Planner — Vision vs Implementation Gap Analysis (v2)

**Generated:** 2026-05-20
**Source:** `agent_must_read.md` (product vision) vs actual codebase audit
**Input from beta testers:** `issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`
**Previous analysis:** `issues/completed/future_functionality_planner.md` (acknowledged — many items resolved since v1)

---

## Progress Since v1 (Previously Completed Items)

The following items from the v1 report are now **resolved** and no longer tracked here:

| Item | Status | Evidence |
|---|---|---|
| M3: Drawing canvas in tutor chat | ✅ DONE | `TutorScreen._openDrawingCanvas()` (tutor_screen.dart:291) calls `CanvasDrawingWidget`, passes output to `ConversationManager.processImage()`. Graph drawing widget exists at `graph_drawing_widget.dart`. |
| Agent loop infrastructure | ✅ DONE | `agent_loop.dart` (217 lines, ReAct pattern), `LlmAgent` (98 lines), `ToolRegistry` (27 lines), `AgentMemoryStore` (105 lines) — all present in `lib/core/services/llm_agent/` |
| Long-term memory system | ✅ DONE | `long_term_memory.dart` (200 lines), `agent_memory.dart` (105 lines) — persistent cross-session memory |
| Calendar view widget | ✅ DONE | `calendar_view_widget.dart` (244 lines) in planner with month grid, day details, roadmap/plan items |
| Lesson booking sheet | ✅ DONE | `lesson_booking_sheet.dart` (312 lines) with date/time/duration selection, conflict detection |
| Mentor agent tools (7 tools) | ✅ DONE | `search_questions_tool.dart`, `get_student_stats_tool.dart`, `get_weak_topics_tool.dart`, `generate_lesson_blocks_tool.dart`, `create_plan_tool.dart`, `schedule_lesson_tool.dart` |

---

## BLOCKER — App crashes or user cannot proceed

### B1. Lessons System: Calendar Scheduling, LLM Agent Preparation, and Rich Presentation Still Missing

**Source:** Beta-tester `lessons.md` + vision audit (`agent_must_read.md:27-47`)
**Severity:** BLOCKER — core teaching loop remains sub-par

**Problem:** Despite calendar_view_widget and lesson_booking_sheet existing in the **planner**, the **lessons feature itself** still has fundamental gaps:
- **No lesson scheduling via calendar**: The `CalendarViewWidget` shows roadmaps/plans, not lesson time slots. `LessonBookingSheet` schedules a bare `Session`, not a `LessonPlan` with content.
- **LessonAgentService uses raw LLM calls, not LlmAgent**: `lesson_agent_service.dart` calls `_llmService.chat()` directly with a manually constructed prompt. It does NOT use the `LlmAgent`/`AgentLoop`/`ToolRegistry` infrastructure that exists in `lib/core/services/llm_agent/`. No tools (getStudentStats, getWeakTopics, searchQuestions) are available during lesson generation.
- **No background/idle lesson preparation**: `IdleExecutor` is never enqueued with lesson-prep tasks. No pre-generated lesson plans for upcoming slots.
- **Slides are plain text, not rich presentation**: `LessonBlockCard` renders slide blocks as plain text in a `PageView`. No markdown/LaTeX rendering, no images, no code blocks with syntax highlighting.
- **LessonAgentService does NOT use LongTermMemory**: It does not inject student profile, past session summaries, or pending actions into the generation context.

**Affected files:**
- `lib/features/lessons/services/lesson_agent_service.dart` (302 lines) — uses raw `_llmService.chat()`, no `LlmAgent`/tools/memory
- `lib/features/lessons/data/models/lesson_block_model.dart` (76 lines) — `LessonBlock` has no `presentationSlide` sub-model, no rich content fields (markdown, LaTeX, images)
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` (504 lines) — slides are text-only `PageView`, no rich rendering
- `lib/features/lessons/presentation/lesson_detail_screen.dart` (263 lines) — no calendar scheduling integration
- `lib/core/services/llm_agent/idle_executor.dart` (109 lines) — no lesson-prep enqueueing
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` (244 lines) — shows roadmaps/plans only, not lesson time slots
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` (312 lines) — creates bare `Session`, not `LessonPlan`
- `lib/features/planner/services/planner_service.dart` — `scheduleLesson()` creates `Session` without triggering LLM lesson prep

**Acceptance Criteria:**
- [ ] `LessonAgentService` refactored to use `LlmAgent` (agent loop + tools + memory) instead of raw `LlmService.chat()`
- [ ] Lesson-prep agent tools registered: `getStudentStats`, `getWeakTopics`, `searchQuestions`, `getSyllabusProgress`, `createLessonPlan`
- [ ] `LongTermMemory.buildMemoryContext()` injected into lesson generation prompts
- [ ] `LessonBlock` gains `richContent` field supporting markdown + LaTeX + image references
- [ ] `LessonBlockCard` renders slide blocks as rich markdown/LaTeX with syntax-highlighted code blocks
- [ ] `CalendarViewWidget` shows scheduled lesson slots (time + topic) with tap-to-view details
- [ ] `LessonBookingSheet.onSchedule()` triggers `IdleExecutor.enqueue()` for background lesson prep
- [ ] Background lesson prep generates structured `LessonPlan` with slides, exercises, examples, summary
- [ ] Lesson detail screen shows slide count + "LLM-prepared" badge when content was pre-generated
- [ ] Slide full-screen mode includes markdown rendering, image support, LaTeX equation rendering

**Rationale:** Without these, "lessons" remain a reading list with text slides. The beta tester explicitly calls the current experience "fucking useless." The agent loop, tools, and memory infrastructure already exist — the lessons feature simply doesn't use them.

---

### B2. Focus Mode Remains Timer-Centric — Practice Hub Vision Not Realized

**Source:** Beta-tester `focus_mode.md` + vision audit (`agent_must_read.md:86-87`)
**Severity:** BLOCKER — advertised feature is actively harmful to UX

**Problem:** While a "Study Hub" toggle was added, core practice delivery is broken:
- **`FocusPracticeService.getDueQuestions()` does NOT use `SpacedRepetitionService`** — it loads ALL questions, puts unattempted first, attempted fill rest. No `nextReview` filtering.
- **`InlinePracticeWidget` loads ALL questions from repo, shuffles, takes N** — no spaced repetition awareness whatsoever.
- **Wrong answers in inline practice are silently dropped** — `MasteryRecorder.recordAttempt()` is only called for correct answers. Wrong answers never enter the mastery/spaced-repetition system.
- **Post-session analytics data is collected but thrown away** — `_onInlinePracticeComplete()` handler in `FocusTimerScreen` resets state without storing accuracy data.
- **`FocusSession` model (77 lines) is completely dead code** — never instantiated by any production code path.

**Affected files:**
- `lib/features/focus_mode/services/focus_practice_service.dart` (84 lines) — naive question selection, does not use `SpacedRepetitionService.getQuestionsDueForReview()`
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` (321 lines) — loads ALL questions, no due-date filtering, wrong answers not recorded
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1207 lines) — `_onInlinePracticeComplete()` ignores accuracy data
- `lib/features/focus_mode/data/models/focus_session_model.dart` (77 lines) — dead code, never used
- `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` (138 lines) — shows only time stats, no practice performance data
- `lib/features/practice/services/spaced_repetition_service.dart` (250 lines) — `getQuestionsDueForReview()` exists but focus mode ignores it

**Acceptance Criteria:**
- [ ] `FocusPracticeService.getDueQuestions()` delegates to `SpacedRepetitionService.getQuestionsDueForReview()` with weighting by `MasteryGraphService.getWeakTopics()`
- [ ] `InlinePracticeWidget._loadQuestions()` filters by `nextReview <= now` (due questions only) when not in "Quick Practice" mode
- [ ] Wrong answers in inline practice are recorded via `MasteryRecorder.recordAttempt()` with `isCorrect: false`
- [ ] `_onInlinePracticeComplete()` stores per-subject accuracy data and passes it to a post-session analytics widget
- [ ] `SessionSummaryCard` shows accuracy %, topic breakdown, and mastery delta (not just time stats) when practice data is available
- [ ] `FocusSession` model either deleted or actually wired into the post-session flow
- [ ] Session type options at top level: "Quick Practice", "Spaced Repetition", "Weak Area Attack", "Free Focus (timer only)"

**Rationale:** The beta tester is unambiguous: "fucking useless." The vision prioritizes adaptive practice as a major component. The inline practice silently discards wrong answers, making it actively harmful to the mastery system's accuracy.

---

## MAJOR — Feature is broken, misleading, or contradicts the vision

### M1. Planner is Entirely Deterministic — No LLM Involvement in Study Planning

**Vision reference:** `agent_must_read.md:73-85`
**Severity:** MAJOR

**Problem:** `PersonalLearningPlanService` (~1036 lines), `SyllabusResolver` (~222 lines), and `PlannerService` (~580 lines) all use deterministic algorithms. A grep for `llm`, `LlmService`, or `LLM` in `personal_learning_plan_service.dart` returns **zero matches**. No LLM is consulted for workload estimation, pathway suggestion, plan adaptation, or qualitative feedback processing.

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart` — full 1036 lines, zero LLM references
- `lib/features/planner/services/planner_service.dart` — `scheduleLesson()`/`createPlan()` need LLM guidance
- `lib/features/planner/services/syllabus_resolver.dart` — prerequisite ordering could be LLM-optimized

**Acceptance Criteria:**
- [ ] LLM agent consulted during plan generation: receives student stats, study history, goals; returns structured plan outline
- [ ] `PersonalLearningPlanService` has an optional `llmAdvisor` strategy for non-deterministic planning
- [ ] Plan adaptation uses LLM to understand *why* student is falling behind (overwhelmed vs busy vs bored) and suggests adjustments
- [ ] At minimum, LLM generates the motivational reasoning and summary for each plan milestone

**Rationale:** The vision explicitly says "intelligent and long-term" planning. Deterministic mastery-score algorithms cannot account for qualitative, contextual factors like student burnout, schedule changes, or content difficulty perception.

---

### M2. Voice Conversation Built but Lacks Natural Turn-Taking

**Vision reference:** `agent_must_read.md:16-22`, line 29
**Severity:** MAJOR

**Problem:** `VoiceService` (239 lines) exists and both tutor and mentor screens have voice buttons. It uses the platform's built-in silence detection (`pauseFor: Timeouts.voicePause`). But:
- **No user-review step**: Transcriptions are streamed directly into the input field. Students can't review/edit before sending.
- **No voice activity detection (VAD)** for knowing when the student stops speaking naturally — relies on a fixed silence timeout.
- **No per-locale voice selection** for TTS — uses default system voice regardless of the app locale.
- **No interruption support** — speaking while TTS plays stops TTS but there's no resume-from-interruption UX.
- **Voice bar in tutor screen** exists but no clear conversation flow (idle → listening → processing → speaking state machine in UI).

**Affected files:**
- `lib/core/services/voice_service.dart` (239 lines) — `startListening()` uses `pauseFor` timeout, no real VAD
- `lib/features/teaching/presentation/widgets/voice_bar.dart` — no state machine UI for voice flow
- `lib/features/mentor/presentation/mentor_screen.dart` — voice button exists but no conversation flow
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — voice input auto-submits

**Acceptance Criteria:**
- [ ] Voice button states: idle (microphone icon) → listening (pulsing wave) → processing (spinner) → done (checkmark)
- [ ] Transcriptions displayed in a text field for user review before submission
- [ ] Silence timeout (2s configurable) triggers ready-for-review state OR user taps stop
- [ ] TTS voice selection per locale (map of locale → flutter_tts voice name)
- [ ] Speaking while TTS plays → TTS pauses, microphone stays active
- [ ] Consistent voice UX across Tutor screen, Mentor screen, and Practice screen

**Rationale:** Voice is a primary interaction mode. Without VAD and review, the experience is error-prone and frustrating.

---

### M3. No Persistent Background Task Runner for Idle LLM Work

**Vision reference:** `agent_must_read.md:98`, line 102
**Severity:** MAJOR

**Problem:** `IdleExecutor` (109 lines) exists but:
- Runs only while the app is in the foreground (Dart `Timer`)
- No `flutter_workmanager` or equivalent for persistent OS scheduling
- `EngagementScheduler` (455 lines) relies on a Dart `Timer`, not persistent OS scheduling
- No periodic background lesson preparation, nudge checking, or adherence tracking
- No notification scheduling that survives app restart (uses `periodicallyShow` but no `ZonedSchedule`)

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart` (109 lines) — foreground-only
- `lib/core/services/engagement_scheduler.dart` (455 lines) — Dart Timer, not persistent
- `lib/core/services/notification_service.dart` (343 lines) — notifications exist but background scheduling is minimal
- `pubspec.yaml` — no `flutter_workmanager` dependency

**Acceptance Criteria:**
- [ ] `flutter_workmanager` integrated for background task scheduling
- [ ] Background tasks: lesson prep (for upcoming scheduled lessons), nudge generation (daily), plan adherence (periodic)
- [ ] `EngagementScheduler` uses `workmanager` periodic task instead of Dart `Timer`
- [ ] Scheduled notifications survive app restart (`flutter_local_notifications` `ZonedSchedule`)
- [ ] Background tasks respect battery/data constraints, cancellable from Settings

**Rationale:** Without persistent background tasks, lesson preparation (B1), proactive engagement, and plan adherence monitoring cannot work reliably on mobile.

---

### M4. Token Usage Tracked but No Budget Enforcement

**Vision reference:** `agent_must_read.md:102`
**Severity:** MAJOR

**Problem:** `LlmTaskManager` (238 lines) and `LlmUsageMeter` (142 lines) exist. `TokenPricingConfig` (20 lines) exists in constants. But:
- No per-feature token budget or daily/weekly spending limits
- No user-facing cost alerts or throttling
- No cost-per-model configuration (uses hardcoded pricing)
- Token counting for streaming is approximate (`content.length ~/ 4`)
- System prompt tokens are not counted
- No way for the user to set caps like "stop tutor after 50K tokens today"

**Affected files:**
- `lib/core/services/llm_usage_meter.dart` (142 lines) — no budget enforcement
- `lib/core/services/llm_task_manager.dart` (238 lines) — no budget checking on task creation
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — no budget UI
- `lib/features/settings/presentation/settings_screen.dart` — shows usage but no budget controls
- `lib/core/constants/token_pricing_config.dart` (20 lines) — hardcoded pricing

**Acceptance Criteria:**
- [ ] `TokenBudgetService` tracks rolling usage per-day/per-feature with configurable hard limits
- [ ] Settings screen has per-feature token budget controls
- [ ] Notifications at 80%/100% of budget
- [ ] LLM service rejects calls that would exceed budget
- [ ] Per-model pricing configurable (map of model ID → cost per 1K tokens)
- [ ] System prompt tokens included in input token count

**Rationale:** Students using their own API keys need cost visibility and control. Without budgets, unexpected costs accumulate silently, undermining trust.

---

### M5. Real PDF Extraction Still Uses Regex — No Proper Library

**Severity:** MAJOR

**Problem:** `PdfExtractor` (152 lines) still uses `String.fromCharCodes(bytes)` + regex extraction from raw PDF bytes. The `pdf: ^3.10.4` package exists in `pubspec.yaml` but is **not imported** by `PdfExtractor`. This fails on:
- Scanned PDFs (no OCR pipeline)
- PDFs with compressed content streams
- PDFs with non-standard encoding
- Any PDF where text isn't stored as simple PDF text objects

**Affected files:**
- `lib/core/data/extraction/pdf_extractor.dart` (152 lines) — regex-based, fragile
- `lib/features/ingestion/services/document_extractor.dart` — delegates to PdfExtractor
- `pubspec.yaml` — has `pdf: ^3.10.4` but unused by extraction code

**Acceptance Criteria:**
- [ ] Use `pdf` package's `PdfDocument.openBytes()` for proper text extraction
- [ ] Page structure preserved (headings, order, paragraph grouping)
- [ ] For scanned PDFs: integrate ML Kit OCR as page-level fallback
- [ ] Extraction method string reflects whether it used text extraction or OCR

**Rationale:** PDFs are the #1 content format for student materials. The regex approach makes "upload materials" unreliable for most real-world PDFs.

---

### M6. OCR is LLM-Only — No Local OCR Engine

**Severity:** MAJOR

**Problem:** `OcrExtractor` (185 lines) base64-encodes images → sends to LLM with vision prompt. No offline OCR engine exists.
- Every image = LLM call ($0.01-0.05 + 3-10s latency)
- No confidence scoring beyond hardcoded `0.7`
- No support for batch/document scanning

**Affected files:**
- `lib/core/data/extraction/ocr_extractor.dart` (185 lines) — LLM-only
- `pubspec.yaml` — no `google_mlkit_text_recognition` dependency

**Acceptance Criteria:**
- [ ] Primary OCR: `google_mlkit_text_recognition` (free, on-device, fast)
- [ ] LLM OCR as fallback when ML Kit confidence is low or text is complex (diagrams, equations)
- [ ] Per-image confidence scores stored with extraction results
- [ ] Document scanning mode: multiple images → merge results

**Rationale:** Every image requiring an LLM call is slow and expensive. For students uploading multiple screenshots or scanning textbook pages, this is prohibitive.

---

### M7. No Proper STT Pipeline for Media Files — YouTube Uses Third-Party API

**Vision reference:** `agent_must_read.md:11` (video/audio)
**Severity:** MAJOR

**Problem:** `TranscriptionExtractor` (358 lines) uses:
- `youtubetranscript.com` API (third-party, rate-limited, may go down) for YouTube videos
- `LlmService` for audio/video file transcription (slow, expensive, no language detection)
- No Whisper API (OpenAI or local Whisper.cpp) integration
- No FFMpeg for media inspection or frame extraction
- No media playback UI or progress bar during transcription
- YouTube Data API v3 config exists (`app_api_config.dart`) but is unused

**Affected files:**
- `lib/core/data/extraction/transcription_extractor.dart` (358 lines) — youtubetranscript.com + LlmService only
- `lib/features/ingestion/services/document_extractor.dart` — delegates audio/video to TranscriptionExtractor
- `lib/features/ingestion/presentation/upload_screen.dart` — accepts video/audio but processing is unreliable
- `lib/core/constants/app_api_config.dart` — YouTube Data API config exists but unused

**Acceptance Criteria:**
- [ ] Whisper API (OpenRouter or direct OpenAI) as primary STT for uploaded audio/video files
- [ ] YouTube Data API v3 captions endpoint as primary YouTube STT (with youtubetranscript.com fallback)
- [ ] FFMpeg for media inspection (duration, codec, sample rate) and frame extraction for visual content
- [ ] Processing progress shown: uploading → transcribing → generating content → complete
- [ ] YouTube API key configurable in Settings > AI Configuration

**Rationale:** Students increasingly use video lectures. The youtubetranscript.com API is a single point of failure with no SLA. Audio files have no proper STT pipeline.

---

### M8. WebScraper is Too Minimal for Modern Websites

**Severity:** MAJOR

**Problem:** `WebScraper` (49 lines) does an HTTP GET and strips HTML tags. Many educational websites require JavaScript rendering, login sessions, or cookie handling. The "website link" ingestion is unreliable for most real educational URLs.

**Affected file:**
- `lib/features/ingestion/services/web_scraper.dart` (49 lines) — minimal HTTP GET + HTML strip

**Acceptance Criteria:**
- [ ] Headless browser API (e.g., `flutter_webview`) for JS-rendered content
- [ ] Cookie/session support for login-walled educational resources
- [ ] Respect robots.txt
- [ ] Configurable timeout in Settings

**Rationale:** Students frequently paste links to educational websites that use JavaScript to render content. The current approach returns empty or garbled text for most modern sites.

---

### M9. CrossFeatureIntegrator is Still Orphaned Dead Code

**Severity:** MAJOR (dead code)

**Problem:** `CrossFeatureIntegrator` (198 lines) provides a unified timeline across sessions, practice, focus, and ingestion. No screen consumes it. Dashboard uses `DashboardService` with its own aggregation.

**Affected files:**
- `lib/core/services/cross_feature_integrator.dart` (198 lines) — entirely dead code
- `lib/features/dashboard/services/dashboard_service.dart` — has own aggregation, doesn't use integrator

**Acceptance Criteria:**
- **Either:** DashboardService delegates to CrossFeatureIntegrator for timeline queries
- **Or:** Delete the file entirely

---

### M10. Only 2 Supported Locales — No French, German, Arabic, etc.

**Vision reference:** `agent_must_read.md:104`
**Severity:** MAJOR

**Problem:** Only `en` and `es` locales exist (`lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`). The `AppLocale` enum has exactly 2 values. Key global education markets (French, Arabic, German, Portuguese, Mandarin) are unsupported.

**Affected files:**
- `lib/l10n/app_en.arb` — English (existing)
- `lib/l10n/app_es.arb` — Spanish (existing)
- `lib/l10n/` — no other locale files
- `lib/core/config/locale_config.dart` — 2-value enum

**Acceptance Criteria:**
- [ ] Add `app_fr.arb` (French — high demand in Africa/Europe)
- [ ] Add `app_ar.arb` (Arabic — high demand in Middle East/North Africa)
- [ ] Add `app_de.arb` (German — European market)
- [ ] Add `app_pt_BR.arb` (Portuguese — Brazil market)
- [ ] LLM prompts respect the locale for lesson generation, mentor conversations, etc.

---

## MINOR — Code quality / UX friction / architectural debt

### m1. PersonalLearningPlanService is Too Large (1036 lines)

**Problem:** At 1036 lines, `PersonalLearningPlanService` is the largest service file in the codebase. It handles plan generation, goal tracking, milestone management, and schedule computation — all in one class.

**Affected file:** `lib/features/planner/services/personal_learning_plan_service.dart` (1036 lines)
**Fix:** Split into:
- `PlanGeneratorService` (plan creation from syllabus + goals)
- `GoalTrackerService` (goal progress, modifications, completion)
- `MilestoneManager` (milestone CRUD, timeline computation)
- Keep a thin `PersonalLearningPlanService` that delegates

---

### m2. Planner Providers is Too Large (689 lines)

**Problem:** `planner_providers.dart` at 689 lines defines all planner-related Riverpod providers in a single file.

**Affected file:** `lib/features/planner/providers/planner_providers.dart` (689 lines)
**Fix:** Split into:
- `plan_providers.dart` (plan progress, weekly progress, PendingAction providers)
- `syllabus_providers.dart` (syllabus, roadmap providers)
- `adherence_providers.dart` (adherence metrics, engagement nudge providers)

---

### m3. FocusTimerScreen is Too Large (1207 lines)

**Problem:** At 1207 lines, `FocusTimerScreen` mixes timer logic, practice hub UI, onboarding, analytics loading, subject picker, and inline practice orchestration.

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1207 lines)
**Fix:** Extract into composable widgets:
- `StudyHubWidget` — subject cards, due counts, session type picker
- `FocusTimerSetupWidget` — duration selection, start button
- `ActiveFocusSessionWidget` — timer display, practice overlay
- Keep `FocusTimerScreen` as a thin orchestrator

---

### m4. LessonAgentService Doesn't Use Existing LlmAgent Infrastructure

**Problem:** The `LlmAgent` + `AgentLoop` + `ToolRegistry` infrastructure exists in `lib/core/services/llm_agent/` but `LessonAgentService` ignores it — using raw `LlmService.chat()` calls directly.

**Affected file:** `lib/features/lessons/services/lesson_agent_service.dart` (302 lines)
**Fix:** Refactor to use `LlmAgent` with registered tools (`getStudentStats`, `getWeakTopics`, `searchQuestions`, `getSyllabusProgress`) and `LongTermMemory` context injection.

---

### m5. Wrong Answers in Inline Practice Silently Dropped

**Problem:** `InlinePracticeWidget` only calls `MasteryRecorder.recordAttempt()` for correct answers. Wrong answers are silently dropped — they never enter the spaced repetition or mastery system.

**Affected files:**
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` (321 lines) — no `recordAttempt()` for wrong answers
- `lib/features/focus_mode/services/focus_practice_service.dart` (84 lines) — same issue in service layer

**Fix:** Record ALL attempts (correct and incorrect) with appropriate `isCorrect` flag.

---

### m6. FocusSession Model is Dead Code

**Problem:** `FocusSession` model (77 lines) is defined but never instantiated by any production code path. It exists solely for `settings_screen.dart` data migration from old JSON blobs.

**Affected file:** `lib/features/focus_mode/data/models/focus_session_model.dart` (77 lines)
**Fix:** Either wire it into the post-session flow or delete it after migration support is no longer needed.

---

### m7. No Widget/Integration Tests for Critical User Flows

**Problem:** 398 test files exist, but nearly all are unit tests for services/repositories. No widget tests exist for: onboarding flow, lesson viewing, focus mode practice, tutor chat session.

**Fix:** Add widget tests for:
- Onboarding flow completes → subject selection screen renders
- Focus timer shows study hub with subjects → "Spaced Repetition" launches practice
- Tutor screen shows chat → voice bar toggle works → drawing canvas opens
- Lesson detail screen shows blocks → slide full-screen navigation works

---

### m8. Configuration System: Only Locale Config — No Environment Abstraction

**Problem:** `lib/core/config/` has only `locale_config.dart` (31 lines). No dev/staging/prod environment config beyond `BuildConfig` enum. API URL abstraction is in constants, not config models. No feature flags.

**Affected files:**
- `lib/core/config/` — only locale_config.dart
- `lib/core/constants/app_api_config.dart` — has `// TODO: implement runtime secret injection` comment

**Fix:** Implement environment-aware config (dev/staging/prod) with overridable API endpoints and feature flags.

---

## Execution Plan — Next Development Phase

### Priority Order:

| Priority | Item | Type | Effort | Dependencies |
|---|---|---|---|---|
| **P0** | **B1: Lessons** — agentify LessonAgentService, add rich slides, calendar scheduling, background prep | BLOCKER | 3-4 weeks | M3 (background tasks), m4 (agent tools for lessons) |
| **P0** | **B2: Focus mode** — fix practice selection, record wrong answers, post-session analytics | BLOCKER | 1-2 weeks | None (uses existing services) |
| **P1** | **M3: Background task runner** — WorkManager for persistent scheduling | MAJOR | 2 weeks | None |
| **P1** | **M4: Token budget/metering** — per-feature budgets, cost alerts | MAJOR | 1 week | None |
| **P2** | **M1: LLM planner advisor** — LLM involvement in plan generation | MAJOR | 1-2 weeks | m4 (agent tools for planner) |
| **P2** | **M2: Voice turn-taking** — VAD, review step, per-locale TTS | MAJOR | 1-2 weeks | None |
| **P2** | **M5: PDF extraction** — use `pdf` package for proper extraction | MAJOR | 3 days | None |
| **P2** | **M6: Local OCR** — ML Kit as primary, LLM as fallback | MAJOR | 3-5 days | None |
| **P2** | **M7: Proper STT** — Whisper API + YouTube Data API | MAJOR | 1-2 weeks | None |
| **P2** | **M8: WebScraper** — headless rendering, cookie support | MAJOR | 3-5 days | None |
| **P2** | **M10: Additional locales** — fr, ar, de, pt_BR | MAJOR | 2-3 days | None |
| **P3** | **M9: Delete/integrate CrossFeatureIntegrator** | MAJOR | 1 day | None |
| **P3** | **m1: Split PersonalLearningPlanService** | MINOR | 2 days | None |
| **P3** | **m2: Split planner providers** | MINOR | 1 day | None |
| **P3** | **m3: Split FocusTimerScreen** | MINOR | 2 days | B2 |
| **P3** | **m4: Refactor LessonAgentService to use LlmAgent** | MINOR | 2-3 days | B1 |
| **P3** | **m5: Record wrong answers in inline practice** | MINOR | 1 day | B2 |
| **P3** | **m6: Handle FocusSession dead code** | MINOR | 1 day | None |
| **P3** | **m7: Widget tests for critical flows** | MINOR | 3-5 days | B1, B2 |
| **P3** | **m8: Environment config abstraction** | MINOR | 2-3 days | None |

### Key Dependencies:
- B1 (Lessons) depends on M3 (background tasks) for idle prep and m4 (agent tools)
- B2 (Focus mode) is independent — can start immediately
- M3 (background tasks) unlocks proactive engagement vision
- All MAJOR extraction items (M5, M6, M7, M8) are independent of each other

### Beta-Tester Issue Closure:
When both beta-tester issues are resolved:
1. `issues/further_issues/open/lessons.md` → resolved (delete or move to `completed/`)
2. `issues/further_issues/open/focus_mode.md` → resolved (delete or move to `completed/`)
3. Mark closure in the moved files with resolution date

---

## Architectural Notes for Future Sprints

1. **Cloud sync**: All data is local Hive. No cross-device sync. Consider `supabase_flutter` or `firebase` for future multi-device.
2. **Batch extraction**: For a student uploading a 300-page textbook, page-level chunking with batch LLM processing is needed. Current per-file processing doesn't scale.
3. **Offline-first is good**: Local Hive + Ollama support is strong. But OpenRouter-dependent features (vision, embeddings) break offline.
4. **Multi-tenancy**: Single-student architecture. No parent/teacher dashboard, no class management. Consider for future.
