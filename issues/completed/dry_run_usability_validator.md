# Dry-Run Usability Validation

**Scenario:** `dry-run-test/scenario_existing_user_pace_subjects_provider.md`
**Persona:** Existing user (weeks of use) who wants to adjust pace, switch AI provider, cancel/reschedule lessons, add a second subject, and export progress.

---

## BLOCKER Findings (app crashes or user cannot proceed)

### B1. No UI to cancel or reschedule a scheduled lesson

**Files:**
- `lib/features/planner/services/planner_service.dart:246-284` — `scheduleLesson()` and `cancelLesson()` exist, but no `rescheduleLesson()`
- `lib/features/planner/providers/planner_providers.dart:392-466` — `scheduleLesson` and `scheduleLessonWithConflictCheck` exist, but no `cancelLesson` or `rescheduleLesson` notifier methods
- `lib/features/planner/presentation/planner_screen.dart:512-561` — `_buildScheduledLessonsSection` renders lessons as read-only `ListTile`s with no cancel/reschedule buttons
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` — only supports creating new lessons, not editing existing ones
- `lib/features/lessons/presentation/lesson_detail_screen.dart:1-160` — lesson detail has no cancel/reschedule button

**Rationale:** Users cannot cancel or reschedule a lesson they've booked. The backend `cancelLesson()` method exists but has zero UI bindings. `rescheduleLesson()` does not exist at all. To cancel a lesson, a user would need to use Session History (which also has no cancel action for planned tutoring sessions).

**Acceptance criteria:**
- [ ] Scheduled lessons in the Planner's "Scheduled Lessons" section show a cancel button and/or a reschedule button on each lesson card
- [ ] LessonDetailScreen provides a cancel action and a reschedule action
- [ ] `PlannerNotifier` exposes `cancelLesson()` and `rescheduleLesson()` methods
- [ ] `PlannerService` gains a `rescheduleLesson()` method (or the LessonBookingSheet is refactored to handle editing)
- [ ] Cancellation shows a confirmation dialog; reschedule opens a pre-filled LessonBookingSheet

### B2. Subject deletion does not actually delete the subject

**Files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:249-273` — `_confirmDelete()` shows a confirmation dialog, then on "Delete" only calls `Navigator.pop(context)` twice. **Never calls `SubjectRepository.delete()` or any repository method.**
- `lib/features/subjects/data/repositories/subject_repository.dart:5-49` — `SubjectRepository` extends `Repository<Subject>` which presumably has a `delete()` method, but it's never invoked from the UI.

**Rationale:** The delete button is a lie. The subject remains in Hive permanently. The user gets no feedback that deletion failed. This is a complete no-op.

**Acceptance criteria:**
- [ ] `_confirmDelete()` actually calls `SubjectRepository.delete(subject.id)` after confirmation
- [ ] Success/failure feedback is shown via SnackBar
- [ ] The screen pops back to the subject list after successful deletion
- [ ] Associated data (topics, sessions, mastery states) is cleaned up or orphaned gracefully

---

## MAJOR Findings (feature is broken or misleading)

### M1. Switching AI provider does not reset the selected model

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:48-97` — `_saveKeys()` saves the new provider but does not clear the selected model
- `lib/features/settings/presentation/settings_screen.dart:289-324` — `_showAiModelSelection()` fetches models from the API but the currently selected model ID remains unchanged until the user explicitly picks a new one
- `lib/core/providers/app_providers.dart:217` — `selectedModelProvider` is independent; provider change does not reset it
- `lib/core/providers/llm_providers.dart:15` — `llmServiceProvider` receives the model from `selectedModelProvider` regardless of provider compatibility

**Rationale:** If a user switches from OpenRouter (model: `mistralai/mixtral-8x7b-instruct`) to Ollama, the model ID remains `mistralai/mixtral-8x7b-instruct`. This model ID does not exist on Ollama, causing silent failures in the Tutor, Mentor, and any LLM-dependent feature. The user must remember to manually select a new model — but there's no warning or prompt.

**Acceptance criteria:**
- [ ] Changing the provider in ApiConfigScreen resets `selectedModelProvider` to empty string
- [ ] After saving a provider change, a dialog prompts the user: "You changed your AI provider. Would you like to select a model for [new provider] now?"
- [ ] OR: The model list is filtered/validated against the selected provider when the model selection screen opens

### M2. Switching from Ollama back to OpenRouter does not reset the base URL

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:307-315` — `onChanged` only auto-fills the base URL for Ollama; switching to OpenRouter or OpenAI does NOT change the base URL field
- `lib/features/settings/presentation/api_config_screen.dart:40-46` — `_loadCurrentValues()` loads whatever base URL is stored, regardless of whether it matches the current provider

**Rationale:** If the user switches from OpenRouter to Ollama (base URL becomes `http://localhost:11434`), then switches back to OpenRouter, the base URL stays as `http://localhost:11434`. The user must know to manually change it back to `https://openrouter.ai/api/v1`. This is not obvious.

**Acceptance criteria:**
- [ ] Switching the provider dropdown to any provider auto-fills the default base URL for that provider
- [ ] If the user has a custom base URL, a tooltip or indicator shows that changing provider will reset the URL
- [ ] OR: The provider and base URL are stored as a combined setting so switching providers restores the last-used URL for that provider

### M3. No edit functionality for subjects

**Files:**
- `lib/features/subjects/presentation/subject_detail_screen.dart:192-247` — `_showMoreOptions()` offers Upload, Dashboard, Delete — no Edit option
- `lib/features/subjects/presentation/subject_selection_screen.dart:47-118` — `_saveSubject()` creates a new subject but there is no equivalent `_updateSubject()` method for editing
- `lib/features/subjects/data/repositories/subject_repository.dart:5-49` — repository likely has an `update()` method, but it's not used from any screen

**Rationale:** A user cannot correct a typo in a subject name, update a teacher name, or change the syllabus reference after creation. The only workaround is to delete and recreate, but deletion is broken (B2). This is a basic CRUD gap that creates data quality issues.

**Acceptance criteria:**
- [ ] SubjectDetailScreen "More" menu includes an "Edit Subject" option
- [ ] SubjectSelectionScreen supports an edit mode (pre-filled fields, `_updateSubject()` instead of `_createSubject()`)
- [ ] SubjectRepository.update() or equivalent is called with the modified subject
- [ ] Changes are reflected immediately in the subject list and all dependent views

---

## PARTIAL Findings (feature works but has significant UX gaps)

### P1. No dedicated pace-adjustment controls

**Files:**
- `lib/features/planner/presentation/planner_screen.dart:96-121` — `_generatePlan()` only supports full regeneration with new course/days/hours
- `lib/features/planner/presentation/planner_screen.dart:260-263` — adherence deviation banner offers "Redistribute" and "Regenerate from Adherence" but these are reactive (triggered by low adherence) not proactive
- `lib/core/services/plan_adapter.dart:94` — `suggestRegeneration()` scales targets by adherence, but this is an automated backend function with no user-facing preview
- `lib/features/planner/providers/planner_providers.dart:468-478` — `redistributeWorkload()` only handles missed minutes

**Rationale:** To slow down from 2 hrs/day to 1 hr/day, the user must fill in the generate-plan form again and tap "Generate Plan". This replaces the entire plan without showing what will change. There is no speed/slider control, no "extend deadline" button, and no way to modify daily targets without regenerating from scratch.

**Acceptance criteria:**
- [ ] Planner provides an explicit "Adjust Pace" action (e.g., a dialog with sliders for hours-per-day and plan duration)
- [ ] Adjustments are applied to the existing plan rather than replacing it entirely
- [ ] A preview shows what will change (e.g., "New daily target: 1h, plan extended by 30 days")

### P2. Planner cannot create multi-subject study plans

**Files:**
- `lib/features/planner/services/planner_service.dart:89-115` — `generatePlan()` takes a single `course` string which is purely a metadata label
- `lib/features/planner/services/planner_service.dart:117-143` — `generatePlanFromSyllabus()` accepts a list of `SyllabusGoal` objects (supports multiple subjects) but has no UI
- `lib/features/planner/presentation/planner_screen.dart:276-283` — the generate form has a single text field for "Course/Subject"
- `lib/core/services/personal_learning_plan_service.dart:218-306` — `_buildEmptyMasteryPlan()` only creates generic topics based on `courseName`
- `lib/core/services/personal_learning_plan_service.dart:91-216` — `_buildPlan()` only works from existing mastery state; new subjects with no mastery data produce empty plans

**Rationale:** A user studying both Physics and Chemistry has no way to create a unified study plan that covers both. The `course` text field is cosmetic. The `generatePlanFromSyllabus` method supports multi-subject plans but has no UI. New subjects without mastery data are invisible to the plan engine.

**Acceptance criteria:**
- [ ] The generate plan form lets users select one or more existing subjects from a multi-select list
- [ ] `generatePlanFromSyllabus` is wired to the UI with actual `SyllabusGoal` objects derived from selected subjects
- [ ] If a selected subject has no topics yet, the user is prompted to upload content or the plan generates time-allocated blocks for future topic discovery
- [ ] The plan shows which subject each daily block belongs to

### P3. Dashboard export is CSV-only and hard to find

**Files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:171-176` — ExportSection is the last item in the dashboard, below 10+ card sections
- `lib/features/dashboard/presentation/widgets/export_section.dart:12-49` — only offers CSV (progress), CSV (session history), and "Instrumentation" (confusing label)
- `lib/features/sessions/presentation/session_history_screen.dart:84-181` — comprehensive export (CSV/PDF/JSON) is gated behind navigating to a separate screen
- `lib/core/services/progress_export_service.dart:16-352` — full export service exists but is only accessible from SessionHistoryScreen

**Rationale:** Export is functionally available but fragmented. A user who wants a PDF report must: scroll past 10+ cards → tap "Session History" → tap export → select PDF. The Dashboard itself should offer at minimum a single "Export Full Report" button that provides format choice. The "Instrumentation" label is jargon.

**Acceptance criteria:**
- [ ] Dashboard export section offers PDF, CSV, and JSON options directly (not just CSV)
- [ ] A single "Export Full Report" button generates a comprehensive report in the chosen format
- [ ] Export section is more discoverable (e.g., a FAB or a card near the top)
- [ ] "Instrumentation" is renamed to something user-friendly (e.g., "Diagnostic Data") or moved to a developer settings area

---

## MINOR Findings (UX friction)

### m1. Focus mode has no subject context from navigation

**Files:**
- `lib/features/focus_mode/presentation/focus_timer_screen.dart:15-29` — accepts `preselectedSubjectId` and `preselectedTopicId` but these are not passed from any navigator call site
- `lib/features/settings/presentation/settings_screen.dart:136-137` — "Focus Time" tile navigates with `Navigator.pushNamed(context, AppRoutes.focusMode)` with no arguments

**Rationale:** When starting a focus session, the user might want to associate it with a specific subject or topic for better tracking. The FocusTimerScreen supports this through parameters, but no navigation path passes these parameters. The session gets recorded with empty `subjectId`, making subject-specific reporting less accurate.

**Acceptance criteria:**
- [ ] Subject picker added to focus timer setup screen
- [ ] Subject is passed through to the session recording (PlanAdapter.recordFromFocusSession)
