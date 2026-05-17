# Future Functionality Plan: Phase 3 Audit & Roadmap

## Context

Fourth-pass audit comparing the vision (`agent_must_read.md`) against current implementation. This report documents: (1) zero progress since the previous completed report — all 16 issues remain open, (2) new user-rage reports from `issues/further_issues/open/`, (3) newly discovered gaps, and (4) a prioritised phase plan with concrete acceptance criteria.

**Critical finding:** Every issue from `issues/completed/future_functionality_planner.md` remains unfixed. The two user-rage issues (`focus_mode.md`, `lessons.md`) have escalated — users now report the same problems *again* with identical severity.

**Further issues integrated:**

| File | Priority | Summary |
|---|---|---|
| `issues/further_issues/open/focus_mode.md` | **URGENT (escalated)** | User rage: "fucking useless", "must change immediately". Wants Focus Mode = cross-subject practice question hub, not Pomodoro timer. |
| `issues/further_issues/open/lessons.md` | **URGENT (escalated)** | User rage: "fucking useless", "fucking clear all of them". Wants Preply-style calendar scheduling, LLM agents that prepare materials, long-term agent memory, tool-using agents, separate scheduling from lesson plans. |

---

## Progress Since Previous Report

| Previous ID | Description | Status | Notes |
|---|---|---|---|
| **B1** | Background notification scheduling | ❌ STILL OPEN | `EngagementScheduler` still `Timer.periodic`-based (engagement_scheduler.dart:94-103); no `workmanager` in pubspec.yaml |
| **B2** | Focus Mode = Pomodoro timer, not practice mode | ❌ STILL OPEN | `focus_timer_screen.dart` unchanged; user rage escalated |
| **B3** | Lesson system static, no LLM agent materials | ❌ STILL OPEN | `lesson_service.dart`, `tutor_screen.dart` unchanged; user rage escalated |
| **M1** | Voice conversation flow (auto-send, TTS, interrupt, toggle) | ❌ STILL OPEN | `voice_controller.dart` unchanged; `speak()` still has zero callers |
| **M2** | Mentor `suggestNextAction()` rule-based | ❌ STILL OPEN | `mentor_service.dart:575-581` still calls rule-based `getRecommendations()` |
| **M3** | Handwriting recognition for canvas submissions | ❌ STILL OPEN | `canvas_drawing_widget.dart` has basic drawing but no handwriting OCR pipeline; `canvas`/`graphDrawing` question types still stubs |
| **M4** | `LessonService` queries `SessionRepository` not `LessonRepository` | ❌ STILL OPEN | `lesson_service.dart` unchanged |
| **M5** | ConversationManager phase transitions fragile | ❌ STILL OPEN | `conversation_manager.dart` unchanged |
| **M6** | No lesson presentation/slide system | ❌ STILL OPEN | `tutor_screen.dart` still chat-only; `LessonBlockType.slide` enum value exists but unused by tutoring system |
| **m1** | `VoiceController.speak()` exists but never called | ❌ STILL OPEN | Zero callers confirmed |
| **m2** | FocusTimerScreen hardcoded English + direct singleton | ❌ STILL OPEN | Hardcoded strings at lines 197-205, 445; direct `StudentIdService()` access at lines 89? |
| **m3** | `EmbeddingService` has zero callers (~200 lines dead code) | ❌ STILL OPEN | `llm_embeddings_service.dart` still uncalled |
| **m4** | `TutorSession.totalTokensUsed` defined but unpopulated | ❌ STILL OPEN | `tutor_session_model.dart` field defined, never written |
| **m5** | No cross-feature event bus | ❌ STILL OPEN | `cross_feature_integrator.dart` uses direct repo calls |
| **m6** | `LlmTaskManager` tasks lost on app restart | ❌ STILL OPEN | In-memory only, no Hive persistence |
| **m7** | Content pipeline excludes 5 question types | ❌ STILL OPEN | `content_pipeline.dart` still hardcodes limited `allowedTypes` |

### New findings since previous report

| ID | Description | Severity |
|---|---|---|
| **N1** | Tutor screen lacks structured slide/presentation mode — critical for B3 | MAJOR |
| **N2** | No long-term agent memory system — agents start fresh each session | MAJOR |
| **N3** | No tool-using agent infrastructure (web search, syllabus access, etc.) | MAJOR |
| **N4** | MentorScreen has no voice input — vision requires voice in all interaction modes | MAJOR |
| **N5** | `EngagementScheduler` creates 7+ singletons via `new` in main.dart:93-105 instead of provider injection | MINOR |
| **N6** | `conversation_memory.dart` maxTurns=30 hardcoded in ConversationManager; no long-term memory beyond current session | MAJOR |
| **N7** | No network connectivity monitoring — all API calls fail silently when offline | MINOR |
| **N8** | `FocusTimerScreen` has dead `_lastTickMs` reconciliation code (focus_timer_screen.dart:70-79) that only works while app is foregrounded | MINOR |
| **N9** | Tab 5 is called "Focus Mode" (timer icon) but user wants practice hub — rebranding required | MAJOR |

---

## BLOCKER — App crashes or user cannot proceed

### B1. Background notifications tied to app process — proactive engagement stops when app is closed

**Context:** `EngagementScheduler` (engagement_scheduler.dart:94-103) uses `Timer.periodic` which dies with the app process. `flutter_local_notifications` is used only for foreground-triggered delivery. No `workmanager`, `android_alarm_manager`, or other background scheduling package exists in `pubspec.yaml`. When the app is killed, all nudges, reminders, and notifications stop — the "persistent mentor" from the vision is non-functional.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/services/engagement_scheduler.dart` | 94-103 | `Timer.periodic` — lost on app close |
| `lib/main.dart` | 92-110 | Scheduler created per-launch with `new`, no background task |
| `lib/core/services/notification_service.dart` | — | `flutter_local_notifications` exists but not wired to background scheduling |
| `pubspec.yaml` | — | Missing `workmanager` dependency |

**Acceptance criteria:**
1. Nudge checks run at least once every 6h even when app is closed (platform-permitted)
2. On app reopen after >24h closed, missed nudges are caught up and displayed
3. Lesson reminders fire 15min before scheduled lesson time
4. Practice nudges fire if no practice session recorded in last 48h
5. All notification scheduling uses platform-native APIs (workmanager), not app-process `Timer`
6. Existing foreground notification behavior is preserved
7. `EngagementScheduler` dependencies injected via Riverpod providers, not `new` in main.dart

---

### B2. Focus Mode is a Pomodoro timer — user demands cross-subject practice mode (ESCALATED)

**Context:** User report (`further_issues/open/focus_mode.md`) states current Focus Mode is "fucking useless" and "must fix immediately making the focus mode actually useful." Current implementation (`focus_timer_screen.dart`) is purely a Pomodoro-style countdown timer with subject selector. The user wants a **practice mode** where students practice questions from different subjects — like a "quick practice" hub that aggregates spaced-repetition due reviews, weak-topic drilling, and free-form question practice into a single focused interface.

The vision describes: "adaptive practice should be a major component: the system should continuously test understanding, focus on weak areas, revisit old content intelligently, and optimize for retention and mastery."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/focus_mode/` (entire feature) | Pomodoro timer, not practice mode |
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | 553 lines of timer + break logic that user rejects |
| `lib/features/focus_mode/presentation/widgets/focus_timer_widget.dart` | Circular progress timer UI |
| `lib/features/focus_mode/providers/focus_mode_providers.dart` | 9 lines — only creates `StudyTimerService` provider |
| `lib/features/practice/` | Practice feature exists but is a separate tab; Focus Mode should be the entry point |
| `lib/main.dart:337-339` | Tab 5 labeled "Focus Mode" with timer icon |

**Rationale:** The timer infrastructure (session recording, adherence tracking, badge checking) is valuable scaffolding. Keep timer as an OPTIONAL sub-mode. The default view should be a practice dashboard.

**Acceptance criteria:**
1. Focus Mode default view shows subjects with due reviews / weak topic practice cards (NOT a timer)
2. User can start a "Focus Practice Session" that pulls questions from: spaced repetition due queue, weak topics (mastery < 0.5), or manual subject/topic selection
3. Timer runs in background during practice (showing elapsed/target time) to track focus duration
4. Session records correct/incorrect answers, updates mastery, and logs a Session record
5. End-of-session summary shows: questions answered, accuracy, time spent, mastery changes
6. Original Pomodoro timer mode still available as a toggle ("Pure Timer" / "Practice Mode")
7. Hardcoded English strings moved to ARB keys (`focus_timer_screen.dart` lines 166, 197-205, 445)
8. Direct `StudentIdService()` singleton calls replaced with provider injection
9. `NotificationService()` created via provider, not `new`
10. Tab 5 renamed from "Focus Mode" to "Practice" or "Study" with appropriate icon

---

### B3. Lesson system is static — user demands LLM agent-driven material preparation and scheduling (ESCALATED)

**Context:** User report (`further_issues/open/lessons.md`) states lessons are "fucking useless", "fucking clear all of them." The user demands:
1. **Preply-style calendar scheduling** — see scheduled lessons in a calendar, reschedule, book new lessons
2. **LLM agents that prepare materials** — not a chatbot, but agents that research, create presentations, generate exercises, and prepare lesson content proactively
3. **Separate scheduling from lesson plan** — scheduling is about time/calendar; lesson plan is about content/presentation
4. **Long-term agent memory** — agents remember past lessons, student progress, preferences across sessions
5. **Tool-using agents** — agents can call tools (search web, access syllabus, generate questions)
6. **Presentation mode** — slide-like structured content alongside conversational AI

The vision says: "AI tutor should dynamically generate the lesson plans and goals beforehand, teach concepts interactively, explain ideas step-by-step" and "lessons may be structured, visual, slide-like, or interactive."

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/lessons/` (entire feature) | Static content model, no agent-driven preparation |
| `lib/features/lessons/presentation/lesson_list_screen.dart` | Flat lesson list, no scheduling view |
| `lib/features/lessons/presentation/lesson_detail_screen.dart` | Static block list; hardcoded `durationMinutes: 45` at line 91 |
| `lib/features/lessons/services/lesson_service.dart` | Confusing architecture — queries `SessionRepository` not `LessonRepository` |
| `lib/features/teaching/presentation/tutor_screen.dart` | Chat-based only, no slides/presentations |
| `lib/features/teaching/services/conversation_manager.dart` | Phase machine fragile, no structured content output |
| `lib/features/teaching/services/prompts/prompts.dart` | Basic prompts, no agent instructions |
| `lib/features/planner/presentation/planner_screen.dart` | Scheduling exists but no calendar view |
| `lib/features/planner/presentation/widgets/calendar_view_widget.dart` | Calendar widget exists but is plan-focused, not lesson-scheduling-focused |
| `lib/core/services/conversation_memory.dart` | maxTurns=30 in-memory only; no cross-session persistence |

**Acceptance criteria:**
1. **Calendar scheduling view:** Dedicated lesson scheduling screen with calendar grid (like Preply/Google Calendar). User can tap a time slot to schedule, drag to reschedule, see availability and conflicts. This is distinct from the planner calendar.
2. **LLM agent system for lesson content:** Create `LessonAgentService` that receives a topic + syllabus + student history and proactively generates: lesson plan (sections, timing), presentation content (structured sections with headings, bullet points, examples), exercises, and summary notes. Runs asynchronously before lesson time.
3. **Separation of concerns:** Clear separation between `SchedulingService` (calendar, time, conflicts) and `LessonContentService` (materials, presentations, exercises). Rename/refactor `LessonService` to resolve `SessionRepository` vs `LessonRepository` confusion.
4. **Long-term agent memory:** Agents receive previous lesson summaries, student weak areas, mastery state, and preference history when preparing new lessons. `ConversationMemory` extended with cross-session persistence (stored per-student, retrievable by topic/subject).
5. **Tool-using agents:** Agents can call tools during lesson preparation: `searchSyllabus`, `getStudentWeakTopics`, `getPreviousLessonSummary`, `generateQuestions`, `searchWeb`. Define a `Tool` interface/abstract class.
6. **Presentation mode in TutorScreen:** Add slide-like view alongside chat. AI produces structured sections (Markdown headings, bullet points, code blocks, math) rendered as scrollable cards. Student can chat alongside viewing slides.
7. Fix hardcoded `durationMinutes: 45` in `lesson_detail_screen.dart:91` and `lesson_list_screen.dart:88` — use configurable or adaptive duration.
8. `LessonPlan.defaultPlan()` resolve `// TODO: i18n` at `lesson_plan_model.dart:72`.

---

## MAJOR — Features broken, misleading, or critically incomplete

### M1. No true voice conversation flow — STT transcription only, no TTS playback, no interrupt

**Context:** VoiceBar is rendered in TutorScreen but:
- No auto-send on silence detection — user must tap send manually
- No TTS playback of AI responses — `VoiceController.speak()` exists (voice_controller.dart:157-177) but **never called** after an AI response arrives (confirmed by grep — zero callers)
- No voice conversation mode toggle (voice-only, text-only, mixed)
- No "interrupt AI speaking with new voice input"
- Mentor screen and Quick Guide screen have no voice support at all despite the vision requiring "speak naturally with the AI tutor"

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | VoiceBar present but no conversational voice loop; TTS never triggered |
| `lib/features/teaching/services/voice_controller.dart` | `speak()` exists (line 157) but never called after AI response |
| `lib/features/teaching/services/conversation_manager.dart` | After streaming AI response (line 169), no `voiceController.speak()` call |
| `lib/features/mentor/presentation/mentor_screen.dart` | No VoiceBar, no voice controller |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | No VoiceBar, no voice controller |
| `lib/features/teaching/providers/teaching_providers.dart` | `voiceControllerProvider` not `KeepAlive` — destroyed on navigation |

**Acceptance criteria:**
1. Tap-to-talk triggers speech recognition; after 1.5s silence, recognized text is auto-sent
2. After AI response arrives, it is read aloud via TTS (`voiceController.speak()` called after streaming completes)
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
5. Recommendation includes actionable `MentorAction.type` that student can tap to execute

---

### M3. No handwriting recognition for canvas submissions

**Context:** `QuestionType.canvas` and `QuestionType.graphDrawing` exist as enum values but only as `break` stubs in `content_pipeline.dart`. The canvas drawing widget exists (`canvas_drawing_widget.dart`) for free-form drawing but there is no handwriting-to-text recognition pipeline. Practice sessions never include canvas-type questions.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` | Drawing exists but no OCR pipeline to convert strokes to text |
| `lib/core/data/extraction/ocr_extractor.dart` | Has LLM-based OCR but not wired to canvas submissions |
| `lib/features/practice/services/practice_session_service.dart` | No canvas question handling |
| `lib/features/practice/providers/practice_providers.dart` | No canvas question type in allowed types |
| `lib/features/ingestion/services/content_pipeline.dart` | `canvas` and `graphDrawing` in allowedTypes but only `break` |

**Acceptance criteria:**
1. Canvas strokes can be submitted for LLM-based interpretation (sent as image bytes via vision API)
2. Recognized text/math shown to student for confirmation before submission
3. Handwritten math expressions evaluated for correctness via `ExerciseEvaluator`
4. Canvas questions appear alongside typed questions in practice sessions
5. Content pipeline's `_generateQuestions` updated to include `canvas` and `graphDrawing` in allowed types

---

### M4. `LessonService` queries `SessionRepository` not `LessonRepository` — confusing architecture

**Context:** `LessonService` (lesson_service.dart) treats `Session` models as "lessons" — it queries `sessionRepository` for all operations. `Lesson` and `Session` are completely separate Hive types with different purposes. `Lesson` is authored content; `Session` is a study activity record.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/lessons/services/lesson_service.dart` | All methods query `SessionRepository`, not `LessonRepository` |

**Acceptance criteria:**
1. `LessonService` renamed to reflect its actual behavior (e.g., `LessonSessionService`)
2. OR `LessonService` refactored to use `LessonRepository` with a separate class for session-based queries
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

**Context:** The tutoring system (`tutor_screen.dart` + `conversation_manager.dart`) is entirely chat-based. There is no "slide" or "presentation" mode where structured lesson content is displayed alongside the conversation. The `LessonBlockType.slide` enum exists in `enums.dart` but is never used by the tutoring system.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/presentation/tutor_screen.dart` | Chat-only; no presentation view |
| `lib/core/data/enums.dart` | `LessonBlockType.slide` enum value exists but unused in teaching |
| `lib/features/teaching/services/conversation_manager.dart` | Outputs streaming text only, no structured sections |

**Acceptance criteria:**
1. LessonPlan sections (introduction, main content, practice) render as structured cards/slides in the tutor screen
2. Students can scroll through slides while the AI explains alongside
3. Slide content includes formatted math, diagrams placeholders, and bullet points

---

## MINOR — Code quality, UX friction, or technical debt

### m1. `VoiceController.speak()` exists but is never called after AI response

**Context:** `VoiceController.speak()` (voice_controller.dart:157-177) has full TTS implementation but no code path calls it. Confirmed by grep — zero callers.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/services/voice_controller.dart:157` | `speak()` implemented but unreferenced |
| `lib/features/teaching/services/conversation_manager.dart:169` | After `assistantContent` ready, no `speak()` call |

---

### m2. `FocusTimerScreen` has hardcoded English strings and direct singleton access

**Context:** The focus timer screen accesses `StudentIdService().getStudentId()` directly and has hardcoded English dialog strings.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/focus_mode/presentation/focus_timer_screen.dart` | Multiple | Hardcoded strings, direct singleton access |

---

### m3. `EmbeddingService` fully implemented but has zero callers (~200 lines dead code)

**Context:** `EmbeddingService` has full OpenRouter/Ollama/OpenAI embedding integration but no callers exist.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/core/services/llm/llm_embeddings_service.dart` | ~200 | Fully implemented, zero callers |

**Acceptance criteria:**
1. Either remove `EmbeddingService` with its provider + barrel export
2. OR create a concrete use case (semantic search across ingested materials, question similarity matching, RAG for tutor context)

---

### m4. `TutorSession.totalTokensUsed` defined but never populated

**Context:** `TutorSession` model has `totalTokensUsed` field but it is never written to.

**Affected files:**
| File | Issue |
|---|---|
| `lib/features/teaching/data/models/tutor_session_model.dart` | `totalTokensUsed` defined, never populated |
| `lib/features/teaching/services/tutor_service.dart` | `endLesson()` doesn't record token usage |

---

### m5. Cross-feature event bus still missing — tight coupling between services

**Context:** `CrossFeatureIntegrator` uses direct repository calls for all cross-feature integration.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/cross_feature_integrator.dart` | Direct repository calls, no event system |

**Acceptance criteria (investigation, not implementation):**
1. Document all current cross-feature coupling points
2. Propose an event system design
3. No implementation required — design doc only

---

### m6. `LlmTaskManager` tasks lost on app restart — no persistence

**Context:** `LlmTaskManager` (llm_task_manager.dart) maintains tasks in-memory. All task history lost on restart.

**Affected files:**
| File | Issue |
|---|---|
| `lib/core/services/llm_task_manager.dart` | In-memory only, no persistence |
| `lib/features/llm_tasks/presentation/llm_task_manager_screen.dart` | Cumulative counters reset on restart |

---

### m7. Content ingestion question generation excludes 5 question types

**Context:** `ContentPipeline._generateQuestions` hardcodes `allowedTypes` excluding `canvas`, `graphDrawing`, `stepByStep`, `fileUpload`, `audioRecording`.

**Affected files:**
| File | Lines | Issue |
|---|---|---|
| `lib/features/ingestion/services/content_pipeline.dart` | ~330-395 | Excludes 5 question types |

---

## Dependency Graph & Ordering

```
Phase 1 — Fix USER-RAGE issues (IMMEDIATE — these are blocking user trust)
├── B2: Focus Mode → Cross-subject Practice Mode (rewrite entire focus_mode feature)
├── B3: Lessons → LLM Agent-driven materials + Calendar Scheduling
│   ├── M6: Presentation/slide view in TutorScreen
│   ├── M4: Fix LessonService architecture confusion
│   └── M5: Fix ConversationManager phase transitions

Phase 2 — Background infrastructure (enables "persistent mentor")
├── B1: Workmanager integration for background notifications
├── N6: Long-term conversation memory (cross-session persistence)

Phase 3 — Voice interaction (highest vision gap)
├── M1: Voice conversation flow (auto-send, TTS, interrupt, toggle)
├── m1: Wire TTS speak() into AI response flow
├── M1/N4: Mentor/Quick Guide voice integration

Phase 4 — Agent infrastructure & smart features
├── M2: LLM-powered suggestNextAction()
├── M3: Handwriting recognition for canvas questions
├── N2: Long-term agent memory system
├── N3: Tool-using agent infrastructure

Phase 5 — Cleanup & architecture
├── m3: EmbeddingService → remove or give a use case
├── m4: TutorSession.totalTokensUsed population
├── m5: Cross-feature pub/sub design doc
├── m6: LlmTaskManager persistence
├── m2: FocusTimerScreen i18n + provider cleanup
├── m7: Content pipeline expanded question types
├── N5: EngagementScheduler provider injection vs singleton hell
├── N7: Network connectivity monitoring
```

## Rationale Summary

**25 gaps identified** — 3 BLOCKER, 6 MAJOR, 9 MINOR (9 new findings since previous report). Key changes:

1. **Zero progress** since the previous completed report — all 16 previously identified issues remain unfixed. This is the single most important finding.
2. **2 user-rage issues escalated** — `focus_mode.md` and `lessons.md` now explicitly demand immediate fixes with stronger language than before. These are the highest-priority items.
3. **9 new findings** (N1-N9) discovered during deep exploration, including missing agent infrastructure (long-term memory, tool use) and voice gaps in Mentor screen.
4. **The blocker issues are interconnected** — B3 (Lessons) touches M4 (LessonService), M5 (phases), M6 (presentation), and the new N2/N3 (agent infrastructure). Fixing B3 requires addressing all of these.
5. **Architecture concerns**: The app has ~315 test files but the core user-facing features (lessons, focus mode) remain broken from a UX standpoint. Testing coverage does not equal product quality.

The highest-impact change is **Phase 1**: B2 (Focus Mode → Practice Hub) and B3 (Lessons → Agent-driven + Scheduling). These two changes directly address user frustration and align with the core vision of "an all-in-one AI-native learning platform."
