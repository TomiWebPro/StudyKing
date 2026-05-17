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
