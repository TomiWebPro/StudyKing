# Dry-Run Usability Validation: First Launch — Learning IB Chemistry

## Scenario

`dry-run-test/scenario_first_launch_ib_chemistry.md`

A new user installs StudyKing for the first time, wanting to learn IB Chemistry. The tracing exposes 12 distinct usability gaps that prevent a new user from successfully adopting the app without external guidance or trial-and-error.

---

## BLOCKER (app crashes or user cannot proceed)

### B1. Empty Dashboard Checklist items are not tappable / actionable

The `EmptyDashboardChecklist` widget shows 4 onboarding steps (Add Subject, Upload Material, Take Practice Quiz, Schedule AI Tutor) but none of the items can be tapped. The `ChecklistItem` is a plain data class with no callback, and items are rendered as static `Row` widgets with no `GestureDetector`/`InkWell`.

**Affected files:**
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:12-33` — `ChecklistItem` class has no `onTap`/`onPressed` field
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:61-103` — Items rendered as `Row` children with no tap handler

**Acceptance criteria:**
- Each `ChecklistItem` must have an `onTap` callback that navigates to the corresponding screen (`AppRoutes.subjectSelection`, `AppRoutes.upload`, `AppRoutes.practiceSession`, `AppRoutes.planner`).
- Alternatively, wrap each item row in `InkWell`/`GestureDetector` with the appropriate navigation route.

### B2. Plan generation for new users produces empty daily plans (zero topics, zero questions)

When a new user creates a study plan ("IB Chemistry, 90 days"), `PersonalLearningPlanService._buildPlan()` calls `_repository.getAllMasteryStates()` which returns an empty list. `_buildRecommendations()` iterates over the empty list and produces zero `PlanRecommendation` items. `_generateDailyPlans()` then loops `planDurationDays` times (e.g. 90), but each day's `priorityTopics` remains empty because the inner `while` loop condition `recommendationIndex < sortedRecs.length` is immediately false. The result is 90 daily plans with `targetQuestions: 0`, `targetMinutes: 0`, and focus label `"General review"`.

Additionally, the `course` parameter entered by the user is silently discarded — `PlannerService.generatePlan()` accepts `course` but never passes it to the plan generation engine.

**Affected files:**
- `lib/features/planner/services/planner_service.dart:89-112` — `generatePlan()` takes `course` parameter but never forwards it to `PersonalLearningPlanService`
- `lib/core/services/personal_learning_plan_service.dart:74-76` — `generatePlan()` calls `_buildPlan(studentId: studentId)` with no course/subject reference
- `lib/core/services/personal_learning_plan_service.dart:88-199` — `_buildPlan()` requires non-empty `masteryStates` to generate meaningful recommendations
- `lib/core/services/personal_learning_plan_service.dart:201-245` — `_buildRecommendations()` returns empty list when `topicMastery` is empty
- `lib/core/services/personal_learning_plan_service.dart:470-591` — `_generateDailyPlans()` produces zero-content days when `recommendations` is empty

**Acceptance criteria:**
- When no mastery state data exists, the planner must create a plan based on the course/subject name alone (e.g. by prompting the LLM to generate a syllabus structure for "IB Chemistry" and distribute topics across the requested duration).
- The `course` parameter in `PlannerService.generatePlan()` must either be forwarded to the plan engine or the screen should prevent plan generation until at least one subject with topics exists.
- The user must receive a clear message: "You need to add a subject and its topics before generating a plan" OR the plan generation must work from an LLM-generated syllabus when no data exists.

---

## MAJOR (feature is broken or misleading)

### M1. No onboarding experience on first launch

The app initializes silently (Hive, UUID) and jumps directly to the 5-tab `MainScreen`. There is no welcome dialog, onboarding walkthrough, or coachmarks. The user must discover all features through trial and error. The closest thing to onboarding is `QuickGuideScreen`, but it's buried 2 navigation levels deep (Settings → Quick Guide) and is never shown automatically.

**Affected files:**
- `lib/main.dart:39-89` — `main()` completes initialization and calls `runApp(StudyKingApp())` with zero user-facing guidance
- `lib/main.dart:220-398` — `MainScreen` renders immediately with 5 tabs and a Dashboard FAB
- `lib/features/quickguide/presentation/quick_guide_screen.dart` — QuickGuide exists but is never triggered on first launch

**Acceptance criteria:**
- On first launch (detecting zero subjects, zero plans, zero practice data), show a welcome dialog or full-screen onboarding that:
  - Explains what StudyKing is ("your AI-native learning companion")
  - Highlights the 5 main tabs and what each does
  - Proactively points to API Key configuration
  - Offers to create a first subject or start the QuickGuide
- The onboarding should have a "Don't show again" checkbox and be dismissible.
- Alternatively, route to `QuickGuideScreen` automatically on first launch.

### M2. No proactive API key configuration prompt

AI-dependent features (Mentor, QuickGuide, AI Tutor) silently degrade or fail when no API key is configured. QuickGuide falls back to canned responses (`_fallbackResponse()`). The Mentor may display errors. The Settings screen shows "Not configured" in small text for the API Keys row, but there is no proactive banner/dialog anywhere telling the user to configure their API key before using AI features.

**Affected files:**
- `lib/features/settings/presentation/settings_screen.dart:84-85` — Shows "Not configured" text non-prominently
- `lib/features/quickguide/presentation/quick_guide_screen.dart:125-127` — Silently falls back to canned responses when `apiKey.isEmpty`
- `lib/features/mentor/presentation/mentor_screen.dart:55-89` — `_initializeMentor()` does not check API key availability before attempting LLM calls
- `lib/core/providers/app_providers.dart` — `apiKeyProvider` starts as empty string

**Acceptance criteria:**
- On first app launch, if no API key is detected, show a prominent banner/dialog: "StudyKing needs an API key to use AI features. Configure one now." with a button linking to `AppRoutes.apiConfig`.
- The banner should persist (dismissible but re-appear on next launch) until the user configures a valid API key.
- The Mentor screen should show a helpful message when API key is missing instead of silently failing.
- The QuickGuide welcome message should include a note about API configuration if no key is set.

### M3. No well-known syllabus database for international curricula

Users who want to study a specific curriculum (IB, A-Levels, AP, GCSE, etc.) must manually type everything: subject name, code, teacher, syllabus, description. There is no pre-populated database or LLM-based auto-complete for well-known courses. Even after creating "IB Chemistry", no topics are generated — the process is entirely manual.

**Affected files:**
- `lib/features/subjects/presentation/subject_selection_screen.dart:20-25` — All subject fields are manual text inputs
- `lib/features/subjects/presentation/subject_form_widgets.dart` — Form fields with no auto-complete

**Acceptance criteria:**
- Add an LLM-powered "Suggest from curriculum" feature: when the user enters "IB Chemistry", the app queries the LLM (or a local database) to generate a list of standard IB Chemistry topics and populate them automatically.
- Alternatively, bundle a starter JSON file of common international curricula topics.

### M4. No follow-up prompt after adding a subject

After the user creates a subject (`_saveSubject()`), the screen just calls `Navigator.pop(context, true)`. There is no dialog suggesting the next logical step: "Great! Would you like to upload your IB Chemistry textbook or syllabus now?"

**Affected files:**
- `lib/features/subjects/presentation/subject_selection_screen.dart:70-75` — Saves subject then navigates back silently

**Acceptance criteria:**
- After successful subject creation, show a brief snackbar or dialog with an action button: "Upload study material for [subject name]?" → navigates to `AppRoutes.upload` with `preselectedSubjectId` set.
- Add option: "Generate topics from LLM for [subject name]?" if no topics exist yet.

### M5. Course name accepted but silently discarded during plan generation

The planner screen's `_generatePlan()` reads `_courseController.text` and passes it to `PlannerService.generatePlan(course: course, ...)`, but `PlannerService` never forwards this value. The user is shown a success message "Plan generated successfully" even though their course name was completely ignored.

(Duplicates part of B2's technical findings but focuses on the misleading user experience.)

**Affected files:**
- Same as B2

**Acceptance criteria:**
- See B2 acceptance criteria.
- Additionally: if the `course` parameter is not used by the plan engine, the input field must be removed or clearly labeled as optional/display-only.

### M6. Lesson content not auto-generated; requires multi-step manual booking

After a plan is generated, each daily plan card shows a "Schedule Lesson" button that opens a time-picker bottom sheet. Even after scheduling, the lesson content is not pre-generated — the AI Tutor session happens in real-time with no preview. There is no one-click "Start Lesson Now" option, and lesson plans are not pre-built from the syllabus.

**Affected files:**
- `lib/features/planner/presentation/planner_screen.dart:68-94` — `_openLessonBooking()` opens a bottom sheet for time selection
- `lib/features/planner/presentation/widgets/daily_plan_card.dart` — Card has "Schedule Lesson" but no "Start Now" option
- `lib/features/teaching/presentation/tutor_screen.dart` — Tutor initializes and generates lesson plan dynamically

**Acceptance criteria:**
- Daily plan cards should include a "Start Lesson Now" button that immediately opens the AI Tutor with the day's topic pre-loaded.
- When scheduling is needed, the system should optionally pre-generate a lesson plan (using LLM) that the user can preview before the scheduled time.

### M7. Uploaded content does not automatically generate questions/lessons

After uploading a PDF or other material via `UploadScreen`, the content is stored as a `SourceModel` source chunk. But the `processFullPipeline()` method (which calls question generation via LLM) is opt-in, not automatic. The user doesn't know they need to take additional steps to derive learning value from their uploaded materials.

**Affected files:**
- `lib/features/ingestion/services/content_pipeline.dart` — `processUpload()` stores material but only `processFullPipeline()` generates questions
- `lib/features/ingestion/presentation/upload_screen.dart` — UI doesn't clearly distinguish between "just store" and "analyze + generate questions"

**Acceptance criteria:**
- After uploading material, automatically queue question generation in the background via `processFullPipeline()`.
- Show a progress indicator: "Generating questions from your material..."
- If the user doesn't want auto-generation, add a toggle "Auto-generate questions from uploaded material" in settings.

---

## MINOR (UX friction)

### m1. QuickGuide AI Tutor navigates with empty args

`ModeNavigationWidget` in the QuickGuide has an "AI Tutor" card that navigates to `AppRoutes.tutor` with `TutorArgs(topicId: '', topicTitle: '', subjectId: '')`. The `TutorScreen` expects valid IDs. Navigating with empty IDs will likely cause errors or a broken tutoring experience.

**Affected file:**
- `lib/features/quickguide/presentation/widgets/mode_navigation_widget.dart:42-51` — Navigation call passes empty `TutorArgs`

**Acceptance criteria:**
- Remove or disable the "AI Tutor" navigation button from QuickGuide until a real subject/topic context exists.
- Alternatively, show a dialog explaining that the user needs to create a subject and plan first before using the AI Tutor.

### m2. No "Getting Started" unified entry point

Each screen has its own empty state (Subjects shows empty icon + text, Practice shows empty state, Planner shows empty state, Dashboard shows checklist). But there's no single "Start Here" button or flow that appears globally to unify the first-run experience.

**Affected files:**
- All feature empty state widgets

**Acceptance criteria:**
- A single "Get Started" CTA that either opens the onboarding flow or directly opens the subject creation screen should be accessible from every tab's empty state.

### m3. No multi-device sync or backup indication

The app generates a UUID silently (`StudentIdService`) and stores all data in local Hive boxes. A reinstall means total data loss. There is no indication to the user that their data is device-local and will not survive reinstallation.

**Affected files:**
- `lib/core/services/student_id_service.dart` — UUID generation without export/recovery mechanism

**Acceptance criteria:**
- Add a one-time notice on first launch: "StudyKing stores all your data locally on this device. To avoid data loss, use the Export feature in Dashboard."
- Consider adding a settings toggle for cloud backup (future feature).
