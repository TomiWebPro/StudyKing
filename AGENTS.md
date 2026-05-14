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
