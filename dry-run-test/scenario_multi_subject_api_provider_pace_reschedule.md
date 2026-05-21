# Dry-Run Scenario: Multi-Subject Learning, Changing Study Pace, Switching API Providers, and Rescheduling Lessons

## Persona

I'm a student who has been using StudyKing for 3 weeks. I started studying **IB Physics** with a 90-day plan, attended 4 AI tutor lessons, completed practice sessions, and uploaded my physics textbook. Now I want to:

1. **Add IB Chemistry** as a second subject and create a combined study plan
2. **Speed up my Physics pace** — I'm ahead of schedule and want to cover more per day
3. **Change my API provider** from OpenAI to Ollama (I want to run local inference to save money)
4. **Reschedule a physics tutoring lesson** because I have a conflict

I expect the app to:
- Let me manage multiple subjects seamlessly — add a new subject without destroying my existing plan
- Allow per-subject pace adjustment (Physics faster, Chemistry at normal pace)
- Save my API provider change immediately and have it take effect for new AI tasks without disrupting running ones
- Let me reschedule a lesson to another time with clear conflict checking that doesn't flag the lesson itself
- Show me per-subject progress clearly on the Dashboard
- Not silently lose my existing plan data when I add a second subject

---

## Step 1: Adding IB Chemistry as a Second Subject

I've been using StudyKing for 3 weeks with only "IB Physics." I create a new subject via the Subjects tab → tap "+" → type "IB Chemistry" → save. The seed data creates 9 topics automatically.

**What I expect:** Now I want a study plan that covers BOTH Physics and Chemistry. I go to the Planner screen, where I already have a Physics plan.

**What actually happens:**

The Planner shows my existing Physics plan with daily overview, pace adjustment slider, and scheduled lessons. There is no "Add another subject to this plan" button. To add Chemistry:

1. I must toggle the `_useMultiSyllabus` switch (`planner_screen.dart:572-575`) — but this creates a **new plan from scratch**
2. The multi-syllabus input shows empty cards. I select Physics (dropdown), enter days/hours
3. I click "Add Subject" to add Chemistry, select it, enter days/hours
4. I tap "Generate Plan" which calls `generatePlanFromSyllabus()` at `planner_screen.dart:205-210`

**Issue 1 — No "Add Subject to Existing Plan" option (MAJOR):** The planner has no incremental update. The only way to add a second subject is to regenerate a completely new multi-syllabus plan from scratch. This means:
- My existing Physics plan's daily plans, adherence records, and progress data remain in the database
- But the Planner screen now shows the NEW plan, which starts fresh with no history
- If the existing plan had catch-up adjustments or customizations, they're lost
- The `PersonalLearningPlanService._buildPlan()` at `personal_learning_plan_service.dart:97-280` creates a new `PersonalLearningPlan` object — it doesn't merge with an existing one

**Issue 2 — No warning about plan regeneration (MAJOR):** If I already have a plan and toggle to multi-syllabus mode, the UI doesn't warn: "This will create a new plan. Your existing plan and progress will remain in the database but this new plan will replace the current view." The toggle just switches the input UI (line 572). When I hit "Generate Plan," the old plan is silently replaced in the provider state. There's no "are you sure?" confirmation.

**Issue 3 — Plan name/summary doesn't reflect multiple subjects (MINOR):** The generated plan's `summary` field may not reflect the multi-subject nature. Looking at `_buildPlan()`, the summary is built from the first syllabus goal's course name, not a combined name like "IB Physics + IB Chemistry."

---

## Step 2: Dashboard Shows Both Subjects' Progress

After generating the multi-subject plan, I go to the Dashboard.

**What I expect:** A clear per-subject breakdown. I can see "Physics: 40% complete" and "Chemistry: 5% complete" side by side, with separate weak areas, adherence, and mastery cards.

**What I see:**

The Dashboard renders `_buildSyllabusProgress()` at `dashboard_screen.dart:508-535` which shows an individual `SyllabusProgressCard` for each syllabus goal. ✓ This works correctly.

**But there are issues:**

**Issue 4 — No per-subject filtering for Dashboard cards (MAJOR):** The Dashboard's main cards (Mastery Overview, Weak Areas, Weekly Chart, Workload, Due Reviews, Focus Stats) show **AGGREGATED** data across ALL subjects. They cannot be filtered by subject. For example:
- `MasteryProgressCard` at `dashboard_screen.dart:300-317` shows a single mastery overview combining both Physics and Chemistry — topics from both subjects mixed together
- `WeakAreasCard` lists weak topics from all subjects combined — no visual separation
- `WeeklyChart` shows combined study time across all subjects
- `workloadAsync` at line 78-80 shows remaining workload aggregated

If I want to see Chemistry-specific mastery, I must navigate to Subjects → Chemistry → Stats tab. There's no subject filter or tab selector on the Dashboard.

**Issue 5 — `SyllabusProgressCard` may show inaccurate data for new subject (PARTIAL):** The `SyllabusProgressCard` at `syllabus_progress_card.dart` calculates progress based on topic mastery. For a brand-new "IB Chemistry" subject with no practice history, the card may show 0% with no guidance on how to improve it. This is partially by design (you need to practice first) but there's no "Start learning Chemistry" call-to-action on the card itself.

---

## Step 3: Speeding Up Physics — Pace Adjustment

I'm ahead in Physics. I want to study more Physics per day (e.g., 3 hours instead of 2) but keep Chemistry at the base pace.

**What I expect:** A per-subject pace adjustment — maybe a slider for each subject in the syllabus progress cards, or at least the ability to edit the subject's hours-per-day.

**What actually happens:**

The Planner shows a single pace adjustment slider at `_buildPaceAdjustment()` (`planner_screen.dart:700-777`). It controls `plan.targetMinutesPerDay` across ALL subjects. The slider ranges from 0.5 to 8.0 hours.

**Issue 6 — Pace adjustment is global, not per-subject (MAJOR):** The `adjustPace()` method at `planner_service.dart:545-580` scales ALL daily plan targets proportionally. It does:
```dart
final ratio = newTargetMinutesPerDay / oldTarget;
final updatedPlans = plan.dailyPlans.map((day) => day.copyWith(
  targetMinutes: (day.targetMinutes * ratio).round().clamp(...),
  targetQuestions: (day.targetQuestions * ratio).round().clamp(...),
));
```

This scales every day equally. There is no concept of "speed up Physics only." Each daily plan might cover topics from both subjects, and the ratio is applied uniformly. If I want Physics at 3h/day and Chemistry at 1h/day, I cannot achieve this with the single slider.

**Issue 7 — No "target date adjustment" — pace scaling doesn't shorten the plan duration (MAJOR):** When I increase pace, I expect to finish Physics FASTER (fewer total days). But `adjustPace()` only scales daily minutes — it doesn't adjust the total plan duration. The plan still spans the same number of days (e.g., 90 days for both subjects), just with more work per day. There's no "I want to finish Physics in 60 days instead of 90" slider.

A `redistributeMissedWorkload()` function exists at `planner_providers.dart:629-640` but it handles missed lessons — it doesn't adjust the end date.

---

## Step 4: Changing API Provider from OpenAI to Ollama

I go to Settings → AI Configuration → tap the provider dropdown.

**What I expect:** A clear, guided process. I select "Ollama" from the dropdown, paste my local URL, click Test Connection, see it works, click Save. My new provider is active immediately for new tasks. My existing API key is cleared for OpenAI.

**What actually happens:**

I open the `ApiConfigScreen`. The provider dropdown has 3 options: OpenRouter (recommended), Ollama, OpenAI. I select Ollama.

**On dropdown change** (`api_config_screen.dart:553-578`):
1. `ref.read(llmProviderProvider.notifier).state = value` at line 556 — **The provider StateProvider is updated IMMEDIATELY**, not on save
2. `ref.read(selectedModelProvider.notifier).state = ''` at line 557 — **The model is cleared immediately**
3. Base URL is auto-set to `http://localhost:11434` at line 569

**Issue 8 — Provider state is mutated on dropdown change, not on save (MAJOR):** At line 556, `llmProviderProvider` is set the moment the user selects a different provider in the dropdown. But the user hasn't clicked "Save" yet — they might change their mind and switch back. If they navigate away without saving (via back button), the provider is already changed in the reactive state. The `PopScope` at line 303 checks `_hasUnsavedChanges` but the provider mutation already happened. The `LlmService` at `llm_providers.dart:27-49` watches `llmProviderProvider` reactively, so any downstream service that reads `llmServiceProvider` between the dropdown change and the save gets an inconsistent configuration (new provider, empty model).

The `_updateUnsavedChanges()` call at line 579 detects changes, but the provider state is prematurely committed. If the user exits without saving:
- The `PopScope` warning appears (because `_hasUnsavedChanges` is true)
- But even if they confirm "Discard changes," the `llmProviderProvider` is already updated and won't revert
- The `_initialProvider` at line 43 is only updated AFTER a successful save (line 183)

Wait, let me re-check — the `initState()` at line 57 calls `_loadCurrentValues()` which reads from `llmProviderProvider`. If the user navigated to this screen, saw their current provider (OpenAI), then selected Ollama in the dropdown, the provider is already Ollama in the provider state. If they cancel, the provider stays Ollama. When they come back to this screen, `_loadCurrentValues()` will read Ollama from `llmProviderProvider` — the initial value is now the changed-but-unsaved value. **There's no way to revert**.

**Issue 9 — No unsaved-changes reversion for provider (MAJOR):** The `PopScope` at line 303-310 only prevents navigation when `_hasUnsavedChanges` is true. But even if the user stays on the screen and re-selects "OpenAI" from the dropdown (undoing the change), the `_updateUnsavedChanges()` logic compares against `_initialProvider` which was set from the (now overwritten) `llmProviderProvider` in `initState()`. Since the first dropdown change already mutated `llmProviderProvider`, the initial value is already wrong.

Actually, let me re-examine. The `_loadCurrentValues()` reads from `ref.read(llmProviderProvider)` (line 108). If this screen just opened, and no one else changed the provider, the initial read should be "OpenAI" (the saved value). Then when the dropdown changes to "Ollama" at line 556, `llmProviderProvider` is mutated to "Ollama." If the user switches back to "OpenAI" in the dropdown, line 556 fires again with "OpenAI" — restoring the original value. But the `_updateUnsavedChanges()` method compares `_selectedProvider` against `_initialProvider` — since both would be "OpenAI," it shows "no changes." This works correctly for undo.

**However, there's still a window where the provider is wrong:** Between the dropdown change and the undo, any AI operation that reads `llmServiceProvider` gets a provider with an empty model. This could cause errors in:
- Upload pipeline
- Mentor chat
- Tutor lessons
- Question generation

The model is empty (line 557: `ref.read(selectedModelProvider.notifier).state = ''`).

**Issue 10 — Model is always cleared on provider switch, requiring re-selection (MAJOR):** At `api_config_screen.dart:557`, switching providers always clears `selectedModelProvider` to `''`. This means the user MUST re-select a model after switching. The Settings screen model label shows "Select model from API" (settings_screen.dart:436) until they do. This is understandable technically (different providers have different models) but the UX is friction:
- The user doesn't know what models are available until they tap the "AI Model" tile in Settings and trigger `_showAiModelSelection()` which fetches models from the API
- If the Ollama server is not running, the model fetch fails with no graceful handling
- The "Test Connection" button at line 204 validates the API endpoint but doesn't help the user understand what models are available

**Issue 11 — No custom API provider option (MINOR):** Only 3 providers are available (`LlmProvider.values` at line 514). Users who want to use a different OpenAI-compatible endpoint (e.g., Groq, Together AI, Anthropic via proxy) must choose "OpenAI" and manually change the base URL. The provider dropdown doesn't have a "Custom" option. The label and recommendations are misleading — selecting "OpenAI" but pointing to Groq's endpoint shows "OpenAI" in the dropdown which is incorrect.

I fill in my Ollama URL, leave the model field as default (it stays empty until I select one later), and tap "Save." The save succeeds and I return to Settings.

**Issue 12 — Test Connection doesn't check model suitability (MINOR, already documented in scenario_first_launch_onboarding_experience.md):** The `_testConnection()` at line 204 sends `"Reply with exactly: OK"`. This confirms the endpoint is reachable but doesn't verify that the model supports features StudyKing needs (tool calling, high token limits, vision for image analysis).

---

## Step 5: Rescheduling a Physics Lesson

I have a Physics tutoring session scheduled for tomorrow at 3 PM, but I have a school commitment. I want to move it to 7 PM.

**What I expect:** I tap the lesson in the Planner's Scheduled Lessons section, see a "Reschedule" option with a clear date/time picker pre-filled with the current time. I change to 7 PM, confirm, and the lesson is moved.

**What actually happens:**

I find the lesson card in the "Scheduled Lessons" section of the Planner Study Plan tab (`planner_screen.dart:1211-1276`). Each non-completed lesson has three icon buttons: play (start tutoring), refresh (reschedule), and cancel (cancel lesson). I tap the refresh icon.

`_openRescheduleLesson()` at line 1326-1350 fires. It opens `LessonBookingSheet` with:
- `initialDate: lesson.startTime` ✓
- `initialDuration: lesson.plannedDurationMinutes ?? 30` ✓
- `onSchedule` callback calls `rescheduleLesson()` ✓

**Issue 13 — Reschedule conflict check falsely flags current lesson (MAJOR):** The `LessonBookingSheet._checkConflicts()` at `lesson_booking_sheet.dart:255-280` calls:
```dart
final conflictResult = await service.hasSchedulingConflict(
  startTime: time,
  durationMinutes: _durationMinutes,
);
```

**Note the missing `excludeSessionId` parameter.** The `hasSchedulingConflict()` method at `planner_service.dart:480-506` supports `excludeSessionId` (line 483):
```dart
Future<Result<bool>> hasSchedulingConflict({
  required DateTime startTime,
  required int durationMinutes,
  String? excludeSessionId,
}) async { ... }
```

At line 493:
```dart
if (session.id == excludeSessionId) continue;
```

But `LessonBookingSheet` never passes `excludeSessionId`. This means:
- When rescheduling lesson "A" to a new time, the conflict checker finds lesson "A" in the session list
- Since `excludeSessionId` is null, it doesn't skip lesson "A"
- Lesson "A"'s start time overlaps with itself (because we're checking the new time, which might be different, but the original lesson's time is also in the sessions list)
- Wait, actually — we're checking the *new* time. If the new time doesn't overlap with the original time, there's no conflict. But if the user changes the time only slightly (e.g., 3:00 PM → 3:30 PM) and the lesson is 45 minutes, the original 3:00-3:45 overlaps with the new 3:30-4:15 — and the original lesson IS in the sessions list. So the conflict checker correctly detects a self-conflict.

**This is actually a real bug:** When the user tries to shift a lesson by less than its duration, the reschedule conflict checker falsely flags the lesson itself as a conflicting session. The user sees a red "Time conflict" warning and cannot save the reschedule — even though they're just moving their own lesson.

**Issue 14 — Lesson reschedule has no "change reason" or confirmation (MINOR):** The reschedule flow silently moves the lesson. There's no dialog asking "Why are you rescheduling?" or confirming "Move Physics lesson from tomorrow 3:00 PM to 7:00 PM?" — the `onSchedule` callback just fires. For the student, a confirmation showing old vs new time would prevent mistakes.

I change the time to 7:00 PM (no overlap with original 3:00 PM time, so no false conflict). I tap "Schedule." The lesson is moved. I return to the Planner. ✓ The reschedule works for non-overlapping time changes.

---

## Step 6: Verifying the API Provider Change Took Effect

I go back to the Tutor screen and start a new lesson.

**What I expect:** The tutor uses my Ollama local model.

**What actually happens:**

The `llmServiceProvider` at `llm_providers.dart:27-49` watches `llmProviderProvider`, `apiKeyProvider`, `baseUrlProvider`, and `selectedModelProvider`. Since:
- Provider was changed to `LlmProvider.ollama`
- Model was cleared to `''`
- Base URL was set to `http://localhost:11434`

The `LlmService` is created with `LlmConfiguration(provider: LlmProvider.ollama, baseUrl: 'http://localhost:11434', model: '', ...)`.

**Issue 15 — Empty model leads to silent failures or cryptic errors (BLOCKER):** When `selectedModel` is empty and the provider is Ollama:
1. The `LlmService._getChatResponse()` method tries to send a request with `model: ''`
2. The Ollama API receives a request with no model specified or an empty model string
3. This results in an HTTP error or a meaningless response
4. The error propagates as a raw exception string: "Exception: Failed to get chat response" or similar

The `api_config_screen.dart:129` guards against empty API keys (`if (_apiKeyController.text.trim().isEmpty && _selectedProvider != LlmProvider.ollama)` — it allows empty key for Ollama). But there's NO guard for empty model. The model field in the API config screen at `api_config_screen.dart:380-420` shows a model text field with the current value from `selectedModelProvider`, which was cleared to `''`. The user sees an empty model field and may not know they need to fill it in — especially since:
1. The model field is BELOW the provider section, easy to miss
2. For Ollama users, the model name is not obvious (do I type "llama3.2"? "llama3.2:3b"? "mistral"?)
3. There's no "Fetch available models" button for Ollama (the Settings screen's model fetch works for OpenRouter/OpenAI but may fail for local Ollama)

**As a user, I change the provider, save, go back to tutor, start a lesson, and get a cryptic error.** The app never tells me: "Please select a model for Ollama before starting AI features."

---

## Step 7: Checking Dashboard After All Changes

After rescheduling, changing provider, and adding Chemistry, I check the Dashboard.

**What I expect:** The dashboard reflects all changes. My Physics adherence data isn't lost, Chemistry shows "0% complete" with a call to action, and the rescheduled lesson shows the new time.

**What I see:**

- **Adherence card**: Shows my Physics plan adherence (from old plan). If the new plan regenerated (Step 1), the adherence may now show gaps or reset because the new plan has different daily plan dates.
- **Syllabus Progress**: Two cards shown, one per subject. ✓
- **Scheduled Lessons Section**: The rescheduled Physics lesson shows 7:00 PM. ✓

**Issue 16 — Plan regeneration may break adherence tracking (MAJOR):** If I regenerated the plan in Step 1 (adding Chemistry), the old Physics plan is replaced by a new merged plan. The `loadExistingPlan()` at `planner_providers.dart:238-256` loads the latest plan. But adherence records are stored separately (via `AdherenceRepository`/`PlanAdherenceOrchestrator`). If the new plan has different `dailyPlans`, the adherence records may reference old plan days that no longer match. The `annotatedPlans` at line 245-249 tries to match by date:
```dart
final record = records.where((r) => r.date.dateOnly == day.date.dateOnly).firstOrNull;
```
If the new Chemistry plan adds days that don't overlap with Physics days, those days have zero adherence. But adherence is per-plan, not per-subject. So the adherence rate drops because Chemistry days show 0% adherence (no study done yet).

This creates a demotivating experience: adding a second subject makes your adherence look worse.

---

## Summary of Expectations vs Reality

| # | Expectation | Reality | Status |
|---|---|---|---|
| 1 | Add a second subject to my existing plan incrementally | Must regenerate entire plan from scratch. No merge/incremental update. | **MAJOR FAIL** |
| 2 | Planner warns before replacing existing plan | The multi-syllabus toggle + generate button silently replaces the current plan view with no confirmation | **MAJOR FAIL** |
| 3 | Dashboard shows per-subject data with filtering | SyllabusProgressCard shows per-subject. All other cards (Mastery, Weak Areas, Charts) are aggregated with no subject filter. | **MAJOR FAIL** |
| 4 | Per-subject pace adjustment (Physics faster, Chemistry normal) | Single global pace slider scales ALL subjects equally. No per-subject pace. | **MAJOR FAIL** |
| 5 | Increasing pace shortens plan duration | `adjustPace()` only scales daily minutes. Plan stays same number of days. | **MAJOR FAIL** |
| 6 | Provider change is committed only on save | `llmProviderProvider` is mutated on dropdown change (line 556), before save. Premature mutation. | **MAJOR FAIL** |
| 7 | Provider change with unsaved changes is revertible | Provider state is already committed. Undo relies on re-selecting original value. No explicit revert mechanism. | **MAJOR FAIL** |
| 8 | Model is preserved when switching providers | Model is always cleared to `''` on provider switch (line 557). User must re-select. | **MAJOR FAIL** |
| 9 | Empty model is caught before AI operations | No guard for empty model in API config. Ollama users get silent failures/cryptic errors. | **BLOCKER FAIL** |
| 10 | Rescheduling conflict check excludes current session | `excludeSessionId` is never passed from `LessonBookingSheet`. Self-conflict false positive when shifting by < duration. | **MAJOR FAIL** |
| 11 | Reschedule shows old vs new time confirmation | Silent move — no confirmation dialog with before/after comparison. | MINOR FAIL |
| 12 | Custom API provider option exists | Only 3 hardcoded providers. No "Custom" option in dropdown. | MINOR FAIL |
| 13 | Adding a second subject doesn't break adherence | Plan regeneration creates new daily plans. Old adherence records mismatch new plan dates, dropping adherence rate. | **MAJOR FAIL** |
| 14 | Dashboard has subject selector/filter | No subject-level filtering on any dashboard card. | **MAJOR FAIL** |
| 15 | Plan summary reflects multi-subject nature | Summary built from first subject only. Combined name not generated. | MINOR FAIL |

---

## Summary

| Severity | Count | Items |
|---|---|---|
| **BLOCKER** | 1 | #9 (empty model guard) |
| **MAJOR** | 10 | #1 (no incremental plan update), #2 (no regeneration warning), #3 (aggregated dashboard), #4 (global pace), #5 (no duration shortening), #6 (premature provider mutation), #7 (no revert for provider), #8 (model cleared on switch), #10 (self-conflict in reschedule), #13 (adherence breakage), #14 (no subject filter) |
| **MINOR** | 3 | #11 (reschedule confirmation), #12 (custom provider), #15 (plan summary) |

The multi-subject learning workflow has significant friction: adding a second subject requires destructive plan regeneration, pace adjustment is global with no duration impact, and the dashboard cannot filter by subject. The API provider switch has a premature state mutation bug that can leave the app in an inconsistent state (provider changed, model empty). The rescheduling flow has a self-conflict false positive when the new time overlaps with the original.
