# Future Functionality Planner — Vision Gap Analysis (Round 6)

**Generated:** 2026-05-19
**Source:** Re-validation of `agent_must_read.md` vision against `lib/` implementation. Previous Round 5 at `issues/completed/future_functionality_planner.md` identified 10 open items (2 MAJOR, 8 MINOR). This round re-assesses progress and identifies **new** gaps discovered through deeper codebase exploration.

---

## Round 5 → Round 6 Progress

### Previously Open Items Status

| Round 5 Ref | Description | Previous Severity | Status | Evidence |
|---|---|---|---|---|
| **M7** | No TTS voice output during tutoring | MAJOR | ✅ **RESOLVED** | `ConversationManager._speakResponse()` called from `sendMessage()` (line 204-205); `TutorScreen` AppBar has voice toggle (line 560-569); `ChatBubble` has `onSpeak` per-bubble playback (line 848-849) |
| **M8** | Proactive mentor never initiates | MAJOR | ✅ **PARTIALLY RESOLVED** | `EngagementScheduler._sendMentorNudges()` exists, calls `MentorService.checkWellbeingAndGenerateNudges()`. But: `_isNotificationEnabled('mentor')` has **no matching switch case** (falls through to `true`), and `showMentorMessage` uses **hardcoded English strings** |
| **m1/m15** | `VoiceController` deprecated wrapper | MINOR | ❌ **STILL OPEN** | `voice_controller.dart` still on disk; `voice_bar.dart` still imports it |
| **m5** | `SessionTrackerScreen` subjectId='all' | MINOR | ❌ **STILL OPEN** | Hardcoded at line 172 |
| **m6** | No CI/CD pipeline | MINOR | ❌ **STILL OPEN** | No `.github/workflows/` |
| **m7** | No gallery button on upload screen | MINOR | ❌ **STILL OPEN** | No `Icons.photo_library` button |
| **m8** | DOCX/EPUB raw byte read → garbled | MINOR | ❌ **STILL OPEN — ESCALATED TO MAJOR** | Binary archive ingestion returns stub message "[DOCX (Word document — ZIP-based XML format)]..." — content is **silently lost**, not just garbled |
| **m9** | No topic dependency visualizer | MINOR | ❌ **STILL OPEN** | Zero progress |
| **m10** | No handwriting/ink recognition | MINOR | ❌ **STILL OPEN — ESCALATED TO MAJOR** | Canvas/graph drawing evaluation is stubbed (always returns "correct" if non-empty) |
| **m13** | Post-lesson practice → focus mode bridge | MINOR | ⚠️ **PARTIALLY RESOLVED** | `TutorScreen._startFocusModePractice()` (line 369) now navigates to `FocusTimerScreen` with `preselectedSubjectId`/`preselectedTopicId`. But: `_startPostLessonPractice()` still uses bare `AppRoutes.practiceSession` path. |
| **m14** | No idle lesson prep | MINOR | ⚠️ **PARTIALLY RESOLVED** | `TutorService.endLesson()` enqueues "Next topic lesson prep" task (line 276-307). But: creates a **stub lesson** with placeholder text `"Pre-generated lesson for {topicId}. Open to start learning."` — not an actual LLM-generated lesson. |

### Resolution Summary

| Category | Round 5 Open | Resolved | Partially Resolved | Still Open | New This Round |
|---|---|---|---|---|---|
| **MAJOR** | 2 | 1 | 1 | 0 | 10 |
| **MINOR** | 8 | 0 | 2 | 6 | 9 |
| **Total** | **10** | **1** | **3** | **6** | **19** |

---

## MAJOR — Feature is broken or misleading

### M9. Binary document ingestion (DOCX/EPUB/XLSX/PPTX) returns stub — content silently lost

**Severity: MAJOR** — When a student uploads a Word document, Excel spreadsheet, PowerPoint, or EPUB ebook, the document extractor detects it as a ZIP archive and returns a stub message like `"[DOCX (Word document — ZIP-based XML format)] File: ... — content is a binary archive, not plain text."` The content is **silently lost** with no error shown to the user. The pipeline continues (topic classification, question generation, etc.) with empty text, producing useless output.

**Root cause:** `document_extractor.dart` only handles PDFs natively. ZIP-based Office formats and EPUB are detected but have no real extraction logic. The files are NOT passed to the LLM for interpretation — the stub message IS the extracted text.

**Affected files:**
- `lib/features/ingestion/services/document_extractor.dart:96-97` — stub return for ZIP archives
- `lib/features/ingestion/services/content_pipeline.dart` — pipeline continues with empty text
- `lib/features/ingestion/presentation/upload_screen.dart` — no validation feedback for unsupported formats

**Acceptance criteria:**
1. DOCX files are parsed to plain text (extract XML from `/word/document.xml`, strip tags)
2. EPUB files are parsed to plain text (extract HTML from `.xhtml` files in the archive, strip tags)
3. XLSX/PPTX extract at minimum the text content (not formatting)
4. If parsing fails, the raw content or a meaningful error is surfaced to the user — not a silent stub
5. Pipeline pauses on extraction failure with an error state, rather than continuing with empty text

---

### M10. Canvas/graph/audio/file question types cannot be auto-graded

**Severity: MAJOR** — Four question types (`canvas`, `graphDrawing`, `fileUpload`, `audioRecording`) have stub evaluation that always returns "correct" if the answer is non-empty:

- `validateCanvasDrawing([])` — just checks `canvasData.isEmpty`, returns "correct" if any points drawn
- `validateGraphDrawing(answer)` — just base64-decodes and returns "correct" if JSON array is non-empty
- `validateFileUpload(answer)` — always returns "correct" if non-empty
- `validateAudioRecording(answer)` — always returns "correct" if non-empty

Students can create and answer these question types but **cannot receive meaningful feedback**. The markscheme is completely ignored in all 4 cases.

**Affected files:**
- `lib/core/services/answer_validation_service.dart:304-313`, `413-479` — stub validators
- `lib/features/practice/presentation/widgets/practice_session_question_card.dart:183-200` — canvas and graph drawing question cards exist but evaluation is stub
- `lib/features/questions/presentation/widgets/question_card_widget.dart:207-217` — rendering for these types exists but evaluation is stub

**Acceptance criteria:**
1. Canvas drawing is evaluated against a reference image or geometric description in the markscheme (e.g., "draw a right triangle with hypotenuse 5cm")
2. Graph drawing is evaluated against a reference function or data points
3. File upload evaluation supports at minimum LLM-based assessment (send upload content + markscheme to LLM for evaluation)
4. Audio recording evaluation supports at minimum LLM-based transcription comparison OR phoneme-level matching
5. All 4 types fall back to a "requires manual review" state when auto-evaluation cannot produce a confident result

---

### M11. `PlannerService` ignores injected dependencies on re-generation — breaks custom configuration

**Severity: MAJOR** — `PlannerService` creates a **new** `PersonalLearningPlanService` internally every time it generates a plan (lines 105-116 and 133-146 of `planner_service.dart`), discarding the one passed via constructor. This means:
- Constructor-injected `masteryService`, `repository`, etc. are ignored during plan generation
- Custom `PlanGenerationConfig` is lost on plan regeneration
- The internal re-creation accesses Hive directly rather than through dependency injection

**Affected files:**
- `lib/features/planner/services/planner_service.dart:105-146` — re-instantiates `PersonalLearningPlanService` with hardcoded config
- `lib/core/services/personal_learning_plan_service.dart` — already receives dependencies via constructor (would work if properly injected)
- `lib/features/planner/providers/planner_providers.dart` — provides `PlannerService` with all dependencies, but `PlannerService` ignores them

**Acceptance criteria:**
1. `PlannerService` uses the injected `PersonalLearningPlanService` (or its dependencies) rather than creating a new one
2. Plan regeneration preserves the original `PlanGenerationConfig`
3. A test verifies that injected dependencies are used (not overridden)

---

### M12. Agent tool calling uses brittle regex — will silently fail on non-standard LLM output

**Severity: MAJOR** — The LLM agent uses a regex-based tool parsing protocol (`TOOL_CALL: tool_name\nARGUMENTS: {"key": "value"}`) instead of OpenAI-compatible structured function calling. This will silently fail when the LLM:
- Wraps output in markdown code blocks
- Adds explanatory text before/after the tool call
- Uses slightly different formatting (extra spaces, different quote styles, etc.)
- Returns tool calls in a different order

Unlike structured function calling (which returns typed JSON), this regex approach **cannot** be fixed by prompt engineering alone — different models have different output biases.

**Affected files:**
- `lib/core/services/llm_agent/agent_loop.dart` — implements regex-based tool parsing
- `lib/core/services/llm_agent/agent_tool.dart` — tool definitions (6 tools)
- `lib/core/services/llm_agent/llm_agent.dart` — agent factory

**Acceptance criteria:**
1. Agent loop supports at minimum JSON-mode tool calling (model returns `{"tool": "...", "arguments": {...}}` in a JSON block) as a fallback parsing strategy
2. If regex and JSON parsing both fail, the error is surfaced to the agent loop (not silently skipped), and the agent can request clarification
3. Output wrapped in markdown code fences is correctly parsed
4. Regression: the original `TOOL_CALL:` format still works for models that consistently produce it

---

### M13. `IdleExecutor.startIdleMonitoring()` never called — background tasks not truly idle-based

**Severity: MAJOR** — The `IdleExecutor` class has a `startIdleMonitoring()` method (line 41) with a timer that polls for queued tasks every 30 seconds. However, **no code in the app calls this method**. The `enqueue()` method on `IdleExecutor` executes tasks immediately (line 83-87) rather than scheduling them for idle time. This means:
- Background tasks run immediately, potentially competing with user-facing operations
- The "when the app is idle" vision feature is completely unimplemented
- Tasks pile up without queue management or prioritization

The "Next topic lesson prep" task added in Round 5 runs immediately after the tutor session ends, potentially slowing down the UI during the post-lesson summary.

**Affected files:**
- `lib/core/services/llm_agent/idle_executor.dart:41` — `startIdleMonitoring()` defined but never called
- `lib/core/services/llm_agent/idle_executor.dart:83-87` — `enqueue()` executes synchronously
- `lib/features/teaching/services/tutor_service.dart:259-308` — enqueues tasks that run immediately
- `lib/core/services/llm_agent/llm_agent.dart` — creates `IdleExecutor` but never starts monitoring

**Acceptance criteria:**
1. `startIdleMonitoring()` is called during app initialization (or on a suitable lifecycle hook)
2. `enqueue()` adds tasks to the queue for idle-time execution rather than running them immediately
3. Idle detection uses a reasonable heuristic (e.g., no user input for X seconds, app in background, screen off)
4. Tasks execute one at a time with configurable concurrency
5. `LlmTaskManagerScreen` shows queued/idle/in-progress tasks

---

### M14. No handwriting/ink recognition — canvas/graph questions cannot be meaningfully evaluated

**Severity: MAJOR** — The "handwritten/drawn responses on canvas" and "vision-based interpretation of student work" requirements from the vision have zero implementation. The `CanvasDrawingWidget` and `GraphDrawingCanvasWidget` capture strokes as coordinate arrays, but:
- There is no handwriting-to-text conversion
- There is no geometric shape recognition (is this a circle? a right triangle?)
- There is no comparison against a reference answer
- Canvas answers are stored but never analyzed for correctness

**Affected files:**
- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` — drawing input only, no recognition
- `lib/features/questions/presentation/widgets/graph_drawing_canvas_widget.dart` — graph input only, no recognition
- `lib/core/services/answer_validation_service.dart:413-463` — stub evaluation
- `lib/features/practice/services/question_type_localizer.dart:10-16` — types exist but evaluation doesn't

**Acceptance criteria:**
1. Handwritten text in canvas drawings is converted to text via ML Kit or LLM vision API
2. Geometric shapes (circles, triangles, lines, angles) can be detected and measured
3. Graph drawings can be evaluated against a reference function (e.g., "does this line have slope 2?")
4. When confidence is low, fall back to "requires manual review" with the drawing data preserved
5. The evaluation is integrated into the practice session flow (not a separate tool)

---

### M15. `QuestionVariantGenerator` never wired into UI — variant generation is dead code

**Severity: MAJOR** — `QuestionVariantGenerator` (154 lines) is fully implemented and compiles cleanly. It can generate semantic variants of questions via LLM. However, **no UI anywhere exposes this functionality**. There is no "Generate Variant" button on the question bank, no variant generation in practice sessions, and no entry point in any screen.

The vision explicitly says questions should be "expanded through generated variants" — this feature exists as infrastructure but is invisible to the student.

**Affected files:**
- `lib/features/questions/services/question_variant_generator.dart` — entire class (dead code from user perspective)
- `lib/features/questions/presentation/question_bank_screen.dart` — no "Generate Variant" UI
- `lib/features/questions/providers/question_providers.dart` — no `QuestionVariantGenerator` provider
- `lib/features/practice/services/practice_data_service.dart` — no variant generation during practice

**Acceptance criteria:**
1. "Generate Variant" button appears on question detail view in question bank
2. Generated variants appear in the question list with a "variant of {original}" label
3. Practice sessions can optionally include variants of previously-seen questions
4. Students can request a variant during practice if they find the current question too easy/hard
5. Variants are stored with a `variantOfId` link to the source question for analytics

---

### M16. FSRS spaced repetition algorithm stubbed (`useFSRS` parameter accepted but ignored)

**Severity: MAJOR** — The `SpacedRepetitionEngine` accepts a `useFSRS` parameter (line 89) but only SM-2 logic is implemented. When `useFSRS` is `true`, no FSRS computation occurs. The `scheduleReview` method (line 136) only runs SM-2 scheduling regardless of the flag.

Additionally, the `SpacedRepetitionEngine` is internally duplicated:
- `spaced_repetition_engine.dart` — the actual engine (SM-2 only)
- `sr_data_codec.dart` — serialization codec (NEVER imported — dead code)
- `spaced_repetition_service.dart:23-63` — `SpacedRepetitionQueries` static class (NEVER imported, with TODO to remove)

**Affected files:**
- `lib/features/practice/services/spaced_repetition_engine.dart:82-89` — `useFSRS` accepted but never branches on it
- `lib/features/practice/utils/sr_data_codec.dart` — entire file (dead code)
- `lib/features/practice/services/spaced_repetition_service.dart:23-63` — `SpacedRepetitionQueries` (dead code)

**Acceptance criteria:**
1. Remove `sr_data_codec.dart` (confirm no imports via `rg`)
2. Remove `SpacedRepetitionQueries` (confirm no imports via `rg`)
3. Implement FSRS algorithm or remove the `useFSRS` parameter entirely
4. If FSRS is implemented, provide a migration path for existing SM-2 data
5. Add a setting to choose between SM-2 and FSRS

---

### M17. Agent memory uses shared Hive box with prefixed keys — risk of data corruption

**Severity: MAJOR** — `AgentMemoryStore` stores facts, session summaries, and student profiles in the **same Hive box** as profile data (`HiveBoxNames.profile`), using prefixed keys (`agent_fact_`, `agent_session_`, `agent_profile_`). This design:
- Pollutes the profile box with agent data
- Risks key collisions if profile keys ever start with these prefixes
- Makes it impossible to clear agent memory independently of profile data
- Creates coupling between agent and profile storage schemas

**Affected files:**
- `lib/core/services/llm_agent/agent_memory.dart` — uses `HiveBoxNames.profile` box for all agent data

**Acceptance criteria:**
1. Agent memory uses its own dedicated Hive box (`AgentMemoryStore` creates/opens `'agent_memory'` box)
2. Data migration from old prefixed keys to new box (run once on first access)
3. Profile box read/write operations are preserved (no data loss during migration)
4. `AgentMemoryStore` can be cleared independently of profile data

---

### M18. `CalendarViewWidget` is basic month grid — no scheduling UX beyond dots

**Severity: MAJOR** — The planner's Calendar tab shows a basic month grid with colored dots for milestones and study days. It does not show:
- Scheduled lessons as actual events on the calendar
- Week view or agenda view
- Drag-to-create or drag-to-reschedule
- Time-of-day visualization for scheduled lessons
- Integration with the lesson booking sheet

The beta user complaint (`issues/further_issues/open/lessons.md`) specifically asks for a "calendar view (time)" like Preply — a view where students can see their lesson schedule on a calendar.

**Affected files:**
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` — basic month grid only
- `lib/features/planner/presentation/screens/planner_screen.dart` — Calendar tab with month grid
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — bottom sheet for scheduling (exists but not visually integrated with calendar)

**Acceptance criteria:**
1. Calendar view shows scheduled lessons as actual event blocks (with subject color, time, topic)
2. Week view with time slots (8:00 AM - 8:00 PM) for daily planning
3. Drag-to-reschedule existing lessons (long-press event → drop on new time slot)
4. Tap on empty time slot → opens lesson booking sheet with that time pre-filled
5. Calendar switches between month/week/day views
6. Agenda list view below the calendar showing upcoming lessons as a list

---

### M19. `PersonalLearningPlanService` in wrong architectural layer — core depends on feature data

**Severity: MAJOR** — `PersonalLearningPlanService` lives in `lib/core/services/` but depends on data models and repositories from `lib/features/planner/data/`. This is a layering violation:
- Core services should only depend on other core modules or shared data
- Feature data models should NOT be imported by core services
- Creates risk of circular dependencies as the planner feature grows
- Violates the feature-first architecture pattern

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart` — imports from `features/planner/data/models/`
- `lib/features/planner/data/models/personal_learning_plan.dart` — feature model depended on by core
- `lib/features/planner/services/planner_service.dart` — creates internal `PersonalLearningPlanService` (compounds the issue)

**Acceptance criteria:**
1. `PersonalLearningPlanService` is moved to `lib/features/planner/services/`
2. Core modules that reference it are updated to use the new location
3. Any truly shared types are extracted to `lib/core/data/models/` or a shared data module
4. `dart analyze` reports zero new issues after the move

---

### M20. `ConversationManager.generateLessonPlan` silently falls back to default plan on LLM failure

**Severity: MAJOR** — When `_generateLessonPlanViaLlm()` fails (LLM error, timeout, empty response), the system silently falls back to `LessonPlan.defaultPlan()` — a hardcoded plan with generic structure and no subject-specific content. The student receives a lesson plan that has no relation to their actual topic. The failure is logged but never surfaced.

**Affected files:**
- `lib/features/teaching/services/conversation_manager.dart` — `generateLessonPlan()` method with default fallback

**Acceptance criteria:**
1. When LLM-based plan generation fails, the student sees a clear error message with options: "Retry" / "Use generic plan" / "Cancel lesson"
2. The generic plan fallback requires explicit student consent (not silent)
3. Error is tracked in `LlmTaskManager` for visibility
4. Repeated failures trigger a settings suggestion (try different model / check connectivity)

---

## MINOR — Code quality, UX friction, incomplete polish

### m16. `VoiceController` still on disk with `@Deprecated` annotation — carried from Round 4 m1

**Severity: MINOR** — Same finding as Round 4 m1 and Round 5 m15. The deprecated wrapper remains importable.

**Affected files:**
- `lib/features/teaching/services/voice_controller.dart` — entire file
- `lib/features/teaching/presentation/widgets/voice_bar.dart:4` — imports `VoiceController`
- `lib/features/teaching/providers/teaching_providers.dart:20` — provides `voiceServiceProvider_`

**Acceptance criteria:** Same as Round 5: delete file, update imports, use core `voiceServiceProvider` directly.

---

### m17. `SessionTrackerScreen` subjectId hardcoded to `'all'` — carried from Round 4 m5

**Severity: MINOR** — `session_tracker_screen.dart:172` still uses `subjectId: 'all'`. Per-subject tracking cannot be filtered.

---

### m18. No CI/CD pipeline — carried from Round 4 m6

**Severity: MINOR** — No `.github/workflows/` files. Quality gating requires manual commands.

---

### m19. No gallery button on upload screen — carried from Round 4 m7

**Severity: MINOR** — `upload_screen.dart` has Camera and File buttons but no gallery/library button.

---

### m20. No topic dependency visualizer — carried from Round 4 m9

**Severity: MINOR** — No graphical dependency tree for topics. The data exists (prerequisites in topic model) but no visualization.

---

### m21. Mentor nudge notifications use hardcoded English strings

**Severity: MINOR** — `engagement_scheduler.dart:133-136` uses `'Mentor Check-In'` as hardcoded title and the nudge body is passed raw (untranslated). This means Spanish (and other locale) users see English notification titles.

**Affected files:**
- `lib/core/services/engagement_scheduler.dart:133-136` — hardcoded `'Mentor Check-In'`

**Acceptance criteria:**
1. Mentor notification title uses `AppLocalizations` (e.g., `l10n.mentorCheckIn`)
2. Mentor notification body either uses localized strings or is pre-localized in the nudge content

---

### m22. `_checkWellbeingInner` is 112 lines with 5+ levels of nesting

**Severity: MINOR** — The method in `mentor_service.dart` (approximately lines 422-538) has deeply nested conditionals for overwork check, late-night check, at-risk questions, consecutive study days, and rate limiting.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart` — `_checkWellbeingInner` method

**Acceptance criteria:**
1. Each wellbeing check (overwork, late-night, at-risk, streak, inactivity) is extracted to a separate method
2. Nesting depth never exceeds 3 levels
3. Existing behavior is preserved (no functional changes)

---

### m23. `_buildContextPrompt` is 109 lines of imperative string building

**Severity: MINOR** — The mentor's `_buildContextPrompt` method builds a large context string imperatively, mixing raw data access with formatting. Hard to test and modify.

**Affected files:**
- `lib/features/mentor/services/mentor_service.dart` — `_buildContextPrompt` method

**Acceptance criteria:**
1. Each data section (stats, weak topics, plan, schedule, adherence) is built by a separate method
2. Each method returns typed data rather than raw strings where feasible

---

### m24. No weekly digest scheduling — `getWeeklyDigest` exists but never called

**Severity: MINOR** — `EngagementScheduler` has a `getWeeklyDigest` method that prepares a summary of the past week, but no timer or trigger calls it.

**Affected files:**
- `lib/core/services/engagement_scheduler.dart` — `getWeeklyDigest` method defined but no scheduling

**Acceptance criteria:**
1. Weekly digest is scheduled (e.g., every Monday at 9 AM) and sent as a notification
2. Digest includes: study hours, topics covered, weak areas, upcoming lessons, streak info

---

### m25. `LessonSessionService` is misnamed — works with `Session`, not `Lesson`

**Severity: MINOR** — `LessonSessionService` queries `Session` objects (tutoring sessions, focus timer sessions) but its name suggests it works with `Lesson` models (AI-generated lesson blocks). The `getCompletionRate()` and `getRemainingLessonCount()` methods operate on `Session` objects.

**Affected files:**
- `lib/features/lessons/services/lesson_session_service.dart`

**Acceptance criteria:**
1. Rename to `SessionQueryService` or split into `LessonQueryService` (for Lesson models) and `SessionQueryService` (for Session models)
2. Update all references

---

### m26. `ActionExecutor` handles only 3 action types

**Severity: MINOR** — `ActionExecutor` in `features/planner/services/` only handles `'create_plan'`, `'reschedule'`, and `'schedule_lesson'`. It's a thin wrapper that barely justifies its own class.

**Affected files:**
- `lib/features/planner/services/action_executor.dart`

**Acceptance criteria:**
1. Add more action types or document the limitation
2. Consider merging into `PlannerService` if it remains thin

---

### m27. `Session` model overloading — same type for focus, practice, tutoring, and lesson sessions

**Severity: MINOR** — The `Session` model uses `SessionType` enum to distinguish modes, but this creates confusion: `getCompletionRate()` on `SessionQueryService` blends analytics across fundamentally different session types.

---

### m28. `TutorService` creates stub lesson for "Next topic lesson prep"

**Severity: MINOR** — The background task at `tutor_service.dart:276-307` creates a `Lesson` with a single `LessonBlock` containing placeholder text. This isn't an actual LLM-generated lesson — it's a placeholder that says "Pre-generated lesson for {topicId}. Open to start learning."

**Affected files:**
- `lib/features/teaching/services/tutor_service.dart:283-301` — stub lesson creation

**Acceptance criteria:**
1. The background task calls `ConversationManager.generateLessonPlan()` or `LessonAgentService.generateLesson()` to produce real content
2. The generated lesson has actual blocks (text, quiz, examples, etc.)
3. If LLM generation fails, the placeholder is used as a fallback with a logged warning

---

### m29. `ConversationManager.generateLessonPlan` fallback swallows LLM failure

**Severity: MINOR** — Same as M20 but noted separately as the silent-fallback pattern. The fallback on `LessonPlan.defaultPlan()` at line 318 hides LLM failures from both users and diagnostics.

---

### m30. `_transcribeWithLlm` sends raw file bytes as base64 to LLM for audio/video — no Whisper/ASR

**Severity: MINOR** — The `TranscriptionExtractor._transcribeWithLlm()` method sends raw base64 content to the LLM for transcription. For audio files, there is no Whisper API integration or local ASR. The LLM is asked to transcribe audio from base64-encoded bytes, which most models cannot do effectively. YouTube videos fall back to LLM-based "transcription" from page metadata when the YouTube API transcript is unavailable.

**Affected files:**
- `lib/core/data/extraction/transcription_extractor.dart:286-346` — `_transcribeWithLlm()` sends raw content to LLM
- `lib/core/data/extraction/transcription_extractor.dart:48-76` — `transcribeAudio()` always falls through to LLM for non-file URLs

**Acceptance criteria:**
1. Add Whisper API integration (OpenAI Whisper or local whisper.cpp) as an optional ASR backend
2. Fall back to LLM-only when Whisper is unavailable
3. YouTube transcript fetching is prioritized (existing implementation is adequate)

---

### m31. Post-lesson "Practice Mode" still uses bare `PracticeSession` route

**Severity: MINOR** — `tutor_screen.dart` has two post-lesson practice buttons:
- "Quick Practice (Focus)" → navigates to `FocusTimerScreen` ✅ (uses focus mode)
- "Practice Mode" → navigates to `AppRoutes.practiceSession` ❌ (bypasses focus mode)

The "Practice Mode" button should also use `FocusTimerScreen` for consistency, or the distinction should be clearly communicated to the user.

**Affected files:**
- `lib/features/teaching/presentation/tutor_screen.dart:383-391` — `_startPostLessonPractice()` still uses `AppRoutes.practiceSession`

**Acceptance criteria:**
1. Both post-lesson practice options are clearly distinguished (e.g., "15-min Focus Session" vs "Full Practice Session")
2. Or "Practice Mode" also opens `FocusTimerScreen` with a longer default duration

---

## Beta User Issue Resolution — Updated Status

### File: `issues/further_issues/open/lessons.md`

| Original Complaint | Verdict | Remaining Gaps |
|---|---|---|
| "Make the lessons like preply" (calendar view with time) | ❌ NOT RESOLVED | M18: Calendar view is basic month grid only |
| "Helper are actually useful can execute tools" | ✅ RESOLVED | 6 tools in mentor agent, agent loop wired |
| "When app is idle, use api to make lesson plan" | ❌ NOT RESOLVED | M13: `IdleExecutor.startIdleMonitoring()` never called |
| "Lessons prepared from llm agents" | ✅ RESOLVED | LessonAgentService generates real LLM content |
| "LLM is not just a fucking chatbot" — must continue to help make materials | ✅ RESOLVED | Pervasive LLM usage across all features |
| "Agents must have long term memory" | ✅ RESOLVED | AgentMemoryStore with Hive-backed memory |
| "Do a full audit to useless and lazily coded" | ⚠️ PARTIAL | m16-m31 identify 16 lazily-coded/ineffective components |

**Remaining blockers to close `lessons.md`:**
1. M18: Calendar view upgrade (month grid → week/day/agenda with event rendering)
2. M13: `IdleExecutor` monitoring startup for true idle-time lesson generation

### File: `issues/further_issues/open/focus_mode.md`

| Original Complaint | Verdict | Remaining Gaps |
|---|---|---|
| "Focus mode should be a place where student can practice questions from different subjects after lessons" | ⚠️ PARTIALLY RESOLVED | Quick Practice → FocusTimerScreen works. But "Practice Mode" still bypasses focus mode. |
| "Make focus mode actually useful" | ✅ RESOLVED | Pomodoro timer, inline practice, per-subject tracking all exist |

**Remaining blockers to close `focus_mode.md`:**
1. m31: "Practice Mode" post-lesson button should also integrate with focus mode

### Process for closing further_issues files

When ALL criteria above are met:
1. Move `issues/further_issues/open/lessons.md` → `issues/further_issues/completed/lessons.md`
2. Move `issues/further_issues/open/focus_mode.md` → `issues/further_issues/completed/focus_mode.md`
3. Add a note in CHANGELOG acknowledging the resolution

---

## Immediate Priority Order (Next Development Phase)

### Phase 1: Unbreak Ingestion & Evaluation (P0)

| # | Issue | Severity | Effort | Impact |
|---|---|---|---|---|
| 1 | **M9: Binary document ingestion stub** | MAJOR | Medium — add ZIP/XML parsing for DOCX/EPUB/XLSX | HIGH — students can't upload Office documents |
| 2 | **M10: Canvas/graph/audio/file evaluation stub** | MAJOR | High — requires evaluation strategy per type | HIGH — 4 question types cannot be graded |

### Phase 2: Agent & Infrastructure Fixes (P1)

| # | Issue | Severity | Effort | Impact |
|---|---|---|---|---|
| 3 | **M12: Agent tool calling regex** | MAJOR | Medium — add JSON fallback parsing | HIGH — prevents silent agent failures |
| 4 | **M13: IdleExecutor monitoring never called** | MAJOR | Low — wire `startIdleMonitoring()` into app init | HIGH — enables background lesson prep |
| 5 | **M11: PlannerService ignores injected deps** | MAJOR | Low — remove internal re-instantiation | MEDIUM — fixes plan regeneration config loss |
| 6 | **M17: Agent memory shares Hive box** | MAJOR | Low — create dedicated box + migrate | MEDIUM — prevents potential data corruption |

### Phase 3: Question & Practice Improvements (P1)

| # | Issue | Severity | Effort | Impact |
|---|---|---|---|---|
| 7 | **M15: QuestionVariantGenerator unused** | MAJOR | Low — add UI button + provider wire-up | MEDIUM — enables question expansion |
| 8 | **M16: FSRS stubbed + dead code** | MAJOR | Medium — implement FSRS or remove param | MEDIUM — better spaced repetition |
| 9 | **M14: Handwriting/ink recognition** | MAJOR | High — requires ML Kit or LLM vision | HIGH — unlocks canvas/graph evaluation |

### Phase 4: Scheduling & Calendar UX (P2)

| # | Issue | Severity | Effort | Impact |
|---|---|---|---|---|
| 10 | **M18: Calendar view upgrade** | MAJOR | High — week/agenda views + drag-reschedule | HIGH — directly addresses lessons.md complaint |

### Phase 5: Architecture & Cleanup (P2-P3)

| # | Issue | Severity | Effort | Impact |
|---|---|---|---|---|
| 11 | **M19: PLPService in wrong layer** | MAJOR | Medium — move + update imports | MEDIUM — fixes layering violation |
| 12 | **M20: Silent lesson plan fallback** | MAJOR | Low — surface error to user with retry options | MEDIUM — prevents silent content gaps |
| 13 | **m22/m23: Mentor service refactor** | MINOR | Medium — extract methods | LOW — code quality |
| 14 | **m24: Weekly digest scheduling** | MINOR | Low — add timer | LOW — engagement improvement |
| 15 | **m25: Rename LessonSessionService** | MINOR | Low — rename + update references | LOW — naming clarity |
| 16 | **m28: Stub lesson → real LLM content** | MINOR | Medium — use LessonAgentService in background task | MEDIUM — addresses idle lesson prep quality |
| 17 | **m30: Whisper ASR integration** | MINOR | Medium — add Whisper API option | MEDIUM — audio transcription quality |

### Phase 6: Polish & Tooling (P3)

| # | Issue | Severity | Effort | Impact |
|---|---|---|---|---|
| 18 | **m16: Remove VoiceController** | MINOR | Low — delete + update 2 imports | LOW — cleanup |
| 19 | **m17: SessionTracker subjectId fix** | MINOR | Low — one-line change | LOW |
| 20 | **m18: CI/CD pipeline** | MINOR | Medium — GitHub Actions config | MEDIUM — quality gating |
| 21 | **m19: Gallery button** | MINOR | Low — add Icons.photo_library | LOW |
| 22 | **m20: Topic dependency viz** | MINOR | High — custom painter | LOW — nice-to-have |
| 23 | **m21: Mentor nudge i18n** | MINOR | Low — use l10n strings | LOW |
| 24 | **m31: Practice Mode → focus mode** | MINOR | Low — change nav target | LOW |

---

## Cross-References

- `issues/completed/future_functionality_planner.md` — Round 5 analysis (10 open items baseline)
- `issues/further_issues/open/lessons.md` — beta user lesson complaint (blocked on M13, M18)
- `issues/further_issues/open/focus_mode.md` — beta user focus mode complaint (blocked on m31)
- `issues/open/ui_ux_master.md` — BLOCKER B1 (dart:io on web) overlaps with ingestion UX
- `issues/open/code_refactor_master.md` — M1 (Deprecated Markscheme) overlaps with M10 evaluation stubs
- `issues/open/dry_run_usability_validator.md` — BLOCKER B1-B4 (AI provider failures) out of scope for this planner
