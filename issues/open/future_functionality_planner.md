# Future Functionality Planner — Vision Gap Analysis & Next Phase Roadmap

**Generated:** 2026-05-18
**Analyzed Scope:** `lib/` (315 files), `test/` (331 files), `agent_must_read.md` (product vision)
**Sources:** Product vision document, codebase deep audit, user beta feedback (`issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`)

---

## Executive Summary

The codebase is surprisingly mature — most features have full implementations across all layers (model → repository → service → provider → UI). However, there are critical gaps between the product vision and what's actually delivered, exacerbated by user beta feedback identifying two features as "fucking useless." This document identifies the gaps, prioritizes user-reported issues first, and proposes a concrete next-phase plan.

---

## PHASE 0: FIX USER-REPORTED BETA ISSUES (HIGHEST PRIORITY)

These are direct complaints from beta testers recorded in `issues/further_issues/open/`. They must be resolved before any new feature work, and the markdown files should be moved to `issues/further_issues/completed/` upon resolution.

---

### BETA-B1: Focus Mode — Make It an Actual Cross-Subject Practice Hub (BLOCKER)

**Source:** `issues/further_issues/open/focus_mode.md`
> "The current focus mode is fucking useless, I wanted it to be a place where student can practice questions from different subjects after lessons."

**Root Cause Analysis:**
The focus mode is a Pomodoro timer with a "Practice Hub" toggle that shows subjects and due counts (`focus_timer_screen.dart:465-570`). It delegates to `PracticeSessionScreen` via `Navigator.pushNamed` but passes the **same broken arguments** that the main practice screen uses — subject + question count only, discarding readiness scoring and SM-2 filtering (see `dry_run_usability_validator.md` B2, B3). The result: the "Practice Hub" is a thin wrapper around the practice system that inherits all its bugs.

**Current Architecture:**
```
FocusTimerScreen._buildStudyHubView()
  ├── _startQuickPractice() → PracticeSessionScreen (subject only, no ordering)
  ├── _startSpacedRepetition() → PracticeSessionScreen (count only, B3 bug)
  └── _startWeakAreasPractice() → PracticeSessionScreen (topic IDs discarded, B2 bug)
```

**What "Fixed" Looks Like (Acceptance Criteria):**
- [ ] Focus mode's default view (when not running a timer) is a real **cross-subject practice aggregation dashboard**, showing:
  - Due reviews across ALL subjects (merged SM-2 queue)
  - Weak questions across ALL topics (merged at-risk question pool)
  - Recent mistakes across ALL subjects (merged mistake review)
  - Quick-practice entry for each subject with accurate due counts
- [ ] The "Practice Hub" tab must pass **pre-ordered question lists** (from `ReadinessScorer`) to `PracticeSessionScreen` — not just subject + count
- [ ] A "Focus Practice" mode exists: student sets a timer, then is fed questions from across all subjects in urgency order while the timer counts down. Session auto-ends when timer expires (submits current question as-is).
- [ ] The Pomodoro timer remains available as a sub-mode (not the primary feature)
- [ ] Wire `DifficultyAdapter` (which is currently dead code — see `difficulty_adapter.dart`) into the focus practice flow so question difficulty adapts in real-time during a focus session
- [ ] When `lessons` branch completes (see BETA-B2), focus mode shows a "Post-Lesson Practice" section: questions from the most recently completed lesson's topic, adjacent weak topics, and spaced repetition items

**Affected Files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — entire `_buildStudyHubView` needs redesign
- `lib/features/focus_mode/providers/focus_mode_providers.dart` — needs cross-subject aggregation providers
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — must accept pre-ordered question lists
- `lib/features/practice/presentation/screens/practice_screen.dart` — focus mode specific entry points
- `lib/features/practice/services/difficulty_adapter.dart` — wire into session flow
- `lib/features/focus_mode/presentation/widgets/session_summary_card.dart` — update for focus-practice hybrid

---

### BETA-B2: Lessons — Make LLM-Driven Agent-Based Teaching with Presentations (BLOCKER)

**Source:** `issues/further_issues/open/lessons.md`
> "Make the lessons like preply... seperate scheduling lesson time and lesson plan. Lesson must have presentation and llm explanations. Current lesson is fucking useless."
> "Lessons are prepared from llm agents, llm is not just a fucking chatbot."
> "Agents must have long term memory not each new session is fresh now and toolless."

**Root Cause Analysis:**
The `lessons/` feature is a static content viewer. `LessonBlockCard` renders ALL block types (text, example, exercise, quiz, slide, summary) as identical text cards in a `ListView` (`lesson_detail_screen.dart:166-175`). The `LessonBlockType.slide` exists in the data model but produces the same `Text(block.content)` widget as every other type (see `lesson_block_card.dart:29`). The LLM is not integrated into the lesson experience — the "AI Tutor" button opens a separate `TutorScreen` that bears no relationship to the lesson content.

Critically, lessons are never **prepared** by LLM agents. They are manually created blocks stored in Hive. The vision says "dynamically generate the lesson plans and goals beforehand" — this doesn't happen.

Long-term memory is non-existent: `ConversationMemory` holds 50 turns but each tutor session starts with zero context from previous sessions. The mentor has `ConversationRepository` for persistence but never seeds new conversations with historical data.

**Scheduling vs Content Separation:**
Currently, scheduling lives in `planner/` (calendar, roadmaps, lesson bookings) and content lives in `lessons/` (static blocks). The vision demands these be separate: "separate scheduling lesson time and lesson plan." A scheduled lesson slot should trigger LLM agent preparation of materials, not just show pre-existing blocks.

**What "Fixed" Looks Like (Acceptance Criteria):**

**Lesson Content & Presentation:**
- [ ] `LessonBlockType.slide` must render as a full-screen/deck-style presentation — `PageView`, decorative background, heading overlay, bullet-point formatting, optional images
- [ ] `LessonBlockCard` must be context-aware: slides get carousel UI, exercises get interactive widgets (inline answer input + check), quizzes get radio button selection
- [ ] The lesson detail screen must show a "lesson agenda" (sections with time estimates) before the student starts, generated by the LLM
- [ ] When opening a lesson, the system calls the LLM to **enrich** the static content: generate explanations, examples tailored to the student's weak areas, follow-up questions
- [ ] An "LLM Explain This" button on every block calls the tutor with the block content as context

**LLM Agent Lesson Preparation:**
- [ ] Create a new `LessonAgentService` (or extend `TutorService`) that:
  - Takes a syllabus topic + student mastery data → generates a structured `LessonPlan` with sections, time estimates, exercises
  - Persists the `LessonPlan` as `LessonBlock` entries in the lesson repository
  - Is callable from the scheduler: when a lesson is scheduled, the agent pre-generates materials
- [ ] The lesson list screen shows which lessons have pre-generated materials and which are pending generation
- [ ] Background generation shows progress in the `LlmTaskManager` screen

**Long-Term Agent Memory:**
- [ ] `ConversationMemory` must support session-level summarization: when a tutor session ends, generate a concise summary (`tutorNotes` already exists on `Session.tutorMetadata`) and store it in the mentor's conversation history
- [ ] When starting a new lesson on a topic the student has studied before, seed the conversation with:
  - Previous session summary
  - Mastery state for that topic
  - Common mistakes from `MistakeReviewService`
  - Last N questions attempted with correctness
- [ ] The mentor chat must seed from historical conversation summaries, not start blank each time

**Scheduling Integration:**
- [ ] `PlannerService` must provide a `getUpcomingLessonSlots()` that returns scheduled slots without content
- [ ] A new screen/tab in planner: "Lesson Prep" shows upcoming slots, their preparation status (pending/generating/ready), and allows manual trigger of agent preparation
- [ ] When a lesson slot's start time approaches (< 15 min), the system must ensure materials are generated
- [ ] The Calendar View (`calendar_view_widget.dart`) needs lesson slots time-slot visualization (like Preply/Google Calendar)

**Affected Files:**
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — full rewrite for type-specific rendering
- `lib/features/lessons/presentation/lesson_detail_screen.dart` — add agenda view, LLM enrichment, slide carousel
- `lib/features/lessons/presentation/lesson_list_screen.dart` — show preparation status
- `lib/features/lessons/services/lesson_service.dart` — add LLM preparation methods
- `lib/features/lessons/providers/lesson_providers.dart` — new providers for lesson agent
- `lib/features/teaching/services/conversation_manager.dart` — seed from historical context
- `lib/features/teaching/services/tutor_service.dart` — add `generateLessonPlan` with persistence
- `lib/features/teaching/services/conversation_memory.dart` (in core) — add session summarization
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` — time-slot lesson visualization
- `lib/features/planner/services/planner_service.dart` — separation of scheduling from content
- `lib/core/services/llm_task_manager.dart` — background preparation task support
- `lib/features/mentor/services/mentor_service.dart` — seed conversations from history

---

## PHASE 1: VISION GAPS — ZERO-IMPLEMENTATION FEATURES (HIGH IMPACT)

---

### VG-1: Proactive Background Notifications & Engagement (BLOCKER)

**Vision Statement:**
> "The system should proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement."

**Current State:**
- `NotificationService` exists with 8 channels and all nudge types (overwork, revision, plan adjustment, lesson reminders, low mastery, badges)
- `EngagementScheduler` runs daily checks and lesson reminders BUT **only in-process via `Timer`**
- There is NO `workmanager`, `flutter_background_service`, or any background isolate — if the app is killed, zero notifications fire
- The mentor's `checkWellbeingAndGenerateNudges()` creates in-app nudges (chat messages) but never calls `NotificationService.showNotification()`
- `EngagementScheduler.init()` requires explicit calling and is not wired into app startup in `main.dart`

**Impact:**
Users who close the app never receive: daily study reminders, upcoming lesson alerts, overwork warnings, revision nudges, plan adjustment suggestions, or low-mastery warnings. The entire proactive engagement system is invisible to users who don't keep the app open.

**Acceptance Criteria:**
- [ ] Add `workmanager` or `flutter_background_service` to `pubspec.yaml` and register a background callback that initializes `EngagementScheduler`
- [ ] Wire `EngagementScheduler.init()` into `main.dart` app initialization (not just when user opens specific screens)
- [ ] Modify `MentorService.checkWellbeingAndGenerateNudges()` to also call `NotificationService.showNotification()` for high-severity nudges (not just in-app chat)
- [ ] Daily reminder notifications work even when the app has been killed for 24+ hours
- [ ] Lesson reminder notifications fire 15-30 minutes before scheduled lessons regardless of app state
- [ ] Add notification tap handling: tapping a notification navigates to the relevant screen (mentor for nudge, lesson for lesson reminder, practice for revision)
- [ ] Settings screen already has toggle controls for all 8 notification channels — verify they work with the background service

**Affected Files:**
- `pubspec.yaml` — add `workmanager` dependency
- `lib/main.dart` — register background callback, wire `EngagementScheduler.init()`
- `lib/core/services/engagement_scheduler.dart` — ensure thread-safe for background isolate
- `lib/features/mentor/services/mentor_service.dart` — add platform notification calls
- `lib/core/services/notification_service.dart` — add notification tap routing

---

### VG-2: Video/Audio Content Ingestion — Real Processing Pipeline (MAJOR)

**Vision Statement:**
> "Students should be able to upload large amounts of study materials such as textbooks, PDFs, notes, question banks, syllabi, online video link, video/audio, online website link, screenshots, etc. The system should intelligently process, organize, classify, validate, and integrate this material."

**Current State:**
- **Images:** OCR processing via `OcrExtractor` — works
- **PDF:** Full extraction via `PdfExtractor` — works
- **Documents:** `.txt`, `.md`, `.docx`, `.epub` via `DocumentExtractor` — works
- **Web pages:** HTML stripping via `WebScraper` — works (no JS rendering)
- **Video:** `_extractVideo()` at `document_extractor.dart:194-226` falls through to `TranscriptionExtractor` for YouTube, but for local files it just stores the URL. No actual video download/transcription pipeline.
- **Audio:** `_extractAudio()` at `document_extractor.dart:228-253` similarly falls back to URL storage.
- **No duplicate detection:** Uploading the same content twice creates two `Source` entries.
- **Question generation** after ingestion uses LLM but the question quality validation is minimal.

**Acceptance Criteria:**
- [ ] Video files (mp4, webm, etc.) uploaded via file picker are: (1) optionally downloaded to app storage, (2) audio track extracted, (3) transcribed via Whisper API or local STT, (4) text stored as `Source.content` with chunks
- [ ] Audio files (mp3, wav, m4a, ogg) are directly transcribed via STT pipeline
- [ ] YouTube URLs trigger actual transcript download (youtube_transcript_api or similar) — not just URL storage
- [ ] All transcriptions show progress in the `UploadScreen` processing progress bar
- [ ] Failed transcriptions show clear error messages (not silent fallback to URL storage)
- [ ] Add a `SourceHash` field for duplicate detection: SHA-256 of content + source type. On upload, check for existing hash and show "Already imported on [date]" dialog
- [ ] Question validation after generation: the LLM's generated questions should be validated for:
  - MCQ: must have exactly 1 correct answer among ≥3 options
  - Typed: must have a non-empty answer + explanation
  - No duplicate questions (same text as existing)
- [ ] Web scraping must handle JavaScript-rendered content (use `webview_flutter` for JS evaluation, or delegate to a headless browser service)

**Affected Files:**
- `lib/features/ingestion/services/document_extractor.dart` — video/audio extraction rewrite
- `lib/core/data/extraction/transcription_extractor.dart` — add actual transcription pipeline
- `lib/features/ingestion/services/content_pipeline.dart` — add duplicate detection, validation step
- `lib/features/ingestion/presentation/upload_screen.dart` — show per-step progress for transcription
- `lib/features/ingestion/data/models/source_model.dart` — add `sourceHash` field
- `lib/features/ingestion/services/web_scraper.dart` — JS rendering support

---

### VG-3: LLM Task Manager — Real-Time Monitoring & Control (MAJOR)

**Vision Statement:**
> "It should track LLM token usage for different tasks and have a task manager-like portal to view actively running inferencing tasks and for what purpose."

**Current State:**
- `LlmTaskManager` (`core/services/llm_task_manager.dart`) tracks tasks with status, model ID, timestamps, tokens used, estimated cost
- A presentation screen at `llm_tasks/presentation/llm_task_manager_screen.dart` shows the task list
- But: **no real-time streaming updates** — user must manually refresh
- **No retry button** for failed tasks
- **No "purpose" labeling** — tasks don't identify why they were created ("lesson generation", "question evaluation", "tutor response", etc.)
- **No per-feature usage breakdown** — the screen shows total tokens but not which feature consumed them
- Token counting uses `content.length ~/ 4` which is extremely rough

**Acceptance Criteria:**
- [ ] Add a `purpose` enum field to `LlmTask`: `lessonGeneration`, `questionGeneration`, `questionEvaluation`, `tutorResponse`, `mentorResponse`, `contentClassification`, `contentSummarization`, `embedding`
- [ ] The task manager screen shows tasks grouped by purpose, with per-purpose token subtotals
- [ ] Real-time updates via StreamProvider or WebSocket-style polling (not manual refresh)
- [ ] Failed tasks have a "Retry" button that re-queues the task with the same parameters
- [ ] Running tasks show a progress indicator (estimated completion based on tokens/time)
- [ ] Token counting uses a more accurate method (actual tokenizer or at least `content.split(' ').length * 1.3`)
- [ ] The `llm_usage_meter.dart` is wired into every LLM call across all features (teaching, mentoring, ingestion, practice evaluation) — verify coverage
- [ ] Total token usage and estimated cost display in the app bar or a persistent bottom bar

**Affected Files:**
- `lib/core/services/llm_task_manager.dart` — add purpose field, retry, real-time updates
- `lib/core/services/llm_usage_meter.dart` — verify coverage across features
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — grouping, retry, real-time
- `lib/features/llm_tasks/providers/llm_tasks_providers.dart` — stream provider (create if missing)
- `lib/core/services/llm/llm_chat_service.dart` — pass task purpose, use better token counting

---

### VG-4: AI Agent Long-Term Memory & Tool-Use Architecture (MAJOR)

**Vision Statement:**
> "Agents must have long term memory not each new session is fresh now and toolless." (user feedback)
> "This assistant should feel like a persistent mentor that understands the student's history, habits, preferences, and academic goals."

**Current State:**
- Mentor has `_buildContextPrompt()` that sends analytics into each chat — good foundation
- But each new conversation session starts with zero context from previous sessions
- `ConversationMemory` has 50-turn limit and is persisted, but never re-loaded across sessions
- The mentor generates `ScheduleProposal` and `PlanProposal` but has no tool-use framework — all "actions" are detected via keyword matching in the user's message text
- No function-calling/tool-use pattern — the LLM cannot directly call `scheduleLesson()`, `generateQuestions()`, etc. instead it outputs natural language text that the mentor screen tries to parse

**Acceptance Criteria:**
- [ ] Implement a tool-use/function-calling pattern for the LLM:
  - Define a set of tools (functions) the LLM can call: `ScheduleLesson`, `GetWeakTopics`, `GetMasteryState`, `GenerateQuestions`, `CreateRoadmap`, `UpdatePlan`, `GetUpcomingLessons`, `GetTodaysStats`
  - Each tool has a JSON schema with parameters
  - The LLM response is parsed for function calls, executed, and results fed back
  - This replaces the current fragile `_detectSchedulingIntent()` keyword matching
- [ ] Conversation memory spans sessions:
  - When a mentor session ends, generate a summary (topics discussed, actions taken, student mood)
  - Store summaries in the conversation repository
  - When a new session begins, load the last N summaries and seed the `_buildContextPrompt()`
- [ ] Long-term preference learning:
  - Track student preferences over time: preferred study times, lesson durations, subject priorities
  - Store in a `StudentProfileModel` (currently `UserProfile` exists but is minimal)
  - Feed preferences into every mentor interaction

**Affected Files:**
- `lib/features/mentor/services/mentor_service.dart` — tool-use pattern, cross-session context
- `lib/features/teaching/services/conversation_manager.dart` — seed from historical summaries
- `lib/core/services/conversation_memory.dart` — session summarization
- `lib/features/mentor/data/models/chat_message_data.dart` — session summary field
- `lib/features/settings/data/models/user_profile_model.dart` — preferences fields
- `lib/core/services/llm/llm_chat_service.dart` — function-calling support in prompt templates

---

## PHASE 2: INCOMPLETE/STUB FEATURES (MEDIUM IMPACT)

---

### VG-5: Slide-Based Lesson Presentations (MAJOR)

**Vision Statement:**
> "Lessons may be structured, visual, slide-like, or interactive, but should always remain conversational and adaptive."

**Current State:**
`LessonBlockType.slide` exists at `lesson_block_card.dart:44-45` but renders as `Icons.slideshow` + `Text(block.content)` — identical to every other block type.

**Acceptance Criteria:**
- [ ] Slide blocks render as full-width cards with: large heading text, bullet-point content formatting, optional background color/image, page indicator
- [ ] A "Presentation Mode" button exists in the lesson detail screen AppBar that opens a full-screen slide carousel (PageView with swipe navigation)
- [ ] Presentation mode shows: slide counter (3/12), navigation arrows, auto-advance timer option
- [ ] The slide content supports rich formatting: bullet lists, code blocks, math expressions (via existing `MathExpressionWidget`), inline images
- [ ] Presentation mode is responsive — works on tablet landscape as a true presentation tool

**Affected Files:**
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — slide-specific rendering
- `lib/features/lessons/presentation/lesson_detail_screen.dart` — "Presentation Mode" entry point
- Create: `lib/features/lessons/presentation/screens/presentation_screen.dart`
- Create: `lib/features/lessons/presentation/widgets/slide_viewer.dart`

---

### VG-6: Voice Interaction Across Features (MAJOR)

**Vision Statement:**
> "voice conversation, speech-to-text and text-to-speech"
> "The student should be able to speak naturally with the AI tutor, ask follow-up questions, interrupt explanations"

**Current State:**
- `VoiceController` wraps `speech_to_text` + `flutter_tts` — only wired into the TutorScreen (`tutor_screen.dart:470-474`)
- **No voice input in mentor chat** — mentor only takes typed text
- **No TTS for mentor responses** — all mentor text is read-only
- **No voice dictation for practice answers** — typed-answer questions don't support speech-to-text input
- **No voice commands** — user cannot say "start practice" or "show my weak areas"
- Voice bar in tutor has no "interrupt" capability — speaking doesn't stop ongoing TTS
- `_buildAdaptiveChunks()` intentionally slows down text streaming (15ms/chunk) to simulate typing — this conflicts with voice output which should be fast

**Acceptance Criteria:**
- [ ] Voice input bar added to `MentorScreen` (same pattern as tutor)
- [ ] TTS for mentor responses: toggle button in AppBar "Read Aloud" speaks the last mentor message
- [ ] Voice dictation added to practice session: when a typed-answer question is shown, a microphone button transcribes speech into the answer field
- [ ] In tutor mode: speaking (voice bar active) stops ongoing TTS automatically (interruption support)
- [ ] Voice input is available with the correct locale mapping (already implemented in `_localeForSpeech()` — just needs wiring)
- [ ] Test with both English and Spanish locales (verify STT/TTS models exist for `es_ES`)

**Affected Files:**
- `lib/features/mentor/presentation/mentor_screen.dart` — add VoiceBar widget
- `lib/features/mentor/providers/mentor_providers.dart` — wire voiceControllerProvider
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — dictation for typed answers
- `lib/features/practice/presentation/widgets/single_answer_widget.dart` — microphone button
- `lib/features/teaching/services/voice_controller.dart` — interruption support
- `lib/features/teaching/services/conversation_manager.dart` — respect voice mode for streaming speed

---

### VG-7: Mastery History & Trend Visualization (MAJOR)

**Vision Statement:**
> "track: performance history... identify weak areas, and drive adaptive revision"

**Current State:**
`MasteryState` is a point-in-time snapshot. No history is kept. The dashboard shows "today's mastery" but users cannot see improvement over time. `getAtRiskQuestions()` exists but is never called from any UI.

**Acceptance Criteria:**
(From `issues/open/dry_run_usability_validator.md` M2 and M4)
- [ ] Implement `MasteryHistoryEntry` model — snapshot per session or per day
- [ ] Dashboard shows a trend line for per-topic accuracy over time (last 7/30 days)
- [ ] `getAtRiskQuestions()` from `MasteryGraphService` is surfaced in a new "At-Risk Questions" card on the dashboard
- [ ] Weak areas detail screen shows historical accuracy chart with annotations for practice sessions

**Affected Files:**
- `lib/features/practice/data/models/mastery_state_model.dart` — add history
- `lib/core/services/mastery_calculation_service.dart` — snapshot creation
- `lib/features/dashboard/presentation/widgets/weak_areas_card.dart` — add historical trend
- `lib/core/services/mastery_graph_service.dart` — wire getAtRiskQuestions to UI

---

## PHASE 3: ARCHITECTURAL DEBT (MEDIUM IMPACT)

---

### AD-1: Repository Contract Enforcement (MAJOR)

**Issue:** 7 repositories violate the `Result<T>` contract (`issues/open/code_refactor_master.md` B2).

**Affected Repositories:**
- `SubjectRepository` — create, addTopicToSubject, removeTopicFromSubject, getWithTopics, getByCode
- `AttemptRepository` — all methods
- `PlanRepository` — all methods
- `RoadmapRepository` — all methods
- `ConversationRepository` — all methods
- `TutorSessionRepository` — all methods
- `EngagementNudgeRepository` — all methods

**Acceptance Criteria:**
- [ ] All 7 repositories wrap all public method return types in `Result<T>`
- [ ] `AttemptRepository.create` fixes the discarded `Result` bug at line 10
- [ ] Add a lint rule or unit test that verifies new repositories follow the contract

---

### AD-2: Bidirectional Feature Dependency Cycles (MAJOR)

**Issue:** `planner ↔ sessions` and `dashboard ↔ subjects` have direct bidirectional imports (`issues/open/code_refactor_master.md` B3, B4).

**Acceptance Criteria:**
- [ ] Extract shared contracts into `core/data/contracts/`
- [ ] `SessionTrackerScreen` receives planner data via Riverpod provider bridge
- [ ] Dashboard imports subject data through a clean abstraction layer

---

## COMPLETE FINDINGS SUMMARY

| ID | Type | Severity | Area | Status |
|---|---|---|---|---|
| BETA-B1 | User Feedback | BLOCKER | Focus Mode | ⚠️ Must Fix Now |
| BETA-B2 | User Feedback | BLOCKER | Lessons / Teaching | ⚠️ Must Fix Now |
| VG-1 | Vision Gap | BLOCKER | Background Notifications | 🔜 Phase 1 |
| VG-2 | Vision Gap | MAJOR | Video/Audio Ingestion | 🔜 Phase 1 |
| VG-3 | Vision Gap | MAJOR | LLM Task Manager | 🔜 Phase 1 |
| VG-4 | Vision Gap | MAJOR | Agent Memory & Tools | 🔜 Phase 1 |
| VG-5 | Vision Gap | MAJOR | Slide Presentations | 🔜 Phase 2 |
| VG-6 | Vision Gap | MAJOR | Voice Across Features | 🔜 Phase 2 |
| VG-7 | Vision Gap | MAJOR | Mastery History | 🔜 Phase 2 |
| AD-1 | Architecture | MAJOR | Repository Contract | 🔜 Phase 3 |
| AD-2 | Architecture | MAJOR | Feature Cycles | 🔜 Phase 3 |
| - | Dry Run | BLOCKER×5 | Practice System Bugs | ⚠️ Listed in separate issue |

---

## IMPLEMENTATION ORDER RECOMMENDATION

1. **Fix Beta Issues** (BETA-B1, BETA-B2) — these are real user complaints
2. **Fix Practice Blocker Bugs** (dry_run_usability_validator.md B1-B5) — listed in separate issue, but the practice system must work before focus mode changes make sense
3. **Architectural:** Add `workmanager` (AD-adacent for VG-1) and fix repository contracts (AD-1) — these unblock everything else
4. **Vision Gap - High Impact:** Background notifications (VG-1), Agent memory/tools (VG-4)
5. **Vision Gap - Medium Impact:** Voice (VG-6), Slide presentations (VG-5), Mastery history (VG-7)
6. **Quality of Life:** LLM task manager (VG-3), Video ingestion (VG-2)

---

## RELATED FILES INDEX

```
Focus Mode:    lib/features/focus_mode/**/* (5 files)
Lessons:       lib/features/lessons/**/* (9 files)
Teaching:      lib/features/teaching/**/* (22 files)
Mentor:        lib/features/mentor/**/* (7 files)
Planner:       lib/features/planner/**/* (35+ files)
Practice:      lib/features/practice/**/* (40+ files)
Core Services: lib/core/services/**/* (21 files)
Ingestion:     lib/features/ingestion/**/* (12 files)
LLM Tasks:     lib/features/llm_tasks/**/* (2 files + core service)
Dashboard:     lib/features/dashboard/**/* (20+ files)
```

---

## When Complete

After all BETA-B1 and BETA-B2 acceptance criteria are met:
1. Move `issues/further_issues/open/lessons.md` to `issues/further_issues/completed/lessons_fixed.md`
2. Move `issues/further_issues/open/focus_mode.md` to `issues/further_issues/completed/focus_mode_fixed.md`
3. Update this file's status headers to [✓] for completed items
4. Remove VG-4 (Agent Memory & Tools) from this issue if it was addressed in BETA-B2's long-term memory requirement
