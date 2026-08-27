# RichContentRenderer swallows LaTeX parse error without logging

## Description
In `RichContentRenderer`, when a LaTeX/rich segment fails to render it is caught and falls back to showing the raw `segment.latex` text in a monospace error-colored style. The catch block (lib/core/widgets/rich_content_renderer.dart:65) logs nothing.

AGENTS.md states: ".w() should be used for caught exceptions in expected error paths (e.g., box not open, item not found)." A LaTeX/rich-content parse failure is exactly an expected error path (malformed or unsupported markup from AI-generated content), yet it is silently swallowed. This makes it impossible to detect systematically broken content (e.g. a bad prompt template producing always-broken markup) or to measure how often rendering falls back.

## Affected files/areas
- lib/core/widgets/rich_content_renderer.dart:65 (catch block with no logging)

## Expected vs Actual
- Expected: The catch block logs the parse failure with a descriptive `.w()` message (e.g. the offending latex segment / widget type) so the failure is observable, while still falling back to the monospace text rendering.
- Actual: The exception is caught and the fallback UI is shown with no log entry, hiding the failure from monitoring.

## Acceptance Criteria
- [ ] A module-level `static final` Logger (or the file's existing logger if present) is used with `.w(...)` inside the catch block at rich_content_renderer.dart:65, describing the failed segment/type.
- [ ] The graceful fallback rendering (monospace `segment.latex`) is preserved.
- [ ] A unit/widget test verifies the fallback path still renders (no exception escapes) and that logging occurs (e.g. via a test logger or by asserting no uncaught exception).
- [ ] `flutter analyze` passes with no new warnings.
