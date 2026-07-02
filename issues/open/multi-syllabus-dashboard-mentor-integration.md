# Multi-Syllabus: Deeper Integration Across Dashboard, Mentor, and Tutor

**Severity:** minor
**Affected area:** Dashboard, Mentor, Teaching — Multi-Syllabus Support
**Reported by:** codebase audit

## Description

The vision document states: "The system should allow student to learn and track from multiple syllabi simultaneously." The planner has partial support for this via `SyllabusGoal[]` in `PersonalLearningPlanService`, where multiple subjects can be combined into one study plan. However, the rest of the application does not fully leverage multi-syllabus context:

1. **Dashboard** — Shows aggregate stats across all subjects but doesn't provide per-syllabus breakdowns or side-by-side comparison
2. **Mentor context** — The `MentorContextBuilder` builds context for all subjects mixed together, but doesn't distinguish which syllabus/plan a student is referring to
3. **Tutor** — Lessons are always for one subject/topic; there's no concept of switching between multiple active syllabi within a session
4. **Dashboard widgets** — The mastery card, weak areas card, and adherence card show aggregate data, not per-syllabus
5. **Progress tracking** — There's no way to see "I'm 60% through IB Physics and 40% through A-Level Math" side by side

## Expected behavior

The system should:
- Show per-syllabus progress and stats on the dashboard (tabs, sections, or side-by-side cards)
- Allow the mentor to understand which syllabus the student is referring to in conversation
- Provide syllabus-switching context in the tutor (student can say "switch to my chemistry syllabus")
- Display per-syllabus adherence, weak areas, and recommendations

## Actual behavior

Multi-syllabus is partially supported in the planner (plan generation from multiple subjects) but not surfaced in the dashboard, mentor, or tutor context.

## Code analysis

- `lib/features/planner/services/personal_learning_plan_service.dart` — `SyllabusGoal[]` supports multiple subjects in one plan
- `lib/features/dashboard/providers/dashboard_data_providers.dart` — Provides aggregate stats, no per-syllabus filtering
- `lib/features/dashboard/presentation/widgets/mastery_progress_card.dart` — Shows overall mastery, no syllabus breakdown
- `lib/features/mentor/services/mentor_context_builder.dart` — Builds context across all subjects
- `lib/features/teaching/services/conversation_manager.dart` — Tutor operates on single subject/topic

## Suggested approach

1. **Add syllabus context to dashboard providers** — Create `dashboardSyllabusBreakdownProvider` that returns per-syllabus stats (completion %, accuracy, study time, weak topics)

2. **Create a syllabus switcher widget** — A dropdown or tab row at the top of the dashboard showing each active syllabus with progress, allowing the student to filter dashboard widgets by syllabus

3. **Add syllabus awareness to mentor context builder** — Include a `currentSyllabusContext` field that identifies which syllabus the student seems to be discussing (based on recent activity or explicit mention)

4. **Support syllabus switching in the tutor** — Add a `/syllabus` command or natural language intent that allows the student to say "Switch to my chemistry lessons" and have the tutor load the correct subject context

5. **Update dashboard widgets** — Modify `mastery_progress_card.dart`, `weak_areas_card.dart`, and `plan_adherence_card.dart` to accept an optional `syllabusId` filter parameter
