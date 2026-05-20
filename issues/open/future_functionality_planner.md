# Future Functionality Planner — Vision vs Implementation Gap Analysis (v3)

**Generated:** 2026-05-20
**Source:** `agent_must_read.md` (product vision) vs codebase audit
**Input from beta testers:** `issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`
**Previous analysis:** `issues/completed/future_functionality_planner.md` (v2 — superseded)

---

## Progress Since v2 (Items Now Resolved)

| Item | Status | Evidence |
|------|--------|----------|
| B2: Focus mode practice question filtering | ✅ Fixed | `FocusPracticeService.getDueQuestions()` now delegates to `SpacedRepetitionService.getQuestionsDueForReview()` |
| B2: Wrong answers silently dropped | ✅ Fixed | `InlinePracticeWidget._nextQuestion()` calls `MasteryRecorder.recordAttempt()` with `isCorrect` for ALL answers |
| B2: Post-session analytics | ✅ Fixed | `PracticePerformanceCard` widget created, `SessionSummaryCard` delegates to it |
| B2: FocusSession dead code | ✅ Fixed | Model actively used by `FocusTimerScreen` and `SessionMigrationService` |
| M3: Background tasks (partial) | ✅ Fixed | `IdleExecutor` monitors app lifecycle for background LLM work. Still no `workmanager`. |
| M9: CrossFeatureIntegrator dead code | ✅ Fixed | File deleted from codebase |
| m5: Wrong answers silently dropped | ✅ Fixed | Same as B2 fix above |
| m6: FocusSession dead code | ✅ Fixed | Model actively instantiated in production paths |

**Still UNRESOLVED from v2:** B1 (lesson agentification, rich slides, calendar scheduling), M1 (LLM planner), M2 (voice VAD), M3 (persistent background tasks via workmanager), M4 (token budget enforcement), M5 (PDF extraction), M6 (local OCR), M7 (proper STT), M8 (web scraper), M10 (additional locales).

---

## BLOCKER — App crashes or user cannot proceed

### B1. Lessons System Still Lacks LLM Agent Integration, Rich Content, and Calendar Scheduling

**Source:** Beta-tester `lessons.md` + vision audit (`agent_must_read.md:27-47`)
**Severity:** BLOCKER — core teaching loop remains sub-par

**Problem:** Despite v2 marking this as "addressed", the following gaps remain:

1. **`LessonAgentService` still uses raw `LlmService.chat()`** — `lesson_agent_service.dart:80` calls `_llmService.chat()` directly with a manually constructed prompt. The `LlmAgent`/`AgentLoop`/`ToolRegistry` infrastructure (which exists in `lib/core/services/llm_agent/` and is used by `MentorService` and `TutorService`) is completely ignored. No tools, no memory, no structured output parsing.

2. **`LessonBlock` has no `richContent` field** — `lesson_block_model.dart` defines only `String content`. No markdown, no LaTeX, no image references, no code blocks. `LessonBlockCard` renders everything as plain `Text()` widgets (e.g., `lesson_block_card.dart:76`).

3. **Calendar view shows roadmaps, not lesson time slots** — `CalendarViewWidget` displays plan milestones and roadmap items, not scheduled lesson slots. The beta tester explicitly wants a Preply-style calendar with lesson time blocks.

4. **No background lesson preparation** — `IdleExecutor` is never enqueued with lesson-prep tasks. `PlannerService.scheduleLesson()` creates a bare `Session` without triggering LLM lesson plan generation.

5. **Lesson planning is fully deterministic** — `PlannerService` and `PersonalLearningPlanService` use rule-based algorithms with zero LLM input. No workload estimation, no adaptive pathways, no qualitative plan reasoning.

**Affected files:**
- `lib/features/lessons/services/lesson_agent_service.dart` — raw `LlmService.chat()` calls, no `LlmAgent`/tools/memory
- `lib/features/lessons/data/models/lesson_block_model.dart` — no `richContent` field
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — plain `Text()` rendering
- `lib/features/lessons/presentation/lesson_detail_screen.dart` — no calendar scheduling integration
- `lib/core/services/llm_agent/idle_executor.dart` — no lesson-prep enqueueing
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` — shows roadmaps, not lesson slots
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — creates bare `Session`, not `LessonPlan`
- `lib/features/planner/services/planner_service.dart` — `scheduleLesson()` does not trigger LLM prep
- `lib/features/planner/services/personal_learning_plan_service.dart` — 1063 lines, zero LLM references

**Acceptance Criteria:**
- [ ] `LessonAgentService` refactored to use `LlmAgent` with agent loop + registered tools + `LongTermMemory` context injection
- [ ] Lesson-prep agent tools: `getStudentStats`, `getWeakTopics`, `searchQuestions`, `getSyllabusProgress`, `createLessonPlan`
- [ ] `LessonBlock` gains `richContent` field (supporting markdown, LaTeX, image references, code blocks with syntax highlighting)
- [ ] `LessonBlockCard` renders rich content with markdown/LaTeX rendering
- [ ] `CalendarViewWidget` shows scheduled lesson time slots (topic + duration + prep status) with tap-to-view
- [ ] `PlannerService.scheduleLesson()` enqueues background lesson prep via `IdleExecutor`
- [ ] Background lesson prep generates structured `LessonPlan` with slides, exercises, examples, summary
- [ ] `PersonalLearningPlanService` gains an optional LLM advisor strategy for workload estimation and adaptive pathway suggestions
- [ ] Slide full-screen mode includes rich markdown rendering with image support and LaTeX equation rendering

**Rationale:** Without these, "lessons" remain a reading list with text slides. The infrastructure (agent loop, tools, memory) already exists — the lessons feature simply doesn't use it. The beta tester explicitly calls the current experience unusable.

---

### B2. Focus Mode UX Still Misaligned with Student Practice Expectations

**Source:** Beta-tester `focus_mode.md` + vision audit (`agent_must_read.md:86-87`)
**Severity:** BLOCKER — advertised feature is actively harming UX trust

**Problem:** While the internal practice pipeline was fixed (due question filtering, wrong answer recording), the **user-facing flow** still centers on a timer rather than practice:

1. **Timer-first, practice-second UX** — The default screen state is a timer setup (`_studyMode = true`). Practice is a hidden toggle (`_studyMode` boolean) behind a switch. The beta tester expects to land on a practice hub, not a timer.

2. **No post-lesson "Focus Mode" entry point** — After finishing a lesson in `TutorScreen`, there is no button like "Practice what you just learned" that navigates to focus mode with the lesson's subject/topic pre-selected.

3. **Session type selector is a dropdown/enum, not prominent UX** — `_sessionType` is a `FocusSessionType` enum set via code, not a visible user-facing selector. Users may not realize they can choose practice modes.

4. **`FocusTimerScreen` is 1357 lines of mixed concerns** — timer logic, practice hub, onboarding, subject picker, session stats, inline practice orchestration all in one file. This makes targeted UX improvements risky.

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1357 lines) — monolith, timer-first UX
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` — separate but UX flow starts from timer
- `lib/features/teaching/presentation/tutor_screen.dart` — no post-lesson practice entry point
- `lib/features/dashboard/presentation/dashboard_screen.dart` — focus card navigates to timer, not practice

**Acceptance Criteria:**
- [ ] Post-lesson summary dialog includes "Practice these topics" button that navigates to focus mode with subject+topic pre-selected and practice mode active
- [ ] Default focus mode view is the "Study Hub" (practice hub with subject cards and due counts), not the timer
- [ ] Session type selector (Spaced Repetition / Weak Area Attack / Quick Practice / Free Focus) is a visible card row, not a hidden enum
- [ ] `FocusTimerScreen` split: timer logic → `ActiveFocusSessionWidget`, practice hub → `StudyHubWidget`, screen as thin orchestrator
- [ ] Dashboard focus card navigates to practice hub by default (not timer)

**Rationale:** The beta tester is unambiguous: the current focus mode is not what they need. The infrastructure is there (SR service, mastery recorder, inline practice), but the UX flow doesn't expose it correctly.

---

## MAJOR — Feature is broken, misleading, or contradicts the vision

### M1. Planner is Fully Deterministic — No LLM Involvement in Study Planning

**Vision reference:** `agent_must_read.md:73-85`
**Severity:** MAJOR

**Problem:** `PersonalLearningPlanService` (1063 lines), `SyllabusResolver`, and `PlannerService` all use deterministic algorithms with zero LLM references. A full grep of `personal_learning_plan_service.dart` for any LLM/chat/AI pattern returns zero matches. The vision explicitly says planning should be "intelligent and long-term" with workload estimation, adaptive pathways, and qualitative reasoning.

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart` (1063 lines, zero LLM references)
- `lib/features/planner/services/planner_service.dart` — no LLM guidance for scheduling/planning
- `lib/features/planner/services/syllabus_resolver.dart` — prerequisite ordering could be LLM-optimized

**Acceptance Criteria:**
- [ ] LLM agent consulted during plan generation: receives student stats, study history, goals; returns structured plan outline with rationale
- [ ] Plan adaptation uses LLM to understand *why* student is falling behind (overwhelmed vs busy vs bored) and suggests adjustments
- [ ] LLM generates motivational reasoning and summary for each plan milestone
- [ ] Workload estimation factors in student's historical study pace, not just topic count

---

### M2. Voice Conversation Still Lacks Natural Turn-Taking

**Vision reference:** `agent_must_read.md:16-22`, line 29
**Severity:** MAJOR

**Problem:** `VoiceService` (239 lines) and `VoiceBar` widget exist but lack proper voice activity detection (VAD). The service relies on the `speech_to_text` package's built-in `pauseFor` timeout instead of energy-based VAD. Key gaps:
- No energy-threshold-based silence detection — uses a fixed timeout (`Timeouts.voicePause`)
- No user-review step for transcriptions (VoiceBar has a review overlay but it's just a 2s timer)
- No per-locale voice selection for TTS
- No interrupt-and-resume UX when TTS plays and user speaks
- Inconsistent voice UX across Tutor, Mentor, and Practice screens

**Affected files:**
- `lib/core/services/voice_service.dart` — no VAD, no per-locale TTS voice config
- `lib/features/teaching/presentation/widgets/voice_bar.dart` — timer-based review, not VAD
- `lib/features/mentor/presentation/mentor_screen.dart` — voice button exists but no conversation flow
- `lib/features/practice/presentation/screens/practice_session_screen.dart` — voice auto-submits

**Acceptance Criteria:**
- [ ] Voice button states: idle → listening (energy wave) → processing → done
- [ ] Transcriptions shown in reviewable text field before submission
- [ ] Silence timeout configurable (default 2s); alternative: manual stop button
- [ ] Per-locale TTS voice mapping (locale → flutter_tts voice name)
- [ ] TTS pauses on user speech; microphone stays active during playback
- [ ] Consistent voice UX across Tutor, Mentor, and Practice screens

---

### M3. No Persistent Background Task Runner for Idle LLM Work

**Vision reference:** `agent_must_read.md:98`, line 102
**Severity:** MAJOR

**Problem:** `IdleExecutor` runs only while the app is in the foreground (Dart `Timer`). `EngagementScheduler` also uses a Dart `Timer`. No `flutter_workmanager`, `android_alarm_manager`, or `background_fetch` dependency exists in `pubspec.yaml`. Notifications cannot be scheduled to survive app restart.

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart` — foreground-only
- `lib/core/services/engagement_scheduler.dart` — Dart Timer, not persistent
- `lib/core/services/notification_service.dart` — no `zonedSchedule`, no background scheduling
- `pubspec.yaml` — no `workmanager` or background execution dependency

**Acceptance Criteria:**
- [ ] `flutter_workmanager` integrated for background task scheduling
- [ ] Background tasks: lesson prep (upcoming slots), nudge generation (daily), plan adherence (periodic), overdue session auto-finalization
- [ ] `EngagementScheduler` uses workmanager periodic task instead of Dart Timer
- [ ] Scheduled notifications survive app restart (`flutter_local_notifications` `zonedSchedule`)
- [ ] Background tasks respect battery/data constraints, cancellable from Settings

---

### M4. Token Usage Tracked but No Budget Enforcement

**Vision reference:** `agent_must_read.md:102`
**Severity:** MAJOR

**Problem:** `LlmUsageMeter` and `LlmTaskManager` record usage but have zero enforcement — no per-feature budgets, no spending limits, no throttling, no user-facing cost controls. Students using their own API keys have no way to cap spending.

**Affected files:**
- `lib/core/services/llm_usage_meter.dart` — no budget enforcement
- `lib/core/services/llm_task_manager.dart` — no budget checks on task creation
- `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` — no budget UI
- `lib/features/settings/presentation/settings_screen.dart` — shows usage but no budget controls
- `lib/core/constants/token_pricing_config.dart` — hardcoded pricing, no per-model config

**Acceptance Criteria:**
- [ ] `TokenBudgetService` tracks rolling usage per-day/per-feature with configurable hard limits
- [ ] Settings screen has per-feature token budget controls with on/off toggle and numeric limit
- [ ] Notifications/alerts at 80%/100% of budget
- [ ] LLM service rejects calls that would exceed budget with clear error message
- [ ] Per-model pricing configurable (map of model ID → cost per 1K tokens)
- [ ] System prompt tokens included in input token count

---

### M5. PDF Extraction Still Uses Regex — No Proper Library

**Severity:** MAJOR

**Problem:** `PdfExtractor` (152 lines) still uses `String.fromCharCodes(bytes)` + regex extraction from raw PDF bytes. The `pdf: ^3.10.4` package exists in `pubspec.yaml` but is not imported. This fails on scanned PDFs, compressed streams, and non-standard encoding. PDFs are the #1 student content format.

**Affected files:**
- `lib/core/data/extraction/pdf_extractor.dart` (regex-based, confirmed NOT fixed)
- `lib/features/ingestion/services/document_extractor.dart` — delegates to PdfExtractor

**Acceptance Criteria:**
- [ ] Use `pdf` package's `PdfDocument.openBytes()` for proper text extraction
- [ ] Page structure preserved (headings, order, paragraph grouping)
- [ ] For scanned PDFs: ML Kit OCR as page-level fallback
- [ ] Extraction method string reflects whether it used text extraction or OCR

---

### M6. OCR is LLM-Only — No Local OCR Engine

**Severity:** MAJOR

**Problem:** `OcrExtractor` (185 lines) base64-encodes images → sends to LLM with vision prompt. No offline OCR engine. Every image = LLM call ($0.01-0.05 + 3-10s latency). No confidence scoring beyond hardcoded `0.7`.

**Affected files:**
- `lib/core/data/extraction/ocr_extractor.dart` — LLM-only
- `pubspec.yaml` — no `google_mlkit_text_recognition` dependency

**Acceptance Criteria:**
- [ ] Primary OCR: `google_mlkit_text_recognition` (free, on-device, fast)
- [ ] LLM OCR as fallback when ML Kit confidence is low or text is complex (diagrams, equations)
- [ ] Per-image confidence scores stored with extraction results
- [ ] Document scanning mode: multiple images → merge results

---

### M7. No Proper STT Pipeline for Media Files

**Vision reference:** `agent_must_read.md:11` (video/audio)
**Severity:** MAJOR

**Problem:** `TranscriptionExtractor` (358 lines) uses:
- `youtubetranscript.com` API (third-party, rate-limited, no SLA)
- `LlmService` for audio/video file transcription (slow, expensive, no language detection)
- No Whisper API (OpenAI or OpenRouter) integration
- No FFMpeg for media inspection or frame extraction
- No processing progress UI

**Affected files:**
- `lib/core/data/extraction/transcription_extractor.dart` — third-party API + LLM only
- `lib/features/ingestion/services/document_extractor.dart` — delegates to TranscriptionExtractor
- `lib/features/ingestion/presentation/upload_screen.dart` — no processing progress for media

**Acceptance Criteria:**
- [ ] Whisper API (OpenRouter or direct OpenAI) as primary STT for uploaded audio/video files
- [ ] YouTube Data API v3 captions endpoint as primary YouTube STT (with youtubetranscript.com fallback)
- [ ] FFMpeg for media inspection (duration, codec, sample rate) and frame extraction
- [ ] Processing progress shown: uploading → transcribing → generating content → complete
- [ ] YouTube API key configurable in Settings > AI Configuration

---

### M8. WebScraper is Too Minimal for Modern Websites

**Severity:** MAJOR

**Problem:** `WebScraper` (49 lines) does an HTTP GET and strips HTML tags. Most educational websites require JavaScript rendering, login sessions, or cookie handling. The "website link" ingestion is unreliable.

**Affected file:**
- `lib/features/ingestion/services/web_scraper.dart` (49 lines)

**Acceptance Criteria:**
- [ ] Headless browser API (e.g., `flutter_webview`) for JS-rendered content
- [ ] Cookie/session support for login-walled educational resources
- [ ] Respect robots.txt
- [ ] Configurable timeout in Settings

---

### M9. Only 2 Supported Locales — No French, German, Arabic, etc.

**Vision reference:** `agent_must_read.md:104`
**Severity:** MAJOR

**Problem:** Only `en` and `es` locale files exist (`lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`). Key global education markets (French, Arabic, German, Portuguese, Mandarin) are unsupported.

**Affected files:**
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` — only 2 locales
- `lib/core/config/locale_config.dart` — 2-value enum

**Acceptance Criteria:**
- [ ] Add `app_fr.arb` (French)
- [ ] Add `app_ar.arb` (Arabic)
- [ ] Add `app_de.arb` (German)
- [ ] Add `app_pt_BR.arb` (Portuguese — Brazil)
- [ ] LLM prompts respect the locale for lesson generation, mentor conversations, etc.

---

### M10. Teaching Mode (Tutor) Lacks Post-Lesson Practice Integration

**Vision reference:** `agent_must_read.md:38` ("assign exercises and homework during and after class")
**Severity:** MAJOR

**Problem:** After a `TutorSession` ends, the summary dialog shows stats but offers no "Practice these topics" button. The `ConversationManager` generates exercises during the lesson, but post-lesson practice is never suggested or navigated to. Students finish a lesson and have no obvious next step for reinforcement.

**Affected files:**
- `lib/features/teaching/presentation/tutor_screen.dart` — summary dialog has no practice CTA
- `lib/features/teaching/services/tutor_service.dart` — endLesson() doesn't trigger practice suggestion
- `lib/features/teaching/services/conversation_manager.dart` — exercise phase generates exercises but no post-session practice push

**Acceptance Criteria:**
- [ ] Post-lesson summary dialog shows "Practice these topics" button
- [ ] Button navigates to Focus Mode with the lesson's subject+topic pre-selected
- [ ] Practice mode defaults to "Weak Area Attack" or "Spaced Repetition" for the lesson's topic
- [ ] Lesson topics are marked for priority review in the spaced repetition system

---

## MINOR — Code quality / UX friction / architectural debt

### m1. FocusTimerScreen is Too Large (1357 lines)

**Problem:** At 1357 lines, `FocusTimerScreen` mixes timer logic, practice hub UI, onboarding, analytics loading, subject picker, and inline practice orchestration in one stateful widget.

**Affected file:** `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1357 lines)
**Fix:** Extract into composable widgets:
- `StudyHubWidget` — subject cards, due counts, session type picker
- `FocusTimerSetupWidget` — duration selection, start button
- `ActiveFocusSessionWidget` — timer display, practice overlay
- Keep `FocusTimerScreen` as a thin orchestrator

---

### m2. PersonalLearningPlanService is Too Large (1063 lines)

**Problem:** At 1063 lines, this service handles plan generation, goal tracking, milestone management, and schedule computation.

**Affected file:** `lib/features/planner/services/personal_learning_plan_service.dart` (1063 lines)
**Fix:** Split into:
- `PlanGeneratorService` (plan creation from syllabus + goals)
- `GoalTrackerService` (goal progress, modifications, completion)
- `MilestoneManager` (milestone CRUD, timeline computation)
- Thin `PersonalLearningPlanService` that delegates

---

### m3. Planner Providers is Too Large

**Affected file:** `lib/features/planner/providers/planner_providers.dart`
**Fix:** Split into:
- `plan_providers.dart` (plan progress, weekly progress, PendingAction providers)
- `syllabus_providers.dart` (syllabus, roadmap providers)
- `adherence_providers.dart` (adherence metrics, engagement nudge providers)

---

### m4. LessonAgentService Doesn't Use Existing LlmAgent Infrastructure

**Affected file:** `lib/features/lessons/services/lesson_agent_service.dart` (302 lines)
**Note:** This is the same root cause as B1. The `LlmAgent` + `AgentLoop` + `ToolRegistry` infrastructure exists but `LessonAgentService` ignores it.
**Fix:** Refactor to use `LlmAgent` with registered tools and `LongTermMemory` context injection.

---

### m5. AudioRecording and FileUpload Question Types Are Stubs

**Affected files:**
- `lib/features/questions/presentation/widgets/question_card_widget.dart` — `_buildAudioRecordingContent()` and `_buildFileUploadContent()` set answer to hardcoded strings ("audio_recorded", "file_uploaded") without actual recording/uploading

**Fix:** Implement actual audio recording via `record` package and file upload via `file_picker`. The `QuestionType` enums exist; the UI needs real implementations.

---

### m6. No Widget/Integration Tests for Critical New Flows

**Problem:** 400+ test files exist, but several critical flows lack widget tests:
- Lesson scheduling flow (booking → calendar displays → tutor launch)
- Focus mode post-session analytics display
- Tutor screen summary dialog interaction (practice button, etc.)
- Multi-locale rendering of lesson content

**Fix:** Add widget tests per AGENTS.md pattern for the above flows.

---

## Execution Plan — Next Development Phase

### Priority Order (Top-Down):

| Priority | Item | Type | Effort | Dependencies |
|---|---|---|---|---|
| **P0** | **B1: Lessons** — agentify LessonAgentService, add rich slides, calendar scheduling, background prep | BLOCKER | 3-4 weeks | M3 (background tasks), m4 (agent tools for lessons) |
| **P0** | **B2: Focus mode UX** — practice-first flow, prominent session picker, post-lesson entry point | BLOCKER | 1-2 weeks | None |
| **P0** | **Further Issues: lessons.md** — address beta tester lesson complaints specifically | BLOCKER | See B1 | B1 |
| **P0** | **Further Issues: focus_mode.md** — address beta tester focus mode complaints specifically | BLOCKER | See B2 | B2 |
| **P1** | **M3: Background task runner** — WorkManager for persistent scheduling | MAJOR | 2 weeks | None |
| **P1** | **M4: Token budget enforcement** — per-feature budgets, cost alerts | MAJOR | 1 week | None |
| **P1** | **M10: Post-lesson practice integration** — practice CTA in tutor summary | MAJOR | 2-3 days | B2 |
| **P2** | **M1: LLM planner advisor** — LLM involvement in plan generation | MAJOR | 1-2 weeks | m4 (agent tools for planner) |
| **P2** | **M2: Voice turn-taking** — VAD, review step, per-locale TTS | MAJOR | 1-2 weeks | None |
| **P2** | **M5: PDF extraction** — use `pdf` package for proper extraction | MAJOR | 3 days | None |
| **P2** | **M6: Local OCR** — ML Kit as primary, LLM as fallback | MAJOR | 3-5 days | None |
| **P2** | **M7: Proper STT** — Whisper API + YouTube Data API | MAJOR | 1-2 weeks | None |
| **P2** | **M8: WebScraper** — headless rendering, cookie support | MAJOR | 3-5 days | None |
| **P2** | **M9: Additional locales** — fr, ar, de, pt_BR | MAJOR | 2-3 days | None |
| **P3** | **m1: Split FocusTimerScreen** | MINOR | 2 days | B2 |
| **P3** | **m2: Split PersonalLearningPlanService** | MINOR | 2 days | M1 |
| **P3** | **m3: Split planner providers** | MINOR | 1 day | None |
| **P3** | **m4: Refactor LessonAgentService to use LlmAgent** | MINOR | 2-3 days | B1 |
| **P3** | **m5: Implement audio recording & file upload stubs** | MINOR | 2-3 days | None |
| **P3** | **m6: Widget tests for critical flows** | MINOR | 3-5 days | B1, B2 |

### Key Dependencies:
- B1 (Lessons) depends on M3 (background tasks) for idle prep and m4 (agent tools)
- B2 (Focus mode UX) is independent — can start immediately
- M10 (post-lesson practice) depends on B2 (practice hub UX)
- All MAJOR extraction items (M5, M6, M7, M8) are independent of each other
- M3 (background tasks) unlocks many proactive engagement features

### Further Issues Closure:
When both beta-tester issues are resolved:
1. `issues/further_issues/open/lessons.md` → delete from `open/`, acknowledge in this file
2. `issues/further_issues/open/focus_mode.md` → delete from `open/`, acknowledge in this file
3. Update this section to record resolution date and commit hash

---

## Architectural Notes for Future Sprints

1. **Cloud sync**: All data is local Hive. No cross-device sync. Consider `supabase_flutter` for future multi-device support.
2. **Batch extraction**: For students uploading 300-page textbooks, page-level chunking with batch LLM processing is needed. Current per-file processing doesn't scale.
3. **Offline-first is good**: Local Hive + Ollama support is strong. But OpenRouter-dependent features (vision, embeddings) break offline.
4. **Multi-tenancy**: Single-student architecture. No parent/teacher dashboard, no class management. Consider for future.
5. **Token budget is P1**: Students using their own API keys will abandon the app if costs spiral without controls. This directly affects trust and retention.
