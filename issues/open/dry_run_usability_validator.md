# Dry-Run Usability Validator — Cumulative Issue Log

> **Purpose:** This file tracks usability issues discovered through systematic dry-run validation of user scenarios against the actual source code. Each entry describes a real user journey, the expected behavior, the actual behavior found in code, and concrete acceptance criteria for resolution.
>
> **Severity levels:**
> - **BLOCKER** — App crashes, user cannot proceed, core workflow impossible
> - **MAJOR** — Feature is broken, misleading, or missing critical functionality
> - **MINOR** — UX friction, cosmetic, edge case, or incomplete polish

---

## Scenario: Syllabus-Driven Curriculum Learning

> "I'm a student who wants to systematically learn IB Chemistry following its official syllabus. I expect StudyKing to parse my syllabus PDF into topics, let me set up prerequisites, create a prerequisite-respecting study plan, track syllabus completion, and enforce prerequisites in practice."

### Summary

StudyKing has a sophisticated syllabus infrastructure in the data layer (SyllabusGoal, TopicDependency, SyllabusResolver with topological sort) and a well-designed multi-syllabus planner UI. However, the user-facing flow is disconnected from the backend: topics cannot be created from uploaded syllabi, topic dependencies have no editor UI, the planner form produces SyllabusGoals with empty subjectId, prerequisites are never enforced, and syllabus completion percentage is not tracked. The engine is built but the ignition wire is unplugged.

---

### BLOCKER Findings

#### B1. Syllabus upload does not create topics

- **Affected files:**
  - `lib/features/ingestion/presentation/upload_screen.dart:240` — passes `possibleTopics: []`
  - `lib/features/ingestion/services/content_pipeline.dart:281-324` — `_classifyTopic()` returns `''` when possibleTopics is empty
  - `lib/features/subjects/presentation/subject_detail_screen.dart` — no topic management tab, no "Manage Topics" option
  - No production code calls `TopicRepository.create()` (zero grep hits for `Topic(id:` outside tests)
- **Rationale:** A student uploading a syllabus PDF reasonably expects the app to extract topic structure and create Topics. The pipeline has a classification stage that calls the LLM to identify topics, but the upload screen disables it by passing an empty `possibleTopics` list. Even if the LLM identified "Atomic Structure", there is no code path that calls `TopicRepository.create()`.
- **Acceptance criteria:**
  1. Upload screen passes `possibleTopics` from the subject's existing topics (or a reasonable default) when uploading a syllabus-type document
  2. When classification identifies a topic title that doesn't exist in the repository, a new `Topic` is auto-created under the subject
  3. Post-upload, the subject detail screen shows the newly created topics
  4. User receives feedback: "3 topics created from your syllabus: Atomic Structure, Bonding, Stoichiometry"

#### B2. No topic creation/dependency editing UI

- **Affected files:**
  - `lib/features/subjects/presentation/subject_detail_screen.dart` — no topic management in any tab or menu
  - `lib/features/subjects/data/models/topic_dependency_model.dart` — full model with prerequisites, masteryThreshold, isRequired, syllabusWeight; zero presentation-layer usage
  - `lib/features/subjects/presentation/subject_form_widgets.dart` — only has Name, Code, Teacher, Syllabus, Description fields; no topic sub-form
  - `lib/features/subjects/data/repositories/topic_repository.dart` — `create()`, `update()`, `delete()` exist but are dead code for production
  - `lib/features/subjects/data/repositories/subject_repository.dart:28` — `addTopicToSubject()` exists but is dead code
- **Rationale:** A student cannot create topics, edit topics, set prerequisites, configure mastery thresholds, or define topic ordering through any UI. The TopicDependency model supports all of these but is only used internally by SyllabusResolver. The only way to have topics in the system is through data import or test fixtures — neither is accessible to a real user.
- **Acceptance criteria:**
  1. Subject Detail screen has a "Topics" tab (or "Manage Topics" option in the menu) showing all topics for the subject
  2. "Add Topic" button/dialog with fields: title, description, syllabus text
  3. Topic detail/edit screen with prerequisite selector (multi-select from subject's other topics)
  4. Topic dependency editor with: prerequisite selection, mastery threshold slider, isRequired toggle, syllabus weight
  5. Delete topic with confirmation and cascade handling (remove from dependent topics' prerequisite lists)
  6. Topic reordering (drag handle or sort-order up/down buttons)

#### B3. Multi-syllabus planner sets empty subjectId

- **Affected files:**
  - `lib/features/planner/presentation/planner_screen.dart:143-148` — `SyllabusGoal(subjectId: '', ...)`
  - `lib/features/planner/presentation/planner_screen.dart:456-537` — `_buildMultiSyllabusInput()` uses free-text subject name field with no subject picker
  - `lib/core/services/personal_learning_plan_service.dart:146-153` — iterates syllabus goals and calls `getBySubject(goal.subjectId)` which returns empty for `''`
  - `lib/core/services/personal_learning_plan_service.dart:175-176` — uses `syllabusGoals.first.subjectId` (empty) for `resolveSyllabus(subjectId: '')`
- **Rationale:** The multi-syllabus planner form looks well-designed with cards for subject name, days, and hours. But the `subjectId` is hardcoded to empty string. The form should present a dropdown of existing subjects and pass the selected subject's real ID. Without this, the plan generation loads zero topics, the SyllabusResolver fails to resolve anything, and daily plans are empty.
- **Acceptance criteria:**
  1. Multi-syllabus entry cards replace free-text subject name with a dropdown selector showing actual subjects from the database
  2. `SyllabusGoal.subjectId` is set to the real subject ID, not `''`
  3. `SyllabusGoal.subjectTitle` is auto-populated from the selected subject's name
  4. After plan generation, the syllabus goal cards show real topic counts from the resolved syllabus
  5. The single-course mode (free-text course name) should also offer a subject picker or at least validate the text against existing subjects

---

### MAJOR Findings

#### M1. No syllabus completion percentage anywhere

- **Affected files:**
  - `lib/features/dashboard/` — zero references to syllabus completion
  - `lib/features/subjects/presentation/subject_detail_screen.dart` — Stats tab shows attempts/accuracy/time but no syllabus progress
  - `lib/features/planner/presentation/planner_screen.dart:539-577` — `_buildSubjectProgressTabs()` shows syllabus goal cards with topic count but no completion percentage
  - `lib/core/services/personal_learning_plan_service.dart:815-818` — `estimatedCoverage` is a crude `uniqueTopics / 10` heuristic, never displayed
- **Rationale:** A student studying from a structured curriculum needs to know "how much of the syllabus have I covered." The app tracks per-topic mastery, plan adherence, and overall accuracy — but never combines these into a syllabus completeness metric. The crude `estimatedCoverage` heuristic (assuming 10 topics = full syllabus) is not exposed in any UI and is mathematically wrong for any syllabus with a different number of topics.
- **Acceptance criteria:**
  1. Dashboard shows a "Syllabus Progress" card per subject: colored progress ring/bar with "X of Y topics mastered (Z%)"
  2. Topic counts come from the actual topic repository for that subject, not from a hardcoded divisor
  3. Subject Detail screen's Stats tab shows syllabus completion with per-topic status (Not Started / In Progress / Mastered)
  4. The `estimatedCoverage` calculation is replaced or supplemented with `masteredTopics / totalTopics`
  5. Planner syllabus goal cards show progress: "12 of 34 topics mastered (35%)" instead of just topic count

#### M2. Prerequisites never enforced in practice or tutor

- **Affected files:**
  - `lib/features/practice/presentation/screens/practice_session_screen.dart:106-145` — loads questions by subject/topic, no prerequisite check
  - `lib/features/teaching/presentation/tutor_screen.dart` — starts tutor with topic/subject, no prerequisite check
  - `lib/core/services/topic_readiness_service.dart` — `getReadyTopics()` and `getNextRecommendedTopics()` exist but are never called from any UI code (zero grep hits in `lib/features/`)
  - `lib/features/planner/services/syllabus_resolver.dart:187-208` — `buildLearningLevels()` groups topics by readiness but has no UI consumer
- **Rationale:** The product vision says prerequisites should ensure students build knowledge in the right order. The TopicDependency model and TopicReadinessService fully support this. But no practice mode, topic selector, or tutor entry point checks prerequisites. A student can study "Organic Chemistry" without mastering "Atomic Structure" — defeating the purpose of a structured curriculum.
- **Acceptance criteria:**
  1. Before starting a Topic Focus or Weak Areas practice session, check if the selected topic has unmet prerequisites
  2. If prerequisites are unmet, show a dialog: "This topic requires mastery of [prerequisite topics]. Would you like to practice those first?"
  3. Tutor entry points (daily plan card, topic chip) perform the same prerequisite check
  4. Topic selection sheets (Topic Focus, Weak Areas) show lock icons on topics with unmet prerequisites
  5. The prerequisite check uses the mastery threshold from TopicDependency (default 0.8)
  6. TopicReadinessService is integrated into practice providers and tutor providers

#### M3. Subject detail has no topic/syllabus overview

- **Affected files:**
  - `lib/features/subjects/presentation/subject_detail_screen.dart` — 5 tabs: Lessons, Practice, Sources, History, Stats; none show topics or syllabus structure
  - `lib/features/lessons/presentation/widgets/` — shows Lesson objects, not Topics
  - `lib/features/subjects/presentation/subject_form_widgets.dart` — only has basic subject fields
- **Rationale:** A student needs to see their subject's topic structure. The data model supports hierarchy (Topic.parentId, childTopicIds, TopicDependency.parentTopicId, sortOrder), but no screen renders it as a tree, list, or learning path. The Lessons tab shows scheduled tutoring sessions (which may not exist yet), not the underlying topic hierarchy.
- **Acceptance criteria:**
  1. Subject Detail has a "Syllabus" tab (or replaces "Lessons" with "Topics" for subjects with no scheduled lessons)
  2. Syllabus tab shows topics in hierarchical order respecting sortOrder and prerequisites
  3. Each topic shows: mastery status (locked/unlocked/in-progress/mastered), accuracy %, next review date
  4. Topics are grouped by learning levels (prerequisites-met groups)
  5. Tapping a topic navigates to topic practice or topic detail

#### M4. Multi-syllabus form lacks subject picker and topic preview

- **Affected files:**
  - `lib/features/planner/presentation/planner_screen.dart:456-537` — `_buildMultiSyllabusInput()` with free-text subject name
  - `lib/features/planner/presentation/planner_screen.dart:143-148` — SyllabusGoal creation uses typed text
- **Rationale:** The multi-syllabus planner is the primary UI for curriculum-driven planning. It should let users select actual subjects, show how many topics each subject has, preview the resolved topic order, and display topic count feedback after generation. Currently the form accepts arbitrary text with no validation, produces broken data (empty subjectId), and shows "0 topics" on result cards.
- **Acceptance criteria:**
  1. Subject name field is replaced with a searchable dropdown of existing subjects
  2. When a subject is selected, show: "12 topics found in this subject"
  3. Add a "Preview topic order" button that shows the topologically-sorted topic list before generating
  4. After plan generation, syllabus goal cards show "12 topics planned in prerequisite order"
  5. The single-course mode (free-text course name) also gets a subject picker option

---

### MINOR Findings

#### m1. Single-course planner accepts course name that does nothing

- **Affected files:**
  - `lib/features/planner/presentation/planner_screen.dart:162-183` — creates a plan with free-text `course` but `course` is just a label, never linked to a real subject
  - `lib/features/planner/providers/planner_providers.dart` — `generatePlan()` accepts `course` but only passes it as a label
  - Confirms scenario 1's finding: course name is silently ignored by plan generation
- **Rationale:** In single-course mode, the user types "IB Chemistry" expecting the plan to center on IB Chemistry content. But `course` is metadata only — the plan is built from mastery state (which is empty for a new user). The user sees a plan with "IB Chemistry" in the title but zero content tailored to it.
- **Acceptance criteria:**
  1. Single-course mode shows a note: "Select a subject to base your plan on its syllabus and topics"
  2. Free-text course name is either validated against existing subjects or replaced with a subject picker
  3. Error message if the typed course name doesn't match any subject: "No subject named 'IB Chemistry' found. Create it first in the Subjects tab."

#### m2. Planner form doesn't validate that subjects have topics before generation

- **Affected files:**
  - `lib/features/planner/presentation/planner_screen.dart:127-158` — no check that the selected/typed subject has topics
  - `lib/core/services/personal_learning_plan_service.dart:148-153` — silently returns empty if `getBySubject` returns nothing
- **Rationale:** A student can happily fill in "IB Chemistry" with 90 days and get a plan generated. If the subject has no topics (which it won't, since there's no topic creation UI), the plan is 90 days of "General review" — no content. The app should validate upfront.
- **Acceptance criteria:**
  1. Before generating a plan, check that the subject has at least one topic
  2. Show a clear message: "IB Chemistry has no topics. Upload a syllabus to auto-create topics, or add topics manually."

#### m3. EN ARB file has duplicate "today" key

- **Affected files:**
  - `lib/l10n/app_en.arb` — duplicate `"today"` key at lines ~114 and ~3496
- **Rationale:** The duplicate key doesn't cause a runtime error (the ARB parser takes the last value), but it indicates the ARB files may have maintenance issues. This could mask future translation gaps or cause localization tooling warnings.
- **Acceptance criteria:**
  1. Remove the duplicate `"today"` key from `app_en.arb`
  2. Audit the ARB file for other potential duplicates

#### m4. `LlmService.defaultSystemPrompt` always returns English

- **Affected files:**
  - `lib/core/services/llm/llm_chat_service.dart:29-30` — `AppLocalizationsEn().aiDefaultSystemPrompt`
  - `lib/core/services/llm/llm_chat_service.dart:60,84` — `defaultSystemPrompt` used as fallback when no explicit systemPrompt is provided
- **Rationale:** When QuickGuide or other features call `chat()` or `chatStream()` without providing a locale-aware `systemPrompt`, the default system prompt is hardcoded to English. An `es` locale user will see an English system prompt as context for the LLM, which may cause the LLM to respond in English even when the user writes in Spanish. Most call sites provide explicit system prompts, but the default fallback should be locale-aware.
- **Acceptance criteria:**
  1. `defaultSystemPrompt` uses the current app locale, not hardcoded English
  2. Option A: Make `chat()`/`chatStream()` accept optional locale parameter and look up localized prompt
  3. Option B: Remove the hardcoded fallback and require callers to always provide a locale-appropriate system prompt

#### m5. `percentComplete` l10n method is dead code

- **Affected files:**
  - `lib/l10n/generated/app_localizations_en.dart` (ES equivalent too) — `percentComplete(int percent, int completed, int total)` defined but never called from production code (only from tests)
- **Rationale:** The localization method exists and is translated, meaning effort was invested in it. But no UI code ever calls it. If a future feature wants to display "85% Complete: 17 of 20 topics", it should use this method rather than re-inventing the string formatting.
- **Acceptance criteria:**
  1. Either integrate `percentComplete` into the syllabus progress display (see M1), or remove the dead code
  2. If kept, add documentation that this method is the canonical way to display "X% Complete: N of M" strings

---

## Historical Note: Previously Reported Issues — Re-verification

The following findings from earlier scenarios were spot-checked during this code analysis. Some have been resolved or partially addressed since the original scenarios were written.

### Re-verified: EngagementScheduler now reads notification preferences

**Original finding (scenario_focus_mode_daily_habit, BLOCKER FAIL):** "EngagementScheduler never reads settings — notification preferences are cosmetic only."

**Current status:** RESOLVED. `engagement_scheduler.dart:116-131` has `_isNotificationEnabled()` which checks `studyRemindersEnabled`, `revisionRemindersEnabled`, `lessonNotificationsEnabled`, `overworkAlertsEnabled`, `planAdjustmentNotificationsEnabled`. All five nudge types (overwork at line 154, revision at line 180, planAdjustment at line 210, weakTopics at line 236, lessonReminder at line 131) route through this check.

### Re-verified: Onboarding exists and works

**Original finding (scenario_first_launch_ib_chemistry, FAIL):** "App explains itself on first launch — No onboarding, dropped into 5-tab shell."

**Current status:** RESOLVED. `main.dart:289-297` has `_handleFirstLaunch()` which shows a non-dismissible `OnboardingDialog` listing all 5 features and a `LocalDataNotice` dialog. The onboarding dialog offers two paths: "Get Started" (→ subject selection) and "Quick Guide" (→ quick guide).

> **Note:** The first-launch scenario did correctly identify several issues that are still open (static checklist items, course name ignored by planner, no syllabus database, lesson content not pre-generated). Those are tracking in this issue file and the original scenarios respectively.
