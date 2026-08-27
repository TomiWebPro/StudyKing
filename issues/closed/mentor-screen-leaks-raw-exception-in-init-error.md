# MentorScreen init error leaks raw exception to user

## Description
In `MentorScreen._initMentor()`, the catch block builds the user-facing init error message from the raw exception text via `l10n.mentorInitFailed(e.toString())`. This surfaces internal exception strings (stack-trace fragments, provider/network internals, Hive errors) directly to the student. The sibling `TutorScreen` was already fixed (CHANGELOG: "UI/UX Master M-1") to use a generic `tutorInitFailedGeneric` message while logging the real exception. `MentorScreen` was missed and still leaks raw `e.toString()`.

The Result-based init path in the same method (line 136) already uses `l10n.mentorInitFailed(initResult.error ?? '')` — a controlled error string — so the two code paths are inconsistent: one shows a controlled message, the other shows the raw exception.

## Affected files/areas
- lib/features/mentor/presentation/mentor_screen.dart:168 (catches `e`, assigns `l10n.mentorInitFailed(e.toString())`)
- lib/features/mentor/presentation/mentor_screen.dart:811 (displays `_initErrorMessage` to the user)
- lib/l10n/app_en.arb / app_es.arb (need a `mentorInitFailedGeneric` key, mirroring `tutorInitFailedGeneric`)
- lib/l10n/generated/* (regenerated)

## Expected vs Actual
- Expected: On mentor init failure, the student sees a generic, localized message ("Failed to initialize mentor. Please check your API configuration in Settings and try again.") and the real exception is logged via `_logger.e(...)` for investigation.
- Actual: The catch block at `mentor_screen.dart:168` interpolates the raw `e.toString()` into the user-visible message, exposing technical internals.

## Acceptance Criteria
- [ ] A `mentorInitFailedGeneric` ARB key (EN + ES, generated l10n) is added mirroring `tutorInitFailedGeneric`.
- [ ] `mentor_screen.dart:168` uses `l10n.mentorInitFailedGeneric` and logs the real exception with `_logger.e('Mentor initialization failed', e)` (the existing `_logger`/logger pattern in the file).
- [ ] The displayed `_initErrorMessage` no longer contains raw exception text from the catch path.
- [ ] `flutter analyze` passes with no new warnings.
