# Future Functionality Planner: High-Value Gaps & Roadmap Opportunities

## 1. Consolidate Redundant Canvas Drawing Widgets

**Context:** Two separate canvas drawing widgets exist — a full-featured one at `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` (337 lines, with undo, grid, save-as-PNG, pressure sensitivity, accessibility) and a simpler variant at `lib/core/widgets/canvas_drawing_widget.dart` (146 lines, basic line drawing). This is confusing for developers and risks divergence.

**Affected files:**
- `lib/core/widgets/canvas_drawing_widget.dart`
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart`
- All files importing either widget (e.g., `practice_session_screen.dart`)

**Rationale:** Eliminates dead code, single source of truth for drawing, easier maintenance. The feature widget should subsume the core variant.

**Acceptance criteria:**
- Remove `lib/core/widgets/canvas_drawing_widget.dart`
- Update all imports to use the feature-level widget
- Verify `practice_session_screen.dart` and all canvas question flows work

---

## 2. Implement Voice/Speech Interaction System

**Context:** The vision mandates typed input, voice conversation, speech-to-text, and text-to-speech as first-class interaction modes. Currently `voiceInput` is defined in localizations and referenced as a tooltip in `tutor_screen.dart` (line 305), but **zero actual implementation exists** — no STT, no TTS, no packages.

**Affected files:**
- `lib/features/teaching/presentation/tutor_screen.dart`
- `lib/core/widgets/conversation_input.dart`
- `lib/l10n/app_en.arb` / `app_es.arb`
- `pubspec.yaml` (needs `speech_to_text`, `flutter_tts` or equivalent)

**Rationale:** Voice interaction is central to the product vision (natural conversational tutoring). Without it, the tutor mode cannot deliver on its promise of "real-time back-and-forth discussion through both text and voice."

**Acceptance criteria:**
- Add speech-to-text recording button in conversation input
- Add text-to-speech playback for AI responses (toggleable)
- Wire voice input into the tutor's conversation_manager
- Support multiple locales for speech recognition
- Add settings to configure voice input language, TTS speed/voice

---

## 3. Build Study Roadmap & Long-Term Planning System

**Context:** The vision describes "creating or modifying study roadmaps" as a core mentor capability ("I want to learn IB Physics in 180 days"). Currently there is **only a single string reference** in `mentor_service.dart` line 243. No roadmap model, no plan generation, no timeline visualization exists. The `planner` feature is a single bare screen.

**Affected files:**
- `lib/core/services/personal_learning_plan_service.dart` (exists but disconnected)
- `lib/features/planner/` (needs full rewrite)
- `lib/features/mentor/services/mentor_service.dart`
- `lib/core/data/models/` (needs `roadmap_model.dart`, `milestone_model.dart`)
- `lib/l10n/` (new roadmap-related strings)

**Rationale:** This is a differentiator — no other study app generates adaptive, LLM-driven multi-month roadmaps with milestone tracking. Without it, "mentor mode" is just a chatbot.

**Acceptance criteria:**
- Create `RoadmapModel` with goals, milestones, time estimates, completion %
- Create `MilestoneModel` with deadline, topics covered, assessment criteria
- Implement `PersonalLearningPlanService` to generate a plan from a goal string via LLM
- Planner screen renders a timeline/Gantt view of the roadmap
- Mentor mode can create/modify roadmaps conversationally
- Track adherence (planned vs actual progress) per the vision

---

## 4. Build Notification & Proactive Engagement System

**Context:** The vision requires the system to "proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement." No notification/reminder infrastructure exists — no local notifications, no scheduling service.

**Affected files:**
- `pubspec.yaml` (needs `flutter_local_notifications`, `workmanager` or equivalent)
- `lib/core/services/engagement_scheduler.dart` (exists but has no notification delivery mechanism)
- `lib/core/providers/app_providers.dart`
- `lib/features/settings/` (notification preferences UI)

**Rationale:** Proactive engagement transforms the app from a passive tool into an active study companion. Without it, students must remember to open the app themselves, dramatically reducing retention and effectiveness.

**Acceptance criteria:**
- Schedule local notifications for: daily practice reminders, spaced repetition due alerts, lesson start nudges, low-mastery topic warnings
- Configurable quiet hours and per-subject notification preferences
- Don't over-notify (respect "prevent student from overworking and stress" from vision)
- Notifications open the relevant screen on tap

---

## 5. Multi-Syllabi Dashboard & Side-by-Side Progress

**Context:** The vision explicitly states "students should be able to learn and track from multiple syllabi simultaneously." Currently syllabus is a single text field on `SubjectModel`; there is no UI for viewing or comparing progress across syllabi.

**Affected files:**
- `lib/features/subjects/` (needs multi-syllabus selection UI)
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/core/services/mastery_graph_service.dart` (may need syllabus-scoped queries)
- `lib/features/practice/presentation/learning_plan_dashboard.dart`

**Rationale:** Real students study multiple subjects from different syllabi (e.g., IB Physics + A-Level Math). Without multi-syllabi views, the system cannot fulfill its all-in-one promise.

**Acceptance criteria:**
- Dashboard shows per-syllabus progress cards
- Each syllabus has independent mastery tracking, time tracking, and lesson planning
- Student can switch between syllabus contexts for lessons/practice
- Topics are tagged with syllabusId; queries filter by active syllabus

---

## 6. LLM Task Manager Portal UI

**Context:** `lib/core/services/llm_task_manager.dart` exists and tracks active LLM inference tasks. The vision says there should be "a task manager-like portal to view actively running inferencing tasks and for what purpose." No UI exists for this.

**Affected files:**
- `lib/features/llm_tasks/` (directory exists but needs implementation)
- `lib/core/services/llm_task_manager.dart`
- `lib/features/settings/presentation/settings_screen.dart` (entry point)
- `lib/l10n/`

**Rationale:** Users need visibility into what the AI is doing — pending tasks, token usage, failures. This builds trust and helps debug performance issues.

**Acceptance criteria:**
- Screen showing all active/completed/failed LLM tasks with purpose, status, timing
- Token usage meter per task and in aggregate
- Cancel in-flight tasks
- Navigate to the originating context (lesson, question generation, etc.)

---

## 7. Progress Export & Reporting

**Context:** The vision demands "exportable progress." No export functionality exists in the codebase.

**Affected files:**
- `lib/core/services/study_progress_tracker.dart` (needs export methods)
- `lib/features/sessions/presentation/session_history_screen.dart`
- `pubspec.yaml` (may need CSV or PDF export utilities — `pdf` already exists)
- `lib/features/settings/` (export UI)

**Rationale:** Students and parents need to share progress with teachers/tutors. Export also serves as a backup mechanism, critical for a long-term study companion.

**Acceptance criteria:**
- Export study hours, mastery levels, and practice history as PDF report
- Export raw data as CSV/JSON for external analysis
- Export includes: subject breakdown, topic-level mastery, time spent, question history
- Share/email export from within the app

---

## Prioritization Guidance

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| P0 | Canvas widget consolidation | Small | Medium (cleanup) |
| P0 | Voice/Speech interaction | Large | Critical (vision gap) |
| P0 | Notification/proactive engagement | Medium | Critical (retention) |
| P1 | Study Roadmap & planning | Large | High (differentiator) |
| P1 | LLM Task Manager Portal | Small | Medium (transparency) |
| P2 | Multi-syllabi dashboard | Medium | High (core requirement) |
| P2 | Progress export | Medium | Medium (parity) |
