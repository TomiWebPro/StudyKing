# Future Functionality Planner — Vision vs Implementation Gap Analysis (v4)

**Generated:** 2026-05-20
**Source:** `agent_must_read.md` (product vision) vs codebase audit
**Input from beta testers:** `issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`
**Previous analysis:** `issues/completed/future_functionality_planner.md` (v3 — superseded)

---

## Progress Since v3 (Items Now Resolved)

| Item | Status | Evidence |
|------|--------|----------|
| B1: PlannerService.scheduleLesson() bare session | ✅ Fixed | Now triggers `LessonAgentService.generateLesson()` eagerly after creating session (planner_service.dart:381-403) |
| B2: Focus mode timer-first UX | ✅ Fixed | Default view is now study hub (`_studyMode = true`), timer is toggle-away option |
| B2: Post-lesson practice entry point | ✅ Fixed | `TutorScreen._showSummaryDialog()` has two buttons: focus timer (15 min) + practice mode (30 min, 20 Q) with subject/topic pre-selected |
| M1: LLM planner advisor | ✅ Fixed | `LlmPlannerAdvisorStrategy` (213 lines) exists, integrates via `PlannerAdvisorStrategy` interface called at lines 239-254 of `PersonalLearningPlanService` |
| m1: FocusTimerScreen timer-first | ✅ Fixed | Study hub is default view. Monolith line count (1374) still needs splitting. |
| m3: Planner providers split | ✅ Fixed | `plan_providers.dart`, `syllabus_providers.dart`, `adherence_providers.dart` are now separate files |
| m5: Audio recording + file upload stubs | ✅ Fixed | `AudioRecordingWidget` uses `record` package (134 lines with amplitude viz), `FileUploadWidget` uses `file_picker` (82 lines) |

**Still UNRESOLVED from v3:** B1 (rich slides, calendar scheduling, LessonAgentService agentification), M2 (voice VAD), M3 (persistent background tasks via workmanager), M4 (token budget enforcement), M5 (PDF extraction proper), M6 (local OCR), M7 (Whisper STT), M8 (web scraper), M9 (additional locales), m1 (FocusTimerScreen split), m2 (PersonalLearningPlanService split), m4 (LessonAgentService agent refactor), m6 (widget tests).

---

## BLOCKER — App crashes or user cannot proceed

### B1. Lessons Rich Content, Calendar Scheduling, and Agentification Still Incomplete

**Source:** Beta-tester `lessons.md` + vision audit (`agent_must_read.md:27-47`)
**Severity:** BLOCKER — core teaching loop is the #1 product value

**Problem:** Despite incremental fixes, three critical gaps remain:

1. **`LessonBlock` has no `richContent` field** — `lesson_block_model.dart` only has `String content`. No markdown, LaTeX, image references, or code blocks. `LessonBlockCard` renders everything as plain `Text()` widgets (e.g., `lesson_block_card.dart:76` renders `Text(widget.block.content)` for slides, quizzes, exercises, etc.). The `grep` for `richContent` across the entire codebase returns zero matches.

2. **`CalendarViewWidget` shows roadmap milestones, not lesson time blocks** — `calendar_view_widget.dart:152-160` renders milestone dots from `widget.roadmaps` -> `milestones` -> `deadline`. No individual session/lesson time slots, no hourly blocks, no tap-to-launch-lesson. The beta tester explicitly wants Preply-style calendar with lesson time blocks.

3. **`LessonAgentService` still uses raw `LlmService.chat()`** — `lesson_agent_service.dart:80,276` calls `_llmService.chat()` directly. The `LlmAgent`/`AgentLoop`/`ToolRegistry` infrastructure (which exists at `lib/core/services/llm_agent/` and IS used by `MentorService` and `TutorService` for background tasks) is completely ignored. No tools, no agent memory, no structured output parsing. Note: `GenerateLessonBlocksTool` wraps `LessonAgentService` to make it available as an agent tool, but `LessonAgentService` itself is not agentic.

**Affected files:**
- `lib/features/lessons/data/models/lesson_block_model.dart` — no `richContent` field
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — plain `Text()` rendering, no markdown/LaTeX
- `lib/features/lessons/services/lesson_agent_service.dart` — raw `LlmService.chat()`, no `LlmAgent`/tools/memory
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` — shows roadmaps/milestones, not lesson slots
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — creates Session + triggers LLM prep but no rich lesson plan scheduling UX
- `lib/features/teaching/presentation/tutor_screen.dart` — summary dialog practice buttons exist but navigate to focus mode timer, not lesson-block-based practice
- `lib/core/services/llm_agent/idle_executor.dart` — no lesson-prep enqueueing path

**Acceptance Criteria:**
- [ ] `LessonBlock` gains `richContent` field (Map or JSON string supporting markdown, LaTeX `$$...$$`, image URLs, code blocks with language tags)
- [ ] `LessonBlockCard` renders rich content: `flutter_markdown` for markdown, `flutter_math_fork` for LaTeX, cached network images, syntax-highlighted code blocks
- [ ] Full-screen slide mode renders rich content, not plain text
- [ ] `CalendarViewWidget` shows scheduled lesson time slots (topic + duration + prep status) with tap-to-view and tap-to-launch
- [ ] `LessonAgentService` refactored to use `LlmAgent` with agent loop + registered tools + memory context injection
- [ ] Lesson-prep agent tools registered: `getStudentStats`, `getWeakTopics`, `searchQuestions`, `getSyllabusProgress`, `createLessonPlan`
- [ ] `IdleExecutor` enqueues lesson-prep tasks when a session is scheduled in advance
- [ ] `PlannerService.scheduleLesson()` enqueues background lesson prep via `IdleExecutor` for future sessions, not just immediate generation

**Rationale:** The beta tester's language is unambiguous — "Current lesson is fucking useless." The teaching loop is the product's core value proposition. Rich content rendering and agent-driven lesson generation are table stakes. The agent infrastructure already exists; lessons simply don't use it.

---

### B2. Focus Mode UX Still Misaligned — Further Issues `focus_mode.md`

**Source:** Beta-tester `focus_mode.md` + vision audit (`agent_must_read.md:86-87`)
**Severity:** BLOCKER

**Problem:** While the study hub is now the default view and post-lesson practice navigation exists, the beta tester remains deeply unhappy:

1. **Beta tester explicitly says current focus mode is "fucking useless"** — they want it as a place to practice questions from different subjects after lessons. The current flow centers on a timer even if the study hub is default.

2. **`FocusTimerScreen` is still a 1374-line monolith** — mixes timer logic, practice hub, onboarding, analytics, subject picker, session state management. This makes targeted UX improvements risky.

3. **No "study without timer" mode** — practice always requires starting a session/timer. The beta tester wants to just browse and answer questions across subjects.

4. **Session type selector is not prominent UX** — the `_sessionType` is set via internal logic, not a visible card-row selector.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1374 lines) — monolith, timer-centric session model
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` (327 lines) — separate but UX flow still starts from timer/session paradigm

**Acceptance Criteria:**
- [ ] `FocusTimerScreen` split into: `StudyHubWidget` (subject cards with due question counts), `ActiveFocusSessionWidget` (timer + practice overlay), `PracticeExplorerWidget` (browse and answer without timer)
- [ ] "Free Practice" mode: browse and answer questions from selected subjects without starting a timer session
- [ ] Post-lesson practice navigates to `PracticeExplorerWidget` with lesson's subject+topic pre-loaded, not timer
- [ ] Session type selector is a visible card row (Spaced Repetition / Weak Area Attack / Quick Practice / Free Practice), not a hidden enum
- [ ] Remove empty catch `(_) {}` blocks in `audio_recording_widget.dart:61,76` and `file_upload_widget.dart:50`

**Rationale:** The beta tester validated the timer flow as not what they want. The infrastructure (SR service, mastery recorder, practice service) is solid — the UX flow needs redesign to put practice first and timer as optional overlay.

---

## MAJOR — Feature is broken, misleading, or contradicts the vision

### M1. Planner is Still Predominantly Deterministic — LLM Advisor is Optional Bolt-On

**Vision reference:** `agent_must_read.md:73-85`
**Severity:** MAJOR

**Problem:** `LlmPlannerAdvisorStrategy` (213 lines) exists and is called from `PersonalLearningPlanService` (lines 239-254), but it is an **optional** plugin. The core 1102-line `PersonalLearningPlanService` still uses purely rule-based algorithms: round-robin topic distribution, hardcoded priority scores, deterministic daily plan generation. The LLM advisor produces metadata only — it doesn't influence the plan structure or scheduling decisions.

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart` (1102 lines, heuristic-only core)
- `lib/features/planner/services/llm_planner_advisor_strategy.dart` (213 lines, optional bolt-on, not integrated into decision logic)

**Acceptance Criteria:**
- [ ] LLM advisor is consulted during plan generation and its recommendations (workloadEstimate, pathwaySuggestion) actually influence dailyPlan distribution
- [ ] Plan adaptation uses LLM advisor to understand *why* student is falling behind (overwhelmed vs busy vs bored) and suggests specific schedule adjustments
- [ ] LLM advisor output is stored as structured `PlanAdvisorSuggestionModel` with traceable audit trail
- [ ] `PersonalLearningPlanService` split into `PlanGeneratorService`, `GoalTrackerService`, `MilestoneManager` (reduces from 1102 to ~400 lines per file)

---

### M2. Voice VAD, Review Step, and Interrupt-and-Resume Still Missing

**Vision reference:** `agent_must_read.md:16-22` (voice interaction, natural conversation)
**Severity:** MAJOR

**Problem:** `VoiceService` (236 lines) has improved locale support for both STT and TTS, but still lacks:
- No energy-threshold-based VAD — uses `speech_to_text` built-in `pauseFor` timeout
- No user review step for transcriptions before submission
- No interrupt-and-resume UX when TTS plays and user speaks (mutual exclusion is enforced by blocking, not duxing)
- No per-locale TTS voice selection (uses default system voice per language)

**Affected files:**
- `lib/core/services/voice_service.dart` — no VAD params, no review step, no interrupt-and-resume
- `lib/features/teaching/presentation/widgets/voice_bar.dart` — timer-based review overlay

**Acceptance Criteria:**
- [ ] Voice button states: idle → listening (energy wave animation) → processing → done/review
- [ ] Transcription shown in editable text field before submission
- [ ] Silence timeout configurable (default 2s); alternative: manual stop button
- [ ] Per-locale TTS voice mapping (locale → flutter_tts voice name/identifier)
- [ ] TTS pauses when user speaks; microphone stays active during playback for natural interruption
- [ ] Consistent voice UX across Tutor, Mentor, and Practice screens

---

### M3. No Persistent Background Task Runner

**Vision reference:** `agent_must_read.md:98` (proactive engagement), line 102 (task manager)
**Severity:** MAJOR

**Problem:** `IdleExecutor` (109 lines) runs only while app is foreground (Dart `Timer.periodic`). `EngagementScheduler` uses a Dart `Timer` + one-shot `Timer`. No `flutter_workmanager` dependency exists in `pubspec.yaml`. Notifications use `periodicallyShow` not `zonedSchedule` — less precise scheduling that doesn't survive app restart.

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart` — foreground-only Dart Timer
- `lib/core/services/engagement_scheduler.dart` — Dart Timer, not persistent
- `lib/core/services/notification_service.dart` — uses `periodicallyShow` not `zonedSchedule` (line 190)
- `pubspec.yaml` — no `workmanager` dependency

**Acceptance Criteria:**
- [ ] `flutter_workmanager` integrated for background task scheduling
- [ ] Background tasks: lesson prep (upcoming slots), nudge generation (daily), plan adherence check (periodic), overdue session auto-finalization
- [ ] `EngagementScheduler` uses workmanager periodic task instead of Dart Timer
- [ ] Notifications use `zonedSchedule` for precise scheduling that survives app restart
- [ ] Background tasks respect battery/data constraints; cancellable from Settings

---

### M4. Token Usage Tracked but No Budget Enforcement

**Vision reference:** `agent_must_read.md:102`
**Severity:** MAJOR

**Problem:** `LlmUsageMeter` (142 lines) records everything but enforces nothing. No pre-flight check, no per-feature budgets, no daily caps, no user-facing cost controls. Students using their own API keys cannot cap spending.

**Affected files:**
- `lib/core/services/llm_usage_meter.dart` — `recordUsage()` has no checks, no budget concept
- `lib/core/services/llm_task_manager.dart` — no reference to `LlmUsageMeter`, no budget checks
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — no budget UI
- `lib/features/settings/presentation/settings_screen.dart` — shows usage but no budget controls
- `lib/core/constants/token_pricing_config.dart` — hardcoded pricing, no per-model config

**Acceptance Criteria:**
- [ ] `TokenBudgetService` tracks rolling usage per-day/per-feature with configurable hard limits
- [ ] Settings screen has per-feature token budget controls with on/off toggle and numeric limit
- [ ] Notifications/alerts at 80%/100% of daily budget
- [ ] `LlmService` rejects calls that would exceed budget with clear `Result.failure('Budget exceeded for feature: ...')`
- [ ] Per-model pricing configurable (map of model ID → cost per 1K tokens)
- [ ] System prompt tokens included in input token count
- [ ] User-facing cost display with estimated monthly cost based on current usage patterns

---

### M5. PDF Extraction Still Regex-Based

**Severity:** MAJOR

**Problem:** `PdfExtractor` (152 lines) still uses `String.fromCharCodes(bytes)` + regex extraction from raw PDF bytes. The `pdf: ^3.10.4` package exists in `pubspec.yaml` but is used for PDF **generation**, not extraction. Fails on scanned PDFs, compressed streams, non-standard encoding.

**Affected files:**
- `lib/core/data/extraction/pdf_extractor.dart` (lines 82-126 regex strategy, 128-143 raw strategy)
- `lib/features/ingestion/services/document_extractor.dart` — delegates to PdfExtractor

**Acceptance Criteria:**
- [ ] Use `pdf` package's `PdfDocument.openBytes()` for proper text extraction with page structure
- [ ] Page structure preserved (headings, order, paragraph grouping)
- [ ] For scanned PDFs: OCR fallback (ML Kit)
- [ ] Extraction method string reflects whether it used text extraction or OCR
- [ ] Unit tests for plain PDF, compressed PDF, and scanned PDF (image-based)

---

### M6. OCR is LLM-Only — No Local Engine

**Severity:** MAJOR

**Problem:** `OcrExtractor` (185 lines) base64-encodes images → sends to LLM with vision prompt. No `google_mlkit_text_recognition` or similar dependency. Every image = $0.01-0.05 LLM call + 3-10s latency.

**Affected files:**
- `lib/core/data/extraction/ocr_extractor.dart` — LLM-only extraction
- `pubspec.yaml` — no `google_mlkit_text_recognition`

**Acceptance Criteria:**
- [ ] Primary OCR: `google_mlkit_text_recognition` (free, on-device, fast, <100ms)
- [ ] LLM vision OCR as fallback when ML Kit confidence is low or text is complex (diagrams, equations, handwritten text)
- [ ] Per-image confidence scores stored with extraction results
- [ ] Document scanning mode: multiple images → merge results

---

### M7. No Whisper API for Audio/Video Transcription

**Vision reference:** `agent_must_read.md:11` (video/audio ingestion)
**Severity:** MAJOR

**Problem:** `TranscriptionExtractor` (358 lines) uses:
- `youtubetranscript.com` third-party API (no SLA, rate-limited, unofficial)
- LLM service for audio/video files (slow, expensive, no language detection)
- No Whisper API (OpenAI or OpenRouter) integration
- No FFMpeg for media inspection or frame extraction

**Affected files:**
- `lib/core/data/extraction/transcription_extractor.dart` — third-party API + LLM only
- `lib/features/ingestion/services/document_extractor.dart` — delegates to TranscriptionExtractor
- `lib/features/ingestion/presentation/upload_screen.dart` — no processing progress for media
- `lib/core/config/app_api_config.dart` — youtubetranscript.com hardcoded (lines 66-67)

**Acceptance Criteria:**
- [ ] Whisper API (OpenRouter or direct OpenAI) as primary STT for uploaded audio/video files
- [ ] YouTube Data API v3 captions endpoint as primary YouTube STT (youtubetranscript.com as fallback)
- [ ] FFMpeg for media inspection (duration, codec, sample rate) and frame extraction
- [ ] Processing progress shown: uploading → transcribing → generating content → complete
- [ ] YouTube API key configurable in Settings > AI Configuration
- [ ] Language detection from audio for multi-language content

---

### M8. WebScraper Too Minimal for Modern Educational Sites

**Severity:** MAJOR

**Problem:** `WebScraper` (49 lines) does HTTP GET + regex HTML stripping. Most educational sites require JS rendering, login sessions, or cookie handling. The "website link" ingestion is unreliable for all but the simplest static pages.

**Affected file:**
- `lib/features/ingestion/services/web_scraper.dart` (49 lines)

**Acceptance Criteria:**
- [ ] Headless browser integration (e.g., `flutter_inappwebview` or server-side headless Chrome) for JS-rendered content
- [ ] Cookie/session support for login-walled educational resources
- [ ] Respect robots.txt
- [ ] Configurable timeout in Settings
- [ ] Content extraction quality scoring (full text vs partial vs failed)

---

### M9. Only 2 Supported Locales

**Vision reference:** `agent_must_read.md:104`
**Severity:** MAJOR

**Problem:** Only `app_en.arb` and `app_es.arb` exist. Key global education markets unsupported.

**Affected files:**
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` — only 2 locales
- Generated files in `lib/l10n/generated/` — only en/es

**Acceptance Criteria:**
- [ ] Add `app_fr.arb` (French — key education market in Africa, Europe, Canada)
- [ ] Add `app_ar.arb` (Arabic — MENA region)
- [ ] Add `app_de.arb` (German — Germany, Austria)
- [ ] Add `app_pt_BR.arb` (Portuguese — Brazil, largest education market in Latin America)
- [ ] Add `app_zh.arb` or `app_zh_CN.arb` (Mandarin — China)
- [ ] LLM prompts respect the locale for lesson generation, mentor conversations (locale already in system prompts for some features)

---

### M10. Teaching Mode Post-Lesson Practice Integration Is Partial

**Vision reference:** `agent_must_read.md:38` ("assign exercises and homework during and after class")
**Severity:** MAJOR

**Problem:** Post-lesson practice buttons exist in `TutorScreen._showSummaryDialog()` (lines 570-632) but:
- Both buttons navigate to `FocusTimerScreen` with timer paradigm
- No way to practice lesson-specific questions in a lesson-block-review flow
- Lesson topics are NOT marked for priority review in spaced repetition after lesson
- Exercises generated during conversation are not persisted as practice material for later review

**Affected files:**
- `lib/features/teaching/presentation/tutor_screen.dart` — practice buttons navigate to focus timer, not practice hub
- `lib/features/teaching/services/tutor_service.dart` — `endLesson()` doesn't mark topics for priority review
- `lib/features/teaching/services/conversation_manager.dart` — exercise phase generates exercises but no post-session practice push

**Acceptance Criteria:**
- [ ] Post-lesson summary dialog shows "Practice these topics" button that navigates to Focus Mode practice hub (not timer) with lesson's subject+topic pre-selected
- [ ] Lesson topics are marked for priority review in spaced repetition system
- [ ] Exercises generated by ConversationManager are persisted to the question bank for later practice
- [ ] Practice mode defaults to "Weak Area Attack" or "Spaced Repetition" for the lesson's topic
- [ ] "Practice lesson blocks" button replays lesson blocks in quiz/exercise mode

---

## MINOR — Code quality / UX friction / architectural debt

### m1. FocusTimerScreen is Still a Monolith (1374 lines)

**Problem:** At 1374 lines, `FocusTimerScreen` mixes timer logic, practice hub UI, onboarding, analytics loading, subject picker, session state orchestration, inline practice, and routing — all in one stateful widget.

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1374 lines)
**Fix:** Extract into composable widgets per B2 requirements:
- `StudyHubWidget` — subject cards, due counts, session type picker
- `FocusTimerSetupWidget` — duration selection, start button
- `ActiveFocusSessionWidget` — timer display, practice overlay
- `PracticeExplorerWidget` — free practice without timer
- Keep `FocusTimerScreen` as thin orchestrator with tab-based navigation

---

### m2. PersonalLearningPlanService is Too Large (1102 lines)

**Problem:** At 1102 lines, this service handles plan generation, goal tracking, milestone management, schedule computation, and advisor strategy calling — all in one file.

**Affected file:** `lib/features/planner/services/personal_learning_plan_service.dart` (1102 lines)
**Fix:** Split per M1 acceptance criteria:
- `PlanGeneratorService` (plan creation from syllabus + goals)
- `GoalTrackerService` (goal progress, modifications, completion)
- `MilestoneManager` (milestone CRUD, timeline computation)
- Thin `PersonalLearningPlanService` that delegates

---

### m3. LessonAgentService Still Doesn't Use LlmAgent Infrastructure

**Affected file:** `lib/features/lessons/services/lesson_agent_service.dart` (302 lines)
**Note:** Same root cause as B1. `LlmAgent`+`AgentLoop`+`ToolRegistry` exists and is used by `MentorService` and `TutorService`. `LessonAgentService` is the last holdout.
**Fix:** Refactor to use `LlmAgent` with registered tools and `AgentMemoryStore` context injection. This directly enables background lesson preparation, student-aware lesson generation, and tool-using lesson agents.

---

### m4. Empty Catch Blocks in Audio and File Upload Widgets

**Affected files:**
- `lib/features/questions/presentation/widgets/audio_recording_widget.dart` — empty `catch (_) {}` on lines 61 and 76
- `lib/features/questions/presentation/widgets/file_upload_widget.dart` — empty `catch (_) {}` on line 50

**Fix:** Log errors using the class's Logger instance and optionally show a user-facing error message via SnackBar or callback.

---

### m5. No Widget/Integration Tests for Critical New Flows

**Problem:** 400+ test files exist, but several critical flows lack widget tests:
- Lesson scheduling flow (booking → calendar displays → tutor launch with pre-generated lesson)
- Focus mode practice hub navigation and session type selection
- Tutor screen summary dialog practice button interaction
- Post-lesson practice with pre-selected subject/topic
- Voice input flow across screens

**Fix:** Add widget tests per AGENTS.md pattern. Priority flows match B1 and B2 acceptance criteria.

---

## Execution Plan — Next Development Phase

### Priority Order (Top-Down):

| Priority | Item | Type | Effort | Dependencies |
|---|---|---|---|---|
| **P0** | **B2: Focus mode free practice + monolith split** | BLOCKER | 2 weeks | None |
| **P0** | **Further Issues: focus_mode.md** — address beta tester complaints | BLOCKER | See B2 | B2 |
| **P0** | **B1: Lesson rich content rendering** (markdown, LaTeX, images) | BLOCKER | 1 week | None |
| **P0** | **B1: Calendar lesson time slots** (not roadmap milestones) | BLOCKER | 1 week | None |
| **P0** | **B1: LessonAgentService agentification** (use LlmAgent) | BLOCKER | 1 week | None |
| **P0** | **Further Issues: lessons.md** — address beta tester lesson complaints | BLOCKER | See B1 | B1 |
| **P1** | **M3: Background task runner** (WorkManager + zonedSchedule) | MAJOR | 2 weeks | None |
| **P1** | **M10: Post-lesson practice full integration** (SR priority marking, exercise persistence) | MAJOR | 1 week | B2 |
| **P1** | **M4: Token budget enforcement** (per-feature budgets, cost alerts) | MAJOR | 1 week | None |
| **P2** | **M1: LLM advisor integration into plan decisions** (not just metadata) | MAJOR | 1 week | m2 (split) |
| **P2** | **M2: Voice VAD + review step + interrupt** | MAJOR | 1-2 weeks | None |
| **P2** | **M5: PDF extraction with pdf package** | MAJOR | 3 days | None |
| **P2** | **M6: Local OCR with ML Kit** | MAJOR | 3-5 days | None |
| **P2** | **M7: Whisper API STT + YouTube Data API** | MAJOR | 1-2 weeks | None |
| **P2** | **M8: Headless web scraper** | MAJOR | 3-5 days | None |
| **P2** | **M9: Additional locales (fr, ar, de, pt_BR, zh)** | MAJOR | 3-5 days | None |
| **P3** | **m1: Split FocusTimerScreen** | MINOR | 2 days | B2 |
| **P3** | **m2: Split PersonalLearningPlanService** | MINOR | 2 days | M1 |
| **P3** | **m3: LessonAgentService agent refactor** | MINOR | 2-3 days | B1 |
| **P3** | **m4: Fix empty catch blocks** | MINOR | 1 hour | None |
| **P3** | **m5: Widget tests for critical flows** | MINOR | 3-5 days | B1, B2 |

### Key Dependencies:
- B1 items can be parallelized (richContent rendering is independent from CalendarView, which is independent from LessonAgentService agentification)
- B2 is independent — can start immediately
- M10 depends on B2 (practice hub UX)
- M1 depends on m2 (PersonalLearningPlanService split)
- M3 unlocks proactive engagement features (scheduled prep, notification scheduling)
- All MAJOR extraction items (M5, M6, M7, M8) are independent of each other
- M4 is critical for user trust (API key cost control)

### Further Issues Closure:
When both beta-tester issues are resolved:
1. `issues/further_issues/open/lessons.md` → delete from `open/`, acknowledge in this file
2. `issues/further_issues/open/focus_mode.md` → delete from `open/`, acknowledge in this file
3. Update this section to record resolution date and commit hash

---

## Architectural Notes for Future Sprints

1. **LLM agent infrastructure is solid but underutilized** — `LlmAgent` + `AgentLoop` + `ToolRegistry` + `AgentMemoryStore` + `IdleExecutor` is a well-designed ReAct agent framework. Only `MentorService` uses it for full agentic chat. `LessonAgentService` is the major gap. `TutorService` uses it only for background tasks.

2. **6 registered tools** (schedule_lesson, search_questions, get_student_stats, generate_lesson_blocks, create_plan, get_weak_topics) — all under `lib/features/mentor/services/tools/`. Only the mentor's agent uses them. Consider whether tools should be shared across agents (mentor, tutor, lesson prep).

3. **No cloud sync** — all data is local Hive. `supabase_flutter` or similar would be needed for multi-device support.

4. **Batch processing needed** — for students uploading 300-page PDFs, current per-file processing doesn't scale. Page-level chunking with batch LLM processing needed.

5. **Offline-first is good** — local Hive + Ollama support is strong. But OpenRouter-dependent features (vision, embeddings, Whisper) break offline.

6. **Multi-language prompt support exists but is inconsistent** — some services pass `localeName` to system prompts, others hardcode English. An audit of all LLM-facing prompts for locale awareness is needed when adding new locales.

7. **Token budget is P1 for user trust** — students using their own API keys will abandon the app if costs spiral without controls. This directly affects retention.

8. **Exercise persistence gap** — `ConversationManager` generates exercises during tutoring but they are not saved to the question bank. This means lesson-generated practice material is lost after the session.
