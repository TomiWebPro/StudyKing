# Issue Discovery Log — 2026-08-24 (issue-finder pass 5)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze lib/`: only 2 info-level `use_build_context_synchronously` (covered by open #6), no new lints.
- `flutter test` (sampled, run timed out at 15 min after processing the bulk of the suite): **~700 failing tests out of ~6500**. Dominant cause: `HiveError: You need to initialize Hive ...` and `Bad state: Box "<name>" is not initialized` — tests that use Hive-backed repositories/services/providers do not initialize Hive.

## Existing open issues reviewed (did NOT duplicate #1–#41)
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#41). Confirmed these are distinct:
- The 700 failing tests are systemic (missing shared Hive test bootstrap), distinct from the specific broken-test files already tracked (#3, #8, #10, #13).
- Inline `Logger(...)` (#11/#35) and empty `catch` (#12, closed) were re-audited: no remaining empty catches; the new practice_screen `catchError` (#46) returns `Result.success` on failure — a more severe, distinct anti-pattern not covered.
- Adapter registration in `main.dart` (AccessibilityPreferences/UserProfile/MasteryImprovementMetric) was checked and does NOT conflict with `HiveInitializer` (those 3 are registered only in `main.dart`), so no double-registration file was opened.

## New issues opened (5)
| # | Title | Label | Summary |
|---|-------|-------|---------|
| 42 | Systemic missing Hive initialization in tests causes ~700 failures | bug | Tests touching Hive-backed repos/services/providers don't init Hive; need a shared test bootstrap (`flutter_test_config.dart` / helper) reusing `HiveInitializer` registration. |
| 43 | Unguarded firstWhere/first throws 'Bad state: No element' on empty/unknown values | bug | Enum/JSON deserialization and archive/file lookups use `firstWhere`/`.first` without `orElse`, crashing on empty/unknown input. |
| 44 | NotificationService.showDailyReminder ignores the chosen remindAt time | bug | `scheduledDate` is computed but never passed to `periodicallyShow(RepeatInterval.daily)`, so the user's reminder time is not honored. |
| 45 | EngagementScheduler sends duplicate lesson reminders every 5 minutes | bug | `_checkUpcomingLessons` fires every 5 min inside a 30-min window with no deduplication → repeated reminders for the same lesson. |
| 46 | practice_screen swallows repository failure and returns empty success | bug | `catchError((_) => Result.success(<Question>[]))` masks DB failures as a successful empty session with no log/error. |

## Duplicate/skipped
- Hive test bootstrap vs #3/#8/#10/#13 (specific files): distinct (systemic, not file-specific) → opened as #42.
- Enum `firstWhere` crash vs #1 (ProcessingStatus switch): distinct mechanism/area → opened as #43.
- Reminder time vs #17 (onboarding overflow)/#39 (dashboard i18n): distinct → opened as #44.
- Duplicate lesson reminders: no existing notification-dedup issue → opened as #45.
- practice_screen catchError vs #12 (silent catch, closed) and #36 (subject_list catchError): distinct file + returns SUCCESS on failure (worse) → opened as #46.
- Adapter double-registration idea was investigated and REJECTED (no actual conflict in `main.dart` vs `HiveInitializer`).

## Notes
- Capped at 5 new issues to avoid spam.
- Only this notes file is committed; no application code modified.
