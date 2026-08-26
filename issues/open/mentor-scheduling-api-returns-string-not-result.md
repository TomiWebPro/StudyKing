# Mentor scheduling API returns String instead of Result<T> and double-renders responses

## Description
`AGENTS.md` mandates that public service/repository methods return `Result<T>` and that `throw` is only allowed in private helpers / startup config. `MentorService` (and its `MentorScheduleHandler`) violate this for the scheduling-confirmation API, which is the most safety-relevant mentor path (it mutates the student's plan).

Two concrete defects:

1. **Non-Result return type:** `MentorService.confirmSchedule` (`lib/features/mentor/services/mentor_service.dart:377`) and `.suggestReschedule` (`mentor_service.dart:381`) return `String`. They simply delegate to `MentorScheduleHandler.confirmSchedule` (`lib/features/mentor/services/mentor_schedule_handler.dart:85`) / `.suggestReschedule` (`mentor_schedule_handler.dart:170`), which also return `String`. On failure the handler returns the localized error string (`l10n.mentorScheduleFail` / `l10n.mentorScheduleConflict`) instead of a `Result.failure`, so callers cannot distinguish success from failure via the type system. Other public `MentorService` methods also deviate: `initialize()` returns `void` (`mentor_service.dart:130`), `hasMeaningfulData()` returns `bool` (`mentor_service.dart:140`), `getProgressReport()` returns `ProgressReport` (`mentor_service.dart:391`).

2. **Duplicate message in conversation:** When scheduling fails or conflicts, `MentorScheduleHandler` already appends the response to memory via `_memory.addAssistantMessage(msg)` (`mentor_schedule_handler.dart:90`, `:122`, `:145`) and *also* returns `msg`. `mentor_screen.dart` then appends the returned `result` again as a new `ChatMessageData` (`mentor_screen.dart:532`, `:378`, `:1059`). The same message therefore appears twice in the visible conversation (once from memory reload, once from the explicit append), including on the success path.

## Affected files/areas
- lib/features/mentor/services/mentor_service.dart:130, :140, :377, :381, :391
- lib/features/mentor/services/mentor_schedule_handler.dart:85, :122, :145, :170
- lib/features/mentor/presentation/mentor_screen.dart:378, :532, :1059

## Expected vs Actual
- Expected: Scheduling methods return `Result<String>`; failures are signaled via `Result.failure` and handled with `.isSuccess` checks at the call site; the confirmation message is rendered exactly once in the conversation.
- Actual: Methods return `String`; failures are indistinguishable from success payloads; the response string is added to both memory and the UI list, producing duplicate messages.

## Acceptance Criteria
- [ ] `MentorService.confirmSchedule` / `suggestReschedule` (and the `MentorScheduleHandler` counterparts) return `Result<String>`.
- [ ] `MentorService.initialize()` returns `Result<void>` and `hasMeaningfulData()` returns `Result<bool>` (or another explicit convention is documented and applied consistently).
- [ ] `mentor_screen.dart` updates to branch on `result.isSuccess` and only displays the message once (remove the double append; let the handler own memory writes OR the screen own UI writes, not both).
- [ ] `getProgressReport()` either returns `Result<ProgressReport>` or is documented as intentionally exception-safe.
- [ ] Existing mentor tests are updated/extended (use hand-written fakes per AGENTS.md) and `flutter test` passes.
