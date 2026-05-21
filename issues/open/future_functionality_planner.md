# Future Functionality Planner — Vision vs Implementation Gap Analysis (v5)

**Generated:** 2026-05-21
**Source:** `agent_must_read.md` (product vision) vs comprehensive codebase audit
**Input from beta testers:** `issues/further_issues/open/lessons.md`, `issues/further_issues/open/focus_mode.md`
**Open dry-run issues incorporated:** All 6 files in `issues/open/`

---

## CORE PRIORITY: Further Issues (Beta Tester Feedback)

The beta tester feedback in `further_issues/open/` is unambiguous and angry. These must be resolved **first** before any other work, as they represent the core product promise failing.

Both issues are consolidated here as BLOCKER items. When finished, remove files from `further_issues/open/` and acknowledge in `issues/further_issues/completed/`.

---

## BLOCKER — App crashes or user cannot proceed

### B-FI1: Lessons Are Fundamentally Broken (further_issues/open/lessons.md)

**Source:** `issues/further_issues/open/lessons.md`
**Severity:** BLOCKER

**Problem:** The complete lesson experience is not what was envisioned:

1. **No calendar scheduling dashboard** — Lessons are accessed via topic list → detail screen → tutor mode. No Preply-style calendar view where you see your lesson slots on a calendar with time, subject, and prep status.

2. **Lesson block rendering is plain text** — `LessonBlockCard` renders everything as `Text(widget.block.content)`. Slides, quizzes, exercises — all plain text. No markdown, LaTeX, code blocks, images, or rich formatting.

3. **LessonAgentService is not a real agent** — It calls `_llmService.chat()` directly. The `LlmAgent` + `AgentLoop` + `ToolRegistry` infrastructure exists (used by `MentorService`) but `LessonAgentService` ignores it entirely. No tools, no memory, no structured output pipeline.

4. **No background lesson preparation** — `IdleExecutor` (109 lines) runs only foreground. When a lesson is scheduled, no background task generates the lesson materials ahead of time. The student must wait for generation when they tap "Start."

5. **Scheduling vs lesson plan are conflated** — `PlannerService.scheduleLesson()` creates a Session and eagerly generates a Lesson, but there's no separate "plan a schedule" step vs "generate materials" step. The vision calls for scheduling first, then agent-preparation of materials as a separate step.

6. **Agent tools are mentor-only** — 6 registered tools (`schedule_lesson`, `create_plan`, `search_questions`, `get_student_stats`, `generate_lesson_blocks`, `get_weak_topics`) exist under `mentor/services/tools/`. The lesson agent never uses them. No tools are shared with lesson generation.

7. **No long-term memory in lessons** — `AgentMemoryStore` is used by mentor but not by `LessonAgentService`. Each lesson generation is from scratch — no student profile, no history, no prior session context.

8. **Previous session doesn't inform current lesson** — `LongTermMemory` and `ConversationMemory` exist but are not integrated into lesson generation.

**Acceptance Criteria:**
- [ ] **Dashboard shows a calendar view with lesson time slots** (subject + topic + duration + prep status), not just milestone dots
- [ ] Calendar slots are tappable → launches lesson detail or tutor screen if materials are ready
- [ ] **`LessonBlock` gains rich content**: markdown via `flutter_markdown`, LaTeX via `flutter_math_fork`, image URLs, code blocks with syntax highlighting
- [ ] `LessonBlockCard` renders rich content instead of plain `Text()` for all block types (slides, quizzes, exercises, examples, summaries)
- [ ] Full-screen slide mode renders rich content, not plain text
- [ ] **`LessonAgentService` refactored to use `LlmAgent`** with `AgentLoop` + `ToolRegistry` + `AgentMemoryStore`
- [ ] Lesson-prep tools registered (or shared from mentor's tool registry): `getStudentStats`, `getWeakTopics`, `searchQuestions`, `getSyllabusProgress`, `getAtRiskQuestions`
- [ ] **Background lesson prep**: When a session is scheduled, `IdleExecutor` enqueues `LessonAgentService.generateLesson()` as a background task
- [ ] Lesson prep status visible in calendar (⏳ generating, ✅ ready, ❌ failed)
- [ ] **IdleExecutor upgraded from Dart Timer to `workmanager`** for persistent background scheduling that survives app restart (also powers engagement nudges)
- [ ] **Long-term memory context injected** into lesson generation prompts (student's prior performance, weak topics, preferred learning style)
- [ ] Exercises generated during tutor conversations are **persisted to the question bank** for later practice

**Affected files:**
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — plain Text() rendering
- `lib/features/lessons/data/models/lesson_block_model.dart` — no richContent field
- `lib/features/lessons/services/lesson_agent_service.dart` — no LlmAgent integration
- `lib/features/planner/presentation/widgets/calendar_view_widget.dart` — shows milestones, not lesson slots
- `lib/features/teaching/services/conversation_manager.dart` — exercises not persisted to question bank
- `lib/core/services/llm_agent/idle_executor.dart` — foreground-only Dart Timer
- `lib/core/services/engagement_scheduler.dart` — foreground-only Dart Timer
- `lib/features/mentor/services/tools/` — tools not accessible to lesson agent
- `pubspec.yaml` — needs `flutter_markdown`, `flutter_math_fork`, `flutter_workmanager`

---

### B-FI2: Focus Mode Is Misaligned (further_issues/open/focus_mode.md)

**Source:** `issues/further_issues/open/focus_mode.md`
**Severity:** BLOCKER

**Problem:** The beta tester explicitly says focus mode is "fucking useless." The current implementation:

1. **Timer-centric session model** — Even though study hub is default, practice is always behind a timer/session paradigm. The beta tester wants to just browse and answer questions across subjects without timer friction.

2. **No browse-and-practice mode** — `FocusTimerScreen` requires a session to start. `InlinePracticeWidget` only activates mid-session. No "open the app → see questions → answer" flow.

3. **Session type hidden in code** — `FocusSessionType` is set via internal logic (`_sessionType`), not via a visible UX picker. The user can't choose "Weak Area Attack" or "Quick Practice" as a visible option.

4. **Post-lesson practice navigates to timer** — `TutorScreen.summaryDialog` practice buttons navigate to `FocusTimerScreen` with timer mode. The user wants practice, not a timer.

5. **1374-line monolith** — `FocusTimerScreen` mixes timer logic, practice hub UI, onboarding, analytics, subject picker, and routing. Impossible to iterate on UX safely.

**Acceptance Criteria:**
- [ ] **Add "Free Practice" mode** — browse and answer questions from selected subjects without starting a timer session. Visible as a primary card on the focus mode screen.
- [ ] **Session type selector is a visible card row**: Spaced Repetition / Weak Area Attack / Quick Practice / Free Practice
- [ ] Post-lesson summary dialog navigates to practice hub with subject+topic pre-loaded, NOT to timer
- [ ] `FocusTimerScreen` split into thin orchestrator + sub-widgets: `StudyHubWidget`, `ActiveFocusSessionWidget`, `PracticeExplorerWidget`
- [ ] Due question counts shown per subject on the main practice hub
- [ ] "Practice without timer" flow: select subjects → see questions → answer → see results → repeat

**Affected files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart` (1470 lines) — monolith, timer-centric
- `lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart` — only accessible mid-timer
- `lib/features/teaching/presentation/tutor_screen.dart` — summary dialog practice buttons target timer
- `lib/features/focus_mode/providers/focus_mode_providers.dart` — may need new providers for free practice

---

### DR-B1: AI Task Monitor Shows Stale Data; Never Updates (dry_run_usability_validator.md M5)

**Source:** `issues/open/dry_run_usability_validator.md` M5
**Severity:** BLOCKER — User cannot trust task monitoring

**Problem:** `_AiTaskMonitorTile` reads `llmTaskManagerProvider` once in `initState()` via `ref.read()`. Counts are frozen forever. Starting a content upload or lesson prep after navigating to Settings shows "0 active tasks" indefinitely.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:1981-2017` — uses `ref.read()` in `initState()`, not `ref.watch()` in `build()`

**Acceptance Criteria:**
- [ ] Replace `ref.read(llmTaskManagerProvider)` with `ref.watch(llmTaskManagerProvider)` inside `build()`
- [ ] Remove `_updateCounts()` from `initState()`, compute counts directly from watched state
- [ ] Remove stale `_activeCount`/`_failedCount` instance variables
- [ ] Verify: starting a content upload → Settings → badge/tile shows live active task count

---

### DR-B2: EngagementScheduler Uses Stale Settings Reference (dry_run_usability_validator.md M4)

**Source:** `issues/open/dry_run_usability_validator.md` M4
**Severity:** BLOCKER — Notification toggles are ignored until app restart

**Problem:** `EngagementScheduler._settingsBox` is set once in constructor. `updateSettings()` exists but is never called from production. Toggling "Overwork Alerts" OFF doesn't stop overwork nudges until restart.

**Affected files:**
- `lib/core/services/engagement_scheduler.dart:88` — stale `_settingsBox` reference
- `lib/core/providers/app_providers.dart:53-80` — never listens to `settingsProvider`

**Acceptance Criteria:**
- [ ] In `engagementSchedulerProvider`, add `ref.listen(settingsProvider, ...)` that calls `scheduler.updateSettings(newSettings)`
- [ ] Verify: toggle notification preference → immediate effect on `_isNotificationEnabled()`
- [ ] "Check Nudges Now" respects current toggle state

---

### DR-B3: 7+ Settings Keys Persisted via Direct `box.put()` Bypassing Repository (dry_run_usability_validator.md M6+M7)

**Source:** `issues/open/dry_run_usability_validator.md` M6, M7
**Severity:** BLOCKER — Settings values are orphaned from the SettingsBox model

**Problem:** 7+ Hive keys (`dailyCapMinutes`, `srMinIntervalDays`, `srMaxIntervalDays`, `srDailyReviewLimit`, `autoBackupIntervalDays`, `lastAutoBackupDate`, `lastAutoBackupPath`, `mentorCheckinFrequencyDays`, `defaultScheduleDuration`, `defaultTeachingDuration`) are written via `Hive.box(HiveBoxNames.settings).put(key, value)` instead of `SettingsRepository.updateSettings()`. These values are invisible to `settingsProvider` and any refactoring will silently drop them.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:662,806,737,103-105`
- `lib/features/settings/data/models/settings_box.dart` — missing fields
- `lib/features/settings/data/repositories/settings_repository.dart` — reads/writes unified JSON

**Acceptance Criteria:**
- [ ] Add all missing fields to `SettingsBox` model with defaults and null handling
- [ ] Update `SettingsRepository` to read/write them as part of unified JSON `'settings'` key
- [ ] Replace all `box.put(key, value)` with `settingsProvider.notifier.updateSettings(SettingsUpdate(...))`
- [ ] Remove `_getSrValue()`/`_setSrValue()` helpers; use `settings.field` directly
- [ ] Audited all SR config consumers to ensure they read from unified location
- [ ] Verify migration doesn't drop existing values

---

### DR-B4: No Mechanism to Flag/Report Incorrect AI Content (dry_run_math_scientific M13)

**Source:** `issues/open/dry_run_result_math_scientific_canvas_validation.md` Step 13
**Severity:** BLOCKER — AI content has no trust mechanism

**Problem:** The vision (`agent_must_read.md:9`) explicitly says "AI-generated content should not be blindly trusted; correctness, consistency, and usefulness should be continuously validated." There is no mechanism to flag incorrect content — no button, no feedback, no UI. Content validation in `content_pipeline.dart:396-405` is an empty stub.

**Additionally from M14-M15:**
- No `isValidated`, `needsReview`, `verifiedBy`, `trustScore` fields on `QuestionModel`
- No `GeneratedBy` indicator distinguishing AI vs manual vs hybrid
- `_isValidGeneratedQuestion()` only does structural/schema validation — no LLM re-check

**Affected files:**
- `lib/core/data/models/question_model.dart:9-91` — no trust/verification fields
- `lib/features/ingestion/services/content_pipeline.dart:396-405` — `_validateGeneratedQuestions` is stub
- `lib/features/ingestion/services/content_pipeline.dart:657-701` — `_isValidGeneratedQuestion` is structural only

**Acceptance Criteria:**
- [ ] Add `isValidated`, `needsReview`, `verifiedBy`, `reviewedAt`, `generatedBy` fields to `QuestionModel`
- [ ] Add "Report incorrect" button on question cards (practice session, question bank)
- [ ] Report feedback persisted to a `ContentFeedbackRepository`
- [ ] Content pipeline actual LLM re-check for generated questions
- [ ] GeneratedBy indicator visible: AI-generated / Manual / Hybrid
- [ ] Settings toggle: "Show AI content trust indicators"

---

## MAJOR — Feature is broken, misleading, or contradicts the vision

### DR-M1: Spaced Repetition Settings Use Hardcoded English Strings (dry_run_usability M1)

**Source:** `issues/open/dry_run_usability_validator.md` M1
**Severity:** MAJOR — Breaks l10n for non-English users

**Problem:** Lines 297-303 of `settings_screen.dart` use raw string literals `'Spaced Repetition'`, `'Min interval'`, `'Max interval'` while every other section uses `l10n.*` keys. The l10n keys exist but are unused.

**Affected file:**
- `lib/features/settings/presentation/settings_screen.dart:297-302`

**Acceptance Criteria:**
- [ ] Replace with `l10n.spacedRepetition`, `l10n.srMinInterval`, `l10n.srMaxInterval`
- [ ] Verify render in both English and Spanish

---

### DR-M2: Language Change Committed Prematurely (dry_run_usability M2, m4)

**Source:** `issues/open/dry_run_usability_validator.md` M2, m4
**Severity:** MAJOR — Unsaved changes + inconsistent UX

**Problem:** Language change in Profile screen immediately mutates `localeProvider` (line 489) but only persists on explicit "Save". If user navigates away without saving, in-memory locale changes but profile language reverts on restart. No `PopScope` to warn.

**Affected file:**
- `lib/features/settings/presentation/profile_screen.dart:486-491`

**Acceptance Criteria:**
- [ ] Language change only commits inside `_saveProfile()` after persistence succeeds
- [ ] OR: Commit immediately AND persist immediately, with revert capability
- [ ] Add `PopScope` with unsaved-changes warning when language differs from persisted value

---

### DR-M3: Settings Screen Does Not Watch `localeProvider` (dry_run_usability M3)

**Source:** `issues/open/dry_run_usability_validator.md` M3
**Severity:** MAJOR — Stale l10n strings in Settings

**Problem:** Settings `build()` watches 5 providers but NOT `localeProvider`. With `AutomaticKeepAliveClientMixin`, any future feature changing locale while Settings is visible will display stale strings.

**Affected file:**
- `lib/features/settings/presentation/settings_screen.dart:125-137`

**Acceptance Criteria:**
- [ ] Add `ref.watch(localeProvider)` to `build()`
- [ ] Verify: change language from another tab → return to Settings → text is updated

---

### DR-M4: Roadmap Topic IDs Displayed as Raw UUIDs (dry_run_roadmaps Issue 1)

**Source:** `issues/open/dry_run_result_roadmaps_milestone_planning.md` Issue 1
**Severity:** MAJOR — Users cannot identify topics

**Problem:** `_formatTopicNames()` at `roadmap_card.dart:24-28` joins raw UUID strings. Human-readable topic names are never resolved from `TopicRepository`.

**Affected files:**
- `lib/features/planner/presentation/widgets/roadmap_card.dart:24-28`
- `lib/features/planner/services/planner_service.dart:239`

**Acceptance Criteria:**
- [ ] Resolve topic IDs to names via `TopicRepository` before display
- [ ] OR store topic names alongside IDs in `MilestoneModel` (add `topicNames` field)

---

### DR-M5: `plannedVsActual` Not Displayed in UI (dry_run_roadmaps Issue 2)

**Source:** `issues/open/dry_run_result_roadmaps_milestone_planning.md` Issue 2
**Severity:** MAJOR — Users can't see schedule adherence

**Problem:** `plannedVsActual` map IS populated in `planner_service.dart:329-349` and stored in Hive, but never displayed in any UI component. No indication of being ahead/behind.

**Affected files:**
- `lib/features/planner/data/models/roadmap_model.dart:33` — Hive field 9, populated but never displayed
- `lib/features/planner/presentation/widgets/roadmap_card.dart` — no adherence indicator

**Acceptance Criteria:**
- [ ] Add visual indicator to `RoadmapCard` showing schedule adherence (e.g. "2 days ahead" / "3 days behind")
- [ ] Add secondary progress bar comparing elapsed time vs milestone completion ratio

---

### DR-M6: Auto-Completion Doesn't Refresh UI State (dry_run_roadmaps Issue 3)

**Source:** `issues/open/dry_run_result_roadmaps_milestone_planning.md` Issue 3
**Severity:** MAJOR — Stale roadmap display

**Problem:** `PersonalLearningPlanService.linkDailyPlanToRoadmap()` correctly auto-completes milestones and saves to Hive, but `PlannerNotifier` is never updated. User must navigate away and back to see changes.

**Affected files:**
- `lib/features/planner/services/personal_learning_plan_service.dart:633-661` — service-only, no notifier update
- `lib/features/planner/providers/planner_providers.dart:145-161` — `loadRoadmaps()` exists but never called after auto-completion

**Acceptance Criteria (choose one):**
- Callback pattern: `recordDailyAdherence()` returns updated roadmap IDs → caller triggers reload
- Bridge method: Add `refreshRoadmaps()` to `PlannerNotifier`, call from adapter
- Reactive: `PlannerNotifier` observes Hive changes via `watch()` on roadmap box

---

### DR-M7: Math Formula Rendering Is Hand-Rolled — No LaTeX Package (dry_run_math M1)

**Source:** `issues/open/dry_run_result_math_scientific_canvas_validation.md` Step 1
**Severity:** MAJOR — Math rendering is broken

**Problem:** `MathExpressionWidget` is a 394-line hand-rolled parser with ~30 commands. No `\int`, proper stacked `\frac`, `\sum`, `\prod`, `\lim`, matrices, multi-line equations, error handling. No LaTeX package in pubspec.

**Affected files:**
- `lib/features/questions/presentation/widgets/math_expression_widget.dart` — hand-rolled parser
- `pubspec.yaml` — no `flutter_math_fork` or `katex_flutter`

**Acceptance Criteria:**
- [ ] Integrate `flutter_math_fork` or `katex_flutter` for proper LaTeX rendering
- [ ] Support: integrals, fractions, sums, products, matrices, multi-line equations
- [ ] Fall back to hand-rolled parser only for non-LaTeX expressions

---

### DR-M8: No Math Answer Input in Practice Sessions (dry_run_math M2)

**Source:** `issues/open/dry_run_result_math_scientific_canvas_validation.md` Step 2
**Severity:** MAJOR — Math questions are unanswerable

**Problem:** No answer input field exists for `mathExpression` type in practice sessions. `QuestionCardWidget` falls through to plain `TextField`. No math keyboard, LaTeX helpers, or formula preview.

**Affected files:**
- `lib/features/practice/presentation/widgets/practice_session_question_card.dart:183-184`
- `lib/features/questions/presentation/widgets/question_card_widget.dart:198-200`

**Acceptance Criteria:**
- [ ] Create `MathInputWidget` with LaTeX helpers and formula preview
- [ ] Math keyboard buttons for common symbols (fractions, integrals, Greek letters, etc.)
- [ ] Preview renders LaTeX in real-time as user types

---

### DR-M9: Math Validation Is Exact String Comparison (dry_run_math M3)

**Source:** `issues/open/dry_run_result_math_scientific_canvas_validation.md` Step 3
**Severity:** MAJOR — Equivalent math expressions marked wrong

**Problem:** `answer_validation_service.dart:382-397` does exact string comparison after minimal normalization (strip spaces, lowercase, `x`→`*`). No tolerance for equivalent expressions.

**Affected file:**
- `lib/core/services/answer_validation_service.dart:382-397`

**Acceptance Criteria:**
- [ ] Add symbolic math comparison or LLM-based math validation
- [ ] Accept equivalent forms (e.g. `2+3` == `3+2`, `x^2` == `x*x`)

---

### DR-M10: Canvas Drawing Validation Is "Any Scribble Is Correct" (dry_run_math M10, M5)

**Sources:** Steps 5 and 10
**Severity:** MAJOR — Drawing questions are meaningless

**Problem:** Both canvas drawing and graph drawing validation check only that data is non-empty. Any scribble is "correct."

**Affected file:**
- `lib/core/services/answer_validation_service.dart:415-426` (canvas), 445-465 (graph)

**Acceptance Criteria:**
- [ ] Content-based validation for canvas drawings (stroke count, coverage area, basic shape recognition)
- [ ] Content-based graph validation (line detection, point positions relative to axes)
- [ ] LLM-assisted evaluation for complex drawings (fallback)

---

### DR-M11: No File Picker for CSV/JSON Question Import (dry_run_custom_questions Item 9)

**Source:** `issues/open/dry_run_result_custom_question_creation.md` Item 9
**Severity:** MAJOR — Users cannot batch import questions

**Problem:** Text-based batch import (`importFromText`) exists. `QuestionImportUtils.importFromJson()` and `importFromCsv()` exist. But the UI only exposes text-paste dialog — no file picker for CSV/JSON files.

**Affected files:**
- `lib/features/questions/presentation/screens/question_bank_screen.dart:278-333`
- `lib/features/questions/services/question_import_utils.dart:16-46`

**Acceptance Criteria:**
- [ ] Add file picker option (CSV/JSON) to import dialog using `file_picker`
- [ ] Connect file picker to `importFromJson()` / `importFromCsv()`
- [ ] Show import preview with conflict resolution options

---

### DR-M12: No "Create Question" FAB on Main Screens (dry_run_custom_questions Item 1)

**Source:** `issues/open/dry_run_result_custom_question_creation.md` Item 1
**Severity:** MAJOR — Creation flow is buried

**Problem:** "Create Question" FAB lives only inside Question Bank screen. No direct access from Dashboard, Practice tab, or Subjects tab.

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:682-685`
- `lib/features/practice/presentation/practice_screen.dart:1192-1194`

**Acceptance Criteria:**
- [ ] Add "Create Question" button on Dashboard quick-actions and Practice tab
- [ ] Add "Question Bank" option to Subjects tab's more-options menu

---

### DR-M13: VoiceBar Review Overlay Skipped With Reduce Motion (dry_run_voice Issue 1)

**Source:** `issues/open/dry_run_result_voice_first_accessibility.md` Issue 1
**Severity:** MAJOR — Accessibility regression

**Problem:** When `widget.reduceMotion` is true, `_toggleListening()` skips the 2-second review overlay and submits transcription immediately. Users who need reduced motion can't review/fix STT errors.

**Affected file:**
- `lib/features/teaching/presentation/widgets/voice_bar.dart:70-74`

**Acceptance Criteria:**
- [ ] Show review overlay regardless of `reduceMotion` state
- [ ] OR add `Semantics` live-region confirmation step for reduced-motion users

---

## MINOR — Code quality / UX friction / architectural debt

### DR-m1: No Content-Based Graph Drawing Tools (dry_run_math M4 partial)

**Source:** Steps 4, 6
**Severity:** MINOR — Incremental improvement

**Problem:** `GraphDrawingWidget` has freehand, line, plot point, eraser, color picker, stroke width, undo/redo. Missing: snap-to-grid, text tool for labeling axes, measurement/scale indicators. `CanvasDrawingWidget` shape tools hidden in practice/question-bank contexts.

**Affected files:**
- `lib/features/questions/presentation/widgets/graph_drawing_widget.dart` — no snap-to-grid/text tool
- `lib/features/questions/presentation/widgets/canvas_drawing_widget.dart` — shape tools hidden outside tutor
- `lib/features/practice/presentation/widgets/practice_session_question_card.dart`

**Acceptance Criteria:**
- [ ] Add snap-to-grid for precise graph drawing
- [ ] Add text tool for labeling axes and data points
- [ ] Enable shape tools in practice/question-bank contexts
- [ ] Consider measurement/scale indicators

---

### DR-m2: Graph Renderer Feature Has Dead l10n Strings (dry_run_math M6)

**Source:** Step 6
**Severity:** MINOR — Dead localization cruft

**Problem:** 17+ l10n strings defined in `app_en.arb:1194-1364+` and `app_es.arb`. Zero usage in `lib/features/`. No widget, screen, service, or provider references these strings.

**Affected files:**
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`

**Acceptance Criteria:**
- [ ] Implement Graph Renderer feature OR remove dead strings
- [ ] If implemented, add widget/service for rendering mathematical graphs from data

---

### DR-m3: VoiceBar Inconsistent Text Overflow (dry_run_voice Issue 2)

**Source:** Issue 2
**Severity:** MINOR

**Problem:** No systematic audit of text overflow across card widgets at max font size (scale 2.0).

**Affected files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart` — card widgets
- `lib/features/dashboard/presentation/widgets/weak_areas_card.dart`, `workload_card.dart`, `topic_breakdown_card.dart`

**Acceptance Criteria:**
- [ ] Audit all card widgets for `TextOverflow.ellipsis`, `softWrap`, clipping at max font size
- [ ] Ensure `Flexible`/`Expanded` wrappers around dynamic text

---

### DR-m4: Color-Blind Accessibility Gaps (dry_run_voice Issue 3)

**Source:** Issue 3
**Severity:** MINOR

**Problem:** `LinearProgressIndicator` uses color-only fill. `_getProgressColor()` and `AppTheme.progressColor()`/`masteryColor()` use color-only thresholds. No color-blind safe palette.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/topic_breakdown_card.dart:155-165, 207-212`
- `lib/core/theme/app_theme.dart:245-264`

**Acceptance Criteria:**
- [ ] Add pattern overlay (stripes, dots) to `LinearProgressIndicator` via `CustomPainter`
- [ ] Add color-blind safe theme palette (e.g. blue-orange instead of red-green)
- [ ] Add icon/shape differentiation alongside color in progress indicators

---

### DR-m5: Large Touch Targets Not Universally Applied (dry_run_voice Issue 4)

**Source:** Issue 4
**Severity:** MINOR

**Problem:** `largeTouchTargets` setting is respected by theme-level button minimum sizes and practice session drawing widgets, but not by most interactive elements: VoiceBar IconButton, AppBar actions, PopupMenuButtons, chips, sliders, tabs.

**Affected files:**
- `lib/features/teaching/presentation/widgets/voice_bar.dart:111-118`
- `lib/features/teaching/presentation/tutor_screen.dart:736-746`
- `lib/features/dashboard/presentation/dashboard_screen.dart`

**Acceptance Criteria:**
- [ ] Propagate `largeTouchTargets` via theme extension or query `settingsProvider` in each widget
- [ ] Apply to: VoiceBar IconButton, tutor screen buttons, dashboard collapsible cards

---

### DR-m6: Mid-Speech TTS Not Restorable After Interruption (dry_run_voice Issue 5)

**Source:** Issue 5
**Severity:** MINOR — Platform limitation

**Problem:** If user navigates away while TTS speaks, and widget is destroyed/recreated, TTS utterance is lost. `flutter_tts` has no position tracking API.

**Affected files:**
- `lib/features/teaching/services/conversation_manager.dart:243-255`
- `lib/core/services/voice_service.dart:185-211`

**Acceptance Criteria:**
- [ ] Re-read last complete AI response on widget re-creation if `_voiceOutputEnabled` is still true
- [ ] Add "Replay last response" TTS button visible when returning to in-progress lesson
- [ ] Document as known limitation

---

### DR-m7: Empty topicId Skips Mastery Attribution (dry_run_custom_questions Item 14)

**Source:** Item 14
**Severity:** MINOR

**Problem:** If user doesn't select a topic during question creation, empty `topicId` results in zero mastery contribution.

**Affected files:**
- `lib/features/questions/presentation/screens/question_bank_screen.dart:794-811`
- `lib/core/services/mastery_graph_service.dart:95-121`

**Acceptance Criteria:**
- [ ] Add visual warning in create/edit dialog when no topic is selected ("Mastery won't be tracked")
- [ ] OR auto-assign to default topic / parent subject mastery aggregate

---

### DR-m8: "Check Nudges Now" Gives Vague Feedback (dry_run_usability m1)

**Source:** m1
**Severity:** MINOR

**Problem:** After tapping "Check Nudges Now," SnackBar shows only "Nudge checks complete." No indication of what was checked.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:274-291`
- `lib/core/services/engagement_scheduler.dart:196-199`

**Acceptance Criteria:**
- [ ] Return result summary from `runDailyChecksNow()` (count per nudge type)
- [ ] Display summary in SnackBar or brief dialog

---

### DR-m9: "Sign Out" Does Not Explain What Data Survives (dry_run_usability m2)

**Source:** m2
**Severity:** MINOR

**Problem:** Sign-out dialog says "Are you sure?" but doesn't explain what data survives (profile, language preference).

**Affected file:**
- `lib/features/settings/presentation/settings_screen.dart:1642-1759`

**Acceptance Criteria:**
- [ ] Add text to dialog explaining what data survives or gets cleared
- [ ] Consider "Clear profile" checkbox

---

### DR-m10: Theme Default Mismatch (dry_run_usability m3)

**Source:** m3
**Severity:** MINOR

**Problem:** `SettingsBox` defaults to `ThemeMode.light` (index 0) but `UiConfig.defaultThemeMode` is `ThemeMode.system`. Discrepancy causes light mode on first launch for system-dark users.

**Affected file:**
- `lib/features/settings/data/models/settings_box.dart:112`

**Acceptance Criteria:**
- [ ] Change default to `ThemeMode.system.index` (2) to match `UiConfig`
- [ ] Verify migration for existing users with stored `themeMode: 0`

---

### DR-m11: No Search or Section Index in Settings (dry_run_usability m5)

**Source:** m5
**Severity:** MINOR

**Problem:** 15 sections with ~40 controls in a single ListView. No search bar, section index, or quick-jump.

**Affected file:**
- `lib/features/settings/presentation/settings_screen.dart:143-377`

**Acceptance Criteria (future):**
- [ ] Add search bar that filters visible sections by label text
- [ ] Add sticky section header index on right side

---

## Execution Plan — Next Development Phase

### Priority Order

| Priority | Item ID | Description | Effort | Dependencies |
|---|---|---|---|---|
| **P0** | **B-FI2** | Focus Mode: free practice + monolith split + session type picker | 2 weeks | None |
| **P0** | **B-FI1.1** | Lessons: calendar scheduling dashboard (not milestone dots) | 1 week | None |
| **P0** | **B-FI1.2** | Lessons: rich content rendering (markdown, LaTeX, images) | 1 week | None |
| **P0** | **B-FI1.3** | Lessons: LessonAgentService agentification (LlmAgent + tools + memory) | 1 week | None |
| **P0** | **B-FI1.4** | Lessons: background lesson prep via IdleExecutor | 3 days | B-FI1.3 |
| **P0** | **DR-B1** | AI Task Monitor stale data fix | 2 hours | None |
| **P0** | **DR-B2** | EngagementScheduler stale settings fix | 1 day | None |
| **P0** | **DR-B3** | Settings orphaned keys migration | 2 days | None |
| **P0** | **DR-B4** | Content trust: flagging + validation fields + LLM re-check | 3-5 days | None |
| **P1** | **DR-M1** | SR settings hardcoded English | 1 hour | None |
| **P1** | **DR-M2** | Language premature commit fix | 1 day | None |
| **P1** | **DR-M3** | Settings watch localeProvider | 1 hour | None |
| **P1** | **DR-M4** | Roadmap topic UUID display fix | 1 day | None |
| **P1** | **DR-M5** | plannedVsActual display | 1 day | None |
| **P1** | **DR-M6** | Auto-completion UI refresh | 1 day | None |
| **P1** | **DR-M7** | LaTeX rendering integration | 3 days | None |
| **P1** | **DR-M8** | Math answer input widget | 3 days | DR-M7 |
| **P2** | **DR-M9** | Math validation improvements | 2 days | DR-M7 |
| **P2** | **DR-M10** | Canvas/graph drawing validation | 2 days | None |
| **P2** | **DR-M11** | CSV/JSON file import UI | 1 day | None |
| **P2** | **DR-M12** | Create Question FAB on main screens | 1 day | None |
| **P2** | **DR-M13** | VoiceBar reduce motion fix | 2 hours | None |
| **P3** | DR-m1 to DR-m11 | All MINOR items | Various | Various |

### Key Dependencies
- B-FI1 items can be partially parallelized: calendar dashboard (B-FI1.1) is independent from rich content (B-FI1.2), which is independent from agentification (B-FI1.3)
- B-FI1.4 (background prep) depends on B-FI1.3 (agentification)
- DR-M8 (math input) depends on DR-M7 (LaTeX rendering)
- All DR-B (blocker) items are independent — can all be started immediately
- DR-M1 through DR-M6 are small fixes (1 hour to 1 day each)

### Further Issues Closure
When both beta-tester issues are fully resolved:
1. Move `issues/further_issues/open/lessons.md` → delete from `open/`
2. Move `issues/further_issues/open/focus_mode.md` → delete from `open/`
3. Record resolution date and commit hash here

---

## Architectural Gaps Blocking Vision Features

### AG-1: No Persistent Background Task System
- `IdleExecutor` uses Dart `Timer.periodic` — stops when app is backgrounded
- `EngagementScheduler` uses Dart `Timer` — doesn't survive app restart
- No `flutter_workmanager` in pubspec
- **Blocks:** background lesson prep, reliable daily nudges, proactive engagement

### AG-2: Token Budget Has No Enforcement
- `LlmUsageMeter` records but never enforces
- No per-feature budgets, no daily caps, no pre-flight checks
- **Blocks:** user trust for API-key-funded students, cost controls

### AG-3: Agent Infrastructure Underutilized
- `LlmAgent` + `AgentLoop` + `ToolRegistry` + `AgentMemoryStore` only used by `MentorService`
- `TutorService` uses it only for background tasks
- `LessonAgentService` doesn't use it at all
- **Blocks:** student-aware lesson generation, cross-session memory in teaching

### AG-4: No Content Feedback Loop
- No mechanism to flag incorrect AI content
- `QuestionModel` has no trust/verification fields
- Content validation is structural-only (schema check, no LLM re-check)
- **Blocks:** trust in AI-generated content, continuous quality improvement

### AG-5: Exercise Generation Not Persisted
- `ConversationManager` generates exercises during tutor sessions
- Exercises are ephemeral — never saved to question bank
- **Blocks:** post-lesson practice, spaced repetition of lesson material

### AG-6: No Whisper API / Local STT for Media Ingestion
- `TranscriptionExtractor` uses third-party `youtubetranscript.com` and LLM calls
- No Whisper API, no YouTube Data API
- **Blocks:** reliable video/audio ingestion from the vision
