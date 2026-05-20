# Dry-Run Scenario: The Complete First-Time Onboarding Experience — From App Install to First Lesson

## Persona

I'm a high school student who just downloaded StudyKing from the app store after a friend recommended it. I have **zero context** about what this app does, what an "API key" is, or how AI tutoring works. I want to learn **IB Chemistry** for my upcoming exams. I open the app for the first time and I'm ready to explore.

I expect the app to:
1. On first launch, explain what it is and what it can do for me — no blank screens
2. Guide me step by step with clear instructions on what to do first
3. Not confuse me with jargon (API keys, providers, models) without explanation
4. Let me create a study plan like "I want to learn IB Chemistry in 90 days"
5. Make uploading my textbook simple and show me progress
6. Help me start my first practice session and first tutor lesson without hunting
7. Show me my progress clearly once I start learning

---

## Step 1: First Launch — The App Starts Up

I tap the StudyKing icon. The app launches.

**What I expect:** Some kind of splash screen, loading indicator, or branding as the app initializes. At minimum, I should know something is happening.

**What actually happens:**

The app starts with a brief flash of the Material Design white/background color (`main.dart:134-238`). During this time, `main()` runs:
1. `WidgetsFlutterBinding.ensureInitialized()` — no visible effect
2. `HiveInitializer.initialize()` — opens ~25 Hive boxes, runs migrations (hive_initializer.dart:1-79). On a slow device this can take 1-3 seconds.
3. `DatabaseService` initialization with all repositories
4. `StudentIdService.init()` — opens its own Hive box
5. `EngagementScheduler` init
6. `runApp(StudyKingApp())` — finally renders the first widget

**During all this initialization, the user sees a white/blank screen.** There is no splash screen, no `SplashScreen` widget, no `CircularProgressIndicator`, and no branding. The `main()` function runs synchronously before `runApp()` is called. For a user on a mid-range phone with many Hive boxes, this blank-screen period can last 2-5 seconds.

The `StudyKingApp` widget (main.dart:301) creates a `MaterialApp` with `home: const MainScreen()`. `MainScreen` renders with a 6-tab `Scaffold` (Dashboard, Subjects, Practice, Mentor, Focus Mode, Settings). The Dashboard tab is selected by default.

**Within the first post-frame callback** (`_handleFirstLaunch()`, line 446):
1. `OnboardingService.isOnboardingNeeded()` returns `true` (no previous completion flag)
2. **OnboardingDialog** shown (non-dismissible, 6-page carousel):
   - Page 1: Subjects — "Add and organize your subjects and topics"
   - Page 2: Practice — "Practice with adaptive questions and spaced repetition"
   - Page 3: Mentor — "Get personalized study recommendations and nudges"
   - Page 4: AI Configuration — "Note: AI features require an API key. Configure one in Settings."
   - Page 5: Focus Mode — "Quick practice hub with timer — practice questions and track focus"
   - Page 6: Settings — "Configure API keys, appearance, and preferences"
   - **Skip** button (calls `markCompleted()`, navigates to SubjectSelectionScreen)
   - **Get Started** button (same action, on last page)
   - **"Don't show again"** checkbox
3. After onboarding dismissed → **LocalDataNotice** dialog (non-dismissible):
   - "StudyKing stores all your data locally on this device. To avoid data loss, use the Backup & Restore feature in Settings"
   - Must tap "I Understand" to dismiss
4. After both dialogs → **ApiKeyBanner** check:
   - If `apiKey` is empty in Hive settings box AND no dismissal within a week → banner shown at top of MainScreen
   - Banner text: "StudyKing needs an API key to use AI features. Configure one now."
   - Buttons: **Configure Now** (→ `ApiConfigScreen`), **Don't show again**, **Dismiss**

**Observations and issues:**

**Issue 1 — No splash/loading screen (MAJOR):** The 2-5 second Hive/database init happens with zero user feedback. On a slow device this looks like the app is frozen. No `SplashScreen`, no `CircularProgressIndicator`, no branding animation.

**Issue 2 — Onboarding doesn't explain API keys (MAJOR):** Page 4 says "Note: AI features require an API key. Configure one in Settings." A brand-new user who has never heard of an API key has no idea:
   - What an API key IS
   - Where to GET one (OpenRouter? OpenAI? Ollama?)
   - What "configure" means
   - Which provider to choose
   - Why the app can't work without one
   
   The text also says "Configure one in Settings" — but the actual flow goes to `ApiConfigScreen` (which is in the Settings section), and the ApiKeyBanner's "Configure Now" button navigates to `/api-config` directly. The onboarding text is slightly misleading — it says "Settings" but the banner goes to a dedicated config screen.

**Issue 3 — LocalDataNotice adds friction without clear value (MINOR):** After the 6-page onboarding, the user must dismiss ANOTHER dialog about local data storage. This dialog tells the user about backup/restore — something they can't act on yet since they have no data. It's an important notice, but its placement immediately after onboarding (before the user has even seen the main screen) adds cognitive friction. A first-time user cannot meaningfully use this information.

**Issue 4 — "Don't show again" and "Dismiss" on ApiKeyBanner have identical behavior (MINOR):** At `main.dart:599-610`, both `onDismiss` and `onDontShowAgain` set `_apiKeyBannerDismissed = true` and store the dismissal timestamp. The "Don't show again" button doesn't actually prevent re-show — it just stores the same timestamp. Both buttons have identical behavior. A user tapping "Don't show again" expects the banner never to return, but it re-appears after 1 week (the same as "Dismiss").

---

## Step 2: Post-Onboarding Dashboard — The Empty State

After the dialogs, I'm on the Dashboard. I see a bottom nav with 6 tabs: Dashboard, Subjects, Practice, Mentor, Focus Mode, Settings.

**What I expect:** Clear guidance on what to do next. A getting-started section that walks me through setup steps.

**What I see:**

A `RocketLaunch` icon with "Getting Started" header and a 4-step checklist:

| # | Step | Navigates To | Status |
|---|---|---|---|
| 1 | Add Subject | `SubjectSelectionScreen` | Unchecked, highlighted "Next Step" |
| 2 | Upload Material | `UploadScreen` | Unchecked |
| 3 | Take Practice Quiz | `SubjectSelectionScreen` | Unchecked |
| 4 | Schedule AI Tutor | `PlannerScreen` | Unchecked |

Step 1 is highlighted with a colored border, "Next Step" badge, and dimmed background. Tapping it navigates correctly.

Below the checklist, the Dashboard renders several other cards with "no data" states:

- **Planner Card** (`_buildPlannerCard`): Shows a "Create Plan" prompt or empty state
- **Sources Card** (`_buildSourcesCard`): Empty/no sources
- **Question Bank Card**: Empty
- **Session History Card**: Empty
- **Summary Card** (`CollapsibleCard`): Shows "0" stats for everything
- **Export Section**: Hidden or empty — need to check
- **Focus Time Card**: 0 minutes
- **Weekly Activity Chart**: Flatline of zeros
- **Mastery Overview**: Empty
- **Weak Areas**: No data

**Issue 5 — Dashboard shows too many empty cards below the checklist (MAJOR):** For a brand-new user, the Dashboard below the checklist shows 8-10 cards/sections, most of which are empty or show "0" for everything. This is overwhelming. A user who just went through a 6-page onboarding + data notice dialog now faces a wall of empty cards. The checklist helps, but the volume of "zero data" cards below it creates visual noise.

The `showSkeleton` logic (line 122: `!hasAnyData && isLoading`) only shows skeletons during loading. Once all providers complete with null/empty data, ALL cards render in their empty state. There is no "minimal mode" that hides empty cards for a first-time user.

**Issue 6 — Checklist step 2 depends on API key, but doesn't warn (MAJOR):** The checklist Step 2 ("Upload Material") navigates to `UploadScreen`. The upload screen requires an API key for AI processing (`fullPipeline: true` is hardcoded). If the user follows the checklist sequentially — Step 1 (Add Subject) → Step 2 (Upload) — they hit the upload screen, fill in their details, select a PDF, tap "Upload & Analyze," and get an error: "Model not configured." There is no checklist-adjacent hint that says "You need to configure your API key first (see the banner at the top)."

The ApiKeyBanner IS visible at the top (unless dismissed), so the user at least has a visual clue. But the checklist itself has no dependency awareness between steps.

---

## Step 3: Creating the First Subject — "IB Chemistry"

I tap Step 1 (or use the Subjects tab). I reach `SubjectSelectionScreen`. I see a form with fields: Name, Code, Teacher, Syllabus, Description, and a Color picker.

I type "IB Chemistry" in the Name field. I leave the other fields empty. I tap Save.

**What happens behind the scenes:**

1. The subject is created with ID `subject_<timestamp>` and saved to `SubjectRepository` (subject_selection_screen.dart:73-96).
2. `findSeedEntry("IB Chemistry")` runs (line 99) against `curriculumSeedData`. The `curriculumName` field at line 33 is `'IB Chemistry'`. `AnswerComparator.areEquivalent("IB Chemistry", "IB Chemistry")` returns `true`.
3. **9 topics with 27 subtopics are auto-created** from the seed data:
   - Stoichiometric Relationships (3 subtopics)
   - Atomic Structure (3 subtopics)
   - Periodicity (3 subtopics)
   - Chemical Bonding & Structure (3 subtopics)
   - Energetics & Thermochemistry (3 subtopics)
   - Chemical Kinetics (3 subtopics)
   - Equilibrium (3 subtopics)
   - Acids & Bases (3 subtopics)
   - Redox Processes (3 subtopics)
4. A SnackBar shows: "Topics auto-created (9)" (line 141-142).
5. A **success dialog** appears (line 162-178): "Subject created successfully! Upload material for IB Chemistry?" with "No Thanks" and "Upload Material" buttons.

**Observation:**

**Issue 7 — No visual preview of auto-created topics (MAJOR):** The user sees a SnackBar saying "Topics auto-created (9)" but NO indication of WHAT those topics are. A user who typed "IB Chemistry" has no way to verify that the 9 topics match their syllabus. The seed data might be outdated, incomplete, or incorrect for their specific exam board. The user cannot review, edit, or remove auto-created topics before proceeding.

The `SubjectTopicsTab` exists (subject_topics_tab.dart) and can display topics, but it's only accessible from `SubjectDetailScreen` (navigate: Subjects tab → tap subject). The auto-creation path creates topics silently in the background and only shows a count.

**Issue 8 — Upload prompt appears before API key may be configured (MAJOR):** The success dialog offers "Upload Material" immediately after subject creation. But the user might not have configured their API key yet. If they tap "Upload Material," they go to UploadScreen which will reject them with "Model not configured." The dialog should either check API key state or warn: "You'll need to configure an API key first."

---

## Step 4: Configuring the API Key

I notice the yellow banner at the top: "StudyKing needs an API key to use AI features. Configure one now." I tap "Configure Now." I'm taken to `ApiConfigScreen`.

**What I see:**

- **Provider dropdown**: Options include OpenRouter, Ollama, OpenAI (and potentially others)
- **API Key field**: A text field (obscured by default) to paste the key
- **Base URL field**: Pre-filled with the provider's default URL
- **Model field**: A text field for the model name
- **Test Connection button**: Sends a real HTTP POST to the provider's `/chat/completions` endpoint
- **Save button**

**Observations:**

**Issue 9 — No "Where do I get an API key?" guidance (MAJOR):** A brand-new user who has never heard of API keys has zero context. The screen doesn't explain:
   - That they need to visit `https://openrouter.ai/keys` or `https://platform.openai.com/api-keys`
   - What the difference is between OpenRouter, OpenAI, and Ollama
   - Why they need to choose a model (and which model is good for studying)
   - Whether the API key costs money
   
   The onboarding page 4 says "Note: AI features require an API key" but doesn't include links or further explanation.

**Issue 10 — Test Connection doesn't validate the model works for StudyKing's use case (MINOR):** `Test Connection` at api_config_screen.dart:152-223 sends `"Reply with exactly: OK"` to the LLM. This confirms the endpoint is reachable and the key is valid — but it doesn't verify the model supports the features StudyKing needs (e.g., tool calling for the agent, vision for image analysis, high token limits for the content pipeline). A model that passes Test Connection might still fail during actual use.

---

## Step 5: Uploading Materials — First Textbook

I go back to the Dashboard. Step 1 now shows a checkmark and "Completed." Step 2 is highlighted as "Next Step." I tap Step 2 and reach `UploadScreen`.

I fill in:
- Title: "IB Chemistry Textbook Chapter 1"
- Subject: "IB Chemistry" (selected from dropdown)
- File: I pick a PDF of my textbook

Both checkboxes are enabled: "Generate questions from content" (ON) and "Generate lesson from content" (OFF). I tap "Upload & Analyze."

**Since the pipeline issues are already documented in `scenario_content_upload_pipeline.md`**, I'll focus on the first-time user's experience here:

**What I see:** A `LinearProgressIndicator` (indeterminate) with text descriptions:
1. "Extracting text from content..."
2. "Classifying content topic..."
3. "Generating summary..."
4. "Generating questions from content..."
5. "Validating generated questions..."
6. "Pipeline complete"

On success: form clears, green container briefly, SnackBar "Content uploaded successfully" with action button "Content Library."

On failure (no API key): red error container "Model not configured" — form stays populated, can retry.

**After upload:** The checklist updates. Step 2 now shows a checkmark. Step 3 "Take Practice Quiz" becomes the highlighted "Next Step."

---

## Step 6: First Practice Session

Step 3 is highlighted. I tap it. I'm taken to `SubjectSelectionScreen`. I select "IB Chemistry."

**What I expect:** A practice session starts automatically since the checklist calls it "Take Practice Quiz."

**What actually happens:** I'm taken to the **Practice tab** (`PracticeScreen`), which shows a grid of practice mode cards. If I have questions from my upload, the grid is interactive. If I have no questions (because my upload is still processing or failed), I see a `PracticeEmptyState` widget:

- "No practice sessions yet"
- "Add subjects and questions to start practicing"  
- Button: **Add Subject** (→ SubjectSelectionScreen)
- Link: **Upload Material** (→ UploadScreen)

**Assuming I have questions:** I see 6 mode cards:
1. Quick Practice (green, lightning bolt)
2. Spaced Repetition (blue, refresh)
3. Topic Focus (orange, target)
4. Weak Areas (red, bar chart)
5. Exam Mode (purple)
6. Source Practice (teal)

**Issue 11 — No "first practice" tutorial or explanation (MAJOR):** A brand-new user seeing 6 mode cards has no context for what each mode does or which to choose. The card subtitles help somewhat ("Practice" for Quick Practice, "Review" for Spaced Repetition) but the user doesn't know:
   - What "spaced repetition" means
   - What "weak areas" refers to (they have no performance data yet)
   - What "topic focus" does (they might not know their topics)
   - What "exam mode" offers differently

The `PracticeEmptyState` has a helpful "Upload Material" link but disappears once there's at least one question. After that, the user is on their own with 6 unlabeled modes.

I tap **Quick Practice**. A bottom sheet asks me to select a subject. I select "IB Chemistry." The session starts with 10 random questions. I answer them. This works as expected. ✓

**Issue 12 — "Take Practice Quiz" checklist step navigates to SubjectSelectionScreen, not PracticeScreen directly (MINOR):** The checklist Step 3 onTap navigates to `AppRoutes.subjectSelection` (empty_dashboard_checklist.dart:47). After selecting a subject, the user is on the Practice tab's mode grid — NOT in an actual practice session. The checklist label "Take Practice Quiz" implies they'll be dropped into a quiz immediately. Instead they face a mode selection screen. A user expecting "one tap → quiz" will be confused.

---

## Step 7: Creating a Study Plan — "Learn IB Chemistry in 90 Days"

Step 4 "Schedule AI Tutor" is now highlighted. I tap it. I'm taken to `PlannerScreen`.

**What I expect:** A guided flow where I tell the app "I want to learn IB Chemistry in 90 days" and it generates a plan.

**What I see:** The Planner has 3 tabs: Study Plan, Calendar, Roadmaps. All three are empty for a new user. The Study Plan tab has a form for creating a plan (multi-syllabus input with cards for subject name, days, hours per day).

**Issue 13 — Planner for a new user is overwhelming (MAJOR):** For a first-time visitor, the Planner screen shows:
   - Three tabs, all empty
   - The multi-syllabus form with fields: Subject Name, Days, Hours Per Day
   - No "Welcome to the Planner" message
   - No pre-filled suggestions
   - The Calendar tab shows an empty calendar grid
   - The Roadmaps tab shows "No roadmaps yet" with a Create button
   
   A new user who tapped "Schedule AI Tutor" from the checklist won't intuitively know:
   - That they need to fill in a form first
   - That "Days" means the total plan length (e.g., 90)
   - That the plan needs to be "generated" before they can schedule a lesson
   - What the Calendar or Roadmaps tabs are for

I fill in: Subject: "IB Chemistry" (I select from the dropdown), Days: "90", Hours: "2". I tap "Generate Plan."

**Issue 14 — Plan generation might fail for a new user due to empty mastery state (PARTIAL — documented in syllabus_driven_curriculum.md):** The plan generation at `PersonalLearningPlanService._buildPlan()` (personal_learning_plan_service.dart:133-144) checks for empty `topicMastery`. If it finds empty mastery (which is the case for a brand-new user with no practice history), the `courseName` extraction fails, and the bypass at line 133 might be skipped. This can cause plan generation to produce an empty or broken plan.

Assuming the plan generates successfully, I see daily plan cards. I can schedule a tutor lesson through the "Schedule Lesson" button. Tapping it, I can configure a time.

---

## Step 8: Starting the First AI Tutor Lesson

I tap "Start Tutoring" on a daily plan card. The `TutorScreen` opens.

**What happens:**
1. `_initializeTutor()` runs
2. Prerequisite check — for my first topic, no prerequisites, so it passes ✓
3. `_startLesson()` → `tutorService.startLesson()` → creates session, generates lesson plan (LLM call)
4. `_sendInitialGreeting()` → sends "Ready to learn about [topic]" → LLM responds
5. Chat interface appears

**Observation:** The tutor lesson experience works correctly based on the earlier validation. ✓

---

## Step 9: Navigating the App After Setup

Now I've created a subject, uploaded materials, practiced, and started a tutor lesson. I want to find my way around.

**What I check:**

- **Subjects tab**: Shows my "IB Chemistry" subject with a colored card. Tapping it shows Subject Detail with tabs: Lessons, Practice, History, Stats, Topics. The Topics tab shows the 9 auto-created topics with subtopics. ✓
- **Practice tab**: Shows the mode grid. Due counts start appearing. ✓
- **Mentor tab**: Chat interface. Can ask "What should I study today?" ✓
- **Focus Mode**: Timer setup or Study Hub mode. ✓
- **Settings**: Has AI Configuration, Backup & Restore, Appearance, etc. ✓

**Issue 15 — No "Congratulations, you're set up!" milestone (MINOR):** After completing all 4 checklist steps, the checklist shows "All Caught Up" with an `EmptyStateWidget`. There's no celebration, no "You've completed your setup" message, no "Here's what you can do next" suggestions. The user goes from guided checklist to "you're on your own" with no transition.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Splash screen or loading indicator during startup | 2-5 second blank white screen with no feedback while Hive initializes | **MAJOR FAIL** |
| 2 | Onboarding explains what an API key is and where to get one | Page 4 says "Note: AI features require an API key" — no explanation, no links, no guidance | **MAJOR FAIL** |
| 3 | "Don't show again" permanently hides the ApiKeyBanner | Identical behavior to "Dismiss" — both store a timestamp that expires in 1 week | **MINOR FAIL** |
| 4 | Dashboard shows only relevant cards for first-time user | Below the checklist, 8-10 empty/zero-data cards render creating visual noise | **MAJOR FAIL** |
| 5 | Checklist steps warn about hidden dependencies | Step 2 (Upload) requires API key but no warning shown. User hits error on first attempt | **MAJOR FAIL** |
| 6 | Auto-created topics are visible and verifiable after creation | SnackBar shows only count: "Topics auto-created (9)" — no topic names, no review option | **MAJOR FAIL** |
| 7 | Upload prompt after subject creation checks API key readiness | Success dialog offers "Upload Material" immediately — may redirect to error screen if no key | **MAJOR FAIL** |
| 8 | API Config screen includes "where to get a key" guidance | No links, no provider comparison, no explanation of what the user needs to do | **MAJOR FAIL** |
| 9 | "Take Practice Quiz" starts a practice session directly | Navigates to SubjectSelectionScreen → Practice mode grid — user must choose a mode | **MINOR FAIL** |
| 10 | Practice modes are explained for new users | All 6 modes shown with no explanatory tooltip, no "recommended for beginners" badge, no tutorial | **MAJOR FAIL** |
| 11 | Planner shows welcome/guidance for new visitors | Three empty tabs with no orientation message. Multi-syllabus form without explanation | **MAJOR FAIL** |
| 12 | New-user plan generation handles empty mastery gracefully | Known gap from syllabus_driven_curriculum.md — may produce empty/broken plan | PARTIAL |
| 13 | Checklist completion triggers a celebration or "what's next" guidance | "All Caught Up" empty state — no milestone celebration, no transition guidance | **MINOR FAIL** |
| 14 | LocalDataNotice is shown at an actionable time | Shown immediately after onboarding, before user has any data. User cannot act on backup info | MINOR FAIL |
| 15 | Skeleton loading during dashboard data fetch | `showSkeleton` logic works but transitions to full card layout once loading completes | PASS |

---

## Summary

| Severity | Count | Items |
|---|---|---|
| **MAJOR** | 10 | #1 (blank screen), #2 (API key explanation), #4 (empty cards), #5 (checklist dependency), #6 (topic visibility), #7 (upload prompt timing), #8 (API key guidance), #10 (practice mode explanation), #11 (planner guidance), #13 (empty mastery plan generation) |
| **MINOR** | 5 | #3 (dont-show-again behavior), #9 (practice quiz navigation), #12 (celebration), #14 (local data notice timing), #15 (skeleton loading) |
| **PASS** | 1 | #15 (already noted above) |

The onboarding experience has a significant first-impression problem: the blank startup screen, unexplained API key requirement, and overwhelming empty dashboard create a friction-filled start. After setup, the transition from guided checklist to unguided app is abrupt. However, once the user gets through setup, the core features (practice, tutor, mentor) function well.
