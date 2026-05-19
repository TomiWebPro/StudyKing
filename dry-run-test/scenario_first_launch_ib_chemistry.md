# Dry-Run Scenario: First Launch — Learning IB Chemistry

## Persona

I'm a new user who just installed StudyKing. I've never used it before. I want to learn **IB Chemistry** (a structured high-school curriculum). I don't know what this app does, where anything is, or what I need to provide to make it work.

---

## Step 1: First Launch — The Blank Canvas

I tap the app icon. I expect either a welcome screen that explains what StudyKing is, or a well-organized starting point. I have no prior data, no subjects, no API key, no study plan.

**What I expect to see:** A welcome message, an onboarding tour, or at minimum a clear "Get Started" prompt that tells me what to do first.

**What actually happens:** The app initializes silently (Hive boxes open, UUID generated) and drops me straight into a `MainScreen` with 5 bottom navigation tabs: **Subjects**, **Practice**, **Mentor**, **Focus Mode**, **Settings**. There's also a floating dashboard button. No splash screen, no welcome dialog, no onboarding overlay. I see five tabs but have no idea what any of them do contextually for my goal (learning IB Chemistry).

**How I discover what to do:** I tap the floating dashboard button and see an `EmptyDashboardChecklist` with 4 steps: "Add Subject", "Upload Material", "Take Practice Quiz", "Schedule AI Tutor". Great — but tapping these items does nothing. They're just static text. I have to figure out that "Add Subject" means going to the Subjects tab manually.

---

## Step 2: Adding a Subject — Manual Labor

I tap the Subjects tab. It shows an empty state with a school icon and "No subjects yet" text. There's a "+" icon in the app bar and an "Add Subject" button.

I tap "Add Subject". I'm taken to a form with fields: Name, Code, Teacher, Syllabus, Description. I type "IB Chemistry" as the name. There is **no auto-complete, no pre-built syllabus database**, no way to search for "IB Chemistry" and have topics populated automatically. I have to manually decide and type everything.

I save the subject. The screen pops back to the subject list, which now shows "IB Chemistry". There is **no prompt** asking "Would you like to upload your IB Chemistry textbook or syllabus now?" I'm left wondering what to do next.

---

## Step 3: Finding the Planner — Telling the App "I want to learn IB Chemistry in 90 days"

I want to create a study plan. I noticed a "Study Planner" card on the Dashboard. I tap it.

The Planner screen has 3 tabs: **Study Plan**, **Calendar**, **Roadmaps**. I'm on the Study Plan tab. I see a form: "Course/Subject", "Days", "Hours per Day".

I enter:
- Course: "IB Chemistry"
- Days: "90"
- Hours per day: "2"

I tap "Generate Plan".

**What I expect:** The app to break IB Chemistry into topics (Atomic Structure, Bonding, Stoichiometry, Organic Chemistry, etc.), schedule them across 90 days, and show me a daily lesson plan.

**What actually happens:** The `course` parameter ("IB Chemistry") is **completely ignored** by the plan generation engine. `PlannerService.generatePlan()` accepts `course` but never passes it to `PersonalLearningPlanService.generatePlan()`. The plan generation works only from existing mastery state data — which is **empty** for a new user with zero practice history. So it produces 90 daily plans, each with **zero priority topics, zero target questions, zero target minutes**, and a generic focus label like "General review". I see 90 days of "study nothing" entries. I don't understand why my "IB Chemistry" course had no effect.

---

## Step 4: Trying Upload — Will the App Understand My Textbook?

I go back to the Dashboard and read the checklist again. "Upload Material" — okay, I have an IB Chemistry PDF textbook. I tap Settings → Dashboard → Upload (I have to navigate back to the Dashboard).

Wait — there's no direct route to Upload from most screens. I need to go to the Dashboard (tap FAB) → find the checklist → but the checklist items aren't tappable. I eventually find the Upload screen via... actually, there's no obvious route. Let me check: the `AppRoutes.upload` exists but there's no button to it from the main screens. The only path is through the Lesson List or Dashboard → Planner → ... no direct Upload button from the main nav.

(As a workaround I find the Settings menu doesn't have upload either. I have to know the route `/upload` exists.)

I upload my IB Chemistry PDF. The content pipeline processes it and stores it as a source. But **no questions or lesson content are automatically generated** from the uploaded material — that requires an explicit "full pipeline" step. I don't know this exists.

---

## Step 5: AI Features — API Key Required

I want to use the AI Tutor or Mentor to help me learn Chemistry. I tap the Mentor tab. It shows a welcome message. But when I type a question, the app tries to use the LLM service — which has no API key configured. The Mentor might show an error or silently fail.

I go to the Settings tab to look for configuration. I see "API Keys" with "Not configured" text. I tap it and see the API configuration screen. I need to:
1. Have an OpenRouter (or Ollama or OpenAI) API key ready
2. Enter it manually
3. Test the connection
4. Select a model from a dropdown (fetched from the provider)

**There was no proactive prompt** on first launch telling me "You need an API key to use AI features. Go to Settings → API Config to set one up." The QuickGuide screen silently falls back to local canned responses if no API key is set, making me think the app is dumb rather than misconfigured.

---

## Step 6: Scheduling a Lesson — Manual Booking

I finally have everything set up (subject created, API configured). I go to the Planner and see my daily plans (which have zero content, but I may not realize that yet).

There's a "Schedule Lesson" button on each day card. I tap it. A bottom sheet opens asking me to pick a time, date, and duration. I configure it and tap "Schedule". The lesson is saved as a planned tutor session.

But **lesson content is not auto-generated**. The AI Tutor session will happen in real-time when I join it, but there's no pre-generated lesson plan visible to me. I can't preview what will be taught. I also can't start the lesson immediately with one tap — it's a multi-step scheduling process.

---

## Step 7: Checking Progress — Confusing Empty Dashboard

After using the app for a few minutes, I check the Dashboard again. All the metric cards show zeros or empty states because there's no practice data, no session data, no adherence data yet. The dashboard is designed for users who already have data — it doesn't guide new users toward their next action.

The 4-step checklist doesn't help because:
1. The items aren't tappable
2. There's no indication of progress (which steps I've completed)
3. There's no "next step" emphasis

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| App explains itself on first launch | No onboarding, dropped into 5-tab shell | FAIL |
| Dashboard checklist items are actionable | Static text — tapping does nothing | FAIL |
| "Learn IB Chemistry in 90 days" works as natural input | Course name accepted but ignored by plan engine | FAIL |
| Plan auto-generates topics from syllabus name | No syllabus database; plan generates empty days | FAIL |
| Uploading a textbook auto-creates questions | Manual full-pipeline step required | PARTIAL |
| API key setup is prompted on first AI use | No prompt; silent fallback to canned responses | FAIL |
| Adding a subject prompts for materials | No follow-up prompt after subject creation | FAIL |
| Lesson content is pre-generated from syllabus | Must manually book and attend live AI tutor session | FAIL |
| Lesson can be started with one click | Multi-step scheduling process | FAIL |
| Dashboard guides new users effectively | Shows empty metrics + static checklist | PARTIAL |

---

## Validation Results (2026-05-19) — Corrected

Codebase re-scanned against each step. Results below reference current source at commit HEAD. Several existing validation claims were incorrect due to outdated code; corrections noted.

---

### Step 1: First Launch — The Blank Canvas
**Status: COMPLETED**
- Onboarding EXISTS: `lib/main.dart:428-436` shows `OnboardingDialog` (6-page PageView) + `LocalDataNotice` on first launch via `_handleFirstLaunch()`. 🟢
- Dashboard is Tab 0 (`_buildTabNavigators()` at `lib/main.dart:461-493`), not behind a FAB. 🟢
- Checklist items ARE tappable: `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:96-97` wraps each in `InkWell(onTap:)` with proper route navigation. 🟢
- **CORRECTION:** Onboarding dialog NOW mentions API keys: `lib/features/onboarding/presentation/onboarding_dialog.dart:157-162` — 6 pages including **"AI Configuration"** page (`Icons.key`, `l10n.needApiKeyNotice`). 6 pages: Subjects, Practice, Mentor, AI Configuration, Focus Mode, Settings. 🟢
- "Get Started" button navigates to `AppRoutes.subjectSelection` at `lib/features/onboarding/presentation/onboarding_dialog.dart:107`. Provides clear first action. 🟢
- ApiKeyBanner shown after onboarding: `lib/main.dart:446-454` checks `apiKey.isEmpty` and sets `_showApiKeyBanner = true`; rendered at line 531-544. 🟢

**Remaining gaps:** None significant.

---

### Step 2: Adding a Subject — Manual Labor
**Status: PARTIAL**
- Add Subject form exists: `lib/features/subjects/presentation/subject_selection_screen.dart` — form with name, code, teacher, syllabus, description, color. 🟢
- Post-creation upload prompt EXISTS: `lib/features/subjects/presentation/subject_selection_screen.dart:104-120` — `showDialog` asking "Would you like to upload study material for {subject}?", navigates to `/upload` on accept. 🟢
- No auto-complete / syllabus database: `lib/features/subjects/presentation/subject_form_widgets.dart` uses plain `TextFormField` — no `Autocomplete`, no presets, no JSON seed data for curricula (IB, A-Levels, AP, etc.). 🔴

**Remaining gaps:** (a) No pre-built syllabus database for common curricula. (b) No auto-complete suggestions when typing subject name.

---

### Step 3: Finding the Planner — "Learn IB Chemistry in 90 days"
**Status: PARTIAL**
- `PlannerService.generatePlan()` at `lib/features/planner/services/planner_service.dart:97-123` passes `courseName: course` to `PersonalLearningPlanService.generatePlan()`. 🟢
- `PersonalLearningPlanService._buildPlan()` at `lib/core/services/personal_learning_plan_service.dart:133-138` checks `topicMastery.isEmpty && courseName.isNotEmpty` → calls `_buildEmptyMasteryPlan()`. 🟢
- `_buildEmptyMasteryPlan()` (lines 234-319) creates daily plans with `estimatedQuestions` (`targetQuestionsPerDay`), `estimatedMinutes` (`targetMinutesPerDay`), focus labels per topic. NOT empty days. 🟢
- `PlannerScreen._generatePlan()` at `lib/features/planner/presentation/planner_screen.dart:223-261` validates course name against existing subjects + topics; blocks with snackbar+action if no match or no topics. 🟢
- Empty-mastery fallback (`_buildEmptyMasteryPlan` at line 234+) tries to resolve real subject/topics by name (lines 244-263); if found, uses real topic IDs. If not found, generates synthetic `'generated_${day}_$studentId'` IDs with empty `subjectId`. 🟡
- **`_linkQuestionsToDailyPlans()` is NOT called for empty-mastery plans** — the method returns early at line 133 before reaching line 201. Generated plans have `reviewQuestionIds: []` and `stretchGoalQuestionIds: []`. 🔴
- When mastery data exists, `courseName` is used in `_generateDailyPlans` (line 198) for summary/labeling but does not influence topic recommendations (driven by mastery data). 🟡

**Remaining gaps:** (a) Empty-mastery plans have zero linked questions. (b) Course name does not influence topic recommendations when mastery data exists. (c) No guidance for user to add topics when none exist for the subject.

---

### Step 4: Trying Upload — Will the App Understand My Textbook?
**Status: COMPLETED**
- **CORRECTION:** Settings HAS direct upload link at `lib/features/settings/presentation/settings_screen.dart:142-143` — "Upload Material" under Content Management section navigates to `AppRoutes.upload`. 🟢
- **CORRECTION:** Main upload button is labeled "Upload & Analyze" and calls `_submitContent(fullPipeline: true)` at `lib/features/ingestion/presentation/upload_screen.dart:610`. Default `_generateQuestions = true` (line 49). 🟢
- `_getPipeline()` at line 144-145 falls back to reading `contentPipelineProvider` from ref (not null). Pipeline IS available. 🟢
- `_submitContent()` with `fullPipeline: true` calls `pipeline.processFullPipeline()` (line 242) — runs extraction, classification, question generation. 🟢
- Upload accessible from: dashboard checklist, practice screens, subject detail, subject creation dialog, settings, content library empty state. 🟢

**Remaining gaps:** None. Upload triggers full pipeline by default.

---

### Step 5: AI Features — API Key Required
**Status: COMPLETED**
- ApiKeyBanner shown after onboarding: `lib/main.dart:446-454` — visible banner with "Configure Now" button → `/api-config`. 🟢
- **CORRECTION:** Onboarding dialog NOW includes AI Configuration page: `lib/features/onboarding/presentation/onboarding_dialog.dart:157-162` — icon `Icons.key`, title `l10n.aiConfiguration`, description `l10n.needApiKeyNotice`. 🟢
- **CORRECTION:** QuickGuide does NOT silently fall back. `lib/features/quickguide/presentation/quick_guide_screen.dart:125-138` — checks `apiKey.isEmpty`, calls `_showNoApiKeyMessage()` (lines 197-217) which shows clear inline message: "API Key Needed" + "Please configure API key" with clickable link. 🟢
- Mentor shows inline error: `lib/features/mentor/presentation/mentor_screen.dart:251-267` — checks `_mentorService.hasApiKey`, shows "Mentor API key missing. Go to settings." 🟢
- Settings > AI Model shows dialog when key missing: `lib/features/settings/presentation/settings_screen.dart:514-534`. 🟢

**Remaining gaps:** None significant. All AI entry points give clear API key guidance.

---

### Step 6: Scheduling a Lesson — Manual Booking
**Status: COMPLETED**
- `PlannerService.scheduleLesson()` at `lib/features/planner/services/planner_service.dart:292-341` creates `Session` AND calls `LessonAgentService.generateLesson()` to pre-generate lesson content. Session marked `lessonReady: true` on success. 🟢
- Daily plan cards have "Start Tutoring" button: `lib/features/planner/presentation/widgets/daily_plan_card.dart:144-153` one-tap navigation to tutor screen. 🟢
- Scheduled lessons list has "Start Tutoring" button: `lib/features/planner/presentation/planner_screen.dart:1127-1137`. 🟢
- `_openTutorMode()` at `lib/features/planner/presentation/planner_screen.dart:107-122` immediately navigates to `AppRoutes.tutor` with `TutorArgs`. 🟢

**No remaining gaps.**

---

### Step 7: Checking Progress — Confusing Empty Dashboard
**Status: PARTIAL**
- Dashboard shows `EmptyDashboardChecklist` when progress incomplete: `lib/features/dashboard/presentation/dashboard_screen.dart:143-144`. 🟢
- Checklist items ARE tappable with navigation: `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:96-97`. 🟢
- **CORRECTION:** Progress tracking EXISTS. `ChecklistProgress` model at `lib/features/dashboard/data/models/dashboard_models.dart:184-209` — tracks `hasSubjects`, `hasSources`, `hasPracticeSessions`, `hasScheduledLessons`. `completedCount`/`totalCount` badge shown at line 64-78. ✅
- **CORRECTION:** Completed items show checkmark icon + strikethrough title + "Completed" subtitle: `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:106-142`. ✅
- **No "next step" emphasis:** All 4 items have identical visual weight — no "Start Here" badge, no numbering, no contextual highlighting. 🔴
- Dashboard renders full metric cards alongside checklist — not a binary hide: `lib/features/dashboard/presentation/dashboard_screen.dart:128-178`. Checklist persists until `isComplete == true`. ✅
- **CORRECTION:** `NextUpCard` at `lib/features/dashboard/presentation/widgets/next_up_card.dart:40-58` shows "All caught up" message when zero data — does NOT hide itself. ✅

**Remaining gaps:** (a) No "next step" visual emphasis in checklist — all 4 items look equally important. (b) No intermediate partial-progress dashboard state between checklist and full 12-card layout.

---

### Summary

| Step | Status | % Complete |
|---|---|---|
| Step 1: First Launch | COMPLETED | ~95% |
| Step 2: Adding a Subject | PARTIAL | ~50% |
| Step 3: Finding the Planner | PARTIAL | ~65% |
| Step 4: Trying Upload | COMPLETED | ~95% |
| Step 5: API Key Setup | COMPLETED | ~95% |
| Step 6: Scheduling a Lesson | COMPLETED | 100% |
| Step 7: Checking Progress | PARTIAL | ~85% |
| **Overall** | | **~84%** |

`≥ 80%` — borderline. Scenario retained because critical gaps remain: (a) no syllabus database/auto-complete for subject creation, (b) empty-mastery plans have zero linked questions. Issues documented at `issues/open/dry_run_result_first_launch_ib_chemistry.md`.
