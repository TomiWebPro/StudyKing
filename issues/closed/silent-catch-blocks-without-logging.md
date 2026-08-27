# Silent catch blocks swallow errors without logging

## Description
Multiple `catch` blocks in production code discard the caught error object and return a fallback value without logging anything, violating the AGENTS.md logging convention ("Every catch must log the error with a descriptive message"). This makes failures invisible and hard to diagnose. Note: the scanner-specific variants (`scanner-catch-blocks-without-logging.md`, `scanner-empty-catch-blocks.md`) are already closed and are excluded here.

Verified occurrences (non-scanner):
- `lib/core/services/answer_validation_service.dart:151` — `catch (_) { return false; }`
- `lib/core/utils/question_import_utils.dart:98` — `catch (e) { return null; }`
- `lib/features/mentor/services/mentor_service.dart:247` — `catch (e) { return ''; }` (long-term memory context silently dropped)
- `lib/features/ingestion/services/document_extractor.dart:929` — `catch (e) { return ''; }`
- `lib/features/lessons/services/lesson_agent_service.dart:232` — `catch (e) { return null; }`
- `lib/features/subjects/presentation/widgets/subject_history_tab.dart:31` — `catch (e) { return []; }`
- `lib/features/practice/services/exam_session_service.dart:337` — `catch (e) { return []; }`
- `lib/features/planner/providers/planner_providers.dart:236` — `catch (e) { return []; }`

## Affected files/areas
- lib/core/services/answer_validation_service.dart:151
- lib/core/utils/question_import_utils.dart:98
- lib/features/mentor/services/mentor_service.dart:247
- lib/features/ingestion/services/document_extractor.dart:929
- lib/features/lessons/services/lesson_agent_service.dart:232
- lib/features/subjects/presentation/widgets/subject_history_tab.dart:31
- lib/features/practice/services/exam_session_service.dart:337
- lib/features/planner/providers/planner_providers.dart:236

## Expected vs Actual
- Expected: each `catch` logs the error with a descriptive message using the file-level static `Logger` (`.w(...)` for expected paths, `.e(...)` for unexpected), e.g. `_logger.w('Failed to build LTM context', e)`, and only then returns the fallback.
- Actual: the exception object is bound to `_` or `e` and ignored; no log line is emitted.

## Acceptance Criteria
- [ ] Every listed catch block emits a log via the static `Logger` with a descriptive message and includes the caught error object.
- [ ] No new `catch` blocks are added without logging anywhere in `lib/` (verified via grep for `catch` bodies that lack a `_logger` call in the same block).
- [ ] `flutter analyze` remains clean.
