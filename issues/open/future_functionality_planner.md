# Future Functionality Planner — Vision Gap Analysis (Round 3)

**Generated:** 2026-05-18
**Source:** Re-validation of `agent_must_read.md` vision against `lib/` implementation, building on `issues/completed/future_functionality_planner.md` (Rounds 1 & 2).

---

## Round 2 Resolutions (items now fixed)

| Old Ref | Issue | Status | Evidence |
|---------|-------|--------|----------|
| B2 | Agent framework disconnected from codebase | ✅ Fixed | `llm_agent_providers.dart` wires 6 tools + `LlmAgent`. `MentorService` accepts `LlmAgent?` param (line 65) and uses it at line 141/149 when non-null. |
| B1 partially | Lesson block rendering per type | ✅ Fixed | `lesson_block_card.dart` now has switch on `LessonBlockType` with interactive quiz, exercise, fullscreen slide, themed example/summary cards. |
| M5 | `LlmTaskManagerScreen` reads core directly | ✅ Fixed | Screen reads `llmTaskServiceProvider` from feature layer (line 27, 66). |
| m1 | Dashboard "Next Up" card missing | ✅ Fixed | `next_up_card.dart` shows upcoming lessons, due reviews, weak topics. |
| m2 | `TutorService.startLesson()` doesn't create `Lesson` | ✅ Fixed | `tutor_service.dart` line 122-134 creates `Lesson` with blocks, and `endLesson()` updates it with session notes (line 217-242). |
| M2 | Engagement scheduler hard-wired deps | ✅ Verified | All sub-providers inject through Riverpod `ref.watch()` — `engagementMasteryServiceProvider`, `engagementPlannerServiceProvider`, etc. |
| M1 | Voice siloed in teaching | ✅ Major progress | `VoiceService` extracted to `core/services/voice_service.dart`. Used by mentor screen (line 402) and practice session screen (line 485). Legacy `VoiceController` in teaching is now a 28-line thin wrapper. |

---

## BLOCKER — App crashes or user cannot proceed

### B1. `LlmAgent` provider exists but is NEVER passed to `MentorService` — agent framework is dead code in production

**Context:** The agent framework (6 production AgentTool implementations, `ToolRegistry`, `AgentMemoryStore`, `IdleExecutor`, `llmAgentProvider`) is fully wired at the provider level but never actually connected to any UI or service.

**Evidence:**
- `llm_agent_providers.dart:41-55` defines `llmAgentProvider` that creates a fully configured `LlmAgent` with all 6 tools
- `MentorService` constructor (line 65, 83) accepts optional `LlmAgent? agent` parameter
- `MentorService.sendMessage()` (line 141) checks `if (_agent != null)` and uses agent loop when set
- But `MentorScreen._initializeMentor()` (lines 73-84) creates `MentorService` **without passing `agent`** — the parameter is simply omitted

```dart
// mentor_screen.dart:73-84 — NO agent passed
_mentorService = MentorService(
  database: ..., llmService: ..., masteryService: ..., progressTracker: ...,
  plannerService: ..., nudgeRepo: ..., sessionRepository: ..., modelId: ...,
  studentId: studentId, localeName: l10n.localeName,
  // agent: NOT PROVIDED
);
```

**Impact:** `_agent` is always `null` at runtime. The `LlmAgent.chat()` path is dead code. The 6 tools (`ScheduleLessonTool`, `SearchQuestionsTool`, `GetStudentStatsTool`, `GenerateLessonBlocksTool`, `CreatePlanTool`, `GetWeakTopicsTool`) are never invoked. Cross-session memory (`AgentMemoryStore`) is never persisted. `IdleExecutor` queue is never populated. This is the single largest gap between architecture and reality.

**Affected files:**
- `lib/features/mentor/presentation/mentor_screen.dart:73-84` — must pass `agent` to `MentorService`
- `lib/core/providers/llm_agent_providers.dart:41` — `llmAgentProvider` exists but is never read by any screen
- `lib/features/mentor/services/mentor_service.dart:141-167` — dead agent path

**Acceptance criteria:**
1. `MentorScreen._initializeMentor()` reads `ref.read(llmAgentProvider(studentId))` and passes the result as `agent:` to `MentorService`
2. When `_agent != null`, mentor chat uses `_agent.chat()` which invokes tool calls via `AgentLoop.run()`
3. Agent memory persists across sessions (test: conversation survives app restart via Hive-backed `AgentMemoryStore`)
4. Tools execute and return results visible in mentor responses (test: `ScheduleLessonTool` called when student says "schedule a physics lesson")
5. `IdleExecutor` has at least one enqueued background task (post-mentor adherence check)

---

### B2. `LessonAgentService` provider exists but `generateLesson()` / `generateLessonFromSource()` are never called

**Context:** The `LessonAgentService` (306 lines in `lesson_agent_service.dart`) is a complete LLM-powered lesson content generator. It creates `Lesson` objects with `LessonBlock` arrays from LLM responses, handles JSON and text parsing, and has both topic-based and source-material-based generation. The provider (`lessonAgentServiceProvider`) is registered in `lesson_providers.dart`. But no production code calls `generateLesson()` or `generateLessonFromSource()`.

**Evidence:**
- `lesson_agent_service.dart:31-67` — `generateLesson()` implementation (complete, LLM-driven)
- `lesson_agent_service.dart:267-305` — `generateLessonFromSource()` implementation (complete)
- `lessonAgentServiceProvider` is only referenced in `llm_agent_providers.dart:23` (used as dependency for `GenerateLessonBlocksTool`)
- Zero calls to `generateLesson()` or `generateLessonFromSource()` anywhere in `lib/`

**Impact:** The vision requires "AI-generated lesson materials prepared ahead of scheduled time." Currently:
- `PlannerService.scheduleLesson()` creates `Session` objects (timing records) but not `Lesson` objects
- `LessonAgentService.generateLesson()` is the only code path that creates LLM-powered `Lesson` with blocks
- The `GenerateLessonBlocksTool` (in the agent framework) wraps `lessonAgentService.generateLesson()` — but since the agent is never connected (B1), the tool also never fires
- Post-ingestion lesson generation from `ContentPipeline` is not implemented

**Affected files:**
- `lib/features/lessons/services/lesson_agent_service.dart` — complete but unused
- `lib/features/lessons/providers/lesson_providers.dart:21-29` — `lessonAgentServiceProvider` registered but never consumed by UI
- `lib/features/planner/services/planner_service.dart` — `scheduleLesson()` only creates Sessions, not Lessons
- `lib/features/ingestion/services/content_pipeline.dart` — no call to `generateLessonFromSource()` in `processFullPipeline()`

**Acceptance criteria:**
1. When a lesson is scheduled via planner, `LessonAgentService.generateLesson()` is called and a `Lesson` record with blocks is created (or linked to the `Session`)
2. User can manually trigger lesson generation from topic detail or subject topic list — lesson appears in lesson list
3. Post-ingestion, `ContentPipeline.processFullPipeline()` optionally calls `generateLessonFromSource()` to create lesson materials from uploaded content
4. `GenerateLessonBlocksTool` (agent tool) actually generates lessons when called through the agent loop (requires B1 fix first)

---

## MAJOR — Feature is broken or misleading

### M1. Focus Mode still has no inline Q&A — all practice navigates away

**Context:** The beta user complaint is only partially addressed. The `FocusTimerScreen` (829 lines) has a study-hub layout with subject practice cards, due counts, quick/weak/spaced practice buttons, and a timer. BUT every practice action calls `Navigator.push()` to `PracticeSessionScreen` — no inline Q&A within the focus screen itself.

**Evidence:**
- `focus_timer_screen.dart:286-288` — `_startQuickPractice()` calls `Navigator.pushNamed(context, AppRoutes.practiceSession)`
- `focus_timer_screen.dart:293-323` — `_startWeakAreasPractice()` calls `Navigator.pushNamed(context, AppRoutes.practiceSession)`
- `focus_timer_screen.dart:343-354` — spaced repetition practice also navigates away
- No inline question widget exists in the focus mode codebase
- `FocusPracticeService` (84 lines) provides due questions but only for count display — not for inline answering
- Session continuity is broken: accuracy from `PracticeSessionScreen` doesn't flow back into the focus session

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` — all practice actions navigate away
- `lib/features/focus_mode/services/focus_practice_service.dart` — provides questions but no inline answer tracking
- `lib/features/focus_mode/data/focus_session_model.dart` — model exists but doesn't track per-question accuracy inline

**Acceptance criteria:**
1. Focus screen has an optional inline practice mode: when selected, questions appear directly in the focus screen (not navigation)
2. During inline practice, the timer continues running and time is tracked per question
3. After session ends, per-subject accuracy is calculated and stored (correct count, total count, accuracy %)
4. Session summary card shows: questions answered, accuracy, time spent, mastery deltas
5. Existing "navigate to PracticeSession" path remains as full-practice alternative

---

### M2. No post-ingestion lesson generation — `ContentPipeline` generates questions but not lessons

**Context:** The vision says: "The system should intelligently process, organize, classify, validate, and integrate this material into the broader learning system." `ContentPipeline.processFullPipeline()` (233 lines) extracts text, classifies topics, generates summaries, generates questions, validates them — but does NOT generate lesson materials from the ingested content.

**Evidence:**
- `content_pipeline.dart:90-233` — `processFullPipeline()` has stages: extracting, classifying, summarizing, question generation, validation — no lesson generation stage
- `content_pipeline.dart:179-212` — question generation block has no companion lesson generation block
- `lesson_agent_service.dart:267-305` — `generateLessonFromSource()` exists and is specifically designed for this, but is never called
- Upload screen (`upload_screen.dart`) has no "Generate lesson from this material" option

**Affected files:**
- `lib/features/ingestion/services/content_pipeline.dart` — no lesson generation stage
- `lib/features/lessons/services/lesson_agent_service.dart:267-305` — `generateLessonFromSource()` method exists but no consumer calls it
- `lib/features/ingestion/presentation/upload_screen.dart` — no lesson generation toggle

**Acceptance criteria:**
1. `ContentPipeline.processFullPipeline()` gets a new `generateLessons` parameter
2. When `generateLessons = true`, after question generation, the pipeline calls `LessonAgentService.generateLessonFromSource()` to create `Lesson` with blocks
3. Upload screen shows "Generate lesson from this material" toggle
4. Generated lessons appear in the lesson list for the matched subject/topic

---

### M3. No topic dependency visualizer — prerequisite management is checkbox-list only

**Context:** Topic dependency management exists (`TopicDependency`, `TopicDependencyDialog`, `subject_topics_tab.dart` shows prereq counts) but there is NO graphical visualization of topic dependencies.

**Evidence:**
- `topic_dependency_dialog.dart` — uses `CheckboxListTile` for prereq selection (no graph/tree)
- `subject_topics_tab.dart:330-335` — shows prereq count as label text only
- `topic_repository.dart` has `getRootTopics()` and `addParent()` but no `getDependencyGraph()` or topological sort
- No widget renders a directed graph, tree view, or dependency arrows

**Affected files:**
- `lib/features/subjects/presentation/dialogs/topic_dependency_dialog.dart` — list-based, no visual graph
- `lib/features/subjects/presentation/widgets/subject_topics_tab.dart` — shows prereq counts as text only
- `lib/features/subjects/data/repositories/topic_repository.dart` — no graph/topological query methods

**Acceptance criteria:**
1. Topics tab shows indentation or arrow indicators showing prerequisite chains
2. Simple directed-graph or tree view widget accessible from subject detail
3. When deleting a topic, app warns if downstream topics depend on it
4. Topic ordering respects prerequisites for practice/lesson flows
5. Add `getDependencyGraph()` / `getTopologicalOrder()` methods to repository

---

### M4. `VoiceController` in teaching is a redundant thin wrapper — should be deprecated

**Context:** `VoiceService` in `core/services/voice_service.dart` now provides the complete STT/TTS API. The teaching feature's `VoiceController` (28 lines) is a pure wrapper with zero added logic. The `VoiceBar` widget imports `VoiceController`.

**Affected files:**
- `lib/features/teaching/services/voice_controller.dart` — redundant (delegates everything to `VoiceService`)
- `lib/features/teaching/presentation/widgets/voice_bar.dart` — imports `voice_controller.dart` instead of `voice_service.dart`
- `lib/features/teaching/providers/teaching_providers.dart` — wires `VoiceController`

**Acceptance criteria:**
1. Deprecate `VoiceController` — all consumers use `VoiceService` directly
2. `VoiceBar` accepts `VoiceService` instead of `VoiceController`
3. Remove `VoiceController` entirely after migration

---

### M5. No background lesson prep — `IdleExecutor` queue is always empty

**Context:** `IdleExecutor` (104 lines) exists and is part of the `LlmAgent` class (via `_idleExecutor`). It monitors idle periods (30s) and processes a task queue. But nothing ever calls `enqueueBackgroundTask()`.

**Evidence:**
- `llm_agent.dart:48-50` — `enqueueBackgroundTask()` method exists and calls `_idleExecutor.enqueue()`
- No code in `lib/` calls `enqueueBackgroundTask()`
- `IdleExecutor` is only instantiated inside `AgentFactory.create()` which is only called by `llmAgentProvider` — which is never consumed (B1)

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart` — functional but never populated
- `lib/core/services/llm_agent/llm_agent.dart:48-50` — `enqueueBackgroundTask()` never called

**Acceptance criteria:**
1. Wire background tasks:
   - **Post-lesson**: after tutor session ends, enqueue plan adherence update
   - **Pre-lesson**: evening before a scheduled lesson, enqueue lesson material pre-generation via `LessonAgentService.generateLesson()`
   - **Post-practice**: after practice session, enqueue weak-topic reanalysis
2. Tasks execute during idle periods (30s of inactivity)
3. Task results (or failures) are visible in `LlmTaskManagerScreen`

---

## MINOR — Code quality, UX friction, incomplete polish

### m1. No handwriting/ink recognition — canvas is pure drawing with no interpretation

`canvas_drawing_widget.dart` (289 lines) exists for canvas-type questions. There is no handwriting recognition, ink-to-text, or LLM-based interpretation of drawn work (except the `TutorScreen.processImage()` method which sends base64 screenshots to LLM — not truly canvas-based).

**Acceptance criteria:**
1. Optional "Recognize handwriting" button on canvas question that sends drawn strokes to LLM for interpretation
2. Recognized text is shown and can be confirmed/edited before submitting

### m2. No dedicated ASR — transcription relies entirely on LLM

`TranscriptionExtractor` wraps `LlmService` for audio/video transcription. No dedicated speech-to-text engine (Whisper, Google Speech, etc.) is available. Impact: high latency, cost, and no offline functionality for transcription.

**Acceptance criteria:**
1. Option to use local ASR (e.g. whisper.cpp via FFI) for audio transcription
2. When local ASR is configured, transcription runs offline without LLM cost

### m3. Engagement notifications are in-app only — no push notification support

`NotificationService` shows local notifications via FlutterLocalNotificationsPlugin. There is no remote push notification infrastructure (FCM, APNs). Proactive engagement only works when the app is open.

**Acceptance criteria:**
1. Evaluate if push notifications are needed for the target deployment model (local-first suggests not critical)
2. If local-only is intentional, ensure notification display works reliably when app is backgrounded

### m4. `MentorService` is created without a Riverpod provider — not overridable in tests

`MentorService` is instantiated directly in `MentorScreen._initializeMentor()` with `new`. There is no `mentorServiceProvider`. Test overrides must mock the entire screen or manually construct `MentorService` with fakes.

**Acceptance criteria:**
1. Create `mentorServiceProvider` in `mentor_providers.dart`
2. `MentorScreen` reads `mentorServiceProvider` instead of constructing manually
3. Existing mentor tests continue to pass (may need minor refactors)

---

## Beta User Issue Resolution Tracking

| File | Priority | Status | Notes |
|------|----------|--------|-------|
| `issues/further_issues/open/lessons.md` | P0 | **Addressed by B1 + B2** | LLM-driven lesson content creation pipeline + agent framework with tools + memory resolved after fixing B1 and B2 |
| `issues/further_issues/open/focus_mode.md` | P1 | **Addressed by M1** | Focus Mode inline Q&A is the only remaining gap |

**Process for closing:**
1. Fix B1 → agent powers tools + memory → addresses `lessons.md` tool-less/memory-less complaint
2. Fix B2 → lesson generation pipeline → addresses `lessons.md` "lesson is fucking useless" complaint  
3. Fix M1 → inline practice in focus mode → addresses `focus_mode.md` complaint
4. When criteria for each are met → move `.md` to `issues/further_issues/completed/`

---

## Immediate Priority Order (Next Development Phase)

| Priority | Issue | Effort | Impact | Dependencies |
|----------|-------|--------|--------|-------------|
| P0 | **B1: Pass `llmAgent` to `MentorService`** — the single line that unlocks the entire agent framework | Very Low (1 line of code change + testing) | Transformative — activates 6 tools, cross-session memory, idle executor | None — everything is already wired |
| P1 | **B2: Wire `LessonAgentService.generateLesson()` into lesson scheduling and content pipeline** | Medium | High — creates actual LLM-driven lesson content | B1 (for agent-based generation via tool) |
| P2 | **M1: Focus Mode inline Q&A** — add inline practice directly in focus screen | Medium | High — addresses beta user complaint | None |
| P3 | **M5: Background lesson prep via IdleExecutor** | Medium | Medium — enables proactive content generation | B1 (IdleExecutor is part of LlmAgent) |
| P4 | **M3: Topic dependency visualizer** — directed graph / dependency tree | Medium | Medium — prerequisite visualization | None |
| P5 | **M2: Post-ingestion lesson generation** — `generateLessonFromSource()` in content pipeline | Low | Medium — ingestion produces lessons, not just questions | B2 (LessonAgentService already exists) |
| P6 | **M4: Deprecate redundant `VoiceController`** | Low | Low — code cleanup | None |
| P7 | **m4: Create `mentorServiceProvider`** for testability | Low | Low — test DX improvement | None |
| P8 | **m1/m2: Handwriting recognition + dedicated ASR** | High | Low-Medium | None (platform-specific work) |

---

## Summary of Round 3 Changes

| Category | Resolved (R2→R3) | New/Renamed | Still Open |
|----------|------------------|-------------|------------|
| BLOCKER | B2 (agent wired), B1 partially (lesson blocks) | **B1 (agent not passed to MentorService)** | 1 |
| | | **B2 (LessonAgentService unused)** | 1 |
| MAJOR | M5 (LLM task screen), M2 (scheduler deps) | M1 (no inline Q&A in focus — renamed from old M3) | 1 |
| | | M2 (no post-ingestion lesson gen — refined from old m3) | 1 |
| | | M3 (no topic visualizer — refined from old M4) | 1 |
| | | M4 (redundant VoiceController — new) | 1 |
| | | M5 (IdleExecutor empty — refined from old B2 sub-item) | 1 |
| MINOR | m1 (NextUp card), m2 (Lesson create) | m1-m4 as listed above | 4 |
| **Total** | **7 issues resolved** | **9 issues open** | **9** |

---

## Cross-References

- `issues/further_issues/open/lessons.md` — beta user lesson complaint (resolved by B1+B2)
- `issues/further_issues/open/focus_mode.md` — beta user focus mode complaint (resolved by M1)
- `issues/open/code_refactor_master.md` — redundant VoiceController (M4), mentor service provider (m4)
- `issues/open/dry_run_usability_validator.md` — topic dependency visualizer (M3)
- `issues/open/test_master.md` — missing behavioral assertions for provider tests
- `issues/completed/future_functionality_planner.md` — Round 2 analysis (baseline for this round)
