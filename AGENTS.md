# StudyKing Conventions

## Test File Placement

Every source file in `lib/features/*/` must have a corresponding test file following this convention:

| Source Location | Test Location |
|---|---|---|
| `lib/features/*/services/*.dart` | `test/features/*/services/*_test.dart` |
| `lib/features/*/data/repositories/*.dart` | `test/features/*/data/repositories/*_test.dart` |
| `lib/features/*/providers/*.dart` | `test/features/*/providers/*_test.dart` |
| `lib/features/*/presentation/*.dart` | `test/features/*/presentation/*_test.dart` |
| `lib/features/*/presentation/widgets/*.dart` | `test/features/*/presentation/widgets/*_test.dart` |
| `lib/features/*/models/*.dart` | `test/features/*/models/*_test.dart` |

## Unit vs Widget Tests

- **Unit tests** (pure logic, no UI): test services, providers, models, and repositories.
- **Widget tests** (UI rendering): test screens and widgets.
- Keep unit tests and widget tests in **separate files** — never mix them in the same file.

## Test Patterns

- Use hand-written fake classes (not `mockito`/`mocktail`) for dependency stubbing.
- Use `ProviderScope` with `overrides` for Riverpod provider stubbing in widget tests.
- Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies.
- Use `pumpAndSettle` for widget tests that involve async operations.
- Use `NavigatorObserver` for verifying navigation behavior.

## MentorService Dependencies

When writing tests for `MentorService` or `MentorScreen`, provide these fakes:

| Parameter | Provider | Fake class |
|---|---|---|
| `plannerService` | `plannerServiceProvider` | `FakePlannerService` (override `loadExistingPlan`, `loadRoadmaps`, `loadPendingActions`, `getScheduledLessons`, `checkAdherence`, `hasSchedulingConflict`, `scheduleLesson`) |
| `nudgeRepo` | `mentorEngagementNudgeRepoProvider` | Fake `EngagementNudgeRepository` (override `init`, `create`, `getRecentByStudent`, `getTodayCount`) |
| `sessionRepository` | `mentorSessionRepositoryProvider` | Fake `SessionRepository` (override `getAll`, `getByDate`, `getTodayDurationMs`) |
| `masteryService` | `masteryGraphServiceProvider` | `FakeMasteryGraphService` (override `getWeakTopics`, `getAtRiskQuestions`) |
| `progressTracker` | `mentorProgressTrackerProvider` | `FakeProgressTracker` (override `getOverallStats`, `getRecommendations`, `getBadges`) |

`MentorService.checkWellbeingAndGenerateNudges()` can be called independently for proactive engagement.

## i18n / Number Formatting Conventions

- **Never use `toStringAsFixed()` for user-facing numeric displays.** It always produces a period decimal separator (e.g. `"85.5%"`), which is incorrect for comma-decimal locales (Spanish `es`, French, German, etc.).
- Instead, use the locale-aware helpers in `lib/core/utils/number_format_utils.dart`:
  - `formatDecimal(value, localeName, ...)` — plain decimals
  - `formatPercent(value, localeName, ...)` — percentages (takes 0–100 range)
  - `formatCompactNumber(value, localeName)` — compact token counts (1.5K, 2.3M)
  - `formatHours(totalSeconds, localeName)` — hours from seconds
  - `formatCurrency(value, localeName, ...)` — dollar amounts
- All helpers accept `localeName` (from `AppLocalizations.of(context)!.localeName`) so they render correctly for every locale.
- **CSV exports** should remain in invariant `en` format (CSV is data, not display).
- **PDF exports** should use the user's locale (they are user-facing documents).
- **LLM-facing** strings (prompts, tutor notes) can stay in `en` invariant format.
