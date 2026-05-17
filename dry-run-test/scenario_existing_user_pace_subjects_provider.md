# Dry-Run Scenario: Existing User Adjusting Pace, Adding Subjects, Switching Providers

## Persona

I'm a student who has been using StudyKing for a few weeks to learn **IB Physics**. I've accumulated some practice data, I have a study plan, and I've scheduled a few AI tutor lessons. I'm comfortable with the basics but now I need to make significant adjustments to how I use the app.

---

## Step 1: Reviewing My Progress

I open the app and tap the Dashboard button (FAB). I expect to see a summary of how I'm doing: my adherence to my study plan, my topic mastery, recent session history, and weak areas.

**What I expect:** A clean overview showing my Physics progress — which topics I've mastered, which I'm weak in, how consistently I've been studying, and my study streak.

**What I see:** All dashboard cards render with real data from my sessions and practice attempts. The dashboard shows:
- Summary row with total questions, accuracy, study time
- Weekly activity chart spanning 8 weeks
- Plan adherence card showing average adherence and weekly breakdown
- Mastery overview, weak areas, and topic breakdown cards
- Badges card if I've earned any
- Export section at the bottom

**Verdict (PASS):** The dashboard works for a returning user with data. However, it's very long — I have to scroll through 10+ cards to see everything. On a phone, the export section is way at the bottom, invisible without scrolling.

---

## Step 2: Slowing Down My Pace — Physics is Harder Than Expected

IB Physics is tougher than I thought. I'm falling behind on my plan. I go to the Planner to adjust my pace.

**What I expect:** A "Slow down" or "Adjust pace" control. Maybe a slider that lets me say "I want 1 hour per day instead of 2" or "Extend my plan from 90 to 120 days." I expect the app to recalculate my schedule gently without deleting what I've done.

**What I find:**
- The Planner shows my existing plan and an adherence deviation banner if I've been missing sessions (it appears after 3+ consecutive low-adherence days)
- The adherence banner offers two buttons: **Redistribute** (spreads missed minutes across next 3 days) and **Regenerate Plan** (recalculates from current adherence)
- There is NO dedicated pace adjustment control. To change from 2 hrs/day to 1 hr/day, I would need to:
  1. Use the generate plan form at the bottom of the Study Plan tab
  2. Enter a new course name, new days, new hours
  3. Tap "Generate Plan" — which **creates an entirely new plan**, discarding the old one

**Problems:**
- There is no way to *modify* an existing plan's targets — only replace it entirely
- If I change the `course` name (e.g., "IB Physics — slow pace"), it has no impact on what's generated (the course name is just a metadata label)
- The "Redistribute" button only handles missed minutes from the *past*, not ongoing pace adjustment
- Regenerating from adherence bases the new plan on my *existing* mastery data, which is what I want, but there's no way to see what's *about* to be generated before committing

**Verdict (PARTIAL):** I can technically slow down by regenerating with different parameters, but there's no explicit "adjust my pace" UX. The regenerate-from-adherence flow handles some of this, but it's not user-friendly and doesn't communicate what will change.

---

## Step 3: Switching AI Provider — Moving from OpenRouter to Local Ollama

I want to switch from OpenRouter (paid API) to my local Ollama instance (free, runs on my laptop).

**What I expect:** Go to Settings → API Config, change the provider dropdown from "OpenRouter" to "Ollama", see the base URL auto-update, enter my Ollama API key (or leave it blank since Ollama doesn't require one), save, and have all AI features immediately use the new provider.

**What actually happens:**

1. I go to **Settings** → tap **API Keys** (listed under AI Configuration)
2. The ApiConfigScreen shows a provider dropdown, API key field, and base URL field
3. I change the dropdown to "Ollama" — the base URL **does** auto-fill to `http://localhost:11434` ✓
4. I tap "Save" — settings are persisted ✓
5. I go back to Settings → tap **AI Model** to select an Ollama model
6. The model selection sheet tries to fetch models from the API using my current API key... but my Ollama API key field is empty (Ollama doesn't need one, and the config screen accepted an empty key)
7. The model list shows all available Ollama models ✓ (the test worked because Ollama doesn't require a key)

**But here's where it goes wrong:**

- The model I previously had selected (`mistralai/mixtral-8x7b-instruct` — an OpenRouter model ID) is **still selected**. Nothing warns me that this model doesn't exist on Ollama. The Tutor and Mentor will silently fail or error when they try to use this model ID against the Ollama API.
- The ApiConfig screen saves the provider switch, but **does not clear or reset the selected model**.
- If I later switch back to OpenRouter, the base URL stays as `http://localhost:11434` — I'd have to remember to manually change it back.

**Verdict (MAJOR FAIL):** Switching providers preserves the old provider's model ID and does not reset the base URL on provider change (except Ollama which auto-fills). The user will encounter silent failures in Tutor/Mentor until they manually select a compatible model.

---

## Step 4: Cancelling a Scheduled Physics Lesson

I have a Physics lesson scheduled for 3 PM today, but I have a conflict. I need to cancel it.

**What I expect:** Go to the Planner → see my scheduled lesson → tap it → see a "Cancel" or "Reschedule" button.

**What actually happens:**

1. I'm on the Planner screen, Study Plan tab
2. At the top, under "Scheduled Lessons", I see up to 3 upcoming lessons
3. Each lesson is displayed as a **read-only ListTile**: topic title, date, time — **no cancel or reschedule buttons**
4. If I have more than 3, I see a "View X more" link that navigates to the Lesson List screen
5. On the Lesson List screen, I see all my lessons as tappable items
6. Tapping a lesson opens **LessonDetailScreen** — which shows the lesson content and blocks but **has no cancel or reschedule option**
7. There is no button to cancel a scheduled lesson anywhere in the visible UI

**The cancelLesson() function exists in PlannerService** (`planner_service.dart:273`), but:
- There is no UI button that calls it
- The PlannerNotifier has no `cancelLesson()` or `rescheduleLesson()` method
- The LessonBookingSheet only creates *new* lessons — it doesn't support editing existing ones
- There is no "reschedule" function at all (the service has `cancelLesson` but no `rescheduleLesson`)

**What I have to do:** There's literally no way to cancel a lesson through the UI. I'd have to either:
- Navigate to Session History, find the tutoring session, and... sessions don't have a cancel action either
- There is no user-facing way to cancel a scheduled lesson

**Verdict (BLOCKER FAIL):** Scheduled lessons are displayed but cannot be cancelled or rescheduled through any UI path. The cancelLesson service method exists but has no connected UI.

---

## Step 5: Adding Chemistry Alongside Physics

I want to start learning **IB Chemistry** while continuing Physics. I already have Physics set up.

**What I expect:** Add a second subject, then create a study plan that covers both.

**What happens:**

1. I go to the Subjects tab → tap "+" → fill in "IB Chemistry" → save
2. Subject is created successfully ✓
3. After creating Chemistry, the app prompts: "Would you like to upload material?" ✓ (good)
4. I go to the Planner to create a plan that includes both Physics and Chemistry

**The problem:** The Planner's `generatePlan()` form has a single text field for "Course/Subject". I type "IB Chemistry & Physics" — but this is just a label. The plan generation uses only my existing mastery state (which is Physics-heavy) and generates recommendations from it. Chemistry topics don't exist in my mastery state because I've never practiced Chemistry.

So the plan is still Physics-only. The `generatePlanFromSyllabus` method exists and accepts `SyllabusGoal` objects (which could represent multiple subjects), but:
- There's no UI for creating `SyllabusGoal` objects from existing subjects
- The planner screen's form doesn't let me select which subjects to include
- The form just has a text field that does nothing useful

**Verdict (PARTIAL):** I can add a second subject, but the planner can't create a multi-subject study plan. The `generatePlanFromSyllabus` method has the right interface but no UI connects to it.

---

## Step 6: Editing Subject Details — Fixing a Typo

I noticed I misspelled my Chemistry subject name. Let me fix it.

**What I expect:** Long-press or tap a "More" menu on the subject → "Edit" → change name → save.

**What actually happens:**

1. I tap on Chemistry in the Subject List
2. I see the SubjectDetailScreen with 4 tabs (Lessons, Practice, History, Stats)
3. In the top-right, there's a "More" (⋮) icon
4. I tap it — I see: **Upload Content**, **Dashboard**, **Delete Subject**
5. **There is no "Edit Subject" option.** I cannot change the name, code, teacher, syllabus, or description of a subject after creation. The only way to fix the typo is to delete the subject and recreate it.

**Even worse:** If I tap "Delete Subject":
1. A confirmation dialog appears
2. I confirm
3. The screen just pops back — **the subject is NOT actually deleted from the repository** (`_confirmDelete` at `subject_detail_screen.dart:249` only calls `Navigator.pop(context)` twice — it never calls `repo.delete()`)

**Verdict (MAJOR FAIL):** No edit functionality for subjects. Delete is broken (UI only — no actual deletion). The user is stuck with their original data.

---

## Step 7: Exporting Progress — Sharing with My Physics Teacher

I want to share my Physics progress with my teacher.

**What I expect:** A single "Export" button that gives me options (PDF report, CSV data, JSON) with all relevant data.

**What actually happens:**

1. From Dashboard, I scroll all the way down to find the Export section
2. I see three buttons: **Export CSV**, **Session History**, **Instrumentation**
3. "Export CSV" exports overall stats + weekly trend + badges as CSV
4. "Session History" navigates to SessionHistoryScreen, which has comprehensive export (CSV, PDF, JSON, comprehensive CSV/PDF/JSON)
5. "Instrumentation" exports something obscure (plan adherence + mastery improvement data)

**Problems:**
- The Dashboard only offers CSV export. PDF and JSON require navigating to a separate screen
- The Export section is at the very bottom of the dashboard — users must scroll past 10+ cards to find it
- The export buttons have no confirmation dialog showing what will be exported
- There's no single "Export full report" button on the Dashboard
- The "Instrumentation" button is confusing — most users won't know what it does

**Verdict (PARTIAL):** Export exists and works, but it's fragmented (CSV on dashboard, comprehensive on session history), buried at the bottom of a long scroll, and has unclear labeling.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Progress dashboard shows existing data | All cards render with real data | PASS |
| I can adjust study pace with dedicated controls | No pace slider — must regenerate entire plan | PARTIAL |
| Switching providers resets model selection | Old model ID persists across provider switch | FAIL (MAJOR) |
| Switching providers resets base URL correctly | Only Ollama auto-fills; OpenRouter URL stays on switch-back | FAIL (MAJOR) |
| I can cancel a scheduled lesson from the UI | No cancel button exists on any screen | FAIL (BLOCKER) |
| I can reschedule a lesson to a different time | `rescheduleLesson()` doesn't exist in service or UI | FAIL (BLOCKER) |
| Planner supports multi-subject plans | Single text field; `generatePlanFromSyllabus` has no UI | PARTIAL |
| I can edit a subject after creation | No edit option in subject menu | FAIL (MAJOR) |
| Deleting a subject actually removes it | _confirmDelete pops navigator but never calls repo.delete | FAIL (BLOCKER) |
| Export from Dashboard includes PDF/JSON options | Dashboard only has CSV; PDF/JSON buried in SessionHistory | PARTIAL |
| Export section is easy to find | At very bottom of long scroll, below 10+ cards | MINOR |
