# Dry-Run Scenario: Reviewing Study History, Tracking Sessions, and Monitoring AI Activity

## Persona

I'm a student who has been using StudyKing for a couple of weeks. I've attended 4 tutor lessons, completed 15 focus mode sessions, and answered about 80 practice questions across IB Chemistry and IB Physics. I have an API key configured and have been actively using AI features. Now I want to **review my complete study history**, **manually track a study session**, **browse my question bank**, **monitor my AI token usage**, and **back up my data**.

---

## Step 1: Looking for My Study History

I open the app and look for a way to see all my past study sessions in one place.

**What I expect:** A "Session History" or "Study Log" option somewhere easy to reach — either in the Dashboard, a tab, or the Settings menu.

**What I do first:** I check the Dashboard. I see my summary stats, weekly chart, plan adherence, mastery overview — all the aggregated data. But where's the raw session list? I scroll all the way down to the Export section. There's a button labeled **"Session History"**.

I tap it, expecting to see a list of my past study sessions with dates, durations, and types.

**What actually happens:** The button doesn't navigate anywhere — it triggers a CSV file export. A file-sharing dialog opens asking me where to save `studyking_progress_*.csv`. That's not what I wanted! The button is labeled "Session History" but it actually exports a CSV of my progress data.

**Verdict (MAJOR FAIL):** The Dashboard's "Session History" button is misleading — it performs a CSV export, not navigation to a session list. A user looking to *view* their history will be confused when a file export dialog appears.

---

## Step 2: Searching for Session History Elsewhere

I close the share dialog. Let me look elsewhere. I check each tab:

- **Subjects tab** → Subject details show per-subject stats but no session list
- **Practice tab** → Practice modes, no history
- **Mentor tab** → Chat interface
- **Focus Mode tab** → Timer interface
- **Settings tab** → No "Session History" entry

I know a Session History screen must exist — there are routes for it in the code. But I can't find a single button that navigates to it.

**Let me trace the only navigation path:**

The `SessionHistoryScreen` route (`/session-history`) is registered in the router. The **only** place that calls `Navigator.pushNamed(context, AppRoutes.sessionHistory)` is the `SessionTrackerScreen` at `session_tracker_screen.dart:410`. But the `SessionTrackerScreen` route (`/session-tracker`) is **also registered in the router** and is **also never navigated to from any code in the app**.

Both screens exist, fully implemented, with tests. Both are **completely inaccessible** through any user-facing navigation path.

**Verdict (BLOCKER FAIL):** The Session History screen and the Session Tracker screen are unreachable through any UI path. Routes exist and screens work, but there's no button, menu item, or link that navigates to either one. The Dashboard's "Session History" button does a CSV export instead of navigating.

---

## Step 3: Manually Tracking a Study Session — The Orphaned Timer

I want to track my study time manually (not using Focus Mode's pomodoro timer, just a simple stopwatch for when I'm reading a textbook).

**What I expect:** A "Manual Session" or "Study Timer" option where I can start/stop a timer and record what I studied.

**What I would find if I could reach it:** The `SessionTrackerScreen` (route `/session-tracker`) has a complete implementation with:
- Start/stop manual timer
- Session end dialog to record questions answered and correct answers
- Recent sessions list with "View All" button to Session History
- Weekly analytics chart
- Plan adherence tracking on session end
- Mastery improvement tracking

All of this is fully implemented, tested, and ready. But **no user can reach it** because the route has zero entry points.

**Verdict (BLOCKER FAIL):** The Session Tracker with its manual timer, analytics, and session recording features is completely orphaned. Zero navigation paths lead to it. The effort invested in building and testing this screen is wasted.

---

## Step 4: Finding the Question Bank

I go to **Settings → Content Management → Question Bank**.

**What I expect:** A way to browse, search, and manage all my questions.

**What I find:** The `QuestionBankScreen` loads and works. I can:
- See all my questions with type, difficulty, subject, topic ✓
- Search by text ✓
- Filter by subject, type, and source ✓
- Edit a question's text and explanation ✓
- Delete individual questions with undo ✓
- Select multiple questions for batch delete ✓
- Pull to refresh ✓

**But here are the problems:**

**Problem 1 — No direct navigation from main tabs.** The Question Bank is buried 2 levels deep in Settings → Content Management → Question Bank. There's no entry from the Practice tab (where users naturally look for questions) or the Subjects tab (where users manage subject content). The settings screen links are contextually disconnected from where users actually interact with questions.

**Problem 2 — Tapping a question from Source Detail navigates to Question Bank but loses context.** At `source_detail_screen.dart:435`, tapping a question calls `Navigator.pushNamed(context, '/question-bank')` **without any arguments**. The question bank loads fresh without scrolling to or highlighting the specific question the user tapped on. The user has to search for it again.

**Problem 3 — Can't add questions.** The Question Bank is read-only in terms of creation. There's no "Add Question" button. Users cannot create their own questions; they must rely entirely on auto-generation from the content pipeline (which as discovered in scenario 8, has `generateQuestions: false` by default) or tutor lessons.

**Verdict (PARTIAL):** Question Bank exists and is functional for browsing and managing existing questions. But it's hard to find (buried in Settings), doesn't receive navigation context from source detail, and has no question creation capability.

---

## Step 5: Monitoring AI Token Usage and Tasks

I go to **Settings → AI Configuration → AI Task Monitor**.

**What I expect:** A dashboard showing my AI usage — how many tokens I've used, what tasks are running, what they cost, and the ability to manage them (cancel stuck tasks, retry failed ones).

**What I find:** The `LlmTaskManagerScreen` loads. It shows:
- A summary bar with total tokens, total cost, done/failed counts ✓
- A list of past LLM tasks with status icons (queued, running, done, failed, cancelled) ✓
- Tokens and cost per task ✓
- Retry button for failed tasks ✓
- Cancel button for running/queued tasks ✓

**Critical problem — Data is in-memory only.** The `LlmTaskManager` and `LlmUsageMeter` are in-memory services with no persistence. Every time the app restarts:
- All task history is erased
- Token usage and cost totals reset to zero
- The beautiful token summary shows zeros
- Any failed tasks that the user wanted to retry are gone

This means the AI Task Monitor only shows useful data within a single app session. If I close and reopen the app, all usage history is lost.

**Second problem — No integration with the rest of the app.** The task monitor is a standalone screen accessible only from Settings. There's no:
- Nudge when a task fails (e.g., "Content processing failed" notification)
- Indicator on the Settings tile when there are active tasks
- Way to see task activity while doing other things (e.g., a mini indicator on the dashboard)
- Historical cost tracking (since it's in-memory)

**Verdict (MAJOR FAIL):** The AI Task Monitor has all the UI pieces for a great feature, but its data is entirely in-memory. All task history is lost on app restart. Long-term cost tracking and task management is impossible. The feature provides a snapshot of current-session activity only, which severely limits its usefulness.

---

## Step 6: Backing Up My Data

I go to **Settings → Backup & Restore**. I want to make sure my study data is safe.

**What I expect:** I can export a backup of all my data, and later restore it if needed.

**What I find:**

**Export Backup:** I tap "Export Backup". The app collects all Hive box data, writes it to a JSON file, and opens the system share sheet. I can save it to my files. ✓

**Import Backup:** I tap "Import Backup". A file picker opens for JSON files. I select a backup file. The app shows a confirmation dialog: "Importing X boxes with Y records. This will overwrite current data." I confirm. The data is written back to Hive. ✓

**Problems:**

**Problem 1 — Import overwrites ALL data with no selective restore.** The `_writeBoxData()` method at `settings_screen.dart` writes every box from the backup file to Hive without any merge logic. If I made changes since the backup and only want to restore specific items, I can't — it's all-or-nothing. The confirmation dialog warns about overwriting but doesn't let me choose what to restore.

**Problem 2 — No backup schedule or automation.** There is no automatic backup feature. The user must manually remember to export backups. Since all data is local (Hive), a phone failure means total data loss unless the user has manually exported.

**Problem 3 — API key and model config are stored with the backup.** The backup includes ALL Hive boxes, including the `settings` box which contains the API key and model configuration. Sharing a backup file via the system share sheet risks inadvertently exposing the API key if the file is shared to an unsecured destination.

**Verdict (MAJOR FAIL):** Backup and Restore works end-to-end but has critical limitations: no selective restore, no automation, and the API key is included in the backup without warning.

---

## Step 7: Exporting Data from Session History — If I Could Reach It

If I could reach the Session History screen, I would find that it offers **six export formats**: CSV, PDF, JSON (for filtered sessions), plus comprehensive CSV, PDF, JSON (full progress report). This is genuinely comprehensive.

But since I can't reach Session History, the only exports available from the Dashboard are:
- CSV (available from the Export section at the bottom)
- PDF (from the Export section)
- JSON (from the Export section)
- "Session History" button → also CSV export (misleading label)
- "Instrumentation" → JSON export of plan adherence + mastery improvement data

The Dashboard's Export section and Session History's export menu **duplicate functionality** (both offer CSV, PDF, JSON exports of comprehensive data), but the Dashboard's export is missing the per-session filtered export options.

**Verdict (MINOR FAIL):** The Session History screen has superior export options (6 formats with session-level filtering), but is inaccessible. The Dashboard's exports are a partial duplicate that lacks session-level filtering.

---

## Step 8: The Content Library — Now Accessible!

I go to **Settings → Content Management → My Uploads**. Earlier scenarios reported that uploaded materials were invisible. Let me check if this has been addressed.

**What I find:** The `ContentLibraryScreen` exists! It shows:
- All uploaded sources with type icons (PDF, video, image, etc.) ✓
- Processing status labels with color coding (pending, completed, failed) ✓
- Subject name displayed under each source ✓
- Sort by date, title, status, or type ✓
- Filter by subject, type, or processing status ✓
- Delete with confirmation and option to also delete linked questions ✓
- Swipe-to-delete ✓
- Undo on delete ✓
- Failed sources show an error icon and a reprocess button ✓
- Tapping a source navigates to Source Detail ✓
- Empty state with "Upload Materials" action button ✓

**This is significantly improved from earlier findings.** The content library now addresses most BLOCKER findings from the managing_content_library scenario.

But there are still gaps:
- No multi-select for batch operations
- Subjects are listed by their internal ID in the filter if the name can't be resolved
- The extract progress (extracting, classifying stages) only shows during upload — after upload completes, past sources show only the final status

**Verdict (PASS):** The Content Library screen resolves most major findings about invisible uploaded materials. Sources are now browseable, filterable, deletable, and their processing status is visible.

---

## Step 9: Source Detail — Viewing Extracted Content

I tap a source in the Content Library to see its details. I'm taken to the `SourceDetailScreen`.

**What I find:**
- Source metadata (status, subject, type, ID, upload date) ✓
- Failed status banner with retry button ✓
- **Topic classification** — shows the assigned topic, allows manual correction via a topic picker, and offers an AI "Classify Now" button ✓
- **AI-generated summary** — shown in a card ✓
- **Extracted text** — shown in a scrollable monospace view with a **search field** (allows searching within the extracted text!) ✓
- **Generated questions** — listed with type and difficulty, tappable to navigate to Question Bank ✓
- **Reprocess** — re-runs the full pipeline (extraction, classification, question generation) ✓
- **Delete** — with confirmation and undo ✓

**Verdict (PASS):** The Source Detail screen provides comprehensive access to all source data. Extracted text with search, AI summary, topic classification with manual correction, question list — all the gaps identified in previous scenarios have been addressed here.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| I can find and browse my session history | SessionHistoryScreen route exists but has zero navigation entry points | **FAIL (BLOCKER)** |
| The Dashboard's "Session History" shows my sessions | It's a CSV export button, not navigation | **FAIL (MAJOR)** |
| I can manually start/stop a study timer | SessionTrackerScreen route exists but is unreachable — no navigation paths | **FAIL (BLOCKER)** |
| Question Bank is easy to find from Practice/Subjects | Buried 2 levels deep in Settings → Content Management | FAIL (MINOR) |
| Tapping a question from Source Detail opens it in Question Bank | Navigates to Question Bank but loses context — no argument passing | FAIL (MAJOR) |
| I can add my own questions in the Question Bank | No "Add Question" button — read-only for review/delete | FAIL (MAJOR) |
| AI Task Monitor persists data across restarts | In-memory only — all history lost on app restart | **FAIL (MAJOR)** |
| I get notified when a task fails | No nudge or notification; must manually open the screen | FAIL (MINOR) |
| Backup & Restore allows selective item restore | All-or-nothing overwrite, no merge or selective restore | **FAIL (MAJOR)** |
| Backup automation exists | No scheduled/automatic backups | FAIL (MAJOR) |
| API key is excluded from exported backup | API key and model config included without warning | **FAIL (MAJOR)** |
| Content Library shows all uploaded sources | Fully implemented with filters, sort, status, delete | PASS |
| Source Detail shows extracted text, summary, topics | Comprehensive detail view with search, reprocess, topic assignment | PASS |
| Generated questions are visible per source | Listed in Source Detail, tappable to Question Bank | PASS |
| Failed sources can be retried | Reprocess button on both Content Library and Source Detail | PASS |
