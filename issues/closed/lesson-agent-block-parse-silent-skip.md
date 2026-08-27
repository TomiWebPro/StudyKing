# Lesson agent block parse silently skips malformed blocks

## Description
`LessonAgentService._parseBlock()` returns `null` on any parse exception with no logging. When the LLM emits a malformed lesson block it is silently skipped, hiding broken AI-generated lesson plans and making diagnosis hard.

## Affected files/areas
- lib/features/lessons/services/lesson_agent_service.dart:220-234 (`_parseBlock`)

## Expected vs Actual
- Expected: A parse failure is logged (`.w(...)`) so malformed LLM output is visible for debugging/improvement.
- Actual: `catch (e) { return null; }` silently drops the block.

## Acceptance Criteria
- [ ] The `catch` block logs the parse error (`_logger.w('Skipping malformed lesson block', e)`).
- [ ] A test covers the malformed-block path and asserts the log/behavior.
