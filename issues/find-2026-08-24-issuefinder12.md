# Issue Finder Log — 2026-08-24 (pass 12)

Repository: TomiWebPro/StudyKing
Toolchain: ready (`/opt/flutter/.installed` present).
Method: `gh issue list --state open` (78 issues, #1–#78) reviewed for de-duplication;
targeted code review + subagent deep-scan for concrete logic/arithmetic/state bugs;
each candidate verified with file:line evidence before opening.

## Issues opened this run

| # | Title | Label | Evidence |
|---|---|---|---|
| 79 | topicsStudied metric is always 1 (questionId prefix, not topic) | bug | `lib/core/services/study_progress_tracker.dart:92-95` |
| 80 | estimateWorkload divides by zero on empty syllabus, returns 3.0 | bug | `lib/features/planner/services/syllabus_resolver.dart:223-225` |
| 81 | Focus timer double-counts elapsed time across background resume | bug | `study_timer_service.dart:54,166` + `focus_timer_screen.dart:107-118` |
| 82 | getPracticeQuestions never returns new/unseen questions (null nextReview excluded) | bug | `lib/features/practice/services/spaced_repetition_service.dart:191-193` |
| 83 | getWeeklyTrend week windows overlap, double-counting boundary-day attempts | bug | `lib/core/services/study_progress_tracker.dart:158-164` |

## Duplicates skipped
All 78 previously open issues (#1–#78) were reviewed. The 5 opened above are new:
- #76 (getWeeklyTrend improvement metric) is distinct from #83 (window overlap double-count); #83 notes the separation.
- #47 (mentor wellbeing without cap) and #44/#45 (notifications/reminders) are unrelated to the timer double-count (#81).
- No existing issue covers questionId-prefix topicsStudied (#79), syllabus_resolver estimateWorkload (#80), or spaced-repetition null nextReview handling (#82).

## Notes
- `toStringAsFixed` call sites confirmed to be only in CSV exports, logs, and LLM-facing prompts (permitted by AGENTS.md).
- `.normalized` used correctly; no `.toLowerCase()`/`trim().toLowerCase()` i18n violations found.
- All `reduce`/`~/`/`/` denominators traced were guarded except the 5 filed above.
