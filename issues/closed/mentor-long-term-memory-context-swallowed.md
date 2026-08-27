# Mentor long-term-memory context build silently swallows errors

## Description
`MentorService._buildLongTermMemoryContext()` catches all exceptions and returns `''` with no logging. Any failure while building the long-term-memory context (e.g., LTM init/store error) silently strips the mentor of its memory context, degrading mentor responses with zero diagnostic visibility.

## Affected files/areas
- lib/features/mentor/services/mentor_service.dart:241-250 (`_buildLongTermMemoryContext`)

## Expected vs Actual
- Expected: Every `catch` logs the error (`.w(...)`) so failures are diagnosable; per conventions private helpers may alternatively `throw`.
- Actual: `catch (e) { return ''; }` silently discards both the context and the cause.

## Acceptance Criteria
- [ ] The `catch` block logs the exception (`_logger.w('Failed to build long-term memory context', e)`) or rethrows.
- [ ] Behavior on failure is covered by a test or documented fallback.
