# Add behavioral tests for mentor agent tools

## Description
The mentor/assistant mode relies on a set of `AgentTool` implementations to answer
student queries (weak topics, adherence trends, question search, etc.). Per
AGENTS.md these must be covered by `test/features/mentor/services/tools/*_test.dart`
with behavioral assertions, but none currently exist. Examples:

- `lib/features/mentor/services/tools/get_adherence_trends_tool.dart:5` —
  `GetAdherenceTrendsTool` (buckets adherence over time; note it rounds values via
  `double.parse(x.toStringAsFixed(2))` at lines ~89/116 — the test should lock this
  behavior).
- `lib/features/mentor/services/tools/get_weak_topics_tool.dart:5` —
  `GetWeakTopicsTool`.
- `lib/features/mentor/services/tools/search_questions_tool.dart:5` —
  `SearchQuestionsTool`.
- Other tools under `lib/features/mentor/services/tools/` (create_plan, modify_plan,
  schedule_lesson, get_student_stats, get_lesson_history, generate_lesson_blocks,
  create_practice_session, get_syllabus_structure).

Untested tools can return malformed payloads to the LLM, degrading mentor answers
with no CI signal.

## Affected files/areas
- lib/features/mentor/services/tools/*.dart (all tool implementations)

## Expected vs Actual
- Expected: A `test/features/mentor/services/tools/*_test.dart` file per tool asserting
  that tool invocation with a hand-written fake repository produces the expected
  structured output (correct fields, correct rounding, graceful empty-result handling).
- Actual: No test files exist for any mentor tool.

## Acceptance Criteria
- [ ] At least the four named tools above have dedicated `_test.dart` files with
      behavioral assertions against fakes.
- [ ] Tests verify empty-result / no-data paths degrade gracefully (no throw).
- [ ] `flutter test test/features/mentor/services/tools` passes and `flutter analyze`
      is clean.
