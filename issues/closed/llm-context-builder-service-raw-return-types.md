# LLM/context builder service methods return raw String instead of Result<T>

## Description
Per AGENTS.md, public service methods must return `Result<T>`. Several service methods that build prompt/summary strings from LLM or storage calls return raw `Future<String>`, so failures (LLM errors, parse errors, missing data) are either thrown unguarded or silently coerced, and callers cannot distinguish failure from an empty string:
- `ConversationManager.generateSummary()` returns `Future<String>` (lib/features/teaching/services/conversation_manager.dart:466) — used at `lib/features/teaching/presentation/tutor_screen.dart:498` (`final summary = await _manager!.generateSummary();`).
- `MentorContextBuilder.buildContextPrompt()` returns `Future<String>` (lib/features/mentor/services/mentor_context_builder.dart:50) — used at `lib/features/mentor/services/mentor_service.dart:178` and `:206`.
- `ChunkedContentProcessor.generateConsolidatedSummary(...)` returns `Future<String>` (lib/features/ingestion/services/chunked_content_processor.dart:194) — used at `lib/features/ingestion/services/content_pipeline.dart:311`.

These are public methods on service classes and should return `Result<String>` so callers can handle failures gracefully (and log them) rather than receiving `''` or crashing.

## Affected files/areas
- lib/features/teaching/services/conversation_manager.dart:466 (and tutor_screen.dart:498)
- lib/features/mentor/services/mentor_context_builder.dart:50 (and mentor_service.dart:178, 206)
- lib/features/ingestion/services/chunked_content_processor.dart:194 (and content_pipeline.dart:311)

## Expected vs Actual
- Expected: these public methods return `Future<Result<String>>`; on LLM/storage failure they return `Result.failure` (logged with `_logger.w`), and callers check `isFailure`.
- Actual: they return raw `String`; a failure either throws or yields an empty string, indistinguishable from a legitimately empty summary, and errors are not consistently logged/handled.

## Acceptance Criteria
- [ ] `ConversationManager.generateSummary` returns `Future<Result<String>>`; `tutor_screen.dart:498` updated to handle `isFailure`.
- [ ] `MentorContextBuilder.buildContextPrompt` returns `Future<Result<String>>`; `mentor_service.dart:178,206` updated to handle `isFailure`.
- [ ] `ChunkedContentProcessor.generateConsolidatedSummary` returns `Future<Result<String>>`; `content_pipeline.dart:311` updated to handle `isFailure`.
- [ ] Relevant tests updated and pass; failures are logged with `_logger.w` where appropriate.
