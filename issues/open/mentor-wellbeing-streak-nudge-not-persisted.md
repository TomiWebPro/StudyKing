# Mentor wellbeing streak nudge is never persisted to the nudge repository

## Description
In `lib/features/mentor/services/mentor_wellbeing_service.dart`, three of the four wellbeing checks persist an `EngagementNudgeModel` via `_nudgeRepo.create(...)` AND add the message to the returned `messages` list:
- `_checkOverwork` (lines 54–65)
- `_checkLateNight` (lines 67–81)
- `_checkRevisionNeeded` (lines 83–97)

However, `_checkStreak` (lines 99–145) only adds the streak encouragement message to `messages` (line 102) and returns **without** calling `_nudgeRepo.create(...)`. Because `MentorService.checkWellbeingAndGenerateNudges()` (lib/features/mentor/services/mentor_service.dart:374) only forwards returned messages as assistant conversation messages, the streak encouragement is never recorded in the engagement nudge repository. This is an inconsistency: the streak nudge never appears in nudge history, is not subject to the same persistence/dedup path as the other wellbeing nudges, and cannot be surfaced by any UI that reads `EngagementNudgeRepository`.

## Affected files/areas
- lib/features/mentor/services/mentor_wellbeing_service.dart:99–104 (`_checkStreak`)
- lib/features/mentor/services/mentor_service.dart:374–380 (wiring)
- test/features/mentor/services/mentor_wellbeing_service_test.dart (behavioral assertion missing)

## Expected vs Actual
- Expected: streak encouragement is persisted as an `EngagementNudgeModel` (consistent with the other three checks) so it is recorded in the engagement nudge repository/history, using an appropriate `NudgeType` (e.g. a `streak` type or `NudgeType.planAdjustment`) and a low severity.
- Actual: the streak message is returned but never persisted; only overwork/late-night/revision nudges are written to the repository.

## Acceptance Criteria
- [ ] `_checkStreak` calls `_nudgeRepo.create(...)` with a properly typed `EngagementNudgeModel` when `consecutiveDays >= 7` (consistent with the other checks).
- [ ] A unit test verifies that calling `checkWellbeingAndGenerateNudges()` for a student with a >=7 day streak results in a persisted nudge in the (fake) `EngagementNudgeRepository`.
- [ ] `flutter analyze` and the mentor wellbeing test suite pass.
