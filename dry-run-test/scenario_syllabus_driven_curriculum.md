# Dry-Run Scenario: Syllabus-Driven Curriculum Learning — Structured Path Through IB Chemistry

## Persona

I'm a student who just installed StudyKing with a clear goal: **I want to systematically learn IB Chemistry following its official syllabus.** I have the IB Chemistry syllabus PDF. I understand that Chemistry topics have prerequisites — you need to understand Bonding before tackling Organic Chemistry. I expect StudyKing to be a smart learning platform that understands curriculum structure, topic dependencies, and syllabus progress. I want the app to:

1. Process my syllabus PDF and auto-create a structured topic hierarchy
2. Let me set up prerequisites between topics (or auto-detect them)
3. Create a study plan that respects the prerequisite order
4. Show me my syllabus completion percentage (e.g., "60% of IB Chemistry completed")
5. Prevent me from practicing topics whose prerequisites I haven't mastered yet

---

## Step 1: Uploading the Syllabus PDF — The App Can't Parse It Into Topics

I open the app. I see the onboarding dialog (which is helpful). I create my "IB Chemistry" subject. Now I want to upload my syllabus PDF.

**What I expect:** I upload my IB Chemistry syllabus PDF. The app's content pipeline processes it, recognizes it as a syllabus document, extracts the topic structure (Atomic Structure, Bonding, Stoichiometry, etc.), and auto-creates Topics under my IB Chemistry subject. After upload, I see a list of topics like "Atomic Structure", "Bonding", "Stoichiometry" in my subject detail.

**What actually happens:**

1. I go to Upload (via the FAB → but it's not there; I have to find it through the subject detail more-options menu or use the route directly).
2. I upload my syllabus PDF. The extraction pipeline runs: text is extracted, OCR if needed, a summary is generated.
3. The `_classifyTopic()` method at `content_pipeline.dart:281-324` runs. It calls the LLM to classify the content against a list of `possibleTopics` (topic titles to match against).
4. **But the upload screen passes `possibleTopics: []`** (`upload_screen.dart:240`). The list is empty. `_classifyTopic()` immediately returns `''` — topic classification is skipped entirely.
5. The pipeline **never creates new topics**. The `TopicRepository.create()` method exists but **nobody calls it from any production code**. Even if the LLM identified "Atomic Structure" in my syllabus, there's no code path to create a new `Topic` from it.
6. After upload, my subject detail shows nothing new. My syllabus is stored as a Source in the content library, but **no topics were created from it**.

To have topics, I would need to... well, there's no topic creation UI. The topic repository has CRUD methods, but no screen or dialog in the entire app lets me add a topic to a subject.

**Verdict (BLOCKER FAIL):** Uploading a syllabus PDF creates zero topics. The content pipeline has a classification stage but the upload screen disables it by passing an empty `possibleTopics` list. There is no topic creation UI anywhere in the app. Topics must exist before the upload, or the syllabus is just a stored document with zero impact on the topic structure.

---

## Step 2: Trying to Set Up Topic Prerequisites — No UI Exists

Somehow, I managed to get topics into the system (perhaps through data import or test fixture). Now I want to configure prerequisites: you must master "Atomic Structure" before "Bonding", and "Bonding" before "Organic Chemistry".

**What I expect:** In the subject detail or a topic management screen, I can select a topic and see "Prerequisites" with a multi-select picker. I select the topics that must be completed first.

**What actually happens:**

The `TopicDependency` model (`topic_dependency_model.dart`) is fully implemented with:
- `prerequisites: List<String>` — topic IDs that must be completed first
- `downstreamTopics: List<String>` — topics that depend on this one
- `masteryThreshold: double` — mastery level needed (default 0.8)
- `isRequired: bool` — whether the topic is mandatory
- `syllabusWeight: double` — weight for priority calculation
- `calculatePriority()` — priority score based on dependencies
- `isReady()` — checks if prerequisites are met

**But there is zero UI that reads or writes these fields.** Searching the entire `presentation/` codebase:

- No topic dependency editor screen or dialog
- No prerequisite selector widget
- No topic management screen at all (topics cannot be created, edited, or deleted through any UI)
- The `TopicDependency` model is only used internally by the `SyllabusResolver` and `PersonalLearningPlanService`

The ONLY user-facing reference to topics is:
- Practice modes (select a topic to practice)
- Dashboard weak areas (shows weak topic names)
- Planner recommended topics (suggests what to study)

None of these let the user configure dependencies.

**Verdict (BLOCKER FAIL):** The entire topic dependency system (prerequisites, mastery thresholds, downstream topics, syllabus weights) is data-only. There is no UI to configure it. The `TopicDependency` model serves only as read-only input to the planner's internal syllabus resolution.

---

## Step 3: Creating a Study Plan from the Syllabus — Broken Pipeline

I go to the Planner screen. I notice a toggle that switches from single-course mode to a "Subjects" multi-syllabus mode (`_useMultiSyllabus`, `planner_screen.dart:53`). This looks promising! I switch to multi-syllabus mode.

The form shows cards where I can enter a subject name, target days, and hours per day. I fill in:
- Subject: "IB Chemistry"
- Days: "90"
- Hours per day: "2"

I tap "Generate Plan."

**What I expect:** The app takes my IB Chemistry syllabus, resolves all topics with their dependencies from the topic repository, topologically sorts them (prerequisites first), and creates a 90-day plan that systematically advances through the curriculum.

**What actually happens — the broken pipeline:**

1. The form creates a `SyllabusGoal` object:
   ```dart
   // planner_screen.dart:143-148
   SyllabusGoal(
     subjectId: '',  // <-- ALWAYS empty string!
     subjectTitle: 'IB Chemistry',  // free text, not linked to actual subject
     ...
   )
   ```
   **`subjectId` is always `''`.** There is no subject picker dropdown — the user types free text. The SyllabusGoal cannot be linked to the actual "IB Chemistry" subject record in the database.

2. The planner provider calls `generatePlanFromSyllabus([SyllabusGoal with subjectId: ''])`.

3. Inside `PersonalLearningPlanService._buildPlan()` (`personal_learning_plan_service.dart:146-153`):
   ```dart
   for (final goal in syllabusGoals) {
     final topicsResult = await _topicRepository.getBySubject(goal.subjectId);
     // goal.subjectId is '' → returns zero topics
   }
   ```
   **No topics are loaded.** The `allTopics` map remains empty.

4. `_addSyllabusRecommendations()` adds nothing because `allTopics.keys.toSet()` is empty.

5. `SyllabusResolver.resolveSyllabus(subjectId: '')` is called with an empty `subjectId`. It fetches topics by empty subject ID — returns zero topics. Returns failure: `"No topics found for subject"`.

6. Despite this cascade of silent failures, the plan is still **generated** — but as an empty plan with 90 days of no content. The `syllabusGoals` metadata is stored, so the planner screen shows the "IB Chemistry" header card — but the actual daily plans are empty.

**Verdict (BLOCKER FAIL):** The multi-syllabus planning UI exists and is functional for data entry, but produces SyllabusGoals with empty `subjectId`. The downstream pipeline cannot link goals to actual subjects/topics. The user sees a syllabus header but gets empty daily plans. The entire syllabus-to-plan pipeline has a critical null junction at `planner_screen.dart:144`.

---

## Step 4: Prerequisite Enforcement — Can I Skip Ahead?

Let's say by some means (manual data entry) I have topics with prerequisites configured and a study plan was generated. I'm supposed to study Atomic Structure first (prerequisite for everything else). But I'm impatient and want to jump to Organic Chemistry.

**What I expect:** The app prevents me from starting a practice session or tutor lesson on Organic Chemistry until I've achieved 80% mastery on Atomic Structure (the prerequisite threshold).

**What actually happens:**

I go to the Practice tab → Topic Focus → select "Organic Chemistry". The session starts with zero checks. I go to the Planner daily plan → tap "Start Tutoring" on Organic Chemistry. The tutor starts.

**Prerequisites are NEVER enforced:**

- `PracticeSessionScreen` (`practice_session_screen.dart:106-145`) loads questions by subject or topic — no prerequisite check
- `TutorScreen` starts with a topic and subject — no prerequisite check
- The `TopicReadinessService.getReadyTopics()` exists (`topic_readiness_service.dart`) and can check prerequisites — but **it is never called from any UI or provider** (zero grep matches in `lib/features/`)
- `SyllabusResolver.buildLearningLevels()` groups topics by readiness — but has no UI consumption
- The ONLY place prerequisites are checked is in `PersonalLearningPlanService._generateDailyPlans()` (line 647-657), which skips unready topics. But this only affects auto-generated plans — the user can freely access those topics through Practice and Tutor modes.

**Verdict (MAJOR FAIL):** Prerequisites are only used for plan generation heuristics. They are never enforced in Practice, Tutor, or any other user-facing screen. A student can study any topic in any order.

---

## Step 5: Tracking Syllabus Completion — "How Much Have I Done?"

After two weeks of studying, I want to see my syllabus progress. I check the Dashboard, Subject Detail, and Planner.

**What I expect:** A clear indicator: "IB Chemistry Syllabus: 35% complete" or "12 of 34 topics mastered." Maybe a progress bar showing my advancement through the curriculum.

**What actually happens:**

- **Dashboard** — Shows plan adherence (how many days you stuck to your plan), mastery overview (per-topic accuracy), weak areas. **No syllabus completion percentage.**
- **Subject Detail → Stats tab** — Shows total attempts, correct count, accuracy, time spent. **No syllabus progress.**
- **Planner → Study Plan** — Shows the plan's `_buildSubjectProgressTabs` which display syllabus goal cards with target days and topic count. **But the topic count is zero** (because `subjectId` is empty, so no topics are resolved). The card only shows the subject title "IB Chemistry" with no progress data.
- **Planner → Roadmaps** — Roadmap milestones track custom goals, not syllabus coverage.

The `PersonalLearningPlan` model has `estimatedCoverage` computed at line 815-818 of `personal_learning_plan_service.dart`:
```dart
final estimatedCoverage = (uniqueTopics / 10).clamp(0, 1).toDouble();
```
This is a crude heuristic (`/ 10` — assuming 10 topics is a full syllabus). It's never exposed in any UI.

**Verdict (MAJOR FAIL):** No syllabus completion percentage exists anywhere. The only "progress" tracking against a syllabus is the plan adherence (did you study when you planned to?), not curriculum coverage (what fraction of the syllabus have you mastered?).

---

## Step 6: The Syllabus Tab in Subject Detail — A Glimpse of What Should Be

The `SubjectDetailScreen` has a "Lessons" tab. I tap it, hoping to see my topics in syllabus order.

**What I expect:** A structured view: "IB Chemistry Syllabus" with a progress tree showing topics organized by learning level, with checkmarks next to mastered topics and lock icons next to prerequisites-not-met topics.

**What actually happens:** The SubjectLessonsTab shows... lessons. Not topics. It queries `LessonRepository` for lesson objects, which are pre-scheduled tutoring sessions. If I have no scheduled lessons, the tab is empty.

There is no "Syllabus" or "Topics" tab in the subject detail. The hierarchy data (Topic.parentId, childTopicIds, TopicDependency.prerequisites) is fully modeled but never rendered.

**Verdict (MAJOR FAIL):** The subject detail has no syllabus/topic overview. The rich topic hierarchy in the data model is invisible to the user.

---

## Step 7: The Planner's Syllabus UI — A Frontend Without a Backend

Going back to the Planner, the multi-syllabus form is one of the most sophisticated UIs in the app for syllabus management. Let me examine it more carefully.

The `_buildMultiSyllabusInput()` method (`planner_screen.dart:456-537`) renders cards with:
- Subject name text field (free text)
- Days field (number input)
- Hours per day field (number input)
- Delete entry button
- "Add Course/Subject" button

**The problems:**

1. **No subject picker** — The user types a subject name. There's no dropdown that lists existing subjects. The typed name is never validated against actual subjects in the database.
2. **Subject IDs are empty** — When creating SyllabusGoal, `subjectId` is hardcoded to `''` (line 144). Even if the user typed the exact name of their existing subject, the ID doesn't match.
3. **No syllabus selection** — There's no way to choose a specific syllabus document from the content library to base the plan on.
4. **No topic preview** — Before generating, the user can't see "these 12 topics will be covered in this order."
5. **No topic count feedback** — After generation, the syllabus cards should show "12 topics planned" but show "0 topics" because the subjectId is empty.

The `_buildSubjectProgressTabs()` method (lines 539-577) tries to display per-subject plan data:
```dart
final subjectPlans = state.plan!.subjectPlans; // map from subjectId
// ...renders cards for each syllabus goal
// but state.plan!.subjectPlans[''] is empty
```
It looks up plans by `goal.subjectId` which is `''` — no subject plans match, so the topic count per subject is zero.

**Verdict (MAJOR FAIL):** The multi-syllabus planning UI is well-designed but produces data that cannot be consumed by the backend. The missing subject picker and hardcoded empty `subjectId` disconnect the frontend from the backend.

---

## Step 8: Syllabus Resolver — The Engine That Could (But Never Runs Properly)

The `SyllabusResolver` (`syllabus_resolver.dart:29-222`) is a sophisticated service that could solve all the problems above — if it received valid data.

What it can do:
- **Topological sort** (lines 158-185) — Sorts topics by prerequisites, handling missing prereqs gracefully
- **Learning levels** (lines 187-208) — Groups topics into levels where all prerequisites in a level are met
- **Workload estimation** (lines 210-222) — Estimates if the plan is feasible

But it only receives valid data when called with a real `subjectId` and topics exist:
- In `PersonalLearningPlanService._buildPlan()` (line 178): called with `syllabusGoals.first.subjectId` which is `''`
- In `PlannerService.createRoadmap()` (line 161-171): called with the actual subject ID from the roadmapping flow

So the roadmap creation flow MIGHT work correctly (it passes a real subjectId). But the plan generation from syllabus goals never reaches the resolver with valid data.

**Verdict (PARTIAL):** The SyllabusResolver is technically sound (topological sort, learning levels, workload estimation) but receives empty/broken input from the planner UI. If fed valid data, it would work correctly.

---

## Step 9: Roadmaps — An Alternative Syllabus Path

Instead of the planner, I try the Roadmap feature (Planner → Roadmaps tab). I create a new roadmap.

**What I expect:** A roadmapping flow that lets me design a curriculum path with milestones.

**What actually happens:** `PlannerService.createRoadmap()` (planner_service.dart:150-171) calls `syllabusResolver.resolveSyllabus(subjectId: subjectId)` — and here `subjectId` IS correctly passed (from the roadmapping flow which has a subject selector). The resolver returns topics sorted by prerequisites.

But roadmaps are custom milestone-based plans, not curriculum-aligned. They don't track syllabus completion percentage, and the topics from the resolver are used as suggestions, not as enforced prerequisites.

**Verdict (PARTIAL):** Roadmaps can use the SyllabusResolver correctly (valid subjectId), but are milestone/goal-oriented rather than syllabus-coverage-oriented. They don't solve the syllabus progress tracking need.

---

## Summary of Expectations vs Reality

| Expectation | Reality | Status |
|---|---|---|
| Uploading a syllabus PDF auto-creates topics | `_classifyTopic()` receives empty `possibleTopics: []` — no classification runs. No topic creation code path exists. | **BLOCKER FAIL** |
| I can create topics for my subject | No topic creation UI exists anywhere. `TopicRepository.create()` is dead code (never called from production). | **BLOCKER FAIL** |
| I can configure topic prerequisites | `TopicDependency` model fully implements prerequisites but has zero presentation-layer usage. No editor UI. | **BLOCKER FAIL** |
| Multi-syllabus planner links to real subjects | `SyllabusGoal.subjectId` hardcoded to `''` at planner_screen.dart:144 | **BLOCKER FAIL** |
| Syllabus progress (% complete) is tracked | No syllabus completion percentage anywhere. `estimatedCoverage` is a crude heuristic and never displayed. | **MAJOR FAIL** |
| Prerequisites are enforced in practice/tutor | `TopicReadinessService` exists but is never called from UI. Prerequisites only affect plan heuristics. | **MAJOR FAIL** |
| Subject detail shows topic hierarchy/syllabus tree | No syllabus/topic overview tab. Lessons tab shows scheduled lessons, not topics. | **MAJOR FAIL** |
| Multi-syllabus form has subject picker dropdown | Free-text subject name field with no validation against existing subjects | **MAJOR FAIL** |
| Planner shows "X topics planned" per subject goal | `subjectPlans['']` is empty because subjectId is empty — shows zero topics | **MAJOR FAIL** |
| SyllabusResolver resolves prerequisites correctly | Topological sort, learning levels, and workload estimation are correctly implemented | PASS (infrastructure) |
| Roadmaps use real subject IDs for syllabus resolution | `createRoadmap()` passes valid subjectId to resolver | PASS |

---

## Updated Validation Results (Dry-Run Audit — 2026-05-20)

The following section documents the actual state of the codebase as traced against each step. Many earlier claims are now outdated because the code has evolved since the original scenario was written.

| Step | Scenario Verdict | Actual Status | Evidence & Current Code References |
|---|---|---|---|
| **1** — Upload syllabus PDF → auto-create topics | BLOCKER FAIL | **NOT_COMPLETED** | `_extractTopicsFromSyllabus()` at `content_pipeline.dart:379-445` correctly creates topics from syllabus content via LLM parsing and `TopicRepository.create()`. However, the code path at line 173 requires `type == SourceType.syllabus`. `_inferSourceType()` at `upload_screen.dart:329-359` NEVER returns `SourceType.syllabus` — only `SourceType.pdf` for PDF uploads. The syllabus extraction path is unreachable from the upload flow. |
| **2** — Topic prerequisites UI | BLOCKER FAIL | **COMPLETED** | `SubjectTopicsTab` (`subject_topics_tab.dart`) provides full CRUD (add/edit/delete/reorder). `TopicDependencyDialog` (`topic_dependency_dialog.dart`) provides CheckboxListTile prerequisite picker, mastery threshold slider (0-100%), required toggle, and syllabus weight slider (0.1-3.0). `_addTopic()` (line 67) creates topics and links to subject. |
| **3** — Study plan from syllabus goals | BLOCKER FAIL | **PARTIAL** | **FIXED**: `subjectId` is valid — uses `e.selectedSubjectId!` from subject picker dropdown (`planner_screen.dart:193-194`, `_SyllabusEntry` at line 37-54). Subject picker exists at line 745. `subject_plans` metadata IS written at `personal_learning_plan_service.dart:238-255`. Topic count in `_buildSubjectProgressTabs` (line 859-894) works from `subjectPlans`. `SyllabusProgressCard` shows real mastery-based progress. **STILL BROKEN**: Empty `topicMastery` (new user with no practice history) causes plan generation failure at line 140-144 — `courseName` is empty when `syllabusGoals != null`, so the empty-mastery bypass at line 133 is skipped. |
| **4** — Prerequisite enforcement in practice/tutor | MAJOR FAIL | **COMPLETED** | **FIXED vs scenario**: `PrerequisiteCheckService` (`prerequisite_check_service.dart`) is used from ALL practice entry points via `_checkPrerequisitesForTopicIds()` (called at `practice_screen.dart:244, 440, 493, 540, 622, 664, 790, 800`). `_startTopicPractice()` (line 292) handles dialog result correctly: `if (dialogResult == true) return;`. TutorScreen checks at `tutor_screen.dart:99-118`. No entry points skip checking in current code. `TopicReadinessService` is unused but `PrerequisiteCheckService` fulfills the same role. |
| **5** — Syllabus completion tracking | MAJOR FAIL | **PARTIAL** | **FIXED versus earlier claims**: `SyllabusProgressCard` (`syllabus_progress_card.dart`) shows mastered/total topics with percentage and progress bar in the planner's `_buildSubjectProgressTabs` (line 903). `PlanSummaryCard` (`plan_summary_card.dart:66`) displays `estimatedCoverage` as a percentage. `estimatedCoverage` uses proper `_calculateCoverage(uniqueTopics, totalSyllabusTopics)` at `personal_learning_plan_service.dart:972-977` (not a `/10` heuristic). **STILL BROKEN**: Dashboard shows plan adherence and mastery overview but no syllabus completion percentage. Subject stats tab (`subject_stats_tab.dart`) shows sessions/accuracy/questions/time only. No syllabus completion tracking exists outside the planner screen. |
| **6** — Syllabus/topic tab in subject detail | MAJOR FAIL | **COMPLETED** | Subjects tab exists at `subject_detail_screen.dart:194` (`Tab(icon: Icon(Icons.topic), text: l10n.topics)`). `SubjectTopicsTab` shows topics with prerequisite indentation, lock icons, count badges, and dependency management. |
| **7** — Planner's syllabus UI | MAJOR FAIL | **COMPLETED** | **FIXED vs scenario**: Subject picker dropdown exists at `planner_screen.dart:745-770`. `subjectId` is valid (from `_SyllabusEntry.selectedSubjectId`). Topic count preview via FutureBuilder at line 817. Topic count in progress tabs (line 894) works from `subjectPlans` which IS written. `SyllabusProgressCard` (line 903) shows real progress. Minor: no syllabus document selection from content library. |
| **8** — SyllabusResolver | PARTIAL → COMPLETED | **COMPLETED** | Topological sort (`syllabus_resolver.dart:158-185`), learning levels (187-208), workload estimation (210-221). Receives valid `subjectId` from both plan generation and roadmap creation. |
| **9** — Roadmaps | PARTIAL → COMPLETED | **COMPLETED** | `PlannerService.createRoadmap()` (`planner_service.dart:141-180`) correctly passes valid `subjectId` to `SyllabusResolver.resolveSyllabus()`. Milestone-based tracking works. |

### Summary

| Status | Count | Steps |
|---|---|---|
| COMPLETED | 6 | 2, 4, 6, 7, 8, 9 |
| PARTIAL | 2 | 3, 5 |
| NOT_COMPLETED | 1 | 1 |

**Overall progress: ~67% (6/9 complete).** Not yet at the 80% threshold for deletion. The remaining blockers are: (1) no `SourceType.syllabus` trigger from upload, (3) empty mastery state blocks new-user plan generation, and (5) syllabus completion not shown in Dashboard or Subject Stats.
