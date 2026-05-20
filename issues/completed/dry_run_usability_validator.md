# Dry-Run Usability Validator — First-Time Onboarding Experience

**Scenario:** `scenario_first_launch_onboarding_experience.md`
**Validator:** Dry-Run Usability Validator
**Date:** 2026-05-20

---

## Scenario Summary

A brand-new user installs StudyKing and opens it for the first time. They want to learn IB Chemistry but have no prior context about the app, API keys, AI providers, or how the system works. The scenario traces the complete journey: first launch → onboarding → dashboard empty state → subject creation → API key config → content upload → first practice → plan creation → first tutor lesson.

---

## Findings

### BLOCKER: None identified

All navigation paths are reachable; no crashes or complete dead-ends were found in the first-launch flow.

---

### MAJOR FAIL: #1 — No Splash Screen or Loading Indicator During App Initialization

**Files:** `lib/main.dart:134-238`

**Description:** The `main()` function runs Hive initialization (~25 boxes), database setup, StudentIdService, and EngagementScheduler synchronously before `runApp()` is called. During this 2-5 second period (longer on slower devices), the user sees a blank white screen with zero feedback — no splash screen, no CircularProgressIndicator, no branding, no text.

**Rationale:** First impressions matter. A blank screen on first launch suggests the app is frozen or broken. Most users expect either a splash screen with branding or at minimum a loading indicator.

**Acceptance Criteria:**
- [ ] Add a `SplashScreen` widget (with branding/logo) that renders immediately when the app starts
- [ ] Show a loading indicator or progress bar during Hive/database initialization
- [ ] Transition to `MainScreen` only after all initialization completes
- [ ] OR restructure `main()` to defer non-critical initialization to after the first frame

---

### MAJOR FAIL: #2 — Onboarding Does Not Explain What an API Key Is or Where to Get One

**Files:**
- `lib/features/onboarding/presentation/onboarding_dialog.dart:163-168` (page 4 text)
- `lib/l10n/generated/app_localizations_en.dart:3628-3629` (`needApiKeyNotice` string)
- `lib/features/settings/presentation/api_config_screen.dart` (config screen)

**Description:** Page 4 of the onboarding carousel shows: "Note: AI features require an API key. Configure one in Settings." A brand-new user who has never heard of "API key" has zero context about:
- What an API key is
- Where to obtain one (OpenRouter, OpenAI, Ollama)
- What the different providers are
- Which model to choose
- Whether it costs money

The `ApiConfigScreen` similarly offers no guidance — it has fields for provider, key, URL, and model but no "How to get started" help text, no links to registration pages, no provider comparison.

**Rationale:** The target audience is students, not developers. Expecting a student to know what an API key is and how to configure it without guidance is a major UX gap. This is the #1 barrier to actually using the app's AI features.

**Acceptance Criteria:**
- [ ] Add a "What is an API key?" expandable section or help icon on page 4 of the onboarding
- [ ] Add provider-specific guidance text in `ApiConfigScreen` for each provider (e.g., "Visit openrouter.ai/keys to create a free account and get your API key")
- [ ] Consider adding a link/button that opens the registration URL in a browser
- [ ] Add a "Recommended for beginners" badge on the simplest provider option

---

### MAJOR FAIL: #3 — Dashboard Shows 8-10 Empty/Zero-Data Cards Below the Checklist for First-Time Users

**Files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:149-300+`
- `lib/features/dashboard/providers/dashboard_data_providers.dart`

**Description:** Below the `EmptyDashboardChecklist`, the Dashboard renders the full card layout for every section: Summary (all zeros), Export Section, Focus Time (0 min), Weekly Activity (flatline), Mastery Overview (empty), Weak Areas (no data), Due Reviews (0), Workload (0), Planner Card (no plan), Sources Card (no sources), Session History (no sessions), Question Bank Card (empty).

For a first-time user, at least 8-10 cards all display some form of "empty" or "0" state. This creates overwhelming visual noise directly beneath the checklist that's supposed to guide the user.

The `showSkeleton` logic (`!hasAnyData && isLoading`) correctly shows skeletons during loading, but once loading completes with no data, EVERY card renders in its empty state. There is no "first-run minimal mode" that hides low-value empty cards.

**Rationale:** A user who just completed onboarding now faces a wall of zero-data widgets. This undermines the guided experience the checklist tries to provide. The checklist should be the primary focus; empty stats cards add cognitive load without value.

**Acceptance Criteria:**
- [ ] When `checklistProgress.isComplete` is false and `!hasAnyData`, show only the checklist + planner card + sources card (items the user can act on)
- [ ] Hide summary, focus time, weekly chart, mastery, weak areas, due reviews, workload, and export sections when the user has no data
- [ ] Add a "You'll see your stats here once you start learning!" placeholder for hidden sections
- [ ] OR create a dedicated "First Run" dashboard layout with minimal cards

---

### MAJOR FAIL: #4 — Checklist Steps Have Hidden Dependencies Not Communicated to the User

**Files:**
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:34-58` (step definitions)
- `lib/features/practice/presentation/screens/practice_screen.dart:1077` (empty state shown when `_subjects.isEmpty`)
- `lib/features/upload/presentation/upload_screen.dart:218-224` (model check blocks upload)

**Description:** The 4-step checklist implies a linear progression, but several steps have hidden dependencies:

- **Step 2 (Upload Material)** requires an API key to be configured. If the user follows the checklist sequentially (Step 1 → Step 2), they hit the upload screen, fill in the form, select a PDF, and get an error "Model not configured." The checklist does not warn about this dependency.

- **Step 3 (Take Practice Quiz)** requires subjects to exist AND questions to exist. If the user has a subject with seed topics but no uploaded source (no questions), the practice screen shows an empty state. The checklist step navigates to `SubjectSelectionScreen`, not to an actual practice session.

- **Step 4 (Schedule AI Tutor)** requires a study plan to exist. The planner screen for a new user shows three empty tabs with no "what to do first" guidance.

**Rationale:** Following the checklist in order should work without unexpected errors. Hidden dependencies that cause the user to hit error screens after filling in forms create frustration and erode trust.

**Acceptance Criteria:**
- [ ] Each checklist step should show a subtle hint if its dependencies aren't met (e.g., Step 2: "Requires API key — configure in the banner above")
- [ ] Step 2 (Upload) should check API key existence before navigating and show a clear message if missing
- [ ] Step 3 should check if subjects exist first. If subjects exist but no questions, show a helpful message asking the user to upload materials
- [ ] Step 4 should guide the user to create a plan first, then schedule a lesson

---

### MAJOR FAIL: #5 — Auto-Created Topics Are Not Visible After Subject Creation

**Files:**
- `lib/features/subjects/presentation/subject_selection_screen.dart:138-144` (SnackBar shows count only)

**Description:** When a user creates "IB Chemistry" (matching seed data), the system auto-creates 9 topics with 27 subtopics in the background. The only feedback is a SnackBar: "Topics auto-created (9)". The user cannot:
1. See WHAT topics were created
2. Verify they match the expected syllabus
3. Edit or remove topics before proceeding
4. Understand that "Stoichiometric Relationships" now exists as a topic

The topics are only visible by navigating to: Subjects tab → tap "IB Chemistry" → Topics tab. This is 3 navigation steps away from the creation flow.

**Rationale:** The seed topic auto-generation is a powerful feature, but hiding the results undermines user trust. If the seed data is wrong (e.g., missing a topic, using wrong exam board), the user has no way to know until they discover problems later. A "here's what we created for you" summary would build confidence.

**Acceptance Criteria:**
- [ ] After auto-creating topics, show a dialog or sheet listing the topic names (not just the count)
- [ ] Include a "Review & Edit" option that navigates to the Subject Topics tab
- [ ] For each topic, show the number of subtopics
- [ ] Add a "These topics are based on our standard IB Chemistry curriculum. You can edit them anytime." hint text

---

### MAJOR FAIL: #6 — Upload Prompt After Subject Creation Doesn't Check API Key Readiness

**Files:**
- `lib/features/subjects/presentation/subject_selection_screen.dart:162-178` (upload prompt dialog)
- `lib/features/upload/presentation/upload_screen.dart:218-224` (model check)

**Description:** After creating "IB Chemistry," a dialog appears: "Subject created successfully! Upload material for IB Chemistry?" with "Upload Material" and "No Thanks" buttons. Tapping "Upload Material" takes the user to `UploadScreen`. If the user hasn't configured an API key (which is likely, since ApiKeyBanner may still be visible), the upload will fail with "Model not configured."

The dialog should check whether an API key exists before offering upload, or at minimum warn about the requirement.

**Acceptance Criteria:**
- [ ] Before showing the upload prompt dialog, check if an API key is configured
- [ ] If no API key, show a modified dialog: "You'll need to configure an API key first to upload and process content. Would you like to configure it now?" with buttons "Configure API Key" and "Maybe Later"
- [ ] If API key exists, show the current behavior unchanged

---

### MAJOR FAIL: #7 — API Configuration Screen Has No "Where to Get Started" Guidance

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart` (entire screen)

**Description:** The `ApiConfigScreen` presents a provider dropdown, API key field, base URL, model name, and test connection button. For a new user, none of these are self-explanatory:

- Provider dropdown offers OpenRouter, Ollama, OpenAI — but no explanation of what each is or why to choose one
- API key field offers no hint about where to register
- Model field requires knowing the model name string (e.g., "gpt-4o", "claude-3-opus")
- Base URL is pre-filled but the user doesn't know what it means or when to change it
- No "What's the difference?" help section
- No links to provider signup pages

**Rationale:** The API config screen is a developer-facing interface. For a student user, it needs to be approachable with clear guidance.

**Acceptance Criteria:**
- [ ] Add a help icon or "?" button next to each field with plain-language explanation
- [ ] Add "Recommended" badge next to the easiest-to-configure provider (likely OpenRouter)
- [ ] Add provider-specific help text: "Visit openrouter.ai/keys → Create account → Copy API key → Paste here"
- [ ] Consider adding a web launch button that opens the provider's API keys page
- [ ] Add default model suggestions per provider
- [ ] Consider a simplified "Quick Setup" mode that auto-fills recommended values

---

### MAJOR FAIL: #8 — Practice Mode Grid Has No New-User Tutorial or Explanation

**Files:**
- `lib/features/practice/presentation/screens/practice_screen.dart` (mode grid)
- `lib/features/practice/presentation/widgets/practice_mode_grid.dart`
- `lib/features/practice/presentation/widgets/practice_empty_state.dart`

**Description:** After creating a subject and uploading materials, a new user reaches the Practice tab and sees 6 mode cards: Quick Practice, Spaced Repetition, Topic Focus, Weak Areas, Exam Mode, Source Practice. The subtitles are short ("Practice", "Review", "Focus", etc.) and don't explain:
- What "spaced repetition" means
- Why "weak areas" would have data (the user has no performance history)
- What differentiates Exam Mode from Quick Practice
- Which mode a beginner should start with

There is no tutorial overlay, no "Recommended for you" badge, no onboarding tooltip for the practice screen. Once `PracticeEmptyState` disappears (because there's at least one question), the user is on their own.

**Rationale:** The practice screen is the core learning interface. New users need guidance to understand which mode suits their current state. Presenting 6 equally-styled options without differentiation creates choice paralysis.

**Acceptance Criteria:**
- [ ] Add a "First practice?" hint banner at the top when the user has <5 practice sessions
- [ ] Add brief tooltip text to each mode card explaining when to use it
- [ ] Consider highlighting "Quick Practice" as the recommended starting point for new users
- [ ] Add a "Recommended for beginners" badge on appropriate modes
- [ ] Consider a one-time tutorial overlay on the first visit to the practice screen

---

### MAJOR FAIL: #9 — Planner Screen Has No Welcome/Orientation for First-Time Visitors

**Files:**
- `lib/features/planner/presentation/planner_screen.dart` (entire 1510-line screen)
- `lib/features/planner/providers/planner_providers.dart`

**Description:** When a new user navigates to the Planner (via checklist Step 4 or the nav), they see three empty tabs:

1. **Study Plan** — Shows the multi-syllabus form with fields for Subject Name, Days, Hours Per Day. No explanation of what this form does, no pre-filled values, no example text.
2. **Calendar** — An empty calendar grid with no events.
3. **Roadmaps** — "No roadmaps yet" with a "Create Roadmap" button.

There is no welcome message, no "Here's how to create your first study plan" guidance, no suggestion to type "Learn IB Chemistry in 90 days." The user who tapped "Schedule AI Tutor" from the checklist doesn't intuitively know they need to fill in a form to generate a plan first.

**Rationale:** The Planner is one of the most complex screens. Without orientation, a new user will be confused about what to do. The checklist sends them here expecting to schedule a tutor, but the planner requires plan generation as a prerequisite.

**Acceptance Criteria:**
- [ ] When no plan exists and the user has subjects, show a welcome card: "Let's create your study plan! Tell me what you want to learn and for how long."
- [ ] Pre-fill the subject dropdown with the user's existing subject(s)
- [ ] Add example text: "e.g., 90 days, 2 hours per day"
- [ ] Consider a one-time tutorial overlay on first planner visit
- [ ] Add a "Not sure? Try Quick Plan" button that auto-generates with sensible defaults

---

### MINOR FAIL: #10 — "Don't Show Again" on ApiKeyBanner Has Identical Behavior to "Dismiss"

**Files:**
- `lib/main.dart:597-611` (ApiKeyBanner callbacks)

**Description:** The `ApiKeyBanner` has three buttons: "Configure Now," "Don't Show Again," and "Dismiss." The "Don't Show Again" and "Dismiss" buttons both execute identical code:
```dart
setState(() => _apiKeyBannerDismissed = true);
Hive.openBox(HiveBoxNames.settings).then((box) {
  box.put(_bannerDismissedTimeKey, DateTime.now().millisecondsSinceEpoch);
});
```
Both store a timestamp and re-show the banner after 1 week (`Timeouts.week.inMilliseconds`). The user tapping "Don't Show Again" expects the banner never to return, but it returns after a week — same as "Dismiss."

**Acceptance Criteria:**
- [ ] "Don't Show Again" should store a permanent flag (e.g., `apiKeyBannerPermanentlyDismissed: true`) that prevents re-show regardless of time elapsed
- [ ] "Dismiss" should continue the current behavior (re-show after 1 week)
- [ ] OR remove "Don't Show Again" since it doesn't behave as labeled

---

### MINOR FAIL: #11 — "Take Practice Quiz" Navigates to Mode Selection, Not Direct Practice

**Files:**
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:47` (step 3 onTap)

**Description:** Checklist Step 3 is labeled "Take Practice Quiz" and navigates to `AppRoutes.subjectSelection`. After selecting a subject, the user reaches the Practice tab's mode grid — not an actual practice session. The label implies a one-tap quiz experience, but the user must still select a practice mode (and understand what each mode does).

**Acceptance Criteria:**
- [ ] Step 3 should navigate to the Practice tab with the subject pre-selected and the Quick Practice mode auto-launched
- [ ] If the user has questions, the practice session should start immediately
- [ ] Update the label to "Start Practicing" to better reflect the multi-step nature

---

### MINOR FAIL: #12 — No Milestone or Celebration When Checklist Completes

**Files:**
- `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart:17-23` ("All Caught Up" state)

**Description:** When all 4 checklist steps are complete, the checklist shows an `EmptyStateWidget` with a checklist icon, "All Caught Up" title, and the generic "Getting Started" description. There is no celebration animation, no confetti, no "You're ready to learn!" message, no "Here's what you can explore next" suggestions. The user transitions from a guided checklist to a completely unguided experience with no acknowledgment.

**Acceptance Criteria:**
- [ ] Show a brief celebration animation or confetti when the last checklist item is completed
- [ ] Add a personalized success message: "Great job setting up, [User]! You're ready to start learning IB Chemistry."
- [ ] Below the celebration, show 2-3 suggested next actions: "Take a practice quiz," "Try your first AI tutor lesson," "Ask the Mentor a question"
- [ ] After dismissal, transition to the normal Dashboard with data cards

---

### MINOR FAIL: #13 — LocalDataNotice Shown Before User Has Any Data

**Files:**
- `lib/main.dart:457-462` (LocalDataNotice shown in _handleFirstLaunch)

**Description:** After the onboarding dialog, the `LocalDataNotice` dialog appears: "StudyKing stores all your data locally on this device. To avoid data loss, use the Backup & Restore feature in Settings." This is shown BEFORE the user has any data to back up. A first-time user cannot meaningfully act on this information — they just read it and tap "I Understand," adding extra dialog friction at the worst possible time (before they've even seen the main screen).

**Acceptance Criteria:**
- [ ] Show the LocalDataNotice after the user has created meaningful data (e.g., after first upload, after first practice session, or after closing the app for the first time)
- [ ] OR replace the dialog with a less intrusive banner/inline notice on the Settings → Backup page
- [ ] OR keep it but integrate it into the onboarding carousel as a 7th page instead of a separate dialog

---

### PARTIAL: #14 — Plan Generation May Fail for New Users Due to Empty Mastery State

**Files:**
- `lib/features/planner/services/personal_learning_plan_service.dart:133-144`

**Description:** As noted in `dry_run_result_syllabus_driven_curriculum.md` (Step 3, status: PARTIAL), plan generation for a new user with empty `topicMastery` may produce a broken/empty plan because the `courseName` extraction fails and the empty-mastery bypass at line 133 is skipped. This is an existing known issue, referenced here for completeness.

**Acceptance Criteria:**
- [ ] See `dry_run_result_syllabus_driven_curriculum.md` for existing acceptance criteria

---

### PASS: #15 — Skeleton Loading During Dashboard Data Fetch

**Files:** `lib/features/dashboard/presentation/dashboard_screen.dart:122, 161-162`

**Description:** During initial loading (before data providers return), `showSkeleton` is `true` and a skeleton loading UI is shown. This provides visual feedback while data loads. Once data arrives, the skeleton transitions to the card layout. ✓

No changes needed.

---

## Summary of Findings

| ID | Severity | Finding | Status |
|---|---|---|---|
| #1 | **MAJOR** | No splash/loading screen during startup — blank screen for 2-5s | NEW |
| #2 | **MAJOR** | Onboarding doesn't explain what API keys are or where to get them | NEW |
| #3 | **MAJOR** | Dashboard shows 8-10 empty cards below checklist for new users | NEW |
| #4 | **MAJOR** | Checklist steps have hidden dependencies not communicated to user | NEW |
| #5 | **MAJOR** | Auto-created topics only show count, not names — no review option | NEW |
| #6 | **MAJOR** | Upload prompt after subject creation doesn't check API key readiness | NEW |
| #7 | **MAJOR** | API Config screen lacks "where to get started" guidance for new users | NEW |
| #8 | **MAJOR** | Practice mode grid has no tutorial/explanation for new users | NEW |
| #9 | **MAJOR** | Planner screen has no welcome/orientation for first-time visitors | NEW |
| #10 | **MINOR** | "Don't Show Again" on ApiKeyBanner behaves identically to "Dismiss" | NEW |
| #11 | **MINOR** | "Take Practice Quiz" navigates to mode selection, not direct practice | NEW |
| #12 | **MINOR** | No milestone celebration when checklist completes | NEW |
| #13 | **MINOR** | LocalDataNotice shown before user has any data (extra friction) | NEW |
| #14 | **PARTIAL** | Plan generation may fail for new users (known from syllabus scenario) | EXISTING |
| #15 | **PASS** | Skeleton loading during dashboard data fetch works correctly | — |

**Total new findings: 13 (9 MAJOR, 4 MINOR) + 1 existing PARTIAL + 1 PASS**

## Key Files Referenced

| File | Key Lines | Role |
|---|---|---|
| `lib/main.dart` | 134-238, 446-482, 597-611 | Startup, onboarding flow, ApiKeyBanner |
| `lib/features/onboarding/presentation/onboarding_dialog.dart` | 143-181, 216-271 | 6-page carousel, ApiKeyBanner widget, LocalDataNotice |
| `lib/features/onboarding/services/onboarding_service.dart` | 16-25, 27-45 | First-launch detection, completion flags |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | 100-150, 149-300 | Empty state handling, card layout |
| `lib/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart` | 1-264 | 4-step checklist with navigation |
| `lib/features/dashboard/data/models/dashboard_models.dart` | 184-209 | ChecklistProgress model |
| `lib/features/dashboard/providers/dashboard_data_providers.dart` | 255-288 | Checklist progress computation |
| `lib/features/subjects/presentation/subject_selection_screen.dart` | 66-178, 98-149 | Subject creation, seed topic auto-creation |
| `lib/features/subjects/data/curriculum_seed_data.dart` | 539-546, 31-537 | Seed data for IB Chemistry (9 topics) |
| `lib/features/settings/presentation/api_config_screen.dart` | 1-452 | API key, provider, model configuration |
| `lib/features/practice/presentation/screens/practice_screen.dart` | 1040-1077 | Practice empty state, mode grid |
| `lib/features/practice/presentation/widgets/practice_empty_state.dart` | 1-32 | Empty practice state widget |
| `lib/features/planner/presentation/planner_screen.dart` | 1-1510 | Planner tabs, multi-syllabus form |
| `lib/features/planner/services/personal_learning_plan_service.dart` | 133-144 | Empty mastery handling in plan generation |
| `lib/features/upload/presentation/upload_screen.dart` | 218-224 | API key check during upload |
| `lib/core/data/hive_initializer.dart` | 1-79 | Hive box initialization (~25 boxes) |
| `lib/l10n/generated/app_localizations_en.dart` | 3600-3646 | Onboarding text strings |
