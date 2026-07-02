# Testing Guide

## Test File Placement

Every source file must have a corresponding test file following these conventions:

| Source Location | Test Location |
|---|---|
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

## Unit vs Widget Tests

| Test Type | Scope | File Rule |
|---|---|---|
| **Unit Tests** | Services, providers, models, repositories | Pure logic, no UI |
| **Widget Tests** | Screens, widgets | UI rendering |

**Keep unit tests and widget tests in separate files** — never mix them in the same file.

## Provider Test Coverage Bar

Every provider test file must include at least one **behavioral assertion** beyond construction checks (`isA<...>()` or `isNotNull`). Acceptable behavioral assertions:

- Verifying dependency wiring via overrides (e.g., a fake repo injected through a provider is used by a downstream service)
- Testing fallback logic (e.g., when a config value is empty, the provider falls back to a default)
- Verifying singleton behavior (same instance across reads)
- Testing that error states are handled gracefully

## Test Patterns

### Fakes (No Mockito/Mocktail)

Use **hand-written fake classes** for dependency stubbing:

```dart
class FakeQuestionRepository implements QuestionRepository {
  final List<Question> _questions = [];

  @override
  Future<Result<List<Question>>> getByTopic(String topicId) async {
    return Result.success(_questions);
  }

  // Override all required methods...
}
```

### ProviderScope with Overrides

For Riverpod provider stubbing in widget tests:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(fakeRepo),
      studentIdServiceProvider.overrideWithValue(fixedStudentId),
    ],
    child: MaterialApp(home: PracticeScreen()),
  ),
);
```

### fixedStudentId

Prefer `fixedStudentId` over `StudentIdService` singleton in widget tests to avoid Hive I/O dependencies.

### Pump and Settle

Use `pumpAndSettle` for widget tests that involve async operations:

```dart
await tester.pumpWidget(widget);
await tester.pumpAndSettle();
```

### NavigatorObserver

Use `NavigatorObserver` for verifying navigation behavior:

```dart
final observer = MockNavigatorObserver();  // or a custom fake
await tester.pumpWidget(
  MaterialApp(
    home: MyScreen(),
    navigatorObservers: [observer],
  ),
);
```

## MentorService Dependencies

When writing tests for `MentorService` or `MentorScreen`, provide these fakes:

| Parameter | Provider | Fake class |
|---|---|---|
| `plannerService` | `plannerServiceProvider` | `FakePlannerService` (override `loadExistingPlan`, `loadRoadmaps`, `loadPendingActions`, `getScheduledLessons`, `checkAdherence`, `hasSchedulingConflict`, `scheduleLesson`) |
| `nudgeRepo` | `mentorEngagementNudgeRepoProvider` | Fake `EngagementNudgeRepository` (override `init`, `create`, `getRecentByStudent`, `getTodayCount`) |
| `sessionRepository` | `mentorSessionRepositoryProvider` | Fake `SessionRepository` (override `getAll`, `getByDate`, `getTodayDurationMs`) |
| `masteryService` | `masteryGraphServiceProvider` | `FakeMasteryGraphService` (override `getWeakTopics`, `getAtRiskQuestions`) |
| `progressTracker` | `mentorProgressTrackerProvider` | `FakeProgressTracker` (override `getOverallStats`, `getRecommendations`, `getBadges`) |

`MentorService.checkWellbeingAndGenerateNudges()` can be called independently for proactive engagement testing.

## Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Single file
flutter test test/core/utils/string_extensions_test.dart

# Feature subset
flutter test test/features/planner/
```
