# Services mask failed inner Result calls as Result.success(default)

## Description
Multiple service/repository methods correctly return `Result<T>`, but when an inner `Result`-returning dependency fails they still return `Result.success(defaultValue)` after reading `result.data ?? <default>`. The failure is therefore silently converted into a successful (but bogus) result, so callers and UI cannot distinguish "no data" from "operation failed". This is a distinct, more subtle bug than the raw-return convention violations already fixed in other areas, and none of the closed issues addressed this specific masking pattern.

## Affected files/areas
- `lib/features/subjects/data/repositories/subject_repository.dart:20` `getWithTopics` (`getAllResult.data ?? []` then `Result.success`)
- `lib/features/subjects/data/repositories/subject_repository.dart:70` `getByCode` (same pattern)
- `lib/features/sessions/services/study_timer_service.dart:265` `getTodayDurationMs` (`Result.success(result.data ?? 0)`); also `:275`, `:285`, `:295`, `:305`
- `lib/features/practice/services/spaced_repetition_service.dart:74` `getQuestionsDue` (`dueQuestionsResult.data ?? []` → `Result.success`)
- `lib/features/practice/services/mistake_review_service.dart:43` `getMistakesFromSession` (`allAttemptsResult.data ?? []` → success); also `:86`, `:127`
- `lib/core/services/study_progress_tracker.dart:40` `getOverallStats` (`:109`, `:145`, `:193`, `:199`, `:306`, `:376`, `:410`, `:447`, `:449`, `:451`, `:485`, `:504`)
- `lib/core/services/long_term_memory.dart:148` `getPendingActionItems` (`result.data ?? []`)
- `lib/core/services/plan_adherence_orchestrator.dart:185` `getDailyAdherenceFeedback` (`planResult.data` read with no `isFailure` check)

## Expected vs Actual
- Expected: when the inner `Result` is a failure, the method returns `Result.failure(innerError)` (and logs it), preserving the error signal.
- Actual: `result.data ?? default` yields `null`/empty on failure, wrapped in `Result.success(...)`, so failures look like empty successful data.

## Acceptance Criteria
- [ ] Each listed method checks `innerResult.isFailure` and returns `Result.failure(innerResult.error)` (logged with `.w()`) instead of `Result.success(default)`.
- [ ] A successful-but-empty inner result still yields an appropriate (empty) success; only genuine failures produce `Result.failure`.
- [ ] Unit tests inject a failing inner Result and assert the outer method returns `Result.failure` (not `Result.success`).
