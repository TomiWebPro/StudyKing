# Future Functionality Plan: Phase 2 Audit & Roadmap

## Context

Third-pass audit comparing the vision (`agent_must_read.md`) against current implementation. This report documents: (1) progress since the previous completed report, (2) user-reported issues from `issues/further_issues/open/`, (3) remaining open items from previous audit, (4) new findings discovered during deep exploration, and (5) a prioritised phase plan with concrete acceptance criteria.

**Further issues integrated:**
| File | Priority | Summary |
|---|---|---|
| `issues/further_issues/open/focus_mode.md` | **URGENT** | User reports Focus Mode (Pomodoro timer) is "fucking useless". Wants it to be a **cross-subject practice mode** (questions, not timer). |
| `issues/further_issues/open/lessons.md` | **URGENT** | User reports Lessons are "fucking useless". Wants: calendar scheduling view (like Preply), LLM agents (not chatbot) that prepare materials/presentations, long-term agent memory, tool-using agents, separate scheduling from lesson plan. |

---

## Progress Since Previous Report

| Previous ID | Description | Status | Notes |
|---|---|---|---|
| **B1** | Background notification scheduling | ❌ STILL OPEN | `EngagementScheduler` still `Timer`-based (engagement_scheduler.dart:94-103); no `workmanager` in pubspec.yaml |
| **M1** | Voice conversation flow (auto-send, TTS, interrupt, toggle) | ⚠️ PARTIAL | VoiceBar + VoiceController in tutor screen; TTS `speak()` exists (voice_controller.dart:157-177) but **never called** after AI response (grep confirms zero callers outside own file); no auto-send on silence; no interrupt; no conversation toggle |
| **M2** | LLM-driven `suggestNextAction()` | ❌ STILL OPEN | Still rule-based via `_progressTracker.getRecommendations()` (mentor_service.dart:575-581) |
| **M3** | Handwriting recognition for canvas | ❌ STILL OPEN | `QuestionType.canvas` and `QuestionType.graphDrawing` exist as enum values but only used as `break` stubs in `content_pipeline.dart`; no canvas widget, stroke capture, or recognition pipeline |
| **M5** | WorkloadCard hardcoded estimation | ✅ FIXED | WorkloadCard now uses `RemainingWorkloadEstimator` via `dashboardWorkloadProvider` (dashboard_data_providers.dart:149-156); hardcoded `_estimateLessonsRemaining()` removed |
| **M6** | Dashboard due reviews card | ✅ FIXED | `dashboardDueReviewsProvider` exists (dashboard_data_providers.dart:163-189) with per-subject breakdown |
| **m1** | Auto-send on silence | ❌ STILL OPEN | `VoiceController.startListening()` sets `pauseFor: 3s` but `onResult` callback only populates stream; no silence-detection-triggered auto-submit |
| **m2** | Voice in Mentor/Quick Guide | ❌ STILL OPEN | `VoiceBar` only appears in `TutorScreen` (tutor_screen.dart:464); no voice support in MentorScreen or QuickGuideScreen |
| **m3** | Cross-feature voice state | ❌ STILL OPEN | `voiceControllerProvider` is `Provider<VoiceController>` not `KeepAlive` (teaching_providers.dart:30-32) — destroyed on navigation |
| **m4** | TTS speak() never invoked after AI response | ❌ STILL OPEN | `grep` confirms `speak()` has **zero callers** outside voice_controller.dart definition |
| **m6** | Cross-feature pub/sub | ❌ STILL OPEN | `CrossFeatureIntegrator` still uses direct repository calls; no event bus |

### New findings since previous report

| ID | Description | Severity |
|---|---|---|
| **N1** | Focus Mode is a Pomodoro timer, not a practice mode — contradicts user expectations | BLOCKER (user rage) |
| **N2** | Lesson system is static content with no LLM agent-driven material preparation | BLOCKER (user rage) |
| **N3** | No calendar/scheduling view for lessons — user wants Preply-style interface | MAJOR |
| **N4** | `LessonService` queries `SessionRepository` not `LessonRepository` — confusing architecture | MAJOR |
| **N5** | `TutorSession.totalTokensUsed` is defined but **never populated** | MAJOR |
| **N6** | `EmbeddingService` fully implemented but has **zero callers** (dead code ~200 lines) | MINOR |
| **N7** | `FocusTimerScreen` has hardcoded English strings and direct `StudentIdService()` singleton access | MINOR |
| **N8** | `ConversationManager` phase transitions fragile — no structured flow back from `adaptiveReview` to `teaching` | MAJOR |
| **N9** | `LessonPlan.defaultPlan()` has `// TODO: i18n` — hardcoded English section titles | MINOR |
| **N10** | No lesson presentation/slide system — LLM only returns chat text, not structured content | MAJOR |
| **N11** | `LlmTaskManager` tasks lost on app restart — no persistence, cumulative counters meaningless | MINOR |
| **N12** | No network connectivity monitoring — API calls fail silently when offline | MINOR |
| **N13** | Content ingestion question generation excludes canvas/graphDrawing/stepByStep types | MINOR |

---

## BLOCKER — App crashes or user cannot proceed

### B1. Background notifications tied to app process — proactive engagement stops when app is closed

**Context:** `EngagementScheduler` (engagement_scheduler.dart:94-103) uses `Timer.periodic` which dies with the app process. `flutter_local_notifications` is used only for foreground-triggered delivery. No `workmanager`, `android_alarm_manager`, or other background scheduling package exists in `pubspec.yaml`. When the app is killed, all nudges, reminders, and notifications stop.

The vision requires a "persistent mentor" that "proactively engage[s] students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement" — this remains the single biggest gap between vision and reality.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/services/engagement_scheduler.dart` | 94-103 | `Timer.periodic` — lost on app close |
| `lib/main.dart` | — | Scheduler started per-launch, no headless task |
| `lib/core/services/notification_service.dart` | — | `flutter_local_notifications` exists but not wired to background scheduling |
| `pubspec.yaml` | — | Missing `workmanager` dependency |

**Acceptance criteria:**
1. Nudge checks run at least once every 6h even when app is closed (platform-permitted)
2. On app reopen after >24h closed, missed nudges are caught up and displayed
3. Lesson reminders fire 15min before scheduled lesson time
4. Practice nudges fire if no practice session recorded in last 48h
5. All notification scheduling uses platform-native APIs (workmanager), not app-process `Timer`
6. Existing foreground notification behavior is preserved

---

### B2. Focus Mode is a Pomodoro timer — user demands cross-subject practice mode

**Context:** User report (`further_issues/open/focus_mode.md`) states current Focus Mode is "fucking useless". Current implementation (`focus_timer_screen.dart`) is purely a Pomodoro-style countdown timer with subject selector. The user wants a **practice mode** where students practice questions from different subjects — like a "quick practice" hub that aggregates spaced-repetition due reviews, weak-topic drilling, and free-form question practice into a single focused interface.

The vision describes: "adaptive practice should be a major component: the system should continuously test understanding, focus on weak areas, revisit old content intelligently, and optimize for retention and mastery."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/focus_mode/` (entire feature) | Pomodoro timer, not practice mode |
| `lib/features/practice/` | Practice feature exists but is separate; Focus Mode should be the entry point |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | Hours of timer + break logic that user rejects |
| `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart` | Circular progress timer UI |
| `lib/features/focus_mode/providers/focus_mode_providers.dart` | 9 lines — only creates `StudyTimerService` provider |

**Rationale for fix rather than delete:** The timer infrastructure (session recording, adherence tracking, badge checking) is valuable. The fix is to ADD a practice mode alongside or replacing the timer, or make the timer OPTIONAL during a focus practice session. The core timer feature could serve as a "focus session duration" that wraps around a practice flow.

**Acceptance criteria:**
1. Focus Mode default view shows subjects with due reviews / weak topic practice cards (NOT a timer)
2. User can start a "Focus Practice Session" that pulls questions from: spaced repetition due queue, weak topics (mastery < 0.5), or manual subject/topic selection
3. Timer runs in background during practice (showing elapsed/target time) to track focus duration
4. Session records correct/incorrect answers, updates mastery, and logs a Session record
5. End-of-session summary shows: questions answered, accuracy, time spent, mastery changes
6. Original Pomodoro timer mode still available as a toggle ("Pure Timer" / "Practice Mode")
7. Hardcoded English strings (focus_timer_screen.dart:197-205, 445) moved to ARB keys
8. Direct `StudentIdService().getStudentId()` calls replaced with injected provider

---

### B3. Lesson system is static — user demands LLM agent-driven material preparation and scheduling

**Context:** User report (`further_issues/open/lessons.md`) states current Lessons are "fucking useless". Current implementation is static pre-authored content (Subject → Topic → Lesson → Blocks) stored in Hive. The user wants:
1. **Calendar scheduling view** (like Preply) — see scheduled lessons in a calendar, reschedule, book new lessons
2. **LLM agents prepare materials** — not just a chatbot, but agents that research, create presentations, generate exercises, and prepare lesson content proactively
3. **Separate scheduling from lesson plan** — scheduling is about time/calendar; lesson plan is about content/presentation
4. **Long-term agent memory** — agents remember past lessons, student progress, preferences across sessions
5. **Tool use** — agents can execute tools (e.g., search web, access syllabus, generate questions)

The vision says: "AI tutor should dynamically generate the lesson plans and goals beforehand, teach concepts interactively, explain ideas step-by-step" and "lessons may be structured, visual, slide-like, or interactive."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/lessons/` (entire feature) | Static content model, no agent-driven preparation |
| `lib/features/lessons/presentation/topic_list_screen.dart` | Simple topic list, no calendar |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | Flat lesson list, no scheduling |
| `lib/features/lessons/services/lesson_service.dart` | Confusing architecture — queries `SessionRepository` not `LessonRepository` |
| `lib/features/teaching/presentation/tutor_screen.dart` | Chat-based only, no slides/presentations |
| `lib/features/teaching/services/conversation_manager.dart` | Phase machine fragile, no structured content output |
| `lib/features/teaching/services/prompts/prompts.dart` | Basic prompts, no agent instructions |
| `lib/features/planner/services/planner_service.dart` | Scheduling exists but no calendar view |

**Acceptance criteria:**
1. **Lesson scheduling redesign:** Calendar view showing scheduled lessons with time slots (like Preply/Google Calendar). User can tap a slot to schedule, drag to reschedule, see availability.
2. **LLM agent system:** Create `LessonAgentService` that receives a topic + syllabus + student history and proactively generates: lesson plan (sections, timing), presentation content (slide-like structured sections), exercises, and summary notes. This runs asynchronously before the lesson.
3. **Separation of concerns:** `SchedulingService` (calendar, time, conflicts) is separate from `LessonContentService` (materials, presentations). Currently `LessonService` conflates both.
4. **Agent memory:** Agents receive previous lesson summaries, student weak areas, mastery state, and preference history when preparing new lessons.
5. **Tool-using agents:** Agents can call tools (e.g., `searchSyllabus`, `getStudentWeakTopics`, `getPreviousLessonSummary`, `generateQuestions`) during preparation.
6. **Presentation mode in TutorScreen:** Add a slide-like view mode alongside the chat. AI can show "slide content" (structured Markdown/sections) that the student can scroll through while chatting alongside.
7. **Fix `LessonService`** to either use `LessonRepository` or be renamed to `SessionService` — current behavior is misleading.
8. Hardcoded `durationMinutes: 45` in lesson_detail_screen.dart:91 and lesson_list_screen.dart:88 replaced with configurable or adaptive duration.
9. `LessonPlan.defaultPlan()` `// TODO: i18n` resolved (lesson_plan_model.dart:72).

---

## MAJOR — Features broken, misleading, or critically incomplete

### M1. No true voice conversation flow — STT transcription only, no TTS playback, no interrupt

**Context:** VoiceBar is rendered in TutorScreen and `_onTranscriptionSubmitted()` fills text and sends. However:
- No auto-send on silence detection — user must tap send manually
- No TTS playback of AI responses — `VoiceController.speak()` exists (voice_controller.dart:157-177) but **never called** after an AI response arrives (confirmed by grep)
- No voice conversation mode toggle (voice-only, text-only, mixed)
- No "interrupt AI speaking with new voice input"
- Mentor screen and Quick Guide screen have no voice support at all despite the vision requiring "speak naturally with the AI tutor"

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | VoiceBar present but no conversational voice loop; TTS never triggered |
| `lib/features/teaching/services/voice_controller.dart` | `speak()` exists (line 157) but never called after AI response; `startListening()` sets 3s pause but no auto-send |
| `lib/features/teaching/services/conversation_manager.dart` | After streaming AI response (line 169), no `voiceController.speak()` call |
| `lib/features/mentor/presentation/mentor_screen.dart` | No VoiceBar, no voice controller |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | No VoiceBar, no voice controller |
| `lib/features/teaching/providers/teaching_providers.dart` | `voiceControllerProvider` not `KeepAlive` |

**Acceptance criteria:**
1. Tap-to-talk triggers speech recognition; after 1.5s silence, recognized text is auto-sent
2. After AI response arrives, it is read aloud via TTS (`voiceController.speak()` called at conversation_manager.dart:169)
3. User can interrupt AI speaking by tapping mic again (stops TTS, starts new recognition)
4. Voice conversation mode toggle in tutor screen (voice-only, text-only, mixed)
5. Mentor screen has microphone button alongside text input
6. Quick Guide screen has microphone button alongside text input
7. Voice mode respects `settingsProvider.locale` for both STT and TTS
8. `voiceControllerProvider` changed to `KeepAliveProvider` to persist across navigation

---

### M2. Mentor `suggestNextAction()` rule-based, not LLM-driven

**Context:** `MentorService.suggestNextAction()` (mentor_service.dart:575-581) calls `_progressTracker.getRecommendations()` which returns rule-based messages, then falls back to generic locale strings. The vision requires an AI mentor that dynamically decides what to study next.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/mentor/services/mentor_service.dart` | 575-581 | Rule-based via `getRecommendations()` |
| `lib/core/services/study_progress_tracker.dart` | ~166-223 | `getRecommendations()` purely rule-based |

**Acceptance criteria:**
1. `suggestNextAction()` composes an LLM prompt with student context (weak topics, adherence %, recent sessions, upcoming lessons, current time)
2. Returns AI-generated contextual recommendation
3. Graceful fallback to rule-based if LLM unavailable
4. LLM recommendation cached for 15min to avoid redundant API calls
5. Recommendation includes actionable `MentorAction.type` that student can tap to execute (e.g., "Start Practice", "Review Topic X", "Take a Break")

---

### M3. No handwriting recognition for canvas submissions

**Context:** `QuestionType.canvas` and `QuestionType.graphDrawing` exist as enum values in `content_pipeline.dart` but only as `break` stubs. There is no canvas drawing widget, no stroke capture, no handwriting recognition pipeline. The practice session never includes canvas-type questions. The vision requires "handwritten/drawn responses on canvas" and "vision-based interpretation of student work."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/questions/presentation/widgets/` | No canvas_drawing_widget.dart exists |
| `lib/features/questions/presentation/painters/` | No drawing_painter.dart exists |
| `lib/core/data/extraction/ocr_extractor.dart` | Has OCR but not wired to canvas |
| `lib/features/practice/services/practice_session_service.dart` | No canvas question handling |
| `lib/features/practice/providers/practice_providers.dart` | No canvas question type in allowed types |
| `lib/features/ingestion/services/content_pipeline.dart` | `canvas` and `graphDrawing` in allowedTypes but only `break` |

**Note:** Previous report referenced "drawing submitted" magic string — this has been removed. However the feature itself is still entirely unimplemented.

**Acceptance criteria:**
1. Canvas drawing widget exists for students to write/draw responses
2. Canvas strokes can be submitted for LLM-based interpretation (sent as image bytes via vision API)
3. Recognized text/math shown to student for confirmation before submission
4. Handwritten math expressions evaluated for correctness via `ExerciseEvaluator`
5. Canvas questions appear alongside typed questions in practice sessions
6. Content pipeline's `_generateQuestions` updated to include `canvas` and `graphDrawing` in allowed types

---

### M4. `LessonService` queries `SessionRepository` not `LessonRepository` — confusing architecture

**Context:** `LessonService` (lesson_service.dart) treats `Session` models as "lessons" — it queries `sessionRepository` for all its operations. But `Lesson` and `Session` are completely separate Hive types with different purposes. `Lesson` is authored content; `Session` is a study activity record. This creates confusion about what a "lesson" actually is in the system.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/lessons/services/lesson_service.dart` | All methods query `SessionRepository`, not `LessonRepository` |

**Acceptance criteria:**
1. `LessonService` renamed to `SessionLessonService` or `LessonSessionService` to reflect reality
2. OR `LessonService` is refactored to use `LessonRepository` and a separate class handles session-based queries
3. No behavior change for callers — public API unchanged

---

### M5. `ConversationManager` phase transitions fragile — no recovery from `adaptiveReview`

**Context:** `ConversationManager.sendMessage()` (conversation_manager.dart:123-178) has phase transitions but once in `adaptiveReview`, there is no structured path back to `teaching` except via `_detectExerciseRequest` (line 260-263) which only fires on explicit user message keywords. A student could get stuck in adaptive review mode indefinitely.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/teaching/services/conversation_manager.dart` | 141-146, 260-263 | Adaptive review → teaching recovery ambiguous |

**Acceptance criteria:**
1. After `adaptiveReview` completes (student answers correctly or explicitly asks to continue), phase transitions back to `teaching`
2. Phase transitions are logged for debugging
3. Tutor screen displays current phase for transparency

---

### M6. No lesson presentation/slide system — LLM returns only chat text, not structured content

**Context:** The tutoring system (`tutor_screen.dart` + `conversation_manager.dart`) is entirely chat-based. There is no "slide" or "presentation" mode where structured lesson content is displayed alongside the conversation. The `LessonBlockType.slide` exists in the lessons model but is never used by the tutoring system.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | Chat-only; no presentation view |
| `lib/features/lessons/data/models/lesson_block_model.dart` | `LessonBlockType.slide` enum value exists but unused |
| `lib/features/teaching/services/conversation_manager.dart` | Outputs streaming text only, no structured sections |

**Acceptance criteria:**
1. LessonPlan sections (introduction, main content, practice) render as structured cards/slides in the tutor screen
2. Students can scroll through slides while the AI explains alongside
3. Slide content includes formatted math, diagrams placeholders, and bullet points

---

## MINOR — Code quality, UX friction, or technical debt

### m1. `VoiceController.speak()` exists but is never called after AI response

**Context:** `VoiceController.speak()` (voice_controller.dart:157-177) has a full TTS implementation with locale-aware language, rate, volume, and pitch settings. However, no code path in the tutor screen, mentor screen, or conversation manager calls `speak()` after receiving an AI response. Confirmed by grep — zero callers.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/services/voice_controller.dart:157` | `speak()` implemented but unreferenced by UI |
| `lib/features/teaching/services/conversation_manager.dart:169` | After `assistantContent` is ready, no `speak()` call |

**Acceptance criteria:**
1. After AI response text is displayed, `voiceController.speak(responseText)` is called
2. Speaking can be interrupted by new user mic input
3. TTS respects locale from settings

---

### m2. `FocusTimerScreen` has hardcoded English strings and direct singleton access

**Context:** Focus timer screen uses hardcoded English for `'Daily Cap Warning'`, `'Continue Anyway'` (lines 197-205), help text on line 445. Also accesses `StudentIdService().getStudentId()` directly (lines 122, 136) instead of through provider injection.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 197-205, 445 | Hardcoded English strings |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 122, 136 | Direct singleton access |
| `lib/features/focus_mode/providers/focus_mode_providers.dart` | 8 | `NotificationService()` created with `new` |

**Acceptance criteria:**
1. All hardcoded strings replaced with ARB keys
2. `StudentIdService()` replaced with provider injection
3. `NotificationService()` created via provider, not `new`

---

### m3. `EmbeddingService` fully implemented but has zero callers (~200 lines dead code)

**Context:** `EmbeddingService` (llm_embeddings_service.dart) has full OpenRouter/Ollama/OpenAI embedding endpoint integration with proper task manager wiring, but no callers exist. This suggests an abandoned RAG/semantic search feature.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/services/llm/llm_embeddings_service.dart` | ~200 | Fully implemented, zero callers |

**Acceptance criteria:**
1. Either remove `EmbeddingService` with its provider + barrel export
2. OR create a concrete use case (e.g., semantic search across ingested materials, question similarity matching, RAG for tutor context)
3. If kept with a use case, document the integration point

---

### m4. `TutorSession.totalTokensUsed` defined but never populated

**Context:** `TutorSession` model (tutor_session_model.dart:57-75) has `totalTokensUsed` field but it is never written to. The teaching flow creates sessions and saves summaries but never records token usage.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/data/models/tutor_session_model.dart` | `totalTokensUsed` defined, never populated |
| `lib/features/teaching/services/tutor_service.dart` | `endLesson()` doesn't record token usage |

**Acceptance criteria:**
1. `TutorService.endLesson()` records `totalTokensUsed` from `LlmUsageMeter` or `LlmTaskManager`
2. Token usage displayed in tutor session history if available

---

### m5. Cross-feature event bus still missing — tight coupling between services

**Context:** `CrossFeatureIntegrator` (cross_feature_integrator.dart) uses direct repository calls for all cross-feature integration. Adding new behaviors requires modifying existing services. No pub/sub or event bus exists.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/cross_feature_integrator.dart` | Direct repository calls, no event system |
| `lib/features/practice/services/practice_session_service.dart` | Writes directly to session repo |
| `lib/features/teaching/services/tutor_service.dart` | Writes directly to session/conversation repos |

**Acceptance criteria (investigation, not implementation):**
1. Document all current cross-feature coupling points
2. Propose an event system design (Riverpod StreamProvider or lightweight EventBus)
3. No implementation required — design doc only

---

### m6. `LlmTaskManager` tasks lost on app restart — no persistence

**Context:** `LlmTaskManager` (llm_task_manager.dart) maintains tasks in-memory. All task history, cumulative token counts, and cost tracking are lost on app restart. The task manager screen shows meaningless totals if the app has been restarted.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/llm_task_manager.dart` | In-memory only, no persistence |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | Shows cumulative counters that reset on restart |

**Acceptance criteria:**
1. Task history optionally persisted to Hive (configurable, max N entries)
2. Cumulative token and cost counters survive app restart
3. Persistence is opt-in to avoid unbounded storage growth

---

### m7. Content ingestion question generation excludes canvas/graphDrawing/audioRecording/fileUpload/stepByStep

**Context:** `ContentPipeline._generateQuestions` (content_pipeline.dart:330-395) hardcodes `allowedTypes` to `['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay']` — excluding `canvas`, `graphDrawing`, `stepByStep`, `fileUpload`, `audioRecording`.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/ingestion/services/content_pipeline.dart` | ~330-395 | Excludes 5 question types from generation |

**Acceptance criteria:**
1. `canvas` and `graphDrawing` added to allowed types when handwriting pipeline exists
2. `stepByStep` added as allowed type
3. Excluded types should have a clear reason documented (e.g., `audioRecording` requires STT)

---

## Dependency Graph & Ordering

```
Phase 1 — Fix USER-RAGE issues (immediate)
├── B2: Focus Mode → Cross-subject Practice Mode (rewrite focus mode)
├── B3: Lessons → LLM Agent-driven materials + Calendar Scheduling
│   ├── M6: Presentation/slide view in TutorScreen
│   ├── M4: Fix LessonService architecture confusion
│   └── M5: Fix ConversationManager phase transitions

Phase 2 — Background infrastructure (enables "persistent mentor")
├── B1: Workmanager integration for background notifications

Phase 3 — Voice interaction (highest vision gap)
├── M1: Voice conversation flow (auto-send, TTS, interrupt, toggle)
├── m1: Wire TTS speak() into AI response flow
├── m2: Mentor/Quick Guide voice integration
├── m3: Cross-feature voice state management (KeepAlive)

Phase 4 — AI-driven mentor & smart content
├── M2: LLM-powered suggestNextAction()
├── M3: Handwriting recognition for canvas questions
├── m7: Content pipeline expanded question types

Phase 5 — Cleanup & architecture
├── m3: EmbeddingService → remove or give a use case
├── m4: TutorSession.totalTokensUsed population
├── m5: Cross-feature pub/sub design doc
├── m6: LlmTaskManager persistence
├── m2: FocusTimerScreen i18n + provider cleanup
```

## Rationale Summary

**16 gaps identified** — 3 BLOCKER, 6 MAJOR, 7 MINOR. Compared to the previous report, this cycle adds:

1. **2 user-rage issues** (B2, B3) from `issues/further_issues/` — the most critical items. The Pomodoro timer focus mode and static lesson system are actively frustrating users and must be redesigned.
2. **5 new findings** (M4 → LessonService confusion, M5 → phase transition fragility, M6 → no presentation system, m4 → totalTokensUsed unpopulated, m7 → excluded question types) discovered during deep exploration.
3. **5 items remain open** from the previous report: B1 (background notifications), M1 (voice flow), M2 (LLM suggestNextAction), M3 (handwriting), m6 (pub/sub). These persist because they require significant architectural work.

The highest-impact change is **B2+B3 combined** — Focus Mode as practice hub and Lessons as agent-driven scheduling + materials. These two changes directly address user frustration and align with the core vision of "an all-in-one AI-native learning platform."
