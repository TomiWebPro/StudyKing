# Dry-Run Usability Validator — Multi-Subject Learning, API Provider Switching, Pace Adjustment & Lesson Rescheduling

**Scenario:** `scenario_multi_subject_api_provider_pace_reschedule.md`
**Validator:** Dry-Run Usability Validator
**Date:** 2026-05-20

---

## Scenario Summary

A student who has been using StudyKing for 3 weeks studying IB Physics wants to: (1) add IB Chemistry as a second subject and create a combined study plan, (2) speed up their Physics pace while keeping Chemistry at normal pace, (3) change their API provider from OpenAI to Ollama for local inference, and (4) reschedule a Physics tutoring lesson due to a conflict. The scenario traces whether the app supports multi-subject management, per-subject pace control, safe API provider switching, and correct lesson rescheduling with conflict detection.

---

## Findings

### BLOCKER FAIL: #1 — Empty Model After API Provider Switch Causes Silent AI Failures

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:150, 557`
- `lib/core/providers/llm_providers.dart:27-49`

**Description:** When the user switches API provider in the dropdown (e.g., OpenAI → Ollama), `selectedModelProvider` is immediately set to `''` (line 557). After saving and returning to the app, the user can start a Tutor lesson or Upload content — but the `LlmService` is created with `model: ''`. There is no guard anywhere that checks for empty model before AI operations. The Ollama API receives a request with no model name, resulting in an HTTP error or cryptic exception like "Failed to get chat response." The user has no indication that they need to select a model.

**Acceptance criteria:**
- [ ] On save of API config, if `selectedModel` is empty, show an error: "Please select a model before saving."
- [ ] If `selectedModel` is empty at the start of any AI operation (tutor, upload, mentor, practice generation), show a clear prompt directing the user to configure a model.
- [ ] For Ollama, add a "Fetch available models" button that queries `GET /api/tags` to list locally available models.
- [ ] The Settings screen AI Model label should show a warning icon/badge when model is empty, not just "Select model from API."

---

### MAJOR FAIL: #2 — No Incremental Subject Addition to Existing Plan

**Files:**
- `lib/features/planner/presentation/planner_screen.dart:572-575, 159-210`
- `lib/features/planner/services/planner_service.dart:545-580`
- `lib/features/planner/services/personal_learning_plan_service.dart:97-280`

**Description:** Adding a second subject to an existing plan requires regenerating the entire plan from scratch via the multi-syllabus mode toggle. There is no "Add subject to plan" or "Merge another subject into existing plan" feature. Regeneration:
- Silently replaces the current plan in the provider state without confirmation
- Loses any manual plan adjustments or customizations
- Creates a new `PersonalLearningPlan` object — adherence records from the old plan may mismatch new plan dates

**Acceptance criteria:**
- [ ] Add a "Add Subject" button in the Planner's study plan view that opens a dialog to select an existing subject and target parameters (days, hours).
- [ ] The add-subject flow merges the new subject's plan into the existing plan (appending or interleaving daily plans), not regenerating from scratch.
- [ ] Before replacing/regenerating a plan, show a confirmation dialog: "This will create a new plan. Your existing progress data is preserved but daily plan scheduling will be rebuilt."
- [ ] If the user already has a plan and toggles multi-syllabus mode, pre-fill the form with existing plan data so they can add to it rather than start over.

---

### MAJOR FAIL: #3 — No Per-Subject Pace Adjustment

**Files:**
- `lib/features/planner/presentation/planner_screen.dart:700-777`
- `lib/features/planner/services/planner_service.dart:545-580`

**Description:** The pace adjustment is a single global slider that scales ALL subjects' daily targets proportionally. If a user wants Physics at 3h/day and Chemistry at 1h/day, they cannot achieve this. The `adjustPace()` method applies a uniform ratio to all daily plans with no concept of per-subject targets.

**Acceptance criteria:**
- [ ] In multi-subject plans, show per-subject pace sliders (one per syllabus goal card) that adjust that subject's daily minutes independently.
- [ ] Each subject card in the plan should show its individual target hours/day with an edit button.
- [ ] The `PersonalLearningPlan` model should track per-subject `targetMinutesPerDay` instead of (or in addition to) the global `targetMinutesPerDay`.

---

### MAJOR FAIL: #4 — Pace Adjustment Doesn't Shorten Plan Duration

**Files:**
- `lib/features/planner/services/planner_service.dart:545-580`

**Description:** Increasing pace should theoretically allow the user to finish faster (fewer total days). But `adjustPace()` only scales daily minutes/questions — the plan maintains the same number of days. The slider label says "Hours Per Day" with no indication of how this affects completion date. There is no "target completion date" display or "I want to finish in 60 days instead of 90" option.

**Acceptance criteria:**
- [ ] The pace slider should show the estimated new completion date as the user drags: "3h/day → Finish by June 15 (was July 15)"
- [ ] Add an "Adjust Duration" option: "I want to finish Physics in 60 days" that recalculates daily targets based on remaining topic count.
- [ ] `adjustPace()` should optionally recalculate the plan end date by redistributing remaining content over fewer days (not just scaling existing days).

---

### MAJOR FAIL: #5 — Provider State Mutated Prematurely on Dropdown Change

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:553-579`

**Description:** When the user selects a different provider in the dropdown, `llmProviderProvider` is immediately updated (line 556) and `selectedModelProvider` is cleared (line 557). This happens BEFORE the user clicks Save. If the user navigates away without saving (confirming the discard dialog), these state changes are NOT reverted. Any downstream service reading `llmServiceProvider` between dropdown change and save gets an inconsistent config (new provider, empty model).

**Acceptance criteria:**
- [ ] Provider state changes should only be committed to `llmProviderProvider` on explicit Save, not on dropdown selection.
- [ ] The dropdown should operate on a local copy (`_selectedProvider` field) until Save.
- [ ] On cancel/discard (including back button), the original provider should be restored to `llmProviderProvider`.
- [ ] Add a warning when switching provider: "Changing the provider will clear the selected model. You'll need to select a new model."

---

### MAJOR FAIL: #6 — No Subject Filter on Dashboard

**Files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart:65-807`

**Description:** When a user has multiple subjects, ALL dashboard cards (Mastery Overview, Weak Areas, Weekly Chart, Workload, Due Reviews, Focus Stats, Summary, Session History) show aggregated data across all subjects with no way to filter by subject. A student wanting to see Physics-specific mastery or Chemistry-specific weak areas must navigate to each subject's detail screen.

**Acceptance criteria:**
- [ ] Add a subject selector dropdown/chips at the top of the Dashboard (similar to the planner's filter).
- [ ] Selecting "All Subjects" shows aggregated data (current behavior).
- [ ] Selecting a specific subject filters ALL cards below to show only that subject's data.
- [ ] Subject-specific providers exist (or existing providers accept optional `subjectId` filter parameter).

---

### MAJOR FAIL: #7 — Plan Regeneration Doesn't Warn About Adherence Impact

**Files:**
- `lib/features/planner/presentation/planner_screen.dart:159-210`
- `lib/features/planner/providers/planner_providers.dart:238-256`
- `lib/features/planner/services/personal_learning_plan_service.dart:97-280`

**Description:** When the user regenerates a plan (e.g., adding a second subject via multi-syllabus), the new plan has different daily plan dates. Adherence records are matched by date (line 245: `r.date.dateOnly == day.date.dateOnly`). New plan days that don't overlap with old plan dates show 0% adherence. This means adding Chemistry makes the user's adherence rate drop because Chemistry days show no study activity — even if the user is studying Physics as planned.

**Acceptance criteria:**
- [ ] Plan regeneration should preserve existing adherence records by matching old plan days to new plan days where dates overlap.
- [ ] New subject days (no overlap) should be excluded from the adherence calculation or shown separately as "New — no data yet."
- [ ] Show a warning before regenerating: "Regenerating will create a new daily schedule. Your adherence history will be preserved where dates match, but the plan structure will change."
- [ ] Per-subject adherence calculation should only consider days assigned to that subject.

---

### MAJOR FAIL: #8 — Reschedule Self-Conflict False Positive

**Files:**
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart:255-280`
- `lib/features/planner/services/planner_service.dart:480-506`

**Description:** When rescheduling a lesson, the `LessonBookingSheet` calls `hasSchedulingConflict()` without passing `excludeSessionId`. The `hasSchedulingConflict()` method at `planner_service.dart:480-506` supports an `excludeSessionId` parameter (line 483) that skips the session being rescheduled (line 493: `if (session.id == excludeSessionId) continue;`). Without this, if the user shifts a lesson by less than its duration (e.g., 3:00 PM → 3:30 PM for a 45-min lesson), the original 3:00-3:45 session overlaps with the new 3:30-4:15 — and the session is flagged as conflicting with itself. The user sees a red "Time conflict" warning and cannot save.

**Acceptance criteria:**
- [ ] Pass `excludeSessionId` to `hasSchedulingConflict()` in `LessonBookingSheet._checkConflicts()`.
- [ ] The `LessonBookingSheet` needs access to the rescheduled lesson's ID — either through a constructor parameter (`excludingSessionId`) or through the `plannerService`.
- [ ] Update `_openRescheduleLesson()` in `planner_screen.dart:1326-1350` to pass the session ID to `LessonBookingSheet`.
- [ ] Test: rescheduling a lesson to a time that overlaps with its original time should succeed (no false conflict).

---

### MAJOR FAIL: #9 — No Multi-Subject Dashboard Summary Card for New Subject

**Files:**
- `lib/features/dashboard/presentation/widgets/syllabus_progress_card.dart`
- `lib/features/planner/presentation/widgets/syllabus_progress_card.dart`

**Description:** The `SyllabusProgressCard` shows 0% progress for a newly added subject with no practice history. There is no call-to-action on the card itself — no "Start learning Chemistry" button, no "Upload Chemistry materials" prompt, no "Practice Chemistry questions" link. The card simply displays "0% — No data" (or equivalent) with no guidance on how to improve it.

**Acceptance criteria:**
- [ ] When a syllabus goal has 0% progress, the `SyllabusProgressCard` should show contextual actions: "Upload materials," "Practice questions," or "Start a tutor lesson" for that subject.
- [ ] The card should explain what "0%" means in context: "You haven't practiced Chemistry yet. Start by uploading materials or scheduling a lesson."
- [ ] Empty progress cards should link directly to the subject's detail screen.

---

### MAJOR FAIL: #10 — Course Name Summary Doesn't Reflect Multi-Subject Plans

**Files:**
- `lib/features/planner/services/personal_learning_plan_service.dart:250-258`

**Description:** The generated plan's metadata (stored in `plan.metadata`) and summary field may only reference the first syllabus goal's course name. When displaying in the Planner, subject progress tabs work correctly but the overall plan summary might say "IB Physics plan" even when Chemistry is included.

**Acceptance criteria:**
- [ ] When multiple syllabus goals exist, generate a combined name: "IB Physics + IB Chemistry Study Plan."
- [ ] The `PlanSummaryCard` should indicate "2 subjects" in its subtitle.
- [ ] The Planner's app bar or header should show the combined subject count.

---

### MINOR FAIL: #11 — Reschedule No Confirmation Dialog

**Files:**
- `lib/features/planner/presentation/planner_screen.dart:1326-1350`

**Description:** Rescheduling a lesson silently moves it when the user taps "Schedule" in the `LessonBookingSheet`. There is no confirmation dialog showing the old vs. new time. A user could accidentally move a lesson to the wrong time with no way to verify before the change is committed.

**Acceptance criteria:**
- [ ] After selecting new time in `LessonBookingSheet` and tapping "Schedule," show a confirmation: "Move [topic] lesson from [old time] to [new time]? This will update your schedule." with Cancel and Confirm buttons.
- [ ] Alternatively, the `LessonBookingSheet` title should change from "Schedule Lesson" to "Reschedule Lesson" when initialDate is provided, and show old vs. new time comparison in the UI.

---

### MINOR FAIL: #12 — No Custom API Provider Option

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:514-552`
- `lib/core/constants/app_api_config.dart`

**Description:** The provider dropdown only offers OpenRouter, Ollama, and OpenAI. Users who want to use a different OpenAI-compatible endpoint (e.g., Groq, Together AI, Anthropic via proxy, local vLLM) must select "OpenAI" and manually change the base URL. The dropdown label is misleading — it says "OpenAI" when the actual endpoint is something else.

**Acceptance criteria:**
- [ ] Add a "Custom" option to the provider dropdown.
- [ ] "Custom" should not auto-fill the base URL (user provides it) and should not show the "recommended" badge.
- [ ] The provider label in Settings should show either the known provider name or "Custom" for custom endpoints.
- [ ] `LlmProvider` enum should include a `custom` value.

---

### MINOR FAIL: #13 — Plan Summary Doesn't Show Multi-Subject Title

(Described in MAJOR #10 above — downgraded to MINOR because it's cosmetic rather than functional)

---

## Summary of Findings

| ID | Severity | Finding | Component |
|---|---|---|---|
| #1 | **BLOCKER** | Empty model after provider switch causes silent AI failures | API Config / LLM Service |
| #2 | **MAJOR** | No incremental subject addition to existing plan | Planner |
| #3 | **MAJOR** | No per-subject pace adjustment | Planner / Pace Adjustment |
| #4 | **MAJOR** | Pace adjustment doesn't shorten plan duration | Planner / Pace Adjustment |
| #5 | **MAJOR** | Provider state mutated prematurely on dropdown change | API Config |
| #6 | **MAJOR** | No subject filter on Dashboard | Dashboard |
| #7 | **MAJOR** | Plan regeneration breaks adherence tracking | Planner / Adherence |
| #8 | **MAJOR** | Reschedule self-conflict false positive | Lesson Booking / Conflict Check |
| #9 | **MAJOR** | No CTA on zero-progress syllabus card | Syllabus Progress Card |
| #10 | **MAJOR** | Plan summary doesn't reflect multi-subject | Personal Learning Plan Service |
| #11 | **MINOR** | No reschedule confirmation dialog | Planner / Lesson Booking |
| #12 | **MINOR** | No custom API provider option | API Config |
| #13 | **MINOR** | Multi-subject plan name not combined | (merged with #10) |

### Count by Severity

| Severity | Count |
|---|---|
| **BLOCKER** | 1 |
| **MAJOR** | 9 |
| **MINOR** | 3 |

### Key Files Referenced

| File | Key Lines | Role |
|---|---|---|
| `planner_screen.dart` | 159-210, 572-577, 700-777, 909-967, 1211-1276, 1326-1350 | Multi-syllabus input, pace slider, scheduled lessons, reschedule |
| `planner_service.dart` | 374-393, 480-506, 545-580 | Reschedule session, conflict check, pace adjustment |
| `personal_learning_plan_service.dart` | 97-280, 644-711 | Plan generation, workload redistribution |
| `planner_providers.dart` | 238-256, 604-627, 629-640, 675-680 | Plan loading, reschedule, pace adjust |
| `lesson_booking_sheet.dart` | 17-18, 48-58, 255-280, 282-311 | Lesson booking, conflict check (missing excludeSessionId) |
| `api_config_screen.dart` | 125-202, 472-579, 553-578 | Provider dropdown, premature state mutation, model clearing |
| `llm_providers.dart` | 27-49 | Reactive LLM service creation |
| `settings_screen.dart` | 195-204, 434-442 | AI model label display |
| `dashboard_screen.dart` | 120-199, 300-322, 508-535 | Syllabus progress display, aggregated dashboard |
