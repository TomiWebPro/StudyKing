# Mentor modify-plan tool swallows exception without logging cause

## Description
`ModifyPlanTool.execute()` catches all exceptions and returns only a generic localized failure message (`l10n.toolModifyPlanError`) to the LLM. The actual exception `e` is never logged, so a genuine repository/planner failure while the mentor modifies a study plan is invisible in logs.

## Affected files/areas
- lib/features/mentor/services/tools/modify_plan_tool.dart:85-90 (`execute` catch block)

## Expected vs Actual
- Expected: The real exception is logged (`.w('modify_plan_tool failed', e)`) while still returning a user-facing message.
- Actual: Only the generic message is returned; the underlying cause is lost.

## Acceptance Criteria
- [ ] The `catch` block logs the exception with the real cause.
- [ ] The user-facing message is preserved.
- [ ] A test verifies logging occurs on a forced failure.
