# Dry-Run Scenario: Creating and Tracking Study Roadmaps — The Milestone Planning Journey

## Persona

I'm a student who has been using StudyKing for about two weeks. I'm studying **IB Chemistry** with a 90-day study plan. I've attended a few tutor lessons and completed several practice sessions. Now I want to use the **Roadmaps** feature to create a structured long-term learning path with milestones. I want my roadmaps to be linked to my actual subjects, track my progress visually, and evolve as I complete my studies.

---

## Step 1: Discovering the Roadmaps Tab

I open the Planner screen (via Dashboard or direct tab). I see a `TabBar` with 3 tabs: **Study Plan**, **Calendar**, **Roadmaps**. I've been using Study Plan and Calendar tabs already, but I've never tapped the third tab.

**What I expect:** A clear explanation of what roadmaps are and how they help me. Maybe a small intro card: "Roadmaps help you break long-term goals into weekly milestones." Or at minimum, a "Create Roadmap" button.

**What I see:** I tap the **Roadmaps** tab. An empty state appears with a map icon and "No roadmaps yet" text. Below it is the hint text from `l10n.roadmapGoalHint`: "e.g., I want to learn IB Physics in 180 days" — same text from the create dialog. This is fine for indicating what to do next.

There's a prominent "Create Roadmap" button at the top. Good.

**But there's a problem — the loading spinner is dead code.** Before the empty state appeared, there was no loading indicator. The `CircularProgressIndicator` at `planner_screen.dart:1150-1153` checks `state.isLoadingRoadmaps`, which is initialized to `false` at `planner_providers.dart:139`. And in `loadRoadmaps()` (lines 251-266), `isLoadingRoadmaps` is **never set to `true`** — it only transitions from `false` to `false`. The loading spinner can never appear. If the Hive read is slow (e.g., many roadmaps), the user sees nothing for a moment, then the list appears — a blank flash with no feedback.

**Verdict (MINOR FAIL):** The loading spinner is dead code. `isLoadingRoadmaps` is never set to `true` in `loadRoadmaps()` at line 251.

---

## Step 2: Creating a Roadmap — The Dialog

I tap "Create Roadmap". A dialog appears with 3 fields:

1. **Goal** — a multi-line text field. I type: "Master IB Chemistry"
2. **Days** — a number field. I type: "90"
3. **Subject (optional)** — a text field with the hint text shown as a locale key name (it actually says "subjectIdHint" or a raw string like "Enter subject ID" — this is the `l10n.subjectIdHint` value).

**What I expect:** Field 3 should be a dropdown of my existing subjects (IB Chemistry, IB Physics). I should be able to select "IB Chemistry" and have the roadmap auto-populate milestones based on my Chemistry syllabus topics.

**What I actually see:** Field 3 is a plain `TextField` (`planner_screen.dart:292-298`). I have to type a **raw UUID subject ID**. There is no way for a normal user to know the subject's internal UUID. The `_allSubjects` list is loaded in `initState` (lines 75-88) and is already available in the same class, but it's used only for the Study Plan tab's multi-syllabus input — it is never offered as a picker for the roadmap dialog.

**The subject-picker pattern already exists** in `_buildMultiSyllabusInput()` (lines 542-658), which uses a `DropdownButtonFormField<Subject>` populated from `_allSubjects`. This exact pattern could have been reused for the roadmap dialog's subject field.

**What happens if I leave subject empty:** That's fine — the roadmap creates generic "Week N" milestones with no topic coverage. But the `days` field has a silent fallback: if I enter non-numeric text (e.g., "ninety"), `int.tryParse` returns `null`, and the code falls back to `30` days with no user feedback (`planner_screen.dart:326`). I'd think I created a 90-day roadmap but actually got 30.

**Verdict (MAJOR FAIL):** The subject field is a raw-ID textbox requiring UUID-level knowledge. No subject picker dropdown, despite the `_allSubjects` list being available in the same class. The days field silently defaults to 30 on invalid input with no user feedback.

---

## Step 3: The Generated Roadmap — Milestones Have No Context

Even without a subject, I tap "Generate Roadmap." The dialog closes, and a snackbar appears: **"Learning Goal"** — that's the `l10n.roadmapGoal` string being misused as a success message (`planner_providers.dart:398`). Instead of "Roadmap created!" or "Roadmap 'Master IB Chemistry' created.", I see the literal text "Learning Goal." This is confusing — what just happened? Was my roadmap created or not?

The roadmap appears as a card in the list. It shows:
- Status badge: "In Progress" (primary color — the same color as "Completed")
- Goal: "Master IB Chemistry"
- Progress bar: 0%
- Milestones: "0/13 Milestones"
- Target completion date
- 13 checkboxes labeled "Week 1" through "Week 13"
- A milestone timeline at the bottom

**What I notice immediately:**

1. **Milestones are generic.** Every milestone is just "Week N" — no topic names, no descriptions beyond "Milestone for Week N." Without a subject linked, milestones have zero educational context. They're just calendar checkpoints.

2. **The milestone timeline is always shown**, even before I check off any milestones. The `MilestoneTimeline` widget at `roadmap_card.dart:145` renders even when all milestones are unchecked — it shows 13 empty circles in a row. This isn't incorrect, but it adds visual noise without conveying information.

3. **Active and Completed statuses use the same color.** At `roadmap_card.dart:29-33`: both `'active'` and `'completed'` statuses render with `theme.colorScheme.primary`. I can't tell at a glance which roadmaps are in progress vs. finished. A later scenario step tests this.

**Verdict (MAJOR FAIL):** Success message is wrong — `l10n.roadmapGoal` ("Learning Goal") is displayed instead of a meaningful confirmation. Generic "Week N" milestones lack educational context when no subject is linked.

---

## Step 4: Trying to Link My Roadmap to IB Chemistry

I realize I should have used a subject. I want to link my "Master IB Chemistry" roadmap to my actual IB Chemistry subject. I look for an "Edit Roadmap" option.

**What I expect:** Tap a "More" menu on the roadmap card, or tap the roadmap itself, to see an edit screen where I can change the goal, days, or link a subject. There might be a dedicated roadmap detail page.

**What actually happens:** There is no way to edit a roadmap. There is no:
- Edit button on the card
- Tap-to-open on the card (tapping the card does nothing — it's a `RoadmapCard` with no `onTap`)
- Dedicated roadmap detail screen (the `roadmapOverview` l10n string is defined but **never used** in any code)
- Delete functionality (cannot delete a roadmap once created — `RoadmapRepository.deleteRoadmap()` exists but no UI calls it)
- "More" menu (⋮) on the card

**I am stuck with my unlinked roadmap forever.** The only interaction allowed is toggling milestone checkboxes.

**Verdict (BLOCKER FAIL):** Roadmaps cannot be edited, deleted, or linked to a subject after creation. There is no roadmap detail screen. Once created, the roadmap is permanent with no modification options.

---

## Step 5: Toggling a Milestone — I Check Off Week 1

I tap the checkbox for "Week 1" to mark it complete. The checkbox fills, the title gets strikethrough, and the progress bar advances to ~8%.

**What I expect:** A snackbar confirming "Milestone completed!" or similar. Maybe I can undo it if I tapped by mistake.

**What actually happens:** The milestone toggles successfully. But:

1. **No success feedback** — `toggleMilestoneCompletion()` at `planner_providers.dart:405-423` calls the service and reloads roadmaps, but sets **no success message**. The only feedback is the visual checkbox change — which happens after a full reload, creating a brief flash where the old state is shown, then the new state.

2. **No optimistic update** — The notifier always waits for the full service call + Hive write + full re-fetch before updating the UI. A simple checkbox toggle triggers an async chain that can take 100ms+. The UI shows no intermediate state.

3. **No undo** — Once checked, `onChanged` is set to `null` at `roadmap_card.dart:134`. The checkbox is permanently filled. The service method itself (`toggleMilestoneCompletion()` in `planner_service.dart:227-254`) accepts `isCompleted: false`, but the UI **blocks** un-checking completed milestones. If I tap by accident, there is no way to revert.

**Verdict (MAJOR FAIL):** No success feedback when toggling milestones. No optimistic update — full re-fetch causes visible flash. No undo for accidental toggle.

---

## Step 6: Creating a Second Roadmap with Subject Fully Specified

I delete the app data (impossible for a real user — but for this scenario, let's say I figure out the raw subject ID) and create a new roadmap with `subjectId: "<my IB Chemistry UUID>"`.

The roadmap now generates 13 milestones each titled "Week N" but with `topicsCovered` populated from the syllabus. The card shows each milestone with a subtitle like "3 topics" (from `l10n.topicCount`).

**But there's no visible indication of which topics.** The `CheckboxListTile` shows only `milestone.title` ("Week 1") and the topic count ("3 topics"). The actual topic names are stored in the data model but **never displayed**. I cannot see that Week 1 covers "Atomic Structure", "Subatomic Particles", and "Isotopes" — I only see "3 topics."

The `topicsCovered` data flows from `syllabusTopics` (`planner_service.dart:165-175`) through `MilestoneModel.topicsCovered` and is stored in Hive. But the `RoadmapCard` widget only shows `l10n.topicCount(milestone.topicsCovered.length)` at line 128-131 — the count, not the names. The actual topic IDs are invisible.

**Verdict (MAJOR FAIL):** Topic IDs linked to milestones are stored but not displayed. Users see only "N topics" with no way to tell which topics are assigned to which milestone.

---

## Step 7: The Milestone Timeline — Visualizing Progress

I scroll down the roadmap card to see the `MilestoneTimeline` widget. It shows a `Stack` with circles positioned horizontally based on each milestone's deadline.

**What I expect:** A visual timeline showing my 13 milestones over 90 days. Completed milestones should be visually distinct (filled, different color, checked). Overdue milestones should be highlighted in red. Upcoming milestones should show clearly.

**What actually happens:** The `MilestoneTimeline` at `milestone_timeline.dart` renders:
- A horizontal bar with circles at positions proportional to each milestone's deadline within the overall duration
- Below the bar, `Wrap` chips for each milestone with color coding: `primary` (completed), `error` (past due), `tertiary` (upcoming)

**But there's a positioning issue:** If milestones have similar deadlines (the spacing algorithm at `planner_service.dart:191-193` uses `((i + 1) * days / numMilestones).round()`), the circles may overlap when `numMilestones` is large (e.g., 13 milestones) and the screen is narrow (phone). The `Stack` widget renders circles with no overlap handling, so on a phone screen, the timeline becomes a cluster of overlapping dots that can't be distinguished.

**Verdict (MINOR FAIL):** Timeline circles can overlap on narrow screens. No overlap prevention or horizontal scrolling.

---

## Step 8: Checking Progress — Can I See Journey-Level Stats?

After two weeks of study, I check my roadmap. I've completed "Week 1" milestone (manually) and am working on Week 2.

**What I expect:** The roadmap shows some indication of how I'm tracking against the plan. Maybe "planned vs actual" progress bars, or "you're 2 days ahead of schedule" text.

**What actually happens:** The `RoadmapModel` has a `plannedVsActual` field (Hive field 9, `roadmap_model.dart:33`) that is **never populated** by any code. It is initialized as `null` and never written to. There is no display of planned-vs-actual progress anywhere on the roadmap card or timeline.

The `completionPercentage` is calculated purely from the ratio of completed milestones to total milestones — it does not consider actual time elapsed vs. plan elapsed.

If I'm 14 days into a 90-day plan (15.5% of time elapsed) and have completed 1 of 13 milestones (7.7%), the roadmap doesn't warn me that I'm behind. The progress bar shows 7.7% without any "trailing behind" indicator.

**Verdict (MAJOR FAIL):** `plannedVsActual` field exists in the model but is never populated. No indication of schedule adherence or being behind/ahead of plan.

---

## Step 9: Auto-Completion of Milestones — Does Daily Study Count?

I complete a tutor lesson on "Atomic Structure" and a practice session on the same topic. My daily plan adherence is recorded. My roadmap has "Week 1" with `topicsCovered: ["atomic-structure-id", "subatomic-particles-id"]`.

**What I expect:** Since the "Atomic Structure" topic ID matches my Week 1 milestone's `topicsCovered`, the milestone should be auto-completed when my daily plan adherence is recorded.

**What actually happens:** The `PersonalLearningPlanService.linkDailyPlanToRoadmap()` method (lines 500-529) iterates active roadmaps and checks if any completed topic ID matches a milestone's `topicsCovered`. This is called from `recordDailyAdherence()` at line 492.

**But there's a problem:** The auto-completion path runs inside `PersonalLearningPlanService.recordDailyAdherence()`, which is called from `PlanAdapter.recordFromTutorSession()` and `PlanAdapter.recordFromFocusSession()`. But `PlannerNotifier.linkDailyPlanToRoadmap()` (lines 621-629) — the notifier-level method that could update the planner state after auto-completion — is **never called from any UI code**. It's dead code.

This means: even if auto-completion fires in the service layer, the roadmap state in the UI is **not refreshed**. The roadmap card still shows the old milestone state until the user manually navigates away and back (triggering `loadInitialData()`).

**Verdict (MAJOR FAIL):** Auto-completion of milestones runs in the service layer but doesn't update the planner notifier state. The UI shows stale milestone data until the user triggers a reload.

---

## Step 10: The Wrong l10n Key Cascade

I delete my roadmap (which I can't do in the UI, but let's say I could via code) and create a new one. The success snackbar shows "Learning Goal."

**What I expect from the localization system:** Each featkey should be meaningful and intentional.

**What the data shows:** The `roadmapGoal` key is defined in both English and Spanish ARB files:
- **English:** "Learning Goal" 
- **Spanish:** "Meta de Aprendizaje"

These strings are appropriate for the dialog's **label text** (which is where they're primarily used: `planner_screen.dart:276`), but they are **misused** as a success message at `planner_providers.dart:398`. Additionally:

- `myRoadmaps` (l10n) — defined but **never referenced** in Dart code
- `completedRoadmaps` (l10n) — defined but **never referenced** in Dart code  
- `activeRoadmapsCount` (l10n) — defined but **never referenced** in Dart code
- `roadmapOverview` (l10n) — defined but **never referenced** in Dart code (no roadmap detail screen exists)
- `roadmapGoal` — used as dialog label (correct) AND as success message (incorrect)

**Verdict (MINOR FAIL):** Four roadmap-related l10n keys are defined but never used. One key is misused as a success message. Signs of incomplete feature implementation.

---

## Step 11: Multiple Roadmaps — List Behavior

I create two roadmaps: "Master IB Chemistry" (90 days) and "Review Physics" (30 days).

**What I expect:** Roadmaps are sorted by creation date (newest first), which the repository does: `getRoadmapsByStudent()` sorts by `createdAt` descending. They each get their own card in the list.

**What I check:** The `ListView.builder` at `planner_screen.dart:1178-1196` renders them as cards. Scrolling works. Each card shows its own milestones and timeline. No issues here.

**But there's no delete gesture.** After creating a "Review Physics" roadmap I no longer need, I try to:
- Long-press → nothing happens (no `onLongPress` on the card)
- Swipe → nothing happens (no `Dismissible` wrapper)
- Tap ⋮ → there is no ⋮
- Navigate to a delete screen → there is none

The roadmap pile grows indefinitely. Old/irrelevant roadmaps clutter the list with no way to remove them.

**Verdict (BLOCKER FAIL):** Roadmaps cannot be deleted through any UI path. `RoadmapRepository.deleteRoadmap()` exists but has zero UI invocation.

---

## Step 12: The Notifier's Error Handling Gap

I simulate a scenario where `roadmapRepo.init()` fails (e.g., Hive box not opened).

**What I expect:** A clear error snackbar: "Failed to load roadmaps" or "Failed to create roadmap."

**What the code shows:** 
- `loadRoadmaps()` (line 262-264) sets `isLoadingRoadmaps: false` but does NOT set `state.error` in the catch block — the error is only logged.
- `createRoadmap()` (line 399-401) correctly sets `state.error` with `l10n.failedToCreateRoadmap`.
- `toggleMilestoneCompletion()` (line 419-421) correctly sets error with `l10n.failedToUpdateMilestone`.
- `linkDailyPlanToRoadmap()` (line 627) catches errors but silently swallows them — not even a log; the catch block is empty except for the body of `call()`.

This inconsistent error handling means some roadmap failures show errors to the user, while others are silently swallowed.

**Verdict (MINOR FAIL):** `loadRoadmaps()` doesn't set `state.error` on failure. `linkDailyPlanToRoadmap()` silently swallows errors.

---

## Step 13: The Calendar Tab — A Missed Connection

I wonder if my roadmap milestones appear on the Planner's Calendar tab (the second tab, between Study Plan and Roadmaps).

**What I expect:** The Calendar tab shows my scheduled lessons AND roadmap milestones. Each milestone appears as a marker on its target completion date.

**What actually happens:** The Calendar tab at `planner_screen.dart:1112-1133` only renders `CalendarViewWidget` with the study plan's daily plans. It has **zero roadmap integration**. Milestone deadlines are completely absent from the calendar view.

**Verdict (MAJOR FAIL):** Roadmap milestones do not appear on the Planner Calendar tab. The two features are completely disconnected despite sharing the same screen.

---

## Step 14: Creating a Roadmap from the Mentor — A Missed Opportunity

I type to the Mentor: "Create a roadmap for me to learn IB Chemistry in 180 days."

**What I expect:** The Mentor detects my intent, asks me to confirm, and creates a roadmap in my planner.

**What actually happens:** The Mentor's `_checkAndHandlePlanningIntent()` at `mentor_service.dart:454-477` checks for keywords: `'schedule'`, `'reschedule'`, `'plan'`, `'create'`, `'generate'`, etc. The word "roadmap" is NOT in any keyword list. The Mentor treats my message as a regular chat query — it responds conversationally but does NOT create a roadmap.

The `_handlePlanIntent()` method (line 535) detects if keywords like "plan" are present and adds a system message about the planner. But "roadmap" is not included, and there is no `_handleRoadmapIntent()` method anywhere.

**Verdict (MAJOR FAIL):** The Mentor cannot create roadmaps through conversation. The word "roadmap" is not in any intent detection keyword list, and no roadmap-related intent handler exists.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Loading spinner shows during roadmap load | `isLoadingRoadmaps` never set to `true` — spinner is dead code | FAIL (MINOR) |
| 2 | Subject field is a dropdown of existing subjects | Raw UUID textbox; `_allSubjects` exists but unused | FAIL (MAJOR) |
| 3 | Invalid days input shows error feedback | Silently defaults to 30 days with no user notification | FAIL (MAJOR) |
| 4 | Success snackbar says "Roadmap created!" | Wrong key `roadmapGoal` — shows "Learning Goal" | FAIL (MAJOR) |
| 5 | Milestones show topic names from syllabus | Only shows "N topics" count — topic names invisible | FAIL (MAJOR) |
| 6 | I can edit/delete a roadmap after creation | No edit UI; no delete UI; `deleteRoadmap()` exists but unreachable | FAIL (BLOCKER) |
| 7 | Active and Completed roadmaps look different | Same `colorScheme.primary` — visually identical | FAIL (MINOR) |
| 8 | Milestone toggle shows success feedback | No success message; full re-fetch causes flash | FAIL (MAJOR) |
| 9 | Accidental milestone toggle can be undone | `onChanged: null` when completed — permanently checked | FAIL (MAJOR) |
| 10 | `plannedVsActual` tracks schedule adherence | Hive field exists but never populated — dead storage | FAIL (MAJOR) |
| 11 | Auto-completion of milestones refreshes UI | Service layer runs but notifier state not updated — stale display | FAIL (MAJOR) |
| 12 | Roadmaps can be deleted from the UI | No swipe, no long-press, no menu — indefinite list growth | FAIL (BLOCKER) |
| 13 | Roadmap milestones appear on Calendar tab | Calendar only shows study plan — zero roadmap integration | FAIL (MAJOR) |
| 14 | Mentor can create roadmaps through conversation | "roadmap" not in intent keywords; no handler method | FAIL (MAJOR) |
| 15 | 4 l10n keys (myRoadmaps, completedRoadmaps, etc.) are used | Defined in ARB but never referenced in Dart code | FAIL (MINOR) |
| 16 | `loadRoadmaps()` failures show user-visible error | Error logged but `state.error` not set | FAIL (MINOR) |
| 17 | `linkDailyPlanToRoadmap()` errors are surfaced | Catch block silently swallows errors | FAIL (MINOR) |
| 18 | Timeline circles don't overlap on narrow screens | No overlap handling for 13+ milestones on phone | FAIL (MINOR) |
| 19 | Success message uses correct l10n key for roadmap creation | `roadmapGoal` ("Learning Goal") misused as success message | FAIL (MAJOR) |
| 20 | `PlannerNotifier.linkDailyPlanToRoadmap()` is wired to UI | Dead code — never called from any screen | FAIL (MAJOR) |
