# Three Foundational Gaps: Content Ingestion, Smart Planner, Analytics Dashboard

## Summary

The Teaching Mode (AI tutor) and Mentor Mode (AI assistant) from the previous roadmap have been implemented — the scaffolding exists in `lib/features/teaching/` and `lib/features/mentor/`. However, three foundational pillars remain **non-functional or completely disconnected from the UI**: (1) Content ingestion from student-uploaded materials, (2) A smart planner that persists, tracks adherence, and adapts, and (3) An analytics dashboard to visualize the study data the system already collects.

These gaps mean the app collects rich data (attempts, mastery states, session records) but never surfaces it meaningfully. The vision document describes a system where the student uploads materials and the platform intelligently integrates them — none of this exists in a usable form.

---

## Issue 1: Content Ingestion Pipeline Is Scaffolded But Dead

### Current State

| Component | Exists? | State |
|-----------|---------|-------|
| `lib/core/services/pdf_ingestion_service.dart` (150 lines) | Yes | Has `_getMockPdfContent()` as primary path. Hardcoded API key, no UI trigger. |
| `lib/core/data/models/source_model.dart` | Yes | `Source` Hive model with `id`, `title`, `type`, `content`. Stored separately from subjects/topics. |
| `lib/core/data/repositories/source_repository.dart` | Yes | Basic CRUD. 22 lines. Never triggered from any screen. |
| `lib/core/services/question_generation_service.dart` (379 lines) | Yes | Generates questions via LLM but has no UI workflow for triggering it. |
| Upload UI (file picker, drag-drop, link entry) | **No** | Zero UI. Student has no way to ingest materials. |

The vision says:
> *"Students should be able to upload large amounts of study materials such as textbooks, PDFs, notes, question banks, syllabi, online video link, video/audio, online website link, screenshots, etc. The system should intelligently process, organize, classify, validate, and integrate this material into the broader learning system."*

**None of this exists in a usable form.** The `PdfIngestionService` will only parse if `apiKey` is non-empty; otherwise it returns mock data silently. There is no screen, dialog, or button to upload content. The `Source` model and repository are orphaned.

### Rationale

This is the primary _input_ mechanism for the entire learning system. Without it:
- Questions must be manually created (or never created)
- Subjects are empty shells
- The AI tutor has no content to teach
- The planner has no topics to schedule

### Affected Files

| File | Issue |
|------|-------|
| `lib/core/services/pdf_ingestion_service.dart:19-21` | Falls back to `_getMockPdfContent()` when API key is empty — silently produces fake data with no user feedback |
| `lib/core/services/pdf_ingestion_service.dart` | Single-purpose (PDF only). No support for web links, video, screenshots. |
| `lib/core/data/models/source_model.dart` | `Source` has no `subjectId`, `topicId`, or `syllabusId` — cannot be linked to the learning graph |
| `lib/core/data/repositories/source_repository.dart` | Orphan — never imported or used by any screen or service |
| `lib/core/services/question_generation_service.dart:27-55` | Generates questions but no UI workflow exists to invoke this with student materials as context |

### Acceptance Criteria

- [ ] **Upload UI**: A screen or bottom sheet allows the student to select a file (PDF, image), enter a URL, or paste text. The UI is accessible from subject management and the home screen.
- [ ] **Pipeline orchestration**: Uploaded content flows through: classification (which subject/topic) -> parsing/extraction -> question generation -> source storage with subject/topic linkage.
- [ ] **Source model update**: `Source` gains `subjectId`, `topicId`, and `syllabusId` fields to link materials to the learning graph.
- [ ] **Fallback removal**: Remove silent mock fallback in `PdfIngestionService`. If the API call fails, surface the error to the user with a retry option.
- [ ] **UI feedback**: Upload progress indicator, success/error states, and a "Your Sources" list visible per subject.

---

## Issue 2: Smart Planner Disconnected — Plans Are Generated but Never Persisted, Tracked, or Adapted

### Current State

Three planning-related subsystems exist but are completely disconnected:

1. **PlannerScreen** (`lib/features/planner/presentation/planner_screen.dart`): Accepts course name, days, hours. Cycles through up to 7 matching topic titles equally. LLM integration attempt has hardcoded empty API key (line 147). The generated `_ScheduleItem` list is stored in-memory only — lost on navigation away.

2. **PersonalLearningPlanService** (`lib/core/services/personal_learning_plan_service.dart`): Generates data-driven plans from mastery graph data with priority sorting, dependence checking, and daily breakdowns. Returns a `PersonalLearningPlan` model. **Never connected to the Planner UI.** Not saved to Hive.

3. **InstrumentationService** (`lib/core/services/instrumentation_service.dart`): Contains `PlanAdherenceTracker` and `MasteryImprovementTracker` with full adherence-scoring logic. **Never invoked** from any planner or session flow — both trackers are memory-only, meaning data is lost on app restart.

The vision says:
> *"The system should: estimate realistic workload, break longterm goals into manageable schedules, generate lesson pathways, assign practice, adapt plans as progress changes, track actual adherence vs intended schedule."*

Currently: schedules are mock data, plans are generated but never saved, adherence is computed but never tracked, nothing adapts.

### Rationale

The planner is the strategic layer of the app. Without persistence and adaptation:
- Students generate a plan once, see it disappear on navigation
- The mentor cannot reference "your study plan" because no plan exists in storage
- Adherence tracking (`InstrumentationService`) computes metrics that are never used
- The "180 days to learn IB Physics" use case from the vision is impossible

### Affected Files

| File | Issue |
|------|-------|
| `lib/features/planner/presentation/planner_screen.dart:144-174` | LLM integration calls `LlmService` with `apiKey: ''` — always fails. Fallback cycles through max 7 topics. |
| `lib/features/planner/presentation/planner_screen.dart:390-407` | `_ScheduleItem` is a private class defined inline. Cannot be persisted or referenced elsewhere. |
| `lib/core/services/personal_learning_plan_service.dart` | `generatePlan()` returns `Result<PersonalLearningPlan>` but result is never saved to Hive. No `savePlan()` or `loadPlan()` method exists. |
| `lib/core/data/models/personal_learning_plan_model.dart` | Model exists with `dailyPlans`, `recommendations`, `summary` — but no Hive adapter registered for it (check `hive_type_ids.dart`). Data cannot persist. |
| `lib/core/services/instrumentation_service.dart:83-113` | `PlanAdherenceTracker.recordDay()` is never called. `getAverageAdherence()` returns 0.0 for everyone. |
| `lib/features/practice/presentation/learning_plan_dashboard.dart:39-67` | `_loadData()` calls `generatePlan()` on every build — no caching, no persistence. |

### Acceptance Criteria

- [ ] **Plan persistence**: `PersonalLearningPlan` is saved to Hive after generation (via a new `plan_repository.dart`). Loading a subject shows the previously generated plan.
- [ ] **Planner UI rewrite**: `PlannerScreen` uses `PersonalLearningPlanService` instead of inline mock generation. The LLM fallback (empty API key) is removed; the user sees a clear "Configure AI provider" prompt instead.
- [ ] **Adherence tracking**: `SessionTrackerScreen._endSession()` triggers `PlanAdherenceTracker.recordDay()` to log planned vs actual. The mentor can report "You completed 80% of your plan this week."
- [ ] **Plan adaptation**: After 3 consecutive days of under-adherence (<50%), the system suggests adjusting the plan (e.g., reduce daily target, re-prioritize topics).
- [ ] **Long-term goals**: The planner accepts natural language like "I want to finish IB Physics in 180 days" and breaks it into weekly/daily plans (delegating to LLM via `LlmService` with the real configured provider).
- [ ] **Mentor integration**: `MentorService.getSchedule()` queries persisted plans, not inline-generated schedules.

---

## Issue 3: Analytics Dashboard Exists But Is Inaccessible — Study Data Collected but Never Visualized

### Current State

The system tracks rich data:
- **AttemptRepository**: Per-question attempt records with correctness, timing, confidence
- **MasteryGraphService**: Per-topic and per-question mastery states with levels (Novice → Expert)
- **StudySessionRepository**: Session records with duration, questions answered, correct count
- **StudyProgressTracker**: Computes overall stats, weekly trends, badges, recommendations, topic progress
- **InstrumentationService**: Tracks plan adherence and mastery improvement over time
- **AdaptivePracticeEngine**: Selects questions based on weakness scores

An `AnalyticsDashboard` widget exists at `lib/features/practice/presentation/analytics_dashboard.dart` (632 lines) with summary rows, weekly charts, mastery progress bars, topic-level breakdowns, and badges. **It is never shown to the user** — there is no navigation entry pointing to it.

The vision says:
> *"The platform should track: study hours by subject, syllabus progress, performance history, lesson completion, practice behavior, weak/strong topic areas, adherence to planned study schedules."*

All of this is computed. None of it is visible.

### Additional visualization gaps

1. **Weekly trend chart** (`_buildWeeklyChart` in analytics_dashboard.dart) uses `AnimatedBarChart` which itself (`lib/core/widgets/animated_bar_chart.dart`) uses hardcoded `EdgeInsets.all(16)` and no axis labels — the chart is non-functional as a data visualization.

2. **Topic mastery view** displays mastery levels but uses LLM-generated topic IDs (not human-readable names) as labels. No search or filter.

3. **StudyProgressTracker.getTopicMasteryLevel()** has a fallback path (lines 239-248) that derives level from attempt count and accuracy but the main mastery path (line 227) calls `_masteryService.getTopicMastery()` which itself depends on the mastery graph repository being initialized — if the student has no data, every topic shows as `'Novice'`.

4. **No aggregate dashboard** combining planner data (what was planned), session data (what was done), and mastery data (what was learned) into a single view.

### Rationale

Without a visible analytics dashboard:
- The student cannot see their progress, reducing motivation
- The system cannot identify weak areas — the "weak areas practice" mode in `PracticeScreen` calls `MasteryGraphService.getWeakTopics()` but the student never sees what those are
- Badges (gamification) are computed but invisible
- The feedback loop (study → see progress → adjust → improve) is broken

### Affected Files

| File | Issue |
|------|-------|
| `lib/features/practice/presentation/analytics_dashboard.dart` | 632-line widget never connected to any navigation route or tab |
| `lib/core/widgets/animated_bar_chart.dart:30` | Hardcoded padding, no axis labels, no tooltips — chart is non-informative |
| `lib/features/practice/presentation/analytics_dashboard.dart:362-380` | Topic IDs displayed as raw strings — no lookup to human-readable names |
| `lib/core/services/study_progress_tracker.dart:224-251` | `getTopicMasteryLevel()` has dead fallback code — real mastery path never activated for students without data |
| `lib/features/sessions/widgets/session_analytics.dart` | Widget exists but is only shown inside `SessionTrackerScreen` — not accessible from subjects or home |

### Acceptance Criteria

- [ ] **Dashboard navigation**: The analytics dashboard is accessible from either a new tab in the bottom navigation, the subject detail screen's Stats tab, or the mentor screen's "Progress Report" button.
- [ ] **Chart readability**: `AnimatedBarChart` is replaced or enhanced with proper axis labels, value tooltips, and theme-aware colors.
- [ ] **Topic name resolution**: Topic IDs in the mastery view are resolved to human-readable titles via `TopicRepository`.
- [ ] **Combined view**: A single dashboard screen shows: plan adherence (planned vs actual), mastery progression per topic, weekly study trends, and recent badges — all in one scrollable view.
- [ ] **Export action**: "Export Data" button on the dashboard triggers CSV download via existing `StudyProgressTracker.exportProgressCSV()` / `exportSessionHistoryCSV()` methods.
- [ ] **Weak area visibility**: The dashboard highlights topics with accuracy < 60% and provides a "Practice Weak Areas" button that navigates to `PracticeSessionScreen`.
- [ ] **Student ID management**: Replace hardcoded `'anonymous'` student ID (used in 7+ files: `tutor_screen.dart:73`, `mentor_service.dart:58`, `progress_tracker.dart`, etc.) with a configurable or auto-generated student profile.

---

## Cross-Cutting Issue: Hardcoded `'anonymous'` Student ID

Throughout the codebase, the student ID is hardcoded as `'anonymous'`:

| File | Line |
|------|------|
| `lib/features/teaching/presentation/tutor_screen.dart` | 73 |
| `lib/features/mentor/services/mentor_service.dart` | 58 |
| `lib/core/services/personal_learning_plan_service.dart` | 280 |
| `lib/core/services/study_progress_tracker.dart` | 81, 224, 253 |
| `lib/features/sessions/presentation/session_tracker_screen.dart` | 16 |
| `lib/features/practice/presentation/practice_screen.dart` | 805 |

As long as every component uses `'anonymous'`, all progress from one device is conflated, and multi-device or multi-user scenarios are impossible. This blocks export/backup (whose data to export?), personalized mentoring, and accurate analytics.

### Acceptance Criteria

- [ ] Student ID is generated once at first launch (via `uuid`) and persisted in settings.
- [ ] All hardcoded `'anonymous'` references are replaced with a provider or injected value from settings.
- [ ] "Export my data" exports the correct student's data.

---

## Summary of New Files Needed

| File | Purpose |
|------|---------|
| `lib/features/ingestion/` | New feature module for content upload & processing |
| `lib/features/ingestion/presentation/upload_screen.dart` | File picker, URL entry, paste UI |
| `lib/features/ingestion/services/content_pipeline.dart` | Orchestrates: classify → parse → generate questions → store source |
| `lib/core/data/repositories/plan_repository.dart` | Persist/load `PersonalLearningPlan` to/from Hive |
| `lib/features/dashboard/` | New feature module for the unified analytics dashboard |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Combined view: adherence + mastery + trends + badges |

## Priority

| Issue | Priority | Risk |
|-------|----------|------|
| Content ingestion | High | Current code silently produces mock data (misleading) |
| Smart planner | High | Core workflow (plan → study → track → adapt) is broken |
| Analytics dashboard | Medium | All tracking infrastructure exists but is invisible |
| Hardcoded student ID | High | Blocks personalization, export, and multi-user scenarios |
