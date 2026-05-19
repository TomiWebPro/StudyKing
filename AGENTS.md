# StudyKing Conventions

## Test File Placement

Every source file in `lib/features/*/` must have a corresponding test file following this convention:

| Source Location | Test Location |
|---|---|---|
| `lib/features/*/services/*.dart` | `test/features/*/services/*_test.dart` |
| `lib/features/*/data/repositories/*.dart` | `test/features/*/data/repositories/*_test.dart` |
| `lib/features/*/data/adapters/*.dart` | `test/features/*/data/adapters/*_test.dart` |
| `lib/features/*/providers/*.dart` | `test/features/*/providers/*_test.dart` |
| `lib/features/*/presentation/*.dart` | `test/features/*/presentation/*_test.dart` |
| `lib/features/*/presentation/widgets/*.dart` | `test/features/*/presentation/widgets/*_test.dart` |
| `lib/features/*/data/models/*.dart` | `test/features/*/data/models/*_test.dart` |
| `lib/core/services/*.dart` | `test/core/services/*_test.dart` |
| `lib/core/providers/*.dart` | `test/core/providers/*_test.dart` |
| `lib/core/utils/*.dart` | `test/core/utils/*_test.dart` |
| `lib/core/data/**/*.dart` | `test/core/data/**/*_test.dart` |

## Provider Test Coverage Bar

Every provider test file must include at least one **behavioral assertion** beyond construction checks (`isA<...>()` or `isNotNull`). Acceptable behavioral assertions include:
- Verifying dependency wiring via overrides (e.g., a fake repo injected through a provider is used by a downstream service).
- Testing fallback logic (e.g., when a config value is empty, the provider falls back to a default).
- Verifying singleton behavior (same instance across reads).
- Testing that error states are handled gracefully.

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

## Error Handling Conventions

- **Public repository and service method return types must be `Result<T>`**.
- `throw` is only allowed in private helper methods or config validation at startup.
- Use `SpacedRepetitionErrorCode` enum (from `lib/core/errors/spaced_repetition_error_codes.dart`) for spaced repetition error codes instead of string literals.
- Empty `catch (_) {}` blocks are forbidden. Every catch must log the error with a descriptive message.

## Logger Conventions

- All Logger instances must be `static final` at class level.
- Inline `const Logger('Name').e(...)` is forbidden.
- `.e()` should only be used for unexpected exceptions that require immediate investigation.
- `.w()` should be used for caught exceptions in expected error paths (e.g., box not open, item not found).

## Barrel File Convention

- Do not create barrel files unless they are imported by production code.

## String Normalization Convention

- Use the `.normalized` extension (from `lib/core/utils/string_extensions.dart`) instead of `.trim().toLowerCase()` or `.toLowerCase().trim()`.

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

## i18n Locale Switching Gotcha

When the user changes their language in the Profile screen (`ref.read(localeProvider.notifier).state = Locale(value)`), any screen that caches `l10n = AppLocalizations.of(context)!` in a local variable (not inside `build`) will display stale strings until the screen is re-entered. To avoid stale text:

- Always read `l10n` inside the `build` method or use `Consumer`/`ConsumerWidget` that re-reads on every build.
- If stale text is observed after a locale switch, refactor to ensure `context` is fresh (e.g., via `Navigator.pushAndRemoveUntil` or by using `ref.watch(localeProvider)` at the widget root).
